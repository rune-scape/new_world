@tool
extends ColorRect

@export var character: Node2D
@export var tilemap_fg: TileMap
@export var tilemap_bg: TileMap

func _ready() -> void:
	var result := []
	var packed_size := RectPack2D.pack(result, [Vector2(1000, 1000)], 1000)
	print("packed_size: ", packed_size, " result: ", result)

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	RunePointLight2D.all_lights.sort_custom(
		func(a: RunePointLight2D, b: RunePointLight2D):
			return (a.global_position - character.global_position).length() < (b.global_position - character.global_position).length())
	
	#var lights2 = RunePointLight2D.all_lights.map(
		#func(light: RunePointLight2D):
			#var light_tex_size := light.texture.get_size() * light.texture_scale
			#var light_rect := Rect2(light.offset - light_tex_size / 2, light_tex_size)
			#light_rect.position *= light.global_scale
			#light_rect.position += light.global_position
			#light_rect.size *= light.global_scale
	#)
	var lights = RunePointLight2D.all_lights.slice(0, 4)
	for li in lights.size():
		var light: PointLight2D = lights[li]
		var light_tex_size := light.texture.get_size() * light.texture_scale
		var lr := Rect2(light.offset - light_tex_size / 2, light_tex_size)
		var light_polygon := PackedVector2Array([lr.position, Vector2(lr.end.x, lr.position.y), lr.end, Vector2(lr.position.x, lr.end.y)])
		var light_rect: Rect2
		for v in light_polygon:
			light_rect = light_rect.expand(v.rotated(light.transform.get_rotation()))
		light_rect.position *= light.global_scale
		light_rect.position += light.global_position
		light_rect.size *= light.global_scale
		var channel_idx := li % 4
		var port_idx: int = li / 4
		var light_channel: Color = [Color(1,0,0,1), Color(0,1,0,1), Color(0,0,1,0), Color(0,0,0,1)][channel_idx]
		var start_tile_coords := tilemap_fg.local_to_map(tilemap_fg.to_local(light_rect.position))
		var end_tile_coords := tilemap_fg.local_to_map(tilemap_fg.to_local(light_rect.end))
		var current_tile_coords := start_tile_coords
		while current_tile_coords.y <= end_tile_coords.y:
			while current_tile_coords.x <= end_tile_coords.x:
				var tile_data := tilemap_fg.get_cell_tile_data(0, current_tile_coords)
				if tile_data != null:
					var occluder := tile_data.get_occluder(0)
					if occluder != null:
						var tile_pos := tilemap_fg.map_to_local(current_tile_coords) + Vector2(tile_data.texture_origin)
						var polygon: PackedVector2Array = occluder.polygon
						draw_set_transform_matrix(tilemap_fg.global_transform.translated_local(tile_pos))
						draw_colored_polygon(polygon, light_channel)
				current_tile_coords.x += 1
			current_tile_coords.x = start_tile_coords.x
			current_tile_coords.y += 1
		break
