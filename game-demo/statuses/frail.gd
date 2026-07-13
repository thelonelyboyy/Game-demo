class_name FrailStatus
extends Status

const MODIFIER := -0.25
const MODIFIER_SOURCE := "frail"


func get_tooltip() -> String:
	return tooltip % duration


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var block_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAIN)
	assert(block_modifier, "No block gain modifier on %s" % target)

	var modifier_value := block_modifier.get_value(MODIFIER_SOURCE)
	if not modifier_value:
		modifier_value = ModifierValue.create_new_modifier(MODIFIER_SOURCE, ModifierValue.Type.PERCENT_BASED)
	modifier_value.percent_value = MODIFIER
	block_modifier.add_new_value(modifier_value)
	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(block_modifier))


func _on_status_changed(block_modifier: Modifier) -> void:
	if duration <= 0 and block_modifier:
		block_modifier.remove_value(MODIFIER_SOURCE)
