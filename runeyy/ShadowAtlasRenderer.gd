@tool
extends SubViewport

@export var atlas_size: int = 1000
@export var character: Node2D
@export var tilemap_fg: TileMap
@export var tilemap_bg: TileMap

func _ready() -> void:
	var result := []
	var packed_size := RectPack2D.pack(result, [Vector2(1000, 1000)], 1000)
	#print("packed_size: ", packed_size, " result: ", result)

func _process(_delta: float) -> void:
	size = Vector2i(atlas_size, atlas_size)
	var unpacked_lights: Array = get_tree().get_nodes_in_group(RPointLight2D.group_name)
	
	unpacked_lights = unpacked_lights.filter(
		func(a: RPointLight2D):
			return a.visible
	)
	# prioritize lights closer to the character 
	unpacked_lights.sort_custom(
		func(a: RPointLight2D, b: RPointLight2D):
			if a.priority != b.priority:
				return a.priority > b.priority
			else:
				return (a.global_position - character.global_position).length() < (b.global_position - character.global_position).length()
	)
	
	var unpacked_light_rects: Array
	unpacked_light_rects.resize(unpacked_lights.size())
	for i in unpacked_lights.size():
		var rect: Rect2 = unpacked_lights[i].get_rect()
		var rect_snapped: Rect2i
		rect_snapped.position = Vector2i(rect.position.floor())
		rect_snapped.end = Vector2i(rect.end.ceil())
		unpacked_light_rects[i] = rect_snapped
	
	pack_regions_in_channel(unpacked_lights, unpacked_light_rects, $ShadowRegionsR, Color(1, 0, 0, 0.5))
	pack_regions_in_channel(unpacked_lights, unpacked_light_rects, $ShadowRegionsG, Color(0, 1, 0, 0.5))
	pack_regions_in_channel(unpacked_lights, unpacked_light_rects, $ShadowRegionsB, Color(0, 0, 1, 0.5))

func pack_regions_in_channel(unpacked_lights: Array, unpacked_light_rects: Array, regions_parent: Node, channel: Color):
	if unpacked_lights.size() != unpacked_light_rects.size():
		push_error("unpacked_lights.size() != unpacked_region_sizes.size()")
		return
	
	var packed_rects := []
	var _packed_size := RectPack2D.pack(packed_rects, unpacked_light_rects.map(func(r: Rect2i) -> Vector2: return r.size), 1000)
	
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
			n.color = Color.TRANSPARENT
			n.clip_contents = true
			regions_parent.add_child(n)
	elif -size_diff > packed_rects.size()*2:
		for i in -size_diff:
			regions_parent.remove_child(regions_parent.get_child(0))
	
	for i in packed_rects.size():
		var c: ShadowRegionRenderer = regions_parent.get_child(i)
		var rect: Rect2i = packed_rects[i]
		c.position = Vector2(rect.position)
		c.size = Vector2(rect.size)
		c.tilemap_fg = tilemap_fg
		c.tilemap_bg = tilemap_bg
		c.light = packed_lights[i]
		c.channel = channel
		c.light_rect = packed_light_rects[i]
