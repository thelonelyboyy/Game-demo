extends EnemyAction

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

@export var stacks := 2


func perform_action() -> void:
	if not enemy:
		return
	var allies := _get_live_allies()
	if allies.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return
	var status_effect := StatusEffect.new()
	var muscle := MUSCLE_STATUS.duplicate() as Status
	muscle.stacks = stacks
	status_effect.status = muscle
	status_effect.execute(allies)
	SFXPlayer.play(sound)
	Events.ui_notice_requested.emit("%s 令全体敌人获得 %s 层劲气" % [enemy.stats.display_name, stacks])
	complete_action_after_delay(0.45)


func _get_live_allies() -> Array[Node]:
	var allies: Array[Node] = []
	if not enemy or not enemy.get_parent():
		return allies
	for child: Node in enemy.get_parent().get_children():
		var ally := child as Enemy
		if ally and not ally.is_queued_for_deletion() and ally.stats and ally.stats.health > 0:
			allies.append(ally)
	return allies
