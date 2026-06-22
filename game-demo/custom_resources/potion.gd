class_name Potion
extends Resource

## 符箓丹药：可携带的一次性消耗品（对标杀戮尖塔药水）。
## 效果直接复用卡牌的 CardEffect（configured_effects），使用时以 card=null 调用。

enum Category { TALISMAN, PILL }                  # 符箓 / 丹药
enum TargetKind { SELF, SINGLE_ENEMY, ALL_ENEMIES }

@export var id: String
@export var potion_name: String
@export var category: Category = Category.PILL
@export var rarity: Card.Rarity = Card.Rarity.COMMON
@export var target_kind: TargetKind = TargetKind.SELF
@export var usable_out_of_combat := false
@export var icon: Texture
@export_multiline var tooltip: String
@export var configured_effects: Array[Resource] = []
@export var character_type: Relic.CharacterType = Relic.CharacterType.ALL


func get_tooltip() -> String:
	return tooltip


func can_appear_as_reward(character: CharacterStats) -> bool:
	if character_type == Relic.CharacterType.ALL:
		return true
	return character_type == _get_character_type(character)


func _get_character_type(character: CharacterStats) -> Relic.CharacterType:
	if not character:
		return Relic.CharacterType.ALL
	var source_path := character.resource_path
	if source_path.is_empty() and character.starting_deck:
		source_path = character.starting_deck.resource_path
	if source_path.contains("body_cultivator"):
		return Relic.CharacterType.BODY
	if source_path.contains("sword_cultivator"):
		return Relic.CharacterType.SWORD
	if source_path.contains("demonic_cultivator"):
		return Relic.CharacterType.DEMONIC
	if source_path.contains("beastmaster"):
		return Relic.CharacterType.BEASTMASTER
	return Relic.CharacterType.ALL
