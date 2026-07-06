class_name ConfiguredSoulMarkDetonateEffect
extends "res://custom_resources/effects/card_effect.gd"

## 引爆魂印：消耗目标敌人魂印层数，造成 damage_per_stack × 消耗层数 的伤害。
## 主动引爆走玩家 DMG_DEALT 增伤（会被煞气放大），与回合末 DoT（不吃增伤）相区分。

@export var target_mode := TargetMode.CARD_TARGETS
@export var consume_all := false
@export var consume_amount := 1
@export var damage_per_stack := 3


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

		var consumed: int = status.stacks if consume_all else mini(consume_amount, status.stacks)
		status.stacks -= consumed
		_notify_class_handler(card, enemy, consumed, modifiers)

		var damage := damage_per_stack * consumed
		if modifiers:
			damage = modifiers.get_modified_value(damage, Modifier.Type.DMG_DEALT)
		damage = DEBUG_CONSOLE_STATE.apply_next_dealt(damage)
		if damage <= 0:
			continue

		var damage_effect := DamageEffect.new()
		damage_effect.amount = damage
		damage_effect.sound = card.sound if card else null
		damage_effect.execute([enemy])


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	if consume_all:
		return "消耗目标全部魂印，每层造成 %d 点伤害。" % damage_per_stack
	return "消耗 %d 层魂印，造成 %d 点伤害。" % [consume_amount, damage_per_stack * consume_amount]


func _notify_class_handler(card: CultivationCard, enemy: Enemy, consumed: int, modifiers: ModifierHandler) -> void:
	if consumed <= 0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var handler := tree.get_first_node_in_group("class_mechanic")
	if handler and handler.has_method("notify_soul_mark_detonated"):
		handler.notify_soul_mark_detonated(card, enemy, consumed, modifiers)
