class_name ConfiguredSoulMarkConsumeEffect
extends "res://custom_resources/effects/card_effect.gd"

## 转化：消耗目标敌人魂印层数（作为代价），收益由同卡的其它效果（护体/回血/抽牌等）给出。

@export var target_mode := TargetMode.CARD_TARGETS
@export var consume_amount := 2


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	for enemy in get_targets(card, targets, target_mode):
		if not is_instance_valid(enemy) or not (enemy is Enemy):
			continue
		var status_handler = enemy.status_handler
		if not status_handler:
			continue
		var status: Status = status_handler.get_status("soul_mark")
		if not status or status.stacks <= 0:
			continue
		var consumed := mini(consume_amount, status.stacks)
		status.stacks -= consumed
		_notify_class_handler(card, enemy, consumed, modifiers)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "消耗目标 %d 层魂印。" % consume_amount


func _notify_class_handler(card: CultivationCard, enemy: Enemy, consumed: int, modifiers: ModifierHandler) -> void:
	if consumed <= 0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var handler := tree.get_first_node_in_group("class_mechanic")
	if handler and handler.has_method("notify_soul_mark_consumed"):
		handler.notify_soul_mark_consumed(card, enemy, consumed, modifiers)
