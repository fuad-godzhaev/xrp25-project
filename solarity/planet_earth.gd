## Simple Earth with day/night textures
@tool
extends Planet

@export_group("Earth Day/Night")
@export var day_texture: Texture2D:
	set(value):
		day_texture = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var night_texture: Texture2D:
	set(value):
		night_texture = value
		if Engine.is_editor_hint():
			_update_planet_in_editor()

@export var sun_direction: Vector3 = Vector3(1, 0, 0):
	set(value):
		sun_direction = value.normalized()
		if Engine.is_editor_hint():
			_update_planet_in_editor()

# Override parent's _setup_body to use day/night shader
func _setup_body():
	if not body:
		return

	var sphere = SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height = planet_radius * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	body.mesh = sphere

	# Create shader material
	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()

	shader.code = """
shader_type spatial;

uniform sampler2D day_tex : source_color;
uniform sampler2D night_tex : source_color;
uniform vec3 sun_dir = vec3(1.0, 0.0, 0.0);

void fragment() {
	vec3 normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float sun_amount = dot(normal, normalize(sun_dir));
	float mix_factor = smoothstep(-0.1, 0.1, sun_amount);

	vec3 day_col = texture(day_tex, UV).rgb;
	vec3 night_col = texture(night_tex, UV).rgb;

	ALBEDO = mix(night_col, day_col, mix_factor);
}
"""

	shader_mat.shader = shader
	if day_texture:
		shader_mat.set_shader_parameter("day_tex", day_texture)
	if night_texture:
		shader_mat.set_shader_parameter("night_tex", night_texture)
	shader_mat.set_shader_parameter("sun_dir", sun_direction)

	body.material_override = shader_mat
