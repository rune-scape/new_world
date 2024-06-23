shader_type canvas_item;
render_mode unshaded;

uniform float fg_height;
uniform float bg_height;
uniform vec3 light_pos1;
uniform vec3 light_pos2;
uniform vec3 light_pos3;
uniform vec3 light_pos4;
uniform sampler2D level_tex: filter_linear;

void vertex() {
	// Called for every vertex the material is visible on.
}

float get_shadow(vec2 screen_uv, vec2 screen_pixel_size, vec3 light_pos) {
	vec2 screen_pixel = screen_uv / screen_pixel_size;
	vec3 vec_to_bg = vec3(screen_pixel, bg_height) - light_pos;
	vec3 vec_to_fg = vec_to_bg / (bg_height - light_pos.z) * (fg_height - light_pos.z);
	vec3 fg_pos = (vec_to_fg + light_pos);
	vec2 fg_uv = fg_pos.xy * screen_pixel_size;
	vec3 shadow_dir = normalize(vec_to_bg);
	float shadow_length = min(length(vec_to_bg - vec_to_fg), 8.0);
	float result = texture(level_tex, fg_uv).a;
	const float max_iterations = 100.0;
	const float step_resolution = 10.0;
	float iterations = shadow_length * step_resolution;
	vec3 shadow_dir_step = shadow_dir / step_resolution;
	for (float i = 1.0; i < iterations && i < max_iterations; i++) {
		result = max(result, texture(level_tex, (fg_pos + i * shadow_dir_step).xy * screen_pixel_size).a);
	}
	return result;
}

void fragment() {
	COLOR.rgb = vec3(0.0);
	COLOR.r = get_shadow(SCREEN_UV, SCREEN_PIXEL_SIZE, light_pos1);
	COLOR.g = get_shadow(SCREEN_UV, SCREEN_PIXEL_SIZE, light_pos2);
	COLOR.b = get_shadow(SCREEN_UV, SCREEN_PIXEL_SIZE, light_pos3);
	//COLOR.a = get_shadow(SCREEN_UV, SCREEN_PIXEL_SIZE, light_pos4);
	COLOR.a = length(COLOR.rgb);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
