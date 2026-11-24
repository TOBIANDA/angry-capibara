extends Control

# Halaman Home 2D Berlapis (Multi-Plane Parallax) untuk Angry Capibara:
# - Background 9 layer parallax bersih dari Visual Studio C++ 2D Vector/SDF Engine
#   (langit, awan, pegunungan bambu, rumah onsen, Torii, uap, tebing ketapel, bukit lumut, bingkai bambu)
# - Matahari & pancaran sunburst senja golden-hour + seluruh kapibara dari Key-Art 2D kemarin
#   yang dipotong transparan per grup (Dash terbang, Trio Mini bertumpuk, & 5 Hero Squad)
#   lengkap dengan animasi bernafas, hover, klik dialog per karakter, & Logo Opsi 2.

const WORLD1_SELECT_PATH := "res://scenes/ui/world1_select.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

# Data dialog 7 karakter kapibara (bisa diklik langsung di layar atau tekan tombol 1-7)
const CAPY_DIALOGS := [
	{ "name": "Chill Capi (MC)", "role": "Pemimpin Pemarah - Gelombang Zen", "quote": "\"Sentuh jeruk Yuzu lagi... HABIS KALIAN!\"" },
	{ "name": "Yuzu Bomb", "role": "Sumbu Pendek - Ledakan Api Yuzu", "quote": "\"Hoaam... jangan bangunin pas sumbu udah nyala!\"" },
	{ "name": "Heavy Onsen Capi", "role": "Titan Sumo - Penghancur Batu & Baja", "quote": "\"Hmph! Satu benturan, rata semua.\"" },
	{ "name": "Seed-Blaster Capi", "role": "Penembak Sinis - Tembakan Biji Kembar", "quote": "\"Target segede itu masa meleset?\"" },
	{ "name": "Bambu-Katana Capi", "role": "Ronin Serius - Tebasan & Pantul Laser", "quote": "\"Satu tebasan, seluruh benteng tumbang.\"" },
	{ "name": "Dash Capi", "role": "Sprinter Hiperaktif - Turbo Seruduk", "quote": "\"WUUUSSSHH!! Ketinggalan semua nih!\"" },
	{ "name": "Trio Mini-Capi", "role": "Trio Usil - Pecah 3 di Udara", "quote": "\"Hehe! Satu aja udah pusing, apalagi bertiga!\"" }
]

# 3 grup sprite 2D transparan yang telah di-harmonisasi Master Anti-Slop LUT di Visual Studio C++
const LAYERED_GROUPS := [
	# 0. Dash Capi melesat di langit kanan atas (di atas gerbang Torii!)
	{
		"tex": "res://assets/generated/home2d/capi_2d_dash_graded.png",
		"pos": Vector2(1018.0, 188.0),
		"size": Vector2(278.0, 230.0),
		"depth": 0.56,
		"bob_amp": 11.0,
		"bob_spd": 3.6,
		"sway_deg": 3.6,
		"phase": 0.6,
		"pivot_y": 0.55,
		"dialog_idx": 5
	},
	# 1. Trio Mini-Capi bertumpuk 3 di tebing kiri sebelah ketapel bambu
	{
		"tex": "res://assets/generated/home2d/capi_2d_trio_mini_graded.png",
		"pos": Vector2(158.0, 444.0),
		"size": Vector2(142.0, 304.0),
		"depth": 0.64,
		"bob_amp": 4.2,
		"bob_spd": 3.2,
		"sway_deg": 2.0,
		"phase": 1.8,
		"pivot_y": 0.88,
		"dialog_idx": 6
	},
	# 2. Formasi 5 Hero Utama (Seed-Blaster, Yuzu Bomb, Chill Capi, Heavy Onsen, Bambu-Katana)
	{
		"tex": "res://assets/generated/home2d/capi_2d_squad_main_graded.png",
		"pos": Vector2(676.0, 450.0),
		"size": Vector2(968.0, 396.0),
		"depth": 0.86,
		"bob_amp": 3.4,
		"bob_spd": 2.2,
		"sway_deg": 0.7,
		"phase": 0.0,
		"pivot_y": 0.86,
		"dialog_idx": -1
	}
]

var shader_vignette: Shader
var stage_root: Control

var parallax_layers: Array[Dictionary] = []
var sunburst_node: TextureRect
var clouds_node: TextureRect
var steam_nodes: Array[Dictionary] = []
var groups: Array[Dictionary] = []
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

	_setup_hybrid_2d_stage()
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

func _setup_hybrid_2d_stage() -> void:
	# Layer 0: Langit senja golden-hour + matahari hangat (VS C++)
	_add_layer_sprite("res://assets/generated/home2d/layer_00_sky_sun.png", Vector2.ZERO, BASE_SIZE, 0.06, 1.06)

	# Layer 1: Pancaran sunburst emas menyala ala 2D kemarin (berputar halus!)
	sunburst_node = TextureRect.new()
	sunburst_node.texture = load("res://assets/generated/home2d/layer_01_sunburst.png")
	sunburst_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sunburst_node.stretch_mode = TextureRect.STRETCH_SCALE
	sunburst_node.size = Vector2(1280.0, 1280.0)
	var sun_base := Vector2(640.0 - 640.0, 395.0 - 640.0)
	sunburst_node.position = sun_base
	sunburst_node.pivot_offset = Vector2(640.0, 640.0)
	sunburst_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sunburst_node.material = add_mat
	stage_root.add_child(sunburst_node)
	parallax_layers.append({ "node": sunburst_node, "base": sun_base, "depth": 0.10 })

	# Layer 2: Awan empuk melayang pelan (VS C++)
	clouds_node = _add_layer_sprite("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 26.0), Vector2(1280.0, 420.0), 0.16, 1.08)

	# Layer 3: Pegunungan bambu berkabut jauh (VS C++)
	_add_layer_sprite("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.24, 1.07)

	# Layer 4: Rumah Onsen kayu Jepang + Gerbang Torii + Kolam air panas (VS C++)
	_add_layer_sprite("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.38, 1.07)

	# Layer 5: Uap onsen lembut naik di atas kolam kanan
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

	# Layer 6: Tebing kiri berlumut + Ketapel Bambu 2D (VS C++)
	_add_layer_sprite("res://assets/generated/home2d/layer_06_slingshot_cliff.png", Vector2.ZERO, BASE_SIZE, 0.54, 1.08)

	# Partikel daun bambu & bara api dipasang di belakang squad utama agar tidak menutupi wajah kapibara!
	_setup_ambient_2d_particles()

	# Grup 0 (Langit): Dash Capi 2D melesat di atas gerbang Torii!
	_spawn_group(0)

	# Layer 7: Bukit rumput lumut depan (VS C++)
	_add_layer_sprite("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 330.0), Vector2(1280.0, 420.0), 0.78, 1.08)

	# Grup 1 (Tebing Kiri): Trio Mini-Capi 2D bertumpuk 3
	_spawn_group(1)

	# Grup 2 (Depan Tengah): 5 Hero Squad 2D (Seed-Blaster, Yuzu Bomb, Chill, Heavy, Katana)
	_spawn_group(2)

	# Layer 8: Bingkai rumpun bambu & daun depan kiri-kanan (parallax tercepat!)
	_add_layer_sprite("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 1.18, 1.08)

func _spawn_group(idx: int) -> void:
	var cfg: Dictionary = LAYERED_GROUPS[idx]
	var sz: Vector2 = cfg["size"]
	var center_pos: Vector2 = cfg["pos"]
	var top_left: Vector2 = center_pos - sz * 0.5
	var piv_y: float = float(cfg["pivot_y"])
	var dlg_idx: int = int(cfg["dialog_idx"])

	var tr := TextureRect.new()
	tr.texture = load(cfg["tex"])
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = sz
	tr.position = top_left
	tr.pivot_offset = Vector2(sz.x * 0.5, sz.y * piv_y)

	var g_idx := groups.size()
	if dlg_idx >= 0:
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tr.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_trigger_dialog_and_hop(dlg_idx, g_idx)
		)
		tr.mouse_entered.connect(func():
			if g_idx < groups.size():
				groups[g_idx]["hovered"] = true
		)
		tr.mouse_exited.connect(func():
			if g_idx < groups.size():
				groups[g_idx]["hovered"] = false
		)
	else:
		# Untuk formasi 5 Hero, pasang 5 zona klik transparan sesuai posisi masing-masing kapibara!
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hitboxes: Array = [
			[Rect2(0.02, 0.32, 0.19, 0.65), 3], # Seed-Blaster
			[Rect2(0.20, 0.14, 0.17, 0.72), 1], # Yuzu Bomb
			[Rect2(0.36, 0.10, 0.24, 0.80), 0], # Chill Capi (MC)
			[Rect2(0.58, 0.04, 0.21, 0.76), 2], # Heavy Onsen
			[Rect2(0.74, 0.38, 0.24, 0.60), 4]  # Bambu-Katana
		]
		for hb in hitboxes:
			var r: Rect2 = hb[0]
			var d_id: int = int(hb[1])
			var btn := Control.new()
			btn.position = Vector2(r.position.x * sz.x, r.position.y * sz.y)
			btn.size = Vector2(r.size.x * sz.x, r.size.y * sz.y)
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_trigger_dialog_and_hop(d_id, g_idx)
			)
			tr.add_child(btn)

	stage_root.add_child(tr)
	groups.append({
		"cfg": cfg,
		"node": tr,
		"base": top_left,
		"hop_t": 0.0,
		"hovered": false,
		"drop_delay": 0.08 * float(g_idx)
	})

func _setup_ambient_2d_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20262425

	# Percikan bara api hangat terukur dari api Yuzu Bomb (sesuai palet anti-slop)
	for i in 12:
		var dot := ColorRect.new()
		var dsz: float = rng.randf_range(4.0, 7.5)
		dot.size = Vector2(dsz, dsz)
		dot.pivot_offset = dot.size * 0.5
		dot.color = Color(0.95, rng.randf_range(0.72, 0.86), 0.36, 0.84)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var base_p := Vector2(462.0 + rng.randf_range(-38.0, 38.0), 312.0 + rng.randf_range(-14.0, 22.0))
		dot.position = base_p
		stage_root.add_child(dot)
		ember_nodes.append({
			"node": dot,
			"base": base_p,
			"spd": rng.randf_range(0.65, 1.25),
			"phase": rng.randf_range(0.0, TAU)
		})

	# Daun bambu zaitun lembut melayang di angin (tanpa hijau neon)
	for i in 9:
		var lf := ColorRect.new()
		lf.size = Vector2(rng.randf_range(13.0, 20.0), rng.randf_range(4.5, 7.0))
		lf.pivot_offset = lf.size * 0.5
		lf.color = Color(0.55, 0.70, 0.34, 0.76)
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

	# Tombol PLAY — 1 Aksen Fokus Tunggal Vermilion Jepang (miqdadbadjuber/anti-slop R-01!)
	play_button = _make_glossy_button("PLAY", Color(0.80, 0.22, 0.16), Color(0.98, 0.95, 0.89), 34, Vector2(238, 62), 14, true)
	play_button.add_theme_font_override("font", display_font)
	play_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play_button.offset_left = -119
	play_button.offset_right = 119
	play_button.offset_top = -82
	play_button.offset_bottom = -20
	play_button.visible = false
	play_button.pressed.connect(_go_to_tester)
	ui_root.add_child(play_button)

	# Tombol sekunder seragam Warm Lacquer Espresso (nol tombol warna-warni pelangi AI slop!)
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

	var sec_bg := Color(0.17, 0.13, 0.11, 0.94)
	var sec_fg := Color(0.96, 0.93, 0.86)
	var btn_worlds := _make_glossy_button("4 WORLD", sec_bg, sec_fg, 13, Vector2(96, 38), 10, false)
	btn_worlds.pressed.connect(_show_worlds_modal)
	corner_menu.add_child(btn_worlds)

	var btn_credits := _make_glossy_button("CREDITS", sec_bg, sec_fg, 13, Vector2(92, 38), 10, false)
	btn_credits.pressed.connect(_show_credits_modal)
	corner_menu.add_child(btn_credits)

	var btn_exit := _make_glossy_button("EXIT", sec_bg, sec_fg, 13, Vector2(72, 38), 10, false)
	btn_exit.pressed.connect(func(): get_tree().quit())
	corner_menu.add_child(btn_exit)

	# Balon dialog seragam Warm Lacquer Espresso + border kertas washi
	speech_bubble = PanelContainer.new()
	speech_bubble.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	speech_bubble.offset_left = 22
	speech_bubble.offset_right = 374
	speech_bubble.offset_top = -94
	speech_bubble.offset_bottom = -20
	speech_bubble.visible = false
	var sb_style := StyleBoxFlat.new()
	sb_style.bg_color = Color(0.15, 0.11, 0.10, 0.94)
	sb_style.border_color = Color(0.82, 0.74, 0.58)
	sb_style.set_border_width_all(2)
	sb_style.set_corner_radius_all(10)
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

	var close_btn := _make_glossy_button("TUTUP", Color(0.80, 0.22, 0.16), Color(0.98, 0.95, 0.89), 15, Vector2(140, 38), 10, true)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): modal_overlay.visible = false)
	mvbox.add_child(close_btn)

func _make_glossy_button(text_str: String, bg: Color, fg: Color, fsize: int, min_sz: Vector2, radius: int, is_primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_str
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.93))
	b.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.08))
	b.add_theme_constant_override("outline_size", 5 if is_primary and fsize >= 24 else 2)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = Color(0.95, 0.86, 0.66) if is_primary else Color(0.76, 0.68, 0.54, 0.85)
	normal.set_border_width_all(3 if is_primary else 2)
	normal.set_corner_radius_all(radius)
	normal.shadow_color = Color(0.12, 0.08, 0.06, 0.45)
	normal.shadow_size = 6 if is_primary else 4
	normal.shadow_offset = Vector2(0, 4 if is_primary else 2)

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

	# 1. Geser 9 layer latar VS C++ sesuai kedalaman parallax
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
		sunburst_node.rotation = elapsed_time * 0.08

	# 2. Uap onsen naik lembut
	for sp in steam_nodes:
		var n: TextureRect = sp["node"]
		var base_p: Vector2 = sp["base"]
		var depth: float = float(sp["depth"])
		var ph: float = float(sp["phase"])
		var cyc: float = fmod(elapsed_time * 0.34 + ph, 2.0) / 2.0
		n.position = base_p + px_offset * depth + Vector2(sin(elapsed_time * 0.9 + ph) * 12.0, -cyc * 68.0)
		n.modulate.a = sin(cyc * PI) * 0.82

	# 3. Bara api Yuzu Bomb & daun bambu melayang
	for em in ember_nodes:
		var n: ColorRect = em["node"]
		var b: Vector2 = em["base"]
		var ph: float = float(em["phase"])
		var spd: float = float(em["spd"])
		var cyc: float = fmod(elapsed_time * spd + ph, 1.8) / 1.8
		n.position = b + px_offset * 0.82 + Vector2(sin(elapsed_time * 3.2 + ph) * 16.0, -cyc * 120.0)
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

	# 4. Intro loading bar & logo breathing
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

	# 5. Animasi parallax + squash-and-stretch 3 grup kapibara 2D
	for i in groups.size():
		var g: Dictionary = groups[i]
		var cfg: Dictionary = g["cfg"]
		var node: TextureRect = g["node"]
		var base_p: Vector2 = g["base"]
		var depth: float = float(cfg["depth"])
		var phase: float = float(cfg["phase"])
		var bob_spd: float = float(cfg["bob_spd"])
		var bob_amp: float = float(cfg["bob_amp"])
		var sway_deg: float = float(cfg["sway_deg"])
		var hovered: bool = bool(g["hovered"])

		var t_local := maxf(elapsed_time - float(g["drop_delay"]), 0.0)
		var drop_y := 0.0
		var sx := 1.0
		var sy := 1.0
		if t_local < 0.48:
			var u := t_local / 0.48
			if u < 0.62:
				var d := 1.0 - (u / 0.62)
				drop_y = -d * d * 220.0
			else:
				var sq := sin(((u - 0.62) / 0.38) * PI)
				sy = 1.0 - sq * 0.14
				sx = 1.0 + sq * 0.10

		var hop_y := 0.0
		var hop_rot := 0.0
		if float(g["hop_t"]) > 0.0:
			g["hop_t"] = maxf(float(g["hop_t"]) - delta * 2.5, 0.0)
			var hu: float = float(g["hop_t"])
			hop_y = -sin(hu * PI) * (34.0 if i < 2 else 18.0)
			hop_rot = sin(hu * TAU) * (6.0 if i < 2 else 1.5)
			sy *= 1.0 + sin(hu * PI) * 0.05
			sx *= 1.0 - sin(hu * PI) * 0.03

		var breath: float = sin(elapsed_time * bob_spd + phase)
		var bob_y: float = breath * bob_amp
		sy *= 1.0 + breath * 0.012
		sx *= 1.0 - breath * 0.008
		if hovered:
			sx *= 1.045
			sy *= 1.045

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

func _trigger_dialog_and_hop(dialog_idx: int, group_idx: int) -> void:
	if group_idx >= 0 and group_idx < groups.size():
		groups[group_idx]["hop_t"] = 1.0
	if dialog_idx < 0 or dialog_idx >= CAPY_DIALOGS.size():
		return
	var d: Dictionary = CAPY_DIALOGS[dialog_idx]
	speech_name.text = "%s  —  %s" % [d["name"], d["role"]]
	speech_quote.text = d["quote"]
	speech_bubble.visible = true
	speech_timer = 3.8

func _go_to_tester() -> void:
	get_tree().change_scene_to_file(WORLD1_SELECT_PATH)

func _show_worlds_modal() -> void:
	modal_title.text = "4 WORLD ANGRY CAPIBARA (80 STAGE)"
	modal_body.text = "[b]WORLD 1 — Bamboo Island (1-1 s/d 1-20)[/b]\nPulau bambu tropis & benteng kayu para Croco Minion bersama Chill Capi, Dash Capi, dan Trio Mini.\n\n[b]WORLD 2 — Sunset Onsen Dojo (2-1 s/d 2-20)[/b]\nPemandian air panas senja dengan batu pantul Onsen, tong Yuzu TNT, Yuzu Bomb, Seed-Blaster, Bambu-Katana, dan Heavy Onsen.\n\n[b]WORLD 3 — Neon Sky-Fortress (3-1 s/d 3-20)[/b]\nBenteng langit & Croc Turret penembak aktif dengan mekanik pantulan dan perisai.\n\n[b]WORLD 4 — Yuzu Moon Orbit (4-1 s/d 4-20)[/b]\nZona gravitasi rendah luar angkasa melawan benteng baja King Croc Boss."
	modal_overlay.visible = true

func _show_credits_modal() -> void:
	modal_title.text = "CREDITS — ANGRY CAPIBARA"
	modal_body.text = "[b]Ketua Tim & Pengembang Utama:[/b]\nTobias Andra Valentino (NIM: 245150200111076)\n\n[b]Mata Kuliah:[/b]\nKomputer Grafika — Interactive 3D Computer Graphics\n\n[b]Teknologi & Toolchain (100% Offline Visual Studio C++ + Godot):[/b]\n- Latar 2D Berlapis: Visual Studio C++ 2D Vector/SDF Painterly Engine (Parallax 9 layer)\n- Pemodelan 3D Gameplay & Tekstur `.bmp`: Visual Studio C++ OpenGL Asset Forge (FreeGLUT, GLEW, GLM, Bicubic Bezier)\n- Game Engine: Godot Engine 4.7.1.stable (GL Compatibility)\n\n[b]Referensi Utama:[/b]\nAngry Birds Star Wars I & II"
	modal_overlay.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_parallax = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			var d_idx: int = event.keycode - KEY_1
			var g_idx: int = 2
			if d_idx == 5:
				g_idx = 0
			elif d_idx == 6:
				g_idx = 1
			_trigger_dialog_and_hop(d_idx, g_idx)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if intro_finished and not modal_overlay.visible:
				_go_to_tester()
			elif not intro_finished:
				_finish_intro()
		elif event.keycode == KEY_ESCAPE and modal_overlay.visible:
			modal_overlay.visible = false
