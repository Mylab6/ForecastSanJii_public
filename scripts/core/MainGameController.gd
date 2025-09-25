extends Control

# Main game controller that manages setup and gameplay

var game_setup_scene: PackedScene
var radar_scene: PackedScene
var current_scene_instance: Node

func _ready():
	print("Starting ForcastSanJii Game")
	
	# Load scene resources
	game_setup_scene = preload("res://game_setup.tscn")
	radar_scene = preload("res://SimpleWeatherGame.tscn")  # Use the existing radar scene
	
	# Start with the setup screen
	show_game_setup()

func show_game_setup():
	"""Show the game setup screen"""
	# Clear current scene
	if current_scene_instance:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Instantiate and show setup scene
	current_scene_instance = game_setup_scene.instantiate()
	add_child(current_scene_instance)
	
	# Connect setup signals
	if current_scene_instance.has_signal("game_ready"):
		current_scene_instance.game_ready.connect(_on_game_ready)
	else:
		print("Warning: Game setup scene doesn't have game_ready signal")

func _on_game_ready(city_count: int):
	"""Handle game setup completion"""
	print("Game ready with ", city_count, " cities")
	
	# Generate cities based on selection
	CityManager.generate_cities_for_game(city_count)
	
	# Show the radar game
	show_radar_game()

func show_radar_game():
	"""Show the main radar game"""
	# Clear current scene
	if current_scene_instance:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Instantiate and show radar scene
	current_scene_instance = radar_scene.instantiate()
	add_child(current_scene_instance)
	
	print("Radar game started")

func _on_game_finished():
	"""Handle game completion"""
	print("Game finished, returning to setup")
	show_game_setup()
