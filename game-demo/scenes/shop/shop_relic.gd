class_name ShopRelic
extends VBoxContainer

const RELIC_UI = preload("res://scenes/relic_handler/relic_ui.tscn")

@export var relic: Relic : set = set_relic

@onready var relic_container: CenterContainer = %RelicContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

const RELIC_PRICE_RANGES := {
	Relic.Rarity.COMMON: Vector2i(150, 190),
	Relic.Rarity.UNCOMMON: Vector2i(210, 260),
	Relic.Rarity.RARE: Vector2i(300, 380),
	Relic.Rarity.BOSS: Vector2i(450, 520),
}

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
	if not relic_container or not price or not buy_button:
		return

	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.add_theme_color_override("font_color", Color("f2c94f"))
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color("e85d4d"))
		buy_button.disabled = true


func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready

	relic = new_relic
	var price_range := get_price_range(relic.rarity)
	base_gold_cost = RNG.instance.randi_range(price_range.x, price_range.y)
	gold_cost = base_gold_cost

	for relic_ui: RelicUI in relic_container.get_children():
		relic_ui.queue_free()
	
	var new_relic_ui := RELIC_UI.instantiate() as RelicUI
	relic_container.add_child(new_relic_ui)
	new_relic_ui.relic = relic


static func get_price_range(rarity: Relic.Rarity) -> Vector2i:
	return RELIC_PRICE_RANGES.get(rarity, RELIC_PRICE_RANGES[Relic.Rarity.COMMON])


func _on_buy_button_pressed() -> void:
	Events.shop_relic_bought.emit(relic, gold_cost)
	relic_container.queue_free()
	price.queue_free()
	buy_button.queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(160, 174)
	add_theme_constant_override("separation", 8)
	relic_container.custom_minimum_size = Vector2(80, 66)
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
