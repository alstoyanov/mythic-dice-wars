extends Node
## Autoload "Sound": sound effects with the player's on/off and volume settings on an "SFX" bus.
## Everything else calls Sound.play("name"). To change a sound, edit SOUNDS. These are placeholder
## sounds from Chasm of Knights until the game's own are made (docs/art_prompts/08_sound_effects.md).

const SFX_DIR := "res://assets/audio/sfx/"
const VOICES := 8

## name -> [file or list of files (without .ogg; one is picked at random), volume in dB, random pitch variation]
const SOUNDS := {
	"click": ["click_003", -2.0, 0.0],
	"hover": ["tick_002", -15.0, 0.0],
	"back": ["back_002", -2.0, 0.0],
	"start": ["maximize_006", -2.0, 0.0],
	"toggle": ["toggle_002", -3.0, 0.0],
	"select": ["pick", -7.0, 0.0],  # a territory is chosen
	"roll": [["place", "pick"], -6.0, 0.15],  # dice tumble
	"conquer": [["crumble_1", "crumble_2"], -5.0, 0.04],
	"repelled": ["back_002", -6.0, 0.05],
	"reinforce": ["place", -6.0, 0.08],
	"miracle": ["special", -4.0, 0.0],
	"win": ["win", -6.0, 0.0],
	"lose": ["lose", -6.0, 0.0],
}

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _streams: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	GameSettings.ensure_loaded()
	_rng.randomize()
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	apply()


## Applies the on/off and volume settings (call after changing them).
func apply() -> void:
	var idx := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(idx, not GameSettings.sfx_enabled or GameSettings.sfx_volume <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(GameSettings.sfx_volume, 0.001)))


func play(sound: String) -> void:
	if not GameSettings.sfx_enabled or not SOUNDS.has(sound):
		return
	var spec: Array = SOUNDS[sound]
	var files: Variant = spec[0]
	var file: String = files if files is String else files[_rng.randi_range(0, files.size() - 1)]
	var stream := _stream(file)
	if stream == null:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.volume_db = spec[1]
	voice.pitch_scale = 1.0 + _rng.randf_range(-spec[2], spec[2])
	voice.play()


func play_later(sound: String, seconds: float) -> void:
	get_tree().create_timer(seconds).timeout.connect(play.bind(sound))


func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		var path := "%s%s.ogg" % [SFX_DIR, file]
		_streams[file] = load(path) if ResourceLoader.exists(path) else null
	return _streams[file]
