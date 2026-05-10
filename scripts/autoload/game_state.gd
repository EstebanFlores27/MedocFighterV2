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
@warning_ignore_restore("unused_signal")

var current_district: int = 1
var defeated_chroniks: Array[String] = []
var streak_days: int = 0
var has_adrenaline: bool = false
