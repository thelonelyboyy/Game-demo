extends Node

var _failed := false


func _ready() -> void:
	await get_tree().process_frame
	await _test_floating_text_order()
	await _test_combatant_bar_order()
	if _failed:
		get_tree().quit(1)
	else:
		print("COMBAT_FEEDBACK_SEQUENCE_SMOKE_OK")
		get_tree().quit()


func _test_floating_text_order() -> void:
	var ui_layer := Control.new()
	ui_layer.add_to_group("ui_layer")
	add_child(ui_layer)
	var world_node := Node2D.new()
	add_child(world_node)

	var block_delay := FloatingCombatText.spawn_block(world_node, 8)
	var damage_delay := FloatingCombatText.spawn_damage(world_node, 5)
	var heal_delay := FloatingCombatText.spawn_heal(world_node, 3)
	_check(block_delay < 0.05, "first feedback starts immediately")
	_check(damage_delay >= FloatingCombatText.FEEDBACK_STAGGER - 0.03, "damage waits behind block")
	_check(heal_delay >= FloatingCombatText.FEEDBACK_STAGGER * 2.0 - 0.05, "heal waits behind damage")
	_check(ui_layer.get_child_count() == 3, "three feedback labels are queued")
	if ui_layer.get_child_count() == 3:
		_check(ui_layer.get_child(0).text == "护体 -8", "block text is explicit")
		_check(float(ui_layer.get_child(1).get_meta("feedback_delay", 0.0)) > 0.0, "damage label stores delay")
		_check(float(ui_layer.get_child(2).get_meta("feedback_delay", 0.0)) > damage_delay, "heal label is third")

	world_node.queue_free()
	ui_layer.queue_free()
	await get_tree().process_frame


func _test_combatant_bar_order() -> void:
	var combatant_card := BattleCombatantCard.new()
	combatant_card.size = Vector2(260, 420)
	add_child(combatant_card)
	await get_tree().process_frame
	var dummy := Node.new()
	add_child(dummy)
	var test_stats := Stats.new()
	test_stats.max_health = 100
	test_stats.health = 100
	test_stats.block = 12
	combatant_card.combatant = dummy
	combatant_card.stats = test_stats
	combatant_card._reset_animation_tracking()
	combatant_card._connect_stats()
	combatant_card._refresh()

	# Stats.take_damage emits once after block changes and once after health changes.
	# The combatant card must show those snapshots as two stages rather than together.
	test_stats.take_damage(17)
	_check(combatant_card._displayed_block == 0, "block stage begins first")
	_check(combatant_card._displayed_health == 100, "health stage has not begun with block stage")
	_check(combatant_card._bar_animation_queue.size() == 1, "health stage waits in queue")
	await get_tree().create_timer(0.38).timeout
	_check(combatant_card._displayed_health == 95, "health stage follows block stage")

	combatant_card.queue_free()
	dummy.queue_free()
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("COMBAT_FEEDBACK_SEQUENCE_SMOKE_FAILED: %s" % message)
