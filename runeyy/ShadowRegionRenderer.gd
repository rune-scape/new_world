@tool
class_name ShadowRegionRenderer extends ColorRect

var tilemap_fg: TileMap
var tilemap_bg: TileMap
var light: RPointLight2D
var light_rect: Rect2i
var channel: Color

func _process(delta: float) -> void:
	queue_redraw()

var _normals_cache := {}
func _draw() -> void:
	draw_rect(Rect2(light.global_position - Vector2(light_rect.position), Vector2(1, 1)), Color.BLUE)
	
	var tile_top_height: float = tilemap_fg.get_layer_z_index(0)
	var bg_height: float = tilemap_bg.get_layer_z_index(0)
	if light.height < bg_height:
		draw_rect(get_rect(), channel) # all shadow
	if tile_top_height < bg_height:
		return # no shadow
	
	var tilemap_xform := tilemap_fg.global_transform
	var light_gpos := light.global_position
	var light_lpos := light_gpos - Vector2(light_rect.position)
	var light_distance_to_top := light.height - tile_top_height
	var top_scale: float
	if light_distance_to_top < 0 or is_zero_approx(light_distance_to_top):
		top_scale = size.x * size.y # just a lazy value that will always be large enough but not toooooo big
	else:
		top_scale = (light.height - bg_height) / light_distance_to_top
	var top_xform := tilemap_xform.translated(-light_gpos).scaled(Vector2.ONE * top_scale).translated(light_lpos)
	
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
					var polygons: Array[PackedVector2Array] = Geometry2D.decompose_polygon_in_convex(occluder.polygon)
					for polygon in polygons:
						var normalsvar = _normals_cache.get(polygon)
						var normals: PackedVector2Array
						if normalsvar != null:
							normals = normalsvar
						else:
							normals.resize(polygon.size())
							for i in polygon.size():
								normals[i] = (polygon[i+1-polygon.size()] - polygon[i]).orthogonal().normalized()
							_normals_cache[polygon] = normals
						
						var tile_depth := 2
						var tile_bot_height := bg_height
						if tile_depth < 0:
							tile_bot_height = bg_height
						else:
							tile_bot_height = tile_top_height - tile_depth
						var tile_bot_scale := (light.height - bg_height) / (light.height - tile_bot_height)
						var tile_bot_xform := tilemap_xform.translated(-light_gpos).scaled(Vector2.ONE * tile_bot_scale).translated(light_gpos-Vector2(light_rect.position))
						
						var top_shadow_polygon := top_xform.translated_local(tile_pos) * polygon
						var bot_shadow_polygon := tile_bot_xform.translated_local(tile_pos) * polygon
						var polygon_out: PackedVector2Array
						var polygon_colors: PackedColorArray
						var last_facing_light := normals[-1].dot(bot_shadow_polygon[-1] - light_lpos) < 0
						for i in polygon.size():
							var facing_light := normals[i].dot(bot_shadow_polygon[i] - light_lpos) < 0
							if facing_light:
								if facing_light != last_facing_light:
									polygon_out.push_back(top_shadow_polygon[i])
									polygon_colors.push_back(Color.GREEN)
								polygon_out.push_back(bot_shadow_polygon[i])
								polygon_colors.push_back(Color.RED)
							else:
								if facing_light != last_facing_light:
									polygon_out.push_back(bot_shadow_polygon[i])
									polygon_colors.push_back(Color.RED)
								polygon_out.push_back(top_shadow_polygon[i])
								polygon_colors.push_back(Color.GREEN)
							
							last_facing_light = facing_light
						#print(polygon_out)
						draw_polygon(polygon_out, polygon_colors)
						draw_colored_polygon(top_shadow_polygon, Color(Color.GREEN, 1.0))
						draw_colored_polygon(bot_shadow_polygon, Color(Color.RED, 1.0))
						draw_polyline(tilemap_xform.translated_local(tile_pos).translated(-light_rect.position) * polygon, Color.BLUE_VIOLET)
						for i in polygon.size():
							var center := tilemap_xform.translated_local(tile_pos).translated(-light_rect.position) * ((polygon[i] + polygon[i + 1 - polygon.size()]) / 2.0)
							draw_line(center, center + normals[i] * 10, Color.FUCHSIA)
			current_tile_coords.x += 1
		current_tile_coords.x = start_tile_coords.x
		current_tile_coords.y += 1
