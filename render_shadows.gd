@tool
extends ColorRect

@export var character: Node2D
@export var tilemap_fg: TileMap
@export var tilemap_bg: TileMap

func _process(delta):
	RunePointLight2D.all_lights.sort_custom(
		func(a: RunePointLight2D, b: RunePointLight2D):
			return (a.global_position - character.global_position).length() < (b.global_position - character.global_position).length())
	var lights = RunePointLight2D.all_lights.slice(0, 32)
	
	var source_mat := material as ShaderMaterial
	for vpi in 1:
		var mat: ShaderMaterial = source_mat
		mat.set_shader_parameter(&"fg_height", tilemap_fg.get_layer_z_index(0))
		mat.set_shader_parameter(&"bg_height", tilemap_bg.get_layer_z_index(0))
		for li in 4:
			var light: PointLight2D = lights[vpi*4 + li]
			var uniform_name: StringName = [&"light_pos1", &"light_pos2", &"light_pos3", &"light_pos4"][li]
			mat.set_shader_parameter(uniform_name, Vector3(light.global_position.x, light.global_position.y, light.height))
