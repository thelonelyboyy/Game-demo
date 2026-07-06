class_name ConfiguredConsumeStatusToBlockEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var status_id := "sha_qi"
@export var status_name := "煞气"
@export var block_per_stack := 1
@export var consume_all := true
@export var consume_amount := 1


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var player := final_targets[0] as Player
	if not player or not player.status_handler:
		return
	var status := player.status_handler.get_status(status_id)
	if not status or status.stacks <= 0:
		return

	var consumed := status.stacks if consume_all else mini(consume_amount, status.stacks)
	status.stacks -= consumed
	var block := consumed * block_per_stack
	if block <= 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = card.sound if card else null
	block_effect.execute([player])


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return description_template
	if consume_all:
		return "消耗所有%s，每点获得 %d 点护体。消耗。" % [status_name, block_per_stack]
	return "消耗 %d 点%s，每点获得 %d 点护体。消耗。" % [consume_amount, status_name, block_per_stack]


func get_primary_value(_card: CultivationCard) -> int:
	return 0
