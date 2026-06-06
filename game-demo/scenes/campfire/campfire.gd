class_name Campfire
extends Control

const CARD_UPGRADE_SCENE := preload("res://scenes/card_upgrade/card_upgrade.tscn")

@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var rest_button: Button = %RestButton
@onready var upgrade_button: Button = %UpgradeButton

var active_card_upgrade: CardUpgrade


func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)


func _on_rest_button_pressed() -> void:
	_set_action_buttons_disabled(true)
	var heal_amount := ceili(char_stats.max_health * 0.3)
	var initial_health := char_stats.health
	char_stats.heal(heal_amount)
	Events.campfire_rested.emit(char_stats, maxi(0, char_stats.health - initial_health))
	animation_player.play("fade_out")


func _on_upgrade_button_pressed() -> void:
	if active_card_upgrade:
		return

	_set_action_buttons_disabled(true)
	active_card_upgrade = CARD_UPGRADE_SCENE.instantiate() as CardUpgrade
	ui_layer.add_child(active_card_upgrade)
	active_card_upgrade.card_pile = char_stats.deck
	active_card_upgrade.closed.connect(_on_card_upgrade_closed)
	active_card_upgrade.card_upgraded.connect(_on_card_upgraded)


func _on_card_upgraded(card: Card) -> void:
	if card:
		Events.campfire_card_upgraded.emit(char_stats, card)

	if active_card_upgrade:
		active_card_upgrade.queue_free()
		active_card_upgrade = null

	_set_action_buttons_disabled(true)
	animation_player.play("fade_out")


func _on_card_upgrade_closed() -> void:
	active_card_upgrade = null
	_set_action_buttons_disabled(false)


func _set_action_buttons_disabled(disabled: bool) -> void:
	rest_button.disabled = disabled
	upgrade_button.disabled = disabled


# This is called from the AnimationPlayer
# at the end of 'fade-out'.
func _on_fade_out_finished() -> void:
	Events.campfire_exited.emit()
