@tool
extends Node2D

@export var light: RPointLight2D

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if light != null and light.renderer != null:
		global_position = light.renderer.light_pos
		var tex := ShadowAtlasRenderer.get_texture()
		var region := light.renderer.get_rect()
		draw_texture_rect_region(tex, Rect2(-region.size/2.0, region.size), region)
