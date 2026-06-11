class_name ShopCard
extends VBoxContainer

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")

@export var card: Card : set = set_card

@onready var card_container: CenterContainer = %CardContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := RNG.instance.randi_range(100, 300)

var current_card_ui: CardMenuUI


func _ready() -> void:
	_apply_visuals()


func _draw() -> void:
	draw_style_box(_make_panel_style(
		Color(0.04, 0.13, 0.15, 0.78),
		Color(0.60, 0.48, 0.25, 0.72),
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
	
	for card_menu_ui: CardMenuUI in card_container.get_children():
		card_menu_ui.queue_free()
	
	var new_card_menu_ui := CARD_MENU_UI.instantiate() as CardMenuUI
	card_container.add_child(new_card_menu_ui)
	new_card_menu_ui.card = card
	current_card_ui = new_card_menu_ui


func _on_buy_button_pressed() -> void:
	Events.shop_card_bought.emit(card, gold_cost)
	card_container.queue_free()
	price.queue_free()
	buy_button.queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(184, 344)
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
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("f4efe4"))
	button.add_theme_color_override("font_hover_color", Color("fff6dc"))
	button.add_theme_color_override("font_pressed_color", Color("f2c94f"))
	button.add_theme_color_override("font_disabled_color", Color(0.67, 0.63, 0.52, 0.44))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.05, 0.20, 0.24, 0.86), Color(0.46, 0.66, 0.70, 0.72), 1, 5))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.08, 0.31, 0.36, 0.96), Color(0.54, 0.90, 0.96, 0.86), 2, 5, Color(0.20, 0.86, 1.0, 0.18), 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.03, 0.14, 0.17, 0.98), Color("f2c94f"), 2, 5))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color(0.05, 0.06, 0.06, 0.68), Color(0.42, 0.38, 0.30, 0.48), 1, 5))


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
