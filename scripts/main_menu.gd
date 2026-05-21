extends Control

@onready var new_game_btn: Button = $CenterContainer/VBox/NewGameBtn
@onready var continue_btn: Button = $CenterContainer/VBox/ContinueBtn
@onready var quit_btn: Button = $CenterContainer/VBox/QuitBtn

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)
	var has_save := GameState.has_save_file()
	continue_btn.disabled = not has_save
	if has_save:
		continue_btn.grab_focus()
	else:
		new_game_btn.grab_focus()

func _on_new_game() -> void:
	GameState.reset_progress()
	GameState.clear_save()
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_continue() -> void:
	if not GameState.load_from_disk():
		return
	get_tree().change_scene_to_file("res://scenes/city_map.tscn")

func _on_quit() -> void:
	get_tree().quit()
