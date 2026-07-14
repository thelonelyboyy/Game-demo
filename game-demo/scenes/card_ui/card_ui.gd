class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const DRAG_STYLEBOX := preload("res://scenes/card_ui/card_drag_stylebox.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_stylebox.tres")

@export var player_modifiers: ModifierHandler
@export var card: Card : set = _set_card
@export var char_stats: CharacterStats : set = _set_char_stats

@onready var card_visuals: CardVisuals = $CardVisuals
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine
@onready var targets: Array[Node] = []

var original_index := 0
var parent: Control
var tween: Tween
var playable := true : set = _set_playable
var disabled := true : set = _set_disabled
var _shake_tween: Tween
var _runtime_values_visible := false


func _ready() -> void:
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_ended.connect(_on_card_drag_or_aim_ended)
	Events.card_aim_ended.connect(_on_card_drag_or_aim_ended)
	card_state_machine.init(self)


func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)


func animate_to_position(new_position: Vector2, duration: float) -> void:
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)


func play() -> void:
	if not card:
		return
	if char_stats and not char_stats.can_play_card(card):
		shake_unplayable()
		return
	
	Events.card_play_preview_requested.emit(card, get_global_rect().get_center())
	card.play(targets, char_stats, player_modifiers)
	queue_free()


func is_outside_hand_area() -> bool:
	if not parent:
		return true

	var hand_rect := Rect2(parent.global_position, parent.size)
	return not hand_rect.has_point(get_global_mouse_position())


func can_auto_release_without_target() -> bool:
	if not card or not is_outside_hand_area():
		return false

	if not card.is_single_targeted():
		return true

	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 1 and enemies[0] is Enemy:
		return true

	return card.type != Card.Type.ATTACK and enemies.size() == 1


func prepare_auto_release_targets() -> bool:
	if not card:
		return false

	if not card.is_single_targeted():
		targets.clear()
		return true

	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 1 and enemies[0] is Enemy:
		targets.clear()
		targets.append(enemies[0])
		return true

	return false


func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1 or not targets[0] is Enemy:
		return null
	
	return targets[0].modifier_handler


func refresh_runtime_values() -> void:
	_runtime_values_visible = true
	if card_visuals:
		card_visuals.show_runtime_values(player_modifiers, get_active_enemy_modifiers())


func reset_runtime_values() -> void:
	_runtime_values_visible = false
	if card_visuals:
		card_visuals.show_default_values()


# 费用不足点击反馈：摇卡面子节点（不动 CardUI 本体，避免和手牌布局 tween 打架）+ 费用闪红。
func shake_unplayable() -> void:
	if _shake_tween and _shake_tween.is_running():
		return

	GameSfx.play(GameSfx.ERROR, -6.0)
	_shake_tween = create_tween()
	for offset in [10.0, -8.0, 6.0, -3.0, 0.0]:
		_shake_tween.tween_property(card_visuals, "position:x", offset, 0.06)
	card_visuals.flash_cost_insufficient()


func is_hovered() -> bool:
	var rect := Rect2(Vector2.ZERO, self.size)
	return rect.has_point(get_local_mouse_position())


func request_tooltip() -> void:
	var enemy_modifiers := get_active_enemy_modifiers()
	var updated_tooltip := card.get_updated_tooltip(player_modifiers, enemy_modifiers)
	updated_tooltip = "%s\n%s" % [updated_tooltip, card.get_element_tooltip()]
	Events.card_tooltip_requested.emit(card.icon, updated_tooltip)


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	card_visuals.card = card


func _set_playable(value: bool) -> void:
	playable = value
	card_visuals.set_disabled_visual(not playable)
	_refresh_playable_glow()


func _set_disabled(value: bool) -> void:
	disabled = value
	_refresh_playable_glow()


func _refresh_playable_glow() -> void:
	if card_visuals:
		card_visuals.set_playable_glow(playable and not disabled)


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	char_stats.stats_changed.connect(_on_char_stats_changed)
	_on_char_stats_changed()


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)
	refresh_runtime_values()


func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)
	refresh_runtime_values()


func _on_card_drag_or_aiming_started(used_card: CardUI) -> void:
	if used_card == self:
		return
	
	disabled = true


func _on_card_drag_or_aim_ended(_card: CardUI) -> void:
	disabled = false
	playable = char_stats.can_play_card(card)


func _on_char_stats_changed() -> void:
	playable = char_stats.can_play_card(card)
	if _runtime_values_visible:
		refresh_runtime_values()
