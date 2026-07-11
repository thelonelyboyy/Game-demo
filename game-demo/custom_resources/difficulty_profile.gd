class_name DifficultyProfile
extends Resource

const PROFILE_PATH := "user://difficulty_profile.tres"
const MAX_LEVEL := 15

@export_range(0, MAX_LEVEL) var unlocked_level := 0
@export_range(0, MAX_LEVEL) var selected_level := 0


func select_level(level: int) -> int:
	selected_level = clampi(level, 0, unlocked_level)
	return selected_level


func record_victory(completed_level: int) -> bool:
	var previous := unlocked_level
	unlocked_level = maxi(unlocked_level, mini(completed_level + 1, MAX_LEVEL))
	if unlocked_level > previous:
		selected_level = unlocked_level
	else:
		selected_level = mini(selected_level, unlocked_level)
	return unlocked_level > previous


func save_data(path := PROFILE_PATH) -> Error:
	return ResourceSaver.save(self, path)


static func load_data(path := PROFILE_PATH) -> DifficultyProfile:
	if not FileAccess.file_exists(path):
		return DifficultyProfile.new()
	var profile := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as DifficultyProfile
	if not profile:
		return DifficultyProfile.new()
	profile.unlocked_level = clampi(profile.unlocked_level, 0, MAX_LEVEL)
	profile.selected_level = clampi(profile.selected_level, 0, profile.unlocked_level)
	return profile


static func record_completed_run(level: int, path := PROFILE_PATH) -> DifficultyProfile:
	var profile := load_data(path)
	profile.record_victory(level)
	var error := profile.save_data(path)
	if error != OK:
		push_warning("无法保存心魔难度进度：%s" % error)
	return profile
