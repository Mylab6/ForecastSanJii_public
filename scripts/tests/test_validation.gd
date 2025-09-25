extends Node

# Simple validation script to test data models
func _ready():
	print("=== Testing Data Models ===")
	
	test_player_stats()
	test_weather_scenario()
	test_storm_data()
	
	print("=== All Tests Completed ===")
	get_tree().quit()

func test_player_stats():
	print("\n--- Testing PlayerStats ---")
	
	var stats = PlayerStats.new()
	print("✓ PlayerStats created successfully")
	
	# Test initial values
	assert(stats.career_level == "Trainee Meteorologist", "Initial career level incorrect")
	assert(stats.accuracy_rate == 0.0, "Initial accuracy rate incorrect")
	print("✓ Initial values correct")
	
	# Test round update
	stats.update_round_stats(true, 45.0, 100, 50000)
	assert(stats.successful_rounds == 1, "Successful rounds not updated")
	assert(stats.accuracy_rate == 1.0, "Accuracy rate not calculated correctly")
	print("✓ Round update working")
	
	# Test career progression
	for i in range(5):
		stats.update_round_stats(true, 60.0, 50, 25000)
	assert(stats.career_level == "Junior Forecaster", "Career progression not working")
	print("✓ Career progression working")
	
	print("PlayerStats: All tests passed!")

func test_weather_scenario():
	print("\n--- Testing WeatherScenario ---")
	
	var scenario = WeatherScenario.new()
	print("✓ WeatherScenario created successfully")
	
	# Test template loading
	var success = scenario.load_template("Hurricane Elena")
	assert(success, "Failed to load Hurricane Elena template")
	assert(scenario.scenario_name == "Hurricane Elena", "Template name not set")
	assert(scenario.storm_type == "Hurricane", "Storm type not set")
	assert(scenario.correct_response == "EVACUATE NOW", "Correct response not set")
	print("✓ Template loading working")
	
	# Test decision evaluation
	var result = scenario.evaluate_player_decision(
		["Puerto Shan", "Bahía Azul"], "EVACUATE NOW", "HIGH"
	)
	assert(result["correct"], "Correct decision not evaluated properly")
	assert(result["score"] == 100, "Perfect score not calculated")
	print("✓ Decision evaluation working")
	
	# Test available templates
	var templates = scenario.get_available_templates()
	assert(templates.size() > 0, "No templates available")
	assert(templates.has("Hurricane Elena"), "Hurricane Elena template missing")
	print("✓ Template availability working")
	
	print("WeatherScenario: All tests passed!")

func test_storm_data():
	print("\n--- Testing StormData ---")
	
	var storm_data = StormData.new()
	print("✓ StormData created successfully")
	
	# Test cell addition
	storm_data.add_storm_cell(Vector2(100, 200), 15.0, 20.0, 45.0)
	assert(storm_data.storm_cells.size() == 1, "Storm cell not added")
	assert(storm_data.max_reflectivity == 45.0, "Max reflectivity not updated")
	print("✓ Storm cell addition working")
	
	# Test supercell generation
	storm_data.clear_storm_data()
	storm_data.generate_supercell_pattern(Vector2(500, 500), 55.0)
	assert(storm_data.storm_type == "supercell", "Storm type not set")
	assert(storm_data.storm_cells.size() > 1, "Multiple cells not generated")
	assert(storm_data.hook_echo, "Hook echo signature not set")
	assert(storm_data.mesocyclone_present, "Mesocyclone signature not set")
	print("✓ Supercell generation working")
	
	# Test hurricane generation
	storm_data.clear_storm_data()
	storm_data.generate_hurricane_pattern(Vector2(400, 400), 65.0, 30.0)
	assert(storm_data.storm_type == "hurricane", "Hurricane type not set")
	assert(storm_data.storm_cells.size() > 10, "Hurricane cells not generated")
	print("✓ Hurricane generation working")
	
	# Test area analysis
	storm_data.clear_storm_data()
	storm_data.add_storm_cell(Vector2(100, 100), 10.0, 10.0, 40.0)
	storm_data.add_storm_cell(Vector2(200, 200), 10.0, 10.0, 50.0)
	
	var max_dbz = storm_data.get_max_reflectivity_in_area(Vector2(150, 150), 100.0)
	assert(max_dbz == 50.0, "Max reflectivity in area not calculated correctly")
	
	var cells_in_area = storm_data.get_storm_cells_in_area(Vector2(150, 150), 100.0)
	assert(cells_in_area.size() == 2, "Cells in area not found correctly")
	print("✓ Area analysis working")
	
	# Test severe weather detection
	assert(storm_data.has_severe_weather_signatures(), "Severe weather not detected")
	print("✓ Severe weather detection working")
	
	print("StormData: All tests passed!")