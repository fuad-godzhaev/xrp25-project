extends Node3D

## Controller script to toggle the teleport menu with a button press

@export var menu_scene: PackedScene
@export var toggle_action: String = "ax_button"  # A/X button on controllers

var menu_instance: Node3D = null
var is_menu_visible: bool = false

func _ready():
	# Load the menu scene if not set
	if not menu_scene:
		menu_scene = load("res://solarity/planet_teleport_menu.tscn")

func _process(_delta):
	# Check for button press to toggle menu
	if Input.is_action_just_pressed(toggle_action):
		toggle_menu()

func toggle_menu():
	if is_menu_visible:
		hide_menu()
	else:
		show_menu()

func show_menu():
	if menu_instance:
		menu_instance.visible = true
	else:
		# Instantiate the menu
		if menu_scene:
			menu_instance = menu_scene.instantiate()
			add_child(menu_instance)
		else:
			push_error("Menu scene not loaded")
			return

	is_menu_visible = true
	print("Teleport menu shown")

func hide_menu():
	if menu_instance:
		menu_instance.visible = false

	is_menu_visible = false
	print("Teleport menu hidden")
