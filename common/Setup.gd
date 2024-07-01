extends Node

func _ready() -> void:
	var root := get_tree().root
	root.positional_shadow_atlas_size = 0
