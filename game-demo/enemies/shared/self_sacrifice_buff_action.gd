extends EnemyAction

const MUSCLE_STATUS := preload("res://statuses/muscle.tres")

@export var health_cost := 4
@export var muscle_stacks := 2


func perform_action() -> void:
	if not enemy or not enemy.stats:
		return

	var paid_health := mini(maxi(health_cost, 0), maxi(enemy.stats.health - 1, 0))
	enemy.stats.health -= paid_health
	var muscle := MUSCLE_STATUS.duplicate() as Status
	muscle.stacks = muscle_stacks
	var status_effect := StatusEffect.new()
	status_effect.status = muscle
	var targets: Array[Node] = [enemy]
	status_effect.execute(targets)
	SFXPlayer.play(sound)
	Events.ui_notice_requested.emit("%s 血祭 %s 点生命，获得 %s 层劲气" % [
		enemy.stats.display_name,
		paid_health,
		muscle_stacks,
	])
	complete_action_after_delay(0.5)
