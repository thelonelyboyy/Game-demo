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
	set_current_character(BODY_CULTIVATOR_STATS)


func set_current_character(new_character: CharacterStats) -> void:
	current_character = new_character
	title.text = current_character.character_name
	description.text = current_character.description
	character_portrait.texture = current_character.portrait


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
