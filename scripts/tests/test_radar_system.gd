extends GutTest

# Comprehensive tests for the radar system

var map_radar: MapRadar
var test_echoes: Array[WeatherEcho]

func before_each():
	map_radar = MapRadar.new()
	test_echoes = []

func after_each():
	if map_radar:
		map_radar.queue_free()
	test_echoes.clear()

func test_radar_initialization():
	assert_not_null(map_radar, "MapRadar should be created")
	assert_eq(map_radar.sweep_angle, 0.0, "Sweep angle should start at 0")
	assert_eq(map_radar.sweep_speed, 0.5, "Sweep speed should be 0.5")
	assert_eq(map_radar.max_echoes, 100, "Max echoes should be 100")

func test_weather_echo_generation():
	var scattered = WeatherDataGenerator.generate_scattered_storms(Vector2(0.5, 0.5), 5, 0.6)
	assert_gt(scattered.size(), 0, "Should generate scattered storms")
	assert_le(scattered.size(), 5, "Should not exceed requested count")
	
	for echo in scattered:
		assert_true(echo is WeatherEcho, "Should generate WeatherEcho objects")
		assert_ge(echo.intensity, 0.0, "Intensity should be non-negative")
		assert_le(echo.intensity, 1.0, "Intensity should not exceed 1.0")

func test_supercell_generation():
	var supercell = WeatherDataGenerator.generate_supercell(Vector2(0.5, 0.5), 0.8)
	assert_gt(supercell.size(), 5, "Supercell should have multiple components")
	
	# Check for hook echo and mesocyclone components
	var has_high_intensity = false
	for echo in supercell:
		if echo.intensity > 0.7:
			has_high_intensity = true
			break
	assert_true(has_high_intensity, "Supercell should have high intensity components")

func test_hurricane_generation():
	var hurricane = WeatherDataGenerator.generate_hurricane(Vector2(0.5, 0.5), 0.9, 0.08)
	assert_gt(hurricane.size(), 15, "Hurricane should have many components")
	
	# Check for eyewall structure
	var center_echoes = 0
	for echo in hurricane:
		var distance = echo.position.distance_to(Vector2(0.5, 0.5))
		if distance < 0.12:  # Within eye wall area
			center_echoes += 1
	assert_gt(center_echoes, 10, "Hurricane should have eyewall structure")

func test_weather_motion_update():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.6, 1.0, 10.0, Vector2(0.1, 0.05))
	var initial_pos = echo.position
	
	echo.update(1.0)  # Update by 1 second
	
	assert_ne(echo.position, initial_pos, "Echo position should change")
	assert_eq(echo.age, 1.0, "Echo age should increase")

func test_echo_expiration():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.6, 1.0, 2.0)  # 2 second lifetime
	
	assert_false(echo.is_expired(), "New echo should not be expired")
	
	echo.update(1.5)
	assert_false(echo.is_expired(), "Echo should not be expired before max age")
	
	echo.update(1.0)  # Total age now 2.5
	assert_true(echo.is_expired(), "Echo should be expired after max age")

func test_color_scaling():
	var light_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.2)
	var heavy_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.8)
	
	var light_color = light_echo.get_display_color()
	var heavy_color = heavy_echo.get_display_color()
	
	# Light should be more green, heavy should be more red
	assert_gt(light_color.g, light_color.r, "Light echo should be more green")
	assert_gt(heavy_color.r, heavy_color.g, "Heavy echo should be more red")

func test_radar_performance_limits():
	# Add many echoes to test performance limiting
	for i in range(150):  # More than max_echoes (100)
		var echo = WeatherEcho.new(Vector2(randf(), randf()), randf())
		map_radar.weather_echoes.append(echo)
	
	map_radar._limit_echo_count()
	
	assert_le(map_radar.weather_echoes.size(), map_radar.max_echoes, 
			 "Echo count should be limited to max_echoes")

func test_city_weather_detection():
	# Add weather near MONTAÑAWEI
	var city_pos = map_radar.cities["MONTAÑAWEI"]
	var echo = WeatherEcho.new(city_pos, 0.7)  # High intensity near city
	map_radar.weather_echoes.append(echo)
	
	var weather_data = map_radar.get_weather_at_city("MONTAÑAWEI")
	
	assert_gt(weather_data["max_intensity"], 0.6, "Should detect high intensity weather")
	assert_eq(weather_data["weather_status"], "Heavy Rain", "Should classify as heavy rain")

func test_weather_scenario_setting():
	map_radar.set_weather_scenario("hurricane")
	assert_gt(map_radar.weather_echoes.size(), 10, "Hurricane scenario should create many echoes")
	
	map_radar.set_weather_scenario("clear")
	assert_eq(map_radar.weather_echoes.size(), 0, "Clear scenario should remove all echoes")

func test_storm_addition_at_city():
	var initial_count = map_radar.weather_echoes.size()
	map_radar.add_storm_at_city("CIUDADLONG", 0.8, "supercell")
	
	assert_gt(map_radar.weather_echoes.size(), initial_count, "Should add echoes for storm")

func test_radar_colors():
	# Test reflectivity colors
	var green_color = RadarColors.get_reflectivity_color(15.0)  # Light precipitation
	var red_color = RadarColors.get_reflectivity_color(55.0)    # Heavy precipitation
	
	assert_gt(green_color.g, 0.5, "Light precipitation should be green")
	assert_gt(red_color.r, 0.5, "Heavy precipitation should be red")

func test_velocity_colors():
	var inbound_color = RadarColors.get_velocity_color(-15.0)  # Inbound motion
	var outbound_color = RadarColors.get_velocity_color(15.0)  # Outbound motion
	
	assert_gt(inbound_color.b, 0.3, "Inbound motion should have blue component")
	assert_gt(outbound_color.r, 0.3, "Outbound motion should have red component")

func test_radar_renderer_utilities():
	# Test radar dimension calculation
	var dimensions = RadarRenderer.calculate_radar_dimensions(Vector2(800, 600))
	
	assert_eq(dimensions["center"], Vector2(400, 300), "Center should be at display center")
	assert_gt(dimensions["radius"], 100, "Radius should be reasonable size")

func test_performance_monitoring():
	# Simulate low performance
	map_radar.average_fps = 20.0  # Below threshold
	var initial_max_echoes = map_radar.max_echoes
	
	map_radar._reduce_quality_for_performance()
	
	assert_lt(map_radar.max_echoes, initial_max_echoes, "Should reduce max echoes for performance")

func test_weather_data_generator_random_scenarios():
	for i in range(5):  # Test multiple random scenarios
		var random_weather = WeatherDataGenerator.generate_random_weather_scenario(Rect2(0, 0, 1, 1))
		assert_gt(random_weather.size(), 0, "Random scenario should generate weather")
		
		for echo in random_weather:
			assert_true(echo.position.x >= 0.0 and echo.position.x <= 1.0, "Echo X should be in bounds")
			assert_true(echo.position.y >= 0.0 and echo.position.y <= 1.0, "Echo Y should be in bounds")

func test_echo_screen_position_conversion():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5))  # Center
	var radar_center = Vector2(400, 300)
	var radar_radius = 200.0
	
	var screen_pos = echo.to_screen_position(radar_center, radar_radius)
	assert_eq(screen_pos, radar_center, "Center echo should map to radar center")

func test_weather_echo_fade_alpha():
	var echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.8, 1.0, 10.0)
	
	# Test fade progression
	echo.age = 5.0  # Before fade starts
	assert_eq(echo.get_fade_alpha(), 1.0, "Should be full alpha before fade")
	
	echo.age = 8.5  # Mid fade
	var mid_alpha = echo.get_fade_alpha()
	assert_gt(mid_alpha, 0.0, "Should have some alpha during fade")
	assert_lt(mid_alpha, 1.0, "Should be fading")
	
	echo.age = 10.0  # At expiration
	assert_almost_eq(echo.get_fade_alpha(), 0.0, 0.01, "Should be nearly transparent at expiration")

func test_city_positions_valid():
	for city_name in map_radar.cities:
		var city_pos = map_radar.cities[city_name]
		assert_ge(city_pos.x, 0.0, city_name + " X position should be >= 0")
		assert_le(city_pos.x, 1.0, city_name + " X position should be <= 1")
		assert_ge(city_pos.y, 0.0, city_name + " Y position should be >= 0")
		assert_le(city_pos.y, 1.0, city_name + " Y position should be <= 1")

func test_storm_data_integration():
	# Add various intensity echoes
	map_radar.weather_echoes.append(WeatherEcho.new(Vector2(0.3, 0.3), 0.3))  # Light
	map_radar.weather_echoes.append(WeatherEcho.new(Vector2(0.5, 0.5), 0.6))  # Moderate
	map_radar.weather_echoes.append(WeatherEcho.new(Vector2(0.7, 0.7), 0.9))  # Severe
	
	var storm_data = map_radar.get_current_storm_data()
	
	assert_eq(storm_data["max_intensity"], 0.9, "Should detect maximum intensity")
	assert_eq(storm_data["total_echoes"], 3, "Should count all echoes")
	assert_eq(storm_data["severe_echoes"], 1, "Should count severe echoes correctly")