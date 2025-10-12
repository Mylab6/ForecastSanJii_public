extends Control

# Simple weather game controller
var radar_node
var mute_button
var music_started = false

func _ready():
	print("San Jii Metro Weather Emergency System started!")

	# Initialize radar
	radar_node = $MapRadar
	if radar_node:
		print("Map radar loaded and active")
	else:
		print("ERROR: Map radar not found!")

	# Create and setup mute button
	_create_mute_button()

func _create_mute_button():
	"""Create a simple music control button"""
	mute_button = Button.new()
	mute_button.text = "Play Music"
	mute_button.add_theme_font_size_override("font_size", 16)
	mute_button.add_theme_color_override("font_color", Color.WHITE)
	mute_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	mute_button.add_theme_constant_override("shadow_offset_x", 1)
	mute_button.add_theme_constant_override("shadow_offset_y", 1)

	# Position in bottom-right corner
	mute_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	mute_button.position.x -= 130
	mute_button.position.y -= 50
	mute_button.size = Vector2(120, 40)

	# Connect signal
	mute_button.pressed.connect(_on_mute_button_pressed)
	add_child(mute_button)
	print("Music button created")

func _on_mute_button_pressed():
	"""Handle music button press"""
	print("Music button pressed!")

	var audio_manager = null
	if Engine.has_singleton("AudioManager"):
		audio_manager = Engine.get_singleton("AudioManager")
		if audio_manager and "unlock_audio" in audio_manager:
			audio_manager.unlock_audio()

	# Toggle between max volume (0 dB) and silent (-80 dB)
	var master_bus = AudioServer.get_bus_index("Master")
	var current_volume = AudioServer.get_bus_volume_db(master_bus)

	if current_volume > -40:
		AudioServer.set_bus_volume_db(master_bus, -80.0)
		mute_button.text = "Music (Off)"
		print("Volume set to 0")
	else:
		AudioServer.set_bus_volume_db(master_bus, 0.0)
		mute_button.text = "Music (On)"
		print("Volume set to max")
		if audio_manager and OS.has_feature("web"):
			audio_manager.unlock_audio()
			var is_playing = false
			if "is_music_playing" in audio_manager:
				is_playing = audio_manager.is_music_playing()
			if not is_playing and "play_default_news_music" in audio_manager:
				audio_manager.play_default_news_music()
