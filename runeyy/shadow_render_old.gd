@tool
extends ColorRect

@export var character: Node2D
@export var tilemap_fg: TileMap
@export var tilemap_bg: TileMap

func _process(delta):
	var all_lights := get_tree().get_nodes_in_group(RunePointLight2D.group_name)
	# prioritize lights closer to the character 
	all_lights.sort_custom(
		func(a: RunePointLight2D, b: RunePointLight2D):
			if a.priority == b.priority:
				return (a.global_position - character.global_position).length() < (b.global_position - character.global_position).length()
			else:
				return a.priority > b.priority
	)
	var lights = all_lights.slice(0, 32)
	
	var source_mat := material as ShaderMaterial
	for vpi in 1:
		var mat: ShaderMaterial = source_mat
		mat.set_shader_parameter(&"fg_height", tilemap_fg.get_layer_z_index(0))
		mat.set_shader_parameter(&"bg_height", tilemap_bg.get_layer_z_index(0))
		for li in 4:
			var light: PointLight2D = lights[vpi*4 + li]
			var uniform_name: StringName = [&"light_pos1", &"light_pos2", &"light_pos3", &"light_pos4"][li]
			mat.set_shader_parameter(uniform_name, Vector3(light.global_position.x, light.global_position.y, light.height))
