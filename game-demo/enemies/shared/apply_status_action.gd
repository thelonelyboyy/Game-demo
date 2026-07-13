extends EnemyAction

enum TargetMode {PLAYER, SELF, ALL_ALLIES}

@export var status: Status
@export var target_mode := TargetMode.PLAYER
@export var notice_name := "状态"


func perform_action() -> void:
	if not enemy or not status:
		Events.enemy_action_completed.emit(enemy)
		return
	var targets := _get_targets()
	if targets.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return
	var status_effect := StatusEffect.new()
	status_effect.status = status
	status_effect.execute(targets)
	SFXPlayer.play(sound)
	Events.ui_notice_requested.emit("%s 施加了「%s」" % [enemy.stats.display_name, notice_name])
	complete_action_after_delay(0.45)


func _get_targets() -> Array[Node]:
	var targets: Array[Node] = []
	match target_mode:
		TargetMode.SELF:
			targets.append(enemy)
		TargetMode.ALL_ALLIES:
			for child: Node in enemy.get_parent().get_children():
				var ally := child as Enemy
				if ally and ally.stats and ally.stats.health > 0 and not ally.is_queued_for_deletion():
					targets.append(ally)
		_:
			var player := target as Player
			if not player:
				player = get_tree().get_first_node_in_group("player") as Player
			if player:
				targets.append(player)
	return targets
