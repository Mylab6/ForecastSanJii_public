extends Node

# Simple Audio manager for background music and SFX.
# Usage: add this node to a running scene (or make it an Autoload) and call play_music/play_sfx/play_alert.

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var alert_player: AudioStreamPlayer
var default_news_music: String = ""
var default_news_alert: String = ""

func _ready():
	# create players at runtime so this script can be dropped in anywhere
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	alert_player = AudioStreamPlayer.new()
	add_child(alert_player)

	# default resource paths (override if you want different files)
	# Chosen defaults
	# Music: use Rolling Clouds if available
	if ResourceLoader.exists("res://assets/audio/ws4kp-music/Rolling Clouds.mp3"):
		default_news_music = "res://assets/audio/ws4kp-music/Rolling Clouds.mp3"
	elif ResourceLoader.exists("res://assets/audio/ws4kp-music/Moonlit sky.mp3"):
		default_news_music = "res://assets/audio/ws4kp-music/Moonlit sky.mp3"
	else:
		default_news_music = ""

	# Alert: use the imported bong_001.ogg if present
	var candidate_alert = "res://.godot/imported/bong_001.ogg-2f4c33f80113bd63dad84b30f697decf.oggvorbisstr"
	if ResourceLoader.exists(candidate_alert):
		default_news_alert = candidate_alert
	else:
		# fallback to a click or confirmation if bong is not present
		if ResourceLoader.exists("res://.godot/imported/click_001.ogg-cbe2013b9bbbeb1ba62f9edce618becd.oggvorbisstr"):
			default_news_alert = "res://.godot/imported/click_001.ogg-cbe2013b9bbbeb1ba62f9edce618becd.oggvorbisstr"
		elif ResourceLoader.exists("res://.godot/imported/confirmation_001.ogg-4c676d0550252e26ca9d8c94b1fe3417.oggvorbisstr"):
			default_news_alert = "res://.godot/imported/confirmation_001.ogg-4c676d0550252e26ca9d8c94b1fe3417.oggvorbisstr"
		else:
			default_news_alert = ""

func play_music(path: String) -> void:
	"""Play a music stream (path to res:// or user path). Replaces current music."""
	if not path or not ResourceLoader.exists(path):
		push_warning("AudioManager: music resource not found: %s" % path)
		return
	var res = ResourceLoader.load(path)
	if not res:
		push_warning("AudioManager: music resource not found: %s" % path)
		return
	music_player.stream = res
	music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_sfx(path: String) -> void:
	"""Play a short sound effect. Uses a dedicated SFX player."""
	if not path or not ResourceLoader.exists(path):
		push_warning("AudioManager: sfx resource not found: %s" % path)
		return
	var res = ResourceLoader.load(path)
	sfx_player.stream = res
	sfx_player.play()

func play_alert(path: String) -> void:
	"""Play an alert sound; does not stop music by default (keeps it simple)."""
	if not path or not ResourceLoader.exists(path):
		push_warning("AudioManager: alert resource not found: %s" % path)
		return
	var res = ResourceLoader.load(path)
	alert_player.stream = res
	alert_player.play()

func play_default_news_music():
	if default_news_music != "":
		play_music(default_news_music)
	else:
		push_warning("AudioManager: no default news music set")

func play_default_news_alert():
	if default_news_alert != "":
		play_alert(default_news_alert)
	else:
		push_warning("AudioManager: no default news alert set")

func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)
