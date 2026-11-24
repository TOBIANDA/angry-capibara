extends Control

# Layar Peta Pilihan Sub-Level World 1: Lembah Onsen Bambu (1-1 s/d 1-20)
# Mengikuti palet Anti-Slop DESIGN.md (3 warna inti + 1 aksen Vermilion + netral Warm Lacquer Espresso)
# dengan latar 2D parallax Visual Studio C++ yang serasi dengan Home Screen.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const WORLD_MAP_SCENE := "res://scenes/ui/world_select_map.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const PHASES := [
	{ "badge": "FASE 1", "title": "1-1 s/d 1-5  •  Intro Bambu & Chill Capi", "start": 1, "end": 5, "pip": Color(0.45, 0.66, 0.32) },
	{ "badge": "FASE 2", "title": "1-6 s/d 1-10  •  Kayu & Dash Capi", "start": 6, "end": 10, "pip": Color(0.72, 0.46, 0.26) },
	{ "badge": "FASE 3", "title": "1-11 s/d 1-15  •  Es/Kaca & Trio Mini-Capi", "start": 11, "end": 15, "pip": Color(0.42, 0.68, 0.82) },
	{ "badge": "FASE 4", "title": "1-16 s/d 1-20  •  Tong Yuzu TNT & Boss 1-20", "start": 16, "end": 20, "pip": Color(0.82, 0.24, 0.18) }
]

var stage_meta: Dictionary = {}
var bg_layers: Array[Dictionary] = []
var grid_container: VBoxContainer
var lbl_stars_total: Label
var total_star_bar: ProgressBar
var btn_unlock_toggle: Button

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-w1="):
			capture_path = arg.substr(13)

	clip_contents = true
	_load_stage_metadata()
	_setup_parallax_bg()
	_setup_ui()

func _load_stage_metadata() -> void:
	for s in range(1, 21):
		var sid := "1-%d" % s
		var path := "res://data/levels/w1/%s.json" % sid
		var title := "Stage %s" % sid
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var parsed = JSON.parse_string(f.get_as_text())
				f.close()
				if parsed is Dictionary:
					title = str(parsed.get("name", title))
		stage_meta[sid] = title

func _add_bg_tex(path: String, base_p: Vector2, sz: Vector2, depth: float, alpha: float = 1.0) -> void:
	var tr := TextureRect.new()
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
	_add_bg_tex("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 20.0), Vector2(1280.0, 420.0), 0.14)
	_add_bg_tex("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.22)
	_add_bg_tex("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.34)
	_add_bg_tex("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 330.0), Vector2(1280.0, 420.0), 0.52)
	_add_bg_tex("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 0.80)

	# Lapisan gelap hangat tipis agar kartu 20 sub-level kontras & nyaman dibaca
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.11, 0.08, 0.07, 0.56)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 12)
	margin.add_child(root_vb)

	# HEADER BAR
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	root_vb.add_child(hdr)

	var btn_home := _make_btn("← PETA WORLD", false, Vector2(130, 42), 13)
	btn_home.pressed.connect(func(): get_tree().change_scene_to_file(WORLD_MAP_SCENE))
	hdr.add_child(btn_home)

	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vb.add_theme_constant_override("separation", 1)
	hdr.add_child(title_vb)

	var lbl_title := Label.new()
	lbl_title.text = "WORLD 1 — LEMBAH ONSEN BAMBU"
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	lbl_title.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.08))
	lbl_title.add_theme_constant_override("outline_size", 4)
	title_vb.add_child(lbl_title)

	var lbl_sub := Label.new()
	lbl_sub.text = "Pertahankan Lembah Onsen dari Klan Buaya Rakus • 4 Fase (20 Sub-Level)"
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color(0.86, 0.80, 0.68))
	title_vb.add_child(lbl_sub)

	# Star counter plaque with live progress bar
	var star_panel := PanelContainer.new()
	var sp_st := StyleBoxFlat.new()
	sp_st.bg_color = Color(0.15, 0.11, 0.09, 0.96)
	sp_st.border_color = Color(0.88, 0.76, 0.46)
	sp_st.set_border_width_all(2)
	sp_st.set_corner_radius_all(10)
	sp_st.shadow_color = Color(0.03, 0.02, 0.02, 0.55)
	sp_st.shadow_size = 5
	sp_st.shadow_offset = Vector2(0, 3)
	sp_st.content_margin_left = 14
	sp_st.content_margin_right = 14
	sp_st.content_margin_top = 5
	sp_st.content_margin_bottom = 5
	star_panel.add_theme_stylebox_override("panel", sp_st)
	hdr.add_child(star_panel)

	var sp_vb := VBoxContainer.new()
	sp_vb.add_theme_constant_override("separation", 3)
	star_panel.add_child(sp_vb)

	lbl_stars_total = Label.new()
	lbl_stars_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_stars_total.add_theme_font_size_override("font_size", 15)
	lbl_stars_total.add_theme_color_override("font_color", Color(0.98, 0.85, 0.42))
	sp_vb.add_child(lbl_stars_total)

	total_star_bar = ProgressBar.new()
	total_star_bar.custom_minimum_size = Vector2(104, 5)
	total_star_bar.max_value = 60.0
	total_star_bar.show_percentage = false
	var tsb_bg := StyleBoxFlat.new()
	tsb_bg.bg_color = Color(0.09, 0.07, 0.06, 0.90)
	tsb_bg.set_corner_radius_all(3)
	var tsb_fill := StyleBoxFlat.new()
	tsb_fill.bg_color = Color(0.96, 0.80, 0.34)
	tsb_fill.set_corner_radius_all(3)
	total_star_bar.add_theme_stylebox_override("background", tsb_bg)
	total_star_bar.add_theme_stylebox_override("fill", tsb_fill)
	sp_vb.add_child(total_star_bar)

	btn_unlock_toggle = _make_btn("BUKA SEMUA", false, Vector2(126, 42), 13)
	btn_unlock_toggle.pressed.connect(_toggle_unlock_preview)
	hdr.add_child(btn_unlock_toggle)

	var btn_sandbox := _make_btn("SANDBOX", false, Vector2(102, 42), 13)
	btn_sandbox.pressed.connect(func(): get_tree().change_scene_to_file(SANDBOX_SCENE))
	hdr.add_child(btn_sandbox)

	# 4 PHASE ROWS × 5 SUB-LEVEL CARDS
	grid_container = VBoxContainer.new()
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_container.add_theme_constant_override("separation", 10)
	root_vb.add_child(grid_container)

	_rebuild_stage_grid()

func _rebuild_stage_grid() -> void:
	for c in grid_container.get_children():
		c.queue_free()

	var total_stars := SaveManager.get_world1_total_stars()
	lbl_stars_total.text = "★ %d / 60" % total_stars
	if total_star_bar:
		total_star_bar.value = float(total_stars)
	btn_unlock_toggle.text = "MODE PROGRES" if SaveManager.unlock_all_preview else "BUKA SEMUA"

	# Cari frontier stage terakhir yang terbuka tapi belum berbintang
	var frontier_id := "1-1"
	for s in range(1, 21):
		var sid := "1-%d" % s
		if SaveManager.is_stage_unlocked(sid):
			frontier_id = sid
			if SaveManager.get_stage_stars(sid) == 0:
				break

	for ph in PHASES:
		var phase_vb := VBoxContainer.new()
		phase_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		phase_vb.add_theme_constant_override("separation", 5)
		grid_container.add_child(phase_vb)

		var s_start: int = int(ph["start"])
		var s_end: int = int(ph["end"])
		var phase_stars := 0
		for s in range(s_start, s_end + 1):
			phase_stars += SaveManager.get_stage_stars("1-%d" % s)

		# Woodblock phase banner plaque
		var ph_banner := PanelContainer.new()
		var pb_st := StyleBoxFlat.new()
		pb_st.bg_color = Color(0.14, 0.10, 0.09, 0.88)
		pb_st.border_color = Color(0.76, 0.65, 0.45, 0.55)
		pb_st.border_width_bottom = 2
		pb_st.set_corner_radius_all(8)
		pb_st.content_margin_left = 10
		pb_st.content_margin_right = 12
		pb_st.content_margin_top = 4
		pb_st.content_margin_bottom = 4
		ph_banner.add_theme_stylebox_override("panel", pb_st)
		phase_vb.add_child(ph_banner)

		var ph_hdr := HBoxContainer.new()
		ph_hdr.add_theme_constant_override("separation", 10)
		ph_hdr.alignment = BoxContainer.ALIGNMENT_CENTER
		ph_banner.add_child(ph_hdr)

		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 16)
		pip.color = ph["pip"]
		ph_hdr.add_child(pip)

		var badge_panel := PanelContainer.new()
		var bp_st := StyleBoxFlat.new()
		bp_st.bg_color = Color(0.22, 0.16, 0.12, 0.96)
		bp_st.border_color = Color(0.86, 0.74, 0.48, 0.85)
		bp_st.set_border_width_all(1)
		bp_st.set_corner_radius_all(5)
		bp_st.content_margin_left = 8
		bp_st.content_margin_right = 8
		bp_st.content_margin_top = 1
		bp_st.content_margin_bottom = 1
		badge_panel.add_theme_stylebox_override("panel", bp_st)
		ph_hdr.add_child(badge_panel)

		var badge_lbl := Label.new()
		badge_lbl.text = str(ph["badge"])
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.44))
		badge_panel.add_child(badge_lbl)

		var plbl := Label.new()
		plbl.text = str(ph["title"])
		plbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plbl.add_theme_font_size_override("font_size", 13)
		plbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
		ph_hdr.add_child(plbl)

		var pstars := Label.new()
		pstars.text = "★ %d / 15" % phase_stars
		pstars.add_theme_font_size_override("font_size", 12)
		pstars.add_theme_color_override("font_color", Color(0.98, 0.84, 0.40) if phase_stars == 15 else Color(0.84, 0.76, 0.62))
		ph_hdr.add_child(pstars)

		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		phase_vb.add_child(row)

		for s in range(s_start, s_end + 1):
			var sid := "1-%d" % s
			var unlocked: bool = SaveManager.is_stage_unlocked(sid)
			var stars: int = SaveManager.get_stage_stars(sid)
			var is_boss: bool = (s == 20)
			var is_frontier: bool = unlocked and (sid == frontier_id)
			row.add_child(_make_stage_card(sid, unlocked, stars, is_frontier, is_boss))

func _make_stage_card(sid: String, unlocked: bool, stars: int, is_frontier: bool, is_boss: bool) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.disabled = not unlocked
	btn.clip_contents = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	var bg := Color(0.17, 0.13, 0.11, 0.95)
	var border := Color(0.76, 0.67, 0.52, 0.82)
	var bevel_col := Color(0.62, 0.50, 0.36, 0.45)
	var border_w := 2
	var shadow_sz := 5
	if not unlocked:
		bg = Color(0.10, 0.09, 0.09, 0.70)
		border = Color(0.32, 0.28, 0.25, 0.45)
		bevel_col = Color(0.24, 0.20, 0.18, 0.22)
		border_w = 1
		shadow_sz = 0
	elif is_frontier:
		# 1 Aksen Fokus Tunggal Vermilion (DESIGN.md R-01)
		bg = Color(0.78, 0.21, 0.16, 0.98)
		border = Color(0.98, 0.88, 0.60)
		bevel_col = Color(0.98, 0.78, 0.50, 0.85)
		border_w = 3
		shadow_sz = 7
	elif is_boss:
		bg = Color(0.24, 0.13, 0.12, 0.96)
		border = Color(0.92, 0.78, 0.42, 0.95)
		bevel_col = Color(0.95, 0.78, 0.38, 0.72)
	elif stars == 3:
		bg = Color(0.22, 0.16, 0.12, 0.96)
		border = Color(0.90, 0.76, 0.42, 0.95)
		bevel_col = Color(0.96, 0.82, 0.40, 0.78)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(border_w)
	normal.border_width_bottom = border_w + (2 if unlocked else 0)
	normal.set_corner_radius_all(10)
	if shadow_sz > 0:
		normal.shadow_color = Color(0.03, 0.02, 0.02, 0.56)
		normal.shadow_size = shadow_sz
		normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.12)
	hover.border_color = Color(0.99, 0.91, 0.66)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.14)
	var disabled_sb := normal.duplicate()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	# Warm inner woodblock top-bevel highlight strip
	var bevel := ColorRect.new()
	bevel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bevel.offset_left = 8
	bevel.offset_right = -8
	bevel.offset_top = border_w + 1
	bevel.offset_bottom = border_w + 3
	bevel.color = bevel_col
	bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bevel)

	var mar := MarginContainer.new()
	mar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mar.add_theme_constant_override("margin_left", 10)
	mar.add_theme_constant_override("margin_right", 10)
	mar.add_theme_constant_override("margin_top", 8)
	mar.add_theme_constant_override("margin_bottom", 7)
	btn.add_child(mar)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 3)
	mar.add_child(vb)

	# Top row: Stage ID + status badge
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_row)

	var lbl_id := Label.new()
	lbl_id.text = sid
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_id.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_id.add_theme_font_size_override("font_size", 15)
	if not unlocked:
		lbl_id.add_theme_color_override("font_color", Color(0.50, 0.45, 0.40, 0.80))
	elif is_frontier:
		lbl_id.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
	else:
		lbl_id.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	top_row.add_child(lbl_id)

	if is_boss:
		top_row.add_child(_make_micro_pill("BOSS", Color(0.14, 0.08, 0.07, 0.94), Color(0.98, 0.86, 0.46), Color(0.96, 0.82, 0.42, 0.92)))
	elif is_frontier:
		top_row.add_child(_make_micro_pill("▶ MAIN", Color(0.42, 0.09, 0.07, 0.88), Color(1.0, 0.96, 0.84), Color(0.98, 0.88, 0.62, 0.85)))
	elif not unlocked:
		top_row.add_child(_make_micro_pill("TERKUNCI", Color(0.14, 0.12, 0.11, 0.72), Color(0.56, 0.51, 0.46, 0.82), Color(0.36, 0.32, 0.28, 0.50)))
	elif stars == 3:
		top_row.add_child(_make_micro_pill("SEMPURNA", Color(0.28, 0.20, 0.11, 0.92), Color(0.98, 0.86, 0.44), Color(0.88, 0.74, 0.40, 0.85)))

	# Middle: Full wrapped stage title (no ellipsis truncation)
	var stage_title: String = str(stage_meta.get(sid, sid))
	var lbl_name := Label.new()
	lbl_name.text = stage_title
	lbl_name.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_name.add_theme_font_size_override("font_size", 13)
	if not unlocked:
		lbl_name.add_theme_color_override("font_color", Color(0.54, 0.49, 0.44, 0.78))
	else:
		lbl_name.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	vb.add_child(lbl_name)

	# Bottom: Recessed lacquer star emblem tray
	var tray_center := HBoxContainer.new()
	tray_center.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(tray_center)

	var tray := PanelContainer.new()
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr_st := StyleBoxFlat.new()
	tr_st.bg_color = Color(0.09, 0.06, 0.05, 0.62) if not is_frontier else Color(0.36, 0.08, 0.06, 0.65)
	tr_st.set_corner_radius_all(8)
	tr_st.content_margin_left = 10
	tr_st.content_margin_right = 10
	tr_st.content_margin_top = 1
	tr_st.content_margin_bottom = 1
	tray.add_theme_stylebox_override("panel", tr_st)
	tray_center.add_child(tray)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 5)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(star_row)

	if not unlocked:
		var l_dash := Label.new()
		l_dash.text = "—  —  —"
		l_dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l_dash.add_theme_font_size_override("font_size", 11)
		l_dash.add_theme_color_override("font_color", Color(0.42, 0.37, 0.33, 0.70))
		star_row.add_child(l_dash)
	else:
		for k in 3:
			var sl := Label.new()
			var earned: bool = k < stars
			sl.text = "★" if earned else "☆"
			sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sl.add_theme_font_size_override("font_size", 15)
			if earned:
				sl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.34))
			else:
				sl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 0.40) if is_frontier else Color(0.54, 0.48, 0.40, 0.72))
			sl.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.05, 0.90))
			sl.add_theme_constant_override("outline_size", 2)
			star_row.add_child(sl)

	var stage_id_cap := sid
	btn.pressed.connect(func():
		SaveManager.selected_stage_id = stage_id_cap
		get_tree().change_scene_to_file(RUNNER_SCENE)
	)
	return btn

func _make_micro_pill(txt: String, bg_col: Color, txt_col: Color, bdr_col: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = bg_col
	st.border_color = bdr_col
	st.set_border_width_all(1)
	st.set_corner_radius_all(5)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", st)
	var lb := Label.new()
	lb.text = txt
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.add_theme_font_size_override("font_size", 10)
	lb.add_theme_color_override("font_color", txt_col)
	pill.add_child(lb)
	return pill

func _make_btn(txt: String, is_primary: bool, min_sz: Vector2, fsize: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.94))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.80, 0.22, 0.16) if is_primary else Color(0.17, 0.13, 0.11, 0.94)
	sb.border_color = Color(0.95, 0.86, 0.66) if is_primary else Color(0.76, 0.68, 0.54, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	var hv := sb.duplicate()
	hv.bg_color = sb.bg_color.lightened(0.14)
	var pr := sb.duplicate()
	pr.bg_color = sb.bg_color.darkened(0.14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", pr)
	return b

func _toggle_unlock_preview() -> void:
	SaveManager.unlock_all_preview = not SaveManager.unlock_all_preview
	_rebuild_stage_grid()

func _process(delta: float) -> void:
	elapsed += delta
	smooth_px = smooth_px.lerp(mouse_px, minf(delta * 5.0, 1.0))
	var off := Vector2(-smooth_px.x * 18.0, -smooth_px.y * 10.0)
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
			get_tree().change_scene_to_file(WORLD_MAP_SCENE)
