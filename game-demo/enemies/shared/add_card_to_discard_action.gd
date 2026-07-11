extends EnemyAction

@export var card_to_add: Card
@export var copies := 1


func perform_action() -> void:
	var player := target as Player
	if not enemy or not player or not player.stats or not player.stats.discard or not card_to_add:
		Events.enemy_action_completed.emit(enemy)
		return

	var added := 0
	for i in range(maxi(copies, 0)):
		var pollution := card_to_add.duplicate(true) as Card
		if pollution:
			player.stats.discard.add_card(pollution)
			added += 1

	if added > 0:
		SFXPlayer.play(sound)
		Events.ui_notice_requested.emit("%s 将 %s 张「%s」塞入弃牌堆" % [
			enemy.stats.display_name,
			added,
			card_to_add.get_display_name(),
		])
	complete_action_after_delay(0.45)
