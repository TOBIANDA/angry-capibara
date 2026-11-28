extends Control

# Halaman Home 2D Berlapis (Multi-Plane Parallax) untuk Angry Capibara:
# - Background 9 layer parallax bersih dari Visual Studio C++ 2D Vector/SDF Engine
#   (langit, awan, pegunungan bambu, rumah onsen, Torii, uap, tebing ketapel, bukit lumut, bingkai bambu)
# - Matahari & pancaran sunburst senja golden-hour + seluruh kapibara dari Key-Art 2D kemarin
#   yang dipotong transparan per grup (Dash terbang, Trio Mini bertumpuk, & 5 Hero Squad)
#   lengkap dengan animasi bernafas, hover, klik dialog per karakter, & Logo Opsi 2.

const WORLD_SELECT_MAP_PATH := "res://scenes/ui/world_select_map.tscn"
const HERO_GALLERY_PATH := "res://scenes/ui/hero_gallery.tscn"
const SETTINGS_PAGE_PATH := "res://scenes/ui/settings_page.tscn"
const GUIDE_PAGE_PATH := "res://scenes/ui/guide_page.tscn"
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
		"pos": Vector2(158.0, 422.0),
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
		"pos": Vector2(676.0, 424.0),
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
var mouse_parallax: Vector2 = Vector2.ZERO
var smooth_parallax: Vector2 = Vector2.ZERO

var capture_path: String = ""
var capture_done: bool = false

# UI nodes
var logo_root: Control
var play_button: Button
var bottom_dock: HBoxContainer
var top_left_bar: HBoxContainer
var top_star_wrap: Control
var audio_btn: Button
var speech_bubble: PanelContainer
var speech_name: Label
var speech_quote: Label
var speech_timer: float = 0.0

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
	else:
		SceneLoader.play_startup_intro()

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

	# TOP-LEFT: 2 Carved Cedar Utility Stamps (Audio + Pengaturan/Credits)
	top_left_bar = HBoxContainer.new()
	top_left_bar.position = Vector2(28, 18)
	top_left_bar.add_theme_constant_override("separation", 12)
	ui_root.add_child(top_left_bar)

	audio_btn = CraftUI.make_icon_stamp("icon_speaker_off" if SaveManager.is_muted else "icon_speaker_on", "wood_sq_bamboo", Vector2(52, 50), -2.2)
	audio_btn.pressed.connect(_toggle_mute)
	top_left_bar.add_child(audio_btn)

	var gear_btn := CraftUI.make_icon_stamp("icon_gear", "wood_sq_cedar", Vector2(52, 50), 1.8)
	gear_btn.pressed.connect(_open_settings_page)
	top_left_bar.add_child(gear_btn)

	# TOP-RIGHT: Bare Floating Gold Star + Total Stars (Zero pill/box!)
	var sc := CraftUI.make_star_counter("%d/240" % SaveManager.get_world1_total_stars(), 32.0, 24)
	top_star_wrap = sc["root"]
	top_star_wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_star_wrap.offset_left = -220
	top_star_wrap.offset_right = -32
	top_star_wrap.offset_top = 18
	top_star_wrap.offset_bottom = 58
	ui_root.add_child(top_star_wrap)

	# BOTTOM-CENTER WOODBLOCK ACTION DOCK (Zero bottom box, zero pills!)
	bottom_dock = HBoxContainer.new()
	bottom_dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_dock.offset_left = -360
	bottom_dock.offset_right = 360
	bottom_dock.offset_top = -86
	bottom_dock.offset_bottom = -14
	bottom_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_dock.add_theme_constant_override("separation", 18)
	bottom_dock.visible = true
	ui_root.add_child(bottom_dock)

	# Left: HERO Amber Wood Plank with Yuzu Capi cutout bursting above wood edge!
	var hero_wrap := Control.new()
	hero_wrap.custom_minimum_size = Vector2(158, 62)
	bottom_dock.add_child(hero_wrap)

	var btn_hero := CraftUI.make_wood_btn("HERO", "wood_btn_amber", Vector2(154, 58), 21, -1.6)
	btn_hero.position = Vector2(10, 4)
	var hero_norm := CraftUI.make_full_style("wood_btn_amber", 14.0, 6.0)
	hero_norm.content_margin_left = 48.0
	var hero_hov := CraftUI.make_full_style("wood_btn_amber", 14.0, 6.0, Color(1.08, 1.06, 1.03))
	hero_hov.content_margin_left = 48.0
	var hero_prs := CraftUI.make_full_style("wood_btn_amber", 14.0, 8.0, Color(0.86, 0.82, 0.78))
	hero_prs.content_margin_left = 48.0
	btn_hero.add_theme_stylebox_override("normal", hero_norm)
	btn_hero.add_theme_stylebox_override("hover", hero_hov)
	btn_hero.add_theme_stylebox_override("pressed", hero_prs)
	btn_hero.pressed.connect(func():
		SceneLoader.quick_transition_to(HERO_GALLERY_PATH)
	)
	hero_wrap.add_child(btn_hero)

	var yuzu_cutout := CraftUI.make_tex_rect(load("res://assets/generated/home2d/char_02_yuzu_bomb.png"), Vector2(64, 64))
	yuzu_cutout.position = Vector2(-6, -14)
	hero_wrap.add_child(yuzu_cutout)

	# Center Primary Focal CTA: MAIN!
	play_button = CraftUI.make_wood_btn("MAIN!", "wood_btn_vermilion", Vector2(226, 72), 32, -0.8, "icon_play_tri", 24)
	play_button.pressed.connect(_go_to_tester)
	bottom_dock.add_child(play_button)

	# Right: PETA Bamboo Plank
	var btn_map := CraftUI.make_wood_btn("PETA", "wood_btn_bamboo", Vector2(152, 58), 21, 1.4, "icon_map", 22)
	btn_map.pressed.connect(_go_to_tester)
	bottom_dock.add_child(btn_map)

	# Far Right: Panduan Stamp (?)
	var btn_help := CraftUI.make_wood_btn("?", "wood_btn_sky", Vector2(58, 56), 28, -2.0)
	btn_help.pressed.connect(_open_guide_page)
	bottom_dock.add_child(btn_help)

	# Speech Bubble using Carved Wood Parchment Modal Style
	speech_bubble = PanelContainer.new()
	speech_bubble.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	speech_bubble.offset_left = 24
	speech_bubble.offset_right = 396
	speech_bubble.offset_top = -188
	speech_bubble.offset_bottom = -92
	speech_bubble.visible = false
	var sb_style := CraftUI.make_modal_panel_style(32.0, 22.0)
	speech_bubble.add_theme_stylebox_override("panel", sb_style)
	ui_root.add_child(speech_bubble)

	var sb_vb := VBoxContainer.new()
	sb_vb.add_theme_constant_override("separation", 2)
	speech_bubble.add_child(sb_vb)

	speech_name = Label.new()
	speech_name.add_theme_font_override("font", CraftUI.display_font())
	speech_name.add_theme_font_size_override("font_size", 14)
	speech_name.add_theme_color_override("font_color", Color(0.75, 0.19, 0.11))
	sb_vb.add_child(speech_name)

	speech_quote = Label.new()
	speech_quote.add_theme_font_override("font", CraftUI.body_font())
	speech_quote.add_theme_font_size_override("font_size", 13)
	speech_quote.add_theme_color_override("font_color", CraftUI.INK)
	speech_quote.autowrap_mode = TextServer.AUTOWRAP_WORD
	sb_vb.add_child(speech_quote)

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

	# 4. Logo & primary CTA breathing
	if logo_root:
		logo_root.scale = Vector2.ONE * (1.0 + sin(elapsed_time * 1.9) * 0.016)

	if play_button and not play_button.is_hovered():
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

func _toggle_mute() -> void:
	var muted := SaveManager.toggle_mute()
	if audio_btn and audio_btn.has_meta("icon_rect"):
		var ic := audio_btn.get_meta("icon_rect") as TextureRect
		if ic:
			ic.texture = CraftUI.tex("icon_speaker_off" if muted else "icon_speaker_on")

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
	SceneLoader.quick_transition_to(WORLD_SELECT_MAP_PATH)

func _open_guide_page() -> void:
	SceneLoader.quick_transition_to(GUIDE_PAGE_PATH)

func _open_settings_page() -> void:
	SceneLoader.quick_transition_to(SETTINGS_PAGE_PATH)

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
			_go_to_tester()
