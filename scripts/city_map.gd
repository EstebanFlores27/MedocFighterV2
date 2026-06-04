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
const DISTRICT_SCENES := {
	1: "res://scenes/level.tscn",
	2: "res://scenes/level.tscn",
	3: "res://scenes/level.tscn",
	4: "res://scenes/level.tscn",
}

const SETTINGS_OVERLAY := preload("res://scenes/settings_overlay.tscn")
const GUIDE_BUBBLE := preload("res://scenes/guide_bubble.tscn")
const MAP_HINT := "Bienvenue à Seek City ! Entre dans un quartier et bats tous ses Chroniks pour ouvrir le quartier suivant."

@onready var back_btn: Button = $TopBar/BackBtn
@onready var settings_btn: Button = $TopBar/SettingsBtn
@onready var cards := {
	1: $CenterContainer/Grid/D1Card,
	2: $CenterContainer/Grid/D2Card,
	3: $CenterContainer/Grid/D3Card,
	4: $CenterContainer/Grid/D4Card,
}
@onready var boost_streak_lbl: Label = $BoostPanel/VBox/StreakLabel
@onready var boost_gauge: TextureRect = $BoostPanel/VBox/Gauge
@onready var boost_state_lbl: Label = $BoostPanel/VBox/StateLabel
@onready var boost_status_lbl: Label = $BoostPanel/VBox/StatusLabel
@onready var pill_box: Control = $BoostPanel/VBox/PillBox
@onready var boost_open_btn: Button = $BoostPanel/VBox/OpenBtn
@onready var boost_dev_btn: Button = $BoostPanel/VBox/DevBtn
@onready var countdown_timer: Timer = $CountdownTimer

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	settings_btn.pressed.connect(_on_settings)
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
		card.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.7)
	boost_open_btn.pressed.connect(_on_boost_open)
	boost_dev_btn.pressed.connect(_on_boost_dev_advance)
	boost_dev_btn.visible = OS.is_debug_build()
	countdown_timer.timeout.connect(_refresh_boost_panel)
	countdown_timer.start()
	_refresh_boost_panel()
	_maybe_show_map_hint()

func _on_settings() -> void:
	AudioManager.play_sfx("click")
	var overlay := SETTINGS_OVERLAY.instantiate()
	add_child(overlay)
	overlay.open()

func _maybe_show_map_hint() -> void:
	if GameState.is_hint_seen("map_intro"):
		return
	var bubble := GUIDE_BUBBLE.instantiate()
	add_child(bubble)
	bubble.show_message(MAP_HINT)
	GameState.mark_hint_seen("map_intro")

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
	var scene_path: String = DISTRICT_SCENES.get(d, "res://scenes/level.tscn")
	GameState.current_district = d
	var card: PanelContainer = cards[d]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.18)
	tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.18)
	tween.chain().tween_callback(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)

func _gauge_frame() -> int:
	var t := clampf(float(GameState.streak_days) / float(GameState.STREAK_VIVID), 0.0, 1.0)
	return clampi(int(round(t * 9.0)) + 1, 1, 10)

func _refresh_boost_panel() -> void:
	var dmg_pct := int(round((1.0 - GameState.get_damage_taken_multiplier()) * 100.0))
	boost_streak_lbl.text = "Série : %d jour%s" % [GameState.streak_days, "s" if GameState.streak_days != 1 else ""]
	boost_state_lbl.text = "Protection : -%d%% dégâts" % dmg_pct
	boost_gauge.texture = load("res://assets/hud/jauge_daily_box_%d.png" % _gauge_frame())
	pill_box.set_state(GameState.week_pills_taken(), GameState.is_daily_boost_available())
	if GameState.is_daily_boost_available():
		boost_status_lbl.text = "Coffre disponible !"
		boost_open_btn.disabled = false
		boost_open_btn.text = "Ouvrir le coffre"
	else:
		var secs := GameState.seconds_until_next_boost()
		boost_status_lbl.text = "Prochaine dose : %s" % _format_duration(secs)
		boost_open_btn.disabled = true
		boost_open_btn.text = "Déjà pris aujourd'hui"

func _format_duration(secs: int) -> String:
	var h := secs / 3600
	var m := (secs % 3600) / 60
	var s := secs % 60
	return "%02d h %02d m %02d s" % [h, m, s]

func _on_boost_open() -> void:
	if not GameState.is_daily_boost_available():
		return
	var slot := GameState.week_pills_taken()
	if GameState.open_daily_boost():
		AudioManager.play_sfx("med")
		pill_box.play_consume(slot, GameState.week_pills_taken(), GameState.is_daily_boost_available())
		_flash_boost_panel()
	_refresh_boost_panel()
	_refresh_district_cards()

func _on_boost_dev_advance() -> void:
	GameState.debug_advance_day()
	_refresh_boost_panel()

func _flash_boost_panel() -> void:
	var panel: Panel = $BoostPanel
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.12)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.4)

func _refresh_district_cards() -> void:
	# After a boost, status text doesn't change but state may. Light refresh
	# in case future signals need to redraw cards. Currently a no-op.
	pass
