class_name Campfire
extends Control

const CARD_UPGRADE_SCENE := preload("res://scenes/card_upgrade/card_upgrade.tscn")
const CARD_REMOVE_SCENE := preload("res://scenes/card_remove/card_remove.tscn")
const BLOOD_REFINE_MAX_HEALTH_COST := 5

@export var char_stats: CharacterStats
@export var run_stats: RunStats

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var rest_button: Button = %RestButton
@onready var upgrade_button: Button = %UpgradeButton
@onready var blood_refine_button: Button = %BloodRefineButton
@onready var title: Label = $UILayer/UI/Title
@onready var description: Label = $UILayer/UI/Description

var active_card_upgrade: CardUpgrade
var active_card_remove: CardRemove


func _ready() -> void:
	InkTheme.animate_screen_entrance(self)
	_apply_visuals()
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	blood_refine_button.pressed.connect(_on_blood_refine_button_pressed)


func setup(character: CharacterStats, stats: RunStats) -> void:
	char_stats = character
	run_stats = stats
	_refresh_action_availability()


func _on_rest_button_pressed() -> void:
	_set_action_buttons_disabled(true)
	var heal_amount := (
		run_stats.get_campfire_heal_amount(char_stats.max_health)
		if run_stats
		else ceili(char_stats.max_health * 0.3)
	)
	var initial_health := char_stats.health
	char_stats.heal(heal_amount)
	GameSfx.play(GameSfx.HEAL, -2.0)
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
		GameSfx.play(GameSfx.BOOK, -4.0)
		Events.campfire_card_upgraded.emit(char_stats, card)

	if active_card_upgrade:
		active_card_upgrade.queue_free()
		active_card_upgrade = null

	_set_action_buttons_disabled(true)
	animation_player.play("fade_out")


func _on_card_upgrade_closed() -> void:
	active_card_upgrade = null
	_set_action_buttons_disabled(false)
	_refresh_action_availability()


func _on_blood_refine_button_pressed() -> void:
	if active_card_remove or not _can_blood_refine():
		return
	_set_action_buttons_disabled(true)
	active_card_remove = CARD_REMOVE_SCENE.instantiate() as CardRemove
	ui_layer.add_child(active_card_remove)
	active_card_remove.card_pile = char_stats.deck
	active_card_remove.closed.connect(_on_blood_refine_closed)
	active_card_remove.card_removed.connect(_on_blood_refine_card_removed)


func _on_blood_refine_card_removed(card: Card) -> void:
	char_stats.max_health = maxi(1, char_stats.max_health - BLOOD_REFINE_MAX_HEALTH_COST)
	GameSfx.play(GameSfx.POWER_UP, -4.0)
	Events.campfire_card_removed.emit(char_stats, card, BLOOD_REFINE_MAX_HEALTH_COST)
	if active_card_remove:
		active_card_remove.queue_free()
		active_card_remove = null
	_set_action_buttons_disabled(true)
	animation_player.play("fade_out")


func _on_blood_refine_closed() -> void:
	active_card_remove = null
	_set_action_buttons_disabled(false)
	_refresh_action_availability()


func _can_blood_refine() -> bool:
	return (
		char_stats
		and char_stats.deck
		and char_stats.deck.cards.size() > 1
		and char_stats.max_health > BLOOD_REFINE_MAX_HEALTH_COST
	)


func _refresh_action_availability() -> void:
	if blood_refine_button:
		blood_refine_button.disabled = not _can_blood_refine()


func _set_action_buttons_disabled(disabled: bool) -> void:
	rest_button.disabled = disabled
	upgrade_button.disabled = disabled
	blood_refine_button.disabled = disabled


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
	blood_refine_button.custom_minimum_size = Vector2(220, 58)
	InkTheme.apply_screen_button(rest_button)
	InkTheme.apply_screen_button(upgrade_button)
	InkTheme.apply_screen_button(blood_refine_button)


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
