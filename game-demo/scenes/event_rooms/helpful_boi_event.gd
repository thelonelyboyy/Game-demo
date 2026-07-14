class_name HelpfulBoiEvent
extends EventRoom

@onready var duplicate_last_card_button: EventRoomButton = %DuplicateLastCardButton
@onready var plus_max_hp_button: EventRoomButton = %PlusMaxHPButton


func _ready() -> void:
	duplicate_last_card_button.event_button_callback = duplicate_last_card
	plus_max_hp_button.event_button_callback = plus_max_hp


func duplicate_last_card() -> void:
	var card := character_stats.deck.cards[-1] as Card
	var copied_card := card.duplicate(true) as Card
	character_stats.deck.add_card(copied_card)
	var cards: Array[Card] = [copied_card]
	Events.card_change_feedback_requested.emit("复制卡牌", cards, "以下副本已加入牌组。")


func plus_max_hp() -> void:
	character_stats.max_health += 5
