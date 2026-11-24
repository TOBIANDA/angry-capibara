extends Control

# Peta Pemilihan 4 Pulau World (setara Planet Selection di Angry Birds Star Wars)
# Mengikuti palet Anti-Slop DESIGN.md (Warm Lacquer Espresso + Washi Gold + 1 Aksen Vermilion)

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const WORLD1_SELECT_SCENE := "res://scenes/ui/world1_select.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

const WORLDS := [
	{
		"id": 1,
		"badge": "WORLD 1",
		"title": "Lembah Onsen Bambu",
		"sub": "Bambu, Kayu & Es • 20 Stage",
		"tex": "res://assets/generated/home2d/world_island_01.png",
		"pos": Vector2(170.0, 355.0),
		"unlocked": true,
		"phase": 0.0
	},
	{
		"id": 2,
		"badge": "WORLD 2",
		"title": "Kebun Yuzu & Ngarai Turret",
		"sub": "Ngarai & Turret Buaya • 20 Stage",
		"tex": "res://assets/generated/home2d/world_island_02.png",
		"pos": Vector2(485.0, 270.0),
		"unlocked": false,
		"phase": 1.4
	},
	{
		"id": 3,
		"badge": "WORLD 3",
		"title": "Gua Kristal Es & Awan",
		"sub": "Kristal Pantul & Awan • 20 Stage",
		"tex": "res://assets/generated/home2d/world_island_03.png",
		"pos": Vector2(805.0, 355.0),
		"unlocked": false,
		"phase": 2.7
	},
	{
		"id": 4,
		"badge": "WORLD 4",
		"title": "Istana Inti Raja Buaya",
		"sub": "Low-G & Raja Buaya • 20 Stage",
		"tex": "res://assets/generated/home2d/world_island_04.png",
		"pos": Vector2(1110.0, 260.0),
		"unlocked": false,
		"phase": 4.1
	}
]

class JourneyPathOverlay extends Control:
	var points_list: Array[Vector2] = []

	func _draw() -> void:
		if points_list.size() < 2:
			return
		for i in range(points_list.size() - 1):
			var p0: Vector2 = points_list[i]
			var p3: Vector2 = points_list[i + 1]
			var mid_x: float = (p0.x + p3.x) * 0.5
			var arc_y: float = -48.0 if (i % 2 == 0) else 44.0
			var ctrl: Vector2 = Vector2(mid_x, (p0.y + p3.y) * 0.5 + arc_y)
			var segs := 18
			for s in range(segs):
				if s % 2 == 1:
					continue
				var t0: float = float(s) / float(segs)
				var t1: float = float(s + 1) / float(segs)
				var a: Vector2 = _quad_bezier(p0, ctrl, p3, t0)
				var b: Vector2 = _quad_bezier(p0, ctrl, p3, t1)
				draw_line(a, b, Color(0.16, 0.11, 0.08, 0.45), 6.0, true)
				var col := Color(0.98, 0.86, 0.48, 0.88) if i == 0 else Color(0.84, 0.76, 0.62, 0.52)
				draw_line(a, b, col, 3.0, true)

	func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
		var u: float = 1.0 - t
		return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

var bg_layers: Array[Dictionary] = []
var sunburst_node: TextureRect
var clouds_node: TextureRect
var island_nodes: Array[Dictionary] = []

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.substr(10)

	clip_contents = true
	_setup_parallax_bg()
	_setup_journey_and_islands()
	_setup_top_bar()

func _add_bg_tex(path: String, base_p: Vector2, sz: Vector2, depth: float, alpha: float = 1.0) -> TextureRect:
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
	return tr

func _setup_parallax_bg() -> void:
	_add_bg_tex("res://assets/generated/home2d/layer_00_sky_sun.png", Vector2.ZERO, BASE_SIZE, 0.06)
	sunburst_node = _add_bg_tex("res://assets/generated/home2d/layer_01_sunburst.png", Vector2.ZERO, BASE_SIZE, 0.10, 0.72)
	sunburst_node.pivot_offset = sunburst_node.size * 0.5
	clouds_node = _add_bg_tex("res://assets/generated/home2d/layer_02_clouds.png", Vector2(0.0, 24.0), Vector2(1280.0, 420.0), 0.16)
	_add_bg_tex("res://assets/generated/home2d/layer_03_mountains_far.png", Vector2(0.0, 80.0), BASE_SIZE, 0.24)

	# Warm atmospheric veil so islands and cards pop cleanly
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.12, 0.09, 0.07, 0.22)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_journey_and_islands() -> void:
	var path_layer := JourneyPathOverlay.new()
	path_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for w in WORLDS:
		path_layer.points_list.append(w["pos"])
	add_child(path_layer)

	var w1_stars: int = SaveManager.get_world1_total_stars()

	for w in WORLDS:
		var wid: int = int(w["id"])
		var unlocked: bool = bool(w["unlocked"])
		var center: Vector2 = w["pos"]

		var holder := Control.new()
		holder.position = center - Vector2(140.0, 145.0)
		holder.size = Vector2(280.0, 390.0)
		holder.pivot_offset = Vector2(140.0, 145.0)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)

		# Clickable island button
		var island_btn := Button.new()
		island_btn.position = Vector2(20.0, 0.0)
		island_btn.size = Vector2(240.0, 240.0)
		island_btn.pivot_offset = Vector2(120.0, 120.0)
		island_btn.flat = true
		island_btn.disabled = not unlocked
		island_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
		var empty_sb := StyleBoxEmpty.new()
		island_btn.add_theme_stylebox_override("normal", empty_sb)
		island_btn.add_theme_stylebox_override("hover", empty_sb)
		island_btn.add_theme_stylebox_override("pressed", empty_sb)
		island_btn.add_theme_stylebox_override("disabled", empty_sb)
		island_btn.add_theme_stylebox_override("focus", empty_sb)
		holder.add_child(island_btn)

		var tex_rect := TextureRect.new()
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex_path := str(w["tex"])
		if ResourceLoader.exists(tex_path):
			tex_rect.texture = load(tex_path)
		if not unlocked:
			tex_rect.modulate = Color(0.62, 0.60, 0.62, 0.84)
		island_btn.add_child(tex_rect)

		# Info Plaque below island
		var card := PanelContainer.new()
		card.position = Vector2(12.0, 238.0)
		card.size = Vector2(256.0, 146.0)
		var card_sb := StyleBoxFlat.new()
		if unlocked:
			card_sb.bg_color = Color(0.16, 0.11, 0.09, 0.95)
			card_sb.border_color = Color(0.95, 0.84, 0.50)
			card_sb.set_border_width_all(2)
			card_sb.border_width_bottom = 4
		else:
			card_sb.bg_color = Color(0.12, 0.10, 0.09, 0.84)
			card_sb.border_color = Color(0.48, 0.42, 0.36, 0.65)
			card_sb.set_border_width_all(2)
		card_sb.set_corner_radius_all(12)
		card_sb.shadow_color = Color(0.03, 0.02, 0.02, 0.55)
		card_sb.shadow_size = 6
		card_sb.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("panel", card_sb)
		holder.add_child(card)

		var mar := MarginContainer.new()
		mar.add_theme_constant_override("margin_left", 12)
		mar.add_theme_constant_override("margin_right", 12)
		mar.add_theme_constant_override("margin_top", 8)
		mar.add_theme_constant_override("margin_bottom", 9)
		card.add_child(mar)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		mar.add_child(vb)

		var top_r := HBoxContainer.new()
		vb.add_child(top_r)

		var pill := PanelContainer.new()
		var p_sb := StyleBoxFlat.new()
		p_sb.bg_color = Color(0.78, 0.21, 0.16) if unlocked else Color(0.20, 0.17, 0.15)
		p_sb.border_color = Color(0.98, 0.88, 0.62) if unlocked else Color(0.52, 0.46, 0.40)
		p_sb.set_border_width_all(1)
		p_sb.set_corner_radius_all(5)
		p_sb.content_margin_left = 7
		p_sb.content_margin_right = 7
		p_sb.content_margin_top = 1
		p_sb.content_margin_bottom = 1
		pill.add_theme_stylebox_override("panel", p_sb)
		top_r.add_child(pill)

		var pill_lbl := Label.new()
		pill_lbl.text = str(w["badge"])
		pill_lbl.add_theme_font_size_override("font_size", 10)
		pill_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86) if unlocked else Color(0.74, 0.68, 0.60))
		pill.add_child(pill_lbl)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_r.add_child(spacer)

		var star_lbl := Label.new()
		var stars_earned: int = w1_stars if wid == 1 else 0
		star_lbl.text = "★ %d / 60" % stars_earned
		star_lbl.add_theme_font_size_override("font_size", 12)
		star_lbl.add_theme_color_override("font_color", Color(0.98, 0.85, 0.42) if unlocked else Color(0.58, 0.52, 0.46))
		top_r.add_child(star_lbl)

		var title_lbl := Label.new()
		title_lbl.text = str(w["title"])
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88) if unlocked else Color(0.70, 0.65, 0.58))
		vb.add_child(title_lbl)

		var sub_lbl := Label.new()
		sub_lbl.text = str(w["sub"])
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 11)
		sub_lbl.add_theme_color_override("font_color", Color(0.84, 0.78, 0.66) if unlocked else Color(0.56, 0.51, 0.46))
		vb.add_child(sub_lbl)

		if unlocked:
			var cta := _make_btn("MASUK →", true, Vector2(0, 32), 13)
			cta.pressed.connect(_enter_world1)
			vb.add_child(cta)
			island_btn.pressed.connect(_enter_world1)
			island_btn.mouse_entered.connect(func():
				island_btn.scale = Vector2(1.06, 1.06)
			)
			island_btn.mouse_exited.connect(func():
				island_btn.scale = Vector2.ONE
			)
		else:
			var lock_panel := PanelContainer.new()
			var lk_sb := StyleBoxFlat.new()
			lk_sb.bg_color = Color(0.16, 0.13, 0.12, 0.85)
			lk_sb.border_color = Color(0.42, 0.37, 0.32, 0.60)
			lk_sb.set_border_width_all(1)
			lk_sb.set_corner_radius_all(7)
			lk_sb.content_margin_top = 4
			lk_sb.content_margin_bottom = 4
			lock_panel.add_theme_stylebox_override("panel", lk_sb)
			vb.add_child(lock_panel)

			var lk_lbl := Label.new()
			lk_lbl.text = "SEGERA HADIR"
			lk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lk_lbl.add_theme_font_size_override("font_size", 11)
			lk_lbl.add_theme_color_override("font_color", Color(0.66, 0.60, 0.52))
			lock_panel.add_child(lk_lbl)

		island_nodes.append({
			"node": holder,
			"base_pos": holder.position,
			"phase": float(w["phase"])
		})

func _setup_top_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_bottom = 86
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 18)
	add_child(margin)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	margin.add_child(hdr)

	var btn_home := _make_btn("← HOME", false, Vector2(110, 44), 14)
	btn_home.pressed.connect(func(): get_tree().change_scene_to_file(HOME_SCENE))
	hdr.add_child(btn_home)

	var title_vb := VBoxContainer.new()
	title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vb.add_theme_constant_override("separation", 1)
	hdr.add_child(title_vb)

	var lbl_title := Label.new()
	lbl_title.text = "PETA WILAYAH — KEPULAUAN KAPIBARA"
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88))
	lbl_title.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.08))
	lbl_title.add_theme_constant_override("outline_size", 4)
	title_vb.add_child(lbl_title)

	var lbl_sub := Label.new()
	lbl_sub.text = "Pilih Pulau Pertempuran • 4 Dunia (80 Stage)"
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	lbl_sub.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.07))
	lbl_sub.add_theme_constant_override("outline_size", 3)
	title_vb.add_child(lbl_sub)

	# Total Star Counter (★ X / 240)
	var total_stars: int = SaveManager.get_world1_total_stars()
	var star_panel := PanelContainer.new()
	var sp_st := StyleBoxFlat.new()
	sp_st.bg_color = Color(0.15, 0.11, 0.09, 0.96)
	sp_st.border_color = Color(0.90, 0.78, 0.48)
	sp_st.set_border_width_all(2)
	sp_st.border_width_bottom = 3
	sp_st.set_corner_radius_all(10)
	sp_st.shadow_color = Color(0.03, 0.02, 0.02, 0.55)
	sp_st.shadow_size = 5
	sp_st.shadow_offset = Vector2(0, 3)
	sp_st.content_margin_left = 16
	sp_st.content_margin_right = 16
	sp_st.content_margin_top = 6
	sp_st.content_margin_bottom = 6
	star_panel.add_theme_stylebox_override("panel", sp_st)
	hdr.add_child(star_panel)

	var sp_vb := VBoxContainer.new()
	sp_vb.add_theme_constant_override("separation", 3)
	star_panel.add_child(sp_vb)

	var lbl_total := Label.new()
	lbl_total.text = "★ %d / 240" % total_stars
	lbl_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_total.add_theme_font_size_override("font_size", 15)
	lbl_total.add_theme_color_override("font_color", Color(0.98, 0.85, 0.42))
	sp_vb.add_child(lbl_total)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(110, 5)
	bar.max_value = 240.0
	bar.value = float(total_stars)
	bar.show_percentage = false
	var b_bg := StyleBoxFlat.new()
	b_bg.bg_color = Color(0.08, 0.06, 0.05, 0.90)
	b_bg.set_corner_radius_all(3)
	var b_fill := StyleBoxFlat.new()
	b_fill.bg_color = Color(0.96, 0.80, 0.34)
	b_fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", b_bg)
	bar.add_theme_stylebox_override("fill", b_fill)
	sp_vb.add_child(bar)

func _make_btn(txt: String, is_primary: bool, min_sz: Vector2, fsize: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = min_sz
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", Color(0.98, 0.95, 0.89))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.94))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.80, 0.22, 0.16) if is_primary else Color(0.17, 0.13, 0.11, 0.95)
	sb.border_color = Color(0.98, 0.88, 0.64) if is_primary else Color(0.78, 0.69, 0.54, 0.85)
	sb.set_border_width_all(2)
	sb.border_width_bottom = 3
	sb.set_corner_radius_all(9)
	var hv: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	hv.bg_color = sb.bg_color.lightened(0.14)
	var pr: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	pr.bg_color = sb.bg_color.darkened(0.14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", pr)
	return b

func _enter_world1() -> void:
	get_tree().change_scene_to_file(WORLD1_SELECT_SCENE)

func _process(delta: float) -> void:
	elapsed += delta
	smooth_px = smooth_px.lerp(mouse_px, minf(delta * 5.0, 1.0))
	var off := Vector2(-smooth_px.x * 16.0, -smooth_px.y * 8.0)
	for lyr in bg_layers:
		var node: TextureRect = lyr["node"]
		var base_p: Vector2 = lyr["base"]
		var d: float = float(lyr["depth"])
		node.position = base_p + off * d
	if sunburst_node:
		sunburst_node.rotation = sin(elapsed * 0.18) * 0.035

	for isl in island_nodes:
		var nd: Control = isl["node"]
		var bp: Vector2 = isl["base_pos"]
		var ph: float = float(isl["phase"])
		nd.position = bp + Vector2(0.0, sin(elapsed * 1.45 + ph) * 5.5)

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
