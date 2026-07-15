extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_mist_wolf.tres"
const STRIKE_PATH := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const FIRE_CHOICE := preload("res://custom_resources/spirit_root_fire_choice.gd")

var failures: PackedStringArray = []
var current_step := "startup"


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	current_step = "load_support"
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "fire choice support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var character := character_resource.create_instance(Card.Element.FIRE)
	for index in mini(7, character.deck.cards.size()):
		character.deck.cards[index].element = Card.Element.FIRE
	character.reset_spirit_root_turn_flags()
	_check(character.is_spirit_root_complete(), "fire spirit root reaches completion for the regression setup")

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	add_child(battle)
	battle.char_stats = character
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	current_step = "wait_for_battle"
	await get_tree().create_timer(1.5).timeout

	var enemies := _get_live_enemies(battle)
	_check(enemies.size() == 1, "fire choice regression starts with one enemy")
	if enemies.is_empty():
		_cleanup_and_finish(battle, relic_handler)
		return

	current_step = "wait_for_choice"
	var captured_choices: Array = []
	var capture_choice := func(choice): captured_choices.append(choice)
	Events.spirit_root_fire_choice_requested.connect(capture_choice, CONNECT_ONE_SHOT)
	var strike := (load(STRIKE_PATH) as Card).duplicate(true) as CultivationCard
	strike.element = Card.Element.FIRE
	strike.bind_spirit_root_owner(character)
	var targets: Array[Node] = [enemies[0]]
	var health_before := enemies[0].stats.health
	strike.play(targets, character, battle.player.modifier_handler)

	# 等到旧实现中的攻击动画早已结束，确保能稳定复现“结束信号先发、后 await”的竞态。
	await get_tree().create_timer(2.1).timeout
	_check(captured_choices.size() == 1, "first fire attack requests the completion choice")
	_check(enemies[0].stats.health == health_before, "damage waits until the fire choice is resolved")
	if not captured_choices.is_empty():
		current_step = "resolve_amplify"
		battle.spirit_root_handler._resolve_fire_choice(captured_choices[0], FIRE_CHOICE.CHOICE_AMPLIFY)
		await get_tree().create_timer(2.1).timeout
		var actual_damage := health_before - enemies[0].stats.health
		_check(actual_damage == 15, "amplify choice resumes the attack and deals fifteen damage (actual: %s)" % actual_damage)
		_check(character.spirit_root_perfect_triggered_this_turn, "fire completion trigger is consumed once")

	_cleanup_and_finish(battle, relic_handler)


func _get_live_enemies(battle: Battle) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child: Node in battle.enemy_handler.get_children():
		var enemy := child as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	return enemies


func _cleanup_and_finish(battle: Battle, relic_handler: RelicHandler) -> void:
	current_step = "cleanup"
	if battle:
		battle.queue_free()
	if relic_handler:
		relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("SPIRIT_ROOT_FIRE_CHOICE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("SPIRIT_ROOT_FIRE_CHOICE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("SPIRIT_ROOT_FIRE_CHOICE_SMOKE_TIMEOUT: %s" % current_step)
	get_tree().paused = false
	get_tree().quit(2)
