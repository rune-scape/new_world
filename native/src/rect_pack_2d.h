#pragma once

#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {
	class RectPack2D : public Object {
		GDCLASS(RectPack2D, Object)

	public:
		static Vector2 pack(Array r_packed_rects, PackedVector2Array p_rect_sizes, int p_max_side, int p_discard_step = 1);

	protected:
		static void _bind_methods();

	public:
		RectPack2D() = default;
		~RectPack2D() = default;
	};
} // namespace godot
