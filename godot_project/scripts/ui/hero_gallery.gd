extends Control

# Halaman Penuh Squad Kapibara (Hero Gallery) dengan Showcase 3D Interaktif 360°
# Menggunakan 7 model 3D asli (.obj) + rovio_25d.gdshader di atas panggung woodblock flat-cel.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const HEROES := [
	{
		"id": "chill",
		"short": "CHILL",
		"name": "CHILL CAPI",
		"role": "KAPTEN KETAPEL • WORLD 1",
		"quote": "\"Sentuh jeruk Yuzu lagi... HABIS KALIAN!\"",
		"skill_name": "JURUS: ZEN BUMP",
		"skill_desc": "Menghantam tegak lurus ke bawah dengan gelombang kejut bambu!",
		"power": 4,
		"speed": 3,
		"target": "BAMBU & KLAN BUAYA",
		"mesh": "res://assets/generated/models/anime_capy_chill.obj",
		"portrait": "res://assets/generated/home2d/char_01_chill_roar.png",
		"wood": "wood_btn_vermilion",
		"burst": Color(0.95, 0.27, 0.18),
		"scale_h": 1.32,
		"unlocked": true,
		"demo_stage": "1-1",
		"cta": "COBA DI STAGE 1-1"
	},
	{
		"id": "dash",
		"short": "DASH",
		"name": "DASH CAPI",
		"role": "PELARI KILAT • WORLD 1",
		"quote": "\"WUUUSSSHH!! Ketinggalan semua nih!\"",
		"skill_name": "JURUS: TURBO DASH 2.2x",
		"skill_desc": "Melesat super cepat menembus balok kayu (1.8x daya hancur)!",
		"power": 3,
		"speed": 5,
		"target": "BALOK KAYU",
		"mesh": "res://assets/generated/models/anime_capy_dash.obj",
		"portrait": "res://assets/generated/home2d/char_06_dash_leap.png",
		"wood": "wood_btn_amber",
		"burst": Color(1.0, 0.72, 0.18),
		"scale_h": 1.32,
		"unlocked": true,
		"demo_stage": "1-6",
		"cta": "COBA DI STAGE 1-6"
	},
	{
		"id": "mini",
		"short": "TRIO MINI",
		"name": "TRIO MINI-CAPI",
		"role": "PASUKAN MINI • WORLD 1",
		"quote": "\"Hehe! Satu aja pusing, apalagi bertiga!\"",
		"skill_name": "JURUS: TRIPLE SPLIT 3x",
		"skill_desc": "Pecah menjadi 3 pasukan mini di udara — 2.0x daya hancur Es & Kaca!",
		"power": 2,
		"speed": 4,
		"target": "ES & KACA",
		"mesh": "res://assets/generated/models/anime_capy_mini.obj",
		"portrait": "res://assets/generated/home2d/char_07_mini_capi.png",
		"wood": "wood_btn_sky",
		"burst": Color(0.23, 0.70, 0.90),
		"scale_h": 1.12,
		"unlocked": true,
		"demo_stage": "1-11",
		"cta": "COBA DI STAGE 1-11"
	},
	{
		"id": "yuzu",
		"short": "YUZU BOMB",
		"name": "YUZU BOMB",
		"role": "AHLI LEDAKAN • WORLD 2",
		"quote": "\"Hoaam... jangan bangunin pas sumbu nyala!\"",
		"skill_name": "JURUS: LEDAKAN API YUZU",
		"skill_desc": "Memicu ledakan jeruk Yuzu dahsyat yang menghancurkan batu & baja!",
		"power": 5,
		"speed": 2,
		"target": "BATU & BENTENG",
		"mesh": "res://assets/generated/models/anime_capy_yuzu_bomb.obj",
		"portrait": "res://assets/generated/home2d/char_02_yuzu_bomb.png",
		"wood": "wood_btn_amber",
		"burst": Color(1.0, 0.55, 0.10),
		"scale_h": 1.40,
		"unlocked": false,
		"demo_stage": "",
		"cta": "TERBUKA DI WORLD 2"
	},
	{
		"id": "seed",
		"short": "SEED",
		"name": "SEED-BLASTER CAPI",
		"role": "PENEMBAK JITU • WORLD 2",
		"quote": "\"Target segede itu masa meleset?\"",
		"skill_name": "JURUS: TEMBAKAN BIJI KEMBAR",
		"skill_desc": "Menembakkan biji energi akurat ke arah turret dan menara atas!",
		"power": 3,
		"speed": 4,
		"target": "TURRET BUAYA",
		"mesh": "res://assets/generated/models/anime_capy_seed_blaster.obj",
		"portrait": "res://assets/generated/home2d/char_04_seed_blaster.png",
		"wood": "wood_btn_cedar",
		"burst": Color(0.89, 0.60, 0.23),
		"scale_h": 1.34,
		"unlocked": false,
		"demo_stage": "",
		"cta": "TERBUKA DI WORLD 2"
	},
	{
		"id": "katana",
		"short": "KATANA",
		"name": "BAMBU-KATANA CAPI",
		"role": "RONIN PEDANG • WORLD 2",
		"quote": "\"Satu tebasan, seluruh benteng tumbang.\"",
		"skill_name": "JURUS: TEBASAN SABER",
		"skill_desc": "Menebas pilar kayu dan bambu dalam satu garis serangan tajam!",
		"power": 4,
		"speed": 4,
		"target": "PILAR & ATAP",
		"mesh": "res://assets/generated/models/anime_capy_katana.obj",
		"portrait": "res://assets/generated/home2d/char_05_bambu_katana.png",
		"wood": "wood_btn_bamboo",
		"burst": Color(0.34, 0.79, 0.20),
		"scale_h": 1.38,
		"unlocked": false,
		"demo_stage": "",
		"cta": "TERBUKA DI WORLD 2"
	},
	{
		"id": "heavy",
		"short": "HEAVY",
		"name": "HEAVY ONSEN CAPI",
		"role": "TITAN SUMO • WORLD 2",
		"quote": "\"Hmph! Satu benturan, rata semua.\"",
		"skill_name": "JURUS: BENTURAN SUMO",
		"skill_desc": "Tubuh super berat yang meremukkan pondasi batu terkuat sekalipun!",
		"power": 5,
		"speed": 1,
		"target": "BENTENG BERAT",
		"mesh": "res://assets/generated/models/anime_capy_heavy_onsen.obj",
		"portrait": "res://assets/generated/home2d/char_03_heavy_onsen.png",
		"wood": "wood_btn_vermilion",
		"burst": Color(0.79, 0.24, 0.17),
		"scale_h": 1.52,
		"unlocked": false,
		"demo_stage": "",
		"cta": "TERBUKA DI WORLD 2"
	}
]

class StarburstHalo extends Control:
	var burst_color: Color = Color(0.95, 0.27, 0.18)
	var spin_angle: float = 0.0

	func _draw() -> void:
		var c := size * 0.5
		var rad := minf(size.x, size.y) * 0.34
		draw_circle(c, rad, Color(burst_color.r, burst_color.g, burst_color.b, 0.36))
		var ray_len := minf(size.x, size.y) * 0.49
		for i in 10:
			var a0 := spin_angle + float(i) * (TAU / 10.0)
			var a1 := a0 + deg_to_rad(15.0)
			var pts := PackedVector2Array([
				c,
				c + Vector2(cos(a0), sin(a0)) * ray_len,
				c + Vector2(cos(a1), sin(a1)) * ray_len
			])
			draw_colored_polygon(pts, Color(1.0, 0.91, 0.40, 0.30))

class ComicSpeechBubble extends Control:
	var quote_text: String = ""
	var padding := Vector2(14.0, 10.0)

	func _draw() -> void:
		var ink := CraftUI.INK
		var box := Rect2(Vector2.ZERO, size - Vector2(6.0, 18.0))
		# Hard comic offset shadow
		draw_rect(Rect2(box.position + Vector2(4.0, 4.0), box.size), ink, true)
		# Tail shadow & cream fill pointing down-left toward 3D hero
		var tail_x := clampf(box.size.x * 0.22, 24.0, box.size.x - 28.0)
		var tail_y := box.end.y
		draw_colored_polygon(PackedVector2Array([
			Vector2(tail_x - 2.0, tail_y - 2.0),
			Vector2(tail_x + 16.0, tail_y - 2.0),
			Vector2(tail_x - 10.0, tail_y + 18.0)
		]), ink)
		# Cream bubble fill + crisp ink border
		draw_rect(box, Color(1.0, 0.992, 0.949), true)
		draw_rect(box, ink, false, 4.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tail_x, tail_y - 3.0),
			Vector2(tail_x + 14.0, tail_y - 3.0),
			Vector2(tail_x - 7.0, tail_y + 13.0)
		]), Color(1.0, 0.992, 0.949))
		draw_line(Vector2(tail_x, tail_y), Vector2(tail_x - 7.0, tail_y + 13.0), ink, 3.5)
		draw_line(Vector2(tail_x + 14.0, tail_y), Vector2(tail_x - 7.0, tail_y + 13.0), ink, 3.5)

		var f := CraftUI.body_font()
		var text_w := box.size.x - padding.x * 2.0
		draw_multiline_string(f, Vector2(padding.x, padding.y + 14.0), quote_text, HORIZONTAL_ALIGNMENT_LEFT, text_w, 14, -1, ink)

var bg_layers: Array[Dictionary] = []
var selected_idx: int = 0
var hero_rail_items: Array[Dictionary] = []

# 3D Turntable Showcase
var shader_rovio: Shader
var tex_wood: Texture2D
var tex_moss: Texture2D
var halo_ctrl: StarburstHalo
var vp_container: SubViewportContainer
var cam_3d: Camera3D
var turntable_pivot: Node3D
var model_holder: Node3D
var speech_ctrl: ComicSpeechBubble

var orbit_yaw: float = -1.12  # +X mesh forward turned ~64 deg toward +Z camera (3/4 right view)
var orbit_pitch: float = 0.24
var cam_dist: float = 4.28
var yaw_vel: float = 0.0
var is_dragging: bool = false
var drag_moved: float = 0.0
var idle_spin_delay: float = 0.6
var hop_t: float = 0.0
var lock_shake_t: float = 0.0
var cta_base_x: float = 0.0

# Dossier UI
var lbl_status: Label
var lbl_hero_name: Label
var lbl_hero_role: Label
var skill_panel: PanelContainer
var lbl_skill_name: Label
var lbl_skill_desc: Label
var stat_power_segs: Array[ColorRect] = []
var stat_speed_segs: Array[ColorRect] = []
var lbl_target_val: Label
var btn_cta: Button

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false
var custom_start_yaw_set: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hero="):
			var target_id := arg.substr(7)
			for i in HEROES.size():
				if str(HEROES[i]["id"]) == target_id:
					selected_idx = i
					break
		elif arg.begins_with("--yaw="):
			orbit_yaw = deg_to_rad(float(arg.substr(6)))
			custom_start_yaw_set = true
		elif arg.begins_with("--capture-hero="):
			capture_path = arg.substr(15)

	shader_rovio = load("res://shaders/rovio_25d.gdshader")
	tex_wood = load("res://assets/generated/textures/tex_wood.bmp")
	tex_moss = load("res://assets/generated/textures/tex_moss_painterly.bmp")

	clip_contents = true
	_setup_parallax_bg()
	_setup_ui()
	_select_hero(selected_idx)

func _add_bg_tex(path: String, base_p: Vector2, sz: Vector2, depth: float, alpha: float = 1.0) -> void:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz * 1.06
	var shift: Vector2 = (tr.size - sz) * 0.5
	var pos: Vector2 = base_p - shift
	tr.position = pos
	tr.modulate.a = alpha
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	bg_layers.append({ "node": tr, "base": pos, "depth": depth })

func _setup_parallax_bg() -> void:
	_add_bg_tex("res://assets/generated/home2d/layer_00_sky_sun.png", Vector2.ZERO, BASE_SIZE, 0.06)
	_add_bg_tex("res://assets/generated/home2d/layer_01_sunburst.png", Vector2.ZERO, BASE_SIZE, 0.10, 0.65)
	_add_bg_tex("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 20.0), Vector2(1280.0, 420.0), 0.14)
	_add_bg_tex("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.22)
	_add_bg_tex("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.34)
	_add_bg_tex("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 330.0), Vector2(1280.0, 420.0), 0.52)
	_add_bg_tex("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 0.80)

	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.08, 0.06, 0.05, 0.24)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _make_rovio_mat(tex: Texture2D, tint: Color = Color.WHITE, uv_sc: Vector2 = Vector2.ONE) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader_rovio
	if tex:
		mat.set_shader_parameter("albedo_tex", tex)
	mat.set_shader_parameter("tint_color", tint)
	mat.set_shader_parameter("uv_scale", uv_sc)
	mat.set_shader_parameter("rim_strength", 0.22)
	mat.set_shader_parameter("sheen_strength", 0.12)
	mat.set_shader_parameter("shadow_tint", Vector3(0.46, 0.42, 0.48))
	mat.set_shader_parameter("rim_color", Vector3(0.98, 0.92, 0.76))
	return mat

func _apply_rovio_model_materials(mi: MeshInstance3D) -> void:
	if not mi.mesh or not shader_rovio:
		return
	for s_idx in mi.mesh.get_surface_count():
		var orig := mi.mesh.surface_get_material(s_idx)
		var mat_name: String = orig.resource_name if orig else ""
		var mat := ShaderMaterial.new()
		mat.shader = shader_rovio

		var local_rim: float = 0.26
		var local_sheen: float = 0.16
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
			mat.set_shader_parameter("tint_color", orig.albedo_color)
			if orig.emission_enabled:
				mat.set_shader_parameter("emission_color", Vector3(orig.emission.r, orig.emission.g, orig.emission.b))
		mi.set_surface_override_material(s_idx, mat)

func _setup_ui() -> void:
	# 1) TOP BAR
	var top_bar := MarginContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 84
	top_bar.add_theme_constant_override("margin_left", CraftUI.TOP_BAR_MARGIN_X)
	top_bar.add_theme_constant_override("margin_right", CraftUI.TOP_BAR_MARGIN_X)
	top_bar.add_theme_constant_override("margin_top", CraftUI.TOP_BAR_MARGIN_TOP)
	add_child(top_bar)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	top_bar.add_child(hdr)

	var btn_home := CraftUI.make_back_btn("HOME")
	btn_home.pressed.connect(func():
		SceneLoader.quick_transition_to(HOME_SCENE)
	)
	hdr.add_child(btn_home)

	var lbl_title := CraftUI.make_stroked_label("SQUAD KAPIBARA", 34, CraftUI.GOLD_TEXT, 7, true)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_title)

	var sc := CraftUI.make_star_counter("3 / 7 AKTIF", 26.0, 22)
	var sc_root: Control = sc["root"]
	sc_root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr.add_child(sc_root)

	# 2) LEFT INTERACTIVE 3D TURNTABLE SHOWCASE
	halo_ctrl = StarburstHalo.new()
	halo_ctrl.position = Vector2(96, 94)
	halo_ctrl.size = Vector2(468, 412)
	halo_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(halo_ctrl)

	vp_container = SubViewportContainer.new()
	vp_container.position = Vector2(96, 90)
	vp_container.size = Vector2(468, 414)
	vp_container.stretch = true
	vp_container.mouse_filter = Control.MOUSE_FILTER_STOP
	vp_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vp_container.gui_input.connect(_on_stage_gui_input)
	add_child(vp_container)

	var sub_vp := SubViewport.new()
	sub_vp.transparent_bg = true
	sub_vp.own_world_3d = true
	sub_vp.msaa_3d = Viewport.MSAA_4X
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(sub_vp)

	# SubViewport 3D Lighting & Camera
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.84, 0.80)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var we := WorldEnvironment.new()
	we.environment = env
	sub_vp.add_child(we)

	var key_sun := DirectionalLight3D.new()
	key_sun.rotation_degrees = Vector3(-32.0, 36.0, 0.0)
	key_sun.light_energy = 1.28
	sub_vp.add_child(key_sun)

	var rim_sun := DirectionalLight3D.new()
	rim_sun.rotation_degrees = Vector3(-16.0, -144.0, 0.0)
	rim_sun.light_energy = 0.66
	rim_sun.light_color = Color(1.0, 0.90, 0.72)
	sub_vp.add_child(rim_sun)

	cam_3d = Camera3D.new()
	cam_3d.fov = 34.0
	cam_3d.near = 0.1
	cam_3d.far = 50.0
	sub_vp.add_child(cam_3d)
	cam_3d.make_current()

	# 3D Pedestal + Turntable Pivot
	turntable_pivot = Node3D.new()
	sub_vp.add_child(turntable_pivot)

	var ped_wood := MeshInstance3D.new()
	var pw_m := CylinderMesh.new()
	pw_m.top_radius = 0.86
	pw_m.bottom_radius = 0.98
	pw_m.height = 0.22
	pw_m.radial_segments = 28
	ped_wood.mesh = pw_m
	ped_wood.position = Vector3(0.0, -0.11, 0.0)
	ped_wood.material_override = _make_rovio_mat(tex_wood, Color(0.76, 0.56, 0.34), Vector2(3.0, 1.0))
	turntable_pivot.add_child(ped_wood)

	var ped_moss := MeshInstance3D.new()
	var pm_m := CylinderMesh.new()
	pm_m.top_radius = 0.78
	pm_m.bottom_radius = 0.82
	pm_m.height = 0.08
	pm_m.radial_segments = 28
	ped_moss.mesh = pm_m
	ped_moss.position = Vector3(0.0, 0.02, 0.0)
	ped_moss.material_override = _make_rovio_mat(tex_moss, Color(0.68, 0.86, 0.44), Vector2(2.0, 2.0))
	turntable_pivot.add_child(ped_moss)

	model_holder = Node3D.new()
	model_holder.position = Vector3(0.0, 0.05, 0.0)
	turntable_pivot.add_child(model_holder)

	# Bare 360 Drag Hint directly below 3D pedestal
	var lbl_drag := CraftUI.make_stroked_label("SERET 360° • SCROLL ZOOM • KLIK LOMPAT", 13, Color(1.0, 0.96, 0.86), 5, false)
	lbl_drag.position = Vector2(102, 512)
	lbl_drag.size = Vector2(456, 26)
	lbl_drag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_drag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl_drag)

	# Left/Right Square Cedar Stamps flanking 3D Stage
	var btn_prev := CraftUI.make_wood_btn("◀", "wood_sq_cedar", Vector2(50, 50), 22, -2.5)
	btn_prev.position = Vector2(54, 274)
	btn_prev.pressed.connect(func(): _step_hero(-1))
	add_child(btn_prev)

	var btn_next := CraftUI.make_wood_btn("▶", "wood_sq_cedar", Vector2(50, 50), 22, 2.2)
	btn_next.position = Vector2(552, 274)
	btn_next.pressed.connect(func(): _step_hero(1))
	add_child(btn_next)

	# Comic Speech Bubble floating cleanly above right shoulder (zero brow overlap!)
	speech_ctrl = ComicSpeechBubble.new()
	speech_ctrl.position = Vector2(390, 88)
	speech_ctrl.size = Vector2(226, 82)
	speech_ctrl.pivot_offset = Vector2(113, 41)
	speech_ctrl.rotation_degrees = 1.6
	speech_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(speech_ctrl)

	# 3) RIGHT OPEN WOODBLOCK DOSSIER (Zero big white container card!)
	var dossier := VBoxContainer.new()
	dossier.position = Vector2(640, 108)
	dossier.size = Vector2(598, 432)
	dossier.add_theme_constant_override("separation", 12)
	add_child(dossier)

	var title_vb := VBoxContainer.new()
	title_vb.add_theme_constant_override("separation", 1)
	dossier.add_child(title_vb)

	lbl_status = CraftUI.make_stroked_label("★ SIAP TEMPUR!", 16, Color(0.48, 0.94, 0.30), 5, false)
	title_vb.add_child(lbl_status)

	lbl_hero_name = CraftUI.make_stroked_label("CHILL CAPI", 46, CraftUI.GOLD_TEXT, 7, true)
	title_vb.add_child(lbl_hero_name)

	lbl_hero_role = CraftUI.make_stroked_label("PEMIMPIN PEMARAH • WORLD 1", 17, Color(1.0, 0.97, 0.86), 5, false)
	title_vb.add_child(lbl_hero_role)

	# Skill Wood Signboard + SPASI Keycap + Effect Text
	var skill_vb := VBoxContainer.new()
	skill_vb.add_theme_constant_override("separation", 6)
	dossier.add_child(skill_vb)

	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 12)
	skill_vb.add_child(skill_row)

	skill_panel = PanelContainer.new()
	skill_panel.custom_minimum_size = Vector2(320, 50)
	skill_panel.pivot_offset = Vector2(160, 25)
	skill_panel.rotation_degrees = -0.8
	skill_panel.add_theme_stylebox_override("panel", CraftUI.make_full_style("wood_btn_vermilion", 20.0, 6.0))
	skill_row.add_child(skill_panel)

	lbl_skill_name = CraftUI.make_stroked_label("JURUS: ZEN BUMP", 18, CraftUI.CREAM_TEXT, 4, true)
	lbl_skill_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_skill_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill_panel.add_child(lbl_skill_name)

	skill_row.add_child(CraftUI.make_keycap("SPASI", 70.0, 36.0, 14))

	lbl_skill_desc = CraftUI.make_stroked_label("", 17, CraftUI.CREAM_TEXT, 5, false)
	lbl_skill_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_skill_desc.custom_minimum_size = Vector2(540, 24)
	skill_vb.add_child(lbl_skill_desc)

	# 3 Flat-Cel Segmented Stat Bars
	var stats_vb := VBoxContainer.new()
	stats_vb.add_theme_constant_override("separation", 8)
	dossier.add_child(stats_vb)

	stat_power_segs = _add_stat_bar_row(stats_vb, "DAYA HANTAM")
	stat_speed_segs = _add_stat_bar_row(stats_vb, "KECEPATAN")

	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 14)
	stats_vb.add_child(target_row)

	var t_lbl := CraftUI.make_stroked_label("TARGET KUAT", 16, Color(1.0, 0.95, 0.78), 4, true)
	t_lbl.custom_minimum_size = Vector2(146, 22)
	target_row.add_child(t_lbl)

	lbl_target_val = CraftUI.make_stroked_label("BAMBU & KLAN BUAYA", 18, Color(0.56, 0.91, 0.41), 4, true)
	target_row.add_child(lbl_target_val)

	# Action CTA Button
	var cta_wrap := Control.new()
	cta_wrap.custom_minimum_size = Vector2(280, 62)
	dossier.add_child(cta_wrap)

	btn_cta = CraftUI.make_wood_btn("COBA DI STAGE 1-1", "wood_btn_vermilion", Vector2(276, 56), 20, -1.0, "icon_play_tri", 20)
	btn_cta.position = Vector2(0, 4)
	cta_base_x = 0.0
	btn_cta.pressed.connect(_on_cta_pressed)
	cta_wrap.add_child(btn_cta)

	# 4) BOTTOM 7-HERO WOODEN PICKER RAIL
	var rail := HBoxContainer.new()
	rail.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rail.offset_left = -590
	rail.offset_right = 590
	rail.offset_top = -126
	rail.offset_bottom = -14
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 16)
	add_child(rail)

	hero_rail_items.clear()
	for i in HEROES.size():
		var h: Dictionary = HEROES[i]
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(146, 106)
		rail.add_child(slot)

		var btn := Button.new()
		btn.position = Vector2(0, 14)
		btn.size = Vector2(146, 90)
		btn.pivot_offset = Vector2(73, 45)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("focus", empty)
		var h_idx := i
		btn.pressed.connect(func(): _select_hero(h_idx))
		slot.add_child(btn)

		var portrait := CraftUI.make_tex_rect(load(str(h["portrait"])), Vector2(74, 74))
		portrait.position = Vector2(36, -6)
		slot.add_child(portrait)

		var lbl_short := CraftUI.make_stroked_label(str(h["short"]), 14, CraftUI.CREAM_TEXT, 4, true)
		lbl_short.position = Vector2(6, 72)
		lbl_short.size = Vector2(134, 24)
		lbl_short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_short.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(lbl_short)

		var lock_ic: TextureRect = null
		if not bool(h["unlocked"]):
			lock_ic = CraftUI.make_tex_rect(CraftUI.tex("icon_padlock"), Vector2(22, 22))
			lock_ic.position = Vector2(114, 18)
			slot.add_child(lock_ic)

		var arrow_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_arrow_down_red"), Vector2(28, 25))
		arrow_ic.position = Vector2(59, -30)
		arrow_ic.visible = false
		slot.add_child(arrow_ic)

		hero_rail_items.append({
			"slot": slot,
			"btn": btn,
			"portrait": portrait,
			"label": lbl_short,
			"arrow": arrow_ic
		})

func _add_stat_bar_row(parent: VBoxContainer, label_txt: String) -> Array[ColorRect]:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(row)

	var lbl := CraftUI.make_stroked_label(label_txt, 16, Color(1.0, 0.95, 0.78), 4, true)
	lbl.custom_minimum_size = Vector2(146, 22)
	row.add_child(lbl)

	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(220, 22)
	track.color = CraftUI.INK
	row.add_child(track)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 3
	hb.offset_right = -3
	hb.offset_top = 3
	hb.offset_bottom = -3
	hb.add_theme_constant_override("separation", 2)
	track.add_child(hb)

	var segs: Array[ColorRect] = []
	for _k in 5:
		var seg := ColorRect.new()
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.color = Color(0.23, 0.11, 0.07)
		hb.add_child(seg)
		segs.append(seg)
	return segs

func _select_hero(idx: int) -> void:
	selected_idx = wrapi(idx, 0, HEROES.size())
	var h: Dictionary = HEROES[selected_idx]

	# Rebuild 3D model on pedestal, centered by AABB with bottom sitting cleanly on moss disc!
	for c in model_holder.get_children():
		c.queue_free()
	var mesh_path := str(h["mesh"])
	if ResourceLoader.exists(mesh_path):
		var mi := MeshInstance3D.new()
		mi.mesh = load(mesh_path)
		_apply_rovio_model_materials(mi)
		var aabb: AABB = mi.mesh.get_aabb()
		var sc: float = float(h["scale_h"]) / maxf(aabb.size.y, 0.01)
		mi.scale = Vector3.ONE * sc
		var center_xz := aabb.position + aabb.size * 0.5
		mi.position = Vector3(-center_xz.x * sc, -aabb.position.y * sc, -center_xz.z * sc)
		model_holder.add_child(mi)

	if not custom_start_yaw_set:
		orbit_yaw = -1.12
	custom_start_yaw_set = false
	yaw_vel = 0.0
	hop_t = 0.85

	if halo_ctrl:
		halo_ctrl.burst_color = h["burst"]
		halo_ctrl.queue_redraw()
	if speech_ctrl:
		speech_ctrl.quote_text = str(h["quote"])
		speech_ctrl.queue_redraw()

	var unlocked := bool(h["unlocked"])
	lbl_status.text = "★ SIAP TEMPUR!" if unlocked else "★ MENYUSUL DI WORLD 2"
	lbl_status.add_theme_color_override("font_color", Color(0.48, 0.94, 0.30) if unlocked else Color(1.0, 0.83, 0.33))
	lbl_hero_name.text = str(h["name"])
	lbl_hero_role.text = str(h["role"])

	skill_panel.add_theme_stylebox_override("panel", CraftUI.make_full_style(str(h["wood"]), 20.0, 6.0))
	lbl_skill_name.text = str(h["skill_name"])
	lbl_skill_desc.text = str(h["skill_desc"])
	lbl_target_val.text = str(h["target"])

	var pw: int = int(h["power"])
	var sp: int = int(h["speed"])
	for i in 5:
		stat_power_segs[i].color = Color(0.95, 0.27, 0.18) if i < pw else Color(0.23, 0.11, 0.07)
		stat_speed_segs[i].color = Color(1.0, 0.72, 0.18) if i < sp else Color(0.23, 0.11, 0.07)

	btn_cta.text = str(h["cta"])
	if unlocked:
		btn_cta.icon = CraftUI.tex("icon_play_tri")
		CraftUI.style_wood_button(btn_cta, "wood_btn_vermilion", 20, Vector2(276, 56), -1.0, true, CraftUI.CREAM_TEXT, 5)
	else:
		btn_cta.icon = CraftUI.tex("icon_padlock")
		CraftUI.style_wood_button(btn_cta, "wood_btn_slate", 19, Vector2(276, 54), -0.8, true, Color(0.93, 0.94, 0.96), 5)
	btn_cta.expand_icon = true
	btn_cta.add_theme_constant_override("icon_max_width", 22)

	# Refresh Bottom 7-Hero Picker Rail
	for i in hero_rail_items.size():
		var item: Dictionary = hero_rail_items[i]
		var is_sel: bool = (i == selected_idx)
		var is_un: bool = bool(HEROES[i]["unlocked"])
		var btn: Button = item["btn"]
		var arrow: TextureRect = item["arrow"]
		var lbl: Label = item["label"]
		var portrait: TextureRect = item["portrait"]
		var tilt := -1.6 if (i % 2 == 0) else 1.4

		var tex_name := "tile_wood_open" if is_un else "tile_wood_locked"
		if is_sel:
			tex_name = "tile_wood_frontier"
			tilt = 0.0
		btn.rotation_degrees = tilt
		btn.scale = Vector2(1.08, 1.08) if is_sel else Vector2.ONE

		var normal := CraftUI.make_full_style(tex_name, 8.0, 4.0)
		var hover := CraftUI.make_full_style(tex_name, 8.0, 4.0, Color(1.08, 1.06, 1.03))
		var pressed := CraftUI.make_full_style(tex_name, 8.0, 6.0, Color(0.86, 0.82, 0.78))
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		portrait.position = Vector2(36, -12 if is_sel else -6)
		portrait.modulate = Color.WHITE if (is_un or is_sel) else Color(0.88, 0.88, 0.90)
		lbl.add_theme_color_override("font_color", CraftUI.GOLD_TEXT if is_sel else CraftUI.CREAM_TEXT)
		arrow.visible = is_sel

func _step_hero(delta_idx: int) -> void:
	_select_hero(selected_idx + delta_idx)

func _on_cta_pressed() -> void:
	var h: Dictionary = HEROES[selected_idx]
	if bool(h["unlocked"]):
		var st_id := str(h["demo_stage"])
		SaveManager.selected_stage_id = st_id
		SceneLoader.transition_to(RUNNER_SCENE, "MEMUAT STAGE %s" % st_id, "", 0.56)
	else:
		hop_t = 1.0
		lock_shake_t = 0.35

func _on_stage_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				drag_moved = 0.0
				yaw_vel = 0.0
				idle_spin_delay = 2.0
			else:
				if is_dragging and drag_moved < 8.0:
					hop_t = 1.0
				is_dragging = false
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = maxf(cam_dist - 0.22, 2.85)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = minf(cam_dist + 0.22, 5.20)
	elif event is InputEventMouseMotion and is_dragging:
		var mm := event as InputEventMouseMotion
		drag_moved += mm.relative.length()
		var d_yaw := mm.relative.x * 0.013
		orbit_yaw += d_yaw
		orbit_pitch = clampf(orbit_pitch + mm.relative.y * 0.008, -0.20, 0.56)
		yaw_vel = clampf(d_yaw / maxf(get_process_delta_time(), 0.008), -12.0, 12.0)
		idle_spin_delay = 1.6

func _process(delta: float) -> void:
	elapsed += delta
	smooth_px = smooth_px.lerp(mouse_px, minf(delta * 5.0, 1.0))
	var off := Vector2(-smooth_px.x * 16.0, -smooth_px.y * 8.0)
	for lyr in bg_layers:
		var node: TextureRect = lyr["node"]
		var base_p: Vector2 = lyr["base"]
		var d: float = float(lyr["depth"])
		node.position = base_p + off * d

	if halo_ctrl:
		halo_ctrl.spin_angle = elapsed * 0.22
		halo_ctrl.queue_redraw()

	# Turntable Inertia & Gentle Auto-Spin when Idle
	if not is_dragging:
		if absf(yaw_vel) > 0.02:
			orbit_yaw += yaw_vel * delta
			yaw_vel = lerpf(yaw_vel, 0.0, clampf(delta * 5.2, 0.0, 1.0))
		else:
			if idle_spin_delay > 0.0:
				idle_spin_delay -= delta
			elif capture_path == "":
				orbit_yaw += delta * 0.32

	if is_instance_valid(turntable_pivot):
		turntable_pivot.rotation.y = orbit_yaw

	# Breathing + Squash-and-Stretch Hop Animation on 3D Model
	if is_instance_valid(model_holder):
		var breath := sin(elapsed * 2.8) * 0.02
		var hop_y := 0.0
		var sx := 1.0 - breath * 0.5
		var sy := 1.0 + breath
		if hop_t > 0.0:
			hop_t = maxf(hop_t - delta * 2.4, 0.0)
			var u := hop_t
			hop_y = sin(u * PI) * 0.34
			var sq := sin(u * PI * 2.0) * 0.10
			sy += sq
			sx -= sq * 0.6
		model_holder.position.y = 0.05 + hop_y
		model_holder.scale = Vector3(sx, sy, sx)

	# Update 3D Camera Orbit
	if is_instance_valid(cam_3d):
		var look_tgt := Vector3(0.0, 0.62, 0.0)
		cam_3d.position = look_tgt + Vector3(
			0.0,
			sin(orbit_pitch) * cam_dist + 0.14,
			cos(orbit_pitch) * cam_dist
		)
		cam_3d.look_at(look_tgt, Vector3.UP)

	# Active Rail Bouncing Arrow & Locked CTA Shake
	var sel_item: Dictionary = hero_rail_items[selected_idx]
	var arr: TextureRect = sel_item["arrow"]
	if is_instance_valid(arr):
		arr.position.y = -30.0 + sin(elapsed * 5.5) * 4.0

	if lock_shake_t > 0.0:
		lock_shake_t = maxf(lock_shake_t - delta, 0.0)
		btn_cta.position.x = cta_base_x + sin(lock_shake_t * 48.0) * 6.0
	else:
		btn_cta.position.x = cta_base_x

	if capture_path != "" and not capture_done and elapsed > 0.45:
		capture_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_path)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_px = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			SceneLoader.quick_transition_to(HOME_SCENE)
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_step_hero(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_step_hero(1)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_7:
			_select_hero(event.keycode - KEY_1)
