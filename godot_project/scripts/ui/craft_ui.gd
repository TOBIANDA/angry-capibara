class_name CraftUI
extends RefCounted

# Shared Hand-Crafted Bamboo Woodblock & Flat-Cel Comic Cutout UI Kit
# Fonts: SIL Open Font License 1.1 (TitanOne-Regular.ttf + Sniglet-ExtraBold.ttf)
# Zero web pills, zero soft gradients, zero dashboard cards.

const INK := Color(0.149, 0.067, 0.031, 1.0) # #261108
const CREAM_TEXT := Color(1.0, 0.992, 0.969, 1.0) # #FFFDF7
const GOLD_TEXT := Color(1.0, 0.902, 0.349, 1.0) # #FFE659
const BACK_BTN_SIZE := Vector2(142.0, 48.0)
const TOP_BAR_MARGIN_X := 32
const TOP_BAR_MARGIN_TOP := 18
const CONFIRM_LAYER_NAME := "CraftConfirmLayer"

class ConfirmModalInput extends Control:
	var on_cancel: Callable
	var on_confirm: Callable

	func _input(event: InputEvent) -> void:
		if not visible:
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				if on_cancel.is_valid():
					on_cancel.call()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if on_confirm.is_valid():
					on_confirm.call()

static var _disp_font: Font = null
static var _body_font: Font = null
static var _tex_cache: Dictionary = {}

static func display_font() -> Font:
	if _disp_font == null:
		var path := "res://assets/fonts/TitanOne-Regular.ttf"
		if ResourceLoader.exists(path):
			_disp_font = load(path)
		else:
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["Arial Black", "Impact"])
			sf.font_weight = 900
			_disp_font = sf
	return _disp_font

static func body_font() -> Font:
	if _body_font == null:
		var path := "res://assets/fonts/Sniglet-ExtraBold.ttf"
		if ResourceLoader.exists(path):
			_body_font = load(path)
		else:
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["Arial Black", "Segoe UI", "Arial"])
			sf.font_weight = 800
			_body_font = sf
	return _body_font

static func tex(asset_name: String) -> Texture2D:
	if _tex_cache.has(asset_name):
		return _tex_cache[asset_name]
	var path := "res://assets/ui/craft/%s.png" % asset_name
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[asset_name] = t
	return t

static func make_full_style(tex_name: String, pad_x: float = 10.0, pad_y: float = 6.0, mod: Color = Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(tex_name)
	sb.texture_margin_left = 0
	sb.texture_margin_right = 0
	sb.texture_margin_top = 0
	sb.texture_margin_bottom = 0
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y + 4.0
	sb.modulate_color = mod
	return sb

static func style_wood_button(
	btn: Button,
	tex_name: String,
	font_size: int,
	min_sz: Vector2,
	tilt_deg: float = 0.0,
	use_display: bool = true,
	text_color: Color = CREAM_TEXT,
	outline_sz: int = 5
) -> void:
	btn.custom_minimum_size = min_sz
	btn.pivot_offset = min_sz * 0.5
	btn.rotation_degrees = tilt_deg
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", display_font() if use_display else body_font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.96))
	btn.add_theme_color_override("font_pressed_color", Color(0.96, 0.92, 0.84))
	btn.add_theme_color_override("font_outline_color", INK)
	btn.add_theme_constant_override("outline_size", outline_sz)

	var normal := make_full_style(tex_name, 14.0, 6.0, Color.WHITE)
	var hover := make_full_style(tex_name, 14.0, 6.0, Color(1.08, 1.06, 1.03))
	var pressed := make_full_style(tex_name, 14.0, 8.0, Color(0.86, 0.82, 0.78))
	var empty := StyleBoxEmpty.new()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", empty)

	if not btn.has_meta("craft_hover_bound"):
		btn.set_meta("craft_hover_bound", true)
		btn.mouse_entered.connect(func():
			btn.pivot_offset = btn.size * 0.5
			btn.scale = Vector2(1.05, 1.05)
		)
		btn.mouse_exited.connect(func():
			btn.scale = Vector2.ONE
		)

	if not btn.has_meta("craft_sfx_bound"):
		btn.set_meta("craft_sfx_bound", true)
		btn.pressed.connect(func():
			if btn.get_tree() and btn.get_tree().root:
				var sm := btn.get_tree().root.get_node_or_null("SoundManager")
				if sm and sm.has_method("play_ui_click"):
					sm.play_ui_click()
		)

static func make_wood_btn(
	text_str: String,
	tex_name: String,
	min_sz: Vector2,
	font_size: int = 22,
	tilt_deg: float = 0.0,
	icon_name: String = "",
	icon_sz: int = 24
) -> Button:
	var btn := Button.new()
	btn.text = text_str
	style_wood_button(btn, tex_name, font_size, min_sz, tilt_deg, true, CREAM_TEXT, 5)
	if icon_name != "":
		var t := tex(icon_name)
		if t:
			btn.icon = t
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", icon_sz)
			btn.add_theme_constant_override("h_separation", 8)
	return btn

static func make_tex_rect(
	tex_obj: Texture2D,
	sz: Vector2,
	stretch: int = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
) -> TextureRect:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = stretch
	tr.custom_minimum_size = sz
	tr.size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex_obj != null:
		tr.texture = tex_obj
	return tr

static func make_icon_stamp(
	icon_name: String,
	sq_tex_name: String,
	sz: Vector2 = Vector2(52, 50),
	tilt_deg: float = 0.0,
	corner_key: String = ""
) -> Button:
	var btn := Button.new()
	btn.text = ""
	style_wood_button(btn, sq_tex_name, 14, sz, tilt_deg, true, CREAM_TEXT, 3)

	var isz := minf(sz.x, sz.y) * 0.54
	var ic := make_tex_rect(tex(icon_name), Vector2(isz, isz))
	ic.set_anchors_preset(Control.PRESET_CENTER)
	ic.offset_left = -isz * 0.5
	ic.offset_right = isz * 0.5
	ic.offset_top = -isz * 0.5 - 2.0
	ic.offset_bottom = isz * 0.5 - 2.0
	btn.add_child(ic)
	btn.set_meta("icon_rect", ic)

	if corner_key != "":
		var kl := make_stroked_label(corner_key, 10, GOLD_TEXT, 3, true)
		kl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		kl.offset_left = -18
		kl.offset_right = -5
		kl.offset_top = -17
		kl.offset_bottom = -3
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(kl)

	return btn

static func make_stroked_label(
	text_str: String,
	font_size: int,
	color: Color = GOLD_TEXT,
	outline_sz: int = 6,
	use_display: bool = true
) -> Label:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_font_override("font", display_font() if use_display else body_font())
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", INK)
	lbl.add_theme_color_override("font_shadow_color", INK)
	lbl.add_theme_constant_override("outline_size", outline_sz)
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", maxi(2, int(round(outline_sz * 0.45))))
	return lbl

static func make_star_counter(text_str: String, star_sz: float = 30.0, font_size: int = 24) -> Dictionary:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_END
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var st := make_tex_rect(tex("icon_star_gold"), Vector2(star_sz, star_sz))
	hb.add_child(st)

	var lbl := make_stroked_label(text_str, font_size, GOLD_TEXT, 6, true)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(lbl)
	return { "root": hb, "label": lbl }

static func make_keycap(key_txt: String, min_w: float = 36.0, h: float = 30.0, font_size: int = 12) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(min_w, h)
	var sb := StyleBoxTexture.new()
	sb.texture = tex("icon_keycap")
	sb.texture_margin_left = 0
	sb.texture_margin_right = 0
	sb.texture_margin_top = 0
	sb.texture_margin_bottom = 0
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lb := Label.new()
	lb.text = key_txt
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.add_theme_font_override("font", display_font())
	lb.add_theme_font_size_override("font_size", font_size)
	lb.add_theme_color_override("font_color", INK)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(lb)
	return pc

static func make_modal_panel_style(pad_x: float = 54.0, pad_y: float = 44.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex("wood_panel_modal")
	sb.texture_margin_left = 36
	sb.texture_margin_right = 36
	sb.texture_margin_top = 36
	sb.texture_margin_bottom = 40
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y + 4.0
	return sb

static func make_back_btn(label_text: String) -> Button:
	var btn := make_wood_btn("◀ " + label_text, "wood_btn_bamboo", BACK_BTN_SIZE, 19, -1.4)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return btn

static func make_volume_slider(initial_val: float = 100.0, width: float = 240.0) -> HSlider:
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 100.0
	sl.step = 5.0
	sl.value = initial_val
	sl.custom_minimum_size = Vector2(width, 28)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl_track := StyleBoxFlat.new()
	sl_track.bg_color = INK
	sl_track.set_corner_radius_all(6)
	sl_track.content_margin_top = 6
	sl_track.content_margin_bottom = 6
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = Color(0.34, 0.79, 0.20)
	sl_fill.set_corner_radius_all(6)
	sl.add_theme_stylebox_override("slider", sl_track)
	sl.add_theme_stylebox_override("grabber_area", sl_fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	var grab_tex := tex("wood_sq_amber")
	if grab_tex:
		var g_img := grab_tex.get_image()
		g_img.resize(26, 26, Image.INTERPOLATE_LANCZOS)
		var small_grab := ImageTexture.create_from_image(g_img)
		sl.add_theme_icon_override("grabber", small_grab)
		sl.add_theme_icon_override("grabber_highlight", small_grab)
	return sl

static func is_confirm_open(tree: SceneTree) -> bool:
	return tree != null and tree.root != null and tree.root.has_node(CONFIRM_LAYER_NAME)

static func show_confirm_modal(
	tree: SceneTree,
	title_str: String,
	body_str: String,
	confirm_label: String,
	on_confirm: Callable,
	cancel_label: String = "BATAL",
	pause_while_open: bool = false
) -> void:
	if tree == null or tree.root == null or is_confirm_open(tree):
		return

	var was_paused := tree.paused
	if pause_while_open:
		tree.paused = true

	var layer := CanvasLayer.new()
	layer.name = CONFIRM_LAYER_NAME
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.03, 0.02, 0.74)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(backdrop)

	var catcher := ConfirmModalInput.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(catcher)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 290)
	panel.pivot_offset = Vector2(270, 145)
	panel.scale = Vector2(0.88, 0.88)
	panel.add_theme_stylebox_override("panel", make_modal_panel_style(54.0, 44.0))
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var lbl_title := make_stroked_label(title_str, 26, GOLD_TEXT, 6, true)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lbl_title)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = Color(0.62, 0.37, 0.14, 0.35)
	vb.add_child(sep)

	var lbl_body := Label.new()
	lbl_body.text = body_str
	lbl_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_body.custom_minimum_size = Vector2(430, 0)
	lbl_body.add_theme_font_override("font", body_font())
	lbl_body.add_theme_font_size_override("font_size", 15)
	lbl_body.add_theme_color_override("font_color", INK)
	vb.add_child(lbl_body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vb.add_child(btn_row)

	var btn_cancel := make_wood_btn(cancel_label, "wood_btn_bamboo", Vector2(166, 48), 18, -0.8)
	var btn_ok := make_wood_btn(confirm_label, "wood_btn_vermilion", Vector2(188, 48), 18, 0.8)
	btn_row.add_child(btn_cancel)
	btn_row.add_child(btn_ok)

	var do_cancel := func():
		if is_instance_valid(layer):
			if layer.get_parent():
				layer.get_parent().remove_child(layer)
			layer.queue_free()
		if tree:
			tree.paused = was_paused

	var do_confirm := func():
		if is_instance_valid(layer):
			if layer.get_parent():
				layer.get_parent().remove_child(layer)
			layer.queue_free()
		if tree:
			tree.paused = was_paused
		if on_confirm.is_valid():
			on_confirm.call()

	btn_cancel.pressed.connect(do_cancel)
	btn_ok.pressed.connect(do_confirm)
	catcher.on_cancel = do_cancel
	catcher.on_confirm = do_confirm

	var tw := layer.create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func format_score(val: int) -> String:
	var raw := "%05d" % maxi(0, val)
	if raw.length() <= 3:
		return raw
	var parts: Array[String] = []
	var idx := raw.length()
	while idx > 0:
		var start := maxi(0, idx - 3)
		parts.push_front(raw.substr(start, idx - start))
		idx = start
	return ",".join(parts)
