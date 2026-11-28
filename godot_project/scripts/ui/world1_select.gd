extends Control

# Layar Peta Pilihan Sub-Level World 1: Lembah Onsen Bambu (1-1 s/d 1-20)
# Desain terinspirasi Angry Birds: grid 5x4 tile persegi tebal di tengah, angka besar,
# 3 bintang melengkung, ikon gembok/mahkota boss, latar Onsen/Bambu terbuka, dan pita preview bawah.

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const WORLD_MAP_SCENE := "res://scenes/ui/world_select_map.tscn"
const RUNNER_SCENE := "res://scenes/gameplay/level_runner.tscn"
const SANDBOX_SCENE := "res://scenes/sandbox/mode_tester.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

var stage_meta: Dictionary = {}
var bg_layers: Array[Dictionary] = []
var grid_container: VBoxContainer
var lbl_stars_total: Label
var btn_unlock_toggle: Button
var lbl_preview: Label
var btn_play_selected: Button
var frontier_arrow: TextureRect
var frontier_arrow_base_y: float = -22.0

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

	# Sedikit meredupkan latar Onsen (24%) agar papan kayu panggung & angka menonjol jelas tanpa kotak wadah
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.08, 0.06, 0.05, 0.24)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", CraftUI.TOP_BAR_MARGIN_X)
	margin.add_theme_constant_override("margin_right", CraftUI.TOP_BAR_MARGIN_X)
	margin.add_theme_constant_override("margin_top", CraftUI.TOP_BAR_MARGIN_TOP)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 14)
	margin.add_child(root_vb)

	# TOP BAR: Bare Title & Floating Star Counter + Carved Wood Utilities
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	root_vb.add_child(hdr)

	var btn_home := CraftUI.make_back_btn("PETA")
	btn_home.pressed.connect(_go_world_map)
	hdr.add_child(btn_home)

	var lbl_title := CraftUI.make_stroked_label("WORLD 1 • LEMBAH ONSEN BAMBU", 30, CraftUI.GOLD_TEXT, 6, true)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_title)

	var sc := CraftUI.make_star_counter("0/60", 28.0, 22)
	var sc_root: Control = sc["root"]
	sc_root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_stars_total = sc["label"]
	hdr.add_child(sc_root)

	btn_unlock_toggle = CraftUI.make_wood_btn("BUKA SEMUA", "wood_btn_cedar", Vector2(140, 46), 14, 1.0)
	btn_unlock_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_unlock_toggle.pressed.connect(_toggle_unlock_preview)
	hdr.add_child(btn_unlock_toggle)

	var btn_sandbox := CraftUI.make_wood_btn("SANDBOX", "wood_btn_cedar_dark", Vector2(112, 46), 14, -1.0)
	btn_sandbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_sandbox.pressed.connect(func():
		SceneLoader.transition_to(SANDBOX_SCENE, "MEMUAT SANDBOX", "Tips: Coba semua 7 Kapibara & 3 sudut kamera 2.5D/3D!", 0.50)
	)
	hdr.add_child(btn_sandbox)

	# OPEN-CANVAS 4-ROW HANGING WOOD EMA GRID (Zero dashboard white container!)
	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(center_wrap)

	grid_container = VBoxContainer.new()
	grid_container.add_theme_constant_override("separation", 16)
	center_wrap.add_child(grid_container)

	# BOTTOM-RIGHT SELECTED STAGE LAUNCH BAR (Compact & Rapi)
	var bot_hb := HBoxContainer.new()
	bot_hb.alignment = BoxContainer.ALIGNMENT_END
	bot_hb.add_theme_constant_override("separation", 14)
	root_vb.add_child(bot_hb)

	lbl_preview = CraftUI.make_stroked_label("", 16, Color(1.0, 0.96, 0.86), 5, true)
	lbl_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bot_hb.add_child(lbl_preview)

	btn_play_selected = CraftUI.make_wood_btn("▶ MAIN 1-1", "wood_btn_vermilion", Vector2(158, 46), 19, 1.2)
	btn_play_selected.pressed.connect(func():
		SaveManager.selected_stage_id = default_preview_sid
		SceneLoader.transition_to(RUNNER_SCENE, "MEMUAT STAGE %s" % default_preview_sid, "", 0.56)
	)
	bot_hb.add_child(btn_play_selected)

	_rebuild_stage_grid()

func _rebuild_stage_grid() -> void:
	frontier_arrow = null
	for c in grid_container.get_children():
		c.queue_free()

	var total_stars := SaveManager.get_world1_total_stars()
	lbl_stars_total.text = "%d/60" % total_stars
	btn_unlock_toggle.text = "MODE PROGRES" if SaveManager.unlock_all_preview else "BUKA SEMUA"

	var frontier_id := "1-1"
	for s in range(1, 21):
		var sid := "1-%d" % s
		if SaveManager.is_stage_unlocked(sid):
			frontier_id = sid
			if SaveManager.get_stage_stars(sid) == 0:
				break
	default_preview_sid = frontier_id
	if btn_play_selected:
		btn_play_selected.text = "▶ MAIN %s" % frontier_id
	_set_preview_stage(default_preview_sid)

	# Centered 5x4 Hanging Wood Stage Grid (Tanpa Kolom FASE)
	for r_idx in 4:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 22)
		grid_container.add_child(row)

		var s_start := r_idx * 5 + 1
		var s_end := s_start + 4
		for s in range(s_start, s_end + 1):
			var sid := "1-%d" % s
			var unlocked: bool = SaveManager.is_stage_unlocked(sid)
			var stars: int = SaveManager.get_stage_stars(sid)
			var is_boss: bool = (s == 20)
			var is_frontier: bool = unlocked and (sid == frontier_id)
			row.add_child(_make_stage_tile(s, sid, unlocked, stars, is_frontier, is_boss))

func _make_stage_tile(stage_num: int, sid: String, unlocked: bool, stars: int, is_frontier: bool, is_boss: bool) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(146, 86)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pivot_offset = Vector2(73, 43)
	btn.disabled = not unlocked
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	var tex_name := "tile_wood_open"
	var tilt := -1.5 if (stage_num % 2 == 1) else 1.3
	if not unlocked:
		tex_name = "tile_wood_locked"
	elif is_boss:
		tex_name = "tile_wood_boss"
		tilt = 1.8
	elif is_frontier:
		tex_name = "tile_wood_frontier"
		tilt = 0.0
		btn.scale = Vector2(1.06, 1.06)

	var normal := CraftUI.make_full_style(tex_name, 8.0, 4.0)
	var hover := CraftUI.make_full_style(tex_name, 8.0, 4.0, Color(1.08, 1.06, 1.03))
	var pressed := CraftUI.make_full_style(tex_name, 8.0, 6.0, Color(0.86, 0.82, 0.78))
	var disabled_sb := CraftUI.make_full_style(tex_name, 8.0, 4.0)
	var empty := StyleBoxEmpty.new()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_stylebox_override("focus", empty)
	btn.rotation_degrees = tilt
	wrap.add_child(btn)

	# Content VBox inside Stage Tile (Stage code "1-X" + Stars / Padlock / Boss Crown)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	if is_boss:
		var top_hb := HBoxContainer.new()
		top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		top_hb.add_theme_constant_override("separation", 4)
		top_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(top_hb)

		var cr := TextureRect.new()
		cr.texture = CraftUI.tex("icon_crown")
		cr.custom_minimum_size = Vector2(22, 22)
		cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_hb.add_child(cr)

		var lbl_b := CraftUI.make_stroked_label(sid, 23, CraftUI.GOLD_TEXT, 5, true)
		lbl_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_hb.add_child(lbl_b)

		var lbl_sub := CraftUI.make_stroked_label("BOSS", 14, CraftUI.CREAM_TEXT, 4, true)
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lbl_sub)
	else:
		var num_col := CraftUI.CREAM_TEXT if unlocked else Color(0.84, 0.88, 0.92)
		var lbl_num := CraftUI.make_stroked_label(sid, 24, num_col, 5, true)
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lbl_num)

		if not unlocked:
			var lk_wrap := CenterContainer.new()
			lk_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(lk_wrap)

			var lk := TextureRect.new()
			lk.texture = CraftUI.tex("icon_padlock")
			lk.custom_minimum_size = Vector2(24, 24)
			lk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lk_wrap.add_child(lk)
		else:
			var star_hb := HBoxContainer.new()
			star_hb.alignment = BoxContainer.ALIGNMENT_CENTER
			star_hb.add_theme_constant_override("separation", 3)
			star_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(star_hb)

			for k in 3:
				var s_ic := TextureRect.new()
				s_ic.texture = CraftUI.tex("icon_star_gold" if k < stars else "icon_star_empty")
				s_ic.custom_minimum_size = Vector2(20, 20)
				s_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				s_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				s_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
				star_hb.add_child(s_ic)

	# Bouncing Red Comic Pointer Arrow above Active Frontier Stage (Zero pill!)
	if is_frontier and not is_boss:
		var arrow := CraftUI.make_tex_rect(CraftUI.tex("icon_arrow_down_red"), Vector2(30, 26))
		arrow.position = Vector2(58, -22)
		wrap.add_child(arrow)
		frontier_arrow = arrow

	var stage_id_cap := sid
	var base_sc := btn.scale
	btn.mouse_entered.connect(func():
		_set_preview_stage(stage_id_cap)
		if unlocked:
			btn.scale = base_sc * 1.06
	)
	btn.mouse_exited.connect(func():
		btn.scale = base_sc
		_set_preview_stage(default_preview_sid)
	)
	btn.pressed.connect(func():
		SaveManager.selected_stage_id = stage_id_cap
		SceneLoader.transition_to(RUNNER_SCENE, "MEMUAT STAGE %s" % stage_id_cap, "", 0.56)
	)
	return wrap

func _set_preview_stage(sid: String) -> void:
	if not is_instance_valid(lbl_preview):
		return
	var title: String = str(stage_meta.get(sid, sid))
	var best: int = SaveManager.get_stage_best_score(sid)
	var unlocked: bool = SaveManager.is_stage_unlocked(sid)
	if not unlocked:
		lbl_preview.text = "%s • %s (TERKUNCI)" % [sid, title.to_upper()]
	elif best > 0:
		lbl_preview.text = "%s • %s (REKOR: %s)" % [sid, title.to_upper(), CraftUI.format_score(best)]
	else:
		lbl_preview.text = "%s • %s" % [sid, title.to_upper()]

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

	if is_instance_valid(frontier_arrow):
		frontier_arrow.position.y = frontier_arrow_base_y + sin(elapsed * 5.5) * 4.5

	if capture_path != "" and not capture_done and elapsed > 0.35:
		capture_done = true
		var img := get_viewport().get_texture().get_image()
		img.save_png(capture_path)
		get_tree().quit()

func _go_world_map() -> void:
	SceneLoader.quick_transition_to(WORLD_MAP_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_px = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_go_world_map()
