extends CanvasLayer

# Smart Hybrid Scene Transition & Loading Manager:
# - Menu <-> Menu (Home, Settings, Guide, Hero, World Maps): snappy 0.23s quick fade (no loading lag)
# - Startup Intro & Entering 3D Gameplay/Sandbox: compact warm Golden-Dusk Leapfrog 3-Capybara loader + gameplay tip

const STEP_DUR := 0.56
const INTRO_HOLD_DUR := 1.05
const FADE_IN_DUR := 0.12
const FADE_OUT_DUR := 0.20

const CAPY_TEX_PATHS := [
	"res://assets/generated/home2d/char_01_chill_roar.png",
	"res://assets/generated/home2d/char_06_dash_leap.png",
	"res://assets/generated/home2d/char_07_mini_capi.png"
]

const GAMEPLAY_TIPS := [
	"Tips: Tekan SPASI di udara untuk mengaktifkan jurus spesial Kapibara!",
	"Tips: Bidik Tong Yuzu TNT untuk memicu ledakan berantai!",
	"Tips: Tekan 1 / 2 / 3 saat bermain untuk ganti sudut kamera 2.5D & 3D!",
	"Tips: Gunakan tombol A / D untuk menggeser kamera mengintip benteng buaya!",
	"Tips: Dash Capi sangat kuat menghancurkan Kayu, Trio Mini efektif pada Es!"
]

class BambooLoadingBg extends Control:
	var capy_x: Array[float] = [505.0, 640.0, 775.0]
	var capy_h: Array[float] = [0.0, 0.0, 0.0]
	var base_y: float = 408.0
	var anim_t: float = 0.0

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var cy := h * 0.5
		base_y = cy + 48.0

		# 1. Warm dark cedar wood background (#22130B) + subtle grain bands
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.133, 0.075, 0.043, 1.0), true)
		var plank_col := Color(0.165, 0.094, 0.055, 0.45)
		var plank_edge := Color(0.082, 0.039, 0.016, 0.65)
		for i in range(6):
			var px := (w / 6.0) * float(i)
			if i % 2 == 1:
				draw_rect(Rect2(px, 0.0, w / 6.0, h), plank_col, true)
			draw_line(Vector2(px, 0.0), Vector2(px, h), plank_edge, 2.0)

		# 2. Warm Golden-Dusk Onsen radial sun glow behind the 3 capybaras
		var glow_c := Vector2(cx, cy - 18.0)
		var glow_rings := [
			[360.0, Color(0.32, 0.17, 0.07, 0.22)],
			[250.0, Color(0.48, 0.26, 0.09, 0.20)],
			[155.0, Color(0.76, 0.45, 0.14, 0.18)]
		]
		for gr in glow_rings:
			draw_circle(glow_c, float(gr[0]), gr[1])

		# 3. Subtle dark bamboo stalks framing left & right edges
		var stalks := [
			[38.0, 26.0, 0.0],
			[84.0, 18.0, 0.7],
			[w - 42.0, 28.0, 1.3],
			[w - 88.0, 18.0, 2.1]
		]
		for st in stalks:
			var sx := float(st[0])
			var sw := float(st[1])
			var sway := sin(anim_t * 1.3 + float(st[2])) * 3.5
			var dark_fill := Color(0.180, 0.110, 0.063, 0.94)
			var mid_fill := Color(0.231, 0.141, 0.082, 0.90)
			var ink := Color(0.082, 0.039, 0.016, 0.95)
			draw_rect(Rect2(sx - sw * 0.5 + sway, -10.0, sw, h + 20.0), dark_fill, true)
			draw_rect(Rect2(sx - sw * 0.25 + sway, -10.0, sw * 0.35, h + 20.0), mid_fill, true)
			draw_rect(Rect2(sx - sw * 0.5 + sway, -10.0, sw, h + 20.0), ink, false, 3.0)
			var y_node := 70.0
			while y_node < h:
				draw_line(Vector2(sx - sw * 0.58 + sway, y_node), Vector2(sx + sw * 0.58 + sway, y_node), ink, 5.0)
				draw_line(Vector2(sx - sw * 0.54 + sway, y_node - 2.0), Vector2(sx + sw * 0.54 + sway, y_node - 2.0), Color(0.28, 0.17, 0.10, 0.85), 2.0)
				y_node += 116.0

			var dir_x := 1.0 if sx < cx else -1.0
			for k in 2:
				var ly := 92.0 + float(k) * 140.0
				var tip := Vector2(sx + dir_x * 46.0 + sway, ly + sin(anim_t * 2.0 + float(k)) * 6.0)
				var base := Vector2(sx + sway, ly)
				var pts := PackedVector2Array([
					base,
					base + Vector2(dir_x * 22.0, -10.0),
					tip,
					base + Vector2(dir_x * 20.0, 8.0)
				])
				draw_colored_polygon(pts, Color(0.22, 0.15, 0.08, 0.86))

		# 4. Warm cedar wooden plank track under the 3 capybaras
		var track_w := 480.0
		var track_rect := Rect2(cx - track_w * 0.5, base_y - 2.0, track_w, 16.0)
		draw_rect(Rect2(track_rect.position + Vector2(0.0, 4.0), track_rect.size), Color(0.086, 0.043, 0.020, 1.0), true)
		draw_rect(track_rect, Color(0.290, 0.169, 0.086, 1.0), true)
		draw_rect(Rect2(track_rect.position + Vector2(4.0, 2.0), Vector2(track_w - 8.0, 4.0)), Color(0.41, 0.25, 0.13, 0.85), true)
		draw_rect(track_rect, Color(0.086, 0.043, 0.020, 1.0), false, 3.0)

		# 5. Dynamic oval landing shadows below each capybara
		for i in 3:
			var cur_x := capy_x[i] if i < capy_x.size() else cx
			var cur_h := maxf(capy_h[i] if i < capy_h.size() else 0.0, 0.0)
			var factor := clampf(1.0 - (cur_h / 220.0), 0.25, 1.0)
			var sh_r := 38.0 * factor
			var sh_alpha := 0.58 * factor
			draw_set_transform(Vector2(cur_x, base_y + 2.0), 0.0, Vector2(1.0, 0.30))
			draw_circle(Vector2.ZERO, sh_r, Color(0.06, 0.025, 0.01, sh_alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

var quick_fade_rect: ColorRect
var overlay_root: Control
var bg_ctrl: BambooLoadingBg
var capy_sprites: Array[TextureRect] = []
var lbl_title: Label
var lbl_subtitle: Label

var _base_title: String = "MEMUAT"
var _tip_idx: int = 0
var _anim_t: float = 0.0
var _active: bool = false
var _intro_played: bool = false
var _transitioning: bool = false
var _intro_mode: bool = false
var _intro_timer: float = 0.0
var _capture_loading_path: String = ""
var _capture_wait: float = 0.0
var _capture_done: bool = false
var _skip_intro_due_to_cli: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-loading="):
			_capture_loading_path = arg.substr(18)
		elif arg.begins_with("--capture") or arg.begins_with("--validate") or arg.begins_with("--open-modal"):
			_skip_intro_due_to_cli = true

	_build_overlay()

	if _capture_loading_path != "":
		_skip_intro_due_to_cli = false
		_intro_played = true
		_start_capture_mode()

func _build_overlay() -> void:
	quick_fade_rect = ColorRect.new()
	quick_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	quick_fade_rect.color = Color(0.133, 0.075, 0.043, 1.0)
	quick_fade_rect.modulate.a = 0.0
	quick_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_fade_rect.visible = false
	add_child(quick_fade_rect)

	overlay_root = Control.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_root.visible = false
	add_child(overlay_root)

	bg_ctrl = BambooLoadingBg.new()
	bg_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(bg_ctrl)

	capy_sprites.clear()
	for i in 3:
		var t_obj: Texture2D = load(CAPY_TEX_PATHS[i])
		var sp := CraftUI.make_tex_rect(t_obj, Vector2(118.0, 118.0))
		sp.pivot_offset = Vector2(59.0, 102.0)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_root.add_child(sp)
		capy_sprites.append(sp)

	var txt_box := VBoxContainer.new()
	txt_box.set_anchors_preset(Control.PRESET_CENTER)
	txt_box.offset_left = -380
	txt_box.offset_right = 380
	txt_box.offset_top = 86
	txt_box.offset_bottom = 196
	txt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	txt_box.add_theme_constant_override("separation", 6)
	txt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(txt_box)

	lbl_title = CraftUI.make_stroked_label("MEMUAT...", 32, CraftUI.GOLD_TEXT, 7, true)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt_box.add_child(lbl_title)

	lbl_subtitle = CraftUI.make_stroked_label(GAMEPLAY_TIPS[0], 16, CraftUI.CREAM_TEXT, 5, false)
	lbl_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	txt_box.add_child(lbl_subtitle)

func _start_capture_mode() -> void:
	_active = true
	_base_title = "MEMUAT STAGE 1-1"
	_anim_t = STEP_DUR * 0.44
	overlay_root.visible = true
	overlay_root.modulate.a = 1.0
	lbl_title.text = "MEMUAT STAGE 1-1.."
	lbl_subtitle.text = GAMEPLAY_TIPS[0]
	_update_leapfrog_pose()

func play_startup_intro() -> void:
	if _intro_played or _skip_intro_due_to_cli or _capture_loading_path != "":
		return
	_intro_played = true
	_intro_mode = true
	_intro_timer = 0.0
	_anim_t = 0.0
	_active = true
	_base_title = "ANGRY CAPIBARA"
	overlay_root.visible = true
	overlay_root.modulate.a = 1.0
	lbl_title.text = "ANGRY CAPIBARA.."
	lbl_subtitle.text = "Menyiapkan Lembah Onsen..."
	_update_leapfrog_pose()

func quick_transition_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false

	quick_fade_rect.visible = true
	quick_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	quick_fade_rect.modulate.a = 0.0

	var t_in := 0.0
	var dur_in := 0.10
	while t_in < dur_in:
		await get_tree().process_frame
		t_in += get_process_delta_time()
		quick_fade_rect.modulate.a = clampf(t_in / dur_in, 0.0, 1.0)
	quick_fade_rect.modulate.a = 1.0

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	var t_out := 0.0
	var dur_out := 0.13
	while t_out < dur_out:
		await get_tree().process_frame
		t_out += get_process_delta_time()
		quick_fade_rect.modulate.a = clampf(1.0 - (t_out / dur_out), 0.0, 1.0)

	quick_fade_rect.modulate.a = 0.0
	quick_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quick_fade_rect.visible = false
	_transitioning = false

func transition_to(scene_path: String, title_text: String = "MEMUAT", tip_text: String = "", min_dur: float = 0.56) -> void:
	if _transitioning:
		return
	_transitioning = true
	_intro_mode = false
	get_tree().paused = false

	_base_title = title_text.strip_edges().trim_suffix("...")
	var chosen_tip := tip_text
	if chosen_tip == "":
		chosen_tip = GAMEPLAY_TIPS[_tip_idx % GAMEPLAY_TIPS.size()]
		_tip_idx += 1

	_active = true
	_anim_t = 0.0
	overlay_root.visible = true
	overlay_root.modulate.a = 0.0
	lbl_title.text = _base_title + "."
	lbl_subtitle.text = chosen_tip
	_update_leapfrog_pose()

	var t_in := 0.0
	while t_in < FADE_IN_DUR:
		await get_tree().process_frame
		t_in += get_process_delta_time()
		overlay_root.modulate.a = clampf(t_in / FADE_IN_DUR, 0.0, 1.0)
	overlay_root.modulate.a = 1.0

	var hold := 0.0
	while hold < min_dur:
		await get_tree().process_frame
		hold += get_process_delta_time()

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	var t_out := 0.0
	while t_out < FADE_OUT_DUR:
		await get_tree().process_frame
		t_out += get_process_delta_time()
		overlay_root.modulate.a = clampf(1.0 - (t_out / FADE_OUT_DUR), 0.0, 1.0)

	_finish_overlay()
	_transitioning = false

func _finish_overlay() -> void:
	_active = false
	_intro_mode = false
	overlay_root.modulate.a = 0.0
	overlay_root.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _intro_mode or not _active:
		return
	var skip := false
	if event is InputEventMouseButton and event.pressed:
		skip = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			skip = true
	if skip:
		_intro_timer = INTRO_HOLD_DUR

func _process(delta: float) -> void:
	if not _active:
		return

	if _capture_loading_path != "":
		_capture_wait += delta
		_update_leapfrog_pose()
		if not _capture_done and _capture_wait > 0.22:
			_capture_done = true
			var img := get_viewport().get_texture().get_image()
			img.save_png(_capture_loading_path)
			get_tree().quit()
		return

	_anim_t += delta
	_update_leapfrog_pose()

	var dot_count := (int(floor(_anim_t * 3.5)) % 3) + 1
	lbl_title.text = _base_title + ".".repeat(dot_count)

	if _intro_mode:
		_intro_timer += delta
		if _intro_timer >= INTRO_HOLD_DUR:
			var out_u := (_intro_timer - INTRO_HOLD_DUR) / FADE_OUT_DUR
			if out_u >= 1.0:
				_finish_overlay()
			else:
				overlay_root.modulate.a = clampf(1.0 - out_u, 0.0, 1.0)

func _update_leapfrog_pose() -> void:
	var vp_sz := overlay_root.size
	if vp_sz.x <= 10.0 or vp_sz.y <= 10.0:
		vp_sz = Vector2(1280.0, 720.0)
	var cx := vp_sz.x * 0.5
	var cy := vp_sz.y * 0.5
	var slots := [cx - 135.0, cx, cx + 135.0]
	var base_y := cy + 48.0

	var cycle_idx := int(floor(_anim_t / STEP_DUR)) % 3
	var u := fmod(_anim_t, STEP_DUR) / STEP_DUR

	var orders := [
		[0, 1, 2],
		[1, 2, 0],
		[2, 0, 1]
	]
	var order: Array = orders[cycle_idx]
	var leaper_id: int = int(order[0])
	var mid_id: int = int(order[1])
	var right_id: int = int(order[2])

	var lx_t := smoothstep(0.06, 0.94, u)
	var lx := lerpf(slots[0], slots[2], lx_t)
	var arc_u := clampf((u - 0.06) / 0.88, 0.0, 1.0)
	var l_height := sin(arc_u * PI) * 142.0
	var ly := base_y - l_height
	var l_rot := sin(arc_u * PI) * 16.0
	var l_sx := 1.0
	var l_sy := 1.0
	if u < 0.12:
		var p := sin((u / 0.12) * PI)
		l_sx = 1.0 + p * 0.14
		l_sy = 1.0 - p * 0.14
	elif u > 0.88:
		var p := sin(((u - 0.88) / 0.12) * PI)
		l_sx = 1.0 + p * 0.16
		l_sy = 1.0 - p * 0.16
	else:
		var st := sin(arc_u * PI)
		l_sx = 1.0 - st * 0.06
		l_sy = 1.0 + st * 0.08
	_apply_capy_transform(leaper_id, lx, ly, l_height, l_rot, Vector2(l_sx, l_sy), 10)

	var su := clampf((u - 0.16) / 0.68, 0.0, 1.0)
	var su_smooth := smoothstep(0.0, 1.0, su)
	var hop_h := sin(su * PI) * 26.0
	var hop_rot := sin(su * PI) * -5.0
	var m_sx := 1.0 - sin(su * PI) * 0.04
	var m_sy := 1.0 + sin(su * PI) * 0.05

	var mx := lerpf(slots[1], slots[0], su_smooth)
	_apply_capy_transform(mid_id, mx, base_y - hop_h, hop_h, hop_rot, Vector2(m_sx, m_sy), 2)

	var rx := lerpf(slots[2], slots[1], su_smooth)
	_apply_capy_transform(right_id, rx, base_y - hop_h, hop_h, -hop_rot, Vector2(m_sx, m_sy), 2)

	if is_instance_valid(bg_ctrl):
		bg_ctrl.anim_t = _anim_t
		bg_ctrl.queue_redraw()

func _apply_capy_transform(cid: int, center_x: float, foot_y: float, height: float, rot_deg: float, sc: Vector2, z_ord: int) -> void:
	if cid < 0 or cid >= capy_sprites.size():
		return
	var sp: TextureRect = capy_sprites[cid]
	sp.position = Vector2(center_x - 59.0, foot_y - 104.0)
	sp.rotation_degrees = rot_deg
	sp.scale = sc
	sp.z_index = z_ord
	if is_instance_valid(bg_ctrl) and cid < bg_ctrl.capy_x.size():
		bg_ctrl.capy_x[cid] = center_x
		bg_ctrl.capy_h[cid] = height
