class_name ConfiguredStatusEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var status: Status
@export var target_mode := TargetMode.PLAYER
@export var use_duration := false


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not status or not can_execute(card):
		return

	var final_targets := get_targets(card, targets, target_mode)
	var status_amount := get_modified_amount(card)
	if final_targets.is_empty() or status_amount <= 0:
		return

	var status_copy := status.duplicate() as Status
	if use_duration:
		status_copy.duration = status_amount
	else:
		status_copy.stacks = status_amount

	var status_effect := StatusEffect.new()
	status_effect.status = status_copy
	status_effect.execute(final_targets)


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)

	var target_text := "自己" if target_mode == TargetMode.PLAYER else "敌人"
	var value_name := "回合" if use_duration else "层"
	return "给予%s %s %s%s。" % [
		target_text,
		get_modified_amount(card, player_modifiers, enemy_modifiers),
		value_name,
		_status_name()
	]


func _status_name() -> String:
	if not status:
		return "状态"
	match status.id:
		"exposed":
			return "破绽"
		"muscle":
			return "劲气"
		"qi_flow":
			return "灵息"
		"forge_sword":
			return "铸剑"
		"gold_body":
			return "金身"
		"soul_mark":
			return "魂印"
		"spirit_beast":
			return "灵兽"
		"beast_pack":
			return "兽群"
		_:
			return status.id
