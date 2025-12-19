extends Node
class_name CelestialGenerator

## Generates moons and planetary rings for the solar system
## This script can be attached to the main scene or called statically

# Path to the JSON data file
const DATA_FILE_PATH = "res://solarity/celestial_data.json"

# Data loaded from JSON file
static var MOON_DATA: Dictionary = {}
static var RING_DATA: Dictionary = {}
static var data_loaded: bool = false

## Load celestial data from JSON file
static func load_celestial_data() -> bool:
	if data_loaded:
		return true

	var file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load celestial data from: " + DATA_FILE_PATH)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return false

	var data = json.data
	if not data is Dictionary:
		push_error("Invalid JSON structure: root is not a dictionary")
		return false

	# Load moon data
	if data.has("moons"):
		MOON_DATA = data["moons"]
	else:
		push_error("JSON missing 'moons' key")
		return false

	# Load ring data and convert color dictionaries to Color objects
	if data.has("rings"):
		var rings_raw = data["rings"]
		for planet_name in rings_raw:
			var ring_info = rings_raw[planet_name].duplicate(true)

			# Convert color dictionaries to Color objects
			if ring_info.has("colors"):
				var colors_array = []
				for color_dict in ring_info["colors"]:
					var color = Color(
						color_dict.get("r", 1.0),
						color_dict.get("g", 1.0),
						color_dict.get("b", 1.0),
						color_dict.get("a", 1.0)
					)
					colors_array.append(color)
				ring_info["colors"] = colors_array

			RING_DATA[planet_name] = ring_info
	else:
		push_error("JSON missing 'rings' key")
		return false

	data_loaded = true
	print("Celestial data loaded successfully from JSON")
	return true

## Generate moons for a planet
static func generate_moons(planet: Node3D) -> void:
	# Ensure data is loaded
	if not load_celestial_data():
		push_error("Failed to load celestial data")
		return

	if not planet:
		push_error("Planet node is null")
		return

	var planet_name = ""

	# Try to get planet name from Planet script
	if planet.has_method("get") and planet.get("planet_name"):
		planet_name = planet.get("planet_name")
	else:
		planet_name = planet.name

	if not MOON_DATA.has(planet_name):
		print("No moon data for planet: ", planet_name)
		return

	var moon_list = MOON_DATA[planet_name]
	if moon_list.is_empty():
		print(planet_name, " has no moons to generate")
		return

	print("Generating ", moon_list.size(), " moons for ", planet_name)

	# Create a container for moons
	var moons_container = Node3D.new()
	moons_container.name = "Moons"
	planet.add_child(moons_container)

	# Set owner only if tree exists
	if planet.get_tree():
		if Engine.is_editor_hint():
			moons_container.owner = planet.get_tree().edited_scene_root
		else:
			moons_container.owner = planet.owner

	for moon_data in moon_list:
		var moon = create_moon(moon_data, planet)
		if moon:
			moons_container.add_child(moon)

			# Set owner only if tree exists
			if planet.get_tree():
				if Engine.is_editor_hint():
					moon.owner = planet.get_tree().edited_scene_root
				else:
					moon.owner = planet.owner

## Create a single moon using the Planet base scene
static func create_moon(moon_data: Dictionary, parent_planet: Node3D) -> Planet:
	# Load the planet base scene
	var planet_scene = load("res://solarity/planet_base.tscn")
	if not planet_scene:
		push_error("Failed to load planet_base.tscn")
		return null

	var moon: Planet = planet_scene.instantiate()
	if not moon:
		push_error("Failed to instantiate planet scene")
		return null

	# Configure moon properties using Planet class
	moon.name = moon_data["name"]
	moon.planet_name = moon_data["name"]
	moon.planet_radius = moon_data["size"]

	# Set orbital parameters (Planet class handles the orbit)
	moon.orbital_center = parent_planet
	moon.orbital_radius = moon_data["distance"]
	moon.orbital_speed = moon_data["speed"]

	# Randomize starting orbital angle
	moon.orbital_angle = randf() * TAU

	# Moon appearance - simple gray rocky surface
	moon.use_procedural_surface = true
	moon.surface_type = Planet.SurfaceType.DESERT  # Rocky/cratered look
	moon.noise_seed = randi()
	moon.noise_scale = 3.0

	# Set moon colors (various shades of gray)
	var moon_color = get_moon_color()
	moon.land_color = moon_color.lightened(0.1)
	moon.water_color = moon_color.darkened(0.2)
	moon.land_threshold = 0.4

	# Moons typically don't have atmospheres or clouds
	moon.has_atmosphere = false
	moon.has_clouds = false
	moon.has_rings = false

	# Slower rotation for moons
	moon.rotation_speed = randf_range(0.5, 2.0)
	moon.axial_tilt = randf_range(-5, 5)

	return moon

## Get a varied gray color for moons
static func get_moon_color() -> Color:
	var brightness = randf_range(0.3, 0.6)
	var variation = randf_range(-0.05, 0.05)
	return Color(
		brightness + variation,
		brightness + variation * 0.5,
		brightness - variation * 0.5
	)

## Generate rings for a planet
static func generate_rings(planet: Node3D) -> void:
	# Ensure data is loaded
	if not load_celestial_data():
		push_error("Failed to load celestial data")
		return

	if not planet:
		push_error("Planet node is null")
		return

	var planet_name = ""

	# Try to get planet name from Planet script
	if planet.has_method("get") and planet.get("planet_name"):
		planet_name = planet.get("planet_name")
	else:
		planet_name = planet.name

	if not RING_DATA.has(planet_name):
		print("No ring data for planet: ", planet_name)
		return

	var ring_data = RING_DATA[planet_name]
	print("Generating rings for ", planet_name)

	# Create ring container
	var rings_container = Node3D.new()
	rings_container.name = "Rings"
	planet.add_child(rings_container)

	# Set owner only if tree exists
	if planet.get_tree():
		if Engine.is_editor_hint():
			rings_container.owner = planet.get_tree().edited_scene_root
		else:
			rings_container.owner = planet.owner

	# Rotate to be perpendicular to planet (horizontal)
	rings_container.rotation_degrees.x = 90

	# Get planet tilt if available
	if planet.has_method("get") and planet.get("axial_tilt") != null:
		var tilt = planet.get("axial_tilt")
		rings_container.rotation_degrees.z = tilt

	# Create multiple ring segments
	var segment_count = ring_data["segments"]
	var inner_radius = ring_data["inner_radius"]
	var outer_radius = ring_data["outer_radius"]
	var colors = ring_data["colors"]

	var radius_step = (outer_radius - inner_radius) / float(segment_count)

	for i in range(segment_count):
		var segment_inner = inner_radius + (i * radius_step)
		var segment_outer = inner_radius + ((i + 1) * radius_step)

		# Add small gaps between rings
		if i > 0:
			segment_inner += 1.0
		if i < segment_count - 1:
			segment_outer -= 1.0

		var ring = create_ring_segment(
			segment_inner,
			segment_outer,
			colors[i % colors.size()],
			planet_name + "_Ring_" + str(i)
		)

		rings_container.add_child(ring)

		# Set owner only if tree exists
		if planet.get_tree():
			if Engine.is_editor_hint():
				ring.owner = planet.get_tree().edited_scene_root
			else:
				ring.owner = planet.owner

## Create a single ring segment
static func create_ring_segment(inner_radius: float, outer_radius: float, color: Color, ring_name: String) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = ring_name

	# Create ring mesh using ArrayMesh
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var segments = 128  # Higher for smoother rings
	var angle_step = TAU / segments

	# Create vertices
	for i in range(segments + 1):
		var angle = i * angle_step
		var cos_a = cos(angle)
		var sin_a = sin(angle)

		# Inner vertex
		vertices.append(Vector3(cos_a * inner_radius, sin_a * inner_radius, 0))
		uvs.append(Vector2(float(i) / segments, 0))
		normals.append(Vector3(0, 0, 1))

		# Outer vertex
		vertices.append(Vector3(cos_a * outer_radius, sin_a * outer_radius, 0))
		uvs.append(Vector2(float(i) / segments, 1))
		normals.append(Vector3(0, 0, 1))

	# Create indices
	for i in range(segments):
		var base = i * 2

		# Triangle 1
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 1)

		# Triangle 2
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 3)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Render both sides
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Self-luminous
	material.roughness = 0.8

	mesh_instance.material_override = material

	return mesh_instance

## Generate all moons and rings for the entire solar system
static func generate_all(root_node: Node) -> void:
	if not root_node:
		push_error("Root node is null")
		return

	print("=== Starting Solar System Generation ===")

	# Find all planets in the scene
	var planets = find_all_planets(root_node)

	print("Found ", planets.size(), " planets")

	for planet in planets:
		generate_moons(planet)
		generate_rings(planet)

	print("=== Generation Complete ===")

## Recursively find all planet nodes
static func find_all_planets(node: Node) -> Array[Node3D]:
	var planets: Array[Node3D] = []

	# Check if this node is a planet
	if node is Node3D:
		# Check if it has the Planet script or planet_name property
		if node.has_method("get") and node.get("planet_name") != null:
			planets.append(node)
		elif node.name in MOON_DATA or node.name in RING_DATA:
			planets.append(node)

	# Recursively check children
	for child in node.get_children():
		planets.append_array(find_all_planets(child))

	return planets
