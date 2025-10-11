extends Node
# Global music facade to interact with the existing MusicPlayer scene autoloaded as GlobalMusic
# This script is optional; if the autoload is the MusicPlayer scene itself, we can attach this to it
# for extra helper methods and persistence.

var player  # Will hold the underlying MusicPlayer instance

signal music_started()
signal muted_changed(is_muted: bool)

func _ready():
	_resolve_player()
	_connect_signals()
	print("GlobalMusic initialized. Player valid:", player != null)

func _connect_signals():
	if player and player.has_signal("music_started"):
		if not player.music_started.is_connected(_on_music_started):
			player.music_started.connect(_on_music_started)
	if player and player.has_signal("muted_changed"):
		if not player.muted_changed.is_connected(_on_muted_changed):
			player.muted_changed.connect(_on_muted_changed)

func _on_music_started():
	music_started.emit()

func _on_muted_changed(is_muted: bool):
	muted_changed.emit(is_muted)

func _resolve_player():
	if player and is_instance_valid(player):
		return
	
	if has_node("MusicLogic"):
		var candidate = get_node("MusicLogic")
		print("MusicLogic node class: ", candidate.get_class())
		print("MusicLogic script: ", candidate.get_script())
		print("Has start_music: ", candidate.has_method("start_music"))
		
		# Check if it has the MusicPlayer methods instead of type check
		if candidate and candidate.has_method("start_music"):
			player = candidate
			print("GlobalMusic player resolved: ", player.get_class())
		else:
			print("ERROR: MusicLogic found but no start_music method")
			# Force call the script's _ready if it exists
			if candidate.has_method("_ready"):
				print("Calling MusicLogic._ready()...")
				candidate._ready()
	else:
		print("ERROR: No MusicLogic child node found")
		var child_names = []
		for child in get_children():
			child_names.append(child.name)
		print("Available children: ", child_names)

func ensure_started():
	_resolve_player()
	if player and player.has_method("start_music"):
		if ("music_has_started" in player and not player.music_has_started) and not player.is_playing():
			player.start_music()

func toggle_mute():
	_resolve_player()
	if player and player.has_method("toggle_mute"):
		player.toggle_mute()

func is_playing() -> bool:
	_resolve_player()
	if player and player.has_method("is_playing"):
		return player.is_playing()
	return false

func start_if_user_clicked():
	# Call this from a UI interaction to satisfy browser autoplay policies
	ensure_started()

# Expose music_has_started property
var music_has_started: bool:
	get:
		_resolve_player()
		if player and "music_has_started" in player:
			return player.music_has_started
		return false

# Expose start_music method directly  
func start_music():
	_resolve_player()
	if player and player.has_method("start_music"):
		print("GlobalMusic starting player...")
		player.start_music()
	else:
		print("ERROR: Player not found or missing start_music method")
