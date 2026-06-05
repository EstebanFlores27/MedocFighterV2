extends Control

const MENU_SCENE := "res://scenes/main_menu.tscn"
const ENDING_MALE := "res://assets/ending/homme_avec texte.png"
const ENDING_FEMALE := "res://assets/ending/femme_avec texte.png"

@onready var image: TextureRect = $Image

func _ready() -> void:
	var path := ENDING_FEMALE if GameState.player_gender == 1 else ENDING_MALE
	image.texture = load(path)
	image.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(image, "modulate:a", 1.0, 0.4)

func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if pressed:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MENU_SCENE)
