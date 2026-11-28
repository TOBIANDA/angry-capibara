extends Node3D

enum CameraView { SIDE_25D = 0, ANGLED_25D = 1, BEHIND_3D = 2 }

const LAUNCH_X := -6.5
const LAUNCH_Y := 1.75
const GRAVITY := 18.0
const MAX_PULL_DIST := 2.9
const LAUNCH_POWER := 8.8

const WORLD1_SELECT_SCENE := "res://scenes/ui/world1_select.tscn"
const HOME_SCENE := "res://scenes/ui/home_screen.tscn"

const CAPY_ROSTER := [
	{ "id": "chill",        "short": "CHILL",  "name": "1. Chill Capi",        "portrait": "res://assets/generated/home2d/char_01_chill_roar.png",   "mesh": "res://assets/generated/models/capy_chill.obj",        "anime_mesh": "res://assets/generated/models/anime_capy_chill.obj",        "mass": 2.0, "radius": 0.36, "skill": "Zen Bump (getar ke bawah)" },
	{ "id": "dash",         "short": "DASH",   "name": "2. Dash Capi",         "portrait": "res://assets/generated/home2d/char_06_dash_leap.png",    "mesh": "res://assets/generated/models/capy_dash.obj",         "anime_mesh": "res://assets/generated/models/anime_capy_dash.obj",         "mass": 1.8, "radius": 0.35, "skill": "Turbo Dash 2.2x" },
	{ "id": "mini",         "short": "MINI",   "name": "3. Trio Mini-Capi",    "portrait": "res://assets/generated/home2d/char_07_mini_capi.png",    "mesh": "res://assets/generated/models/capy_mini.obj",         "anime_mesh": "res://assets/generated/models/anime_capy_mini.obj",         "mass": 1.0, "radius": 0.25, "skill": "Preview Model Trio Mini" },
	{ "id": "yuzu_bomb",    "short": "YUZU",   "name": "4. Yuzu Bomb Capi",    "portrait": "res://assets/generated/home2d/char_02_yuzu_bomb.png",    "mesh": "res://assets/generated/models/capy_yuzu_bomb.obj",    "anime_mesh": "res://assets/generated/models/anime_capy_yuzu_bomb.obj",    "mass": 2.5, "radius": 0.40, "skill": "Ledakan Area Yuzu (r=4.5m)" },
	{ "id": "seed_blaster", "short": "SEED",   "name": "5. Seed-Blaster Capi", "portrait": "res://assets/generated/home2d/char_04_seed_blaster.png", "mesh": "res://assets/generated/models/capy_seed_blaster.obj", "anime_mesh": "res://assets/generated/models/anime_capy_seed_blaster.obj", "mass": 2.0, "radius": 0.37, "skill": "Preview Model Seed-Blaster" },
	{ "id": "bambu_saber",  "short": "KATANA", "name": "6. Bambu-Katana Capi", "portrait": "res://assets/generated/home2d/char_05_bambu_katana.png", "mesh": "res://assets/generated/models/capy_bambu_saber.obj",  "anime_mesh": "res://assets/generated/models/anime_capy_katana.obj",       "mass": 2.1, "radius": 0.37, "skill": "Tebasan Katana 360° (r=3.0m)" },
	{ "id": "heavy_onsen",  "short": "HEAVY",  "name": "7. Heavy Onsen Capi",  "portrait": "res://assets/generated/home2d/char_03_heavy_onsen.png",  "mesh": "res://assets/generated/models/capy_heavy_onsen.obj",  "anime_mesh": "res://assets/generated/models/anime_capy_heavy_onsen.obj",  "mass": 4.8, "radius": 0.48, "skill": "Pasif: Massa Jumbo Penembus" },
]

var current_view: int = CameraView.ANGLED_25D
var current_capy_idx: int = 0
var use_anime_style: bool = true
var btn_style_toggle: Button
var shader_toon: Shader
var shader_outline: Shader

# Scene nodes
var cam: Camera3D
var sun: DirectionalLight3D
var world_env: WorldEnvironment
var arena_root: Node3D
var slingshot_visual: Node3D
var band_mesh_a: MeshInstance3D
var band_mesh_b: MeshInstance3D
var traj_dots: Array[MeshInstance3D] = []
var active_capy: RigidBody3D = null
var capy_visual: Node3D = null
var blocks: Array[RigidBody3D] = []
var vfx_nodes: Array[Dictionary] = []

# Aiming & camera state
var is_aiming: bool = false
var drag_start_px: Vector2 = Vector2.ZERO
var pull_vector: Vector3 = Vector3.ZERO
var is_flying: bool = false
var skill_used: bool = false
var flight_timer: float = 0.0
var anim_time: float = 0.0

var orbit_active: bool = false
var custom_orbit_active: bool = false
var orbit_yaw: float = 0.35
var orbit_pitch: float = 0.22
var cam_zoom_offset: float = 0.0

# UI nodes
var lbl_mode_desc: Label
var lbl_capy_info: Label
var btn_views: Array[Button] = []
var btn_capys: Array[Button] = []
var capy_tile_labels: Array[Label] = []
var capy_tile_portraits: Array[TextureRect] = []

# Cached textures & scenery animation
var tex_wood: Texture2D
var tex_bamboo: Texture2D
var tex_stone: Texture2D
var tex_moss: Texture2D
var tex_cliff: Texture2D
var mesh_croco: Mesh
var mesh_slingshot: Mesh
var steam_puffs: Array[Dictionary] = []
var bg_leaves: Array[Dictionary] = []
var sun_rays_node: Node3D = null
var capture_arena_path: String = ""
var capture_arena_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-arena="):
			capture_arena_path = arg.substr(16)

	tex_wood = load("res://assets/generated/textures/tex_wood.bmp")
	tex_bamboo = load("res://assets/generated/textures/tex_bamboo.bmp")
	tex_stone = load("res://assets/generated/textures/tex_stone.bmp")
	tex_moss = load("res://assets/generated/textures/tex_moss_painterly.bmp")
	tex_cliff = load("res://assets/generated/textures/tex_cliff_rock.bmp")
	mesh_croco = load("res://assets/generated/models/enemy_croco_minion.obj")
	mesh_slingshot = load("res://assets/generated/models/prop_slingshot_bamboo.obj")
	shader_toon = load("res://shaders/rovio_25d.gdshader")
	shader_outline = null

	_setup_environment()
	_setup_ground()
	_setup_bamboo_onsen_scenery()
	_setup_slingshot_visual()
	_setup_trajectory_dots()
	_setup_ui()

	arena_root = Node3D.new()
	add_child(arena_root)

	_reset_arena()
	_set_camera_view(CameraView.ANGLED_25D)

func _setup_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	# Palet langit Woodblock/Ghibli Anti-Slop (DESIGN.md — serasi 100% dengan Home 2D!)
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
	env.glow_intensity = 0.22
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.18

	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

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

func _make_25d_mat(tex: Texture2D, tint: Color = Color.WHITE, uv_sc: Vector2 = Vector2.ONE, rim_str: float = 0.18, sheen_str: float = 0.10) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader_toon
	if tex:
		mat.set_shader_parameter("albedo_tex", tex)
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("uv_scale", uv_sc)
	mat.set_shader_parameter("rim_strength", rim_str)
	mat.set_shader_parameter("sheen_strength", sheen_str)
	mat.set_shader_parameter("shadow_tint", Vector3(0.46, 0.42, 0.48))
	mat.set_shader_parameter("rim_color", Vector3(0.98, 0.92, 0.76))
	return mat

func _setup_ground() -> void:
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(44.0, 2.0, 14.0)
	col.shape = shape
	ground.position = Vector3(1.0, -1.0, 0.0)
	ground.add_child(col)

	# Lapisan rumput lumut gouache halus (matcha-olive alami sesuai DESIGN.md, nol bintik statis!)
	var moss_top := MeshInstance3D.new()
	var mt := BoxMesh.new()
	mt.size = Vector3(36.0, 0.42, 10.5)
	moss_top.mesh = mt
	moss_top.position = Vector3(0.0, 0.79, 0.0)
	var moss_mat := _make_25d_mat(tex_moss, Color(0.68, 0.80, 0.56), Vector2(5.0, 1.8), 0.10, 0.05)
	moss_mat.set_shader_parameter("shadow_tint", Vector3(0.36, 0.46, 0.38))
	moss_top.material_override = moss_mat
	ground.add_child(moss_top)

	# Dinding tebing tanah-batu hangat di bawah rumput
	var cliff := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(35.4, 3.6, 10.0)
	cliff.mesh = cm
	cliff.position = Vector3(0.0, -1.20, 0.0)
	var cliff_mat := _make_25d_mat(tex_cliff, Color(0.68, 0.62, 0.56), Vector2(6.0, 1.2), 0.06, 0.04)
	cliff.material_override = cliff_mat
	ground.add_child(cliff)
	add_child(ground)

	# Penanda lintasan jalan setapak tanah hangat halus di Z=0 (bukan garis hitam!)
	var lane := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(22.0, 0.025, 0.42)
	lane.mesh = lm
	lane.position = Vector3(2.0, 0.015, 0.0)
	var lane_mat := _make_25d_mat(null, Color(0.76, 0.68, 0.52), Vector2.ONE, 0.0, 0.02)
	lane_mat.set_shader_parameter("shadow_tint", Vector3(0.56, 0.48, 0.38))
	lane.material_override = lane_mat
	add_child(lane)

func _setup_bamboo_onsen_scenery() -> void:
	var scenery := Node3D.new()
	scenery.name = "BambooOnsenBackdrop"
	add_child(scenery)

	# 1. Matahari washi-emas lembut + sinar woodblock halus di belakang benteng
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
	ray_mat.albedo_color = Color(0.98, 0.94, 0.80, 0.16)
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

	# 2. Pegunungan bambu berkabut palet woodblock-pine (DESIGN.md)
	var hill_mesh: Mesh = load("res://assets/generated/models/home_stage_hill.obj")
	var mountain_layers := [
		[Vector3(-12.5, -1.5, -14.0), Vector3(2.3, 3.8, 1.6), Color(0.36, 0.54, 0.44)],
		[Vector3(  2.0, -2.0, -18.5), Vector3(3.4, 4.4, 1.8), Color(0.45, 0.62, 0.57)],
		[Vector3( 15.5, -1.4, -14.5), Vector3(2.5, 4.0, 1.6), Color(0.34, 0.52, 0.42)],
		[Vector3( -5.0, -1.8, -11.5), Vector3(1.6, 2.2, 1.3), Color(0.41, 0.58, 0.40)]
	]
	for ml in mountain_layers:
		var m := MeshInstance3D.new()
		m.mesh = hill_mesh
		m.position = ml[0]
		m.scale = ml[1]
		var mmat := StandardMaterial3D.new()
		mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mmat.albedo_color = ml[2]
		m.material_override = mmat
		scenery.add_child(m)

	# 3. Rumah Onsen Kayu Jepang pahatan VS C++ (prop_onsen_house.obj!)
	var onsen := MeshInstance3D.new()
	onsen.mesh = load("res://assets/generated/models/prop_onsen_house.obj")
	onsen.position = Vector3(-5.8, 0.85, -10.8)
	onsen.rotation_degrees = Vector3(0.0, 16.0, 0.0)
	onsen.scale = Vector3.ONE * 1.18
	_apply_anime_toon_materials(onsen)
	scenery.add_child(onsen)

	# 4. Gerbang Torii Vermilion + Kolam Air Panas Onsen Beruap di sisi kanan belakang!
	var torii := MeshInstance3D.new()
	torii.mesh = load("res://assets/generated/models/prop_torii_gate.obj")
	torii.position = Vector3(11.4, 0.55, -8.8)
	torii.rotation_degrees = Vector3(0.0, -18.0, 0.0)
	torii.scale = Vector3.ONE * 1.12
	_apply_anime_toon_materials(torii)
	scenery.add_child(torii)

	var pond := MeshInstance3D.new()
	var pnd := CylinderMesh.new()
	pnd.top_radius = 4.6
	pnd.bottom_radius = 4.6
	pnd.height = 0.16
	pond.mesh = pnd
	pond.position = Vector3(10.5, -0.05, -7.8)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.52, 0.78, 0.74)
	pond.material_override = pmat
	scenery.add_child(pond)

	# Kepulan uap onsen lembut (prop_cloud_fluffy.obj)
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

	# 5. Rumpun Bambu pahatan VS C++ membingkai kiri & kanan arena (prop_bamboo_grove.obj)
	var grove_mesh: Mesh = load("res://assets/generated/models/prop_bamboo_grove.obj")
	for bg_cfg in [
		[Vector3(-10.8, 0.1, -5.8), Vector3(0.0, 14.0, -3.0), 1.85],
		[Vector3( 13.8, 0.1, -6.2), Vector3(0.0, -158.0, 3.0), 1.90]
	]:
		var grove := MeshInstance3D.new()
		grove.mesh = grove_mesh
		grove.position = bg_cfg[0]
		grove.rotation_degrees = bg_cfg[1]
		grove.scale = Vector3.ONE * float(bg_cfg[2])
		_apply_anime_toon_materials(grove)
		scenery.add_child(grove)

	# 6. Awan Ghibli gading-lavender pahatan VS C++ (nol awan oranye AI!)
	for cp in [Vector3(-11.0, 7.6, -15.5), Vector3(11.5, 7.8, -16.0), Vector3(-2.5, 9.2, -18.5)]:
		var cl := MeshInstance3D.new()
		cl.mesh = cloud_mesh
		cl.position = cp
		cl.scale = Vector3(2.4, 1.7, 1.3)
		var cmat := _make_25d_mat(null, Color(0.98, 0.96, 0.92), Vector2.ONE, 0.18, 0.04)
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

func _setup_slingshot_visual() -> void:
	slingshot_visual = Node3D.new()
	slingshot_visual.position = Vector3(LAUNCH_X, 0.0, 0.0)
	add_child(slingshot_visual)

	# Pakai model Ketapel Bambu Ukir 2.5D dari C++ (prop_slingshot_bamboo.obj) + tinta komik!
	var sling_mi := MeshInstance3D.new()
	sling_mi.mesh = mesh_slingshot
	_apply_anime_toon_materials(sling_mi)
	slingshot_visual.add_child(sling_mi)

	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.28, 0.14, 0.06)
	band_mesh_a = _create_band_cylinder(band_mat)
	band_mesh_b = _create_band_cylinder(band_mat)
	add_child(band_mesh_a)
	add_child(band_mesh_b)

func _create_band_cylinder(mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.035
	cm.bottom_radius = 0.035
	cm.height = 1.0
	mi.mesh = cm
	mi.material_override = mat
	return mi

func _setup_trajectory_dots() -> void:
	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = Color(1.0, 0.92, 0.45)
	dot_mat.emission_enabled = true
	dot_mat.emission = Color(1.0, 0.78, 0.2)
	dot_mat.emission_energy_multiplier = 0.8

	for i in 18:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = lerp(0.11, 0.045, float(i) / 17.0)
		sm.height = sm.radius * 2.0
		mi.mesh = sm
		mi.material_override = dot_mat
		mi.visible = false
		add_child(mi)
		traj_dots.append(mi)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# 1) TOP-LEFT: Bamboo Woodblock Back Button + Reset + Camera Tabs + Art Style Toggle
	var tl_row := HBoxContainer.new()
	tl_row.position = Vector2(24, 16)
	tl_row.add_theme_constant_override("separation", 10)
	canvas.add_child(tl_row)

	var btn_back := CraftUI.make_back_btn("PETA")
	btn_back.pressed.connect(func(): SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE))
	tl_row.add_child(btn_back)

	var btn_reset := CraftUI.make_icon_stamp("icon_retry", "wood_sq_amber", Vector2(46, 46), 1.6, "R")
	btn_reset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_reset.pressed.connect(_request_reset_arena)
	tl_row.add_child(btn_reset)

	btn_views.clear()
	var view_names := ["1 • 2.5D", "2 • SERONG", "3 • 3D"]
	var view_tilts := [-1.2, 0.8, -0.8]
	for i in 3:
		var b := CraftUI.make_wood_btn(view_names[i], "wood_btn_cedar_dark", Vector2(92, 42), 13, view_tilts[i])
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.toggle_mode = true
		var idx := i
		b.pressed.connect(func(): _set_camera_view(idx))
		tl_row.add_child(b)
		btn_views.append(b)

	btn_style_toggle = CraftUI.make_wood_btn("ANIME 2.5D", "wood_btn_sky", Vector2(124, 42), 13, 1.0)
	btn_style_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_style_toggle.pressed.connect(_toggle_art_style)
	tl_row.add_child(btn_style_toggle)

	# 2) TOP-RIGHT: Bare Stroked Mode Header + Camera Hint
	var tr_vb := VBoxContainer.new()
	tr_vb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr_vb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr_vb.offset_left = -560
	tr_vb.offset_right = -24
	tr_vb.offset_top = 14
	tr_vb.offset_bottom = 78
	tr_vb.add_theme_constant_override("separation", 2)
	tr_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tr_vb)

	var sb_title := CraftUI.make_stroked_label("MODE SANDBOX • 7 KAPIBARA", 22, CraftUI.GOLD_TEXT, 5, true)
	sb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_vb.add_child(sb_title)

	lbl_mode_desc = CraftUI.make_stroked_label("", 12, CraftUI.CREAM_TEXT, 4, false)
	lbl_mode_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr_vb.add_child(lbl_mode_desc)

	# 3) BOTTOM CENTERED: Active Capy Info + 7-Hero Woodblock Picker Rail
	lbl_capy_info = CraftUI.make_stroked_label("", 15, CraftUI.GOLD_TEXT, 5, false)
	lbl_capy_info.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	lbl_capy_info.offset_left = -480
	lbl_capy_info.offset_right = 480
	lbl_capy_info.offset_top = -126
	lbl_capy_info.offset_bottom = -98
	lbl_capy_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_capy_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl_capy_info)

	var rail := HBoxContainer.new()
	rail.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rail.offset_left = -560
	rail.offset_right = 560
	rail.offset_top = -94
	rail.offset_bottom = -12
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 12)
	canvas.add_child(rail)

	btn_capys.clear()
	capy_tile_labels.clear()
	capy_tile_portraits.clear()
	for i in CAPY_ROSTER.size():
		var cdata: Dictionary = CAPY_ROSTER[i]
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(138, 78)
		rail.add_child(slot)

		var b := Button.new()
		b.position = Vector2(0, 10)
		b.size = Vector2(138, 66)
		b.pivot_offset = Vector2(69, 33)
		b.toggle_mode = true
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var idx := i
		b.pressed.connect(func():
			SoundManager.play_ui_click()
			_select_capy(idx)
		)
		slot.add_child(b)
		btn_capys.append(b)

		var portrait := CraftUI.make_tex_rect(load(str(cdata["portrait"])), Vector2(52, 52))
		portrait.position = Vector2(43, -10)
		slot.add_child(portrait)
		capy_tile_portraits.append(portrait)

		var lbl := CraftUI.make_stroked_label("%d. %s" % [i + 1, str(cdata["short"])], 13, CraftUI.CREAM_TEXT, 4, true)
		lbl.position = Vector2(4, 46)
		lbl.size = Vector2(130, 24)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(lbl)
		capy_tile_labels.append(lbl)

func _set_camera_view(view_idx: int) -> void:
	# PENTING: Hanya memindahkan kamera — TIDAK mereset atau mengubah benteng!
	current_view = view_idx
	custom_orbit_active = false
	cam_zoom_offset = 0.0
	var view_tilts := [-1.2, 0.8, -0.8]
	for i in btn_views.size():
		var is_act := (i == view_idx)
		btn_views[i].set_pressed_no_signal(is_act)
		CraftUI.style_wood_button(
			btn_views[i],
			"wood_btn_amber" if is_act else "wood_btn_cedar_dark",
			13,
			Vector2(92, 42),
			view_tilts[i],
			true,
			CraftUI.CREAM_TEXT if is_act else Color(0.91, 0.85, 0.76),
			4
		)

	match current_view:
		CameraView.SIDE_25D:
			lbl_mode_desc.text = "Kamera [1] 2.5D Samping • Klik-Kanan drag = orbit bebas"
		CameraView.ANGLED_25D:
			lbl_mode_desc.text = "Kamera [2] 2.5D Serong • Bangunan 3D terlihat ke dalam"
		CameraView.BEHIND_3D:
			lbl_mode_desc.text = "Kamera [3] 3D Katapel • Sudut belakang peluncur"

func _select_capy(idx: int) -> void:
	current_capy_idx = clampi(idx, 0, CAPY_ROSTER.size() - 1)
	for i in btn_capys.size():
		var is_sel := (i == current_capy_idx)
		var b := btn_capys[i]
		b.set_pressed_no_signal(is_sel)
		var tex_name := "tile_wood_frontier" if is_sel else "tile_wood_open"
		b.rotation_degrees = 0.0 if is_sel else (-1.4 if (i % 2 == 0) else 1.4)
		b.scale = Vector2(1.06, 1.06) if is_sel else Vector2.ONE
		b.add_theme_stylebox_override("normal", CraftUI.make_full_style(tex_name, 8.0, 4.0))
		b.add_theme_stylebox_override("hover", CraftUI.make_full_style(tex_name, 8.0, 4.0, Color(1.08, 1.06, 1.03)))
		b.add_theme_stylebox_override("pressed", CraftUI.make_full_style(tex_name, 8.0, 6.0, Color(0.86, 0.82, 0.78)))
		if i < capy_tile_portraits.size():
			capy_tile_portraits[i].position.y = -15.0 if is_sel else -10.0
		if i < capy_tile_labels.size():
			capy_tile_labels[i].add_theme_color_override("font_color", CraftUI.GOLD_TEXT if is_sel else CraftUI.CREAM_TEXT)
	var data: Dictionary = CAPY_ROSTER[current_capy_idx]
	lbl_capy_info.text = "Pion Aktif: %s  |  Massa: %.1f kg  |  Jurus (Klik/Spasi di udara): %s" % [
		data["name"], data["mass"], data["skill"]
	]
	if not is_flying:
		_spawn_capy_on_slingshot()

func _reset_arena() -> void:
	is_aiming = false
	is_flying = false
	skill_used = false
	flight_timer = 0.0
	pull_vector = Vector3.ZERO
	_hide_trajectory()

	for child in arena_root.get_children():
		child.queue_free()
	blocks.clear()
	active_capy = null

	_build_unified_3d_fortress()
	_select_capy(current_capy_idx)

func _build_unified_3d_fortress() -> void:
	# SATU benteng 3D terpadu yang berjejer sepanjang +X (dari dekat katapel ke belakang),
	# dengan lebar 3D nyata di sumbu Z (-0.55 .. +0.55) agar konsisten dilihat dari samping (2.5D) maupun belakang (3D)!
	var tower_x_positions := [3.8, 6.2, 8.6]
	for t_idx in tower_x_positions.size():
		var tx: float = tower_x_positions[t_idx]
		# 4 pilar sudut tiap menara (membentuk ruang 3D nyata depan-belakang & kiri-kanan)
		for dx in [-0.48, 0.48]:
			for dz in [-0.45, 0.45]:
				_spawn_block(Vector3(tx + dx, 0.85, dz), Vector3(0.34, 1.7, 0.34), "wood", 1.3)

		# Atap papan kayu & balok bambu melintang
		_spawn_block(Vector3(tx, 1.88, 0.0), Vector3(1.45, 0.32, 1.35), "bamboo", 1.1)

		# Menara tengah lebih tinggi (lantai 2 dari batu)
		if t_idx == 1:
			_spawn_block(Vector3(tx - 0.38, 2.55, 0.0), Vector3(0.36, 1.0, 0.90), "stone", 2.2)
			_spawn_block(Vector3(tx + 0.38, 2.55, 0.0), Vector3(0.36, 1.0, 0.90), "stone", 2.2)
			_spawn_block(Vector3(tx, 3.22, 0.0), Vector3(1.25, 0.34, 1.05), "stone", 2.4)
			_spawn_target_orb(Vector3(tx, 2.42, 0.0))
			_spawn_target_orb(Vector3(tx, 3.72, 0.0))
		else:
			_spawn_block(Vector3(tx, 2.38, 0.0), Vector3(0.68, 0.68, 0.68), "stone", 2.0)

		# Target hijau di dalam lantai dasar tiap menara
		_spawn_target_orb(Vector3(tx, 0.40, 0.0))

func _spawn_block(pos: Vector3, size: Vector3, mat_kind: String, mass_val: float) -> void:
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = mass_val

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	rb.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm

	var block_tex: Texture2D = tex_wood
	var block_tint: Color = Color(0.92, 0.84, 0.76)
	match mat_kind:
		"wood":
			block_tex = tex_wood
			block_tint = Color(0.88, 0.78, 0.68)
		"bamboo":
			block_tex = tex_bamboo
			block_tint = Color(0.84, 0.90, 0.74)
		"stone":
			block_tex = tex_stone
			block_tint = Color(0.92, 0.90, 0.86)
	mi.material_override = _make_25d_mat(block_tex, block_tint, Vector2.ONE, 0.16, 0.10)
	rb.add_child(mi)

	arena_root.add_child(rb)
	blocks.append(rb)

func _spawn_target_orb(pos: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.position = pos
	rb.mass = 0.85

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.36
	col.shape = shape
	rb.add_child(col)

	# Ganti bola hijau polos dengan model 3D Musuh Croco Minion 2.5D ekspresif!
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_croco
	mi.scale = Vector3.ONE * 1.15
	_apply_anime_toon_materials(mi)
	rb.add_child(mi)

	arena_root.add_child(rb)
	blocks.append(rb)

func _spawn_capy_on_slingshot() -> void:
	if is_instance_valid(active_capy):
		active_capy.queue_free()

	var data: Dictionary = CAPY_ROSTER[current_capy_idx]
	var rb := RigidBody3D.new()
	rb.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	rb.mass = data["mass"]
	rb.freeze = true
	rb.continuous_cd = true
	rb.contact_monitor = true
	rb.max_contacts_reported = 4

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = data["radius"]
	col.shape = shape
	rb.add_child(col)

	var visual_pivot := Node3D.new()
	visual_pivot.name = "VisualPivot"
	var mi := MeshInstance3D.new()
	var mesh_path: String = data["anime_mesh"] if use_anime_style else data["mesh"]
	mi.mesh = load(mesh_path)
	if use_anime_style:
		_apply_anime_toon_materials(mi)
	visual_pivot.add_child(mi)
	rb.add_child(visual_pivot)

	arena_root.add_child(rb)
	active_capy = rb
	capy_visual = visual_pivot
	is_flying = false
	skill_used = false
	flight_timer = 0.0

func _toggle_art_style() -> void:
	use_anime_style = not use_anime_style
	btn_style_toggle.text = "ANIME 2.5D" if use_anime_style else "ORIGINAL 3D"
	CraftUI.style_wood_button(
		btn_style_toggle,
		"wood_btn_sky" if use_anime_style else "wood_btn_cedar",
		13,
		Vector2(124, 42),
		1.0
	)
	if not is_flying:
		_spawn_capy_on_slingshot()

func _apply_anime_toon_materials(mi: MeshInstance3D) -> void:
	if not mi.mesh or not shader_toon:
		return
	for s_idx in mi.mesh.get_surface_count():
		var orig := mi.mesh.surface_get_material(s_idx)
		var mat_name: String = orig.resource_name if orig else ""
		var rovio_mat := ShaderMaterial.new()
		rovio_mat.shader = shader_toon

		var local_rim: float = 0.24
		var local_sheen: float = 0.14
		if mat_name in ["mat_ink", "mat_mouth_dark", "mat_anime_eye", "mat_croco_eye"]:
			local_rim = 0.04
			local_sheen = 0.24 if "eye" in mat_name else 0.03
		elif mat_name in ["mat_white", "mat_tongue", "mat_anger", "mat_spark", "mat_shoji_glow"]:
			local_rim = 0.05
			local_sheen = 0.18

		rovio_mat.set_shader_parameter("rim_color", Vector3(0.98, 0.92, 0.76))
		rovio_mat.set_shader_parameter("shadow_tint", Vector3(0.46, 0.40, 0.48))
		rovio_mat.set_shader_parameter("rim_strength", local_rim)
		rovio_mat.set_shader_parameter("sheen_strength", local_sheen)
		if orig is BaseMaterial3D:
			if orig.albedo_texture:
				rovio_mat.set_shader_parameter("albedo_tex", orig.albedo_texture)
			rovio_mat.set_shader_parameter("tint_color", orig.albedo_color)
			if orig.emission_enabled:
				rovio_mat.set_shader_parameter("emission_color", Vector3(orig.emission.r, orig.emission.g, orig.emission.b))
		mi.set_surface_override_material(s_idx, rovio_mat)

func _request_reset_arena() -> void:
	if is_aiming:
		is_aiming = false
		pull_vector = Vector3.ZERO
		_hide_trajectory()
		if is_instance_valid(active_capy):
			active_capy.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	CraftUI.show_confirm_modal(
		get_tree(),
		"RESET ARENA SANDBOX?",
		"Seluruh balok benteng uji akan dibangun ulang ke posisi awal.\nYakin ingin mereset arena?",
		"YA, RESET",
		func(): _reset_arena(),
		"BATAL",
		true
	)

func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if CraftUI.is_confirm_open(get_tree()):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_camera_view(CameraView.SIDE_25D)
			KEY_2: _set_camera_view(CameraView.ANGLED_25D)
			KEY_3: _set_camera_view(CameraView.BEHIND_3D)
			KEY_R: _request_reset_arena()
			KEY_V: _toggle_art_style()
			KEY_H: SceneLoader.quick_transition_to(HOME_SCENE)
			KEY_ESCAPE: SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE)
			KEY_Q: _select_capy((current_capy_idx + CAPY_ROSTER.size() - 1) % CAPY_ROSTER.size())
			KEY_E: _select_capy((current_capy_idx + 1) % CAPY_ROSTER.size())
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
			var scale := 0.014
			if current_view == CameraView.BEHIND_3D:
				# Dari belakang katapel: drag bawah -> tenaga/tinggi, drag kiri/kanan -> geser Z ringan
				var power := clampf(delta_px.y * scale, 0.2, MAX_PULL_DIST)
				var yaw_z := clampf(-delta_px.x * scale * 0.55, -1.35, 1.35)
				pull_vector = Vector3(-clampf(power * 0.95, 0.35, MAX_PULL_DIST), -power * 0.56, -yaw_z)
			else:
				# Dari samping / serong: drag Kiri & Bawah -> luncur Kanan & Atas (Z=0 center lane)
				var vx := -delta_px.x * scale
				var vy := delta_px.y * scale
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

	var launch_vel := _compute_launch_velocity()
	if launch_vel.length() < 3.0:
		active_capy.position = Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
		pull_vector = Vector3.ZERO
		return

	active_capy.freeze = false
	active_capy.linear_velocity = launch_vel
	is_flying = true
	flight_timer = 0.0
	pull_vector = Vector3.ZERO
	SoundManager.play_sfx("launch", 1.0, -2.0, 0.06)

func _compute_launch_velocity() -> Vector3:
	return -pull_vector * LAUNCH_POWER

func _activate_skill() -> void:
	if not is_instance_valid(active_capy):
		return
	skill_used = true
	var capy_id: String = CAPY_ROSTER[current_capy_idx]["id"]
	var pos := active_capy.global_position

	match capy_id:
		"chill":
			active_capy.apply_central_impulse(Vector3(0.0, -10.0, 0.0))
			_spawn_vfx_sphere(pos, 1.4, Color(0.95, 0.95, 0.75))
			SoundManager.play_sfx("skill_zen", 1.0, -1.0)
		"dash":
			var dir := active_capy.linear_velocity.normalized()
			if dir.length() < 0.1:
				dir = Vector3(1, 0, 0)
			active_capy.linear_velocity = dir * 32.0
			_spawn_vfx_sphere(pos, 1.1, Color(1.0, 0.85, 0.2))
			SoundManager.play_sfx("skill_dash", 1.0, -1.5)
		"yuzu_bomb":
			_apply_radial_blast(pos, 4.8, 34.0)
			_spawn_vfx_sphere(pos, 4.2, Color(1.0, 0.55, 0.08))
			SoundManager.play_sfx("tnt_boom", 1.0, 0.0)
		"bambu_saber":
			_apply_radial_blast(pos, 3.2, 22.0)
			_spawn_vfx_sphere(pos, 3.0, Color(0.25, 1.0, 0.45))
			SoundManager.play_sfx("skill_dash", 1.25, -1.5)

func _apply_radial_blast(center: Vector3, radius: float, strength: float) -> void:
	for b in blocks:
		if not is_instance_valid(b):
			continue
		var diff := b.global_position - center
		var dist := diff.length()
		if dist < radius and dist > 0.01:
			var falloff := 1.0 - (dist / radius)
			b.apply_central_impulse(diff.normalized() * strength * falloff)

func _spawn_vfx_sphere(pos: Vector3, max_r: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	mi.mesh = sm
	mi.position = pos
	mi.scale = Vector3.ONE * 0.2

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.55)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	arena_root.add_child(mi)
	vfx_nodes.append({ "node": mi, "mat": mat, "t": 0.0, "max_r": max_r })

func _update_trajectory_preview() -> void:
	var vel := _compute_launch_velocity()
	if vel.length() < 3.0:
		_hide_trajectory()
		return
	var start_pos := active_capy.position if is_instance_valid(active_capy) else Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	for i in traj_dots.size():
		var t := float(i + 1) * 0.075
		var p := start_pos + vel * t + Vector3(0.0, -0.5 * GRAVITY * t * t, 0.0)
		traj_dots[i].position = p
		traj_dots[i].visible = p.y > 0.05

func _hide_trajectory() -> void:
	for d in traj_dots:
		d.visible = false

func _process(delta: float) -> void:
	anim_time += delta
	_update_slingshot_bands()
	_update_capy_life_animation(delta)
	_update_camera(delta)
	_update_vfx(delta)

	if sun_rays_node:
		sun_rays_node.rotation.z = anim_time * 0.06
	for sp in steam_puffs:
		var node: MeshInstance3D = sp["node"]
		var base: Vector3 = sp["base"]
		var ph: float = float(sp["phase"])
		var cycle: float = fmod(anim_time * 0.45 + ph, 2.2)
		node.position = base + Vector3(sin(anim_time + ph) * 0.35, cycle * 1.15, 0.0)
		var sc: float = sin((cycle / 2.2) * PI) * 0.55
		node.scale = Vector3.ONE * maxf(sc, 0.05)
	for lf in bg_leaves:
		var node: MeshInstance3D = lf["node"]
		var base: Vector3 = lf["base"]
		var ph: float = float(lf["phase"])
		node.position = base + Vector3(sin(anim_time * 0.9 + ph) * 0.85, -fmod(anim_time * 0.55 + ph, 4.5) + 2.2, 0.0)
		node.rotation = Vector3(anim_time * 1.5 + ph, anim_time * 0.8, sin(anim_time + ph))

	if capture_arena_path != "" and not capture_arena_done and anim_time > 0.65:
		capture_arena_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_arena_path)
		get_tree().quit()

	if is_flying:
		flight_timer += delta
		if flight_timer > 4.5 or (is_instance_valid(active_capy) and active_capy.position.y < -5.0):
			_spawn_capy_on_slingshot()

func _update_capy_life_animation(delta: float) -> void:
	if not is_instance_valid(active_capy) or not is_instance_valid(capy_visual):
		return
	if is_aiming:
		var stretch := clampf(pull_vector.length() / MAX_PULL_DIST, 0.0, 1.0)
		var launch_dir := _compute_launch_velocity().normalized()
		var pitch := atan2(launch_dir.y, maxf(0.1, launch_dir.x))
		capy_visual.rotation = Vector3(0.0, 0.0, pitch)
		capy_visual.scale = Vector3(1.0 + 0.16 * stretch, 1.0 - 0.10 * stretch, 1.0 - 0.06 * stretch)
	elif not is_flying:
		# Napas santai + goyang imut saat menunggu di katapel
		var breath := sin(anim_time * 3.4)
		var sway := sin(anim_time * 1.9) * 0.08
		capy_visual.scale = Vector3(1.0 - 0.04 * breath, 1.0 + 0.06 * breath, 1.0 - 0.03 * breath)
		capy_visual.rotation = Vector3(sway * 0.5, sway, sin(anim_time * 2.5) * 0.05)
	else:
		# Di udara: kembali ke proporsi normal & beri efek squash ringan saat melaju cepat
		capy_visual.scale = capy_visual.scale.lerp(Vector3.ONE, clampf(delta * 10.0, 0.0, 1.0))
		capy_visual.rotation = capy_visual.rotation.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))

func _update_slingshot_bands() -> void:
	var target := Vector3(LAUNCH_X, LAUNCH_Y, 0.0)
	if is_aiming and is_instance_valid(active_capy):
		target = active_capy.position
	_stretch_band(band_mesh_a, Vector3(LAUNCH_X, 1.82,  0.42), target)
	_stretch_band(band_mesh_b, Vector3(LAUNCH_X, 1.82, -0.42), target)

func _stretch_band(mi: MeshInstance3D, p0: Vector3, p1: Vector3) -> void:
	var diff := p1 - p0
	var len := diff.length()
	if len < 0.02:
		mi.visible = false
		return
	mi.visible = true
	mi.position = (p0 + p1) * 0.5
	mi.scale = Vector3(1.0, len, 1.0)
	var dir := diff / len
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		mi.basis = Basis.IDENTITY
	else:
		var axis := up.cross(dir).normalized()
		var angle := acos(clampf(up.dot(dir), -1.0, 1.0))
		mi.basis = Basis(axis, angle)

func _update_camera(delta: float) -> void:
	var desired_pos := Vector3.ZERO
	var look_target := Vector3(1.8, 2.0, 0.0)

	if custom_orbit_active:
		cam.fov = lerpf(cam.fov, 45.0, delta * 6.0)
		var center := Vector3(2.2, 2.0, 0.0)
		var dist := 16.5 + cam_zoom_offset
		desired_pos = center + Vector3(
			-sin(orbit_yaw) * cos(orbit_pitch) * dist,
			sin(orbit_pitch) * dist + 1.2,
			cos(orbit_yaw) * cos(orbit_pitch) * dist
		)
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
				# Sudut serong ~22 deg dari belakang-samping kiri sehingga benteng terlihat 3D berjejer!
				desired_pos = Vector3(fx - 5.2, 4.8, 15.8 + cam_zoom_offset)
				look_target = Vector3(fx + 1.4, 1.8, 0.0)

			CameraView.BEHIND_3D:
				cam.fov = lerpf(cam.fov, 54.0, delta * 6.0)
				# Tepat di belakang katapel melihat benteng yg SAMA berjejer lurus ke depan (+X)!
				desired_pos = Vector3(LAUNCH_X - 4.4 - cam_zoom_offset * 0.4, 4.1, 0.6)
				look_target = Vector3(5.8, 1.8, 0.0)

	cam.position = cam.position.lerp(desired_pos, clampf(delta * 7.5, 0.0, 1.0))
	cam.look_at(look_target, Vector3.UP)

func _update_vfx(delta: float) -> void:
	for i in range(vfx_nodes.size() - 1, -1, -1):
		var item: Dictionary = vfx_nodes[i]
		item["t"] += delta
		var p: float = item["t"] / 0.35
		var node: MeshInstance3D = item["node"]
		var mat: StandardMaterial3D = item["mat"]
		if p >= 1.0 or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()
			vfx_nodes.remove_at(i)
		else:
			node.scale = Vector3.ONE * lerpf(0.2, item["max_r"], p)
			mat.albedo_color.a = lerpf(0.55, 0.0, p)
