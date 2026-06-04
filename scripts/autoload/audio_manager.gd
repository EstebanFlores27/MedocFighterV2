extends Node

# Autoload. Owns the audio buses, the user settings (volumes + fullscreen) and
# the SFX hook points. No audio files exist yet, so play_sfx() is a safe no-op
# until the matching files in _SFX_PATHS are added — see docs TODO list.

const SETTINGS_PATH := "user://settings.cfg"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const _SFX_POOL := 6

# id -> file. Drop the files here later and the hooks light up automatically.
const _SFX_PATHS := {
	"punch": "res://assets/audio/sfx_punch.wav",
	"hit": "res://assets/audio/sfx_hit.wav",
	"med": "res://assets/audio/sfx_med.wav",
	"victory": "res://assets/audio/sfx_victory.wav",
	"defeat": "res://assets/audio/sfx_defeat.wav",
	"click": "res://assets/audio/sfx_click.wav",
}

var master_volume: float = 0.9
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var fullscreen: bool = false

var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0

func _ready() -> void:
	_ensure_buses()
	for id in _SFX_PATHS:
		var path: String = _SFX_PATHS[id]
		if ResourceLoader.exists(path):
			_sfx_streams[id] = load(path)
	for i in _SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_players.append(p)
	load_settings()
	_apply_all()

func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func play_sfx(id: String) -> void:
	if not _sfx_streams.has(id):
		return  # no file yet — silent hook
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = _sfx_streams[id]
	p.play()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Master", master_volume)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus(MUSIC_BUS, music_volume)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus(SFX_BUS, sfx_volume)

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))

func _apply_all() -> void:
	_apply_bus("Master", master_volume)
	_apply_bus(MUSIC_BUS, music_volume)
	_apply_bus(SFX_BUS, sfx_volume)
	set_fullscreen(fullscreen)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)
