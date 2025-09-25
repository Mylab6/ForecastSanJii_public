extends Node

# Demo script to showcase the comprehensive weather impact system

var demo_timer: float = 0.0
var scenario_duration: float = 20.0  # 20 seconds per scenario
var current_scenario: int = 0

var weather_scenarios = [
	{
		"name": "Hurricane Elena Approaches",
		"description": "Category 4 hurricane threatening coastal cities",
		"setup": "hurricane_elena"
	},
	{
		"name": "Mountain Supercells",
		"description": "Severe thunderstorms in mountain regions",
		"setup": "mountain_storms"
	},
	{
		"name": "Coastal Storm System",
		"description": "Widespread storms affecting ports and beaches",
		"setup": "coastal_storms"
	},
	{
		"name": "Clear Weather Recovery",
		"description": "Weather clears, population begins to return",
		"setup": "clear_recovery"
	}
]

func _ready():
	print("=== WEATHER IMPACT SYSTEM DEMO ===")
	print("Comprehensive 3-Question Weather Assessment Framework")
	print("- Question 1: What's the weather? (Clear, Rain, Storm, etc.)")
	print("- Question 2: What's the severity? (None, Low, Medium, High, Extreme)")
	print("- Question 3: What action to take? (None, Caution, Shelter, Evacuate)")
	print("")
	print("Features:")
	print("✓ Dynamic population migration based on weather")
	print("✓ Real-time weather impact assessment")
	print("✓ Population evacuation and recovery simulation")
	print("✓ 20% larger radar coverage")
	print("✓ Comprehensive logging system")
	print("")
	
	# Initialize systems
	CityWeatherData.initialize_temperatures()
	WeatherImpactSystem.load_game_settings()
	
	# Show initial population status
	print_population_baseline()
	
	# Start first scenario
	start_scenario(0)

func _process(delta):
	demo_timer += delta
	
	# Switch scenarios every 20 seconds
	if demo_timer >= scenario_duration:
		demo_timer = 0.0
		current_scenario = (current_scenario + 1) % weather_scenarios.size()
		start_scenario(current_scenario)

func start_scenario(scenario_index: int):
	"""Start a weather scenario"""
	var scenario = weather_scenarios[scenario_index]
	
	print("\n" + "=".repeat(60))
	print("SCENARIO %d: %s" % [scenario_index + 1, scenario["name"]])
	print(scenario["description"])
	print("=".repeat(60))
	
	# Create weather pattern based on scenario
	var weather_echoes = create_scenario_weather(scenario["setup"])
	
	# Assess all cities with new weather
	WeatherImpactSystem.update_all_city_weather(weather_echoes)
	
	# Show comprehensive assessment
	show_weather_assessment_summary()
	
	# Process initial population dynamics
	WeatherImpactSystem.process_population_dynamics(1.0)
	
	# Show population impact
	show_population_impact_summary()

func create_scenario_weather(setup_type: String) -> Array[WeatherEcho]:
	"""Create weather patterns for different scenarios"""
	var weather_echoes: Array[WeatherEcho] = []
	
	match setup_type:
		"hurricane_elena":
			# Major hurricane threatening coastal cities
			var coastal_cities = ["PUERTOSHAN", "BAHÍA AZUL", "PLAYAHAI"]
			for city_name in coastal_cities:
				var city_pos = CityWeatherData.get_city_position(city_name)
				# Create hurricane-force weather
				var hurricane_echo = WeatherEcho.new(city_pos, 0.95, 4.0, 30.0, Vector2(-0.01, -0.005), "severe")
				weather_echoes.append(hurricane_echo)
				
				# Add spiral bands
				for i in range(8):
					var angle = (i / 8.0) * TAU
					var band_pos = city_pos + Vector2(cos(angle), sin(angle)) * 0.08
					var band_echo = WeatherEcho.new(band_pos, 0.7, 2.0, 25.0, Vector2(-0.008, -0.003), "heavy")
					weather_echoes.append(band_echo)
		
		"mountain_storms":
			# Severe storms in mountain regions
			var mountain_cities = ["MONTAÑAWEI", "MONTAÑA-LONG RIDGE", "VALLEGU"]
			for city_name in mountain_cities:
				var city_pos = CityWeatherData.get_city_position(city_name)
				# Create supercell storms
				var supercell_echo = WeatherEcho.new(city_pos, 0.85, 3.0, 20.0, Vector2(0.01, 0.008), "severe")
				weather_echoes.append(supercell_echo)
				
				# Add mesocyclone signature
				for i in range(6):
					var angle = (i / 6.0) * TAU
					var meso_pos = city_pos + Vector2(cos(angle), sin(angle)) * 0.03
					var meso_echo = WeatherEcho.new(meso_pos, 0.6, 1.5, 15.0, Vector2(0.008, 0.006), "moderate")
					weather_echoes.append(meso_echo)
		
		"coastal_storms":
			# Widespread coastal storm system
			var all_cities = CityWeatherData.get_all_cities()
			for city_name in all_cities:
				var city_type = CityWeatherData.get_city_type(city_name)
				if city_type in ["coastal", "beach"]:
					var city_pos = CityWeatherData.get_city_position(city_name)
					var storm_echo = WeatherEcho.new(city_pos, 0.65, 2.5, 18.0, Vector2(0.005, 0.003), "heavy")
					weather_echoes.append(storm_echo)
		
		"clear_recovery":
			# Clear weather - no echoes, allowing recovery
			pass
	
	return weather_echoes

func show_weather_assessment_summary():
	"""Show comprehensive weather assessment for all cities"""
	print("\n📊 WEATHER ASSESSMENT SUMMARY")
	print("-".repeat(50))
	
	var assessments = WeatherImpactSystem.get_all_assessments()
	var cities = CityWeatherData.get_all_cities()
	
	for city_name in cities:
		if assessments.has(city_name):
			var assessment = assessments[city_name]
			var display_name = CityWeatherData.get_city_display_name(city_name)
			var current_pop = CityWeatherData.get_city_current_population(city_name)
			
			print("\n🏙️  %s (Pop: %s)" % [display_name, _format_number(current_pop)])
			print("   Weather: %s" % assessment["weather_condition"])
			print("   Severity: %s" % assessment["severity_level"])
			print("   Action: %s" % assessment["recommended_action"])
			print("   Intensity: %d dBZ" % assessment["dbz_value"])
			
			# Add action-specific details
			match assessment["recommended_action"]:
				"Evacuate":
					print("   ⚠️  EVACUATION ORDERED - Major population exodus expected")
				"Shelter":
					print("   🏠 SHELTER IN PLACE - Some residents may relocate")
				"Caution":
					print("   ⚡ WEATHER ADVISORY - Minor population movement possible")
				"None":
					print("   ✅ SAFE CONDITIONS - May receive evacuees from other areas")

func show_population_impact_summary():
	"""Show population impact and migration summary"""
	print("\n📈 POPULATION IMPACT ANALYSIS")
	print("-".repeat(50))
	
	var summary = WeatherImpactSystem.get_population_summary()
	
	print("Total Starting Population: %s" % _format_number(summary["total_starting"]))
	print("Total Current Population: %s" % _format_number(summary["total_current"]))
	
	var population_change = summary["total_current"] - summary["total_starting"]
	var change_str = ("+" + str(population_change)) if population_change >= 0 else str(population_change)
	print("Net Population Change: %s" % _format_number(population_change))
	
	if summary["cities_evacuating"].size() > 0:
		print("\n🚨 CITIES UNDER EVACUATION:")
		for city in summary["cities_evacuating"]:
			var display_name = CityWeatherData.get_city_display_name(city)
			var current_pop = CityWeatherData.get_city_current_population(city)
			var starting_pop = CityWeatherData.get_city_starting_population(city)
			var loss = starting_pop - current_pop
			print("   %s: %s (-%s evacuated)" % [display_name, _format_number(current_pop), _format_number(loss)])
	
	if summary["cities_sheltering"].size() > 0:
		print("\n🏠 CITIES UNDER SHELTER ORDERS:")
		for city in summary["cities_sheltering"]:
			var display_name = CityWeatherData.get_city_display_name(city)
			var current_pop = CityWeatherData.get_city_current_population(city)
			print("   %s: %s" % [display_name, _format_number(current_pop)])
	
	if summary["safe_cities"].size() > 0:
		print("\n✅ SAFE CITIES (Potential Evacuation Destinations):")
		for city in summary["safe_cities"]:
			var display_name = CityWeatherData.get_city_display_name(city)
			var current_pop = CityWeatherData.get_city_current_population(city)
			var starting_pop = CityWeatherData.get_city_starting_population(city)
			var gain = current_pop - starting_pop
			if gain > 0:
				print("   %s: %s (+%s refugees)" % [display_name, _format_number(current_pop), _format_number(gain)])
			else:
				print("   %s: %s" % [display_name, _format_number(current_pop)])

func print_population_baseline():
	"""Print initial population baseline"""
	print("📊 INITIAL POPULATION BASELINE")
	print("-".repeat(40))
	
	var cities = CityWeatherData.get_all_cities()
	var total_pop = 0
	
	for city_name in cities:
		var display_name = CityWeatherData.get_city_display_name(city_name)
		var population = CityWeatherData.get_city_starting_population(city_name)
		var city_type = CityWeatherData.get_city_type(city_name)
		total_pop += population
		
		print("%s (%s): %s" % [display_name, city_type.capitalize(), _format_number(population)])
	
	print("Total Population: %s" % _format_number(total_pop))
	print("")

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

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Manual scenario advance
				demo_timer = scenario_duration
				print("\n⏭️  Advancing to next scenario...")
			
			KEY_P:
				# Show current population status
				show_population_impact_summary()
			
			KEY_W:
				# Show current weather assessment
				show_weather_assessment_summary()
			
			KEY_R:
				# Reset all populations to starting values
				var cities = CityWeatherData.get_all_cities()
				for city_name in cities:
					var starting_pop = CityWeatherData.get_city_starting_population(city_name)
					CityWeatherData.set_city_current_population(city_name, starting_pop)
				print("\n🔄 All populations reset to starting values")
			
			KEY_ESCAPE:
				# Quit demo
				print("\n👋 Weather Impact System Demo Complete!")
				get_tree().quit()

func _exit_tree():
	print("\n=== FINAL POPULATION REPORT ===")
	show_population_impact_summary()
	print("\nDemo completed successfully! 🎉")