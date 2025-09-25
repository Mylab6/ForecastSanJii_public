class_name OSMMapRendererBackup extends RefCounted

# Dynamic Hex Map Renderer for weather radar simulation
# Generates random island maps with dynamic city placement

static var current_cities: Array = []  # Current game cities

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
	"""Complete workflow: generate dynamic hex map with cities"""
	print("Generating simple game map...")
	return render_fallback_texture(image_size)
