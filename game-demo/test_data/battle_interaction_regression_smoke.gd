extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const POTION_HANDLER_SCENE_PATH := "res://scenes/potion_handler/potion_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/tier_1_bats_3.tres"
const POTION_PATH := "res://potions/flame_talisman.tres"

var failures: PackedStringArray = []


func _ready() -> void:
	get_tree().create_timer(20.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var battle_scene := load(BATTLE_SCENE_PATH) as PackedScene
	var relic_handler_scene := load(RELIC_HANDLER_SCENE_PATH) as PackedScene
	var potion_handler_scene := load(POTION_HANDLER_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	var battle_stats := load(BATTLE_PATH) as BattleStats
	var potion := load(POTION_PATH) as Potion
	_check(
		battle_scene != null
		and relic_handler_scene != null
		and potion_handler_scene != null
		and character_resource != null
		and battle_stats != null
		and potion != null,
		"battle interaction resources load"
	)
	if not battle_scene or not relic_handler_scene or not potion_handler_scene or not character_resource or not battle_stats or not potion:
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
	await get_tree().create_timer(1.0, true).timeout

	var enemies := battle.enemy_handler.get_live_enemies()
	_check(enemies.size() == 3, "three-enemy regression battle spawns three targets")
	_check(battle.battle_ui._enemy_cards.size() == 3, "three enemy combatant cards are visible")
	_check_all_combatants_aligned(battle)
	_check_combatant_card_information(battle)

	var potion_handler := potion_handler_scene.instantiate() as PotionHandler
	add_child(potion_handler)
	await get_tree().process_frame
	_check(potion_handler.add_potion(potion), "single-target talisman enters a potion slot")
	var occupied_ui := _occupied_potion_ui(potion_handler)
	_check(occupied_ui != null, "single-target talisman has an occupied UI slot")
	if occupied_ui and enemies.size() == 3:
		var selected := enemies[1] as Enemy
		var selected_health := selected.stats.health
		var other_health := (enemies[2] as Enemy).stats.health
		potion_handler._on_use_requested(occupied_ui)
		_check(potion_handler._aiming_ui == occupied_ui and potion_handler.is_processing_input(), "multi-enemy talisman enters active aiming")
		var selected_center := selected.get_global_transform_with_canvas().origin
		_check(potion_handler._select_target_at(selected_center), "aiming resolves the enemy at the clicked card position")
		await get_tree().process_frame
		_check(selected.stats.health < selected_health, "single-target talisman damages only the selected enemy")
		_check((enemies[2] as Enemy).stats.health == other_health, "single-target talisman leaves other enemies untouched")
		_check(potion_handler._aiming_ui == null and not potion_handler.is_processing_input(), "successful talisman use exits aiming without a stalled input state")
		_check(occupied_ui.potion == null, "successful talisman use consumes the talisman")

	if enemies.size() == 3:
		var defeated := enemies[0] as Enemy
		defeated.take_damage(defeated.stats.health + defeated.stats.block + 999, Modifier.Type.DMG_TAKEN)
		var wait_started := Time.get_ticks_msec()
		while battle.battle_ui._enemy_cards.size() != 2 and Time.get_ticks_msec() - wait_started < 3000:
			await get_tree().process_frame
		for _frame in 4:
			await get_tree().process_frame
		_check(battle.battle_ui._enemy_cards.size() == 2, "defeated enemy card is removed from the three-enemy row")
		_check_all_combatants_aligned(battle)

	_check_hit_pause_watchdog()

	get_tree().paused = false
	Engine.time_scale = 1.0
	potion_handler.queue_free()
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	_finish()


func _check_all_combatants_aligned(battle: Battle) -> void:
	for card: BattleCombatantCard in battle.battle_ui._enemy_cards:
		var enemy := card.combatant as Enemy
		_check(enemy != null, "enemy card remains bound to a live enemy")
		if not enemy:
			continue
		var expected := card.get_global_rect().get_center()
		var actual := enemy.get_global_transform_with_canvas().origin
		_check(actual.distance_to(expected) <= 1.5, "enemy target frame follows its reflowed combatant card")
		_check(enemy.aligned_feedback_extents.distance_to(card.get_global_rect().size) <= 1.5, "enemy target extents follow the reflowed card size")


func _check_combatant_card_information(battle: Battle) -> void:
	var player_card := battle.battle_ui._player_card
	_check(player_card != null and player_card._name_label != null and not player_card._name_label.visible, "player name is hidden on the combatant card")
	_check(player_card != null and player_card._frame.get_theme_stylebox("panel") is StyleBoxEmpty, "player combatant card has no outer ornamental frame")
	_check(player_card != null and player_card.tooltip_text.is_empty(), "player card body does not expose the character tooltip")
	_check(player_card != null and player_card._portrait.tooltip_text.contains(battle.player.stats.character_name), "player portrait hover tooltip contains the character name")
	_check(player_card != null and player_card._status_row is HFlowContainer, "player statuses use a wrapping flow layout")
	_check(
		player_card != null
		and absf(player_card.get_global_rect().end.y - get_viewport().get_visible_rect().end.y) <= 1.5,
		"player combatant card touches the bottom edge"
	)
	_check(
		player_card != null
		and is_equal_approx(player_card._status_row.size.y, BattleCombatantCard.STATUS_ROW_HEIGHT),
		"player combatant card reserves exactly two status rows"
	)
	_check(
		player_card != null
		and player_card._status_row.size.x >= BattleCombatantCard.STATUS_CHIP_WIDTH * 4.0 + 18.0
		and player_card._status_row.size.y >= BattleCombatantCard.STATUS_CHIP_HEIGHT * 2.0 + 6.0,
		"player status rail fits four large chips per row and two wrapped rows"
	)
	if battle.battle_ui._enemy_cards.is_empty():
		return
	var enemy_card: BattleCombatantCard = battle.battle_ui._enemy_cards.front()
	var enemy := enemy_card.combatant as Enemy
	_check(not enemy_card._name_label.visible, "enemy name is hidden on the combatant card")
	_check(enemy_card._frame.get_theme_stylebox("panel") is StyleBoxEmpty, "enemy combatant card has no outer ornamental frame")
	_check(enemy_card.tooltip_text.is_empty(), "enemy card body does not expose the enemy tooltip")
	_check(enemy != null and enemy_card._portrait.tooltip_text.contains(enemy.stats.display_name), "enemy portrait hover tooltip contains the enemy name")
	_check(enemy_card._status_row is HFlowContainer, "enemy statuses use a wrapping flow layout")


func _occupied_potion_ui(handler: PotionHandler) -> PotionUI:
	for ui: PotionUI in handler.get_children():
		if ui.potion:
			return ui
	return null


func _check_hit_pause_watchdog() -> void:
	HitPause.force_restore()
	Engine.time_scale = 0.05
	HitPause._restore_time_scale = 1.0
	HitPause._pause_until_msec = Time.get_ticks_msec() - 1
	HitPause._active = true
	HitPause.watchdog()
	_check(is_equal_approx(Engine.time_scale, 1.0), "hit-pause watchdog restores normal animation speed after a lost timer")
	_check(not HitPause._active, "hit-pause watchdog clears the active pause state")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("BATTLE_INTERACTION_REGRESSION_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("BATTLE_INTERACTION_REGRESSION_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("BATTLE_INTERACTION_REGRESSION_SMOKE: timed out")
	get_tree().quit(1)
