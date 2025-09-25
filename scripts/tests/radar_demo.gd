extends Control

# Demo script to showcase the enhanced radar with transparent circles and sweep sync

var radar: MapRadar
var demo_timer: float = 0.0
var current_scenario: int = 0

var scenarios = [
	{"name": "Clear Weather", "type": "clear"},
	{"name": "Scattered Storms", "type": "scattered"},
	{"name": "Supercell at MONTAÑAWEI", "type": "supercell"},
	{"name": "Hurricane", "type": "hurricane"},
	{"name": "Squall Line", "type": "squall_line"}
]

func _ready():
	print("=== ENHANCED RADAR DEMO ===")
	print("Features:")
	print("✓ Semi-transparent weather circles")
	print("✓ Sweep-synchronized echo appearance")
	print("✓ Tropical city temperatures (70-88°F)")
	print("✓ Authentic radar colors")
	print("✓ Realistic fade effects")
	print("")
	
	# Create radar
	radar = MapRadar.new()
	add_child(radar)
	radar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Start with scattered storms
	radar.set_weather_scenario("scattered")
	
	print("Demo starting with scattered storms...")
	print("Watch how weather echoes only appear after the green sweep line passes!")

func _process(delta):
	demo_timer += delta
	
	# Change scenarios every 15 seconds
	if demo_timer >= 15.0:
		demo_timer = 0.0
		current_scenario = (current_scenario + 1) % scenarios.size()
		
		var scenario = scenarios[current_scenario]
		radar.set_weather_scenario(scenario["type"])
		
		print("Switching to: ", scenario["name"])
		print("Weather echoes: ", radar.get_weather_count())
		
		# Show storm data
		var storm_data = radar.get_current_storm_data()
		if storm_data["affected_cities"].size() > 0:
			print("Affected cities: ", storm_data["affected_cities"])
		
		# Show city information from JSON
		var cities = CityWeatherData.get_all_cities()
		print("Current city status:")
		for city in cities:
			var temp = CityWeatherData.get_city_temperature(city)
			var display_name = CityWeatherData.get_city_display_name(city)
			var current_pop = CityWeatherData.get_city_current_population(city)
			var city_type = CityWeatherData.get_city_type(city)
			print("  %s (%s): %d°F, Pop: %s, Type: %s" % [
				display_name, city, int(temp), 
				_format_population(current_pop), city_type.capitalize()
			])

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Manual scenario change
				current_scenario = (current_scenario + 1) % scenarios.size()
				var scenario = scenarios[current_scenario]
				radar.set_weather_scenario(scenario["type"])
				print("Manual switch to: ", scenario["name"])
			
			KEY_C:
				# Clear weather
				radar.set_weather_scenario("clear")
				print("Cleared all weather")
			
			KEY_S:
				# Add storm at random city
				var cities = CityWeatherData.get_all_cities()
				var random_city = cities[randi() % cities.size()]
				radar.add_storm_at_city(random_city, randf_range(0.5, 0.9), "thunderstorm")
				print("Added storm at ", random_city)
			
			KEY_H:
				# Hurricane
				radar.set_weather_scenario("hurricane")
				print("Hurricane scenario activated")
			
			KEY_T:
				# Show temperatures
				print("\nCurrent city temperatures:")
				var cities = CityWeatherData.get_all_cities()
				for city in cities:
					var temp = CityWeatherData.get_city_temperature(city)
					var weather_info = radar.get_weather_at_city(city)
					print("  ", city, ": ", int(temp), "°F - ", weather_info["weather_status"])
			
			KEY_ESCAPE:
				# Quit
				get_tree().quit()

func _draw():
	# Draw instructions
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	var instructions = [
		"ENHANCED RADAR DEMO",
		"",
		"SPACE - Next scenario",
		"C - Clear weather", 
		"S - Add random storm",
		"H - Hurricane",
		"T - Show temperatures",
		"ESC - Quit",
		"",
		"Watch the sweep synchronization!"
	]
	
	var y_pos = 10
	for instruction in instructions:
		if instruction == "ENHANCED RADAR DEMO":
			draw_string(font, Vector2(10, y_pos), instruction, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.CYAN)  # 16 * 1.5 = 24
		elif instruction == "":
			pass  # Skip empty lines
		else:
			draw_string(font, Vector2(10, y_pos), instruction, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)  # 12 * 1.5 = 18
		y_pos += 27  # 18 * 1.5 = 27

func _format_population(num: int) -> String:
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