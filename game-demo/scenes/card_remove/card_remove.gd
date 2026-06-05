class_name CardRemove
extends Control

signal closed
signal card_removed(card: Card)

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var card_pile: CardPile : set = set_card_pile

@onready var cards_grid: GridContainer = %CardsGrid
@onready var selected_card_container: CenterContainer = %SelectedCard
@onready var info_label: RichTextLabel = %InfoLabel
@onready var remove_button: Button = %RemoveButton
@onready var back_button: Button = %BackButton

var selected_card: Card


func _ready() -> void:
	remove_button.pressed.connect(_on_remove_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_cards()
	_update_selection(null)


func set_card_pile(value: CardPile) -> void:
	card_pile = value
	if is_node_ready():
		_refresh_cards()
		_update_selection(null)


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
		new_card.tooltip_requested.connect(_update_selection)


func _update_selection(card: Card) -> void:
	selected_card = card

	for child: Node in selected_card_container.get_children():
		child.queue_free()

	if not selected_card:
		info_label.text = "[center]请选择一张要净化移除的卡牌。[/center]"
		remove_button.disabled = true
		return

	var preview_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	selected_card_container.add_child(preview_card)
	preview_card.card = selected_card

	remove_button.disabled = not _can_remove_selected_card()
	info_label.text = _get_selected_card_text(selected_card)


func _can_remove_selected_card() -> bool:
	return card_pile and selected_card and card_pile.cards.size() > 1


func _get_selected_card_text(card: Card) -> String:
	var lines: PackedStringArray = []
	lines.append("[center][b]%s[/b][/center]" % card.get_display_name())
	lines.append("[center]将此牌从本局牌组中永久移除。[/center]")
	if card_pile and card_pile.cards.size() <= 1:
		lines.append("")
		lines.append("[center][color=#c9564f]牌组至少需要保留一张牌。[/color][/center]")
	return "\n".join(lines)


func _on_remove_button_pressed() -> void:
	if not _can_remove_selected_card():
		return

	var removed_card := selected_card
	if not card_pile.remove_card(removed_card):
		return

	card_removed.emit(removed_card)
	_refresh_cards()
	_update_selection(null)


func _on_back_button_pressed() -> void:
	closed.emit()
	queue_free()
