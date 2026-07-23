class_name ShopPotion
extends VBoxContainer

const PRICE_BY_RARITY := {
	Card.Rarity.COMMON: 55,
	Card.Rarity.UNCOMMON: 80,
	Card.Rarity.RARE: 115,
	Card.Rarity.MYTHIC: 150,
}

@export var potion: Potion : set = set_potion

@onready var icon: TextureRect = %Icon
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

var gold_cost := 0
var base_gold_cost := 0


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
	if not price_label or not buy_button:
		return
	price_label.text = str(gold_cost)
	if run_stats.gold >= gold_cost:
		price_label.add_theme_color_override("font_color", Color("f2c94f"))
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color("e85d4d"))
		buy_button.disabled = true


func set_potion(new_potion: Potion) -> void:
	if not is_node_ready():
		await ready
	potion = new_potion
	if not potion:
		return
	icon.texture = potion.icon
	var label := "符箓" if potion.category == Potion.Category.TALISMAN else "丹药"
	icon.tooltip_text = "%s（%s）\n%s" % [potion.potion_name, label, potion.get_tooltip()]
	base_gold_cost = PRICE_BY_RARITY.get(potion.rarity, 80)
	gold_cost = base_gold_cost


func _on_buy_button_pressed() -> void:
	Events.shop_potion_bought.emit(potion, gold_cost)
	queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(112, 150)
	add_theme_constant_override("separation", 8)
	price.add_theme_constant_override("separation", 6)
	price_label.add_theme_color_override("font_color", Color("f2c94f"))
	price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	price_label.add_theme_constant_override("shadow_offset_x", 2)
	price_label.add_theme_constant_override("shadow_offset_y", 2)
	price_label.add_theme_font_size_override("font_size", 20)
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(96, 40)
	InkTheme.apply_screen_button(buy_button)
	buy_button.add_theme_font_size_override("font_size", 19)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


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
