extends GutTest

# Test the JSON-based city system with population fixes and runtime calculations

func test_starting_vs_current_population():
	# Test that cities have both starting and current population
	CityWeatherData.initialize_temperatures()
	
	var city_info = CityWeatherData.get_city_info("CIUDADLONG")
	
	# Check both population fields exist
	assert_true(city_info.has("starting_population"), "City should have starting_population")
	assert_true(city_info.has("current_population"), "City should have current_population")
	
	# Initially they should be the same
	assert_eq(city_info["starting_population"], city_info["current_population"], 
			  "Starting and current population should initially be equal")

func test_population_functions():
	# Test the new population functions
	CityWeatherData.initialize_temperatures()
	
	var starting_pop = CityWeatherData.get_city_starting_population("CIUDADLONG")
	var current_pop = CityWeatherData.get_city_current_population("CIUDADLONG")
	
	assert_eq(starting_pop, 125000, "CIUDADLONG should have correct starting population")
	assert_eq(current_pop, 125000, "Current population should initially equal starting population")

func test_population_adjustment():
	# Test population adjustment functions
	CityWeatherData.initialize_temperatures()
	
	var initial_pop = CityWeatherData.get_city_current_population("PUERTOSHAN")
	
	# Adjust population down by 1000
	CityWeatherData.adjust_city_population("PUERTOSHAN", -1000)
	var adjusted_pop = CityWeatherData.get_city_current_population("PUERTOSHAN")
	
	assert_eq(adjusted_pop, initial_pop - 1000, "Population should decrease by 1000")
	
	# Starting population should remain unchanged
	var starting_pop = CityWeatherData.get_city_starting_population("PUERTOSHAN")
	assert_eq(starting_pop, 89000, "Starting population should not change")

func test_set_current_population():
	# Test setting current population directly
	CityWeatherData.initialize_temperatures()
	
	CityWeatherData.set_city_current_population("MONTAÑAWEI", 50000)
	var new_pop = CityWeatherData.get_city_current_population("MONTAÑAWEI")
	
	assert_eq(new_pop, 50000, "Should be able to set current population directly")
	
	# Starting population should remain unchanged
	var starting_pop = CityWeatherData.get_city_starting_population("MONTAÑAWEI")
	assert_eq(starting_pop, 67000, "Starting population should not change")

func test_runtime_calculations():
	# Test that totals are calculated at runtime
	CityWeatherData.initialize_temperatures()
	
	var total_cities = CityWeatherData.calculate_total_cities()
	var total_starting = CityWeatherData.calculate_total_starting_population()
	var total_current = CityWeatherData.calculate_total_current_population()
	
	assert_eq(total_cities, 7, "Should calculate 7 total cities")
	assert_eq(total_starting, 407000, "Should calculate correct total starting population")
	assert_eq(total_current, 407000, "Current should initially equal starting population")

func test_runtime_metadata():
	# Test the runtime metadata function
	CityWeatherData.initialize_temperatures()
	
	var metadata = CityWeatherData.get_runtime_metadata()
	
	assert_true(metadata.has("total_cities"), "Metadata should include total cities")
	assert_true(metadata.has("total_starting_population"), "Metadata should include starting population")
	assert_true(metadata.has("total_current_population"), "Metadata should include current population")
	assert_true(metadata.has("last_calculated"), "Metadata should include calculation timestamp")
	
	assert_eq(metadata["total_cities"], 7, "Should show 7 cities")
	assert_eq(metadata["total_starting_population"], 407000, "Should show correct starting total")

func test_population_changes_affect_totals():
	# Test that population changes affect total calculations
	CityWeatherData.initialize_temperatures()
	
	var initial_total = CityWeatherData.calculate_total_current_population()
	
	# Reduce one city's population
	CityWeatherData.adjust_city_population("CIUDADLONG", -10000)
	
	var new_total = CityWeatherData.calculate_total_current_population()
	
	assert_eq(new_total, initial_total - 10000, "Total should reflect population changes")
	
	# Starting total should remain unchanged
	var starting_total = CityWeatherData.calculate_total_starting_population()
	assert_eq(starting_total, 407000, "Starting total should not change")

func test_population_cannot_go_negative():
	# Test that population adjustments cannot go below zero
	CityWeatherData.initialize_temperatures()
	
	# Try to set negative population
	CityWeatherData.set_city_current_population("VALLEGU", -5000)
	var pop_after_negative = CityWeatherData.get_city_current_population("VALLEGU")
	
	assert_eq(pop_after_negative, 0, "Population should not go below zero")
	
	# Try to adjust below zero
	CityWeatherData.set_city_current_population("VALLEGU", 1000)
	CityWeatherData.adjust_city_population("VALLEGU", -2000)
	var pop_after_adjust = CityWeatherData.get_city_current_population("VALLEGU")
	
	assert_eq(pop_after_adjust, 0, "Population adjustment should not go below zero")

func test_city_summary_shows_both_populations():
	# Test that city summary shows both starting and current populations
	CityWeatherData.initialize_temperatures()
	
	# Adjust some populations to make them different
	CityWeatherData.adjust_city_population("CIUDADLONG", -5000)
	CityWeatherData.adjust_city_population("PUERTOSHAN", 2000)
	
	# This should not crash and should show both populations
	CityWeatherData.print_city_summary()
	
	# Verify the populations are different
	var ciudadlong_current = CityWeatherData.get_city_current_population("CIUDADLONG")
	var ciudadlong_starting = CityWeatherData.get_city_starting_population("CIUDADLONG")
	
	assert_ne(ciudadlong_current, ciudadlong_starting, "Current should differ from starting after adjustment")

func test_json_loading_with_starting_population():
	# Test that JSON loading correctly handles starting_population field
	CityWeatherData.load_cities_from_json()
	
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var starting_pop = CityWeatherData.get_city_starting_population(city_name)
		assert_gt(starting_pop, 0, "All cities should have positive starting population: " + city_name)

func test_radar_integration_with_new_population_system():
	# Test that MapRadar works with the new population system
	var radar = MapRadar.new()
	radar._ready()
	
	# Should work without errors
	var storm_data = radar.get_current_storm_data()
	assert_true(storm_data.has("affected_cities"), "Should track affected cities")
	
	# Test adding storm at city (should use new city system)
	radar.add_storm_at_city("CIUDADLONG", 0.7, "thunderstorm")
	assert_gt(radar.get_weather_count(), 0, "Should add storm at city")

func test_population_data_consistency():
	# Test that all cities have consistent population data
	CityWeatherData.initialize_temperatures()
	
	var cities = CityWeatherData.get_all_cities()
	var expected_populations = {
		"CIUDADLONG": 125000,
		"PUERTOSHAN": 89000,
		"MONTAÑAWEI": 67000,
		"PLAYAHAI": 45000,
		"VALLEGU": 38000,
		"BAHÍA AZUL": 28000,
		"MONTAÑA-LONG RIDGE": 15000
	}
	
	for city_name in cities:
		if expected_populations.has(city_name):
			var starting_pop = CityWeatherData.get_city_starting_population(city_name)
			assert_eq(starting_pop, expected_populations[city_name], 
					  "Starting population should match expected for " + city_name)