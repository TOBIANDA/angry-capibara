extends Control

# Layar Peta Pilihan Sub-Level World 1: Lembah Onsen Bambu (1-1 s/d 1-20)
# Desain terinspirasi Angry Birds: grid 5x4 tile persegi tebal di tengah, angka besar,
# 3 bintang melengkung, ikon gembok/mahkota boss, latar Onsen/Bambu terbuka, dan pita preview bawah.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const WORLD_MAP_SCENE := "res://scenes/ui/world_select_map.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const PHASES := [
	{ "badge": "FASE 1", "short": "Bambu & Chill", "start": 1, "end": 5, "pip": Color(0.45, 0.66, 0.32) },
	{ "badge": "FASE 2", "short": "Kayu & Dash", "start": 6, "end": 10, "pip": Color(0.72, 0.46, 0.26) },
	{ "badge": "FASE 3", "short": "Es & Trio Mini", "start": 11, "end": 15, "pip": Color(0.42, 0.68, 0.82) },
	{ "badge": "FASE 4", "short": "TNT & Boss", "start": 16, "end": 20, "pip": Color(0.82, 0.24, 0.18) }
]

var stage_meta: Dictionary = {}
var bg_layers: Array[Dictionary] = []
var grid_container: VBoxContainer
var lbl_stars_total: Label
var total_star_bar: ProgressBar
var btn_unlock_toggle: Button
var lbl_preview: Label
var display_font: SystemFont

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false
var default_preview_sid: String = "1-1"

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-w1="):
			capture_path = arg.substr(13)

	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["Impact", "Arial Black", "Segoe UI Black"])
	display_font.font_weight = 900

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
	_add_bg_tex("res://assets/generated/home2d/layer_01_sunburst.png", Vector2.ZERO, BASE_SIZE, 0.10, 0.72)
	_add_bg_tex("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 20.0), Vector2(1280.0, 420.0), 0.14)
	_add_bg_tex("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2.ZERO, BASE_SIZE, 0.22)
	_add_bg_tex("res://assets/generated/home2d/layer_04_midground_onsen.png", Vector2.ZERO, BASE_SIZE, 0.34)
	_add_bg_tex("res://assets/generated/home2d/layer_07_foreground_hill.png", Vector2(0.0, 330.0), Vector2(1280.0, 420.0), 0.52)
	_add_bg_tex("res://assets/generated/home2d/layer_08_bamboo_frame.png", Vector2.ZERO, BASE_SIZE, 0.80)

	# Lapisan hangat tipis (14%) agar pemandangan Onsen/Bambu bersinar cerah di belakang grid
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.11, 0.08, 0.07, 0.14)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
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
	lbl_sub.text = "Pilih Stage Pertempuran • 4 Fase (20 Sub-Level)"
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	lbl_sub.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.08))
	lbl_sub.add_theme_constant_override("outline_size", 3)
	title_vb.add_child(lbl_sub)

	# Star counter plaque (9-slice ui_panel_lacquer.png + ui_star_gold.png)
	var star_panel := PanelContainer.new()
	var sp_st := StyleBoxTexture.new()
	sp_st.texture = load("res://assets/generated/home2d/ui_panel_lacquer.png")
	sp_st.texture_margin_left = 20
	sp_st.texture_margin_right = 20
	sp_st.texture_margin_top = 20
	sp_st.texture_margin_bottom = 20
	sp_st.content_margin_left = 18
	sp_st.content_margin_right = 18
	sp_st.content_margin_top = 10
	sp_st.content_margin_bottom = 10
	star_panel.add_theme_stylebox_override("panel", sp_st)
	hdr.add_child(star_panel)

	var sp_vb := VBoxContainer.new()
	sp_vb.add_theme_constant_override("separation", 3)
	star_panel.add_child(sp_vb)

	var sp_top := HBoxContainer.new()
	sp_top.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_top.add_theme_constant_override("separation", 5)
	sp_vb.add_child(sp_top)

	var hdr_star_ic := TextureRect.new()
	hdr_star_ic.texture = load("res://assets/generated/home2d/ui_star_gold.png")
	hdr_star_ic.custom_minimum_size = Vector2(16, 16)
	hdr_star_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hdr_star_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp_top.add_child(hdr_star_ic)

	lbl_stars_total = Label.new()
	lbl_stars_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_stars_total.add_theme_font_size_override("font_size", 15)
	lbl_stars_total.add_theme_color_override("font_color", Color(0.98, 0.85, 0.42))
	sp_top.add_child(lbl_stars_total)

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

	# CENTERED 5x4 ANGRY BIRDS-STYLE TILE GRID
	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(center_wrap)

	grid_container = VBoxContainer.new()
	grid_container.add_theme_constant_override("separation", 12)
	center_wrap.add_child(grid_container)

	# BOTTOM STAGE PREVIEW RIBBON
	var bot_center := CenterContainer.new()
	root_vb.add_child(bot_center)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(680, 46)
	var pv_st := StyleBoxTexture.new()
	pv_st.texture = load("res://assets/generated/home2d/ui_panel_lacquer.png")
	pv_st.texture_margin_left = 20
	pv_st.texture_margin_right = 20
	pv_st.texture_margin_top = 14
	pv_st.texture_margin_bottom = 14
	pv_st.content_margin_left = 20
	pv_st.content_margin_right = 20
	pv_st.content_margin_top = 10
	pv_st.content_margin_bottom = 10
	preview_panel.add_theme_stylebox_override("panel", pv_st)
	bot_center.add_child(preview_panel)

	lbl_preview = Label.new()
	lbl_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_preview.add_theme_font_size_override("font_size", 14)
	lbl_preview.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
	preview_panel.add_child(lbl_preview)

	_rebuild_stage_grid()

func _rebuild_stage_grid() -> void:
	for c in grid_container.get_children():
		c.queue_free()

	var total_stars := SaveManager.get_world1_total_stars()
	lbl_stars_total.text = "%d / 60" % total_stars
	if total_star_bar:
		total_star_bar.value = float(total_stars)
	btn_unlock_toggle.text = "MODE PROGRES" if SaveManager.unlock_all_preview else "BUKA SEMUA"

	var frontier_id := "1-1"
	for s in range(1, 21):
		var sid := "1-%d" % s
		if SaveManager.is_stage_unlocked(sid):
			frontier_id = sid
			if SaveManager.get_stage_stars(sid) == 0:
				break
	default_preview_sid = frontier_id
	_set_preview_stage(default_preview_sid)

	for ph in PHASES:
		var s_start: int = int(ph["start"])
		var s_end: int = int(ph["end"])
		var phase_stars := 0
		for s in range(s_start, s_end + 1):
			phase_stars += SaveManager.get_stage_stars("1-%d" % s)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		grid_container.add_child(row)

		# Compact left-side Phase Crest Pill
		var crest_center := CenterContainer.new()
		row.add_child(crest_center)

		var crest := PanelContainer.new()
		crest.custom_minimum_size = Vector2(126, 86)
		var cr_st := StyleBoxTexture.new()
		cr_st.texture = load("res://assets/generated/home2d/ui_panel_lacquer.png")
		cr_st.texture_margin_left = 18
		cr_st.texture_margin_right = 18
		cr_st.texture_margin_top = 18
		cr_st.texture_margin_bottom = 18
		cr_st.content_margin_left = 12
		cr_st.content_margin_right = 12
		cr_st.content_margin_top = 10
		cr_st.content_margin_bottom = 10
		crest.add_theme_stylebox_override("panel", cr_st)
		crest_center.add_child(crest)

		var cr_vb := VBoxContainer.new()
		cr_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		cr_vb.add_theme_constant_override("separation", 2)
		crest.add_child(cr_vb)

		var cr_top := HBoxContainer.new()
		cr_top.alignment = BoxContainer.ALIGNMENT_CENTER
		cr_top.add_theme_constant_override("separation", 5)
		cr_vb.add_child(cr_top)

		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 13)
		pip.color = ph["pip"]
		cr_top.add_child(pip)

		var cr_badge := Label.new()
		cr_badge.text = str(ph["badge"])
		cr_badge.add_theme_font_size_override("font_size", 12)
		cr_badge.add_theme_color_override("font_color", Color(0.98, 0.86, 0.44))
		cr_top.add_child(cr_badge)

		var cr_short := Label.new()
		cr_short.text = str(ph["short"])
		cr_short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cr_short.add_theme_font_size_override("font_size", 11)
		cr_short.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
		cr_vb.add_child(cr_short)

		var cr_stars := Label.new()
		cr_stars.text = "★ %d / 15" % phase_stars
		cr_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cr_stars.add_theme_font_size_override("font_size", 11)
		cr_stars.add_theme_color_override("font_color", Color(0.98, 0.84, 0.40) if phase_stars == 15 else Color(0.80, 0.74, 0.62))
		cr_vb.add_child(cr_stars)

		for s in range(s_start, s_end + 1):
			var sid := "1-%d" % s
			var unlocked: bool = SaveManager.is_stage_unlocked(sid)
			var stars: int = SaveManager.get_stage_stars(sid)
			var is_boss: bool = (s == 20)
			var is_frontier: bool = unlocked and (sid == frontier_id)
			row.add_child(_make_stage_tile(s, sid, unlocked, stars, is_frontier, is_boss))

func _make_stage_tile(stage_num: int, sid: String, unlocked: bool, stars: int, is_frontier: bool, is_boss: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(118, 108)
	btn.pivot_offset = Vector2(59, 54)
	btn.disabled = not unlocked
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	var tex_path := "res://assets/generated/home2d/ui_tile_open.png"
	if not unlocked:
		tex_path = "res://assets/generated/home2d/ui_tile_locked.png"
	elif is_boss:
		tex_path = "res://assets/generated/home2d/ui_tile_boss.png"

	var normal := StyleBoxTexture.new()
	if ResourceLoader.exists(tex_path):
		normal.texture = load(tex_path)
	normal.texture_margin_left = 22
	normal.texture_margin_right = 22
	normal.texture_margin_top = 22
	normal.texture_margin_bottom = 26
	if is_frontier and not is_boss:
		normal.modulate_color = Color(1.06, 1.02, 0.90)

	var hover: StyleBoxTexture = normal.duplicate() as StyleBoxTexture
	hover.modulate_color = normal.modulate_color * Color(1.08, 1.06, 1.02)
	var pressed: StyleBoxTexture = normal.duplicate() as StyleBoxTexture
	pressed.modulate_color = normal.modulate_color * Color(0.88, 0.86, 0.84)
	var disabled_sb: StyleBoxTexture = normal.duplicate() as StyleBoxTexture

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_sb)

	# Big bold stage number (Angry Birds style)
	var lbl_num := Label.new()
	lbl_num.text = str(stage_num)
	lbl_num.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_num.offset_top = 8
	lbl_num.offset_bottom = 58
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display_font:
		lbl_num.add_theme_font_override("font", display_font)
	lbl_num.add_theme_font_size_override("font_size", 36)
	if not unlocked:
		lbl_num.add_theme_color_override("font_color", Color(0.76, 0.72, 0.68, 0.45))
		lbl_num.add_theme_color_override("font_outline_color", Color(0.14, 0.11, 0.10, 0.55))
		lbl_num.add_theme_constant_override("outline_size", 4)
	elif is_boss:
		lbl_num.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72))
		lbl_num.add_theme_color_override("font_outline_color", Color(0.24, 0.06, 0.05))
		lbl_num.add_theme_constant_override("outline_size", 5)
	else:
		lbl_num.add_theme_color_override("font_color", Color(0.99, 0.96, 0.88))
		lbl_num.add_theme_color_override("font_outline_color", Color(0.20, 0.12, 0.08))
		lbl_num.add_theme_constant_override("outline_size", 5)
	btn.add_child(lbl_num)

	# Boss crown badge in top-right corner
	if is_boss and ResourceLoader.exists("res://assets/generated/home2d/ui_boss_crown.png"):
		var crown := TextureRect.new()
		crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crown.texture = load("res://assets/generated/home2d/ui_boss_crown.png")
		crown.custom_minimum_size = Vector2(28, 28)
		crown.position = Vector2(82, 6)
		crown.size = Vector2(28, 28)
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(crown)

	# Frontier subtle golden indicator dot in top-left
	if is_frontier and unlocked:
		var dot := ColorRect.new()
		dot.position = Vector2(12, 12)
		dot.size = Vector2(8, 8)
		dot.color = Color(0.98, 0.84, 0.30)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(dot)

	if not unlocked:
		# Centered padlock icon
		if ResourceLoader.exists("res://assets/generated/home2d/ui_lock.png"):
			var lock_ic := TextureRect.new()
			lock_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_ic.texture = load("res://assets/generated/home2d/ui_lock.png")
			lock_ic.custom_minimum_size = Vector2(36, 36)
			lock_ic.position = Vector2(41, 48)
			lock_ic.size = Vector2(36, 36)
			lock_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(lock_ic)
	else:
		# 3 large arched/overlapping stars at bottom (center star larger & higher!)
		var tex_gold: Texture2D = load("res://assets/generated/home2d/ui_star_gold.png")
		var tex_empty: Texture2D = load("res://assets/generated/home2d/ui_star_empty.png")
		var star_cfgs := [
			{ "pos": Vector2(19, 64), "sz": 24.0, "rot": -8.0 },
			{ "pos": Vector2(45, 58), "sz": 28.0, "rot": 0.0 },
			{ "pos": Vector2(75, 64), "sz": 24.0, "rot": 8.0 }
		]
		for k in 3:
			var sc: Dictionary = star_cfgs[k]
			var ssz: float = float(sc["sz"])
			var s_ic := TextureRect.new()
			s_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			s_ic.texture = tex_gold if k < stars else tex_empty
			s_ic.custom_minimum_size = Vector2(ssz, ssz)
			s_ic.position = sc["pos"]
			s_ic.size = Vector2(ssz, ssz)
			s_ic.pivot_offset = Vector2(ssz * 0.5, ssz * 0.5)
			s_ic.rotation_degrees = float(sc["rot"])
			s_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(s_ic)

	var stage_id_cap := sid
	btn.mouse_entered.connect(func():
		_set_preview_stage(stage_id_cap)
		if unlocked:
			btn.scale = Vector2(1.06, 1.06)
	)
	btn.mouse_exited.connect(func():
		btn.scale = Vector2.ONE
		_set_preview_stage(default_preview_sid)
	)
	btn.pressed.connect(func():
		SaveManager.selected_stage_id = stage_id_cap
		get_tree().change_scene_to_file(RUNNER_SCENE)
	)
	return btn

func _set_preview_stage(sid: String) -> void:
	if not is_instance_valid(lbl_preview):
		return
	var title: String = str(stage_meta.get(sid, sid))
	var best: int = SaveManager.get_stage_best_score(sid)
	var unlocked: bool = SaveManager.is_stage_unlocked(sid)
	if not unlocked:
		lbl_preview.text = "Stage %s: %s  •  Terkunci (Selesaikan stage sebelumnya)" % [sid, title]
	elif best > 0:
		lbl_preview.text = "Stage %s: %s  •  Rekor: %d" % [sid, title, best]
	else:
		lbl_preview.text = "Stage %s: %s  •  Siap Dimainkan!" % [sid, title]

func _make_btn(txt: String, is_primary: bool, min_sz: Vector2, fsize: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_sz
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", Color(0.98, 0.95, 0.89))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.94))
	b.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.06))
	b.add_theme_constant_override("outline_size", 2)
	var tex_path := "res://assets/generated/home2d/ui_btn_vermilion.png" if is_primary else "res://assets/generated/home2d/ui_btn_wood.png"
	var sb := StyleBoxTexture.new()
	sb.texture = load(tex_path)
	sb.texture_margin_left = 20
	sb.texture_margin_right = 20
	sb.texture_margin_top = 14
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 5
	var hv: StyleBoxTexture = sb.duplicate() as StyleBoxTexture
	hv.modulate_color = Color(1.10, 1.07, 1.03)
	var pr: StyleBoxTexture = sb.duplicate() as StyleBoxTexture
	pr.modulate_color = Color(0.84, 0.80, 0.78)
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
