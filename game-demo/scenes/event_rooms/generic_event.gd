class_name GenericEvent
extends EventRoom

@export var event_title := ""
@export_multiline var event_body := ""
@export var choice_texts := PackedStringArray()
@export var choice_effects := PackedStringArray()
@export var choice_amounts := PackedInt32Array()

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var choice_buttons: Array[EventRoomButton] = [
	%ChoiceButton1,
	%ChoiceButton2,
	%ChoiceButton3,
]


func setup() -> void:
	title_label.text = event_title
	body_label.text = event_body

	for index in choice_buttons.size():
		var button := choice_buttons[index]
		if index >= choice_texts.size():
			button.hide()
			continue

		var effect := _get_choice_effect(index)
		var amount := _get_choice_amount(index)
		button.show()
		button.text = choice_texts[index]
		button.disabled = not _can_apply_effect(effect, amount)
		button.event_button_callback = _apply_choice.bind(index)


func _apply_choice(index: int) -> void:
	var effect := _get_choice_effect(index)
	var amount := _get_choice_amount(index)
	_apply_effect_sequence(effect, amount)
	Events.event_choice_resolved.emit(effect, amount, character_stats, run_stats)


func _get_choice_effect(index: int) -> String:
	return choice_effects[index] if index < choice_effects.size() else "skip"


func _get_choice_amount(index: int) -> int:
	return choice_amounts[index] if index < choice_amounts.size() else 0


func _can_apply_effect(effect: String, amount: int) -> bool:
	for effect_part: String in _get_effect_parts(effect, amount):
		var parsed := _parse_effect_part(effect_part)
		if not _can_apply_single_effect(parsed[0], parsed[1]):
			return false
	return true


func _can_apply_single_effect(effect: String, amount: int) -> bool:
	match effect:
		"lose_gold":
			return run_stats and run_stats.gold >= amount
		"remove_random":
			return character_stats and character_stats.deck and character_stats.deck.cards.size() > 1
		"upgrade_random":
			return _get_upgrade_candidates().size() > 0
		_:
			return true


func _apply_effect_sequence(effect: String, amount: int) -> void:
	for effect_part: String in _get_effect_parts(effect, amount):
		var parsed := _parse_effect_part(effect_part)
		_apply_single_effect(parsed[0], parsed[1])


func _apply_single_effect(effect: String, amount: int) -> void:
	match effect:
		"gain_gold":
			if run_stats:
				run_stats.gold += amount
		"lose_gold":
			if run_stats:
				run_stats.gold = maxi(0, run_stats.gold - amount)
		"heal":
			if character_stats:
				character_stats.heal(amount)
		"damage":
			if character_stats:
				character_stats.health = maxi(1, character_stats.health - amount)
		"max_hp":
			if character_stats:
				character_stats.max_health += amount
		"upgrade_random":
			var candidates := _get_upgrade_candidates()
			if not candidates.is_empty():
				var card := RNG.array_pick_random(candidates) as Card
				if card:
					card.upgrade()
		"remove_random":
			if character_stats and character_stats.deck and character_stats.deck.cards.size() > 1:
				var card := RNG.array_pick_random(character_stats.deck.cards) as Card
				if card:
					character_stats.deck.remove_card(card)
		_:
			pass


func _get_effect_parts(effect: String, amount: int) -> PackedStringArray:
	if effect.is_empty() or effect == "skip":
		return PackedStringArray()
	if effect.contains(":") or effect.contains("|"):
		return effect.split("|", false)
	return PackedStringArray(["%s:%s" % [effect, amount]])


func _parse_effect_part(effect_part: String) -> Array:
	var effect_name := effect_part
	var amount := 0
	if effect_part.contains(":"):
		effect_name = effect_part.get_slice(":", 0)
		amount = effect_part.get_slice(":", 1).to_int()
	return [effect_name, amount]


func _get_upgrade_candidates() -> Array[Card]:
	var candidates: Array[Card] = []
	if not character_stats or not character_stats.deck:
		return candidates

	for card: Card in character_stats.deck.cards:
		if card and card.can_upgrade():
			candidates.append(card)
	return candidates
