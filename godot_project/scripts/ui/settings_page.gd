extends Control

# Halaman Penuh Pengaturan Game (Audio, Tampilan Layar, Akses World/Stage, Keluar Game)

const HOME_SCENE := "res://scenes/ui/home_screen.tscn"
const BASE_SIZE := Vector2(1280.0, 720.0)

var bg_layers: Array[Dictionary] = []
var audio_icon_rect: TextureRect
var vol_slider: HSlider
var lbl_vol_pct: Label
var btn_mute: Button
var btn_display: Button
var btn_unlock: Button

var elapsed: float = 0.0
var mouse_px: Vector2 = Vector2.ZERO
var smooth_px: Vector2 = Vector2.ZERO
var capture_path: String = ""
var capture_confirm_path: String = ""
var capture_done: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-settings="):
			capture_path = arg.substr(19)
		elif arg.begins_with("--capture-confirm="):
			capture_confirm_path = arg.substr(18)

	clip_contents = true
	_setup_parallax_bg()
	_setup_ui()
	_sync_controls()

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

	var lbl_title := CraftUI.make_stroked_label("PENGATURAN GAME", 34, CraftUI.GOLD_TEXT, 7, true)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_title)

	var sc := CraftUI.make_star_counter("%d/240" % SaveManager.get_world1_total_stars(), 30.0, 24)
	var sc_root: Control = sc["root"]
	sc_root.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr.add_child(sc_root)

	# 2) Spacious Full-Page Woodblock Settings Panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 82
	center.offset_bottom = -20
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 500)
	panel.add_theme_stylebox_override("panel", CraftUI.make_modal_panel_style(60.0, 48.0))
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 24)
	panel.add_child(vb)

	# Row 1: Audio Suara
	var r_audio := HBoxContainer.new()
	r_audio.add_theme_constant_override("separation", 14)
	r_audio.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(r_audio)

	audio_icon_rect = CraftUI.make_tex_rect(CraftUI.tex("icon_speaker_on"), Vector2(34, 34))
	r_audio.add_child(audio_icon_rect)

	var lbl_a := Label.new()
	lbl_a.text = "Volume Suara"
	lbl_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_a.add_theme_font_override("font", CraftUI.body_font())
	lbl_a.add_theme_font_size_override("font_size", 18)
	lbl_a.add_theme_color_override("font_color", CraftUI.INK)
	r_audio.add_child(lbl_a)

	vol_slider = CraftUI.make_volume_slider(SaveManager.audio_volume, 250.0)
	vol_slider.value_changed.connect(func(v: float):
		SaveManager.set_audio_volume(v)
		_sync_controls()
	)
	r_audio.add_child(vol_slider)

	lbl_vol_pct = Label.new()
	lbl_vol_pct.text = "100%"
	lbl_vol_pct.custom_minimum_size = Vector2(58, 0)
	lbl_vol_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_vol_pct.add_theme_font_override("font", CraftUI.display_font())
	lbl_vol_pct.add_theme_font_size_override("font_size", 18)
	lbl_vol_pct.add_theme_color_override("font_color", CraftUI.INK)
	r_audio.add_child(lbl_vol_pct)

	btn_mute = CraftUI.make_wood_btn("AKTIF", "wood_btn_bamboo", Vector2(124, 44), 16, 0.0)
	btn_mute.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_mute.pressed.connect(func():
		SaveManager.toggle_mute()
		_sync_controls()
	)
	r_audio.add_child(btn_mute)

	# Row 2: Tampilan Layar
	var r_disp := HBoxContainer.new()
	r_disp.add_theme_constant_override("separation", 14)
	r_disp.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(r_disp)

	r_disp.add_child(CraftUI.make_tex_rect(CraftUI.tex("icon_gear"), Vector2(34, 34)))

	var disp_txt := VBoxContainer.new()
	disp_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disp_txt.add_theme_constant_override("separation", 2)
	r_disp.add_child(disp_txt)

	var lbl_d := Label.new()
	lbl_d.text = "Tampilan Layar"
	lbl_d.add_theme_font_override("font", CraftUI.body_font())
	lbl_d.add_theme_font_size_override("font_size", 18)
	lbl_d.add_theme_color_override("font_color", CraftUI.INK)
	disp_txt.add_child(lbl_d)

	var lbl_d_sub := Label.new()
	lbl_d_sub.text = "Pilih mode Jendela (1280×720) atau Layar Penuh untuk kenyamanan bermain."
	lbl_d_sub.add_theme_font_override("font", CraftUI.body_font())
	lbl_d_sub.add_theme_font_size_override("font_size", 13)
	lbl_d_sub.add_theme_color_override("font_color", Color(0.38, 0.22, 0.11))
	disp_txt.add_child(lbl_d_sub)

	btn_display = CraftUI.make_wood_btn("JENDELA", "wood_btn_cedar", Vector2(216, 46), 16, 0.0)
	btn_display.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_display.pressed.connect(func():
		SaveManager.toggle_fullscreen()
		_sync_controls()
	)
	r_disp.add_child(btn_display)

	# Row 3: Akses Stage & World
	var r_prog := HBoxContainer.new()
	r_prog.add_theme_constant_override("separation", 14)
	r_prog.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(r_prog)

	r_prog.add_child(CraftUI.make_tex_rect(CraftUI.tex("icon_star_gold"), Vector2(34, 34)))

	var prog_txt := VBoxContainer.new()
	prog_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_txt.add_theme_constant_override("separation", 2)
	r_prog.add_child(prog_txt)

	var lbl_p := Label.new()
	lbl_p.text = "Akses World & Stage (%d/60 ★)" % SaveManager.get_world1_total_stars()
	lbl_p.add_theme_font_override("font", CraftUI.body_font())
	lbl_p.add_theme_font_size_override("font_size", 18)
	lbl_p.add_theme_color_override("font_color", CraftUI.INK)
	prog_txt.add_child(lbl_p)

	var lbl_p_sub := Label.new()
	lbl_p_sub.text = "Mode 'Semua Terbuka' membuka seluruh Stage World 1 & preview World 2–4 di Peta."
	lbl_p_sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_p_sub.add_theme_font_override("font", CraftUI.body_font())
	lbl_p_sub.add_theme_font_size_override("font_size", 13)
	lbl_p_sub.add_theme_color_override("font_color", Color(0.38, 0.22, 0.11))
	prog_txt.add_child(lbl_p_sub)

	btn_unlock = CraftUI.make_wood_btn("MODE PROGRES", "wood_btn_amber", Vector2(216, 46), 16, 0.0)
	btn_unlock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_unlock.pressed.connect(func():
		SaveManager.unlock_all_preview = not SaveManager.unlock_all_preview
		_sync_controls()
	)
	r_prog.add_child(btn_unlock)

	# Divider
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = Color(0.62, 0.37, 0.14, 0.38)
	vb.add_child(sep)

	# Bottom Actions
	var m_btns := HBoxContainer.new()
	m_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	m_btns.add_theme_constant_override("separation", 22)
	vb.add_child(m_btns)

	var btn_quit := CraftUI.make_wood_btn("KELUAR GAME", "wood_btn_slate", Vector2(194, 48), 18, -0.8)
	btn_quit.pressed.connect(_confirm_quit_game)
	m_btns.add_child(btn_quit)

	var btn_done := CraftUI.make_wood_btn("KEMBALI KE HOME", "wood_btn_vermilion", Vector2(228, 50), 18, 0.8)
	btn_done.pressed.connect(_go_home)
	m_btns.add_child(btn_done)

func _sync_controls() -> void:
	if is_instance_valid(vol_slider) and absf(vol_slider.value - SaveManager.audio_volume) > 0.5:
		vol_slider.set_value_no_signal(SaveManager.audio_volume)
	if is_instance_valid(lbl_vol_pct):
		lbl_vol_pct.text = "%d%%" % int(round(SaveManager.audio_volume))
	if is_instance_valid(audio_icon_rect):
		audio_icon_rect.texture = CraftUI.tex("icon_speaker_off" if SaveManager.is_muted else "icon_speaker_on")
	if is_instance_valid(btn_mute):
		btn_mute.text = "BISU" if SaveManager.is_muted else "AKTIF"
		CraftUI.style_wood_button(btn_mute, "wood_btn_slate" if SaveManager.is_muted else "wood_btn_bamboo", 16, Vector2(124, 44), 0.0)
	if is_instance_valid(btn_display):
		btn_display.text = "LAYAR PENUH" if SaveManager.is_fullscreen() else "JENDELA"
	if is_instance_valid(btn_unlock):
		var all_open := SaveManager.unlock_all_preview
		btn_unlock.text = "SEMUA TERBUKA" if all_open else "MODE PROGRES"
		CraftUI.style_wood_button(btn_unlock, "wood_btn_bamboo" if all_open else "wood_btn_amber", 16, Vector2(216, 46), 0.0)

func _confirm_quit_game() -> void:
	CraftUI.show_confirm_modal(
		get_tree(),
		"KELUAR GAME?",
		"Progres bintang sudah tersimpan otomatis.\nYakin ingin menutup Angry Capibara?",
		"YA, KELUAR",
		func(): get_tree().quit(),
		"BATAL",
		false
	)

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
	elif capture_confirm_path != "" and not capture_done and elapsed > 0.35:
		capture_done = true
		_capture_confirm_async()

func _capture_confirm_async() -> void:
	_confirm_quit_game()
	await get_tree().create_timer(0.18).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(capture_confirm_path)
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if CraftUI.is_confirm_open(get_tree()):
		return
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		if vp.x > 0 and vp.y > 0:
			mouse_px = (event.position / vp - Vector2(0.5, 0.5)) * 2.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_go_home()
