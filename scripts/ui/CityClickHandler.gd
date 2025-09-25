extends Node
class_name CityClickHandler

# Handles click detection for cities on the radar map

signal city_clicked(city_name: String)

var radar_size: Vector2i
var hex_radius: int = 12

func _ready():
	# Connect to city click events
	city_clicked.connect(_on_city_clicked)

func setup_radar_dimensions(size: Vector2i):
	"""Setup the radar map dimensions for click detection"""
	radar_size = size
	print("City click handler setup for radar size: ", size)

func handle_radar_click(click_position: Vector2):
	"""Handle a click on the radar map"""
	print("Radar clicked at position: ", click_position)
	
	# Convert click position to hex grid coordinates
	var hex_pos = pixel_to_hex_grid(click_position, hex_radius)
	print("Click maps to hex position: ", hex_pos)
	
	# Check if this hex contains a city
	var cities = CityManager.get_cities()
	for city in cities:
		if city.hex_pos == hex_pos:
			print("City clicked: ", city.name)
			city_clicked.emit(city.name)
			return
	
	print("No city found at clicked position")

func pixel_to_hex_grid(pixel_pos: Vector2, hex_radius: int) -> Vector2i:
	"""Convert pixel position to hex grid coordinates"""
	# Use the same conversion as OSMMapRenderer
	var hex_width = hex_radius * 1.5
	var hex_height = hex_radius * 1.732
	
	var col = int(pixel_pos.x / hex_width)
	var row = int(pixel_pos.y / hex_height)
	
	# Adjust for hex offset pattern
	if col % 2 == 1:
		row = int((pixel_pos.y - hex_radius * 0.866) / hex_height)
	
	return Vector2i(col, row)

func _on_city_clicked(city_name: String):
	"""Handle city click event"""
	print("Opening alert dialog for city: ", city_name)
	
	# Load and show the city alert dialog
	var dialog_scene = preload("res://city_alert_dialog.tscn")
	var dialog = dialog_scene.instantiate()
	
	# Get the current scene tree
	var scene_tree = get_tree()
	if scene_tree and scene_tree.current_scene:
		scene_tree.current_scene.add_child(dialog)
		dialog.setup_for_city(city_name)
		dialog.popup_centered()
	else:
		print("Error: Could not access scene tree to show dialog")
