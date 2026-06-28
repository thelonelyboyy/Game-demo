class_name SpiritRootBadge
extends PanelContainer

@export var character: CharacterStats : set = set_character

var icon_label: Label
var name_label: Label
var connected_character: CharacterStats
var connected_deck: CardPile


func _ready() -> void:
	custom_minimum_size = Vector2(140, 66)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := InkTheme.make_texture_style(InkTheme.HUD_BLUE_PILE_PANEL, 32, 18, Color(1, 1, 1, 0.96))
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 7)
	add_child(content)

	icon_label = Label.new()
	icon_label.custom_minimum_size = Vector2(34, 40)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 24)
	content.add_child(icon_label)

	name_label = Label.new()
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("f3dfb6"))
	name_label.add_theme_color_override("font_shadow_color", Color(0.08, 0, 0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	content.add_child(name_label)

	mouse_entered.connect(_refresh)
	_refresh()


func set_character(new_character: CharacterStats) -> void:
	_disconnect_character_signals()
	character = new_character
	_connect_character_signals()
	if is_node_ready():
		_refresh()


func _connect_character_signals() -> void:
	connected_character = character
	if connected_character and not connected_character.stats_changed.is_connected(_refresh):
		connected_character.stats_changed.connect(_refresh)

	connected_deck = connected_character.deck if connected_character else null
	if connected_deck and not connected_deck.card_pile_size_changed.is_connected(_on_deck_changed):
		connected_deck.card_pile_size_changed.connect(_on_deck_changed)


func _disconnect_character_signals() -> void:
	if connected_character and connected_character.stats_changed.is_connected(_refresh):
		connected_character.stats_changed.disconnect(_refresh)
	if connected_deck and connected_deck.card_pile_size_changed.is_connected(_on_deck_changed):
		connected_deck.card_pile_size_changed.disconnect(_on_deck_changed)
	connected_character = null
	connected_deck = null


func _on_deck_changed(_cards_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if not icon_label or not name_label:
		return

	if not character or not character.has_spirit_root():
		icon_label.text = "灵"
		icon_label.add_theme_color_override("font_color", Color("b8ad8e"))
		name_label.text = "未定"
		tooltip_text = SpiritRootText.status_tooltip(character)
		return

	var element := character.spirit_root
	icon_label.text = SpiritRootText.element_name(element)
	icon_label.add_theme_color_override("font_color", SpiritRootText.element_color(element))
	name_label.text = "%s\n%s张" % [
		character.get_spirit_root_stage_name(),
		character.count_spirit_root_cards(),
	]
	tooltip_text = SpiritRootText.status_tooltip(character)


func _exit_tree() -> void:
	_disconnect_character_signals()
