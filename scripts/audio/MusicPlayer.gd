extends Node

# Simple music player that loops through available tracks
class_name MusicPlayer

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@export var music_folder: String = "res://assets/audio/ws4kp-music"
@export var auto_play: bool = true
@export var shuffle: bool = false

var music_files: Array = []
var current_track_index: int = 0
var is_muted: bool = false
var original_volume: float = 0.0

signal track_changed(track_name: String)
signal muted_changed(is_muted: bool)

func _ready():
	_scan_music_folder()
	if auto_play and music_files.size() > 0:
		play_track(0)

func _scan_music_folder():
	"""Scan the music folder for .mp3 and .ogg files"""
	music_files.clear()

	var dir = DirAccess.open(music_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".mp3") or file_name.ends_with(".ogg"):
				music_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("Found ", music_files.size(), " music files: ", music_files)

func play_track(index: int):
	"""Play a specific track by index"""
	if index < 0 or index >= music_files.size():
		return

	current_track_index = index
	var track_path = music_folder + "/" + music_files[index]

	if ResourceLoader.exists(track_path):
		var stream = load(track_path)
		if stream:
			audio_player.stream = stream
			audio_player.play()
			track_changed.emit(music_files[index])
			print("Playing: ", music_files[index])
		else:
			print("Failed to load track: ", track_path)
	else:
		print("Track not found: ", track_path)

func play_next():
	"""Play the next track"""
	if music_files.size() == 0:
		return

	if shuffle:
		current_track_index = randi() % music_files.size()
	else:
		current_track_index = (current_track_index + 1) % music_files.size()

	play_track(current_track_index)

func play_previous():
	"""Play the previous track"""
	if music_files.size() == 0:
		return

	if shuffle:
		current_track_index = randi() % music_files.size()
	else:
		current_track_index = (current_track_index - 1 + music_files.size()) % music_files.size()

	play_track(current_track_index)

func toggle_mute():
	"""Toggle mute on/off"""
	is_muted = !is_muted

	if is_muted:
		original_volume = audio_player.volume_db
		audio_player.volume_db = -80.0  # Very quiet but not completely silent
	else:
		audio_player.volume_db = original_volume

	muted_changed.emit(is_muted)
	print("Music muted: ", is_muted)

func set_volume(volume_db: float):
	"""Set the volume in dB"""
	if not is_muted:
		audio_player.volume_db = volume_db
	else:
		original_volume = volume_db

func stop():
	"""Stop playback"""
	audio_player.stop()

func pause():
	"""Pause playback"""
	audio_player.stream_paused = true

func resume():
	"""Resume playback"""
	audio_player.stream_paused = false

func is_playing() -> bool:
	"""Check if music is currently playing"""
	return audio_player.playing

func get_current_track_name() -> String:
	"""Get the name of the currently playing track"""
	if current_track_index >= 0 and current_track_index < music_files.size():
		return music_files[current_track_index]
	return ""

func _on_audio_stream_player_finished():
	"""Called when current track finishes - play next track"""
	play_next()
