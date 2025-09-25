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
	mute_button.text = "▶️ Play Music"
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
	
	if not music_started:
		# First click - try to start music via autoload
		var global_music = get_node_or_null("/root/GlobalMusic")
		if global_music:
			print("Found GlobalMusic, attempting to start...")
			# Try different methods to start music
			if global_music.has_method("start_music"):
				global_music.start_music()
			elif global_music.has_method("ensure_started"):
				global_music.ensure_started()
			elif global_music.has_node("MusicLogic"):
				var music_logic = global_music.get_node("MusicLogic")
				if music_logic.has_method("start_music"):
					music_logic.start_music()
			music_started = true
			mute_button.text = "🔊 Music"
			print("Music should be starting...")
		else:
			print("No GlobalMusic autoload found")
	else:
		# Toggle mute using master bus
		var master_bus = AudioServer.get_bus_index("Master")
		var is_muted = AudioServer.is_bus_mute(master_bus)
		AudioServer.set_bus_mute(master_bus, not is_muted)
		
		mute_button.text = "🔇 Music" if not is_muted else "🔊 Music"
		print("Toggled mute: ", not is_muted)
