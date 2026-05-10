extends Control

const DISTRICT_NAMES := {
	1: "1. Place centrale",
	2: "2. Centre commercial",
	3: "3. Parc",
	4: "4. Hôpital",
}
const DISTRICT_DESC := {
	1: "Cortexia • Epidermos",
	2: "Pancréok • Hépatox • Gastrix • Nefronix",
	3: "Kardiox • Pulmos • Ostéox • Articulix",
	4: "Boss final",
}

@onready var back_btn: Button = $TopBar/BackBtn
@onready var cards := {
	1: $CenterContainer/Grid/D1Card,
	2: $CenterContainer/Grid/D2Card,
	3: $CenterContainer/Grid/D3Card,
	4: $CenterContainer/Grid/D4Card,
}

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	for d in cards.keys():
		var card: PanelContainer = cards[d]
		var name_lbl: Label = card.get_node("VBox/Name")
		var desc_lbl: Label = card.get_node("VBox/Description")
		var status_lbl: Label = card.get_node("VBox/Status")
		var enter_btn: Button = card.get_node("VBox/EnterBtn")
		name_lbl.text = DISTRICT_NAMES[d]
		desc_lbl.text = DISTRICT_DESC[d]
		var status := _district_status(d)
		status_lbl.text = status
		var unlocked := GameState.is_district_unlocked(d)
		var cleared := GameState.is_district_cleared(d)
		enter_btn.disabled = (not unlocked) or cleared
		enter_btn.text = "Libéré ✓" if cleared else ("Entrer" if unlocked else "Verrouillé")
		enter_btn.pressed.connect(_on_district.bind(d))

func _district_status(d: int) -> String:
	if GameState.is_district_cleared(d):
		var target := int(GameState.DISTRICT_CHRONIK_COUNT.get(d, 0))
		return "Libéré ✓ (%d/%d)" % [target, target]
	if GameState.is_district_unlocked(d):
		var defeated := int(GameState.defeated_per_district.get(d, 0))
		var target := int(GameState.DISTRICT_CHRONIK_COUNT.get(d, 0))
		return "Disponible — %d/%d Chroniks" % [defeated, target]
	return "Verrouillé"

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_district(d: int) -> void:
	if not GameState.is_district_unlocked(d) or GameState.is_district_cleared(d):
		return
	GameState.current_district = d
	var card: PanelContainer = cards[d]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.18)
	tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.18)
	tween.chain().tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	)
