class_name ConfiguredCopyPreviousCardEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var temporary_cost_reduction := 1


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var mechanic_handler := _get_class_mechanic_handler()
	if not mechanic_handler or not mechanic_handler.has_method("get_previous_card_played"):
		return
	var previous := mechanic_handler.get_previous_card_played(card) as Card
	if not previous or previous.blocks_manual_play():
		return

	var copy := previous.create_runtime_copy()
	if not copy:
		return
	copy.temporary = true
	copy.ensure_mechanic_tag(Card.TEMPORARY_MECHANIC_TAG)
	copy.reset_temporary_cost()
	copy.reduce_cost_for_turn(temporary_cost_reduction)

	var tree := _get_tree(card, targets)
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler if tree else null
	if player_handler:
		player_handler.add_temporary_cards_to_hand([copy])


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	return "复刻本回合上一张打出的可用牌，将临时副本加入手牌；其本回合费用 -%s。" % temporary_cost_reduction
