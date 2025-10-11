# Test script to verify music loading
# Add this as a temporary scene to test music loading

extends Control

func _ready():
	print("=== MUSIC DEBUG TEST ===")
	
	# Test 1: Check if GlobalMusic autoload exists
	var global_music = get_node_or_null("/root/GlobalMusic")
	print("GlobalMusic found: ", global_music != null)
	
	if global_music:
		print("GlobalMusic node: ", global_music)
		
		# Check if it has MusicLogic child
		if global_music.has_node("MusicLogic"):
			var music_logic = global_music.get_node("MusicLogic")
			print("MusicLogic found: ", music_logic != null)
			
			if music_logic:
				print("MusicLogic methods: ", music_logic.get_method_list())
				if "music_tracks" in music_logic:
					print("Music tracks loaded: ", music_logic.music_tracks.size())
					print("Track names: ", music_logic.music_file_names)
				else:
					print("No music_tracks property found")
		else:
			print("No MusicLogic child found")
	
	# Test 2: Direct file loading test
	print("\n=== DIRECT FILE TEST ===")
	var test_files = [
		"res://assets/audio/ws4kp-music/Rolling Clouds.mp3",
		"res://assets/audio/ws4kp-music/Moonlit sky.mp3"
	]
	
	for file_path in test_files:
		var exists = ResourceLoader.exists(file_path)
		print("File exists (", file_path, "): ", exists)
		
		if exists:
			var resource = load(file_path)
			print("  Loaded successfully: ", resource != null)
			print("  Resource type: ", resource.get_class() if resource else "null")
	
	print("=== END DEBUG TEST ===")