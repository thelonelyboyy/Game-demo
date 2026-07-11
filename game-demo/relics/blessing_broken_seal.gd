extends Relic

## 破劫之印（开局祝福专属）：接下来 N 场战斗敌人以七成气血入场，用尽后碎裂。
## 挂 START_OF_COMBAT：battle.gd 在敌人生成后才激活该类法宝，时序安全。

const HEALTH_RATIO := 0.7

@export var battles_left := 3


func activate_relic(owner: RelicUI) -> void:
	if battles_left <= 0:
		return
	battles_left -= 1

	for node in owner.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.stats:
			enemy.stats.health = maxi(1, ceili(enemy.stats.health * HEALTH_RATIO))

	# 用尽即碎：移除自身的法宝栏位（queue_free 延迟执行，激活循环内安全）。
	if battles_left <= 0:
		owner.queue_free()


func get_tooltip() -> String:
	return "破劫之印\n接下来 %d 场战斗，敌人以七成气血入场。用尽后碎裂。" % maxi(battles_left, 0)
