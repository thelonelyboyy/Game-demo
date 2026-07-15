extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const SAMPLE_CARD_PATHS := [
	"res://characters/demonic_cultivator/cards/demon_blood_repay.tres",
	"res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres",
	"res://characters/demonic_cultivator/cards/shadow_step.tres",
	"res://common_cards/circulating_breath.tres",
]

var failures := PackedStringArray()


func _ready() -> void:
	get_tree().create_timer(45.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_static_keyword_rules()
	_check_innate_ordering()
	_check_eternal_guards()

	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene and relic_handler_scene and character_resource and battle_stats, "关键词实战资源可加载")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.0).timeout

	_check(battle.player_handler.player_actions_enabled, "真实战斗进入可操作回合")
	await _clear_hand(battle)
	_check_play_destinations(battle)
	await _check_retained_hand(battle)
	await _check_pile_selection_keywords(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_static_keyword_rules() -> void:
	var card := CultivationCard.new()
	card.type = Card.Type.SKILL
	card.retains = true
	_check(card.get_end_turn_destination() == Card.EndTurnDestination.RETAIN, "保留牌回合结束留在手牌")
	card.ethereal = true
	_check(card.get_end_turn_destination() == Card.EndTurnDestination.EXHAUST, "虚无优先于保留")
	card.temporary_keyword = true
	_check(card.get_end_turn_destination() == Card.EndTurnDestination.REMOVE, "临时优先于虚无和保留")

	card = CultivationCard.new()
	card.type = Card.Type.SKILL
	card.cyclic = true
	_check(card.get_play_destination() == Card.PlayDestination.DRAW_TOP, "周天牌打出后回到抽牌堆顶")
	card.exhausts = true
	_check(card.get_play_destination() == Card.PlayDestination.EXHAUST, "消耗优先于周天")
	card.temporary_keyword = true
	_check(card.get_play_destination() == Card.PlayDestination.REMOVE, "临时优先于消耗和周天")
	_check(card.get_keyword_conflict_notes().size() > 0, "冲突组合提供明确优先级说明")

	card = CultivationCard.new()
	card.search_count = 2
	card.retrieve_count = 1
	card.reclaim_count = 1
	var labels := card.get_keyword_labels()
	_check(labels.has("检索2") and labels.has("取回1") and labels.has("归墟1"), "一张牌可同时呈现多个带参数关键词")
	_check(card.get_standard_effect_count() == 3, "带参数关键词分别计为独立标准效果")


func _check_innate_ordering() -> void:
	var normal_a := _make_card("normal_a")
	var innate_a := _make_card("innate_a")
	var normal_b := _make_card("normal_b")
	var innate_b := _make_card("innate_b")
	innate_a.innate = true
	innate_b.innate = true
	var pile := CardPile.new()
	pile.cards = [normal_a, innate_a, normal_b, innate_b]
	pile.move_innate_cards_to_top()
	_check(pile.cards[0].is_innate_card() and pile.cards[1].is_innate_card(), "固有牌统一移到起手抽牌区顶部")


func _check_eternal_guards() -> void:
	var eternal := _make_card("eternal")
	eternal.eternal = true
	var normal := _make_card("normal")
	_check(eternal.blocks_manual_play(), "永恒牌无法打出")
	_check(not eternal.can_be_removed_from_deck(), "永恒牌无法删除")
	_check(not eternal.can_be_transformed(), "永恒牌无法变化")
	_check(not eternal.can_be_fused(), "永恒牌无法合炼")
	var library := CardFusionLibrary.new()
	_check(not library.can_fuse(eternal, normal), "合炼入口拒绝永恒牌")


func _check_play_destinations(battle: Battle) -> void:
	battle.char_stats.draw_pile.clear()
	battle.char_stats.discard.clear()
	battle.char_stats.exhaust_pile.clear()

	var cyclic := _make_card("cyclic")
	cyclic.cyclic = true
	battle.player_handler._on_card_played(cyclic)
	_check(battle.char_stats.draw_pile.cards.front() == cyclic, "真实战斗中周天牌回到抽牌堆顶")

	var exhaust_cyclic := _make_card("exhaust_cyclic")
	exhaust_cyclic.cyclic = true
	exhaust_cyclic.exhausts = true
	battle.player_handler._on_card_played(exhaust_cyclic)
	_check(battle.char_stats.exhaust_pile.cards.has(exhaust_cyclic), "真实战斗中消耗+周天进入消耗堆")
	_check(not battle.char_stats.draw_pile.cards.has(exhaust_cyclic), "消耗+周天不会重复回到抽牌堆")

	var temporary_all := _make_card("temporary_all")
	temporary_all.temporary_keyword = true
	temporary_all.exhausts = true
	temporary_all.cyclic = true
	battle.player_handler._on_card_played(temporary_all)
	_check(
		not battle.char_stats.draw_pile.cards.has(temporary_all)
		and not battle.char_stats.discard.cards.has(temporary_all)
		and not battle.char_stats.exhaust_pile.cards.has(temporary_all),
		"真实战斗中临时牌不会重复进入任何牌堆"
	)


func _check_retained_hand(battle: Battle) -> void:
	var retained := _make_card("retained")
	retained.retains = true
	_check(battle.player_handler.hand.add_card(retained, false), "保留测试牌进入手牌")
	await get_tree().process_frame
	battle.player_handler.discard_cards()
	await get_tree().process_frame
	_check(_find_card_ui(battle.player_handler.hand, retained) != null, "回合清理后保留牌仍在手牌")
	_check(not battle.char_stats.discard.cards.has(retained), "保留牌未进入弃牌堆")
	var retained_ui := _find_card_ui(battle.player_handler.hand, retained)
	if retained_ui:
		battle.player_handler.remove_card_from_hand(retained_ui)
	await get_tree().process_frame


func _check_pile_selection_keywords(battle: Battle) -> void:
	await _clear_hand(battle)
	battle.char_stats.draw_pile.clear()
	battle.char_stats.discard.clear()
	battle.char_stats.exhaust_pile.clear()

	var samples: Array[Card] = []
	for path: String in SAMPLE_CARD_PATHS:
		var resource := load(path) as Card
		if resource:
			samples.append(resource.create_runtime_copy())
	_check(samples.size() == SAMPLE_CARD_PATHS.size(), "检索测试牌全部可加载")
	if samples.size() < 4:
		return
	battle.char_stats.draw_pile.add_card(samples[0])
	battle.char_stats.draw_pile.add_card(samples[1])
	battle.char_stats.discard.add_card(samples[2])
	battle.char_stats.exhaust_pile.add_card(samples[3])

	var battle_ui_listener := Callable(battle.battle_ui, "_on_card_discovery_requested")
	var restore_battle_ui_listener := Events.card_discovery_requested.is_connected(battle_ui_listener)
	if restore_battle_ui_listener:
		Events.card_discovery_requested.disconnect(battle_ui_listener)
	if not Events.card_discovery_requested.is_connected(_auto_resolve_selection):
		Events.card_discovery_requested.connect(_auto_resolve_selection)

	var keyword_card := _make_card("multi_select")
	keyword_card.search_count = 1
	keyword_card.retrieve_count = 1
	keyword_card.reclaim_count = 1
	await keyword_card.apply_keyword_effects([battle.player])
	await get_tree().process_frame

	if Events.card_discovery_requested.is_connected(_auto_resolve_selection):
		Events.card_discovery_requested.disconnect(_auto_resolve_selection)
	if restore_battle_ui_listener and is_instance_valid(battle.battle_ui):
		Events.card_discovery_requested.connect(battle_ui_listener)

	_check(_find_card_ui(battle.player_handler.hand, samples[0]) != null, "检索打开抽牌堆并选取一张牌")
	_check(_find_card_ui(battle.player_handler.hand, samples[2]) != null, "取回打开弃牌堆并选取一张牌")
	_check(_find_card_ui(battle.player_handler.hand, samples[3]) != null, "归墟打开消耗堆并选取一张牌")
	_check(battle.char_stats.draw_pile.cards.has(samples[1]), "未选择的抽牌堆卡牌保持原位")


func _auto_resolve_selection(request: CardDiscoveryRequest) -> void:
	var selected: Array[Card] = []
	for index in range(mini(request.picks, request.choices.size())):
		selected.append(request.choices[index])
	request.resolve(selected)


func _clear_hand(battle: Battle) -> void:
	for child: Node in battle.player_handler.hand.get_children():
		var card_ui := child as CardUI
		if card_ui:
			battle.player_handler.remove_card_from_hand(card_ui)
	await get_tree().process_frame


func _find_card_ui(hand: Hand, card: Card) -> CardUI:
	for child: Node in hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card == card:
			return card_ui
	return null


func _make_card(card_id: String) -> CultivationCard:
	var card := CultivationCard.new()
	card.id = card_id
	card.display_name = card_id
	card.type = Card.Type.SKILL
	card.target = Card.Target.SELF
	return card


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CARD_KEYWORD_STANDARDIZATION_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CARD_KEYWORD_STANDARDIZATION_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("CARD_KEYWORD_STANDARDIZATION_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
