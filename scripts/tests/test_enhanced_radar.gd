extends GutTest

# Test the enhanced radar system with temperature data

func test_city_temperature_initialization():
	# Test that cities get initialized with tropical temperatures
	CityWeatherData.initialize_temperatures()
	
	var cities = CityWeatherData.get_all_cities()
	assert_gt(cities.size(), 0, "Should have cities defined")
	
	for city_name in cities:
		var temp = CityWeatherData.get_city_temperature(city_name)
		assert_between(temp, 70.0, 88.0, "Temperature should be in tropical range for " + city_name)

func test_city_positions():
	# Test that all cities have valid positions
	var cities = CityWeatherData.get_all_cities()
	
	for city_name in cities:
		var pos = CityWeatherData.get_city_position(city_name)
		assert_ne(pos, Vector2.ZERO, "City should have valid position: " + city_name)
		assert_between(pos.x, 0.0, 1.0, "X position should be normalized for " + city_name)
		assert_between(pos.y, 0.0, 1.0, "Y position should be normalized for " + city_name)

func test_temperature_updates():
	# Test temperature variation system
	CityWeatherData.initialize_temperatures()
	
	var initial_temp = CityWeatherData.get_city_temperature("CIUDADLONG")
	
	# Update temperatures multiple times
	for i in range(10):
		CityWeatherData.update_temperatures()
	
	var updated_temp = CityWeatherData.get_city_temperature("CIUDADLONG")
	
	# Temperature should still be in valid range
	assert_between(updated_temp, 70.0, 88.0, "Updated temperature should stay in tropical range")

func test_radar_colors():
	# Test the radar color system
	var low_intensity_color = RadarColors.get_intensity_color(0.1)
	var high_intensity_color = RadarColors.get_intensity_color(0.9)
	
	# Low intensity should be greenish
	assert_gt(low_intensity_color.g, 0.5, "Low intensity should be green")
	
	# High intensity should be reddish or magenta
	assert_true(high_intensity_color.r > 0.5, "High intensity should have red component")

func test_weather_echo_colors():
	# Test that weather echoes get proper colors
	var light_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.2, 1.0, 10.0)
	var severe_echo = WeatherEcho.new(Vector2(0.5, 0.5), 0.9, 1.0, 10.0)
	
	var light_color = light_echo.get_display_color()
	var severe_color = severe_echo.get_display_color()
	
	# Colors should be different
	assert_ne(light_color, severe_color, "Different intensities should have different colors")
	
	# Light should be more green, severe should be more red/magenta
	assert_gt(light_color.g, light_color.r, "Light echo should be greenish")
	assert_gt(severe_color.r, severe_color.g, "Severe echo should be reddish")

func test_city_weather_status_update():
	# Test weather status updates based on nearby echoes
	CityWeatherData.initialize_temperatures()
	
	var city_pos = CityWeatherData.get_city_position("CIUDADLONG")
	
	# Create weather echo near the city
	var weather_echoes: Array[WeatherEcho] = []
	var nearby_echo = WeatherEcho.new(city_pos, 0.7, 1.0, 10.0)  # Severe weather
	weather_echoes.append(nearby_echo)
	
	# Update weather status
	CityWeatherData.update_city_weather_status("CIUDADLONG", weather_echoes)
	
	var city_info = CityWeatherData.get_city_info("CIUDADLONG")
	assert_ne(city_info["weather_status"], "Clear", "City should show weather when echo is nearby")

func test_map_radar_integration():
	# Test that MapRadar can work with the new system
	var radar = MapRadar.new()
	
	# This should not crash
	radar._ready()
	
	# Should have weather echoes
	assert_ge(radar.get_weather_count(), 0, "Radar should initialize without errors")
	
	# Should be able to get storm data
	var storm_data = radar.get_current_storm_data()
	assert_true(storm_data.has("max_intensity"), "Should return storm data dictionary")
	assert_true(storm_data.has("affected_cities"), "Should include affected cities")

func test_easy_weather_scenarios():
	# Test that we can easily set different weather scenarios
	var radar = MapRadar.new()
	radar._ready()
	
	# Test clear weather
	radar.set_weather_scenario("clear")
	assert_eq(radar.get_weather_count(), 0, "Clear scenario should have no weather")
	
	# Test scattered storms
	radar.set_weather_scenario("scattered")
	assert_gt(radar.get_weather_count(), 0, "Scattered scenario should have weather")
	
	# Test adding storm at specific city
	radar.clear_weather()
	radar.add_storm_at_city("CIUDADLONG", 0.8, "thunderstorm")
	assert_gt(radar.get_weather_count(), 0, "Should be able to add storm at city")

func test_temperature_display_format():
	# Test temperature formatting for display
	CityWeatherData.initialize_temperatures()
	
	var temp = CityWeatherData.get_city_temperature("PUERTOSHAN")
	var formatted = str(int(temp)) + "°F"
	
	# Should be reasonable format
	assert_true(formatted.ends_with("°F"), "Temperature should be formatted in Fahrenheit")
	assert_true(formatted.length() >= 4, "Should have at least 2 digits plus °F")