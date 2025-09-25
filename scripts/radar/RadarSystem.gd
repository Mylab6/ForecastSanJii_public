extends Control
class_name RadarSystem

# Real radar system implementation based on actual weather radar behavior
# Radar sweeps in a circle, echoes appear when beam hits precipitation,
# then fade gradually until the beam comes around again

# Core radar properties  
var sweep_angle: float = 0.0
var sweep_speed: float = 0.05  # Much slower - realistic 10+ minute rotation like real WSR-88D
var radar_center: Vector2
var radar_radius: float
var radar_radius_multiplier: float = 0.45  # Configurable radius multiplier
var beam_width: float = 0.03  # Narrower beam for precision

# Echo system
var active_echoes: Array[RadarEcho] = []
var weather_targets: Array[WeatherEcho] = []
var echo_fade_time: float = 12.0  # Longer persistence like real radar phosphor

# Timing
var start_time: float

# Display properties
var persistence_trails: Array[PersistenceTrail] = []
var max_persistence_trails: int = 120  # Longer trail history for smoother sweep

# Map integration
var map_texture: Texture2D
var last_display_size: Vector2 = Vector2.ZERO

# Echo shape configuration
enum EchoShape { CIRCLE, BOX, BLOB }
var current_echo_shape: EchoShape = EchoShape.CIRCLE

# City emergency status system
enum EmergencyStatus { NONE, CAUTION, SHELTER, EVAC }
var city_emergency_status: Dictionary = {}  # city_name -> EmergencyStatus
var selected_city: String = ""
var show_context_menu: bool = false
var context_menu_position: Vector2

class RadarEcho:
	var position: Vector2
	var intensity: float
	var spawn_time: float
	var last_hit_time: float
	var current_alpha: float = 1.0
	var weather_source: WeatherEcho
	
	func _init(pos: Vector2, intens: float, time: float, source: WeatherEcho):
		position = pos
		intensity = intens
		spawn_time = time
		last_hit_time = time
		weather_source = source

class PersistenceTrail:
	var angle: float
	var timestamp: float
	var alpha: float
	
	func _init(a: float, t: float, al: float):
		angle = a
		timestamp = t
		alpha = al

func _ready():
	print("Real radar system initializing...")
	_setup_radar_display()
	start_time = Time.get_ticks_msec() / 1000.0
	# Initialize city emergency status
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		city_emergency_status[city_name] = EmergencyStatus.NONE

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Check if clicking on context menu first
			if show_context_menu:
				_handle_context_menu_click(event.position)
			else:
				_handle_city_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			show_context_menu = false  # Close context menu on right click

func _handle_city_click(click_pos: Vector2):
	"""Handle mouse clicks to detect city selection"""
	var display_size = get_rect().size
	var cities = CityWeatherData.get_all_cities()
	var closest_city = ""
	var closest_distance = 50.0  # Maximum click distance in pixels
	
	for city_name in cities:
		var city_pos = CityWeatherData.get_city_position(city_name)
		var screen_pos = Vector2(city_pos.x * display_size.x, city_pos.y * display_size.y)
		var distance = click_pos.distance_to(screen_pos)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_city = city_name
	
	if closest_city != "":
		selected_city = closest_city
		show_context_menu = true
		context_menu_position = click_pos
		print("Selected city: ", closest_city)
	
	# Generate some sample weather for testing
	_generate_sample_weather()
	
	print("Radar system active with ", weather_targets.size(), " weather targets")

func _setup_radar_display():
	"""Initialize radar display properties"""
	custom_minimum_size = Vector2(800, 600)
	var display_size = get_viewport().get_visible_rect().size
	# default center/radius
	radar_center = display_size * 0.5
	radar_radius = min(display_size.x, display_size.y) * radar_radius_multiplier
	last_display_size = display_size
	# try to fit the radar to include all cities
	fit_radar_to_all_cities()


func fit_radar_to_all_cities(padding_norm: float = 0.05) -> void:
	"""Adjust radar_center and radar_radius so all cities are inside the radar scope.
	Positions in CityWeatherData are normalized (0..1). padding_norm is added in normalized units."""
	# Ensure city data is loaded
	CityWeatherData.load_cities_from_json()
	var cities = CityWeatherData.get_all_cities()
	if cities.is_empty():
		# keep defaults
		return

	var display_size = get_viewport().get_visible_rect().size
	# compute bounding box in normalized coords
	var minp = Vector2(1.0, 1.0)
	var maxp = Vector2(0.0, 0.0)
	for city_name in cities:
		var p = CityWeatherData.get_city_position(city_name)
		minp.x = min(minp.x, p.x)
		minp.y = min(minp.y, p.y)
		maxp.x = max(maxp.x, p.x)
		maxp.y = max(maxp.y, p.y)

	# center in normalized coords
	var center_norm = (minp + maxp) * 0.5

	# determine radius as max distance from center to any city (normalized)
	var maxd = 0.0
	for city_name in cities:
		var p = CityWeatherData.get_city_position(city_name)
		maxd = max(maxd, p.distance_to(center_norm))

	# add padding in normalized units
	maxd += padding_norm

	# convert to pixels using the smaller display dimension for a circular radar
	var min_display = min(display_size.x, display_size.y)
	radar_center = Vector2(center_norm.x * display_size.x, center_norm.y * display_size.y)
	radar_radius = clamp(maxd * min_display, 50.0, min_display * 0.5)


func _generate_sample_weather():
	"""Generate sample weather targets for testing"""
	weather_targets.clear()
	
	# Create some test weather echoes
	for i in range(15):
		var angle = randf() * TAU
		var distance = randf() * 0.8  # Keep within radar range
		var pos = Vector2(cos(angle), sin(angle)) * distance
		pos = (pos + Vector2.ONE) * 0.5  # Convert to 0-1 range
		
		var echo = WeatherEcho.new(pos, randf() * 0.8 + 0.2, randf() * 0.05 + 0.02, 30.0, Vector2.ZERO, "test")
		weather_targets.append(echo)

func _process(delta):
	# Update radar sweep
	sweep_angle += sweep_speed * delta
	if sweep_angle >= TAU:
		sweep_angle -= TAU
	
	# Check for beam intersection with weather targets
	_check_beam_intersections()
	
	# Update echo persistence (fade over time)
	_update_echo_persistence(delta)
	
	# Update persistence trails
	_update_persistence_trails(delta)
	
	# Add new persistence trail for current beam position
	var current_time = Time.get_ticks_msec() / 1000.0
	var new_trail = PersistenceTrail.new(sweep_angle, current_time, 1.0)
	persistence_trails.append(new_trail)
	
	# Limit trail count
	while persistence_trails.size() > max_persistence_trails:
		persistence_trails.remove_at(0)
	
	queue_redraw()

func _check_beam_intersections():
	"""Check if the radar beam is currently hitting any weather targets"""
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for weather in weather_targets:
		if _is_target_in_beam(weather):
			# Check if we already have an echo for this target
			var existing_echo = _find_echo_for_target(weather)
			
			if existing_echo:
				# Refresh the existing echo
				existing_echo.last_hit_time = current_time
				existing_echo.current_alpha = 1.0
			else:
				# Create new echo
				var new_echo = RadarEcho.new(weather.position, weather.intensity, current_time, weather)
				active_echoes.append(new_echo)

func _is_target_in_beam(weather: WeatherEcho) -> bool:
	"""Check if a weather target is currently within the radar beam"""
	# Convert weather position to screen coordinates
	var screen_pos = _weather_to_screen_pos(weather.position)
	var target_angle = atan2(screen_pos.y - radar_center.y, screen_pos.x - radar_center.x)
	
	# Normalize angles to 0-TAU range
	if target_angle < 0:
		target_angle += TAU
	
	# Calculate angular difference
	var angle_diff = abs(target_angle - sweep_angle)
	if angle_diff > PI:
		angle_diff = TAU - angle_diff
	
	# Check if target is within beam width
	return angle_diff <= beam_width * 0.5

func _weather_to_screen_pos(weather_pos: Vector2) -> Vector2:
	"""Convert weather position (0-1 range) to screen coordinates"""
	var display_size = get_rect().size
	return Vector2(weather_pos.x * display_size.x, weather_pos.y * display_size.y)

func _find_echo_for_target(weather: WeatherEcho) -> RadarEcho:
	"""Find existing echo for a weather target"""
	for echo in active_echoes:
		if echo.weather_source == weather:
			return echo
	return null

func _update_echo_persistence(_delta: float):
	"""Update echo fading over time"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var echoes_to_remove = []
	
	for echo in active_echoes:
		var time_since_hit = current_time - echo.last_hit_time
		
		if time_since_hit >= echo_fade_time:
			# Echo has completely faded
			echoes_to_remove.append(echo)
		else:
			# Calculate fade alpha
			var fade_progress = time_since_hit / echo_fade_time
			echo.current_alpha = 1.0 - fade_progress
	
	# Remove faded echoes
	for echo in echoes_to_remove:
		active_echoes.erase(echo)

func _update_persistence_trails(_delta: float):
	"""Update radar beam persistence trails"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var trails_to_remove = []
	
	for trail in persistence_trails:
		var age = current_time - trail.timestamp
		if age > 3.0:  # Trails last 3 seconds for smooth sweep effect
			trails_to_remove.append(trail)
		else:
			# Smooth fade curve
			trail.alpha = 1.0 - pow(age / 3.0, 0.5)  # Slower fade at start
	
	# Remove old trails
	for trail in trails_to_remove:
		persistence_trails.erase(trail)

func _draw():
	var display_size = get_rect().size
	
	# Update radar properties if display size changed
	if display_size != last_display_size:
		# viewport size changed; recompute center/radius and try to fit cities
		last_display_size = display_size
		fit_radar_to_all_cities()
	
	# Draw map background
	_draw_map_background(display_size)
	
	# Draw radar scope
	_draw_radar_scope()
	
	# Draw weather echoes with proper persistence
	_draw_weather_echoes()
	
	# Draw persistence trails
	_draw_persistence_trails()
	
	# Draw current radar beam
	_draw_radar_beam()
	
	# Draw city markers
	_draw_city_markers(display_size)
	
	# Draw radar info
	_draw_radar_info()
	
	# Draw context menu if visible
	if show_context_menu:
		_draw_context_menu()

func _draw_map_background(display_size: Vector2):
	"""Draw the map background"""
	if map_texture:
		var map_rect = Rect2(Vector2.ZERO, display_size)
		draw_texture_rect(map_texture, map_rect, false)
	else:
		# Dark background
		draw_rect(Rect2(Vector2.ZERO, display_size), Color(0.05, 0.1, 0.2, 1.0))

func _draw_radar_scope():
	"""Draw radar scope rings and grid"""
	# Range rings
	var num_rings = 4
	for i in range(1, num_rings + 1):
		var ring_radius = radar_radius * (i / float(num_rings))
		draw_arc(radar_center, ring_radius, 0, TAU, 64, Color(0.0, 0.4, 0.0, 0.3), 1.0)
	
	# Center dot
	draw_circle(radar_center, 3, Color(0.0, 1.0, 0.2, 1.0))

func _draw_weather_echoes():
	"""Draw weather echoes with dense, overlapping precipitation patterns like real radar"""
	for echo in active_echoes:
		var weather_pos = echo.weather_source.position
		var screen_pos = _weather_to_screen_pos(weather_pos)
		var distance = radar_center.distance_to(screen_pos)
		
		# Only draw if within radar range
		if distance <= radar_radius:
			# Color based on intensity with fading
			var base_color = _get_weather_color(echo.intensity)
			var faded_color = Color(base_color.r, base_color.g, base_color.b, base_color.a * echo.current_alpha)
			
			# Draw DENSE, SMALL, OVERLAPPING echoes like real radar
			_draw_dense_precipitation_pattern(screen_pos, echo.weather_source.size, echo.intensity, faded_color)

func _draw_dense_precipitation_pattern(center_pos: Vector2, weather_size: float, intensity: float, color: Color):
	"""Draw precipitation pattern with configurable shapes"""
	# Calculate pattern area based on weather size
	var pattern_radius = weather_size * radar_radius * 0.12
	
	# Much fewer echoes - clean and simple like real radar
	var num_echoes = int(3 + intensity * 8)  # Only 3-11 small echoes per weather system
	
	# Moderate echo size 
	var base_echo_size = 3.0 + intensity * 5.0  # 3-8 pixel radius
	
	# Use position as seed for consistent pattern per weather system
	var seed_val = int(center_pos.x * 1000 + center_pos.y * 1000)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Draw main weather area with soft fill based on shape
	var main_alpha = color.a * 0.3
	var main_color = Color(color.r, color.g, color.b, main_alpha)
	
	match current_echo_shape:
		EchoShape.CIRCLE:
			draw_circle(center_pos, pattern_radius * 0.7, main_color)
		EchoShape.BOX:
			var box_size = pattern_radius * 1.4  # Make box roughly equivalent area
			var box_rect = Rect2(center_pos - Vector2(box_size/2, box_size/2), Vector2(box_size, box_size))
			draw_rect(box_rect, main_color)
		EchoShape.BLOB:
			_draw_blob_shape(center_pos, pattern_radius * 0.7, main_color, rng)
	
	# Add scattered discrete echoes for detail
	for i in range(num_echoes):
		# Random position within weather area
		var angle = rng.randf() * TAU
		var distance_factor = pow(rng.randf(), 0.4)  # Bias toward center
		var offset_distance = distance_factor * pattern_radius
		
		var echo_pos = center_pos + Vector2(cos(angle), sin(angle)) * offset_distance
		
		# Vary echo size slightly
		var echo_size = base_echo_size * (0.8 + rng.randf() * 0.4)
		
		# Vary intensity slightly for realism
		var intensity_variation = 0.8 + rng.randf() * 0.4
		var echo_color = Color(color.r, color.g, color.b, color.a * intensity_variation)
		
		# Draw echo with current shape
		_draw_single_echo(echo_pos, echo_size, echo_color, rng)

func _draw_single_echo(pos: Vector2, echo_size: float, color: Color, rng: RandomNumberGenerator):
	"""Draw a single echo with the current shape"""
	match current_echo_shape:
		EchoShape.CIRCLE:
			draw_circle(pos, echo_size, color)
		EchoShape.BOX:
			var box_size = echo_size * 1.6  # Make box roughly equivalent area
			var box_rect = Rect2(pos - Vector2(box_size/2, box_size/2), Vector2(box_size, box_size))
			draw_rect(box_rect, color)
		EchoShape.BLOB:
			_draw_blob_shape(pos, echo_size, color, rng)

func _draw_blob_shape(center: Vector2, radius: float, color: Color, rng: RandomNumberGenerator):
	"""Draw an organic blob shape using multiple circles"""
	var num_circles = 4 + rng.randi() % 4  # 4-7 circles for organic shape
	
	for i in range(num_circles):
		var angle = (i / float(num_circles)) * TAU + rng.randf() * 0.5
		var distance = radius * (0.3 + rng.randf() * 0.4)  # Vary distance from center
		var circle_pos = center + Vector2(cos(angle), sin(angle)) * distance
		var circle_radius = radius * (0.4 + rng.randf() * 0.4)  # Vary circle size
		
		draw_circle(circle_pos, circle_radius, color)

func _get_weather_color(intensity: float) -> Color:
	"""Get color based on weather intensity (like real radar)"""
	if intensity < 0.2:
		return Color(0.0, 1.0, 0.0, 0.7)  # Light green
	elif intensity < 0.4:
		return Color(1.0, 1.0, 0.0, 0.8)  # Yellow
	elif intensity < 0.6:
		return Color(1.0, 0.5, 0.0, 0.9)  # Orange
	elif intensity < 0.8:
		return Color(1.0, 0.0, 0.0, 1.0)  # Red
	else:
		return Color(1.0, 0.0, 1.0, 1.0)  # Magenta (severe)

func _draw_persistence_trails():
	"""Draw radar beam persistence trails"""
	for trail in persistence_trails:
		var beam_end = radar_center + Vector2(cos(trail.angle), sin(trail.angle)) * radar_radius
		var trail_color = Color(0.0, 1.0, 0.2, trail.alpha * 0.3)
		draw_line(radar_center, beam_end, trail_color, 1.0)

func _draw_radar_beam():
	"""Draw the current radar beam"""
	var beam_end = radar_center + Vector2(cos(sweep_angle), sin(sweep_angle)) * radar_radius
	
	# Main beam
	draw_line(radar_center, beam_end, Color(0.0, 1.0, 0.2, 1.0), 3.0)
	
	# Beam width indicators
	var beam_start_angle = sweep_angle - beam_width * 0.5
	var beam_end_angle = sweep_angle + beam_width * 0.5
	
	var beam_start = radar_center + Vector2(cos(beam_start_angle), sin(beam_start_angle)) * radar_radius
	var beam_end_pos = radar_center + Vector2(cos(beam_end_angle), sin(beam_end_angle)) * radar_radius
	
	draw_line(radar_center, beam_start, Color(0.0, 1.0, 0.2, 0.5), 1.0)
	draw_line(radar_center, beam_end_pos, Color(0.0, 1.0, 0.2, 0.5), 1.0)

func _draw_radar_info():
	"""Draw radar information overlay"""
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	var info_pos = Vector2(10, 25)
	var line_height = 20
	
	# Radar identification
	draw_string(font, info_pos, "SAN JII METRO WSR-88D", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	info_pos.y += line_height
	
	# Sweep information
	var sweep_degrees = int(rad_to_deg(sweep_angle))
	draw_string(font, info_pos, "Sweep: " + str(sweep_degrees) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	info_pos.y += line_height
	
	# Echo count
	draw_string(font, info_pos, "Echoes: " + str(active_echoes.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.CYAN)
	info_pos.y += line_height
	
	# Mode
	draw_string(font, info_pos, "Mode: Precipitation", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)

func _draw_context_menu():
	"""Draw emergency status context menu"""
	var font = ThemeDB.fallback_font
	if not font or selected_city == "":
		return
	
	var menu_items = ["Caution", "Shelter", "Evac", "Clear Status"]
	var menu_colors = [Color.YELLOW, Color.ORANGE, Color.RED, Color.WHITE]
	var item_height = 30
	var item_width = 120
	var menu_height = menu_items.size() * item_height
	
	# Adjust position if menu would go off screen
	var display_size = get_rect().size
	var menu_pos = context_menu_position
	if menu_pos.x + item_width > display_size.x:
		menu_pos.x = display_size.x - item_width
	if menu_pos.y + menu_height > display_size.y:
		menu_pos.y = display_size.y - menu_height
	
	# Draw menu background
	draw_rect(Rect2(menu_pos, Vector2(item_width, menu_height)), Color(0.1, 0.1, 0.1, 0.9))
	draw_rect(Rect2(menu_pos, Vector2(item_width, menu_height)), Color.WHITE, false, 2.0)
	
	# Draw menu items
	for i in range(menu_items.size()):
		var item_pos = menu_pos + Vector2(0, i * item_height)
		var item_rect = Rect2(item_pos, Vector2(item_width, item_height))
		
		# Highlight item on hover
		var mouse_pos = get_global_mouse_position()
		if item_rect.has_point(mouse_pos):
			draw_rect(item_rect, Color(0.3, 0.3, 0.3, 0.5))
		
		# Draw item text
		var text_pos = item_pos + Vector2(10, item_height * 0.7)
		draw_string(font, text_pos, menu_items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, menu_colors[i])

func _handle_context_menu_click(click_pos: Vector2):
	"""Handle clicks on context menu items"""
	if not show_context_menu or selected_city == "":
		return
	
	var menu_items = ["Caution", "Shelter", "Evac", "Clear Status"]
	var item_height = 30
	var item_width = 120
	var menu_height = menu_items.size() * item_height
	
	# Adjust position if menu would go off screen
	var display_size = get_rect().size
	var menu_pos = context_menu_position
	if menu_pos.x + item_width > display_size.x:
		menu_pos.x = display_size.x - item_width
	if menu_pos.y + menu_height > display_size.y:
		menu_pos.y = display_size.y - menu_height
	
	# Check if click is inside the menu area
	var menu_rect = Rect2(menu_pos, Vector2(item_width, menu_height))
	if not menu_rect.has_point(click_pos):
		# Click is outside menu, close it
		show_context_menu = false
		queue_redraw()
		return
	
	# Check which item was clicked
	for i in range(menu_items.size()):
		var item_pos = menu_pos + Vector2(0, i * item_height)
		var item_rect = Rect2(item_pos, Vector2(item_width, item_height))
		
		if item_rect.has_point(click_pos):
			match i:
				0: city_emergency_status[selected_city] = EmergencyStatus.CAUTION
				1: city_emergency_status[selected_city] = EmergencyStatus.SHELTER
				2: city_emergency_status[selected_city] = EmergencyStatus.EVAC
				3: city_emergency_status[selected_city] = EmergencyStatus.NONE
			
			print("Set ", selected_city, " status to: ", menu_items[i])
			show_context_menu = false
			queue_redraw()
			break

func _draw_city_markers(display_size: Vector2):
	"""Draw city markers and labels with temperatures"""
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	var cities = CityWeatherData.get_all_cities()
	for city_name in cities:
		var city_pos = CityWeatherData.get_city_position(city_name)
		var screen_pos = Vector2(city_pos.x * display_size.x, city_pos.y * display_size.y)
		var temperature = CityWeatherData.get_city_temperature(city_name)
		_draw_city_marker_with_temp(screen_pos, city_name, temperature, font)

func _draw_city_marker_with_temp(marker_position: Vector2, city_name: String, temperature: float, font: Font):
	"""Draw a city marker with temperature display and emergency status outline"""
	
	# Get emergency status for this city
	var emergency_status = city_emergency_status.get(city_name, EmergencyStatus.NONE)
	
	# Draw emergency status outline if needed
	if emergency_status != EmergencyStatus.NONE:
		var outline_color = Color.WHITE
		match emergency_status:
			EmergencyStatus.CAUTION:
				outline_color = Color.YELLOW
			EmergencyStatus.SHELTER:
				outline_color = Color.ORANGE
			EmergencyStatus.EVAC:
				outline_color = Color.RED
		
		# Draw thick colored outline
		draw_circle(marker_position, 10, outline_color, false, 3.0)
	
	# Draw city marker (white circle with black center)
	draw_circle(marker_position, 6, Color.WHITE)
	draw_circle(marker_position, 4, Color.BLACK)
	
	# Format temperature
	var temp_text = str(int(temperature)) + "°F"
	
	# Draw city name and temperature with background
	var name_size = font.get_string_size(city_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	var temp_size = font.get_string_size(temp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var max_width = max(name_size.x, temp_size.x)
	
	var name_pos = marker_position + Vector2(-name_size.x * 0.5, -25)
	var temp_pos = marker_position + Vector2(-temp_size.x * 0.5, -10)
	
	# Background for text
	var bg_rect = Rect2(name_pos - Vector2(3, 3), Vector2(max_width + 6, 20))
	draw_rect(bg_rect, Color(0, 0, 0, 0.8))
	
	# City name (white)
	draw_string(font, name_pos, city_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	
	# Temperature (yellow)
	draw_string(font, temp_pos, temp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

# Public interface
func set_weather_targets(targets: Array[WeatherEcho]):
	"""Set the weather targets for radar detection"""
	weather_targets = targets

func set_radius_multiplier(multiplier: float):
	"""Set the radar radius multiplier"""
	radar_radius_multiplier = clamp(multiplier, 0.1, 1.0)
	# Recalculate radius with current display size
	var display_size = get_rect().size
	if display_size != Vector2.ZERO:
		radar_radius = min(display_size.x, display_size.y) * radar_radius_multiplier

func get_current_sweep_angle() -> float:
	"""Get current radar sweep angle"""
	return sweep_angle

func get_active_echo_count() -> int:
	"""Get number of active radar echoes"""
	return active_echoes.size()

func set_map_texture(texture: Texture2D):
	"""Set the background map texture"""
	map_texture = texture

func set_echo_shape(shape: EchoShape):
	"""Set the echo shape for precipitation display"""
	current_echo_shape = shape
	queue_redraw()
