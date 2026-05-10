extends Control

const ACTIVATION_THRESHOLD := 0.3
const DUCK_THRESHOLD := 0.5
const JUMP_THRESHOLD := -0.5
const KNOB_RADIUS := 100.0

@onready var knob: Panel = $Knob

var _touch_index: int = -1
var _last_jump: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_reset_knob)
	_reset_knob()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1 and _has_point(t.position):
			_touch_index = t.index
			_update_knob(t.position)
			get_viewport().set_input_as_handled()
		elif (not t.pressed) and t.index == _touch_index:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update_knob(d.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed and _touch_index == -1 and _has_point(m.position):
				_touch_index = -2
				_update_knob(m.position)
				get_viewport().set_input_as_handled()
			elif (not m.pressed) and _touch_index == -2:
				_release()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _touch_index == -2:
		_update_knob((event as InputEventMouseMotion).position)

func _has_point(global_pos: Vector2) -> bool:
	return get_global_rect().has_point(global_pos)

func _update_knob(global_pos: Vector2) -> void:
	var local := global_pos - global_position
	var center := size / 2
	var v := local - center
	if v.length() > KNOB_RADIUS:
		v = v.normalized() * KNOB_RADIUS
	knob.position = center - knob.size / 2 + v
	var dir := v / KNOB_RADIUS
	_set_action("move_left", dir.x < -ACTIVATION_THRESHOLD)
	_set_action("move_right", dir.x > ACTIVATION_THRESHOLD)
	_set_action("duck", dir.y > DUCK_THRESHOLD)
	var jump := dir.y < JUMP_THRESHOLD
	if jump and not _last_jump:
		Input.action_press("jump")
	elif (not jump) and _last_jump:
		Input.action_release("jump")
	_last_jump = jump

func _reset_knob() -> void:
	if knob == null:
		return
	var center := size / 2
	knob.position = center - knob.size / 2

func _release() -> void:
	_touch_index = -1
	_reset_knob()
	_set_action("move_left", false)
	_set_action("move_right", false)
	_set_action("duck", false)
	if _last_jump:
		Input.action_release("jump")
		_last_jump = false

func _set_action(action_name: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action_name):
		Input.action_press(action_name)
	elif (not pressed) and Input.is_action_pressed(action_name):
		Input.action_release(action_name)
