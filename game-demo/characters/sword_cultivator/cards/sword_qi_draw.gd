extends Card

@export var cards_to_draw := 2
@export var exhaust_amount := 1


func get_default_tooltip() -> String:
	return tooltip_text % [get_spirit_root_modified_value(cards_to_draw), exhaust_amount]


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % [get_spirit_root_modified_value(cards_to_draw), exhaust_amount]


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var draw_effect := CardDrawEffect.new()
	draw_effect.cards_to_draw = get_spirit_root_modified_value(cards_to_draw)
	draw_effect.execute(targets)

	var exhaust_effect := ExhaustRandomEffect.new()
	exhaust_effect.amount = exhaust_amount
	exhaust_effect.execute(targets)


func _upgrade_values() -> void:
	cards_to_draw = _upgrade_number(cards_to_draw)


func get_spirit_root_primary_value() -> int:
	return get_spirit_root_modified_value(cards_to_draw)
