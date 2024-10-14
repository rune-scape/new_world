@tool
class_name ShadowRegionRenderer extends Node2D

var size: Vector2
var tilemap: TileMap
var fg_height: float
var bg_height: float
var light: RPointLight2D
var light_rect: Rect2i
var channel: Color
var debug: bool = false

var _tile_coords: Array[Vector2i]
#var _meshes: Array[Mesh]

# godot might use 16 bit floats, and with a mantissa of 10 bits, the resolution from 0 to 1 is approx 11 bits
# have to keep it linear bc thats how vertex colors will be interpolated
# this amnt of blur will never relly be 'used' but it will help keep consistency when vertexes are scaled very far away
const MAX_BLUR: float = pow(2.0, 8.0) - 1.0 # MUST BE SYNCHRONIZED WITH SHADER

#func get_max_shadow_scale() -> float:
	#return (MAX_BLUR - 1.0) / light.light_size + 1.0

# i like plugged an equasion into wolfram alpha: 's*((x-z)/(y-x)-1)=m, solve for x'
# when used to clamp surface height
func get_max_surface_height() -> float:
	return (MAX_BLUR * light.height + light.light_size * (light.height + bg_height)) / (MAX_BLUR + 2 * light.light_size)

func get_shadow_scale(surface_height: float) -> float:
	surface_height = clampf(surface_height, bg_height, get_max_surface_height())
	return (light.height - bg_height) / (light.height - surface_height)
	#var max_shadow_scale_v := get_max_shadow_scale()
	#if surface_height > light.height or is_equal_approx(surface_height, light.height):
		#return max_shadow_scale_v
	
	#return minf(max_shadow_scale_v, (light.height - bg_height) / (light.height - surface_height))

func get_shadow_blur(surface_height: float) -> float:
	surface_height = clampf(surface_height, bg_height, get_max_surface_height())
	return light.light_size * ((surface_height - bg_height) / (light.height - surface_height))
	#var max_shadow_blur_v := MAX_BLUR - 1.0
	#if surface_height > light.height or is_equal_approx(surface_height, light.height):
		#return max_shadow_blur_v
	#
	#return clampf(light.light_size * ((surface_height - bg_height) / (light.height - surface_height) - 1.0), 0.0, max_shadow_blur_v)

# have to keep it linear bc thats how vertex colors will be interpolated
func get_shadow_color(surface_height: float) -> Color:
	return channel * ((get_shadow_blur(surface_height) / 2.0 + 1.0) / MAX_BLUR)

static var _cache := {}
func _draw() -> void:
	if debug:
		draw_rect(get_rect(), Color(Color.from_hsv(rand_from_seed(light.get_instance_id())[0], 1.0, 1.0), 0.25))
		draw_rect(Rect2(light.global_position - Vector2(light_rect.position), Vector2(1, 1)), Color.BLUE)
	
	#_meshes.clear()
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(Vector2.ZERO, size))
	RenderingServer.canvas_item_set_clip(get_canvas_item(), true)
	
	var full_shadow_color := channel
	if debug:
		full_shadow_color = Color.RED
	full_shadow_color.a = 1.0
	if light.height < bg_height:
		draw_rect(get_rect(), full_shadow_color) # all shadow
	if fg_height < bg_height:
		return # no shadow
	
	var tile_mid_depth := (fg_height + bg_height) / 2.0
	var tilemap_xform := tilemap.global_transform
	var light_gpos := light.global_position
	var light_lpos := light_gpos - Vector2(light_rect.position)
	
	var start_tile_coords := tilemap.local_to_map(tilemap.to_local(light_rect.position))
	var end_tile_coords := tilemap.local_to_map(tilemap.to_local(light_rect.end)) + Vector2i(1, 1)
	var tile_coord_block_size := end_tile_coords - start_tile_coords
	var light_tile_coords := tilemap.local_to_map(tilemap.to_local(light.global_position))
	
	_tile_coords.resize(tile_coord_block_size.x * tile_coord_block_size.y)
	var tile_coord_index := 0
	for x in range(start_tile_coords.x, end_tile_coords.x):
		for y in range(start_tile_coords.y, end_tile_coords.y):
			_tile_coords[tile_coord_index] = Vector2i(x, y)
			tile_coord_index += 1
	_tile_coords.sort_custom(
		func(a: Vector2i, b: Vector2i):
			return (a - light_tile_coords).length_squared() < (b - light_tile_coords).length_squared()
	)
	
	for ti in _tile_coords:
		#print(current_tile_coords)
		var tile_data := tilemap.get_cell_tile_data(0, ti)
		if tile_data == null:
			continue
		
		var occluder := tile_data.get_occluder(0)
		if occluder == null or occluder.polygon.is_empty():
			continue
		
		var tile_pos := tilemap.map_to_local(ti) + Vector2(tile_data.texture_origin)
		var tile_local_xform := tilemap_xform.translated_local(tile_pos).translated(-light_rect.position)
		
		var tile_depth: float = absf(tile_data.get_custom_data_by_layer_id(0))
		var tile_depth_offset: float = tile_data.get_custom_data_by_layer_id(1)
		var tile_top_height := clampf(tile_mid_depth + tile_depth * 0.5 + tile_depth_offset, bg_height, fg_height)
		var tile_bot_height := clampf(tile_mid_depth - tile_depth * 0.5 + tile_depth_offset, bg_height, fg_height)
		
		if light.height < tile_bot_height:
			continue
		
		var top_shadow_color := get_shadow_color(tile_top_height)
		if debug:
			top_shadow_color = Color.GREEN
		top_shadow_color.a = 1.0
		
		var bot_shadow_color := get_shadow_color(tile_bot_height)
		if debug:
			bot_shadow_color = Color.RED
		bot_shadow_color.a = 1.0
		
		var top_shadow_scale := get_shadow_scale(tile_top_height)
		var top_shadow_xform := Transform2D.IDENTITY.translated(-light_lpos).scaled(Vector2.ONE * top_shadow_scale).translated(light_lpos)
		var bot_shadow_scale := get_shadow_scale(tile_bot_height)
		var bot_shadow_xform := Transform2D.IDENTITY.translated(-light_lpos).scaled(Vector2.ONE * bot_shadow_scale).translated(light_lpos)
		
		var cache_var = _cache.get(occluder.polygon)
		
		var src_polygon: PackedVector2Array
		var normals: PackedVector2Array
		if cache_var != null:
			src_polygon = cache_var.polygon
			normals = cache_var.normals
		else:
			src_polygon = occluder.polygon
			
			if Geometry2D.is_polygon_clockwise(src_polygon):
				src_polygon.reverse()
			
			normals.resize(src_polygon.size())
			for v in src_polygon.size():
				normals[v] = (src_polygon[v+1-src_polygon.size()] - src_polygon[v]).normalized().orthogonal()
			
			cache_var = {
				polygon = src_polygon,
				normals = normals
			}
			_cache[occluder.polygon] = cache_var
		
		if src_polygon.size() != normals.size():
			push_error("src_polygon.size() != normals.size()")
			return
		
		var polygon := tile_local_xform * src_polygon
		draw_colored_polygon(bot_shadow_xform * polygon, bot_shadow_color)
		
		if is_zero_approx(tile_depth):
			continue
		
		var is_light_inside_tile := tile_bot_height <= light.height and light.height <= tile_top_height and Geometry2D.is_point_in_polygon(light_lpos, polygon)
		if is_light_inside_tile:
			draw_rect(get_rect(), full_shadow_color) # all shadow
			return
		
		#var middle_shadow_polygon: PackedVector2Array
		#var middle_shadow_polygon_colors: PackedColorArray
		
		#var last_facing_light_v := normals[-1].dot(polygon[-1] - light_lpos) < 0
		#for i in polygon.size():
			#var is_facing_light := normals[i].dot(polygon[i] - light_lpos) < 0
			#if is_facing_light:
				#if is_facing_light != last_facing_light_v:
					#middle_shadow_polygon.push_back(top_shadow_xform * polygon[i])
					#middle_shadow_polygon_colors.push_back(top_shadow_color)
					#middle_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
					#middle_shadow_polygon_colors.push_back(bot_shadow_color)
			#else:
				#if is_facing_light != last_facing_light_v:
					#middle_shadow_polygon.push_back(bot_shadow_xform * polygon[i])
					#middle_shadow_polygon_colors.push_back(bot_shadow_color)
					#middle_shadow_polygon.push_back(top_shadow_xform * polygon[i])
					#middle_shadow_polygon_colors.push_back(top_shadow_color)
			#
			#last_facing_light_v = is_facing_light
		
		#var shadow_meshes: Array[Dictionary]
		#var vertex_array: PackedVector2Array
		#var vertex_colors: PackedColorArray
		#var vi := -polygon.size()
		#var shadow_max_dist := 0.0
		#var last_facing_light_v := normals[-1].dot(polygon[-1] - light_lpos) < 0
		#var write_vertices_start := vi
		#var writing_vertices := false
		#var looping := true
		#while looping:
			#var is_facing_light := normals[vi].dot(polygon[vi] - light_lpos) < 0
			#if not writing_vertices:
				#if (last_facing_light_v and not is_facing_light) or (vi == -1):
					#writing_vertices = true
					#write_vertices_start = vi
			#
			#if writing_vertices:
				#if not is_facing_light or not last_facing_light_v:
					#var vin: int = vi+1 - polygon.size()
					#shadow_max_dist = maxf(shadow_max_dist, maxf((polygon[vi] - light_lpos).length_squared(), (polygon[vin] - light_lpos).length_squared()))
					#vertex_array.push_back(bot_shadow_xform * polygon[vi])
					#vertex_colors.push_back(bot_shadow_color)
					#vertex_array.push_back(top_shadow_xform * polygon[vi])
					#vertex_colors.push_back(top_shadow_color)
			#
			#last_facing_light_v = is_facing_light
			#vi += 1
			#
			#if not (vi < polygon.size()-1 and vi < (write_vertices_start + polygon.size() + 1)):
				#looping = false
			#if writing_vertices:
				#if is_facing_light or not looping:
					#writing_vertices = false
				#if not writing_vertices and vertex_array.size() >= 3:
					#var mesh_arrays := []
					#mesh_arrays.resize(Mesh.ARRAY_MAX)
					#mesh_arrays[Mesh.ARRAY_VERTEX] = vertex_array
					#mesh_arrays[Mesh.ARRAY_COLOR] = vertex_colors
					#var shadow_mesh := ArrayMesh.new()
					#shadow_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, mesh_arrays)
					#shadow_meshes.push_back({
						#mesh = shadow_mesh,
						#dist = shadow_max_dist
					#})
					#_meshes.push_back(shadow_mesh)
					#vertex_array.clear()
					#vertex_colors.clear()
					#shadow_max_dist = 0.0
		#
		#shadow_meshes.sort_custom(
			#func(a: Dictionary, b: Dictionary):
				#return a.dist < b.dist
		#)
		#
		#for d in shadow_meshes:
			#draw_mesh(d.mesh, null)
		
		var dists: Array[Dictionary]
		for vi in polygon.size():
			var is_facing_light := normals[vi].dot(polygon[vi] - light_lpos) < 0
			if not is_facing_light:
				var vin: int = vi+1 - polygon.size()
				dists.push_back({
					i = vi,
					dist = ((polygon[vi] + polygon[vin])/2.0 - light_lpos).length_squared(),
				})
		
		dists.sort_custom(
			func(a: Dictionary, b: Dictionary):
				return a.dist < b.dist
		)
		
		var mid_shadow_colors := PackedColorArray([bot_shadow_color, bot_shadow_color, top_shadow_color, top_shadow_color])
		for d in dists:
			var vi: int = d.i
			var vin: int = d.i+1 - polygon.size()
			draw_polygon([bot_shadow_xform * polygon[vi], bot_shadow_xform * polygon[vin], top_shadow_xform * polygon[vin], top_shadow_xform * polygon[vi]], mid_shadow_colors)
		
		if debug:
			draw_polyline(polygon, Color.BLUE_VIOLET)
			for v in polygon.size():
				var center := ((polygon[v] + polygon[v + 1 - polygon.size()]) / 2.0).floor() + Vector2(0.5, 0.5)
				draw_line(center, center + normals[v] * 4, Color.FUCHSIA)

func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)
