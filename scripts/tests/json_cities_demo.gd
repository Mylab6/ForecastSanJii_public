extends Node

# Demo script to showcase the JSON-based city system

func _ready():
	print("=== JSON CITIES DEMO ===")
	print("Loading cities from cities.json...")
	
	# Initialize the city system
	CityWeatherData.initialize_temperatures()
	
	# Print comprehensive city summary
	CityWeatherData.print_city_summary()
	
	# Demonstrate city type filtering
	print("=== CITIES BY TYPE ===")
	var coastal_cities = CityWeatherData.get_cities_by_type("coastal")
	print("Coastal cities: ", coastal_cities)
	
	var mountain_cities = CityWeatherData.get_cities_by_type("mountain")
	print("Mountain cities: ", mountain_cities)
	
	var urban_cities = CityWeatherData.get_cities_by_type("urban")
	print("Urban cities: ", urban_cities)
	
	# Show detailed info for each city
	print("\n=== DETAILED CITY INFO ===")
	var all_cities = CityWeatherData.get_all_cities()
	for city_name in all_cities:
		var info = CityWeatherData.get_city_info(city_name)
		print("\n%s (%s):" % [info["name"], city_name])
		print("  Starting Population: %s" % _format_number(info["starting_population"]))
		print("  Current Population: %s" % _format_number(info["current_population"]))
		print("  Elevation: %dm above sea level" % info["elevation"])
		print("  Type: %s" % info["type"].capitalize())
		print("  Position: (%.2f, %.2f)" % [info["position"].x, info["position"].y])
		print("  Temperature: %d°F" % int(info["temperature"]))
		print("  Weather: %s" % info["weather_status"])
		print("  Description: %s" % info["description"])
	
	# Show runtime calculated metadata
	print("\n=== RUNTIME CALCULATIONS ===")
	var runtime_metadata = CityWeatherData.get_runtime_metadata()
	print("Total cities: %d" % runtime_metadata["total_cities"])
	print("Total starting population: %s" % _format_number(runtime_metadata["total_starting_population"]))
	print("Total current population: %s" % _format_number(runtime_metadata["total_current_population"]))
	print("Last calculated: %s" % runtime_metadata["last_calculated"])
	
	# Demonstrate population changes during game events
	print("\n=== POPULATION CHANGE SIMULATION ===")
	print("Simulating weather disaster affecting Ciudad Long...")
	var initial_pop = CityWeatherData.get_city_current_population("CIUDADLONG")
	print("Ciudad Long initial population: %s" % _format_number(initial_pop))
	
	# Simulate evacuation (population decrease)
	CityWeatherData.adjust_city_population("CIUDADLONG", -15000)
	var after_evacuation = CityWeatherData.get_city_current_population("CIUDADLONG")
	print("After evacuation: %s (-%s people)" % [_format_number(after_evacuation), _format_number(15000)])
	
	# Show how this affects total population
	var new_total = CityWeatherData.calculate_total_current_population()
	print("New total population: %s" % _format_number(new_total))
	
	# Simulate recovery (partial population return)
	print("\nSimulating post-disaster recovery...")
	CityWeatherData.adjust_city_population("CIUDADLONG", 8000)
	var after_recovery = CityWeatherData.get_city_current_population("CIUDADLONG")
	print("Ciudad Long after recovery: %s (+%s people returned)" % [_format_number(after_recovery), _format_number(8000)])
	
	# Show starting vs current comparison
	var starting_pop = CityWeatherData.get_city_starting_population("CIUDADLONG")
	var population_change = after_recovery - starting_pop
	print("Net change from starting population: %s" % _format_number(population_change))
	
	# Test weather generation with JSON cities
	print("\n=== WEATHER GENERATION TEST ===")
	var weather_echoes = WeatherDataGenerator.get_city_weather_echoes()
	print("Generated %d weather echoes over random cities" % weather_echoes.size())
	
	# Show which cities have weather
	var cities_with_weather = []
	for echo in weather_echoes:
		for city_name in all_cities:
			var city_pos = CityWeatherData.get_city_position(city_name)
			var distance = city_pos.distance_to(echo.position)
			if distance < 0.1:  # Within 10% of radar
				if not cities_with_weather.has(city_name):
					cities_with_weather.append(city_name)
	
	print("Cities with weather: ", cities_with_weather)
	
	print("\n=== JSON CITIES DEMO COMPLETE ===")
	
	# Quit after demo
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _format_number(num: int) -> String:
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