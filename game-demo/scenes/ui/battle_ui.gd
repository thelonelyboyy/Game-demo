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


func _ready() -> void:
	_polish_ui()
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("抽牌堆", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("弃牌堆"))


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


func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()


func _polish_ui() -> void:
	var top_band := ColorRect.new()
	top_band.name = "TopInkBand"
	top_band.color = Color(0.05, 0.055, 0.05, 0.72)
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_band.anchor_right = 1.0
	top_band.offset_bottom = 76.0
	add_child(top_band)
	move_child(top_band, 0)

	InkTheme.apply_button(end_turn_button, true)
	InkTheme.apply_panel(mana_ui)
	draw_pile_button.modulate = Color(0.95, 0.86, 0.62, 0.96)
	discard_pile_button.modulate = Color(0.95, 0.86, 0.62, 0.96)
