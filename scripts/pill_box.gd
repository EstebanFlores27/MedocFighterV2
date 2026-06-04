extends Control

# Weekly 7-day pill organizer shown in the city-map daily panel.
# Taken days = empty compartment, today = colored pill, future = grey pills.
# Opening plays: lid opens (closed -> open) then today's pill pops and fades.

const BOX_OPEN := "res://assets/dailyBox/dailybox_vide.png"
const BOX_CLOSED := "res://assets/dailyBox/dailybox_fermé.png"
const PILL_COLOR := "res://assets/dailyBox/pilule du jour_coloré.png"
const PILL_GREY := "res://assets/dailyBox/pilules futures_grises.png"
# Compartment centers as a fraction of the open-box image.
const SLOT_XS := [0.203, 0.306, 0.405, 0.504, 0.603, 0.703, 0.801]
const SLOT_Y := 0.518
const PILL_W_FRAC := 0.095

var _open_box: TextureRect
var _closed_box: TextureRect
var _pills: Array[TextureRect] = []
var _tex_color: Texture2D
var _tex_grey: Texture2D
var _animating := false
var _week_taken := 0
var _available := true

func _ready() -> void:
	clip_contents = true
	_tex_color = _load(PILL_COLOR)
	_tex_grey = _load(PILL_GREY)
	_open_box = _make_box(BOX_OPEN)
	add_child(_open_box)
	for i in 7:
		var p := TextureRect.new()
		p.texture = _tex_grey
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		_pills.append(p)
	_closed_box = _make_box(BOX_CLOSED)
	add_child(_closed_box)
	resized.connect(_layout)
	_apply_state(_week_taken, _available)

func set_state(week_taken: int, available: bool) -> void:
	if _animating:
		return
	_apply_state(week_taken, available)

func play_consume(slot: int, new_taken: int, new_available: bool) -> void:
	_animating = true
	_layout()
	var pill := _pills[slot]
	pill.visible = true
	pill.texture = _tex_color
	pill.modulate.a = 1.0
	pill.scale = Vector2.ONE
	var tw := create_tween()
	tw.tween_property(_closed_box, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: _closed_box.visible = false)
	tw.tween_property(pill, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(pill, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		_animating = false
		_apply_state(new_taken, new_available))

func _apply_state(week_taken: int, available: bool) -> void:
	_week_taken = week_taken
	_available = available
	for i in 7:
		var p := _pills[i]
		p.scale = Vector2.ONE
		p.modulate.a = 1.0
		if i < week_taken:
			p.visible = false
		elif i == week_taken:
			p.visible = true
			p.texture = _tex_color if available else _tex_grey
		else:
			p.visible = true
			p.texture = _tex_grey
	_closed_box.visible = available
	_closed_box.modulate.a = 1.0
	_layout()

func _layout(_unused := Vector2.ZERO) -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var pw := w * PILL_W_FRAC
	var ph := pw / 1.5
	for i in 7:
		var p := _pills[i]
		p.size = Vector2(pw, ph)
		p.pivot_offset = Vector2(pw, ph) / 2.0
		p.position = Vector2(float(SLOT_XS[i]) * w - pw / 2.0, SLOT_Y * h - ph / 2.0)

func _make_box(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	return t

func _load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null
