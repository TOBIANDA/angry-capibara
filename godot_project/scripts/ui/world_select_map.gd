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
	var all_unlocked: bool = false

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
				draw_line(a, b, Color(0.149, 0.067, 0.031, 0.72), 8.0, true)
				var col := Color(1.0, 0.84, 0.27, 0.96) if (i == 0 or all_unlocked) else Color(0.84, 0.80, 0.71, 0.80)
				draw_line(a, b, col, 4.0, true)

	func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
		var u: float = 1.0 - t
		return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

var bg_layers: Array[Dictionary] = []
var sunburst_node: TextureRect
var clouds_node: TextureRect
var island_nodes: Array[Dictionary] = []
var world_info_overlay: ColorRect
var info_title_lbl: Label
var info_body_lbl: Label

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.substr(10)
		elif arg == "--unlock-all":
			SaveManager.unlock_all_preview = true

	clip_contents = true
	_setup_parallax_bg()
	_setup_journey_and_islands()
	_setup_top_bar()
	_setup_world_info_modal()

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

	# Light atmospheric tint keeping sky sunny & clear
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.10, 0.08, 0.06, 0.08)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _setup_journey_and_islands() -> void:
	var path_layer := JourneyPathOverlay.new()
	path_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.all_unlocked = SaveManager.unlock_all_preview
	for w in WORLDS:
		path_layer.points_list.append(w["pos"])
	add_child(path_layer)

	var w1_stars: int = SaveManager.get_world1_total_stars()
	var short_names := {
		1: "1. LEMBAH ONSEN BAMBU",
		2: "2. KEBUN YUZU",
		3: "3. GUA KRISTAL ES",
		4: "4. ISTANA RAJA BUAYA"
	}

	for w in WORLDS:
		var wid: int = int(w["id"])
		var has_levels: bool = SaveManager.world_has_levels(wid)
		var unlocked: bool = bool(w["unlocked"]) or SaveManager.unlock_all_preview
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
			tex_rect.modulate = Color(0.76, 0.74, 0.78, 0.94)
		island_btn.add_child(tex_rect)

		# Crown floating above World 4 Castle
		if wid == 4:
			var crown_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_crown"), Vector2(36, 36))
			crown_ic.position = Vector2(122.0, 8.0)
			holder.add_child(crown_ic)

		if unlocked:
			if wid == 1:
				# Floating Red Pennant Flag with Chill Capi Emblem above World 1
				var flag_wrap := Control.new()
				flag_wrap.position = Vector2(158.0, -14.0)
				flag_wrap.size = Vector2(76.0, 62.0)
				flag_wrap.rotation_degrees = 4.0
				flag_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
				holder.add_child(flag_wrap)

				var flag_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_flag_pennant"), Vector2(76, 62))
				flag_ic.set_anchors_preset(Control.PRESET_FULL_RECT)
				flag_wrap.add_child(flag_ic)

				var flag_hero := CraftUI.make_tex_rect(load("res://assets/generated/home2d/char_01_chill_roar.png"), Vector2(28, 28))
				flag_hero.position = Vector2(23.0, 15.0)
				flag_wrap.add_child(flag_hero)

			# Compact Hanging Cedar Wood Nameplate
			var sign_panel := PanelContainer.new()
			sign_panel.position = Vector2(8.0, 232.0)
			sign_panel.size = Vector2(264.0, 74.0)
			sign_panel.pivot_offset = Vector2(132.0, 37.0)
			sign_panel.rotation_degrees = -1.2 if (wid % 2 == 1) else 1.2
			sign_panel.add_theme_stylebox_override("panel", CraftUI.make_full_style("wood_btn_cedar", 14.0, 8.0))
			sign_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(sign_panel)

			var s_vb := VBoxContainer.new()
			s_vb.alignment = BoxContainer.ALIGNMENT_CENTER
			s_vb.add_theme_constant_override("separation", 1)
			sign_panel.add_child(s_vb)

			var name_lbl := CraftUI.make_stroked_label(str(short_names.get(wid, w["title"])), 14, CraftUI.CREAM_TEXT, 4, true)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_vb.add_child(name_lbl)

			var star_row := HBoxContainer.new()
			star_row.alignment = BoxContainer.ALIGNMENT_CENTER
			star_row.add_theme_constant_override("separation", 4)
			s_vb.add_child(star_row)

			var st_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_star_gold"), Vector2(16, 16))
			star_row.add_child(st_ic)

			var st_val := w1_stars if wid == 1 else 0
			var st_lbl := CraftUI.make_stroked_label("%d / 60" % st_val, 13, CraftUI.GOLD_TEXT, 3, true)
			star_row.add_child(st_lbl)

			# Action Stamp (MASUK if level JSON exists, CEK WORLD if preview-unlocked without JSON)
			var cta_txt := "MASUK ▶" if has_levels else "CEK WORLD ▶"
			var cta_tex := "wood_btn_vermilion" if has_levels else "wood_btn_amber"
			var cta := CraftUI.make_wood_btn(cta_txt, cta_tex, Vector2(164, 52), 19, 1.6)
			cta.position = Vector2(58.0, 310.0)
			cta.size = Vector2(164.0, 52.0)

			var wid_cap := wid
			var wtitle_cap := str(w["title"])
			var on_select := func():
				if has_levels:
					_enter_world1()
				else:
					_show_missing_world_modal(wid_cap, wtitle_cap)
			cta.pressed.connect(on_select)
			island_btn.pressed.connect(on_select)
			holder.add_child(cta)

			island_btn.mouse_entered.connect(func():
				island_btn.scale = Vector2(1.06, 1.06)
			)
			island_btn.mouse_exited.connect(func():
				island_btn.scale = Vector2.ONE
			)
		else:
			# Chunky Cartoon Brass Padlock over locked island
			var lock_ic := CraftUI.make_tex_rect(CraftUI.tex("icon_padlock"), Vector2(40, 40))
			lock_ic.position = Vector2(120.0, 96.0)
			holder.add_child(lock_ic)

			var locked_lbl := CraftUI.make_stroked_label(str(short_names.get(wid, w["title"])), 18, Color(0.92, 0.88, 0.78), 5, true)
			locked_lbl.position = Vector2(0.0, 224.0)
			locked_lbl.size = Vector2(280.0, 34.0)
			locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(locked_lbl)

		island_nodes.append({
			"node": holder,
			"base_pos": holder.position,
			"phase": float(w["phase"])
		})

func _setup_top_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_bottom = 86
	margin.add_theme_constant_override("margin_left", CraftUI.TOP_BAR_MARGIN_X)
	margin.add_theme_constant_override("margin_right", CraftUI.TOP_BAR_MARGIN_X)
	margin.add_theme_constant_override("margin_top", CraftUI.TOP_BAR_MARGIN_TOP)
	add_child(margin)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	margin.add_child(hdr)

	var btn_home := CraftUI.make_back_btn("HOME")
	btn_home.pressed.connect(_go_home)
	hdr.add_child(btn_home)

	var lbl_title := CraftUI.make_stroked_label("KEPULAUAN KAPIBARA", 34, CraftUI.GOLD_TEXT, 7, true)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_title)

	var sc := CraftUI.make_star_counter("%d/240" % SaveManager.get_world1_total_stars(), 30.0, 24)
	var sc_root: Control = sc["root"]
	sc_root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr.add_child(sc_root)

func _setup_world_info_modal() -> void:
	world_info_overlay = ColorRect.new()
	world_info_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_info_overlay.color = Color(0.06, 0.04, 0.03, 0.72)
	world_info_overlay.visible = false
	add_child(world_info_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -155
	panel.offset_bottom = 155
	panel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style())
	world_info_overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	info_title_lbl = CraftUI.make_stroked_label("WORLD 2", 24, CraftUI.GOLD_TEXT, 5, true)
	info_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info_title_lbl)

	info_body_lbl = Label.new()
	info_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_body_lbl.add_theme_font_override("font", CraftUI.body_font())
	info_body_lbl.add_theme_font_size_override("font_size", 15)
	info_body_lbl.add_theme_color_override("font_color", CraftUI.INK)
	vb.add_child(info_body_lbl)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	vb.add_child(btns)

	var btn_w1 := CraftUI.make_wood_btn("MAIN WORLD 1", "wood_btn_vermilion", Vector2(186, 46), 17, -0.8)
	btn_w1.pressed.connect(func():
		world_info_overlay.visible = false
		_enter_world1()
	)
	btns.add_child(btn_w1)

	var btn_ok := CraftUI.make_wood_btn("TUTUP", "wood_btn_bamboo", Vector2(140, 46), 17, 0.8)
	btn_ok.pressed.connect(func(): world_info_overlay.visible = false)
	btns.add_child(btn_ok)

func _show_missing_world_modal(wid: int, wtitle: String) -> void:
	if is_instance_valid(info_title_lbl):
		info_title_lbl.text = "WORLD %d • %s" % [wid, wtitle.to_upper()]
	if is_instance_valid(info_body_lbl):
		info_body_lbl.text = "Mode 'Semua Terbuka' aktif! Namun folder data level (data/levels/w%d/) belum dibuat.\nSaat ini baru World 1 (20 Stage: 1-1 s/d 1-20) yang memiliki file level JSON." % wid
	if is_instance_valid(world_info_overlay):
		world_info_overlay.visible = true

func _go_home() -> void:
	SceneLoader.quick_transition_to(HOME_SCENE)

func _enter_world1() -> void:
	SceneLoader.quick_transition_to(WORLD1_SELECT_SCENE)

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
			if is_instance_valid(world_info_overlay) and world_info_overlay.visible:
				world_info_overlay.visible = false
			else:
				_go_home()
