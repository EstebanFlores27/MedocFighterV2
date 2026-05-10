extends CanvasLayer

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

func _ready() -> void:
	chronik_panel.visible = false
	countdown_label.visible = false
	victory_panel.visible = false
	GameState.player_hp_changed.connect(_on_player_hp_changed)
	GameState.chronik_engaged.connect(_on_chronik_engaged)
	GameState.chronik_hp_changed.connect(_on_chronik_hp_changed)
	GameState.chronik_defeated.connect(_on_chronik_defeated)
	continue_btn.pressed.connect(_on_continue_pressed)

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

func _on_continue_pressed() -> void:
	victory_panel.visible = false
	GameState.combat_resolved.emit()

func _play_countdown() -> void:
	countdown_label.visible = true
	for step in ["3", "2", "1", "GO !"]:
		countdown_label.text = step
		await get_tree().create_timer(0.6).timeout
	countdown_label.visible = false
	GameState.combat_countdown_done.emit()
