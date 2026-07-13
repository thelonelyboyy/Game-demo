extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const OTHER_CHARACTER_PATH := "res://characters/sword_cultivator/sword_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const RELIC_POOL_PATH := "res://relics/relic_reward_pool.tres"
const FLAME_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_flame_white.tres"
const NEW_RELIC_PATHS := [
	"res://relics/demon_blood_crucible.tres",
	"res://relics/demon_crimson_gourd.tres",
	"res://relics/demon_soul_bell.tres",
	"res://relics/demon_wraith_banner.tres",
	"res://relics/demon_sha_urn.tres",
	"res://relics/demon_flame_wheel_core.tres",
	"res://relics/demon_ash_furnace.tres",
	"res://relics/demon_blood_tally.tres",
	"res://relics/demon_flame_lantern.tres",
	"res://relics/demon_soul_censer.tres",
	"res://relics/demon_ash_ledger.tres",
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(20.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var other_character := load(OTHER_CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "demonic relic support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	_check_reward_pool(character_resource, other_character)

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	for path: String in NEW_RELIC_PATHS:
		relic_handler.add_relic(load(path) as Relic)

	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	await get_tree().create_timer(2.4).timeout

	_check(battle.player.status_handler.get_status_stacks("sha_qi") >= 2, "sha urn grants two sha qi at combat start")
	await _check_self_damage_relics(battle)
	await _check_soul_mark_relics(battle)
	await _check_flame_relic(battle)
	await _check_exhaust_relic(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_reward_pool(character: CharacterStats, other_character: CharacterStats) -> void:
	var pool := load(RELIC_POOL_PATH) as RelicRewardPool
	_check(pool != null and pool.relics.size() == 53, "reward pool contains fifty-three relics")
	if not pool:
		return
	var found := 0
	for relic: Relic in pool.relics:
		if not relic or not NEW_RELIC_PATHS.has(relic.resource_path):
			continue
		found += 1
		_check(relic.can_appear_as_reward(character), "%s appears for demonic cultivator" % relic.id)
		_check(not relic.can_appear_as_reward(other_character), "%s stays out of other class pools" % relic.id)
	_check(found == NEW_RELIC_PATHS.size(), "all eleven tested demonic relics are in reward pool")


func _check_self_damage_relics(battle: Battle) -> void:
	var initial_hand := battle.player_handler.hand.get_child_count()
	var initial_mana := battle.char_stats.mana
	var initial_health := battle.player.stats.health
	battle.player.stats.block = 2
	battle.player.take_self_damage(2, Modifier.Type.DMG_TAKEN)
	await get_tree().create_timer(1.0).timeout
	_check(battle.player.stats.health == initial_health, "fully blocked self-inflicted damage does not count as lost life")
	_check(battle.player.stats.block == 0, "hero-style self damage still consumes block")
	_check(battle.player_handler.hand.get_child_count() == initial_hand, "fully blocked self damage does not trigger blood relics")

	battle.player.take_self_damage(2, Modifier.Type.DMG_TAKEN)
	await get_tree().create_timer(1.0).timeout
	_check(battle.player.stats.health == initial_health - 2, "self-inflicted damage reports actual lost life")
	_check(battle.player.stats.block == 3, "blood crucible grants block on self damage")
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "crimson gourd draws on first self damage")
	_check(battle.char_stats.mana == initial_mana, "blood tally waits for cumulative self damage threshold")

	battle.player.stats.block = 0
	battle.player.take_self_damage(2, Modifier.Type.DMG_TAKEN)
	await get_tree().create_timer(1.0).timeout
	_check(battle.player.stats.health == initial_health - 4, "repeated self-inflicted damage uses the same actual-loss path")
	_check(battle.player.stats.block == 3, "blood crucible can trigger repeatedly")
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "crimson gourd triggers only once per turn")
	_check(battle.char_stats.mana == initial_mana + 1, "blood tally grants mana at four cumulative self damage")
	Events.player_self_damaged.emit(4)
	await get_tree().process_frame
	_check(battle.char_stats.mana == initial_mana + 1, "blood tally triggers only once per turn")


func _check_soul_mark_relics(battle: Battle) -> void:
	battle.player.stats.mana = 0
	var block_before := battle.player.stats.block
	var enemies := _get_live_enemies(battle)
	var health_before: Array[int] = []
	for enemy: Enemy in enemies:
		health_before.append(enemy.stats.health)
	Events.soul_mark_spent.emit(3, true)
	await get_tree().create_timer(0.25).timeout
	_check(battle.player.stats.mana == 1, "soul bell grants mana on first soul mark spend")
	_check(battle.player.stats.block == block_before + 6, "soul censer grants block after spending at least three marks at once")
	for i in enemies.size():
		_check(health_before[i] - enemies[i].stats.health == 3, "wraith banner damages enemy %s per spent mark" % i)

	var second_health: Array[int] = []
	for enemy: Enemy in enemies:
		second_health.append(enemy.stats.health)
	Events.soul_mark_spent.emit(2, false)
	await get_tree().create_timer(0.25).timeout
	_check(battle.player.stats.mana == 1, "soul bell triggers only once per turn")
	_check(battle.player.stats.block == block_before + 6, "soul censer triggers only once per turn")
	for i in enemies.size():
		_check(second_health[i] == enemies[i].stats.health, "wraith banner triggers only once per turn for enemy %s" % i)

	Events.player_turn_started.emit()
	await get_tree().process_frame
	var next_turn_block := battle.player.stats.block
	Events.soul_mark_spent.emit(2, false)
	await get_tree().process_frame
	_check(battle.player.stats.block == next_turn_block, "soul censer ignores a spend below three marks")
	Events.soul_mark_spent.emit(3, false)
	await get_tree().process_frame
	_check(battle.player.stats.block == next_turn_block + 6, "a below-threshold spend does not consume soul censer's turn trigger")


func _check_flame_relic(battle: Battle) -> void:
	var flame := load(FLAME_CARD_PATH) as Card
	var initial_hand := battle.player_handler.hand.get_child_count()
	battle.char_stats.mana = 0
	Events.card_played.emit(flame)
	await get_tree().create_timer(0.45).timeout
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "flame wheel core draws on first flame card")
	Events.card_played.emit(flame)
	await get_tree().create_timer(0.45).timeout
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "flame wheel core triggers only once per turn")
	Events.flame_wheel_changed.emit([0, 1])
	await get_tree().process_frame
	_check(battle.char_stats.mana == 0, "flame lantern waits for three distinct colors")
	Events.flame_wheel_changed.emit([0, 1, 2])
	await get_tree().process_frame
	_check(battle.char_stats.mana == 1, "flame lantern grants mana at three distinct colors")
	Events.flame_wheel_changed.emit([0, 1, 2, 3])
	await get_tree().process_frame
	_check(battle.char_stats.mana == 1, "flame lantern triggers only once per turn")


func _check_exhaust_relic(battle: Battle) -> void:
	for i in 7:
		var draw_card := Card.new()
		draw_card.id = "ash_furnace_draw_%s" % i
		battle.char_stats.draw_pile.add_card(draw_card)

	battle.char_stats.mana = 0
	var initial_hand := battle.player_handler.hand.get_child_count()
	var exhausted_cards: Array[Card] = []
	for i in 6:
		var exhausted := Card.new()
		exhausted.id = "ash_ledger_exhaust_%s" % i
		exhausted_cards.append(exhausted)

	battle.player_handler._add_card_to_exhaust_pile(exhausted_cards[0])
	await get_tree().create_timer(0.35).timeout
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "ash furnace draws on first exhausted card")
	_check(battle.char_stats.mana == 0, "ash ledger waits for its third exhausted card")

	battle.player_handler._add_card_to_exhaust_pile(exhausted_cards[1])
	await get_tree().create_timer(0.35).timeout
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 1, "ash furnace triggers only once per turn")
	_check(battle.char_stats.mana == 0, "ash ledger still waits after two exhausted cards")

	battle.player_handler._add_card_to_exhaust_pile(exhausted_cards[2])
	await get_tree().create_timer(0.35).timeout
	_check(battle.player_handler.hand.get_child_count() == initial_hand + 2, "ash ledger draws on the third exhausted card")
	_check(battle.char_stats.mana == 1, "ash ledger grants mana on the third exhausted card")

	for _i in 2:
		var card_ui := battle.player_handler.hand.get_child(0)
		card_ui.queue_free()
		await get_tree().process_frame
	var next_turn_hand := battle.player_handler.hand.get_child_count()
	Events.player_turn_started.emit()
	await get_tree().process_frame
	for i in range(3, 6):
		battle.player_handler._add_card_to_exhaust_pile(exhausted_cards[i])
		await get_tree().create_timer(0.35).timeout
	_check(battle.player_handler.hand.get_child_count() == next_turn_hand + 2, "exhaust relic draws reset independently next turn")
	_check(battle.char_stats.mana == 2, "ash ledger counter resets at the next player turn")
	for exhausted: Card in exhausted_cards:
		_check(battle.char_stats.exhaust_pile.cards.has(exhausted), "exhaust relics preserve %s in the exhaust pile" % exhausted.id)


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	return enemies


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("DEMONIC_RELIC_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DEMONIC_RELIC_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DEMONIC_RELIC_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
