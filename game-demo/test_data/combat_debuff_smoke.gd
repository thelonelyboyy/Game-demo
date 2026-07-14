extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_spirit_leech.tres"
const WEAK_PATH := "res://statuses/weak.tres"
const FRAIL_PATH := "res://statuses/frail.tres"
const EXPOSED_PATH := "res://statuses/exposed.tres"
const STRIKE_PATH := "res://common_cards/strike.tres"
const DEFEND_PATH := "res://common_cards/defend.tres"
const ENEMY_ACTION_CONFIGS := [
	{
		"enemy": "res://enemies/spirit_leech/spirit_leech_enemy.tres",
		"action": "DrainAction",
		"status": "weak",
		"intent": "虚弱1回合",
	},
	{
		"enemy": "res://enemies/scripture_moth/scripture_moth_enemy.tres",
		"action": "PoisonPowderAction",
		"status": "frail",
		"intent": "碎甲1回合",
	},
	{
		"enemy": "res://enemies/karma_collector/karma_collector_enemy.tres",
		"action": "SentenceAction",
		"status": "frail",
		"intent": "碎甲1回合",
	},
	{
		"enemy": "res://enemies/underworld_judge/underworld_judge_enemy.tres",
		"action": "SoulStrikeAction",
		"status": "weak",
		"intent": "虚弱1回合",
	},
]

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(30.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_enemy_action_configuration()
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "combat debuff support resources load")
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
	await get_tree().create_timer(2.4).timeout

	var enemy := battle.enemy_handler.get_live_enemies().front() as Enemy
	_check(enemy != null and enemy.stats.id == "spirit_leech", "combat debuff smoke spawns spirit leech")
	if enemy:
		await _check_real_weak_action(battle, enemy)
		await _check_frail_card_math(battle)

	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_real_weak_action(battle: Battle, enemy: Enemy) -> void:
	var action := enemy.enemy_action_picker.get_node_or_null("DrainAction") as EnemyAction
	_check(action != null, "spirit leech exposes its attack-and-weak action")
	if not action:
		return

	var completion_callable := Callable(battle.enemy_handler, "_on_enemy_action_completed")
	var was_connected := Events.enemy_action_completed.is_connected(completion_callable)
	if was_connected:
		Events.enemy_action_completed.disconnect(completion_callable)
	var exposed_effect := StatusEffect.new()
	exposed_effect.status = load(EXPOSED_PATH) as Status
	var player_targets: Array[Node] = [battle.player]
	exposed_effect.execute(player_targets)
	await get_tree().process_frame
	action.update_intent_text()
	_check(action.intent.current_text.begins_with("18"), "enemy intent applies exposed exactly once")
	var health_before := battle.char_stats.health
	action.perform_action()
	await Events.enemy_action_completed
	if was_connected and is_instance_valid(battle.enemy_handler):
		Events.enemy_action_completed.connect(completion_callable)

	var weak := battle.player.status_handler.get_status("weak")
	_check(health_before - battle.char_stats.health == 18, "action completion waits for advertised exposed damage to resolve exactly once")
	_check(weak != null and weak.duration == 2, "attack-and-status action applies weak before turn ticking")
	_check(battle.player.modifier_handler.get_modified_value(20, Modifier.Type.DMG_DEALT) == 15, "weak reduces outgoing damage by twenty-five percent")
	var exposed := battle.player.status_handler.get_status("exposed")
	if exposed:
		exposed.duration = 0
	await get_tree().process_frame
	await get_tree().process_frame

	var strike := (load(STRIKE_PATH) as CultivationCard).duplicate(true) as CultivationCard
	var strike_preview := strike.get_updated_tooltip(battle.player.modifier_handler, enemy.modifier_handler)
	_check(strike_preview.contains("4 点伤害"), "selected attack preview shows the actual weak-modified damage")
	var enemy_health_before := enemy.stats.health
	strike.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(enemy_health_before - enemy.stats.health == 4, "weak modifies real attack card damage with floor rounding")

	if weak:
		weak.duration = 0
	await get_tree().process_frame
	await get_tree().process_frame
	_check(battle.player.status_handler.get_status("weak") == null, "weak status disappears at zero duration")
	_check(battle.player.modifier_handler.get_modified_value(20, Modifier.Type.DMG_DEALT) == 20, "weak damage modifier is removed on expiry")


func _check_frail_card_math(battle: Battle) -> void:
	var frail_resource := load(FRAIL_PATH) as Status
	var effect := StatusEffect.new()
	effect.status = frail_resource
	var targets: Array[Node] = [battle.player]
	effect.execute(targets)
	await get_tree().process_frame
	var frail := battle.player.status_handler.get_status("frail")
	_check(frail != null and frail.duration == 2, "frail applies with one full player-turn window")
	_check(battle.player.modifier_handler.get_modified_value(20, Modifier.Type.BLOCK_GAIN) == 15, "frail reduces block gain by twenty-five percent")

	var defend := (load(DEFEND_PATH) as CultivationCard).duplicate(true) as CultivationCard
	var defend_preview := defend.get_updated_tooltip(battle.player.modifier_handler, null)
	_check(defend_preview.contains("3 点护体"), "selected defense preview shows the actual frail-modified block")
	battle.char_stats.block = 0
	defend.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.char_stats.block == 3, "frail modifies real defense card block with floor rounding")

	effect.execute(targets)
	await get_tree().process_frame
	frail = battle.player.status_handler.get_status("frail")
	_check(frail != null and frail.duration == 4, "reapplying frail extends its duration")
	if frail:
		frail.duration = 0
	await get_tree().process_frame
	await get_tree().process_frame
	_check(battle.player.status_handler.get_status("frail") == null, "frail status disappears at zero duration")
	_check(battle.player.modifier_handler.get_modified_value(20, Modifier.Type.BLOCK_GAIN) == 20, "frail block modifier is removed on expiry")


func _check_enemy_action_configuration() -> void:
	var weak := load(WEAK_PATH) as Status
	var frail := load(FRAIL_PATH) as Status
	_check(weak != null and weak.is_debuff and weak.stack_type == Status.StackType.DURATION, "weak is a duration-stacking debuff")
	_check(frail != null and frail.is_debuff and frail.stack_type == Status.StackType.DURATION, "frail is a duration-stacking debuff")
	for spec: Dictionary in ENEMY_ACTION_CONFIGS:
		var stats := load(String(spec.enemy)) as EnemyStats
		_check(stats != null and stats.ai != null, "%s loads configured AI" % spec.enemy)
		if not stats or not stats.ai:
			continue
		var ai := stats.ai.instantiate() as EnemyActionPicker
		var action := ai.get_node_or_null(String(spec.action)) as EnemyAction
		_check(action != null, "%s uses the shared attack-and-status action" % spec.enemy)
		if action:
			var configured_status := action.get("status") as Status
			_check(configured_status != null and configured_status.id == String(spec.status), "%s applies the configured debuff" % spec.enemy)
			_check(action.intent.base_text.contains(String(spec.intent)), "%s telegraphs the debuff duration" % spec.enemy)
		ai.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("COMBAT_DEBUFF_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("COMBAT_DEBUFF_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("COMBAT_DEBUFF_SMOKE_TIMEOUT")
	get_tree().paused = false
	get_tree().quit(2)
