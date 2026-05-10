extends Control

@onready var new_game_btn: Button = $CenterContainer/VBox/NewGameBtn
@onready var continue_btn: Button = $CenterContainer/VBox/ContinueBtn
@onready var quit_btn: Button = $CenterContainer/VBox/QuitBtn

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	quit_btn.pressed.connect(_on_quit)
	continue_btn.disabled = true
	new_game_btn.grab_focus()

func _on_new_game() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_quit() -> void:
	get_tree().quit()
