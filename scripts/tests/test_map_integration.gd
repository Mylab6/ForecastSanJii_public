extends Node

func _ready():
	print("=== Testing MapRadar Integration ===")
	
	# Test MapRadar creation with authentic rendering
	var map_radar = MapRadar.new()
	print("✓ MapRadar created successfully")
	
	# Test authentic rendering setup
	assert(map_radar.use_authentic_rendering, "Should use authentic rendering by default")
	
	# Add to scene tree for proper initialization
	add_child(map_radar)
	
	# Wait a frame for _ready to be called
	await get_tree().process_frame
	
	# Test that authentic renderer was created
	assert(map_radar.authentic_renderer != null, "Authentic renderer should be initialized")
	assert(map_radar.current_storm_data != null, "Storm data should be initialized")
	print("✓ Authentic radar renderer initialized")
	
	# Test storm data generation
	var storm_count = map_radar.current_storm_data.storm_cells.size()
	assert(storm_count > 0, "Should generate storm cells")
	print("✓ Generated ", storm_count, " storm cells")
	
	# Test weather scenario update
	var test_scenario = WeatherScenario.new()
	test_scenario.load_template("Hurricane Elena")
	
	map_radar.update_storm_scenario(test_scenario)
	var hurricane_cells = map_radar.current_storm_data.storm_cells.size()
	assert(hurricane_cells > 10, "Hurricane should generate many cells")
	print("✓ Hurricane scenario generated ", hurricane_cells, " cells")
	
	# Test rendering stats
	var stats = map_radar.get_rendering_stats()
	assert(stats.has("storm_cells_rendered"), "Should provide rendering stats")
	print("✓ Rendering stats: ", stats["storm_cells_rendered"], " cells rendered")
	
	# Test debug mode toggle
	map_radar.set_debug_mode(true)
	assert(map_radar.authentic_renderer.debug_mode, "Debug mode should be enabled")
	print("✓ Debug mode toggle working")
	
	# Test legacy rendering fallback
	map_radar.set_authentic_rendering(false)
	assert(not map_radar.use_authentic_rendering, "Should disable authentic rendering")
	print("✓ Legacy rendering fallback working")
	
	# Test city position mapping
	var display_size = Vector2(800, 600)
	var montanawei_pos = map_radar._get_city_screen_position("MONTAÑAWEI", display_size)
	var expected_pos = Vector2(0.35 * 800, 0.25 * 600)
	assert(montanawei_pos.distance_to(expected_pos) < 1.0, "City position should be mapped correctly")
	print("✓ City position mapping working")
	
	print("MapRadar Integration: All tests passed!")
	print("=== Integration Test Complete ===")
	
	quit()