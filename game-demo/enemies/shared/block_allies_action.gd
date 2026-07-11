extends EnemyAction

@export var block := 10


func perform_action() -> void:
	if not enemy:
		return
	var allies := _get_live_allies()
	if allies.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute(allies)
	Events.ui_notice_requested.emit("%s 令全体敌人获得 %s 点护体" % [enemy.stats.display_name, block])
	complete_action_after_delay(0.55)


func _get_live_allies() -> Array[Node]:
	var allies: Array[Node] = []
	if not enemy or not enemy.get_parent():
		return allies
	for child: Node in enemy.get_parent().get_children():
		var ally := child as Enemy
		if ally and not ally.is_queued_for_deletion() and ally.stats and ally.stats.health > 0:
			allies.append(ally)
	return allies
