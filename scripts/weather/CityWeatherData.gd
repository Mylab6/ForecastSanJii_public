class_name CityWeatherData extends RefCounted

# Simple city weather data for San Jii Metro
# Loads city information from JSON and manages weather/temperature data

static var city_data = {}
static var city_metadata = {}
static var json_loaded = false

static func reset_data():
	"""Clear cached city data so a new map can repopulate fresh positions"""
	city_data.clear()
	city_metadata.clear()
	json_loaded = false

static func load_cities_from_json():
	"""Load city data from cities.json file"""
	if json_loaded:
		return  # Already loaded
	
	var file = FileAccess.open("res://cities.json", FileAccess.READ)
	if not file:
		print("Error: Could not open cities.json file")
		_create_fallback_data()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing cities.json: ", json.get_error_message())
		_create_fallback_data()
		return
	
	var json_data = json.data
	
	# Load city information
	if json_data.has("cities"):
		for city_name in json_data["cities"]:
			var city_info = json_data["cities"][city_name]
			
			# Convert position array to Vector2
			var pos_array = city_info["position"]
			var position = Vector2(pos_array[0], pos_array[1])
			
			# Create city data with weather tracking
			var starting_pop = city_info.get("starting_population", 0)
			city_data[city_name] = {
				"position": position,
				"name": city_info.get("name", city_name),
				"starting_population": starting_pop,
				"current_population": starting_pop,  # Start with same as starting population
				"elevation": city_info.get("elevation", 0),
				"type": city_info.get("type", "unknown"),
				"description": city_info.get("description", ""),
				"temperature": 0.0,
				"weather_status": "Clear",
				"last_update": 0.0
			}
	
	# Load metadata
	if json_data.has("metadata"):
		city_metadata = json_data["metadata"]
	
	json_loaded = true
	print("Loaded ", city_data.size(), " cities from cities.json")

static func _create_fallback_data():
	"""Create fallback city data if JSON loading fails"""
	city_data = {
		"CIUDADLONG": {
			"position": Vector2(0.45, 0.35),
			"name": "Ciudad Long",
			"starting_population": 125000,
			"current_population": 125000,
			"elevation": 45,
			"type": "urban",
			"description": "Major metropolitan area",
			"temperature": 0.0,
			"weather_status": "Clear",
			"last_update": 0.0
		},
		"PUERTOSHAN": {
			"position": Vector2(0.65, 0.45),
			"name": "Puerto Shan", 
			"starting_population": 89000,
			"current_population": 89000,
			"elevation": 12,
			"type": "coastal",
			"description": "Primary seaport",
			"temperature": 0.0,
			"weather_status": "Clear",
			"last_update": 0.0
		},
		"MONTAÑAWEI": {
			"position": Vector2(0.35, 0.32),
			"name": "Montaña Wei",
			"starting_population": 67000,
			"current_population": 67000,
			"elevation": 320,
			"type": "mountain",
			"description": "Mountain resort town",
			"temperature": 0.0,
			"weather_status": "Clear",
			"last_update": 0.0
		}
	}
	print("Using fallback city data")

static func initialize_temperatures():
	"""Initialize city temperature data"""
	print("Initializing city weather data...")
	
	# Get cities from the map renderer
	load_cities_from_renderer()
	
	print("Initialized weather data for ", city_data.size(), " cities")

static func load_cities_from_renderer():
	"""Load city data from OSMMapRenderer instead of JSON"""
	if json_loaded:
		return  # Already loaded
	
	# Get cities from OSMMapRenderer
	var cities = OSMMapRenderer.get_cities()
	var city_positions = OSMMapRenderer.get_city_positions()
	
	if cities.is_empty():
		print("No cities from renderer, creating fallback data")
		_create_fallback_data()
		return
	
	# Convert to our format
	for city in cities:
		var city_name = city.name
		var position = city_positions.get(city_name, Vector2(0.5, 0.5))
		
		city_data[city_name] = {
			"position": position,
			"name": city_name,
			"starting_population": city.population,
			"current_population": city.population,
			"elevation": 0,  # Default elevation
			"weather_status": "Clear",
			"temperature": 78.0 + randf_range(-5.0, 5.0)
		}
		
		city_metadata[city_name] = {
			"temperature": city_data[city_name]["temperature"],
			"weather_status": "Clear",
			"last_update": Time.get_unix_time_from_system(),
			"weather_history": [],
			"population_change": 0,
			"safety_status": "Safe"
		}
	
	json_loaded = true
	print("Loaded ", city_data.size(), " cities from map renderer")

static func update_temperatures():
	"""Update temperatures with small random variations"""
	for city_name in city_data:
		var current_temp = city_data[city_name]["temperature"]
		# Small random variation (-2 to +2 degrees)
		var variation = randf_range(-2.0, 2.0)
		var new_temp = current_temp + variation
		
		# Keep in tropical range
		new_temp = clamp(new_temp, 70.0, 88.0)
		city_data[city_name]["temperature"] = new_temp

static func get_city_temperature(city_name: String) -> float:
	"""Get temperature for a specific city"""
	if city_data.has(city_name):
		return city_data[city_name]["temperature"]
	return 75.0  # Default tropical temperature

static func get_city_position(city_name: String) -> Vector2:
	"""Get position for a specific city"""
	if city_data.has(city_name):
		return city_data[city_name]["position"]
	return Vector2.ZERO

static func get_all_cities() -> Array[String]:
	"""Get list of all city names"""
	var cities: Array[String] = []
	for city_name in city_data:
		cities.append(city_name)
	return cities

static func update_city_weather_status(city_name: String, weather_echoes: Array[WeatherEcho]):
	"""Update weather status based on nearby weather echoes"""
	if not city_data.has(city_name):
		return
	
	var city_pos = city_data[city_name]["position"]
	var max_intensity = 0.0
	
	# Check for weather within 0.1 radius of city
	for echo in weather_echoes:
		var distance = city_pos.distance_to(echo.position)
		if distance < 0.1 and echo.intensity > max_intensity:
			max_intensity = echo.intensity
	
	# Determine weather status
	var status = "Clear"
	if max_intensity > 0.1:
		if max_intensity < 0.3:
			status = "Light Rain"
		elif max_intensity < 0.6:
			status = "Rain"
		elif max_intensity < 0.8:
			status = "Heavy Rain"
		else:
			status = "Severe"
	
	city_data[city_name]["weather_status"] = status

static func get_city_info(city_name: String) -> Dictionary:
	"""Get complete city information"""
	if city_data.has(city_name):
		return city_data[city_name].duplicate()
	return {}

static func get_city_display_name(city_name: String) -> String:
	"""Get the display name for a city"""
	if city_data.has(city_name):
		return city_data[city_name].get("name", city_name)
	return city_name

static func get_city_starting_population(city_name: String) -> int:
	"""Get starting population for a specific city"""
	if city_data.has(city_name):
		return city_data[city_name].get("starting_population", 0)
	return 0

static func get_city_current_population(city_name: String) -> int:
	"""Get current population for a specific city"""
	if city_data.has(city_name):
		return city_data[city_name].get("current_population", 0)
	return 0

static func set_city_current_population(city_name: String, new_population: int):
	"""Set current population for a specific city (for game events)"""
	if city_data.has(city_name):
		city_data[city_name]["current_population"] = max(0, new_population)

static func adjust_city_population(city_name: String, change: int):
	"""Adjust current population by a specific amount (positive or negative)"""
	if city_data.has(city_name):
		var current = city_data[city_name]["current_population"]
		city_data[city_name]["current_population"] = max(0, current + change)

static func get_city_elevation(city_name: String) -> int:
	"""Get elevation for a specific city"""
	if city_data.has(city_name):
		return city_data[city_name].get("elevation", 0)
	return 0

static func get_city_type(city_name: String) -> String:
	"""Get city type (urban, coastal, mountain, etc.)"""
	if city_data.has(city_name):
		return city_data[city_name].get("type", "unknown")
	return "unknown"

static func get_cities_by_type(city_type: String) -> Array[String]:
	"""Get all cities of a specific type"""
	var cities: Array[String] = []
	for city_name in city_data:
		if city_data[city_name].get("type", "") == city_type:
			cities.append(city_name)
	return cities

static func get_metadata() -> Dictionary:
	"""Get city metadata information"""
	return city_metadata.duplicate()

static func calculate_total_cities() -> int:
	"""Calculate total number of cities at runtime"""
	load_cities_from_json()
	return city_data.size()

static func calculate_total_starting_population() -> int:
	"""Calculate total starting population at runtime"""
	load_cities_from_json()
	var total = 0
	for city_name in city_data:
		total += city_data[city_name].get("starting_population", 0)
	return total

static func calculate_total_current_population() -> int:
	"""Calculate total current population at runtime"""
	load_cities_from_json()
	var total = 0
	for city_name in city_data:
		total += city_data[city_name].get("current_population", 0)
	return total

static func get_runtime_metadata() -> Dictionary:
	"""Get calculated metadata at runtime"""
	load_cities_from_json()
	return {
		"total_cities": calculate_total_cities(),
		"total_starting_population": calculate_total_starting_population(),
		"total_current_population": calculate_total_current_population(),
		"coordinate_system": "normalized",
		"coordinate_range": "0.0 to 1.0",
		"temperature_range": "70-88°F (tropical climate)",
		"last_calculated": Time.get_datetime_string_from_system()
	}

static func print_city_summary():
	"""Print a summary of all loaded cities"""
	load_cities_from_json()
	
	print("\n=== SAN JII METRO CITIES ===")
	print("Total cities: ", calculate_total_cities())
	print("Total starting population: ", calculate_total_starting_population())
	print("Total current population: ", calculate_total_current_population())
	
	for city_name in city_data:
		var info = city_data[city_name]
		var temp_str = str(int(info["temperature"])) if info["temperature"] > 0 else "N/A"
		print("%s (%s) - Current Pop: %d, Starting Pop: %d, Elev: %dm, Temp: %s°F, Weather: %s" % [
			info["name"], 
			info["type"].capitalize(),
			info["current_population"],
			info["starting_population"],
			info["elevation"],
			temp_str,
			info["weather_status"]
		])
	
	print("========================\n")
