extends Object

const SAVE_PATH := "user://defeat_legacy.cfg"
const SECTION := "legacy"
const RELIC_PATHS_KEY := "relic_paths"


static func remember_failed_run(run_relics: Array[Relic], starting_relic: Relic = null) -> void:
	var relic_paths: Array[String] = []
	var seen_ids := {}
	var starting_relic_id := starting_relic.id if starting_relic else ""

	for relic: Relic in run_relics:
		if not relic:
			continue
		if relic.starter_relic:
			continue
		if not starting_relic_id.is_empty() and relic.id == starting_relic_id:
			continue
		if relic.id.is_empty() or seen_ids.has(relic.id):
			continue
		if relic.resource_path.is_empty():
			continue

		seen_ids[relic.id] = true
		relic_paths.append(relic.resource_path)

	if relic_paths.is_empty():
		delete_data()
		return

	var config := ConfigFile.new()
	config.set_value(SECTION, RELIC_PATHS_KEY, relic_paths)
	var err := config.save(SAVE_PATH)
	assert(err == OK, "Couldn't save defeat legacy!")


static func load_relics() -> Array[Relic]:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return []

	var raw_paths: Array = config.get_value(SECTION, RELIC_PATHS_KEY, [])
	var relics: Array[Relic] = []
	var seen_ids := {}

	for path_value in raw_paths:
		var path := String(path_value)
		if path.is_empty() or not ResourceLoader.exists(path):
			continue

		var relic := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Relic
		if not relic or relic.id.is_empty() or seen_ids.has(relic.id):
			continue

		seen_ids[relic.id] = true
		relics.append(relic)

	if relics.is_empty():
		delete_data()

	return relics


static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
