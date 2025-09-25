class_name WeatherImpactSystem extends RefCounted

# Comprehensive weather impact system for San Jii Metro
# Handles weather assessment, population dynamics, and city-to-city migration

static var game_settings = {}
static var settings_loaded = false

# Weather assessment data for each city
static var city_weather_assessments = {}

static func load_game_settings():
	"""Load game settings from JSON"""
	if settings_loaded:
		return
	
	var file = FileAccess.open("res://game_settings.json", FileAccess.READ)
	if not file:
		print("Warning: Could not load game_settings.json, using defaults")
		_create_default_settings()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing game_settings.json: ", json.get_error_message())
		_create_default_settings()
		return
	
	game_settings = json.data
	settings_loaded = true
	print("Game settings loaded successfully")

static func _create_default_settings():
	"""Create default settings if JSON loading fails"""
	game_settings = {
		"radar_settings": {"base_radius_multiplier": 0.48},
		"population_dynamics": {
			"migration_enabled": true,
			"migration_rate": 0.05,
			"weather_influence_factor": 0.3
		},
		"display_settings": {"show_weather_logs": true}
	}
	settings_loaded = true

static func assess_city_weather(city_name: String, weather_echoes: Array[WeatherEcho]) -> Dictionary:
	"""Assess weather conditions for a city using the 3-question framework"""
	load_game_settings()
	CityWeatherData.load_cities_from_json()
	
	var city_pos = CityWeatherData.get_city_position(city_name)
	if city_pos == Vector2.ZERO:
		return {"error": "City not found"}
	
	# Analyze weather echoes near the city
	var max_intensity = 0.0
	var echo_count = 0
	var closest_distance = 1.0
	var weather_types = []
	
	for echo in weather_echoes:
		var distance = city_pos.distance_to(echo.position)
		if distance < 0.15:  # Within 15% of radar scope
			echo_count += 1
			if echo.intensity > max_intensity:
				max_intensity = echo.intensity
			if distance < closest_distance:
				closest_distance = distance
			
			# Determine weather type based on intensity and echo type
			var weather_type = _determine_weather_type(echo.intensity, echo.echo_type)
			if not weather_types.has(weather_type):
				weather_types.append(weather_type)
	
	# Answer the 3 questions
	var weather_condition = _determine_weather_condition(weather_types, max_intensity)
	var severity_level = _determine_severity_level(max_intensity, echo_count)
	var recommended_action = _determine_recommended_action(severity_level, weather_condition)
	
	# Create assessment
	var assessment = {
		"city": city_name,
		"weather_condition": weather_condition,
		"severity_level": severity_level,
		"recommended_action": recommended_action,
		"max_intensity": max_intensity,
		"echo_count": echo_count,
		"closest_distance": closest_distance,
		"dbz_value": int(max_intensity * 60),
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	# Store assessment for population dynamics
	city_weather_assessments[city_name] = assessment
	
	# Log the assessment
	if game_settings.get("display_settings", {}).get("show_weather_logs", true):
		_log_weather_assessment(assessment)
	
	return assessment

static func _determine_weather_type(intensity: float, echo_type: String) -> String:
	"""Determine weather type based on intensity and echo characteristics"""
	if intensity < 0.1:
		return "Clear"
	elif intensity < 0.3:
		return "Light Rain"
	elif intensity < 0.6:
		return "Heavy Rain"
	elif intensity < 0.8:
		if echo_type == "severe":
			return "Severe Storm"
		else:
			return "Thunderstorm"
	else:
		return "Severe Storm"

static func _determine_weather_condition(weather_types: Array, max_intensity: float) -> String:
	"""Question 1: What's the weather?"""
	if weather_types.is_empty() or max_intensity < 0.1:
		return "Clear"
	
	# Return the most severe weather type present
	var severity_order = ["Clear", "Light Rain", "Heavy Rain", "Thunderstorm", "Severe Storm", "Blizzard"]
	var most_severe = "Clear"
	
	for weather_type in weather_types:
		var current_index = severity_order.find(weather_type)
		var most_severe_index = severity_order.find(most_severe)
		if current_index > most_severe_index:
			most_severe = weather_type
	
	return most_severe

static func _determine_severity_level(max_intensity: float, echo_count: int) -> String:
	"""Question 2: What's the severity level?"""
	if max_intensity < 0.1:
		return "None"
	elif max_intensity < 0.3:
		return "Low"
	elif max_intensity < 0.6:
		return "Medium" if echo_count < 3 else "High"
	elif max_intensity < 0.8:
		return "High"
	else:
		return "Extreme"

static func _determine_recommended_action(severity: String, weather: String) -> String:
	"""Question 3: What action should be taken?"""
	match severity:
		"None":
			return "None"
		"Low":
			return "Caution"
		"Medium":
			if weather in ["Thunderstorm", "Heavy Rain"]:
				return "Caution"
			else:
				return "None"
		"High":
			if weather in ["Severe Storm", "Blizzard"]:
				return "Shelter"
			else:
				return "Caution"
		"Extreme":
			return "Evacuate"
		_:
			return "None"

static func _log_weather_assessment(assessment: Dictionary):
	"""Log weather assessment for debugging and monitoring"""
	var city_display_name = CityWeatherData.get_city_display_name(assessment["city"])
	var current_pop = CityWeatherData.get_city_current_population(assessment["city"])
	
	print("\n=== WEATHER ASSESSMENT: %s ===" % city_display_name)
	print("Population: %s" % _format_number(current_pop))
	print("Weather: %s" % assessment["weather_condition"])
	print("Severity: %s" % assessment["severity_level"])
	print("Recommended Action: %s" % assessment["recommended_action"])
	print("Max Intensity: %.1f dBZ (%d%%)" % [assessment["dbz_value"], assessment["max_intensity"] * 100])
	print("Weather Echoes: %d" % assessment["echo_count"])
	print("Time: %s" % assessment["timestamp"])

static func process_population_dynamics(delta: float):
	"""Process population migration based on weather conditions"""
	load_game_settings()
	
	var migration_settings = game_settings.get("population_dynamics", {})
	if not migration_settings.get("migration_enabled", true):
		return
	
	var migration_rate = migration_settings.get("migration_rate", 0.05)
	var weather_influence = migration_settings.get("weather_influence_factor", 0.3)
	
	# Process each city's population changes
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		if city_weather_assessments.has(city_name):
			var assessment = city_weather_assessments[city_name]
			_process_city_population_impact(city_name, assessment, delta, migration_rate, weather_influence)

static func _process_city_population_impact(city_name: String, assessment: Dictionary, 
										   delta: float, migration_rate: float, weather_influence: float):
	"""Process population impact for a specific city"""
	var current_pop = CityWeatherData.get_city_current_population(city_name)
	var action = assessment["recommended_action"]
	var severity = assessment["severity_level"]
	
	var population_change = 0
	
	match action:
		"Evacuate":
			# Major evacuation - 60-85% of population leaves
			var evacuation_rate = randf_range(0.6, 0.85)
			population_change = -int(current_pop * evacuation_rate * delta * 0.1)  # Gradual over time
			_log_population_change(city_name, "EVACUATION", population_change)
		
		"Shelter":
			# Some people leave for safer areas - 10-25% migration
			var shelter_migration = randf_range(0.1, 0.25)
			population_change = -int(current_pop * shelter_migration * delta * 0.05)
			_log_population_change(city_name, "SHELTER MIGRATION", population_change)
		
		"Caution":
			# Minor migration - 2-8% leave for better weather
			var caution_migration = randf_range(0.02, 0.08)
			population_change = -int(current_pop * caution_migration * delta * 0.02)
			_log_population_change(city_name, "WEATHER MIGRATION", population_change)
		
		"None":
			# City might receive migrants from worse weather areas
			population_change = _calculate_immigration(city_name, delta)
			if population_change > 0:
				_log_population_change(city_name, "IMMIGRATION", population_change)
	
	# Apply population change
	if population_change != 0:
		CityWeatherData.adjust_city_population(city_name, population_change)

static func _calculate_immigration(safe_city: String, delta: float) -> int:
	"""Calculate immigration to a safe city from dangerous areas"""
	var immigration = 0
	var safe_city_pos = CityWeatherData.get_city_position(safe_city)
	
	# Check other cities for dangerous conditions
	for other_city in city_weather_assessments:
		if other_city == safe_city:
			continue
		
		var other_assessment = city_weather_assessments[other_city]
		var other_pos = CityWeatherData.get_city_position(other_city)
		var distance = safe_city_pos.distance_to(other_pos)
		
		# Only migrate to nearby cities (within 40% of map)
		if distance < 0.4 and other_assessment["recommended_action"] in ["Evacuate", "Shelter"]:
			var other_pop = CityWeatherData.get_city_current_population(other_city)
			var migration_amount = int(other_pop * 0.1 * delta * 0.05)  # Small portion migrates
			immigration += migration_amount
	
	return immigration

static func _log_population_change(city_name: String, reason: String, change: int):
	"""Log population changes for monitoring"""
	if abs(change) < 10:  # Don't log tiny changes
		return
	
	var city_display_name = CityWeatherData.get_city_display_name(city_name)
	var current_pop = CityWeatherData.get_city_current_population(city_name)
	var change_str = "+" + str(change) if change > 0 else str(change)
	
	print("📊 %s: %s (%s) - Population: %s" % [
		city_display_name, 
		reason, 
		change_str,
		_format_number(current_pop)
	])

static func update_all_city_weather(weather_echoes: Array[WeatherEcho]):
	"""Update weather assessments for all cities"""
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		assess_city_weather(city_name, weather_echoes)

static func get_city_assessment(city_name: String) -> Dictionary:
	"""Get the current weather assessment for a city"""
	return city_weather_assessments.get(city_name, {})

static func get_all_assessments() -> Dictionary:
	"""Get all current city weather assessments"""
	return city_weather_assessments.duplicate()

static func get_population_summary() -> Dictionary:
	"""Get summary of population changes across all cities"""
	var cities = CityWeatherData.get_all_cities()
	var summary = {
		"total_current": 0,
		"total_starting": 0,
		"cities_evacuating": [],
		"cities_sheltering": [],
		"safe_cities": [],
		"most_affected": "",
		"least_affected": ""
	}
	
	var max_loss = 0
	var min_loss = 999999
	
	for city_name in cities:
		var starting = CityWeatherData.get_city_starting_population(city_name)
		var current = CityWeatherData.get_city_current_population(city_name)
		var loss = starting - current
		
		summary["total_starting"] += starting
		summary["total_current"] += current
		
		if city_weather_assessments.has(city_name):
			var assessment = city_weather_assessments[city_name]
			match assessment["recommended_action"]:
				"Evacuate":
					summary["cities_evacuating"].append(city_name)
				"Shelter":
					summary["cities_sheltering"].append(city_name)
				_:
					summary["safe_cities"].append(city_name)
		
		if loss > max_loss:
			max_loss = loss
			summary["most_affected"] = city_name
		if loss < min_loss:
			min_loss = loss
			summary["least_affected"] = city_name
	
	return summary

static func _format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	
	return result
