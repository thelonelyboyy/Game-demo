extends RefCounted

const CHOICE_NONE := 0
const CHOICE_AMPLIFY := 1
const CHOICE_SPLASH := 2

signal completed(choice: int)

var card: Card
var targets: Array[Node] = []
var modifiers: ModifierHandler
var selected_choice := CHOICE_NONE
var resolved := false


func resolve(choice: int) -> void:
	if resolved:
		return

	selected_choice = choice
	resolved = true
	completed.emit(choice)
