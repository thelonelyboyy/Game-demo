class_name GoldRelic
extends Relic

@export var gold_amount := 12


func activate_relic(owner: RelicUI) -> void:
	var run := owner.get_tree().get_first_node_in_group("run")
	if not run or not run.stats:
		return

	run.stats.gold += gold_amount
	owner.flash()
