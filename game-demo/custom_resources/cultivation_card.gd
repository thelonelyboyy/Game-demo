class_name CultivationCard
extends Card

@export_group("Configured Effects")
@export var configured_effects: Array[Resource] = []
@export_multiline var effect_text := ""


func get_default_tooltip() -> String:
	return _build_configured_tooltip()


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	return _build_configured_tooltip(player_modifiers, enemy_modifiers)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	for effect in configured_effects:
		if effect:
			effect.execute(self, targets, modifiers)


func _build_configured_tooltip(player_modifiers: ModifierHandler = null, enemy_modifiers: ModifierHandler = null) -> String:
	var lines: PackedStringArray = []
	for effect in configured_effects:
		if not effect:
			continue
		var line: String = effect.get_description(self, player_modifiers, enemy_modifiers)
		if not line.is_empty():
			lines.append(line)

	var text := "\n".join(lines)
	if text.is_empty() and not effect_text.is_empty():
		text = effect_text
	return "[center][b]%s[/b]\n%s[/center]" % [get_display_name(), text]


func _upgrade_values() -> void:
	for effect in configured_effects:
		if effect:
			effect.upgrade_values()


func get_spirit_root_primary_value() -> int:
	var result := 0
	for effect in configured_effects:
		if effect:
			result = maxi(result, effect.get_primary_value(self))
	return result
