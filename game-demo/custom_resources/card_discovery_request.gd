class_name CardDiscoveryRequest
extends RefCounted

signal completed(selected_cards: Array[Card])

var source_card: Card
var title := "发现"
var prompt := ""
var choices: Array[Card] = []
var picks := 1
var allow_skip := false
var bonus_upgrade_count := 0
var resolved := false


func resolve(selected_cards: Array[Card]) -> void:
	if resolved:
		return
	resolved = true
	var upgrades_remaining := maxi(bonus_upgrade_count, 0)
	for card: Card in selected_cards:
		if upgrades_remaining <= 0:
			break
		if card and card.upgrade():
			upgrades_remaining -= 1
	completed.emit(selected_cards)
