extends Node3D

## Teleport menu for VR that allows player to teleport to different planets

@export var teleport_distance: float = 100.0
@export var menu_distance_from_player: float = 0.8
@export var menu_vertical_offset: float = -0.1  # Slightly below eye level
@export var follow_camera: bool = true

var xr_camera: XRCamera3D
var planets: Array[Node3D] = []
var button_container: VBoxContainer
var menu_scene: Control
var viewport_screen: XRToolsViewport2DIn3D

func _ready():
	# Find the XR camera
	xr_camera = get_viewport().get_camera_3d()
	if not xr_camera:
		push_error("Could not find XR camera")
		return

	# Find all planets in the scene
	_find_all_planets()

	# Create the UI
	_create_ui()

func _find_all_planets():
	planets.clear()

	# Get the root of the scene tree
	var root = get_tree().root

	# Search from the root to find all planets
	_recursive_find_planets(root)

	print("Found ", planets.size(), " planets for teleport menu")

func _recursive_find_planets(node: Node):
	# Check if this node is a Planet
	if node is Planet:
		var planet_name = node.planet_name if node.planet_name != "" else node.name
		# Skip very small objects (likely moons)
		if node.planet_radius > 1.0 and planet_name != "Moon":
			planets.append(node)
			print("Added planet to menu: ", planet_name)

	# Recursively check children
	for child in node.get_children():
		_recursive_find_planets(child)

func _create_ui():
	print("Creating teleport menu UI...")

	# Create the 2D UI scene
	menu_scene = _create_menu_panel()

	# Load and instantiate the XRToolsViewport2DIn3D scene
	var viewport_scene = load("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
	if not viewport_scene:
		push_error("Failed to load viewport_2d_in_3d.tscn")
		return

	viewport_screen = viewport_scene.instantiate()
	viewport_screen.screen_size = Vector2(0.5, 0.7)  # Physical size in 3D
	viewport_screen.viewport_size = Vector2(400, 600)  # Resolution
	viewport_screen.transparent = XRToolsViewport2DIn3D.TransparancyMode.TRANSPARENT
	viewport_screen.unshaded = true
	viewport_screen.collision_layer = 0x00500000  # Layers 21 (pointable) and 23 (ui-objects)
	add_child(viewport_screen)

	# Wait for viewport to be ready, then add our UI scene
	await get_tree().process_frame
	var viewport = viewport_screen.get_node_or_null("Viewport")
	if viewport:
		viewport.add_child(menu_scene)
		print("Menu UI added to viewport")
	else:
		push_error("Could not find Viewport in XRToolsViewport2DIn3D")

func _create_menu_panel() -> Control:
	# Create the UI panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 600)

	# Style the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_color = Color(0.3, 0.5, 0.8, 1.0)
	panel.add_theme_stylebox_override("panel", style_box)

	# Create main container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size = Vector2(400, 600)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PLANET TELEPORTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(title)

	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scroll container for planet buttons
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	vbox.add_child(scroll)

	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 8)
	scroll.add_child(button_container)

	# Create buttons for each planet
	for planet in planets:
		_create_planet_button(planet)

	return panel

func _create_planet_button(planet: Node3D):
	var button = Button.new()
	var planet_name = planet.planet_name if planet.planet_name != "" else planet.name
	button.text = planet_name
	button.custom_minimum_size = Vector2(0, 50)

	# Style the button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.3, 0.5, 0.8)
#	style_normal.corner_radius_all = 8
	button.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.5, 0.7, 0.9)
#	style_hover.corner_radius_all = 8
	button.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.4, 0.6, 0.8, 1.0)
#	style_pressed.corner_radius_all = 8
	button.add_theme_stylebox_override("pressed", style_pressed)

	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(1, 1, 1))

	# Connect button press
	button.pressed.connect(_on_planet_button_pressed.bind(planet))

	button_container.add_child(button)

func _on_planet_button_pressed(planet: Node3D):
	var planet_name = planet.planet_name if planet.planet_name != "" else planet.name
	print("Teleporting to ", planet_name)

	if not xr_camera:
		xr_camera = get_viewport().get_camera_3d()
		if not xr_camera:
			push_error("No XR camera found for teleport")
			return

	# Get the XROrigin3D (parent of camera)
	var xr_origin = xr_camera.get_parent()
	if not xr_origin or not xr_origin is XROrigin3D:
		push_error("Could not find XROrigin3D")
		return

	# Calculate teleport position
	# Position at teleport_distance from planet center
	var direction = (xr_origin.global_position - planet.global_position).normalized()
	if direction.length() < 0.1:
		# If we're too close to center, use a default direction
		direction = Vector3(1, 0, 0)

	var target_position = planet.global_position + direction * teleport_distance

	# Teleport the XROrigin
	xr_origin.global_position = target_position

	print("Teleported to ", planet_name, " at position ", target_position)

func _process(_delta):
	if not xr_camera or not follow_camera or not viewport_screen:
		return

	# Position the menu in front of the camera
	var camera_transform = xr_camera.global_transform
	var forward = -camera_transform.basis.z
	var up = camera_transform.basis.y

	var position_offset = forward * menu_distance_from_player
	var vertical_offset = up * menu_vertical_offset

	viewport_screen.global_position = xr_camera.global_position + position_offset + vertical_offset

	# Make the menu face the camera
	viewport_screen.look_at(xr_camera.global_position, Vector3.UP)
