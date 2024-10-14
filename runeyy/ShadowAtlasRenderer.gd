@tool
extends SubViewport

@export_range(512, 2048) var atlas_size: int = 512
@export_range(0.5, 2.0) var scale: float = 1.0

var character: Node2D
var tilemap_fg: TileMap
var tilemap_bg: TileMap

var unpacked_lights: Array

signal started_packing
signal finished_packing
signal finished_packing_channel(lights: Array, channel: Color)

func _process(_delta: float) -> void:
	size = Vector2i(atlas_size, atlas_size)
	
	unpacked_lights = get_tree().get_nodes_in_group(RPointLight2D.group_name)
	for l in unpacked_lights:
		l.renderer = null
	
	unpacked_lights = unpacked_lights.filter(
		func(a: RPointLight2D):
			return a.visible
	)
	
	if character != null:
		# prioritize lights closer to the character
		unpacked_lights.sort_custom(
			func(a: RPointLight2D, b: RPointLight2D):
				if a.priority != b.priority:
					return a.priority > b.priority
				else:
					return (a.global_position - character.global_position).length_squared() < (b.global_position - character.global_position).length_squared()
		)
	
	if not unpacked_lights.is_empty() and (tilemap_fg == null or tilemap_bg == null):
		push_warning("can't render lights without tilemap")
		return
	
	var unpacked_light_rects: Array
	unpacked_light_rects.resize(unpacked_lights.size())
	for i in unpacked_lights.size():
		var rect: Rect2 = unpacked_lights[i].get_rect()
		var rect_snapped: Rect2i
		# scalify it
		rect_snapped.position = Vector2i((rect.position * scale).floor())
		rect_snapped.end = Vector2i((rect.end * scale).ceil())
		unpacked_light_rects[i] = rect_snapped
	
	started_packing.emit()
	
	# try packing as many into each color channel, overflowing if needed
	pack_regions_in_channel(unpacked_lights, unpacked_light_rects, %ShadowRegionsR, Color(1, 0, 0, 0))
	#pack_regions_in_channel(unpacked_lights, unpacked_light_rects, %ShadowRegionsG, Color(0, 1, 0, 0))
	#pack_regions_in_channel(unpacked_lights, unpacked_light_rects, %ShadowRegionsB, Color(0, 0, 1, 0))
	#pack_regions_in_channel(unpacked_lights, unpacked_light_rects, %ShadowRegionsA, Color(0, 0, 0, 1))
	
	finished_packing.emit()

func pack_regions_in_channel(unpacked_lights: Array, unpacked_light_rects: Array, regions_parent: Node, channel: Color):
	if unpacked_lights.size() != unpacked_light_rects.size():
		push_error("unpacked_lights.size() != unpacked_region_sizes.size()")
		return
	
	var packed_rects := []
	var _packed_size := RectPack2D.pack(packed_rects, unpacked_light_rects.map(func(r: Rect2i) -> Vector2: return r.size), atlas_size)
	
	var packed_lights: Array[RPointLight2D]
	var packed_light_rects: Array[Rect2i]
	for i in range(packed_rects.size()-1, -1, -1):
		var rect: Rect2i = packed_rects[i]
		if rect.position == Vector2i(-1, -1):
			packed_rects.remove_at(i)
		else:
			packed_lights.push_front(unpacked_lights[i])
			packed_light_rects.push_front(unpacked_light_rects[i])
			unpacked_lights.remove_at(i)
			unpacked_light_rects.remove_at(i)
	
	if packed_lights.size() != packed_rects.size():
		push_error("packed_lights.size() != packed_rects.size()")
		return
	
	var size_diff := packed_rects.size() - regions_parent.get_child_count()
	if size_diff > 0:
		for i in size_diff:
			var n := ShadowRegionRenderer.new()
			n.use_parent_material = true
			regions_parent.add_child(n)
	elif -size_diff > packed_rects.size()*2:
		for i in -size_diff:
			regions_parent.remove_child(regions_parent.get_child(0))
	
	for i in regions_parent.get_child_count():
		var c: ShadowRegionRenderer = regions_parent.get_child(i)
		if i >= packed_rects.size():
			c.visible = false
			continue
		
		c.visible = true
		c.queue_redraw()
		var rect: Rect2i = packed_rects[i]
		var light_rect: Rect2 = packed_light_rects[i]
		c.position = Vector2(rect.position)
		c.debug = false
		c.size = Vector2(rect.size) / scale
		c.scale = Vector2.ONE * scale
		c.tilemap = tilemap_fg
		c.fg_height = tilemap_fg.get_layer_z_index(0)
		c.bg_height = tilemap_bg.get_layer_z_index(0)
		c.light = packed_lights[i]
		c.light.renderer = c
		c.channel = channel
		# descalify it
		c.light_rect = Rect2(light_rect.position / scale, light_rect.size / scale)
	
	finished_packing_channel.emit(packed_lights, channel)
