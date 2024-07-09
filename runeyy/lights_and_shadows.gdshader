shader_type canvas_item;

const int MAX_LIGHT_COUNT = 64;

uniform sampler2D shadow_atlas;

uniform int light_count;
uniform vec4 shadow_rects[MAX_LIGHT_COUNT];
uniform vec4 shadow_channels[MAX_LIGHT_COUNT];
uniform vec2 shadow_light_positions[MAX_LIGHT_COUNT];
uniform vec3 light_positions[MAX_LIGHT_COUNT];

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	int real_light_count = min(light_count, MAX_LIGHT_COUNT);
	for (int i = 0; i < real_light_count; i++) {
		vec4 shadow_rect = shadow_rects[i];
		vec4 shadow_channel = shadow_channels[i];
		vec2 shadow_light_position = shadow_light_positions[i];
		vec3 light_position = light_positions[i];
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
