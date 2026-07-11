class_name ShopCard
extends VBoxContainer

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")

@export var card: Card : set = set_card

@onready var card_container: CenterContainer = %CardContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

# 按稀有度定基价（±10% 浮动），不再与稀有度脱钩
const PRICE_BY_RARITY := {
	Card.Rarity.COMMON: 90,
	Card.Rarity.UNCOMMON: 140,
	Card.Rarity.RARE: 210,
	Card.Rarity.MYTHIC: 320,
}

var gold_cost := 0
var base_gold_cost := 0
var sale_multiplier := 1.0
var is_on_sale := false
var current_card_ui: CardMenuUI


func _roll_card_price(rarity: Card.Rarity) -> int:
	var base: int = PRICE_BY_RARITY.get(rarity, 140)
	return RNG.instance.randi_range(roundi(base * 0.9), roundi(base * 1.1))


func _ready() -> void:
	_apply_visuals()
	InkTheme.animate_item_entrance(self, 0.07)


func _draw() -> void:
	draw_style_box(_make_panel_style(
		Color(0.045, 0.030, 0.028, 0.82),
		Color(0.62, 0.42, 0.22, 0.76),
		1,
		8,
		Color(0, 0, 0, 0.42),
		10
	), Rect2(Vector2.ZERO, size))


func update(run_stats: RunStats) -> void:
	if not card_container or not price or not buy_button:
		return

	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.add_theme_color_override("font_color", Color("f2c94f"))
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color("e85d4d"))
		buy_button.disabled = true


func set_card(new_card: Card) -> void:
	if not is_node_ready():
		await ready

	card = new_card
	base_gold_cost = _roll_card_price(card.rarity)
	gold_cost = base_gold_cost

	for card_menu_ui: CardMenuUI in card_container.get_children():
		card_menu_ui.queue_free()
	
	var new_card_menu_ui := CARD_MENU_UI.instantiate() as CardMenuUI
	card_container.add_child(new_card_menu_ui)
	new_card_menu_ui.card = card
	current_card_ui = new_card_menu_ui


func set_on_sale(value: bool) -> void:
	is_on_sale = value
	sale_multiplier = 0.5 if value else 1.0
	tooltip_text = "本店特惠：最终价格减半。" if value else ""
	if buy_button:
		buy_button.text = "半价购买" if value else "购买"


func _on_buy_button_pressed() -> void:
	var from_center := global_position + size * 0.5
	if current_card_ui and is_instance_valid(current_card_ui):
		from_center = current_card_ui.get_global_rect().get_center()
	Events.shop_card_bought.emit(card, gold_cost)
	# 购买反馈：run 顶栏播放"卡牌飞向总牌库"动画。
	Events.card_acquired_animation_requested.emit(card, from_center)
	card_container.queue_free()
	price.queue_free()
	buy_button.queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(216, 392)
	add_theme_constant_override("separation", 8)
	price.add_theme_constant_override("separation", 6)
	price_label.add_theme_color_override("font_color", Color("f2c94f"))
	price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	price_label.add_theme_constant_override("shadow_offset_x", 2)
	price_label.add_theme_constant_override("shadow_offset_y", 2)
	price_label.add_theme_font_size_override("font_size", 22)
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(124, 42)
	_style_button(buy_button)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _style_button(button: Button) -> void:
	InkTheme.apply_screen_button(button)
	button.add_theme_font_size_override("font_size", 20)


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
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	return style
