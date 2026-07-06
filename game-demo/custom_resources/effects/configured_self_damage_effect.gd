class_name ConfiguredSelfDamageEffect
extends "res://custom_resources/effects/card_effect.gd"


func execute(card: CultivationCard, targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if not can_execute(card):
		return

	var final_targets := get_targets(card, targets, TargetMode.PLAYER)
	var damage := get_modified_amount(card)
	if final_targets.is_empty() or damage <= 0:
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


func get_description(card: CultivationCard, player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	if not description_template.is_empty():
		return super.get_description(card, player_modifiers, enemy_modifiers)
	return "失去 %s 点生命。" % get_modified_amount(card, player_modifiers, enemy_modifiers)
