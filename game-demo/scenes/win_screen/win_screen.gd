class_name WinScreen
extends Control

const MAIN_MENU_PATH = "res://scenes/ui/main_menu.tscn"
const WIN_BACKGROUND := preload("res://art/backgrounds/main_menu_background_v2.png")
const MESSAGE := "%s\n渡劫功成！"

@export var character: CharacterStats : set = set_character

@onready var background: TextureRect = $Background
@onready var message: Label = %Message
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var main_menu_button: Button = $VboxContainer/MainMenuButton


func _ready() -> void:
	InkTheme.animate_screen_entrance(self, 0.45)
	_apply_visuals()


func set_character(new_character: CharacterStats) -> void:
	character = new_character
	message.text = MESSAGE % character.character_name
	character_portrait.texture = character.portrait


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _apply_visuals() -> void:
	background.texture = WIN_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.72, 0.62, 0.55, 0.88)

	_ensure_dimmer()
	InkTheme.apply_screen_title(message, 44)
	InkTheme.apply_screen_button(main_menu_button)
	main_menu_button.custom_minimum_size = Vector2(240, 62)

	character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _ensure_dimmer() -> void:
	if has_node("Dimmer"):
		return
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.018, 0.010, 0.010, 0.46)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	move_child(dimmer, background.get_index() + 1)
