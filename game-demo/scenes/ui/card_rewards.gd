class_name CardRewards
extends ColorRect

signal card_reward_selected(card: Card)

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")

@export var rewards: Array[Card] : set = set_rewards

@onready var cards: HBoxContainer = %Cards
@onready var skip_card_reward: Button = %SkipCardReward
@onready var card_tooltip_popup: CardTooltipPopup = $CardTooltipPopup
@onready var take_button: Button = %TakeButton

var selected_card: Card
var skip_gold_reward := 0 : set = set_skip_gold_reward


func _ready() -> void:
	_apply_visuals()
	_clear_rewards()
	
	take_button.pressed.connect(_on_take_button_pressed)
	
	skip_card_reward.pressed.connect(
		func(): 
			card_reward_selected.emit(null)
			queue_free()
	)
	_update_skip_button_text()


func set_skip_gold_reward(value: int) -> void:
	skip_gold_reward = maxi(value, 0)
	if is_node_ready():
		_update_skip_button_text()


func _update_skip_button_text() -> void:
	if not skip_card_reward:
		return
	skip_card_reward.text = "跳过 · +%s 灵石" % skip_gold_reward if skip_gold_reward > 0 else "跳过"


func _on_take_button_pressed() -> void:
	# 领取动画：选中的卡从当前位置飞向顶栏总牌库（run.gd 统一处理该信号）。
	if selected_card:
		Events.card_acquired_animation_requested.emit(selected_card, _selected_card_global_center())
	card_reward_selected.emit(selected_card)
	queue_free()


func _selected_card_global_center() -> Vector2:
	for child in cards.get_children():
		var menu := child as CardMenuUI
		if menu and menu.card == selected_card:
			return menu.get_global_rect().get_center()
	return get_global_rect().get_center()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		card_tooltip_popup.hide_tooltip()


func _clear_rewards() -> void:
	for card: Node in cards.get_children():
		card.queue_free()
		
	card_tooltip_popup.hide_tooltip()

	selected_card = null
	take_button.disabled = true


func _show_tooltip(card: Card) -> void:
	selected_card = card
	take_button.disabled = selected_card == null
	card_tooltip_popup.show_tooltip(card)


func set_rewards(new_cards: Array[Card]) -> void:
	rewards = new_cards
	
	if not is_node_ready():
		await ready
		
	_clear_rewards()
	for card: Card in rewards:
		var new_card := CARD_MENU_UI.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_show_tooltip)


func _apply_visuals() -> void:
	color = Color(0.018, 0.010, 0.010, 0.90)
	cards.add_theme_constant_override("separation", 28)
	skip_card_reward.custom_minimum_size = Vector2(180, 54)
	take_button.custom_minimum_size = Vector2(170, 52)
	InkTheme.apply_secondary_button(skip_card_reward)
	InkTheme.apply_screen_button(take_button)
	card_tooltip_popup.background_color = Color(0.018, 0.010, 0.010, 0.92)
	card_tooltip_popup.background.color = card_tooltip_popup.background_color
