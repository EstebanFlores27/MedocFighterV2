extends Control

@onready var male_btn: Button      = $CenterContainer/VBox/HBox/MaleCard/MaleBtn
@onready var female_btn: Button    = $CenterContainer/VBox/HBox/FemaleCard/FemaleBtn
@onready var male_image: TextureRect   = $CenterContainer/VBox/HBox/MaleCard/MaleImage
@onready var female_image: TextureRect = $CenterContainer/VBox/HBox/FemaleCard/FemaleImage

func _ready() -> void:
	male_btn.pressed.connect(_on_choose_male)
	female_btn.pressed.connect(_on_choose_female)
	male_btn.grab_focus()
	_apply_white_removal(male_image)
	_apply_white_removal(female_image)

func _apply_white_removal(node: TextureRect) -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float is_white = step(0.97, min(c.r, min(c.g, c.b)));
	COLOR = vec4(c.rgb, c.a * (1.0 - is_white));
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	node.material = mat

func _on_choose_male() -> void:
	GameState.player_gender = 0
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_choose_female() -> void:
	GameState.player_gender = 1
	get_tree().change_scene_to_file("res://scenes/intro.tscn")
