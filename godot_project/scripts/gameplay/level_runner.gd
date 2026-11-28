extends Node3D

# World 1 Gameplay Engine (Data-Driven LevelRunner) — Angry Capibara
# Memuat 20 Sub-Level JSON (data/levels/w1/1-1.json .. 1-20.json) dengan gaya visual
# Anti-Slop 2.5D Lineless Painterly (DESIGN.md + rovio_25d.gdshader), 3 Kapibara World 1
# (Chill, Dash, Trio Mini + Triple Split nyata), 4 material (Bambu, Kayu, Es/Kaca, Tong Yuzu TNT),
# 2 musuh (Croc Minion & Mini-Boss Mahkota 1-20), sistem skor + Yuzu Combo + 1-3 Bintang lokal!

enum CameraView { SIDE_25D = 0, ANGLED_25D = 1, BEHIND_3D = 2 }

const WORLD1_SELECT_SCENE := "res://scenes/ui/world1_select.tscn"
const HOME_SCENE := "res://scenes/ui/home_screen.tscn"

const GRAVITY := 18.0
const MAX_PULL_DIST := 3.20
const LAUNCH_POWER := 13.0

const CAPY_SPECS := {
	"chill": {
		"name": "Chill Capi",
		"mesh": "res://assets/generated/models/anime_capy_chill.obj",
		"portrait": "res://assets/generated/home2d/char_01_chill_roar.png",
		"wood": "wood_sq_vermilion",
		"accent": Color(1.0, 0.902, 0.349),
		"mass": 2.0,
		"radius": 0.36,
		"skill_short": "ZEN BUMP",
		"skill_desc": "Zen Bump (getar ke bawah)"
	},
	"dash": {
		"name": "Dash Capi",
		"mesh": "res://assets/generated/models/anime_capy_dash.obj",
		"portrait": "res://assets/generated/home2d/char_06_dash_leap.png",
		"wood": "wood_sq_amber",
		"accent": Color(1.0, 0.855, 0.32),
		"mass": 1.8,
		"radius": 0.35,
		"skill_short": "TURBO DASH",
		"skill_desc": "Turbo Dash 2.2x (1.8x ke Kayu)"
	},
	"mini": {
		"name": "Trio Mini-Capi",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"portrait": "res://assets/generated/home2d/char_07_mini_capi.png",
		"wood": "wood_sq_sky",
		"accent": Color(0.502, 0.882, 1.0),
		"mass": 1.0,
		"radius": 0.25,
		"skill_short": "TRIPLE SPLIT 3x",
		"skill_desc": "Triple Split 3x (2.0x ke Es/Kaca)"
	}
}

const MAT_SPECS := {
	"bamboo":      { "hp": 30.0,  "mass": 0.85, "thresh": 2.4, "score": 300 },
	"ice":         { "hp": 38.0,  "mass": 1.00, "thresh": 1.9, "score": 500 },
	"wood":        { "hp": 72.0,  "mass": 1.50, "thresh": 3.6, "score": 600 },
	"stone":       { "hp": 135.0, "mass": 2.65, "thresh": 4.4, "score": 900 },
	"tnt":         { "hp": 20.0,  "mass": 1.20, "thresh": 2.5, "score": 1500 },
	"boulder":     { "hp": 220.0, "mass": 3.40, "thresh": 6.5, "score": 1200 },
	"yuzu_basket": { "hp": 12.0,  "mass": 0.45, "thresh": 0.9, "score": 1500 }
}

var current_stage_id: String = "1-1"
var stage_data: Dictionary = {}
var current_view: int = CameraView.SIDE_25D

# Dynamic per-stage slingshot & panorama camera bounds
var sling_x: float = -10.0
var sling_base_y: float = 0.0
var launch_x: float = -10.0
var launch_y: float = 1.75
var stage_min_x: float = -11.5
var stage_max_x: float = 13.0
var stage_max_y: float = 6.5

# Cached resources
var shader_rovio: Shader
var tex_wood: Texture2D
var tex_bamboo: Texture2D
var tex_stone: Texture2D
var tex_moss: Texture2D
var tex_cliff: Texture2D
var mesh_croco: Mesh
var mesh_slingshot: Mesh
var capy_meshes: Dictionary = {}

# Scene roots
var cam: Camera3D
var sun: DirectionalLight3D
var arena_root: Node3D
var queue_visual_root: Node3D
var slingshot_visual: Node3D
var band_mesh_a: MeshInstance3D
var band_mesh_b: MeshInstance3D
var traj_dots: Array[MeshInstance3D] = []
var sun_rays_node: Node3D
var steam_puffs: Array[Dictionary] = []
var bg_leaves: Array[Dictionary] = []

# Runtime gameplay state
var capy_queue: Array[String] = []
var active_capy: RigidBody3D = null
var active_capy_type: String = "chill"
var active_capy_visual: Node3D = null
var flying_projectiles: Array[RigidBody3D] = []
var blocks: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var bounce_pads: Array[Dictionary] = []
var vfx_nodes: Array[Dictionary] = []

var is_aiming: bool = false
var drag_start_px: Vector2 = Vector2.ZERO
var pull_vector: Vector3 = Vector3.ZERO
var is_flying: bool = false
var shot_fired: bool = false
var skill_used: bool = false
var flight_timer: float = 0.0
var settle_timer: float = 0.0
var spawn_grace: float = 0.0
var anim_time: float = 0.0

var score: int = 0
var combo_count: int = 0
var combo_timer: float = 0.0
var stage_ended: bool = false
var end_delay_timer: float = 0.0
var pending_victory: bool = false
var pending_defeat: bool = false
var floating_texts: Array[Dictionary] = []
var shake_trauma: float = 0.0

# Camera orbit & pan state
var orbit_active: bool = false
var custom_orbit_active: bool = false
var orbit_yaw: float = 0.35
var orbit_pitch: float = 0.22
var cam_zoom_offset: float = 0.0
var cam_pan_x: float = 0.0
var cam_pan_target_x: float = 0.0
var snap_camera: bool = true

# HUD & Overlays (Bamboo Woodblock Arcade UX + 3D-Projected Diegetic Cues)
class DiegeticOverlay extends Control:
	var runner: Node = null

	func _draw() -> void:
		if runner == null or runner.stage_ended or not is_instance_valid(runner.cam):
			return
		var cam_3d: Camera3D = runner.cam
		var f_disp: Font = CraftUI.display_font()
		var ink: Color = CraftUI.INK

		# 1. Diegetic Slingshot Pull + Zen Bump Arc Cue on Stage 1-1 before first aim/shot
		if runner.current_stage_id == "1-1" and not runner.shot_fired and not runner.is_aiming and is_instance_valid(runner.active_capy):
			var p_start := Vector3(runner.sling_x + 0.35, runner.sling_base_y + 2.0, 0.0)
			var p_apex := Vector3(runner.sling_x + 6.4, runner.sling_base_y + 3.6, 0.0)
			var p_ctrl := Vector3(runner.sling_x + 3.2, runner.sling_base_y + 4.5, 0.0)
			if not cam_3d.is_position_behind(p_start) and not cam_3d.is_position_behind(p_apex):
				var s2 := cam_3d.unproject_position(p_start)
				var a2 := cam_3d.unproject_position(p_apex)
				var c2 := cam_3d.unproject_position(p_ctrl)
				var steps := 14
				for i in steps:
					var t := float(i) / float(steps - 1)
					var u := 1.0 - t
					var pt: Vector2 = u * u * s2 + 2.0 * u * t * c2 + t * t * a2
					draw_circle(pt, 3.2, Color(1.0, 0.99, 0.94, 0.78))
				# Pull-back arrow beside slingshot
				var pull_tip := s2 + Vector2(-48, 22)
				var pull_base := s2 + Vector2(-12, 6)
				draw_line(pull_base, pull_tip, Color(1.0, 0.90, 0.35, 0.92), 4.0, true)
				draw_colored_polygon(PackedVector2Array([
					pull_tip + Vector2(-6, 3),
					pull_tip + Vector2(10, -6),
					pull_tip + Vector2(11, 7)
				]), Color(1.0, 0.90, 0.35, 0.95))
				# Zen Bump Sky Prompt at arc apex
				draw_circle(a2, 10.0, ink)
				draw_circle(a2, 7.5, Color(1.0, 0.90, 0.35, 0.96))
				draw_colored_polygon(PackedVector2Array([
					a2 + Vector2(-7, 14), a2 + Vector2(7, 14), a2 + Vector2(0, 24)
				]), Color(1.0, 0.90, 0.35, 0.96))
				draw_string_outline(f_disp, a2 + Vector2(-76, -16), "SPASI = ZEN BUMP!", HORIZONTAL_ALIGNMENT_CENTER, 152, 14, 5, ink)
				draw_string(f_disp, a2 + Vector2(-76, -16), "SPASI = ZEN BUMP!", HORIZONTAL_ALIGNMENT_CENTER, 152, 14, Color(1.0, 0.99, 0.96))

		# 2. Diegetic Boss & TNT Markers
		for e in runner.enemies:
			if bool(e["dead"]):
				continue
			if str(e["type"]) == "mini_boss":
				var rb: RigidBody3D = e["rb"]
				if is_instance_valid(rb):
					var wp := rb.global_position + Vector3(0.0, 1.15, 0.0)
					if not cam_3d.is_position_behind(wp):
						var bob_y := sin(runner.anim_time * 4.5) * 4.0
						var sp := cam_3d.unproject_position(wp) + Vector2(0.0, bob_y)
						draw_colored_polygon(PackedVector2Array([
							sp + Vector2(-11, -14), sp + Vector2(11, -14), sp + Vector2(0, -1)
						]), ink)
						draw_colored_polygon(PackedVector2Array([
							sp + Vector2(-8, -12), sp + Vector2(8, -12), sp + Vector2(0, -3)
						]), Color(0.95, 0.27, 0.18))
						draw_string_outline(f_disp, sp + Vector2(-42, -20), "BOSS!", HORIZONTAL_ALIGNMENT_CENTER, 84, 15, 5, ink)
						draw_string(f_disp, sp + Vector2(-42, -20), "BOSS!", HORIZONTAL_ALIGNMENT_CENTER, 84, 15, Color(1.0, 0.90, 0.35))

		if not runner.shot_fired:
			var best_tnt_pos := Vector3.ZERO
			var found_tnt := false
			for b in runner.blocks:
				if bool(b["dead"]) or str(b["type"]) != "tnt":
					continue
				var brb: RigidBody3D = b["rb"]
				if is_instance_valid(brb) and (not found_tnt or brb.global_position.y > best_tnt_pos.y):
					best_tnt_pos = brb.global_position
					found_tnt = true
			if found_tnt:
				var tp := best_tnt_pos + Vector3(0.0, 0.68, 0.0)
				if not cam_3d.is_position_behind(tp):
					var sp_t := cam_3d.unproject_position(tp) + Vector2(0.0, sin(runner.anim_time * 5.0) * 3.0)
					draw_colored_polygon(PackedVector2Array([
						sp_t + Vector2(-8, -10), sp_t + Vector2(8, -10), sp_t + Vector2(0, 0)
					]), Color(1.0, 0.83, 0.15))
					draw_string_outline(f_disp, sp_t + Vector2(-34, -15), "TNT!", HORIZONTAL_ALIGNMENT_CENTER, 68, 12, 4, ink)
					draw_string(f_disp, sp_t + Vector2(-34, -15), "TNT!", HORIZONTAL_ALIGNMENT_CENTER, 68, 12, Color(1.0, 0.48, 0.28))

		# 3. Floating Score & Combo Popups (Gameplay Juice)
		for ft in runner.floating_texts:
			var wp: Vector3 = ft["pos"]
			if cam_3d.is_position_behind(wp):
				continue
			var sp: Vector2 = cam_3d.unproject_position(wp)
			var u: float = clampf(float(ft["t"]) / maxf(float(ft["dur"]), 0.01), 0.0, 1.0)
			var alpha: float = 1.0 if u < 0.65 else clampf(1.0 - (u - 0.65) / 0.35, 0.0, 1.0)
			var txt: String = str(ft["text"])
			var fsz: int = int(ft["size"])
			var base_col: Color = ft["color"]
			var col := Color(base_col.r, base_col.g, base_col.b, alpha)
			var ink_a := Color(ink.r, ink.g, ink.b, alpha)
			draw_string_outline(f_disp, sp + Vector2(-90, -8), txt, HORIZONTAL_ALIGNMENT_CENTER, 180, fsz, 5, ink_a)
			draw_string(f_disp, sp + Vector2(-90, -8), txt, HORIZONTAL_ALIGNMENT_CENTER, 180, fsz, col)

class PauseInputCatcher extends Control:
	var on_resume_key: Callable

	func _input(event: InputEvent) -> void:
		if CraftUI.is_confirm_open(get_tree()):
			return
		if visible and event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
				get_viewport().set_input_as_handled()
				if on_resume_key.is_valid():
					on_resume_key.call()

var diegetic_overlay: DiegeticOverlay
var lbl_stage_title: Label
var lbl_enemy_pill: Label
var lbl_score: Label
var score_star_bar: ProgressBar
var hud_star_pips: Array[TextureRect] = []
var lbl_combo: Label
var boss_bar_root: Control
var boss_segments: Array[ColorRect] = []
var lbl_boss_hp: Label
var active_hero_wood_bg: ColorRect
var active_hero_portrait: TextureRect
var active_skill_lbl: Label
var hud_squad_row: HBoxContainer
var btn_views: Array[Button] = []
var result_overlay: ColorRect
var result_badge_lbl: Label
var result_title: Label
var result_stars: Label
var result_star_labels: Array[TextureRect] = []
var result_body: Label
var btn_retry: Button
var btn_next_stage: Button

# In-Game Pause Menu state & controls
var is_paused: bool = false
var pause_layer: CanvasLayer
var pause_overlay: ColorRect
var pause_stage_lbl: Label
var pause_stats_lbl: Label
var pause_audio_icon: TextureRect
var pause_vol_slider: HSlider
var pause_vol_pct: Label
var pause_btn_mute: Button
var pause_btn_disp: Button

# CLI flags for capture & automated 20-stage stability validation
var capture_stage_path: String = ""
var capture_croco_path: String = ""
var capture_pause_path: String = ""
var capture_confirm_reset_path: String = ""
var capture_done: bool = false
var validate_all_w1: bool = false
var validate_idx: int = 1
var validate_timer: float = 0.0
var validate_failed: Array[String] = []

func _ready() -> void:
	current_stage_id = SaveManager.selected_stage_id
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			current_stage_id = arg.substr(8)
		elif arg.begins_with("--capture-stage="):
			capture_stage_path = arg.substr(16)
		elif arg.begins_with("--capture-croco="):
			capture_croco_path = arg.substr(16)
		elif arg.begins_with("--capture-pause="):
			capture_pause_path = arg.substr(16)
		elif arg.begins_with("--capture-confirm-reset="):
			capture_confirm_reset_path = arg.substr(24)
		elif arg == "--validate-w1":
			validate_all_w1 = true
			current_stage_id = "1-1"

	shader_rovio = load("res://shaders/rovio_25d.gdshader")
	tex_wood = load("res://assets/generated/textures/tex_wood.bmp")
	tex_bamboo = load("res://assets/generated/textures/tex_bamboo.bmp")
	tex_stone = load("res://assets/generated/textures/tex_stone.bmp")
	tex_moss = load("res://assets/generated/textures/tex_moss_painterly.bmp")
	tex_cliff = load("res://assets/generated/textures/tex_cliff_rock.bmp")
	mesh_croco = load("res://assets/generated/models/enemy_croco_minion.obj")
	mesh_slingshot = load("res://assets/generated/models/prop_slingshot_bamboo.obj")
	for cid in CAPY_SPECS.keys():
		capy_meshes[cid] = load(CAPY_SPECS[cid]["mesh"])

	_setup_environment()
	_setup_ground()
	_setup_world1_scenery()
	_setup_slingshot()
	_setup_trajectory_dots()
	_setup_hud()
	_setup_pause_menu()

	arena_root = Node3D.new()
	add_child(arena_root)
	queue_visual_root = Node3D.new()
	add_child(queue_visual_root)

	_load_stage(current_stage_id)
	_set_camera_view(CameraView.SIDE_25D)

func _setup_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	# Palet Woodblock/Ghibli Anti-Slop (DESIGN.md — serasi 100% dengan Home & World 1 Select!)
	sky_mat.sky_top_color = Color(0.22, 0.52, 0.72)
	sky_mat.sky_horizon_color = Color(0.95, 0.90, 0.76)
	sky_mat.ground_bottom_color = Color(0.24, 0.39, 0.28)
	sky_mat.ground_horizon_color = Color(0.84, 0.84, 0.72)
	sky_mat.sky_curve = 0.08
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.72, 0.68)
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.00
	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.18

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32.0, 28.0, 0.0)
	sun.light_energy = 0.84
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	add_child(sun)

	var rim_sun := DirectionalLight3D.new()
	rim_sun.rotation_degrees = Vector3(-16.0, -152.0, 0.0)
	rim_sun.light_energy = 0.28
	rim_sun.light_color = Color(0.98, 0.92, 0.76)
	add_child(rim_sun)

	cam = Camera3D.new()
	cam.near = 0.1
	cam.far = 160.0
	add_child(cam)
	cam.make_current()

func _make_rovio_mat(tex: Texture2D, tint: Color = Color.WHITE, uv_sc: Vector2 = Vector2.ONE, rim_str: float = 0.18, sheen_str: float = 0.10) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader_rovio
	if tex:
		mat.set_shader_parameter("albedo_tex", tex)
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("uv_scale", uv_sc)
	mat.set_shader_parameter("rim_strength", rim_str)
	mat.set_shader_parameter("sheen_strength", sheen_str)
	mat.set_shader_parameter("shadow_tint", Vector3(0.46, 0.42, 0.48))
	mat.set_shader_parameter("rim_color", Vector3(0.98, 0.92, 0.76))
	return mat

func _apply_rovio_model_materials(mi: MeshInstance3D, tint_mult: Color = Color.WHITE) -> void:
	if not mi.mesh or not shader_rovio:
		return
	for s_idx in mi.mesh.get_surface_count():
		var orig := mi.mesh.surface_get_material(s_idx)
		var mat_name: String = orig.resource_name if orig else ""
		var mat := ShaderMaterial.new()
		mat.shader = shader_rovio

		var local_rim: float = 0.24
		var local_sheen: float = 0.14
		if mat_name in ["mat_ink", "mat_mouth_dark", "mat_anime_eye", "mat_croco_eye"]:
			local_rim = 0.04
			local_sheen = 0.24 if "eye" in mat_name else 0.03
		elif mat_name in ["mat_white", "mat_tongue", "mat_anger", "mat_spark", "mat_shoji_glow"]:
			local_rim = 0.05
			local_sheen = 0.18

		mat.set_shader_parameter("rim_color", Vector3(0.98, 0.92, 0.76))
		mat.set_shader_parameter("shadow_tint", Vector3(0.46, 0.40, 0.48))
		mat.set_shader_parameter("rim_strength", local_rim)
		mat.set_shader_parameter("sheen_strength", local_sheen)
		if orig is BaseMaterial3D:
			if orig.albedo_texture:
				mat.set_shader_parameter("albedo_tex", orig.albedo_texture)
			mat.set_shader_parameter("tint_color", orig.albedo_color * tint_mult)
			if orig.emission_enabled:
				mat.set_shader_parameter("emission_color", Vector3(orig.emission.r, orig.emission.g, orig.emission.b))
		mi.set_surface_override_material(s_idx, mat)

func _setup_ground() -> void:
	var ground := StaticBody3D.new()
	ground.set_meta("kind", "ground")
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(84.0, 2.0, 16.0)
	col.shape = shape
	ground.position = Vector3(2.0, -1.0, 0.0)
	ground.add_child(col)

	var moss_top := MeshInstance3D.new()
	var mt := BoxMesh.new()
	mt.size = Vector3(76.0, 0.42, 12.0)
	moss_top.mesh = mt
	moss_top.position = Vector3(0.0, 0.79, 0.0)
	var moss_mat := _make_rovio_mat(tex_moss, Color(0.68, 0.80, 0.56), Vector2(10.0, 1.8), 0.10, 0.05)
	moss_mat.set_shader_parameter("shadow_tint", Vector3(0.36, 0.46, 0.38))
	moss_top.material_override = moss_mat
	ground.add_child(moss_top)

	var cliff := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(75.4, 3.8, 11.4)
	cliff.mesh = cm
	cliff.position = Vector3(0.0, -1.30, 0.0)
	cliff.material_override = _make_rovio_mat(tex_cliff, Color(0.68, 0.62, 0.56), Vector2(12.0, 1.2), 0.06, 0.04)
	ground.add_child(cliff)
	add_child(ground)

	# Jalan setapak pasir hangat sepanjang arena luas di Z=0 (-28..+32)
	var lane := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(60.0, 0.025, 0.46)
	lane.mesh = lm
	lane.position = Vector3(2.0, 0.015, 0.0)
	var lane_mat := _make_rovio_mat(null, Color(0.56, 0.50, 0.38), Vector2.ONE, 0.0, 0.02)
	lane_mat.set_shader_parameter("shadow_tint", Vector3(0.42, 0.38, 0.30))
	lane.material_override = lane_mat
	add_child(lane)

func _setup_world1_scenery() -> void:
	var scenery := Node3D.new()
	add_child(scenery)

	# 1. Matahari washi-emas + sinar woodblock
	sun_rays_node = Node3D.new()
	sun_rays_node.position = Vector3(1.5, 4.8, -22.0)
	scenery.add_child(sun_rays_node)

	var sun_disk := MeshInstance3D.new()
	var sdm := SphereMesh.new()
	sdm.radius = 4.2
	sdm.height = 8.4
	sun_disk.mesh = sdm
	var sd_mat := StandardMaterial3D.new()
	sd_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sd_mat.albedo_color = Color(0.99, 0.96, 0.86)
	sd_mat.emission_enabled = true
	sd_mat.emission = Color(0.96, 0.88, 0.64)
	sd_mat.emission_energy_multiplier = 0.85
	sun_disk.material_override = sd_mat
	sun_disk.scale = Vector3(1.0, 1.0, 0.1)
	sun_rays_node.add_child(sun_disk)

	var ray_mat := StandardMaterial3D.new()
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.albedo_color = Color(0.98, 0.94, 0.80, 0.15)
	for i in 12:
		var ray := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(2.2, 22.0, 0.05)
		ray.mesh = pm
		ray.material_override = ray_mat
		var ang := (float(i) / 12.0) * TAU
		ray.rotation.z = ang
		ray.position = Vector3(-sin(ang), cos(ang), -0.4) * 9.0
		sun_rays_node.add_child(ray)

	# 2. Pegunungan bambu berkabut (palet woodblock-pine DESIGN.md)
	var hill_mesh: Mesh = load("res://assets/generated/models/home_stage_hill.obj")
	for ml in [
		[Vector3(-18.0, -1.5, -14.5), Vector3(2.8, 4.0, 1.6), Color(0.36, 0.54, 0.44)],
		[Vector3(  1.5, -2.0, -19.0), Vector3(4.0, 4.6, 1.8), Color(0.45, 0.62, 0.57)],
		[Vector3( 19.0, -1.4, -14.5), Vector3(2.8, 4.2, 1.6), Color(0.34, 0.52, 0.42)],
		[Vector3( -6.5, -1.8, -11.5), Vector3(1.9, 2.3, 1.3), Color(0.41, 0.58, 0.40)]
	]:
		var m := MeshInstance3D.new()
		m.mesh = hill_mesh
		m.position = ml[0]
		m.scale = ml[1]
		var mmat := StandardMaterial3D.new()
		mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mmat.albedo_color = ml[2]
		m.material_override = mmat
		scenery.add_child(m)

	# 3. Rumah Onsen Kayu Jepang + Gerbang Torii + Kolam Onsen + Rumpun Bambu (VS C++)
	var onsen := MeshInstance3D.new()
	onsen.mesh = load("res://assets/generated/models/prop_onsen_house.obj")
	onsen.position = Vector3(-5.8, -0.35, -8.6)
	onsen.rotation_degrees = Vector3(0.0, 16.0, 0.0)
	onsen.scale = Vector3.ONE * 1.18
	_apply_rovio_model_materials(onsen)
	scenery.add_child(onsen)

	var torii := MeshInstance3D.new()
	torii.mesh = load("res://assets/generated/models/prop_torii_gate.obj")
	torii.position = Vector3(11.6, -0.25, -8.4)
	torii.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	torii.scale = Vector3.ONE * 1.12
	_apply_rovio_model_materials(torii, Color(0.84, 0.44, 0.36))
	scenery.add_child(torii)

	var pond := MeshInstance3D.new()
	var pnd := CylinderMesh.new()
	pnd.top_radius = 4.6
	pnd.bottom_radius = 4.6
	pnd.height = 0.16
	pond.mesh = pnd
	pond.position = Vector3(10.6, -0.05, -7.8)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.52, 0.78, 0.74)
	pond.material_override = pmat
	scenery.add_child(pond)

	var cloud_mesh: Mesh = load("res://assets/generated/models/prop_cloud_fluffy.obj")
	var st_mat := StandardMaterial3D.new()
	st_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	st_mat.albedo_color = Color(0.98, 0.96, 0.90, 0.22)
	for i in 6:
		var puff := MeshInstance3D.new()
		puff.mesh = cloud_mesh
		puff.material_override = st_mat
		var base := Vector3(8.8 + float(i) * 0.75, 0.55, -7.6 + sin(float(i)) * 0.8)
		puff.position = base
		scenery.add_child(puff)
		steam_puffs.append({ "node": puff, "base": base, "phase": float(i) * 0.9 })

	var grove_mesh: Mesh = load("res://assets/generated/models/prop_bamboo_grove.obj")
	for bg_cfg in [
		[Vector3(-18.5, 0.1, -6.2), Vector3(0.0, 14.0, -3.0), 1.95],
		[Vector3( 17.5, 0.1, -6.2), Vector3(0.0, -158.0, 3.0), 1.95]
	]:
		var grove := MeshInstance3D.new()
		grove.mesh = grove_mesh
		grove.position = bg_cfg[0]
		grove.rotation_degrees = bg_cfg[1]
		grove.scale = Vector3.ONE * float(bg_cfg[2])
		_apply_rovio_model_materials(grove, Color(0.78, 0.84, 0.64))
		scenery.add_child(grove)

	for cp in [Vector3(-16.5, 8.2, -16.0), Vector3(16.0, 8.4, -16.5), Vector3(-1.5, 9.8, -19.0)]:
		var cl := MeshInstance3D.new()
		cl.mesh = cloud_mesh
		cl.position = cp
		cl.scale = Vector3(2.6, 1.8, 1.3)
		var cmat := _make_rovio_mat(null, Color(0.98, 0.96, 0.92), Vector2.ONE, 0.18, 0.04)
		cmat.set_shader_parameter("shadow_tint", Vector3(0.68, 0.72, 0.78))
		cmat.set_shader_parameter("rim_color", Vector3(1.0, 0.99, 0.96))
		cl.material_override = cmat
		scenery.add_child(cl)

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaf_mat.albedo_color = Color(0.56, 0.70, 0.36)
	for i in 8:
		var lf := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 0.022, 0.08)
		lf.mesh = bm
		lf.material_override = leaf_mat
		var st := Vector3(-16.0 + float(i) * 4.2, 2.6 + fmod(float(i) * 1.7, 5.2), -2.8 + sin(float(i)) * 2.0)
		lf.position = st
		scenery.add_child(lf)
		bg_leaves.append({ "node": lf, "base": st, "phase": float(i) * 1.1 })

func _setup_slingshot() -> void:
	slingshot_visual = Node3D.new()
	slingshot_visual.position = Vector3(sling_x, sling_base_y, 0.0)
	add_child(slingshot_visual)

	var sling_mi := MeshInstance3D.new()
	sling_mi.mesh = mesh_slingshot
	_apply_rovio_model_materials(sling_mi)
	slingshot_visual.add_child(sling_mi)

	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.32, 0.16, 0.08)
	band_mesh_a = _create_band_cyl(band_mat)
	band_mesh_b = _create_band_cyl(band_mat)
	add_child(band_mesh_a)
	add_child(band_mesh_b)

func _create_band_cyl(mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.036
	cm.bottom_radius = 0.036
	cm.height = 1.0
	mi.mesh = cm
	mi.material_override = mat
	return mi

func _setup_trajectory_dots() -> void:
	var dot_mat := StandardMaterial3D.new()
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.albedo_color = Color(0.98, 0.94, 0.78)
	for i in 30:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = lerp(0.115, 0.042, float(i) / 29.0)
		sm.height = sm.radius * 2.0
		mi.mesh = sm
		mi.material_override = dot_mat
		mi.visible = false
		add_child(mi)
		traj_dots.append(mi)

func _make_lacquer_sb() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/generated/home2d/ui_panel_lacquer.png")
	sb.texture_margin_left = 20
	sb.texture_margin_right = 20
	sb.texture_margin_top = 18
	sb.texture_margin_bottom = 18
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

func _add_hud_bevel(_panel: Control, _col: Color = Color.WHITE) -> void:
	pass

func _setup_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# 0) 3D-Projected Diegetic Cues Layer (behind floating HUD stamps)
	diegetic_overlay = DiegeticOverlay.new()
	diegetic_overlay.runner = self
	diegetic_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	diegetic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(diegetic_overlay)

	# 1) TOP-LEFT: Bare Carved Wood Action Stamps + Angular Camera Angle Tabs
	var tl_row := HBoxContainer.new()
	tl_row.position = Vector2(18, 14)
	tl_row.add_theme_constant_override("separation", 8)
	canvas.add_child(tl_row)

	var btn_map := CraftUI.make_icon_stamp("icon_pause", "wood_sq_bamboo", Vector2(46, 44), -2.0)
	btn_map.pressed.connect(_toggle_pause)
	tl_row.add_child(btn_map)

	var btn_restart := CraftUI.make_icon_stamp("icon_retry", "wood_sq_amber", Vector2(46, 44), 1.8, "R")
	btn_restart.pressed.connect(_request_restart_stage)
	tl_row.add_child(btn_restart)

	var cam_spacer := Control.new()
	cam_spacer.custom_minimum_size = Vector2(4, 1)
	tl_row.add_child(cam_spacer)

	btn_views.clear()
	var view_names := ["1 • 2.5D", "2 • SERONG", "3 • 3D"]
	var view_tilts := [-1.2, 0.8, -0.8]
	for i in 3:
		var b := CraftUI.make_wood_btn(view_names[i], "wood_btn_cedar_dark", Vector2(88, 38), 13, view_tilts[i])
		b.toggle_mode = true
		var idx := i
		b.pressed.connect(func(): _set_camera_view(idx))
		tl_row.add_child(b)
		btn_views.append(b)

	# 2) TOP-CENTER: Arcade Segmented Boss Meter (visible on Boss stages!)
	boss_bar_root = Control.new()
	boss_bar_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_bar_root.offset_left = -190
	boss_bar_root.offset_right = 190
	boss_bar_root.offset_top = 10
	boss_bar_root.offset_bottom = 68
	boss_bar_root.visible = false
	boss_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(boss_bar_root)

	var boss_title := CraftUI.make_stroked_label("BENTENG AGUNG KLAN BUAYA", 17, CraftUI.GOLD_TEXT, 5, true)
	boss_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar_root.add_child(boss_title)

	var boss_track_wrap := Control.new()
	boss_track_wrap.position = Vector2(54, 26)
	boss_track_wrap.size = Vector2(268, 22)
	boss_bar_root.add_child(boss_track_wrap)

	var track_bg := ColorRect.new()
	track_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_bg.color = CraftUI.INK
	boss_track_wrap.add_child(track_bg)

	var seg_hb := HBoxContainer.new()
	seg_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	seg_hb.offset_left = 3
	seg_hb.offset_right = -3
	seg_hb.offset_top = 3
	seg_hb.offset_bottom = -3
	seg_hb.add_theme_constant_override("separation", 2)
	boss_track_wrap.add_child(seg_hb)

	boss_segments.clear()
	for _k in 5:
		var seg := ColorRect.new()
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.color = Color(0.91, 0.22, 0.16)
		seg_hb.add_child(seg)
		boss_segments.append(seg)

	var boss_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_croc_boss"), Vector2(44, 44))
	boss_ic.position = Vector2(22, 16)
	boss_bar_root.add_child(boss_ic)

	lbl_boss_hp = CraftUI.make_stroked_label("5/5", 16, CraftUI.CREAM_TEXT, 4, true)
	lbl_boss_hp.position = Vector2(328, 25)
	boss_bar_root.add_child(lbl_boss_hp)

	# 3) TOP-RIGHT: Bare Floating Arcade Score, 3-Star Progress Bar & Croc Target Icon (NO box/pill!)
	var tr_wrap := HBoxContainer.new()
	tr_wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr_wrap.offset_left = -360
	tr_wrap.offset_right = -24
	tr_wrap.offset_top = 10
	tr_wrap.offset_bottom = 86
	tr_wrap.alignment = BoxContainer.ALIGNMENT_END
	tr_wrap.add_theme_constant_override("separation", 18)
	tr_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tr_wrap)

	var tr_left := VBoxContainer.new()
	tr_left.add_theme_constant_override("separation", 1)
	tr_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr_wrap.add_child(tr_left)

	lbl_stage_title = CraftUI.make_stroked_label("W1 1-1 • GERBANG LEMBAH BAMBU", 12, Color(1.0, 0.97, 0.88), 4, false)
	lbl_stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_left.add_child(lbl_stage_title)

	lbl_score = CraftUI.make_stroked_label("00,000", 34, CraftUI.GOLD_TEXT, 6, true)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_left.add_child(lbl_score)

	var bar_row := HBoxContainer.new()
	bar_row.alignment = BoxContainer.ALIGNMENT_END
	bar_row.add_theme_constant_override("separation", 4)
	tr_left.add_child(bar_row)

	score_star_bar = ProgressBar.new()
	score_star_bar.custom_minimum_size = Vector2(104, 10)
	score_star_bar.show_percentage = false
	var ssb_bg := StyleBoxFlat.new()
	ssb_bg.bg_color = Color(0.23, 0.11, 0.07)
	ssb_bg.border_color = CraftUI.INK
	ssb_bg.set_border_width_all(2)
	ssb_bg.set_corner_radius_all(3)
	var ssb_fill := StyleBoxFlat.new()
	ssb_fill.bg_color = Color(1.0, 0.83, 0.15)
	ssb_fill.set_corner_radius_all(2)
	score_star_bar.add_theme_stylebox_override("background", ssb_bg)
	score_star_bar.add_theme_stylebox_override("fill", ssb_fill)
	bar_row.add_child(score_star_bar)

	hud_star_pips.clear()
	for _k in 3:
		var sp := TextureRect.new()
		sp.texture = CraftUI.tex("icon_star_empty")
		sp.custom_minimum_size = Vector2(18, 18)
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bar_row.add_child(sp)
		hud_star_pips.append(sp)

	var enemy_box := HBoxContainer.new()
	enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_box.add_theme_constant_override("separation", 5)
	tr_wrap.add_child(enemy_box)

	var croc_ic := TextureRect.new()
	croc_ic.texture = CraftUI.tex("icon_croc_target")
	croc_ic.custom_minimum_size = Vector2(34, 34)
	croc_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	croc_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_box.add_child(croc_ic)

	lbl_enemy_pill = CraftUI.make_stroked_label("×2", 28, CraftUI.CREAM_TEXT, 6, true)
	enemy_box.add_child(lbl_enemy_pill)

	# Bare Floating Combo Text (NO vermilion pill box!)
	lbl_combo = CraftUI.make_stroked_label("", 22, Color(1.0, 0.45, 0.25), 5, true)
	lbl_combo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl_combo.offset_left = -240
	lbl_combo.offset_right = -24
	lbl_combo.offset_top = 88
	lbl_combo.offset_bottom = 118
	lbl_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_combo.visible = false
	canvas.add_child(lbl_combo)

	# 4) BOTTOM-LEFT: Bare Floating Active Hero Cutout + Skill Name + Keycap + Tilted Queue Cutouts
	var bl_wrap := HBoxContainer.new()
	bl_wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bl_wrap.offset_left = 20
	bl_wrap.offset_right = 760
	bl_wrap.offset_top = -80
	bl_wrap.offset_bottom = -14
	bl_wrap.add_theme_constant_override("separation", 12)
	bl_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bl_wrap)

	var hero_frame := Control.new()
	hero_frame.custom_minimum_size = Vector2(66, 66)
	hero_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl_wrap.add_child(hero_frame)

	active_hero_wood_bg = ColorRect.new()
	active_hero_wood_bg.position = Vector2(5, 6)
	active_hero_wood_bg.size = Vector2(56, 56)
	active_hero_wood_bg.pivot_offset = Vector2(28, 28)
	active_hero_wood_bg.rotation_degrees = -5.0
	active_hero_wood_bg.color = CraftUI.INK
	hero_frame.add_child(active_hero_wood_bg)

	var inner_sq := ColorRect.new()
	inner_sq.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_sq.offset_left = 4
	inner_sq.offset_right = -4
	inner_sq.offset_top = 4
	inner_sq.offset_bottom = -4
	inner_sq.color = Color(0.92, 0.28, 0.19)
	active_hero_wood_bg.add_child(inner_sq)
	active_hero_wood_bg.set_meta("inner_sq", inner_sq)

	active_hero_portrait = TextureRect.new()
	active_hero_portrait.position = Vector2(0, -4)
	active_hero_portrait.size = Vector2(66, 66)
	active_hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	active_hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	active_hero_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_frame.add_child(active_hero_portrait)

	var bl_col := VBoxContainer.new()
	bl_col.alignment = BoxContainer.ALIGNMENT_END
	bl_col.add_theme_constant_override("separation", 4)
	bl_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl_wrap.add_child(bl_col)

	var skill_hb := HBoxContainer.new()
	skill_hb.alignment = BoxContainer.ALIGNMENT_BEGIN
	skill_hb.add_theme_constant_override("separation", 8)
	bl_col.add_child(skill_hb)

	active_skill_lbl = CraftUI.make_stroked_label("ZEN BUMP", 20, CraftUI.GOLD_TEXT, 5, true)
	skill_hb.add_child(active_skill_lbl)
	skill_hb.add_child(CraftUI.make_keycap("SPASI", 66.0, 30.0, 12))

	hud_squad_row = HBoxContainer.new()
	hud_squad_row.add_theme_constant_override("separation", 6)
	bl_col.add_child(hud_squad_row)

	# 5) BOTTOM-RIGHT: Minimal Bare Camera Pan Keycaps
	var cam_hint := HBoxContainer.new()
	cam_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cam_hint.offset_left = -220
	cam_hint.offset_right = -20
	cam_hint.offset_top = -44
	cam_hint.offset_bottom = -12
	cam_hint.alignment = BoxContainer.ALIGNMENT_END
	cam_hint.add_theme_constant_override("separation", 6)
	cam_hint.modulate.a = 0.88
	cam_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(cam_hint)

	cam_hint.add_child(CraftUI.make_keycap("A", 32.0, 30.0, 12))
	cam_hint.add_child(CraftUI.make_stroked_label("◀ KAMERA ▶", 12, Color(1.0, 0.97, 0.86), 4, false))
	cam_hint.add_child(CraftUI.make_keycap("D", 32.0, 30.0, 12))

	# 6) RESULT OVERLAY (Wood-Framed Parchment Modal)
	result_overlay = ColorRect.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.06, 0.04, 0.03, 0.74)
	result_overlay.visible = false
	canvas.add_child(result_overlay)

	var rpanel := PanelContainer.new()
	rpanel.set_anchors_preset(Control.PRESET_CENTER)
	rpanel.offset_left = -310
	rpanel.offset_right = 310
	rpanel.offset_top = -220
	rpanel.offset_bottom = 220
	rpanel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style(50.0, 42.0))
	result_overlay.add_child(rpanel)

	var rvb := VBoxContainer.new()
	rvb.alignment = BoxContainer.ALIGNMENT_CENTER
	rvb.add_theme_constant_override("separation", 10)
	rpanel.add_child(rvb)

	result_badge_lbl = CraftUI.make_stroked_label("MENANG!", 15, Color(0.95, 0.27, 0.18), 3, true)
	result_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rvb.add_child(result_badge_lbl)

	result_title = CraftUI.make_stroked_label("STAGE SELESAI!", 26, CraftUI.GOLD_TEXT, 5, true)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rvb.add_child(result_title)

	var star_hb := HBoxContainer.new()
	star_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hb.add_theme_constant_override("separation", 16)
	rvb.add_child(star_hb)

	result_star_labels.clear()
	for _k in 3:
		var rsl := TextureRect.new()
		rsl.texture = CraftUI.tex("icon_star_empty")
		rsl.custom_minimum_size = Vector2(48, 48)
		rsl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rsl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_hb.add_child(rsl)
		result_star_labels.append(rsl)

	result_stars = Label.new()
	result_stars.visible = false
	rvb.add_child(result_stars)

	result_body = Label.new()
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.add_theme_font_override("font", CraftUI.body_font())
	result_body.add_theme_font_size_override("font_size", 15)
	result_body.add_theme_color_override("font_color", CraftUI.INK)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	rvb.add_child(result_body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	rvb.add_child(btn_row)

	btn_retry = CraftUI.make_wood_btn("ULANGI", "wood_btn_amber", Vector2(124, 46), 17, -1.0)
	btn_retry.pressed.connect(func(): _load_stage(current_stage_id))
	btn_row.add_child(btn_retry)

	btn_next_stage = CraftUI.make_wood_btn("LANJUT ▶", "wood_btn_vermilion", Vector2(168, 48), 19, 1.0)
	btn_next_stage.pressed.connect(_go_next_stage)
	btn_row.add_child(btn_next_stage)

	var btn_back := CraftUI.make_wood_btn("PETA", "wood_btn_bamboo", Vector2(110, 46), 17, 0.5)
	btn_back.pressed.connect(func(): SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE))
	btn_row.add_child(btn_back)

	var res_home_wrap := CenterContainer.new()
	rvb.add_child(res_home_wrap)
	var btn_res_home := CraftUI.make_wood_btn("MENU UTAMA", "wood_btn_slate", Vector2(172, 42), 15, 0.0)
	btn_res_home.pressed.connect(func(): SceneLoader.quick_transition_to(HOME_SCENE))
	res_home_wrap.add_child(btn_res_home)

func _setup_pause_menu() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 20
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	pause_overlay = ColorRect.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0.05, 0.03, 0.02, 0.74)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	pause_layer.add_child(pause_overlay)

	var catcher := PauseInputCatcher.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catcher.on_resume_key = func(): _set_paused(false)
	pause_overlay.add_child(catcher)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 488)
	panel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style(50.0, 40.0))
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	var hdr := CraftUI.make_stroked_label("PERMAINAN DIJEDA", 30, CraftUI.GOLD_TEXT, 6, true)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hdr)

	pause_stage_lbl = Label.new()
	pause_stage_lbl.text = "W1 1-1 • STAGE"
	pause_stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_stage_lbl.add_theme_font_override("font", CraftUI.display_font())
	pause_stage_lbl.add_theme_font_size_override("font_size", 16)
	pause_stage_lbl.add_theme_color_override("font_color", Color(0.68, 0.17, 0.10))
	vb.add_child(pause_stage_lbl)

	pause_stats_lbl = Label.new()
	pause_stats_lbl.text = "Skor: 00,000  •  Buaya Tersisa: 1"
	pause_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_stats_lbl.add_theme_font_override("font", CraftUI.body_font())
	pause_stats_lbl.add_theme_font_size_override("font_size", 14)
	pause_stats_lbl.add_theme_color_override("font_color", CraftUI.INK)
	vb.add_child(pause_stats_lbl)

	var sep1 := ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 3)
	sep1.color = Color(0.62, 0.37, 0.14, 0.35)
	vb.add_child(sep1)

	# Audio Row
	var r_audio := HBoxContainer.new()
	r_audio.add_theme_constant_override("separation", 10)
	r_audio.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(r_audio)

	pause_audio_icon = CraftUI.make_tex_rect(CraftUI.tex("icon_speaker_on"), Vector2(28, 28))
	r_audio.add_child(pause_audio_icon)

	var lbl_s := Label.new()
	lbl_s.text = "Suara"
	lbl_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_s.add_theme_font_override("font", CraftUI.body_font())
	lbl_s.add_theme_font_size_override("font_size", 15)
	lbl_s.add_theme_color_override("font_color", CraftUI.INK)
	r_audio.add_child(lbl_s)

	pause_vol_slider = CraftUI.make_volume_slider(SaveManager.audio_volume, 195.0)
	pause_vol_slider.value_changed.connect(func(v: float):
		SaveManager.set_audio_volume(v)
		_sync_pause_controls()
	)
	r_audio.add_child(pause_vol_slider)

	pause_vol_pct = Label.new()
	pause_vol_pct.text = "100%"
	pause_vol_pct.custom_minimum_size = Vector2(46, 0)
	pause_vol_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_vol_pct.add_theme_font_override("font", CraftUI.display_font())
	pause_vol_pct.add_theme_font_size_override("font_size", 15)
	pause_vol_pct.add_theme_color_override("font_color", CraftUI.INK)
	r_audio.add_child(pause_vol_pct)

	pause_btn_mute = CraftUI.make_wood_btn("AKTIF", "wood_btn_bamboo", Vector2(102, 38), 14, 0.0)
	pause_btn_mute.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause_btn_mute.pressed.connect(func():
		SaveManager.toggle_mute()
		_sync_pause_controls()
	)
	r_audio.add_child(pause_btn_mute)

	# Display Row
	var r_disp := HBoxContainer.new()
	r_disp.add_theme_constant_override("separation", 10)
	r_disp.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(r_disp)

	r_disp.add_child(CraftUI.make_tex_rect(CraftUI.tex("icon_gear"), Vector2(28, 28)))

	var lbl_d := Label.new()
	lbl_d.text = "Tampilan Layar"
	lbl_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_d.add_theme_font_override("font", CraftUI.body_font())
	lbl_d.add_theme_font_size_override("font_size", 15)
	lbl_d.add_theme_color_override("font_color", CraftUI.INK)
	r_disp.add_child(lbl_d)

	pause_btn_disp = CraftUI.make_wood_btn("JENDELA", "wood_btn_cedar", Vector2(184, 40), 15, 0.0)
	pause_btn_disp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause_btn_disp.pressed.connect(func():
		SaveManager.toggle_fullscreen()
		_sync_pause_controls()
	)
	r_disp.add_child(pause_btn_disp)

	var sep2 := ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 3)
	sep2.color = Color(0.62, 0.37, 0.14, 0.35)
	vb.add_child(sep2)

	# Primary Resume Button
	var resume_wrap := CenterContainer.new()
	vb.add_child(resume_wrap)
	var btn_resume := CraftUI.make_wood_btn("LANJUTKAN", "wood_btn_vermilion", Vector2(340, 52), 21, -0.6, "icon_play_tri", 20)
	btn_resume.pressed.connect(func(): _set_paused(false))
	resume_wrap.add_child(btn_resume)

	# Secondary Row: Restart + World 1 Map
	var mid_row := HBoxContainer.new()
	mid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_row.add_theme_constant_override("separation", 14)
	vb.add_child(mid_row)

	var btn_p_restart := CraftUI.make_wood_btn("ULANG STAGE", "wood_btn_amber", Vector2(174, 46), 16, -0.8, "icon_retry", 18)
	btn_p_restart.pressed.connect(_request_restart_stage)
	mid_row.add_child(btn_p_restart)

	var btn_p_map := CraftUI.make_wood_btn("PETA STAGE", "wood_btn_bamboo", Vector2(174, 46), 16, 0.8, "icon_map", 18)
	btn_p_map.pressed.connect(_request_exit_to_map)
	mid_row.add_child(btn_p_map)

	# Bottom Row: Main Menu
	var bot_wrap := CenterContainer.new()
	vb.add_child(bot_wrap)
	var btn_p_home := CraftUI.make_wood_btn("MENU UTAMA", "wood_btn_slate", Vector2(180, 42), 15, 0.0)
	btn_p_home.pressed.connect(_request_exit_to_home)
	bot_wrap.add_child(btn_p_home)

func _cancel_active_aim() -> void:
	if is_aiming:
		is_aiming = false
		pull_vector = Vector3.ZERO
		_hide_trajectory()
		if is_instance_valid(active_capy):
			active_capy.position = Vector3(launch_x, launch_y, 0.0)

func _request_restart_stage() -> void:
	if stage_ended:
		return
	_cancel_active_aim()
	CraftUI.show_confirm_modal(
		get_tree(),
		"ULANG STAGE %s?" % current_stage_id,
		"Skor dan tembakan pada percobaan ini akan direset dari awal.\nYakin ingin mengulang stage?",
		"YA, ULANG",
		func():
			_set_paused(false)
			_load_stage(current_stage_id),
		"BATAL",
		true
	)

func _request_exit_to_map() -> void:
	CraftUI.show_confirm_modal(
		get_tree(),
		"KELUAR KE PETA?",
		"Stage %s belum selesai dan progres tembakan saat ini akan hilang.\nYakin ingin kembali ke Peta World 1?" % current_stage_id,
		"YA, KELUAR",
		func():
			_set_paused(false)
			SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE),
		"BATAL",
		true
	)

func _request_exit_to_home() -> void:
	CraftUI.show_confirm_modal(
		get_tree(),
		"KE MENU UTAMA?",
		"Stage %s belum selesai dan progres tembakan saat ini akan hilang.\nYakin ingin kembali ke Menu Utama?" % current_stage_id,
		"YA, KELUAR",
		func():
			_set_paused(false)
			SceneLoader.quick_transition_to(HOME_SCENE),
		"BATAL",
		true
	)

func _toggle_pause() -> void:
	if stage_ended:
		return
	_set_paused(not is_paused)

func _set_paused(paused: bool) -> void:
	if paused and stage_ended:
		return
	is_paused = paused
	if paused:
		_cancel_active_aim()
		_sync_pause_controls()
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = paused
	if get_tree():
		get_tree().paused = paused

func _sync_pause_controls() -> void:
	if is_instance_valid(pause_stage_lbl):
		pause_stage_lbl.text = ("W1 %s • %s" % [current_stage_id, str(stage_data.get("name", current_stage_id))]).to_upper()
	if is_instance_valid(pause_stats_lbl):
		pause_stats_lbl.text = "Skor: %s  •  Buaya Tersisa: %d" % [CraftUI.format_score(score), enemies.size()]
	if is_instance_valid(pause_vol_slider) and absf(pause_vol_slider.value - SaveManager.audio_volume) > 0.5:
		pause_vol_slider.set_value_no_signal(SaveManager.audio_volume)
	if is_instance_valid(pause_vol_pct):
		pause_vol_pct.text = "%d%%" % int(round(SaveManager.audio_volume))
	if is_instance_valid(pause_audio_icon):
		pause_audio_icon.texture = CraftUI.tex("icon_speaker_off" if SaveManager.is_muted else "icon_speaker_on")
	if is_instance_valid(pause_btn_mute):
		pause_btn_mute.text = "BISU" if SaveManager.is_muted else "AKTIF"
		CraftUI.style_wood_button(pause_btn_mute, "wood_btn_slate" if SaveManager.is_muted else "wood_btn_bamboo", 14, Vector2(102, 38), 0.0)
	if is_instance_valid(pause_btn_disp):
		pause_btn_disp.text = "LAYAR PENUH" if SaveManager.is_fullscreen() else "JENDELA"

func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false

func _make_hud_btn(txt: String, is_primary: bool) -> Button:
	return CraftUI.make_wood_btn(txt, "wood_btn_vermilion" if is_primary else "wood_btn_cedar", Vector2(115, 44), 16, 0.0)

func _style_hud_btn(b: Button, is_primary: bool) -> void:
	CraftUI.style_wood_button(b, "wood_btn_vermilion" if is_primary else "wood_btn_amber", 18, b.custom_minimum_size, b.rotation_degrees)

# =========================================================================
# JSON STAGE LOADER & SPAWNER
# =========================================================================

func _load_stage(stage_id: String) -> void:
	if is_paused:
		_set_paused(false)
	current_stage_id = stage_id
	SaveManager.selected_stage_id = stage_id

	for c in arena_root.get_children():
		c.queue_free()
	for c in queue_visual_root.get_children():
		c.queue_free()

	blocks.clear()
	enemies.clear()
	bounce_pads.clear()
	flying_projectiles.clear()
	vfx_nodes.clear()
	floating_texts.clear()
	shake_trauma = 0.0
	active_capy = null
	active_capy_visual = null
	is_aiming = false
	is_flying = false
	shot_fired = false
	skill_used = false
	flight_timer = 0.0
	settle_timer = 0.0
	spawn_grace = 0.65
	score = 0
	combo_count = 0
	combo_timer = 0.0
	stage_ended = false
	pending_victory = false
	pending_defeat = false
	end_delay_timer = 0.0
	cam_pan_x = 0.0
	cam_pan_target_x = 0.0
	snap_camera = true
	result_overlay.visible = false
	_hide_trajectory()

	var path := "res://data/levels/w1/%s.json" % stage_id
	if not FileAccess.file_exists(path):
		push_error("Stage JSON not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		push_error("Invalid stage JSON: " + path)
		return
	stage_data = parsed

	# Posisi ketapel dinamis per stage (bisa di atas tebing tinggi atau lembah rendah!)
	var sp_raw: Array = stage_data.get("slingshot_pos", [-9.5, 0.0])
	sling_x = float(sp_raw[0])
	sling_base_y = float(sp_raw[1])
	launch_x = sling_x
	launch_y = sling_base_y + 1.75
	if is_instance_valid(slingshot_visual):
		slingshot_visual.position = Vector3(sling_x, sling_base_y, 0.0)

	stage_min_x = sling_x - 3.0
	stage_max_x = sling_x + 22.0
	stage_max_y = maxf(sling_base_y + 3.5, 4.5)

	capy_queue.clear()
	var q_raw: Array = stage_data.get("queue", ["chill"])
	for item in q_raw:
		capy_queue.append(str(item))

	var t_raw: Array = stage_data.get("terrain", [])
	for t_def in t_raw:
		_spawn_terrain_from_def(t_def)

	var bp_raw: Array = stage_data.get("bounce_pads", [])
	for bp_def in bp_raw:
		_spawn_bounce_pad_from_def(bp_def)

	var b_raw: Array = stage_data.get("blocks", [])
	for b_def in b_raw:
		_spawn_block_from_def(b_def)

	var e_raw: Array = stage_data.get("enemies", [])
	for e_def in e_raw:
		_spawn_enemy_from_def(e_def)

	lbl_stage_title.text = ("W1 %s • %s" % [stage_id, str(stage_data.get("name", stage_id))]).to_upper()
	var has_boss := (stage_id == "1-20")
	if not has_boss:
		for e in enemies:
			if str(e["type"]) == "mini_boss":
				has_boss = true
				break
	if is_instance_valid(boss_bar_root):
		boss_bar_root.visible = has_boss
	_load_next_capy_onto_slingshot()
	_refresh_score_hud()

func _spawn_terrain_from_def(def: Dictionary) -> void:
	var pos_arr: Array = def.get("pos", [0.0, 0.5])
	var sz_arr: Array = def.get("size", [3.0, 1.5, 2.2])
	var rot_deg: float = float(def.get("rot", 0.0))
	var style: String = str(def.get("style", "cliff"))
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), 0.0)
	var sz := Vector3(float(sz_arr[0]), float(sz_arr[1]), float(sz_arr[2]))

	var rad: float = deg_to_rad(rot_deg)
	var half_x: float = absf(sz.x * 0.5 * cos(rad)) + absf(sz.y * 0.5 * sin(rad))
	var half_y: float = absf(sz.x * 0.5 * sin(rad)) + absf(sz.y * 0.5 * cos(rad))
	stage_min_x = minf(stage_min_x, pos.x - half_x - 0.3)
	stage_max_x = maxf(stage_max_x, pos.x + half_x + 0.3)
	stage_max_y = maxf(stage_max_y, pos.y + half_y + 0.3)

	var sb := StaticBody3D.new()
	sb.position = pos
	sb.rotation_degrees = Vector3(0.0, 0.0, rot_deg)
	sb.set_meta("kind", "ground")

	var pm := PhysicsMaterial.new()
	pm.friction = 0.65 if absf(rot_deg) < 5.0 else 0.14
	pm.bounce = 0.04
	sb.physics_material_override = pm

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape
	sb.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	if style == "wood_deck":
		mi.material_override = _make_rovio_mat(tex_wood, Color(0.68, 0.54, 0.40), Vector2(maxf(1.0, sz.x * 0.45), 1.0), 0.10, 0.06)
	elif style == "stone_wall":
		mi.material_override = _make_rovio_mat(tex_stone, Color(0.76, 0.78, 0.80), Vector2(maxf(1.0, sz.x * 0.4), maxf(1.0, sz.y * 0.4)), 0.12, 0.08)
	else:
		mi.material_override = _make_rovio_mat(tex_cliff, Color(0.72, 0.60, 0.50), Vector2(maxf(1.0, sz.x * 0.45), maxf(1.0, sz.y * 0.45)), 0.08, 0.04)
		# Lapisan rumput lumut hijau di puncak tebing batu (ala tebing Angry Birds!)
		if absf(rot_deg) <= 36.0:
			var cap := MeshInstance3D.new()
			var cbm := BoxMesh.new()
			cbm.size = Vector3(sz.x + 0.08, minf(0.24, sz.y * 0.35), sz.z + 0.06)
			cap.mesh = cbm
			cap.position = Vector3(0.0, sz.y * 0.5 - cbm.size.y * 0.35, 0.0)
			var cap_mat := _make_rovio_mat(tex_moss, Color(0.68, 0.82, 0.52), Vector2(maxf(1.0, sz.x * 0.5), 1.0), 0.14, 0.06)
			cap_mat.set_shader_parameter("shadow_tint", Vector3(0.34, 0.46, 0.34))
			cap.material_override = cap_mat
			sb.add_child(cap)
	sb.add_child(mi)
	arena_root.add_child(sb)

func _spawn_bounce_pad_from_def(def: Dictionary) -> void:
	var pos_arr: Array = def.get("pos", [0.0, 0.25])
	var sz_arr: Array = def.get("size", [1.5, 0.34, 1.0])
	var rot_deg: float = float(def.get("rot", 0.0))
	var power: float = float(def.get("power", 16.5))
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), 0.0)
	var sz := Vector3(float(sz_arr[0]), float(sz_arr[1]), float(sz_arr[2]))

	stage_min_x = minf(stage_min_x, pos.x - sz.x * 0.6)
	stage_max_x = maxf(stage_max_x, pos.x + sz.x * 0.6)
	stage_max_y = maxf(stage_max_y, pos.y + sz.y * 0.6 + 0.4)

	var sb := StaticBody3D.new()
	sb.position = pos
	sb.rotation_degrees = Vector3(0.0, 0.0, rot_deg)
	sb.set_meta("kind", "bounce_pad")
	sb.set_meta("bounce_power", power)

	var pm := PhysicsMaterial.new()
	pm.friction = 0.08
	pm.bounce = 0.92
	sb.physics_material_override = pm

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape
	sb.add_child(col)

	# Visual Drum Taiko Onsen (bantalan pegas merah-krem + pinggiran emas!)
	var vis := Node3D.new()
	sb.add_child(vis)

	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	base.mesh = bm
	base.material_override = _make_rovio_mat(null, Color(0.84, 0.22, 0.28), Vector2.ONE, 0.26, 0.22)
	vis.add_child(base)

	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(sz.x * 0.88, sz.y * 0.42, sz.z * 0.88)
	top.mesh = tm
	top.position = Vector3(0.0, sz.y * 0.36, 0.0)
	top.material_override = _make_rovio_mat(null, Color(0.98, 0.88, 0.56), Vector2.ONE, 0.22, 0.28)
	vis.add_child(top)

	var pad_rec := { "sb": sb, "vis": vis, "pulse_t": 0.0 }
	sb.set_meta("pad_rec", pad_rec)
	bounce_pads.append(pad_rec)

	arena_root.add_child(sb)

func _spawn_block_from_def(def: Dictionary) -> void:
	var btype: String = str(def.get("type", "bamboo"))
	var bshape: String = str(def.get("shape", "boulder" if btype == "boulder" else "box"))
	var pos_arr: Array = def.get("pos", [5.0, 0.8])
	var sz_arr: Array = def.get("size", [0.4, 1.5, 0.9])
	var rot_deg: float = float(def.get("rot", 0.0))
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), 0.0)
	var sz := Vector3(float(sz_arr[0]), float(sz_arr[1]), float(sz_arr[2]))

	var rot_rad: float = deg_to_rad(rot_deg)
	var half_x: float = absf(sz.x * 0.5 * cos(rot_rad)) + absf(sz.y * 0.5 * sin(rot_rad))
	var half_y: float = absf(sz.x * 0.5 * sin(rot_rad)) + absf(sz.y * 0.5 * cos(rot_rad))
	stage_min_x = minf(stage_min_x, pos.x - half_x - 0.3)
	stage_max_x = maxf(stage_max_x, pos.x + half_x + 0.3)
	stage_max_y = maxf(stage_max_y, pos.y + half_y + 0.6)

	var spec: Dictionary = MAT_SPECS.get(btype, MAT_SPECS["bamboo"])
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.rotation_degrees = Vector3(0.0, 0.0, rot_deg)
	rb.mass = float(spec["mass"])
	rb.axis_lock_linear_z = true
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_y = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 6
	rb.linear_damp = 0.06 if bshape == "boulder" else 0.25
	rb.angular_damp = 0.08 if bshape == "boulder" else 0.35

	var pm := PhysicsMaterial.new()
	if bshape == "boulder":
		pm.friction = 0.32
		pm.bounce = 0.14
	elif btype == "ice":
		pm.friction = 0.22
		pm.bounce = 0.04
	else:
		pm.friction = 0.74
		pm.bounce = 0.03
	rb.physics_material_override = pm

	var col := CollisionShape3D.new()
	var mi := MeshInstance3D.new()

	if bshape == "boulder":
		var rad: float = maxf(sz.x * 0.5, 0.35)
		var sp := SphereShape3D.new()
		sp.radius = rad
		col.shape = sp
		var sm := SphereMesh.new()
		sm.radius = rad
		sm.height = rad * 2.0
		mi.mesh = sm
	elif bshape == "wedge" or bshape == "roof":
		var skew: float = float(def.get("skew", 0.5))
		var pmsh := PrismMesh.new()
		pmsh.size = sz
		pmsh.left_to_right = skew
		mi.mesh = pmsh
		var hx: float = sz.x * 0.5
		var hy: float = sz.y * 0.5
		var hz: float = sz.z * 0.5
		var top_x: float = lerpf(-hx, hx, skew)
		var cvx := ConvexPolygonShape3D.new()
		cvx.points = PackedVector3Array([
			Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(top_x, hy, -hz),
			Vector3(-hx, -hy,  hz), Vector3(hx, -hy,  hz), Vector3(top_x, hy,  hz)
		])
		col.shape = cvx
	else:
		var shape := BoxShape3D.new()
		shape.size = sz
		col.shape = shape
		var bm := BoxMesh.new()
		bm.size = sz
		mi.mesh = bm

	rb.add_child(col)

	var mat: Material
	if btype == "ice":
		var imat := StandardMaterial3D.new()
		imat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		imat.albedo_color = Color(0.68, 0.90, 0.95, 0.76)
		imat.roughness = 0.14
		imat.metallic = 0.08
		imat.emission_enabled = true
		imat.emission = Color(0.36, 0.68, 0.78)
		imat.emission_energy_multiplier = 0.22
		mat = imat
	elif btype == "tnt":
		mat = _make_rovio_mat(tex_wood, Color(0.86, 0.24, 0.18), Vector2.ONE, 0.24, 0.20)
		var band := MeshInstance3D.new()
		var bbm := BoxMesh.new()
		bbm.size = Vector3(sz.x * 1.04, sz.y * 0.24, sz.z * 1.04)
		band.mesh = bbm
		band.material_override = _make_rovio_mat(null, Color(0.96, 0.78, 0.24), Vector2.ONE, 0.20, 0.25)
		rb.add_child(band)
	elif btype == "stone" or btype == "boulder":
		mat = _make_rovio_mat(tex_stone, Color(0.76, 0.78, 0.80), Vector2.ONE, 0.16, 0.12)
	elif btype == "yuzu_basket":
		mat = _make_rovio_mat(tex_wood, Color(0.74, 0.56, 0.36), Vector2.ONE, 0.18, 0.12)
		# 3 buah Jeruk Yuzu emas bertumpuk di atas keranjang bonus!
		var ymat := _make_rovio_mat(null, Color(0.98, 0.80, 0.20), Vector2.ONE, 0.28, 0.30)
		for yp in [Vector3(-0.14, sz.y * 0.45, 0.0), Vector3(0.14, sz.y * 0.45, 0.0), Vector3(0.0, sz.y * 0.68, 0.0)]:
			var orb := MeshInstance3D.new()
			var osm := SphereMesh.new()
			osm.radius = 0.14
			osm.height = 0.28
			orb.mesh = osm
			orb.position = yp
			orb.material_override = ymat
			rb.add_child(orb)
	elif btype == "wood":
		mat = _make_rovio_mat(tex_wood, Color(0.88, 0.76, 0.64), Vector2.ONE, 0.16, 0.10)
	else:
		mat = _make_rovio_mat(tex_bamboo, Color(0.82, 0.90, 0.70), Vector2.ONE, 0.16, 0.12)
	mi.material_override = mat
	rb.add_child(mi)

	var rec := {
		"rb": rb,
		"mi": mi,
		"type": btype,
		"hp": float(spec["hp"]),
		"max_hp": float(spec["hp"]),
		"thresh": float(spec["thresh"]),
		"score": int(spec["score"]),
		"last_vel": Vector3.ZERO,
		"dead": false
	}
	rb.set_meta("kind", "block")
	rb.set_meta("rec", rec)
	rb.body_entered.connect(func(other: Node): _on_body_impact(rec, other, false))

	arena_root.add_child(rb)
	blocks.append(rec)

func _spawn_enemy_from_def(def: Dictionary) -> void:
	var etype: String = str(def.get("type", "minion"))
	var pos_arr: Array = def.get("pos", [6.0, 0.4])
	var is_boss: bool = (etype == "mini_boss")
	var rad: float = 0.48 if is_boss else 0.36
	var hp: float = 92.0 if is_boss else 24.0
	var pts: int = 15000 if is_boss else 5000

	var rb := RigidBody3D.new()
	rb.position = Vector3(float(pos_arr[0]), float(pos_arr[1]), 0.0)
	stage_min_x = minf(stage_min_x, rb.position.x - rad - 0.5)
	stage_max_x = maxf(stage_max_x, rb.position.x + rad + 0.6)
	stage_max_y = maxf(stage_max_y, rb.position.y + rad + (1.0 if is_boss else 0.7))
	rb.mass = 1.85 if is_boss else 0.80
	rb.axis_lock_linear_z = true
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_y = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 8
	rb.linear_damp = 0.35
	rb.angular_damp = 0.45

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = rad
	col.shape = shape
	rb.add_child(col)

	var base_sc: float = 1.52 if is_boss else 1.12
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_croco
	mi.scale = Vector3.ONE * base_sc
	var base_tint := Color(0.95, 0.90, 0.76) if is_boss else Color.WHITE
	_apply_rovio_model_materials(mi, base_tint)
	rb.add_child(mi)

	# Mahkota Emas Yuzu untuk Mini-Boss Stage 1-20!
	if is_boss:
		var crown := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22
		cm.bottom_radius = 0.16
		cm.height = 0.20
		crown.mesh = cm
		crown.position = Vector3(-0.08, 0.56, 0.0)
		crown.material_override = _make_rovio_mat(null, Color(0.96, 0.78, 0.22), Vector2.ONE, 0.30, 0.35)
		rb.add_child(crown)

	var rec := {
		"rb": rb,
		"mi": mi,
		"type": etype,
		"hp": hp,
		"max_hp": hp,
		"thresh": 1.35 if is_boss else 0.75,
		"score": pts,
		"last_vel": Vector3.ZERO,
		"base_scale": base_sc,
		"base_tint": base_tint,
		"hurt_t": 0.0,
		"bruised": false,
		"phase": float(enemies.size()) * 1.4,
		"dead": false
	}
	rb.set_meta("kind", "enemy")
	rb.set_meta("rec", rec)
	rb.body_entered.connect(func(other: Node): _on_body_impact(rec, other, true))

	arena_root.add_child(rb)
	enemies.append(rec)

func _load_next_capy_onto_slingshot() -> void:
	if capy_queue.is_empty():
		active_capy = null
		active_capy_visual = null
		_rebuild_queue_visuals()
		_refresh_queue_hud()
		return

	active_capy_type = capy_queue.pop_front()
	var spec: Dictionary = CAPY_SPECS.get(active_capy_type, CAPY_SPECS["chill"])

	var rb := RigidBody3D.new()
	rb.position = Vector3(launch_x, launch_y, 0.0)
	rb.mass = float(spec["mass"])
	rb.freeze = true
	rb.continuous_cd = true
	rb.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	rb.linear_damp = 0.0
	rb.axis_lock_linear_z = true
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_y = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 6
	rb.set_meta("kind", "capy")
	rb.set_meta("capy_type", active_capy_type)
	rb.set_meta("last_vel", Vector3.ZERO)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = float(spec["radius"])
	col.shape = shape
	rb.add_child(col)

	var pivot := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = capy_meshes[active_capy_type]
	_apply_rovio_model_materials(mi)
	pivot.add_child(mi)
	rb.add_child(pivot)

	arena_root.add_child(rb)
	active_capy = rb
	active_capy_visual = pivot
	is_flying = false
	skill_used = false
	flight_timer = 0.0
	settle_timer = 0.0

	_rebuild_queue_visuals()
	_refresh_queue_hud()

func _rebuild_queue_visuals() -> void:
	for c in queue_visual_root.get_children():
		c.queue_free()
	var compact_spacing: float = 0.46 if capy_queue.size() > 3 else 0.68
	for i in capy_queue.size():
		var cid: String = capy_queue[i]
		var mi := MeshInstance3D.new()
		mi.mesh = capy_meshes.get(cid, capy_meshes["chill"])
		_apply_rovio_model_materials(mi)
		var z_off: float = 0.0
		if capy_queue.size() > 3:
			z_off = -0.24 if (i % 2 == 1) else 0.18
		mi.position = Vector3(sling_x - 1.05 - float(i) * compact_spacing, sling_base_y + 0.36, z_off)
		mi.set_meta("base_y", sling_base_y + 0.36)
		mi.set_meta("phase", float(i) * 1.1)
		queue_visual_root.add_child(mi)

# =========================================================================
# DAMAGE, TNT EXPLOSIONS, SCORE & YUZU COMBO
# =========================================================================

func _on_body_impact(rec: Dictionary, other: Node, is_enemy: bool) -> void:
	if spawn_grace > 0.0 or bool(rec["dead"]) or stage_ended:
		return
	var rb: RigidBody3D = rec["rb"]
	if not is_instance_valid(rb):
		return

	var v_self: Vector3 = rec["last_vel"]
	var v_other := Vector3.ZERO
	var other_mass: float = 2.0
	var other_kind: String = str(other.get_meta("kind", ""))
	var capy_mult: float = 1.0

	if other is RigidBody3D:
		if other.has_meta("last_vel"):
			v_other = other.get_meta("last_vel")
		else:
			v_other = other.linear_velocity
		other_mass = other.mass
		if other_kind == "capy":
			var ctype: String = str(other.get_meta("capy_type", "chill"))
			var btype: String = str(rec["type"])
			if ctype == "dash" and btype == "wood":
				capy_mult = 1.85
			elif ctype == "mini" and btype == "ice":
				capy_mult = 2.15

	var rel_speed: float = (v_self - v_other).length()
	var thresh: float = float(rec["thresh"])

	if is_enemy:
		# Buaya sensitif terhadap senggolan kapibara, tertimpa/tersenggol balok bangunan, & jatuh ke tanah!
		if other_kind == "capy":
			# Senggolan kapibara sekecil apa pun (>= 0.45 m/s) langsung melukai parah (min 16 HP)
			if rel_speed < 0.45:
				return
			var dmg_capy: float = maxf(16.0, (rel_speed - 0.35) * (7.2 + other_mass * 2.8) * 1.45)
			_apply_damage(rec, dmg_capy, true)
			return
		elif other_kind == "block":
			# Tertimpa / tersenggol bangunan (bambu, kayu, es, TNT): ekstra sakit setelah tembakan!
			var eff_thresh: float = thresh if shot_fired else 2.2
			if rel_speed < eff_thresh:
				return
			var base_min: float = 10.0 if shot_fired else 0.0
			var dmg_blk: float = maxf(base_min, (rel_speed - eff_thresh) * (6.8 + other_mass * 4.2) * 1.65)
			_apply_damage(rec, dmg_blk, true)
			return
		elif other_kind == "enemy":
			if rel_speed < 1.0:
				return
			_apply_damage(rec, (rel_speed - 0.6) * 10.5, true)
			return
		else:
			# Jatuh terbanting ke tanah setelah terlempar dari bangunan
			var g_thresh: float = 1.25 if shot_fired else 2.5
			if rel_speed < g_thresh:
				return
			_apply_damage(rec, (rel_speed - 0.85) * 11.0, true)
			return

	if rel_speed < thresh:
		return

	var dmg: float = (rel_speed - thresh) * (4.6 + other_mass * 1.9) * capy_mult
	_apply_damage(rec, dmg, false)

func _apply_damage(rec: Dictionary, dmg: float, is_enemy: bool) -> void:
	if bool(rec["dead"]) or dmg <= 0.08:
		return
	rec["hp"] = float(rec["hp"]) - dmg
	if float(rec["hp"]) <= 0.0:
		_destroy_entity(rec, is_enemy)
	else:
		var ratio: float = float(rec["hp"]) / maxf(float(rec["max_hp"]), 1.0)
		if is_enemy:
			# Feedback luka nyata pada buaya: flash + squash-bounce + rona memar di bawah 65% HP!
			rec["hurt_t"] = 0.24
			if dmg >= 4.0:
				var rb: RigidBody3D = rec["rb"]
				if is_instance_valid(rb):
					_spawn_vfx_sphere(rb.global_position + Vector3(0.0, 0.15, 0.0), 0.56, Color(0.98, 0.86, 0.42))
			if ratio < 0.65:
				rec["bruised"] = true
			_tint_enemy_mesh(rec, Color(1.0, 0.56, 0.46))
		elif ratio < 0.55:
			var mi: MeshInstance3D = rec["mi"]
			if is_instance_valid(mi):
				if mi.material_override is ShaderMaterial:
					(mi.material_override as ShaderMaterial).set_shader_parameter("tint_color", Color(0.62, 0.54, 0.48))
				elif mi.material_override is StandardMaterial3D:
					(mi.material_override as StandardMaterial3D).albedo_color = Color(0.56, 0.78, 0.88, 0.88)

func _tint_enemy_mesh(rec: Dictionary, tint: Color) -> void:
	var mi: MeshInstance3D = rec["mi"]
	if not is_instance_valid(mi) or mi.mesh == null:
		return
	for s_idx in mi.mesh.get_surface_count():
		var mat := mi.get_surface_override_material(s_idx)
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("tint_color", tint)

func _spawn_floating_text(world_pos: Vector3, txt: String, col: Color, fsize: int = 20) -> void:
	floating_texts.append({
		"pos": world_pos + Vector3(0.0, 0.35, 0.0),
		"text": txt,
		"color": col,
		"size": fsize,
		"t": 0.0,
		"dur": 0.95
	})

func _add_shake(amount: float) -> void:
	shake_trauma = minf(shake_trauma + amount, 1.0)

func _destroy_entity(rec: Dictionary, is_enemy: bool) -> void:
	if bool(rec["dead"]):
		return
	rec["dead"] = true
	var rb: RigidBody3D = rec["rb"]
	var pos := rb.global_position if is_instance_valid(rb) else Vector3.ZERO
	var btype: String = str(rec["type"])

	# Yuzu Combo multiplier (x1.0 -> x1.5 -> x2.0 -> x3.0)
	combo_count += 1
	combo_timer = 1.8
	var mult: float = 1.0
	if combo_count >= 5:
		mult = 3.0
	elif combo_count >= 3:
		mult = 2.0
	elif combo_count >= 2:
		mult = 1.5
	var gained := int(round(float(rec["score"]) * mult))
	score += gained
	_refresh_score_hud()

	if is_enemy or btype == "tnt" or btype == "yuzu_basket":
		_spawn_floating_text(pos, "+%s" % CraftUI.format_score(gained), CraftUI.GOLD_TEXT, 22)
	else:
		_spawn_floating_text(pos, "+%s" % CraftUI.format_score(gained), CraftUI.CREAM_TEXT, 16)
	if combo_count >= 2:
		_spawn_floating_text(pos + Vector3(0.0, 0.72, 0.0), "KOMBO ×%d!" % combo_count, Color(1.0, 0.45, 0.24), 19)

	if is_instance_valid(rb):
		rb.queue_free()

	if is_enemy:
		_spawn_vfx_sphere(pos, 1.5, Color(0.54, 0.88, 0.44))
		SoundManager.play_sfx("croc_defeat", 0.78 if btype == "mini_boss" else 1.0, -1.0, 0.08)
		_add_shake(0.68 if btype == "mini_boss" else 0.24)
		enemies.erase(rec)
		if enemies.is_empty() and not stage_ended:
			pending_victory = true
			end_delay_timer = 1.15
	else:
		blocks.erase(rec)
		if btype == "tnt":
			_trigger_tnt_explosion(pos)
		elif btype == "ice":
			_spawn_vfx_sphere(pos, 1.2, Color(0.72, 0.94, 1.0))
			SoundManager.play_sfx("hit_ice", 1.0, -3.0, 0.08)
		elif btype == "stone" or btype == "boulder":
			_spawn_vfx_sphere(pos, 1.1, Color(0.76, 0.74, 0.70))
			SoundManager.play_sfx("hit_stone", 1.0, -2.0, 0.08)
		elif btype == "wood":
			_spawn_vfx_sphere(pos, 1.0, Color(0.84, 0.62, 0.36))
			SoundManager.play_sfx("hit_wood", 1.0, -3.0, 0.08)
		elif btype == "yuzu_basket":
			_spawn_vfx_sphere(pos, 1.65, Color(0.98, 0.82, 0.22))
			SoundManager.play_sfx("star_pop", 1.08, -2.0)
		else:
			_spawn_vfx_sphere(pos, 1.0, Color(0.88, 0.78, 0.56))
			SoundManager.play_sfx("hit_bamboo", 1.0, -3.5, 0.08)

func _trigger_tnt_explosion(center: Vector3) -> void:
	_spawn_vfx_sphere(center, 4.8, Color(0.95, 0.42, 0.14))
	SoundManager.play_sfx("tnt_boom", 1.0, 0.0, 0.05)
	_add_shake(0.78)
	var radius: float = 5.0
	for b in blocks.duplicate():
		if bool(b["dead"]):
			continue
		var rb: RigidBody3D = b["rb"]
		if not is_instance_valid(rb):
			continue
		var diff := rb.global_position - center
		var dist := diff.length()
		if dist < radius and dist > 0.01:
			var falloff := 1.0 - (dist / radius)
			rb.apply_central_impulse(diff.normalized() * 30.0 * falloff + Vector3(0.0, 5.0 * falloff, 0.0))
			_apply_damage(b, 130.0 * falloff, false)

	for e in enemies.duplicate():
		if bool(e["dead"]):
			continue
		var rb: RigidBody3D = e["rb"]
		if not is_instance_valid(rb):
			continue
		var diff := rb.global_position - center
		var dist := diff.length()
		if dist < radius and dist > 0.01:
			var falloff := 1.0 - (dist / radius)
			rb.apply_central_impulse(diff.normalized() * 26.0 * falloff + Vector3(0.0, 6.0 * falloff, 0.0))
			_apply_damage(e, 115.0 * falloff, true)

# =========================================================================
# WORLD 1 CAPYBARA ACTIVE SKILLS (Chill, Dash, Trio Mini Triple Split!)
# =========================================================================

func _activate_skill() -> void:
	if not is_instance_valid(active_capy) or skill_used:
		return
	skill_used = true
	var pos := active_capy.global_position

	match active_capy_type:
		"chill":
			# Zen Bump: dorongan tajam ke bawah + gelombang getar radius 2.8m (melukai balok DAN buaya!)
			active_capy.apply_central_impulse(Vector3(0.0, -11.5, 0.0))
			_spawn_vfx_sphere(pos, 2.5, Color(0.95, 0.88, 0.62))
			SoundManager.play_sfx("skill_zen", 1.0, -1.0)
			_add_shake(0.42)
			for b in blocks.duplicate():
				var rb: RigidBody3D = b["rb"]
				if is_instance_valid(rb):
					var d := rb.global_position - pos
					if d.length() < 2.8:
						rb.apply_central_impulse(d.normalized() * 10.0)
						_apply_damage(b, 20.0, false)
			for e in enemies.duplicate():
				var rb: RigidBody3D = e["rb"]
				if is_instance_valid(rb):
					var d := rb.global_position - pos
					if d.length() < 3.0:
						rb.apply_central_impulse(d.normalized() * 9.5 + Vector3(0.0, 2.5, 0.0))
						_apply_damage(e, 26.0, true)
		"dash":
			# Turbo Dash 2.2x lurus!
			var vel := active_capy.linear_velocity
			var dir := vel.normalized() if vel.length() > 0.5 else Vector3(1, 0, 0)
			active_capy.linear_velocity = dir * maxf(vel.length() * 2.2, 29.0)
			_spawn_vfx_sphere(pos, 1.35, Color(0.98, 0.84, 0.28))
			SoundManager.play_sfx("skill_dash", 1.0, -1.5)
		"mini":
			# TRIPLE SPLIT: Spawn 2 klon Trio Mini-Capi menyebar +12 deg dan -12 deg!
			var base_vel := active_capy.linear_velocity
			if base_vel.length() < 4.0:
				base_vel = Vector3(14.0, 2.0, 0.0)
			_spawn_vfx_sphere(pos, 1.3, Color(0.45, 0.84, 0.98))
			SoundManager.play_sfx("skill_split", 1.0, -1.5)
			for ang_deg in [-12.0, 12.0]:
				var rad := deg_to_rad(float(ang_deg))
				var c := cos(rad)
				var s := sin(rad)
				var rot_vel := Vector3(base_vel.x * c - base_vel.y * s, base_vel.x * s + base_vel.y * c, 0.0)
				_spawn_mini_clone(pos + Vector3(0.0, 0.28 if ang_deg > 0 else -0.28, 0.0), rot_vel)

func _spawn_mini_clone(pos: Vector3, vel: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = 1.0
	rb.continuous_cd = true
	rb.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	rb.linear_damp = 0.0
	rb.axis_lock_linear_z = true
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_y = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 6
	rb.linear_velocity = vel
	rb.set_meta("kind", "capy")
	rb.set_meta("capy_type", "mini")
	rb.set_meta("last_vel", vel)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	col.shape = shape
	rb.add_child(col)

	var mi := MeshInstance3D.new()
	mi.mesh = capy_meshes["mini"]
	_apply_rovio_model_materials(mi)
	rb.add_child(mi)

	arena_root.add_child(rb)
	flying_projectiles.append(rb)

# =========================================================================
# INPUT, AIMING, CAMERA & MAIN LOOP
# =========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if CraftUI.is_confirm_open(get_tree()):
		return
	if is_paused:
		return
	if stage_ended:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			_load_stage(current_stage_id)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_camera_view(CameraView.SIDE_25D)
			KEY_2: _set_camera_view(CameraView.ANGLED_25D)
			KEY_3: _set_camera_view(CameraView.BEHIND_3D)
			KEY_TAB: _set_camera_view((current_view + 1) % 3)
			KEY_R: _request_restart_stage()
			KEY_ESCAPE, KEY_P: _toggle_pause()
			KEY_SPACE:
				if is_flying and not skill_used:
					_activate_skill()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbit_active = event.pressed
			if event.pressed:
				custom_orbit_active = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_zoom_offset = clampf(cam_zoom_offset - 1.4, -10.0, 12.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_zoom_offset = clampf(cam_zoom_offset + 1.4, -10.0, 12.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_flying and not skill_used:
					_activate_skill()
				elif not is_flying and is_instance_valid(active_capy):
					is_aiming = true
					drag_start_px = event.position
					pull_vector = Vector3.ZERO
					SoundManager.play_sfx("sling_stretch", 1.0, -5.0, 0.05)
			else:
				if is_aiming:
					_release_slingshot()

	if event is InputEventMouseMotion:
		if orbit_active:
			orbit_yaw -= event.relative.x * 0.006
			orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.006, 0.05, 1.05)
		elif is_aiming:
			var delta_px: Vector2 = event.position - drag_start_px
			var sc := 0.0145
			var vx := -delta_px.x * sc
			var vy := delta_px.y * sc
			var v2 := Vector2(vx, vy)
			if v2.length() > MAX_PULL_DIST:
				v2 = v2.normalized() * MAX_PULL_DIST
			pull_vector = Vector3(-v2.x, -v2.y, 0.0)
			if is_instance_valid(active_capy):
				var aim_pos := Vector3(launch_x, launch_y, 0.0) + pull_vector * 0.65
				aim_pos.y = maxf(sling_base_y + 0.38, aim_pos.y)
				active_capy.position = aim_pos
			_update_trajectory_preview()

func _release_slingshot() -> void:
	is_aiming = false
	_hide_trajectory()
	if not is_instance_valid(active_capy):
		return
	var launch_vel := -pull_vector * LAUNCH_POWER
	if launch_vel.length() < 3.0:
		active_capy.position = Vector3(launch_x, launch_y, 0.0)
		pull_vector = Vector3.ZERO
		return
	active_capy.freeze = false
	active_capy.linear_velocity = launch_vel
	active_capy.set_meta("last_vel", launch_vel)
	flying_projectiles.append(active_capy)
	is_flying = true
	shot_fired = true
	flight_timer = 0.0
	settle_timer = 0.0
	pull_vector = Vector3.ZERO
	SoundManager.play_sfx("launch", 1.0, -2.0, 0.06)

func _physics_process(delta: float) -> void:
	if spawn_grace > 0.0:
		spawn_grace = maxf(spawn_grace - delta, 0.0)

	# Simpan kecepatan frame sebelumnya untuk perhitungan impak fisik yang akurat
	for b in blocks.duplicate():
		var rb: RigidBody3D = b["rb"]
		if is_instance_valid(rb):
			b["last_vel"] = rb.linear_velocity
			if rb.global_position.y < -4.0:
				_destroy_entity(b, false)
	for e in enemies.duplicate():
		var rb: RigidBody3D = e["rb"]
		if is_instance_valid(rb):
			e["last_vel"] = rb.linear_velocity
			if rb.global_position.y < -3.5:
				_destroy_entity(e, true)
				continue
			# Cek kontinu: buaya tertindih/tertimpa balok miring ATAU disenggol kapibara menggelinding!
			if shot_fired and spawn_grace <= 0.0 and not stage_ended and not bool(e["dead"]):
				for col_body in rb.get_colliding_bodies():
					if not (col_body is RigidBody3D):
						continue
					var crb: RigidBody3D = col_body as RigidBody3D
					var ckind: String = str(crb.get_meta("kind", ""))
					if ckind == "block":
						var above: bool = crb.global_position.y > rb.global_position.y + 0.14
						var rel_v: float = (crb.linear_velocity - rb.linear_velocity).length()
						var spin: float = absf(crb.angular_velocity.z)
						if above or rel_v > 0.35 or spin > 0.55:
							_apply_damage(e, (28.0 + crb.mass * 18.0) * delta, true)
							if bool(e["dead"]):
								break
					elif ckind == "capy":
						var rel_c: float = (crb.linear_velocity - rb.linear_velocity).length()
						if rel_c > 0.22:
							_apply_damage(e, 38.0 * delta, true)
							if bool(e["dead"]):
								break
	for p in flying_projectiles:
		if is_instance_valid(p):
			var prev_vel: Vector3 = p.get_meta("last_vel", p.linear_velocity)
			p.set_meta("last_vel", p.linear_velocity)
			# Cek pantulan Drum Taiko Onsen (bounce_pad)
			var cd: float = float(p.get_meta("bounce_cd", 0.0))
			if cd > 0.0:
				p.set_meta("bounce_cd", maxf(cd - delta, 0.0))
			else:
				for col_body in p.get_colliding_bodies():
					if str(col_body.get_meta("kind", "")) == "bounce_pad":
						var pwr: float = float(col_body.get_meta("bounce_power", 16.5))
						var pad_up: Vector3 = (col_body as Node3D).global_transform.basis.y.normalized()
						var boost_vel: Vector3 = pad_up * pwr + Vector3(prev_vel.x * 0.45, 0.0, 0.0)
						boost_vel.z = 0.0
						p.linear_velocity = boost_vel
						p.set_meta("last_vel", boost_vel)
						p.set_meta("bounce_cd", 0.25)
						if col_body.has_meta("pad_rec"):
							var pad_rec: Dictionary = col_body.get_meta("pad_rec")
							pad_rec["pulse_t"] = 0.28
						_spawn_vfx_sphere(p.global_position, 1.45, Color(0.98, 0.42, 0.36))
						SoundManager.play_sfx("bounce_pad", 1.0, -1.5, 0.06)
						break

func _process(delta: float) -> void:
	anim_time += delta

	if validate_all_w1:
		_process_automated_validator(delta)
		return

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			_refresh_score_hud()

	_update_slingshot_bands()
	_update_capy_anim(delta)
	_update_enemy_anim(delta)
	_update_bounce_pad_anim(delta)
	_update_camera(delta)
	_update_vfx(delta)
	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		ft["t"] = float(ft["t"]) + delta
		ft["pos"] = (ft["pos"] as Vector3) + Vector3(0.0, delta * 1.55, 0.0)
		if float(ft["t"]) >= float(ft["dur"]):
			floating_texts.remove_at(i)
	if shake_trauma > 0.0:
		shake_trauma = maxf(shake_trauma - delta * 2.4, 0.0)
	if is_instance_valid(diegetic_overlay):
		diegetic_overlay.queue_redraw()

	if sun_rays_node:
		sun_rays_node.rotation.z = anim_time * 0.05
	for sp in steam_puffs:
		var node: MeshInstance3D = sp["node"]
		var base: Vector3 = sp["base"]
		var ph: float = float(sp["phase"])
		var cyc: float = fmod(anim_time * 0.45 + ph, 2.2)
		node.position = base + Vector3(sin(anim_time + ph) * 0.35, cyc * 1.15, 0.0)
		node.scale = Vector3.ONE * maxf(sin((cyc / 2.2) * PI) * 0.55, 0.05)
	for lf in bg_leaves:
		var node: MeshInstance3D = lf["node"]
		var base: Vector3 = lf["base"]
		var ph: float = float(lf["phase"])
		node.position = base + Vector3(sin(anim_time * 0.9 + ph) * 0.85, -fmod(anim_time * 0.55 + ph, 4.5) + 2.2, 0.0)
		node.rotation = Vector3(anim_time * 1.5 + ph, anim_time * 0.8, sin(anim_time + ph))
	for qnode in queue_visual_root.get_children():
		var by: float = float(qnode.get_meta("base_y", 0.36))
		var ph: float = float(qnode.get_meta("phase", 0.0))
		qnode.position.y = by + absf(sin(anim_time * 2.6 + ph)) * 0.08

	# Stage progression & end conditions
	if pending_victory:
		end_delay_timer -= delta
		if end_delay_timer <= 0.0 and not stage_ended:
			_finish_stage_victory()
	elif is_flying and not stage_ended:
		flight_timer += delta
		var speed_now: float = 0.0
		var any_in_bounds: bool = false
		for p in flying_projectiles:
			if is_instance_valid(p):
				var p_oob: bool = (p.global_position.y < -4.0 or p.global_position.x > stage_max_x + 9.0 or p.global_position.x < stage_min_x - 8.0)
				if not p_oob:
					any_in_bounds = true
					speed_now = maxf(speed_now, p.linear_velocity.length())
		if speed_now < 0.75 or not any_in_bounds:
			settle_timer += delta
		else:
			settle_timer = 0.0
		if flight_timer > 7.5 or settle_timer > 1.45:
			is_flying = false
			if not capy_queue.is_empty():
				_load_next_capy_onto_slingshot()
			elif not enemies.is_empty() and not pending_victory:
				pending_defeat = true
				end_delay_timer = 1.2
	elif pending_defeat:
		end_delay_timer -= delta
		if end_delay_timer <= 0.0 and not stage_ended:
			if enemies.is_empty():
				_finish_stage_victory()
			else:
				_finish_stage_defeat()

	if capture_stage_path != "" and not capture_done and anim_time > 0.75:
		capture_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_stage_path)
		get_tree().quit()
	elif capture_croco_path != "" and not capture_done and anim_time > 0.75:
		capture_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_croco_path)
		get_tree().quit()
	elif capture_pause_path != "" and not capture_done and anim_time > 0.65:
		capture_done = true
		_capture_pause_async()
	elif capture_confirm_reset_path != "" and not capture_done and anim_time > 0.65:
		capture_done = true
		_capture_confirm_reset_async()

func _capture_pause_async() -> void:
	_set_paused(true)
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(capture_pause_path)
	_set_paused(false)
	get_tree().quit()

func _capture_confirm_reset_async() -> void:
	_request_restart_stage()
	await get_tree().create_timer(0.18, true).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(capture_confirm_reset_path)
	get_tree().paused = false
	get_tree().quit()

func _process_automated_validator(delta: float) -> void:
	validate_timer += delta
	if validate_timer < 1.35:
		return
	var sid := "1-%d" % validate_idx
	var expected_enemies: int = (stage_data.get("enemies", []) as Array).size()
	var alive_enemies: int = enemies.size()
	var ok: bool = (alive_enemies == expected_enemies and expected_enemies >= 1 and blocks.size() > 0)
	if not ok:
		validate_failed.append("%s (enemies %d/%d, blocks %d)" % [sid, alive_enemies, expected_enemies, blocks.size()])
	print("[VALIDATOR] Stage %s: %s (enemies=%d/%d, blocks=%d)" % [sid, "PASS" if ok else "FAIL", alive_enemies, expected_enemies, blocks.size()])

	validate_idx += 1
	validate_timer = 0.0
	if validate_idx > 20:
		if validate_failed.is_empty():
			print("[VALIDATOR] ALL 20 WORLD 1 SUB-LEVELS PASSED STABILITY CHECK!")
			get_tree().quit(0)
		else:
			push_error("[VALIDATOR] FAILED STAGES: " + str(validate_failed))
			get_tree().quit(1)
	else:
		_load_stage("1-%d" % validate_idx)

func _finish_stage_victory() -> void:
	stage_ended = true
	var unused_capys: int = capy_queue.size() + (1 if (is_instance_valid(active_capy) and not is_flying) else 0)
	var bonus: int = unused_capys * 10000
	score += bonus
	_refresh_score_hud()

	var star_arr: Array = stage_data.get("stars", [15000, 25000, 35000])
	var s1: int = int(star_arr[0])
	var s2: int = int(star_arr[1])
	var s3: int = int(star_arr[2])
	var stars := 1
	if score >= s3:
		stars = 3
	elif score >= s2:
		stars = 2
	elif score >= s1:
		stars = 1

	SaveManager.record_stage_clear(current_stage_id, score, stars)
	SoundManager.play_sfx("victory", 1.0, -1.0)

	if result_badge_lbl:
		result_badge_lbl.text = "MENANG!" if stars >= 1 else "SELESAI"
	result_title.text = "STAGE %s SELESAI!" % current_stage_id
	var tex_empty: Texture2D = CraftUI.tex("icon_star_empty")
	for k in result_star_labels.size():
		var rsl: TextureRect = result_star_labels[k]
		rsl.texture = tex_empty
		rsl.pivot_offset = Vector2(24, 24)
		rsl.scale = Vector2.ONE
	result_body.text = "Skor Akhir: %s\nBonus Sisa %d Kapibara: +%s  •  Target 3★: %s" % [
		CraftUI.format_score(0), unused_capys, CraftUI.format_score(bonus), CraftUI.format_score(s3)
	]
	var has_next: bool = (SaveManager.get_next_stage_id(current_stage_id) != "")
	btn_next_stage.visible = has_next
	_style_hud_btn(btn_next_stage, true)
	_style_hud_btn(btn_retry, not has_next)
	result_overlay.visible = true
	_animate_victory_celebration(score, stars, unused_capys, bonus, s3)

func _animate_victory_celebration(final_score: int, stars: int, unused_capys: int, bonus: int, s3: int) -> void:
	var count_dur := 0.48
	var t_c := 0.0
	while t_c < count_dur and result_overlay.visible and stage_ended:
		await get_tree().process_frame
		t_c += get_process_delta_time()
		var p := clampf(t_c / count_dur, 0.0, 1.0)
		var shown := int(round(float(final_score) * smoothstep(0.0, 1.0, p)))
		result_body.text = "Skor Akhir: %s\nBonus Sisa %d Kapibara: +%s  •  Target 3★: %s" % [
			CraftUI.format_score(shown), unused_capys, CraftUI.format_score(bonus), CraftUI.format_score(s3)
		]

	var tex_gold: Texture2D = CraftUI.tex("icon_star_gold")
	for k in mini(stars, result_star_labels.size()):
		if not result_overlay.visible:
			return
		var rsl: TextureRect = result_star_labels[k]
		rsl.texture = tex_gold
		rsl.pivot_offset = Vector2(24, 24)
		rsl.scale = Vector2(0.15, 0.15)
		var tw := create_tween()
		tw.tween_property(rsl, "scale", Vector2(1.34, 1.34), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(rsl, "scale", Vector2.ONE, 0.12)
		SoundManager.play_sfx("star_pop", 1.0 + float(k) * 0.15, -1.5)
		await get_tree().create_timer(0.24).timeout

func _finish_stage_defeat() -> void:
	stage_ended = true
	SoundManager.play_sfx("defeat", 1.0, -1.5)
	if result_badge_lbl:
		result_badge_lbl.text = "COBA LAGI"
	result_title.text = "BELUM BERHASIL"
	var tex_empty: Texture2D = CraftUI.tex("icon_star_empty")
	for rsl in result_star_labels:
		rsl.texture = tex_empty
	result_body.text = "Masih ada %d Klan Buaya bertahan.\nCoba sudut bidikan atau aktifkan skill kapibara di udara!" % enemies.size()
	btn_next_stage.visible = false
	_style_hud_btn(btn_retry, true)
	result_overlay.visible = true

func _go_next_stage() -> void:
	var nxt := SaveManager.get_next_stage_id(current_stage_id)
	if nxt != "":
		_load_stage(nxt)
	else:
		SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE)

func _refresh_score_hud() -> void:
	var star_arr: Array = stage_data.get("stars", [15000, 25000, 35000])
	var s1: int = int(star_arr[0])
	var s2: int = int(star_arr[1])
	var s3: int = maxi(int(star_arr[2]), 1)
	var total_e: int = maxi((stage_data.get("enemies", []) as Array).size(), enemies.size())
	if is_instance_valid(lbl_enemy_pill):
		lbl_enemy_pill.text = "×%d" % enemies.size()
	lbl_score.text = CraftUI.format_score(score)
	if is_instance_valid(score_star_bar):
		score_star_bar.max_value = float(s3)
		score_star_bar.value = minf(float(score), float(s3))
	var thresh: Array[int] = [s1, s2, s3]
	var tex_gold: Texture2D = CraftUI.tex("icon_star_gold")
	var tex_empty: Texture2D = CraftUI.tex("icon_star_empty")
	for k in mini(hud_star_pips.size(), 3):
		var sp: TextureRect = hud_star_pips[k]
		sp.texture = tex_gold if score >= thresh[k] else tex_empty

	# Live Boss / Klan Segmented HP Bar
	if is_instance_valid(boss_bar_root) and boss_bar_root.visible:
		var ratio := float(enemies.size()) / maxf(float(total_e), 1.0)
		var lit_segs := int(ceil(ratio * float(boss_segments.size())))
		for i in boss_segments.size():
			boss_segments[i].color = Color(0.91, 0.22, 0.16) if i < lit_segs else Color(0.24, 0.12, 0.09)
		if is_instance_valid(lbl_boss_hp):
			lbl_boss_hp.text = "%d/%d" % [enemies.size(), total_e]

	if is_instance_valid(lbl_combo):
		if combo_count >= 2:
			var mult: float = 1.5
			if combo_count >= 5:
				mult = 3.0
			elif combo_count >= 3:
				mult = 2.0
			lbl_combo.text = "KOMBO ×%d! (%.1fx)" % [combo_count, mult]
			lbl_combo.visible = true
		else:
			lbl_combo.visible = false

func _make_queue_cutout(ctype: String, q_idx: int) -> Control:
	var spec: Dictionary = CAPY_SPECS.get(ctype, CAPY_SPECS["chill"])
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(36, 36)
	tile.pivot_offset = Vector2(18, 18)
	tile.rotation_degrees = -4.5 if (q_idx % 2 == 0) else 4.0
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sh := ColorRect.new()
	sh.position = Vector2(2, 4)
	sh.size = Vector2(34, 34)
	sh.color = CraftUI.INK
	tile.add_child(sh)

	var frame := ColorRect.new()
	frame.position = Vector2(0, 1)
	frame.size = Vector2(34, 34)
	frame.color = CraftUI.INK
	tile.add_child(frame)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 3
	bg.offset_right = -3
	bg.offset_top = 3
	bg.offset_bottom = -3
	bg.color = Color(0.65, 0.41, 0.22)
	frame.add_child(bg)

	var ic := CraftUI.make_tex_rect(load(str(spec["portrait"])), Vector2(28, 28))
	ic.position = Vector2(3, 3)
	frame.add_child(ic)
	return tile

func _refresh_queue_hud() -> void:
	if is_instance_valid(hud_squad_row):
		for c in hud_squad_row.get_children():
			c.queue_free()
		var idx := 0
		if is_instance_valid(active_capy):
			hud_squad_row.add_child(_make_queue_cutout(active_capy_type, idx))
			idx += 1
		for q_type in capy_queue:
			hud_squad_row.add_child(_make_queue_cutout(str(q_type), idx))
			idx += 1

	var disp_type := active_capy_type if is_instance_valid(active_capy) else "chill"
	var spec: Dictionary = CAPY_SPECS.get(disp_type, CAPY_SPECS["chill"])
	if is_instance_valid(active_hero_portrait):
		active_hero_portrait.texture = load(str(spec["portrait"]))
	if is_instance_valid(active_hero_wood_bg) and active_hero_wood_bg.has_meta("inner_sq"):
		var inner_sq := active_hero_wood_bg.get_meta("inner_sq") as ColorRect
		if inner_sq:
			if disp_type == "dash":
				inner_sq.color = Color(0.97, 0.71, 0.22)
			elif disp_type == "mini":
				inner_sq.color = Color(0.23, 0.70, 0.90)
			else:
				inner_sq.color = Color(0.92, 0.28, 0.19)
	if is_instance_valid(active_skill_lbl):
		active_skill_lbl.text = str(spec["skill_short"]) if is_instance_valid(active_capy) else "MELUNCUR..."
		active_skill_lbl.add_theme_color_override("font_color", spec["accent"])

func _set_camera_view(view_idx: int) -> void:
	current_view = view_idx
	custom_orbit_active = false
	cam_zoom_offset = 0.0
	cam_pan_x = 0.0
	cam_pan_target_x = 0.0
	var view_tilts := [-1.2, 0.8, -0.8]
	for i in btn_views.size():
		var is_act := (i == view_idx)
		btn_views[i].set_pressed_no_signal(is_act)
		CraftUI.style_wood_button(
			btn_views[i],
			"wood_btn_amber" if is_act else "wood_btn_cedar_dark",
			13,
			Vector2(88, 38),
			view_tilts[i],
			true,
			CraftUI.CREAM_TEXT if is_act else Color(0.91, 0.85, 0.76),
			4
		)

func _update_capy_anim(delta: float) -> void:
	if not is_instance_valid(active_capy) or not is_instance_valid(active_capy_visual):
		return
	if is_aiming:
		var stretch := clampf(pull_vector.length() / MAX_PULL_DIST, 0.0, 1.0)
		var launch_dir := (-pull_vector).normalized()
		var pitch := atan2(launch_dir.y, maxf(0.1, launch_dir.x))
		active_capy_visual.rotation = Vector3(0.0, 0.0, pitch)
		active_capy_visual.scale = Vector3(1.0 + 0.16 * stretch, 1.0 - 0.10 * stretch, 1.0 - 0.06 * stretch)
	elif not is_flying:
		var breath := sin(anim_time * 3.4)
		var sway := sin(anim_time * 1.9) * 0.08
		active_capy_visual.scale = Vector3(1.0 - 0.04 * breath, 1.0 + 0.06 * breath, 1.0 - 0.03 * breath)
		active_capy_visual.rotation = Vector3(sway * 0.5, sway, sin(anim_time * 2.5) * 0.05)
	else:
		active_capy_visual.scale = active_capy_visual.scale.lerp(Vector3.ONE, clampf(delta * 10.0, 0.0, 1.0))
		active_capy_visual.rotation = active_capy_visual.rotation.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))

func _update_slingshot_bands() -> void:
	var target := Vector3(launch_x, launch_y, 0.0)
	if is_aiming and is_instance_valid(active_capy):
		target = active_capy.position
	_stretch_band(band_mesh_a, Vector3(sling_x, sling_base_y + 1.82,  0.42), target)
	_stretch_band(band_mesh_b, Vector3(sling_x, sling_base_y + 1.82, -0.42), target)

func _stretch_band(mi: MeshInstance3D, p0: Vector3, p1: Vector3) -> void:
	var diff := p1 - p0
	var ln := diff.length()
	if ln < 0.02:
		mi.visible = false
		return
	mi.visible = true
	mi.position = (p0 + p1) * 0.5
	mi.scale = Vector3(1.0, ln, 1.0)
	var dir := diff / ln
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		mi.basis = Basis.IDENTITY
	else:
		var axis := up.cross(dir).normalized()
		mi.basis = Basis(axis, acos(clampf(up.dot(dir), -1.0, 1.0)))

func _update_trajectory_preview() -> void:
	var vel := -pull_vector * LAUNCH_POWER
	if vel.length() < 3.0:
		_hide_trajectory()
		return
	var start_p := active_capy.position if is_instance_valid(active_capy) else Vector3(launch_x, launch_y, 0.0)
	for i in traj_dots.size():
		var t := float(i + 1) * 0.072
		var p := start_p + vel * t + Vector3(0.0, -0.5 * GRAVITY * t * t, 0.0)
		traj_dots[i].position = p
		traj_dots[i].visible = p.y > 0.05

func _hide_trajectory() -> void:
	for d in traj_dots:
		d.visible = false

func _spawn_vfx_sphere(pos: Vector3, max_r: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	mi.mesh = sm
	mi.position = pos
	mi.scale = Vector3.ONE * 0.2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.60)
	mi.material_override = mat
	arena_root.add_child(mi)
	vfx_nodes.append({ "node": mi, "mat": mat, "t": 0.0, "max_r": max_r })

func _update_vfx(delta: float) -> void:
	for i in range(vfx_nodes.size() - 1, -1, -1):
		var item: Dictionary = vfx_nodes[i]
		item["t"] = float(item["t"]) + delta
		var p: float = float(item["t"]) / 0.36
		var node: MeshInstance3D = item["node"]
		var mat: StandardMaterial3D = item["mat"]
		if p >= 1.0 or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			vfx_nodes.remove_at(i)
		else:
			node.scale = Vector3.ONE * lerpf(0.2, float(item["max_r"]), p)
			mat.albedo_color.a = lerpf(0.60, 0.0, p)

func _update_enemy_anim(delta: float) -> void:
	for e in enemies:
		if bool(e["dead"]):
			continue
		var mi: MeshInstance3D = e["mi"]
		if not is_instance_valid(mi):
			continue
		var base_sc: float = float(e["base_scale"])
		var ph: float = float(e["phase"])
		var ht: float = float(e["hurt_t"])
		if ht > 0.0:
			ht = maxf(ht - delta, 0.0)
			e["hurt_t"] = ht
			var p: float = ht / 0.24
			# Squash-stretch memantul saat kena senggolan/timpaan!
			var sq: float = sin(p * PI) * 0.22
			mi.scale = Vector3(base_sc * (1.0 + sq), base_sc * (1.0 - sq * 0.85), base_sc * (1.0 + sq * 0.5))
			if ht <= 0.0:
				var bt: Color = e["base_tint"]
				var rest_tint: Color = bt * Color(0.86, 0.64, 0.58) if bool(e["bruised"]) else bt
				_tint_enemy_mesh(e, rest_tint)
		else:
			# Napas santai / geliat buaya agar terasa hidup!
			var br: float = sin(anim_time * 3.0 + ph)
			mi.scale = Vector3(base_sc * (1.0 - 0.03 * br), base_sc * (1.0 + 0.045 * br), base_sc * (1.0 - 0.02 * br))

func _update_bounce_pad_anim(delta: float) -> void:
	for pad_rec in bounce_pads:
		var pt: float = float(pad_rec["pulse_t"])
		if pt <= 0.0:
			continue
		pt = maxf(pt - delta, 0.0)
		pad_rec["pulse_t"] = pt
		var vis: Node3D = pad_rec["vis"]
		if not is_instance_valid(vis):
			continue
		if pt <= 0.0:
			vis.scale = Vector3.ONE
		else:
			var p: float = pt / 0.28
			var wave: float = sin(p * PI * 2.0) * p * 0.24
			vis.scale = Vector3(1.0 - wave * 0.65, 1.0 + wave * 1.15, 1.0 - wave * 0.45)

func _update_camera(delta: float) -> void:
	if capture_croco_path != "" and not enemies.is_empty():
		# Ambil musuh tertinggi/terbuka agar tidak terhalang pilar saat potret close-up
		var best_rb: RigidBody3D = enemies[0]["rb"]
		for e in enemies:
			var erb: RigidBody3D = e["rb"]
			if is_instance_valid(erb) and (not is_instance_valid(best_rb) or erb.global_position.y > best_rb.global_position.y):
				best_rb = erb
		if is_instance_valid(best_rb):
			cam.fov = 34.0
			var target := best_rb.global_position + Vector3(-0.06, 0.06, 0.0)
			cam.position = target + Vector3(-0.95, 0.45, 2.25)
			cam.look_at(target, Vector3.UP)
			return
	var span_x: float = maxf(stage_max_x - stage_min_x, 24.0)
	var mid_x: float = (stage_min_x + stage_max_x) * 0.5
	var mid_y: float = clampf(stage_max_y * 0.44, 2.3, 4.7)

	# Smooth horizontal camera pan (A/D or Left/Right arrow keys, clamped to stage bounds)
	var pan_dir: float = 0.0
	if not stage_ended and capture_stage_path == "" and capture_croco_path == "":
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			pan_dir -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			pan_dir += 1.0
	var max_pan_left: float = minf((stage_min_x + 4.0) - mid_x, -5.0)
	var max_pan_right: float = maxf((stage_max_x - 4.0) - mid_x, 5.0)
	if pan_dir != 0.0:
		cam_pan_target_x = clampf(cam_pan_target_x + pan_dir * 20.0 * delta, max_pan_left, max_pan_right)
	elif is_aiming or is_flying:
		cam_pan_target_x = lerpf(cam_pan_target_x, 0.0, clampf(delta * 4.5, 0.0, 1.0))
	cam_pan_x = lerpf(cam_pan_x, cam_pan_target_x, clampf(delta * 10.0, 0.0, 1.0))

	var desired_pos := Vector3.ZERO
	var desired_fov: float = 34.0
	var look_target := Vector3(mid_x + cam_pan_x, mid_y, 0.0)
	if custom_orbit_active:
		desired_fov = 45.0
		var center := Vector3(mid_x + 1.0 + cam_pan_x, mid_y, 0.0)
		var dist: float = maxf(span_x * 0.78, 22.0) + cam_zoom_offset
		desired_pos = center + Vector3(-sin(orbit_yaw) * cos(orbit_pitch) * dist, sin(orbit_pitch) * dist + 1.2, cos(orbit_yaw) * cos(orbit_pitch) * dist)
		look_target = center
	else:
		match current_view:
			CameraView.SIDE_25D:
				desired_fov = 34.0
				var z_fit_x: float = (span_x * 0.54) / (tan(deg_to_rad(17.0)) * 1.72)
				var z_fit_y: float = ((stage_max_y + 1.8) * 0.62) / tan(deg_to_rad(17.0))
				var cam_z: float = maxf(maxf(z_fit_x, z_fit_y), 25.0) + cam_zoom_offset
				var fx: float = mid_x + cam_pan_x
				if is_flying and is_instance_valid(active_capy):
					fx = lerpf(mid_x, clampf(active_capy.position.x, stage_min_x + 4.0, stage_max_x - 3.0), 0.38) + cam_pan_x
				desired_pos = Vector3(fx, mid_y + 0.55, cam_z)
				look_target = Vector3(fx, mid_y, 0.0)
			CameraView.ANGLED_25D:
				desired_fov = 42.0
				var cam_z: float = maxf(span_x * 0.74, 22.0) + cam_zoom_offset
				var fx: float = mid_x + cam_pan_x
				if is_flying and is_instance_valid(active_capy):
					fx = lerpf(mid_x, clampf(active_capy.position.x, stage_min_x + 4.0, stage_max_x - 3.0), 0.42) + cam_pan_x
				desired_pos = Vector3(fx - 5.8, mid_y + 3.0, cam_z)
				look_target = Vector3(fx + 1.4, mid_y - 0.1, 0.0)
			CameraView.BEHIND_3D:
				desired_fov = 54.0
				desired_pos = Vector3(sling_x - 4.4 - cam_zoom_offset * 0.4, sling_base_y + 4.1, 0.6)
				look_target = Vector3(stage_max_x * 0.6, mid_y, 0.0)
	if snap_camera:
		cam.fov = desired_fov
		cam.position = desired_pos
		snap_camera = false
	else:
		cam.fov = lerpf(cam.fov, desired_fov, clampf(delta * 6.0, 0.0, 1.0))
		cam.position = cam.position.lerp(desired_pos, clampf(delta * 7.5, 0.0, 1.0))
	cam.look_at(look_target, Vector3.UP)
	if shake_trauma > 0.01 and capture_stage_path == "" and capture_croco_path == "" and capture_pause_path == "":
		var mag := shake_trauma * shake_trauma * 0.42
		cam.position += Vector3(randf_range(-mag, mag), randf_range(-mag, mag), 0.0)
