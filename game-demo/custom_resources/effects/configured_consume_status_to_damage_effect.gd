class_name ConfiguredConsumeStatusToDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var status_id := "sha_qi"
@export var status_name := "煞气"
@export var damage_per_stack := 5
@export var consume_all := false
@export var consume_amount := 2
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

	var consumed := status.stacks if consume_all else mini(consume_amount, status.stacks)
	status.stacks -= consumed
	execute_damage(
		card,
		get_targets(card, targets, target_mode),
		consumed * damage_per_stack,
		modifiers
	)


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if consume_all:
		return "消耗所有%s，每点造成 %d 点伤害。" % [status_name, damage_per_stack]
	return "消耗至多 %d 点%s，每点造成 %d 点伤害。" % [consume_amount, status_name, damage_per_stack]


func get_primary_value(_card: CultivationCard) -> int:
	return consume_amount * damage_per_stack


func upgrade_values() -> void:
	damage_per_stack = _upgrade_number(damage_per_stack)
