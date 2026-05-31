class_name SwordIntentStatus
extends Status

const MODIFIER_PER_STACK := 0.25


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(dmg_dealt_modifier, "No dmg dealt modifier on %s" % target)

	_update_modifier(dmg_dealt_modifier)

	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(dmg_dealt_modifier))


func _on_status_changed(dmg_dealt_modifier: Modifier) -> void:
	if stacks <= 0 and dmg_dealt_modifier:
		dmg_dealt_modifier.remove_value("sword_intent")
	else:
		_update_modifier(dmg_dealt_modifier)


func _update_modifier(dmg_dealt_modifier: Modifier) -> void:
	var intent_modifier_value := dmg_dealt_modifier.get_value("sword_intent")

	if not intent_modifier_value:
		intent_modifier_value = ModifierValue.create_new_modifier("sword_intent", ModifierValue.Type.PERCENT_BASED)
		dmg_dealt_modifier.add_new_value(intent_modifier_value)

	intent_modifier_value.percent_value = MODIFIER_PER_STACK * stacks
