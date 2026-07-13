class_name CultivationCard
extends Card

enum GrowthTrigger {NONE, PLAYED, DISCARDED, EXHAUSTED}

@export_group("Configured Effects")
@export var configured_effects: Array[Resource] = []
@export var discard_trigger_effects: Array[Resource] = []
@export var exhaust_trigger_effects: Array[Resource] = []
@export var draw_trigger_effects: Array[Resource] = []
@export var end_turn_trigger_effects: Array[Resource] = []
@export_multiline var effect_text := ""

@export_group("Growth")
@export var growth_trigger := GrowthTrigger.NONE
@export var growth_amount := 1
@export var growth_limit := 0

var growth_accumulated := 0


func create_runtime_copy() -> Card:
	var copy := super.create_runtime_copy() as CultivationCard
	if not copy:
		return null
	copy.configured_effects = _duplicate_effects(configured_effects)
	copy.discard_trigger_effects = _duplicate_effects(discard_trigger_effects)
	copy.exhaust_trigger_effects = _duplicate_effects(exhaust_trigger_effects)
	copy.draw_trigger_effects = _duplicate_effects(draw_trigger_effects)
	copy.end_turn_trigger_effects = _duplicate_effects(end_turn_trigger_effects)
	return copy


func _duplicate_effects(source: Array[Resource]) -> Array[Resource]:
	var copies: Array[Resource] = []
	for effect: Resource in source:
		copies.append(effect.duplicate(true) if effect else null)
	return copies


func get_default_tooltip() -> String:
	return _build_configured_tooltip()


func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	return _build_configured_tooltip(player_modifiers, enemy_modifiers)


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	for effect in configured_effects:
		if effect:
			effect.execute(self, targets, modifiers)


func handle_lifecycle_trigger(trigger: LifecycleTrigger, targets: Array[Node], modifiers: ModifierHandler) -> void:
	match trigger:
		Card.LifecycleTrigger.DISCARDED:
			_execute_trigger_effects(discard_trigger_effects, targets, modifiers)
		Card.LifecycleTrigger.EXHAUSTED:
			_execute_trigger_effects(exhaust_trigger_effects, targets, modifiers)
		Card.LifecycleTrigger.DRAWN:
			_execute_trigger_effects(draw_trigger_effects, targets, modifiers)
		Card.LifecycleTrigger.TURN_ENDED_IN_HAND:
			_execute_trigger_effects(end_turn_trigger_effects, targets, modifiers)
	_maybe_grow(trigger)


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
	var trigger_lines := _build_trigger_tooltip(discard_trigger_effects, "弃牌触发", player_modifiers, enemy_modifiers)
	if not trigger_lines.is_empty():
		text = _append_tooltip_line(text, trigger_lines)
	trigger_lines = _build_trigger_tooltip(exhaust_trigger_effects, "消耗触发", player_modifiers, enemy_modifiers)
	if not trigger_lines.is_empty():
		text = _append_tooltip_line(text, trigger_lines)
	trigger_lines = _build_trigger_tooltip(draw_trigger_effects, "抽牌触发", player_modifiers, enemy_modifiers)
	if not trigger_lines.is_empty():
		text = _append_tooltip_line(text, trigger_lines)
	trigger_lines = _build_trigger_tooltip(end_turn_trigger_effects, "滞留触发", player_modifiers, enemy_modifiers)
	if not trigger_lines.is_empty():
		text = _append_tooltip_line(text, trigger_lines)
	var growth_text := _get_growth_tooltip()
	if not growth_text.is_empty():
		text = _append_tooltip_line(text, growth_text)
	return with_runtime_tooltip("[center][b]%s[/b]\n%s[/center]" % [get_display_name(), text])


func _upgrade_values() -> void:
	for effect in configured_effects:
		if effect:
			effect.upgrade_values()
	for effect in discard_trigger_effects:
		if effect:
			effect.upgrade_values()
	for effect in exhaust_trigger_effects:
		if effect:
			effect.upgrade_values()
	for effect in draw_trigger_effects:
		if effect:
			effect.upgrade_values()
	for effect in end_turn_trigger_effects:
		if effect:
			effect.upgrade_values()


func get_spirit_root_primary_value() -> int:
	var result := 0
	for effect in configured_effects:
		if effect:
			result = maxi(result, effect.get_primary_value(self))
	return result


func _execute_trigger_effects(effects: Array[Resource], targets: Array[Node], modifiers: ModifierHandler) -> void:
	for effect in effects:
		if effect:
			effect.execute(self, targets, modifiers)


func _maybe_grow(trigger: LifecycleTrigger) -> void:
	if not is_growth_card() or growth_trigger == GrowthTrigger.NONE or growth_amount <= 0:
		return
	if not _growth_trigger_matches(trigger):
		return
	var remaining := growth_amount
	if growth_limit > 0:
		remaining = mini(remaining, growth_limit - growth_accumulated)
	if remaining <= 0:
		return
	for effect in configured_effects:
		if effect and effect.has_method("grow_values"):
			effect.grow_values(remaining)
	growth_accumulated += remaining


func _growth_trigger_matches(trigger: LifecycleTrigger) -> bool:
	match growth_trigger:
		GrowthTrigger.PLAYED:
			return trigger == Card.LifecycleTrigger.PLAYED
		GrowthTrigger.DISCARDED:
			return trigger == Card.LifecycleTrigger.DISCARDED
		GrowthTrigger.EXHAUSTED:
			return trigger == Card.LifecycleTrigger.EXHAUSTED
		_:
			return false


func _build_trigger_tooltip(
	effects: Array[Resource],
	label: String,
	player_modifiers: ModifierHandler,
	enemy_modifiers: ModifierHandler
) -> String:
	if effects.is_empty():
		return ""
	var lines := PackedStringArray()
	for effect in effects:
		if not effect:
			continue
		var line: String = effect.get_description(self, player_modifiers, enemy_modifiers)
		if not line.is_empty():
			lines.append(line)
	if lines.is_empty():
		return label
	return "%s：%s" % [label, " ".join(lines)]


func _get_growth_tooltip() -> String:
	if not is_growth_card() or growth_trigger == GrowthTrigger.NONE or growth_amount <= 0:
		return ""
	var trigger_name := ""
	match growth_trigger:
		GrowthTrigger.PLAYED:
			trigger_name = "打出后"
		GrowthTrigger.DISCARDED:
			trigger_name = "弃牌时"
		GrowthTrigger.EXHAUSTED:
			trigger_name = "消耗时"
	var suffix := ""
	if growth_limit > 0:
		suffix = "，最多成长 %s 点" % growth_limit
	return "成长：%s本牌数值 +%s%s。" % [trigger_name, growth_amount, suffix]


func _append_tooltip_line(text: String, line: String) -> String:
	if text.is_empty():
		return line
	return "%s\n%s" % [text, line]
