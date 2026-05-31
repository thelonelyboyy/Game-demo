extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var codex_panel: Control = $CodexPanel


func _ready() -> void:
	get_tree().paused = false
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
