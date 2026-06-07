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
const FLOATING_NUMBER := preload("res://scenes/floating_number.tscn")

# Both characters use individual sprites — one file per pose, declined in 3
# health states. The art itself carries the health look (top form / mid /
# worst), so no colour tint is applied. Sprites are 256x256, character facing
# right, feet near the bottom.
const MALE_SCALE := 1.85
# The visual floor sits ~78 px below the physics-node origin (enemies draw their
# feet that far down to land on it). We anchor the player's feet there too.
const MALE_FLOOR_DROP := 78.0
const WALK_FRAME_TIME := 0.12  # seconds per walk frame
# health_state (GameState) -> sprite suffix.
const MALE_STATE_NAMES := {2: "sante", 1: "malade", 0: "gris"}

# Each entry: "feet" = y of the feet in the 256px canvas (used to drop the feet
# onto the floor), "scale" = per-pose size correction (default 1.0). The _sante
# art is drawn at uneven zoom levels across poses, so its walk/jump/crouch/punch
# frames get a scale < 1 to match the idle size. The on-screen scale and the
# vertical offset are derived from these in _male_frame_transform().
const MALE_POSES := {
	"sante": {
		"idle":  {"file": "res://assets/homme/combat_sante.png", "feet": 211},
		"jump":  {"file": "res://assets/homme/jump_sante.png",   "feet": 196, "scale": 0.63},
		"duck":  {"file": "res://assets/homme/crouch_sante.png", "feet": 195, "scale": 0.65},
		"punch": {"file": "res://assets/homme/punch_sante.png",  "feet": 213, "scale": 0.92},
	},
	"malade": {
		"idle":  {"file": "res://assets/homme/fightneutral_malade.png", "feet": 210},
		"jump":  {"file": "res://assets/homme/jump_malade.png",   "feet": 190},
		"duck":  {"file": "res://assets/homme/crouch_malade.png", "feet": 205},
		"punch": {"file": "res://assets/homme/punch_malade.png",  "feet": 202},
	},
	"gris": {
		"idle":  {"file": "res://assets/homme/fullbody_gris.png", "feet": 232},
		"jump":  {"file": "res://assets/homme/jump_gris.png",     "feet": 197},
		"duck":  {"file": "res://assets/homme/crouch_gris.png",   "feet": 198},
		"punch": {"file": "res://assets/homme/punch_gris.png",    "feet": 221},
	},
}

# Walk cycle frames per state (used for advance/retreat). Cycled over time.
const MALE_WALK := {
	"sante": [
		{"file": "res://assets/homme/walk1_sante.png", "feet": 235, "scale": 0.71},
		{"file": "res://assets/homme/walk2_sante.png", "feet": 240, "scale": 0.73},
		{"file": "res://assets/homme/walk3_sante.png", "feet": 240, "scale": 0.68},
	],
	"malade": [
		{"file": "res://assets/homme/walk1_malade.png", "feet": 208},
		{"file": "res://assets/homme/walk2_malade.png", "feet": 218},
	],
	"gris": [
		{"file": "res://assets/homme/walk1_gris.png", "feet": 224},
		{"file": "res://assets/homme/walk2_gris.png", "feet": 224},
	],
}

# Female — same scheme as the male, art from assets/characters/female/<state>.
# The three states are drawn at different zoom levels, so each pose carries a
# "scale" that normalises it to the healthy-state pose size; "feet" is the
# lowest opaque pixel row in the 256px canvas (drops the feet onto the floor).
# The state folder names double as the sprite-set keys.
const FEMALE_SCALE := 1.62
const FEMALE_FLOOR_DROP := 78.0  # same visual floor as the male
const FEMALE_STATE_NAMES := {2: "woman healthy", 1: "Malade", 0: "Deteriorée"}

const FEMALE_POSES := {
	"woman healthy": {
		"idle":  {"file": "res://assets/characters/female/woman healthy/fightneutral.png", "feet": 225},
		"jump":  {"file": "res://assets/characters/female/woman healthy/jump.png",         "feet": 196},
		"duck":  {"file": "res://assets/characters/female/woman healthy/crouch.png",       "feet": 208},
		"punch": {"file": "res://assets/characters/female/woman healthy/punch.png",        "feet": 217},
	},
	"Malade": {
		"idle":  {"file": "res://assets/characters/female/Malade/fightneutral.png", "feet": 249, "scale": 0.80},
		"jump":  {"file": "res://assets/characters/female/Malade/jump.png",         "feet": 248, "scale": 0.73},
		"duck":  {"file": "res://assets/characters/female/Malade/crouch.png",       "feet": 248, "scale": 0.70},
		"punch": {"file": "res://assets/characters/female/Malade/punch.png",        "feet": 248, "scale": 0.75},
	},
	"Deteriorée": {
		"idle":  {"file": "res://assets/characters/female/Deteriorée/fightneutral.png", "feet": 233, "scale": 0.90},
		"jump":  {"file": "res://assets/characters/female/Deteriorée/jump.png",         "feet": 174, "scale": 1.21},
		"duck":  {"file": "res://assets/characters/female/Deteriorée/crouch.png",       "feet": 202, "scale": 1.08},
		"punch": {"file": "res://assets/characters/female/Deteriorée/punch.png",        "feet": 212, "scale": 1.03},
	},
}

const FEMALE_WALK := {
	"woman healthy": [
		{"file": "res://assets/characters/female/woman healthy/walk1.png", "feet": 215},
		{"file": "res://assets/characters/female/woman healthy/walk2.png", "feet": 214},
	],
	"Malade": [
		{"file": "res://assets/characters/female/Malade/walk1.png", "feet": 248, "scale": 0.75},
		{"file": "res://assets/characters/female/Malade/walk2.png", "feet": 248, "scale": 0.75},
	],
	"Deteriorée": [
		{"file": "res://assets/characters/female/Deteriorée/walk1.png", "feet": 217, "scale": 0.99},
		{"file": "res://assets/characters/female/Deteriorée/walk2.png", "feet": 214, "scale": 1.01},
	],
}

var _tex: Dictionary = {}        # state_name -> { pose -> Texture2D }
var _walk_tex: Dictionary = {}   # state_name -> [ Texture2D, ... ]
var _state_names: Dictionary     # health_state int -> sprite-set name
var _poses_def: Dictionary       # state_name -> { pose -> entry }
var _walk_def: Dictionary        # state_name -> [ entry, ... ]
var _char_scale: float
var _floor_drop: float
var _health_state := GameState.STATE_BLEAK
var _walk_t := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var collider: CollisionShape2D = $Collider
@onready var punch_hitbox: Area2D = $PunchHitbox
@onready var punch_visual: ColorRect = $PunchHitbox/PunchVisual

var hp: int = MAX_HP
var facing: int = 1
var locked: bool = false

var med_charges: Dictionary = {}
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
	med_charges = GameState.med_charges.duplicate()
	var shape := collider.shape as RectangleShape2D
	_default_collider_height = shape.size.y
	_default_collider_pos = collider.position
	_default_punch_offset = abs(punch_hitbox.position.x)
	punch_hitbox.monitoring = false
	punch_visual.visible = false

	if GameState.player_gender == 0:
		_state_names = MALE_STATE_NAMES
		_poses_def = MALE_POSES
		_walk_def = MALE_WALK
		_char_scale = MALE_SCALE
		_floor_drop = MALE_FLOOR_DROP
	else:
		_state_names = FEMALE_STATE_NAMES
		_poses_def = FEMALE_POSES
		_walk_def = FEMALE_WALK
		_char_scale = FEMALE_SCALE
		_floor_drop = FEMALE_FLOOR_DROP
	sprite.region_enabled = false
	for state_name in _poses_def:
		var by_pose := {}
		for pose in _poses_def[state_name]:
			by_pose[pose] = load(_poses_def[state_name][pose]["file"]) as Texture2D
		_tex[state_name] = by_pose
		var frames: Array = []
		for f in _walk_def[state_name]:
			frames.append(load(f["file"]) as Texture2D)
		_walk_tex[state_name] = frames
	_health_state = GameState.get_health_state()
	sprite.texture = _tex[_state_name()]["idle"]
	_apply_transform(_poses_def[_state_name()]["idle"])

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
	GameState.player_buff_changed.emit(false, false, 0.0, 0.0)

func _on_chronik_engaged(_display_name: String, _max_hp: int, _portrait_path: String) -> void:
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
	GameState.med_charges = med_charges.duplicate()
	GameState.med_inventory_changed.emit(med_charges.duplicate())

func _on_health_state_changed(state: int) -> void:
	_health_state = state
	_apply_health_tint(state)

func _state_name() -> String:
	return _state_names.get(_health_state, _state_names[GameState.STATE_BLEAK])

# Applies the per-pose scale and the vertical offset that drops the feet onto
# the visual floor. offset is in pre-scale local space, so the floor drop is
# divided by the total scale.
func _apply_transform(entry: Dictionary) -> void:
	var ps: float = entry.get("scale", 1.0)
	var st := _char_scale * ps
	sprite.scale = Vector2(st, st)
	sprite.offset = Vector2(0.0, (128.0 - float(entry["feet"])) + _floor_drop / st)

func _apply_health_tint(_state: int) -> void:
	# Both characters' art conveys the health state, so keep the sprite
	# untinted (buffs in _apply_visual_state still tint it slightly).
	_base_color = Color.WHITE

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
	AudioManager.play_sfx("med")
	GameState.med_charges = med_charges.duplicate()
	GameState.med_inventory_changed.emit(med_charges.duplicate())

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_punch_cd = max(0.0, _punch_cd - delta)
	_invuln_t = max(0.0, _invuln_t - delta)
	_speed_buff_t = max(0.0, _speed_buff_t - delta)
	_force_buff_t = max(0.0, _force_buff_t - delta)
	_emit_buff_change_if_needed()

	var walking := absf(velocity.x) > 1.0 and is_on_floor() and not _is_ducking and not locked
	_walk_t = _walk_t + delta if walking else 0.0

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
	_push_out_from_enemies()
	_apply_visual_state()

func _start_punch() -> void:
	AudioManager.play_sfx("punch")
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
	_spawn_damage_number(modified)
	AudioManager.play_sfx("hit")
	GameState.player_hp_changed.emit(hp, MAX_HP)
	if hp == 0:
		locked = true
		GameState.player_defeated.emit()

func heal(amount: int) -> void:
	hp = mini(MAX_HP, hp + amount)
	GameState.player_hp_changed.emit(hp, MAX_HP)

func _spawn_damage_number(amount: int) -> void:
	if amount <= 0:
		return
	var n := FLOATING_NUMBER.instantiate()
	get_tree().current_scene.add_child(n)
	n.global_position = global_position + Vector2(0, -260)
	n.set_value(amount, Color(1.0, 0.45, 0.45))

func _emit_buff_change_if_needed() -> void:
	var s_active := _speed_buff_t > 0.0
	var f_active := _force_buff_t > 0.0
	var state_changed := s_active != _last_speed_active or f_active != _last_force_active
	if state_changed or s_active or f_active:
		_last_speed_active = s_active
		_last_force_active = f_active
		GameState.player_buff_changed.emit(s_active, f_active, _speed_buff_t, _force_buff_t)

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

	var state_name := _state_name()
	if pose_name == "advance" or pose_name == "retreat":
		var frames: Array = _walk_tex[state_name]
		var idx := int(_walk_t / WALK_FRAME_TIME) % frames.size()
		sprite.texture = frames[idx]
		_apply_transform(_walk_def[state_name][idx])
	else:
		sprite.texture = _tex[state_name][pose_name]
		_apply_transform(_poses_def[state_name][pose_name])
	sprite.flip_h = flip

func _push_out_from_enemies() -> void:
	const MIN_DIST := 152.0  # demi-largeur joueur (108) + demi-largeur ennemi (40) + marge
	for node in get_tree().get_nodes_in_group("chronik"):
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if absf(global_position.y - enemy.global_position.y) > 300.0:
			continue
		var dx := global_position.x - enemy.global_position.x
		if absf(dx) < MIN_DIST:
			var sep_dir := 1.0 if dx >= 0.0 else -1.0
			global_position.x += sep_dir * (MIN_DIST - absf(dx))
			if velocity.x * sep_dir < 0.0:
				velocity.x = 0.0

func is_ducking() -> bool:
	return _is_ducking

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
