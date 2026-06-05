class_name ConsumeStatusEffect
extends "res://custom_resources/effects/card_effect.gd"

enum ConvertTo {DAMAGE, BLOCK, DRAW}

@export var status_id := "forge_sword"
@export var consume_all := true
@export var max_stacks_to_consume := 1
@export var value_per_stack := 1
@export var convert_to := ConvertTo.DAMAGE
@export var target_mode := TargetMode.CARD_TARGETS


func execute(card: CultivationCard, targets: Array[Node], modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var player := _get_player(card)
	if not player or not player.status_handler:
		return

	var status := player.status_handler.get_status(status_id)
	if not status or status.stacks <= 0:
		return

	var consumed := status.stacks if consume_all else mini(status.stacks, max_stacks_to_consume)
	status.stacks -= consumed
	var converted_value := consumed * value_per_stack
	if converted_value <= 0:
		return

	match convert_to:
		ConvertTo.DAMAGE:
			var damage_effect := ConfiguredDamageEffect.new()
			damage_effect.amount = converted_value
			damage_effect.affected_by_spirit_root = false
			damage_effect.target_mode = target_mode
			damage_effect.execute(card, targets, modifiers)
		ConvertTo.BLOCK:
			var block_effect := ConfiguredBlockEffect.new()
			block_effect.amount = converted_value
			block_effect.affected_by_spirit_root = false
			block_effect.execute(card, targets, modifiers)
		ConvertTo.DRAW:
			var draw_effect := ConfiguredDrawEffect.new()
			draw_effect.amount = converted_value
			draw_effect.affected_by_spirit_root = false
			draw_effect.execute(card, targets, modifiers)


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return description_template

	var target_text := "伤害"
	if convert_to == ConvertTo.BLOCK:
		target_text = "护体"
	elif convert_to == ConvertTo.DRAW:
		target_text = "抽牌"
	return "消耗%s，每层转化为 %s 点%s。" % [status_id, value_per_stack, target_text]
