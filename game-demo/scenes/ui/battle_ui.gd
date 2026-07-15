class_name BattleUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand
@onready var mana_ui: ManaUI = $ManaUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var draw_pile_button: CardPileOpener = %DrawPileButton
@onready var discard_pile_button: CardPileOpener = %DiscardPileButton
@onready var exhaust_pile_button: CardPileOpener = %ExhaustPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var exhaust_pile_view: CardPileView = %ExhaustPileView
@onready var player_handler: PlayerHandler = $"../PlayerHandler"

const REFERENCE_SIZE := Vector2(1920.0, 1080.0)
const DRAW_PILE_ICON := preload("res://assets/ui/generated/icons/icon_card_deck_stack.png")
const DISCARD_PILE_ICON := preload("res://art/ui/icons/discard.png")
const DRAW_PILE_WIDGET := preload("res://art/ui/battle_widgets/battle_draw_pile.png")
const DISCARD_PILE_WIDGET := preload("res://art/ui/battle_widgets/battle_discard_pile.png")
const CARD_VISUALS_SCENE := preload("res://scenes/ui/card_visuals.tscn")
const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const PHASE_B_GUIDES_VISIBLE := false
const PLAYED_CARD_PREVIEW_SIZE := Vector2(269.0, 386.0)
const PLAYED_CARD_PREVIEW_SCALE := 1.45
const PLAYED_CARD_PREVIEW_IN_DURATION := 0.16
const PLAYED_CARD_PREVIEW_HOLD_DURATION := 0.34
const PLAYED_CARD_PREVIEW_OUT_DURATION := 0.18
const PLAYER_COMBATANT_CARD_SIZE := Vector2(327.0, 567.0)
const ENEMY_COMBATANT_CARD_SIZE := Vector2(327.0, 642.0)
const COMBATANT_CARD_GAP := 30.0
const PLAYER_CARD_BOTTOM_OFFSET := Vector2(70.0, 0.0)
const HERO_SKILL_SIZE := Vector2(158.4, 86.4)
const END_TURN_SIZE := Vector2(200.0, 104.0)
# 手牌悬停层级最高为 1000；操作按钮必须始终在手牌之上，同时低于发现牌弹窗。
const COMBAT_ACTION_Z_INDEX := 2200

const PHASE_BANNER_COLOR_PLAYER := Color("f2c94f")
const PHASE_BANNER_COLOR_ENEMY := Color("e0503c")
const BOSS_BANNER_COLOR := Color("b04ae0")
# 与 enemy.gd _get_target_art_max_size 的 Boss 名单保持一致。
const BOSS_IDS := ["bone_dragon", "black_lotus_matriarch", "sky_palace_guardian", "abyssal_sword_soul", "eclipse_tyrant", "blood_moon_demon_king", "bronze_corpse_king", "venom_broodmother", "underworld_judge"]

var _turn_count := 0
var _turn_label: Label
var _phase_banner: PanelContainer
var _phase_banner_label: Label
var _phase_banner_tween: Tween
var _end_turn_breath_tween: Tween
var _breath_check_elapsed := 0.0
var _layout_guides: Control
var _combatant_layer: Control
var _battlefield_frame: PanelContainer
var _played_card_preview_layer: Control
var _player_card: BattleCombatantCard
var _enemy_cards: Array[BattleCombatantCard] = []
var _tracked_player: Player
var _tracked_enemies: Array[Enemy] = []
var _combatant_layout_generation := 0
var _discover_overlay: ColorRect
var _discover_request
var _discover_selected: Array[Card] = []
var _discover_cards_box: GridContainer
var _discover_confirm_button: Button
var _discover_count_label: Label
var hero_skill_button: Button
# 英雄技能每回合限一次：施放后按钮禁用到下回合开始。
var _hero_skill_used_this_turn := false

func _ready() -> void:
	layer = 4
	_polish_ui()
	get_viewport().size_changed.connect(_layout_battle_controls)
	Events.card_play_preview_requested.connect(_on_card_play_preview_requested)
	Events.card_discarded.connect(_on_card_discarded)
	Events.deck_reshuffled.connect(_on_deck_reshuffled)
	Events.sha_qi_tier_changed.connect(_on_sha_qi_tier_changed)
	Events.card_drawn.connect(_on_card_drawn_sfx)
	Events.card_played.connect(_on_card_played_sfx)
	Events.card_discovery_requested.connect(_on_card_discovery_requested)
	Events.player_turn_started.connect(_on_player_turn_started)
	Events.player_turn_ended.connect(_on_player_turn_ended_for_banner)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.hero_skill_used.connect(_on_hero_skill_used)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	if hero_skill_button:
		hero_skill_button.pressed.connect(_on_hero_skill_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("抽牌堆", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("弃牌堆"))
	exhaust_pile_button.pressed.connect(exhaust_pile_view.show_current_view.bind("消耗牌堆"))
	_layout_battle_controls()


func initialize_card_pile_ui() -> void:
	draw_pile_button.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile_button.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard
	exhaust_pile_button.card_pile = char_stats.exhaust_pile
	exhaust_pile_view.card_pile = char_stats.exhaust_pile


var _boss_banner_shown := false
var _last_sha_tier_ui := 0

# 煞气档位气场：档位越高玩家信息卡立绘染得越红。
const SHA_TIER_TINTS := [
	Color.WHITE,
	Color(1.05, 0.82, 0.78),
	Color(1.10, 0.62, 0.55),
	Color(1.18, 0.42, 0.36),
]
const SHA_TIER_BANNERS := [
	"",
	"煞气凝聚 · 卡牌伤害 +1",
	"煞气翻涌 · 造成与受到伤害 ×2",
	"天魔降世 · 伤害 ×3",
]


# 煞气跨档演出：升档弹横幅 + 玩家信息卡立绘染红气场（世界立绘已隐藏，染卡才看得见）。
func _on_sha_qi_tier_changed(tier: int, _stacks: int) -> void:
	var tier_index := clampi(tier, 0, SHA_TIER_TINTS.size() - 1)

	if _player_card:
		_player_card.set_aura_tint(SHA_TIER_TINTS[tier_index])

	if tier_index > _last_sha_tier_ui:
		var accent := Color("d0342c") if tier_index >= 3 else Color("c05a3c")
		var hold := 2.4 if tier_index >= 3 else 1.6
		var font_size := 52 if tier_index >= 3 else 42
		# 煞气升档用锣声做国风重音，天魔降世用更重的一记。
		GameSfx.play(GameSfx.GONG_HEAVY if tier_index >= 3 else GameSfx.GONG, -2.0)
		_show_phase_banner(SHA_TIER_BANNERS[tier_index], accent, hold, font_size)
		if is_instance_valid(_tracked_player):
			HitEffect.spawn(_tracked_player, _tracked_player._feedback_radius() * 1.2, Color(1.0, 0.30, 0.24, 0.95))
		if tier_index >= 3 and is_instance_valid(_tracked_player):
			# 天魔降世：附带战场震动。
			var battle_root := _tracked_player.get_parent() as Node2D
			if battle_root:
				Shaker.shake(battle_root, 5, 0.4)
	_last_sha_tier_ui = tier_index


func setup_combatant_cards(player: Player, enemies: Array[Enemy]) -> void:
	_tracked_player = player
	_tracked_enemies = enemies.duplicate()
	_rebuild_combatant_cards()
	_layout_battle_controls()
	_maybe_show_boss_banner()


# Boss 战开场名牌：等回合横幅（~0.95s）播完后出场，停留更久、深紫强调色。
func _maybe_show_boss_banner() -> void:
	if _boss_banner_shown:
		return

	var boss_name := ""
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy) and enemy.stats and BOSS_IDS.has(enemy.stats.id):
			boss_name = enemy.stats.display_name
			break
	if boss_name.is_empty():
		return

	_boss_banner_shown = true
	var timer := get_tree().create_timer(1.45, false)
	timer.timeout.connect(_show_boss_banner_now.bind(boss_name))


func _show_boss_banner_now(boss_name: String) -> void:
	if not is_inside_tree():
		return
	GameSfx.play(GameSfx.BOSS_BELL, -2.0)
	_show_phase_banner("—— %s ——" % boss_name, BOSS_BANNER_COLOR, 1.6, 50)


func _set_char_stats(value: CharacterStats) -> void:
	if char_stats and char_stats.stats_changed.is_connected(_update_hero_skill_button_state):
		char_stats.stats_changed.disconnect(_update_hero_skill_button_state)
	char_stats = value
	mana_ui.char_stats = char_stats
	hand.char_stats = char_stats
	if char_stats and not char_stats.stats_changed.is_connected(_update_hero_skill_button_state):
		char_stats.stats_changed.connect(_update_hero_skill_button_state)
	_sync_hero_skill_visibility()


func _on_player_hand_drawn() -> void:
	_sync_end_turn_button_state()
	_update_hero_skill_button_state()


func _on_player_turn_started() -> void:
	_turn_count += 1
	_hero_skill_used_this_turn = false
	if _turn_label:
		_turn_label.text = "回合 %s" % _turn_count
	_pulse_turn_badge()
	_show_phase_banner("我方回合", PHASE_BANNER_COLOR_PLAYER)


func _on_hero_skill_used() -> void:
	_hero_skill_used_this_turn = true
	_update_hero_skill_button_state()


func _on_player_turn_ended_for_banner() -> void:
	if hero_skill_button:
		hero_skill_button.disabled = true
	_show_phase_banner("敌方回合", PHASE_BANNER_COLOR_ENEMY)


func _pulse_turn_badge() -> void:
	var badge := get_node_or_null("TurnBadge") as Control
	if not badge:
		return
	badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2.ONE * 1.10
	var tween := badge.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.40)


func _ensure_phase_banner() -> void:
	if _phase_banner:
		return

	_phase_banner = PanelContainer.new()
	_phase_banner.name = "PhaseBanner"
	_phase_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_banner.z_index = 2600
	_phase_banner.custom_minimum_size = Vector2(420, 92)
	_phase_banner.anchor_left = 0.5
	_phase_banner.anchor_right = 0.5
	_phase_banner.anchor_top = 0.30
	_phase_banner.anchor_bottom = 0.30
	_phase_banner.offset_left = -210.0
	_phase_banner.offset_right = 210.0
	_phase_banner.offset_top = -46.0
	_phase_banner.offset_bottom = 46.0
	_phase_banner.hide()
	add_child(_phase_banner)

	_phase_banner_label = Label.new()
	_phase_banner_label.name = "PhaseLabel"
	_phase_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase_banner_label.add_theme_font_size_override("font_size", 44)
	_phase_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0.01, 0.05, 0.94))
	_phase_banner_label.add_theme_constant_override("shadow_offset_x", 3)
	_phase_banner_label.add_theme_constant_override("shadow_offset_y", 3)
	_phase_banner.add_child(_phase_banner_label)


# 敌我回合切换的中央横幅：弹入 → 停留 → 上浮淡出，重复触发时打断重放。
func _show_phase_banner(text: String, accent: Color, hold := 0.80, font_size := 44) -> void:
	_ensure_phase_banner()

	_phase_banner_label.text = text
	_phase_banner_label.add_theme_font_size_override("font_size", font_size)
	_phase_banner_label.add_theme_color_override("font_color", accent.lightened(0.28))
	var style := InkTheme.make_style(
		Color(0.016, 0.024, 0.052, 0.88),
		Color(accent.r, accent.g, accent.b, 0.88),
		2,
		10,
		Color(accent.r, accent.g, accent.b, 0.30),
		20
	)
	style.content_margin_left = 44
	style.content_margin_right = 44
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_phase_banner.add_theme_stylebox_override("panel", style)

	if _phase_banner_tween and _phase_banner_tween.is_running():
		_phase_banner_tween.kill()

	_phase_banner.show()
	_phase_banner.pivot_offset = _phase_banner.size * 0.5
	_phase_banner.modulate = Color(1, 1, 1, 0.0)
	_phase_banner.scale = Vector2.ONE * 0.84

	_phase_banner_tween = create_tween()
	_phase_banner_tween.set_parallel(true)
	_phase_banner_tween.tween_property(_phase_banner, "modulate:a", 1.0, 0.20)
	_phase_banner_tween.tween_property(_phase_banner, "scale", Vector2.ONE, 0.32) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_phase_banner_tween.set_parallel(false)
	_phase_banner_tween.tween_interval(hold)
	_phase_banner_tween.set_parallel(true)
	_phase_banner_tween.tween_property(_phase_banner, "modulate:a", 0.0, 0.36)
	_phase_banner_tween.tween_property(_phase_banner, "scale", Vector2.ONE * 1.05, 0.36) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_phase_banner_tween.set_parallel(false)
	_phase_banner_tween.tween_callback(_phase_banner.hide)


func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	if hero_skill_button:
		hero_skill_button.disabled = true
	GameSfx.play(GameSfx.END_TURN, -6.0)
	Events.player_turn_ended.emit()


func _on_hero_skill_button_pressed() -> void:
	if not hero_skill_button or hero_skill_button.disabled:
		return

	Events.hero_skill_requested.emit(hero_skill_button.get_global_rect().get_center())
	_pulse_hero_skill_button()
	_update_hero_skill_button_state.call_deferred()


func _on_card_drawn_sfx(_card: Card) -> void:
	GameSfx.play(GameSfx.DRAW, -6.0)


func _on_card_played_sfx(_card: Card) -> void:
	GameSfx.play(GameSfx.PLAY_CARD, -2.0)


func _on_card_discovery_requested(request) -> void:
	if not request or request.choices.is_empty():
		if request:
			request.resolve([])
		return

	if _discover_overlay:
		_finish_discovery([])

	_discover_request = request
	_discover_selected.clear()
	_show_discovery_overlay()


func _show_discovery_overlay() -> void:
	if hand:
		hand.disable_hand()
	end_turn_button.disabled = true
	if hero_skill_button:
		hero_skill_button.disabled = true

	_discover_overlay = ColorRect.new()
	_discover_overlay.name = "DiscoveryOverlay"
	_discover_overlay.color = Color(0.012, 0.008, 0.014, 0.86)
	_discover_overlay.z_index = 3200
	_discover_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_discover_overlay)

	var panel := PanelContainer.new()
	panel.name = "DiscoveryPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -560.0
	panel.offset_top = -450.0
	panel.offset_right = 560.0
	panel.offset_bottom = 450.0
	panel.add_theme_stylebox_override("panel", InkTheme.make_style(
		Color(0.030, 0.020, 0.032, 0.96),
		Color(0.72, 0.47, 0.22, 0.92),
		2,
		8,
		Color(0.95, 0.48, 0.12, 0.22),
		20
	))
	_discover_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = _discover_request.title if not _discover_request.title.is_empty() else "发现"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("ffe2a6"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(title)

	_discover_count_label = Label.new()
	_discover_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_discover_count_label.add_theme_font_size_override("font_size", 19)
	_discover_count_label.add_theme_color_override("font_color", Color("d8c29a"))
	layout.add_child(_discover_count_label)

	if not _discover_request.prompt.is_empty():
		var prompt_label := Label.new()
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt_label.text = _discover_request.prompt
		prompt_label.add_theme_font_size_override("font_size", 18)
		prompt_label.add_theme_color_override("font_color", Color("cdbf92"))
		layout.add_child(prompt_label)

	var cards_scroll := ScrollContainer.new()
	cards_scroll.custom_minimum_size = Vector2(0, 570)
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(cards_scroll)

	_discover_cards_box = GridContainer.new()
	_discover_cards_box.columns = 5
	_discover_cards_box.add_theme_constant_override("h_separation", 18)
	_discover_cards_box.add_theme_constant_override("v_separation", 18)
	cards_scroll.add_child(_discover_cards_box)

	for card: Card in _discover_request.choices:
		var menu := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		menu.set_visual_size(Vector2(180, 258))
		menu.card = card
		menu.tooltip_requested.connect(_on_discover_card_clicked.bind(menu))
		_discover_cards_box.add_child(menu)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	layout.add_child(buttons)

	_discover_confirm_button = Button.new()
	_discover_confirm_button.text = "确认"
	_discover_confirm_button.custom_minimum_size = Vector2(156, 48)
	InkTheme.apply_screen_button(_discover_confirm_button)
	_discover_confirm_button.pressed.connect(_finish_discovery.bind(_discover_selected))
	buttons.add_child(_discover_confirm_button)

	if _discover_request.allow_skip:
		var skip_button := Button.new()
		skip_button.text = "跳过"
		skip_button.custom_minimum_size = Vector2(146, 48)
		InkTheme.apply_secondary_button(skip_button)
		skip_button.pressed.connect(_finish_discovery.bind([]))
		buttons.add_child(skip_button)

	_refresh_discovery_selection()


func _on_discover_card_clicked(card: Card, menu: CardMenuUI) -> void:
	if not _discover_request or not card:
		return
	if _discover_selected.has(card):
		_discover_selected.erase(card)
	elif _discover_selected.size() < _discover_request.picks:
		_discover_selected.append(card)
	GameSfx.play(GameSfx.UI_CLICK, -8.0)
	_refresh_discovery_selection()


func _refresh_discovery_selection() -> void:
	if not _discover_request:
		return
	if _discover_count_label:
		_discover_count_label.text = "选择 %s / %s 张加入手牌" % [_discover_selected.size(), _discover_request.picks]
	if _discover_confirm_button:
		_discover_confirm_button.disabled = _discover_selected.size() != _discover_request.picks
	if _discover_cards_box:
		for child in _discover_cards_box.get_children():
			var menu := child as CardMenuUI
			if not menu:
				continue
			var selected := _discover_selected.has(menu.card)
			menu.modulate = Color(1.18, 1.08, 0.82, 1.0) if selected else Color.WHITE
			menu.z_index = 20 if selected else 0


func _finish_discovery(selected_cards: Array[Card]) -> void:
	var request = _discover_request
	var selected_copy := selected_cards.duplicate()
	_discover_request = null
	if _discover_overlay:
		_discover_overlay.queue_free()
		_discover_overlay = null
	_discover_cards_box = null
	_discover_confirm_button = null
	_discover_count_label = null
	_discover_selected.clear()

	if request and not request.resolved:
		request.resolve(selected_copy)

	if hand:
		hand.enable_hand()
	_sync_end_turn_button_state()
	_update_hero_skill_button_state()


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

	if card.type == Card.Type.POWER:
		# 功法牌：悬停后化作金光飞向角色融入，与普通牌"上浮淡出"区分。
		var absorb_target := _power_card_absorb_position()
		tween.tween_property(preview, "position", absorb_target - PLAYED_CARD_PREVIEW_SIZE * 0.5, 0.46) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(preview, "scale", Vector2.ONE * 0.10, 0.46) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(preview, "modulate", Color(1.8, 1.5, 0.7, 0.55), 0.46)
		tween.tween_callback(_burst_power_absorb)
		tween.tween_callback(preview.queue_free)
		return

	tween.tween_property(preview, "position", target_position + Vector2(0, -34), PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.parallel().tween_property(preview, "scale", Vector2.ONE * (PLAYED_CARD_PREVIEW_SCALE * 0.96), PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.parallel().tween_property(preview, "modulate:a", 0.0, PLAYED_CARD_PREVIEW_OUT_DURATION)
	tween.tween_callback(preview.queue_free)


# 功法牌吸收落点：优先玩家立绘的画布位置，取不到则退回右下玩家信息卡。
func _power_card_absorb_position() -> Vector2:
	if is_instance_valid(_tracked_player):
		return _tracked_player.get_global_transform_with_canvas().origin - _played_card_preview_layer.get_global_rect().position
	if _player_card:
		return _player_card.get_global_rect().get_center() - _played_card_preview_layer.get_global_rect().position
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.6)


func _burst_power_absorb() -> void:
	GameSfx.play(GameSfx.POWER_UP, -2.0)
	if is_instance_valid(_tracked_player):
		HitEffect.spawn(_tracked_player, _tracked_player._feedback_radius(), Color(1.0, 0.85, 0.42, 0.95))


# 弃牌动画：真卡立即释放，用轻量 CardVisuals 幽灵卡飞向弃牌堆，避免动 CardUI 状态机。
func _on_card_discarded(card: Card, from_global_center: Vector2) -> void:
	if not card or not is_inside_tree() or not discard_pile_button:
		return

	GameSfx.play(GameSfx.DISCARD, -10.0)

	if not _played_card_preview_layer:
		_add_played_card_preview_layer()

	var ghost := CARD_VISUALS_SCENE.instantiate() as CardVisuals
	ghost.name = "DiscardGhost"
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ghost.size = PLAYED_CARD_PREVIEW_SIZE
	ghost.custom_minimum_size = PLAYED_CARD_PREVIEW_SIZE
	ghost.pivot_offset = PLAYED_CARD_PREVIEW_SIZE * 0.5
	_played_card_preview_layer.add_child(ghost)
	ghost.card = card

	var layer_origin := _played_card_preview_layer.get_global_rect().position
	ghost.position = from_global_center - layer_origin - PLAYED_CARD_PREVIEW_SIZE * 0.5
	var target_center := discard_pile_button.get_global_rect().get_center() - layer_origin
	var target_position := target_center - PLAYED_CARD_PREVIEW_SIZE * 0.5

	var tween := ghost.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "position", target_position, 0.44)
	tween.tween_property(ghost, "scale", Vector2.ONE * 0.16, 0.44)
	tween.tween_property(ghost, "rotation_degrees", 24.0, 0.44)
	tween.tween_property(ghost, "modulate:a", 0.35, 0.44)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)


# 洗牌提示：几张空白幽灵卡背从弃牌堆错落飞向抽牌堆 + 抽牌堆计数 punch，
# 让"弃牌堆洗回抽牌堆"这个暗改动作可见。
func _on_deck_reshuffled(card_count: int) -> void:
	if not is_inside_tree() or not draw_pile_button or not discard_pile_button:
		return

	GameSfx.play(GameSfx.SHUFFLE, -4.0)

	if not _played_card_preview_layer:
		_add_played_card_preview_layer()

	var layer_origin := _played_card_preview_layer.get_global_rect().position
	var from := discard_pile_button.get_global_rect().get_center() - layer_origin
	var to := draw_pile_button.get_global_rect().get_center() - layer_origin
	var ghost_count := mini(card_count, 4)
	var ghost_size := Vector2(78.0, 112.0)

	for i in range(ghost_count):
		var ghost := CARD_VISUALS_SCENE.instantiate() as CardVisuals
		ghost.name = "ReshuffleGhost%d" % i
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ghost.size = PLAYED_CARD_PREVIEW_SIZE
		ghost.pivot_offset = PLAYED_CARD_PREVIEW_SIZE * 0.5
		ghost.scale = Vector2.ONE * (ghost_size.x / PLAYED_CARD_PREVIEW_SIZE.x)
		ghost.position = from - PLAYED_CARD_PREVIEW_SIZE * 0.5
		ghost.modulate = Color(1, 1, 1, 0.0)
		_played_card_preview_layer.add_child(ghost)

		var tween := ghost.create_tween()
		tween.tween_interval(0.09 * i)
		tween.tween_property(ghost, "modulate:a", 0.9, 0.11)
		tween.set_parallel(true)
		tween.tween_property(ghost, "position", to - PLAYED_CARD_PREVIEW_SIZE * 0.5, 0.46) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(ghost, "rotation_degrees", -18.0, 0.46)
		tween.set_parallel(false)
		tween.tween_property(ghost, "modulate:a", 0.0, 0.14)
		tween.tween_callback(ghost.queue_free)

	_punch_pile_counter(draw_pile_button)


func _punch_pile_counter(button: CardPileOpener) -> void:
	if not button or not button.counter:
		return
	var counter := button.counter
	counter.pivot_offset = counter.size * 0.5
	counter.scale = Vector2.ONE * 1.5
	var tween := counter.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(counter, "scale", Vector2.ONE, 0.42)


func _polish_ui() -> void:
	var top_band := get_node_or_null("TopInkBand")
	if top_band:
		top_band.queue_free()

	_add_turn_badge()
	_add_phase_b_guides()
	_add_combatant_layer()
	_add_played_card_preview_layer()

	end_turn_button.text = "结束回合"
	end_turn_button.custom_minimum_size = END_TURN_SIZE
	end_turn_button.z_index = COMBAT_ACTION_Z_INDEX
	end_turn_button.mouse_filter = Control.MOUSE_FILTER_STOP
	end_turn_button.focus_mode = Control.FOCUS_NONE
	InkTheme.apply_battle_blue_button(end_turn_button, true)
	_add_hero_skill_button()
	_polish_pile_button(draw_pile_button, "抽牌堆", false)
	_polish_pile_button(discard_pile_button, "弃牌堆", true)
	_polish_pile_button(exhaust_pile_button, "消耗", true)
	_tint_exhaust_pile_button()


func _add_hero_skill_button() -> void:
	if hero_skill_button:
		return

	hero_skill_button = Button.new()
	hero_skill_button.name = "HeroSkillButton"
	hero_skill_button.text = "焚心"
	hero_skill_button.custom_minimum_size = HERO_SKILL_SIZE
	hero_skill_button.z_index = COMBAT_ACTION_Z_INDEX
	hero_skill_button.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_skill_button.focus_mode = Control.FOCUS_NONE
	hero_skill_button.disabled = true
	hero_skill_button.hide()
	# 边框与「结束回合」同款；代价说明只在悬停 tooltip 里。
	InkTheme.apply_battle_blue_button(hero_skill_button, false)
	hero_skill_button.add_theme_font_size_override("font_size", 23)
	InkTheme.wire_button_sfx(hero_skill_button)
	add_child(hero_skill_button)


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
		_player_card = _create_combatant_card("PlayerCard", PLAYER_COMBATANT_CARD_SIZE)
		_player_card.bind_player(_tracked_player)

	for enemy in _tracked_enemies:
		if not is_instance_valid(enemy):
			continue
		var enemy_card := _create_combatant_card("EnemyCard", ENEMY_COMBATANT_CARD_SIZE)
		enemy_card.bind_enemy(enemy)
		_enemy_cards.append(enemy_card)


func _create_combatant_card(card_name: String, base_size: Vector2) -> BattleCombatantCard:
	var card := BattleCombatantCard.new()
	card.name = card_name
	card.custom_minimum_size = base_size
	card.mouse_filter = Control.MOUSE_FILTER_PASS
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


func _tint_exhaust_pile_button() -> void:
	if not exhaust_pile_button:
		return
	var panel := exhaust_pile_button.get_node_or_null("BattlePilePanel") as TextureRect
	if panel:
		panel.modulate = Color(0.78, 0.64, 1.0, 0.96)
	var icon := exhaust_pile_button.get_node_or_null("BattlePileIcon") as TextureRect
	if icon:
		icon.modulate = Color(0.82, 0.58, 1.0, 0.92)
	var title_label := exhaust_pile_button.get_node_or_null("BattlePileTitle") as Label
	if title_label:
		title_label.add_theme_color_override("font_color", Color("e0c2ff"))


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
	_place_bottom_left(exhaust_pile_button, Vector2(276, 40), Vector2(104, 156), scale_factor)
	# 结束回合位于人物牌左侧的空隙，避开底部手牌；英雄技能保留在人物牌下方。
	_place_bottom_right(end_turn_button, Vector2(414, 402), END_TURN_SIZE, scale_factor)
	if hero_skill_button:
		var hero_skill_offset := Vector2(
			PLAYER_CARD_BOTTOM_OFFSET.x + PLAYER_COMBATANT_CARD_SIZE.x - HERO_SKILL_SIZE.x,
			PLAYER_CARD_BOTTOM_OFFSET.y + PLAYER_COMBATANT_CARD_SIZE.y + 8.0
		)
		_place_bottom_right(hero_skill_button, hero_skill_offset, HERO_SKILL_SIZE, scale_factor)
	# 灵力球放在焰轮右缘和手牌左缘之间，既靠近手牌，也不遮挡卡面。
	_place_bottom_left(mana_ui, Vector2(328, 380), Vector2(116, 116), scale_factor)

	hand.offset_top = -386.0 * scale_factor
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

	end_turn_button.add_theme_font_size_override("font_size", roundi(30.0 * scale_factor))
	if hero_skill_button:
		hero_skill_button.add_theme_font_size_override("font_size", roundi(24.0 * scale_factor))
		_update_hero_skill_button_state()
	_update_hand_draw_origin.call_deferred()


func _update_hand_draw_origin() -> void:
	if hand and draw_pile_button:
		hand.draw_origin_global = draw_pile_button.get_global_rect().get_center()


func _process(delta: float) -> void:
	_hide_legacy_combatant_overlays()
	_breath_check_elapsed += delta
	if _breath_check_elapsed >= 0.2:
		_breath_check_elapsed = 0.0
		_sync_end_turn_button_state()
		_update_hero_skill_button_state()
		_update_end_turn_breath()


func _sync_end_turn_button_state() -> void:
	if not end_turn_button or not is_instance_valid(player_handler):
		return
	var battle := get_parent() as Battle
	var can_end_turn := (
		battle
		and battle.battle_active
		and player_handler.battle_running
		and player_handler.player_actions_enabled
		and _discover_request == null
		and not get_tree().paused
	)
	end_turn_button.disabled = not can_end_turn


# 无牌可打（费用不够或手牌空）时结束回合按钮呼吸发亮，提示玩家该收手了。
func _update_end_turn_breath() -> void:
	var should_breathe := not end_turn_button.disabled and not _hand_has_playable_card() and not _hero_skill_available()
	var breathing := _end_turn_breath_tween and _end_turn_breath_tween.is_running()

	if should_breathe and not breathing:
		_end_turn_breath_tween = create_tween().set_loops()
		_end_turn_breath_tween.tween_property(end_turn_button, "modulate", Color(1.24, 1.16, 1.0), 0.75) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_end_turn_breath_tween.tween_property(end_turn_button, "modulate", Color.WHITE, 0.75) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif not should_breathe and breathing:
		_end_turn_breath_tween.kill()
		end_turn_button.modulate = Color.WHITE


func _hand_has_playable_card() -> bool:
	if not hand:
		return false
	for child in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.playable:
			return true
	return false


func _hero_skill_available() -> bool:
	return (
		hero_skill_button
		and hero_skill_button.visible
		and not hero_skill_button.disabled
	)


func _sync_hero_skill_visibility() -> void:
	if not hero_skill_button:
		return

	var should_show := _is_demonic_character()
	hero_skill_button.visible = should_show
	if not should_show:
		hero_skill_button.disabled = true
	else:
		_update_hero_skill_button_state()


func _update_hero_skill_button_state() -> void:
	if not hero_skill_button:
		return
	_update_hero_skill_tooltip()

	if not _is_demonic_character():
		hero_skill_button.hide()
		hero_skill_button.disabled = true
		return

	hero_skill_button.show()
	hero_skill_button.disabled = (
		end_turn_button.disabled
		or _hero_skill_used_this_turn
		or not char_stats
		or char_stats.health <= 0
		or (hand and hand.is_full())
	)


func _update_hero_skill_tooltip() -> void:
	if not hero_skill_button:
		return
	var stage := clampi(char_stats.hero_skill_stage if char_stats else 1, 1, 3)
	var stage_effect := ""
	match stage:
		2:
			stage_effect = "生成的牌已突破。"
		3:
			stage_effect = "生成的牌已突破且本回合费用降低 1。"
	hero_skill_button.tooltip_text = (
		"魔焰焚心·%s阶：受到 %s 点伤害，生成 1 张临时随机魔修卡（不含攻击与基础防御）。%s临时牌离开手牌后移除。每回合限用一次。"
		% [stage, 1 if stage >= 3 else 2, stage_effect]
	)


func _pulse_hero_skill_button() -> void:
	if not hero_skill_button:
		return
	hero_skill_button.pivot_offset = hero_skill_button.size * 0.5
	hero_skill_button.scale = Vector2.ONE * 1.08
	var tween := hero_skill_button.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hero_skill_button, "scale", Vector2.ONE, 0.36)


func _is_demonic_character() -> bool:
	if not char_stats:
		return false
	if char_stats.character_name == "魔修" or char_stats.battle_anim_id == "demonic_cultivator":
		return true
	var paths := [
		char_stats.resource_path,
		char_stats.starting_deck.resource_path if char_stats.starting_deck else "",
		char_stats.draftable_cards.resource_path if char_stats.draftable_cards else "",
	]
	return ("%s %s %s" % [paths[0], paths[1], paths[2]]).contains("demonic_cultivator")


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
		var enemy_size := ENEMY_COMBATANT_CARD_SIZE * scale_factor
		var gap := COMBATANT_CARD_GAP * scale_factor
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
		_place_bottom_right(_player_card, PLAYER_CARD_BOTTOM_OFFSET, PLAYER_COMBATANT_CARD_SIZE, scale_factor)

	# 世界立绘已隐藏、战斗单位只显示为信息卡，但瞄准/选中框/飘字仍挂在世界节点上。
	# 把世界节点对齐到各自信息卡中心，否则选中框和卡的位置对不上（敌人越多偏得越远）。
	_schedule_world_combatant_alignment()


func _schedule_world_combatant_alignment() -> void:
	_combatant_layout_generation += 1
	_settle_world_combatants.call_deferred(_combatant_layout_generation)


func _settle_world_combatants(generation: int) -> void:
	# Control sizing and the Area2D broad phase settle on different frames. Reapply
	# briefly after a death/summon so the visible card, collision and target frame
	# all follow the surviving enemy's new slot.
	for _frame in 3:
		if generation != _combatant_layout_generation or not is_inside_tree():
			return
		await get_tree().process_frame
		_align_world_combatants()


func _align_world_combatants() -> void:
	if not is_inside_tree():
		return
	for card in _enemy_cards:
		_align_world_combatant(card)
	_align_world_combatant(_player_card)


func _align_world_combatant(card: BattleCombatantCard) -> void:
	if not card:
		return
	var combatant := card.combatant as Node2D
	if not is_instance_valid(combatant) or not combatant.is_inside_tree():
		return

	var rect := card.get_global_rect()
	var center := rect.position + rect.size * 0.5
	var canvas_xform := combatant.get_viewport().get_canvas_transform()
	combatant.global_position = canvas_xform.affine_inverse() * center
	combatant.force_update_transform()

	if combatant is Enemy:
		(combatant as Enemy).align_feedback_to_card(rect.size)
	elif combatant is Player:
		(combatant as Player).aligned_feedback_extents = rect.size


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
		_place_center_top(enemy_card, viewport_size, ENEMY_COMBATANT_CARD_SIZE, 58.0, scale_factor)
	if player_card:
		_place_bottom_right(player_card, PLAYER_CARD_BOTTOM_OFFSET, PLAYER_COMBATANT_CARD_SIZE, scale_factor)
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
	if char_stats and char_stats.stats_changed.is_connected(_update_hero_skill_button_state):
		char_stats.stats_changed.disconnect(_update_hero_skill_button_state)
	if get_viewport().size_changed.is_connected(_layout_battle_controls):
		get_viewport().size_changed.disconnect(_layout_battle_controls)
	if Events.card_play_preview_requested.is_connected(_on_card_play_preview_requested):
		Events.card_play_preview_requested.disconnect(_on_card_play_preview_requested)
	if Events.card_discarded.is_connected(_on_card_discarded):
		Events.card_discarded.disconnect(_on_card_discarded)
	if Events.deck_reshuffled.is_connected(_on_deck_reshuffled):
		Events.deck_reshuffled.disconnect(_on_deck_reshuffled)
	if Events.sha_qi_tier_changed.is_connected(_on_sha_qi_tier_changed):
		Events.sha_qi_tier_changed.disconnect(_on_sha_qi_tier_changed)
	if Events.card_drawn.is_connected(_on_card_drawn_sfx):
		Events.card_drawn.disconnect(_on_card_drawn_sfx)
	if Events.card_played.is_connected(_on_card_played_sfx):
		Events.card_played.disconnect(_on_card_played_sfx)
	if Events.card_discovery_requested.is_connected(_on_card_discovery_requested):
		Events.card_discovery_requested.disconnect(_on_card_discovery_requested)
	if Events.player_turn_started.is_connected(_on_player_turn_started):
		Events.player_turn_started.disconnect(_on_player_turn_started)
	if Events.player_turn_ended.is_connected(_on_player_turn_ended_for_banner):
		Events.player_turn_ended.disconnect(_on_player_turn_ended_for_banner)
	if Events.hero_skill_used.is_connected(_on_hero_skill_used):
		Events.hero_skill_used.disconnect(_on_hero_skill_used)
