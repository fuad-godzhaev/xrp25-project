## TODO: rings, gravity, split the code in to smaller files?
## I didn't expect it to grow this big...
@tool

class_name Planet
extends Node3D

# Enum for surface types (must be before exports)
enum SurfaceType {
	EARTH_LIKE,      # Continents and oceans
	LAVA,            # Hot lava patterns
	ICE,             # Ice caps and frozen surface
	DESERT,          # Sandy/rocky patterns
	GAS_BANDS,       # Jupiter-like bands
	RANDOM_ABSTRACT  # Random colorful patterns
}

## Planet properties that can be customized per planet
@export_group("Planet Properties")
@export var _play_in_editor: bool = true:
	set(value):
		_play_in_editor = value
		
@export var planet_name: String = "Planet":
	set(value):
		planet_name = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var planet_radius: float = 1.0:
	set(value):
		planet_radius = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var has_atmosphere: bool = true:
	set(value):
		has_atmosphere = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var has_clouds: bool = false:
	set(value):
		has_clouds = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var has_rings: bool = false:
	set(value):
		has_rings = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Rotation")
@export var rotation_speed: float = 1.0  # degrees per second
@export var rotation_axis: Vector3 = Vector3.UP

@export var axial_tilt: float = 0.0:  # degrees
	set(value):
		axial_tilt = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Orbit")
@export var orbital_radius: float = 10.0
@export var orbital_speed: float = 10.0  # degrees per second
@export var orbital_center: Node3D = null

@export_group("Appearance")
@export var surface_texture: Texture2D:
	set(value):
		surface_texture = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var normal_map: Texture2D:
	set(value):
		normal_map = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var surface_color: Color = Color.WHITE:
	set(value):
		surface_color = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Procedural Surface")
@export var use_procedural_surface: bool = false:
	set(value):
		use_procedural_surface = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var surface_type: SurfaceType = SurfaceType.EARTH_LIKE:
	set(value):
		surface_type = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var land_color: Color = Color(0.2, 0.5, 0.1):  # Green continents
	set(value):
		land_color = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var water_color: Color = Color(0.1, 0.3, 0.6):  # Blue oceans
	set(value):
		water_color = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var noise_scale: float = 5.0:  # Controls continent size
	set(value):
		noise_scale = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var noise_seed: int = 0:  # Change for different patterns
	set(value):
		noise_seed = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var land_threshold: float = 0.3:  # Higher = less land
	set(value):
		land_threshold = clamp(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Atmosphere Settings")
@export var atmosphere_color: Color = Color(0.5, 0.7, 1.0):
	set(value):
		atmosphere_color = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var atmosphere_intensity: float = 1.0:
	set(value):
		atmosphere_intensity = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var atmosphere_thickness: float = 0.1:  # relative to radius
	set(value):
		atmosphere_thickness = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Cloud Settings")
@export var cloud_texture: Texture2D:
	set(value):
		cloud_texture = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var cloud_texture_scale: Vector2 = Vector2(1.0, 1.0):
	set(value):
		cloud_texture_scale = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var auto_scale_cloud_texture: bool = true

@export var cloud_speed: float = 0.5

@export var cloud_height: float = 0.05:
	set(value):
		cloud_height = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var cloud_opacity: float = 0.5:
	set(value):
		cloud_opacity = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export_group("Physics")
@export var has_gravity: bool = false
@export var gravity_strength: float = 9.8
@export var gravity_range: float = 10.0

@export_group("Player Interaction")
@export var pause_on_player_nearby: bool = true
@export var pause_distance: float = 200.0  # Distance from player to pause planet movement

@export_group("Celestial Generation")
@export var auto_generate_moons: bool = false:
	set(value):
		auto_generate_moons = value
		if value and Engine.is_editor_hint():
			generate_moons()

@export var auto_generate_rings: bool = false:
	set(value):
		auto_generate_rings = value
		if value and Engine.is_editor_hint():
			generate_rings()

# Internal references
var body: MeshInstance3D
var atmosphere: MeshInstance3D
var clouds: MeshInstance3D
var rings: MeshInstance3D
var rotation_pivot: Node3D

var orbital_angle: float = 0.0
var _editor_initialized: bool = false
var _is_paused: bool = false
var _xr_camera: XRCamera3D = null

# Editor initialization and update functions
func _ready():
	if Engine.is_editor_hint():
		_initialize_editor_nodes()
		_setup_planet()
	else:
		# Runtime initialization
		_get_node_references()
		_setup_planet()

func _initialize_editor_nodes():
	# Create or get child nodes for the planet structure
	body = _get_or_create_child("PlanetBody", MeshInstance3D)
	atmosphere = _get_or_create_child("Atmosphere", MeshInstance3D)
	clouds = _get_or_create_child("Clouds", MeshInstance3D)
	rings = _get_or_create_child("Rings", MeshInstance3D)
	rotation_pivot = _get_or_create_child("RotationPivot", Node3D)

	# Make sure planet body is a child of rotation pivot
	if body and rotation_pivot:
		if body.get_parent() != rotation_pivot:
			if body.get_parent():
				body.get_parent().remove_child(body)
			rotation_pivot.add_child(body)
			body.owner = get_tree().edited_scene_root

	_editor_initialized = true

func _get_or_create_child(node_name: String, node_type) -> Node:
	var node = get_node_or_null(node_name)
	if not node:
		# Check if it's under RotationPivot
		var pivot = get_node_or_null("RotationPivot")
		if pivot:
			node = pivot.get_node_or_null(node_name)

	if not node:
		node = node_type.new()
		node.name = node_name
		add_child(node)
		node.owner = get_tree().edited_scene_root

	return node

func _get_node_references():
	# Runtime node reference gathering
	body = $RotationPivot/PlanetBody if has_node("RotationPivot/PlanetBody") else null
	atmosphere = $Atmosphere if has_node("Atmosphere") else null
	clouds = $Clouds if has_node("Clouds") else null
	rings = $Rings if has_node("Rings") else null
	rotation_pivot = $RotationPivot if has_node("RotationPivot") else null

func _update_planet_in_editor():
	if not _editor_initialized:
		_initialize_editor_nodes()
	_setup_planet()

func _setup_planet():
	if not body or not atmosphere or not clouds or not rings or not rotation_pivot:
		return

	_setup_body()

	atmosphere.visible = has_atmosphere
	if has_atmosphere:
		_setup_atmosphere()

	clouds.visible = has_clouds
	if has_clouds:
		_setup_clouds()

	rings.visible = has_rings
	if has_rings:
		_setup_rings()

	# Apply axial tilt
	rotation_pivot.rotation_degrees = Vector3(axial_tilt, 0, 0)

	# Position in orbit if orbital_center is set
	if is_instance_valid(orbital_center):
		position = Vector3(orbital_radius, 0, 0)


func _setup_body():
	if not body:
		return

	var sphere = SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height = planet_radius * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	body.mesh = sphere

	var material = StandardMaterial3D.new()

	# NEW: Use procedural surface if enabled
	if use_procedural_surface:
		var procedural_texture = _generate_procedural_surface()
		material.albedo_texture = procedural_texture
		material.albedo_color = Color.WHITE  # Let texture define color
	else:
		material.albedo_color = surface_color
		if surface_texture:
			material.albedo_texture = surface_texture

	if normal_map:
		material.normal_enabled = true
		material.normal_texture = normal_map

	body.material_override = material

# NEW: Generate procedural surface texture
func _generate_procedural_surface() -> NoiseTexture2D:
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.01 * noise_scale
	noise.fractal_octaves = 4

	var noise_texture = NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.width = 512
	noise_texture.height = 512

	# Create color gradient based on surface type
	var gradient = Gradient.new()

	match surface_type:
		SurfaceType.EARTH_LIKE:
			# Water to land gradient
			gradient.add_point(0.0, water_color.darkened(0.3))
			gradient.add_point(land_threshold * 0.9, water_color)
			gradient.add_point(land_threshold, land_color.darkened(0.2))
			gradient.add_point(land_threshold + 0.1, land_color)
			gradient.add_point(0.7, land_color.lightened(0.1))
			gradient.add_point(1.0, Color.WHITE)  # Snow caps

		SurfaceType.LAVA:
			gradient.add_point(0.0, Color(0.1, 0.0, 0.0))  # Dark rock
			gradient.add_point(0.3, Color(0.3, 0.1, 0.0))
			gradient.add_point(0.5, Color(0.8, 0.2, 0.0))  # Lava
			gradient.add_point(0.7, Color(1.0, 0.5, 0.0))
			gradient.add_point(1.0, Color(1.0, 0.9, 0.2))  # Bright lava

		SurfaceType.ICE:
			gradient.add_point(0.0, Color(0.7, 0.8, 0.9))  # Ice
			gradient.add_point(0.4, Color(0.85, 0.9, 0.95))
			gradient.add_point(0.7, Color(0.95, 0.97, 1.0))
			gradient.add_point(1.0, Color(1.0, 1.0, 1.0))  # Pure white ice

		SurfaceType.DESERT:
			gradient.add_point(0.0, Color(0.6, 0.4, 0.2))  # Dark sand
			gradient.add_point(0.3, Color(0.8, 0.6, 0.3))
			gradient.add_point(0.6, Color(0.9, 0.7, 0.4))  # Sand
			gradient.add_point(1.0, Color(0.95, 0.85, 0.6))  # Light sand

		SurfaceType.GAS_BANDS:
			# Jupiter-like bands
			noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			gradient.add_point(0.0, Color(0.7, 0.5, 0.3))
			gradient.add_point(0.25, Color(0.9, 0.7, 0.5))
			gradient.add_point(0.5, Color(0.8, 0.6, 0.4))
			gradient.add_point(0.75, Color(0.95, 0.8, 0.6))
			gradient.add_point(1.0, Color(0.85, 0.65, 0.45))

		SurfaceType.RANDOM_ABSTRACT:
			# Random colorful patterns
			gradient.add_point(0.0, Color(randf(), randf(), randf()))
			gradient.add_point(0.25, Color(randf(), randf(), randf()))
			gradient.add_point(0.5, Color(randf(), randf(), randf()))
			gradient.add_point(0.75, Color(randf(), randf(), randf()))
			gradient.add_point(1.0, Color(randf(), randf(), randf()))

	noise_texture.color_ramp = gradient

	return noise_texture


func _setup_atmosphere():
	if not atmosphere:
		return

	var sphere = SphereMesh.new()
	var atmo_radius = planet_radius * (1.0 + atmosphere_thickness)
	sphere.radius = atmo_radius
	sphere.height = atmo_radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	atmosphere.mesh = sphere

	# Create atmosphere shader
	var shader_material = ShaderMaterial.new()
	var atmosphere_shader = load("res://solarity/atmosphere.tres")
	if atmosphere_shader:
		shader_material.shader = atmosphere_shader
		shader_material.set_shader_parameter("atmosphere_color", atmosphere_color)
		shader_material.set_shader_parameter("intensity", atmosphere_intensity)
		atmosphere.material_override = shader_material

func _setup_clouds():
	if not clouds:
		return

	var sphere = SphereMesh.new()
	var cloud_radius = planet_radius * (1.0 + cloud_height)
	sphere.radius = cloud_radius
	sphere.height = cloud_radius * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	clouds.mesh = sphere

	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	if cloud_texture:
		material.albedo_texture = cloud_texture

		var uv_scale = cloud_texture_scale
		if auto_scale_cloud_texture:
			var scale_factor = planet_radius / 1.0
			uv_scale = Vector2(scale_factor, scale_factor)

		material.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)

	material.albedo_color = Color(1, 1, 1, cloud_opacity)

	clouds.material_override = material

func _setup_rings():
	# TODO: Implement rings
	pass

func _process(delta: float) -> void:
	# Don't animate in editor mode
	#if Engine.is_editor_hint():
	#	return

	if not rotation_pivot:
		return

	# Check if we should pause orbital movement based on player proximity
	_check_player_proximity()

	# Rotate around own axis (always happens, even when paused)
	rotation_pivot.rotate(rotation_axis.normalized(), deg_to_rad(rotation_speed * delta))

	# Orbit around center if set (only if not paused)
	if is_instance_valid(orbital_center) and not _is_paused:
		orbital_angle += deg_to_rad(orbital_speed * delta)
		position = orbital_center.position + Vector3(
			cos(orbital_angle) * orbital_radius,
			0,
			sin(orbital_angle) * orbital_radius
		)

	if has_clouds and clouds and clouds.visible:
		clouds.rotate_y(deg_to_rad(cloud_speed * delta))

func _check_player_proximity():
	if not pause_on_player_nearby:
		_is_paused = false
		return

	# Find XR camera if we don't have it yet
	if not _xr_camera:
		_xr_camera = get_viewport().get_camera_3d()
		if not _xr_camera:
			return

	# Check distance from player to planet
	var distance = global_position.distance_to(_xr_camera.global_position)

	# Pause if player is within pause distance
	_is_paused = distance < pause_distance

func _physics_process(delta: float):
	# Don't run physics in editor mode
	#if Engine.is_editor_hint():
	#	return
	if has_gravity:
		_apply_gravity()

func _apply_gravity():
	# Get all bodies in range and apply gravitational force
	var space_state = get_world_3d().direct_space_state
	# TODO: Implement gravity pulling logic here
	pass

## Generate moons for this planet using CelestialGenerator
func generate_moons():
	CelestialGenerator.generate_moons(self)

## Generate rings for this planet using CelestialGenerator
func generate_rings():
	CelestialGenerator.generate_rings(self)

## Clear all generated moons
func clear_moons():
	var moons_container = get_node_or_null("Moons")
	if moons_container:
		remove_child(moons_container)
		moons_container.queue_free()

## Clear all generated rings
func clear_rings():
	var rings_container = get_node_or_null("Rings")
	if rings_container:
		remove_child(rings_container)
		rings_container.queue_free()
