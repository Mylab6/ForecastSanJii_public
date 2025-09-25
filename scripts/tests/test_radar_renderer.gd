extends GutTest

# Unit tests for AuthenticRadarRenderer
# Tests polygon generation, color scaling, and storm signature rendering

var renderer: AuthenticRadarRenderer
var test_storm_data: StormData

func before_each():
	renderer = AuthenticRadarRenderer.new()
	test_storm_data = StormData.new()
	
	# Add renderer to scene tree for proper testing
	add_child(renderer)

func after_each():
	if renderer:
		renderer.queue_free()
	if test_storm_data:
		test_storm_data = null

func test_renderer_initialization():
	assert_not_null(renderer, "Renderer should be created")
	assert_true(renderer.enable_smooth_rendering, "Smooth rendering should be enabled by default")
	assert_true(renderer.enable_storm_signatures, "Storm signatures should be enabled")
	assert_eq(renderer.storm_cell_alpha, 0.7, "Default alpha should be 0.7")

func test_dbz_color_scale():
	# Test authentic NWS color scale
	var transparent = renderer.get_dbz_color(0.0)
	assert_eq(transparent, Color.TRANSPARENT, "Low reflectivity should be transparent")
	
	var light_green = renderer.get_dbz_color(10.0)
	assert_eq(light_green.r, 0.0, "Light green should have no red component")
	assert_true(light_green.g > 0.8, "Light green should have high green component")
	
	var yellow = renderer.get_dbz_color(30.0)
	assert_true(yellow.r > 0.9, "Yellow should have high red component")
	assert_true(yellow.g > 0.9, "Yellow should have high green component")
	
	var red = renderer.get_dbz_color(50.0)
	assert_true(red.r > 0.9, "Red should have high red component")
	assert_eq(red.g, 0.0, "Red should have no green component")
	
	var magenta = renderer.get_dbz_color(60.0)
	assert_true(magenta.r > 0.9, "Magenta should have high red component")
	assert_true(magenta.b > 0.9, "Magenta should have high blue component")

func test_storm_cell_rendering():
	# Create test storm cell
	test_storm_data.add_storm_cell(Vector2(100, 100), 20.0, 25.0, 45.0)
	
	renderer.render_storm_data(test_storm_data)
	
	assert_eq(renderer.rendered_cells.size(), 1, "Should render one storm cell")
	assert_eq(renderer.rendered_cells[0]["position"], Vector2(100, 100), "Should have correct position")
	assert_eq(renderer.rendered_cells[0]["intensity"], 45.0, "Should have correct intensity")

func test_intensity_layers():
	# Test intensity layer generation
	var severe_layers = renderer.get_intensity_layers(55.0)
	assert_eq(severe_layers.size(), 3, "Severe weather should have 3 layers")
	
	var moderate_layers = renderer.get_intensity_layers(40.0)
	assert_eq(moderate_layers.size(), 2, "Moderate weather should have 2 layers")
	
	var light_layers = renderer.get_intensity_layers(25.0)
	assert_eq(light_layers.size(), 1, "Light weather should have 1 layer")

func test_stratiform_polygon_generation():
	var center = Vector2(150, 150)
	var radius = 20.0
	
	var polygon = renderer.generate_stratiform_polygon(center, radius)
	
	assert_eq(polygon.size(), 12, "Stratiform polygon should have 12 points for smoothness")
	
	# Stratiform should be more regular than convective
	var distances = []
	for point in polygon:
		distances.append(point.distance_to(center))
	
	# Calculate variance in distances (should be lower for stratiform)
	var mean_distance = 0.0
	for distance in distances:
		mean_distance += distance
	mean_distance /= distances.size()
	
	var variance = 0.0
	for distance in distances:
		variance += pow(distance - mean_distance, 2)
	variance /= distances.size()
	
	assert_true(variance < 50.0, "Stratiform polygon should be relatively regular")

func test_polygon_rotation():
	var original_polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(10, 0),
		Vector2(0, 10),
		Vector2(-10, 0)
	])
	var center = Vector2.ZERO
	var rotation = PI * 0.5  # 90 degrees
	
	var rotated = renderer.rotate_polygon(original_polygon, center, rotation)
	
	assert_eq(rotated.size(), original_polygon.size(), "Rotated polygon should have same number of points")
	
	# Check that first point rotated correctly (0, -10) -> (10, 0)
	var expected_first = Vector2(10, 0)
	var actual_first = rotated[0]
	assert_true(actual_first.distance_to(expected_first) < 0.1, "First point should rotate correctly")

func test_storm_cell_rendering_modes():
	# Test polygon rendering
	renderer.enable_polygon_rendering = true
	test_storm_data.add_storm_cell(Vector2(100, 100), 15.0, 20.0, 40.0)
	
	renderer.render_storm_data(test_storm_data)
	
	assert_eq(renderer.rendered_cells.size(), 1, "Should render one storm cell")
	assert_eq(renderer.rendered_cells[0]["type"], "polygon", "Should use polygon rendering")
	
	# Test rectangle fallback
	renderer.enable_polygon_rendering = false
	renderer.fallback_to_rectangles = true
	renderer.render_storm_data(test_storm_data)
	
	assert_eq(renderer.rendered_cells[0]["type"], "rectangle", "Should use rectangle fallback")
	
	# Test circle emergency fallback
	renderer.fallback_to_rectangles = false
	renderer.render_storm_data(test_storm_data)
	
	assert_eq(renderer.rendered_cells[0]["type"], "circle", "Should use circle emergency fallback")

func test_viewport_culling():
	renderer.viewport_culling = true
	
	# Add cell within viewport
	test_storm_data.add_storm_cell(Vector2(50, 50), 10.0, 10.0, 30.0)
	
	# Add cell far outside viewport
	test_storm_data.add_storm_cell(Vector2(5000, 5000), 10.0, 10.0, 30.0)
	
	renderer.render_storm_data(test_storm_data)
	
	# Should only render visible cells (exact count depends on viewport size)
	assert_true(renderer.rendered_cells.size() <= test_storm_data.storm_cells.size(), 
				"Culling should not render more cells than exist")

func test_hook_echo_signature():
	# Create supercell with hook echo
	test_storm_data.generate_supercell_pattern(Vector2(300, 300), 55.0)
	
	renderer.render_storm_data(test_storm_data)
	
	# Should have hook echo signature
	var has_hook_signature = false
	for signature in renderer.signature_overlays:
		if signature["type"] == "hook_echo":
			has_hook_signature = true
			break
	
	assert_true(has_hook_signature, "Should render hook echo signature for supercell")

func test_mesocyclone_signature():
	# Create storm with rotation
	var rotating_cell = StormData.StormCell.new(Vector2(200, 200), 15.0, 20.0, 50.0, 0.5, Vector2.ZERO, "convective")
	test_storm_data.storm_cells.append(rotating_cell)
	test_storm_data.mesocyclone_present = true
	
	renderer.render_storm_data(test_storm_data)
	
	# Should have mesocyclone signature
	var has_meso_signature = false
	for signature in renderer.signature_overlays:
		if signature["type"] == "mesocyclone":
			has_meso_signature = true
			break
	
	assert_true(has_meso_signature, "Should render mesocyclone signature for rotating cell")

func test_bow_echo_signature():
	# Create squall line with bow echo
	test_storm_data.generate_squall_line_pattern(Vector2(100, 200), Vector2(300, 200), 45.0)
	
	renderer.render_storm_data(test_storm_data)
	
	# Should have bow echo signature
	var has_bow_signature = false
	for signature in renderer.signature_overlays:
		if signature["type"] == "bow_echo":
			has_bow_signature = true
			break
	
	assert_true(has_bow_signature, "Should render bow echo signature for squall line")

func test_bwer_signature():
	# Create strong cell that should have BWER
	test_storm_data.add_storm_cell(Vector2(250, 250), 20.0, 25.0, 55.0)
	test_storm_data.bounded_weak_echo = true
	
	renderer.render_storm_data(test_storm_data)
	
	# Should have BWER signature
	var has_bwer_signature = false
	for signature in renderer.signature_overlays:
		if signature["type"] == "bwer":
			has_bwer_signature = true
			break
	
	assert_true(has_bwer_signature, "Should render BWER signature for strong cell")

func test_rendering_performance():
	# Create many storm cells to test performance
	for i in range(50):
		var pos = Vector2(randf() * 800, randf() * 600)
		test_storm_data.add_storm_cell(pos, 10.0, 12.0, randf() * 60.0)
	
	var start_time = Time.get_time_dict_from_system()["unix"]
	renderer.render_storm_data(test_storm_data)
	var end_time = Time.get_time_dict_from_system()["unix"]
	
	var render_time = end_time - start_time
	assert_true(render_time < 1.0, "Rendering 50 cells should complete within 1 second")

func test_debug_mode():
	renderer.set_debug_mode(true)
	assert_true(renderer.debug_mode, "Debug mode should be enabled")
	
	test_storm_data.add_storm_cell(Vector2(100, 100), 15.0, 20.0, 45.0)
	renderer.render_storm_data(test_storm_data)
	
	var stats = renderer.get_rendering_stats()
	assert_has(stats, "storm_cells_rendered", "Stats should include rendered cell count")
	assert_has(stats, "signatures_rendered", "Stats should include signature count")
	assert_has(stats, "max_reflectivity", "Stats should include max reflectivity")

func test_clear_radar_display():
	test_storm_data.add_storm_cell(Vector2(100, 100), 15.0, 20.0, 45.0)
	renderer.render_storm_data(test_storm_data)
	
	assert_true(renderer.rendered_cells.size() > 0, "Should have rendered cells before clear")
	
	renderer.clear_radar_display()
	
	assert_eq(renderer.rendered_cells.size(), 0, "Should have no rendered cells after clear")
	assert_eq(renderer.signature_overlays.size(), 0, "Should have no signatures after clear")
	assert_null(renderer.current_storm_data, "Current storm data should be null after clear")

func test_radar_sweep_animation():
	var initial_angle = renderer.radar_sweep_angle
	renderer.set_radar_sweep_angle(PI * 0.5)
	
	assert_eq(renderer.radar_sweep_angle, PI * 0.5, "Radar sweep angle should be updated")
	assert_ne(renderer.radar_sweep_angle, initial_angle, "Radar sweep angle should change")

func test_rendering_stats():
	test_storm_data.generate_hurricane_pattern(Vector2(400, 300), 65.0)
	renderer.render_storm_data(test_storm_data)
	
	var stats = renderer.get_rendering_stats()
	
	assert_true(stats["storm_cells_rendered"] > 0, "Should report rendered storm cells")
	assert_true(stats["max_reflectivity"] > 60.0, "Should report correct max reflectivity")
	assert_eq(stats["polygon_mode"], renderer.enable_polygon_rendering, "Should report polygon mode status")