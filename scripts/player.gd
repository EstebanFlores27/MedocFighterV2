extends CharacterBody2D

const SPEED := 420.0
const JUMP_VELOCITY := -900.0
const GRAVITY := 2200.0

@onready var sprite: ColorRect = $Sprite
@onready var collider: CollisionShape2D = $Collider

var _is_ducking := false
var _default_sprite_size: Vector2
var _default_sprite_pos: Vector2
var _default_collider_height: float
var _default_collider_pos: Vector2

func _ready() -> void:
	_default_sprite_size = sprite.size
	_default_sprite_pos = sprite.position
	var shape := collider.shape as RectangleShape2D
	_default_collider_height = shape.size.y
	_default_collider_pos = collider.position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_ducking:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	_set_ducking(Input.is_action_pressed("duck") and is_on_floor())

	move_and_slide()

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
