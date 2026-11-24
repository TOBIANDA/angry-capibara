extends Control

# Halaman Home Hybrid 2.5D untuk Angry Capibara:
# - Latar belakang & bingkai bambu depan: 9 layer 2D Vector/SDF Painterly Parallax hasil Visual Studio C++
#   (langit senja, matahari besar berpendar + sunburst berputar ala versi kemarin, awan empuk, pegunungan berkabut,
#   rumah onsen kayu Jepang, gerbang Torii merah, kolam air panas beruap, tebing ketapel bambu, bukit lumut, bingkai bambu)
# - Karakter utama: 9 Kapibara 3D pahatan Visual Studio C++ dengan shader lineless painterly (rovio_25d.gdshader)
#   dirender transparan di atas latar 2D & di belakang bingkai bambu depan!
# - Logo Vektor Original Opsi 2 (tulisannya saja) & menu PLAY / 4 WORLD / CREDITS / EXIT.

const TESTER_SCENE_PATH := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const SQUAD_ACTORS := [
	# 0. HERO DEPAN-TENGAH: Chill Capi Mengaum (MC Merah Crimson)
	{
		"name": "Chill Capi (MC)",
		"role": "Pemimpin Pemarah - Gelombang Zen",
		"quote": "\"Sentuh jeruk Yuzu lagi... HABIS KALIAN!\"",
		"mesh": "res://assets/generated/models/home_capy_chill_roar.obj",
		"pos": Vector3(-0.02, 0.84, 1.56),
		"scale": 1.66,
		"yaw": -62.0,
		"pitch": -7.0,
		"roll": 2.0,
		"bob_amp": 0.024,
		"bob_spd": 2.6,
		"phase": 0.0,
		"rim": Color(1.0, 0.80, 0.40)
	},
	# 1. BAHU KIRI CHILL: Yuzu Bomb + Kobaran Api Menyala!
	{
		"name": "Yuzu Bomb",
		"role": "Sumbu Pendek - Ledakan Api Yuzu",
		"quote": "\"Hoaam... jangan bangunin pas sumbu udah nyala!\"",
		"mesh": "res://assets/generated/models/home_capy_bomb_blaze.obj",
		"pos": Vector3(-1.12, 0.96, 0.72),
		"scale": 1.28,
		"yaw": -50.0,
		"pitch": 4.0,
		"roll": -4.0,
		"bob_amp": 0.022,
		"bob_spd": 1.9,
		"phase": 1.2,
		"rim": Color(1.0, 0.68, 0.28)
	},
	# 2. BAHU KANAN MENJULANG: Heavy Onsen ("Merah Besar") Raksasa!
	{
		"name": "Heavy Onsen Capi",
		"role": "Titan Sumo - Penghancur Batu & Baja",
		"quote": "\"Hmph! Satu benturan, rata semua.\"",
		"mesh": "res://assets/generated/models/anime_capy_heavy_onsen.obj",
		"pos": Vector3(1.16, 1.12, 0.34),
		"scale": 1.30,
		"yaw": -124.0,
		"pitch": -4.0,
		"roll": 2.0,
		"bob_amp": 0.018,
		"bob_spd": 1.4,
		"phase": 2.1,
		"rim": Color(1.0, 0.78, 0.52)
	},
	# 3. SAYAP KANAN DEPAN: Bambu-Katana + Tebasan Sabit Cyan!
	{
		"name": "Bambu-Katana Capi",
		"role": "Ronin Serius - Tebasan & Pantul Laser",
		"quote": "\"Satu tebasan, seluruh benteng tumbang.\"",
		"mesh": "res://assets/generated/models/home_capy_katana_slash.obj",
		"pos": Vector3(1.86, 0.68, 1.06),
		"scale": 1.12,
		"yaw": -132.0,
		"pitch": -9.0,
		"roll": 7.0,
		"bob_amp": 0.028,
		"bob_spd": 3.1,
		"phase": 3.4,
		"rim": Color(0.55, 0.94, 1.0)
	},
	# 4. SAYAP KIRI DEPAN: Seed-Blaster (Koboi Sinis)
	{
		"name": "Seed-Blaster Capi",
		"role": "Penembak Sinis - Tembakan Biji Kembar",
		"quote": "\"Target segede itu masa meleset?\"",
		"mesh": "res://assets/generated/models/anime_capy_seed_blaster.obj",
		"pos": Vector3(-1.66, 0.68, 1.18),
		"scale": 1.04,
		"yaw": -46.0,
		"pitch": -3.0,
		"roll": -5.0,
		"bob_amp": 0.024,
		"bob_spd": 2.4,
		"phase": 4.0,
		"rim": Color(1.0, 0.80, 0.42)
	},
	# 5. MELESAT DI LANGIT SENJA KANAN ATAS (tepat di atas Gerbang Torii 2D!)
	{
		"name": "Dash Capi",
		"role": "Sprinter Hiperaktif - Turbo Seruduk",
		"quote": "\"WUUUSSSHH!! Ketinggalan semua nih!\"",
		"mesh": "res://assets/generated/models/home_capy_dash_leap.obj",
		"pos": Vector3(2.26, 2.52, -0.35),
		"scale": 1.12,
		"yaw": -142.0,
		"pitch": -15.0,
		"roll": -14.0,
		"bob_amp": 0.095,
		"bob_spd": 4.2,
		"phase": 0.7,
		"rim": Color(1.0, 0.92, 0.46)
	},
	# 6-8. TRIO MINI BERTUMPUK 3 DI TEBING KIRI SEBELAH KETAPEL BAMBU 2D!
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Hehe! Satu aja udah pusing, apalagi bertiga!\"",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"pos": Vector3(-2.34, 0.78, 0.56),
		"scale": 0.78,
		"yaw": -36.0,
		"pitch": 6.0,
		"roll": 5.0,
		"bob_amp": 0.028,
		"bob_spd": 3.8,
		"phase": 1.4,
		"rim": Color(0.68, 0.90, 1.0)
	},
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Ayo luncurin kita duluan!!\"",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"pos": Vector3(-2.42, 1.22, 0.46),
		"scale": 0.76,
		"yaw": -44.0,
		"pitch": 10.0,
		"roll": -7.0,
		"bob_amp": 0.036,
		"bob_spd": 4.2,
		"phase": 2.4,
		"rim": Color(0.68, 0.90, 1.0)
	},
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Wihh dari puncak tebing bambu kelihatan semua!\"",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"pos": Vector3(-2.34, 1.64, 0.36),
		"scale": 0.74,
		"yaw": -34.0,
		"pitch": 14.0,
		"roll": 10.0,
		"bob_amp": 0.044,
		"bob_spd": 4.6,
		"phase": 3.5,
		"rim": Color(0.68, 0.90, 1.0)
	}
]

const BASE_CAM_POS := Vector3(0.0, 1.48, 6.25)
const BASE_CAM_TARGET := Vector3(0.0, 1.32, 0.0)

var shader_rovio: Shader
var shader_vignette: Shader

var bg_stage: Control
var fg_stage: Control
var sub_viewport: SubViewport
var world_3d_root: Node3D
var cam: Camera3D

var parallax_layers: Array[Dictionary] = []
var sunburst_node: TextureRect
var clouds_node: TextureRect
var steam_nodes: Array[Dictionary] = []
var leaf_nodes: Array[Dictionary] = []

var actors: Array[Dictionary] = []
var ember_nodes: Array[Dictionary] = []

var elapsed_time: float = 0.0
var intro_duration: float = 1.10
var intro_finished: bool = false
var mouse_parallax: Vector2 = Vector2.ZERO
var smooth_parallax: Vector2 = Vector2.ZERO

var capture_path: String = ""
var capture_done: bool = false

# UI nodes
var logo_root: Control
var loading_strip: Control
var loading_bar: ProgressBar
var play_button: Button
var corner_menu: HBoxContainer
var speech_bubble: PanelContainer
var speech_name: Label
var speech_quote: Label
var speech_timer: float = 0.0
var modal_overlay: ColorRect
var modal_title: Label
var modal_body: RichTextLabel

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.substr(10)

	shader_rovio = load("res://shaders/rovio_25d.gdshader")
	shader_vignette = load("res://shaders/vignette.gdshader")
	clip_contents = true

	# 1. Latar 2D Berlapis (Layer 00 s/d 07)
	bg_stage = Control.new()
	bg_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_stage)
	_setup_2d_background_layers()

	# 2. SubViewport 3D Transparan untuk 9 Kapibara 3D Lineless Painterly (rovio_25d.gdshader)
	_setup_3d_capybara_viewport()

	# 3. Bingkai Bambu Depan & Daun Melayang (di depan karakter 3D untuk kedalaman 2.5D sejati!)
	fg_stage = Control.new()
	fg_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	fg_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fg_stage)
	_setup_2d_foreground_layers()

	# 4. Antarmuka Logo Opsi 2 & Tombol Arcade
	_setup_arcade_ui()

	if capture_path != "":
		elapsed_time = 2.0
		_finish_intro()

func _add_layer_sprite(parent: Control, path: String, base_pos: Vector2, sz: Vector2, depth: float, overscan: float = 1.06) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz * overscan
	var center_shift: Vector2 = (tr.size - sz) * 0.5
	var pos: Vector2 = base_pos - center_shift
	tr.position = pos
	tr.pivot_offset = tr.size * 0.5
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	parallax_layers.append({ "node": tr, "base": pos, "depth": depth })
	return tr

func _setup_2d_background_layers() -> void:
	# Layer 0: Langit senja golden-hour + bola matahari besar berpendar ala versi kemarin
	_add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_00_sky_sun.png", Vector2.ZERO, BASE_SIZE, 0.06, 1.06)

	# Layer 1: Sunburst tegas berputar halus berpusat di bola matahari (640, 342)
	sunburst_node = TextureRect.new()
	sunburst_node.texture = load("res://assets/generated/home2d/layer_01_sunburst.png")
	sunburst_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sunburst_node.stretch_mode = TextureRect.STRETCH_SCALE
	sunburst_node.size = Vector2(1240.0, 1240.0)
	var sun_base := Vector2(640.0 - 620.0, 342.0 - 620.0)
	sunburst_node.position = sun_base
	sunburst_node.pivot_offset = Vector2(620.0, 620.0)
	sunburst_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_stage.add_child(sunburst_node)
	parallax_layers.append({ "node": sunburst_node, "base": sun_base, "depth": 0.10 })

	# Layer 2: Awan empuk melayang pelan
	clouds_node = _add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 18.0), Vector2(1280.0, 420.0), 0.16, 1.08)

	# Layer 3: Pegunungan bambu berkabut jauh
	_add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.24, 1.07)

	# Layer 4: Rumah Onsen kayu Jepang + Gerbang Torii merah + Kolam air panas
	_add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.38, 1.07)

	# Layer 5: Kepulan uap onsen lembut naik di atas kolam kanan
	var steam_tex: Texture2D = load("res://assets/generated/home2d/layer_05_steam_wisps.png")
	for i in 2:
		var st := TextureRect.new()
		st.texture = steam_tex
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.stretch_mode = TextureRect.STRETCH_SCALE
		st.size = Vector2(310.0, 310.0)
		var base_p := Vector2(885.0 + float(i) * 32.0, 310.0)
		st.position = base_p
		st.pivot_offset = st.size * 0.5
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_stage.add_child(st)
		steam_nodes.append({ "node": st, "base": base_p, "depth": 0.42, "phase": float(i) * 1.45 })

	# Layer 6: Tebing kiri berlumut + Ketapel Bambu 2D
	_add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_06_slingshot_cliff.png", Vector2.ZERO, BASE_SIZE, 0.54, 1.08)

	# Layer 7: Bukit rumput lumut depan tempat seluruh 9 kapibara 3D berpijak
	_add_layer_sprite(bg_stage, "res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 318.0), Vector2(1280.0, 420.0), 0.78, 1.08)

func _setup_3d_capybara_viewport() -> void:
	var vp_container := SubViewportContainer.new()
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	vp_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(vp_container)

	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2i(1280, 720)
	sub_viewport.transparent_bg = true
	sub_viewport.own_world_3d = true
	sub_viewport.physics_object_picking = true
	sub_viewport.msaa_3d = Viewport.MSAA_4X
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(sub_viewport)

	world_3d_root = Node3D.new()
	sub_viewport.add_child(world_3d_root)

	# Environment 3D transparan (BG_CLEAR_COLOR) + pencahayaan studio golden-hour kemarin
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.58, 0.62)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.00

	var we := WorldEnvironment.new()
	we.environment = env
	world_3d_root.add_child(we)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-28.0, 26.0, 0.0)
	key_light.light_energy = 0.80
	key_light.light_color = Color(1.0, 0.94, 0.85)
	world_3d_root.add_child(key_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-14.0, -160.0, 0.0)
	rim_light.light_energy = 0.34
	rim_light.light_color = Color(1.0, 0.78, 0.40)
	world_3d_root.add_child(rim_light)

	var fire_light := OmniLight3D.new()
	fire_light.position = Vector3(-1.14, 1.94, 0.82)
	fire_light.light_color = Color(1.0, 0.56, 0.16)
	fire_light.light_energy = 0.34
	fire_light.omni_range = 1.25
	world_3d_root.add_child(fire_light)

	var slash_light := OmniLight3D.new()
	slash_light.position = Vector3(2.18, 1.04, 1.32)
	slash_light.light_color = Color(0.28, 0.92, 1.0)
	slash_light.light_energy = 0.30
	slash_light.omni_range = 1.25
	world_3d_root.add_child(slash_light)

	cam = Camera3D.new()
	cam.fov = 34.0
	cam.near = 0.1
	cam.far = 100.0
	cam.position = BASE_CAM_POS
	world_3d_root.add_child(cam)
	cam.make_current()
	cam.look_at(BASE_CAM_TARGET, Vector3.UP)

	# Spawn seluruh 9 aktor kapibara 3D pahatan Visual Studio C++
	for i in SQUAD_ACTORS.size():
		var cfg: Dictionary = SQUAD_ACTORS[i]
		var root := Node3D.new()
		root.position = cfg["pos"]
		root.rotation_degrees = Vector3(0.0, float(cfg["yaw"]), 0.0)
		world_3d_root.add_child(root)

		var pose_pivot := Node3D.new()
		pose_pivot.rotation_degrees = Vector3(float(cfg["roll"]), 0.0, float(cfg["pitch"]))
		pose_pivot.scale = Vector3.ONE * float(cfg["scale"])
		root.add_child(pose_pivot)

		var mi := MeshInstance3D.new()
		mi.mesh = load(cfg["mesh"])
		_apply_25d_model_materials(mi, cfg["rim"], 0.34, 0.16)
		pose_pivot.add_child(mi)

		# Hitbox klik interaktif untuk pose lompat & balon dialog singkat
		var area := Area3D.new()
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.46 * float(cfg["scale"])
		col.shape = sphere
		col.position = Vector3(0.0, 0.10, 0.0)
		area.add_child(col)
		var idx := i
		area.input_event.connect(func(_cam, event, _pos, _norm, _shape):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_trigger_actor_reaction(idx)
		)
		root.add_child(area)

		actors.append({
			"cfg": cfg,
			"root": root,
			"pose": pose_pivot,
			"hop_t": 0.0,
			"drop_delay": 0.060 * float(i)
		})

	# Percikan bara api 3D hangat naik dari kobaran api Yuzu Bomb
	var rng := RandomNumberGenerator.new()
	rng.seed = 20262332
	var em_mat := StandardMaterial3D.new()
	em_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em_mat.albedo_color = Color(1.0, 0.84, 0.28)
	em_mat.emission_enabled = true
	em_mat.emission = Color(1.0, 0.56, 0.14)
	em_mat.emission_energy_multiplier = 1.6
	for i in 12:
		var em := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.018, 0.036)
		sm.height = sm.radius * 2.0
		em.mesh = sm
		em.material_override = em_mat
		var orig := Vector3(-1.12 + rng.randf_range(-0.28, 0.28), 1.68 + rng.randf_range(0.0, 0.95), 0.78 + rng.randf_range(-0.15, 0.20))
		em.position = orig
		world_3d_root.add_child(em)
		ember_nodes.append({ "node": em, "base": orig, "spd": rng.randf_range(0.65, 1.3), "phase": rng.randf_range(0.0, TAU) })

func _apply_25d_model_materials(mi: MeshInstance3D, rim_col: Color, rim_str: float, sheen_str: float = 0.16) -> void:
	if not mi.mesh or not shader_rovio:
		return

	for s_idx in mi.mesh.get_surface_count():
		var orig := mi.mesh.surface_get_material(s_idx)
		var mat_name: String = orig.resource_name if orig else ""
		var rovio_mat := ShaderMaterial.new()
		rovio_mat.shader = shader_rovio

		var local_rim: float = rim_str
		var local_sheen: float = sheen_str
		if mat_name in ["mat_ink", "mat_mouth_dark", "mat_anime_eye"]:
			local_rim = 0.05
			local_sheen = 0.24 if mat_name == "mat_anime_eye" else 0.04
		elif mat_name in ["mat_home_flame", "mat_home_slash", "mat_home_speed", "mat_spark", "mat_shoji_glow"]:
			local_rim = 0.0
			local_sheen = 0.0

		rovio_mat.set_shader_parameter("rim_color", Vector3(rim_col.r, rim_col.g, rim_col.b))
		rovio_mat.set_shader_parameter("rim_strength", local_rim)
		rovio_mat.set_shader_parameter("sheen_strength", local_sheen)

		if orig is BaseMaterial3D:
			if orig.albedo_texture:
				rovio_mat.set_shader_parameter("albedo_tex", orig.albedo_texture)
			rovio_mat.set_shader_parameter("tint_color", orig.albedo_color)
			if orig.emission_enabled:
				rovio_mat.set_shader_parameter("emission_color", Vector3(orig.emission.r, orig.emission.g, orig.emission.b))
		mi.set_surface_override_material(s_idx, rovio_mat)

func _setup_2d_foreground_layers() -> void:
	# Layer 8: Bingkai batang & daun bambu 2D di depan kapibara 3D (parallax tercepat!)
	_add_layer_sprite(fg_stage, "res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 1.18, 1.08)

	# Daun bambu hijau lembut melayang di sisi kiri & kanan dekat rumpun bambu (tidak menutupi wajah MC!)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20262424
	for i in 8:
		var lf := ColorRect.new()
		lf.size = Vector2(rng.randf_range(12.0, 18.0), rng.randf_range(4.5, 6.5))
		lf.pivot_offset = lf.size * 0.5
		lf.color = Color(0.58, 0.90, 0.28, 0.78)
		lf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lx: float = rng.randf_range(45.0, 290.0) if (i % 2 == 0) else rng.randf_range(990.0, 1235.0)
		var base_p := Vector2(lx, rng.randf_range(40.0, 560.0))
		lf.position = base_p
		fg_stage.add_child(lf)
		leaf_nodes.append({
			"node": lf,
			"base": base_p,
			"spd": rng.randf_range(0.45, 0.85),
			"phase": rng.randf_range(0.0, TAU)
		})

func _setup_arcade_ui() -> void:
	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)

	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if shader_vignette:
		var vmat := ShaderMaterial.new()
		vmat.shader = shader_vignette
		vmat.set_shader_parameter("vignette_strength", 0.24)
		vmat.set_shader_parameter("vignette_softness", 0.56)
		vig.material = vmat
	else:
		vig.color = Color(0, 0, 0, 0)
	ui_root.add_child(vig)

	# LOGO VEKTOR ORIGINAL OPSI 2 (tulisannya saja, PNG transparan)
	logo_root = Control.new()
	logo_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo_root.offset_left = -295
	logo_root.offset_right = 295
	logo_root.offset_top = 12
	logo_root.offset_bottom = 228
	logo_root.pivot_offset = Vector2(295, 108)
	logo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(logo_root)

	var logo_tex := TextureRect.new()
	logo_tex.texture = load("res://assets/ui/logo_angry_capibara.png")
	logo_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_root.add_child(logo_tex)

	var display_font := SystemFont.new()
	display_font.font_names = PackedStringArray(["Impact", "Arial Black", "Segoe UI Black"])
	display_font.font_weight = 900

	# Intro loading bar
	loading_strip = Control.new()
	loading_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	loading_strip.offset_left = -180
	loading_strip.offset_right = 180
	loading_strip.offset_top = -52
	loading_strip.offset_bottom = -20
	ui_root.add_child(loading_strip)

	loading_bar = ProgressBar.new()
	loading_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_bar.min_value = 0.0
	loading_bar.max_value = 100.0
	loading_bar.show_percentage = false
	var lbg := StyleBoxFlat.new()
	lbg.bg_color = Color(0.08, 0.10, 0.08, 0.86)
	lbg.border_color = Color(1.0, 0.84, 0.30)
	lbg.set_border_width_all(3)
	lbg.set_corner_radius_all(12)
	var lfill := StyleBoxFlat.new()
	lfill.bg_color = Color(1.0, 0.56, 0.14)
	lfill.set_corner_radius_all(9)
	loading_bar.add_theme_stylebox_override("background", lbg)
	loading_bar.add_theme_stylebox_override("fill", lfill)
	loading_strip.add_child(loading_bar)

	# Tombol PLAY arcade besar bersih di bagian bawah tengah
	play_button = _make_glossy_button("PLAY", Color(0.94, 0.32, 0.14), Color(1.0, 0.96, 0.80), 34, Vector2(238, 62), 20)
	play_button.add_theme_font_override("font", display_font)
	play_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play_button.offset_left = -119
	play_button.offset_right = 119
	play_button.offset_top = -82
	play_button.offset_bottom = -20
	play_button.visible = false
	play_button.pressed.connect(_go_to_tester)
	ui_root.add_child(play_button)

	# Tombol pojok kanan bawah kompak
	corner_menu = HBoxContainer.new()
	corner_menu.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	corner_menu.offset_left = -318
	corner_menu.offset_right = -20
	corner_menu.offset_top = -60
	corner_menu.offset_bottom = -20
	corner_menu.alignment = BoxContainer.ALIGNMENT_END
	corner_menu.add_theme_constant_override("separation", 8)
	corner_menu.visible = false
	ui_root.add_child(corner_menu)

	var btn_worlds := _make_glossy_button("4 WORLD", Color(0.16, 0.48, 0.78), Color(0.95, 0.98, 1.0), 13, Vector2(96, 38), 14)
	btn_worlds.pressed.connect(_show_worlds_modal)
	corner_menu.add_child(btn_worlds)

	var btn_credits := _make_glossy_button("CREDITS", Color(0.24, 0.58, 0.28), Color(0.96, 1.0, 0.92), 13, Vector2(92, 38), 14)
	btn_credits.pressed.connect(_show_credits_modal)
	corner_menu.add_child(btn_credits)

	var btn_exit := _make_glossy_button("EXIT", Color(0.24, 0.22, 0.28), Color(0.94, 0.92, 0.96), 13, Vector2(72, 38), 14)
	btn_exit.pressed.connect(func(): get_tree().quit())
	corner_menu.add_child(btn_exit)

	# Balon dialog sementara saat klik kapibara / tekan 1-7
	speech_bubble = PanelContainer.new()
	speech_bubble.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	speech_bubble.offset_left = 22
	speech_bubble.offset_right = 374
	speech_bubble.offset_top = -94
	speech_bubble.offset_bottom = -20
	speech_bubble.visible = false
	var sb_style := StyleBoxFlat.new()
	sb_style.bg_color = Color(0.09, 0.11, 0.15, 0.90)
	sb_style.border_color = Color(1.0, 0.82, 0.28)
	sb_style.set_border_width_all(3)
	sb_style.set_corner_radius_all(14)
	speech_bubble.add_theme_stylebox_override("panel", sb_style)
	ui_root.add_child(speech_bubble)

	var sb_mar := MarginContainer.new()
	sb_mar.add_theme_constant_override("margin_left", 14)
	sb_mar.add_theme_constant_override("margin_right", 14)
	sb_mar.add_theme_constant_override("margin_top", 8)
	sb_mar.add_theme_constant_override("margin_bottom", 8)
	speech_bubble.add_child(sb_mar)

	var sb_vb := VBoxContainer.new()
	sb_vb.add_theme_constant_override("separation", 2)
	sb_mar.add_child(sb_vb)

	speech_name = Label.new()
	speech_name.add_theme_font_size_override("font_size", 15)
	speech_name.add_theme_color_override("font_color", Color(1.0, 0.86, 0.26))
	sb_vb.add_child(speech_name)

	speech_quote = Label.new()
	speech_quote.add_theme_font_size_override("font_size", 13)
	speech_quote.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
	speech_quote.autowrap_mode = TextServer.AUTOWRAP_WORD
	sb_vb.add_child(speech_quote)

	# Modal Overlay (Worlds & Credits)
	modal_overlay = ColorRect.new()
	modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.color = Color(0.03, 0.04, 0.07, 0.78)
	modal_overlay.visible = false
	ui_root.add_child(modal_overlay)

	var mpanel := PanelContainer.new()
	mpanel.set_anchors_preset(Control.PRESET_CENTER)
	mpanel.offset_left = -310
	mpanel.offset_right = 310
	mpanel.offset_top = -205
	mpanel.offset_bottom = 205
	mpanel.add_theme_stylebox_override("panel", sb_style)
	modal_overlay.add_child(mpanel)

	var mmar := MarginContainer.new()
	mmar.add_theme_constant_override("margin_left", 22)
	mmar.add_theme_constant_override("margin_right", 22)
	mmar.add_theme_constant_override("margin_top", 18)
	mmar.add_theme_constant_override("margin_bottom", 18)
	mpanel.add_child(mmar)

	var mvbox := VBoxContainer.new()
	mvbox.add_theme_constant_override("separation", 12)
	mmar.add_child(mvbox)

	modal_title = Label.new()
	modal_title.add_theme_font_size_override("font_size", 22)
	modal_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	mvbox.add_child(modal_title)

	modal_body = RichTextLabel.new()
	modal_body.bbcode_enabled = true
	modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_font_size_override("normal_font_size", 14)
	mvbox.add_child(modal_body)

	var close_btn := _make_glossy_button("TUTUP", Color(0.86, 0.26, 0.20), Color(1, 1, 1), 15, Vector2(140, 38), 14)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): modal_overlay.visible = false)
	mvbox.add_child(close_btn)

func _make_glossy_button(text_str: String, bg: Color, fg: Color, fsize: int, min_sz: Vector2, radius: int) -> Button:
	var b := Button.new()
	b.text = text_str
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	b.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.03))
	b.add_theme_constant_override("outline_size", 6 if fsize >= 24 else 3)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = Color(1.0, 0.88, 0.42) if fsize >= 24 else Color(0.08, 0.06, 0.10)
	normal.set_border_width_all(4 if fsize >= 24 else 3)
	normal.set_corner_radius_all(radius)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	normal.shadow_size = 10
	normal.shadow_offset = Vector2(0, 5)

	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.16)

	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.16)
	pressed.shadow_offset = Vector2(0, 1)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _process(delta: float) -> void:
	elapsed_time += delta
	smooth_parallax = smooth_parallax.lerp(mouse_parallax, minf(delta * 5.2, 1.0))

	# 1. Geser seluruh layer latar 2D & bingkai bambu depan sesuai parallax mouse
	var px_offset := Vector2(-smooth_parallax.x * 26.0, -smooth_parallax.y * 13.0)
	for lyr in parallax_layers:
		var node: TextureRect = lyr["node"]
		var base_p: Vector2 = lyr["base"]
		var depth: float = float(lyr["depth"])
		var extra := Vector2.ZERO
		if node == clouds_node:
			extra.x = sin(elapsed_time * 0.24) * 18.0
		node.position = base_p + px_offset * depth + extra

	if sunburst_node:
		sunburst_node.rotation = elapsed_time * 0.10

	# 2. Uap onsen 2D naik lembut di atas kolam kanan
	for sp in steam_nodes:
		var n: TextureRect = sp["node"]
		var base_p: Vector2 = sp["base"]
		var depth: float = float(sp["depth"])
		var ph: float = float(sp["phase"])
		var cyc: float = fmod(elapsed_time * 0.34 + ph, 2.0) / 2.0
		n.position = base_p + px_offset * depth + Vector2(sin(elapsed_time * 0.9 + ph) * 12.0, -cyc * 68.0)
		n.modulate.a = sin(cyc * PI) * 0.85

	# 3. Daun bambu 2D melayang di depan
	for lf in leaf_nodes:
		var n: ColorRect = lf["node"]
		var b: Vector2 = lf["base"]
		var ph: float = float(lf["phase"])
		var spd: float = float(lf["spd"])
		var ny: float = fmod(b.y + elapsed_time * 38.0 * spd, 760.0) - 20.0
		n.position = Vector2(b.x + sin(elapsed_time * spd + ph) * 44.0, ny) + px_offset * 1.05
		n.rotation = sin(elapsed_time * 1.8 + ph) * 0.85

	# 4. Bara api 3D naik dari Yuzu Bomb
	for em in ember_nodes:
		var n: MeshInstance3D = em["node"]
		var b: Vector3 = em["base"]
		var ph: float = float(em["phase"])
		var spd: float = float(em["spd"])
		var cycle: float = fmod(elapsed_time * spd + ph, 1.8)
		n.position = b + Vector3(sin(elapsed_time * 3.0 + ph) * 0.16 + cycle * 0.16, cycle * 0.80, 0.0)
		n.scale = Vector3.ONE * maxf(sin((cycle / 1.8) * PI), 0.01)

	# 5. Intro loading bar & logo pulse
	if not intro_finished:
		var pct := clampf(elapsed_time / intro_duration, 0.0, 1.0)
		loading_bar.value = pct * 100.0
		if pct >= 1.0:
			_finish_intro()

	if logo_root:
		logo_root.scale = Vector2.ONE * (1.0 + sin(elapsed_time * 1.9) * 0.016)

	if intro_finished and play_button and not play_button.is_hovered():
		var pulse := 1.0 + sin(elapsed_time * 4.0) * 0.030
		play_button.pivot_offset = play_button.size * 0.5
		play_button.scale = Vector2(pulse, pulse)

	if speech_timer > 0.0:
		speech_timer -= delta
		if speech_timer <= 0.0 and speech_bubble:
			speech_bubble.visible = false

	# 6. Animasi 9 Kapibara 3D & kamera 3D tersinkron halus dengan parallax 2D
	for i in actors.size():
		var a: Dictionary = actors[i]
		var cfg: Dictionary = a["cfg"]
		var root: Node3D = a["root"]
		var pose: Node3D = a["pose"]

		var t_local := maxf(elapsed_time - float(a["drop_delay"]), 0.0)
		var drop_h := 0.0
		var sy := 1.0
		var sxz := 1.0
		if t_local < 0.50:
			var u := t_local / 0.50
			if u < 0.65:
				var d := 1.0 - (u / 0.65)
				drop_h = d * d * 2.2
			else:
				var sq := sin(((u - 0.65) / 0.35) * PI)
				sy = 1.0 - sq * 0.22
				sxz = 1.0 + sq * 0.15

		if float(a["hop_t"]) > 0.0:
			a["hop_t"] = maxf(float(a["hop_t"]) - delta * 2.2, 0.0)
			var hu: float = float(a["hop_t"])
			drop_h += sin(hu * PI) * 0.36
			root.rotation_degrees.y = float(cfg["yaw"]) + sin(hu * TAU) * 16.0
		else:
			root.rotation_degrees.y = float(cfg["yaw"]) + sin(elapsed_time * 0.9 + float(cfg["phase"])) * 2.5

		var bob: float = sin(elapsed_time * float(cfg["bob_spd"]) + float(cfg["phase"])) * float(cfg["bob_amp"])
		var base_p: Vector3 = cfg["pos"]
		root.position = base_p + Vector3(0.0, drop_h + bob, 0.0)
		pose.scale = Vector3(sxz, sy, sxz) * float(cfg["scale"])
		pose.rotation_degrees = Vector3(
			float(cfg["roll"]) + cos(elapsed_time * float(cfg["bob_spd"]) * 0.7 + float(cfg["phase"])) * 2.0,
			0.0,
			float(cfg["pitch"]) + sin(elapsed_time * float(cfg["bob_spd"]) + float(cfg["phase"])) * 2.8
		)

	if cam:
		var target_cam := BASE_CAM_POS + Vector3(smooth_parallax.x * 0.32, -smooth_parallax.y * 0.16, 0.0)
		cam.position = cam.position.lerp(target_cam, minf(delta * 5.2, 1.0))
		cam.look_at(BASE_CAM_TARGET, Vector3.UP)

	if capture_path != "" and not capture_done and elapsed_time > 2.25:
		capture_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_path)
		get_tree().quit()

func _finish_intro() -> void:
	intro_finished = true
	if loading_strip:
		loading_strip.visible = false
	if play_button:
		play_button.visible = true
	if corner_menu:
		corner_menu.visible = true

func _trigger_actor_reaction(idx: int) -> void:
	if idx < 0 or idx >= actors.size():
		return
	actors[idx]["hop_t"] = 1.0
	var cfg: Dictionary = SQUAD_ACTORS[idx]
	speech_name.text = "%s  —  %s" % [cfg["name"], cfg["role"]]
	speech_quote.text = cfg["quote"]
	speech_bubble.visible = true
	speech_timer = 3.8

func _go_to_tester() -> void:
	get_tree().change_scene_to_file(TESTER_SCENE_PATH)

func _show_worlds_modal() -> void:
	modal_title.text = "4 WORLD ANGRY CAPIBARA (80 STAGE)"
	modal_body.text = "[b]WORLD 1 — Bamboo Island (1-1 s/d 1-20)[/b]\nPulau bambu tropis & benteng kayu para Croco Minion bersama Chill Capi, Dash Capi, dan Trio Mini.\n\n[b]WORLD 2 — Sunset Onsen Dojo (2-1 s/d 2-20)[/b]\nPemandian air panas senja dengan batu pantul Onsen, tong Yuzu TNT, Yuzu Bomb, Seed-Blaster, Bambu-Katana, dan Heavy Onsen.\n\n[b]WORLD 3 — Neon Sky-Fortress (3-1 s/d 3-20)[/b]\nBenteng langit & Croc Turret penembak aktif dengan mekanik pantulan dan perisai.\n\n[b]WORLD 4 — Yuzu Moon Orbit (4-1 s/d 4-20)[/b]\nZona gravitasi rendah luar angkasa melawan benteng baja King Croc Boss."
	modal_overlay.visible = true

func _show_credits_modal() -> void:
	modal_title.text = "CREDITS — ANGRY CAPIBARA"
	modal_body.text = "[b]Ketua Tim & Pengembang Utama:[/b]\nTobias Andra Valentino (NIM: 245150200111076)\n\n[b]Mata Kuliah:[/b]\nKomputer Grafika — Interactive 3D Computer Graphics\n\n[b]Teknologi & Toolchain (100% Offline Visual Studio C++ + Godot):[/b]\n- Latar 2D Berlapis: Visual Studio C++ 2D Vector/SDF Painterly Engine (9 RGBA PNG layers)\n- Karakter 3D & Tekstur `.bmp`: Visual Studio C++ OpenGL Asset Forge (FreeGLUT, GLEW, GLM, Bicubic Bezier)\n- Game Engine & Shaders: Godot Engine 4.7.1.stable (GL Compatibility + Lineless 2.5D Painterly Shader)\n\n[b]Referensi Utama:[/b]\nAngry Birds Star Wars I & II"
	modal_overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_parallax = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			_trigger_actor_reaction(event.keycode - KEY_1)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if intro_finished and not modal_overlay.visible:
				_go_to_tester()
			elif not intro_finished:
				_finish_intro()
		elif event.keycode == KEY_ESCAPE and modal_overlay.visible:
			modal_overlay.visible = false
