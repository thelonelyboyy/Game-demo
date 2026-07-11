extends Node

const CAMPFIRE_SCENE_PATH := "res://scenes/campfire/campfire.tscn"
const CHARACTER_PATH := "res://characters/demonic_cultivator/demonic_cultivator.tres"

var failures: PackedStringArray = []
var removal_signal_seen := false


func _ready() -> void:
	get_tree().create_timer(12.0, true).timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var packed := load(CAMPFIRE_SCENE_PATH) as PackedScene
	var character_resource := load(CHARACTER_PATH) as CharacterStats
	_check(packed != null and character_resource != null, "campfire choice resources load")
	if not packed or not character_resource:
		_finish()
		return

	var character := character_resource.create_instance() as CharacterStats
	var campfire := packed.instantiate() as Campfire
	add_child(campfire)
	await get_tree().process_frame
	campfire.setup(character, RunStats.new())
	_check(campfire._can_blood_refine(), "demonic starter deck can use blood refinement")
	_check(not campfire.blood_refine_button.disabled, "blood refinement button is enabled")

	var initial_deck_size := character.deck.cards.size()
	var initial_max_health := character.max_health
	Events.campfire_card_removed.connect(_on_card_removed, CONNECT_ONE_SHOT)
	campfire._on_blood_refine_button_pressed()
	await get_tree().process_frame
	_check(campfire.active_card_remove != null, "blood refinement opens card removal")
	if campfire.active_card_remove:
		var card := character.deck.cards[0]
		campfire.active_card_remove._update_selection(card)
		campfire.active_card_remove._on_remove_button_pressed()
		await get_tree().process_frame

	_check(character.deck.cards.size() == initial_deck_size - 1, "blood refinement removes one selected card")
	_check(character.max_health == initial_max_health - Campfire.BLOOD_REFINE_MAX_HEALTH_COST, "blood refinement costs five max health")
	_check(removal_signal_seen, "blood refinement emits campfire removal signal")

	character.max_health = Campfire.BLOOD_REFINE_MAX_HEALTH_COST
	_check(not campfire._can_blood_refine(), "blood refinement cannot reduce max health below one")
	character.max_health = initial_max_health
	while character.deck.cards.size() > 1:
		character.deck.remove_card(character.deck.cards.back())
	_check(not campfire._can_blood_refine(), "blood refinement preserves at least one card")

	campfire.queue_free()
	await get_tree().process_frame
	_finish()


func _on_card_removed(_character: CharacterStats, _card: Card, cost: int) -> void:
	removal_signal_seen = cost == Campfire.BLOOD_REFINE_MAX_HEALTH_COST


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CAMPFIRE_CHOICES_SMOKE_OK")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("CAMPFIRE_CHOICES_SMOKE: %s" % failure)
	get_tree().quit(1)


func _on_watchdog_timeout() -> void:
	push_error("CAMPFIRE_CHOICES_SMOKE: timed out")
	get_tree().quit(1)
