extends CharacterBody2D
class_name Chronik

const GRAVITY := 2200.0
const ATTACK_COOLDOWN := 0.9
const HIT_FLASH_DURATION := 0.3
const STOP_DISTANCE := 148.0
const WALK_FRAME_DURATION := 0.18
const PUNCH_DISPLAY_DURATION := 0.35

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
@onready var char_sprite: Sprite2D = $CharSprite
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

var _has_sprite := false
var _sprite_faces_right := false       # orientation des sprites idle/punch/fullbody
var _sprite_walk_faces_right := false  # orientation des sprites de marche (peut différer)
var _tex_fullbody: Texture2D
var _tex_fight_neutral: Texture2D
var _tex_walk1: Texture2D
var _tex_walk2: Texture2D
var _tex_jump: Texture2D
var _tex_punch: Texture2D
var _walk_timer := 0.0
var _walk_frame := 0
var _punch_timer := 0.0

func _ready() -> void:
	add_to_group("chronik")
	if chronik_id in GameState.defeated_chroniks:
		process_mode = Node.PROCESS_MODE_DISABLED
		hide()
		call_deferred("queue_free")
		return
	hp = max_hp
	sprite.color = color
	if size_scale != 1.0:
		_apply_size_scale()
	_load_sprites()
	detect_area.body_entered.connect(_on_player_detected)
	GameState.combat_countdown_done.connect(_on_countdown_done)
	GameState.player_defeated.connect(_on_player_defeated)

func _load_sprites() -> void:
	match chronik_id:
		"cortexia":
			_tex_fullbody      = load("res://assets/spritesEnnemi1/fullbody.png")
			_tex_fight_neutral = load("res://assets/spritesEnnemi1/fight_neutral.png")
			_tex_walk1         = load("res://assets/spritesEnnemi1/walk1.png")
			_tex_walk2         = load("res://assets/spritesEnnemi1/walk2.png")
			_tex_jump          = load("res://assets/spritesEnnemi1/jump.png")
			_tex_punch         = load("res://assets/spritesEnnemi1/punch.png")
		"epidermos":
			_sprite_faces_right      = false  # idle/punch/fullbody regardent à gauche
			_sprite_walk_faces_right = true   # walk1/walk2 regardent à droite
			_tex_fullbody      = load("res://assets/spritesEnnemi2/fullbody.png")
			_tex_fight_neutral = load("res://assets/spritesEnnemi2/fightneutral.png")
			_tex_walk1         = load("res://assets/spritesEnnemi2/walk1.png")
			_tex_walk2         = load("res://assets/spritesEnnemi2/walk2.png")
			_tex_jump          = load("res://assets/spritesEnnemi2/jump.png")
			_tex_punch         = load("res://assets/spritesEnnemi2/punch.png")
		_:
			return
	_has_sprite = true
	sprite.hide()
	char_sprite.texture = _tex_fullbody
	char_sprite.show()

func _update_sprite(delta: float) -> void:
	if not _has_sprite:
		return

	# En l'air après avoir reçu un coup
	if not is_on_floor() and velocity.y < -30.0:
		char_sprite.texture = _tex_jump
		char_sprite.flip_h = (_facing == 1) if not _sprite_walk_faces_right else (_facing == -1)
		return

	# Animation de coup (l'ennemi attaque)
	if _punch_timer > 0.0:
		char_sprite.texture = _tex_punch
		char_sprite.flip_h = (_facing == 1) if not _sprite_faces_right else (_facing == -1)
		_punch_timer -= delta
		return

	# Avant d'être engagé : pose relaxée
	if not engaged:
		char_sprite.texture = _tex_fullbody
		char_sprite.flip_h = (_facing == 1) if not _sprite_faces_right else (_facing == -1)
		return

	# En déplacement : alterner walk1 / walk2 (peut avoir une orientation différente)
	if absf(velocity.x) > 10.0:
		_walk_timer += delta
		if _walk_timer >= WALK_FRAME_DURATION:
			_walk_timer = 0.0
			_walk_frame = 1 - _walk_frame
		char_sprite.texture = _tex_walk1 if _walk_frame == 0 else _tex_walk2
		char_sprite.flip_h = (_facing == 1) if not _sprite_walk_faces_right else (_facing == -1)
		return

	# Garde de combat (immobile, au contact)
	char_sprite.texture = _tex_fight_neutral
	char_sprite.flip_h = (_facing == 1) if not _sprite_faces_right else (_facing == -1)

func _on_player_defeated() -> void:
	active = false
	velocity.x = 0

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
	var fade_node: CanvasItem = char_sprite if _has_sprite else sprite
	var tween := create_tween()
	tween.tween_property(fade_node, "modulate:a", 0.0, 0.6)
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
	_update_sprite(delta)
	_apply_hit_flash()

func _check_contact_damage() -> void:
	if not active or hp <= 0 or _attack_cd > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			_attack_cd = ATTACK_COOLDOWN
			_punch_timer = PUNCH_DISPLAY_DURATION
			velocity.x = -_facing * 200.0
			if body.has_method("is_ducking") and body.is_ducking():
				break  # attaque esquivée par l'accroupissement
			body.take_damage(contact_damage, _facing)
			break

func _apply_hit_flash() -> void:
	if hp <= 0:
		return
	var target_node: CanvasItem = char_sprite if _has_sprite else sprite
	if _hit_flash > 0.0:
		var on_frame := int(_hit_flash * 20) % 2 == 0
		target_node.modulate = Color(1.6, 0.6, 0.6, target_node.modulate.a) if on_frame else Color(1, 1, 1, target_node.modulate.a)
	else:
		target_node.modulate = Color(1, 1, 1, target_node.modulate.a)
