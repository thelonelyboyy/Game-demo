class_name PauseMenu
extends CanvasLayer

signal save_and_quit

@onready var back_to_game_button: Button = %BackToGameButton
@onready var save_and_quit_button: Button = %SaveAndQuitButton
@onready var panel: PanelContainer = $CenterPanel
@onready var title: Label = $CenterPanel/MarginContainer/VBoxContainer/Title
@onready var subtitle: Label = $CenterPanel/MarginContainer/VBoxContainer/Subtitle
@onready var actions: VBoxContainer = $CenterPanel/MarginContainer/VBoxContainer/Actions


func _ready() -> void:
	_apply_visuals()
	back_to_game_button.pressed.connect(_unpause)
	save_and_quit_button.pressed.connect(_on_save_and_quit_button_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_unpause()
		else:
			_pause()
			
		get_viewport().set_input_as_handled()


func _pause() -> void:
	show()
	get_tree().paused = true
	back_to_game_button.grab_focus()


func _unpause() -> void:
	hide()
	get_tree().paused = false


func _on_save_and_quit_button_pressed() -> void:
	get_tree().paused = false
	save_and_quit.emit()


func _apply_visuals() -> void:
	title.text = "暂停"
	subtitle.text = "山路暂歇，整理一下再继续。"
	back_to_game_button.text = "继续"
	save_and_quit_button.text = "返回山门"

	panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.03, 0.12, 0.15, 0.92),
		Color(0.66, 0.53, 0.28, 0.82),
		2,
		8,
		Color(0, 0, 0, 0.58),
		18
	))

	title.add_theme_color_override("font_color", Color("f2c94f"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_font_size_override("font_size", 44)

	subtitle.add_theme_color_override("font_color", Color("d7eef4"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", 22)

	_style_button(back_to_game_button, Color("6fb2d8"))
	_style_button(save_and_quit_button, Color("b89648"))

	var hint := Label.new()
	hint.text = "再次按 ESC 关闭"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("9fb5b8"))
	hint.add_theme_font_size_override("font_size", 17)
	actions.get_parent().add_child(hint)


func _style_button(button: Button, accent: Color) -> void:
	button.custom_minimum_size = Vector2(260, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("f4efe4"))
	button.add_theme_color_override("font_hover_color", Color("fff6dc"))
	button.add_theme_color_override("font_pressed_color", Color("f2c94f"))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.05, 0.20, 0.24, 0.86), accent.darkened(0.25), 1, 6))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.08, 0.31, 0.36, 0.96), accent.lightened(0.20), 2, 6, Color(accent.r, accent.g, accent.b, 0.22), 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.03, 0.14, 0.17, 0.98), Color("f2c94f"), 2, 6))
	button.add_theme_stylebox_override("focus", _make_panel_style(Color(0.07, 0.26, 0.31, 0.92), Color("f2c94f"), 2, 6, Color(0.95, 0.75, 0.22, 0.22), 8))


func _make_panel_style(bg: Color, border: Color, border_width := 1, radius := 6, shadow := Color(0, 0, 0, 0.34), shadow_size := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
