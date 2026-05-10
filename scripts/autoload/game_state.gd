extends Node

# Autoload singleton. Holds runtime game state that needs to survive scene changes.
# Persistence (save/load) will be added in a later milestone.

var current_district: int = 1
var defeated_chroniks: Array[String] = []
var streak_days: int = 0
var has_adrenaline: bool = false
