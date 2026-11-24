extends Control

# Layar Peta Pilihan Sub-Level World 1: Lembah Onsen Bambu (1-1 s/d 1-20)
# Mengikuti palet Anti-Slop DESIGN.md (3 warna inti + 1 aksen Vermilion + netral Warm Lacquer Espresso)
# dengan latar 2D parallax Visual Studio C++ yang serasi dengan Home Screen.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const PHASES := [
	{ "title": "FASE 1 (1-1 s/d 1-5) — Intro Bambu & Chill Capi", "start": 1, "end": 5 },
	{ "title": "FASE 2 (1-6 s/d 1-10) — + Kayu & Dash Capi", "start": 6, "end": 10 },
	{ "title": "FASE 3 (1-11 s/d 1-15) — + Es/Kaca & Trio Mini-Capi", "start": 11, "end": 15 },
	{ "title": "FASE 4 (1-16 s/d 1-20) — + Tong Yuzu TNT & Boss 1-20", "start": 16, "end": 20 }
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

		var plbl := Label.new()
		plbl.text = str(ph["title"])
		plbl.add_theme_font_size_override("font_size", 13)
		plbl.add_theme_color_override("font_color", Color(0.92, 0.85, 0.70))
		phase_vb.add_child(plbl)

		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		phase_vb.add_child(row)

		var s_start: int = int(ph["start"])
		var s_end: int = int(ph["end"])
		for s in range(s_start, s_end + 1):
			var sid := "1-%d" % s
			var unlocked: bool = SaveManager.is_stage_unlocked(sid)
			var stars: int = SaveManager.get_stage_stars(sid)
			var is_boss: bool = (s == 20)
			var is_highlight: bool = unlocked and (sid == frontier_id or is_boss)
			row.add_child(_make_stage_card(sid, unlocked, stars, is_highlight, is_boss))

func _make_stage_card(sid: String, unlocked: bool, stars: int, is_highlight: bool, is_boss: bool) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.disabled = not unlocked
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	var bg := Color(0.16, 0.12, 0.11, 0.92)
	var border := Color(0.76, 0.68, 0.54, 0.85)
	if not unlocked:
		bg = Color(0.12, 0.10, 0.09, 0.72)
		border = Color(0.42, 0.37, 0.32, 0.55)
	elif is_highlight:
		# 1 Aksen Fokus Tunggal Vermilion (DESIGN.md R-01)
		bg = Color(0.74, 0.21, 0.16, 0.95)
		border = Color(0.96, 0.88, 0.68)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2 if not is_highlight else 3)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.14)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.14)
	var disabled_sb := normal.duplicate()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	var star_str := ""
	if not unlocked:
		star_str = "TERKUNCI"
	else:
		for k in 3:
			star_str += "★" if k < stars else "☆"
		if is_boss:
			star_str = "BOSS  " + star_str

	var stage_title: String = str(stage_meta.get(sid, sid))
	if stage_title.length() > 21:
		stage_title = stage_title.substr(0, 20) + "…"
	btn.text = "%s\n%s\n%s" % [sid, stage_title, star_str]
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.98, 0.95, 0.89))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.94))
	btn.add_theme_color_override("font_disabled_color", Color(0.62, 0.57, 0.52, 0.82))

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
