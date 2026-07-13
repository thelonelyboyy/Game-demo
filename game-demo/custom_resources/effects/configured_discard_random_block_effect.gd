class_name ConfiguredDiscardRandomBlockEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var cards_to_discard := 1


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var tree := final_targets[0].get_tree()
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler if tree else null
	if not player_handler:
		return
	var discarded := player_handler.discard_random_cards_from_hand(cards_to_discard, card)
	if discarded.is_empty():
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = get_modified_amount(card) * discarded.size()
	block_effect.sound = card.sound if card else null
	block_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	return "随机弃置手牌中其它 %s 张牌；每成功弃置 1 张，获得 %s 点护体。" % [
		maxi(cards_to_discard, 1),
		get_modified_amount(card, player_modifiers, enemy_modifiers),
	]
