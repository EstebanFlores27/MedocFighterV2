extends Node

# Autoload singleton. Holds runtime game state and combat-event signals.
# Persistence is added in a later milestone.

@warning_ignore_start("unused_signal")
signal player_hp_changed(hp: int, max_hp: int)
signal player_defeated
signal chronik_engaged(display_name: String, max_hp: int)
signal chronik_hp_changed(hp: int, max_hp: int)
signal chronik_defeated(display_name: String, victory_text: String)
signal combat_countdown_done
signal combat_resolved
signal med_inventory_changed(charges: Dictionary)
signal med_use_requested(med_id: String)
signal player_buff_changed(speed_active: bool, force_active: bool)
signal district_cleared(district: int)
signal health_state_changed(state: int)
@warning_ignore_restore("unused_signal")

const DISTRICT_CHRONIK_COUNT := {1: 2, 2: 4, 3: 4, 4: 1}
const SAVE_PATH := "user://save.cfg"
const DAY_SECS := 86400
const STATE_BLEAK := 0
const STATE_PASTEL := 1
const STATE_VIVID := 2
const STREAK_PASTEL := 3
const STREAK_VIVID := 12

var current_district: int = 1
var defeated_chroniks: Array[String] = []
var defeated_per_district: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var streak_days: int = 0
var has_adrenaline: bool = false
var intro_seen: bool = false
var last_boost_unix: int = 0
var player_gender: int = 0  # 0 = Homme, 1 = Femme

func register_chronik_defeated(chronik_id: String, district: int) -> void:
	if defeated_chroniks.has(chronik_id):
		return
	defeated_chroniks.append(chronik_id)
	defeated_per_district[district] = int(defeated_per_district.get(district, 0)) + 1
	var target := int(DISTRICT_CHRONIK_COUNT.get(district, 9999))
	if int(defeated_per_district[district]) >= target:
		district_cleared.emit(district)
	save_to_disk()

func reset_progress() -> void:
	current_district = 1
	defeated_chroniks.clear()
	defeated_per_district = {1: 0, 2: 0, 3: 0, 4: 0}
	has_adrenaline = false
	intro_seen = false
	streak_days = 0
	last_boost_unix = 0
	player_gender = 0
	health_state_changed.emit(get_health_state())

func get_health_state() -> int:
	if streak_days >= STREAK_VIVID:
		return STATE_VIVID
	if streak_days >= STREAK_PASTEL:
		return STATE_PASTEL
	return STATE_BLEAK

func get_damage_taken_multiplier() -> float:
	match get_health_state():
		STATE_VIVID: return 0.5
		STATE_PASTEL: return 0.7
		_: return 1.0

func is_daily_boost_available() -> bool:
	if last_boost_unix == 0:
		return true
	var now := int(Time.get_unix_time_from_system())
	return now - last_boost_unix >= DAY_SECS

func seconds_until_next_boost() -> int:
	if last_boost_unix == 0:
		return 0
	var now := int(Time.get_unix_time_from_system())
	return max(0, DAY_SECS - (now - last_boost_unix))

func open_daily_boost() -> bool:
	if not is_daily_boost_available():
		return false
	var now := int(Time.get_unix_time_from_system())
	if last_boost_unix == 0:
		streak_days = 1
	elif now - last_boost_unix < DAY_SECS * 2:
		streak_days += 1
	else:
		streak_days = 1
	last_boost_unix = now
	save_to_disk()
	health_state_changed.emit(get_health_state())
	return true

func debug_advance_day() -> void:
	# Dev-only: shifts the last-boost timestamp 24h into the past so the
	# chest becomes available immediately. Used to verify the streak loop
	# without waiting real time.
	if last_boost_unix == 0:
		last_boost_unix = int(Time.get_unix_time_from_system()) - DAY_SECS
	else:
		last_boost_unix -= DAY_SECS
	save_to_disk()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_district", current_district)
	cfg.set_value("progress", "defeated_chroniks", defeated_chroniks)
	cfg.set_value("progress", "defeated_per_district", defeated_per_district)
	cfg.set_value("progress", "has_adrenaline", has_adrenaline)
	cfg.set_value("progress", "intro_seen", intro_seen)
	cfg.set_value("progress", "player_gender", player_gender)
	cfg.set_value("daily", "streak_days", streak_days)
	cfg.set_value("daily", "last_boost_unix", last_boost_unix)
	cfg.save(SAVE_PATH)

func load_from_disk() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	current_district = int(cfg.get_value("progress", "current_district", 1))
	var loaded_chroniks: Array = cfg.get_value("progress", "defeated_chroniks", [])
	defeated_chroniks.clear()
	for c in loaded_chroniks:
		defeated_chroniks.append(str(c))
	var loaded_counts: Dictionary = cfg.get_value("progress", "defeated_per_district", {})
	defeated_per_district = {1: 0, 2: 0, 3: 0, 4: 0}
	for k in loaded_counts:
		defeated_per_district[int(k)] = int(loaded_counts[k])
	has_adrenaline = bool(cfg.get_value("progress", "has_adrenaline", false))
	intro_seen = bool(cfg.get_value("progress", "intro_seen", false))
	player_gender = int(cfg.get_value("progress", "player_gender", 0))
	streak_days = int(cfg.get_value("daily", "streak_days", cfg.get_value("progress", "streak_days", 0)))
	last_boost_unix = int(cfg.get_value("daily", "last_boost_unix", 0))
	health_state_changed.emit(get_health_state())
	return true

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func is_district_cleared(d: int) -> bool:
	var target := int(DISTRICT_CHRONIK_COUNT.get(d, 9999))
	return int(defeated_per_district.get(d, 0)) >= target

func is_district_unlocked(d: int) -> bool:
	if d == 1:
		return true
	return is_district_cleared(d - 1)
