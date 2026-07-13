class_name Relic
extends Resource

enum Type {START_OF_TURN, START_OF_COMBAT, END_OF_TURN, END_OF_COMBAT, EVENT_BASED}
enum CharacterType {ALL, BODY, SWORD, DEMONIC, BEASTMASTER}
enum Rarity {COMMON, UNCOMMON, RARE, BOSS}

@export var relic_name: String
@export var id: String
@export var type: Type
@export var character_type: CharacterType
@export var rarity: Rarity = Rarity.COMMON
@export var starter_relic: bool = false
@export var exclusive_group := ""
@export var icon: Texture
@export_multiline var tooltip: String


func initialize_relic(_owner: RelicUI) -> void:
	pass


func activate_relic(_owner: RelicUI) -> void:
	pass


# This method should be implemented by event-based relics
# which connect to the EventBus to make sure that they are
# disconnected when a relic gets removed.
func deactivate_relic(_owner: RelicUI) -> void:
	pass


func get_tooltip() -> String:
	return tooltip


func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_relic:
		return false

	if character_type == CharacterType.ALL:
		return true

	return character_type == _get_character_type(character)


func _get_character_type(character: CharacterStats) -> CharacterType:
	if not character:
		return CharacterType.ALL

	var source_path := character.resource_path
	if source_path.is_empty() and character.draftable_cards:
		source_path = character.draftable_cards.resource_path
	if source_path.is_empty() and character.starting_deck:
		source_path = character.starting_deck.resource_path

	if source_path.contains("body_cultivator"):
		return CharacterType.BODY
	if source_path.contains("sword_cultivator"):
		return CharacterType.SWORD
	if source_path.contains("demonic_cultivator"):
		return CharacterType.DEMONIC
	if source_path.contains("beastmaster"):
		return CharacterType.BEASTMASTER
	return CharacterType.ALL
