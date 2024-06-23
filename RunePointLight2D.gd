@tool
class_name RunePointLight2D extends PointLight2D

static var all_lights: Array[RunePointLight2D]

when visibility_changed:
	if visible:
		if not all_lights.has(self):
			all_lights.push_back(self)
	else:
		if all_lights.has(self):
			all_lights.erase(self)

func _exit_tree() -> void:
	all_lights.erase(self)
