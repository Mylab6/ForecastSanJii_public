class_name OSMMapRenderer extends RefCounted

# Dynamic Hex Map Renderer for weather radar simulation
# Generates random island maps with dynamic city placement

static var current_cities: Array = []  # Current game cities
static var city_positions: Dictionary = {}  # city_name -> Vector2 position

static func generate_cities_on_land(island_centers: Array, image_size: Vector2i, hex_radius: int) -> Array:
	"""Generate cities only on verified land hexes with proper spacing"""
	var cities = []
	var city_names = [
		"Flying Fish Cove",
		"Silver City", 
		"San Ji City",
		"Drumsite",
		"Settlement",
		"The Dales",
		"Phosphate Hill"
	]
	
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system() + 1000  # Different seed from terrain
	
	# First, identify all land hexes
	print("Identifying land hexes for city placement...")
	var land_hexes = get_land_hex_tiles(island_centers, image_size, hex_radius, rng)
	print("Found ", land_hexes.size(), " suitable land hexes for cities")
	
	if land_hexes.is_empty():
		print("WARNING: No land hexes found for city placement!")
		return cities
	
	var placed_positions = []
	var min_distance = hex_radius * 8  # Minimum distance between cities
	
	# Try to place each city on verified land hexes
	for city_name in city_names:
		var attempts = 0
		var max_attempts = 50
		var placed = false
		
		while attempts < max_attempts and not placed and not land_hexes.is_empty():
			attempts += 1
			
			# Pick a random land hex
			var hex_index = rng.randi() % land_hexes.size()
			var land_hex = land_hexes[hex_index]
			var city_pos = land_hex.center
			
			# Check distance from other cities
			var too_close = false
			for existing_pos in placed_positions:
				if city_pos.distance_to(existing_pos) < min_distance:
					too_close = true
					break
			
			if not too_close:
				var city = {
					"name": city_name,
					"position": city_pos,
					"hex_pos": land_hex.hex_pos,
					"population": rng.randi_range(1000, 15000)
				}
				
				cities.append(city)
				placed_positions.append(city_pos)
				city_positions[city_name] = Vector2(city_pos.x / image_size.x, city_pos.y / image_size.y)
				placed = true
				print("Placed city: ", city_name, " at hex ", land_hex.hex_pos, " (", city_pos, ")")
				
				# Remove this hex and nearby hexes from available land hexes
				land_hexes = filter_land_hexes_by_distance(land_hexes, city_pos, min_distance)
			else:
				# Remove this hex since it's too close to existing cities
				land_hexes.remove_at(hex_index)
	
	print("Generated ", cities.size(), " cities on verified land hexes")
	return cities

static func get_land_hex_tiles(island_centers: Array, image_size: Vector2i, hex_radius: int, rng: RandomNumberGenerator) -> Array:
	"""Get a list of all hexes that are suitable land for city placement"""
	var land_hexes = []
	var hex_width = hex_radius * 2
	var hex_height = int(hex_radius * 1.732)
	
	# Calculate hex grid dimensions
	var cols = int(image_size.x / (hex_width * 0.75)) + 2
	var rows = int(image_size.y / hex_height) + 2
	
	# Check each hex to see if it's suitable land
	for row in range(rows):
		for col in range(cols):
			var hex_center = get_hex_center(col, row, hex_radius)
			
			# Skip if hex is outside image bounds with margin
			if hex_center.x < hex_radius * 2 or hex_center.x > image_size.x - hex_radius * 2:
				continue
			if hex_center.y < hex_radius * 2 or hex_center.y > image_size.y - hex_radius * 2:
				continue
			
			# Check if this hex is suitable land for cities
			if is_hex_suitable_for_city(hex_center, island_centers, rng):
				land_hexes.append({
					"center": hex_center,
					"hex_pos": Vector2i(col, row)
				})
	
	return land_hexes

static func is_hex_suitable_for_city(hex_center: Vector2, island_centers: Array, rng: RandomNumberGenerator) -> bool:
	"""Check if a hex position is suitable land for city placement"""
	# Calculate distance to nearest island
	var min_dist_to_land = 999999.0
	for island in island_centers:
		var dist = hex_center.distance_to(island.center)
		var land_influence = dist - island.radius
		min_dist_to_land = min(min_dist_to_land, land_influence)
	
	# Add noise for more natural coastlines (same logic as terrain generation)
	var noise_offset = rng.randf_range(-15, 15)
	min_dist_to_land += noise_offset
	
	# Only allow cities on INLAND land terrain (not beaches, water, mountains, or coast)
	# Be more restrictive - only deep inland areas for cities
	if min_dist_to_land < -40:  # Deep inland areas only
		# Additional check - prefer grassland and forest areas
		var terrain_choice = rng.randf()
		if terrain_choice < 0.7:  # 70% chance for good terrain (grassland/forest)
			return true
	elif min_dist_to_land < -20:  # Moderate inland areas
		return rng.randf() < 0.4  # 40% chance for moderate inland
	
	return false  # Not suitable (water, beach, mountains, too close to shore)

static func filter_land_hexes_by_distance(land_hexes: Array, placed_position: Vector2, min_distance: float) -> Array:
	"""Remove land hexes that are too close to a placed city"""
	var filtered_hexes = []
	for hex_data in land_hexes:
		if hex_data.center.distance_to(placed_position) >= min_distance:
			filtered_hexes.append(hex_data)
	return filtered_hexes

static func pixel_to_hex_grid(pixel_pos: Vector2, hex_radius: int) -> Vector2i:
	"""Convert pixel position to hex grid coordinates"""
	var hex_width = hex_radius * 1.5
	var hex_height = hex_radius * 1.732
	
	var col = int(pixel_pos.x / hex_width)
	var row = int(pixel_pos.y / hex_height)
	
	# Adjust for hex offset pattern
	if col % 2 == 1:
		row = int((pixel_pos.y - hex_radius * 0.866) / hex_height)
	
	return Vector2i(col, row)

static func render_dynamic_map_texture(image_size: Vector2i = Vector2i(512, 512)) -> ImageTexture:
	"""Render a dynamic hex map with current cities"""
	print("Rendering dynamic hex tile map at size: ", image_size)
	
	var image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	
	# Create hex-based island map with dynamic cities
	render_dynamic_hex_map(image, image_size)
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	print("Dynamic hex map texture rendered successfully")
	return texture

static func render_dynamic_hex_map(image: Image, image_size: Vector2i):
	"""Render a hex-based island map with random terrain generation"""
	print("Starting random hex map generation, image size: ", image_size)
	
	# Hex tile settings
	var hex_radius = 12
	var hex_width = hex_radius * 2
	var hex_height = int(hex_radius * 1.732)  # sqrt(3) ≈ 1.732
	
	# Colors for different terrain types
	var water_color = Color(0.1, 0.3, 0.7, 1.0)      # Deep ocean blue
	var shallow_color = Color(0.3, 0.5, 0.8, 1.0)    # Light blue shallow
	var beach_color = Color(0.9, 0.8, 0.6, 1.0)      # Sandy beach
	var land_color = Color(0.4, 0.7, 0.3, 1.0)       # Green grassland
	var forest_color = Color(0.2, 0.5, 0.2, 1.0)     # Dark green forest
	var mountain_color = Color(0.6, 0.5, 0.4, 1.0)   # Brown mountains
	var city_color = Color(0.8, 0.8, 0.8, 1.0)       # Light gray cities
	
	# Fill background with water
	image.fill(water_color)
	print("Filled background with deep water")
	
	# Calculate hex grid dimensions
	var cols = int(image_size.x / (hex_width * 0.75)) + 2
	var rows = int(image_size.y / hex_height) + 2
	print("Grid dimensions: ", cols, "x", rows)
	
	# Generate random seed for this map (changes each game)
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_unix_time_from_system()  # Random seed each game start
	print("Using random seed: ", rng.seed)
	
	# Generate multiple random island centers for archipelago effect
	var island_centers = []
	var num_islands = rng.randi_range(2, 4)  # 2-4 islands
	
	for i in range(num_islands):
		var center = Vector2(
			rng.randf_range(image_size.x * 0.2, image_size.x * 0.8),
			rng.randf_range(image_size.y * 0.2, image_size.y * 0.8)
		)
		var radius = rng.randf_range(50, 120)
		island_centers.append({"center": center, "radius": radius})
		print("Island ", i + 1, " at ", center, " with radius ", radius)
	
	# Generate cities on land hexes
	current_cities = generate_cities_on_land(island_centers, image_size, hex_radius)
	
	# Convert cities to hex positions for rendering
	var city_hexes = {}
	for city in current_cities:
		var hex_key = str(city.hex_pos.x) + "," + str(city.hex_pos.y)
		city_hexes[hex_key] = city
	
	var hexes_drawn = 0
	var city_hexes_drawn = 0
	
	# Draw hex grid with procedural terrain
	for row in range(rows):
		for col in range(cols):
			var hex_center = get_hex_center(col, row, hex_radius)
			
			# Skip if hex is outside image bounds
			if hex_center.x < -hex_radius or hex_center.x > image_size.x + hex_radius:
				continue
			if hex_center.y < -hex_radius or hex_center.y > image_size.y + hex_radius:
				continue
			
			var hex_key = str(col) + "," + str(row)
			var terrain_color: Color
			
			# Check if this hex contains a city first
			if city_hexes.has(hex_key):
				var city = city_hexes[hex_key]
				terrain_color = city_color
				city_hexes_drawn += 1
				print("Drawing city hex at ", col, ",", row, " - ", city.name)
			else:
				# Calculate distance to nearest island
				var min_dist_to_land = 999999.0
				for island in island_centers:
					var dist = hex_center.distance_to(island.center)
					var land_influence = dist - island.radius
					min_dist_to_land = min(min_dist_to_land, land_influence)
				
				# Add noise for more natural coastlines
				var noise_offset = rng.randf_range(-15, 15)
				min_dist_to_land += noise_offset
				
				# Determine terrain based on distance to land
				if min_dist_to_land < -40:
					# Deep inland - varied terrain
					var terrain_choice = rng.randf()
					if terrain_choice < 0.4:
						terrain_color = forest_color  # 40% forest
					elif terrain_choice < 0.7:
						terrain_color = land_color    # 30% grassland
					else:
						terrain_color = mountain_color  # 30% mountains
				elif min_dist_to_land < -20:
					# Inland areas
					terrain_color = land_color if rng.randf() < 0.7 else forest_color
				elif min_dist_to_land < 0:
					# Near coast - mostly land with some variety
					terrain_color = land_color if rng.randf() < 0.8 else beach_color
				elif min_dist_to_land < 15:
					# Beach/coastal areas
					terrain_color = beach_color
				elif min_dist_to_land < 30:
					# Shallow water near shore
					terrain_color = shallow_color
				else:
					# Deep water
					terrain_color = water_color
			
			# Draw the hexagon
			draw_hexagon(image, hex_center, hex_radius, terrain_color)
			hexes_drawn += 1
	
	print("Generated random map with ", hexes_drawn, " hexagons (", city_hexes_drawn, " cities)")

static func get_hex_center(col: int, row: int, radius: int) -> Vector2:
	"""Calculate the center position of a hex tile"""
	var x = col * radius * 1.5
	var y = row * radius * 1.732  # sqrt(3)
	
	# Offset every other column
	if col % 2 == 1:
		y += radius * 0.866  # sqrt(3)/2
	
	return Vector2(x, y)

static func draw_hexagon(image: Image, center: Vector2, radius: int, color: Color):
	"""Draw a filled hexagon at the given center"""
	var points: Array[Vector2] = []
	
	# Calculate hexagon vertices
	for i in range(6):
		var angle = i * PI / 3.0
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Fill the hexagon using scanline algorithm
	var min_y = int(points[0].y)
	var max_y = int(points[0].y)
	
	for point in points:
		min_y = min(min_y, int(point.y))
		max_y = max(max_y, int(point.y))
	
	# Ensure bounds are within image
	min_y = max(0, min_y)
	max_y = min(image.get_height() - 1, max_y)
	
	for y in range(min_y, max_y + 1):
		var intersections: Array[float] = []
		
		# Find intersections with hexagon edges
		for i in range(6):
			var p1 = points[i]
			var p2 = points[(i + 1) % 6]
			
			if (p1.y <= y and p2.y > y) or (p2.y <= y and p1.y > y):
				var x_intersect = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
				intersections.append(x_intersect)
		
		# Sort intersections and fill between pairs
		intersections.sort()
		
		for i in range(0, intersections.size(), 2):
			if i + 1 < intersections.size():
				var x1 = max(0, int(intersections[i]))
				var x2 = min(image.get_width() - 1, int(intersections[i + 1]))
				
				for x in range(x1, x2 + 1):
					image.set_pixel(x, y, color)

static func render_fallback_texture(image_size: Vector2i) -> ImageTexture:
	"""Fallback rendering using simple hex pattern"""
	print("Using fallback hex rendering")
	var image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	
	# Create a simple hex pattern
	image.fill(Color(0.2, 0.4, 0.8))  # Water blue background
	
	# Draw a simple hex island
	var center = Vector2(image_size.x / 2, image_size.y / 2)
	var island_radius = min(image_size.x, image_size.y) / 4
	
	# Draw beach first (larger circle)
	draw_filled_circle(image, center, island_radius + 20, Color(0.9, 0.8, 0.6))  # Sandy beach ring
	# Then draw land on top (smaller circle)
	draw_filled_circle(image, center, island_radius, Color(0.4, 0.6, 0.3))  # Green land
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func draw_filled_circle(image: Image, center: Vector2, radius: int, color: Color):
	"""Draw a filled circle on the image"""
	var x1 = max(0, int(center.x - radius))
	var x2 = min(image.get_width() - 1, int(center.x + radius))
	var y1 = max(0, int(center.y - radius))
	var y2 = min(image.get_height() - 1, int(center.y + radius))
	
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			var dist = Vector2(x - center.x, y - center.y).length()
			if dist <= radius:
				image.set_pixel(x, y, color)

static func generate_game_map(image_size: Vector2i = Vector2i(512, 512)) -> ImageTexture:
	"""Generate a completely new random hex map for each game"""
	print("=== GENERATING NEW RANDOM MAP FOR GAME START ===")
	
	# Generate fresh random map with hex tiles and cities
	return render_dynamic_map_texture(image_size)

static func get_city_positions() -> Dictionary:
	"""Get city positions for the weather system"""
	return city_positions

static func get_cities() -> Array:
	"""Get current cities array"""
	return current_cities
