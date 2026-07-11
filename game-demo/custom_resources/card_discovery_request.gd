class_name CardDiscoveryRequest
extends RefCounted

signal completed(selected_cards: Array[Card])

var source_card: Card
var title := "发现"
var prompt := ""
var choices: Array[Card] = []
var picks := 1
var allow_skip := false
var resolved := false


func resolve(selected_cards: Array[Card]) -> void:
	if resolved:
		return
	resolved = true
	completed.emit(selected_cards)
