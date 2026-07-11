class_name BattleOverPanel
extends Panel

const MAIN_MENU = "res://scenes/ui/main_menu.tscn"

enum Type {WIN, LOSE}

@onready var label: Label = %Label
@onready var summary_label: Label = %SummaryLabel
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_apply_visuals()
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	main_menu_button.pressed.connect(get_tree().change_scene_to_file.bind(MAIN_MENU))
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	var parts := text.split("\n\n本轮记要\n", false, 1)
	label.text = parts[0]
	summary_label.text = parts[1] if parts.size() > 1 else ""
	summary_label.visible = not summary_label.text.is_empty()
	continue_button.visible = type == Type.WIN
	main_menu_button.visible = type == Type.LOSE
	show()
	get_tree().paused = true
	# 树已暂停，入场动画的 tween 必须设 TWEEN_PAUSE_PROCESS 才会走。
	_animate_entrance.call_deferred(type)


func _animate_entrance(type: Type) -> void:
	modulate = Color(1, 1, 1, 0.0)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * (1.35 if type == Type.WIN else 0.8)
	var visible_button := continue_button if type == Type.WIN else main_menu_button
	visible_button.modulate = Color(1, 1, 1, 0.0)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.38) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.60) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_property(visible_button, "modulate:a", 1.0, 0.30)


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
	summary_label.add_theme_font_size_override("font_size", 22)
	summary_label.add_theme_color_override("font_color", Color("d8c9a4"))
	summary_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	summary_label.add_theme_constant_override("shadow_offset_x", 2)
	summary_label.add_theme_constant_override("shadow_offset_y", 2)
	for button: Button in [continue_button, main_menu_button]:
		button.custom_minimum_size = Vector2(220, 58)
		InkTheme.apply_screen_button(button)
