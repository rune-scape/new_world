@tool
class_name RPointLight2D extends Node2D

static var group_name := &"rpoint_lights"
@export var texture: Texture2D
@export var offset: Vector2
@export var light_size: float
@export var height: float = 0
@export var color: Color = Color.WHITE
@export_range(0, 360, 0.1, "radians_as_degrees") var range: float = PI*2
@export var priority := 0
@export var follow: bool = false

var renderer: ShadowRegionRenderer

func _ready() -> void:
	add_to_group(group_name)
	if Engine.is_editor_hint():
		set_process(true)

func _process(_delta: float) -> void:
	if follow:
		global_position = get_global_mouse_position()
	if Engine.is_editor_hint():
		queue_redraw()

when visibility_changed:
	var in_group := is_in_group(group_name)
	if visible and not in_group:
		add_to_group(group_name)
	elif not visible and in_group:
		remove_from_group(group_name)

func _draw():
	if Engine.is_editor_hint():
		if range < 2*PI:
			draw_line(Vector2(0,0), Vector2(25, 0).rotated(range/2), Color.AQUAMARINE)
			draw_line(Vector2(0,0), Vector2(25, 0).rotated(-range/2), Color.AQUAMARINE)

func get_local_rect() -> Rect2:
	var real_tex_size := texture.get_size()
	return Rect2(offset - real_tex_size / 2, real_tex_size)

func get_rect() -> Rect2:
	var lr := get_local_rect()
	var light_polygon := PackedVector2Array([lr.position, Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)])
	var result: Rect2
	for v in light_polygon:
		result = result.expand(v.rotated(global_rotation))
	result.position *= global_scale
	result.position += global_position.floor()
	result.size *= global_scale
	return result
