extends EnemyAction

@export var block := 11
@export var card_to_add: Card
@export var copies := 1


func perform_action() -> void:
	var player := target as Player
	if not player:
		player = get_tree().get_first_node_in_group("player") as Player
	if not enemy or not player or not player.stats or not player.stats.discard:
		Events.enemy_action_completed.emit(enemy)
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])

	var added := 0
	if card_to_add:
		for i in range(maxi(copies, 0)):
			var pollution := card_to_add.duplicate(true) as Card
			if pollution:
				player.stats.discard.add_card(pollution)
				added += 1

	if added > 0:
		Events.ui_notice_requested.emit("%s 获得 %s 点护体，并将 %s 张「%s」塞入弃牌堆" % [
			enemy.stats.display_name,
			block,
			added,
			card_to_add.get_display_name(),
		])
	complete_action_after_delay(0.6)
