class_name SoulLanternRelic
extends Relic

const SOUL_MARK_STATUS = preload("res://statuses/soul_mark.tres")


func activate_relic(owner: RelicUI) -> void:
	var enemies: Array[Node] = owner.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var enemy := RNG.array_pick_random(enemies) as Node
	var mark := SOUL_MARK_STATUS.duplicate() as Status
	mark.stacks = 1
	var status_effect := StatusEffect.new()
	status_effect.status = mark
	status_effect.execute([enemy])
	owner.flash()
