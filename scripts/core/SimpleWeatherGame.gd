extends Control

# Simple weather game controller
var radar_node
var music_player
var mute_button

func _ready():
	print("San Jii Metro Weather Emergency System started!")

	# Initialize radar
	radar_node = $MapRadar
	if radar_node:
		print("Map radar loaded and active")
	else:
		print("ERROR: Map radar not found!")

	# Initialize music player
	music_player = $MusicPlayer
	if music_player:
		print("Music player loaded and active")
	else:
		print("ERROR: Music player not found!")

	# Create and setup mute button
	_create_mute_button()

func _create_mute_button():
	"""Create a music control button for the music"""
	mute_button = Button.new()
	mute_button.text = "▶️ Play Music"  # Start with play button for web compatibility
	mute_button.add_theme_font_size_override("font_size", 16)
	mute_button.add_theme_color_override("font_color", Color.WHITE)
	mute_button.add_theme_color_override("font_shadow_color", Color.BLACK)
	mute_button.add_theme_constant_override("shadow_offset_x", 1)
	mute_button.add_theme_constant_override("shadow_offset_y", 1)

	# Position in top-right corner
	mute_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mute_button.position.x -= 10
	mute_button.position.y += 10
	mute_button.size = Vector2(120, 40)

	# Connect signal
	mute_button.pressed.connect(_on_mute_button_pressed)

	# Connect to music player signals
	if music_player:
		music_player.muted_changed.connect(_on_music_muted_changed)
		music_player.music_started.connect(_on_music_started)

	add_child(mute_button)

func _on_mute_button_pressed():
	"""Handle music button press - starts music on first click for web compatibility"""
	if music_player:
		if not music_player.music_has_started:
			# First click - start the music
			music_player.start_music()
		else:
			# Subsequent clicks - toggle mute
			music_player.toggle_mute()

func _on_music_started():
	"""Update button text when music starts playing"""
	if mute_button:
		mute_button.text = "🔊 Music"

func _on_music_muted_changed(is_muted: bool):
	"""Update button text when mute state changes"""
	if mute_button and music_player.music_has_started:
		if is_muted:
			mute_button.text = "🔇 Music"
		else:
			mute_button.text = "🔊 Music"
