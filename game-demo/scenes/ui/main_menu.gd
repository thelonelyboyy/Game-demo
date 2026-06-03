extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const MENU_BACKGROUND := preload("res://test1.png")

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var codex_panel: Control = $CodexPanel


func _ready() -> void:
	get_tree().paused = false
	_polish_scene()
	continue_button.disabled = SaveGame.load_data() == null


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_codex_pressed() -> void:
	codex_panel.show()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _polish_scene() -> void:
	_apply_custom_background()
	InkTheme.apply_title($Title, 62)
	InkTheme.apply_buttons($VBoxContainer, true)

	for sprite in [
		$SwordCultivator,
		$DemonicCultivator,
		$BodyCultivator,
		$Beastmaster,
		$Bat,
		$Crab,
		$Ghost,
	]:
		sprite.hide()

func _apply_custom_background() -> void:
	var background := $Background as TextureRect
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.show()
