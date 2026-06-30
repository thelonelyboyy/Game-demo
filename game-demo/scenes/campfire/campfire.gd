class_name Campfire
extends Control

const CARD_UPGRADE_SCENE := preload("res://scenes/card_upgrade/card_upgrade.tscn")

@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var rest_button: Button = %RestButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var title: Label = $UILayer/UI/Title
@onready var description: Label = $UILayer/UI/Description

var active_card_upgrade: CardUpgrade


func _ready() -> void:
	_apply_visuals()
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


func _apply_visuals() -> void:
	_ensure_campfire_panel()
	InkTheme.apply_screen_title(title, 42)
	InkTheme.apply_subtitle(description, 21)
	rest_button.custom_minimum_size = Vector2(220, 58)
	upgrade_button.custom_minimum_size = Vector2(220, 58)
	InkTheme.apply_screen_button(rest_button)
	InkTheme.apply_screen_button(upgrade_button)


func _ensure_campfire_panel() -> void:
	if ui_layer.has_node("CampfirePanel"):
		return

	var panel := PanelContainer.new()
	panel.name = "CampfirePanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210.0
	panel.offset_top = -150.0
	panel.offset_right = 210.0
	panel.offset_bottom = 184.0
	InkTheme.apply_screen_panel(panel, true)
	ui_layer.add_child(panel)
	ui_layer.move_child(panel, ui_layer.get_node("UI").get_index())
