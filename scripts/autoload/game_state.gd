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
@warning_ignore_restore("unused_signal")

const DISTRICT_CHRONIK_COUNT := {1: 2, 2: 4, 3: 4, 4: 1}

var current_district: int = 1
var defeated_chroniks: Array[String] = []
var defeated_per_district: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
var streak_days: int = 0
var has_adrenaline: bool = false

func register_chronik_defeated(chronik_id: String, district: int) -> void:
	if defeated_chroniks.has(chronik_id):
		return
	defeated_chroniks.append(chronik_id)
	defeated_per_district[district] = int(defeated_per_district.get(district, 0)) + 1
	var target := int(DISTRICT_CHRONIK_COUNT.get(district, 9999))
	if int(defeated_per_district[district]) >= target:
		district_cleared.emit(district)

func reset_progress() -> void:
	current_district = 1
	defeated_chroniks.clear()
	defeated_per_district = {1: 0, 2: 0, 3: 0, 4: 0}
	has_adrenaline = false

func is_district_cleared(d: int) -> bool:
	var target := int(DISTRICT_CHRONIK_COUNT.get(d, 9999))
	return int(defeated_per_district.get(d, 0)) >= target

func is_district_unlocked(d: int) -> bool:
	if d == 1:
		return true
	return is_district_cleared(d - 1)
