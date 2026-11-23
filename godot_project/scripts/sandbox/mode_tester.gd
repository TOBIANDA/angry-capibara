extends Node3D

enum CameraView { SIDE_25D = 0, ANGLED_25D = 1, BEHIND_3D = 2 }

const LAUNCH_X := -6.5
const LAUNCH_Y := 1.75
const GRAVITY := 18.0
const MAX_PULL_DIST := 2.9
const LAUNCH_POWER := 8.8

const CAPY_ROSTER := [
	{ "id": "chill",        "name": "1. Chill Capi",        "mesh": "res://assets/generated/models/capy_chill.obj",        "anime_mesh": "res://assets/generated/models/anime_capy_chill.obj",        "mass": 2.0, "radius": 0.36, "skill": "Zen Bump (getar ke bawah)" },
	{ "id": "dash",         "name": "2. Dash Capi",         "mesh": "res://assets/generated/models/capy_dash.obj",         "anime_mesh": "res://assets/generated/models/anime_capy_dash.obj",         "mass": 1.8, "radius": 0.35, "skill": "Turbo Dash 2.2x" },
	{ "id": "mini",         "name": "3. Trio Mini-Capi",    "mesh": "res://assets/generated/models/capy_mini.obj",         "anime_mesh": "res://assets/generated/models/anime_capy_mini.obj",         "mass": 1.0, "radius": 0.25, "skill": "Preview Model Trio Mini" },
	{ "id": "yuzu_bomb",    "name": "4. Yuzu Bomb Capi",    "mesh": "res://assets/generated/models/capy_yuzu_bomb.obj",    "anime_mesh": "res://assets/generated/models/anime_capy_yuzu_bomb.obj",    "mass": 2.5, "radius": 0.40, "skill": "Ledakan Area Yuzu (r=4.5m)" },
	{ "id": "seed_blaster", "name": "5. Seed-Blaster Capi", "mesh": "res://assets/generated/models/capy_seed_blaster.obj", "anime_mesh": "res://assets/generated/models/anime_capy_seed_blaster.obj", "mass": 2.0, "radius": 0.37, "skill": "Preview Model Seed-Blaster" },
	{ "id": "bambu_saber",  "name": "6. Bambu-Katana Capi", "mesh": "res://assets/generated/models/capy_bambu_saber.obj",  "anime_mesh": "res://assets/generated/models/anime_capy_katana.obj",       "mass": 2.1, "radius": 0.37, "skill": "Tebasan Katana 360° (r=3.0m)" },
	{ "id": "heavy_onsen",  "name": "7. Heavy Onsen Capi",  "mesh": "res://assets/generated/models/capy_heavy_onsen.obj",  "anime_mesh": "res://assets/generated/models/anime_capy_heavy_onsen.obj",  "mass": 4.8, "radius": 0.48, "skill": "Pasif: Massa Jumbo Penembus" },
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
	tex_moss = load("res://assets/generated/textures/tex_moss_top.bmp")
	tex_cliff = load("res://assets/generated/textures/tex_cliff_rock.bmp")
	mesh_croco = load("res://assets/generated/models/enemy_croco_minion.obj")
	mesh_slingshot = load("res://assets/generated/models/prop_slingshot_bamboo.obj")
	shader_toon = load("res://shaders/toon_25d.gdshader")
	shader_outline = load("res://shaders/anime_outline.gdshader")

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
	# Palet langit senja Bamboo-Onsen yang serasi 100% dengan Key-Art Home 2D!
	sky_mat.sky_top_color = Color(0.09, 0.30, 0.42)
	sky_mat.sky_horizon_color = Color(0.96, 0.68, 0.34)
	sky_mat.ground_bottom_color = Color(0.14, 0.28, 0.24)
	sky_mat.ground_horizon_color = Color(0.86, 0.64, 0.36)
	sky_mat.sky_curve = 0.22
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.56, 0.50)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.04
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.14
	env.glow_hdr_threshold = 1.05

	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32.0, 28.0, 0.0)
	sun.light_energy = 0.86
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.shadow_enabled = true
	add_child(sun)

	cam = Camera3D.new()
	cam.near = 0.1
	cam.far = 160.0
	add_child(cam)
	cam.make_current()

func _make_25d_mat(tex: Texture2D, tint: Color = Color.WHITE, uv_sc: Vector2 = Vector2.ONE, with_outline: bool = true, outline_w: float = 0.015) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader_toon
	if tex:
		mat.set_shader_parameter("albedo_tex", tex)
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("uv_scale", uv_sc)
	if with_outline and shader_outline:
		var om := ShaderMaterial.new()
		om.shader = shader_outline
		om.set_shader_parameter("outline_width", outline_w)
		om.set_shader_parameter("outline_color", Color(0.08, 0.05, 0.06, 1.0))
		mat.next_pass = om
	return mat

func _setup_ground() -> void:
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(44.0, 2.0, 14.0)
	col.shape = shape
	ground.position = Vector3(1.0, -1.0, 0.0)
	ground.add_child(col)

	# Lapisan rumput lumut tenang bergaya ilustrasi 2.5D agar karakter merah & benteng kontras tajam
	var moss_top := MeshInstance3D.new()
	var mt := BoxMesh.new()
	mt.size = Vector3(36.0, 0.42, 10.5)
	moss_top.mesh = mt
	moss_top.position = Vector3(0.0, 0.79, 0.0)
	var moss_mat := _make_25d_mat(tex_moss, Color(0.56, 0.70, 0.46), Vector2(6.0, 2.0), true, 0.024)
	moss_mat.set_shader_parameter("rim_strength", 0.06)
	moss_top.material_override = moss_mat
	ground.add_child(moss_top)

	# Dinding tebing batu vulkanik gelap di bawah rumput
	var cliff := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(35.4, 3.6, 10.0)
	cliff.mesh = cm
	cliff.position = Vector3(0.0, -1.20, 0.0)
	var cliff_mat := _make_25d_mat(tex_cliff, Color(0.74, 0.68, 0.64), Vector2(6.0, 1.2), true, 0.028)
	cliff_mat.set_shader_parameter("rim_strength", 0.05)
	cliff.material_override = cliff_mat
	ground.add_child(cliff)
	add_child(ground)

	# Penanda lintasan tanah hangat halus di Z=0
	var lane := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(22.0, 0.025, 0.34)
	lane.mesh = lm
	lane.position = Vector3(2.0, 0.015, 0.0)
	var lane_mat := _make_25d_mat(tex_cliff, Color(0.52, 0.44, 0.34), Vector2(10.0, 1.0), false)
	lane_mat.set_shader_parameter("rim_strength", 0.0)
	lane.material_override = lane_mat
	add_child(lane)

func _setup_bamboo_onsen_scenery() -> void:
	var scenery := Node3D.new()
	scenery.name = "BambooOnsenBackdrop"
	add_child(scenery)

	# 1. Matahari senja keemasan + sinar sunburst halus di belakang benteng
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
	sd_mat.albedo_color = Color(1.0, 0.93, 0.65)
	sd_mat.emission_enabled = true
	sd_mat.emission = Color(1.0, 0.85, 0.45)
	sd_mat.emission_energy_multiplier = 1.15
	sun_disk.material_override = sd_mat
	sun_disk.scale = Vector3(1.0, 1.0, 0.1)
	sun_rays_node.add_child(sun_disk)

	var ray_mat := StandardMaterial3D.new()
	ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.albedo_color = Color(1.0, 0.90, 0.55, 0.14)
	for i in 10:
		var ray := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(2.2, 22.0, 0.05)
		ray.mesh = pm
		ray.material_override = ray_mat
		var ang := (float(i) / 10.0) * TAU
		ray.rotation.z = ang
		ray.position = Vector3(-sin(ang), cos(ang), -0.4) * 9.0
		sun_rays_node.add_child(ray)

	# 2. Pegunungan bambu tropis berkabut berlapis (menggunakan pahatan home_stage_hill.obj!)
	var hill_mesh: Mesh = load("res://assets/generated/models/home_stage_hill.obj")
	var mountain_layers := [
		[Vector3(-12.5, -1.5, -14.0), Vector3(2.3, 3.8, 1.6), Color(0.24, 0.52, 0.36)],
		[Vector3(  2.0, -2.0, -18.5), Vector3(3.4, 4.4, 1.8), Color(0.20, 0.44, 0.38)],
		[Vector3( 15.5, -1.4, -14.5), Vector3(2.5, 4.0, 1.6), Color(0.22, 0.48, 0.34)],
		[Vector3( -5.0, -1.8, -11.5), Vector3(1.6, 2.2, 1.3), Color(0.28, 0.56, 0.32)]
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

	# 3. Rumah Onsen Kayu Jepang berkabut di tebing kiri belakang (palet redup atmosferik serasi Key-Art 2D!)
	var onsen := Node3D.new()
	onsen.position = Vector3(-5.8, 0.85, -10.8)
	onsen.rotation_degrees = Vector3(0.0, 14.0, 0.0)
	scenery.add_child(onsen)

	var onsen_wall_mat := StandardMaterial3D.new()
	onsen_wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	onsen_wall_mat.albedo_color = Color(0.46, 0.42, 0.34)
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(3.3, 2.0, 2.3)
	wall.mesh = wm
	wall.position = Vector3(0.0, 1.0, 0.0)
	wall.material_override = onsen_wall_mat
	onsen.add_child(wall)

	var onsen_roof_mat := StandardMaterial3D.new()
	onsen_roof_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	onsen_roof_mat.albedo_color = Color(0.26, 0.30, 0.28)
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(4.4, 1.15, 3.0)
	roof.mesh = rm
	roof.position = Vector3(0.0, 2.55, 0.0)
	roof.material_override = onsen_roof_mat
	onsen.add_child(roof)

	# Beranda kayu & jendela shoji hangat bercahaya
	var porch := MeshInstance3D.new()
	var pm2 := BoxMesh.new()
	pm2.size = Vector3(3.7, 0.28, 2.8)
	porch.mesh = pm2
	porch.position = Vector3(0.0, 0.14, 0.1)
	porch.material_override = onsen_roof_mat
	onsen.add_child(porch)

	var win := MeshInstance3D.new()
	var winm := BoxMesh.new()
	winm.size = Vector3(1.15, 0.85, 0.08)
	win.mesh = winm
	win.position = Vector3(0.0, 1.02, 1.18)
	var win_mat := StandardMaterial3D.new()
	win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	win_mat.albedo_color = Color(1.0, 0.90, 0.52)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.80, 0.32)
	win_mat.emission_energy_multiplier = 1.1
	win.material_override = win_mat
	onsen.add_child(win)

	# 4. Gerbang Torii Merah + Kolam Air Panas Onsen Beruap di sisi kanan belakang!
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
	pmat.albedo_color = Color(0.42, 0.86, 0.78)
	pmat.emission_enabled = true
	pmat.emission = Color(0.32, 0.78, 0.70)
	pmat.emission_energy_multiplier = 0.55
	pond.material_override = pmat
	scenery.add_child(pond)

	# Kepulan uap onsen lembut
	var st_mat := StandardMaterial3D.new()
	st_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	st_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	st_mat.albedo_color = Color(1.0, 0.98, 0.92, 0.24)
	for i in 7:
		var puff := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.65
		sm.height = 1.15
		puff.mesh = sm
		puff.material_override = st_mat
		var base := Vector3(8.5 + float(i) * 0.75, 0.45, -7.6 + sin(float(i)) * 0.9)
		puff.position = base
		scenery.add_child(puff)
		steam_puffs.append({ "node": puff, "base": base, "phase": float(i) * 0.9 })

	# 5. Rumpun Bambu Raksasa membingkai kiri & kanan arena
	var bamboo_mat := _make_25d_mat(tex_bamboo, Color(1.0, 1.0, 1.0), Vector2(1.0, 3.0), true, 0.022)
	for b_cfg in [
		[Vector3(-10.5, 3.4, -5.8), 7.4, -6.0],
		[Vector3(-11.4, 3.0, -4.6), 6.6,  5.0],
		[Vector3(-9.7,  2.8, -6.5), 6.2, -3.0],
		[Vector3( 13.6, 3.6, -6.2), 7.8,  7.0],
		[Vector3( 14.5, 3.1, -5.0), 6.8, -5.0]
	]:
		var stalk := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.16
		sc.bottom_radius = 0.22
		sc.height = b_cfg[1]
		stalk.mesh = sc
		stalk.position = b_cfg[0]
		stalk.rotation_degrees = Vector3(0.0, 0.0, b_cfg[2])
		stalk.material_override = bamboo_mat
		scenery.add_child(stalk)

	# 6. Awan senja hangat & daun bambu melayang
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.albedo_color = Color(0.98, 0.74, 0.52)
	for cp in [Vector3(-11.0, 7.6, -15.5), Vector3(11.5, 7.8, -16.0), Vector3(-2.5, 9.2, -18.5)]:
		var cg := Node3D.new()
		cg.position = cp
		for off in [Vector3(0, 0, 0), Vector3(-1.3, -0.2, 0), Vector3(1.4, -0.25, 0)]:
			var p := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 1.15 if off == Vector3.ZERO else 0.85
			sm.height = sm.radius * 1.35
			p.mesh = sm
			p.position = off
			p.material_override = cloud_mat
			cg.add_child(p)
		scenery.add_child(cg)

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaf_mat.albedo_color = Color(0.48, 0.84, 0.28)
	for i in 10:
		var lf := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.24, 0.025, 0.09)
		lf.mesh = bm
		lf.material_override = leaf_mat
		var st := Vector3(-10.0 + float(i) * 2.4, 2.2 + fmod(float(i) * 1.7, 5.2), -2.8 + sin(float(i)) * 2.0)
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

	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.08, 0.11, 0.14, 0.78)
	hud_style.border_color = Color(0.96, 0.76, 0.30, 0.80)
	hud_style.set_border_width_all(2)
	hud_style.set_corner_radius_all(12)

	# Baris atas tipis untuk kontrol kamera & tombol aksi (tidak menutupi langit senja!)
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(14, 12)
	top_panel.add_theme_stylebox_override("panel", hud_style)
	canvas.add_child(top_panel)

	var tmar := MarginContainer.new()
	tmar.add_theme_constant_override("margin_left", 10)
	tmar.add_theme_constant_override("margin_right", 10)
	tmar.add_theme_constant_override("margin_top", 6)
	tmar.add_theme_constant_override("margin_bottom", 6)
	top_panel.add_child(tmar)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	tmar.add_child(mode_row)

	var home_btn := Button.new()
	home_btn.text = "[H] Home"
	home_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/home_screen.tscn"))
	mode_row.add_child(home_btn)

	var view_names := [
		"[1] 2.5D Samping",
		"[2] 2.5D Serong",
		"[3] 3D Katapel"
	]
	for i in 3:
		var b := Button.new()
		b.text = view_names[i]
		b.toggle_mode = true
		var idx := i
		b.pressed.connect(func(): _set_camera_view(idx))
		mode_row.add_child(b)
		btn_views.append(b)

	var reset_btn := Button.new()
	reset_btn.text = "[R] Reset"
	reset_btn.pressed.connect(_reset_arena)
	mode_row.add_child(reset_btn)

	btn_style_toggle = Button.new()
	btn_style_toggle.text = "[V] ANIME 2.5D"
	btn_style_toggle.pressed.connect(_toggle_art_style)
	mode_row.add_child(btn_style_toggle)

	# Dock pemilihan 7 Kapibara rapi di bagian bawah layar!
	var bot_panel := PanelContainer.new()
	bot_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bot_panel.offset_left = 14
	bot_panel.offset_right = 920
	bot_panel.offset_top = -76
	bot_panel.offset_bottom = -12
	bot_panel.add_theme_stylebox_override("panel", hud_style)
	canvas.add_child(bot_panel)

	var bmar := MarginContainer.new()
	bmar.add_theme_constant_override("margin_left", 10)
	bmar.add_theme_constant_override("margin_right", 10)
	bmar.add_theme_constant_override("margin_top", 6)
	bmar.add_theme_constant_override("margin_bottom", 6)
	bot_panel.add_child(bmar)

	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 4)
	bmar.add_child(bvb)

	var capy_row := HBoxContainer.new()
	capy_row.add_theme_constant_override("separation", 5)
	bvb.add_child(capy_row)

	for i in CAPY_ROSTER.size():
		var b := Button.new()
		b.text = CAPY_ROSTER[i]["name"]
		b.toggle_mode = true
		var idx := i
		b.pressed.connect(func(): _select_capy(idx))
		capy_row.add_child(b)
		btn_capys.append(b)

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 14)
	bvb.add_child(info_row)

	lbl_capy_info = Label.new()
	lbl_capy_info.add_theme_font_size_override("font_size", 12)
	lbl_capy_info.modulate = Color(1.0, 0.90, 0.50)
	info_row.add_child(lbl_capy_info)

	lbl_mode_desc = Label.new()
	lbl_mode_desc.add_theme_font_size_override("font_size", 11)
	lbl_mode_desc.modulate = Color(0.84, 0.90, 0.96)
	info_row.add_child(lbl_mode_desc)

func _set_camera_view(view_idx: int) -> void:
	# PENTING: Hanya memindahkan kamera — TIDAK mereset atau mengubah benteng!
	current_view = view_idx
	custom_orbit_active = false
	cam_zoom_offset = 0.0
	for i in btn_views.size():
		btn_views[i].set_pressed_no_signal(i == view_idx)

	match current_view:
		CameraView.SIDE_25D:
			lbl_mode_desc.text = "Kamera [1] 2.5D Samping: Tampak samping klasik. Tarik Kiri/Bawah untuk bidik. (Klik-Kanan Drag = putar orbit bebas)"
		CameraView.ANGLED_25D:
			lbl_mode_desc.text = "Kamera [2] 2.5D Serong: Bangunan 3D terlihat berjejer ke dalam + tetap akurat dibidik dari samping!"
		CameraView.BEHIND_3D:
			lbl_mode_desc.text = "Kamera [3] 3D Belakang Katapel: Melihat benteng YG SAMA berjejer ke belakang! Drag kiri/kanan bisa geser arah Z."

func _select_capy(idx: int) -> void:
	current_capy_idx = clampi(idx, 0, CAPY_ROSTER.size() - 1)
	for i in btn_capys.size():
		btn_capys[i].set_pressed_no_signal(i == current_capy_idx)
	var data: Dictionary = CAPY_ROSTER[current_capy_idx]
	lbl_capy_info.text = "Pion Aktif: %s | Massa: %.1f kg | Skill (Klik/Spasi di udara): %s" % [
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
	match mat_kind:
		"wood":
			block_tex = tex_wood
		"bamboo":
			block_tex = tex_bamboo
		"stone":
			block_tex = tex_stone
	mi.material_override = _make_25d_mat(block_tex, Color.WHITE, Vector2.ONE, true, 0.016)
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
	btn_style_toggle.text = "[V] Style: ANIME 2.5D" if use_anime_style else "[V] Style: ORIGINAL"
	if not is_flying:
		_spawn_capy_on_slingshot()

func _apply_anime_toon_materials(mi: MeshInstance3D) -> void:
	if not mi.mesh or not shader_toon or not shader_outline:
		return
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = shader_outline
	for s_idx in mi.mesh.get_surface_count():
		var orig := mi.mesh.surface_get_material(s_idx)
		var mat_name: String = orig.resource_name if orig else ""
		var toon_mat := ShaderMaterial.new()
		toon_mat.shader = shader_toon
		if not (mat_name in ["mat_mouth_dark", "mat_tongue", "mat_white", "mat_anime_eye", "mat_croco_eye", "mat_ink", "mat_anger"]):
			toon_mat.next_pass = outline_mat
		if orig is BaseMaterial3D:
			if orig.albedo_texture:
				toon_mat.set_shader_parameter("albedo_tex", orig.albedo_texture)
			toon_mat.set_shader_parameter("tint_color", orig.albedo_color)
			if orig.emission_enabled:
				toon_mat.set_shader_parameter("emission_color", orig.emission)
		mi.set_surface_override_material(s_idx, toon_mat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_camera_view(CameraView.SIDE_25D)
			KEY_2: _set_camera_view(CameraView.ANGLED_25D)
			KEY_3: _set_camera_view(CameraView.BEHIND_3D)
			KEY_R: _reset_arena()
			KEY_V: _toggle_art_style()
			KEY_H: get_tree().change_scene_to_file("res://scenes/ui/home_screen.tscn")
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
		"dash":
			var dir := active_capy.linear_velocity.normalized()
			if dir.length() < 0.1:
				dir = Vector3(1, 0, 0)
			active_capy.linear_velocity = dir * 32.0
			_spawn_vfx_sphere(pos, 1.1, Color(1.0, 0.85, 0.2))
		"yuzu_bomb":
			_apply_radial_blast(pos, 4.8, 34.0)
			_spawn_vfx_sphere(pos, 4.2, Color(1.0, 0.55, 0.08))
		"bambu_saber":
			_apply_radial_blast(pos, 3.2, 22.0)
			_spawn_vfx_sphere(pos, 3.0, Color(0.25, 1.0, 0.45))

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
		var sc: float = sin((cycle / 2.2) * PI) * 1.25
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
