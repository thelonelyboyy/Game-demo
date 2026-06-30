class_name BattleOverPanel
extends Panel

const MAIN_MENU = "res://scenes/ui/main_menu.tscn"

enum Type {WIN, LOSE}

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_apply_visuals()
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	main_menu_button.pressed.connect(get_tree().change_scene_to_file.bind(MAIN_MENU))
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	label.text = text
	continue_button.visible = type == Type.WIN
	main_menu_button.visible = type == Type.LOSE
	show()
	get_tree().paused = true


func _apply_visuals() -> void:
	add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.018, 0.010, 0.010, 0.88),
		Color(0.60, 0.42, 0.22, 0.24),
		1,
		0,
		Color(0, 0, 0, 0.55),
		0
	))
	InkTheme.apply_screen_title(label, 48)
	for button: Button in [continue_button, main_menu_button]:
		button.custom_minimum_size = Vector2(220, 58)
		InkTheme.apply_screen_button(button)
