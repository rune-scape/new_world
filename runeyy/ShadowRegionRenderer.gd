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
	var bot_shadow_color := Color.RED
	var top_shadow_color := Color.GREEN
	
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
	var top_shadow_xform := Transform2D.IDENTITY.translated(-light_lpos).scaled(Vector2.ONE * top_scale).translated(light_lpos)
	
	var start_tile_coords := tilemap_fg.local_to_map(tilemap_fg.to_local(light_rect.position))
	var end_tile_coords := tilemap_fg.local_to_map(tilemap_fg.to_local(light_rect.end))
	var light_tile_coords := tilemap_fg.local_to_map(tilemap_fg.to_local(light.global_position))
	
	var tile_coords: Array[Vector2i]
	for x in range(start_tile_coords.x, end_tile_coords.x+1):
		for y in range(start_tile_coords.y, end_tile_coords.y+1):
			tile_coords.push_back(Vector2i(x, y))
	tile_coords.sort_custom(
		func(a: Vector2i, b: Vector2i):
			return (a - light_tile_coords).length_squared() > (b - light_tile_coords).length_squared()
	)
	
	for ti in tile_coords:
		#print(current_tile_coords)
		var tile_data := tilemap_fg.get_cell_tile_data(0, ti)
		if tile_data == null:
			continue
		var occluder := tile_data.get_occluder(0)
		if occluder == null:
			continue
		var tile_pos := tilemap_fg.map_to_local(ti) + Vector2(tile_data.texture_origin)
		var tile_local_xform := tilemap_xform.translated_local(tile_pos).translated(-light_rect.position)
		var polygons: Array[PackedVector2Array] = Geometry2D.decompose_polygon_in_convex(occluder.polygon)
		for src_polygon in polygons:
			var normalsvar = _normals_cache.get(src_polygon)
			var normals: PackedVector2Array
			if normalsvar != null:
				normals = normalsvar
			else:
				normals.resize(src_polygon.size())
				for i in src_polygon.size():
					normals[i] = (src_polygon[i+1-src_polygon.size()] - src_polygon[i]).orthogonal().normalized()
					#normals[i] = (src_polygon[i] - src_polygon[i-1]).orthogonal().normalized()
				_normals_cache[src_polygon] = normals
			
			var polygon := tile_local_xform * src_polygon
			var tile_depth := 4
			var tile_bot_height := bg_height
			if tile_depth < 0:
				tile_bot_height = bg_height
			else:
				tile_bot_height = tile_top_height - tile_depth
			var bot_shadow_scale := (light.height - bg_height) / (light.height - tile_bot_height)
			var bot_shadow_xform := Transform2D.IDENTITY.translated(-light_lpos).scaled(Vector2.ONE * bot_shadow_scale).translated(light_lpos)
			
			var top_shadow_polygon: PackedVector2Array
			var bot_shadow_polygon: PackedVector2Array
			var middle_shadow_polygon: PackedVector2Array
			var middle_shadow_polygon_colors: PackedColorArray
			var last_facing_light := normals[-1].dot(polygon[-1] - light_lpos) < 0
			for i in polygon.size():
				var facing_light := normals[i].dot(polygon[i] - light_lpos) < 0
				if facing_light:
					if facing_light != last_facing_light:
						middle_shadow_polygon.push_back(top_shadow_xform * polygon[i])
						middle_shadow_polygon_colors.push_back(top_shadow_color)
						middle_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
						middle_shadow_polygon_colors.push_back(bot_shadow_color)
						top_shadow_polygon.push_back(top_shadow_xform * polygon[i])
					bot_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
				else:
					if facing_light != last_facing_light:
						middle_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
						middle_shadow_polygon_colors.push_back(bot_shadow_color)
						middle_shadow_polygon.push_back(top_shadow_xform * polygon[i])
						middle_shadow_polygon_colors.push_back(top_shadow_color)
						bot_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
					top_shadow_polygon.push_back(top_shadow_xform * polygon[i])
				
				last_facing_light = facing_light
			#print(polygon_out)
			if bot_shadow_polygon.size() >= 3:
				draw_colored_polygon(bot_shadow_polygon, bot_shadow_color)
			if top_shadow_polygon.size() >= 3:
				draw_colored_polygon(top_shadow_polygon, top_shadow_color)
			if middle_shadow_polygon.size() >= 3:
				draw_polygon(middle_shadow_polygon, middle_shadow_polygon_colors)
			#draw_polyline(tilemap_xform.translated_local(tile_pos).translated(-light_rect.position) * polygon, Color.BLUE_VIOLET)
			#for i in polygon.size():
			#	var center := tilemap_xform.translated_local(tile_pos).translated(-light_rect.position) * ((polygon[i] + polygon[i + 1 - polygon.size()]) / 2.0)
			#	draw_line(center, center + normals[i] * 10, Color.FUCHSIA)
