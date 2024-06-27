@tool
class_name RunePointLight2D extends PointLight2D

static var group_name := &"point_lights"
@export var priority := 0

func _ready() -> void:
	add_to_group(group_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		var in_group := is_in_group(group_name)
		if visible and not in_group:
			add_to_group(group_name)
		elif not visible and in_group:
			remove_from_group(group_name)

func get_rect() -> Rect2:
	var real_tex_size := texture.get_size() * texture_scale
	var lr := Rect2(offset - real_tex_size / 2, real_tex_size)
	var light_polygon := PackedVector2Array([lr.position, Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)])
	var result: Rect2
	for v in light_polygon:
		result = result.expand(v.rotated(transform.get_rotation()))
	result.position *= global_scale
	result.position += global_position.round()
	result.size *= global_scale
	return result
