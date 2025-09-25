class_name RadarColors extends RefCounted

# Simple radar color system for weather intensity display
# Uses standard meteorological color scale

static func get_intensity_color(intensity: float, alpha: float = 1.0) -> Color:
	"""Get color based on weather intensity using standard meteorological scale"""
	# Clamp intensity to 0-1 range
	intensity = clamp(intensity, 0.0, 1.0)
	
	# Standard NWS radar color scale with natural transparency
	if intensity < 0.1:
		return Color(0.0, 0.0, 0.0, 0.0)  # Transparent (no precipitation)
	elif intensity < 0.2:
		return Color(0.0, 0.9, 0.0, alpha * 0.5)  # Light green - more transparent
	elif intensity < 0.4:
		return Color(0.0, 0.7, 0.0, alpha * 0.6)  # Green - semi-transparent
	elif intensity < 0.6:
		return Color(1.0, 1.0, 0.0, alpha * 0.7)  # Yellow - moderately transparent
	elif intensity < 0.8:
		return Color(1.0, 0.5, 0.0, alpha * 0.8)  # Orange - less transparent
	elif intensity < 0.9:
		return Color(1.0, 0.0, 0.0, alpha * 0.85)  # Red - mostly opaque
	else:
		return Color(1.0, 0.0, 1.0, alpha * 0.9)  # Magenta (extreme) - nearly opaque

static func get_dbz_color(dbz_value: float, alpha: float = 1.0) -> Color:
	"""Get color based on dBZ reflectivity value"""
	# Convert dBZ to intensity (0-60 dBZ range)
	var intensity = clamp(dbz_value / 60.0, 0.0, 1.0)
	return get_intensity_color(intensity, alpha)

static func get_color_scale_info() -> Dictionary:
	"""Get information about the color scale for legends"""
	return {
		"ranges": [
			{"min": 0, "max": 5, "color": Color(0.0, 0.0, 0.0, 0.0), "label": "No Echo"},
			{"min": 5, "max": 15, "color": Color(0.0, 0.9, 0.0, 0.6), "label": "Light"},
			{"min": 15, "max": 25, "color": Color(0.0, 0.7, 0.0, 0.7), "label": "Moderate"},
			{"min": 25, "max": 35, "color": Color(1.0, 1.0, 0.0, 0.8), "label": "Heavy"},
			{"min": 35, "max": 45, "color": Color(1.0, 0.5, 0.0, 0.9), "label": "Very Heavy"},
			{"min": 45, "max": 55, "color": Color(1.0, 0.0, 0.0, 1.0), "label": "Intense"},
			{"min": 55, "max": 70, "color": Color(1.0, 0.0, 1.0, 1.0), "label": "Extreme"}
		],
		"unit": "dBZ"
	}