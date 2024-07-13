@tool
extends ColorRect

const MAX_LIGHT_COUNT = 64 # MUST BE SYNCHRONIZED WITH SHADER

var light_count: int
var shadow_rects: PackedColorArray # the type should be PackedVector4Array ... if it existed
var shadow_channels: PackedColorArray
var shadow_light_positions: PackedVector2Array
var light_positions: PackedVector3Array

@onready
when ShadowAtlasRenderer.started_packing:
	light_count = 0
	shadow_rects.resize(MAX_LIGHT_COUNT)
	shadow_channels.resize(MAX_LIGHT_COUNT)
	shadow_light_positions.resize(MAX_LIGHT_COUNT)
	light_positions.resize(MAX_LIGHT_COUNT)

@onready
when ShadowAtlasRenderer.finished_packing_channel(lights: Array, channel: Color):
	light_count += lights.size()
	shadow_rects.append_array(lights.map(
		func(l: RPointLight2D) -> Color:
			return Color(l.renderer.position.x, l.renderer.position.y, l.renderer.size.x, l.renderer.size.y)
	))
	shadow_channels.append_array(lights.map(
		func(l: RPointLight2D) -> Color:
			return l.renderer.channel
	))
	shadow_light_positions.append_array(lights.map(
		func(l: RPointLight2D) -> Vector2:
			return l.global_position - Vector2(l.renderer.light_rect.position)
	))
	light_positions.append_array(lights.map(
		func(l: RPointLight2D) -> Vector2:
			return l.get_global_transform_with_canvas().origin
	))

@onready
when ShadowAtlasRenderer.finished_packing:
	var mat: ShaderMaterial = material
	mat.set_shader_parameter(&"shadow_atlas", ShadowAtlasRenderer.get_texture())
	mat.set_shader_parameter(&"light_count", shadow_rects)
	mat.set_shader_parameter(&"shadow_rects", shadow_rects)
	mat.set_shader_parameter(&"shadow_channels", shadow_channels)
	mat.set_shader_parameter(&"shadow_light_positions", shadow_light_positions)
	mat.set_shader_parameter(&"light_positions", light_positions)
