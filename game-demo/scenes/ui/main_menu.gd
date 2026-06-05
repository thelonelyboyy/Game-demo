extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const MENU_BACKGROUND := preload("res://test1.png")

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var codex_panel: Control = $CodexPanel
@onready var subtitle: Label = %Subtitle
@onready var settings_toast: Label = %SettingsToast


func _ready() -> void:
	get_tree().paused = false
	_polish_scene()
	var has_save := SaveGame.load_data() != null
	continue_button.disabled = not has_save


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_codex_pressed() -> void:
	codex_panel.show()


func _on_settings_pressed() -> void:
	settings_toast.show()
	settings_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(settings_toast, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(settings_toast, "hide"))


func _on_exit_pressed() -> void:
	get_tree().quit()


func _polish_scene() -> void:
	_apply_custom_background()
	_apply_title_style()
	_apply_menu_button_style()
	_apply_toast_style()

func _apply_custom_background() -> void:
	var background := $Background as TextureRect
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()


func _apply_title_style() -> void:
	var title := $Title as Label
	title.add_theme_color_override("font_color", Color("ffd33d"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 6)

	subtitle.add_theme_color_override("font_color", Color("70f4ff"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", 28)


func _apply_menu_button_style() -> void:
	var empty_style := StyleBoxEmpty.new()
	for button: Button in $VBoxContainer.get_children():
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", empty_style)
		button.add_theme_stylebox_override("hover", empty_style)
		button.add_theme_stylebox_override("pressed", empty_style)
		button.add_theme_stylebox_override("disabled", empty_style)
		button.add_theme_color_override("font_color", Color("f4efe4"))
		button.add_theme_color_override("font_hover_color", Color("ffe38a"))
		button.add_theme_color_override("font_pressed_color", Color("d7bb62"))
		button.add_theme_color_override("font_disabled_color", Color(0.82, 0.78, 0.68, 0.45))
		button.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.03, 0.9))
		button.add_theme_constant_override("outline_size", 5)
		button.add_theme_font_size_override("font_size", 34)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _apply_toast_style() -> void:
	settings_toast.add_theme_color_override("font_color", Color("f4efe4"))
	settings_toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	settings_toast.add_theme_constant_override("shadow_offset_x", 2)
	settings_toast.add_theme_constant_override("shadow_offset_y", 2)
	settings_toast.add_theme_font_size_override("font_size", 18)
