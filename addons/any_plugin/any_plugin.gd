@tool
class_name AnyPlugin extends EditorPlugin

static var _inst: EditorPlugin

static func get_instance() -> EditorPlugin:
	return _inst

func _enter_tree() -> void:
	if _inst != null:
		push_error("whoa 2 selves")
		return
	_inst = self

func _exit_tree() -> void:
	if _inst == self:
		_inst = null
