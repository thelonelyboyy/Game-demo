class_name RunStartup
extends Resource

enum Type {NEW_RUN, CONTINUED_RUN}

@export var type: Type
@export var picked_character: CharacterStats
@export var selected_spirit_root: Card.Element = Card.Element.NONE
@export var spirit_root_declined := false
@export_range(0, RunStats.MAX_DIFFICULTY_LEVEL) var difficulty_level := 0
