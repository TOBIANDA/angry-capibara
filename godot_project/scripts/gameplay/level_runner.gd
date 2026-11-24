extends Node3D

# World 1 Gameplay Engine (Data-Driven LevelRunner) — Angry Capibara
# Memuat 20 Sub-Level JSON (data/levels/w1/1-1.json .. 1-20.json) dengan gaya visual
# Anti-Slop 2.5D Lineless Painterly (DESIGN.md + rovio_25d.gdshader), 3 Kapibara World 1
# (Chill, Dash, Trio Mini + Triple Split nyata), 4 material (Bambu, Kayu, Es/Kaca, Tong Yuzu TNT),
# 2 musuh (Croc Minion & Mini-Boss Mahkota 1-20), sistem skor + Yuzu Combo + 1-3 Bintang lokal!

enum CameraView { SIDE_25D = 0, ANGLED_25D = 1, BEHIND_3D = 2 }

const WORLD1_SELECT_SCENE := "res://scenes/ui/world1_select.tscn"
const HOME_SCENE := "res://scenes/ui/home_screen.tscn"

const LAUNCH_X := -6.5
const LAUNCH_Y := 1.75
const GRAVITY := 18.0
const MAX_PULL_DIST := 2.95
const LAUNCH_POWER := 8.9

const CAPY_SPECS := {
	"chill": {
		"name": "Chill Capi",
		"mesh": "res://assets/generated/models/anime_capy_chill.obj",
		"mass": 2.0,
		"radius": 0.36,
		"skill_desc": "Zen Bump (getar ke bawah)"
	},
	"dash": {
		"name": "Dash Capi",
		"mesh": "res://assets/generated/models/anime_capy_dash.obj",
		"mass": 1.8,
		"radius": 0.35,
		"skill_desc": "Turbo Dash 2.2x (1.8x ke Kayu)"
	},
	"mini": {
		"name": "Trio Mini-Capi",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"mass": 1.0,
		"radius": 0.25,
		"skill_desc": "Triple Split 3x (2.0x ke Es/Kaca)"
	}
}

const MAT_SPECS := {
	"bamboo": { "hp": 30.0, "mass": 0.85, "thresh": 2.4, "score": 300 },
	"ice":    { "hp": 40.0, "mass": 1.00, "thresh": 2.0, "score": 500 },
	"wood":   { "hp": 75.0, "mass": 1.50, "thresh": 3.8, "score": 600 },
	"tnt":    { "hp": 20.0, "mass": 1.20, "thresh": 2.6, "score": 1500 }
}

var current_stage_id: String = "1-1"
var stage_data: Dictionary = {}
var current_view: int = CameraView.ANGLED_25D

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

# Camera orbit state
var orbit_active: bool = false
var custom_orbit_active: bool = false
var orbit_yaw: float = 0.35
var orbit_pitch: float = 0.22
var cam_zoom_offset: float = 0.0

# HUD & Overlays
var lbl_stage_title: Label
var lbl_score: Label
var lbl_queue_info: Label
var lbl_tip: Label
var btn_views: Array[Button] = []
var result_overlay: ColorRect
var result_title: Label
var result_stars: Label
var result_body: Label
var btn_next_stage: Button

# CLI flags for capture & automated 20-stage stability validation
var capture_stage_path: String = ""
var capture_croco_path: String = ""
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

	arena_root = Node3D.new()
	add_child(arena_root)
	queue_visual_root = Node3D.new()
	add_child(queue_visual_root)

	_load_stage(current_stage_id)
	_set_camera_view(CameraView.ANGLED_25D)

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
	shape.size = Vector3(48.0, 2.0, 14.0)
	col.shape = shape
	ground.position = Vector3(1.0, -1.0, 0.0)
	ground.add_child(col)

	var moss_top := MeshInstance3D.new()
	var mt := BoxMesh.new()
	mt.size = Vector3(40.0, 0.42, 11.0)
	moss_top.mesh = mt
	moss_top.position = Vector3(0.0, 0.79, 0.0)
	var moss_mat := _make_rovio_mat(tex_moss, Color(0.68, 0.80, 0.56), Vector2(5.5, 1.8), 0.10, 0.05)
	moss_mat.set_shader_parameter("shadow_tint", Vector3(0.36, 0.46, 0.38))
	moss_top.material_override = moss_mat
	ground.add_child(moss_top)

	var cliff := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(39.4, 3.6, 10.4)
	cliff.mesh = cm
	cliff.position = Vector3(0.0, -1.20, 0.0)
	cliff.material_override = _make_rovio_mat(tex_cliff, Color(0.68, 0.62, 0.56), Vector2(6.5, 1.2), 0.06, 0.04)
	ground.add_child(cliff)
	add_child(ground)

	# Jalan setapak pasir hangat di Z=0
	var lane := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(24.0, 0.025, 0.44)
	lane.mesh = lm
	lane.position = Vector3(1.5, 0.015, 0.0)
	var lane_mat := _make_rovio_mat(null, Color(0.76, 0.68, 0.52), Vector2.ONE, 0.0, 0.02)
	lane_mat.set_shader_parameter("shadow_tint", Vector3(0.56, 0.48, 0.38))
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
		[Vector3(-12.5, -1.5, -14.0), Vector3(2.3, 3.8, 1.6), Color(0.36, 0.54, 0.44)],
		[Vector3(  2.0, -2.0, -18.5), Vector3(3.4, 4.4, 1.8), Color(0.45, 0.62, 0.57)],
		[Vector3( 15.5, -1.4, -14.5), Vector3(2.5, 4.0, 1.6), Color(0.34, 0.52, 0.42)],
		[Vector3( -5.0, -1.8, -11.5), Vector3(1.6, 2.2, 1.3), Color(0.41, 0.58, 0.40)]
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
	onsen.position = Vector3(-5.8, 0.85, -10.8)
	onsen.rotation_degrees = Vector3(0.0, 16.0, 0.0)
	onsen.scale = Vector3.ONE * 1.18
	_apply_rovio_model_materials(onsen)
	scenery.add_child(onsen)

	var torii := MeshInstance3D.new()
	torii.mesh = load("res://assets/generated/models/prop_torii_gate.obj")
	torii.position = Vector3(11.6, 0.55, -8.8)
	torii.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	torii.scale = Vector3.ONE * 1.12
	_apply_rovio_model_materials(torii)
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
		[Vector3(-11.4, 0.1, -5.8), Vector3(0.0, 14.0, -3.0), 1.85],
		[Vector3( 14.0, 0.1, -6.2), Vector3(0.0, -158.0, 3.0), 1.90]
	]:
		var grove := MeshInstance3D.new()
		grove.mesh = grove_mesh
		grove.position = bg_cfg[0]
		grove.rotation_degrees = bg_cfg[1]
		grove.scale = Vector3.ONE * float(bg_cfg[2])
		_apply_rovio_model_materials(grove)
		scenery.add_child(grove)

	for cp in [Vector3(-11.0, 7.6, -15.5), Vector3(11.5, 7.8, -16.0), Vector3(-2.5, 9.2, -18.5)]:
		var cl := MeshInstance3D.new()
		cl.mesh = cloud_mesh
		cl.position = cp
		cl.scale = Vector3(2.4, 1.7, 1.3)
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
		var st := Vector3(-10.0 + float(i) * 2.8, 2.4 + fmod(float(i) * 1.7, 5.0), -2.8 + sin(float(i)) * 2.0)
		lf.position = st
		scenery.add_child(lf)
		bg_leaves.append({ "node": lf, "base": st, "phase": float(i) * 1.1 })

func _setup_slingshot() -> void:
	slingshot_visual = Node3D.new()
	slingshot_visual.position = Vector3(LAUNCH_X, 0.0, 0.0)
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
	for i in 18:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = lerp(0.105, 0.042, float(i) / 17.0)
		sm.height = sm.radius * 2.0
		mi.mesh = sm
		mi.material_override = dot_mat
		mi.visible = false
		add_child(mi)
		traj_dots.append(mi)

func _setup_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var hud_sb := StyleBoxFlat.new()
	hud_sb.bg_color = Color(0.15, 0.11, 0.10, 0.92)
	hud_sb.border_color = Color(0.80, 0.72, 0.56, 0.85)
	hud_sb.set_border_width_all(2)
	hud_sb.set_corner_radius_all(10)

	# TOP-LEFT: Navigasi & Kamera
	var top_l := PanelContainer.new()
	top_l.position = Vector2(14, 12)
	top_l.add_theme_stylebox_override("panel", hud_sb)
	canvas.add_child(top_l)

	var tl_mar := MarginContainer.new()
	tl_mar.add_theme_constant_override("margin_left", 10)
	tl_mar.add_theme_constant_override("margin_right", 10)
	tl_mar.add_theme_constant_override("margin_top", 6)
	tl_mar.add_theme_constant_override("margin_bottom", 6)
	top_l.add_child(tl_mar)

	var tl_row := HBoxContainer.new()
	tl_row.add_theme_constant_override("separation", 6)
	tl_mar.add_child(tl_row)

	var btn_map := _make_hud_btn("← PETA W1", false)
	btn_map.pressed.connect(func(): get_tree().change_scene_to_file(WORLD1_SELECT_SCENE))
	tl_row.add_child(btn_map)

	var btn_restart := _make_hud_btn("[R] Ulang", false)
	btn_restart.pressed.connect(func(): _load_stage(current_stage_id))
	tl_row.add_child(btn_restart)

	for i in 3:
		var names := ["[1] 2.5D", "[2] Serong", "[3] 3D"]
		var b := _make_hud_btn(names[i], false)
		b.toggle_mode = true
		var idx := i
		b.pressed.connect(func(): _set_camera_view(idx))
		tl_row.add_child(b)
		btn_views.append(b)

	# TOP-RIGHT: Stage Title & Score Counter
	var top_r := PanelContainer.new()
	top_r.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_r.offset_left = -390
	top_r.offset_right = -14
	top_r.offset_top = 12
	top_r.offset_bottom = 64
	top_r.add_theme_stylebox_override("panel", hud_sb)
	canvas.add_child(top_r)

	var tr_mar := MarginContainer.new()
	tr_mar.add_theme_constant_override("margin_left", 14)
	tr_mar.add_theme_constant_override("margin_right", 14)
	tr_mar.add_theme_constant_override("margin_top", 6)
	tr_mar.add_theme_constant_override("margin_bottom", 6)
	top_r.add_child(tr_mar)

	var tr_vb := VBoxContainer.new()
	tr_vb.add_theme_constant_override("separation", 1)
	tr_mar.add_child(tr_vb)

	lbl_stage_title = Label.new()
	lbl_stage_title.add_theme_font_size_override("font_size", 14)
	lbl_stage_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	lbl_stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_vb.add_child(lbl_stage_title)

	lbl_score = Label.new()
	lbl_score.add_theme_font_size_override("font_size", 13)
	lbl_score.add_theme_color_override("font_color", Color(0.95, 0.84, 0.46))
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_vb.add_child(lbl_score)

	# BOTTOM BAR: Active Capybara Skill & Stage Tip
	var bot := PanelContainer.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bot.offset_left = 14
	bot.offset_right = 880
	bot.offset_top = -62
	bot.offset_bottom = -12
	bot.add_theme_stylebox_override("panel", hud_sb)
	canvas.add_child(bot)

	var b_mar := MarginContainer.new()
	b_mar.add_theme_constant_override("margin_left", 12)
	b_mar.add_theme_constant_override("margin_right", 12)
	b_mar.add_theme_constant_override("margin_top", 5)
	b_mar.add_theme_constant_override("margin_bottom", 5)
	bot.add_child(b_mar)

	var b_vb := VBoxContainer.new()
	b_vb.add_theme_constant_override("separation", 2)
	b_mar.add_child(b_vb)

	lbl_queue_info = Label.new()
	lbl_queue_info.add_theme_font_size_override("font_size", 13)
	lbl_queue_info.add_theme_color_override("font_color", Color(0.96, 0.86, 0.50))
	b_vb.add_child(lbl_queue_info)

	lbl_tip = Label.new()
	lbl_tip.add_theme_font_size_override("font_size", 12)
	lbl_tip.add_theme_color_override("font_color", Color(0.88, 0.84, 0.76))
	b_vb.add_child(lbl_tip)

	# RESULT OVERLAY (Win / Lose)
	result_overlay = ColorRect.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.08, 0.06, 0.05, 0.76)
	result_overlay.visible = false
	canvas.add_child(result_overlay)

	var rpanel := PanelContainer.new()
	rpanel.set_anchors_preset(Control.PRESET_CENTER)
	rpanel.offset_left = -250
	rpanel.offset_right = 250
	rpanel.offset_top = -170
	rpanel.offset_bottom = 170
	rpanel.add_theme_stylebox_override("panel", hud_sb)
	result_overlay.add_child(rpanel)

	var rmar := MarginContainer.new()
	rmar.add_theme_constant_override("margin_left", 24)
	rmar.add_theme_constant_override("margin_right", 24)
	rmar.add_theme_constant_override("margin_top", 20)
	rmar.add_theme_constant_override("margin_bottom", 20)
	rpanel.add_child(rmar)

	var rvb := VBoxContainer.new()
	rvb.add_theme_constant_override("separation", 12)
	rmar.add_child(rvb)

	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 26)
	result_title.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	rvb.add_child(result_title)

	result_stars = Label.new()
	result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stars.add_theme_font_size_override("font_size", 36)
	result_stars.add_theme_color_override("font_color", Color(0.96, 0.82, 0.36))
	rvb.add_child(result_stars)

	result_body = Label.new()
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.add_theme_font_size_override("font_size", 14)
	result_body.add_theme_color_override("font_color", Color(0.90, 0.86, 0.78))
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	rvb.add_child(result_body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 10)
	rvb.add_child(btn_row)

	var btn_retry := _make_hud_btn("ULANGI", false)
	btn_retry.custom_minimum_size = Vector2(115, 42)
	btn_retry.pressed.connect(func(): _load_stage(current_stage_id))
	btn_row.add_child(btn_retry)

	btn_next_stage = _make_hud_btn("STAGE BERIKUTNYA →", true)
	btn_next_stage.custom_minimum_size = Vector2(185, 42)
	btn_next_stage.pressed.connect(_go_next_stage)
	btn_row.add_child(btn_next_stage)

	var btn_back := _make_hud_btn("PETA W1", false)
	btn_back.custom_minimum_size = Vector2(105, 42)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file(WORLD1_SELECT_SCENE))
	btn_row.add_child(btn_back)

func _make_hud_btn(txt: String, is_primary: bool) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.94))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.80, 0.22, 0.16) if is_primary else Color(0.22, 0.17, 0.15, 0.96)
	sb.border_color = Color(0.95, 0.86, 0.66) if is_primary else Color(0.72, 0.64, 0.50, 0.80)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var hv := sb.duplicate()
	hv.bg_color = sb.bg_color.lightened(0.14)
	var pr := sb.duplicate()
	pr.bg_color = Color(0.80, 0.22, 0.16)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", pr)
	return b

# =========================================================================
# JSON STAGE LOADER & SPAWNER
# =========================================================================

func _load_stage(stage_id: String) -> void:
	current_stage_id = stage_id
	SaveManager.selected_stage_id = stage_id

	for c in arena_root.get_children():
		c.queue_free()
	for c in queue_visual_root.get_children():
		c.queue_free()

	blocks.clear()
	enemies.clear()
	flying_projectiles.clear()
	vfx_nodes.clear()
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
	result_overlay.visible = false
	_hide_trajectory()

	var path := "res://data/levels/w1/%s.json" % stage_id
	if not FileAccess.file_exists(path):
		push_error("Stage JSON not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		push_error("Invalid stage JSON: " + path)
		return
	stage_data = parsed

	capy_queue.clear()
	var q_raw: Array = stage_data.get("queue", ["chill"])
	for item in q_raw:
		capy_queue.append(str(item))

	var b_raw: Array = stage_data.get("blocks", [])
	for b_def in b_raw:
		_spawn_block_from_def(b_def)

	var e_raw: Array = stage_data.get("enemies", [])
	for e_def in e_raw:
		_spawn_enemy_from_def(e_def)

	lbl_stage_title.text = "W1 %s — %s" % [stage_id, str(stage_data.get("name", stage_id))]
	lbl_tip.text = str(stage_data.get("tip", ""))
	_load_next_capy_onto_slingshot()
	_refresh_score_hud()

func _spawn_block_from_def(def: Dictionary) -> void:
	var btype: String = str(def.get("type", "bamboo"))
	var pos_arr: Array = def.get("pos", [5.0, 0.8])
	var sz_arr: Array = def.get("size", [0.4, 1.5, 0.9])
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), 0.0)
	var sz := Vector3(float(sz_arr[0]), float(sz_arr[1]), float(sz_arr[2]))

	var spec: Dictionary = MAT_SPECS.get(btype, MAT_SPECS["bamboo"])
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = float(spec["mass"])
	rb.axis_lock_linear_z = true
	rb.axis_lock_angular_x = true
	rb.axis_lock_angular_y = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 6
	rb.linear_damp = 0.25
	rb.angular_damp = 0.35

	var pm := PhysicsMaterial.new()
	pm.friction = 0.22 if btype == "ice" else 0.72
	pm.bounce = 0.04
	rb.physics_material_override = pm

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape
	rb.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm

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
		# Pita emas Yuzu TNT di sekeliling tong agar langsung dikenali!
		var band := MeshInstance3D.new()
		var bbm := BoxMesh.new()
		bbm.size = Vector3(sz.x * 1.04, sz.y * 0.24, sz.z * 1.04)
		band.mesh = bbm
		band.material_override = _make_rovio_mat(null, Color(0.96, 0.78, 0.24), Vector2.ONE, 0.20, 0.25)
		rb.add_child(band)
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
	rb.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	rb.mass = float(spec["mass"])
	rb.freeze = true
	rb.continuous_cd = true
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
	for i in capy_queue.size():
		var cid: String = capy_queue[i]
		var mi := MeshInstance3D.new()
		mi.mesh = capy_meshes.get(cid, capy_meshes["chill"])
		_apply_rovio_model_materials(mi)
		mi.position = Vector3(LAUNCH_X - 1.75 - float(i) * 1.05, 0.36, 0.0)
		mi.set_meta("base_y", 0.36)
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
			if is_instance_valid(mi) and mi.material_override is ShaderMaterial:
				(mi.material_override as ShaderMaterial).set_shader_parameter("tint_color", Color(0.62, 0.54, 0.48))

func _tint_enemy_mesh(rec: Dictionary, tint: Color) -> void:
	var mi: MeshInstance3D = rec["mi"]
	if not is_instance_valid(mi) or mi.mesh == null:
		return
	for s_idx in mi.mesh.get_surface_count():
		var mat := mi.get_surface_override_material(s_idx)
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("tint_color", tint)

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
	score += int(round(float(rec["score"]) * mult))
	_refresh_score_hud()

	if is_instance_valid(rb):
		rb.queue_free()

	if is_enemy:
		_spawn_vfx_sphere(pos, 1.5, Color(0.54, 0.88, 0.44))
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
		else:
			_spawn_vfx_sphere(pos, 1.0, Color(0.88, 0.78, 0.56))

func _trigger_tnt_explosion(center: Vector3) -> void:
	_spawn_vfx_sphere(center, 4.8, Color(0.95, 0.42, 0.14))
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
		"mini":
			# TRIPLE SPLIT: Spawn 2 klon Trio Mini-Capi menyebar +12 deg dan -12 deg!
			var base_vel := active_capy.linear_velocity
			if base_vel.length() < 4.0:
				base_vel = Vector3(14.0, 2.0, 0.0)
			_spawn_vfx_sphere(pos, 1.3, Color(0.45, 0.84, 0.98))
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
			KEY_R: _load_stage(current_stage_id)
			KEY_ESCAPE: get_tree().change_scene_to_file(WORLD1_SELECT_SCENE)
			KEY_SPACE:
				if is_flying and not skill_used:
					_activate_skill()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbit_active = event.pressed
			if event.pressed:
				custom_orbit_active = true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_zoom_offset = clampf(cam_zoom_offset - 1.2, -5.0, 9.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_zoom_offset = clampf(cam_zoom_offset + 1.2, -5.0, 9.0)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_flying and not skill_used:
					_activate_skill()
				elif not is_flying and is_instance_valid(active_capy):
					is_aiming = true
					drag_start_px = event.position
					pull_vector = Vector3.ZERO
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
				active_capy.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0) + pull_vector * 0.65
			_update_trajectory_preview()

func _release_slingshot() -> void:
	is_aiming = false
	_hide_trajectory()
	if not is_instance_valid(active_capy):
		return
	var launch_vel := -pull_vector * LAUNCH_POWER
	if launch_vel.length() < 3.0:
		active_capy.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
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

func _physics_process(delta: float) -> void:
	if spawn_grace > 0.0:
		spawn_grace = maxf(spawn_grace - delta, 0.0)

	# Simpan kecepatan frame sebelumnya untuk perhitungan impak fisik yang akurat
	for b in blocks:
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
			p.set_meta("last_vel", p.linear_velocity)

func _process(delta: float) -> void:
	anim_time += delta

	if validate_all_w1:
		_process_automated_validator(delta)
		return

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0

	_update_slingshot_bands()
	_update_capy_anim(delta)
	_update_enemy_anim(delta)
	_update_camera(delta)
	_update_vfx(delta)

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
		var speed_now: float = active_capy.linear_velocity.length() if is_instance_valid(active_capy) else 0.0
		var out_of_bounds: bool = is_instance_valid(active_capy) and (active_capy.global_position.y < -4.0 or active_capy.global_position.x > 20.0)
		if speed_now < 0.75 or out_of_bounds:
			settle_timer += delta
		else:
			settle_timer = 0.0
		if flight_timer > 5.0 or settle_timer > 1.35:
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

	result_title.text = "STAGE %s SELESAI!" % current_stage_id
	var st_txt := ""
	for k in 3:
		st_txt += "★ " if k < stars else "☆ "
	result_stars.text = st_txt.strip_edges()
	result_body.text = "Skor Akhir: %d\n(Termasuk Bonus Sisa %d Kapibara: +%d)\nTarget 3 Bintang: %d" % [score, unused_capys, bonus, s3]
	btn_next_stage.visible = (SaveManager.get_next_stage_id(current_stage_id) != "")
	result_overlay.visible = true

func _finish_stage_defeat() -> void:
	stage_ended = true
	result_title.text = "BELUM BERHASIL"
	result_stars.text = "☆ ☆ ☆"
	result_body.text = "Masih ada %d Klan Buaya bertahan.\nCoba sudut bidikan atau aktifkan skill kapibara di udara!" % enemies.size()
	btn_next_stage.visible = false
	result_overlay.visible = true

func _go_next_stage() -> void:
	var nxt := SaveManager.get_next_stage_id(current_stage_id)
	if nxt != "":
		_load_stage(nxt)
	else:
		get_tree().change_scene_to_file(WORLD1_SELECT_SCENE)

func _refresh_score_hud() -> void:
	var best: int = SaveManager.get_stage_best_score(current_stage_id)
	lbl_score.text = "Skor: %d  |  Buaya: %d  |  Rekor: %d" % [score, enemies.size(), best]

func _refresh_queue_hud() -> void:
	if is_instance_valid(active_capy):
		var spec: Dictionary = CAPY_SPECS.get(active_capy_type, CAPY_SPECS["chill"])
		lbl_queue_info.text = "Aktif: %s  •  Skill (Klik/Spasi): %s  •  Sisa Antrean: %d" % [
			str(spec["name"]), str(spec["skill_desc"]), capy_queue.size()
		]
	else:
		lbl_queue_info.text = "Seluruh kapibara sudah diluncurkan — menunggu benteng tumbang..."

func _set_camera_view(view_idx: int) -> void:
	current_view = view_idx
	custom_orbit_active = false
	cam_zoom_offset = 0.0
	for i in btn_views.size():
		btn_views[i].set_pressed_no_signal(i == view_idx)

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
	var target := Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	if is_aiming and is_instance_valid(active_capy):
		target = active_capy.position
	_stretch_band(band_mesh_a, Vector3(LAUNCH_X, 1.82,  0.42), target)
	_stretch_band(band_mesh_b, Vector3(LAUNCH_X, 1.82, -0.42), target)

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
	var start_p := active_capy.position if is_instance_valid(active_capy) else Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	for i in traj_dots.size():
		var t := float(i + 1) * 0.075
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
	var desired_pos := Vector3.ZERO
	var look_target := Vector3(1.8, 2.0, 0.0)
	if custom_orbit_active:
		cam.fov = lerpf(cam.fov, 45.0, delta * 6.0)
		var center := Vector3(2.2, 2.0, 0.0)
		var dist := 16.5 + cam_zoom_offset
		desired_pos = center + Vector3(-sin(orbit_yaw) * cos(orbit_pitch) * dist, sin(orbit_pitch) * dist + 1.2, cos(orbit_yaw) * cos(orbit_pitch) * dist)
		look_target = center
	else:
		match current_view:
			CameraView.SIDE_25D:
				cam.fov = lerpf(cam.fov, 34.0, delta * 6.0)
				var fx := 1.2
				if is_flying and is_instance_valid(active_capy):
					fx = clampf(active_capy.position.x * 0.45, -1.0, 5.5)
				desired_pos = Vector3(fx, 2.6, 22.0 + cam_zoom_offset)
				look_target = Vector3(fx, 2.0, 0.0)
			CameraView.ANGLED_25D:
				cam.fov = lerpf(cam.fov, 44.0, delta * 6.0)
				var fx := 1.4
				if is_flying and is_instance_valid(active_capy):
					fx = clampf(active_capy.position.x * 0.45, -1.0, 5.5)
				desired_pos = Vector3(fx - 5.2, 4.8, 15.8 + cam_zoom_offset)
				look_target = Vector3(fx + 1.4, 1.8, 0.0)
			CameraView.BEHIND_3D:
				cam.fov = lerpf(cam.fov, 54.0, delta * 6.0)
				desired_pos = Vector3(LAUNCH_X - 4.4 - cam_zoom_offset * 0.4, 4.1, 0.6)
				look_target = Vector3(5.8, 1.8, 0.0)
	cam.position = cam.position.lerp(desired_pos, clampf(delta * 7.5, 0.0, 1.0))
	cam.look_at(look_target, Vector3.UP)
