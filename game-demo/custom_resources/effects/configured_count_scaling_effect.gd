class_name ConfiguredCountScalingEffect
extends "res://custom_resources/effects/card_effect.gd"

enum Result {DAMAGE, BLOCK}
enum CountSource {
	CARDS_PLAYED_THIS_TURN,
	ATTACKS_PLAYED_THIS_TURN,
	SKILLS_PLAYED_THIS_TURN,
	POWERS_PLAYED_THIS_TURN,
	CARDS_EXHAUSTED_THIS_TURN,
	CARDS_EXHAUSTED_THIS_COMBAT,
	CARDS_DISCARDED_THIS_TURN,
	DISCARD_PILE_SIZE,
	EXHAUST_PILE_SIZE,
}

@export var result := Result.DAMAGE
@export var count_source := CountSource.CARDS_PLAYED_THIS_TURN
@export var amount_per_count := 1
@export var minimum_count := 0
@export var target_mode := TargetMode.CARD_TARGETS
@export var exclude_current_card := false


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var final_targets := get_targets(card, targets, target_mode)
	var value := get_modified_amount(card, modifiers)
	if final_targets.is_empty() or value <= 0:
		return

	match result:
		Result.BLOCK:
			var block_effect := BlockEffect.new()
			block_effect.amount = value
			block_effect.execute(final_targets)
		_:
			execute_damage(card, final_targets, value, modifiers)


func get_modified_amount(card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> int:
	var count := maxi(_get_count(card), minimum_count)
	var value := amount + amount_per_count * count
	if affected_by_spirit_root and card:
		value = card.get_spirit_root_modified_value(value)
	if _condition_matches(card):
		value += bonus_amount
	return value


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var count := maxi(_get_count(card), minimum_count)
	var total := get_modified_amount(card, player_modifiers, enemy_modifiers)
	if not description_template.is_empty():
		return description_template.replace("{amount}", str(amount)).replace("{per}", str(amount_per_count)).replace("{count}", str(count)).replace("{total}", str(total)).replace("{source}", _source_name())
	var action := "获得护体" if result == Result.BLOCK else "造成伤害"
	return "基础%s %s；每有 1 个%s，额外 +%s（当前 %s）。" % [action, amount, _source_name(), amount_per_count, total]


func upgrade_values() -> void:
	super.upgrade_values()
	amount_per_count = _upgrade_number(amount_per_count)


func _get_count(card: Card = null) -> int:
	var handler := _get_class_mechanic_handler()
	if not handler or not handler.has_method("get_combat_card_count"):
		return 0
	var count: int = handler.get_combat_card_count(count_source)
	if exclude_current_card and card and handler.has_method("is_card_in_count_source"):
		if handler.is_card_in_count_source(count_source, card):
			count -= 1
	return maxi(count, 0)


func _source_name() -> String:
	match count_source:
		CountSource.ATTACKS_PLAYED_THIS_TURN:
			return "本回合打出的攻击牌"
		CountSource.SKILLS_PLAYED_THIS_TURN:
			return "本回合打出的技能牌"
		CountSource.POWERS_PLAYED_THIS_TURN:
			return "本回合打出的功法牌"
		CountSource.CARDS_EXHAUSTED_THIS_TURN:
			return "本回合消耗的牌"
		CountSource.CARDS_EXHAUSTED_THIS_COMBAT:
			return "本场战斗消耗的牌"
		CountSource.CARDS_DISCARDED_THIS_TURN:
			return "本回合弃置的牌"
		CountSource.DISCARD_PILE_SIZE:
			return "弃牌堆中的牌"
		CountSource.EXHAUST_PILE_SIZE:
			return "消耗牌堆中的牌"
		_:
			return "本回合打出的牌"
