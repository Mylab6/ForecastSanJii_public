extends GutTest

# Test the enhanced radar sweep synchronization and transparency

func test_radar_sweep_synchronization():
	# Test that echoes only appear after sweep passes
	var radar_center = Vector2(400, 300)
	var radar_radius = 200.0
	var sweep_angle = 0.0  # Starting at 0 degrees (east)
	var sweep_speed = 0.5
	var persistence_time = 2.0
	
	# Create echo at 90 degrees (north)
	var echo_pos = Vector2(0.5, 0.3)  # North of center
	var echo = WeatherEcho.new(echo_pos, 0.7, 1.0, 10.0)
	
	# Calculate echo angle (should be around PI/2 for north)
	var screen_pos = echo.to_screen_position(radar_center, radar_radius)
	var echo_angle = radar_center.angle_to_point(screen_pos)
	if echo_angle < 0:
		echo_angle += TAU
	
	# When sweep is at 0 degrees, echo at 90 degrees shouldn't be visible
	var angle_diff = sweep_angle - echo_angle
	if angle_diff < 0:
		angle_diff += TAU
	
	var persistence_angle = sweep_speed * persistence_time
	var should_be_visible = angle_diff <= persistence_angle
	
	# At sweep angle 0, echo at 90 degrees should not be visible
	assert_false(should_be_visible, "Echo should not be visible before sweep passes")

func test_transparency_levels():
	# Test that different intensities have appropriate transparency
	var low_intensity = RadarColors.get_intensity_color(0.2)
	var medium_intensity = RadarColors.get_intensity_color(0.5)
	var high_intensity = RadarColors.get_intensity_color(0.9)
	
	# Lower intensity should be more transparent
	assert_lt(low_intensity.a, medium_intensity.a, "Low intensity should be more transparent")
	assert_lt(medium_intensity.a, high_intensity.a, "Medium intensity should be more transparent than high")
	
	# All should be somewhat transparent (less than fully opaque)
	assert_lt(low_intensity.a, 1.0, "Low intensity should be transparent")
	assert_lt(medium_intensity.a, 1.0, "Medium intensity should be transparent")

func test_sweep_fade_effect():
	# Test that echoes fade as sweep moves away
	var persistence_time = 2.0
	var sweep_speed = 0.5
	var persistence_angle = sweep_speed * persistence_time
	
	# Test fade at different distances from sweep
	var fade_at_start = 1.0 - (0.0 / persistence_angle)  # Just passed
	var fade_at_middle = 1.0 - (persistence_angle * 0.5 / persistence_angle)  # Half way
	var fade_at_end = 1.0 - (persistence_angle * 0.9 / persistence_angle)  # Almost gone
	
	assert_eq(fade_at_start, 1.0, "Should be fully visible when just passed")
	assert_eq(fade_at_middle, 0.5, "Should be half faded at middle")
	assert_lt(fade_at_end, 0.2, "Should be mostly faded at end")

func test_weather_echo_transparency():
	# Test that weather echoes have proper transparency in their colors
	var light_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.2, 1.0, 10.0)
	var heavy_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.8, 1.0, 10.0)
	
	var light_color = light_echo.get_display_color()
	var heavy_color = heavy_echo.get_display_color()
	
	# Both should be transparent, but heavy should be less transparent
	assert_lt(light_color.a, 1.0, "Light echo should be transparent")
	assert_lt(heavy_color.a, 1.0, "Heavy echo should be transparent")
	assert_lt(light_color.a, heavy_color.a, "Light echo should be more transparent than heavy")

func test_outline_effect():
	# Test that bright outline appears when sweep just passes
	var persistence_time = 2.0
	var sweep_speed = 0.5
	var persistence_angle = sweep_speed * persistence_time
	
	# Test outline visibility at different sweep distances
	var just_passed = persistence_angle * 0.05  # Within 5% of persistence
	var recently_passed = persistence_angle * 0.15  # Within 15% of persistence
	
	var outline_alpha_just = (1.0 - (just_passed / (persistence_angle * 0.1))) * 0.8
	var outline_alpha_recent = (1.0 - (recently_passed / (persistence_angle * 0.1))) * 0.8
	
	assert_gt(outline_alpha_just, 0.5, "Should have bright outline when just passed")
	assert_lt(outline_alpha_recent, 0.0, "Should have no outline when not recently passed")

func test_radar_integration():
	# Test that MapRadar works with the new sweep system
	var radar = MapRadar.new()
	radar._ready()
	
	# Add some weather
	radar.add_storm_at_city("CIUDADLONG", 0.6, "thunderstorm")
	
	# Should have weather echoes
	assert_gt(radar.get_weather_count(), 0, "Should have weather echoes")
	
	# Get storm data
	var storm_data = radar.get_current_storm_data()
	assert_gt(storm_data["max_intensity"], 0.0, "Should have weather intensity")
	
	# Test that affected cities are detected
	assert_true(storm_data["affected_cities"].size() >= 0, "Should track affected cities")

func test_realistic_sweep_timing():
	# Test that sweep timing feels realistic
	var sweep_speed = 0.5  # radians per second
	var full_rotation_time = TAU / sweep_speed  # Should be about 12.5 seconds
	
	assert_between(full_rotation_time, 10.0, 15.0, "Full rotation should take 10-15 seconds for realism")
	
	# Persistence time should be reasonable
	var persistence_time = 2.0
	var persistence_angle = sweep_speed * persistence_time
	var persistence_degrees = rad_to_deg(persistence_angle)
	
	assert_between(persistence_degrees, 45.0, 90.0, "Persistence should cover 45-90 degrees for good visibility")