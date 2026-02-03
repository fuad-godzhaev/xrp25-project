extends Node3D

## Main space scene script
## Handles teleport menu initialization and other scene-level functionality

@export var enable_teleport_menu: bool = true
@export var menu_toggle_action: String = "ax_button"  # OpenXR action name

var teleport_menu: Node3D = null
var is_menu_visible: bool = false
var xr_origin: XROrigin3D = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null
var button_pressed_last_frame: bool = false

func _ready():
	# Wait for a frame to ensure all nodes are ready
	await get_tree().process_frame

	# Find XROrigin3D and controllers
	xr_origin = _find_xr_origin(self)

	if xr_origin:
		_find_controllers()

	if enable_teleport_menu:
		_setup_teleport_menu()

func _find_xr_origin(node: Node) -> XROrigin3D:
	if node is XROrigin3D:
		return node

	for child in node.get_children():
		var result = _find_xr_origin(child)
		if result:
			return result

	return null

func _find_controllers():
	if not xr_origin:
		return

	for child in xr_origin.get_children():
		if child is XRController3D:
			if child.tracker == "left_hand":
				left_controller = child
			elif child.tracker == "right_hand":
				right_controller = child

	if left_controller:
		print("Found left controller")
	if right_controller:
		print("Found right controller")

func _setup_teleport_menu():
	print("Setting up teleport menu...")

	# Load and instantiate the teleport menu
	var menu_scene = load("res://solarity/planet_teleport_menu.tscn")
	if not menu_scene:
		push_error("Failed to load teleport menu scene")
		return

	teleport_menu = menu_scene.instantiate()

	# Add it to the scene
	if xr_origin:
		xr_origin.add_child(teleport_menu)
		print("Teleport menu added to XROrigin3D")
	else:
		add_child(teleport_menu)
		print("Teleport menu added to Space scene (XROrigin not found)")

	# Start hidden
	teleport_menu.visible = false
	is_menu_visible = false

func _process(_delta):
	if not enable_teleport_menu or not teleport_menu:
		return

	# Check for button press on either controller
	var button_pressed = false

	if left_controller and left_controller.is_button_pressed(menu_toggle_action):
		button_pressed = true
	elif right_controller and right_controller.is_button_pressed(menu_toggle_action):
		button_pressed = true

	# Toggle only on button press (not hold)
	if button_pressed and not button_pressed_last_frame:
		toggle_menu()

	button_pressed_last_frame = button_pressed

func toggle_menu():
	is_menu_visible = !is_menu_visible
	teleport_menu.visible = is_menu_visible

	if is_menu_visible:
		print("Teleport menu shown - Press ", menu_toggle_action, " to hide")
	else:
		print("Teleport menu hidden - Press ", menu_toggle_action, " to show")
