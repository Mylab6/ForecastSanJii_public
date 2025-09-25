extends GutTest

# Unit tests for ScenarioManager
# Tests weather pattern generation, geographic positioning, and difficulty progression

var scenario_manager: ScenarioManager

func before_each():
	scenario_manager = ScenarioManager.new()
	add_child(scenario_manager)

func after_each():
	if scenario_manager:
		scenario_manager.queue_free()

func test_scenario_manager_initialization():
	assert_not_null(scenario_manager, "ScenarioManager should be created")
	assert_true(scenario_manager.enable_difficulty_progression, "Difficulty progression should be enabled by default")
	assert_true(scenario_manager.seasonal_variation, "Seasonal variation should be enabled by default")
	assert_true(scenario_manager.geographic_realism, "Geographic realism should be enabled by default")

func test_enhanced_scenarios_availability():
	var available = scenario_manager.get_available_scenarios()
	
	assert_true(available.size() > 0, "Should have available scenarios")
	assert_true(available.has("Hurricane Elena - Category 4"), "Should include Hurricane Elena Category 4")
	assert_true(available.has("CIUDADLONG Supercell Complex"), "Should include CIUDADLONG Supercell")
	assert_true(available.has("PUERTOSHAN Sea Breeze Convergence"), "Should include sea breeze scenario")

func test_scenario_template_details():
	var hurricane_details = scenario_manager.get_scenario_details("Hurricane Elena - Category 4")
	
	assert_not_null(hurricane_details, "Should return scenario details")
	assert_eq(hurricane_details["storm_type"], "Hurricane", "Should have correct storm type")
	assert_eq(hurricane_details["threat_level"], 5, "Should have correct threat level")
	assert_eq(hurricane_details["correct_response"], "EVACUATE NOW", "Should have correct response")
	assert_true(hurricane_details["affected_areas"].has("Puerto Shan"), "Should affect Puerto Shan")

func test_difficulty_progression_easy():
	scenario_manager.enable_difficulty_progression = true
	
	# Test early round (should be easy)
	var easy_scenario = scenario_manager.generate_scenario_for_round(3)
	
	assert_not_null(easy_scenario, "Should generate easy scenario")
	assert_true(easy_scenario.threat_level <= 3, "Easy scenario should have low threat level")
	
	# Common easy scenarios
	var easy_names = ["PUERTOSHAN Sea Breeze Convergence", "Valle Gu Flash Flood Risk", "Montaña Ridge Orographic Enhancement"]
	assert_true(easy_scenario.scenario_name in easy_names, "Should be an easy scenario type")

func test_difficulty_progression_medium():
	scenario_manager.enable_difficulty_progression = true
	
	# Test medium round
	var medium_scenario = scenario_manager.generate_scenario_for_round(10)
	
	assert_not_null(medium_scenario, "Should generate medium scenario")
	assert_true(medium_scenario.threat_level >= 3, "Medium scenario should have moderate threat level")

func test_difficulty_progression_hard():
	scenario_manager.enable_difficulty_progression = true
	
	# Test hard round
	var hard_scenario = scenario_manager.generate_scenario_for_round(20)
	
	assert_not_null(hard_scenario, "Should generate hard scenario")
	assert_true(hard_scenario.threat_level >= 4, "Hard scenario should have high threat level")

func test_geographic_positioning_coastal():
	var scenario = WeatherScenario.new()
	scenario.affected_areas = ["Puerto Shan", "Bahía Azul"]
	scenario.storm_type = "Hurricane"
	scenario.storm_intensity = 50.0
	scenario.radar_signature = {}
	
	scenario_manager._apply_geographic_positioning(scenario)
	
	# Coastal storms should be intensified
	assert_true(scenario.storm_intensity > 50.0, "Coastal hurricane should be intensified")
	assert_true(scenario.radar_signature.has("storm_surge_risk"), "Should add storm surge risk")

func test_geographic_positioning_mountainous():
	var scenario = WeatherScenario.new()
	scenario.affected_areas = ["Montaña-Long Ridge", "Valle Gu"]
	scenario.storm_type = "Supercell"
	scenario.storm_intensity = 50.0
	scenario.radar_signature = {}
	
	scenario_manager._apply_geographic_positioning(scenario)
	
	# Mountain storms should have orographic enhancement
	assert_true(scenario.storm_intensity > 50.0, "Mountain supercell should be enhanced")
	assert_true(scenario.radar_signature.has("orographic_enhancement"), "Should add orographic enhancement")

func test_geographic_positioning_urban():
	var scenario = WeatherScenario.new()
	scenario.affected_areas = ["San Jii", "Ciudad Long"]
	scenario.storm_type = "Multi-Cell"
	scenario.storm_intensity = 50.0
	scenario.radar_signature = {}
	
	scenario_manager._apply_geographic_positioning(scenario)
	
	# Urban storms should have heat island effect
	assert_true(scenario.storm_intensity > 50.0, "Urban storm should be enhanced by heat island")
	assert_true(scenario.radar_signature.has("urban_heat_island"), "Should add urban heat island effect")

func test_seasonal_variations_hurricane_season():
	scenario_manager.current_season = "hurricane_season"
	
	var scenario = WeatherScenario.new()
	scenario.storm_type = "Hurricane"
	scenario.storm_intensity = 50.0
	scenario.movement_pattern = Vector2(10, -10)
	
	scenario_manager._apply_seasonal_variations(scenario)
	
	# Hurricane season should intensify tropical systems
	assert_true(scenario.storm_intensity > 50.0, "Hurricane season should intensify hurricanes")
	assert_true(scenario.movement_pattern.length() > Vector2(10, -10).length(), "Should increase movement speed")

func test_seasonal_variations_dry_season():
	scenario_manager.current_season = "dry_season"
	
	var scenario = WeatherScenario.new()
	scenario.storm_type = "Sea Breeze"
	scenario.storm_intensity = 50.0
	
	scenario_manager._apply_seasonal_variations(scenario)
	
	# Dry season should generally weaken storms but enhance sea breeze
	assert_true(scenario.storm_intensity > 50.0, "Sea breeze should be enhanced in dry season")

func test_seasonal_variations_wet_season():
	scenario_manager.current_season = "wet_season"
	
	var scenario = WeatherScenario.new()
	scenario.storm_type = "Multi-Cell"
	scenario.storm_intensity = 50.0
	scenario.movement_pattern = Vector2(20, -15)
	scenario.radar_signature = {}
	
	scenario_manager._apply_seasonal_variations(scenario)
	
	# Wet season should slow storm movement and add training
	assert_true(scenario.movement_pattern.length() < Vector2(20, -15).length(), "Should slow storm movement")
	assert_true(scenario.radar_signature.has("training_storms"), "Should add training storm signature")

func test_difficulty_scaling():
	var scenario = WeatherScenario.new()
	scenario.storm_intensity = 50.0
	scenario.affected_areas = ["San Jii"]
	scenario.correct_areas = ["San Jii"]
	scenario.radar_signature = {}
	
	scenario_manager._apply_difficulty_scaling(scenario, 15)
	
	# Round 15 should have 28% intensity increase (14 * 2%)
	var expected_intensity = 50.0 * 1.28
	assert_almost_eq(scenario.storm_intensity, expected_intensity, 1.0, "Should scale intensity correctly")

func test_difficulty_scaling_complex_scenarios():
	var scenario = WeatherScenario.new()
	scenario.storm_intensity = 50.0
	scenario.affected_areas = ["San Jii"]
	scenario.correct_areas = ["San Jii"]
	scenario.radar_signature = {}
	
	scenario_manager._apply_difficulty_scaling(scenario, 25)
	
	# High rounds should potentially add complexity
	assert_true(scenario.radar_signature.has("storm_evolution"), "Should add storm evolution for high rounds")

func test_primary_region_determination():
	# Test coastal region
	var coastal_areas = ["Puerto Shan", "Bahía Azul"]
	var region = scenario_manager._determine_primary_region(coastal_areas)
	assert_eq(region, "coastal", "Should identify coastal region")
	
	# Test mountainous region
	var mountain_areas = ["Montaña-Long Ridge", "Valle Gu"]
	region = scenario_manager._determine_primary_region(mountain_areas)
	assert_eq(region, "mountainous", "Should identify mountainous region")
	
	# Test urban region
	var urban_areas = ["San Jii", "Ciudad Long"]
	region = scenario_manager._determine_primary_region(urban_areas)
	assert_eq(region, "urban", "Should identify urban region")

func test_adjacent_areas():
	var adjacent = scenario_manager._get_adjacent_areas("San Jii")
	
	assert_true(adjacent.has("Ciudad Long"), "San Jii should be adjacent to Ciudad Long")
	assert_true(adjacent.has("Puerto Shan"), "San Jii should be adjacent to Puerto Shan")
	
	var puerto_adjacent = scenario_manager._get_adjacent_areas("Puerto Shan")
	assert_true(puerto_adjacent.has("San Jii"), "Puerto Shan should be adjacent to San Jii")
	assert_true(puerto_adjacent.has("Bahía Azul"), "Puerto Shan should be adjacent to Bahía Azul")

func test_scenario_history_tracking():
	# Generate several scenarios
	scenario_manager.generate_scenario_for_round(1)
	scenario_manager.generate_scenario_for_round(2)
	scenario_manager.generate_scenario_for_round(3)
	
	var history = scenario_manager.get_scenario_history()
	assert_eq(history.size(), 3, "Should track 3 scenarios in history")
	
	# Reset history
	scenario_manager.reset_scenario_history()
	history = scenario_manager.get_scenario_history()
	assert_eq(history.size(), 0, "History should be empty after reset")

func test_recent_scenario_filtering():
	# Manually add to history
	scenario_manager.scenario_history = ["Hurricane Elena - Category 4", "CIUDADLONG Supercell Complex"]
	
	var all_templates = scenario_manager.get_available_scenarios()
	var filtered = scenario_manager._filter_recent_scenarios(all_templates)
	
	assert_false(filtered.has("Hurricane Elena - Category 4"), "Should filter out recent scenario")
	assert_false(filtered.has("CIUDADLONG Supercell Complex"), "Should filter out recent scenario")
	assert_true(filtered.size() < all_templates.size(), "Filtered list should be smaller")

func test_seasonal_filtering():
	scenario_manager.current_season = "hurricane_season"
	
	var all_templates = scenario_manager.get_available_scenarios()
	var filtered = scenario_manager._filter_by_season(all_templates)
	
	# Should include hurricane scenarios
	assert_true(filtered.has("Hurricane Elena - Category 4"), "Should include hurricane scenarios in hurricane season")
	assert_true(filtered.has("Hurricane Elena - Category 2"), "Should include hurricane scenarios in hurricane season")

func test_storm_evolution():
	# Create a hurricane scenario
	var scenario = WeatherScenario.new()
	scenario.storm_type = "Hurricane"
	scenario.storm_intensity = 55.0
	scenario_manager.current_scenario = scenario
	
	var initial_intensity = scenario.storm_intensity
	
	# Apply evolution
	scenario_manager._apply_storm_evolution()
	
	# Intensity should change (could increase or decrease)
	assert_ne(scenario.storm_intensity, initial_intensity, "Storm intensity should evolve")
	assert_true(scenario.storm_intensity >= 30.0, "Intensity should not go below minimum")
	assert_true(scenario.storm_intensity <= 70.0, "Intensity should not exceed maximum")

func test_meteorological_validation():
	var scenario = WeatherScenario.new()
	scenario.storm_type = "Hurricane"
	scenario.storm_intensity = 25.0  # Low for hurricane
	scenario.affected_areas = ["Puerto Shan"]
	
	var validation = scenario_manager.validate_scenario_meteorology(scenario)
	
	assert_true(validation["valid"], "Should still be valid despite warnings")
	assert_true(validation["warnings"].size() > 0, "Should have warnings for low hurricane intensity")

func test_geographic_info_access():
	var geo_info = scenario_manager.get_geographic_info()
	
	assert_true(geo_info.has("coastal"), "Should include coastal region info")
	assert_true(geo_info.has("mountainous"), "Should include mountainous region info")
	assert_true(geo_info.has("urban"), "Should include urban region info")
	
	var coastal_info = geo_info["coastal"]
	assert_true(coastal_info.has("areas"), "Coastal info should include areas")
	assert_true(coastal_info.has("storm_types"), "Coastal info should include storm types")

func test_seasonal_override():
	scenario_manager.set_seasonal_override("dry_season")
	assert_eq(scenario_manager.current_season, "dry_season", "Should override season")
	
	scenario_manager.set_seasonal_override("hurricane_season")
	assert_eq(scenario_manager.current_season, "hurricane_season", "Should change to hurricane season")

func test_complete_scenario_generation_flow():
	# Test complete flow from generation to validation
	var scenario = scenario_manager.generate_scenario_for_round(8)
	
	assert_not_null(scenario, "Should generate complete scenario")
	assert_true(scenario.scenario_name.length() > 0, "Should have scenario name")
	assert_true(scenario.storm_type.length() > 0, "Should have storm type")
	assert_true(scenario.affected_areas.size() > 0, "Should have affected areas")
	assert_true(scenario.correct_response.length() > 0, "Should have correct response")
	assert_true(scenario.storm_intensity > 0.0, "Should have positive storm intensity")
	
	# Validate the generated scenario
	var validation = scenario_manager.validate_scenario_meteorology(scenario)
	assert_true(validation["valid"], "Generated scenario should be meteorologically valid")

func test_scenario_variety():
	# Generate multiple scenarios and check for variety
	var generated_types = {}
	
	for i in range(10):
		var scenario = scenario_manager.generate_scenario_for_round(i + 1)
		if not generated_types.has(scenario.storm_type):
			generated_types[scenario.storm_type] = 0
		generated_types[scenario.storm_type] += 1
	
	assert_true(generated_types.size() > 1, "Should generate variety of storm types")
	print("Generated storm types: ", generated_types.keys())