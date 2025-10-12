extends Node
# Dev Assistant — optimized + HTML5-safe, Godot 3.x/4.x compatible

# --- Players ---
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var alert_player: AudioStreamPlayer
var _unlock_player: AudioStreamPlayer            # one-shot WebAudio unlock

# --- Defaults (set if files exist) ---
var default_news_music: String = ""
var default_news_alert: String = ""

# --- State ---
var _audio_unlocked: bool = false

func _ready() -> void:
	# Players
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	alert_player = AudioStreamPlayer.new()
	add_child(alert_player)

	# One-shot unlock player using an AudioStreamGenerator
	_unlock_player = AudioStreamPlayer.new()
	_unlock_player.stream = _make_generator_stream(44100.0)
	add_child(_unlock_player)

	# Defaults (ALWAYS original res:// paths, never .godot/imported)
	default_news_music = _first_existing([
		"res://assets/audio/ws4kp-music/Rolling Clouds.ogg",
		"res://assets/audio/ws4kp-music/Moonlit sky.ogg",
		"res://assets/audio/ws4kp-music/Rolling Clouds.mp3",
		"res://assets/audio/ws4kp-music/Moonlit sky.mp3",
	])

	default_news_alert = _first_existing([
		"res://assets/audio/sfx/bong_001.ogg",
		"res://assets/audio/sfx/click_001.ogg",
		"res://assets/audio/sfx/confirmation_001.ogg",
	])

	# Capture first user gesture for web autoplay – use _input so UI events count
	set_process_input(true)

func _input(e: InputEvent) -> void:
	if not _audio_unlocked and e.is_pressed():
		unlock_audio()
		set_process_input(false)

# Call from a UI button too (e.g., "Tap to enable sound")
func unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	if _is_web():
		# Simple approach: just play and immediately stop a regular player to wake WebAudio
		# Use the sfx_player with a minimal silent stream instead of generator
		var silent_stream = AudioStreamGenerator.new()
		silent_stream.mix_rate = 22050.0
		silent_stream.buffer_length = 0.1
		sfx_player.stream = silent_stream
		sfx_player.play()
		sfx_player.stop()

# ------------------ Public API ------------------

func play_music(path: String) -> void:
	var res: AudioStream = _load(path)
	if res == null or not _can_play_now():
		return
	music_player.stream = res
	music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func is_music_playing() -> bool:
	return music_player != null and music_player.playing

func play_sfx(path: String) -> void:
	var res: AudioStream = _load(path)
	if res == null or not _can_play_now():
		return
	sfx_player.stream = res
	sfx_player.play()

func play_alert(path: String) -> void:
	var res: AudioStream = _load(path)
	if res == null or not _can_play_now():
		return
	alert_player.stream = res
	alert_player.play()

func play_default_news_music() -> void:
	if default_news_music != "":
		play_music(default_news_music)
	else:
		push_warning("AudioManager: no default news music set")

func play_default_news_alert() -> void:
	if default_news_alert != "":
		play_alert(default_news_alert)
	else:
		push_warning("AudioManager: no default news alert set")

func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)

# ------------------ Internals ------------------

func _is_web() -> bool:
	# Godot 4: "web", Godot 3: "HTML5"
	return OS.has_feature("web") or OS.has_feature("HTML5")

func _can_play_now() -> bool:
	if _is_web() and not _audio_unlocked:
		push_warning("Audio blocked by browser until user gesture. Call unlock_audio() or click/tap once.")
		return false
	return true

func _load(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("AudioManager: not found: %s" % path)
		return null
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		push_warning("AudioManager: failed to load: %s" % path)
		return null
	return res as AudioStream

func _first_existing(paths: Array) -> String:
	for p in paths:
		if ResourceLoader.exists(p):
			return p
	return ""

func _make_generator_stream(mix_rate: float) -> AudioStreamGenerator:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = mix_rate
	# small buffer; we only use it to nudge the context
	if "buffer_length" in gen:
		gen.buffer_length = 0.05
	return gen

func _push_silence_frames(pb: AudioStreamGeneratorPlayback, frames: int) -> void:
	# Works on Godot 3.x and 4.x (push_frame exists in both)
	for i in range(frames):
		if pb.can_push_buffer(1):
			pb.push_frame(Vector2(0.0, 0.0))
		else:
			break

func _stop_unlock_player() -> void:
	if _unlock_player and _unlock_player.playing:
		_unlock_player.stop()
