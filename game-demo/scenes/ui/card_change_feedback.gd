class_name CardChangeFeedback
extends CanvasLayer

const CARD_VISUALS_SCENE := preload("res://scenes/ui/card_visuals.tscn")

var pending_requests: Array[Dictionary] = []
var dim: ColorRect
var title_label: Label
var detail_label: Label
var cards_row: HBoxContainer
var confirm_button: Button


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	hide()


func request_feedback(title: String, cards: Array[Card], detail := "") -> void:
	var visible_cards: Array[Card] = []
	for card: Card in cards:
		if card:
			visible_cards.append(card)
	if visible_cards.is_empty():
		return
	pending_requests.append({
		"title": title,
		"cards": visible_cards,
		"detail": detail,
	})
	if not visible:
		_show_next_request()


func _build_interface() -> void:
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.008, 0.006, 0.010, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "CardChangePanel"
	panel.custom_minimum_size = Vector2(1120, 650)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -560
	panel.offset_top = -325
	panel.offset_right = 560
	panel.offset_bottom = 325
	InkTheme.apply_screen_panel(panel)
	dim.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InkTheme.apply_screen_title(title_label, 38)
	content.add_child(title_label)

	detail_label = Label.new()
	detail_label.custom_minimum_size = Vector2(0, 34)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	InkTheme.apply_subtitle(detail_label, 20)
	content.add_child(detail_label)

	var card_scroll := ScrollContainer.new()
	card_scroll.custom_minimum_size = Vector2(1040, 380)
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(card_scroll)

	var card_center := CenterContainer.new()
	card_center.custom_minimum_size = Vector2(1040, 360)
	card_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.add_child(card_center)

	cards_row = HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 18)
	card_center.add_child(cards_row)

	confirm_button = Button.new()
	confirm_button.text = "确认"
	confirm_button.custom_minimum_size = Vector2(260, 58)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.focus_mode = Control.FOCUS_ALL
	InkTheme.apply_screen_button(confirm_button, true)
	confirm_button.pressed.connect(_on_confirm_pressed)
	content.add_child(confirm_button)


func _show_next_request() -> void:
	if pending_requests.is_empty():
		hide()
		return

	var request: Dictionary = pending_requests.pop_front()
	title_label.text = request.get("title", "卡牌变更")
	detail_label.text = request.get("detail", "")
	detail_label.visible = not detail_label.text.is_empty()
	for child: Node in cards_row.get_children():
		child.queue_free()

	var cards: Array[Card] = request.get("cards", [])
	for card: Card in cards:
		var visuals := CARD_VISUALS_SCENE.instantiate() as CardVisuals
		visuals.custom_minimum_size = Vector2(238, 342)
		visuals.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cards_row.add_child(visuals)
		visuals.card = card

	show()
	confirm_button.grab_focus.call_deferred()


func _on_confirm_pressed() -> void:
	if pending_requests.is_empty():
		hide()
	else:
		_show_next_request()
