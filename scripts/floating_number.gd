extends Node2D

# Short-lived "-10" that floats up and fades, then frees itself. Spawned in the
# world at the hit position to make damage (and Force buffs) readable.

@onready var _label: Label = $Label

func set_value(amount: int, color: Color) -> void:
	# Deferred-safe: store until _ready if called before the node is in tree.
	if _label == null:
		_pending = {"amount": amount, "color": color}
		return
	_apply(amount, color)

var _pending: Dictionary = {}

func _ready() -> void:
	if not _pending.is_empty():
		_apply(int(_pending["amount"]), _pending["color"])
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 90.0, 0.7)
	tween.tween_property(_label, "modulate:a", 0.0, 0.6).set_delay(0.15)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _apply(amount: int, color: Color) -> void:
	_label.text = "-%d" % amount
	_label.add_theme_color_override("font_color", color)
