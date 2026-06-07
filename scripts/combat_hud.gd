extends CanvasLayer

const SETTINGS_OVERLAY := preload("res://scenes/settings_overlay.tscn")
const GUIDE_BUBBLE := preload("res://scenes/guide_bubble.tscn")
const BUFF_DURATION := 10.0
const LOW_HP_RATIO := 0.3

const HINT_CHRONIK := "Un Chronik ! Frappe avec X, et baisse-toi (▼) pour esquiver. Vide sa jauge de vie pour le vaincre."
const HINT_MEDS := "Ta boîte de médocs ! Soin (1) rend des PV, Vitesse (2) et Force (3) te boostent 10 s. Une seule dose de chaque — choisis le bon moment."
const HINT_LOW_HP := "Tes PV sont bas ! Utilise Soin (1) pour récupérer +20 PV."

const MED_KEYS := {
	KEY_1: "soin",
	KEY_2: "vitesse",
	KEY_3: "force",
}
# Centers of the lower compartments in the boite_vide tray (fractions of size).
const MED_TRAY_X := {"vitesse": 0.301, "soin": 0.501, "force": 0.699}
const MED_TRAY_Y := 0.583
const MED_TRAY_BTN_W := 0.18
const MED_TRAY_BTN_H := 0.14
# HP-bar track window inside the jauge_sante frame (fractions of the slot).
const TRACK_X0 := 0.330
const TRACK_W := 0.510
const TRACK_Y0 := 0.444
const TRACK_H := 0.105

@onready var top_left: Control = $Root/TopLeft
@onready var player_hp_bar: ProgressBar = $Root/TopLeft/PlayerHpBar
@onready var player_hp_label: Label = $Root/TopLeft/PlayerHpLabel
@onready var chronik_panel: Control = $Root/TopCenter
@onready var chronik_name_label: Label = $Root/TopCenter/ChronikName
@onready var chronik_portrait: TextureRect = $Root/TopCenter/Portrait
@onready var bar_slot: Control = $Root/TopCenter/BarSlot
@onready var chronik_hp_bar: ProgressBar = $Root/TopCenter/BarSlot/ChronikHpBar
@onready var chronik_hp_label: Label = $Root/TopCenter/BarSlot/ChronikHpLabel
@onready var countdown_label: Label = $Root/CountdownLabel
@onready var victory_panel: Panel = $Root/VictoryPanel
@onready var victory_title: Label = $Root/VictoryPanel/VBox/Title
@onready var victory_body: Label = $Root/VictoryPanel/VBox/Body
@onready var continue_btn: Button = $Root/VictoryPanel/VBox/ContinueButton
@onready var med_tray: Control = $Root/MedTray
@onready var med_btns := {
	"soin": $Root/MedTray/SoinBtn as Button,
	"vitesse": $Root/MedTray/VitesseBtn as Button,
	"force": $Root/MedTray/ForceBtn as Button,
}
@onready var objective_line: Label = $Root/ObjectiveLine
@onready var pause_btn: Button = $Root/PauseBtn
@onready var buff_box: VBoxContainer = $Root/BuffBox
@onready var speed_row: HBoxContainer = $Root/BuffBox/SpeedRow
@onready var force_row: HBoxContainer = $Root/BuffBox/ForceRow
@onready var speed_bar: ProgressBar = $Root/BuffBox/SpeedRow/Bar
@onready var force_bar: ProgressBar = $Root/BuffBox/ForceRow/Bar
@onready var defeat_panel: Panel = $Root/DefeatPanel
@onready var retry_btn: Button = $Root/DefeatPanel/VBox/Buttons/RetryBtn
@onready var defeat_map_btn: Button = $Root/DefeatPanel/VBox/Buttons/MapBtn

var _last_charges: Dictionary = {"soin": 1, "vitesse": 1, "force": 1}
var _pending_district_cleared: int = 0
var _showing_district_panel: bool = false
var _player_fill: StyleBoxFlat
var _chronik_fill: StyleBoxFlat
var _guide: CanvasLayer

func _ready() -> void:
	chronik_panel.visible = false
	countdown_label.visible = false
	victory_panel.visible = false
	defeat_panel.visible = false
	buff_box.visible = false
	_player_fill = _setup_bar(player_hp_bar)
	_chronik_fill = _setup_bar(chronik_hp_bar)
	speed_bar.max_value = BUFF_DURATION
	force_bar.max_value = BUFF_DURATION
	_guide = GUIDE_BUBBLE.instantiate()
	add_child(_guide)
	_guide.place_bottom_center()
	_update_objective()
	call_deferred("_layout_dynamic")
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
	pause_btn.pressed.connect(_open_settings)
	for med_id in med_btns:
		var btn: Button = med_btns[med_id]
		btn.pressed.connect(_on_med_pressed.bind(med_id))
	_refresh_med_buttons()

# Positions the HP bars over the frame's painted track and the med buttons over
# the tray sections. Run deferred so the slot sizes are valid.
func _layout_dynamic() -> void:
	_place_over_track(top_left, player_hp_bar, player_hp_label)
	_place_over_track(bar_slot, chronik_hp_bar, chronik_hp_label)
	_place_med_buttons()

func _place_over_track(slot: Control, bar: ProgressBar, label: Label) -> void:
	var s := slot.size
	if s.x <= 0.0:
		return
	var pos := Vector2(s.x * TRACK_X0, s.y * TRACK_Y0)
	var sz := Vector2(s.x * TRACK_W, s.y * TRACK_H)
	var label_h := 38.0
	bar.position = pos
	bar.size = sz
	label.position = Vector2(pos.x, pos.y + sz.y / 2.0 - label_h / 2.0)
	label.size = Vector2(sz.x, label_h)

func _place_med_buttons() -> void:
	var s := med_tray.size
	if s.x <= 0.0:
		return
	var bw := s.x * MED_TRAY_BTN_W
	var bh := s.y * MED_TRAY_BTN_H
	for med_id in med_btns:
		var b: Button = med_btns[med_id]
		b.position = Vector2(float(MED_TRAY_X[med_id]) * s.x - bw / 2.0, s.y * MED_TRAY_Y - bh / 2.0)
		b.size = Vector2(bw, bh)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_ESCAPE:
		_open_settings()
		get_viewport().set_input_as_handled()
	elif MED_KEYS.has(k):
		_on_med_pressed(MED_KEYS[k])

func _open_settings() -> void:
	AudioManager.play_sfx("click")
	var overlay := SETTINGS_OVERLAY.instantiate()
	add_child(overlay)
	overlay.open()

func _on_med_pressed(med_id: String) -> void:
	if int(_last_charges.get(med_id, 0)) <= 0:
		return
	GameState.med_use_requested.emit(med_id)

func _on_player_hp_changed(hp: int, max_hp: int) -> void:
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = hp
	player_hp_label.text = "%d / %d" % [hp, max_hp]
	_player_fill.bg_color = _bar_color(float(hp) / maxf(1.0, max_hp))
	_maybe_low_hp_hint(hp, max_hp)

func _on_chronik_engaged(display_name: String, max_hp: int, portrait_path: String) -> void:
	chronik_name_label.text = display_name
	chronik_hp_bar.max_value = max_hp
	chronik_hp_bar.value = max_hp
	chronik_hp_label.text = "%d / %d" % [max_hp, max_hp]
	_chronik_fill.bg_color = _bar_color(1.0)
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		chronik_portrait.texture = load(portrait_path)
		chronik_portrait.visible = true
	else:
		chronik_portrait.visible = false
	chronik_panel.visible = true
	_maybe_combat_hints()
	_play_countdown()

func _on_chronik_hp_changed(hp: int, max_hp: int) -> void:
	chronik_hp_bar.max_value = max_hp
	chronik_hp_bar.value = hp
	chronik_hp_label.text = "%d / %d" % [hp, max_hp]
	_chronik_fill.bg_color = _bar_color(float(hp) / maxf(1.0, max_hp))

func _on_chronik_defeated(display_name: String, victory_text: String) -> void:
	AudioManager.play_sfx("victory")
	chronik_panel.visible = false
	victory_title.text = "BRAVO !"
	victory_body.text = "%s vaincu !\n\n%s" % [display_name, victory_text]
	victory_panel.visible = true
	continue_btn.grab_focus()
	call_deferred("_update_objective")

func _on_player_defeated() -> void:
	AudioManager.play_sfx("defeat")
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
		btn.disabled = n <= 0
		btn.modulate.a = 1.0 if n > 0 else 0.0  # empty compartment when used

func _on_buff_changed(speed_active: bool, force_active: bool, speed_t: float, force_t: float) -> void:
	speed_row.visible = speed_active
	force_row.visible = force_active
	if speed_active:
		speed_bar.value = speed_t
	if force_active:
		force_bar.value = force_t
	buff_box.visible = speed_active or force_active

func _play_countdown() -> void:
	countdown_label.visible = true
	for step in ["3", "2", "1", "GO !"]:
		countdown_label.text = step
		await get_tree().create_timer(0.8).timeout
	countdown_label.visible = false
	GameState.combat_countdown_done.emit()

# ----------------------------------------------------------------- helpers

func _setup_bar(bar: ProgressBar) -> StyleBoxFlat:
	var bg := StyleBoxEmpty.new()
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = _bar_color(1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	return fill

func _bar_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.30, 0.80, 0.35)
	if ratio > 0.25:
		return Color(0.95, 0.65, 0.20)
	return Color(0.90, 0.25, 0.25)

func _update_objective() -> void:
	var d := GameState.current_district
	var target := int(GameState.DISTRICT_CHRONIK_COUNT.get(d, 0))
	var done := int(GameState.defeated_per_district.get(d, 0))
	objective_line.text = "Bats tous les Chroniks du quartier — %d/%d" % [done, target]

func _maybe_combat_hints() -> void:
	if not GameState.is_hint_seen("chronik_intro"):
		_guide.show_message(HINT_CHRONIK)
		GameState.mark_hint_seen("chronik_intro")
	if not GameState.is_hint_seen("meds_intro"):
		_guide.show_message(HINT_MEDS)
		GameState.mark_hint_seen("meds_intro")

func _maybe_low_hp_hint(hp: int, max_hp: int) -> void:
	if hp <= 0 or GameState.is_hint_seen("low_hp"):
		return
	if float(hp) / maxf(1.0, max_hp) <= LOW_HP_RATIO and int(_last_charges.get("soin", 0)) > 0:
		_guide.show_message(HINT_LOW_HP)
		GameState.mark_hint_seen("low_hp")
