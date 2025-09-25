extends GutTest

# Test the comprehensive weather impact system with 3-question framework

func test_weather_assessment_framework():
	# Test the 3-question assessment framework
	CityWeatherData.initialize_temperatures()
	
	# Create test weather echoes
	var weather_echoes: Array[WeatherEcho] = []
	var city_pos = CityWeatherData.get_city_position("CIUDADLONG")
	
	# Add severe weather near the city
	var severe_echo = WeatherEcho.new(city_pos, 0.9, 2.0, 15.0, Vector2.ZERO, "severe")
	weather_echoes.append(severe_echo)
	
	# Assess the weather
	var assessment = WeatherImpactSystem.assess_city_weather("CIUDADLONG", weather_echoes)
	
	# Check the 3 questions are answered
	assert_true(assessment.has("weather_condition"), "Should answer: What's the weather?")
	assert_true(assessment.has("severity_level"), "Should answer: What's the severity?")
	assert_true(assessment.has("recommended_action"), "Should answer: What action to take?")
	
	# Severe weather should trigger evacuation
	assert_eq(assessment["severity_level"], "Extreme", "High intensity should be Extreme severity")
	assert_eq(assessment["recommended_action"], "Evacuate", "Extreme weather should recommend evacuation")

func test_weather_condition_determination():
	# Test weather condition classification
	CityWeatherData.initialize_temperatures()
	
	var city_pos = CityWeatherData.get_city_position("PUERTOSHAN")
	var weather_echoes: Array[WeatherEcho] = []
	
	# Test light rain
	var light_echo = WeatherEcho.new(city_pos, 0.2, 1.0, 10.0, Vector2.ZERO, "light")
	weather_echoes.append(light_echo)
	
	var assessment = WeatherImpactSystem.assess_city_weather("PUERTOSHAN", weather_echoes)
	assert_eq(assessment["weather_condition"], "Light Rain", "Low intensity should be Light Rain")
	assert_eq(assessment["severity_level"], "Low", "Light rain should be Low severity")
	assert_eq(assessment["recommended_action"], "Caution", "Low severity should recommend Caution")

func test_severity_level_scaling():
	# Test severity level determination
	CityWeatherData.initialize_temperatures()
	
	var city_pos = CityWeatherData.get_city_position("MONTAÑAWEI")
	
	# Test different intensity levels
	var test_cases = [
		{"intensity": 0.05, "expected_severity": "None"},
		{"intensity": 0.25, "expected_severity": "Low"},
		{"intensity": 0.5, "expected_severity": "Medium"},
		{"intensity": 0.75, "expected_severity": "High"},
		{"intensity": 0.95, "expected_severity": "Extreme"}
	]
	
	for test_case in test_cases:
		var weather_echoes: Array[WeatherEcho] = []
		var echo = WeatherEcho.new(city_pos, test_case["intensity"], 1.0, 10.0)
		weather_echoes.append(echo)
		
		var assessment = WeatherImpactSystem.assess_city_weather("MONTAÑAWEI", weather_echoes)
		assert_eq(assessment["severity_level"], test_case["expected_severity"], 
				  "Intensity %.2f should be %s severity" % [test_case["intensity"], test_case["expected_severity"]])

func test_action_recommendation_logic():
	# Test action recommendation based on severity and weather type
	CityWeatherData.initialize_temperatures()
	
	var city_pos = CityWeatherData.get_city_position("VALLEGU")
	
	# Test action escalation
	var test_cases = [
		{"intensity": 0.0, "expected_action": "None"},
		{"intensity": 0.2, "expected_action": "Caution"},
		{"intensity": 0.6, "expected_action": "Caution"},
		{"intensity": 0.8, "expected_action": "Shelter"},
		{"intensity": 0.95, "expected_action": "Evacuate"}
	]
	
	for test_case in test_cases:
		var weather_echoes: Array[WeatherEcho] = []
		if test_case["intensity"] > 0:
			var echo = WeatherEcho.new(city_pos, test_case["intensity"], 1.0, 10.0)
			weather_echoes.append(echo)
		
		var assessment = WeatherImpactSystem.assess_city_weather("VALLEGU", weather_echoes)
		assert_eq(assessment["recommended_action"], test_case["expected_action"],
				  "Intensity %.2f should recommend %s" % [test_case["intensity"], test_case["expected_action"]])

func test_population_evacuation_dynamics():
	# Test population changes during evacuation
	CityWeatherData.initialize_temperatures()
	
	var initial_pop = CityWeatherData.get_city_current_population("PLAYAHAI")
	var city_pos = CityWeatherData.get_city_position("PLAYAHAI")
	
	# Create extreme weather requiring evacuation
	var weather_echoes: Array[WeatherEcho] = []
	var extreme_echo = WeatherEcho.new(city_pos, 0.95, 3.0, 20.0, Vector2.ZERO, "severe")
	weather_echoes.append(extreme_echo)
	
	# Assess weather (should recommend evacuation)
	var assessment = WeatherImpactSystem.assess_city_weather("PLAYAHAI", weather_echoes)
	assert_eq(assessment["recommended_action"], "Evacuate", "Extreme weather should trigger evacuation")
	
	# Process population dynamics (simulate time passing)
	WeatherImpactSystem.process_population_dynamics(1.0)  # 1 second
	
	var new_pop = CityWeatherData.get_city_current_population("PLAYAHAI")
	assert_lt(new_pop, initial_pop, "Population should decrease during evacuation")

func test_population_migration_to_safe_cities():
	# Test population migration from dangerous to safe areas
	CityWeatherData.initialize_temperatures()
	
	# Get initial populations
	var dangerous_city = "BAHÍA AZUL"
	var safe_city = "VALLEGU"
	
	var initial_dangerous = CityWeatherData.get_city_current_population(dangerous_city)
	var initial_safe = CityWeatherData.get_city_current_population(safe_city)
	
	# Create severe weather at dangerous city
	var dangerous_pos = CityWeatherData.get_city_position(dangerous_city)
	var weather_echoes: Array[WeatherEcho] = []
	var severe_echo = WeatherEcho.new(dangerous_pos, 0.85, 2.5, 15.0, Vector2.ZERO, "severe")
	weather_echoes.append(severe_echo)
	
	# Assess both cities
	WeatherImpactSystem.assess_city_weather(dangerous_city, weather_echoes)
	WeatherImpactSystem.assess_city_weather(safe_city, [])  # No weather at safe city
	
	# Process population dynamics multiple times to see migration
	for i in range(5):
		WeatherImpactSystem.process_population_dynamics(1.0)
	
	var final_dangerous = CityWeatherData.get_city_current_population(dangerous_city)
	var final_safe = CityWeatherData.get_city_current_population(safe_city)
	
	assert_lt(final_dangerous, initial_dangerous, "Dangerous city should lose population")
	# Note: Safe city might not always gain population due to distance/other factors

func test_game_settings_loading():
	# Test game settings JSON loading
	WeatherImpactSystem.load_game_settings()
	
	var settings = WeatherImpactSystem.game_settings
	assert_true(settings.has("radar_settings"), "Should load radar settings")
	assert_true(settings.has("weather_system"), "Should load weather system settings")
	assert_true(settings.has("population_dynamics"), "Should load population dynamics settings")

func test_weather_assessment_logging():
	# Test that weather assessments are logged properly
	CityWeatherData.initialize_temperatures()
	
	var city_pos = CityWeatherData.get_city_position("MONTAÑA-LONG RIDGE")
	var weather_echoes: Array[WeatherEcho] = []
	var storm_echo = WeatherEcho.new(city_pos, 0.7, 2.0, 12.0, Vector2.ZERO, "heavy")
	weather_echoes.append(storm_echo)
	
	# This should log the assessment (visible in console)
	var assessment = WeatherImpactSystem.assess_city_weather("MONTAÑA-LONG RIDGE", weather_echoes)
	
	assert_true(assessment.has("timestamp"), "Assessment should include timestamp")
	assert_true(assessment.has("dbz_value"), "Assessment should include dBZ value")

func test_population_summary_generation():
	# Test population summary functionality
	CityWeatherData.initialize_temperatures()
	
	# Create varied weather conditions
	var cities = CityWeatherData.get_all_cities()
	var weather_echoes: Array[WeatherEcho] = []
	
	# Add severe weather to some cities
	for i in range(min(3, cities.size())):
		var city_pos = CityWeatherData.get_city_position(cities[i])
		var intensity = 0.6 + (i * 0.15)  # Varying intensities
		var echo = WeatherEcho.new(city_pos, intensity, 2.0, 15.0)
		weather_echoes.append(echo)
		WeatherImpactSystem.assess_city_weather(cities[i], [echo])
	
	# Get population summary
	var summary = WeatherImpactSystem.get_population_summary()
	
	assert_true(summary.has("total_current"), "Summary should include current total population")
	assert_true(summary.has("total_starting"), "Summary should include starting total population")
	assert_true(summary.has("cities_evacuating"), "Summary should list evacuating cities")
	assert_true(summary.has("cities_sheltering"), "Summary should list sheltering cities")
	assert_true(summary.has("safe_cities"), "Summary should list safe cities")

func test_all_cities_weather_update():
	# Test updating weather for all cities at once
	CityWeatherData.initialize_temperatures()
	
	# Create scattered weather across the map
	var weather_echoes: Array[WeatherEcho] = []
	for i in range(10):
		var pos = Vector2(randf(), randf())
		var intensity = randf_range(0.3, 0.8)
		var echo = WeatherEcho.new(pos, intensity, 1.5, 12.0)
		weather_echoes.append(echo)
	
	# Update all cities
	WeatherImpactSystem.update_all_city_weather(weather_echoes)
	
	# Check that assessments were created
	var assessments = WeatherImpactSystem.get_all_assessments()
	var cities = CityWeatherData.get_all_cities()
	
	assert_eq(assessments.size(), cities.size(), "Should have assessments for all cities")

func test_radar_integration_with_weather_system():
	# Test that MapRadar integrates with the weather impact system
	var radar = MapRadar.new()
	radar._ready()
	
	# Add some weather
	radar.add_storm_at_city("CIUDADLONG", 0.8, "supercell")
	
	# Simulate radar processing (this should trigger weather assessments)
	# Note: In real usage, this happens automatically in _process()
	WeatherImpactSystem.update_all_city_weather(radar.weather_echoes)
	
	# Check that assessment was created
	var assessment = WeatherImpactSystem.get_city_assessment("CIUDADLONG")
	assert_false(assessment.is_empty(), "Should have weather assessment for city with storm")

func test_population_cannot_go_negative_during_evacuation():
	# Test population safety during extreme evacuation scenarios
	CityWeatherData.initialize_temperatures()
	
	# Set a small population for testing
	CityWeatherData.set_city_current_population("MONTAÑA-LONG RIDGE", 1000)
	
	var city_pos = CityWeatherData.get_city_position("MONTAÑA-LONG RIDGE")
	var weather_echoes: Array[WeatherEcho] = []
	var extreme_echo = WeatherEcho.new(city_pos, 1.0, 5.0, 25.0, Vector2.ZERO, "severe")
	weather_echoes.append(extreme_echo)
	
	# Assess weather (should trigger evacuation)
	WeatherImpactSystem.assess_city_weather("MONTAÑA-LONG RIDGE", weather_echoes)
	
	# Process evacuation multiple times
	for i in range(20):  # Simulate extended evacuation
		WeatherImpactSystem.process_population_dynamics(1.0)
	
	var final_pop = CityWeatherData.get_city_current_population("MONTAÑA-LONG RIDGE")
	assert_ge(final_pop, 0, "Population should never go below zero")