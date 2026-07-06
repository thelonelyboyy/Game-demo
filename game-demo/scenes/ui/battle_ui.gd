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
const DRAW_PILE_WIDGET := preload("res://art/ui/battle_widgets/battle_draw_pile.png")
const DISCARD_PILE_WIDGET := preload("res://art/ui/battle_widgets/battle_discard_pile.png")
const CARD_VISUALS_SCENE := preload("res://scenes/ui/card_visuals.tscn")
const PHASE_B_GUIDES_VISIBLE := false
const PLAYED_CARD_PREVIEW_SIZE := Vector2(224.0, 322.0)
const PLAYED_CARD_PREVIEW_SCALE := 1.45
const PLAYED_CARD_PREVIEW_IN_DURATION := 0.18
const PLAYED_CARD_PREVIEW_HOLD_DURATION := 0.42
const PLAYED_CARD_PREVIEW_OUT_DURATION := 0.22

var _turn_count := 0
var _turn_label: Label
var _layout_guides: Control
var _combatant_layer: Control
var _battlefield_frame: PanelContainer
var _played_card_preview_layer: Control
var _player_card: BattleCombatantCard
var _enemy_cards: Array[BattleCombatantCard] = []
var _tracked_player: Player
var _tracked_enemies: Array[Enemy] = []

func _ready() -> void:
	layer = 4
	_polish_ui()
	get_viewport().size_changed.connect(_layout_battle_controls)
	Events.card_play_preview_requested.connect(_on_card_play_preview_requested)
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


func setup_combatant_cards(player: Player, enemies: Array[Enemy]) -> void:
	_tracked_player = player
	_tracked_enemies = enemies.duplicate()
	_rebuild_combatant_cards()
	_layout_battle_controls()


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


func _on_card_play_preview_requested(card: Card, start_global_center: Vector2) -> void:
	if not card or not is_inside_tree():
		return

	if not _played_card_preview_layer:
		_add_played_card_preview_layer()

	var preview := CARD_VISUALS_SCENE.instantiate() as CardVisuals
	preview.name = "PlayedCardPreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	preview.size = PLAYED_CARD_PREVIEW_SIZE
	preview.custom_minimum_size = PLAYED_CARD_PREVIEW_SIZE
	preview.pivot_offset = PLAYED_CARD_PREVIEW_SIZE * 0.5
	preview.scale = Vector2.ONE * 0.88
	preview.modulate = Color(1, 1, 1, 0.0)
	_played_card_preview_layer.add_child(preview)
	preview.card = card

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = REFERENCE_SIZE

	var start_center: Vector2 = start_global_center - _played_card_preview_layer.get_global_rect().position
	var target_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.48)
	var target_position := target_center - PLAYED_CARD_PREVIEW_SIZE * 0.5
	preview.position = start_center - PLAYED_CARD_PREVIEW_SIZE * 0.5

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "position", target_position, PLAYED_CARD_PREVIEW_IN_DURATION)
	tween.parallel().tween_property(preview, "scale", Vector2.ONE * PLAYED_CARD_PREVIEW_SCALE, PLAYED_CARD_PREVIEW_IN_DURATION)
	tween.parallel().tween_property(preview, "modulate:a", 1.0, PLAYED_CARD_PREVIEW_IN_DURATION * 0.75)
	tween.tween_interval(PLAYED_CARD_PREVIEW_HOLD_DURATION)
	tween.tween_property(preview, "position", target_position + Vector2(0, -34), PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.parallel().tween_property(preview, "scale", Vector2.ONE * (PLAYED_CARD_PREVIEW_SCALE * 0.96), PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.parallel().tween_property(preview, "modulate:a", 0.0, PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.tween_callback(preview.queue_free)


func _polish_ui() -> void:
	var top_band := get_node_or_null("TopInkBand")
	if top_band:
		top_band.queue_free()

	_add_turn_badge()
	_add_phase_b_guides()
	_add_combatant_layer()
	_add_played_card_preview_layer()

	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = Vector2(316, 104)
	InkTheme.apply_battle_blue_button(end_turn_button, true)
	_polish_pile_button(draw_pile_button, "抽牌堆", false)
	_polish_pile_button(discard_pile_button, "弃牌堆", true)


func _add_combatant_layer() -> void:
	if _combatant_layer:
		return

	_combatant_layer = Control.new()
	_combatant_layer.name = "CombatantCards"
	_combatant_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combatant_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combatant_layer.z_index = -45
	add_child(_combatant_layer)

	_battlefield_frame = PanelContainer.new()
	_battlefield_frame.name = "BattlefieldFrame"
	_battlefield_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battlefield_frame.hide()
	_battlefield_frame.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.010, 0.015, 0.032, 0.18),
		Color(0.38, 0.44, 0.58, 0.20),
		1,
		4
	))
	_combatant_layer.add_child(_battlefield_frame)


func _add_played_card_preview_layer() -> void:
	if _played_card_preview_layer:
		return

	_played_card_preview_layer = Control.new()
	_played_card_preview_layer.name = "PlayedCardPreviewLayer"
	_played_card_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_played_card_preview_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_played_card_preview_layer.z_index = 2500
	add_child(_played_card_preview_layer)


func _rebuild_combatant_cards() -> void:
	if not _combatant_layer:
		return

	if _player_card:
		_player_card.queue_free()
		_player_card = null
	for card in _enemy_cards:
		if card:
			card.queue_free()
	_enemy_cards.clear()

	if _tracked_player:
		_player_card = _create_combatant_card("PlayerCard", Vector2(318, 306))
		_player_card.bind_player(_tracked_player)

	for enemy in _tracked_enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_card := _create_combatant_card("EnemyCard", Vector2(332, 338))
		enemy_card.bind_enemy(enemy)
		_enemy_cards.append(enemy_card)


func _create_combatant_card(card_name: String, base_size: Vector2) -> BattleCombatantCard:
	var card := BattleCombatantCard.new()
	card.name = card_name
	card.custom_minimum_size = base_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combatant_layer.add_child(card)
	return card


func _add_phase_b_guides() -> void:
	if not PHASE_B_GUIDES_VISIBLE:
		return

	var existing := get_node_or_null("PhaseBGreyboxGuides")
	if existing:
		existing.queue_free()

	_layout_guides = Control.new()
	_layout_guides.name = "PhaseBGreyboxGuides"
	_layout_guides.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_guides.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout_guides.z_index = -80
	add_child(_layout_guides)

	_create_guide_panel("BattlefieldGuide", "中央战场留白")
	_create_guide_panel("EnemyCardGuide", "怪物信息框")
	_create_guide_panel("PlayerCardGuide", "玩家信息框")
	_create_guide_panel("LeftDockGuide", "机制 / 牌堆")


func _create_guide_panel(panel_name: String, label_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.018, 0.024, 0.040, 0.26),
		Color(0.62, 0.46, 0.20, 0.54),
		2,
		6,
		Color(0.0, 0.0, 0.0, 0.22),
		10
	))
	_layout_guides.add_child(panel)

	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("d8c18a", 0.56))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)
	return panel


func _add_turn_badge() -> void:
	var existing := get_node_or_null("TurnBadge")
	if existing:
		existing.queue_free()

	var badge := PanelContainer.new()
	badge.name = "TurnBadge"
	badge.custom_minimum_size = Vector2(300, 104)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 100
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
	_turn_label.custom_minimum_size = Vector2(220, 56)
	_turn_label.z_index = 101
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
	var widget_texture := DISCARD_PILE_WIDGET if align_right else DRAW_PILE_WIDGET
	button.modulate = Color.WHITE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(104, 156)
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
	panel.texture = widget_texture
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	icon.position = Vector2(10, 113)
	icon.size = Vector2(20, 20)
	icon.modulate = Color(1, 0.88, 0.68, 0.74)

	var plate := button.get_node_or_null("BattlePileTextPlate") as Panel
	if not plate:
		plate = Panel.new()
		plate.name = "BattlePileTextPlate"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(plate)
		button.move_child(plate, 1)
	plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
	plate.position = Vector2(7, 105)
	plate.size = Vector2(90, 45)
	plate.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.015, 0.010, 0.006, 0.80),
		Color(0.58, 0.42, 0.18, 0.56),
		1,
		4,
		Color(0, 0, 0, 0.35),
		7
	))

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
	title_label.position = Vector2(27, 122)
	title_label.size = Vector2(70, 25)
	title_label.add_theme_font_size_override("font_size", 17)

	if button.counter:
		button.counter.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.counter.position = Vector2(31, 98)
		button.counter.size = Vector2(52, 28)
		button.counter.add_theme_font_size_override("font_size", 24)
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

	if _played_card_preview_layer:
		_played_card_preview_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_played_card_preview_layer.offset_left = 0.0
		_played_card_preview_layer.offset_top = 0.0
		_played_card_preview_layer.offset_right = 0.0
		_played_card_preview_layer.offset_bottom = 0.0

	_place_bottom_left($FlameWheelUI as Control, Vector2(34, 208), Vector2(220, 172), scale_factor)
	_place_bottom_left(draw_pile_button, Vector2(48, 40), Vector2(104, 156), scale_factor)
	_place_bottom_left(discard_pile_button, Vector2(162, 40), Vector2(104, 156), scale_factor)
	_place_bottom_right(end_turn_button, Vector2(264, 366), Vector2(316, 104), scale_factor)
	_place_bottom_right(mana_ui, Vector2(56, 362), Vector2(116, 116), scale_factor)

	hand.offset_top = -322.0 * scale_factor
	_layout_phase_b_guides(viewport_size, scale_factor)
	_layout_combatant_cards(viewport_size, scale_factor)

	var turn_badge := get_node_or_null("TurnBadge") as Control
	if turn_badge:
		turn_badge.anchor_left = 0.73
		turn_badge.anchor_right = 0.73
		turn_badge.anchor_top = 0.0
		turn_badge.anchor_bottom = 0.0
		turn_badge.offset_left = -150.0 * scale_factor
		turn_badge.offset_top = 6.0 * scale_factor
		turn_badge.offset_right = 150.0 * scale_factor
		turn_badge.offset_bottom = 110.0 * scale_factor
		if _turn_label:
			_turn_label.add_theme_font_size_override("font_size", roundi(35.0 * scale_factor))

	end_turn_button.add_theme_font_size_override("font_size", roundi(36.0 * scale_factor))


func _process(_delta: float) -> void:
	_hide_legacy_combatant_overlays()


func _layout_combatant_cards(viewport_size: Vector2, scale_factor: float) -> void:
	if not _combatant_layer:
		return

	_combatant_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combatant_layer.offset_left = 0.0
	_combatant_layer.offset_top = 0.0
	_combatant_layer.offset_right = 0.0
	_combatant_layer.offset_bottom = 0.0

	if _battlefield_frame:
		_place_absolute(
			_battlefield_frame,
			Vector2(viewport_size.x * 0.30, viewport_size.y * 0.34),
			Vector2(viewport_size.x * 0.40, viewport_size.y * 0.26)
		)

	var enemy_count := _enemy_cards.size()
	if enemy_count > 0:
		var enemy_size := Vector2(332, 388) * scale_factor
		var gap := 26.0 * scale_factor
		var total_width: float = enemy_size.x * enemy_count + gap * max(enemy_count - 1, 0)
		var start_x: float = viewport_size.x * 0.5 - total_width * 0.5
		for i in range(enemy_count):
			var card := _enemy_cards[i]
			if not card:
				continue
			_place_absolute(
				card,
				Vector2(start_x + (enemy_size.x + gap) * i, 58.0 * scale_factor),
				enemy_size
			)

	if _player_card:
		_place_bottom_right(_player_card, Vector2(70, 56), Vector2(318, 306), scale_factor)


func _hide_legacy_combatant_overlays() -> void:
	if is_instance_valid(_tracked_player):
		_hide_legacy_overlay_nodes(_tracked_player)
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy):
			_hide_legacy_overlay_nodes(enemy)


func _hide_legacy_overlay_nodes(node: Node) -> void:
	for ui_name in ["StatsUI", "IntentUI", "StatusHandler"]:
		var ui_node := node.get_node_or_null(ui_name) as Control
		if ui_node:
			ui_node.hide()

	for visual_name in ["Sprite2D", "Arrow", "InkStand"]:
		var visual := node.get_node_or_null(visual_name) as CanvasItem
		if visual:
			visual.hide()

	for child in node.get_children():
		if child is AnimatedSprite2D:
			(child as AnimatedSprite2D).hide()


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


func _layout_phase_b_guides(viewport_size: Vector2, scale_factor: float) -> void:
	if not _layout_guides:
		return

	_layout_guides.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout_guides.offset_left = 0.0
	_layout_guides.offset_top = 0.0
	_layout_guides.offset_right = 0.0
	_layout_guides.offset_bottom = 0.0

	var battlefield := _layout_guides.get_node_or_null("BattlefieldGuide") as Control
	var enemy_card := _layout_guides.get_node_or_null("EnemyCardGuide") as Control
	var player_card := _layout_guides.get_node_or_null("PlayerCardGuide") as Control
	var left_dock := _layout_guides.get_node_or_null("LeftDockGuide") as Control

	if battlefield:
		_place_absolute(
			battlefield,
			Vector2(viewport_size.x * 0.30, viewport_size.y * 0.34),
			Vector2(viewport_size.x * 0.40, viewport_size.y * 0.26)
		)
	if enemy_card:
		_place_center_top(enemy_card, viewport_size, Vector2(332, 338), 88.0, scale_factor)
	if player_card:
		_place_bottom_right(player_card, Vector2(70, 56), Vector2(318, 306), scale_factor)
	if left_dock:
		_place_bottom_left(left_dock, Vector2(28, 42), Vector2(358, 486), scale_factor)


func _place_center_top(control: Control, viewport_size: Vector2, rect_size: Vector2, top: float, scale_factor: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	var size := rect_size * scale_factor
	control.offset_left = viewport_size.x * 0.5 - size.x * 0.5
	control.offset_top = top * scale_factor
	control.offset_right = control.offset_left + size.x
	control.offset_bottom = control.offset_top + size.y


func _place_absolute(control: Control, position: Vector2, rect_size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = position.x
	control.offset_top = position.y
	control.offset_right = position.x + rect_size.x
	control.offset_bottom = position.y + rect_size.y


func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_layout_battle_controls):
		get_viewport().size_changed.disconnect(_layout_battle_controls)
	if Events.card_play_preview_requested.is_connected(_on_card_play_preview_requested):
		Events.card_play_preview_requested.disconnect(_on_card_play_preview_requested)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
