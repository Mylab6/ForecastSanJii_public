extends GutTest

# Unit tests for WeatherEcho class

func test_weather_echo_creation():
	var echo = WeatherEcho.new(Vector2(0.5, 0.3), 0.7, 2.0, 15.0, Vector2(0.01, 0.02), "heavy")
	
	assert_eq(echo.position, Vector2(0.5, 0.3), "Position should be set correctly")
	assert_eq(echo.intensity, 0.7, "Intensity should be set correctly")
	assert_eq(echo.size, 2.0, "Size should be set correctly")
	assert_eq(echo.max_age, 15.0, "Max age should be set correctly")
	assert_eq(echo.velocity, Vector2(0.01, 0.02), "Velocity should be set correctly")
	assert_eq(echo.echo_type, "heavy", "Echo type should be set correctly")
	assert_eq(echo.age, 0.0, "Age should start at 0")

func test_intensity_clamping():
	var echo1 = WeatherEcho.new(Vector2.ZERO, -0.5)  # Below 0
	var echo2 = WeatherEcho.new(Vector2.ZERO, 1.5)   # Above 1
	
	assert_eq(echo1.intensity, 0.0, "Intensity should be clamped to 0")
	assert_eq(echo2.intensity, 1.0, "Intensity should be clamped to 1")

func test_echo_update():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.5, 1.0, 10.0, Vector2(0.1, 0.05))
	
	echo.update(1.0)  # Update by 1 second
	
	assert_eq(echo.age, 1.0, "Age should increase by delta")
	assert_eq(echo.position, Vector2(0.6, 0.55), "Position should move by velocity * delta")

func test_position_clamping():
	var echo = WeatherEcho.new(Vector2(0.9, 0.9), 0.5, 1.0, 10.0, Vector2(0.5, 0.5))
	
	echo.update(1.0)  # This would move position to (1.4, 1.4)
	
	assert_eq(echo.position, Vector2(1.0, 1.0), "Position should be clamped to bounds")

func test_expiration():
	var echo = WeatherEcho.new(Vector2.ZERO, 0.5, 1.0, 5.0)
	
	assert_false(echo.is_expired(), "New echo should not be expired")
	
	echo.update(3.0)
	assert_false(echo.is_expired(), "Echo should not be expired before max age")
	
	echo.update(2.5)  # Total age now 5.5, max is 5.0
	assert_true(echo.is_expired(), "Echo should be expired after max age")

func test_fade_alpha():
	var echo = WeatherEcho.new(Vector2.ZERO, 0.5, 1.0, 10.0)
	
	# Before fade starts (70% of max age = 7 seconds)
	echo.age = 5.0
	assert_eq(echo.get_fade_alpha(), 1.0, "Alpha should be 1.0 before fade starts")
	
	# At fade start
	echo.age = 7.0
	assert_eq(echo.get_fade_alpha(), 1.0, "Alpha should be 1.0 at fade start")
	
	# Halfway through fade
	echo.age = 8.5
	assert_almost_eq(echo.get_fade_alpha(), 0.5, 0.01, "Alpha should be 0.5 halfway through fade")
	
	# At expiration
	echo.age = 10.0
	assert_almost_eq(echo.get_fade_alpha(), 0.0, 0.01, "Alpha should be 0.0 at expiration")

func test_color_scaling():
	# Test different intensity levels
	var light_echo = WeatherEcho.new(Vector2.ZERO, 0.1)
	var moderate_echo = WeatherEcho.new(Vector2.ZERO, 0.3)
	var heavy_echo = WeatherEcho.new(Vector2.ZERO, 0.7)
	var severe_echo = WeatherEcho.new(Vector2.ZERO, 0.9)
	
	var light_color = light_echo.get_display_color()
	var moderate_color = moderate_echo.get_display_color()
	var heavy_color = heavy_echo.get_display_color()
	var severe_color = severe_echo.get_display_color()
	
	# Light should be green
	assert_gt(light_color.g, 0.7, "Light echo should be green")
	assert_lt(light_color.r, 0.1, "Light echo should have minimal red")
	
	# Moderate should be brighter green
	assert_gt(moderate_color.g, 0.9, "Moderate echo should be bright green")
	
	# Heavy should be orange/yellow
	assert_gt(heavy_color.r, 0.9, "Heavy echo should have high red component")
	assert_gt(heavy_color.g, 0.5, "Heavy echo should have some green component")
	
	# Severe should be red
	assert_gt(severe_color.r, 0.9, "Severe echo should be red")
	assert_lt(severe_color.g, 0.1, "Severe echo should have minimal green")

func test_screen_position_conversion():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5))  # Center of radar
	var radar_center = Vector2(400, 300)
	var radar_radius = 200.0
	
	var screen_pos = echo.to_screen_position(radar_center, radar_radius)
	assert_eq(screen_pos, radar_center, "Center position should map to radar center")
	
	# Test corner position
	var corner_echo = WeatherEcho.new(Vector2(1.0, 1.0))
	var corner_pos = corner_echo.to_screen_position(radar_center, radar_radius)
	assert_eq(corner_pos, radar_center + Vector2(radar_radius, radar_radius), "Corner should map correctly")

func test_dbz_conversion():
	var echo = WeatherEcho.new(Vector2.ZERO, 0.5)
	assert_eq(echo.get_dbz_value(), 30.0, "0.5 intensity should convert to 30 dBZ")
	
	var max_echo = WeatherEcho.new(Vector2.ZERO, 1.0)
	assert_eq(max_echo.get_dbz_value(), 60.0, "1.0 intensity should convert to 60 dBZ")

func test_echo_duplication():
	var original = WeatherEcho.new(Vector2(0.3, 0.7), 0.8, 1.5, 12.0, Vector2(0.02, 0.01), "severe")
	original.age = 5.0
	
	var copy = original.duplicate_echo()
	
	assert_eq(copy.position, original.position, "Copy should have same position")
	assert_eq(copy.intensity, original.intensity, "Copy should have same intensity")
	assert_eq(copy.size, original.size, "Copy should have same size")
	assert_eq(copy.age, original.age, "Copy should have same age")
	assert_eq(copy.velocity, original.velocity, "Copy should have same velocity")
	assert_eq(copy.echo_type, original.echo_type, "Copy should have same type")
	
	# Verify they are separate objects
	copy.age = 10.0
	assert_ne(copy.age, original.age, "Copy should be independent of original")