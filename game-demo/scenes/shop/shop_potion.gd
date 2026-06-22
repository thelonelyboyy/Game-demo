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


func _ready() -> void:
	_apply_visuals()


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
	gold_cost = PRICE_BY_RARITY.get(potion.rarity, 80)


func _on_buy_button_pressed() -> void:
	Events.shop_potion_bought.emit(potion, gold_cost)
	queue_free()


func _apply_visuals() -> void:
	custom_minimum_size = Vector2(132, 150)
	add_theme_constant_override("separation", 8)
	price.add_theme_constant_override("separation", 6)
	price_label.add_theme_color_override("font_color", Color("f2c94f"))
	price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	price_label.add_theme_constant_override("shadow_offset_x", 2)
	price_label.add_theme_constant_override("shadow_offset_y", 2)
	price_label.add_theme_font_size_override("font_size", 20)
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(108, 40)
