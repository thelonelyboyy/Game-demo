extends Node

const CODEX_SCENE_PATH := "res://scenes/ui/codex.tscn"

const CARD_ROOTS := {
	"通用": ["res://common_cards/"],
	"体修": ["res://characters/body_cultivator/cards/"],
	"剑修": ["res://characters/sword_cultivator/cards/"],
	"魔修": ["res://characters/demonic_cultivator/cards/"],
	"驭兽": ["res://characters/beastmaster/cards/"],
	"融合": ["res://fusion_cards/"],
}

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var codex_scene := load(CODEX_SCENE_PATH) as PackedScene
	_check(codex_scene != null, "codex scene loads")
	if not codex_scene:
		_finish()
		return

	var codex := codex_scene.instantiate()
	add_child(codex)
	await get_tree().process_frame

	_check(codex.all_cards.size() == _expected_card_count(), "codex scans all cards")
	_check(codex.all_relics.size() == _count_resources_of_type("res://relics/", Relic), "codex scans all relics")
	_check(codex.all_enemies.size() == _count_resources_of_type("res://enemies/", EnemyStats), "codex scans all enemies")
	_check(codex.all_statuses.size() == _count_resources_of_type("res://statuses/", Status), "codex scans all statuses")
	_check(codex.cards_by_scope.get("全部", []).size() == codex.all_cards.size(), "all card scope matches all cards")

	for scope_name: String in CARD_ROOTS.keys():
		var expected_count := _count_tres_in_roots(CARD_ROOTS[scope_name])
		_check(codex.cards_by_scope.get(scope_name, []).size() == expected_count, "%s card scope scans matching cards" % scope_name)

	var directory := codex.get_node("%Directory") as Tree
	var root := directory.get_root()
	_check(root != null, "codex directory has root")
	if root:
		var labels := _top_level_labels(root)
		_check(_has_label_prefix(labels, "卡牌"), "directory has card category")
		_check(_has_label_prefix(labels, "法宝"), "directory has relic category")
		_check(_has_label_prefix(labels, "怪物"), "directory has enemy category")
		_check(_has_label_prefix(labels, "词条"), "directory has status category")

	codex._show_card_detail(codex.all_cards[0] as Card)
	await get_tree().process_frame
	var detail_title := codex.get_node("%DetailTitle") as Label
	var detail_text := codex.get_node("%DetailText") as RichTextLabel
	_check(not detail_title.text.is_empty(), "card detail title renders")
	_check(not detail_text.text.is_empty(), "card detail text renders")

	_finish()


func _expected_card_count() -> int:
	var count := 0
	for roots: Array in CARD_ROOTS.values():
		count += _count_tres_in_roots(roots)
	return count


func _count_tres_in_roots(roots: Array) -> int:
	var count := 0
	for root: String in roots:
		count += _count_tres(root)
	return count


func _count_tres(path: String) -> int:
	var dir := DirAccess.open(path)
	if not dir:
		return 0

	var count := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var resource_path := path.path_join(file_name)
		if dir.current_is_dir():
			count += _count_tres(resource_path)
		elif file_name.ends_with(".tres"):
			count += 1

		file_name = dir.get_next()

	return count


func _count_resources_of_type(path: String, expected_type) -> int:
	var dir := DirAccess.open(path)
	if not dir:
		return 0

	var count := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var resource_path := path.path_join(file_name)
		if dir.current_is_dir():
			count += _count_resources_of_type(resource_path, expected_type)
		elif file_name.ends_with(".tres"):
			var resource := load(resource_path)
			if is_instance_of(resource, expected_type):
				count += 1

		file_name = dir.get_next()

	return count


func _top_level_labels(root: TreeItem) -> PackedStringArray:
	var labels := PackedStringArray()
	var child := root.get_first_child()
	while child:
		labels.append(child.get_text(0))
		child = child.get_next()
	return labels


func _has_label_prefix(labels: PackedStringArray, prefix: String) -> bool:
	for label: String in labels:
		if label.begins_with(prefix):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("CODEX_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error("CODEX_SMOKE_FAIL: %s" % failure)
		get_tree().quit(1)
