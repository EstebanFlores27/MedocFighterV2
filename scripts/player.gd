extends CharacterBody2D

const SPEED := 420.0
const JUMP_VELOCITY := -900.0
const GRAVITY := 2200.0
const MAX_HP := 100
const PUNCH_COOLDOWN := 0.4
const PUNCH_DURATION := 0.14
const PUNCH_DAMAGE := 10
const INVULN_DURATION := 0.6

@onready var sprite: ColorRect = $Sprite
@onready var collider: CollisionShape2D = $Collider
@onready var punch_hitbox: Area2D = $PunchHitbox
@onready var punch_visual: ColorRect = $PunchHitbox/PunchVisual

var hp: int = MAX_HP
var facing: int = 1
var locked: bool = false

var _is_ducking := false
var _default_sprite_size: Vector2
var _default_sprite_pos: Vector2
var _default_collider_height: float
var _default_collider_pos: Vector2
var _default_punch_offset: float
var _punch_cd := 0.0
var _punch_t := 0.0
var _invuln_t := 0.0

func _ready() -> void:
	add_to_group("player")
	_default_sprite_size = sprite.size
	_default_sprite_pos = sprite.position
	var shape := collider.shape as RectangleShape2D
	_default_collider_height = shape.size.y
	_default_collider_pos = collider.position
	_default_punch_offset = abs(punch_hitbox.position.x)
	punch_hitbox.monitoring = false
	punch_visual.visible = false
	GameState.chronik_engaged.connect(_on_chronik_engaged)
	GameState.combat_countdown_done.connect(_on_countdown_done)
	GameState.chronik_defeated.connect(_on_chronik_defeated)
	GameState.combat_resolved.connect(_on_combat_resolved)
	GameState.player_hp_changed.emit(hp, MAX_HP)

func _on_chronik_engaged(_display_name: String, _max_hp: int) -> void:
	locked = true

func _on_countdown_done() -> void:
	locked = false

func _on_chronik_defeated(_display_name: String, _victory_text: String) -> void:
	locked = true

func _on_combat_resolved() -> void:
	locked = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_punch_cd = max(0.0, _punch_cd - delta)
	_invuln_t = max(0.0, _invuln_t - delta)
	if _punch_t > 0.0:
		_punch_t = max(0.0, _punch_t - delta)
		if _punch_t == 0.0:
			_end_punch()

	if locked:
		velocity.x = move_toward(velocity.x, 0, SPEED * 4 * delta)
		move_and_slide()
		_apply_invuln_flash()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_ducking:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	if direction != 0.0:
		facing = int(sign(direction))

	_set_ducking(Input.is_action_pressed("duck") and is_on_floor())

	if Input.is_action_just_pressed("punch") and _punch_cd <= 0.0 and not _is_ducking:
		_start_punch()

	move_and_slide()
	_apply_invuln_flash()

func _start_punch() -> void:
	_punch_cd = PUNCH_COOLDOWN
	_punch_t = PUNCH_DURATION
	punch_hitbox.position.x = _default_punch_offset * facing
	punch_visual.visible = true
	punch_hitbox.monitoring = true
	await get_tree().physics_frame
	if not is_inside_tree() or _punch_t <= 0.0:
		return
	for body in punch_hitbox.get_overlapping_bodies():
		if body.is_in_group("chronik") and body.has_method("receive_punch"):
			body.receive_punch(PUNCH_DAMAGE, facing)

func _end_punch() -> void:
	punch_hitbox.monitoring = false
	punch_visual.visible = false

func take_damage(amount: int, from_dir: int) -> void:
	if _invuln_t > 0.0 or hp <= 0:
		return
	hp = max(0, hp - amount)
	_invuln_t = INVULN_DURATION
	velocity.x = from_dir * 350.0
	velocity.y = -400.0
	GameState.player_hp_changed.emit(hp, MAX_HP)
	if hp == 0:
		GameState.player_defeated.emit()

func heal(amount: int) -> void:
	hp = min(MAX_HP, hp + amount)
	GameState.player_hp_changed.emit(hp, MAX_HP)

func _apply_invuln_flash() -> void:
	if _invuln_t > 0.0:
		sprite.modulate.a = 0.4 if int(_invuln_t * 20) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

func _set_ducking(ducking: bool) -> void:
	if ducking == _is_ducking:
		return
	_is_ducking = ducking
	var shape := collider.shape as RectangleShape2D
	if ducking:
		sprite.size = Vector2(_default_sprite_size.x, _default_sprite_size.y * 0.5)
		sprite.position = _default_sprite_pos + Vector2(0, _default_sprite_size.y * 0.5)
		shape.size = Vector2(shape.size.x, _default_collider_height * 0.5)
		collider.position = _default_collider_pos + Vector2(0, _default_collider_height * 0.25)
	else:
		sprite.size = _default_sprite_size
		sprite.position = _default_sprite_pos
		shape.size = Vector2(shape.size.x, _default_collider_height)
		collider.position = _default_collider_pos
