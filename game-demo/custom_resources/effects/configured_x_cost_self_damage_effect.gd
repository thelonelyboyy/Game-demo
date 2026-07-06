class_name ConfiguredXCostSelfDamageEffect
extends "res://custom_resources/effects/card_effect.gd"

@export var self_damage_per_mana := 1


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var x_paid := card.get_x_cost_paid() if card else 0
	var damage := x_paid * self_damage_per_mana
	if damage <= 0:
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	if final_targets.is_empty():
		return
	var player := final_targets[0] as Player
	if not player or not player.stats:
		return

	var initial_health := player.stats.health
	player.stats.health = maxi(player.stats.health - damage, 0)
	SFXPlayer.play(card.sound if card else null)
	var actual_lost := maxi(0, initial_health - player.stats.health)
	if actual_lost > 0:
		Events.player_self_damaged.emit(actual_lost)
		Events.player_hit.emit()
	if player.stats.health <= 0:
		Events.player_died.emit()


func get_description(_card: CultivationCard, _player_modifiers: ModifierHandler = null, _enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return description_template
	return "消耗所有灵气，每点失去 %d 点生命。" % self_damage_per_mana


func get_primary_value(_card: CultivationCard) -> int:
	return 0
