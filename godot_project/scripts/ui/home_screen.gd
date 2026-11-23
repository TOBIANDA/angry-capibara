extends Control

# Halaman Home 2D Berlapis (Multi-Plane Parallax) untuk Angry Capibara.
# 100% aset 2D PNG transparan dihasilkan lokal oleh Visual Studio C++ 2D Vector/SDF Painterly Engine
# (vs_asset_forge/src/home2d_painter.cpp) — gaya lineless painterly ala Rovio Angry Birds 2, nol AI slop!
# Fitur:
# - 9 layer latar parallax (langit senja, sunburst berputar, awan melayang, pegunungan berkabut,
#   rumah onsen + Torii + kolam air panas, uap onsen naik, tebing ketapel bambu, bukit lumut, bingkai bambu)
# - 7 sprite kapibara 2D (+3 Trio Mini bertumpuk) dengan squash-and-stretch hidup, hover & klik berdialog
# - Logo Vektor Original Opsi 2 (tulisannya saja) & menu PLAY / 4 WORLD / CREDITS / EXIT.

const TESTER_SCENE_PATH := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

# Konfigurasi 9 aktor kapibara 2D berlapis (urut z dari belakang ke depan)
const SQUAD_ACTORS := [
	# 0. Dash Capi melesat di langit senja kanan atas di atas Torii
	{
		"name": "Dash Capi",
		"role": "Sprinter Hiperaktif - Turbo Seruduk",
		"quote": "\"WUUUSSSHH!! Ketinggalan semua nih!\"",
		"tex": "res://assets/generated/home2d/char_06_dash_leap.png",
		"pos": Vector2(1015.0, 195.0),
		"size": Vector2(285.0, 285.0),
		"depth": 0.56,
		"bob_amp": 12.0,
		"bob_spd": 3.8,
		"sway_deg": 4.2,
		"phase": 0.6,
		"in_sky": true
	},
	# 1-3. Trio Mini-Capi bertumpuk 3 di tebing kiri sebelah ketapel bambu
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Hehe! Satu aja udah pusing, apalagi bertiga!\"",
		"tex": "res://assets/generated/home2d/char_07_mini_capi.png",
		"pos": Vector2(198.0, 488.0),
		"size": Vector2(138.0, 138.0),
		"depth": 0.62,
		"bob_amp": 3.5,
		"bob_spd": 3.4,
		"sway_deg": 2.4,
		"phase": 1.2,
		"in_sky": false
	},
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Ayo luncurin kita duluan!!\"",
		"tex": "res://assets/generated/home2d/char_07_mini_capi.png",
		"pos": Vector2(190.0, 412.0),
		"size": Vector2(132.0, 132.0),
		"depth": 0.63,
		"bob_amp": 4.5,
		"bob_spd": 3.9,
		"sway_deg": 3.2,
		"phase": 2.2,
		"in_sky": false
	},
	{
		"name": "Trio Mini-Capi",
		"role": "Trio Usil - Pecah 3 di Udara",
		"quote": "\"Wihh dari puncak tebing bambu kelihatan semua!\"",
		"tex": "res://assets/generated/home2d/char_07_mini_capi.png",
		"pos": Vector2(196.0, 340.0),
		"size": Vector2(126.0, 126.0),
		"depth": 0.64,
		"bob_amp": 5.5,
		"bob_spd": 4.3,
		"sway_deg": 4.0,
		"phase": 3.3,
		"in_sky": false
	},
	# 4. Yuzu Bomb (bahu kiri belakang Chill Capi + kobaran api)
	{
		"name": "Yuzu Bomb",
		"role": "Sumbu Pendek - Ledakan Api Yuzu",
		"quote": "\"Hoaam... jangan bangunin pas sumbu udah nyala!\"",
		"tex": "res://assets/generated/home2d/char_02_yuzu_bomb.png",
		"pos": Vector2(448.0, 405.0),
		"size": Vector2(315.0, 315.0),
		"depth": 0.72,
		"bob_amp": 4.0,
		"bob_spd": 1.9,
		"sway_deg": 1.6,
		"phase": 1.4,
		"in_sky": false
	},
	# 5. Heavy Onsen ("Merah Besar", menjulang di bahu kanan belakang)
	{
		"name": "Heavy Onsen Capi",
		"role": "Titan Sumo - Penghancur Batu & Baja",
		"quote": "\"Hmph! Satu benturan, rata semua.\"",
		"tex": "res://assets/generated/home2d/char_03_heavy_onsen.png",
		"pos": Vector2(832.0, 412.0),
		"size": Vector2(335.0, 335.0),
		"depth": 0.72,
		"bob_amp": 3.2,
		"bob_spd": 1.4,
		"sway_deg": 1.2,
		"phase": 2.3,
		"in_sky": false
	},
	# 6. Seed-Blaster (sayap kiri depan)
	{
		"name": "Seed-Blaster Capi",
		"role": "Penembak Sinis - Tembakan Biji Kembar",
		"quote": "\"Target segede itu masa meleset?\"",
		"tex": "res://assets/generated/home2d/char_04_seed_blaster.png",
		"pos": Vector2(292.0, 500.0),
		"size": Vector2(265.0, 265.0),
		"depth": 0.84,
		"bob_amp": 4.2,
		"bob_spd": 2.4,
		"sway_deg": 2.1,
		"phase": 3.9,
		"in_sky": false
	},
	# 7. Bambu-Katana (sayap kanan depan + tebasan sabit cyan)
	{
		"name": "Bambu-Katana Capi",
		"role": "Ronin Serius - Tebasan & Pantul Laser",
		"quote": "\"Satu tebasan, seluruh benteng tumbang.\"",
		"tex": "res://assets/generated/home2d/char_05_bambu_katana.png",
		"pos": Vector2(986.0, 496.0),
		"size": Vector2(288.0, 288.0),
		"depth": 0.84,
		"bob_amp": 4.8,
		"bob_spd": 2.9,
		"sway_deg": 2.4,
		"phase": 3.1,
		"in_sky": false
	},
	# 8. HERO DEPAN-TENGAH: Chill Capi Mengaum (MC Merah Crimson)
	{
		"name": "Chill Capi (MC)",
		"role": "Pemimpin Pemarah - Gelombang Zen",
		"quote": "\"Sentuh jeruk Yuzu lagi... HABIS KALIAN!\"",
		"tex": "res://assets/generated/home2d/char_01_chill_roar.png",
		"pos": Vector2(636.0, 474.0),
		"size": Vector2(365.0, 365.0),
		"depth": 0.92,
		"bob_amp": 5.0,
		"bob_spd": 2.6,
		"sway_deg": 1.8,
		"phase": 0.0,
		"in_sky": false
	}
]

var shader_vignette: Shader
var stage_root: Control

var parallax_layers: Array[Dictionary] = []
var sunburst_node: TextureRect
var clouds_node: TextureRect
var steam_nodes: Array[Dictionary] = []
var actors: Array[Dictionary] = []
var ember_nodes: Array[Dictionary] = []
var leaf_nodes: Array[Dictionary] = []

var elapsed_time: float = 0.0
var intro_duration: float = 1.05
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

	shader_vignette = load("res://shaders/vignette.gdshader")
	clip_contents = true

	stage_root = Control.new()
	stage_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage_root)

	_setup_2d_parallax_stage()
	_setup_ambient_2d_particles()
	_setup_arcade_ui()

	if capture_path != "":
		elapsed_time = 2.0
		_finish_intro()

func _add_layer_sprite(path: String, base_pos: Vector2, sz: Vector2, depth: float, overscan: float = 1.06) -> TextureRect:
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
	stage_root.add_child(tr)
	parallax_layers.append({ "node": tr, "base": pos, "depth": depth })
	return tr

func _setup_2d_parallax_stage() -> void:
	# Layer 0: Langit senja golden-hour + matahari
	_add_layer_sprite("res://assets/generated/home2d/layer_00_sky_sun.png", Vector2.ZERO, BASE_SIZE, 0.06, 1.06)

	# Layer 1: Sunburst berputar halus di belakang pegunungan
	sunburst_node = TextureRect.new()
	sunburst_node.texture = load("res://assets/generated/home2d/layer_01_sunburst.png")
	sunburst_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sunburst_node.stretch_mode = TextureRect.STRETCH_SCALE
	sunburst_node.size = Vector2(1024.0, 1024.0)
	var sun_base := Vector2(640.0 - 512.0, 415.0 - 512.0)
	sunburst_node.position = sun_base
	sunburst_node.pivot_offset = Vector2(512.0, 512.0)
	sunburst_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_root.add_child(sunburst_node)
	parallax_layers.append({ "node": sunburst_node, "base": sun_base, "depth": 0.10 })

	# Layer 2: Awan empuk melayang pelan
	clouds_node = _add_layer_sprite("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 26.0), Vector2(1280.0, 420.0), 0.16, 1.08)

	# Layer 3: Pegunungan bambu berkabut jauh
	_add_layer_sprite("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.24, 1.07)

	# Layer 4: Rumah Onsen kayu Jepang + Gerbang Torii merah + Kolam air panas
	_add_layer_sprite("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.38, 1.07)

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
		stage_root.add_child(st)
		steam_nodes.append({ "node": st, "base": base_p, "depth": 0.42, "phase": float(i) * 1.45 })

	# Layer 6: Tebing kiri berlumut + Ketapel Bambu 2D
	_add_layer_sprite("res://assets/generated/home2d/layer_06_slingshot_cliff.png", Vector2.ZERO, BASE_SIZE, 0.54, 1.08)

	# Dash Capi melesat di langit kanan atas (di atas Torii & belakang bukit depan)
	_spawn_actor(0)

	# Layer 7: Bukit rumput lumut depan tempat seluruh squad berdiri
	_add_layer_sprite("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 318.0), Vector2(1280.0, 420.0), 0.78, 1.08)

	# 8 Aktor Squad Kapibara 2D lainnya (urut kedalaman belakang -> depan)
	for i in range(1, SQUAD_ACTORS.size()):
		_spawn_actor(i)

	# Layer 8: Bingkai rumpun bambu & daun depan di kiri & kanan (parallax tercepat!)
	_add_layer_sprite("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 1.18, 1.08)

func _spawn_actor(idx: int) -> void:
	var cfg: Dictionary = SQUAD_ACTORS[idx]
	var sz: Vector2 = cfg["size"]
	var center_pos: Vector2 = cfg["pos"]
	var top_left: Vector2 = center_pos - sz * 0.5

	var tr := TextureRect.new()
	tr.texture = load(cfg["tex"])
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = sz
	tr.position = top_left
	# Pivot di bagian bawah-tengah agar animasi bernafas & lompat squash-and-stretch natural!
	tr.pivot_offset = Vector2(sz.x * 0.5, sz.y * 0.82)
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var actor_idx := actors.size()
	tr.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_trigger_actor_reaction(actor_idx)
	)
	tr.mouse_entered.connect(func():
		if actor_idx < actors.size():
			actors[actor_idx]["hovered"] = true
	)
	tr.mouse_exited.connect(func():
		if actor_idx < actors.size():
			actors[actor_idx]["hovered"] = false
	)
	stage_root.add_child(tr)

	actors.append({
		"cfg": cfg,
		"node": tr,
		"base": top_left,
		"hop_t": 0.0,
		"hovered": false,
		"drop_delay": 0.055 * float(actor_idx)
	})

func _setup_ambient_2d_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20262424

	# 1. Percikan bara api hangat melayang naik dari kobaran api Yuzu Bomb
	for i in 12:
		var dot := ColorRect.new()
		var dsz: float = rng.randf_range(4.0, 8.5)
		dot.size = Vector2(dsz, dsz)
		dot.pivot_offset = dot.size * 0.5
		dot.color = Color(1.0, rng.randf_range(0.62, 0.90), 0.20, 0.92)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var base_p := Vector2(455.0 + rng.randf_range(-42.0, 42.0), 275.0 + rng.randf_range(-16.0, 26.0))
		dot.position = base_p
		stage_root.add_child(dot)
		ember_nodes.append({
			"node": dot,
			"base": base_p,
			"spd": rng.randf_range(0.65, 1.25),
			"phase": rng.randf_range(0.0, TAU)
		})

	# 2. Daun bambu hijau lembut melayang di angin senja
	for i in 9:
		var lf := ColorRect.new()
		lf.size = Vector2(rng.randf_range(14.0, 22.0), rng.randf_range(5.0, 8.0))
		lf.pivot_offset = lf.size * 0.5
		lf.color = Color(0.58, 0.90, 0.28, 0.84)
		lf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var base_p := Vector2(rng.randf_range(80.0, 1200.0), rng.randf_range(40.0, 560.0))
		lf.position = base_p
		stage_root.add_child(lf)
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
	smooth_parallax = smooth_parallax.lerp(mouse_parallax, minf(delta * 5.5, 1.0))

	# 1. Geser setiap layer 2D sesuai kedalaman parallax (maks +/- 28 px)
	var px_offset := Vector2(-smooth_parallax.x * 28.0, -smooth_parallax.y * 14.0)
	for lyr in parallax_layers:
		var node: TextureRect = lyr["node"]
		var base_p: Vector2 = lyr["base"]
		var depth: float = float(lyr["depth"])
		var extra := Vector2.ZERO
		if node == clouds_node:
			extra.x = sin(elapsed_time * 0.24) * 18.0
		node.position = base_p + px_offset * depth + extra

	if sunburst_node:
		sunburst_node.rotation = elapsed_time * 0.11

	# 2. Uap onsen naik lembut & memudar transparan
	for sp in steam_nodes:
		var n: TextureRect = sp["node"]
		var base_p: Vector2 = sp["base"]
		var depth: float = float(sp["depth"])
		var ph: float = float(sp["phase"])
		var cyc: float = fmod(elapsed_time * 0.34 + ph, 2.0) / 2.0
		n.position = base_p + px_offset * depth + Vector2(sin(elapsed_time * 0.9 + ph) * 12.0, -cyc * 68.0)
		n.modulate.a = sin(cyc * PI) * 0.85

	# 3. Percikan bara api Yuzu Bomb & daun bambu melayang
	for em in ember_nodes:
		var n: ColorRect = em["node"]
		var b: Vector2 = em["base"]
		var ph: float = float(em["phase"])
		var spd: float = float(em["spd"])
		var cyc: float = fmod(elapsed_time * spd + ph, 1.8) / 1.8
		n.position = b + px_offset * 0.75 + Vector2(sin(elapsed_time * 3.2 + ph) * 16.0, -cyc * 120.0)
		n.rotation = elapsed_time * 2.5 + ph
		n.modulate.a = sin(cyc * PI) * 0.95

	for lf in leaf_nodes:
		var n: ColorRect = lf["node"]
		var b: Vector2 = lf["base"]
		var ph: float = float(lf["phase"])
		var spd: float = float(lf["spd"])
		var ny: float = fmod(b.y + elapsed_time * 38.0 * spd, 760.0) - 20.0
		n.position = Vector2(b.x + sin(elapsed_time * spd + ph) * 44.0, ny) + px_offset * 1.05
		n.rotation = sin(elapsed_time * 1.8 + ph) * 0.85

	# 4. Intro loading bar
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

	# 5. Animasi squash-and-stretch 2D & reaksi klik seluruh 9 kapibara!
	for i in actors.size():
		var a: Dictionary = actors[i]
		var cfg: Dictionary = a["cfg"]
		var node: TextureRect = a["node"]
		var base_p: Vector2 = a["base"]
		var depth: float = float(cfg["depth"])
		var phase: float = float(cfg["phase"])
		var bob_spd: float = float(cfg["bob_spd"])
		var bob_amp: float = float(cfg["bob_amp"])
		var sway_deg: float = float(cfg["sway_deg"])
		var hovered: bool = bool(a["hovered"])

		var t_local := maxf(elapsed_time - float(a["drop_delay"]), 0.0)
		var drop_y := 0.0
		var sx := 1.0
		var sy := 1.0
		if t_local < 0.48:
			var u := t_local / 0.48
			if u < 0.62:
				var d := 1.0 - (u / 0.62)
				drop_y = -d * d * 240.0
			else:
				var sq := sin(((u - 0.62) / 0.38) * PI)
				sy = 1.0 - sq * 0.16
				sx = 1.0 + sq * 0.12

		var hop_y := 0.0
		var hop_rot := 0.0
		if float(a["hop_t"]) > 0.0:
			a["hop_t"] = maxf(float(a["hop_t"]) - delta * 2.4, 0.0)
			var hu: float = float(a["hop_t"])
			hop_y = -sin(hu * PI) * 44.0
			hop_rot = sin(hu * TAU) * 9.0
			sy *= 1.0 + sin(hu * PI) * 0.08
			sx *= 1.0 - sin(hu * PI) * 0.05

		var breath: float = sin(elapsed_time * bob_spd + phase)
		var bob_y: float = breath * bob_amp
		sy *= 1.0 + breath * 0.018
		sx *= 1.0 - breath * 0.012
		if hovered:
			sx *= 1.055
			sy *= 1.055

		node.position = base_p + px_offset * depth + Vector2(0.0, drop_y + hop_y + bob_y)
		node.scale = Vector2(sx, sy)
		node.rotation_degrees = sin(elapsed_time * bob_spd * 0.65 + phase) * sway_deg + hop_rot

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
	var cfg: Dictionary = actors[idx]["cfg"]
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
	modal_body.text = "[b]Ketua Tim & Pengembang Utama:[/b]\nTobias Andra Valentino (NIM: 245150200111076)\n\n[b]Mata Kuliah:[/b]\nKomputer Grafika — Interactive 3D Computer Graphics\n\n[b]Teknologi & Toolchain (100% Offline Visual Studio C++ + Godot):[/b]\n- Home 2D Berlapis: Visual Studio C++ 2D Vector/SDF Painterly Engine (Lineless Rovio Style, 16 RGBA PNG layers)\n- Pemodelan 3D Gameplay & Tekstur `.bmp`: Visual Studio C++ OpenGL Asset Forge (FreeGLUT, GLEW, GLM, Bicubic Bezier)\n- Game Engine: Godot Engine 4.7.1.stable (GL Compatibility)\n\n[b]Referensi Utama:[/b]\nAngry Birds Star Wars I & II"
	modal_overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_parallax = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			# Map tombol 1-7 langsung ke Chill, Yuzu, Heavy, Blaster, Katana, Dash, Mini
			var key_map: Array[int] = [8, 4, 5, 6, 7, 0, 1]
			var k_i: int = event.keycode - KEY_1
			if k_i >= 0 and k_i < key_map.size():
				_trigger_actor_reaction(key_map[k_i])
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if intro_finished and not modal_overlay.visible:
				_go_to_tester()
			elif not intro_finished:
				_finish_intro()
		elif event.keycode == KEY_ESCAPE and modal_overlay.visible:
			modal_overlay.visible = false
