extends Control

# Real weather radar implementation based on actual radar physics
# The sweep beam rotates, hits weather targets, creates echoes that fade over time
class_name MapRadar

# Editor-configurable radar parameters
@export_group("Radar Settings")
@export_range(0.01, 1.0, 0.01) var radar_sweep_speed: float = 0.20 : set = _set_radar_sweep_speed
@export_range(0.1, 1.0, 0.05) var radar_radius_multiplier: float = 0.45 : set = _set_radar_radius

@export_group("Weather Settings") 
@export_range(0.1, 2.0, 0.1) var weather_intensity_multiplier: float = 1.0 : set = _set_weather_intensity
@export_range(1, 50, 1) var max_weather_echoes: int = 30 : set = _set_max_weather_echoes
@export_range(5, 60, 5) var weather_update_interval: int = 20 : set = _set_weather_update_interval
@export var echo_shape: EchoShape = EchoShape.CIRCLE : set = _set_echo_shape

@export_group("Game Settings")
@export_range(30, 300, 1) var round_duration: int = 90 : set = _set_round_duration

enum EchoShape {
	CIRCLE,
	BOX,
	BLOB
}

# Game timer and scoring
var round_timer: float = 0.0
var game_active: bool = true
var round_score: int = 0
var total_score: int = 0

# UI elements
var timer_label: Label
var score_label: Label

# Radar system
var radar_system: RadarSystem

# Map and weather data
var map_texture: Texture2D

# Performance monitoring
var frame_time_accumulator: float = 0.0
var frame_count: int = 0
var average_fps: float = 60.0
var performance_warning_threshold: float = 30.0

# Weather data interface
var weather_echoes: Array[WeatherEcho] = []

func _ready():
	print("San Jii Metro Radar initializing...")
	
	# Generate random hex map for this game session FIRST
	print("Generating random hex map...")
	map_texture = OSMMapRenderer.generate_game_map(Vector2i(800, 600))
	
	# Initialize city temperature data AFTER map generation
	CityWeatherData.initialize_temperatures()
	
	if map_texture:
		print("Random hex map generated: ", map_texture.get_width(), "x", map_texture.get_height())
	else:
		print("Warning: Map generation failed, loading fallback")
		# Fallback to static maps if generation fails
		map_texture = load("res://pro_map.png")
		if not map_texture:
			map_texture = load("res://IslandMap.png")
	
	# Create and setup the real radar system
	radar_system = RadarSystem.new()
	add_child(radar_system)
	radar_system.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	radar_system.set_map_texture(map_texture)
	
	# Apply editor-configured radar settings
	radar_system.sweep_speed = radar_sweep_speed
	radar_system.set_radius_multiplier(radar_radius_multiplier)
	radar_system.set_echo_shape(echo_shape as RadarSystem.EchoShape)
	
	# Generate initial weather
	_generate_initial_weather()
	
	# Give weather targets to radar system
	radar_system.set_weather_targets(weather_echoes)
	
	# Setup game UI
	_setup_game_ui()
	
	# Start round timer
	round_timer = round_duration
	game_active = true
	
	print("Radar initialized with real sweep behavior")

func _setup_game_ui():
	"""Setup timer and score UI elements"""
	# Timer label (top right)
	timer_label = Label.new()
	timer_label.text = "Time: 90"
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(timer_label)
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	timer_label.position.x -= 120
	timer_label.position.y += 10
	
	# Score label (top left, below radar info)
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(score_label)
	score_label.position.x = 10
	score_label.position.y = 100

func _generate_initial_weather():
	"""Generate initial weather patterns using the existing system"""
	weather_echoes.clear()
	
	# Generate weather over cities using the existing system
	var city_weather = WeatherDataGenerator.get_city_weather_echoes()
	weather_echoes.append_array(city_weather)
	
	# Add some random weather for variety
	if randf() < 0.7:  # 70% chance for additional weather
		var random_weather = WeatherDataGenerator.generate_random_weather_scenario(Rect2(0, 0, 1, 1))
		weather_echoes.append_array(random_weather)
	
	print("Generated ", weather_echoes.size(), " weather targets for radar")

# Setter functions for editor variables
func _set_radar_sweep_speed(value: float):
	radar_sweep_speed = value
	if radar_system:
		radar_system.sweep_speed = value

func _set_radar_radius(value: float):
	radar_radius_multiplier = value
	if radar_system:
		radar_system.radar_radius_multiplier = value

func _set_weather_intensity(value: float):
	weather_intensity_multiplier = value
	# Apply to existing weather echoes
	for echo in weather_echoes:
		echo.intensity = clamp(echo.intensity * value, 0.0, 1.0)
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)

func _set_max_weather_echoes(value: int):
	max_weather_echoes = value
	# Trim existing weather if needed
	if weather_echoes.size() > value:
		weather_echoes = weather_echoes.slice(0, value)
		if radar_system:
			radar_system.set_weather_targets(weather_echoes)

func _set_weather_update_interval(value: int):
	weather_update_interval = value

func _set_echo_shape(value: EchoShape):
	echo_shape = value
	if radar_system:
		radar_system.set_echo_shape(value as RadarSystem.EchoShape)

func _set_round_duration(value: int):
	round_duration = value
	if game_active:
		round_timer = value

func _process(delta):
	# Update game timer
	if game_active:
		round_timer -= delta
		_update_timer_display()
		_update_score_display()
		
		if round_timer <= 0.0:
			_end_round()
	
	# Performance monitoring
	_update_performance_metrics(delta)
	
	# Update weather targets periodically (configurable interval)
	var weather_update_timer = Time.get_ticks_msec() / 1000.0
	if int(weather_update_timer) % weather_update_interval == 0 and int(weather_update_timer * 10) % 10 == 0:
		_regenerate_weather()
	
	# Update temperature periodically
	if int(weather_update_timer) % 30 == 0 and int(weather_update_timer * 10) % 10 == 0:
		CityWeatherData.update_temperatures()
		_update_city_weather_status()
		WeatherImpactSystem.update_all_city_weather(weather_echoes)
		WeatherImpactSystem.process_population_dynamics(delta)

func _update_performance_metrics(delta):
	"""Update performance monitoring"""
	frame_time_accumulator += delta
	frame_count += 1
	
	# Update average FPS every second
	if frame_time_accumulator >= 1.0:
		average_fps = frame_count / frame_time_accumulator
		frame_time_accumulator = 0.0
		frame_count = 0
		
		# Log performance warnings
		if average_fps < performance_warning_threshold:
			print("Performance warning: FPS dropped to ", average_fps)

func _update_timer_display():
	"""Update the timer display"""
	if timer_label:
		var minutes = int(round_timer / 60)
		var seconds = int(round_timer) % 60
		timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func _update_score_display():
	"""Update the score display"""
	if score_label:
		score_label.text = "Score: %d" % round_score

func _end_round():
	"""End the current round and calculate score"""
	game_active = false
	
	# Calculate score based on emergency predictions
	_calculate_final_score()
	
	# Add round score to total
	total_score += round_score
	
	# Update high score in GameData
	if GameData:
		GameData.set_score(total_score)
	
	# Show final score
	print("Round ended! Score: ", round_score, " Total: ", total_score)
	
	# Transition to NewsRoom scene
	_transition_to_newsroom()

func start_new_round():
	"""Prepare and start a new round without recreating the node (not currently used)"""
	round_score = 0
	round_timer = round_duration
	game_active = true
	_generate_initial_weather()
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	print("New round started")

func _calculate_final_score():
	"""Calculate score based on emergency status accuracy"""
	round_score = 0
	
	if not radar_system:
		return
	
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var emergency_status = radar_system.city_emergency_status.get(city_name, 0)  # NONE = 0
		var city_pos = CityWeatherData.get_city_position(city_name)
		
		# Check if there's severe weather near this city
		var has_severe_weather = false
		var max_intensity = 0.0
		
		for echo in weather_echoes:
			var distance = city_pos.distance_to(echo.position)
			if distance < 0.15:  # Within 15% of radar scope
				max_intensity = max(max_intensity, echo.intensity)
				if echo.intensity > 0.6:  # Severe weather threshold
					has_severe_weather = true
		
		# Award points for correct predictions
		if has_severe_weather:
			match emergency_status:
				2: round_score += 20  # SHELTER - good prediction
				3: round_score += 30  # EVAC - excellent prediction
				1: round_score += 10  # CAUTION - okay prediction
				0: round_score -= 10  # NONE - missed severe weather
		else:
			# No severe weather
			match emergency_status:
				0: round_score += 5   # NONE - correct, no action needed
				1: round_score -= 2   # CAUTION - minor over-prediction
				2: round_score -= 10  # SHELTER - over-prediction
				3: round_score -= 15  # EVAC - major over-prediction
	
	# Ensure minimum score of 0
	round_score = max(0, round_score)

func _transition_to_newsroom():
	"""Transition to the NewsRoom scene"""
	# Compute ideal score for this round (best possible decisions per city)
	var ideal_score: int = 0
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var city_pos = CityWeatherData.get_city_position(city_name)
		var max_intensity = 0.0
		for echo in weather_echoes:
			var distance = city_pos.distance_to(echo.position)
			if distance < 0.15:
				max_intensity = max(max_intensity, echo.intensity)
		# If severe weather present, best action is EVAC (30), else best is NONE (5)
		if max_intensity > 0.6:
			ideal_score += 30
		else:
			ideal_score += 5

	# Store score in a simple way - add it to the scene's metadata
	get_tree().set_meta("last_score", total_score)
	get_tree().set_meta("round_score", round_score)
	get_tree().set_meta("ideal_score", ideal_score)
	
	# Store high score data
	if GameData:
		get_tree().set_meta("high_score", GameData.get_high_score())
		get_tree().set_meta("is_new_high", total_score == GameData.get_high_score() and round_score > 0)
	else:
		get_tree().set_meta("high_score", 0)
		get_tree().set_meta("is_new_high", false)
	
	# Load NewsRoom scene
	# Play audio (if AudioManager autoload is available)
	if Engine.has_singleton("AudioManager"):
		var am = Engine.get_singleton("AudioManager")
		# play short alert then music (non-blocking)
		if am:
			if "play_default_news_alert" in am:
				am.play_default_news_alert()
			if "play_default_news_music" in am:
				am.play_default_news_music()

	get_tree().change_scene_to_file("res://NewsRoom.tscn")

func _regenerate_weather():
	"""Regenerate weather patterns periodically"""
	# Keep some existing weather, add new weather
	var existing_count = weather_echoes.size()
	
	# Remove old weather (keep 30% of existing)
	var keep_count = int(existing_count * 0.3)
	if weather_echoes.size() > keep_count:
		weather_echoes = weather_echoes.slice(0, keep_count)
	
	# Add new weather with smaller, more realistic echo sizes
	var new_weather = WeatherDataGenerator.generate_random_weather_scenario(Rect2(0, 0, 1, 1))
	
	# Make weather echoes smaller for dense precipitation patterns and apply intensity multiplier
	for weather in new_weather:
		weather.size = weather.size * 0.6  # Smaller individual echo areas
		weather.intensity = clamp(weather.intensity * weather_intensity_multiplier, 0.0, 1.0)
	
	weather_echoes.append_array(new_weather)
	
	# Trim to max echoes if needed
	if weather_echoes.size() > max_weather_echoes:
		weather_echoes = weather_echoes.slice(0, max_weather_echoes)
	
	# Update radar system with new targets
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	
	print("Weather regenerated: ", weather_echoes.size(), " total targets")

func _update_city_weather_status():
	"""Update weather status for all cities based on nearby weather echoes"""
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		CityWeatherData.update_city_weather_status(city_name, weather_echoes)

# Public interface methods for compatibility

func regenerate_weather():
	"""Manually regenerate weather patterns"""
	_generate_initial_weather()
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	print("Weather manually regenerated")

func add_weather_echo(echo_position: Vector2, intensity: float, echo_size: float = 1.0):
	"""Add a custom weather echo"""
	var echo = WeatherEcho.new(echo_position, intensity, echo_size, 15.0, Vector2.ZERO, "custom")
	weather_echoes.append(echo)
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)

func clear_weather():
	"""Clear all weather echoes"""
	weather_echoes.clear()
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	print("All weather cleared")

func get_weather_count() -> int:
	"""Get current number of weather echoes"""
	return weather_echoes.size()

func set_sweep_speed(speed: float):
	"""Set radar sweep speed"""
	if radar_system:
		radar_system.sweep_speed = clamp(speed, 0.1, 2.0)

func get_current_storm_data() -> Dictionary:
	"""Get current storm data for game integration"""
	var max_intensity = 0.0
	var storm_count = 0
	var severe_count = 0
	var affected_cities = []
	
	for echo in weather_echoes:
		if echo.intensity > max_intensity:
			max_intensity = echo.intensity
		if echo.intensity > 0.4:
			storm_count += 1
		if echo.intensity > 0.7:
			severe_count += 1
	
	# Check which cities are affected by weather
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var city_pos = CityWeatherData.get_city_position(city_name)
		for echo in weather_echoes:
			var distance = city_pos.distance_to(echo.position)
			if distance < 0.1 and echo.intensity > 0.3:
				if not affected_cities.has(city_name):
					affected_cities.append(city_name)
				break
	
	var sweep_angle = 0.0
	if radar_system:
		sweep_angle = radar_system.get_current_sweep_angle()
	
	return {
		"max_intensity": max_intensity,
		"total_echoes": weather_echoes.size(),
		"storm_echoes": storm_count,
		"severe_echoes": severe_count,
		"affected_cities": affected_cities,
		"sweep_angle": sweep_angle,
		"average_fps": average_fps,
		"active_radar_echoes": radar_system.get_active_echo_count() if radar_system else 0
	}

func set_weather_scenario(scenario_name: String):
	"""Set specific weather scenario"""
	weather_echoes.clear()
	
	match scenario_name.to_lower():
		"hurricane":
			var center = Vector2(0.5, 0.5)
			weather_echoes = WeatherDataGenerator.generate_hurricane(center, 0.9, 0.08)
		"supercell":
			var cities = CityWeatherData.get_all_cities()
			if cities.size() > 0:
				var center = CityWeatherData.get_city_position(cities[0])
				weather_echoes = WeatherDataGenerator.generate_supercell(center, 0.8)
		"squall_line":
			var start = Vector2(0.2, 0.3)
			var end = Vector2(0.8, 0.7)
			weather_echoes = WeatherDataGenerator.generate_squall_line(start, end, 0.7)
		"scattered":
			var center = Vector2(0.5, 0.5)
			weather_echoes = WeatherDataGenerator.generate_scattered_storms(center, 8, 0.5)
		"frontal":
			var center = Vector2(0.4, 0.5)
			weather_echoes = WeatherDataGenerator.generate_frontal_system(center, 0.6, 0.4)
		"clear":
			weather_echoes.clear()
		_:
			_generate_initial_weather()
	
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	
	print("Weather scenario set to: ", scenario_name, " with ", weather_echoes.size(), " targets")

func add_storm_at_city(city_name: String, intensity: float = 0.7, storm_type: String = "thunderstorm"):
	"""Add a storm at a specific city"""
	var city_pos = CityWeatherData.get_city_position(city_name)
	if city_pos == Vector2.ZERO:
		print("City not found: ", city_name)
		return
	
	var new_echoes: Array[WeatherEcho] = []
	
	match storm_type.to_lower():
		"supercell":
			new_echoes = WeatherDataGenerator.generate_supercell(city_pos, intensity)
		"hurricane":
			new_echoes = WeatherDataGenerator.generate_hurricane(city_pos, intensity, 0.06)
		_:
			new_echoes = WeatherDataGenerator.generate_scattered_storms(city_pos, 5, intensity, 0.08)
	
	weather_echoes.append_array(new_echoes)
	if radar_system:
		radar_system.set_weather_targets(weather_echoes)
	
	print("Added ", storm_type, " at ", city_name, " with ", new_echoes.size(), " targets")

func get_weather_at_city(city_name: String) -> Dictionary:
	"""Get weather information for a specific city"""
	var city_pos = CityWeatherData.get_city_position(city_name)
	if city_pos == Vector2.ZERO:
		return {"error": "City not found"}
	
	var max_intensity = 0.0
	var echo_count = 0
	var closest_distance = 1.0
	
	for echo in weather_echoes:
		var distance = city_pos.distance_to(echo.position)
		if distance < 0.15:  # Within 15% of radar scope
			echo_count += 1
			if echo.intensity > max_intensity:
				max_intensity = echo.intensity
			if distance < closest_distance:
				closest_distance = distance
	
	var weather_status = "Clear"
	if max_intensity > 0.1:
		if max_intensity < 0.3:
			weather_status = "Light Rain"
		elif max_intensity < 0.6:
			weather_status = "Moderate Rain"
		elif max_intensity < 0.8:
			weather_status = "Heavy Rain"
		else:
			weather_status = "Severe Weather"
	
	return {
		"city": city_name,
		"max_intensity": max_intensity,
		"echo_count": echo_count,
		"closest_distance": closest_distance,
		"weather_status": weather_status,
		"dbz_value": int(max_intensity * 60)
	}
