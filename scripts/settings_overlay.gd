extends CanvasLayer

# Reusable Paramètres + Aide overlay. Instanced over any scene; pauses the tree
# while open so it doubles as the combat pause menu. UI is built in code so the
# same overlay drops into the menu, the map and combat without per-scene wiring.

const PILL_PATHS := {
	"soin": "res://assets/boiteMedicament/pilule soin.png",
	"vitesse": "res://assets/boiteMedicament/pilule vitesse.png",
	"force": "res://assets/boiteMedicament/pilule force.png",
}
const ADHERIX_PATH := "res://assets/buttons/adherix.png"
const TOUCH_PATHS := [
	"res://assets/boutons/Joystick.png",
	"res://assets/boutons/sauter.png",
	"res://assets/boutons/baisser.png",
	"res://assets/boutons/frapper.png",
]

const MED_HELP := {
	"soin": "[b]Soin[/b] : +20 PV. À utiliser quand ta vie est basse.",
	"vitesse": "[b]Vitesse[/b] : ×2 vitesse pendant 10 s. Pour esquiver et te repositionner.",
	"force": "[b]Force[/b] : ×2 dégâts pendant 10 s. Pour achever un Chronik plus vite.",
}
const MED_NOTE := "Réserve limitée : 1 dose de chaque. La boîte ne se recharge qu'une fois le quartier entièrement libéré. Gère tes doses !"
const CONTROLS_TEXT := "[b]Clavier[/b]\n• Se déplacer : ◀ ▶  (ou A / D)\n• Sauter : ▲ / Espace / W\n• Se baisser (esquiver) : ▼ / S\n• Frapper : X / J\n• Médicaments : 1 Soin · 2 Vitesse · 3 Force\n\n[b]Tactile[/b]\n• Joystick (gauche) : se déplacer\n• Boutons : Sauter, Se baisser, Frapper\n• Boutons Médicaments : Soin / Vitesse / Force"
const OBJECTIVE_TEXT := "Libère les quartiers de [b]Seek City[/b] en battant tous les Chroniks de chaque quartier. Chaque quartier libéré débloque le suivant et t'accorde l'[b]Adrénaline[/b] (+70 PV).\n\n[b]Boost quotidien[/b] : reviens chaque jour ouvrir le coffre. Maintenir ton traitement améliore ton état de santé et réduit les dégâts subis (jusqu'à −50 %). Le traitement n'est pas un super-pouvoir : il t'aide à rester stable et à continuer d'avancer."
const CHARACTERS_TEXT := "[b]Adhérix[/b] : ton guide. Un Mini-Chronik inoffensif, seul de son espèce, qui t'accompagne tout au long de l'aventure.\n\n[b]Les Chroniks[/b] : les ennemis — des maladies chroniques nées des traitements abandonnés et des oublis de médicaments. Bats-les pour libérer la ville."

var _param_panel: Control
var _help_panel: Control
var _sliders: Dictionary = {}
var _slider_value_labels: Dictionary = {}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func open() -> void:
	visible = true
	get_tree().paused = true
	_show_param()

func open_help() -> void:
	visible = true
	get_tree().paused = true
	_show_help()

func close() -> void:
	AudioManager.save_settings()
	get_tree().paused = false
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		if _help_panel.visible:
			_show_param()
		else:
			close()
		get_viewport().set_input_as_handled()

func _show_param() -> void:
	_param_panel.visible = true
	_help_panel.visible = false

func _show_help() -> void:
	_param_panel.visible = false
	_help_panel.visible = true

# ----------------------------------------------------------------- UI building

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_param_panel = _build_param_panel()
	center.add_child(_param_panel)
	_help_panel = _build_help_panel()
	center.add_child(_help_panel)

func _build_param_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	var margin := _margin(28)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	vbox.add_child(_title("Paramètres"))
	_sliders["master"] = _add_volume_row(vbox, "Volume principal", AudioManager.master_volume)
	_sliders["music"] = _add_volume_row(vbox, "Musique", AudioManager.music_volume)
	_sliders["sfx"] = _add_volume_row(vbox, "Effets (SFX)", AudioManager.sfx_volume)

	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 16)
	var fs_label := Label.new()
	fs_label.text = "Plein écran"
	fs_label.custom_minimum_size = Vector2(220, 0)
	fs_row.add_child(fs_label)
	var fs_check := CheckButton.new()
	fs_check.button_pressed = AudioManager.fullscreen
	fs_check.toggled.connect(func(on: bool) -> void:
		AudioManager.play_sfx("click")
		AudioManager.set_fullscreen(on))
	fs_row.add_child(fs_check)
	vbox.add_child(fs_row)

	vbox.add_child(_spacer(8))
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	var help_btn := _button("Aide", Vector2(220, 56))
	help_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_show_help())
	btn_row.add_child(help_btn)
	var close_btn := _button("Fermer", Vector2(220, 56))
	close_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		close())
	btn_row.add_child(close_btn)
	vbox.add_child(btn_row)
	return panel

func _add_volume_row(parent: Node, label_text: String, value: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(220, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var val_label := Label.new()
	val_label.text = "%d %%" % round(value * 100.0)
	val_label.custom_minimum_size = Vector2(70, 0)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_label)
	parent.add_child(row)
	_slider_value_labels[label_text] = val_label
	slider.value_changed.connect(func(v: float) -> void:
		val_label.text = "%d %%" % round(v * 100.0)
		_on_volume_changed(label_text, v))
	return slider

func _on_volume_changed(label_text: String, v: float) -> void:
	match label_text:
		"Volume principal": AudioManager.set_master_volume(v)
		"Musique": AudioManager.set_music_volume(v)
		"Effets (SFX)": AudioManager.set_sfx_volume(v)

func _build_help_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 560)
	var margin := _margin(24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	vbox.add_child(_title("Aide"))
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 20)
	vbox.add_child(tabs)
	tabs.add_child(_controls_tab())
	tabs.add_child(_meds_tab())
	tabs.add_child(_text_tab("Objectif", OBJECTIVE_TEXT))
	tabs.add_child(_characters_tab())

	var back_btn := _button("Retour", Vector2(220, 52))
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		_show_param())
	vbox.add_child(back_btn)
	return panel

func _controls_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Contrôles"
	root.add_theme_constant_override("separation", 12)
	var inner := _margin(16)
	root.add_child(inner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	inner.add_child(box)
	box.add_child(_rich(CONTROLS_TEXT))
	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 18)
	for p in TOUCH_PATHS:
		var tex := _tex(p)
		if tex != null:
			icons.add_child(_icon(tex, 64))
	box.add_child(icons)
	return root

func _meds_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Médicaments"
	var inner := _margin(16)
	root.add_child(inner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	inner.add_child(box)
	for med_id in ["soin", "vitesse", "force"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var tex := _tex(PILL_PATHS[med_id])
		if tex != null:
			row.add_child(_icon(tex, 56))
		var rich := _rich(MED_HELP[med_id])
		rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rich.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(rich)
		box.add_child(row)
	box.add_child(_rich(MED_NOTE))
	return root

func _characters_tab() -> Control:
	var root := HBoxContainer.new()
	root.name = "Personnages"
	root.add_theme_constant_override("separation", 20)
	var inner := _margin(16)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(inner)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	inner.add_child(hb)
	var portrait := _tex(ADHERIX_PATH)
	if portrait != null:
		hb.add_child(_icon(portrait, 220))
	var rich := _rich(CHARACTERS_TEXT)
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(rich)
	return root

func _text_tab(tab_name: String, text: String) -> Control:
	var root := VBoxContainer.new()
	root.name = tab_name
	var inner := _margin(16)
	root.add_child(inner)
	inner.add_child(_rich(text))
	return root

# --------------------------------------------------------------- small helpers

func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _rich(bbcode: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", 20)
	r.add_theme_font_size_override("bold_font_size", 20)
	r.text = bbcode
	return r

func _icon(tex: Texture2D, box: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(box, box)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

func _button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 24)
	return b

func _margin(m: int) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", m)
	mc.add_theme_constant_override("margin_right", m)
	mc.add_theme_constant_override("margin_top", m)
	mc.add_theme_constant_override("margin_bottom", m)
	return mc

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null
