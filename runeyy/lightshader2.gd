extends CanvasItem

# MUST KEEP SYNCED WITH SHADER
const MAX_LIGHTS = 64

@export var character: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var light_positions: PackedVector3Array
var light_colors: PackedColorArray
var light_size_angle_ranges: PackedVector3Array
func _process(delta: float) -> void:
	light_positions.resize(MAX_LIGHTS)
	light_colors.resize(MAX_LIGHTS)
	light_size_angle_ranges.resize(MAX_LIGHTS)
	
	var cam_zoom := 1.0
	var cam_rot := 0.0
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		if not is_equal_approx(camera.zoom.aspect(), 1.0):
			push_error("cant deal with non uniform zoom")
		cam_zoom = camera.zoom.x
		cam_rot = camera.global_rotation
	
	var all_lights := get_tree().get_nodes_in_group(RunePointLight2D.group_name)
	# prioritize lights closer to the character 
	all_lights.sort_custom(
		func(a: RunePointLight2D, b: RunePointLight2D):
			if a.priority != b.priority:
				return a.priority > b.priority
			else:
				return (a.global_position - character.global_position).length() < (b.global_position - character.global_position).length()
	)
	
	for i in all_lights.size():
		var l: RPointLight2D = all_lights[i]
		var lpos := l.global_position
		light_positions[i] = Vector3(lpos.x, lpos.y, l.height)
		light_colors[i] = l.color
		light_size_angle_ranges[i] = Vector3(l.texture.get_size().x, l.global_rotation, l.range)
	
	var mat := (material as ShaderMaterial)
	mat.set_shader_parameter(&"light_count", all_lights.size())
	mat.set_shader_parameter(&"light_positions", light_positions)
	mat.set_shader_parameter(&"light_colors", light_colors)
	mat.set_shader_parameter(&"light_size_angle_ranges", light_size_angle_ranges)
	mat.set_shader_parameter(&"zoom", cam_zoom)
	mat.set_shader_parameter(&"rotation", cam_rot)
	mat.set_shader_parameter(&"comp_mat", get_global_transform_with_canvas())
