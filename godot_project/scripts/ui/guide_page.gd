extends Control

# Halaman Penuh Panduan Bermain & Tim Pengembang (Diurutkan Alfabetis A -> Z)

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const WORLD_MAP_SCENE := "res://scenes/ui/world_select_map.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

# Roster resmi Tim Kepler452b (iterasi_3_angry_capybara.pdf) terurut alfabetis A -> Z
const TEAM_MEMBERS := [
	{ "name": "Adidharma Dewabrata Kusumaputra", "nim": "245150200111072" },
	{ "name": "Tobias Andra Valentino", "nim": "245150200111076" },
	{ "name": "Willy Gregory", "nim": "245150207111089" }
]

var bg_layers: Array[Dictionary] = []
var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-guide="):
			capture_path = arg.substr(16)

	clip_contents = true
	_setup_parallax_bg()
	_setup_ui()

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
	_add_bg_tex("res://assets/generated/home2d/layer_01_sunburst.png", Vector2.ZERO, BASE_SIZE, 0.10, 0.70)
	_add_bg_tex("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 20.0), Vector2(1280.0, 420.0), 0.14)
	_add_bg_tex("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.22)
	_add_bg_tex("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.34)
	_add_bg_tex("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 330.0), Vector2(1280.0, 420.0), 0.52)
	_add_bg_tex("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 0.80)

	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.08, 0.06, 0.05, 0.30)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_ui() -> void:
	# 1) Standardized Top Bar
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
	btn_home.pressed.connect(_go_home)
	hdr.add_child(btn_home)

	var lbl_title := CraftUI.make_stroked_label("PANDUAN BERMAIN", 34, CraftUI.GOLD_TEXT, 7, true)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_title)

	var btn_play := CraftUI.make_wood_btn("MULAI MAIN!", "wood_btn_vermilion", Vector2(182, 48), 18, 1.0, "icon_play_tri", 18)
	btn_play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_play.pressed.connect(func():
		SceneLoader.quick_transition_to(WORLD_MAP_SCENE)
	)
	hdr.add_child(btn_play)

	# 2) Full-Screen Body (3 Visual Steps + Keycaps + Team Roster A-Z)
	var body_mar := MarginContainer.new()
	body_mar.set_anchors_preset(Control.PRESET_FULL_RECT)
	body_mar.offset_top = 82
	body_mar.add_theme_constant_override("margin_left", 44)
	body_mar.add_theme_constant_override("margin_right", 44)
	body_mar.add_theme_constant_override("margin_bottom", 18)
	add_child(body_mar)

	var body_vb := VBoxContainer.new()
	body_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	body_vb.add_theme_constant_override("separation", 12)
	body_mar.add_child(body_vb)

	# Upper Panel: 3-Step Visual Guide + Keycaps
	var guide_panel := PanelContainer.new()
	guide_panel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style(52.0, 44.0))
	body_vb.add_child(guide_panel)

	var g_vb := VBoxContainer.new()
	g_vb.add_theme_constant_override("separation", 10)
	guide_panel.add_child(g_vb)

	var steps_row := HBoxContainer.new()
	steps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	steps_row.add_theme_constant_override("separation", 22)
	g_vb.add_child(steps_row)

	var steps_data := [
		{
			"img": "guide_step_1",
			"title": "1. PILIH LEVEL",
			"desc": "Pilih pulau & arena di Peta Lembah Onsen, lalu siapkan pasukan Kapibaramu."
		},
		{
			"img": "guide_step_2",
			"title": "2. TARIK KETAPEL",
			"desc": "Seret ketapel ke belakang untuk membidik, lalu tekan SPASI saat terbang di udara!"
		},
		{
			"img": "guide_step_3",
			"title": "3. HABISKAN BUAYA",
			"desc": "Runtuhkan benteng kayu/bambu/es, picu tong TNT, dan tumbangkan semua Klan Buaya!"
		}
	]

	for st in steps_data:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(310, 0)
		col.add_theme_constant_override("separation", 5)
		steps_row.add_child(col)

		var thumb_wrap := CenterContainer.new()
		col.add_child(thumb_wrap)
		var thumb := CraftUI.make_tex_rect(CraftUI.tex(str(st["img"])), Vector2(236, 132))
		thumb_wrap.add_child(thumb)

		var st_title := Label.new()
		st_title.text = str(st["title"])
		st_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_title.add_theme_font_override("font", CraftUI.display_font())
		st_title.add_theme_font_size_override("font_size", 17)
		st_title.add_theme_color_override("font_color", Color(0.75, 0.19, 0.11))
		col.add_child(st_title)

		var st_desc := Label.new()
		st_desc.text = str(st["desc"])
		st_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		st_desc.custom_minimum_size = Vector2(304, 38)
		st_desc.add_theme_font_override("font", CraftUI.body_font())
		st_desc.add_theme_font_size_override("font_size", 13)
		st_desc.add_theme_color_override("font_color", CraftUI.INK)
		col.add_child(st_desc)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.62, 0.37, 0.14, 0.35)
	g_vb.add_child(sep)

	var keys_row := HBoxContainer.new()
	keys_row.alignment = BoxContainer.ALIGNMENT_CENTER
	keys_row.add_theme_constant_override("separation", 10)
	g_vb.add_child(keys_row)

	var key_tips := [
		["SPASI", 60.0, "Jurus Udara"],
		["1 / 2 / 3", 64.0, "Sudut Kamera"],
		["A / D", 54.0, "Geser Arena"],
		["R", 32.0, "Ulang Stage"],
		["ESC", 44.0, "Jeda Game"]
	]
	for kt in key_tips:
		keys_row.add_child(CraftUI.make_keycap(str(kt[0]), float(kt[1]), 28.0, 11))
		var kl := Label.new()
		kl.text = str(kt[2])
		kl.add_theme_font_override("font", CraftUI.body_font())
		kl.add_theme_font_size_override("font_size", 13)
		kl.add_theme_color_override("font_color", CraftUI.INK)
		keys_row.add_child(kl)

	# Lower Panel: Tim Pengembang (Alphabetical A -> Z)
	var team_panel := PanelContainer.new()
	team_panel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style(52.0, 46.0))
	body_vb.add_child(team_panel)

	var t_vb := VBoxContainer.new()
	t_vb.add_theme_constant_override("separation", 10)
	team_panel.add_child(t_vb)

	var t_hdr := HBoxContainer.new()
	t_hdr.add_theme_constant_override("separation", 12)
	t_vb.add_child(t_hdr)

	var lbl_team := CraftUI.make_stroked_label("TIM PENGEMBANG • TIM KEPLER452B", 17, CraftUI.GOLD_TEXT, 5, true)
	lbl_team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_hdr.add_child(lbl_team)

	var lbl_course := Label.new()
	lbl_course.text = "Komputer Grafis (CIF65116) Kelas D • Dosen: Pak Agi Putra Kharisma, S.T., M.T."
	lbl_course.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_course.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_course.add_theme_font_override("font", CraftUI.body_font())
	lbl_course.add_theme_font_size_override("font_size", 12)
	lbl_course.add_theme_color_override("font_color", Color(0.35, 0.19, 0.09))
	t_hdr.add_child(lbl_course)

	var members_row := HBoxContainer.new()
	members_row.alignment = BoxContainer.ALIGNMENT_CENTER
	members_row.add_theme_constant_override("separation", 14)
	t_vb.add_child(members_row)

	for m in TEAM_MEMBERS:
		var badge := PanelContainer.new()
		badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b_sb := StyleBoxFlat.new()
		b_sb.bg_color = Color(1.0, 0.973, 0.906, 1.0)
		b_sb.border_color = CraftUI.INK
		b_sb.border_width_left = 3
		b_sb.border_width_right = 3
		b_sb.border_width_top = 3
		b_sb.border_width_bottom = 6
		b_sb.set_corner_radius_all(8)
		b_sb.content_margin_left = 10
		b_sb.content_margin_right = 10
		b_sb.content_margin_top = 6
		b_sb.content_margin_bottom = 6
		badge.add_theme_stylebox_override("panel", b_sb)
		members_row.add_child(badge)

		var m_vb := VBoxContainer.new()
		m_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		m_vb.add_theme_constant_override("separation", 2)
		badge.add_child(m_vb)

		var m_name := Label.new()
		m_name.text = str(m["name"])
		m_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m_name.autowrap_mode = TextServer.AUTOWRAP_WORD
		m_name.add_theme_font_override("font", CraftUI.display_font())
		m_name.add_theme_font_size_override("font_size", 14)
		m_name.add_theme_color_override("font_color", Color(0.68, 0.17, 0.10))
		m_vb.add_child(m_name)

		var m_nim := Label.new()
		m_nim.text = "NIM %s" % str(m["nim"])
		m_nim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m_nim.add_theme_font_override("font", CraftUI.body_font())
		m_nim.add_theme_font_size_override("font_size", 13)
		m_nim.add_theme_color_override("font_color", CraftUI.INK)
		m_vb.add_child(m_nim)

func _go_home() -> void:
	SceneLoader.quick_transition_to(HOME_SCENE)

func _process(delta: float) -> void:
	elapsed += delta
	smooth_px = smooth_px.lerp(mouse_px, minf(delta * 5.0, 1.0))
	var off := Vector2(-smooth_px.x * 16.0, -smooth_px.y * 8.0)
	for lyr in bg_layers:
		var node: TextureRect = lyr["node"]
		var base_p: Vector2 = lyr["base"]
		var d: float = float(lyr["depth"])
		node.position = base_p + off * d

	if capture_path != "" and not capture_done and elapsed > 0.35:
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
			_go_home()
