class_name ConfiguredTopdeckFilterEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var max_cards := 0


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
	player_handler.filter_afflictions_from_draw_pile(get_modified_amount(card), max_cards)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var limit_text := "所有" if max_cards <= 0 else "至多 %s 张" % max_cards
	return "检视抽牌堆顶 %s 张牌，将其中%s状态牌或诅咒牌置入弃牌堆。" % [
		get_modified_amount(card, player_modifiers, enemy_modifiers),
		limit_text,
	]
