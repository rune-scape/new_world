#include "rect_pack_2d.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/physics_server2d.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/classes/rigid_body2d.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "../rectpack2D/src/finders_interface.h"

namespace godot {

	Vector2 RectPack2D::pack(Array r_packed_rects, const PackedVector2Array p_rect_sizes, int p_max_side, int p_discard_step) {
		using namespace rectpack2D;

		constexpr bool allow_flip = false;
		const auto runtime_flipping_mode = flipping_option::DISABLED;

		/*
			Here, we choose the "empty_spaces" class that the algorithm will use from now on.

			The first template argument is a bool which determines
			if the algorithm will try to flip rectangles to better fit them.

			The second argument is optional and specifies an allocator for the empty spaces.
			The default one just uses a vector to store the spaces.
			You can also pass a "static_empty_spaces<10000>" which will allocate 10000 spaces on the stack,
			possibly improving performance.
		*/

		using spaces_type = rectpack2D::empty_spaces<allow_flip, default_empty_spaces>;

		/*
			rect_xywh or rect_xywhf (see src/rect_structs.h),
			depending on the value of allow_flip.
		*/

		using rect_type = output_rect_t<spaces_type>;

		/*
			Note:

			The multiple-bin functionality was removed.
			This means that it is now up to you what is to be done with unsuccessful insertions.
			You may initialize another search when this happens.
		*/

		auto report_successful = [](rect_type&) {
			return callback_result::CONTINUE_PACKING;
		};

		auto report_unsuccessful = [](rect_type&) {
			return callback_result::ABORT_PACKING;
		};

		/*
			Initial size for the bin, from which the search begins.
			The result can only be smaller - if it cannot, the algorithm will gracefully fail.
		*/

		/*
			The search stops when the bin was successfully inserted into,
			AND the next candidate bin size differs from the last successful one by *less* then discard_step.

			The best possible granuarity is achieved with discard_step = 1.
			If you pass a negative discard_step, the algoritm will search with even more granularity -
			E.g. with discard_step = -4, the algoritm will behave as if you passed discard_step = 1,
			but it will make as many as 4 attempts to optimize bins down to the single pixel.

			Since discard_step = 0 does not make sense, the algoritm will automatically treat this case
			as if it were passed a discard_step = 1.

			For common applications, a discard_step = 1 or even discard_step = 128
			should yield really good packings while being very performant.
			If you are dealing with very small rectangles specifically,
			it might be a good idea to make this value negative.

			See the algorithm section of README for more information.
		*/

		const auto discard_step = 1;

		/*
			Create some arbitrary rectangles.
			Every subsequent call to the packer library will only read the widths and heights that we now specify,
			and always overwrite the x and y coordinates with calculated results.
		*/

		std::vector<rect_type> rectangles;

		for (Vector2 rsize : p_rect_sizes) {
			rectangles.emplace_back(rect_xywh(-1, -1, rsize.x, rsize.y));
		}

		/*
			Example 1: Find best packing with default orders.

			If you pass no comparators whatsoever,
			the standard collection of 6 orders:
			by area, by perimeter, by bigger side, by width, by height and by "pathological multiplier"
			- will be passed by default.
		*/

		const auto result_size = find_best_packing<spaces_type>(
			rectangles,
			make_finder_input(
				p_max_side,
				p_discard_step,
				report_successful,
				report_unsuccessful,
				runtime_flipping_mode
			)
		);

		r_packed_rects.clear();
		for (const rect_type &rect : rectangles) {
			r_packed_rects.push_back(Rect2i(rect.x, rect.y, rect.w, rect.h));
		}

		return Vector2(result_size.w, result_size.h);
	}

	void RectPack2D::_bind_methods() {
		ClassDB::bind_static_method(get_class_static(), D_METHOD("pack", "r_packed_rects", "p_rect_sizes", "p_max_side", "p_discard_step"), &RectPack2D::pack, DEFVAL(1));
	}
} // namespace godot
