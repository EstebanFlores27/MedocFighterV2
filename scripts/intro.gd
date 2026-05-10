extends Control

const TYPE_SPEED := 0.022

const PAGES: Array[String] = [
	"Psst ! Hé, toi ! De l'autre côté de la vitre ! Baisse les yeux, je suis là !",
	"Ne panique pas, je sais que j'ai une tête de monstre, mais je suis inoffensif. Je m'appelle Mini-Chronik. Je suis une sorte d'anomalie... le seul et unique de mon espèce. Et honnêtement, heureusement que tu es là, parce que j'ai besoin d'aide.",
	"Je vois que tu es en noir et blanc. C'est parce que le diagnostic vient de tomber, tu viens d'apprendre que tu as une maladie chronique. C'est normal que tu sois épuisé et que tu commences tout en bas.",
	"Tu vois ces ombres immenses ? Ce sont les Chroniks. Ce sont des maladies nées des traitements abandonnés, de la négligence et des oublis de médicaments des patients de cette ville. Ils ont envahi Seek City.",
	"Pour des raisons de sécurité, le dôme a verrouillé la ville quartier par quartier. On ne peut pas aller partout d'un coup. Il faut affronter les Chroniks d'un quartier pour débloquer le suivant.",
	"Voici ta boîte de médicaments d'urgence. À l'intérieur, 3 médicaments aux effets différents :\n\n• Soin — répare tes dommages, +20 PV.\n• Vitesse — ×2 vitesse de déplacement.\n• Force — ×2 dégâts de tes coups.",
	"Attention ! Aucun réapprovisionnement de la boîte avant que tu battes TOUS les monstres du quartier. Gère chaque dose pour tenir jusqu'au bout.",
	"Au bout de chaque quartier se dresse une menace plus sombre que les autres. En la vainquant, tu débloques l'Adrénaline : +70 PV pour repartir frais à la suite.",
	"Allez, en route ! Le dôme s'ouvre. La carte de Seek City t'attend.",
]

@onready var dialog_label: Label = $DialogPanel/Margin/VBox/DialogLabel
@onready var page_label: Label = $DialogPanel/Margin/VBox/NextRow/PageLabel
@onready var next_btn: Button = $DialogPanel/Margin/VBox/NextRow/NextBtn
@onready var skip_btn: Button = $TopBar/SkipBtn

var _idx: int = 0
var _is_typing: bool = false
var _text_tween: Tween

func _ready() -> void:
	next_btn.pressed.connect(_advance)
	skip_btn.pressed.connect(_skip)
	_show_page()
	next_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER:
			_advance()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			_skip()
			get_viewport().set_input_as_handled()

func _show_page() -> void:
	dialog_label.text = PAGES[_idx]
	dialog_label.visible_characters = 0
	page_label.text = "%d / %d" % [_idx + 1, PAGES.size()]
	next_btn.text = "Entrer dans Seek City ▶" if _idx == PAGES.size() - 1 else "Continuer ▶"
	_is_typing = true
	if _text_tween:
		_text_tween.kill()
	var char_count := dialog_label.get_total_character_count()
	_text_tween = create_tween()
	_text_tween.tween_property(dialog_label, "visible_characters", char_count, char_count * TYPE_SPEED)
	_text_tween.tween_callback(func() -> void: _is_typing = false)

func _advance() -> void:
	if _is_typing:
		if _text_tween:
			_text_tween.kill()
		dialog_label.visible_characters = -1
		_is_typing = false
		return
	_idx += 1
	if _idx >= PAGES.size():
		_go_to_map()
	else:
		_show_page()

func _skip() -> void:
	_go_to_map()

func _go_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/city_map.tscn")
