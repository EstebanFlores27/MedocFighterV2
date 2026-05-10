extends CharacterBody2D
class_name Chronik

const GRAVITY := 2200.0
const ATTACK_COOLDOWN := 0.9
const HIT_FLASH_DURATION := 0.3
const STOP_DISTANCE := 90.0

@export var chronik_id: String = "cortexia"
@export var display_name: String = "Cortexia"
@export var district_id: int = 1
@export var max_hp: int = 60
@export var contact_damage: int = 10
@export var move_speed: float = 240.0
@export var size_scale: float = 1.0
@export var color: Color = Color(0.85, 0.45, 0.85)
@export_multiline var victory_text: String = ""

@onready var sprite: ColorRect = $Sprite
@onready var collider: CollisionShape2D = $Collider
@onready var detect_area: Area2D = $DetectArea
@onready var contact_area: Area2D = $ContactArea

var hp: int
var target: Node2D
var engaged: bool = false
var active: bool = false
var _attack_cd := 0.0
var _hit_flash := 0.0
var _facing := -1

func _ready() -> void:
	add_to_group("chronik")
	hp = max_hp
	sprite.color = color
	if size_scale != 1.0:
		_apply_size_scale()
	detect_area.body_entered.connect(_on_player_detected)
	GameState.combat_countdown_done.connect(_on_countdown_done)

func _apply_size_scale() -> void:
	sprite.size *= size_scale
	sprite.position *= size_scale
	var body_shape := (collider.shape as RectangleShape2D).duplicate() as RectangleShape2D
	body_shape.size *= size_scale
	collider.shape = body_shape
	collider.position *= size_scale
	var contact_shape_node: CollisionShape2D = contact_area.get_node("ContactShape")
	var contact_rect := (contact_shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
	contact_rect.size *= size_scale
	contact_shape_node.shape = contact_rect
	contact_area.position *= size_scale

func _on_player_detected(body: Node) -> void:
	if engaged or hp <= 0:
		return
	if not body.is_in_group("player"):
		return
	target = body
	engaged = true
	GameState.chronik_engaged.emit(display_name, max_hp)
	GameState.chronik_hp_changed.emit(hp, max_hp)

func _on_countdown_done() -> void:
	if engaged and hp > 0:
		active = true

func receive_punch(damage: int, from_dir: int) -> void:
	if hp <= 0:
		return
	hp = max(0, hp - damage)
	_hit_flash = HIT_FLASH_DURATION
	velocity.x = from_dir * 280.0
	velocity.y = -220.0
	GameState.chronik_hp_changed.emit(hp, max_hp)
	if hp == 0:
		_die()

func _die() -> void:
	active = false
	GameState.chronik_defeated.emit(display_name, victory_text)
	GameState.register_chronik_defeated(chronik_id, district_id)
	contact_area.set_deferred("monitoring", false)
	detect_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_attack_cd = max(0.0, _attack_cd - delta)
	_hit_flash = max(0.0, _hit_flash - delta)

	if active and is_instance_valid(target) and hp > 0:
		var dx := target.global_position.x - global_position.x
		var dist := absf(dx)
		_facing = -1 if dx < 0 else 1
		if dist > STOP_DISTANCE:
			velocity.x = _facing * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed * 4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 4 * delta)

	move_and_slide()
	_check_contact_damage()
	_apply_hit_flash()

func _check_contact_damage() -> void:
	if not active or hp <= 0 or _attack_cd > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage, _facing)
			_attack_cd = ATTACK_COOLDOWN
			velocity.x = -_facing * 200.0
			break

func _apply_hit_flash() -> void:
	if hp <= 0:
		return
	if _hit_flash > 0.0:
		var on_frame := int(_hit_flash * 20) % 2 == 0
		sprite.modulate = Color(1.6, 0.6, 0.6, sprite.modulate.a) if on_frame else Color(1, 1, 1, sprite.modulate.a)
	else:
		sprite.modulate = Color(1, 1, 1, sprite.modulate.a)
