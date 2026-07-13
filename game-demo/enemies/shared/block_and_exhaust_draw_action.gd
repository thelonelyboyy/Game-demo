extends EnemyAction

@export var block := 10


func perform_action() -> void:
	var player := target as Player
	if not player:
		player = get_tree().get_first_node_in_group("player") as Player
	if not enemy or not player or not player.stats is CharacterStats:
		Events.enemy_action_completed.emit(enemy)
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])

	var character := player.stats as CharacterStats
	var exhausted_card: Card
	if character.draw_pile and not character.draw_pile.cards.is_empty():
		exhausted_card = RNG.array_pick_random(character.draw_pile.cards) as Card
		if exhausted_card and character.draw_pile.remove_card(exhausted_card):
			var player_handler := get_tree().get_first_node_in_group("player_handler") as PlayerHandler
			if player_handler:
				player_handler._trigger_card_lifecycle(exhausted_card, Card.LifecycleTrigger.EXHAUSTED)
				player_handler._add_card_to_exhaust_pile(exhausted_card)
			else:
				character.exhaust_pile.add_card(exhausted_card)
		else:
			exhausted_card = null

	if exhausted_card:
		Events.ui_notice_requested.emit("%s 获得 %s 点护体，并将「%s」送入消耗区" % [
			enemy.stats.display_name,
			block,
			exhausted_card.get_display_name(),
		])
	complete_action_after_delay(0.6)
