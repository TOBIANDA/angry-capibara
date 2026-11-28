extends Node

# Audio & Sound Effects Manager (100% Offline Procedural Onsen & Cartoon SFX + BGM)
# Uses Master bus controlled by SaveManager (volume slider + mute).

const SFX_PATHS := {
	"ui_click": "res://assets/audio/sfx_ui_click.wav",
	"sling_stretch": "res://assets/audio/sfx_sling_stretch.wav",
	"launch": "res://assets/audio/sfx_launch.wav",
	"hit_bamboo": "res://assets/audio/sfx_hit_bamboo.wav",
	"hit_wood": "res://assets/audio/sfx_hit_wood.wav",
	"hit_ice": "res://assets/audio/sfx_hit_ice.wav",
	"hit_stone": "res://assets/audio/sfx_hit_stone.wav",
	"tnt_boom": "res://assets/audio/sfx_tnt_boom.wav",
	"croc_defeat": "res://assets/audio/sfx_croc_defeat.wav",
	"skill_zen": "res://assets/audio/sfx_skill_zen.wav",
	"skill_dash": "res://assets/audio/sfx_skill_dash.wav",
	"skill_split": "res://assets/audio/sfx_skill_split.wav",
	"bounce_pad": "res://assets/audio/sfx_bounce_pad.wav",
	"star_pop": "res://assets/audio/sfx_star_pop.wav",
	"victory": "res://assets/audio/sfx_victory.wav",
	"defeat": "res://assets/audio/sfx_defeat.wav"
}
const BGM_PATH := "res://assets/audio/bgm_onsen_loop.wav"

var _sfx_streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _is_headless_or_cli: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if DisplayServer.get_name() == "headless":
		_is_headless_or_cli = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture") or arg.begins_with("--validate"):
			_is_headless_or_cli = true
			break

	for key in SFX_PATHS.keys():
		var path: String = str(SFX_PATHS[key])
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)

	for _i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -14.0
	add_child(_bgm_player)

	if not _is_headless_or_cli and ResourceLoader.exists(BGM_PATH):
		var bgm := load(BGM_PATH)
		if bgm is AudioStreamWAV:
			var wav := bgm as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = maxi(1, int(wav.data.size() / 2))
		_bgm_player.stream = bgm
		_bgm_player.play()

func play_sfx(sfx_name: String, pitch_scale: float = 1.0, vol_db: float = 0.0, jitter: float = 0.0) -> void:
	if _is_headless_or_cli:
		return
	var stream: AudioStream = _sfx_streams.get(sfx_name, null)
	if stream == null:
		return

	var chosen: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			chosen = p
			break
	if chosen == null:
		chosen = _sfx_pool[0]

	var final_pitch := pitch_scale
	if jitter > 0.0:
		final_pitch *= randf_range(1.0 - jitter, 1.0 + jitter)

	chosen.stream = stream
	chosen.pitch_scale = clampf(final_pitch, 0.5, 2.0)
	chosen.volume_db = vol_db
	chosen.play()

func play_ui_click() -> void:
	play_sfx("ui_click", 1.0, -4.0, 0.05)
