extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")

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
	InkTheme.add_backdrop(self, "menu")
	$Background.hide()
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

	_add_menu_seals()


func _add_menu_seals() -> void:
	var seals := [
		["体", Vector2(106, 520), Color("7b2b28")],
		["剑", Vector2(190, 575), Color("8c6a32")],
		["魔", Vector2(1080, 535), Color("5b2534")],
		["兽", Vector2(1160, 600), Color("27624d")],
	]

	for seal_data in seals:
		var seal := PanelContainer.new()
		seal.position = seal_data[1]
		seal.size = Vector2(96, 96)
		InkTheme.apply_panel(seal)
		seal.add_theme_stylebox_override("panel", InkTheme.make_style(seal_data[2], Color("c5a862"), 2, 6, Color(0, 0, 0, 0.38), 10))
		add_child(seal)

		var label := Label.new()
		label.text = seal_data[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 54)
		label.add_theme_color_override("font_color", Color("f1dfbd"))
		seal.add_child(label)
