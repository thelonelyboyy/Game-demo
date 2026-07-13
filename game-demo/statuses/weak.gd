class_name WeakStatus
extends Status

const MODIFIER := -0.25
const MODIFIER_SOURCE := "weak"


func get_tooltip() -> String:
	return tooltip % duration


func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	var damage_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(damage_modifier, "No damage dealt modifier on %s" % target)

	var modifier_value := damage_modifier.get_value(MODIFIER_SOURCE)
	if not modifier_value:
		modifier_value = ModifierValue.create_new_modifier(MODIFIER_SOURCE, ModifierValue.Type.PERCENT_BASED)
	modifier_value.percent_value = MODIFIER
	damage_modifier.add_new_value(modifier_value)
	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(damage_modifier))


func _on_status_changed(damage_modifier: Modifier) -> void:
	if duration <= 0 and damage_modifier:
		damage_modifier.remove_value(MODIFIER_SOURCE)
