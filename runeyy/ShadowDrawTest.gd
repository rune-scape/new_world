@tool
extends ColorRect

const MAX_LIGHT_COUNT = 64 # MUST BE SYNCHRONIZED WITH SHADER
const MAX_BLUR_SAMPLE_COUNT = 256 # MUST BE SYNCHRONIZED WITH SHADER

var light_count: int
var shadow_atlas_positions: PackedVector2Array
var shadow_screen_rects: PackedColorArray # the type should be PackedVector4Array ... if it existed
var shadow_channels: PackedColorArray
var light_positions: PackedVector3Array

@export_range(1, MAX_BLUR_SAMPLE_COUNT) var blur_sample_count: int = 50 

@onready
when ShadowAtlasRenderer.started_packing:
	light_count = 0
	shadow_atlas_positions.resize(MAX_LIGHT_COUNT)
	shadow_screen_rects.resize(MAX_LIGHT_COUNT)
	shadow_channels.resize(MAX_LIGHT_COUNT)
	light_positions.resize(MAX_LIGHT_COUNT)

func find_camera(node: Node, list: Array):
	if node is Viewport:
		var camera = node.get_camera_2d()
		if is_instance_valid(camera) and camera is Camera2D:
			list.append(camera)
			return list
	for child in node.get_children():
		find_camera(child, list)
	return list

@onready
when ShadowAtlasRenderer.finished_packing_channel(lights: Array, channel: Color):
	for i in range(0, min(MAX_LIGHT_COUNT - light_count, lights.size())):
		var l: RPointLight2D = lights[i]
		shadow_atlas_positions[light_count + i] = l.renderer.position
	
	for i in range(0, min(MAX_LIGHT_COUNT - light_count, lights.size())):
		var l: RPointLight2D = lights[i]
		var lrlocal := Rect2(Vector2(l.renderer.light_rect.position) - l.global_position, l.renderer.light_rect.size)
		var lsr := l.get_canvas_transform() * Rect2(l.renderer.light_rect)
		shadow_screen_rects[light_count + i] = Color(lsr.position.x, lsr.position.y, lsr.end.x, lsr.end.y)
	
	for i in range(0, min(MAX_LIGHT_COUNT - light_count, lights.size())):
		var l: RPointLight2D = lights[i]
		shadow_channels[light_count + i] = l.renderer.channel
	
	for i in range(0, min(MAX_LIGHT_COUNT - light_count, lights.size())):
		var l: RPointLight2D = lights[i]
		var lpos := l.get_global_transform_with_canvas().origin
		light_positions[light_count + i] = Vector3(lpos.x, lpos.y, l.height)
	
	light_count += lights.size()

const PHI := 1.618033988749895
var gaussian_sum: float
func random_circle_sample(n: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	var sum := 0.0
	for k in n:
		var r := randf()
		var theta := randf() * TAU
		var pos := r * Vector2.from_angle(theta)
		var gaus := gaussian(pos)
		sum += gaus
		points.push_back(Vector3(pos.x, pos.y, gaus))
	gaussian_sum = sum
	for i in points.size():
		points[i].z /= sum
	
	return points

func random_normal_circle_sample(n: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	var sum := 0.0
	for k in n:
		var r := sqrt(normal())
		var theta := randf() * TAU
		var pos := r * Vector2.from_angle(theta)
		var gaus := gaussian(pos)
		sum += gaus
		points.push_back(Vector3(pos.x, pos.y, gaus))
	gaussian_sum = sum
	for i in points.size():
		points[i].z /= sum
	
	return points

func sunflower(n: int, alpha: int = 2, geodesic: bool = false) -> PackedVector3Array:
	var points := PackedVector3Array()
	var angle_stride := (360.0 * PHI) if geodesic else (2 * PI / PHI ** 2)
	var b := roundf(alpha * sqrt(n))  # number of boundary points
	var sum := 0.0
	for k in n:
		var r := radius(k + 1, n, b)
		var theta := k * angle_stride
		var pos := r * Vector2.from_angle(theta)
		var gaus := gaussian(pos)
		sum += gaus
		points.push_back(Vector3(pos.x, pos.y, gaus))
	gaussian_sum = sum
	for i in points.size():
		points[i].z /= sum
	
	return points

func radius(k: int, n: int, b: int) -> float:
	if k > (n - b):
		return 1.0
	else:
		return sqrt(k - 0.5) / sqrt(n - (b + 1) / 2)

func gaussian(pos: Vector2) -> float:
	return exp(-pos.length_squared()) + 1

func normal(avg : float = 0.0, sd : float = 1.0) -> float:
	return avg+sd*sqrt(-2*(log(randf())))*cos(2*PI*randf())
	
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var points := random_normal_circle_sample(512)
	#print(points)
	draw_set_transform(Vector2.ONE)
	for p in points:
		draw_primitive([p], [Color.RED], [Vector2(0,0)])

@onready
when ShadowAtlasRenderer.finished_packing:
	#print(light_count)
	#print(shadow_screen_rects.slice(0, light_count))
	
	var mat: ShaderMaterial = material
	mat.set_shader_parameter(&"shadow_atlas", ShadowAtlasRenderer.get_texture())
	mat.set_shader_parameter(&"light_count", light_count)
	mat.set_shader_parameter(&"shadow_atlas_scale", ShadowAtlasRenderer.scale)
	
	mat.set_shader_parameter(&"shadow_atlas_positions", shadow_atlas_positions)
	mat.set_shader_parameter(&"shadow_screen_rects", shadow_screen_rects)
	mat.set_shader_parameter(&"shadow_channels", shadow_channels)
	mat.set_shader_parameter(&"light_positions", light_positions)
	
	mat.set_shader_parameter(&"blur_sample_count", blur_sample_count)
	var samples := random_circle_sample(blur_sample_count)
	samples.resize(MAX_BLUR_SAMPLE_COUNT)
	mat.set_shader_parameter(&"blur_samples", samples)
	#mat.set_shader_parameter(&"gaussian_sum", gaussian_sum)
