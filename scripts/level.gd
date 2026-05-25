extends Node2D

@onready var home_btn: TextureButton = $HomeLayer/HomeButton

func _ready() -> void:
	var tex := load("res://assets/sprites/homeButton.png") as Texture2D
	if tex:
		home_btn.texture_normal = tex

	home_btn.pressed.connect(_on_home_pressed)

	GameState.chronik_engaged.connect(_on_chronik_engaged)
	GameState.combat_resolved.connect(_on_combat_resolved)
	GameState.player_defeated.connect(_on_player_defeated)

func _on_chronik_engaged(_display_name: String, _max_hp: int) -> void:
	home_btn.visible = false

func _on_combat_resolved() -> void:
	home_btn.visible = true

func _on_player_defeated() -> void:
	home_btn.visible = false

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/city_map.tscn")
