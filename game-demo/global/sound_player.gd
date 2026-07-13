extends Node


func play(audio: AudioStream, single := false, volume_db := 0.0) -> void:
	if not audio:
		return

	if single:
		for player: AudioStreamPlayer in get_children():
			if player.playing and player.stream == audio:
				player.volume_db = volume_db
				return
		stop()

	for player: AudioStreamPlayer in get_children():
		if not player.playing:
			player.stream = audio
			player.volume_db = volume_db
			player.play()
			break


func stop() -> void:
	for player: AudioStreamPlayer in get_children():
		player.stop()
