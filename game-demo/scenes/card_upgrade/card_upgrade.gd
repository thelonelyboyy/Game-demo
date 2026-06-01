class_name CardUpgrade
extends Control

signal closed
signal card_upgraded(card: Card)

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var card_pile: CardPile : set = set_card_pile

@onready var cards_grid: GridContainer = %CardsGrid
@onready var selected_card_container: CenterContainer = %SelectedCard
@onready var info_label: RichTextLabel = %InfoLabel
@onready var upgrade_button: Button = %UpgradeButton
@onready var back_button: Button = %BackButton

var selected_card: Card


func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
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
		info_label.text = "[center]请选择一张要突破的卡牌。[/center]"
		upgrade_button.disabled = true
		return

	var preview_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	selected_card_container.add_child(preview_card)
	preview_card.card = selected_card

	upgrade_button.disabled = not selected_card.can_upgrade()
	info_label.text = _get_selected_card_text(selected_card)


func _get_selected_card_text(card: Card) -> String:
	var lines: PackedStringArray = []
	lines.append("[center][b]%s[/b][/center]" % card.get_display_name())
	lines.append("[center]%s[/center]" % card.get_upgrade_description())

	if card.can_upgrade():
		lines.append("")
		lines.append("[center][color=#d7b56d]突破预览[/color][/center]")
		lines.append(_get_upgrade_preview(card))

	return "\n".join(lines)


func _get_upgrade_preview(card: Card) -> String:
	var preview := card.duplicate() as Card
	if not preview or not preview.upgrade():
		return ""

	var preview_text := preview.get_default_tooltip()
	preview_text = preview_text.replace(
		"[center][b]%s[/b]\n" % preview.get_display_name(),
		"[center]"
	)

	return preview_text


func _on_upgrade_button_pressed() -> void:
	if not selected_card or not selected_card.upgrade():
		return

	card_upgraded.emit(selected_card)
	_refresh_cards()
	_update_selection(selected_card)


func _on_back_button_pressed() -> void:
	closed.emit()
	queue_free()
