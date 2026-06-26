class_name BattleUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand
@onready var mana_ui: ManaUI = $ManaUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var draw_pile_button: CardPileOpener = %DrawPileButton
@onready var discard_pile_button: CardPileOpener = %DiscardPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView

const REFERENCE_SIZE := Vector2(1920.0, 1080.0)
const DRAW_PILE_ICON := preload("res://assets/ui/generated/icons/icon_card_deck_stack.png")
const DISCARD_PILE_ICON := preload("res://art/ui/icons/discard.png")

var _turn_count := 0
var _turn_label: Label

func _ready() -> void:
	_polish_ui()
	get_viewport().size_changed.connect(_layout_battle_controls)
	Events.player_turn_started.connect(_on_player_turn_started)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("抽牌堆", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("弃牌堆"))
	_layout_battle_controls()


func initialize_card_pile_ui() -> void:
	draw_pile_button.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile_button.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	mana_ui.char_stats = char_stats
	hand.char_stats = char_stats


func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = false


func _on_player_turn_started() -> void:
	_turn_count += 1
	if _turn_label:
		_turn_label.text = "回合 %s" % _turn_count


func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()


func _polish_ui() -> void:
	var top_band := get_node_or_null("TopInkBand")
	if top_band:
		top_band.queue_free()

	_add_turn_badge()

	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(316, 104)
	InkTheme.apply_battle_blue_button(end_turn_button, true)
	_polish_pile_button(draw_pile_button, "抽牌堆", false)
	_polish_pile_button(discard_pile_button, "弃牌堆", true)


func _add_turn_badge() -> void:
	var existing := get_node_or_null("TurnBadge")
	if existing:
		existing.queue_free()

	var badge := PanelContainer.new()
	badge.name = "TurnBadge"
	badge.custom_minimum_size = Vector2(300, 104)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 0.5
	badge.anchor_right = 0.5
	badge.offset_left = -150.0
	badge.offset_top = -10.0
	badge.offset_right = 150.0
	badge.offset_bottom = 94.0
	badge.add_theme_stylebox_override("panel", InkTheme.make_texture_style(InkTheme.HUD_BLUE_TURN_BADGE, 56, 36, Color(1, 1, 1, 0.98)))
	add_child(badge)

	_turn_label = Label.new()
	_turn_label.name = "TurnLabel"
	_turn_label.text = "回合"
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_turn_label.add_theme_font_size_override("font_size", 35)
	_turn_label.add_theme_color_override("font_color", Color("fff0c2"))
	_turn_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.08, 0.95))
	_turn_label.add_theme_constant_override("shadow_offset_x", 3)
	_turn_label.add_theme_constant_override("shadow_offset_y", 3)
	badge.add_child(_turn_label)


func _polish_pile_button(button: CardPileOpener, title: String, align_right := false) -> void:
	var icon_texture := DISCARD_PILE_ICON if align_right else DRAW_PILE_ICON
	button.modulate = Color.WHITE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(190, 92)
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null

	var panel := button.get_node_or_null("BattlePilePanel") as TextureRect
	if not panel:
		panel = TextureRect.new()
		panel.name = "BattlePilePanel"
		button.add_child(panel)
	panel.show_behind_parent = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.texture = InkTheme.HUD_BATTLE_DISCARD_PILE_PANEL if align_right else InkTheme.HUD_BLUE_PILE_PANEL
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.modulate = Color(1, 1, 1, 0.98)

	var icon := button.get_node_or_null("BattlePileIcon") as TextureRect
	if not icon:
		icon = TextureRect.new()
		icon.name = "BattlePileIcon"
		button.add_child(icon)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(15, 21)
	icon.size = Vector2(54, 54)
	icon.modulate = Color(1, 0.92, 0.72, 0.98)

	var title_label := button.get_node_or_null("BattlePileTitle") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "BattlePileTitle"
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.add_theme_color_override("font_color", Color("ffe0a0"))
		title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(title_label)
	title_label.text = title
	title_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_label.position = Vector2(72, 18)
	title_label.size = Vector2(104, 30)

	if button.counter:
		button.counter.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.counter.position = Vector2(72, 51)
		button.counter.size = Vector2(104, 32)
		button.counter.add_theme_font_size_override("font_size", 26)
		button.counter.add_theme_color_override("font_color", Color("fff0c8"))
		button.counter.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		button.counter.add_theme_constant_override("shadow_offset_x", 2)
		button.counter.add_theme_constant_override("shadow_offset_y", 2)
		button.counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _layout_battle_controls() -> void:
	if not is_inside_tree():
		return

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = REFERENCE_SIZE
	var scale_factor: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	scale_factor = clampf(scale_factor, 0.78, 1.12)

	_place_bottom_left(mana_ui, Vector2(42, 286), Vector2(216, 216), scale_factor)
	_place_bottom_left($FlameWheelUI as Control, Vector2(20, 488), Vector2(300, 236), scale_factor)
	_place_bottom_left(draw_pile_button, Vector2(42, 124), Vector2(190, 92), scale_factor)
	_place_bottom_right(discard_pile_button, Vector2(42, 124), Vector2(190, 92), scale_factor)
	_place_bottom_right(end_turn_button, Vector2(36, 236), Vector2(316, 104), scale_factor)

	hand.offset_top = -324.0 * scale_factor

	var turn_badge := get_node_or_null("TurnBadge") as Control
	if turn_badge:
		turn_badge.anchor_left = 0.5
		turn_badge.anchor_right = 0.5
		turn_badge.anchor_top = 0.0
		turn_badge.anchor_bottom = 0.0
		turn_badge.offset_left = -150.0 * scale_factor
		turn_badge.offset_top = -10.0 * scale_factor
		turn_badge.offset_right = 150.0 * scale_factor
		turn_badge.offset_bottom = 94.0 * scale_factor
		if _turn_label:
			_turn_label.add_theme_font_size_override("font_size", roundi(35.0 * scale_factor))

	end_turn_button.add_theme_font_size_override("font_size", roundi(36.0 * scale_factor))


func _place_bottom_left(control: Control, position_from_bottom: Vector2, rect_size: Vector2, scale_factor: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 1.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = position_from_bottom.x * scale_factor
	control.offset_top = -(position_from_bottom.y + rect_size.y) * scale_factor
	control.offset_right = control.offset_left + rect_size.x * scale_factor
	control.offset_bottom = -position_from_bottom.y * scale_factor


func _place_bottom_right(control: Control, position_from_bottom: Vector2, rect_size: Vector2, scale_factor: float) -> void:
	control.anchor_left = 1.0
	control.anchor_top = 1.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_right = -position_from_bottom.x * scale_factor
	control.offset_left = control.offset_right - rect_size.x * scale_factor
	control.offset_bottom = -position_from_bottom.y * scale_factor
	control.offset_top = control.offset_bottom - rect_size.y * scale_factor


func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_layout_battle_controls):
		get_viewport().size_changed.disconnect(_layout_battle_controls)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
