extends CanvasLayer

const MED_LABELS := {
	"soin": "Soin\n+20 PV",
	"vitesse": "Vitesse\nx2 vitesse",
	"force": "Force\nx2 dégâts",
}
const MED_KEYS := {
	KEY_1: "soin",
	KEY_2: "vitesse",
	KEY_3: "force",
}

@onready var player_hp_bar: ProgressBar = $Root/TopLeft/PlayerHpBar
@onready var player_hp_label: Label = $Root/TopLeft/PlayerHpLabel
@onready var chronik_panel: Control = $Root/TopCenter
@onready var chronik_name_label: Label = $Root/TopCenter/ChronikName
@onready var chronik_hp_bar: ProgressBar = $Root/TopCenter/ChronikHpBar
@onready var countdown_label: Label = $Root/CountdownLabel
@onready var victory_panel: Panel = $Root/VictoryPanel
@onready var victory_title: Label = $Root/VictoryPanel/VBox/Title
@onready var victory_body: Label = $Root/VictoryPanel/VBox/Body
@onready var continue_btn: Button = $Root/VictoryPanel/VBox/ContinueButton
@onready var med_box: VBoxContainer = $Root/MedBox
@onready var med_btns := {
	"soin": $Root/MedBox/SoinBtn as Button,
	"vitesse": $Root/MedBox/VitesseBtn as Button,
	"force": $Root/MedBox/ForceBtn as Button,
}
@onready var buff_label: Label = $Root/BuffLabel
@onready var defeat_panel: Panel = $Root/DefeatPanel
@onready var retry_btn: Button = $Root/DefeatPanel/VBox/Buttons/RetryBtn
@onready var defeat_map_btn: Button = $Root/DefeatPanel/VBox/Buttons/MapBtn

var _last_charges: Dictionary = {"soin": 1, "vitesse": 1, "force": 1}
var _pending_district_cleared: int = 0
var _showing_district_panel: bool = false

func _ready() -> void:
	chronik_panel.visible = false
	countdown_label.visible = false
	victory_panel.visible = false
	defeat_panel.visible = false
	buff_label.visible = false
	GameState.player_hp_changed.connect(_on_player_hp_changed)
	GameState.player_defeated.connect(_on_player_defeated)
	GameState.chronik_engaged.connect(_on_chronik_engaged)
	GameState.chronik_hp_changed.connect(_on_chronik_hp_changed)
	GameState.chronik_defeated.connect(_on_chronik_defeated)
	GameState.med_inventory_changed.connect(_on_med_inventory_changed)
	GameState.player_buff_changed.connect(_on_buff_changed)
	GameState.district_cleared.connect(_on_district_cleared)
	continue_btn.pressed.connect(_on_continue_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	defeat_map_btn.pressed.connect(_on_defeat_map_pressed)
	for med_id in med_btns:
		var btn: Button = med_btns[med_id]
		btn.pressed.connect(_on_med_pressed.bind(med_id))
	_refresh_med_buttons()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).keycode
	if MED_KEYS.has(k):
		_on_med_pressed(MED_KEYS[k])

func _on_med_pressed(med_id: String) -> void:
	if int(_last_charges.get(med_id, 0)) <= 0:
		return
	GameState.med_use_requested.emit(med_id)

func _on_player_hp_changed(hp: int, max_hp: int) -> void:
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = hp
	player_hp_label.text = "%d / %d" % [hp, max_hp]

func _on_chronik_engaged(display_name: String, max_hp: int) -> void:
	chronik_name_label.text = display_name
	chronik_hp_bar.max_value = max_hp
	chronik_hp_bar.value = max_hp
	chronik_panel.visible = true
	_play_countdown()

func _on_chronik_hp_changed(hp: int, max_hp: int) -> void:
	chronik_hp_bar.max_value = max_hp
	chronik_hp_bar.value = hp

func _on_chronik_defeated(display_name: String, victory_text: String) -> void:
	chronik_panel.visible = false
	victory_title.text = "BRAVO !"
	victory_body.text = "%s vaincu !\n\n%s" % [display_name, victory_text]
	victory_panel.visible = true
	continue_btn.grab_focus()

func _on_player_defeated() -> void:
	chronik_panel.visible = false
	victory_panel.visible = false
	countdown_label.visible = false
	defeat_panel.visible = true
	retry_btn.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_defeat_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/city_map.tscn")

func _on_continue_pressed() -> void:
	if _pending_district_cleared > 0:
		_show_district_cleared_panel(_pending_district_cleared)
		_pending_district_cleared = 0
		_showing_district_panel = true
		return
	if _showing_district_panel:
		_showing_district_panel = false
		victory_panel.visible = false
		get_tree().change_scene_to_file("res://scenes/city_map.tscn")
		return
	victory_panel.visible = false
	GameState.combat_resolved.emit()

func _on_district_cleared(district: int) -> void:
	_pending_district_cleared = district

func _show_district_cleared_panel(_district: int) -> void:
	victory_title.text = "QUARTIER LIBÉRÉ !"
	victory_body.text = "Adrénaline débloquée : +70 PV !\nLa boîte de médicaments est à nouveau pleine."
	continue_btn.grab_focus()

func _on_med_inventory_changed(charges: Dictionary) -> void:
	_last_charges = charges.duplicate()
	_refresh_med_buttons()

func _refresh_med_buttons() -> void:
	for med_id in med_btns:
		var btn: Button = med_btns[med_id]
		var n := int(_last_charges.get(med_id, 0))
		btn.text = "%s\n[%d]" % [MED_LABELS[med_id], n]
		btn.disabled = n <= 0

func _on_buff_changed(speed_active: bool, force_active: bool, speed_t: float, force_t: float) -> void:
	var parts: Array[String] = []
	if speed_active:
		parts.append("Vitesse x2  %.1fs" % speed_t)
	if force_active:
		parts.append("Force x2  %.1fs" % force_t)
	if parts.is_empty():
		buff_label.visible = false
	else:
		buff_label.text = "\n".join(parts)
		buff_label.visible = true

func _play_countdown() -> void:
	countdown_label.visible = true
	for step in ["3", "2", "1", "GO !"]:
		countdown_label.text = step
		await get_tree().create_timer(0.6).timeout
	countdown_label.visible = false
	GameState.combat_countdown_done.emit()
