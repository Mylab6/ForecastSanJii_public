extends GutTest

# Test the JSON-based city data system

func test_json_loading():
	# Test that cities load from JSON
	CityWeatherData.load_cities_from_json()
	
	var cities = CityWeatherData.get_all_cities()
	assert_gt(cities.size(), 0, "Should load cities from JSON")
	assert_eq(cities.size(), 7, "Should load all 7 cities from JSON")

func test_city_data_structure():
	# Test that city data has all expected fields
	CityWeatherData.initialize_temperatures()
	
	var city_info = CityWeatherData.get_city_info("CIUDADLONG")
	
	# Check required fields
	assert_true(city_info.has("position"), "City should have position")
	assert_true(city_info.has("name"), "City should have display name")
	assert_true(city_info.has("population"), "City should have population")
	assert_true(city_info.has("elevation"), "City should have elevation")
	assert_true(city_info.has("type"), "City should have type")
	assert_true(city_info.has("temperature"), "City should have temperature")
	assert_true(city_info.has("weather_status"), "City should have weather status")

func test_city_positions():
	# Test that positions are loaded correctly from JSON
	CityWeatherData.load_cities_from_json()
	
	var ciudadlong_pos = CityWeatherData.get_city_position("CIUDADLONG")
	assert_eq(ciudadlong_pos, Vector2(0.45, 0.35), "CIUDADLONG position should match JSON")
	
	var puertoshan_pos = CityWeatherData.get_city_position("PUERTOSHAN")
	assert_eq(puertoshan_pos, Vector2(0.65, 0.45), "PUERTOSHAN position should match JSON")

func test_city_display_names():
	# Test that display names are loaded from JSON
	CityWeatherData.load_cities_from_json()
	
	var display_name = CityWeatherData.get_city_display_name("CIUDADLONG")
	assert_eq(display_name, "Ciudad Long", "Should use display name from JSON")
	
	var puerto_name = CityWeatherData.get_city_display_name("PUERTOSHAN")
	assert_eq(puerto_name, "Puerto Shan", "Should use display name from JSON")

func test_city_population_data():
	# Test population data from JSON
	CityWeatherData.load_cities_from_json()
	
	var ciudadlong_pop = CityWeatherData.get_city_population("CIUDADLONG")
	assert_eq(ciudadlong_pop, 125000, "CIUDADLONG should have correct population")
	
	var montanawei_pop = CityWeatherData.get_city_population("MONTAÑAWEI")
	assert_eq(montanawei_pop, 67000, "MONTAÑAWEI should have correct population")

func test_city_elevation_data():
	# Test elevation data from JSON
	CityWeatherData.load_cities_from_json()
	
	var montanawei_elev = CityWeatherData.get_city_elevation("MONTAÑAWEI")
	assert_eq(montanawei_elev, 320, "MONTAÑAWEI should be at 320m elevation")
	
	var puertoshan_elev = CityWeatherData.get_city_elevation("PUERTOSHAN")
	assert_eq(puertoshan_elev, 12, "PUERTOSHAN should be at 12m elevation (coastal)")

func test_city_types():
	# Test city type classification from JSON
	CityWeatherData.load_cities_from_json()
	
	var ciudadlong_type = CityWeatherData.get_city_type("CIUDADLONG")
	assert_eq(ciudadlong_type, "urban", "CIUDADLONG should be urban type")
	
	var puertoshan_type = CityWeatherData.get_city_type("PUERTOSHAN")
	assert_eq(puertoshan_type, "coastal", "PUERTOSHAN should be coastal type")
	
	var montanawei_type = CityWeatherData.get_city_type("MONTAÑAWEI")
	assert_eq(montanawei_type, "mountain", "MONTAÑAWEI should be mountain type")

func test_cities_by_type():
	# Test filtering cities by type
	CityWeatherData.load_cities_from_json()
	
	var coastal_cities = CityWeatherData.get_cities_by_type("coastal")
	assert_gt(coastal_cities.size(), 0, "Should have coastal cities")
	assert_true(coastal_cities.has("PUERTOSHAN"), "PUERTOSHAN should be in coastal cities")
	assert_true(coastal_cities.has("BAHÍA AZUL"), "BAHÍA AZUL should be in coastal cities")
	
	var mountain_cities = CityWeatherData.get_cities_by_type("mountain")
	assert_gt(mountain_cities.size(), 0, "Should have mountain cities")
	assert_true(mountain_cities.has("MONTAÑAWEI"), "MONTAÑAWEI should be in mountain cities")

func test_metadata_loading():
	# Test that metadata is loaded from JSON
	CityWeatherData.load_cities_from_json()
	
	var metadata = CityWeatherData.get_metadata()
	assert_true(metadata.has("total_cities"), "Metadata should include total cities")
	assert_true(metadata.has("total_population"), "Metadata should include total population")
	assert_eq(metadata["total_cities"], 7, "Should show 7 total cities")

func test_temperature_initialization():
	# Test that temperatures are initialized in tropical range
	CityWeatherData.initialize_temperatures()
	
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var temp = CityWeatherData.get_city_temperature(city_name)
		assert_between(temp, 70.0, 88.0, "Temperature should be tropical for " + city_name)

func test_fallback_data():
	# Test fallback data when JSON fails
	# This is harder to test directly, but we can verify the system handles missing cities
	var invalid_city_pos = CityWeatherData.get_city_position("NONEXISTENT")
	assert_eq(invalid_city_pos, Vector2.ZERO, "Should return zero vector for invalid city")
	
	var invalid_city_temp = CityWeatherData.get_city_temperature("NONEXISTENT")
	assert_eq(invalid_city_temp, 75.0, "Should return default temp for invalid city")

func test_radar_integration():
	# Test that MapRadar works with JSON-based cities
	var radar = MapRadar.new()
	radar._ready()
	
	# Should load cities without errors
	var storm_data = radar.get_current_storm_data()
	assert_true(storm_data.has("affected_cities"), "Should track affected cities")
	
	# Should be able to add storms at JSON-loaded cities
	radar.add_storm_at_city("CIUDADLONG", 0.7, "thunderstorm")
	assert_gt(radar.get_weather_count(), 0, "Should add storm at JSON city")

func test_city_summary_output():
	# Test the city summary function (mainly for coverage)
	CityWeatherData.initialize_temperatures()
	
	# This should not crash
	CityWeatherData.print_city_summary()
	
	# Verify data is loaded
	var cities = CityWeatherData.get_all_cities()
	assert_eq(cities.size(), 7, "Summary should show all cities loaded")