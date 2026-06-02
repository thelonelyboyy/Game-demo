extends Control

const SPIRIT_ROOT_SELECTOR_SCENE = preload("res://scenes/ui/spirit_root_selector.tscn")
const BODY_CULTIVATOR_STATS := preload("res://characters/body_cultivator/body_cultivator.tres")
const SWORD_CULTIVATOR_STATS := preload("res://characters/sword_cultivator/sword_cultivator.tres")
const DEMONIC_CULTIVATOR_STATS := preload("res://characters/demonic_cultivator/demonic_cultivator.tres")
const BEASTMASTER_STATS := preload("res://characters/beastmaster/beastmaster.tres")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var character_portrait: TextureRect = %CharacterPortrait

var current_character: CharacterStats : set = set_current_character


func _ready() -> void:
	_polish_scene()
	set_current_character(BODY_CULTIVATOR_STATS)


func set_current_character(new_character: CharacterStats) -> void:
	current_character = new_character
	title.text = current_character.character_name
	description.text = current_character.description
	character_portrait.texture = current_character.portrait
	_update_portrait_treatment()


func _on_start_button_pressed() -> void:
	print("Start new Run with %s" % current_character.character_name)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.picked_character = current_character
	get_tree().change_scene_to_packed(SPIRIT_ROOT_SELECTOR_SCENE)


func _on_body_cultivator_button_pressed() -> void:
	current_character = BODY_CULTIVATOR_STATS


func _on_sword_cultivator_button_pressed() -> void:
	current_character = SWORD_CULTIVATOR_STATS


func _on_demonic_cultivator_button_pressed() -> void:
	current_character = DEMONIC_CULTIVATOR_STATS


func _on_beastmaster_button_pressed() -> void:
	current_character = BEASTMASTER_STATS


func _polish_scene() -> void:
	InkTheme.add_backdrop(self, "character")
	$Background.hide()
	InkTheme.apply_title(title, 56)
	InkTheme.apply_body_label(description, 24)
	InkTheme.apply_button($StartButton, true)
	InkTheme.apply_buttons($CharacterButtons)

	for button in $CharacterButtons.get_children():
		button.custom_minimum_size = Vector2(150, 132)
		var icon := button.get_node_or_null("Icon")
		if icon:
			icon.hide()

	$CharacterButtons/BodyCultivatorButton.text = "体修"
	$CharacterButtons/SwordCultivatorButton.text = "剑修"
	$CharacterButtons/DemonicCultivatorButton.text = "魔修"
	$CharacterButtons/BeastmasterButton.text = "驭兽"


func _update_portrait_treatment() -> void:
	character_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	character_portrait.modulate = Color(0.96, 0.90, 0.76, 0.86)
