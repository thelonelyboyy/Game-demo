class_name GoldBodyStatus
extends Status


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var dmg_taken_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	assert(dmg_taken_modifier, "No dmg taken modifier on %s" % target)
	_update_modifier(dmg_taken_modifier)
	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(dmg_taken_modifier))


func _on_status_changed(dmg_taken_modifier: Modifier) -> void:
	if stacks <= 0 and dmg_taken_modifier:
		dmg_taken_modifier.remove_value("gold_body")
	else:
		_update_modifier(dmg_taken_modifier)


func _update_modifier(dmg_taken_modifier: Modifier) -> void:
	var value := dmg_taken_modifier.get_value("gold_body")
	if not value:
		value = ModifierValue.create_new_modifier("gold_body", ModifierValue.Type.FLAT)
		dmg_taken_modifier.add_new_value(value)
	value.flat_value = -stacks
