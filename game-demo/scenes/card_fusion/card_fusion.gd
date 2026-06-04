class_name CardFusion
extends Control

signal closed
signal fusion_completed(result: Card)

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var card_pile: CardPile : set = set_card_pile
@export var fusion_library: CardFusionLibrary : set = set_fusion_library

@onready var cards_grid: GridContainer = %CardsGrid
@onready var first_slot: CenterContainer = %FirstSlot
@onready var second_slot: CenterContainer = %SecondSlot
@onready var result_slot: CenterContainer = %ResultSlot
@onready var info_label: RichTextLabel = %InfoLabel
@onready var fuse_button: Button = %FuseButton
@onready var back_button: Button = %BackButton

var selected_cards: Array[Card] = []
var preview_card: Card


func _ready() -> void:
	fuse_button.pressed.connect(_on_fuse_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_cards()
	_update_preview()


func set_card_pile(value: CardPile) -> void:
	card_pile = value
	if is_node_ready():
		_refresh_cards()
		_clear_selection()


func set_fusion_library(value: CardFusionLibrary) -> void:
	fusion_library = value
	if is_node_ready():
		_update_preview()


func _refresh_cards() -> void:
	if not is_node_ready():
		return

	for child: Node in cards_grid.get_children():
		child.queue_free()

	if not card_pile:
		return

	for card: Card in card_pile.cards:
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		cards_grid.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_on_card_clicked)


func _on_card_clicked(card: Card) -> void:
	if not card:
		return

	if selected_cards.has(card):
		selected_cards.erase(card)
	elif selected_cards.size() < 2:
		selected_cards.append(card)
	else:
		selected_cards[1] = card

	_update_preview()


func _clear_selection() -> void:
	selected_cards.clear()
	_update_preview()


func _update_preview() -> void:
	preview_card = null
	_clear_container(first_slot)
	_clear_container(second_slot)
	_clear_container(result_slot)

	if selected_cards.size() > 0:
		_show_card(first_slot, selected_cards[0])
	if selected_cards.size() > 1:
		_show_card(second_slot, selected_cards[1])

	var card_a: Card = selected_cards[0] if selected_cards.size() > 0 else null
	var card_b: Card = selected_cards[1] if selected_cards.size() > 1 else null

	if fusion_library:
		preview_card = fusion_library.get_fusion_preview(card_a, card_b)
		info_label.text = "[center]%s[/center]" % fusion_library.get_fusion_message(card_a, card_b)
	else:
		info_label.text = "[center]融合丹方尚未载入。[/center]"

	if preview_card:
		_show_card(result_slot, preview_card)
		info_label.text += "\n\n[center][color=#d7b56d]预览：%s[/color][/center]\n%s" % [
			preview_card.get_display_name(),
			preview_card.get_default_tooltip()
		]

	fuse_button.disabled = preview_card == null


func _show_card(container: CenterContainer, card: Card) -> void:
	var card_ui := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	container.add_child(card_ui)
	card_ui.card = card


func _clear_container(container: Node) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _on_fuse_button_pressed() -> void:
	if not card_pile or not fusion_library or selected_cards.size() < 2:
		return

	var result := fusion_library.fuse(card_pile, selected_cards[0], selected_cards[1])
	if not result:
		_update_preview()
		return

	fusion_completed.emit(result)
	queue_free()


func _on_back_button_pressed() -> void:
	closed.emit()
	queue_free()
