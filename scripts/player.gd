extends CharacterBody2D

const BASE_SPEED := 420.0
const JUMP_VELOCITY := -900.0
const GRAVITY := 2200.0
const MAX_HP := 100
const PUNCH_COOLDOWN := 0.4
const PUNCH_DURATION := 0.14
const BASE_PUNCH_DAMAGE := 10
const INVULN_DURATION := 0.6
const SOIN_HEAL_AMOUNT := 20
const BUFF_DURATION := 10.0

# Female sprite sheet (player_sheet.png) — regions + offset_y.
# "idle" and "jump" share the same region (standing pose used for both).
const POSES_FEMALE := {
	"idle":    {"region": Rect2(300,   5, 335, 595), "oy": -191.1},
	"jump":    {"region": Rect2(300,   5, 335, 595), "oy": -191.1},
	"duck":    {"region": Rect2( 25, 170, 230, 405), "oy": -129.9},
	"retreat": {"region": Rect2(  5, 575, 230, 445), "oy": -142.8},
	"advance": {"region": Rect2(245, 570, 280, 450), "oy": -144.6},
	"punch":   {"region": Rect2(520, 570, 500, 450), "oy": -144.6},
}

# Male individual sprites — one file per pose.
const MALE_FILES := {
	"idle":    "res://assets/sprites/Debout.png",
	"advance": "res://assets/sprites/Marche.png",
	"retreat": "res://assets/sprites/Marche.png",
	"jump":    "res://assets/sprites/Saut.png",
	"duck":    "res://assets/sprites/Baisser.png",
	"punch":   "res://assets/sprites/Coup.png",
}
const MALE_OFFSETS := {
	"idle":    -187.5,
	"advance": -184.8,
	"retreat": -184.8,
	"jump":    -149.7,
	"duck":    -164.4,
	"punch":   -167.1,
}

var _is_male := false
var _male_tex: Dictionary = {}
var _poses: Dictionary        # used only for female

@onready var sprite: Sprite2D = $Sprite
@onready var collider: CollisionShape2D = $Collider
@onready var punch_hitbox: Area2D = $PunchHitbox
@onready var punch_visual: ColorRect = $PunchHitbox/PunchVisual

var hp: int = MAX_HP
var facing: int = 1
var locked: bool = false

var med_charges: Dictionary = {"soin": 1, "vitesse": 1, "force": 1}
var _speed_buff_t := 0.0
var _force_buff_t := 0.0
var _last_speed_active := false
var _last_force_active := false

var _is_ducking := false
var _default_collider_height: float
var _default_collider_pos: Vector2
var _default_punch_offset: float
var _punch_cd := 0.0
var _punch_t := 0.0
var _invuln_t := 0.0
var _base_color := Color.WHITE

func _ready() -> void:
	add_to_group("player")
	var shape := collider.shape as RectangleShape2D
	_default_collider_height = shape.size.y
	_default_collider_pos = collider.position
	_default_punch_offset = abs(punch_hitbox.position.x)
	punch_hitbox.monitoring = false
	punch_visual.visible = false

	if GameState.player_gender == 0:
		_is_male = true
		sprite.region_enabled = false
		for pose in MALE_FILES:
			_male_tex[pose] = load(MALE_FILES[pose]) as Texture2D
		sprite.texture = _male_tex["idle"]
		sprite.offset = Vector2(0.0, MALE_OFFSETS["idle"])
	else:
		_poses = POSES_FEMALE
		sprite.texture = load("res://assets/sprites/player_sheet.png") as Texture2D

	GameState.chronik_engaged.connect(_on_chronik_engaged)
	GameState.combat_countdown_done.connect(_on_countdown_done)
	GameState.chronik_defeated.connect(_on_chronik_defeated)
	GameState.combat_resolved.connect(_on_combat_resolved)
	GameState.med_use_requested.connect(_on_med_use_requested)
	GameState.district_cleared.connect(_on_district_cleared)
	GameState.health_state_changed.connect(_on_health_state_changed)
	_apply_health_tint(GameState.get_health_state())
	GameState.player_hp_changed.emit(hp, MAX_HP)
	GameState.med_inventory_changed.emit(med_charges.duplicate())
	GameState.player_buff_changed.emit(false, false)

func _on_chronik_engaged(_display_name: String, _max_hp: int) -> void:
	locked = true

func _on_countdown_done() -> void:
	locked = false

func _on_chronik_defeated(_display_name: String, _victory_text: String) -> void:
	locked = true

func _on_combat_resolved() -> void:
	locked = false

func _on_med_use_requested(med_id: String) -> void:
	use_med(med_id)

func _on_district_cleared(_district: int) -> void:
	GameState.has_adrenaline = true
	heal(70)
	med_charges = {"soin": 1, "vitesse": 1, "force": 1}
	GameState.med_inventory_changed.emit(med_charges.duplicate())

func _on_health_state_changed(state: int) -> void:
	_apply_health_tint(state)

func _apply_health_tint(_state: int) -> void:
	var is_female := GameState.player_gender == 1
	var col_min := Color(0.60, 0.45, 0.54) if is_female else Color(0.42, 0.45, 0.60)
	var col_max := Color(0.90, 0.30, 0.60) if is_female else Color(0.20, 0.40, 0.85)
	var t := clampf(float(GameState.streak_days) / float(GameState.STREAK_VIVID), 0.0, 1.0)
	_base_color = col_min.lerp(col_max, t)

func use_med(med_id: String) -> void:
	if not med_charges.has(med_id):
		return
	if med_charges[med_id] <= 0:
		return
	med_charges[med_id] -= 1
	match med_id:
		"soin":
			hp = mini(MAX_HP, hp + SOIN_HEAL_AMOUNT)
			GameState.player_hp_changed.emit(hp, MAX_HP)
		"vitesse":
			_speed_buff_t = BUFF_DURATION
		"force":
			_force_buff_t = BUFF_DURATION
	GameState.med_inventory_changed.emit(med_charges.duplicate())

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_punch_cd = max(0.0, _punch_cd - delta)
	_invuln_t = max(0.0, _invuln_t - delta)
	_speed_buff_t = max(0.0, _speed_buff_t - delta)
	_force_buff_t = max(0.0, _force_buff_t - delta)
	_emit_buff_change_if_needed()

	if _punch_t > 0.0:
		_punch_t = max(0.0, _punch_t - delta)
		if _punch_t == 0.0:
			_end_punch()

	var current_speed := BASE_SPEED * (2.0 if _speed_buff_t > 0.0 else 1.0)

	if locked:
		velocity.x = move_toward(velocity.x, 0, current_speed * 4 * delta)
		move_and_slide()
		_apply_visual_state()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_ducking:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * current_speed
	if direction != 0.0:
		facing = int(sign(direction))

	_set_ducking(Input.is_action_pressed("duck") and is_on_floor())

	if Input.is_action_just_pressed("punch") and _punch_cd <= 0.0 and not _is_ducking:
		_start_punch()

	move_and_slide()
	_apply_visual_state()

func _start_punch() -> void:
	_punch_cd = PUNCH_COOLDOWN
	_punch_t = PUNCH_DURATION
	punch_hitbox.position.x = _default_punch_offset * facing
	punch_visual.visible = true
	punch_hitbox.monitoring = true
	await get_tree().physics_frame
	if not is_inside_tree() or _punch_t <= 0.0:
		return
	var dmg := BASE_PUNCH_DAMAGE * (2 if _force_buff_t > 0.0 else 1)
	for body in punch_hitbox.get_overlapping_bodies():
		if body.is_in_group("chronik") and body.has_method("receive_punch"):
			body.receive_punch(dmg, facing)

func _end_punch() -> void:
	punch_hitbox.monitoring = false
	punch_visual.visible = false

func take_damage(amount: int, from_dir: int) -> void:
	if _invuln_t > 0.0 or hp <= 0:
		return
	var modified := int(ceil(amount * GameState.get_damage_taken_multiplier()))
	hp = max(0, hp - modified)
	_invuln_t = INVULN_DURATION
	velocity.x = from_dir * 350.0
	velocity.y = -400.0
	GameState.player_hp_changed.emit(hp, MAX_HP)
	if hp == 0:
		locked = true
		GameState.player_defeated.emit()

func heal(amount: int) -> void:
	hp = mini(MAX_HP, hp + amount)
	GameState.player_hp_changed.emit(hp, MAX_HP)

func _emit_buff_change_if_needed() -> void:
	var s_active := _speed_buff_t > 0.0
	var f_active := _force_buff_t > 0.0
	if s_active != _last_speed_active or f_active != _last_force_active:
		_last_speed_active = s_active
		_last_force_active = f_active
		GameState.player_buff_changed.emit(s_active, f_active)

func _apply_visual_state() -> void:
	var alpha := 1.0
	if _invuln_t > 0.0:
		alpha = 0.4 if int(_invuln_t * 20) % 2 == 0 else 1.0
	var r := _base_color.r * (1.4 if _force_buff_t > 0.0 else 1.0)
	var b := _base_color.b * (1.4 if _speed_buff_t > 0.0 else 1.0)
	sprite.modulate = Color(r, _base_color.g, b, alpha)
	_update_sprite_pose()

func _update_sprite_pose() -> void:
	var pose_name: String
	var flip := false

	if _is_ducking:
		pose_name = "duck"
		flip = facing < 0
	elif _punch_t > 0.0:
		pose_name = "punch"
		flip = facing < 0
	elif not is_on_floor():
		pose_name = "jump"
		flip = facing < 0
	elif velocity.x > 0.0:
		pose_name = "advance"
	elif velocity.x < 0.0:
		pose_name = "retreat"
		flip = true
	else:
		pose_name = "idle"
		flip = facing < 0

	if _is_male:
		sprite.texture = _male_tex[pose_name]
		sprite.offset = Vector2(0.0, MALE_OFFSETS[pose_name])
		sprite.flip_h = flip
	else:
		var p: Dictionary = _poses[pose_name]
		sprite.region_rect = p["region"]
		sprite.offset = Vector2(0.0, p["oy"])
		sprite.flip_h = flip

func _set_ducking(ducking: bool) -> void:
	if ducking == _is_ducking:
		return
	_is_ducking = ducking
	var shape := collider.shape as RectangleShape2D
	if ducking:
		shape.size = Vector2(shape.size.x, _default_collider_height * 0.5)
		collider.position = _default_collider_pos + Vector2(0, _default_collider_height * 0.25)
	else:
		shape.size = Vector2(shape.size.x, _default_collider_height)
		collider.position = _default_collider_pos
