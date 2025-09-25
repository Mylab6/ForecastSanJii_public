extends GutTest

# Unit tests for core data model classes
# Tests PlayerStats, WeatherScenario, and StormData functionality

func test_player_stats_initialization():
	var stats = PlayerStats.new()
	
	assert_eq(stats.accuracy_rate, 0.0, "Initial accuracy rate should be 0.0")
	assert_eq(stats.response_time_avg, 0.0, "Initial response time should be 0.0")
	assert_eq(stats.lives_saved, 0, "Initial lives saved should be 0")
	assert_eq(stats.economic_impact, 0, "Initial economic impact should be 0")
	assert_eq(stats.career_level, "Trainee Meteorologist", "Initial career level should be Trainee")
	assert_eq(stats.successful_rounds, 0, "Initial successful rounds should be 0")
	assert_eq(stats.total_rounds, 0, "Initial total rounds should be 0")
	assert_eq(stats.false_evacuations, 0, "Initial false evacuations should be 0")
	assert_eq(stats.missed_threats, 0, "Initial missed threats should be 0")

func test_player_stats_round_update():
	var stats = PlayerStats.new()
	
	# Test successful round
	stats.update_round_stats(true, 45.0, 100, 50000)
	
	assert_eq(stats.total_rounds, 1, "Total rounds should be 1")
	assert_eq(stats.successful_rounds, 1, "Successful rounds should be 1")
	assert_eq(stats.accuracy_rate, 1.0, "Accuracy rate should be 100%")
	assert_eq(stats.response_time_avg, 45.0, "Response time should be 45.0")
	assert_eq(stats.lives_saved, 100, "Lives saved should be 100")
	assert_eq(stats.economic_impact, 50000, "Economic impact should be 50000")

func test_player_stats_career_progression():
	var stats = PlayerStats.new()
	
	# Test career advancement
	for i in range(6):  # Complete 6 successful rounds
		stats.update_round_stats(true, 60.0, 50, 25000)
	
	assert_eq(stats.career_level, "Junior Forecaster", "Should advance to Junior Forecaster at 5+ rounds")
	
	# Test career termination
	stats.record_false_evacuation()
	assert_true(stats.is_career_terminated(), "Career should be terminated after false evacuation")

func test_player_stats_performance_summary():
	var stats = PlayerStats.new()
	stats.update_round_stats(true, 30.0, 200, 75000)
	
	var summary = stats.get_performance_summary()
	
	assert_has(summary, "accuracy_rate", "Summary should include accuracy rate")
	assert_has(summary, "career_level", "Summary should include career level")
	assert_has(summary, "career_terminated", "Summary should include termination status")
	assert_eq(summary["lives_saved"], 200, "Summary should show correct lives saved")

func test_weather_scenario_template_loading():
	var scenario = WeatherScenario.new()
	
	# Test loading Hurricane Elena template
	var success = scenario.load_template("Hurricane Elena")
	
	assert_true(success, "Should successfully load Hurricane Elena template")
	assert_eq(scenario.scenario_name, "Hurricane Elena", "Scenario name should be set")
	assert_eq(scenario.storm_type, "Hurricane", "Storm type should be Hurricane")
	assert_eq(scenario.threat_level, 5, "Threat level should be 5")
	assert_eq(scenario.correct_response, "EVACUATE NOW", "Correct response should be EVACUATE NOW")
	assert_true(scenario.affected_areas.has("Puerto Shan"), "Should affect Puerto Shan")

func test_weather_scenario_custom_creation():
	var scenario = WeatherScenario.new()
	
	var areas = ["San Jii", "Ciudad Long"]
	scenario.create_custom_scenario("Test Storm", "Thunderstorm", areas, 
									40.0, Vector2(15, -10), "SHELTER IN PLACE", "MEDIUM")
	
	assert_eq(scenario.scenario_name, "Test Storm", "Custom scenario name should be set")
	assert_eq(scenario.storm_type, "Thunderstorm", "Custom storm type should be set")
	assert_eq(scenario.threat_level, 3, "Threat level should be 3 for SHELTER/MEDIUM")
	assert_eq(scenario.correct_response, "SHELTER IN PLACE", "Correct response should be set")

func test_weather_scenario_decision_evaluation():
	var scenario = WeatherScenario.new()
	scenario.load_template("CIUDADLONG Supercells")
	
	# Test correct decision
	var correct_result = scenario.evaluate_player_decision(
		["Ciudad Long"], "SHELTER IN PLACE", "HIGH"
	)
	
	assert_true(correct_result["correct"], "Should evaluate correct decision as true")
	assert_true(correct_result["areas_correct"], "Areas should be correct")
	assert_true(correct_result["response_correct"], "Response should be correct")
	assert_true(correct_result["priority_correct"], "Priority should be correct")
	assert_eq(correct_result["score"], 100, "Perfect score should be 100")
	
	# Test false evacuation
	var false_evac_result = scenario.evaluate_player_decision(
		["Ciudad Long"], "EVACUATE NOW", "HIGH"
	)
	
	assert_true(false_evac_result["false_evacuation"], "Should detect false evacuation")
	assert_false(false_evac_result["correct"], "Should not be marked as correct")

func test_weather_scenario_available_templates():
	var scenario = WeatherScenario.new()
	var templates = scenario.get_available_templates()
	
	assert_true(templates.size() > 0, "Should have available templates")
	assert_true(templates.has("Hurricane Elena"), "Should include Hurricane Elena")
	assert_true(templates.has("CIUDADLONG Supercells"), "Should include CIUDADLONG Supercells")

func test_storm_data_initialization():
	var storm_data = StormData.new()
	
	assert_eq(storm_data.storm_cells.size(), 0, "Should start with no storm cells")
	assert_eq(storm_data.max_reflectivity, 0.0, "Max reflectivity should be 0.0")
	assert_false(storm_data.rotation_signature, "Rotation signature should be false")
	assert_false(storm_data.mesocyclone_present, "Mesocyclone should be false")
	assert_false(storm_data.hook_echo, "Hook echo should be false")

func test_storm_data_cell_addition():
	var storm_data = StormData.new()
	
	storm_data.add_storm_cell(Vector2(100, 200), 15.0, 20.0, 45.0)
	
	assert_eq(storm_data.storm_cells.size(), 1, "Should have one storm cell")
	assert_eq(storm_data.max_reflectivity, 45.0, "Max reflectivity should be updated")
	
	var cell = storm_data.storm_cells[0]
	assert_eq(cell.position, Vector2(100, 200), "Cell position should be correct")
	assert_eq(cell.reflectivity, 45.0, "Cell reflectivity should be correct")

func test_storm_data_supercell_generation():
	var storm_data = StormData.new()
	
	storm_data.generate_supercell_pattern(Vector2(500, 500), 55.0)
	
	assert_eq(storm_data.storm_type, "supercell", "Storm type should be supercell")
	assert_true(storm_data.storm_cells.size() > 1, "Should have multiple storm cells")
	assert_true(storm_data.hook_echo, "Should have hook echo signature")
	assert_true(storm_data.mesocyclone_present, "Should have mesocyclone signature")
	assert_true(storm_data.rotation_signature, "Should have rotation signature")

func test_storm_data_hurricane_generation():
	var storm_data = StormData.new()
	
	storm_data.generate_hurricane_pattern(Vector2(400, 400), 65.0, 30.0)
	
	assert_eq(storm_data.storm_type, "hurricane", "Storm type should be hurricane")
	assert_true(storm_data.storm_cells.size() > 10, "Should have many storm cells for eyewall and bands")
	assert_eq(storm_data.max_reflectivity, 65.0, "Max reflectivity should match input")

func test_storm_data_area_analysis():
	var storm_data = StormData.new()
	
	# Add cells at known positions
	storm_data.add_storm_cell(Vector2(100, 100), 10.0, 10.0, 40.0)
	storm_data.add_storm_cell(Vector2(200, 200), 10.0, 10.0, 50.0)
	storm_data.add_storm_cell(Vector2(300, 300), 10.0, 10.0, 30.0)
	
	# Test max reflectivity in area
	var max_dbz = storm_data.get_max_reflectivity_in_area(Vector2(150, 150), 100.0)
	assert_eq(max_dbz, 50.0, "Should find max reflectivity of 50.0 in area")
	
	# Test cells in area
	var cells_in_area = storm_data.get_storm_cells_in_area(Vector2(150, 150), 100.0)
	assert_eq(cells_in_area.size(), 2, "Should find 2 cells in area")

func test_storm_data_severe_weather_detection():
	var storm_data = StormData.new()
	
	# Test with low intensity
	storm_data.add_storm_cell(Vector2(100, 100), 10.0, 10.0, 25.0)
	assert_false(storm_data.has_severe_weather_signatures(), "Should not detect severe weather")
	
	# Test with high intensity
	storm_data.add_storm_cell(Vector2(200, 200), 10.0, 10.0, 55.0)
	assert_true(storm_data.has_severe_weather_signatures(), "Should detect severe weather")

func test_storm_data_summary():
	var storm_data = StormData.new()
	storm_data.generate_supercell_pattern(Vector2(300, 300), 60.0)
	
	var summary = storm_data.get_storm_summary()
	
	assert_has(summary, "storm_type", "Summary should include storm type")
	assert_has(summary, "cell_count", "Summary should include cell count")
	assert_has(summary, "max_reflectivity", "Summary should include max reflectivity")
	assert_has(summary, "severe_signatures", "Summary should include severe signature flag")
	assert_true(summary["severe_signatures"], "Should detect severe signatures in supercell")

func test_storm_data_clear_functionality():
	var storm_data = StormData.new()
	storm_data.generate_hurricane_pattern(Vector2(200, 200), 70.0)
	
	# Verify data exists
	assert_true(storm_data.storm_cells.size() > 0, "Should have storm cells before clear")
	
	storm_data.clear_storm_data()
	
	# Verify data is cleared
	assert_eq(storm_data.storm_cells.size(), 0, "Should have no storm cells after clear")
	assert_eq(storm_data.max_reflectivity, 0.0, "Max reflectivity should be reset")
	assert_false(storm_data.rotation_signature, "Signatures should be reset")