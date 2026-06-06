class_name CampfireRelic
extends Relic

enum Trigger {REST, UPGRADE, ANY}
enum RewardMode {MAX_HP, HEAL}

@export var trigger := Trigger.ANY
@export var reward_mode := RewardMode.MAX_HP
@export var amount := 2
@export var only_once_per_run := false

var relic_ui: RelicUI
var triggered := false


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.campfire_rested.is_connected(_on_campfire_rested):
		Events.campfire_rested.connect(_on_campfire_rested)
	if not Events.campfire_card_upgraded.is_connected(_on_campfire_card_upgraded):
		Events.campfire_card_upgraded.connect(_on_campfire_card_upgraded)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.campfire_rested.is_connected(_on_campfire_rested):
		Events.campfire_rested.disconnect(_on_campfire_rested)
	if Events.campfire_card_upgraded.is_connected(_on_campfire_card_upgraded):
		Events.campfire_card_upgraded.disconnect(_on_campfire_card_upgraded)


func _on_campfire_rested(character: CharacterStats, _heal_amount: int) -> void:
	if trigger == Trigger.REST or trigger == Trigger.ANY:
		_apply_reward(character)


func _on_campfire_card_upgraded(character: CharacterStats, _card: Card) -> void:
	if trigger == Trigger.UPGRADE or trigger == Trigger.ANY:
		_apply_reward(character)


func _apply_reward(character: CharacterStats) -> void:
	if only_once_per_run and triggered:
		return
	if not character:
		return

	match reward_mode:
		RewardMode.MAX_HP:
			character.max_health += amount
		RewardMode.HEAL:
			character.heal(amount)

	triggered = true
	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()
