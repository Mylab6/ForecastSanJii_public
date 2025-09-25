class_name StormData extends Resource

# Storm cell data structure
class StormCell:
	var position: Vector2
	var width: float
	var height: float
	var reflectivity: float  # dBZ value
	var rotation: float  # Radians
	var velocity: Vector2  # Storm motion
	var cell_type: String  # "convective", "stratiform", "mixed"
	
	func _init(pos: Vector2 = Vector2.ZERO, w: float = 10.0, h: float = 10.0, 
			   dbz: float = 20.0, rot: float = 0.0, vel: Vector2 = Vector2.ZERO, 
			   type: String = "convective"):
		position = pos
		width = w
		height = h
		reflectivity = dbz
		rotation = rot
		velocity = vel
		cell_type = type

# Core storm data
var storm_cells: Array[StormCell] = []
@export var velocity_data: Array[Vector2] = []
@export var reflectivity_data: Array[float] = []
@export var storm_motion: Vector2 = Vector2.ZERO
@export var timestamp: float = 0.0

# Storm signature flags
@export var rotation_signature: bool = false
@export var mesocyclone_present: bool = false
@export var hook_echo: bool = false
@export var bow_echo: bool = false
@export var bounded_weak_echo: bool = false
@export var three_body_scatter: bool = false

# Storm classification
@export var storm_type: String = "thunderstorm"
@export var max_reflectivity: float = 0.0
@export var storm_top_height: float = 0.0  # km
@export var vertically_integrated_liquid: float = 0.0  # kg/m²

func _init():
	storm_cells = []
	velocity_data = []
	reflectivity_data = []
	storm_motion = Vector2.ZERO
	timestamp = Time.get_unix_time_from_system()
	reset_signatures()

func reset_signatures():
	"""Reset all storm signature flags"""
	rotation_signature = false
	mesocyclone_present = false
	hook_echo = false
	bow_echo = false
	bounded_weak_echo = false
	three_body_scatter = false

func add_storm_cell(position: Vector2, width: float, height: float, 
				   reflectivity: float, rotation: float = 0.0, 
				   velocity: Vector2 = Vector2.ZERO, cell_type: String = "convective"):
	"""Add a new storm cell to the data"""
	var cell = StormCell.new(position, width, height, reflectivity, rotation, velocity, cell_type)
	storm_cells.append(cell)
	
	# Update maximum reflectivity
	if reflectivity > max_reflectivity:
		max_reflectivity = reflectivity

func generate_supercell_pattern(center: Vector2, intensity: float = 55.0):
	"""Generate authentic supercell radar pattern"""
	storm_type = "supercell"
	max_reflectivity = intensity
	
	# Main updraft core
	add_storm_cell(center, 15.0, 20.0, intensity, 0.0, storm_motion, "convective")
	
	# Hook echo formation
	if intensity > 50.0:
		hook_echo = true
		var hook_pos = center + Vector2(-8, 12)
		add_storm_cell(hook_pos, 8.0, 15.0, intensity - 10.0, PI * 0.25, storm_motion, "convective")
	
	# Mesocyclone signature
	if intensity > 45.0:
		mesocyclone_present = true
		rotation_signature = true
		var meso_pos = center + Vector2(-5, 8)
		add_storm_cell(meso_pos, 6.0, 8.0, intensity - 15.0, PI * 0.5, storm_motion, "convective")
	
	# Bounded weak echo region
	if intensity > 50.0:
		bounded_weak_echo = true
		var bwer_pos = center + Vector2(0, -5)
		add_storm_cell(bwer_pos, 4.0, 6.0, 15.0, 0.0, storm_motion, "stratiform")
	
	# Forward flank downdraft
	var ffd_pos = center + Vector2(10, -8)
	add_storm_cell(ffd_pos, 12.0, 10.0, intensity - 20.0, 0.0, storm_motion, "mixed")

func generate_hurricane_pattern(center: Vector2, intensity: float = 65.0, eye_diameter: float = 25.0):
	"""Generate authentic hurricane radar pattern"""
	storm_type = "hurricane"
	max_reflectivity = intensity
	
	# Eye wall
	var eyewall_radius = eye_diameter * 0.5
	var eyewall_thickness = 8.0
	
	for angle in range(0, 360, 15):
		var rad = deg_to_rad(angle)
		var inner_pos = center + Vector2(cos(rad), sin(rad)) * eyewall_radius
		var outer_pos = center + Vector2(cos(rad), sin(rad)) * (eyewall_radius + eyewall_thickness)
		
		add_storm_cell(inner_pos, 6.0, 8.0, intensity, rad, storm_motion, "convective")
		add_storm_cell(outer_pos, 4.0, 6.0, intensity - 10.0, rad, storm_motion, "convective")
	
	# Spiral rain bands
	for band in range(3):
		var band_radius = eyewall_radius + 20.0 + (band * 15.0)
		for angle in range(0, 360, 30):
			var rad = deg_to_rad(angle + band * 45)  # Spiral offset
			var pos = center + Vector2(cos(rad), sin(rad)) * band_radius
			var band_intensity = intensity - 20.0 - (band * 5.0)
			
			add_storm_cell(pos, 8.0, 12.0, band_intensity, rad, storm_motion, "mixed")

func generate_squall_line_pattern(start_pos: Vector2, end_pos: Vector2, intensity: float = 45.0):
	"""Generate authentic squall line radar pattern"""
	storm_type = "squall_line"
	max_reflectivity = intensity
	
	var line_vector = end_pos - start_pos
	var line_length = line_vector.length()
	var segments = int(line_length / 8.0)  # 8km segments
	
	for i in range(segments):
		var t = float(i) / float(segments - 1) if segments > 1 else 0.0
		var pos = start_pos + line_vector * t
		
		# Main convective line
		var segment_intensity = intensity + randf_range(-5.0, 5.0)
		add_storm_cell(pos, 6.0, 15.0, segment_intensity, line_vector.angle(), storm_motion, "convective")
		
		# Bow echo formation (occasional)
		if randf() < 0.3 and intensity > 40.0:
			bow_echo = true
			var bow_offset = Vector2(0, 8).rotated(line_vector.angle() + PI * 0.5)
			add_storm_cell(pos + bow_offset, 8.0, 12.0, segment_intensity - 5.0, 
						  line_vector.angle(), storm_motion, "convective")
		
		# Trailing stratiform region
		var trailing_offset = Vector2(-12, 0).rotated(line_vector.angle())
		add_storm_cell(pos + trailing_offset, 10.0, 8.0, intensity - 15.0, 
					  line_vector.angle(), storm_motion, "stratiform")

func generate_scattered_storms_pattern(region_center: Vector2, region_size: Vector2, 
									  num_cells: int = 5, intensity: float = 35.0):
	"""Generate scattered thunderstorm pattern"""
	storm_type = "scattered_thunderstorms"
	max_reflectivity = intensity
	
	for i in range(num_cells):
		var random_offset = Vector2(
			randf_range(-region_size.x * 0.5, region_size.x * 0.5),
			randf_range(-region_size.y * 0.5, region_size.y * 0.5)
		)
		var cell_pos = region_center + random_offset
		var cell_intensity = intensity + randf_range(-10.0, 10.0)
		var cell_size = randf_range(8.0, 15.0)
		
		add_storm_cell(cell_pos, cell_size, cell_size * 1.2, cell_intensity, 
					  randf() * PI * 2, storm_motion, "convective")

func update_storm_motion(delta_time: float):
	"""Update storm cell positions based on motion vectors"""
	timestamp += delta_time
	
	for cell in storm_cells:
		cell.position += cell.velocity * delta_time

func get_max_reflectivity_in_area(area_center: Vector2, area_radius: float) -> float:
	"""Get maximum reflectivity within a specified area"""
	var max_dbz = 0.0
	
	for cell in storm_cells:
		var distance = cell.position.distance_to(area_center)
		if distance <= area_radius:
			if cell.reflectivity > max_dbz:
				max_dbz = cell.reflectivity
	
	return max_dbz

func get_storm_cells_in_area(area_center: Vector2, area_radius: float) -> Array[StormCell]:
	"""Get all storm cells within a specified area"""
	var cells_in_area: Array[StormCell] = []
	
	for cell in storm_cells:
		var distance = cell.position.distance_to(area_center)
		if distance <= area_radius:
			cells_in_area.append(cell)
	
	return cells_in_area

func has_severe_weather_signatures() -> bool:
	"""Check if storm data contains severe weather signatures"""
	return (rotation_signature or mesocyclone_present or hook_echo or 
			bow_echo or max_reflectivity > 50.0)

func get_storm_summary() -> Dictionary:
	"""Get comprehensive storm data summary"""
	return {
		"storm_type": storm_type,
		"cell_count": storm_cells.size(),
		"max_reflectivity": max_reflectivity,
		"storm_motion": storm_motion,
		"has_rotation": rotation_signature,
		"has_mesocyclone": mesocyclone_present,
		"has_hook_echo": hook_echo,
		"has_bow_echo": bow_echo,
		"has_bwer": bounded_weak_echo,
		"severe_signatures": has_severe_weather_signatures(),
		"timestamp": timestamp
	}

func clear_storm_data():
	"""Clear all storm data and reset to initial state"""
	storm_cells.clear()
	velocity_data.clear()
	reflectivity_data.clear()
	storm_motion = Vector2.ZERO
	max_reflectivity = 0.0
	storm_top_height = 0.0
	vertically_integrated_liquid = 0.0
	reset_signatures()
	timestamp = Time.get_unix_time_from_system()
