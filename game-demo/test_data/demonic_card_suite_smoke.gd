extends Node

const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const RELIC_HANDLER_SCENE_PATH := "res://scenes/relic_handler/relic_handler.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const BATTLE_PATH := "res://battles/demo_n_paper_wolf.tres"
const BLOOD_DEBT_PATH := "res://characters/demonic_cultivator/cards/demon_blood_debt.tres"
const SHA_BLADE_PATH := "res://characters/demonic_cultivator/cards/demon_sha_blade.tres"
const MYRIAD_MARKS_PATH := "res://characters/demonic_cultivator/cards/demon_myriad_marks_return.tres"
const SHADOW_STEP_PATH := "res://characters/demonic_cultivator/cards/shadow_step.tres"
const SOUL_LAMP_RENEWAL_PATH := "res://characters/demonic_cultivator/cards/demon_soul_lamp_renewal.tres"
const FLESH_REBIRTH_PATH := "res://characters/demonic_cultivator/cards/demon_flesh_rebirth.tres"
const BLOOD_MEMBRANE_PATH := "res://characters/demonic_cultivator/cards/engines/demon_blood_membrane.tres"
const BLOOD_DEBT_CURSE_PATH := "res://common_cards/status/blood_debt_curse.tres"
const KARMIC_FIRE_CURSE_PATH := "res://common_cards/status/karmic_fire_curse.tres"
const STRIKE_PATH := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const DEFEND_PATH := "res://characters/demonic_cultivator/cards/demon_defend.tres"
const BLOOD_WARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_ward.tres"
const SHA_QI_PATH := "res://statuses/sha_qi.tres"
const SOUL_MARK_PATH := "res://statuses/soul_mark.tres"

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
	_check(battle_scene != null and relic_handler_scene != null and character_resource != null and battle_stats != null, "demonic suite support resources load")
	if not battle_scene or not relic_handler_scene or not character_resource or not battle_stats:
		_finish()
		return

	var relic_handler := relic_handler_scene.instantiate() as RelicHandler
	current_step = "setup_relics"
	add_child(relic_handler)
	await get_tree().process_frame
	var battle := battle_scene.instantiate() as Battle
	current_step = "setup_battle"
	add_child(battle)
	battle.char_stats = character_resource.create_instance()
	battle.battle_stats = battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	current_step = "wait_for_battle"
	await get_tree().create_timer(1.8).timeout

	current_step = "resolve_cards"
	var enemies := _get_live_enemies(battle)
	_check(enemies.size() == 2, "demonic suite starts with two enemies")
	if enemies.size() >= 2:
		current_step = "blood_debt"
		await _check_blood_debt(battle, enemies[0])
		current_step = "sha_blade"
		await _check_sha_blade(battle, enemies[0])
		current_step = "myriad_marks"
		await _check_myriad_marks(battle, enemies)
		current_step = "pile_tutors"
		await _check_pile_tutors(battle, enemies[0])
		current_step = "exhaust_engine"
		await _check_exhaust_guard_engine(battle)
		current_step = "curse_lifecycle"
		await _check_curse_lifecycle(battle)

	current_step = "cleanup"
	get_tree().paused = false
	battle.queue_free()
	relic_handler.queue_free()
	await get_tree().process_frame
	current_step = "finish"
	_finish()


func _check_blood_debt(battle: Battle, enemy: Enemy) -> void:
	var card := (load(BLOOD_DEBT_PATH) as Card).duplicate(true) as CultivationCard
	Events.player_self_damaged.emit(4)
	var before := enemy.stats.health
	card.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(before - enemy.stats.health == 9, "blood debt converts current-turn self damage into attack damage")


func _check_curse_lifecycle(battle: Battle) -> void:
	var blood_debt := (load(BLOOD_DEBT_CURSE_PATH) as Card).duplicate(true) as CultivationCard
	var health_before_discard := battle.player.stats.health
	blood_debt.handle_lifecycle_trigger(Card.LifecycleTrigger.DISCARDED, [], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(health_before_discard - battle.player.stats.health == 2, "discarding blood debt loses two life in combat")

	var karmic_fire := (load(KARMIC_FIRE_CURSE_PATH) as Card).duplicate(true) as CultivationCard
	var health_before_burn := battle.player.stats.health
	karmic_fire.apply_effects([], battle.player.modifier_handler)
	battle.player_handler._on_card_played(karmic_fire)
	await get_tree().process_frame
	_check(health_before_burn - battle.player.stats.health == 3, "burning karmic fire loses three life in combat")
	_check(battle.char_stats.exhaust_pile.cards.has(karmic_fire), "burned karmic fire enters the exhaust pile")


func _check_sha_blade(battle: Battle, enemy: Enemy) -> void:
	var sha := (load(SHA_QI_PATH) as Status).duplicate() as Status
	sha.stacks = 3
	battle.player.status_handler.add_status(sha)
	var card := (load(SHA_BLADE_PATH) as Card).duplicate(true) as CultivationCard
	var before := enemy.stats.health
	card.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(battle.player.status_handler.get_status_stacks("sha_qi") == 1, "sha blade consumes at most two sha qi")
	_check(before - enemy.stats.health >= 10, "sha blade converts consumed sha qi into damage")


func _check_myriad_marks(battle: Battle, enemies: Array[Enemy]) -> void:
	for enemy: Enemy in enemies:
		var mark := (load(SOUL_MARK_PATH) as Status).duplicate() as Status
		mark.stacks = 3
		enemy.status_handler.add_status(mark)
	var before := [enemies[0].stats.health, enemies[1].stats.health]
	var card := (load(MYRIAD_MARKS_PATH) as Card).duplicate(true) as CultivationCard
	var targets: Array[Node] = []
	targets.assign(enemies)
	card.apply_effects(targets, battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	for i in enemies.size():
		_check(enemies[i].status_handler.get_status_stacks("soul_mark") == 0, "myriad marks consumes all marks on enemy %s" % i)
		_check(before[i] - enemies[i].stats.health >= 6, "myriad marks damages enemy %s from consumed marks" % i)


func _check_pile_tutors(battle: Battle, enemy: Enemy) -> void:
	var character := battle.player_handler.character
	character.draw_pile.clear()
	character.draw_pile.add_card((load(STRIKE_PATH) as Card).duplicate(true) as Card)
	character.draw_pile.add_card((load(DEFEND_PATH) as Card).duplicate(true) as Card)
	character.draw_pile.add_card((load(BLOOD_WARD_PATH) as Card).duplicate(true) as Card)
	var hand_before := battle.battle_ui.hand.get_child_count()
	var shadow_step := (load(SHADOW_STEP_PATH) as Card).duplicate(true) as CultivationCard
	shadow_step.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 2, "shadow step tutors two skills into hand")
	_check(character.draw_pile.cards.size() == 1 and character.draw_pile.cards[0].type == Card.Type.ATTACK, "shadow step leaves nonmatching attacks in draw pile")

	character.discard.clear()
	character.discard.add_card((load(DEFEND_PATH) as Card).duplicate(true) as Card)
	character.discard.add_card((load(STRIKE_PATH) as Card).duplicate(true) as Card)
	var recent_skill := (load(BLOOD_WARD_PATH) as Card).duplicate(true) as Card
	character.discard.add_card(recent_skill)
	var mark := (load(SOUL_MARK_PATH) as Status).duplicate() as Status
	mark.stacks = 2
	enemy.status_handler.add_status(mark)
	hand_before = battle.battle_ui.hand.get_child_count()
	var renewal := (load(SOUL_LAMP_RENEWAL_PATH) as Card).duplicate(true) as CultivationCard
	renewal.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 1, "soul lamp renewal returns one skill to hand")
	_check(not character.discard.cards.has(recent_skill), "soul lamp renewal takes the most recent matching discard")
	_check(character.discard.cards.size() == 2, "soul lamp renewal leaves older and nonmatching discards")

	character.exhaust_pile.clear()
	var older_exhaust := (load(STRIKE_PATH) as Card).duplicate(true) as Card
	var recent_exhaust := (load(DEFEND_PATH) as Card).duplicate(true) as Card
	var rebirth := (load(FLESH_REBIRTH_PATH) as Card).duplicate(true) as CultivationCard
	character.exhaust_pile.add_card(older_exhaust)
	character.exhaust_pile.add_card(recent_exhaust)
	# 打出消耗牌时 card_played 信号先把自身放入消耗区，再执行卡牌效果。
	character.exhaust_pile.add_card(rebirth)
	hand_before = battle.battle_ui.hand.get_child_count()
	var health_before := maxi(battle.player.stats.max_health - 12, 1)
	battle.player.stats.health = health_before
	rebirth.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 1, "flesh rebirth retrieves one exhausted card")
	_check(not character.exhaust_pile.cards.has(recent_exhaust), "flesh rebirth retrieves the most recent prior exhaust")
	_check(character.exhaust_pile.cards.has(rebirth), "flesh rebirth excludes itself from exhaust retrieval")
	_check(character.exhaust_pile.cards.has(older_exhaust), "flesh rebirth leaves older exhausted cards in place")
	_check(battle.player.stats.health == mini(health_before + 8, battle.player.stats.max_health), "flesh rebirth still heals for eight")


func _check_exhaust_guard_engine(battle: Battle) -> void:
	var membrane := (load(BLOOD_MEMBRANE_PATH) as Card).duplicate(true) as CultivationCard
	membrane.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	var block_before := battle.player.stats.block
	var consumable := Card.new()
	consumable.id = "exhaust_guard_smoke"
	consumable.exhausts = true
	battle.player_handler._on_card_played(consumable)
	_check(battle.player.stats.block == block_before + 2, "blood membrane grants block when a card is exhausted")
	_check(battle.player_handler.character.exhaust_pile.cards.has(consumable), "exhaust guard trigger preserves normal exhaust destination")
	_check(battle.battle_ui.exhaust_pile_button.card_pile == battle.player_handler.character.exhaust_pile, "battle UI tracks the active exhaust pile")
	battle.battle_ui.exhaust_pile_button.pressed.emit()
	await get_tree().process_frame
	_check(battle.battle_ui.exhaust_pile_view.visible, "exhaust pile viewer opens from its button")
	_check(battle.battle_ui.exhaust_pile_view.cards.get_child_count() == battle.player_handler.character.exhaust_pile.cards.size(), "exhaust pile viewer shows every exhausted card")
	battle.battle_ui.exhaust_pile_view.hide()


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
		print("DEMONIC_CARD_SUITE_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("DEMONIC_CARD_SUITE_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("DEMONIC_CARD_SUITE_SMOKE_TIMEOUT: %s" % current_step)
	get_tree().paused = false
	get_tree().quit(2)
