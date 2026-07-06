class_name CardPileView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var card_pile: CardPile

@onready var title: Label = %Title
@onready var cards: GridContainer = %Cards
@onready var card_tooltip_popup: CardTooltipPopup = %CardTooltipPopup
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_apply_visuals()
	back_button.pressed.connect(hide)
	
	for card: Node in cards.get_children():
		card.queue_free()
	
	card_tooltip_popup.hide_tooltip()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_tooltip_popup.visible:
			card_tooltip_popup.hide_tooltip()
		else:
			hide()


func show_current_view(new_title: String, randomized: bool = false) -> void:
	for card: Node in cards.get_children():
		card.queue_free()

	card_tooltip_popup.hide_tooltip()
	title.text = new_title
	InkTheme.animate_screen_entrance(self, 0.2)
	_update_view.call_deferred(randomized)


func _update_view(randomized: bool) -> void:
	if not card_pile:
		return
	
	var all_cards := card_pile.cards.duplicate()
	if randomized:
		all_cards.shuffle()
	
	for card: Card in all_cards:
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(card_tooltip_popup.show_tooltip)
		
	show()


func _apply_visuals() -> void:
	var background := $Background as ColorRect
	if background:
		background.color = Color(0.018, 0.010, 0.010, 0.92)
	InkTheme.apply_screen_title(title, 36)
	InkTheme.apply_secondary_button(back_button)
	back_button.custom_minimum_size = Vector2(132, 54)
	cards.add_theme_constant_override("h_separation", 22)
	cards.add_theme_constant_override("v_separation", 22)
