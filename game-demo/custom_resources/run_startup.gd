class_name RunStartup
extends Resource

enum Type {NEW_RUN, CONTINUED_RUN}

@export var type: Type
@export var picked_character: CharacterStats
@export var selected_spirit_root: Card.Element = Card.Element.NONE
