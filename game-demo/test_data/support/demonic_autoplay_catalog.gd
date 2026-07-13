class_name DemonicAutoplayCatalog
extends RefCounted

const BASIC_STRIKE := "res://characters/demonic_cultivator/cards/demon_strike.tres"
const BASIC_DEFEND := "res://characters/demonic_cultivator/cards/demon_defend.tres"

const BASELINE_ENCOUNTERS := [
	{"id": "bronze_puppet", "tier": "normal", "path": "res://battles/demo_n_bronze_puppet.tres", "max_turns": 12},
	{"id": "iron_golem", "tier": "elite", "path": "res://battles/demo_e_iron_golem.tres", "max_turns": 16},
	{"id": "bone_dragon", "tier": "boss", "path": "res://battles/demo_b_bone_dragon.tres", "max_turns": 20},
]

const BOSS_MATRIX := [
	{"id": "bone_dragon", "chapter": 1, "upgrade_count": 0, "path": "res://battles/demo_b_bone_dragon.tres", "max_turns": 22},
	{"id": "abyssal_sword_soul", "chapter": 2, "upgrade_count": 4, "path": "res://battles/demo_b_sword_soul.tres", "max_turns": 24},
	{"id": "underworld_judge", "chapter": 3, "upgrade_count": 8, "path": "res://battles/demo_b_underworld_judge.tres", "max_turns": 26},
]

const DECKS := {
	"blood": [
		BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_rite_slash.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_ward.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_ward.tres",
		"res://characters/demonic_cultivator/cards/demon_blood_forge_armor.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/demon_desperate_burst.tres",
		"res://characters/demonic_cultivator/cards/demon_desperate_burst.tres",
		"res://characters/demonic_cultivator/cards/demon_flesh_rebirth.tres",
		"res://characters/demonic_cultivator/cards/demon_sha_blade.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_blood_qi_guard.tres",
	],
	"soul": [
		BASIC_STRIKE, BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/soul_drain.tres",
		"res://characters/demonic_cultivator/cards/soul_drain.tres",
		"res://characters/demonic_cultivator/cards/demon_soul_devour_claw.tres",
		"res://characters/demonic_cultivator/cards/demon_soul_devour_claw.tres",
		"res://characters/demonic_cultivator/cards/demon_shatter_soul_seal.tres",
		"res://characters/demonic_cultivator/cards/demon_shatter_soul_seal.tres",
		"res://characters/demonic_cultivator/cards/phase3/demon_soul_armor.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_soul_mark_sense.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_soul_rite.tres",
	],
	"flame": [
		BASIC_STRIKE, BASIC_DEFEND, BASIC_DEFEND,
		"res://characters/demonic_cultivator/cards/demon_flame_blue.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_green.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_yellow.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_purple.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_white.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_black.tres",
		"res://characters/demonic_cultivator/cards/demon_flame_red.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_flame_continuity.tres",
		"res://characters/demonic_cultivator/cards/engines/demon_flame_refining.tres",
	],
}

const RELICS := {
	"blood": [
		"res://relics/demon_blood_crucible.tres",
		"res://relics/demon_blood_tally.tres",
		"res://relics/sacrifice_blade.tres",
		"res://relics/demon_blood_pact_crown.tres",
	],
	"soul": [
		"res://relics/demon_soul_bell.tres",
		"res://relics/demon_soul_censer.tres",
		"res://relics/demon_wraith_banner.tres",
	],
	"flame": [
		"res://relics/demon_flame_lantern.tres",
		"res://relics/demon_flame_wheel_core.tres",
		"res://relics/demon_ash_furnace.tres",
	],
}
