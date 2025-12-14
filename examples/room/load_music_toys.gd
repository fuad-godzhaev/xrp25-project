extends Node

# Path to the music_toys scene you want to load
@export var music_toys_path: String = "res://examples/xr_sequencer/music_toys.tscn"
@export var load_on_ready: bool = true
@export var offset: Vector3 = Vector3(0, 0, 0)

func _ready():
	if load_on_ready:
		load_music_toys_scene()

func load_music_toys_scene():
	# Load the music_toys scene
	var music_toys_scene = load(music_toys_path)
	if music_toys_scene:
		var instance = music_toys_scene.instantiate()

		# Position it with the offset
		if instance is Node3D:
			instance.position = offset

		# Add it to the current scene
		get_parent().add_child(instance)

		print("Music toys scene loaded successfully!")
	else:
		push_error("Failed to load music_toys scene from: " + music_toys_path)
