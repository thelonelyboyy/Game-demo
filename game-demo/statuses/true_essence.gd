class_name TrueEssenceStatus
extends Status


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)


func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	var block_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAIN)
	assert(block_modifier, "No block gain modifier on %s" % target)

	var true_essence_modifier_value := block_modifier.get_value("true_essence")
	if not true_essence_modifier_value:
		true_essence_modifier_value = ModifierValue.create_new_modifier("true_essence", ModifierValue.Type.FLAT)

	true_essence_modifier_value.flat_value = stacks
	block_modifier.add_new_value(true_essence_modifier_value)
