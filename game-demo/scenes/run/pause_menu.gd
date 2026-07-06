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


func open() -> void:
	_pause()


func _pause() -> void:
	show()
	get_tree().paused = true
	back_to_game_button.grab_focus()
	_animate_open.call_deferred()


# 开启动画：树已暂停，tween 需 TWEEN_PAUSE_PROCESS。
func _animate_open() -> void:
	if not panel:
		return
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE * 0.9
	panel.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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

	InkTheme.apply_screen_panel(panel, true)
	InkTheme.apply_screen_title(title, 44)
	InkTheme.apply_subtitle(subtitle, 22)

	_style_button(back_to_game_button)
	_style_button(save_and_quit_button)

	var hint := Label.new()
	hint.text = "再次按 ESC 关闭"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	InkTheme.apply_small_note(hint, 17)
	actions.get_parent().add_child(hint)


func _style_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(260, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	InkTheme.apply_screen_button(button)


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
