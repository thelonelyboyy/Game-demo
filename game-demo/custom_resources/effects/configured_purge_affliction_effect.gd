class_name ConfiguredPurgeAfflictionEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var max_cards := 0


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return
	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var tree := final_targets[0].get_tree()
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler if tree else null
	if not player_handler:
		return
	var exhausted := player_handler.exhaust_affliction_cards_from_hand(max_cards, card)
	if exhausted.is_empty():
		return

	var block_per_card := get_modified_amount(card)
	if block_per_card > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block_per_card * exhausted.size()
		block_effect.sound = card.sound if card else null
		block_effect.execute(final_targets)
	Events.ui_notice_requested.emit("焚化 %s 张污染牌，转化为 %s 点护体" % [
		exhausted.size(),
		block_per_card * exhausted.size(),
	])


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var limit_text := "所有" if max_cards <= 0 else "至多 %s 张" % max_cards
	var block_per_card := get_preview_block_amount(
		get_modified_amount(card, player_modifiers, enemy_modifiers),
		player_modifiers
	)
	return "消耗手牌中%s状态牌或诅咒牌，每张获得 %s 点护体。" % [
		limit_text,
		block_per_card,
	]
