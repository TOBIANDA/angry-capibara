extends Control

# Layar Peta Pilihan Sub-Level World 1: Lembah Onsen Bambu (1-1 s/d 1-20)
# Mengikuti palet Anti-Slop DESIGN.md (3 warna inti + 1 aksen Vermilion + netral Warm Lacquer Espresso)
# dengan latar 2D parallax Visual Studio C++ yang serasi dengan Home Screen.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const PHASES := [
	{ "badge": "FASE 1", "title": "1-1 s/d 1-5  •  Intro Bambu & Chill Capi", "start": 1, "end": 5 },
	{ "badge": "FASE 2", "title": "1-6 s/d 1-10  •  Kayu & Dash Capi", "start": 6, "end": 10 },
	{ "badge": "FASE 3", "title": "1-11 s/d 1-15  •  Es/Kaca & Trio Mini-Capi", "start": 11, "end": 15 },
	{ "badge": "FASE 4", "title": "1-16 s/d 1-20  •  Tong Yuzu TNT & Boss 1-20", "start": 16, "end": 20 }
]

var stage_meta: Dictionary = {}
var bg_layers: Array[Dictionary] = []
var grid_container: VBoxContainer
var lbl_stars_total: Label
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

	var btn_home := _make_btn("← HOME", false, Vector2(104, 42), 14)
	btn_home.pressed.connect(func(): get_tree().change_scene_to_file(HOME_SCENE))
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

	# Star counter badge
	var star_panel := PanelContainer.new()
	var sp_st := StyleBoxFlat.new()
	sp_st.bg_color = Color(0.16, 0.12, 0.10, 0.94)
	sp_st.border_color = Color(0.84, 0.74, 0.54)
	sp_st.set_border_width_all(2)
	sp_st.set_corner_radius_all(10)
	sp_st.content_margin_left = 14
	sp_st.content_margin_right = 14
	sp_st.content_margin_top = 6
	sp_st.content_margin_bottom = 6
	star_panel.add_theme_stylebox_override("panel", sp_st)
	hdr.add_child(star_panel)

	lbl_stars_total = Label.new()
	lbl_stars_total.add_theme_font_size_override("font_size", 16)
	lbl_stars_total.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
	star_panel.add_child(lbl_stars_total)

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

	lbl_stars_total.text = "★ %d / 60" % SaveManager.get_world1_total_stars()
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

		var ph_hdr := HBoxContainer.new()
		ph_hdr.add_theme_constant_override("separation", 10)
		ph_hdr.alignment = BoxContainer.ALIGNMENT_CENTER
		phase_vb.add_child(ph_hdr)

		var badge_panel := PanelContainer.new()
		var bp_st := StyleBoxFlat.new()
		bp_st.bg_color = Color(0.18, 0.13, 0.11, 0.95)
		bp_st.border_color = Color(0.83, 0.72, 0.50, 0.90)
		bp_st.set_border_width_all(1)
		bp_st.set_corner_radius_all(6)
		bp_st.content_margin_left = 9
		bp_st.content_margin_right = 9
		bp_st.content_margin_top = 2
		bp_st.content_margin_bottom = 2
		badge_panel.add_theme_stylebox_override("panel", bp_st)
		ph_hdr.add_child(badge_panel)

		var badge_lbl := Label.new()
		badge_lbl.text = str(ph["badge"])
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.44))
		badge_panel.add_child(badge_lbl)

		var plbl := Label.new()
		plbl.text = str(ph["title"])
		plbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plbl.add_theme_font_size_override("font_size", 13)
		plbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
		plbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.07, 0.90))
		plbl.add_theme_constant_override("outline_size", 3)
		ph_hdr.add_child(plbl)

		var pstars := Label.new()
		pstars.text = "★ %d / 15" % phase_stars
		pstars.add_theme_font_size_override("font_size", 12)
		pstars.add_theme_color_override("font_color", Color(0.94, 0.82, 0.48) if phase_stars == 15 else Color(0.82, 0.75, 0.62))
		pstars.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.07, 0.85))
		pstars.add_theme_constant_override("outline_size", 2)
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

	var bg := Color(0.17, 0.13, 0.11, 0.93)
	var border := Color(0.78, 0.69, 0.54, 0.82)
	var border_w := 2
	if not unlocked:
		bg = Color(0.11, 0.09, 0.08, 0.74)
		border = Color(0.38, 0.33, 0.29, 0.50)
	elif is_frontier:
		# 1 Aksen Fokus Tunggal Vermilion (DESIGN.md R-01)
		bg = Color(0.78, 0.21, 0.16, 0.96)
		border = Color(0.98, 0.88, 0.62)
		border_w = 3
	elif is_boss:
		bg = Color(0.21, 0.15, 0.12, 0.95)
		border = Color(0.92, 0.78, 0.42, 0.95)
		border_w = 2
	elif stars == 3:
		bg = Color(0.19, 0.14, 0.12, 0.94)
		border = Color(0.88, 0.77, 0.48, 0.92)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(border_w)
	normal.set_corner_radius_all(10)

	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.13)
	hover.border_color = Color(0.98, 0.90, 0.66)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.14)
	var disabled_sb := normal.duplicate()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	var mar := MarginContainer.new()
	mar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mar.add_theme_constant_override("margin_left", 10)
	mar.add_theme_constant_override("margin_right", 10)
	mar.add_theme_constant_override("margin_top", 7)
	mar.add_theme_constant_override("margin_bottom", 7)
	btn.add_child(mar)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 3)
	mar.add_child(vb)

	# Top row: Stage ID + optional Boss/Status badge
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_row)

	var lbl_id := Label.new()
	lbl_id.text = sid
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_id.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_id.add_theme_font_size_override("font_size", 15)
	if not unlocked:
		lbl_id.add_theme_color_override("font_color", Color(0.56, 0.51, 0.46, 0.85))
	elif is_frontier:
		lbl_id.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
	else:
		lbl_id.add_theme_color_override("font_color", Color(0.95, 0.83, 0.45))
	top_row.add_child(lbl_id)

	if is_boss:
		var boss_pill := PanelContainer.new()
		boss_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.14, 0.09, 0.08, 0.90)
		bs.border_color = Color(0.96, 0.84, 0.46, 0.90)
		bs.set_border_width_all(1)
		bs.set_corner_radius_all(5)
		bs.content_margin_left = 6
		bs.content_margin_right = 6
		bs.content_margin_top = 1
		bs.content_margin_bottom = 1
		boss_pill.add_theme_stylebox_override("panel", bs)
		top_row.add_child(boss_pill)

		var bl := Label.new()
		bl.text = "BOSS"
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bl.add_theme_font_size_override("font_size", 10)
		bl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.46))
		boss_pill.add_child(bl)
	elif is_frontier:
		var cta_lbl := Label.new()
		cta_lbl.text = "MAIN"
		cta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cta_lbl.add_theme_font_size_override("font_size", 10)
		cta_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
		top_row.add_child(cta_lbl)
	elif not unlocked:
		var lock_lbl := Label.new()
		lock_lbl.text = "TERKUNCI"
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_lbl.add_theme_font_size_override("font_size", 10)
		lock_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.45, 0.80))
		top_row.add_child(lock_lbl)

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
		lbl_name.add_theme_color_override("font_color", Color(0.58, 0.53, 0.48, 0.80))
	else:
		lbl_name.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	vb.add_child(lbl_name)

	# Bottom: Star badge row
	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 4)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(star_row)

	if not unlocked:
		var l_dash := Label.new()
		l_dash.text = "—  —  —"
		l_dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l_dash.add_theme_font_size_override("font_size", 12)
		l_dash.add_theme_color_override("font_color", Color(0.45, 0.40, 0.36, 0.72))
		star_row.add_child(l_dash)
	else:
		for k in 3:
			var sl := Label.new()
			var earned: bool = k < stars
			sl.text = "★" if earned else "☆"
			sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sl.add_theme_font_size_override("font_size", 15)
			if earned:
				sl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.38))
			else:
				sl.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 0.42) if is_frontier else Color(0.56, 0.50, 0.42, 0.72))
			sl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.06, 0.85))
			sl.add_theme_constant_override("outline_size", 2)
			star_row.add_child(sl)

	var stage_id_cap := sid
	btn.pressed.connect(func():
		SaveManager.selected_stage_id = stage_id_cap
		get_tree().change_scene_to_file(RUNNER_SCENE)
	)
	return btn

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
			get_tree().change_scene_to_file(HOME_SCENE)
