extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const RELIC_PATHS := [
	"res://relics/formless_heavenly_tome.tres",
	"res://relics/heaven_devouring_core.tres",
	"res://relics/hidden_breath_seal.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(30.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var other_character := load(OTHER_CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and other_character != null and battle_stats != null and pool != null, "boss relic support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not other_character or not battle_stats or not pool:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	for path: String in RELIC_PATHS:
		var relic := load(path) as Relic
		_check(relic != null and pool.relics.has(relic), "%s is present in the reward pool" % path)
		_check(relic != null and relic.rarity == Relic.Rarity.BOSS, "%s is boss rarity" % path)
		_check(relic != null and relic.can_appear_as_reward(character_resource), "%s supports demonic cultivator" % path)
		_check(relic != null and relic.can_appear_as_reward(other_character), "%s supports other professions" % path)
		relic_handler.add_relic(relic)

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(3.2).timeout

	_check(battle.player_handler.hand.get_child_count() == battle.char_stats.cards_per_turn + 1, "formless heavenly tome draws one extra card on the first turn")
	_check(_count_combat_card(battle, "eclipse_scar") == 2, "formless heavenly tome adds exactly two eclipse scars to the combat cycle")
	for enemy: Enemy in battle.enemy_handler.get_live_enemies():
		_check(enemy.status_handler.get_status_stacks("muscle") >= 2, "heaven devouring core grants enemy muscle at combat start")
	_check(battle.char_stats.mana == battle.char_stats.max_mana + 1, "heaven devouring core grants one mana after the turn reset")
	_check_retained_mana(battle, relic_handler)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_retained_mana(battle: Battle, relic_handler: RelicHandler) -> void:
	var relic_ui := _find_relic_ui(relic_handler, "hidden_breath_seal")
	_check(relic_ui != null, "hidden breath seal UI is available")
	if not relic_ui:
		return
	var turn_started_callable := Callable(relic_ui.relic, "_on_player_turn_started")
	var turn_ended_callable := Callable(relic_ui.relic, "_on_player_turn_ended")
	_check(Events.player_turn_started.is_connected(turn_started_callable), "hidden breath seal listens for turn starts")
	_check(Events.player_turn_ended.is_connected(turn_ended_callable), "hidden breath seal listens for turn ends")

	battle.char_stats.mana = 5
	relic_ui.relic.call("_on_player_turn_ended")
	battle.char_stats.reset_mana()
	relic_ui.relic.call("_on_player_turn_started")
	_check(battle.char_stats.mana == battle.char_stats.max_mana + 2, "hidden breath seal carries at most two mana into the next turn")
	battle.char_stats.reset_mana()
	relic_ui.relic.call("_on_player_turn_started")
	_check(battle.char_stats.mana == battle.char_stats.max_mana, "hidden breath seal spends stored mana only once")


func _count_combat_card(battle: Battle, card_id: String) -> int:
	var count := 0
	for pile: CardPile in [battle.char_stats.draw_pile, battle.char_stats.discard, battle.char_stats.exhaust_pile]:
		if not pile:
			continue
		for card: Card in pile.cards:
			if card and card.id == card_id:
				count += 1
	for child: Node in battle.player_handler.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.id == card_id:
			count += 1
	return count


func _find_relic_ui(handler: RelicHandler, relic_id: String) -> RelicUI:
	for child: Node in handler.relics.get_children():
		var relic_ui := child as RelicUI
		if relic_ui and relic_ui.relic and relic_ui.relic.id == relic_id:
			return relic_ui
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("BOSS_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("BOSS_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("BOSS_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
