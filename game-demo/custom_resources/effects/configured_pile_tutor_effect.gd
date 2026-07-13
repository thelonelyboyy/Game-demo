class_name ConfiguredPileTutorEffect
extends "res://custom_resources/effects/card_effect.gd"

enum SourcePile {DRAW_PILE, DISCARD_PILE, EXHAUST_PILE}
enum CardFilter {ANY, ATTACK, SKILL, POWER}

@export var source_pile := SourcePile.DRAW_PILE
@export var card_filter := CardFilter.ANY


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var player_handler := final_targets[0].get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if not player_handler:
		return
	player_handler.move_matching_cards_to_hand(
		source_pile,
		_get_card_type_filter(),
		get_modified_amount(card),
		card
	)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	var verb := "检索"
	var pile_name := "抽牌堆"
	if source_pile == SourcePile.DISCARD_PILE:
		verb = "回收最近的"
		pile_name = "弃牌堆"
	elif source_pile == SourcePile.EXHAUST_PILE:
		verb = "取回最近的"
		pile_name = "消耗牌堆"
	return "从%s%s %s 张%s加入手牌。" % [pile_name, verb, get_modified_amount(card, player_modifiers, enemy_modifiers), _get_filter_name()]


func _get_card_type_filter() -> int:
	match card_filter:
		CardFilter.ATTACK:
			return Card.Type.ATTACK
		CardFilter.SKILL:
			return Card.Type.SKILL
		CardFilter.POWER:
			return Card.Type.POWER
		_:
			return -1


func _get_filter_name() -> String:
	match card_filter:
		CardFilter.ATTACK:
			return "攻击牌"
		CardFilter.SKILL:
			return "技能牌"
		CardFilter.POWER:
			return "功法牌"
		_:
			return "牌"
