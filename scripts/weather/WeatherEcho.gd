class_name WeatherEcho extends RefCounted

# Simple weather echo data structure for radar display
# Replaces the complex StormData system with something that actually works

var position: Vector2      # Normalized coordinates (0-1) relative to radar scope
var intensity: float       # Weather intensity (0-1, maps to dBZ values)
var size: float           # Echo size multiplier for drawing
var age: float            # Time since echo was created
var max_age: float        # Maximum age before echo expires
var velocity: Vector2     # Movement vector for storm motion
var echo_type: String     # "light", "moderate", "heavy", "severe"
var random_seed: int = 0  # Stable seed for rendering jitter-free patterns

func _init(pos: Vector2 = Vector2.ZERO, intens: float = 0.5, echo_size: float = 1.0, 
           max_lifetime: float = 10.0, vel: Vector2 = Vector2.ZERO, type: String = "moderate"):
	position = pos
	intensity = clamp(intens, 0.0, 1.0)
	size = max(echo_size, 0.1)
	age = 0.0
	max_age = max_lifetime
	velocity = vel
	echo_type = type
	random_seed = _build_seed_from_properties(pos, intens, echo_size)

func update(delta: float):
	"""Update echo age and position"""
	age += delta
	position += velocity * delta
	
	# Keep position within radar bounds (0-1)
	position.x = clamp(position.x, 0.0, 1.0)
	position.y = clamp(position.y, 0.0, 1.0)

func is_expired() -> bool:
	"""Check if echo has exceeded its maximum age"""
	return age >= max_age

func get_fade_alpha() -> float:
	"""Get alpha value based on age for fading effect"""
	if max_age <= 0:
		return 1.0
	
	var fade_start = max_age * 0.7  # Start fading at 70% of max age
	if age < fade_start:
		return 1.0
	else:
		var fade_progress = (age - fade_start) / (max_age - fade_start)
		return 1.0 - fade_progress

func get_display_color() -> Color:
	"""Get color based on intensity using standard meteorological scale"""
	var alpha = get_fade_alpha()
	return RadarColors.get_intensity_color(intensity, alpha)

func get_display_size() -> float:
	"""Get size for drawing, adjusted by intensity"""
	return size * (0.5 + intensity * 0.5)  # Larger echoes for higher intensity

func to_screen_position(radar_center: Vector2, radar_radius: float) -> Vector2:
	"""Convert normalized position to screen coordinates"""
	var relative_pos = (position - Vector2(0.5, 0.5)) * 2.0  # Convert to -1 to 1
	return radar_center + relative_pos * radar_radius

func get_dbz_value() -> float:
	"""Convert intensity to approximate dBZ value for display"""
	return intensity * 60.0  # 0-60 dBZ range

func duplicate_echo() -> WeatherEcho:
	"""Create a copy of this echo"""
	var copy = WeatherEcho.new(position, intensity, size, max_age, velocity, echo_type)
	copy.age = age
	copy.random_seed = random_seed
	return copy

func _build_seed_from_properties(pos: Vector2, intens: float, echo_size: float) -> int:
	"""Derive a deterministic seed from echo properties when one is not provided"""
	var px = int(round(pos.x * 10000.0))
	var py = int(round(pos.y * 10000.0))
	var i_hash = int(round(intens * 1000.0))
	var size_hash = int(round(echo_size * 1000.0))
	var hash_value = px * 73856093 ^ py * 19349663 ^ i_hash * 83492791 ^ size_hash * 2654435761
	if hash_value == 0:
		hash_value = 1337  # Avoid zero seeds for RNG stability
	return abs(hash_value) % 2147483647