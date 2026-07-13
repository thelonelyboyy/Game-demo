extends Node

const GROWTH_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres"
const DISCARD_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_blood_repay.tres"
const EXHAUST_CARD_PATH := "res://characters/demonic_cultivator/cards/engines/demon_sha_return.tres"
const DISCOVER_CARD_PATH := "res://characters/demonic_cultivator/cards/demon_forbidden_archive.tres"
const DRAFT_POOL_PATH := "res://characters/demonic_cultivator/demonic_cultivator_draftable_cards.tres"
const DEMONIC_CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"
const DRAFT_POOL_PATHS := [
	DRAFT_POOL_PATH,
	"res://characters/body_cultivator/body_cultivator_draftable_cards.tres",
	"res://characters/sword_cultivator/sword_cultivator_draftable_cards.tres",
	"res://characters/beastmaster/beastmaster_draftable_cards.tres",
]
const NEW_COMMON_CARD_PATHS := [
	"res://common_cards/circulating_breath.tres",
	"res://common_cards/flowing_cloud_guard.tres",
	"res://common_cards/momentum_pursuit.tres",
	"res://common_cards/embers_return.tres",
	"res://common_cards/returning_light.tres",
	"res://common_cards/discard_aegis.tres",
	"res://common_cards/ash_heart_guard.tres",
	"res://common_cards/spirit_stone_needle.tres",
]
const DISCOVERY_REQUEST_SCRIPT := preload("res://custom_resources/card_discovery_request.gd")
const NEW_DEMONIC_CARD_IDS := [
	"demon_blood_reversal",
	"demon_blood_debt",
	"demon_blood_forge_armor",
	"demon_sha_blade",
	"demon_seven_flame_cycle",
	"demon_soul_lamp_renewal",
	"demon_myriad_marks_return",
]

var failures := PackedStringArray()
var resolved_card_count := -1


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	_check_growth_card()
	_check_lifecycle_trigger_cards()
	_check_discover_card()
	_check_discovery_request()
	_check_card_reward_choices()
	_check_card_reward_tiers()
	_check_card_reward_archetype_synergy()
	_check_card_reward_chapter_upgrades()
	_check_demonic_pool_depth()
	_check_hero_skill_growth()
	_check_hand_size_limit()
	_check_exhaust_pile_lifecycle()
	_finish()


func _check_growth_card() -> void:
	var card := (load(GROWTH_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null and card.is_growth_card(), "growth card loads with growth tag")
	if not card or card.configured_effects.size() < 2:
		return

	var self_damage = card.configured_effects[0]
	var damage = card.configured_effects[1]
	_check(self_damage.amount == 2 and damage.amount == 7, "growth card starts with expected values")
	card.handle_lifecycle_trigger(Card.LifecycleTrigger.PLAYED, [], null)
	_check(self_damage.amount == 2, "growth excludes self-damage cost")
	_check(damage.amount == 9, "growth increases damage after play")
	for i in range(4):
		card.handle_lifecycle_trigger(Card.LifecycleTrigger.PLAYED, [], null)
	_check(damage.amount == 13 and card.growth_accumulated == 6, "growth respects combat cap")


func _check_lifecycle_trigger_cards() -> void:
	var discard_card := load(DISCARD_CARD_PATH) as CultivationCard
	_check(discard_card != null and discard_card.has_discard_trigger(), "discard trigger card has marker")
	_check(discard_card != null and discard_card.discard_trigger_effects.size() == 1, "discard trigger card has configured effect")
	if discard_card and not discard_card.discard_trigger_effects.is_empty():
		_check(discard_card.discard_trigger_effects[0].amount == 4, "discard trigger grants expected block")

	var exhaust_card := load(EXHAUST_CARD_PATH) as CultivationCard
	_check(exhaust_card != null and exhaust_card.has_exhaust_trigger(), "exhaust trigger card has marker")
	_check(exhaust_card != null and exhaust_card.exhaust_trigger_effects.size() == 1, "exhaust trigger card has configured effect")
	if exhaust_card and not exhaust_card.exhaust_trigger_effects.is_empty():
		_check(exhaust_card.exhaust_trigger_effects[0].amount == 1, "exhaust trigger grants expected mana")


func _check_discover_card() -> void:
	var card := (load(DISCOVER_CARD_PATH) as Card).duplicate(true) as CultivationCard
	_check(card != null, "discover card loads")
	if not card or card.configured_effects.is_empty():
		return

	var effect = card.configured_effects[0]
	_check(effect.card_pool != null and effect.card_pool.cards.size() == 7, "discover uses fixed seven-card pool")
	var choices: Array[Card] = effect._build_choices(null)
	_check(choices.size() == 3, "discover presents configured choice count")
	var ids := {}
	for choice: Card in choices:
		ids[choice.id] = true
		_check(not choice.is_temporary_card(), "discovered cards participate in discard cycle")
	_check(ids.size() == choices.size(), "discover choices are unique")

	_check(card.can_upgrade(), "discover card can upgrade")
	card.upgrade()
	_check(effect.amount == 2, "discover upgrade increases pick count")

	var draft_pool := load(DRAFT_POOL_PATH) as CardPile
	var found := false
	for draft_card: Card in draft_pool.cards:
		if draft_card and draft_card.id == card.id:
			found = true
			break
	_check(found, "discover card is in demonic draft pool")


func _check_discovery_request() -> void:
	var request = DISCOVERY_REQUEST_SCRIPT.new()
	request.completed.connect(_on_request_completed)
	var selected: Array[Card] = [load(DISCOVER_CARD_PATH) as Card]
	request.resolve(selected)
	request.resolve([])
	_check(request.resolved and resolved_card_count == 1, "discovery request resolves exactly once")


func _on_request_completed(selected_cards: Array[Card]) -> void:
	resolved_card_count = selected_cards.size()


func _check_card_reward_choices() -> void:
	var character_resource := load(DEMONIC_CHARACTER_PATH) as CharacterStats
	var reward := BattleReward.new()
	reward.character_stats = character_resource.create_instance()
	reward.run_stats = RunStats.new()
	for i in range(40):
		var choices := reward._generate_card_reward_choices()
		var ids := {}
		for card: Card in choices:
			ids[card.id] = true
		_check(choices.size() == reward.run_stats.card_rewards, "card reward returns configured choice count")
		_check(ids.size() == choices.size(), "card reward choices never repeat an id")

	reward.run_stats.card_reward_miss_streak = BattleReward.RARE_PITY_HARD_LIMIT
	var guaranteed_choices := reward._generate_card_reward_choices()
	_check(guaranteed_choices.any(func(card: Card): return card.rarity >= Card.Rarity.RARE), "hard pity guarantees a rare card")
	_check(reward.run_stats.card_reward_miss_streak == 0, "seeing a rare card resets pity")

	var common_card := load("res://characters/demonic_cultivator/cards/demon_strike.tres") as Card
	reward._update_card_reward_pity([common_card])
	_check(reward.run_stats.card_reward_miss_streak == 1, "all-low-rarity reward increments pity")
	reward._setup_card_chances()
	_check(reward.card_rarity_weights[Card.Rarity.COMMON] == reward.run_stats.common_weight - BattleReward.RARE_PITY_WEIGHT_PER_MISS, "pity shifts common weight toward rare")

	var reward_button := RewardButton.new()
	reward.card_reward_choices = [common_card]
	var gold_before_skip := reward.run_stats.gold
	reward._on_card_reward_taken(null, reward_button)
	_check(reward.card_reward_choices.is_empty(), "skipping consumes cached card choices")
	_check(reward.run_stats.gold == gold_before_skip + BattleReward.CARD_REWARD_SKIP_GOLD, "skipping a card reward grants ten gold")
	reward._on_card_reward_taken(null, reward_button)
	_check(reward.run_stats.gold == gold_before_skip + BattleReward.CARD_REWARD_SKIP_GOLD, "consumed card reward cannot grant skip gold twice")
	_check(reward_button.is_queued_for_deletion(), "skipping consumes the card reward button")
	reward_button.free()
	reward.free()


func _check_card_reward_tiers() -> void:
	var character_resource := load(DEMONIC_CHARACTER_PATH) as CharacterStats
	var reward := BattleReward.new()
	reward.character_stats = character_resource.create_instance()
	reward.run_stats = RunStats.new()

	reward.card_reward_tier = BattleReward.CardRewardTier.ELITE
	var elite_choices := reward._generate_card_reward_choices()
	_check(elite_choices.any(func(card: Card): return card.rarity >= Card.Rarity.UNCOMMON), "elite rewards guarantee at least one uncommon card")
	_check(reward._get_card_reward_subtext().contains("蓝卡"), "elite reward copy explains its quality floor")

	reward.card_reward_tier = BattleReward.CardRewardTier.BOSS
	var boss_choices := reward._generate_card_reward_choices()
	_check(boss_choices.any(func(card: Card): return card.rarity >= Card.Rarity.RARE), "boss rewards guarantee at least one rare card")
	_check(reward._get_card_reward_subtext().contains("金卡"), "boss reward copy explains its quality floor")
	reward.free()


func _check_card_reward_archetype_synergy() -> void:
	var reward := BattleReward.new()
	reward.character_stats = CharacterStats.new()
	reward.character_stats.deck = CardPile.new()
	for i in range(6):
		var support := Card.new()
		support.id = "soul_support_%s" % i
		support.mechanic_tags = PackedStringArray(["魂印"])
		reward.character_stats.deck.add_card(support)
	var soul_candidate := Card.new()
	soul_candidate.id = "soul_candidate"
	soul_candidate.mechanic_tags = PackedStringArray(["魂印"])
	var neutral_candidate := Card.new()
	neutral_candidate.id = "neutral_candidate"
	_check(is_equal_approx(reward._get_card_synergy_weight(neutral_candidate), 1.0), "neutral rewards keep base weight")
	_check(is_equal_approx(reward._get_card_synergy_weight(soul_candidate), 1.9), "archetype reward bonus reaches its configured cap")
	var blood_candidate := Card.new()
	blood_candidate.id = "blood_candidate"
	blood_candidate.mechanic_tags = PackedStringArray(["献祭"])
	_check(is_equal_approx(reward._get_card_synergy_weight(blood_candidate), 1.0), "unbuilt archetypes remain available at base weight")
	reward.free()


func _check_card_reward_chapter_upgrades() -> void:
	var source := load("res://characters/demonic_cultivator/cards/demon_strike.tres") as Card
	var reward := BattleReward.new()
	reward.run_stats = RunStats.new()
	var chapter_one := source.duplicate(true) as Card
	reward.run_stats.current_chapter = 1
	_check(not reward._maybe_upgrade_reward_card(chapter_one, 0.0) and not chapter_one.upgraded, "chapter one rewards never arrive upgraded")
	var chapter_two_hit := source.duplicate(true) as Card
	reward.run_stats.current_chapter = 2
	_check(reward._maybe_upgrade_reward_card(chapter_two_hit, 0.149) and chapter_two_hit.upgraded, "chapter two upgrades rolls below fifteen percent")
	var chapter_two_miss := source.duplicate(true) as Card
	_check(not reward._maybe_upgrade_reward_card(chapter_two_miss, 0.15) and not chapter_two_miss.upgraded, "chapter two keeps rolls at the boundary unupgraded")
	var chapter_three_hit := source.duplicate(true) as Card
	reward.run_stats.current_chapter = 3
	_check(reward._maybe_upgrade_reward_card(chapter_three_hit, 0.299) and chapter_three_hit.upgraded, "chapter three upgrades rolls below thirty percent")
	var chapter_three_miss := source.duplicate(true) as Card
	_check(not reward._maybe_upgrade_reward_card(chapter_three_miss, 0.30) and not chapter_three_miss.upgraded, "chapter three keeps rolls at the boundary unupgraded")
	reward.free()


func _check_demonic_pool_depth() -> void:
	var draft_pool := load(DRAFT_POOL_PATH) as CardPile
	_check(draft_pool != null, "demonic draft pool loads for depth check")
	if not draft_pool:
		return
	var unique_ids := {}
	var found_new := {}
	for card: Card in draft_pool.cards:
		if not card:
			continue
		unique_ids[card.id] = true
		if NEW_DEMONIC_CARD_IDS.has(card.id):
			found_new[card.id] = true
			var upgraded := card.duplicate(true) as Card
			_check(upgraded.can_upgrade(), "%s can upgrade" % card.id)
			_check(upgraded.upgrade(), "%s upgrade resolves" % card.id)
	_check(unique_ids.size() == 84, "demonic draft pool contains eighty-four unique cards")
	_check(unique_ids.has("demon_shadow_reenactment"), "demonic draft pool includes shadow reenactment")
	_check(found_new.size() == NEW_DEMONIC_CARD_IDS.size(), "all seven construction bridge cards are in draft pool")

	var common_ids := {}
	for path: String in NEW_COMMON_CARD_PATHS:
		var card := load(path) as Card
		_check(card != null, "%s common card loads" % path)
		if not card:
			continue
		common_ids[card.id] = true
		_check(card.get_profession() == Card.Profession.COMMON, "%s remains profession-neutral" % card.id)
		var upgraded := card.duplicate(true) as Card
		_check(upgraded.can_upgrade() and upgraded.upgrade(), "%s common card can upgrade" % card.id)
	_check(common_ids.size() == 8, "eight new common construction cards have unique ids")

	for pool_path: String in DRAFT_POOL_PATHS:
		var profession_pool := load(pool_path) as CardPile
		_check(profession_pool != null, "%s draft pool loads" % pool_path)
		if not profession_pool:
			continue
		var pool_ids := {}
		for card: Card in profession_pool.cards:
			if card:
				pool_ids[card.id] = true
		for common_id: String in common_ids:
			_check(pool_ids.has(common_id), "%s includes common card %s" % [pool_path, common_id])


func _check_hero_skill_growth() -> void:
	var character_resource := load(DEMONIC_CHARACTER_PATH) as CharacterStats
	var handler := PlayerHandler.new()
	handler.character = character_resource.create_instance()
	for stage in range(1, 4):
		handler.character.hero_skill_stage = stage
		var generated := handler._create_demonic_hero_skill_card()
		_check(generated != null and generated.is_temporary_card(), "hero skill stage %s creates a temporary card" % stage)
		if not generated:
			continue
		_check(generated.type != Card.Type.ATTACK, "hero skill stage %s excludes attacks" % stage)
		_check(not generated.upgraded if stage == 1 else (generated.upgraded or not generated.can_upgrade()), "hero skill stage %s applies expected upgrade state" % stage)
		var base_cost := generated.cost + generated.temporary_cost_reduction
		var expected_reduction := mini(1, base_cost) if stage >= 3 else 0
		_check(generated.temporary_cost_reduction == expected_reduction, "hero skill stage %s applies expected temporary discount" % stage)
	_check(handler._get_hero_skill_self_damage() == 1, "hero skill final stage lowers self damage")
	handler.free()


func _check_hand_size_limit() -> void:
	var full_hand := Hand.new()
	for _i in Hand.MAX_HAND_SIZE:
		full_hand.add_child(Node.new())
	_check(full_hand.is_full() and full_hand.available_slots() == 0, "hand caps at ten cards")

	var handler := PlayerHandler.new()
	handler.hand = full_hand
	handler.character = CharacterStats.new()
	handler.character.draw_pile = CardPile.new()
	handler.character.discard = CardPile.new()
	handler.battle_running = true
	var queued_draw := Card.new()
	queued_draw.id = "queued_draw"
	handler.character.draw_pile.add_card(queued_draw)
	handler.draw_card()
	_check(handler.character.draw_pile.cards.size() == 1, "drawing with a full hand leaves the draw pile unchanged")

	var discovered := Card.new()
	discovered.id = "overflow_discovery"
	handler.add_discovered_cards_to_hand([discovered])
	_check(handler.character.discard.cards.size() == 1 and handler.character.discard.cards[0] == discovered, "discovery overflow enters the discard pile")

	full_hand.free()
	handler.hand = null
	handler.free()


func _check_exhaust_pile_lifecycle() -> void:
	var handler := PlayerHandler.new()
	handler.character = CharacterStats.new()
	handler.character.draw_pile = CardPile.new()
	handler.character.discard = CardPile.new()
	handler.character.exhaust_pile = CardPile.new()
	handler.battle_running = true
	var consumable := Card.new()
	consumable.id = "smoke_consumable"
	consumable.exhausts = true
	handler._on_card_played(consumable)
	_check(handler.character.exhaust_pile.cards.has(consumable), "played consumable enters exhaust pile")
	_check(handler.character.discard.cards.is_empty(), "played consumable never enters discard pile")
	var power := Card.new()
	power.id = "smoke_power"
	power.type = Card.Type.POWER
	handler._on_card_played(power)
	_check(not handler.character.exhaust_pile.cards.has(power), "played power stays out of exhaust pile")
	var temporary := Card.new()
	temporary.id = "smoke_temporary"
	temporary.temporary = true
	temporary.exhausts = true
	handler._on_card_played(temporary)
	_check(not handler.character.exhaust_pile.cards.has(temporary), "played temporary card is removed instead of exhausted")
	var regular := Card.new()
	regular.id = "smoke_regular"
	regular.type = Card.Type.SKILL
	handler._on_card_played(regular)
	_check(handler.character.discard.cards.has(regular), "played regular skill still enters discard pile")
	handler.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CARD_MECHANICS_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CARD_MECHANICS_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
