extends Button

@export var action: String = ""

func _ready() -> void:
	button_down.connect(_on_press)
	button_up.connect(_on_release)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_press() -> void:
	if action != "" and InputMap.has_action(action):
		Input.action_press(action)

func _on_release() -> void:
	if action != "" and InputMap.has_action(action):
		Input.action_release(action)
