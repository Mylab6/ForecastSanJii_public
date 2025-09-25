class_name RadarRenderer extends RefCounted

# Radar rendering utilities for drawing radar displays
# Provides static methods for consistent radar visualization

static func draw_radar_background(canvas: CanvasItem, center: Vector2, radius: float, 
								 background_color: Color = Color(0.0, 0.0, 0.0, 0.3)):
	"""Draw radar background circle"""
	canvas.draw_circle(center, radius + 5, background_color)

static func draw_radar_scope(canvas: CanvasItem, center: Vector2, radius: float, 
							scope_color: Color = Color(0.0, 0.8, 0.0, 0.8)):
	"""Draw radar scope outline"""
	canvas.draw_arc(center, radius, 0, TAU, 64, scope_color, 2.0)

static func draw_range_rings(canvas: CanvasItem, center: Vector2, radius: float, 
							num_rings: int = 4, ring_color: Color = Color(0.0, 0.6, 0.0, 0.4)):
	"""Draw concentric range rings"""
	for i in range(1, num_rings + 1):
		var ring_radius = radius * (i / float(num_rings))
		canvas.draw_arc(center, ring_radius, 0, TAU, 32, ring_color, 1.0)

static func draw_crosshairs(canvas: CanvasItem, center: Vector2, radius: float, 
						   crosshair_color: Color = Color(0.0, 0.6, 0.0, 0.3)):
	"""Draw radar crosshairs"""
	# Horizontal line
	canvas.draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), crosshair_color, 1.0)
	# Vertical line
	canvas.draw_line(center - Vector2(0, radius), center + Vector2(0, radius), crosshair_color, 1.0)

static func draw_sweep_beam(canvas: CanvasItem, center: Vector2, radius: float, angle: float, 
						   beam_color: Color = Color(0.0, 1.0, 0.2, 1.0), trail_length: int = 15):
	"""Draw rotating radar sweep beam with trail"""
	var beam_end = center + Vector2(cos(angle), sin(angle)) * radius
	
	# Main sweep beam
	canvas.draw_line(center, beam_end, beam_color, 3.0)
	
	# Beam trail effect
	for i in range(1, trail_length):
		var trail_angle = angle - (i * 0.03)
		var trail_end = center + Vector2(cos(trail_angle), sin(trail_angle)) * radius
		var alpha = beam_color.a * (1.0 - i / float(trail_length))
		var trail_color = Color(beam_color.r, beam_color.g, beam_color.b, alpha)
		canvas.draw_line(center, trail_end, trail_color, 2.0)
	
	# Center dot
	canvas.draw_circle(center, 3, beam_color)

static func draw_weather_echo(canvas: CanvasItem, position: Vector2, echo: WeatherEcho, 
							 size_multiplier: float = 4.0, show_outline: bool = true):
	"""Draw a single weather echo"""
	var color = echo.get_display_color()
	var size = echo.get_display_size() * size_multiplier
	
	# Draw the echo circle
	canvas.draw_circle(position, size, color)
	
	# Add outline for high intensity echoes
	if show_outline and echo.intensity > 0.6:
		canvas.draw_arc(position, size + 1, 0, TAU, 16, Color.WHITE, 1.0)

static func draw_weather_echoes_with_sweep(canvas: CanvasItem, echoes: Array[WeatherEcho], 
										  radar_center: Vector2, radar_radius: float, 
										  sweep_angle: float, sweep_speed: float, 
										  persistence_time: float = 2.0):
	"""Draw weather echoes that spawn when sweep crosses them and fade to 30% by next sweep"""
	
	for echo in echoes:
		var screen_pos = echo.to_screen_position(radar_center, radar_radius)
		
		# Check if echo is within radar range
		var distance_from_center = radar_center.distance_to(screen_pos)
		if distance_from_center > radar_radius:
			continue
		
		# Calculate echo angle relative to radar center
		var echo_angle = radar_center.angle_to_point(screen_pos)
		if echo_angle < 0:
			echo_angle += TAU
		
		# Calculate how far the sweep has passed this echo
		var angle_diff = sweep_angle - echo_angle
		if angle_diff < 0:
			angle_diff += TAU
		if angle_diff > TAU:
			angle_diff -= TAU
		
		# Full sweep cycle time (360 degrees)
		var full_sweep_time = TAU / sweep_speed
		var current_cycle_progress = angle_diff / TAU
		
		# Only show echo if sweep has passed over it within one full rotation
		if angle_diff <= TAU:
			var intensity_factor: float
			
			# Spawn at 100% when sweep just crossed, fade to 30% by next sweep
			if current_cycle_progress <= 0.05:  # Just crossed (first 5% of cycle)
				intensity_factor = 1.0  # Full intensity when sweep just crossed
			else:
				# Fade from 100% to 30% over the rest of the sweep cycle
				var fade_progress = (current_cycle_progress - 0.05) / 0.95
				intensity_factor = lerp(1.0, 0.3, fade_progress)
			
			# Get echo color and apply intensity
			var echo_color = echo.get_display_color()
			echo_color.a *= intensity_factor
			
			# Draw the echo with calculated intensity
			var echo_size = echo.get_display_size() * 4.0
			canvas.draw_circle(screen_pos, echo_size, echo_color)
			
			# Add bright outline when sweep just crossed (within 5% of cycle)
			if current_cycle_progress <= 0.05:
				var outline_alpha = (1.0 - (current_cycle_progress / 0.05)) * 0.8
				var outline_color = Color.WHITE
				outline_color.a = outline_alpha
				canvas.draw_arc(screen_pos, echo_size + 1, 0, TAU, 16, outline_color, 2.0)

static func draw_city_marker(canvas: CanvasItem, position: Vector2, city_name: String, 
							font: Font, marker_color: Color = Color.WHITE, 
							text_color: Color = Color.WHITE):
	"""Draw a city marker with label"""
	if not font:
		return
	
	# Draw city marker (white circle with black center)
	canvas.draw_circle(position, 5, marker_color)
	canvas.draw_circle(position, 3, Color.BLACK)
	
	# Draw city name with background
	var text_size = font.get_string_size(city_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var text_pos = position + Vector2(-text_size.x * 0.5, -18)
	
	# Text background
	canvas.draw_rect(Rect2(text_pos - Vector2(2, 2), text_size + Vector2(4, 4)), Color(0, 0, 0, 0.7))
	# Text
	canvas.draw_string(font, text_pos, city_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)

static func draw_radar_info_panel(canvas: CanvasItem, position: Vector2, font: Font, 
								 radar_data: Dictionary):
	"""Draw radar information panel"""
	if not font:
		return
	
	var line_height = 20
	var current_pos = position
	
	# Radar title
	canvas.draw_string(font, current_pos, "SAN JII METRO DOPPLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	current_pos.y += line_height
	
	# Status
	canvas.draw_string(font, current_pos, "WSR-88D Active", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GREEN)
	current_pos.y += line_height
	
	# Range
	var range_text = "Range: " + str(radar_data.get("range", "120")) + "nm"
	canvas.draw_string(font, current_pos, range_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	current_pos.y += line_height
	
	# Sweep angle
	var sweep_deg = int(rad_to_deg(radar_data.get("sweep_angle", 0.0)))
	var sweep_text = "Sweep: " + str(sweep_deg) + "°"
	canvas.draw_string(font, current_pos, sweep_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	current_pos.y += line_height
	
	# Echo count
	var echo_count = radar_data.get("echo_count", 0)
	var echo_text = "Echoes: " + str(echo_count)
	canvas.draw_string(font, current_pos, echo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.CYAN)

static func draw_weather_alert(canvas: CanvasItem, position: Vector2, font: Font, 
							  max_intensity: float, alert_threshold: float = 0.7):
	"""Draw weather alert if conditions warrant"""
	if not font or max_intensity < alert_threshold:
		return
	
	var alert_text = "⚠️ SEVERE WEATHER ALERT"
	canvas.draw_string(font, position, alert_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
	
	var detail_pos = position + Vector2(0, 20)
	var dbz_value = int(max_intensity * 60)
	var detail_text = "Max Intensity: " + str(dbz_value) + " dBZ"
	canvas.draw_string(font, detail_pos, detail_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.ORANGE)

static func draw_velocity_scale(canvas: CanvasItem, position: Vector2, font: Font, 
							   scale_height: float = 200.0, scale_width: float = 20.0):
	"""Draw velocity color scale legend"""
	if not font:
		return
	
	# Title
	canvas.draw_string(font, position + Vector2(-10, -10), "Velocity (m/s)", 
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	
	# Color segments (simplified meteorological scale)
	var colors = [
		Color(0.0, 0.8, 0.0),    # Light green
		Color(0.0, 1.0, 0.0),    # Green
		Color(1.0, 1.0, 0.0),    # Yellow
		Color(1.0, 0.6, 0.0),    # Orange
		Color(1.0, 0.0, 0.0)     # Red
	]
	
	var labels = ["-20", "-10", "0", "+10", "+20"]
	
	for i in range(colors.size()):
		var y_start = position.y + (float(i) / colors.size()) * scale_height
		var y_end = position.y + (float(i + 1) / colors.size()) * scale_height
		var segment_height = y_end - y_start
		
		# Draw color segment
		canvas.draw_rect(Rect2(position.x, y_start, scale_width, segment_height), colors[i])
		
		# Draw label
		if i < labels.size():
			canvas.draw_string(font, Vector2(position.x + scale_width + 5, y_start + 10), 
							  labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

static func get_standard_radar_colors() -> Dictionary:
	"""Get standard meteorological radar colors"""
	return {
		"background": Color(0.0, 0.0, 0.0, 0.3),
		"scope": Color(0.0, 0.8, 0.0, 0.8),
		"grid": Color(0.0, 0.6, 0.0, 0.4),
		"crosshairs": Color(0.0, 0.6, 0.0, 0.3),
		"beam": Color(0.0, 1.0, 0.2, 1.0),
		"text": Color.WHITE,
		"alert": Color.RED,
		"warning": Color.ORANGE,
		"status": Color.GREEN,
		"info": Color.YELLOW
	}

static func calculate_radar_dimensions(display_size: Vector2, margin_factor: float = 0.1) -> Dictionary:
	"""Calculate optimal radar dimensions for given display size"""
	var margin = min(display_size.x, display_size.y) * margin_factor
	var available_size = min(display_size.x, display_size.y) - (margin * 2)
	var radius = available_size * 0.4
	var center = display_size * 0.5
	
	return {
		"center": center,
		"radius": radius,
		"margin": margin,
		"display_size": display_size
	}

static func is_point_in_radar_range(point: Vector2, radar_center: Vector2, radar_radius: float) -> bool:
	"""Check if a point is within radar display range"""
	return radar_center.distance_to(point) <= radar_radius

static func normalize_angle(angle: float) -> float:
	"""Normalize angle to 0-2π range"""
	while angle < 0:
		angle += TAU
	while angle >= TAU:
		angle -= TAU
	return angle