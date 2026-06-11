class_name BattleReward
extends Control

const CARD_REWARDS = preload("res://scenes/ui/card_rewards.tscn")
const CARD_FUSION = preload("res://scenes/card_fusion/card_fusion.tscn")
const CARD_FUSION_LIBRARY := preload("res://fusion_recipes/card_fusion_library.tres")
const REWARD_BUTTON = preload("res://scenes/ui/reward_button.tscn")
const REWARD_BACKGROUND := preload("res://art/treasure/treasure_room_bg.png")
const GOLD_ICON := preload("res://art/gold.png")
const GOLD_TEXT := "%s 灵石"
const CARD_ICON := preload("res://art/rarity.png")
const FUSION_ICON := preload("res://art/map/map_elite.png")
const FUSION_TEXT := "术法熔炼"
const CARD_TEXT := "择取新术法"
const REWARD_RARITY_ORDER := [
	Card.Rarity.COMMON,
	Card.Rarity.UNCOMMON,
	Card.Rarity.RARE,
	Card.Rarity.MYTHIC,
]

@export var run_stats: RunStats
@export var character_stats: CharacterStats
@export var relic_handler: RelicHandler

@onready var background: TextureRect = %Background
@onready var dimmer: ColorRect = %BackgroundDimmer
@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var reward_container: PanelContainer = %RewardContainer
@onready var rewards: BoxContainer = %Rewards
@onready var back_button: Button = %BackButton

var card_reward_total_weight := 0.0
var card_reward_choices: Array[Card] = []
var active_card_rewards: CardRewards
var active_card_fusion: CardFusion
var relic_choice_locked := false
var card_rarity_weights := {
	Card.Rarity.COMMON: 0.0,
	Card.Rarity.UNCOMMON: 0.0,
	Card.Rarity.RARE: 0.0,
	Card.Rarity.MYTHIC: 0.0,
}


func _ready() -> void:
	_apply_visuals()
	for node: Node in rewards.get_children():
		node.queue_free()


func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.reward_subtext = "收纳战后散落的灵石"
	gold_reward.accent_color = Color("f2c94f")
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)


func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.reward_subtext = "从三张术法中选择一张"
	card_reward.accent_color = Color("6fb2d8")
	card_reward.auto_consume = false
	card_reward.pressed.connect(_show_card_rewards.bind(card_reward))
	rewards.add_child.call_deferred(card_reward)


func add_relic_reward(relic: Relic) -> void:
	if not relic:
		return

	var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
	relic_reward.reward_icon = relic.icon
	relic_reward.reward_text = relic.relic_name
	relic_reward.reward_subtext = _make_relic_summary(relic, "获得一件法宝")
	relic_reward.accent_color = Color("d6b35c")
	relic_reward.pressed.connect(_on_relic_reward_taken.bind(relic))
	rewards.add_child.call_deferred(relic_reward)


func add_relic_choice_rewards(relics: Array[Relic]) -> void:
	if relics.is_empty():
		return
	if relics.size() == 1:
		add_relic_reward(relics[0])
		return

	_set_reward_copy("秘匣择宝", "两件法宝显形，只可取其一。")
	back_button.disabled = true
	back_button.text = "先择一件法宝"
	for relic: Relic in relics:
		if not relic:
			continue
		var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
		relic_reward.reward_icon = relic.icon
		relic_reward.reward_text = relic.relic_name
		relic_reward.reward_subtext = _make_relic_summary(relic, "点击收下此法宝")
		relic_reward.accent_color = Color("8fd9ef")
		relic_reward.auto_consume = false
		relic_reward.set_meta("relic_choice", true)
		relic_reward.pressed.connect(_on_relic_choice_taken.bind(relic))
		rewards.add_child.call_deferred(relic_reward)


func add_card_fusion_reward() -> void:
	var fusion_reward := REWARD_BUTTON.instantiate() as RewardButton
	fusion_reward.reward_icon = FUSION_ICON
	fusion_reward.reward_text = FUSION_TEXT
	fusion_reward.reward_subtext = "将旧术炼成新的战法"
	fusion_reward.accent_color = Color("b88ad8")
	fusion_reward.auto_consume = false
	fusion_reward.pressed.connect(_show_card_fusion.bind(fusion_reward))
	rewards.add_child.call_deferred(fusion_reward)


func _show_card_rewards(card_reward: RewardButton) -> void:
	if active_card_rewards or not run_stats or not character_stats:
		return

	active_card_rewards = CARD_REWARDS.instantiate() as CardRewards
	add_child(active_card_rewards)
	active_card_rewards.card_reward_selected.connect(_on_card_reward_taken.bind(card_reward))

	if card_reward_choices.is_empty():
		card_reward_choices = _generate_card_reward_choices()

	active_card_rewards.rewards = card_reward_choices
	active_card_rewards.show()


func _generate_card_reward_choices() -> Array[Card]:
	var card_reward_array: Array[Card] = []
	var available_cards: Array[Card] = character_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		_setup_card_chances()
		var picked_card := _pick_reward_card(available_cards)
		if not picked_card:
			break

		picked_card.bind_spirit_root_owner(character_stats)
		card_reward_array.append(picked_card)
		available_cards.erase(picked_card)

	return card_reward_array


func _pick_reward_card(available_cards: Array[Card]) -> Card:
	if available_cards.is_empty():
		return null

	var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)
	for rarity in REWARD_RARITY_ORDER:
		if card_rarity_weights[rarity] > roll:
			return _get_random_available_card(available_cards, rarity)

	return _get_random_available_card(available_cards, Card.Rarity.COMMON)


func _show_card_fusion(fusion_reward: RewardButton) -> void:
	if active_card_fusion or not character_stats:
		return

	active_card_fusion = CARD_FUSION.instantiate() as CardFusion
	add_child(active_card_fusion)
	active_card_fusion.card_pile = character_stats.deck
	active_card_fusion.fusion_library = CARD_FUSION_LIBRARY
	active_card_fusion.closed.connect(_on_card_fusion_closed)
	active_card_fusion.fusion_completed.connect(_on_card_fusion_completed.bind(fusion_reward))


func _setup_card_chances() -> void:
	card_reward_total_weight = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight + run_stats.mythic_weight
	card_rarity_weights[Card.Rarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Card.Rarity.UNCOMMON] = run_stats.common_weight + run_stats.uncommon_weight
	card_rarity_weights[Card.Rarity.RARE] = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	card_rarity_weights[Card.Rarity.MYTHIC] = card_reward_total_weight


func _get_random_available_card(available_cards: Array[Card], with_rarity: Card.Rarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card):
			return card.rarity == with_rarity
	)

	if all_possible_cards.is_empty():
		all_possible_cards = available_cards.filter(
			func(card: Card):
				return card.rarity != Card.Rarity.MYTHIC
		)
	if all_possible_cards.is_empty():
		all_possible_cards = available_cards

	return RNG.array_pick_random(all_possible_cards)


func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return

	run_stats.gold += amount


func _on_card_reward_taken(card: Card, card_reward: RewardButton) -> void:
	active_card_rewards = null
	if not character_stats or not card:
		return

	character_stats.deck.add_card(card)
	card_reward_choices.clear()
	if is_instance_valid(card_reward):
		card_reward.queue_free()


func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return

	relic_handler.add_relic(relic)


func _on_relic_choice_taken(relic: Relic) -> void:
	if relic_choice_locked or not relic or not relic_handler:
		return

	relic_choice_locked = true
	relic_handler.add_relic(relic)
	_set_reward_copy("法宝入囊", "灵光已定，继续前行。")
	back_button.disabled = false
	back_button.text = "继续"
	for node: Node in rewards.get_children():
		if node.has_meta("relic_choice"):
			node.queue_free()


func _on_card_fusion_closed() -> void:
	active_card_fusion = null


func _on_card_fusion_completed(_result: Card, fusion_reward: RewardButton) -> void:
	active_card_fusion = null
	if is_instance_valid(fusion_reward):
		fusion_reward.queue_free()


func _on_back_button_pressed() -> void:
	Events.battle_reward_exited.emit()


func _apply_visuals() -> void:
	background.texture = REWARD_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dimmer.color = Color(0.00, 0.03, 0.05, 0.34)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_set_reward_copy("战利归匣", "收下战斗所得，再继续向洞府深处前行。")

	reward_container.add_theme_stylebox_override("panel", _make_panel_style(
		Color(0.03, 0.12, 0.14, 0.76),
		Color(0.60, 0.48, 0.25, 0.76),
		2,
		8,
		Color(0, 0, 0, 0.54),
		18
	))
	rewards.add_theme_constant_override("separation", 18)
	_style_button(back_button, Color("b89648"))
	queue_redraw()


func _set_reward_copy(title_text: String, subtitle_text: String) -> void:
	if title:
		title.text = title_text
		title.add_theme_color_override("font_color", Color("f2c94f"))
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 5)
		title.add_theme_font_size_override("font_size", 56)
	if subtitle:
		subtitle.text = subtitle_text
		subtitle.add_theme_color_override("font_color", Color("d7eef4"))
		subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.76))
		subtitle.add_theme_constant_override("shadow_offset_x", 2)
		subtitle.add_theme_constant_override("shadow_offset_y", 3)
		subtitle.add_theme_font_size_override("font_size", 23)


func _make_relic_summary(relic: Relic, fallback: String) -> String:
	if not relic:
		return fallback
	var text := relic.get_tooltip().strip_edges()
	if text.is_empty():
		return fallback
	text = text.replace("\n", " ")
	return text.substr(0, 42) + ("..." if text.length() > 42 else "")


func _style_button(button: Button, accent: Color) -> void:
	button.text = "继续"
	button.custom_minimum_size = Vector2(190, 54)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("f4efe4"))
	button.add_theme_color_override("font_hover_color", Color("fff6dc"))
	button.add_theme_color_override("font_pressed_color", Color("f2c94f"))
	button.add_theme_color_override("font_disabled_color", Color(0.67, 0.63, 0.52, 0.48))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.05, 0.20, 0.24, 0.88), accent.darkened(0.25), 1, 6))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.08, 0.31, 0.36, 0.96), accent.lightened(0.20), 2, 6, Color(accent.r, accent.g, accent.b, 0.22), 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.03, 0.14, 0.17, 0.98), Color("f2c94f"), 2, 6))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color(0.05, 0.06, 0.06, 0.68), Color(0.42, 0.38, 0.30, 0.48), 1, 6))


func _draw() -> void:
	var center := size * Vector2(0.5, 0.54)
	draw_circle(center, 260.0, Color(0.05, 0.36, 0.42, 0.10))
	draw_arc(center, 314.0, -0.15, TAU - 0.15, 128, Color(0.78, 0.60, 0.26, 0.28), 2.0, true)
	draw_arc(center, 240.0, 0.42, TAU + 0.42, 128, Color(0.50, 0.86, 0.96, 0.18), 1.6, true)


func _make_panel_style(bg: Color, border: Color, border_width := 1, radius := 8, shadow := Color(0, 0, 0, 0.34), shadow_size := 8) -> StyleBoxFlat:
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
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
