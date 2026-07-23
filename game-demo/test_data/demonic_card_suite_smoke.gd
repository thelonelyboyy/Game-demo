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
const HUNDRED_GHOSTS_PATH := "res://characters/demonic_cultivator/cards/phase3/demon_hundred_ghosts.tres"
const TEN_THOUSAND_SACRIFICE_PATH := "res://characters/demonic_cultivator/cards/phase3/demon_ten_thousand_sacrifice.tres"
const CIRCULATING_BREATH_PATH := "res://common_cards/circulating_breath.tres"
const FLOWING_CLOUD_GUARD_PATH := "res://common_cards/flowing_cloud_guard.tres"
const MOMENTUM_PURSUIT_PATH := "res://common_cards/momentum_pursuit.tres"
const EMBERS_RETURN_PATH := "res://common_cards/embers_return.tres"
const RETURNING_LIGHT_PATH := "res://common_cards/returning_light.tres"
const DISCARD_AEGIS_PATH := "res://common_cards/discard_aegis.tres"
const ASH_HEART_GUARD_PATH := "res://common_cards/ash_heart_guard.tres"
const SPIRIT_STONE_NEEDLE_PATH := "res://common_cards/spirit_stone_needle.tres"
const SHADOW_REENACTMENT_PATH := "res://characters/demonic_cultivator/cards/demon_shadow_reenactment.tres"
const CALAMITY_EMBRYO_PATH := "res://characters/demonic_cultivator/cards/demon_calamity_embryo.tres"
const LURKING_SOUL_CURSE_PATH := "res://characters/demonic_cultivator/cards/demon_lurking_soul_curse.tres"
const BURN_IMPURITY_PATH := "res://characters/demonic_cultivator/cards/demon_burn_impurity.tres"
const ASH_BARRIER_PATH := "res://characters/demonic_cultivator/cards/demon_ash_barrier.tres"
const BLOOD_DEBT_CURSE_PATH := "res://common_cards/status/blood_debt_curse.tres"
const KARMIC_FIRE_CURSE_PATH := "res://common_cards/status/karmic_fire_curse.tres"
const HEART_DEMON_PATH := "res://common_cards/status/heart_demon.tres"
const UNDERWORLD_WRIT_PATH := "res://common_cards/status/underworld_writ.tres"
const TOXIN_PATH := "res://common_cards/toxin.tres"
const STRIKE_PATH := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const DEFEND_PATH := "res://characters/demonic_cultivator/cards/demon_defend.tres"
const BLOOD_WARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_ward.tres"
const BLOOD_QI_GUARD_PATH := "res://characters/demonic_cultivator/cards/engines/demon_blood_qi_guard.tres"
const SHA_QI_PATH := "res://statuses/sha_qi.tres"
const SOUL_MARK_PATH := "res://statuses/soul_mark.tres"

var failures: PackedStringArray = []
var current_step := "startup"


func _ready() -> void:
	get_tree().create_timer(15.0, true).timeout.connect(_on_watchdog_timeout)
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
		current_step = "count_scaling"
		await _check_count_scaling_cards(battle, enemies)
		current_step = "common_cards"
		await _check_common_card_combat(battle, enemies[0])
		current_step = "copy_previous"
		await _check_copy_previous_card(battle)
		current_step = "delayed_cast"
		await _check_delayed_cast(battle, enemies[0])
		current_step = "affliction_purge"
		await _check_affliction_purge(battle)
		current_step = "blood_debt"
		await _check_blood_debt(battle, enemies[0])
		current_step = "blood_qi_guard"
		await _check_blood_qi_guard(battle)
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


func _check_count_scaling_cards(battle: Battle, enemies: Array[Enemy]) -> void:
	Events.player_turn_started.emit()
	await get_tree().process_frame

	var filler_attack := Card.new()
	filler_attack.id = "count_filler_attack"
	filler_attack.type = Card.Type.ATTACK
	Events.card_played.emit(filler_attack)
	var filler_skill := Card.new()
	filler_skill.id = "count_filler_skill"
	filler_skill.type = Card.Type.SKILL
	Events.card_played.emit(filler_skill)

	var hundred_ghosts := (load(HUNDRED_GHOSTS_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(hundred_ghosts)
	var before_chain: Array[int] = []
	var chain_targets: Array[Node] = []
	for enemy: Enemy in enemies:
		before_chain.append(enemy.stats.health)
		chain_targets.append(enemy)
	hundred_ghosts.apply_effects(chain_targets, battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	for i in enemies.size():
		_check(before_chain[i] - enemies[i].stats.health == 6, "hundred ghosts deals two damage for each of three cards to enemy %s" % i)
	_check(battle.class_mechanic_handler.get_combat_card_count(0) == 3, "combat counter tracks all cards played this turn")
	_check(battle.class_mechanic_handler.get_combat_card_count(1) == 2, "combat counter separates attack cards")
	_check(battle.class_mechanic_handler.get_combat_card_count(2) == 1, "combat counter separates skill cards")
	Events.card_discarded.emit(filler_skill, Vector2.ZERO)
	_check(battle.class_mechanic_handler.get_combat_card_count(6) == 1, "combat counter tracks cards discarded this turn")

	var exhaust_before := battle.class_mechanic_handler.get_combat_card_count(5)
	for i in 3:
		var prep_exhaust := Card.new()
		prep_exhaust.id = "count_prep_exhaust_%s" % i
		prep_exhaust.exhausts = true
		Events.card_played.emit(prep_exhaust)
	var sacrifice := (load(TEN_THOUSAND_SACRIFICE_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(sacrifice)
	var expected_exhaust_count := battle.class_mechanic_handler.get_combat_card_count(5)
	_check(battle.class_mechanic_handler.get_combat_card_count(5) == expected_exhaust_count, "combat exhaust counter includes the finisher itself")
	var enemy_health_before := enemies[0].stats.health
	var player_health_before := battle.player.stats.health
	sacrifice.apply_effects([enemies[0]], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(enemy_health_before - enemies[0].stats.health == 10 + expected_exhaust_count * 4, "ten thousand sacrifice scales with combat exhaust count")
	_check(player_health_before - battle.player.stats.health == 6, "ten thousand sacrifice retains its self-damage cost")
	_check(battle.char_stats.exhaust_pile.cards.has(sacrifice), "ten thousand sacrifice enters the exhaust pile")
	_check(battle.class_mechanic_handler.get_combat_card_count(7) == battle.char_stats.discard.cards.size(), "combat counter exposes live discard pile size")
	_check(battle.class_mechanic_handler.get_combat_card_count(8) == battle.char_stats.exhaust_pile.cards.size(), "combat counter exposes live exhaust pile size")

	for enemy: Enemy in enemies:
		enemy.stats.health = enemy.stats.max_health
	battle.player.stats.health = player_health_before
	var sha_status := battle.player.status_handler.get_status("sha_qi")
	if sha_status:
		sha_status.stacks = 0
	Events.player_turn_started.emit()
	await get_tree().process_frame
	_check(battle.class_mechanic_handler.get_combat_card_count(0) == 0, "new turn resets cards-played count")
	_check(battle.class_mechanic_handler.get_combat_card_count(4) == 0, "new turn resets turn exhaust count")
	_check(battle.class_mechanic_handler.get_combat_card_count(6) == 0, "new turn resets discard count")
	_check(battle.class_mechanic_handler.get_combat_card_count(5) == expected_exhaust_count, "new turn preserves combat exhaust count")


func _check_common_card_combat(battle: Battle, enemy: Enemy) -> void:
	var initial_hand := battle.player_handler.hand.get_child_count()
	Events.player_turn_started.emit()
	await get_tree().process_frame


	var flowing_guard := (load(FLOWING_CLOUD_GUARD_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(flowing_guard)
	var block_before := battle.player.stats.block
	flowing_guard.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.player.stats.block == block_before + 2, "flowing cloud guard counts itself as the first card in the chain")

	var pursuit := (load(MOMENTUM_PURSUIT_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(pursuit)
	var enemy_health_before := enemy.stats.health
	pursuit.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(enemy_health_before - enemy.stats.health == 5, "momentum pursuit starts at five damage for the first attack")

	var draw_one := Card.new()
	draw_one.id = "common_cycle_draw"
	battle.char_stats.draw_pile.add_card_to_top(draw_one)
	var breath := (load(CIRCULATING_BREATH_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(breath)
	block_before = battle.player.stats.block
	var hand_before := battle.player_handler.hand.get_child_count()
	breath.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().create_timer(0.45).timeout
	_check(battle.player.stats.block == block_before + 5 and battle.player_handler.hand.get_child_count() == hand_before + 1, "circulating breath grants block and draws one")

	for i in 2:
		var draw_card := Card.new()
		draw_card.id = "embers_return_draw_%s" % i
		battle.char_stats.draw_pile.add_card_to_top(draw_card)
	var embers := (load(EMBERS_RETURN_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(embers)
	block_before = battle.player.stats.block
	hand_before = battle.player_handler.hand.get_child_count()
	embers.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().create_timer(0.45).timeout
	_check(battle.player.stats.block == block_before + 5 and battle.player_handler.hand.get_child_count() == hand_before + 3, "embers return is an exhaust burst that grants five block and draws three")
	_check(battle.char_stats.exhaust_pile.cards.has(embers), "embers return enters the exhaust pile")

	battle.player.stats.health = maxi(battle.player.stats.max_health - 12, 1)
	var returning_light := (load(RETURNING_LIGHT_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(returning_light)
	var health_before := battle.player.stats.health
	returning_light.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.player.stats.health == health_before + 5, "returning light heals five")
	_check(battle.char_stats.exhaust_pile.cards.has(returning_light), "returning light exhausts after use")

	var discard_count := battle.char_stats.discard.cards.size()
	var discard_aegis := (load(DISCARD_AEGIS_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(discard_aegis)
	block_before = battle.player.stats.block
	discard_aegis.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.player.stats.block == block_before + 4 + discard_count, "discard aegis scales with the visible discard pile and excludes itself")

	var exhaust_count := battle.class_mechanic_handler.get_combat_card_count(5)
	var ash_guard := (load(ASH_HEART_GUARD_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(ash_guard)
	block_before = battle.player.stats.block
	ash_guard.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.player.stats.block == block_before + 2 + exhaust_count * 2, "ash heart guard scales with combat exhaust count")

	var needle := (load(SPIRIT_STONE_NEEDLE_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(needle)
	enemy_health_before = enemy.stats.health
	needle.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(enemy_health_before - enemy.stats.health == 3, "spirit stone needle deals three damage for zero mana")
	_check(battle.char_stats.exhaust_pile.cards.has(needle), "spirit stone needle exhausts after use")

	enemy.stats.health = enemy.stats.max_health
	battle.player.stats.health = battle.player.stats.max_health
	for index in range(battle.player_handler.hand.get_child_count() - 1, initial_hand - 1, -1):
		battle.player_handler.hand.get_child(index).queue_free()
	await get_tree().process_frame
	Events.player_turn_started.emit()
	await get_tree().process_frame


func _check_copy_previous_card(battle: Battle) -> void:
	Events.player_turn_started.emit()
	await get_tree().process_frame
	var previous := (load(BLOOD_WARD_PATH) as Card).duplicate(true) as Card
	Events.card_played.emit(previous)
	var reenactment := (load(SHADOW_REENACTMENT_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(reenactment)
	var hand_before := battle.player_handler.hand.get_child_count()
	reenactment.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.player_handler.hand.get_child_count() == hand_before + 1, "shadow reenactment adds one copied card to hand")
	var copied_ui := battle.player_handler.hand.get_child(battle.player_handler.hand.get_child_count() - 1) as CardUI
	var copied := copied_ui.card if copied_ui else null
	_check(copied != null and copied.id == previous.id, "shadow reenactment copies the previous card identity")
	_check(copied != null and copied.is_temporary_card(), "shadow reenactment copy is temporary")
	_check(copied != null and copied.cost == maxi(previous.cost - 1, 0), "shadow reenactment discounts the copied card by one")
	_check(battle.char_stats.exhaust_pile.cards.has(reenactment), "shadow reenactment exhausts after use")
	if copied_ui:
		copied_ui.queue_free()
	await get_tree().process_frame
	Events.player_turn_started.emit()
	await get_tree().process_frame
	_check(battle.class_mechanic_handler.get_previous_card_played() == null, "new turn clears previous-card history")


func _check_delayed_cast(battle: Battle, enemy: Enemy) -> void:
	Events.player_turn_started.emit()
	await get_tree().process_frame
	var card := (load(CALAMITY_EMBRYO_PATH) as Card).duplicate(true) as CultivationCard
	var hand_before := battle.player_handler.hand.get_child_count()
	var health_before := battle.player.stats.max_health
	battle.player.stats.health = health_before
	battle.char_stats.mana = 0
	Events.card_played.emit(card)
	card.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.player.stats.health == health_before - 3, "calamity embryo pays self-damage immediately")
	_check(battle.char_stats.mana == 0 and battle.player_handler.hand.get_child_count() == hand_before, "calamity embryo does not grant its delayed rewards immediately")
	_check(battle.class_mechanic_handler.get_pending_delayed_effect_count() == 1, "calamity embryo queues one delayed cast")
	_check(battle.char_stats.exhaust_pile.cards.has(card), "calamity embryo enters the exhaust pile")

	for index in 2:
		var draw_card := Card.new()
		draw_card.id = "calamity_embryo_draw_%s" % index
		battle.char_stats.draw_pile.add_card_to_top(draw_card)
	Events.player_turn_started.emit()
	await get_tree().create_timer(0.7).timeout
	_check(battle.class_mechanic_handler.get_pending_delayed_effect_count() == 0, "next turn consumes the delayed cast")
	_check(battle.char_stats.mana == 2, "calamity embryo grants two mana next turn")
	_check(battle.player_handler.hand.get_child_count() == hand_before + 2, "calamity embryo draws two cards next turn")

	for index in range(battle.player_handler.hand.get_child_count() - 1, hand_before - 1, -1):
		battle.player_handler.hand.get_child(index).queue_free()
	await get_tree().process_frame

	var curse := (load(LURKING_SOUL_CURSE_PATH) as Card).duplicate(true) as CultivationCard
	enemy.stats.health = enemy.stats.max_health
	var enemy_health_before := enemy.stats.health
	var marks_before := enemy.status_handler.get_status_stacks("soul_mark")
	Events.card_played.emit(curse)
	curse.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(enemy.stats.health == enemy_health_before, "lurking soul curse does not hit its target immediately")
	_check(battle.class_mechanic_handler.get_pending_delayed_effect_count() == 1, "lurking soul curse preserves one delayed target")
	Events.player_turn_started.emit()
	await get_tree().create_timer(0.3).timeout
	_check(enemy_health_before - enemy.stats.health == 12, "lurking soul curse damages the preserved target next turn")
	_check(enemy.status_handler.get_status_stacks("soul_mark") == marks_before + 1, "lurking soul curse applies one soul mark next turn")
	_check(battle.class_mechanic_handler.get_pending_delayed_effect_count() == 0, "targeted delayed cast leaves no stale queue entry")

	var soul_mark := enemy.status_handler.get_status("soul_mark")
	if soul_mark:
		soul_mark.stacks = 0
	enemy.stats.health = enemy.stats.max_health
	battle.player.stats.health = battle.player.stats.max_health
	var sha_status := battle.player.status_handler.get_status("sha_qi")
	if sha_status:
		sha_status.stacks = 0
	await get_tree().process_frame


func _check_affliction_purge(battle: Battle) -> void:
	var hand := battle.player_handler.hand
	var hand_before := hand.get_child_count()
	var afflictions: Array[Card] = [
		(load(HEART_DEMON_PATH) as Card).duplicate(true) as Card,
		(load(UNDERWORLD_WRIT_PATH) as Card).duplicate(true) as Card,
		(load(TOXIN_PATH) as Card).duplicate(true) as Card,
	]
	for affliction: Card in afflictions:
		_check(hand.add_card(affliction, false), "%s enters the hand for purge testing" % affliction.id)
	var normal_card := (load(DEFEND_PATH) as Card).duplicate(true) as Card
	_check(hand.add_card(normal_card, false), "normal card enters the hand beside afflictions")
	await get_tree().process_frame
	_check(afflictions[2].is_status_card() and not afflictions[2].blocks_manual_play(), "toxin is a playable status card")

	var exhaust_before := battle.char_stats.exhaust_pile.cards.size()
	var block_before := battle.player.stats.block
	var purge := (load(BURN_IMPURITY_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(purge)
	purge.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	_check(battle.player.stats.block == block_before + 17, "burn impurity grants base block plus four per purged affliction")
	_check(battle.char_stats.exhaust_pile.cards.size() == exhaust_before + 3, "burn impurity exhausts all three afflictions")
	for affliction: Card in afflictions:
		_check(battle.char_stats.exhaust_pile.cards.has(affliction), "%s moves to the exhaust pile" % affliction.id)
	_check(hand.get_child_count() == hand_before + 1, "burn impurity leaves the normal card in hand")
	_check(battle.char_stats.discard.cards.has(purge), "burn impurity remains in the normal draw-discard cycle")

	for index in range(hand.get_child_count() - 1, hand_before - 1, -1):
		hand.get_child(index).queue_free()
	await get_tree().process_frame


func _check_blood_debt(battle: Battle, enemy: Enemy) -> void:
	var card := (load(BLOOD_DEBT_PATH) as Card).duplicate(true) as CultivationCard
	Events.player_self_damaged.emit(4)
	var before := enemy.stats.health
	card.apply_effects([enemy], battle.player.modifier_handler)
	await get_tree().create_timer(0.25).timeout
	_check(before - enemy.stats.health == 9, "blood debt converts current-turn self damage into attack damage")


func _check_blood_qi_guard(battle: Battle) -> void:
	var card := (load(BLOOD_QI_GUARD_PATH) as Card).duplicate(true) as CultivationCard
	card.apply_effects([battle.player], battle.player.modifier_handler)
	var block_before := battle.player.stats.block
	Events.player_self_damaged.emit(3)
	await get_tree().process_frame
	_check(battle.player.stats.block == block_before + 6, "blood qi guard grants block for each life lost to self damage")


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
	var battle_ui_listener := Callable(battle.battle_ui, "_on_card_discovery_requested")
	var restore_battle_ui_listener := Events.card_discovery_requested.is_connected(battle_ui_listener)
	if restore_battle_ui_listener:
		Events.card_discovery_requested.disconnect(battle_ui_listener)
	if not Events.card_discovery_requested.is_connected(_auto_resolve_pile_selection):
		Events.card_discovery_requested.connect(_auto_resolve_pile_selection)

	var character := battle.player_handler.character
	character.draw_pile.clear()
	character.draw_pile.add_card((load(STRIKE_PATH) as Card).duplicate(true) as Card)
	character.draw_pile.add_card((load(DEFEND_PATH) as Card).duplicate(true) as Card)
	character.draw_pile.add_card((load(BLOOD_WARD_PATH) as Card).duplicate(true) as Card)
	var hand_before := battle.battle_ui.hand.get_child_count()
	var shadow_step := (load(SHADOW_STEP_PATH) as Card).duplicate(true) as CultivationCard
	await shadow_step.apply_keyword_effects([battle.player])
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 2, "shadow step opens the draw pile and selects two cards")
	_check(character.draw_pile.cards.size() == 1, "shadow step leaves unselected cards in the draw pile")

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
	await renewal.apply_keyword_effects([battle.player])
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 1, "soul lamp renewal opens the discard pile and selects one card")
	_check(not character.discard.cards.has(recent_skill), "soul lamp renewal can select the most recent discard")
	_check(character.discard.cards.size() == 2, "soul lamp renewal leaves unselected discards")

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
	await rebirth.apply_keyword_effects([battle.player])
	await get_tree().process_frame
	_check(battle.battle_ui.hand.get_child_count() == hand_before + 1, "flesh rebirth retrieves one exhausted card")
	_check(not character.exhaust_pile.cards.has(recent_exhaust), "flesh rebirth retrieves the most recent prior exhaust")
	_check(character.exhaust_pile.cards.has(rebirth), "flesh rebirth excludes itself from exhaust retrieval")
	_check(character.exhaust_pile.cards.has(older_exhaust), "flesh rebirth leaves older exhausted cards in place")
	_check(battle.player.stats.health == mini(health_before + 8, battle.player.stats.max_health), "flesh rebirth still heals for eight")

	if Events.card_discovery_requested.is_connected(_auto_resolve_pile_selection):
		Events.card_discovery_requested.disconnect(_auto_resolve_pile_selection)
	if restore_battle_ui_listener and is_instance_valid(battle.battle_ui):
		Events.card_discovery_requested.connect(battle_ui_listener)


func _auto_resolve_pile_selection(request: CardDiscoveryRequest) -> void:
	var selected: Array[Card] = []
	for index in range(mini(request.picks, request.choices.size())):
		selected.append(request.choices[index])
	request.resolve(selected)


func _check_exhaust_guard_engine(battle: Battle) -> void:
	var membrane := (load(BLOOD_MEMBRANE_PATH) as Card).duplicate(true) as CultivationCard
	membrane.apply_effects([battle.player], battle.player.modifier_handler)
	await get_tree().process_frame
	var block_before := battle.player.stats.block
	var ash_barrier := (load(ASH_BARRIER_PATH) as Card).duplicate(true) as CultivationCard
	Events.card_played.emit(ash_barrier)
	ash_barrier.apply_effects([battle.player], battle.player.modifier_handler)
	_check(battle.player.stats.block == block_before + 6, "ash barrier grants four block and triggers two more from blood membrane")
	_check(battle.player_handler.character.exhaust_pile.cards.has(ash_barrier), "ash barrier enters the normal exhaust destination")
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
