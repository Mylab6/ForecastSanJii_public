class_name CityManager extends RefCounted

# Manages dynamic city placement and city data for the weather radar game

static var available_city_names: Array[String] = [
	"Flying Fish Cove",
	"Silver City", 
	"San Ji City",
	"Drumsite",
	"Settlement",
	"The Dales",
	"Phosphate Hill",
	"Greta Beach",
	"Ethel Beach",
	"West White Beach",
	"South Point",
	"North East Point"
]

static var city_alert_levels: Dictionary = {}  # city_name -> alert_level
static var current_cities: Array = []  # Current game cities

enum AlertLevel {
	NONE,
	CAUTION,
	SHELTER,
	EVACUATE
}

static func get_alert_level_text(level: AlertLevel) -> String:
	match level:
		AlertLevel.CAUTION:
			return "CAUTION"
		AlertLevel.SHELTER:
			return "SHELTER"
		AlertLevel.EVACUATE:
			return "EVACUATE"
		_:
			return "NORMAL"

static func get_alert_level_color(level: AlertLevel) -> Color:
	match level:
		AlertLevel.CAUTION:
			return Color.YELLOW
		AlertLevel.SHELTER:
			return Color.ORANGE
		AlertLevel.EVACUATE:
			return Color.RED
		_:
			return Color.WHITE

static func get_cities() -> Array:
	"""Get current city data"""
	return current_cities

static func generate_cities_for_game(count: int):
	"""Generate a specific number of cities for the game"""
	print("Generating ", count, " cities for game")
	
	current_cities.clear()
	city_alert_levels.clear()
	
	# Use standard image size for positioning
	var image_size = Vector2i(800, 600)
	var hex_radius = 12
	
	# Get random city names
	var selected_names = []
	var available_names = available_city_names.duplicate()
	available_names.shuffle()
	
	for i in range(min(count, available_names.size())):
		selected_names.append(available_names[i])
	
	# Generate cities with random positions
	var center = Vector2(image_size.x / 2, image_size.y / 2)
	var island_radius = min(image_size.x, image_size.y) / 4
	
	var attempts = 0
	var max_attempts = 100
	
	for city_name in selected_names:
		var city = null
		attempts = 0
		
		while not city and attempts < max_attempts:
			attempts += 1
			
			# Generate random position within island bounds
			var angle = randf() * 2 * PI
			var distance = randf() * island_radius * 0.7
			
			var city_pos = Vector2(
				center.x + cos(angle) * distance,
				center.y + sin(angle) * distance
			)
			
			# Check if position is valid and not too close to other cities
			var valid = true
			for existing_city in current_cities:
				if city_pos.distance_to(existing_city.position) < hex_radius * 4:
					valid = false
					break
			
			if valid:
				city = {
					"name": city_name,
					"position": city_pos,
					"hex_pos": pixel_to_hex_grid(city_pos, hex_radius),
					"population": randi_range(500, 5000),
					"alert_level": AlertLevel.NONE
				}
		
		if city:
			current_cities.append(city)
			city_alert_levels[city_name] = AlertLevel.NONE
			print("Generated city: ", city_name, " at hex position ", city.hex_pos)
	
	print("Generated ", current_cities.size(), " cities total")

static func generate_random_cities(count: int, image_size: Vector2i, hex_radius: int) -> Array:
	"""Generate random city positions within the island bounds"""
	var cities = []
	var used_names = []
	
	# Shuffle available names
	var shuffled_names = available_city_names.duplicate()
	shuffled_names.shuffle()
	
	# Define island bounds (should match the hex map generation)
	var center = Vector2(image_size.x / 2, image_size.y / 2)
	var island_radius = min(image_size.x, image_size.y) / 4
	
	# Generate cities within the land area
	var attempts = 0
	var max_attempts = 100
	
	while cities.size() < count and attempts < max_attempts:
		attempts += 1
		
		# Generate random position within island bounds
		var angle = randf() * 2 * PI
		var distance = randf() * island_radius * 0.7  # Keep within 70% of island radius
		
		var city_pos = Vector2(
			center.x + cos(angle) * distance,
			center.y + sin(angle) * distance
		)
		
		# Make sure position is within image bounds
		if city_pos.x < 50 or city_pos.x > image_size.x - 50:
			continue
		if city_pos.y < 50 or city_pos.y > image_size.y - 50:
			continue
		
		# Check distance from other cities (minimum separation)
		var too_close = false
		for existing_city in cities:
			if city_pos.distance_to(existing_city.position) < hex_radius * 4:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Create city data
		var city_name = shuffled_names[cities.size()] if cities.size() < shuffled_names.size() else "City " + str(cities.size() + 1)
		
		var city = {
			"name": city_name,
			"position": city_pos,
			"hex_pos": pixel_to_hex_grid(city_pos, hex_radius),
			"population": randi_range(500, 5000),
			"alert_level": AlertLevel.NONE
		}
		
		cities.append(city)
		city_alert_levels[city_name] = AlertLevel.NONE
		print("Generated city: ", city_name, " at ", city_pos)
	
	print("Generated ", cities.size(), " cities")
	return cities

static func pixel_to_hex_grid(pixel_pos: Vector2, hex_radius: int) -> Vector2i:
	"""Convert pixel position to hex grid coordinates"""
	var hex_width = hex_radius * 1.5
	var hex_height = hex_radius * 1.732
	
	var col = int(pixel_pos.x / hex_width)
	var row = int(pixel_pos.y / hex_height)
	
	# Adjust for hex offset pattern
	if col % 2 == 1:
		row = int((pixel_pos.y - hex_radius * 0.866) / hex_height)
	
	return Vector2i(col, row)

static func set_city_alert(city_name: String, alert_level: AlertLevel):
	"""Set alert level for a specific city"""
	city_alert_levels[city_name] = alert_level
	print("Set alert for ", city_name, " to ", get_alert_level_text(alert_level))

static func get_city_alert(city_name: String) -> AlertLevel:
	"""Get current alert level for a city"""
	return city_alert_levels.get(city_name, AlertLevel.NONE)

static func clear_all_alerts():
	"""Clear all city alerts"""
	for city_name in city_alert_levels:
		city_alert_levels[city_name] = AlertLevel.NONE
	print("Cleared all city alerts")
