class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_RELIC = preload("res://scenes/shop/shop_relic.tscn")
const SHOP_POTION = preload("res://scenes/shop/shop_potion.tscn")
const SHOP_POTION_PATHS := PotionRewardPool.POTION_PATHS
const SHOP_POTION_COUNT := 4
const CARD_REMOVE_SCENE := preload("res://scenes/card_remove/card_remove.tscn")
const RELIC_REWARD_POOL := preload("res://relics/relic_reward_pool.tres")
const SHOP_BACKGROUND := preload("res://art/backgrounds/shop_market_bg.png")
const SHOP_SECTION_FRAME := preload("res://assets/ui/generated/panels/codex_main_content_panel_9slice.png")
const SHOP_SECTION_TITLE_PLATE := preload("res://assets/ui/generated/panels/codex_section_title_backplate_9slice.png")
const COMMON_SHOP_CARDS := [
	preload("res://common_cards/strike.tres"),
	preload("res://common_cards/defend.tres"),
	preload("res://common_cards/toxin.tres"),
	preload("res://common_cards/ink_flow_slash.tres"),
	preload("res://common_cards/muscle_resonance_strike.tres"),
]

const SHOP_CARD_COUNT := 6
const SHOP_RELIC_COUNT := 4
const MYTHIC_SHOP_CHANCE := 0.04

@export var shop_relics: Array[Relic]
@export var char_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler
@export var potion_handler: PotionHandler

@onready var ui_layer: CanvasLayer = $UILayer
@onready var background: TextureRect = $BackgroundLayer/Background
@onready var title: Label = $UILayer/Title
@onready var shop_content: VBoxContainer = $UILayer/ShopContent
@onready var cards: HBoxContainer = %Cards
@onready var relics: HBoxContainer = %Relics
@onready var potions: HBoxContainer = %Potions
@onready var back_button: Button = $UILayer/BackButton
@onready var remove_card_button: Button = %RemoveCardButton
@onready var shopkeeper: TextureRect = $DecorationLayer/Shopkeeper
@onready var shop_keeper_animation: AnimationPlayer = %ShopkeeperAnimation
@onready var blink_timer: Timer = %BlinkTimer
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var active_card_remove: CardRemove
var active_remove_cost := 0
var remove_service_used := false
var cards_section: PanelContainer
var relics_section: PanelContainer
var potions_section: PanelContainer
var remove_section: PanelContainer
var lower_sections: HBoxContainer


func _ready() -> void:
	InkTheme.animate_screen_entrance(self)
	_apply_shop_visuals()
	ui_layer.move_child(back_button, ui_layer.get_child_count() - 1)
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.queue_free()

	for shop_potion: ShopPotion in potions.get_children():
		shop_potion.queue_free()

	Events.shop_card_bought.connect(_on_shop_card_bought)
	Events.shop_relic_bought.connect(_on_shop_relic_bought)
	Events.shop_potion_bought.connect(_on_shop_potion_bought)
	remove_card_button.pressed.connect(_on_remove_card_button_pressed)

	_blink_timer_setup()
	blink_timer.timeout.connect(_on_blink_timer_timeout)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and card_tooltip_popup.visible:
		card_tooltip_popup.hide_tooltip()


func populate_shop() -> void:
	_generate_shop_cards()
	_generate_shop_relics()
	_generate_shop_potions()
	_update_remove_card_service()


func _blink_timer_setup() -> void:
	blink_timer.wait_time = randf_range(1.0, 5.0)
	blink_timer.start()


func _generate_shop_cards() -> void:
	var available_cards := _get_available_shop_cards()
	var shop_card_array := _pick_shop_cards(available_cards)
	var sale_index := RNG.instance.randi_range(0, shop_card_array.size() - 1) if not shop_card_array.is_empty() else -1

	for index in shop_card_array.size():
		var card: Card = shop_card_array[index]
		card.bind_spirit_root_owner(char_stats)
		var new_shop_card := SHOP_CARD.instantiate() as ShopCard
		cards.add_child(new_shop_card)
		new_shop_card.card = card
		new_shop_card.set_on_sale(index == sale_index)
		new_shop_card.current_card_ui.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
		new_shop_card.gold_cost = _get_item_cost(new_shop_card.base_gold_cost, new_shop_card.sale_multiplier)
		new_shop_card.update(run_stats)


func _pick_shop_cards(available_cards: Array[Card]) -> Array[Card]:
	RNG.array_shuffle(available_cards)
	var picked: Array[Card] = []

	var rare_cards := available_cards.filter(func(card: Card): return card.rarity == Card.Rarity.RARE)
	var guaranteed_rare := RNG.array_pick_random(rare_cards) as Card
	if guaranteed_rare:
		picked.append(guaranteed_rare)
		available_cards.erase(guaranteed_rare)

	var mythic_cards := available_cards.filter(func(card: Card): return card.rarity == Card.Rarity.MYTHIC)
	if not mythic_cards.is_empty() and RNG.instance.randf() < MYTHIC_SHOP_CHANCE:
		var mythic_card := RNG.array_pick_random(mythic_cards) as Card
		picked.append(mythic_card)
		available_cards.erase(mythic_card)

	var non_mythic_cards := available_cards.filter(func(card: Card): return card.rarity != Card.Rarity.MYTHIC)
	RNG.array_shuffle(non_mythic_cards)
	while picked.size() < SHOP_CARD_COUNT and not non_mythic_cards.is_empty():
		picked.append(non_mythic_cards.pop_front())

	return picked


func _get_available_shop_cards() -> Array[Card]:
	var result := _dedupe_cards_by_id(char_stats.draftable_cards.duplicate_cards())

	for common_card: Card in COMMON_SHOP_CARDS:
		var card_copy := common_card.duplicate(true) as Card
		if card_copy:
			result.append(card_copy)

	return _dedupe_cards_by_id(result)


func _dedupe_cards_by_id(source_cards: Array[Card]) -> Array[Card]:
	var result: Array[Card] = []
	var seen_ids := {}
	for card: Card in source_cards:
		if not card or seen_ids.has(card.id):
			continue
		seen_ids[card.id] = true
		result.append(card)
	return result


func _generate_shop_relics() -> void:
	var shop_relics_array: Array[Relic] = RELIC_REWARD_POOL.get_random_available_choices(
		char_stats,
		relic_handler,
		SHOP_RELIC_COUNT,
		run_stats.current_chapter if run_stats else 1,
		RelicRewardPool.RewardContext.SHOP
	)

	for relic in shop_relics_array:
		var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
		relics.add_child(new_shop_relic)
		new_shop_relic.relic = relic
		new_shop_relic.gold_cost = _get_item_cost(new_shop_relic.base_gold_cost)
		new_shop_relic.update(run_stats)


func _append_available_relic(relic, available_relics: Array, seen_ids: Dictionary) -> void:
	if not relic or seen_ids.has(relic.id):
		return

	seen_ids[relic.id] = true
	var can_appear: bool = relic.can_appear_as_reward(char_stats)
	var already_had_it: bool = relic_handler and relic_handler.has_relic(relic.id)
	if can_appear and not already_had_it:
		available_relics.append(relic)


func _generate_shop_potions() -> void:
	var available: Array[Potion] = []
	for path in SHOP_POTION_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var potion := load(path) as Potion
		if potion and potion.can_appear_as_reward(char_stats):
			available.append(potion)

	var shop_choices := PotionRewardPool.pick_choices(
		available,
		SHOP_POTION_COUNT,
		run_stats.current_chapter if run_stats else 1,
		PotionRewardPool.RewardContext.SHOP
	)
	for potion: Potion in shop_choices:
		var new_shop_potion := SHOP_POTION.instantiate() as ShopPotion
		potions.add_child(new_shop_potion)
		new_shop_potion.potion = potion
		new_shop_potion.gold_cost = _get_item_cost(new_shop_potion.base_gold_cost)
		new_shop_potion.update(run_stats)


func _on_shop_potion_bought(potion: Potion, gold_cost: int) -> void:
	if not potion_handler or potion_handler.is_full():
		return
	potion_handler.add_potion(potion)
	run_stats.gold -= gold_cost
	GameSfx.play(GameSfx.COINS, -4.0)
	_update_items()


func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.update(run_stats)

	for shop_potion: ShopPotion in potions.get_children():
		shop_potion.update(run_stats)

	_update_remove_card_service()


func _update_item_costs() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.gold_cost = _get_item_cost(shop_card.base_gold_cost, shop_card.sale_multiplier)
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics.get_children():
		shop_relic.gold_cost = _get_item_cost(shop_relic.base_gold_cost)
		shop_relic.update(run_stats)

	for shop_potion: ShopPotion in potions.get_children():
		shop_potion.gold_cost = _get_item_cost(shop_potion.base_gold_cost)
		shop_potion.update(run_stats)

	_update_remove_card_service()


func _get_updated_shop_cost(original_cost: int) -> int:
	var modified_cost := modifier_handler.get_modified_value(original_cost, Modifier.Type.SHOP_COST)
	if run_stats:
		modified_cost = run_stats.apply_shop_cost_multiplier(modified_cost)
	return modified_cost


func _get_item_cost(base_cost: int, sale_multiplier := 1.0) -> int:
	return maxi(1, ceili(_get_updated_shop_cost(base_cost) * sale_multiplier))


func _get_remove_card_cost() -> int:
	if not run_stats:
		return RunStats.BASE_CARD_REMOVE_COST
	return _get_updated_shop_cost(run_stats.card_remove_cost)


func _update_remove_card_service() -> void:
	if not remove_card_button or not run_stats or not char_stats:
		return

	var cost := _get_remove_card_cost()
	var can_remove := char_stats.deck and char_stats.deck.cards.size() > 1
	if remove_service_used:
		remove_card_button.text = "本次坊市已完成净化"
	elif active_card_remove:
		remove_card_button.text = "正在选择要净化的卡牌…"
	elif not can_remove:
		remove_card_button.text = "牌组至少保留一张卡牌"
	else:
		remove_card_button.text = "净化一张卡牌\n%s 灵石" % cost
	remove_card_button.disabled = (
		remove_service_used
		or active_card_remove != null
		or run_stats.gold < cost
		or not can_remove
	)


func _on_remove_card_button_pressed() -> void:
	if active_card_remove or remove_service_used or not char_stats or not char_stats.deck:
		return

	active_remove_cost = _get_remove_card_cost()
	if run_stats.gold < active_remove_cost or char_stats.deck.cards.size() <= 1:
		_update_remove_card_service()
		return

	active_card_remove = CARD_REMOVE_SCENE.instantiate() as CardRemove
	ui_layer.add_child(active_card_remove)
	active_card_remove.card_pile = char_stats.deck
	active_card_remove.closed.connect(_on_card_remove_closed)
	active_card_remove.card_removed.connect(_on_card_removed)
	_update_remove_card_service()


func _on_card_removed(card: Card) -> void:
	Events.shop_card_removed.emit(card, active_remove_cost)
	run_stats.gold -= active_remove_cost
	run_stats.card_remove_cost += RunStats.CARD_REMOVE_COST_INCREMENT
	active_remove_cost = 0
	remove_service_used = true

	if active_card_remove:
		active_card_remove.queue_free()
		active_card_remove = null

	_update_items()


func _on_card_remove_closed() -> void:
	active_card_remove = null
	active_remove_cost = 0
	_update_remove_card_service()


func _on_back_button_pressed() -> void:
	Events.shop_exited.emit()


func _on_shop_card_bought(card: Card, gold_cost: int) -> void:
	char_stats.deck.add_card(card)
	run_stats.gold -= gold_cost
	GameSfx.play(GameSfx.COINS, -4.0)
	_update_items()


func _on_shop_relic_bought(relic: Relic, gold_cost: int) -> void:
	relic_handler.add_relic(relic)
	run_stats.gold -= gold_cost
	GameSfx.play(GameSfx.COINS, -4.0)

	if relic is CouponsRelic:
		var coupons_relic := relic as CouponsRelic
		coupons_relic.add_shop_modifier(self)
		_update_item_costs()
	else:
		_update_items()


func _on_blink_timer_timeout() -> void:
	shop_keeper_animation.play("blink")
	_blink_timer_setup()


func _apply_shop_visuals() -> void:
	background.texture = SHOP_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.03, 0.00, 0.00, 0.28)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	$BackgroundLayer.add_child(dimmer)

	shopkeeper.hide()

	title.text = "坊市"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -120.0
	title.offset_top = 76.0
	title.offset_right = 120.0
	title.offset_bottom = 126.0
	InkTheme.apply_screen_title(title, 50)

	_add_subtitle()
	_add_market_panel()
	_build_shop_sections()

	shop_content.offset_left = -790.0
	shop_content.offset_top = -335.0
	shop_content.offset_right = 790.0
	shop_content.offset_bottom = 415.0
	shop_content.add_theme_constant_override("separation", 18)

	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 18)
	relics.alignment = BoxContainer.ALIGNMENT_CENTER
	relics.add_theme_constant_override("separation", 12)
	potions.alignment = BoxContainer.ALIGNMENT_CENTER
	potions.add_theme_constant_override("separation", 12)

	back_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_button.offset_left = 38.0
	back_button.offset_top = -112.0
	back_button.offset_right = 270.0
	back_button.offset_bottom = -30.0
	back_button.custom_minimum_size = Vector2(232, 82)
	back_button.text = "离开"
	_style_button(back_button)
	back_button.add_theme_font_size_override("font_size", 27)

	remove_card_button.custom_minimum_size = Vector2(350, 104)
	remove_card_button.add_theme_font_size_override("font_size", 27)
	remove_card_button.tooltip_text = "每次进入坊市只能净化一张卡牌；净化费用会随使用次数逐步提高。"
	_style_button(remove_card_button)


func _add_subtitle() -> void:
	if $UILayer.has_node("Subtitle"):
		return

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "灵石可换符牌法宝，也可请掌柜净化一张旧牌。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 固定锚到屏幕上沿并留出安全边距，避免较矮分辨率下说明文字顶到窗口外。
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.offset_left = -520.0
	subtitle.offset_top = 124.0
	subtitle.offset_right = 520.0
	subtitle.offset_bottom = 152.0
	InkTheme.apply_subtitle(subtitle, 19)
	ui_layer.add_child(subtitle)


func _add_market_panel() -> void:
	if $UILayer.has_node("MarketPanel"):
		return

	var panel := PanelContainer.new()
	panel.name = "MarketPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -820.0
	panel.offset_top = -350.0
	panel.offset_right = 820.0
	panel.offset_bottom = 430.0
	InkTheme.apply_screen_panel(panel)
	ui_layer.add_child(panel)
	ui_layer.move_child(panel, shop_content.get_index())


func _build_shop_sections() -> void:
	if cards_section:
		return

	for child in shop_content.get_children():
		shop_content.remove_child(child)

	var cards_data := _create_shop_section(
		"CardsSection",
		"卡牌",
		"扩充牌组 · 每次坊市必有一张稀有卡与一张半价卡",
		Vector2(0, 478),
		Color("d2a34b")
	)
	cards_section = cards_data["panel"] as PanelContainer
	shop_content.add_child(cards_section)
	(cards_data["body"] as VBoxContainer).add_child(cards)

	lower_sections = HBoxContainer.new()
	lower_sections.name = "LowerSections"
	lower_sections.custom_minimum_size = Vector2(0, 254)
	lower_sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower_sections.add_theme_constant_override("separation", 18)
	shop_content.add_child(lower_sections)

	var relics_data := _create_shop_section(
		"RelicsSection",
		"法宝",
		"永久强化本轮构筑",
		Vector2(630, 254),
		Color("a879d8")
	)
	relics_section = relics_data["panel"] as PanelContainer
	lower_sections.add_child(relics_section)
	(relics_data["body"] as VBoxContainer).add_child(relics)

	var potions_data := _create_shop_section(
		"PotionsSection",
		"符箓丹药",
		"一次性战斗补给",
		Vector2(520, 254),
		Color("61b9ad")
	)
	potions_section = potions_data["panel"] as PanelContainer
	lower_sections.add_child(potions_section)
	(potions_data["body"] as VBoxContainer).add_child(potions)

	var remove_data := _create_shop_section(
		"RemoveSection",
		"删牌",
		"净化旧牌 · 每次坊市限一次",
		Vector2(394, 254),
		Color("d06a55")
	)
	remove_section = remove_data["panel"] as PanelContainer
	lower_sections.add_child(remove_section)
	var remove_body := remove_data["body"] as VBoxContainer
	remove_body.alignment = BoxContainer.ALIGNMENT_CENTER
	remove_body.add_child(remove_card_button)


func _create_shop_section(
	section_name: String,
	heading: String,
	description: String,
	minimum_size: Vector2,
	accent: Color
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = section_name
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_shop_section_style(accent))

	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 4)
	panel.add_child(body)

	var heading_plate := PanelContainer.new()
	heading_plate.name = "HeadingPlate"
	heading_plate.custom_minimum_size = Vector2(0, 32)
	heading_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_plate.add_theme_stylebox_override("panel", _make_shop_heading_style(accent))
	body.add_child(heading_plate)

	var heading_label := Label.new()
	heading_label.name = "Heading"
	heading_label.text = heading
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading_label.custom_minimum_size = Vector2(0, 28)
	heading_label.add_theme_font_size_override("font_size", 24)
	heading_label.add_theme_color_override("font_color", accent.lightened(0.28))
	heading_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	heading_label.add_theme_constant_override("shadow_offset_x", 2)
	heading_label.add_theme_constant_override("shadow_offset_y", 2)
	heading_plate.add_child(heading_label)

	var description_label := Label.new()
	description_label.name = "Description"
	description_label.text = description
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.custom_minimum_size = Vector2(0, 20)
	description_label.add_theme_font_size_override("font_size", 17)
	description_label.add_theme_color_override("font_color", Color(0.87, 0.81, 0.70, 0.88))
	body.add_child(description_label)

	return {"panel": panel, "body": body}


func _make_shop_section_style(accent: Color) -> StyleBoxTexture:
	# 复用图鉴主面板的九宫格美术边框；轻微染色只用于区分商店分区。
	var tint := Color(
		lerpf(1.0, accent.r, 0.14),
		lerpf(1.0, accent.g, 0.14),
		lerpf(1.0, accent.b, 0.14),
		0.96
	)
	var style := InkTheme.make_texture_style(SHOP_SECTION_FRAME, 56, 56, tint)
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	return style


func _make_shop_heading_style(accent: Color) -> StyleBoxTexture:
	var tint := Color(
		lerpf(0.92, accent.r, 0.22),
		lerpf(0.86, accent.g, 0.22),
		lerpf(0.72, accent.b, 0.22),
		0.98
	)
	var style := InkTheme.make_texture_style(SHOP_SECTION_TITLE_PLATE, 44, 14, tint)
	style.content_margin_left = 16
	style.content_margin_top = 0
	style.content_margin_right = 16
	style.content_margin_bottom = 0
	return style


func _style_button(button: Button) -> void:
	InkTheme.apply_screen_button(button)
