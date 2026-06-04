extends CanvasLayer

# Adhérix's tutorial bubble. Pops in a bottom corner with his portrait + a short
# tip, non-blocking (the game keeps running). Dismissed by the button or after a
# delay. Messages queue, so several tips at the same moment play one at a time.
# Reused on the map and in combat; one CanvasLayer so it sits above HUDs.

const ADHERIX_PATH := "res://assets/buttons/adherix.png"
const AUTO_DISMISS := 8.0

var _root: Control
var _hb: HBoxContainer
var _label: RichTextLabel
var _queue: Array[String] = []
var _showing: bool = false
var _token: int = 0

func _ready() -> void:
	layer = 60
	_build()
	visible = false

# Switch to a top-anchored position. Used in combat, where the bottom corners
# are taken by the touch joystick / action buttons.
func place_top() -> void:
	_hb.anchor_top = 0.0
	_hb.anchor_bottom = 0.0
	_hb.offset_top = 150.0
	_hb.offset_bottom = 360.0
	_hb.grow_vertical = Control.GROW_DIRECTION_END
	for child in _hb.get_children():
		(child as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func show_message(text: String) -> void:
	_queue.append(text)
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		var out := create_tween()
		out.tween_property(_root, "modulate:a", 0.0, 0.2)
		out.tween_callback(func() -> void: visible = false)
		return
	_showing = true
	_token += 1
	var my_token := _token
	_label.text = _queue.pop_front()
	visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.25)
	var timer := get_tree().create_timer(AUTO_DISMISS)
	timer.timeout.connect(func() -> void:
		if my_token == _token:
			_advance())

func _advance() -> void:
	_token += 1  # invalidate any pending auto-dismiss for the current message
	_show_next()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var hb := HBoxContainer.new()
	_hb = hb
	hb.add_theme_constant_override("separation", 14)
	hb.anchor_left = 0.0
	hb.anchor_right = 0.0
	hb.anchor_top = 1.0
	hb.anchor_bottom = 1.0
	hb.offset_left = 30.0
	hb.offset_top = -230.0
	hb.offset_right = 790.0
	hb.offset_bottom = -30.0
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(hb)

	if ResourceLoader.exists(ADHERIX_PATH):
		var portrait := TextureRect.new()
		portrait.texture = load(ADHERIX_PATH)
		portrait.custom_minimum_size = Vector2(170, 170)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_vertical = Control.SIZE_SHRINK_END
		hb.add_child(portrait)

	var bubble := PanelContainer.new()
	bubble.size_flags_vertical = Control.SIZE_SHRINK_END
	bubble.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.20, 0.96)
	sb.set_corner_radius_all(18)
	sb.border_color = Color(0.58, 0.46, 0.86)
	sb.set_border_width_all(3)
	for side in ["content_margin_left", "content_margin_right", "content_margin_top", "content_margin_bottom"]:
		sb.set(side, 18.0)
	bubble.add_theme_stylebox_override("panel", sb)
	hb.add_child(bubble)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	bubble.add_child(vb)

	var name_label := Label.new()
	name_label.text = "Adhérix"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.66, 1.0))
	vb.add_child(name_label)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(520, 0)
	_label.add_theme_font_size_override("normal_font_size", 20)
	_label.add_theme_font_size_override("bold_font_size", 20)
	vb.add_child(_label)

	var ok_btn := Button.new()
	ok_btn.text = "Compris !"
	ok_btn.custom_minimum_size = Vector2(160, 44)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_advance())
	vb.add_child(ok_btn)
