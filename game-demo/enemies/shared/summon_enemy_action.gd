extends EnemyAction

@export var summon_stats: EnemyStats
@export var max_enemies := 3
@export var fallback_block := 10


func perform_action() -> void:
	if not enemy or not summon_stats:
		Events.enemy_action_completed.emit(enemy)
		return

	var handler := enemy.get_parent() as EnemyHandler
	var summoned := handler.summon_enemy(summon_stats, max_enemies) if handler else null
	if summoned:
		SFXPlayer.play(sound)
		Events.ui_notice_requested.emit("%s 召来「%s」助战" % [
			enemy.stats.display_name,
			summon_stats.display_name,
		])
	else:
		var block_effect := BlockEffect.new()
		block_effect.amount = fallback_block
		var targets: Array[Node] = [enemy]
		block_effect.execute(targets)
		Events.ui_notice_requested.emit("%s 增援已满，转而获得 %s 点护体" % [
			enemy.stats.display_name,
			fallback_block,
		])
	complete_action_after_delay(0.55)
