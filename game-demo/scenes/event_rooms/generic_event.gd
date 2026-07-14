class_name GenericEvent
extends EventRoom

const HEART_DEMON := preload("res://common_cards/status/heart_demon.tres")
const BLOOD_DEBT_CURSE := preload("res://common_cards/status/blood_debt_curse.tres")
const KARMIC_FIRE_CURSE := preload("res://common_cards/status/karmic_fire_curse.tres")
const CURSE_POOL: Array[Card] = [HEART_DEMON, BLOOD_DEBT_CURSE, KARMIC_FIRE_CURSE]

@export var event_title := ""
@export_multiline var event_body := ""
@export var event_illustration: Texture2D
@export var choice_texts := PackedStringArray()
@export var choice_effects := PackedStringArray()
@export var choice_amounts := PackedInt32Array()

@export_group("Spirit Root Choice Override")
@export_range(-1, 2) var spirit_root_choice_index := -1
@export var spirit_root_choice_texts := PackedStringArray()
@export var spirit_root_choice_effects := PackedStringArray()
@export var spirit_root_choice_amounts := PackedInt32Array()

@onready var background: ColorRect = $ColorRect
@onready var content_box: VBoxContainer = $VBoxContainer
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var choice_buttons: Array[EventRoomButton] = [
	%ChoiceButton1,
	%ChoiceButton2,
	%ChoiceButton3,
]

var event_panel: PanelContainer
var illustration_panel: PanelContainer
var illustration_rect: TextureRect


func setup() -> void:
	_apply_event_style()
	_refresh_illustration()
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
		button.text = _get_choice_text(index)
		button.disabled = not _can_apply_effect(effect, amount)
		button.event_button_callback = _apply_choice.bind(index)
		_apply_choice_button_style(button)


func _apply_choice(index: int) -> void:
	var effect := _get_choice_effect(index)
	var amount := _get_choice_amount(index)
	_apply_effect_sequence(effect, amount)
	Events.event_choice_resolved.emit(effect, amount, character_stats, run_stats)


func _get_choice_effect(index: int) -> String:
	var root_index := _get_spirit_root_override_index(index)
	if root_index >= 0 and root_index < spirit_root_choice_effects.size():
		var root_effect := spirit_root_choice_effects[root_index]
		if not root_effect.is_empty():
			return root_effect
	return choice_effects[index] if index < choice_effects.size() else "skip"


func _get_choice_amount(index: int) -> int:
	var root_index := _get_spirit_root_override_index(index)
	if root_index >= 0 and root_index < spirit_root_choice_amounts.size():
		return spirit_root_choice_amounts[root_index]
	return choice_amounts[index] if index < choice_amounts.size() else 0


func _get_choice_text(index: int) -> String:
	var root_index := _get_spirit_root_override_index(index)
	if root_index >= 0 and root_index < spirit_root_choice_texts.size():
		var root_text := spirit_root_choice_texts[root_index]
		if not root_text.is_empty():
			return root_text
	return choice_texts[index] if index < choice_texts.size() else "离开"


func _get_spirit_root_override_index(index: int) -> int:
	if index != spirit_root_choice_index or not character_stats or not character_stats.has_spirit_root():
		return -1
	return int(character_stats.spirit_root)


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
		"gain_random_card":
			return not _get_draftable_candidates(false).is_empty()
		"gain_rare_card":
			return not _get_draftable_candidates(true).is_empty()
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
					_emit_card_feedback("突破卡牌", [card], "卡牌已完成突破。")
		"remove_random":
			if character_stats and character_stats.deck and character_stats.deck.cards.size() > 1:
				var card := RNG.array_pick_random(character_stats.deck.cards) as Card
				if card:
					character_stats.deck.remove_card(card)
					_emit_card_feedback("移除卡牌", [card], "卡牌已从本次牌组中移除。")
		"gain_random_card":
			_add_random_draftable_cards(maxi(amount, 1), false)
		"gain_rare_card":
			_add_random_draftable_cards(maxi(amount, 1), true)
		"gain_curse":
			_add_random_curses(maxi(amount, 1))
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


func _get_draftable_candidates(rare_only: bool) -> Array[Card]:
	var candidates: Array[Card] = []
	if not character_stats or not character_stats.draftable_cards:
		return candidates
	for card: Card in character_stats.draftable_cards.cards:
		if not card or card.rarity == Card.Rarity.MYTHIC:
			continue
		if rare_only and card.rarity != Card.Rarity.RARE:
			continue
		candidates.append(card)
	return candidates


func _add_random_draftable_cards(count: int, rare_only: bool) -> void:
	if not character_stats or not character_stats.deck:
		return
	var candidates := _get_draftable_candidates(rare_only)
	var added_cards: Array[Card] = []
	for _i in count:
		if candidates.is_empty():
			break
		var picked := RNG.array_pick_random(candidates) as Card
		if picked:
			var card_copy := picked.duplicate(true) as Card
			character_stats.deck.add_card(card_copy)
			added_cards.append(card_copy)
	_emit_card_feedback("获得卡牌", added_cards, "以下卡牌已加入牌组。")


func _add_random_curses(count: int) -> Array[Card]:
	var added: Array[Card] = []
	if not character_stats or not character_stats.deck or count <= 0:
		return added

	var candidates: Array[Card] = CURSE_POOL.duplicate()
	RNG.array_shuffle(candidates)
	for _i in mini(count, candidates.size()):
		var curse := candidates.pop_back().duplicate(true) as Card
		if not curse:
			continue
		character_stats.deck.add_card(curse)
		added.append(curse)

	if not added.is_empty():
		_emit_card_feedback("获得诅咒", added, "以下诅咒已加入牌组。")
	return added


func _emit_card_feedback(title: String, cards: Array, detail: String) -> void:
	var typed_cards: Array[Card] = []
	for card: Card in cards:
		if card:
			typed_cards.append(card)
	if not typed_cards.is_empty():
		Events.card_change_feedback_requested.emit(title, typed_cards, detail)


func _apply_event_style() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if background:
		background.color = Color(0.018, 0.016, 0.017, 0.94)

	if not event_panel:
		event_panel = PanelContainer.new()
		event_panel.name = "EventPanel"
		event_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		event_panel.set_anchors_preset(Control.PRESET_CENTER)
		event_panel.offset_left = -455
		event_panel.offset_top = -365
		event_panel.offset_right = 455
		event_panel.offset_bottom = 365
		event_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.030, 0.023, 0.022, 0.82), Color(0.72, 0.52, 0.25, 0.72), 2, 8))
		add_child(event_panel)
		if content_box:
			move_child(event_panel, content_box.get_index())

	if content_box:
		content_box.set_anchors_preset(Control.PRESET_CENTER)
		content_box.offset_left = -390
		content_box.offset_top = -335
		content_box.offset_right = 390
		content_box.offset_bottom = 335
		content_box.add_theme_constant_override("separation", 12)

	if title_label:
		title_label.custom_minimum_size = Vector2(780, 58)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_color_override("font_color", Color("f2c94f"))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)
		title_label.add_theme_font_size_override("font_size", 42)

	if body_label:
		body_label.custom_minimum_size = Vector2(760, 78)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		body_label.add_theme_color_override("font_color", Color("efe6d0"))
		body_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
		body_label.add_theme_constant_override("shadow_offset_x", 2)
		body_label.add_theme_constant_override("shadow_offset_y", 2)
		body_label.add_theme_font_size_override("font_size", 23)


func _refresh_illustration() -> void:
	if not event_illustration or not content_box or not body_label:
		if illustration_panel:
			illustration_panel.hide()
		return

	if not illustration_panel:
		illustration_panel = PanelContainer.new()
		illustration_panel.name = "IllustrationPanel"
		illustration_panel.custom_minimum_size = Vector2(760, 270)
		illustration_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		illustration_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.010, 0.012, 0.96), Color(0.82, 0.61, 0.27, 0.78), 1, 6, Color(0, 0, 0, 0.45), 10))
		content_box.add_child(illustration_panel)
		content_box.move_child(illustration_panel, body_label.get_index())

		illustration_rect = TextureRect.new()
		illustration_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		illustration_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		illustration_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		illustration_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		illustration_panel.add_child(illustration_rect)

	illustration_rect.texture = event_illustration
	illustration_panel.show()


func _apply_choice_button_style(button: Button) -> void:
	button.custom_minimum_size = Vector2(760, 62)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.050, 0.036, 0.030, 0.88), Color(0.54, 0.40, 0.20, 0.80), 1, 6))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.105, 0.055, 0.045, 0.94), Color("f2c94f"), 2, 6, Color(0.75, 0.32, 0.14, 0.18), 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.035, 0.025, 0.024, 0.98), Color(0.86, 0.55, 0.25, 0.92), 2, 6))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color(0.025, 0.023, 0.024, 0.70), Color(0.28, 0.24, 0.19, 0.65), 1, 6))
	button.add_theme_color_override("font_color", Color("f4e6c6"))
	button.add_theme_color_override("font_hover_color", Color("fff4d6"))
	button.add_theme_color_override("font_pressed_color", Color("dba65d"))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.52, 0.44, 0.72))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_font_size_override("font_size", 22)


func _make_panel_style(
	bg: Color,
	border: Color,
	border_width := 1,
	radius := 6,
	shadow := Color(0, 0, 0, 0.36),
	shadow_size := 8
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_top = 8
	style.content_margin_right = 14
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
