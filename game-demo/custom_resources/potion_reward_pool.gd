class_name PotionRewardPool
extends RefCounted

enum RewardContext {STANDARD, ELITE, BOSS, SHOP}

const POTION_PATHS := [
	"res://potions/healing_pill.tres",
	"res://potions/qi_pill.tres",
	"res://potions/draw_talisman.tres",
	"res://potions/flame_talisman.tres",
	"res://potions/frost_talisman.tres",
	"res://potions/blood_rite_talisman.tres",
	"res://potions/greater_healing_pill.tres",
	"res://potions/jade_skin_pill.tres",
	"res://potions/spirit_surge_pill.tres",
	"res://potions/clarity_pill.tres",
	"res://potions/gold_body_pill.tres",
	"res://potions/true_essence_pill.tres",
	"res://potions/marrow_strength_pill.tres",
	"res://potions/sword_heart_pill.tres",
	"res://potions/demon_blood_pill.tres",
	"res://potions/beast_lure_pill.tres",
	"res://potions/thunder_talisman.tres",
	"res://potions/five_thunder_talisman.tres",
	"res://potions/expose_talisman.tres",
	"res://potions/bleed_talisman.tres",
	"res://potions/warding_talisman.tres",
	"res://potions/cloudstep_talisman.tres",
	"res://potions/qi_barrier_talisman.tres",
	"res://potions/sword_guard_talisman.tres",
	"res://potions/soul_snare_talisman.tres",
	"res://potions/soul_burst_talisman.tres",
]

const CONTEXT_WEIGHTS := {
	RewardContext.STANDARD: [
		[70.0, 25.0, 5.0, 0.0],
		[55.0, 35.0, 10.0, 0.0],
		[45.0, 38.0, 17.0, 0.0],
	],
	RewardContext.ELITE: [
		[35.0, 45.0, 20.0, 0.0],
		[25.0, 45.0, 30.0, 0.0],
		[15.0, 45.0, 40.0, 0.0],
	],
	RewardContext.BOSS: [
		[10.0, 40.0, 50.0, 0.0],
		[5.0, 35.0, 60.0, 0.0],
		[0.0, 30.0, 70.0, 0.0],
	],
	RewardContext.SHOP: [
		[55.0, 35.0, 10.0, 0.0],
		[45.0, 40.0, 15.0, 0.0],
		[35.0, 42.0, 23.0, 0.0],
	],
}


static func pick(available: Array[Potion], chapter := 1, context := RewardContext.STANDARD) -> Potion:
	var choices := pick_choices(available, 1, chapter, context)
	return choices[0] if not choices.is_empty() else null


static func pick_choices(
	available: Array[Potion],
	count: int,
	chapter := 1,
	context := RewardContext.STANDARD
) -> Array[Potion]:
	var remaining := available.duplicate()
	var choices: Array[Potion] = []
	for _i in mini(count, remaining.size()):
		var picked := _pick_weighted(remaining, chapter, context)
		if not picked:
			break
		choices.append(picked)
		remaining.erase(picked)
	return choices


static func _pick_weighted(available: Array[Potion], chapter: int, context: int) -> Potion:
	if available.is_empty():
		return null
	var context_key := context if CONTEXT_WEIGHTS.has(context) else RewardContext.STANDARD
	var weights: Array = CONTEXT_WEIGHTS[context_key][clampi(chapter, 1, 3) - 1]
	var candidates_by_rarity := {}
	var total_weight := 0.0
	for potion: Potion in available:
		if not candidates_by_rarity.has(potion.rarity):
			candidates_by_rarity[potion.rarity] = []
		candidates_by_rarity[potion.rarity].append(potion)
	for rarity in candidates_by_rarity:
		if rarity < weights.size():
			total_weight += float(weights[rarity])
	if total_weight <= 0.0:
		return RNG.array_pick_random(available) as Potion

	var roll := RNG.instance.randf_range(0.0, total_weight)
	var fallback: Potion
	for rarity in candidates_by_rarity:
		if rarity >= weights.size():
			continue
		var rarity_weight := float(weights[rarity])
		if rarity_weight <= 0.0:
			continue
		fallback = RNG.array_pick_random(candidates_by_rarity[rarity]) as Potion
		roll -= rarity_weight
		if roll <= 0.0:
			return fallback
	return fallback
