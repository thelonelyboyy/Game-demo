class_name CouponsRelic
extends Relic

@export_range(1, 100) var discount := 50

var relic_ui: RelicUI


func initialize_relic(owner: RelicUI) -> void:
	Events.shop_entered.connect(add_shop_modifier)
	relic_ui = owner


func deactivate_relic(_owner: RelicUI) -> void:
	Events.shop_entered.disconnect(add_shop_modifier)


func add_shop_modifier(shop) -> void:
	if not shop or not shop.modifier_handler:
		return

	var shop_cost_modifier: Modifier = shop.modifier_handler.get_modifier(Modifier.Type.SHOP_COST)
	assert(shop_cost_modifier, "No shop cost modifier in shop!")

	var coupons_modifier_value: ModifierValue = shop_cost_modifier.get_value("coupons")

	if not coupons_modifier_value:
		coupons_modifier_value = ModifierValue.create_new_modifier("coupons", ModifierValue.Type.PERCENT_BASED)
		coupons_modifier_value.percent_value = -1 * discount / 100.0
		shop_cost_modifier.add_new_value(coupons_modifier_value)

	relic_ui.flash()
