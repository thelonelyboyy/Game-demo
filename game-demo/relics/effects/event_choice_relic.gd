class_name EventChoiceRelic
extends Relic

enum RewardMode {GOLD, HEAL, MAX_HP}

@export var reward_mode := RewardMode.GOLD
@export var amount := 8
@export var require_costly_choice := false

var relic_ui: RelicUI


func initialize_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.event_choice_resolved.is_connected(_on_event_choice_resolved):
		Events.event_choice_resolved.connect(_on_event_choice_resolved)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.event_choice_resolved.is_connected(_on_event_choice_resolved):
		Events.event_choice_resolved.disconnect(_on_event_choice_resolved)


func _on_event_choice_resolved(effect: String, _choice_amount: int, character: CharacterStats, run_stats: RunStats) -> void:
	if require_costly_choice and not _is_costly_choice(effect):
		return

	match reward_mode:
		RewardMode.GOLD:
			if not run_stats:
				return
			run_stats.gold += amount
		RewardMode.HEAL:
			if not character:
				return
			character.heal(amount)
		RewardMode.MAX_HP:
			if not character:
				return
			character.max_health += amount

	if relic_ui and is_instance_valid(relic_ui):
		relic_ui.flash()


func _is_costly_choice(effect: String) -> bool:
	return effect.contains("lose_gold") or effect.contains("damage") or effect.contains("remove_random")
