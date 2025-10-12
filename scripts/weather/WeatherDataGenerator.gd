class_name WeatherDataGenerator extends RefCounted

# Generates realistic weather patterns for radar display
# Creates various storm types with authentic meteorological characteristics

# Deterministic RNG so weather patterns respawn in the same places.


static func generate_scattered_storms(center: Vector2, count: int = 5, base_intensity: float = 0.4, 
									 spread_radius: float = 0.3) -> Array[WeatherEcho]:
	"""Generate scattered thunderstorm pattern"""
	var echoes: Array[WeatherEcho] = []
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		# Random position within spread radius
		var angle = rng.randf() * TAU
		var distance = rng.randf() * spread_radius
		var pos = center + Vector2(cos(angle), sin(angle)) * distance
		
		# Clamp to radar bounds
		pos.x = clamp(pos.x, 0.05, 0.95)
		pos.y = clamp(pos.y, 0.05, 0.95)
		
		# Vary intensity and size
		var intensity = base_intensity + rng.randf_range(-0.2, 0.3)
		intensity = clamp(intensity, 0.1, 1.0)
		
		var size = rng.randf_range(0.8, 2.0)
		var lifetime = rng.randf_range(8.0, 15.0)
		
		# Random movement (typical storm motion)
		var motion_angle = rng.randf_range(-PI/4, PI/4) + PI/4  # Generally northeast
		var motion_speed = rng.randf_range(0.005, 0.015)  # Slow movement
		var velocity = Vector2(cos(motion_angle), sin(motion_angle)) * motion_speed
		
		var echo_type = _get_echo_type_from_intensity(intensity)
		var echo = WeatherEcho.new(pos, intensity, size, lifetime, velocity, echo_type)
		echo.random_seed = rng.randi()
		echoes.append(echo)
	
	return echoes

static func generate_supercell(center: Vector2, intensity: float = 0.8) -> Array[WeatherEcho]:
	"""Generate supercell thunderstorm with hook echo and mesocyclone"""
	var echoes: Array[WeatherEcho] = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Main updraft core - stationary
	var core_echo = WeatherEcho.new(center, intensity, 2.5, 20.0, Vector2.ZERO, "severe")
	core_echo.random_seed = rng.randi()
	echoes.append(core_echo)

	# Hook echo (characteristic of supercells)
	var hook_offset = Vector2(-0.03, 0.04)  # Southwest of main core
	var hook_pos = center + hook_offset
	hook_pos.x = clamp(hook_pos.x, 0.05, 0.95)
	hook_pos.y = clamp(hook_pos.y, 0.05, 0.95)

	var hook_echo = WeatherEcho.new(hook_pos, intensity - 0.2, 1.8, 18.0, Vector2.ZERO, "heavy")
	hook_echo.random_seed = rng.randi()
	echoes.append(hook_echo)

	# Mesocyclone signature (rotating updraft)
	for i in range(6):
		var angle = (i / 6.0) * TAU
		var radius = 0.025
		var meso_pos = center + Vector2(cos(angle), sin(angle)) * radius
		meso_pos.x = clamp(meso_pos.x, 0.05, 0.95)
		meso_pos.y = clamp(meso_pos.y, 0.05, 0.95)
        
		var meso_intensity = intensity - 0.3 + rng.randf_range(-0.1, 0.1)
		meso_intensity = clamp(meso_intensity, 0.2, 1.0)
        
		var meso_echo = WeatherEcho.new(meso_pos, meso_intensity, 1.2, 15.0, Vector2.ZERO, "moderate")
		meso_echo.random_seed = rng.randi()
		echoes.append(meso_echo)
	
	# Forward flank downdraft
	var ffd_offset = Vector2(0.04, -0.02)  # Northeast of core
	var ffd_pos = center + ffd_offset
	ffd_pos.x = clamp(ffd_pos.x, 0.05, 0.95)
	ffd_pos.y = clamp(ffd_pos.y, 0.05, 0.95)
	
	var ffd_echo = WeatherEcho.new(ffd_pos, intensity - 0.4, 2.0, 12.0, Vector2.ZERO, "moderate")
	ffd_echo.random_seed = rng.randi()
	echoes.append(ffd_echo)
	
	return echoes

static func generate_hurricane(center: Vector2, intensity: float = 0.9, eye_radius: float = 0.08) -> Array[WeatherEcho]:
	"""Generate hurricane pattern with eye wall and spiral bands"""
	var echoes: Array[WeatherEcho] = []
	
	# Eye wall - ring of intense convection
	var eyewall_segments = 16
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(eyewall_segments):
		var angle = (i / float(eyewall_segments)) * TAU
		var eyewall_pos = center + Vector2(cos(angle), sin(angle)) * eye_radius
        
		# Clamp to bounds
		eyewall_pos.x = clamp(eyewall_pos.x, 0.05, 0.95)
		eyewall_pos.y = clamp(eyewall_pos.y, 0.05, 0.95)
        
		var wall_intensity = intensity + rng.randf_range(-0.1, 0.05)
		wall_intensity = clamp(wall_intensity, 0.7, 1.0)
        
		# Hurricane motion disabled - stationary system
		var hurricane_motion = Vector2.ZERO
        
		var wall_echo = WeatherEcho.new(eyewall_pos, wall_intensity, 2.0, 25.0, hurricane_motion, "severe")
		wall_echo.random_seed = rng.randi()
		echoes.append(wall_echo)
	
	# Spiral rain bands
	var num_bands = 3
	for band in range(num_bands):
		var band_radius = eye_radius + 0.06 + (band * 0.08)
		var band_segments = 12 - (band * 2)  # Fewer segments for outer bands
		
		for i in range(band_segments):
			var base_angle = (i / float(band_segments)) * TAU
			var spiral_offset = band * 0.3  # Create spiral effect
			var angle = base_angle + spiral_offset
			
			var band_pos = center + Vector2(cos(angle), sin(angle)) * band_radius
			band_pos.x = clamp(band_pos.x, 0.05, 0.95)
			band_pos.y = clamp(band_pos.y, 0.05, 0.95)
			
			var band_intensity = intensity - 0.2 - (band * 0.15)
			band_intensity = clamp(band_intensity, 0.3, 0.8)
			
			var band_size = 1.5 - (band * 0.2)
			var hurricane_motion = Vector2.ZERO  # Stationary bands
			
			var band_echo = WeatherEcho.new(band_pos, band_intensity, band_size, 20.0, hurricane_motion, "heavy")
			band_echo.random_seed = rng.randi()
			echoes.append(band_echo)
	
	return echoes

static func generate_squall_line(start_pos: Vector2, end_pos: Vector2, intensity: float = 0.6) -> Array[WeatherEcho]:
	"""Generate squall line (line of thunderstorms)"""
	var echoes: Array[WeatherEcho] = []
	var line_vector = end_pos - start_pos
	var line_length = line_vector.length()
	var segments = max(int(line_length / 0.04), 5)  # Segment every 4% of radar
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(segments):
		var t = i / float(segments - 1) if segments > 1 else 0.0
		var pos = start_pos + line_vector * t
		
		# Clamp to bounds
		pos.x = clamp(pos.x, 0.05, 0.95)
		pos.y = clamp(pos.y, 0.05, 0.95)
		
		# Main convective line
		var line_intensity = intensity + rng.randf_range(-0.15, 0.2)
		line_intensity = clamp(line_intensity, 0.3, 1.0)
		
		# Squall lines now stationary - no movement
		var line_angle = line_vector.angle()
		var velocity = Vector2.ZERO  # No movement
		
		var main_echo = WeatherEcho.new(pos, line_intensity, 1.8, 18.0, velocity, "heavy")
		main_echo.random_seed = rng.randi()
		echoes.append(main_echo)
		
		# Trailing stratiform region (behind the line)
		var trailing_offset = Vector2(cos(line_angle + PI), sin(line_angle + PI)) * 0.03
		var trailing_pos = pos + trailing_offset
		trailing_pos.x = clamp(trailing_pos.x, 0.05, 0.95)
		trailing_pos.y = clamp(trailing_pos.y, 0.05, 0.95)
		
		var trailing_intensity = intensity - 0.3
		trailing_intensity = clamp(trailing_intensity, 0.1, 0.6)
		
		var trailing_echo = WeatherEcho.new(trailing_pos, trailing_intensity, 2.2, 15.0, Vector2.ZERO, "moderate")
		trailing_echo.random_seed = rng.randi()
		echoes.append(trailing_echo)
		
		# Occasional bow echo (curved segment)
		if rng.randf() < 0.3 and i > 2 and i < segments - 3:
			var bow_offset = Vector2(cos(line_angle + PI/2), sin(line_angle + PI/2)) * 0.02
			var bow_pos = pos + bow_offset
			bow_pos.x = clamp(bow_pos.x, 0.05, 0.95)
			bow_pos.y = clamp(bow_pos.y, 0.05, 0.95)
			
			var bow_echo = WeatherEcho.new(bow_pos, line_intensity + 0.1, 1.5, 16.0, Vector2.ZERO, "heavy")
			bow_echo.random_seed = rng.randi()
			echoes.append(bow_echo)
	
	return echoes

static func generate_frontal_system(center: Vector2, width: float = 0.4, intensity: float = 0.5) -> Array[WeatherEcho]:
	"""Generate weather front with widespread precipitation"""
	var echoes: Array[WeatherEcho] = []
	
	# Create a broad area of precipitation
	var rows = 8
	var cols = 12
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for row in range(rows):
		for col in range(cols):
			var x_offset = (col / float(cols - 1) - 0.5) * width
			var y_offset = (row / float(rows - 1) - 0.5) * width * 0.6
			
			var pos = center + Vector2(x_offset, y_offset)
			pos.x = clamp(pos.x, 0.05, 0.95)
			pos.y = clamp(pos.y, 0.05, 0.95)
			
			# Vary intensity across the front
			var front_intensity = intensity + rng.randf_range(-0.2, 0.2)
			front_intensity = clamp(front_intensity, 0.1, 0.8)
			
			# Frontal systems now stationary
			var front_velocity = Vector2.ZERO
			
			var size = rng.randf_range(1.0, 1.8)
			var lifetime = rng.randf_range(12.0, 20.0)
			
			var front_echo = WeatherEcho.new(pos, front_intensity, size, lifetime, front_velocity, "moderate")
			front_echo.random_seed = rng.randi()
			echoes.append(front_echo)
	
	return echoes

static func update_weather_motion(echoes: Array[WeatherEcho], delta: float):
	"""Update weather echoes with aging only (no motion - echoes stay stationary)"""
	for i in range(echoes.size() - 1, -1, -1):
		var echo = echoes[i]
		# Only update age, not position - echoes now stay stationary
		echo.age += delta
		
		# Remove expired echoes
		if echo.is_expired():
			echoes.remove_at(i)

static func _get_echo_type_from_intensity(intensity: float) -> String:
	"""Convert intensity to descriptive echo type"""
	if intensity < 0.3:
		return "light"
	elif intensity < 0.6:
		return "moderate"
	elif intensity < 0.8:
		return "heavy"
	else:
		return "severe"

static func generate_random_weather_scenario(radar_bounds: Rect2) -> Array[WeatherEcho]:
	"""Generate a random weather scenario for variety"""
	var scenarios = ["scattered", "supercell", "hurricane", "squall_line", "frontal", "mixed"]
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var scenario = scenarios[rng.randi() % scenarios.size()]

	var center = Vector2(
		rng.randf_range(0.2, 0.8),
		rng.randf_range(0.2, 0.8)
	)
	
	match scenario:
		"scattered":
			return generate_scattered_storms(center, rng.randi_range(3, 8), rng.randf_range(0.3, 0.7))
		"supercell":
			return generate_supercell(center, rng.randf_range(0.7, 0.9))
		"hurricane":
			return generate_hurricane(center, rng.randf_range(0.8, 1.0), rng.randf_range(0.06, 0.12))
		"squall_line":
			var end_pos = center + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.2, 0.2))
			return generate_squall_line(center, end_pos, rng.randf_range(0.5, 0.8))
		"frontal":
			return generate_frontal_system(center, rng.randf_range(0.3, 0.5), rng.randf_range(0.4, 0.6))
		"mixed":
			var all_echoes: Array[WeatherEcho] = []
			all_echoes.append_array(generate_scattered_storms(center, 3, 0.4))
			if rng.randf() < 0.6:
				var second_center = Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8))
				all_echoes.append_array(generate_supercell(second_center, 0.7))
			return all_echoes
		_:
			return generate_scattered_storms(center)

static func get_city_weather_echoes() -> Array[WeatherEcho]:
	"""Generate weather echoes positioned over cities"""
	var echoes: Array[WeatherEcho] = []
	
	# Get cities from the current system (no need to load JSON)
	var all_cities = CityWeatherData.get_all_cities()
	
	if all_cities.is_empty():
		print("No cities available for weather generation")
		return echoes
	
	# Create weather over some random cities
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num_affected = rng.randi_range(2, 4)  # 2-4 cities with weather
	var affected_cities: Array[String] = []

	# Randomly select cities to have weather
	for i in range(num_affected):
		var random_city = all_cities[rng.randi() % all_cities.size()]
		if not affected_cities.has(random_city):
			affected_cities.append(random_city)

	# Generate weather at selected cities
	for city_name in affected_cities:
		var city_pos = CityWeatherData.get_city_position(city_name)
		
		# Use default intensity since we don't have city types in the new system
		var base_intensity = 0.5 + rng.randf_range(-0.1, 0.2)  # Random variation
		
		var city_echoes = generate_scattered_storms(city_pos, rng.randi_range(2, 5), base_intensity, 0.08)
		echoes.append_array(city_echoes)
	
	return echoes
