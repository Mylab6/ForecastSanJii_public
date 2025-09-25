extends Control

# 1999 Weather Channel San Jii Metro Hurricane Radar Simulator - MAP-ENHANCED VERSION
# Features ultra-realistic polygon precipitation with web-compatible shaders
# Now uses beautiful IslandMap.png as background for professional radar display
# 1999 Weather Channel San Jii Metro Hurricane Radar Simulator with REALISTIC DATA
var storm_cells := []
var precipitation_polygons := []
var noise_generator: FastNoiseLite
var frame_timer := 0.0
var frame_interval := 0.2 # Faster updates for smooth animation
var wind_shear := Vector2(0.8, -0.3) # Northeast wind pattern
var hurricane_center := Vector2(300, 600) # Off-coast low pressure
var hurricane_intensity := 0.7
var terrain_elevation := {}

# Web-optimized shader materials for enhanced visual effects
var precipitation_shader_material: ShaderMaterial
var lightning_shader_material: ShaderMaterial

# Performance optimization settings for web deployment
var web_optimized := true  # Enable web performance optimizations
var max_polygon_points := 16  # Reduced for web performance (was 28)
var reduced_noise_octaves := 2  # Simplified noise for web (was 4)
var shader_time := 0.0

# San Jii Metropolitan Area - Map-based coordinates (no city drawing needed)
var sanjii_cities := [
	{"name": "CIUDADLONG", "pos": Vector2(520, 350), "population": 1247000, "type": "capital"},
	{"name": "PUERTOSHAN", "pos": Vector2(580, 280), "population": 892000, "type": "port"},
	{"name": "MONTAÑAWEI", "pos": Vector2(440, 250), "population": 653000, "type": "mountain"},
	{"name": "PLAYAHAI", "pos": Vector2(620, 420), "population": 534000, "type": "beach"},
	{"name": "VALLEGU", "pos": Vector2(380, 380), "population": 428000, "type": "valley"}
]

# Background map texture
var island_map_texture: Texture2D

# Real weather patterns based on atmospheric physics
var atmospheric_layers := [
	{"altitude": 0, "wind": Vector2(0.5, -0.2), "temperature": 85},
	{"altitude": 5000, "wind": Vector2(1.2, -0.8), "temperature": 65},
	{"altitude": 15000, "wind": Vector2(2.1, -1.2), "temperature": 35},
	{"altitude": 30000, "wind": Vector2(3.5, 0.2), "temperature": -40}
]

func _ready():
	print("Initializing REALISTIC San Jii Metro hurricane radar simulation...")
	print("Viewport size: ", get_viewport_rect().size)
	
	# Initialize web-optimized shader materials
	_initialize_shader_materials()
	
	# Load the San Jii Metro island map
	_load_island_map()
	
	# Initialize Perlin noise for realistic precipitation patterns (web-optimized)
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = Time.get_unix_time_from_system() as int
	noise_generator.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_generator.frequency = 0.02
	noise_generator.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_generator.fractal_octaves = reduced_noise_octaves if web_optimized else 4
	noise_generator.frequency = 0.05
	noise_generator.fractal_octaves = 4
	noise_generator.fractal_gain = 0.5
	
	# Generate terrain elevation map for orographic effects (Montaña-Long Ridge)
	_generate_terrain_map()
	
	# Initialize realistic storm systems
	_generate_realistic_weather_systems()
	print("Generated ", storm_cells.size(), " realistic storm cells")
	
	# Generate precipitation polygons from real atmospheric data
	_generate_precipitation_polygons()
	
	# Draw city labels with population-based sizing and cultural styling
	for city in sanjii_cities:
		var label = Label.new()
		label.text = city["name"]
		label.position = city["pos"]
		var font_size = 14 + int(city["population"] / 200000) * 3
		label.add_theme_font_size_override("font_size", font_size)
		
		# Color-code cities by type (Spanish-Chinese cultural theme)
		var city_color = Color.WHITE
		match city["type"]:
			"capital":
				city_color = Color(1.0, 0.8, 0.2)  # Imperial gold for capital (龙 - dragon)
			"port":
				city_color = Color(0.2, 0.6, 0.9)  # Ocean blue for port (山 - mountain by sea)
			"mountain":
				city_color = Color(0.7, 0.5, 0.3)  # Earth brown for mountain (伟 - magnificent)
			"beach":
				city_color = Color(0.3, 0.9, 0.7)  # Jade green for beach (海 - sea)
			"valley":
				city_color = Color(0.5, 0.8, 0.3)  # Rice green for valley (谷 - grain valley)
		
		label.add_theme_color_override("font_color", city_color)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		add_child(label)
	
	print("Added ", sanjii_cities.size(), " San Jii city labels with cultural styling")
	set_process(true)

func _initialize_shader_materials():
	# Load precipitation shader for enhanced visual effects
	var precip_shader = load("res://precipitation_shader.gdshader")
	if precip_shader:
		precipitation_shader_material = ShaderMaterial.new()
		precipitation_shader_material.shader = precip_shader
		precipitation_shader_material.set_shader_parameter("time", 0.0)
		precipitation_shader_material.set_shader_parameter("intensity", 0.5)
		precipitation_shader_material.set_shader_parameter("storm_center", Vector2(0.5, 0.5))
		precipitation_shader_material.set_shader_parameter("storm_type", 0.0)
		precipitation_shader_material.set_shader_parameter("base_color", Color(0.0, 1.0, 0.0, 0.8))
		print("Precipitation shader loaded successfully")
	else:
		print("Warning: Precipitation shader not found - using fallback rendering")
	
	# Load lightning shader for storm effects
	var lightning_shader = load("res://lightning_shader.gdshader")
	if lightning_shader:
		lightning_shader_material = ShaderMaterial.new()
		lightning_shader_material.shader = lightning_shader
		lightning_shader_material.set_shader_parameter("time", 0.0)
		lightning_shader_material.set_shader_parameter("lightning_start", Vector2(0.3, 0.2))
		lightning_shader_material.set_shader_parameter("lightning_end", Vector2(0.7, 0.8))
		lightning_shader_material.set_shader_parameter("flash_intensity", 1.0)
		lightning_shader_material.set_shader_parameter("bolt_width", 0.005)
		print("Lightning shader loaded successfully")
	else:
		print("Warning: Lightning shader not found - using fallback rendering")

func _load_island_map():
	# Load the beautiful San Jii Metropolitan Area map
	island_map_texture = load("res://IslandMap.png")
	if island_map_texture:
		print("San Jii Metropolitan Area map loaded successfully!")
		print("Map dimensions: ", island_map_texture.get_width(), "x", island_map_texture.get_height())
	else:
		print("Error: Could not load IslandMap.png")

func _generate_terrain_map():
	# Generate elevation data for San Jii Metro (affects precipitation)
	var viewport_size = get_viewport_rect().size
	for x in range(0, int(viewport_size.x), 20):
		for y in range(0, int(viewport_size.y), 20):
			var elevation = 0
			# Montaña-Long Ridge (central mountain range)
			if x > 400 and x < 550 and y > 200 and y < 350:
				elevation = randf_range(100, 200)  # Higher peaks
			# Coastal plains near Bahía Azul
			elif x < 250 or x > 650 or y < 150 or y > 500:
				elevation = randf_range(0, 30)
			# Rolling hills and valleys
			else:
				elevation = randf_range(30, 100)
			terrain_elevation[Vector2(x, y)] = elevation

func _generate_realistic_weather_systems():
	storm_cells.clear()
	
	# Simulate real atmospheric conditions
	var random_seed = Time.get_unix_time_from_system() as int
	seed(random_seed)
	
	# Hurricane outflow bands (realistic asymmetric structure)
	if hurricane_intensity > 0.3:
		_generate_hurricane_spiral_bands()
	
	# Afternoon convective thunderstorms (typical Florida pattern)
	_generate_convective_storms()
	
	# Sea breeze convergence zones
	_generate_sea_breeze_storms()
	
	# Frontal systems
	_generate_frontal_precipitation()

func _generate_hurricane_spiral_bands():
	var center = hurricane_center
	var max_radius = 400 * hurricane_intensity
	
	# Generate spiral bands using logarithmic spiral
	for band in range(3):
		var band_angle_offset = band * 120.0
		for point in range(40):
			var angle = deg_to_rad(point * 9.0 + band_angle_offset)
			var radius = 80 + point * 8.0
			if radius > max_radius:
				break
				
			var spiral_pos = center + Vector2(
				cos(angle) * radius,
				sin(angle) * radius
			)
			
			# Only add if within viewport
			if spiral_pos.x > 0 and spiral_pos.x < get_viewport_rect().size.x and \
			   spiral_pos.y > 0 and spiral_pos.y < get_viewport_rect().size.y:
				
				var intensity = 45 + (hurricane_intensity * 30) - (radius / max_radius * 20)
				storm_cells.append({
					"center": spiral_pos,
					"radius": randf_range(8, 25),
					"intensity": clamp(intensity, 20, 75),
					"type": "hurricane_band",
					"drift": _calculate_hurricane_wind(spiral_pos, center) * 0.3,
					"rotation_rate": 2.0 + hurricane_intensity
				})

func _generate_convective_storms():
	# Afternoon thunderstorms over land (heating effect)
	for i in range(8):
		var land_pos = Vector2(
			randf_range(350, 650),  # Over land areas
			randf_range(200, 450)
		)
		
		# Check if over elevated terrain (more likely)
		var elevation = _get_terrain_elevation(land_pos)
		if elevation > 50 or randf() < 0.4:  # Higher chance on hills
			storm_cells.append({
				"center": land_pos,
				"radius": randf_range(12, 35),
				"intensity": randf_range(35, 65),
				"type": "convective",
				"drift": Vector2(randf_range(-0.2, 0.8), randf_range(-0.6, 0.2)),
				"growth_rate": randf_range(0.1, 0.3)
			})

func _generate_sea_breeze_storms():
	# Sea breeze convergence creates storms inland
	var convergence_lines = [
		{"start": Vector2(600, 300), "end": Vector2(500, 500), "side": "east"},
		{"start": Vector2(300, 300), "end": Vector2(450, 450), "side": "west"}
	]
	
	for line in convergence_lines:
		for i in range(5):
			var t = float(i) / 4.0
			var pos = line["start"].lerp(line["end"], t)
			pos += Vector2(randf_range(-30, 30), randf_range(-30, 30))
			
			storm_cells.append({
				"center": pos,
				"radius": randf_range(15, 40),
				"intensity": randf_range(25, 50),
				"type": "sea_breeze",
				"drift": Vector2(randf_range(-0.3, 0.3), randf_range(-0.4, 0.1)),
				"merger_tendency": 0.7
			})

func _generate_frontal_precipitation():
	# Cold front moving through (linear precipitation)
	var front_angle = deg_to_rad(135)  # Southwest to northeast
	var front_center = Vector2(200, 400)
	
	for i in range(15):
		var distance = i * 30
		var pos = front_center + Vector2(
			cos(front_angle) * distance,
			sin(front_angle) * distance
		)
		
		if pos.x > 0 and pos.x < get_viewport_rect().size.x and \
		   pos.y > 0 and pos.y < get_viewport_rect().size.y:
			storm_cells.append({
				"center": pos,
				"radius": randf_range(20, 50),
				"intensity": randf_range(20, 45),
				"type": "frontal",
				"drift": Vector2(1.2, -0.8),  # Northeast movement
				"linear_extent": 80
			})

func _generate_precipitation_polygons():
	precipitation_polygons.clear()
	
	# Generate ultra-realistic precipitation shapes using advanced noise techniques
	for cell in storm_cells:
		var polygon_points = PackedVector2Array()
		var num_points = max_polygon_points if web_optimized else (16 + randi_range(0, 12))
		
		# Create base shape with optimized noise layers
		var primary_noise = noise_generator.get_noise_2d(cell["center"].x, cell["center"].y)
		var time_offset = Time.get_unix_time_from_system() * 0.1  # Slow evolution
		
		for i in range(num_points):
			var angle = (float(i) / num_points) * TAU
			var base_radius = cell["radius"]
			
			# Layer 1: Primary shape variation using Perlin noise
			var noise_value1 = noise_generator.get_noise_2d(
				cell["center"].x + cos(angle) * 100,
				cell["center"].y + sin(angle) * 100 + time_offset
			)
			
			# Layer 2: Secondary detail using higher frequency
			var noise_value2 = noise_generator.get_noise_2d(
				cell["center"].x * 2.5 + cos(angle) * 50,
				cell["center"].y * 2.5 + sin(angle) * 50 + time_offset * 2
			)
			
			# Layer 3: Fine detail using even higher frequency
			var noise_value3 = noise_generator.get_noise_2d(
				cell["center"].x * 5.0 + cos(angle) * 25,
				cell["center"].y * 5.0 + sin(angle) * 25 + time_offset * 3
			)
			
			# Combine noise layers with different weights
			var combined_noise = (noise_value1 * 0.6) + (noise_value2 * 0.3) + (noise_value3 * 0.1)
			
			# Apply noise-based radius variation
			var radius_variation = 1.0 + (combined_noise * 0.8)
			
			# Storm type specific shape modifications
			match cell["type"]:
				"hurricane_band":
					# Hurricane bands are more elongated and curved
					var spiral_factor = sin(angle * 2 + primary_noise * PI) * 0.3
					radius_variation *= (1.0 + spiral_factor)
				"convective":
					# Convective storms have more chaotic, bumpy edges
					var chaos_factor = sin(angle * 6 + noise_value2 * PI * 2) * 0.4
					radius_variation *= (1.0 + chaos_factor)
				"sea_breeze":
					# Sea breeze storms are more linear and stretched
					var linear_factor = cos(angle + PI/4) * 0.2
					radius_variation *= (1.0 + linear_factor)
				"frontal":
					# Frontal precipitation is more uniform but with fine structure
					radius_variation *= (1.0 + noise_value3 * 0.3)
			
			var actual_radius = base_radius * radius_variation
			
			# Add terrain influence for orographic enhancement
			var terrain_effect = _get_terrain_elevation(cell["center"]) / 150.0
			actual_radius *= (1.0 + terrain_effect * 0.5)
			
			# Add wind shear stretching effect
			var wind_influence = wind_shear.normalized()
			var wind_stretch = wind_influence.dot(Vector2(cos(angle), sin(angle))) * wind_shear.length() * 0.1
			actual_radius += wind_stretch
			
			# Ensure minimum radius
			actual_radius = max(actual_radius, base_radius * 0.3)
			
			var point = cell["center"] + Vector2(
				cos(angle) * actual_radius,
				sin(angle) * actual_radius
			)
			polygon_points.append(point)
		
		# Add sub-cells for complex storm structure
		var subcells = []
		if cell["intensity"] > 45 and cell["type"] in ["convective", "hurricane_band"]:
			# Create embedded high-intensity cores
			var num_cores = randi_range(1, 3)
			for j in range(num_cores):
				var core_offset = Vector2(
					randf_range(-cell["radius"] * 0.4, cell["radius"] * 0.4),
					randf_range(-cell["radius"] * 0.4, cell["radius"] * 0.4)
				)
				var core_center = cell["center"] + core_offset
				var core_radius = cell["radius"] * randf_range(0.2, 0.4)
				
				var core_points = PackedVector2Array()
				for k in range(8):
					var core_angle = (float(k) / 8.0) * TAU
					var core_noise = noise_generator.get_noise_2d(
						core_center.x * 8 + cos(core_angle) * 20,
						core_center.y * 8 + sin(core_angle) * 20
					)
					var core_actual_radius = core_radius * (1.0 + core_noise * 0.3)
					core_points.append(core_center + Vector2(
						cos(core_angle) * core_actual_radius,
						sin(core_angle) * core_actual_radius
					))
				
				subcells.append({
					"points": core_points,
					"intensity": cell["intensity"] + randf_range(5, 15),
					"type": cell["type"] + "_core"
				})
		
		precipitation_polygons.append({
			"points": polygon_points,
			"intensity": cell["intensity"],
			"type": cell["type"],
			"subcells": subcells
		})

func _calculate_hurricane_wind(pos: Vector2, center: Vector2) -> Vector2:
	var diff = pos - center
	var distance = diff.length()
	if distance < 10:
		return Vector2.ZERO
	
	# Cyclonic rotation with realistic wind profile
	var tangential = Vector2(-diff.y, diff.x).normalized()
	var wind_speed = hurricane_intensity * (200.0 / (distance + 50))
	return tangential * wind_speed

func _get_terrain_elevation(pos: Vector2) -> float:
	# Find nearest terrain point
	var nearest_key = Vector2.ZERO
	var min_dist = INF
	
	for key in terrain_elevation.keys():
		var dist = pos.distance_to(key)
		if dist < min_dist:
			min_dist = dist
			nearest_key = key
	
	if terrain_elevation.has(nearest_key):
		return terrain_elevation[nearest_key]
	return 0.0



func _process(delta):
	frame_timer += delta
	shader_time += delta
	
	# Update shader time parameters for visual effects
	if precipitation_shader_material:
		precipitation_shader_material.set_shader_parameter("time", shader_time)
	if lightning_shader_material:
		lightning_shader_material.set_shader_parameter("time", shader_time)
	
	if frame_timer >= frame_interval:
		frame_timer = 0
		_update_storm()
		queue_redraw()

func _update_storm():
	# Realistic atmospheric dynamics
	_update_hurricane_motion()
	
	# Update each storm cell with physics-based behavior
	for i in range(storm_cells.size() - 1, -1, -1):
		var cell = storm_cells[i]
		
		# Apply wind shear and atmospheric layers
		var wind_drift = _calculate_wind_at_altitude(cell["center"])
		cell["drift"] = cell["drift"].lerp(wind_drift, 0.1)
		
		# Move storm
		cell["center"] += cell["drift"]
		
		# Storm evolution based on type
		match cell["type"]:
			"hurricane_band":
				_update_hurricane_cell(cell)
			"convective":
				_update_convective_cell(cell)
			"sea_breeze":
				_update_sea_breeze_cell(cell)
			"frontal":
				_update_frontal_cell(cell)
		
		# Add storm shape evolution
		_evolve_storm_shape(cell)
		
		# Check for storm merger
		_check_storm_merger(i)
		
		# Remove weak storms
		if cell["intensity"] < 10 or cell["radius"] < 5:
			storm_cells.remove_at(i)
		
		# Wrap around screen edges with realistic behavior
		_wrap_storm_position(cell)
	
	# Regenerate precipitation polygons with updated positions and shapes
	_generate_precipitation_polygons()
	
	# Evolve hurricane system
	hurricane_intensity += randf_range(-0.02, 0.01)
	hurricane_intensity = clamp(hurricane_intensity, 0.1, 1.0)
	hurricane_center += Vector2(randf_range(-0.5, 1.0), randf_range(-1.0, 0.5))

func _evolve_storm_shape(cell):
	# Add realistic shape evolution parameters
	if not cell.has("shape_evolution"):
		cell["shape_evolution"] = {
			"asymmetry": randf_range(0.0, 0.3),
			"elongation": randf_range(0.8, 1.2),
			"rotation": randf_range(-0.1, 0.1)
		}
	
	# Evolve shape parameters based on storm type and conditions
	var evolution = cell["shape_evolution"]
	
	match cell["type"]:
		"hurricane_band":
			# Hurricane bands become more elongated and asymmetric over time
			evolution["asymmetry"] += randf_range(-0.02, 0.03)
			evolution["elongation"] += randf_range(-0.01, 0.02)
			evolution["rotation"] += randf_range(-0.05, 0.05)
		"convective":
			# Convective storms become more chaotic
			evolution["asymmetry"] += randf_range(-0.03, 0.05)
			evolution["elongation"] += randf_range(-0.02, 0.02)
		"frontal":
			# Frontal systems become more linear
			evolution["elongation"] = move_toward(evolution["elongation"], 1.5, 0.01)
			evolution["asymmetry"] = move_toward(evolution["asymmetry"], 0.1, 0.01)
		"sea_breeze":
			# Sea breeze storms oscillate in shape
			evolution["asymmetry"] = 0.2 + sin(Time.get_unix_time_from_system()) * 0.1
	
	# Clamp values to reasonable ranges
	evolution["asymmetry"] = clamp(evolution["asymmetry"], 0.0, 0.8)
	evolution["elongation"] = clamp(evolution["elongation"], 0.5, 2.0)
	evolution["rotation"] = clamp(evolution["rotation"], -0.3, 0.3)

func _update_hurricane_motion():
	# Hurricane moves with upper-level steering winds
	var steering_wind = atmospheric_layers[2]["wind"] * 0.3
	hurricane_center += steering_wind

func _calculate_wind_at_altitude(pos: Vector2) -> Vector2:
	# Realistic wind shear calculation
	var base_wind = wind_shear
	
	# Add hurricane influence
	if hurricane_intensity > 0.3:
		var hurricane_wind = _calculate_hurricane_wind(pos, hurricane_center) * 0.1
		base_wind += hurricane_wind
	
	# Add terrain effects
	var elevation = _get_terrain_elevation(pos)
	if elevation > 50:
		base_wind *= 0.8  # Reduced wind over hills
	
	return base_wind

func _update_hurricane_cell(cell):
	# Hurricane cells rotate and intensify/weaken
	if cell.has("rotation_rate"):
		var center_dist = cell["center"].distance_to(hurricane_center)
		cell["intensity"] += randf_range(-1.0, 2.0) * hurricane_intensity
		cell["intensity"] = clamp(cell["intensity"], 25, 75)
		
		# Spiral motion
		var angle_to_center = (cell["center"] - hurricane_center).angle()
		angle_to_center += deg_to_rad(cell["rotation_rate"])
		var radius = center_dist
		cell["center"] = hurricane_center + Vector2(cos(angle_to_center), sin(angle_to_center)) * radius

func _update_convective_cell(cell):
	# Convective storms grow rapidly then dissipate
	if cell.has("growth_rate"):
		cell["radius"] += cell["growth_rate"]
		cell["intensity"] += randf_range(-2.0, 3.0)
		cell["intensity"] = clamp(cell["intensity"], 15, 70)
		
		# Mature storms start to weaken
		if cell["radius"] > 40:
			cell["growth_rate"] *= 0.95
			cell["intensity"] *= 0.98

func _update_sea_breeze_cell(cell):
	# Sea breeze storms tend to merge and move inland
	cell["intensity"] += randf_range(-1.0, 1.5)
	cell["intensity"] = clamp(cell["intensity"], 20, 55)
	
	# Slight inland drift
	cell["drift"].x = max(cell["drift"].x, 0.1)

func _update_frontal_cell(cell):
	# Frontal precipitation moves steadily and weakens gradually
	cell["intensity"] *= 0.999  # Slow weakening
	cell["intensity"] = clamp(cell["intensity"], 10, 50)

func _check_storm_merger(index):
	var cell1 = storm_cells[index]
	for i in range(storm_cells.size()):
		if i == index:
			continue
		var cell2 = storm_cells[i]
		var distance = cell1["center"].distance_to(cell2["center"])
		
		# Merger condition
		if distance < (cell1["radius"] + cell2["radius"]) * 0.7:
			if cell1["type"] == cell2["type"] or randf() < 0.3:
				# Merge storms
				var combined_intensity = (cell1["intensity"] + cell2["intensity"]) * 0.6
				var combined_radius = sqrt(pow(cell1["radius"], 2) + pow(cell2["radius"], 2))
				var new_center = (cell1["center"] + cell2["center"]) * 0.5
				
				cell1["center"] = new_center
				cell1["radius"] = combined_radius
				cell1["intensity"] = combined_intensity
				
				storm_cells.remove_at(i)
				break

func _wrap_storm_position(cell):
	# More realistic edge behavior
	var viewport = get_viewport_rect().size
	if cell["center"].x < -100:
		cell["center"].x = viewport.x + 100
	elif cell["center"].x > viewport.x + 100:
		cell["center"].x = -100
	if cell["center"].y < -100:
		cell["center"].y = viewport.y + 100
	elif cell["center"].y > viewport.y + 100:
		cell["center"].y = -100


func _draw():
	# Draw the beautiful San Jii Metropolitan Area map as background
	if island_map_texture:
		var viewport_size = get_viewport_rect().size
		# Scale the map to fit the viewport while maintaining aspect ratio
		var map_size = island_map_texture.get_size()
		var scale_factor = min(viewport_size.x / map_size.x, viewport_size.y / map_size.y)
		var scaled_size = map_size * scale_factor
		var offset = (viewport_size - scaled_size) * 0.5
		
		# Draw the map centered and scaled
		draw_texture_rect(island_map_texture, Rect2(offset, scaled_size), false)
	else:
		# Fallback dark background
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.05, 0.05, 0.1))
	
	# Draw realistic precipitation shapes over the map
	_draw_realistic_precipitation()
	
	# Draw atmospheric features (wind patterns, etc.)
	_draw_atmospheric_features()
	
	# Draw enhanced radar interface
	_draw_enhanced_radar_interface()

func _draw_realistic_precipitation():
	# Draw ultra-realistic precipitation polygons with advanced rendering
	for polygon in precipitation_polygons:
		var base_color = _enhanced_reflectivity_color(polygon["intensity"], polygon["type"])
		if base_color.a > 0:
			# Draw main precipitation shape with gradient effect
			_draw_precipitation_with_gradient(polygon["points"], base_color, polygon["intensity"])
			
			# Draw subcells (embedded cores) if they exist
			if polygon.has("subcells"):
				for subcel in polygon["subcells"]:
					var core_color = _enhanced_reflectivity_color(subcel["intensity"], subcel["type"])
					core_color.a = min(core_color.a + 0.3, 1.0)
					_draw_precipitation_with_gradient(subcel["points"], core_color, subcel["intensity"])
			
			# Add realistic precipitation texture
			_draw_precipitation_texture(polygon["points"], polygon["intensity"], polygon["type"])
			
			# Add storm-specific visual effects
			_draw_storm_effects(polygon)

func _draw_precipitation_with_gradient(points: PackedVector2Array, base_color: Color, _intensity: float):
	if points.size() < 3:
		return
		
	# Draw the main filled polygon
	draw_colored_polygon(points, base_color)
	
	# Add gradient rings for depth effect
	var center = _get_polygon_center(points)
	
	# Create concentric gradient rings
	for ring in range(3):
		var ring_factor = 1.0 - (float(ring) / 3.0) * 0.7
		var ring_points = PackedVector2Array()
		
		for point in points:
			var direction = (point - center).normalized()
			var distance = point.distance_to(center)
			var new_point = center + direction * (distance * ring_factor)
			ring_points.append(new_point)
		
		if ring_points.size() >= 3:
			var ring_color = base_color
			ring_color.a *= (0.3 + ring * 0.2)  # Inner rings more intense
			if ring == 0:  # Innermost ring
				ring_color.r = min(ring_color.r + 0.1, 1.0)
				ring_color.g = min(ring_color.g + 0.1, 1.0)
				ring_color.b = min(ring_color.b + 0.1, 1.0)
			draw_colored_polygon(ring_points, ring_color)

func _draw_precipitation_texture(points: PackedVector2Array, intensity: float, storm_type: String):
	# Add realistic precipitation texture using small shapes
	var center = _get_polygon_center(points)
	var avg_radius = _get_average_radius(points, center)
	
	# Number of texture elements based on intensity
	var num_elements = int(intensity * 0.5 + randf_range(5, 15))
	
	for i in range(num_elements):
		var random_pos = _get_random_point_in_polygon(points, center, avg_radius)
		if random_pos != Vector2.ZERO:
			var element_size = randf_range(1, 3)
			var element_color = Color.WHITE
			element_color.a = randf_range(0.1, 0.3)
			
			# Different texture patterns for different storm types
			match storm_type:
				"hurricane_band":
					# Spiral texture elements
					var spiral_angle = random_pos.angle_to(center) + randf_range(-0.5, 0.5)
					var spiral_offset = Vector2(cos(spiral_angle), sin(spiral_angle)) * 2
					draw_line(random_pos, random_pos + spiral_offset, element_color, element_size)
				"convective":
					# Chaotic dot pattern
					draw_circle(random_pos, element_size, element_color)
				"frontal":
					# Linear streaks
					var streak_angle = randf() * TAU
					var streak_length = randf_range(3, 8)
					var streak_end = random_pos + Vector2(cos(streak_angle), sin(streak_angle)) * streak_length
					draw_line(random_pos, streak_end, element_color, 1)
				_:
					# Default dots
					draw_circle(random_pos, element_size * 0.5, element_color)

func _draw_storm_effects(polygon_data):
	var points = polygon_data["points"]
	var intensity = polygon_data["intensity"]
	var storm_type = polygon_data["type"]
	var center = _get_polygon_center(points)
	
	# Lightning effects for intense storms
	if intensity > 55 and storm_type in ["convective", "hurricane_band"]:
		if randf() < 0.1:  # 10% chance per frame
			_draw_lightning_flash(center, _get_average_radius(points, center))
	
	# Rotation indicators for hurricanes
	if storm_type == "hurricane_band" and intensity > 40:
		_draw_rotation_indicator(center, _get_average_radius(points, center) * 0.3)
	
	# Wind shear visualization
	if storm_type == "convective" and intensity > 50:
		_draw_wind_shear_effect(center, wind_shear)

func _draw_lightning_flash(center: Vector2, radius: float):
	# Draw realistic lightning bolt
	var lightning_color = Color(1.0, 1.0, 0.8, 0.9)
	var num_segments = randi_range(3, 6)
	var current_pos = center
	
	for i in range(num_segments):
		var angle = randf() * TAU
		var length = randf_range(radius * 0.3, radius * 0.8)
		var next_pos = current_pos + Vector2(cos(angle), sin(angle)) * length
		
		# Main bolt
		draw_line(current_pos, next_pos, lightning_color, 3)
		# Glow effect
		draw_line(current_pos, next_pos, Color(lightning_color.r, lightning_color.g, lightning_color.b, 0.3), 6)
		
		current_pos = next_pos

func _draw_rotation_indicator(center: Vector2, radius: float):
	# Draw rotation arrows for hurricane bands
	var rotation_color = Color(1.0, 1.0, 1.0, 0.4)
	for i in range(4):
		var angle = (float(i) / 4.0) * TAU + Time.get_unix_time_from_system() * 0.5
		var start_pos = center + Vector2(cos(angle), sin(angle)) * radius
		var end_angle = angle + PI * 0.3
		var end_pos = center + Vector2(cos(end_angle), sin(end_angle)) * radius * 1.1
		
		draw_line(start_pos, end_pos, rotation_color, 2)
		# Arrow head
		var arrow_angle = end_angle + PI + 0.3
		var arrow_point = end_pos + Vector2(cos(arrow_angle), sin(arrow_angle)) * 5
		draw_line(end_pos, arrow_point, rotation_color, 2)

func _draw_wind_shear_effect(center: Vector2, shear: Vector2):
	# Draw wind shear streaks
	var shear_color = Color(0.8, 0.8, 1.0, 0.3)
	var shear_dir = shear.normalized()
	
	for i in range(3):
		var offset = Vector2(-shear_dir.y, shear_dir.x) * (i - 1) * 15
		var start_pos = center + offset - shear_dir * 20
		var end_pos = center + offset + shear_dir * 20
		draw_line(start_pos, end_pos, shear_color, 1)

func _get_average_radius(points: PackedVector2Array, center: Vector2) -> float:
	var total_distance = 0.0
	for point in points:
		total_distance += point.distance_to(center)
	return total_distance / points.size()

func _get_random_point_in_polygon(_points: PackedVector2Array, center: Vector2, avg_radius: float) -> Vector2:
	# Simple method: generate random point within average radius and check if inside polygon
	for attempt in range(10):  # Max 10 attempts
		var angle = randf() * TAU
		var distance = randf() * avg_radius * 0.8
		var test_point = center + Vector2(cos(angle), sin(angle)) * distance
		
		# Simple point-in-polygon test (ray casting would be more accurate)
		if test_point.distance_to(center) < avg_radius:
			return test_point
	
	return Vector2.ZERO  # Fallback if no valid point found

func _get_polygon_center(points: PackedVector2Array) -> Vector2:
	var center = Vector2.ZERO
	for point in points:
		center += point
	return center / points.size()

func _draw_realistic_geography():
	# Geographic features are now handled by the IslandMap.png background
	# This function is disabled to use the beautiful custom San Jii Metro map instead
	pass

func _draw_detailed_coastline():
	var coast_color = Color(0.6, 0.4, 0.2, 0.9)
	
	# Dragon Peninsula eastern coastline (Bahía Azul)
	var eastern_coast = PackedVector2Array([
		Vector2(520, 120), Vector2(540, 140), Vector2(560, 170), Vector2(580, 200),
		Vector2(600, 240), Vector2(615, 280), Vector2(630, 320), Vector2(640, 360),
		Vector2(650, 400), Vector2(655, 440), Vector2(660, 480), Vector2(650, 520),
		Vector2(640, 550), Vector2(620, 575), Vector2(590, 590), Vector2(560, 595),
		Vector2(530, 585), Vector2(500, 570)
	])
	
	# Western coastline (facing the Emerald Sea)
	var western_coast = PackedVector2Array([
		Vector2(280, 280), Vector2(320, 295), Vector2(360, 310), Vector2(400, 325),
		Vector2(440, 340), Vector2(480, 355), Vector2(520, 375), Vector2(550, 400),
		Vector2(575, 430), Vector2(590, 465), Vector2(600, 500), Vector2(595, 535),
		Vector2(585, 565), Vector2(570, 585), Vector2(550, 595), Vector2(520, 590)
	])
	
	# Draw detailed coastlines
	_draw_polyline_smooth(eastern_coast, coast_color, 3)
	_draw_polyline_smooth(western_coast, coast_color, 3)
	
	# Add small islands (Isla Fenghuang and others)
	var islands = [
		PackedVector2Array([Vector2(660, 350), Vector2(680, 360), Vector2(675, 380), Vector2(655, 375)]),
		PackedVector2Array([Vector2(665, 420), Vector2(685, 430), Vector2(680, 450), Vector2(660, 445)])
	]
	
	for island in islands:
		_draw_polyline_smooth(island, coast_color, 2)

func _draw_polyline_smooth(points: PackedVector2Array, color: Color, width: float):
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width)

func _draw_county_boundaries():
	var boundary_color = Color(0.3, 0.3, 0.3, 0.4)
	
	# More realistic county grid
	for x in range(250, 700, 60):
		draw_line(Vector2(x, 150), Vector2(x, 550), boundary_color, 1)
	
	for y in range(180, 580, 50):
		draw_line(Vector2(250, y), Vector2(680, y), boundary_color, 1)

func _draw_major_roads():
	var road_color = Color(0.4, 0.4, 0.4, 0.6)
	
	# I-95 (Atlantic coast)
	var i95 = PackedVector2Array([
		Vector2(620, 150), Vector2(630, 200), Vector2(635, 250), Vector2(640, 300),
		Vector2(645, 350), Vector2(650, 400), Vector2(645, 450), Vector2(640, 500)
	])
	_draw_polyline_smooth(i95, road_color, 2)
	
	# I-75 (Central Florida)
	var i75 = PackedVector2Array([
		Vector2(450, 150), Vector2(470, 200), Vector2(490, 250), Vector2(510, 300),
		Vector2(520, 350), Vector2(525, 400), Vector2(530, 450), Vector2(535, 500)
	])
	_draw_polyline_smooth(i75, road_color, 2)

func _draw_water_bodies():
	var water_color = Color(0.2, 0.4, 0.7, 0.5)
	
	# Lago Feng (Wind Lake) - crater lake
	var lake_center = Vector2(480, 320)
	var lake_points = PackedVector2Array()
	for i in range(12):
		var angle = (float(i) / 12.0) * TAU
		var radius = 20 + sin(angle * 3) * 6
		lake_points.append(lake_center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(lake_points, water_color)

func _draw_terrain_contours():
	# Terrain contours are now part of the IslandMap.png background
	# This function is disabled to use the beautiful custom map instead
	pass

func _draw_atmospheric_features():
	# Draw subtle wind barbs at major cities (positions only)
	for city in sanjii_cities:
		if city["population"] > 500000:  # Only major cities (CIUDADLONG and PUERTOSHAN)
			_draw_wind_barb(city["pos"], wind_shear * 10)
	
	# Draw pressure center
	if hurricane_intensity > 0.4:
		draw_circle(hurricane_center, 15, Color(1.0, 0.3, 0.3, 0.7))
		var font = get_theme_default_font()
		if font == null:
			font = ThemeDB.fallback_font
		if font != null:
			draw_string(font, hurricane_center + Vector2(-10, -20), "L", 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_wind_barb(pos: Vector2, wind: Vector2):
	var wind_color = Color(0.8, 0.8, 0.8, 0.8)
	var wind_length = wind.length() * 2
	var wind_dir = wind.normalized()
	
	# Main wind line
	draw_line(pos, pos + wind_dir * wind_length, wind_color, 2)
	
	# Wind barbs (every 10 knots)
	var knots = int(wind_length / 4)
	for i in range(min(knots / 10.0, 5)):
		var barb_pos = pos + wind_dir * wind_length * 0.8 - wind_dir * i * 8
		var perpendicular = Vector2(-wind_dir.y, wind_dir.x)
		draw_line(barb_pos, barb_pos + perpendicular * 8, wind_color, 2)

func _enhanced_reflectivity_color(dbz: float, storm_type: String) -> Color:
	var base_color: Color
	
	# More realistic color mapping
	if dbz < 5:
		return Color.TRANSPARENT
	elif dbz < 15:
		base_color = Color(0.4, 0.8, 0.4, 0.4)  # Very light green
	elif dbz < 25:
		base_color = Color(0.2, 0.9, 0.2, 0.6)  # Light green
	elif dbz < 35:
		base_color = Color(0.0, 0.8, 0.0, 0.7)  # Green
	elif dbz < 45:
		base_color = Color(0.8, 0.8, 0.0, 0.8)  # Yellow
	elif dbz < 55:
		base_color = Color(1.0, 0.6, 0.0, 0.85) # Orange
	elif dbz < 65:
		base_color = Color(1.0, 0.2, 0.0, 0.9)  # Red
	elif dbz < 75:
		base_color = Color(0.8, 0.0, 0.8, 0.95) # Magenta
	else:
		base_color = Color(1.0, 1.0, 1.0, 1.0)  # White (extreme)
	
	# Modify color based on storm type
	match storm_type:
		"hurricane_band":
			base_color.a = min(base_color.a + 0.2, 1.0)  # More intense
		"convective":
			base_color.r = min(base_color.r + 0.1, 1.0)  # Slightly redder
		"frontal":
			base_color.b = min(base_color.b + 0.1, 1.0)  # Slightly bluer
	
	return base_color

func _draw_enhanced_radar_interface():
	# Professional radar interface
	var interface_color = Color(0.1, 0.1, 0.2, 0.95)
	var header_height = 50
	var footer_height = 60
	
	# Header
	draw_rect(Rect2(0, 0, get_viewport_rect().size.x, header_height), interface_color)
	
	# Footer
	draw_rect(Rect2(0, get_viewport_rect().size.y - footer_height, get_viewport_rect().size.x, footer_height), interface_color)
	
	var font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	
	if font != null:
		# Header text
		draw_string(font, Vector2(20, 25), 
			"NEXRAD DOPPLER RADAR - SAN JII METRO HURRICANE WATCH", 
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_string(font, Vector2(get_viewport_rect().size.x - 200, 25), 
			Time.get_datetime_string_from_system(), 
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.CYAN)
		
		# Footer information
		var footer_y = get_viewport_rect().size.y - 35
		draw_string(font, Vector2(20, footer_y), 
			"Hurricane Intensity: " + str(int(hurricane_intensity * 100)) + "%", 
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
		draw_string(font, Vector2(250, footer_y), 
			"Storm Cells: " + str(storm_cells.size()), 
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		draw_string(font, Vector2(400, footer_y), 
			"Wind Shear: " + str(int(wind_shear.length() * 10)) + " kt", 
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		
		# Range rings
		var center = get_viewport_rect().size * 0.5
		for range_km in [50, 100, 150, 200]:
			var radius = range_km * 1.5  # Scale factor
			draw_arc(center, radius, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.5), 1)
			draw_string(font, center + Vector2(radius * 0.7, -10), 
				str(range_km) + "km", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
