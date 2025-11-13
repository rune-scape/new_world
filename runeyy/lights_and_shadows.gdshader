shader_type canvas_item;
render_mode unshaded;

const int MAX_LIGHT_COUNT = 64; // MUST BE SYNCHRONIZED WITH SCRIPT ShadowDrawTest.gd
const int MAX_BLUR_SAMPLE_COUNT = 256; // MUST BE SYNCHRONIZED WITH SCRIPT ShadowDrawTest.gd
const float MAX_BLUR = pow(2.0, 8.0) - 1.0; // MUST BE SYNCHRONIZED WITH SCRIPT ShadowRegionRenderer.gd

uniform sampler2D shadow_atlas: filter_linear_mipmap;

uniform int light_count;
uniform float shadow_atlas_scale;
uniform vec2 shadow_atlas_positions[MAX_LIGHT_COUNT];
uniform vec4 shadow_channels[MAX_LIGHT_COUNT];
uniform vec4 shadow_screen_rects[MAX_LIGHT_COUNT];
uniform vec3 light_positions[MAX_LIGHT_COUNT];

uniform int blur_sample_count;
uniform vec3 blur_samples[MAX_BLUR_SAMPLE_COUNT];
uniform float gaussian_sum;

void vertex() {
	
}

bool is_in_rect(vec2 pos, vec4 rect) {
	return pos.x >= rect.x && pos.y >= rect.y && pos.x <= rect.z && pos.y <= rect.w;
}

float get_channel_value(vec4 color, vec4 channel) {
	vec4 v = color * channel;
	return v.x + v.y + v.z + v.w;
}

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}

// Pseudo-random value in half-open range [0:1].
float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random2to1( vec2 v ) { return floatConstruct(hash(floatBitsToUint(v.x) ^ floatBitsToUint(v.y))); }
vec2 random2( vec2  v ) {
	return vec2(
		floatConstruct(hash(floatBitsToUint(v.x))),
		floatConstruct(hash(floatBitsToUint(v.y)))
	);
}

void fragment() {
	float pixel_randf = random2to1(SCREEN_UV);
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 screen_pixel = SCREEN_UV * screen_size;
	vec2 shadow_atlas_size = vec2(textureSize(shadow_atlas, 0));
	vec2 shadow_atlas_pixel_size = 1.0 / shadow_atlas_size;
	int real_light_count = min(light_count, MAX_LIGHT_COUNT);
	int real_blur_sample_count = min(blur_sample_count, MAX_BLUR_SAMPLE_COUNT);
	
	float light = 0.0;
	for (int i = 0; i < real_light_count; i++) {
		vec4 shadow_screen_rect = shadow_screen_rects[i];
		if (!is_in_rect(screen_pixel, shadow_screen_rect)) {
			continue;
		}
		vec2 shadow_atlas_pos = shadow_atlas_positions[i];
		vec4 shadow_channel = shadow_channels[i];
		vec3 light_position = light_positions[i];
		vec2 light_size = (shadow_screen_rect.zw - shadow_screen_rect.xy) * 0.5;
		vec2 shadow_atlas_pixel = shadow_atlas_pos + ((screen_pixel - shadow_screen_rect.xy) * shadow_atlas_scale);
		vec2 shadow_atlas_uv = shadow_atlas_pixel * shadow_atlas_pixel_size;
		
		light += 1.0 / (pow(length((screen_pixel - light_position.xy) / light_size * 2.0), 5.0) + 1.0);
		float shadow_v = get_channel_value(texture(shadow_atlas, shadow_atlas_uv), shadow_channel);
		//if (shadow_v == 0.0) {
			//continue;
		//} else {
			//light -= fract(shadow_v);
			//continue;
		//}
		float blur_radius = shadow_v == 0.0 ? MAX_BLUR : (shadow_v * MAX_BLUR - 1.0);
		//blur_radius = pow(blur_radius, 1.5);
		//light -= fract((1.0 - shadow_v) * MAX_BLUR);
		//continue;
		//vec2 blur_radius = 5.0 * shadow_atlas_pixel_size;
		float search_dist = clamp(blur_radius, 0.0, 10.0);
		//float search_dist = 10.0;
		float shadow_accum = 0.0;
		//vec2 blur_sample_source = vec2(SCREEN_UV.x + TIME, SCREEN_UV.y + random(TIME));
		for (int s = 0; s < real_blur_sample_count; s++) {
		//for (int x = 0; x < 11; x++) {
		//for (int y = 0; y < 11; y++) {
			//blur_sample_source = random2(blur_sample_source);
			//float blur_sample_theta = blur_sample_source.x * PI * 2.0;
			//float blur_sample_len = blur_sample_source.y;
			//vec2 blur_sample = vec2(cos(blur_sample_theta), sin(blur_sample_theta)) * blur_sample_len;
			vec2 blur_sample = blur_samples[s].xy;
			//vec3 blur_sample = vec3(float(x-4), float(y-4), 0.0) / 5.0;
			float th = floor(pixel_randf * 16.0) / 16.0 * 2.0 * TAU;
			float s = sin(th);
			float c = cos(th);
			blur_sample.xy = mat2(
				vec2(c, -s),
				vec2(s, c)
			) * blur_sample.xy;
			//blur_sample.z = exp(-2.0 * blur_sample.x * blur_sample.x + -2.0 * blur_sample.y * blur_sample.y) / 15.0;
			vec2 blur_sample_ofs = blur_sample.xy * search_dist;
			vec2 blur_sample_uv_ofs = blur_sample_ofs * shadow_atlas_pixel_size;
			float shadow_v = get_channel_value(texture(shadow_atlas, shadow_atlas_uv + blur_sample_uv_ofs * shadow_atlas_scale), shadow_channel);
			//if (shadow_v == 0.0) {
			//	continue;
			//}
			float sample_dist_sq = blur_sample_ofs.x * blur_sample_ofs.x + blur_sample_ofs.y * blur_sample_ofs.y;
			float sblur_radius = shadow_v * MAX_BLUR - 1.0;
			//if () {}
			shadow_accum += sblur_radius;
			
			//float sblur_radius_sq = sblur_radius * sblur_radius;
			//if (sample_dist_sq <= sblur_radius_sq) {
				//float gausian_dist_sq = sample_dist_sq / sblur_radius_sq;
				//float gausian_kernel = exp(-gausian_dist_sq);
				//shadow_accum += gausian_kernel;
			//	shadow_accum += (sblur_radius / search_dist);
			//}
		//}
		//}
		}
		light -= pow(max(shadow_accum, 0.0) / float(real_blur_sample_count) / search_dist, 0.4);
	}
	//light = pow(light, 3.5);
	COLOR = vec4(light, light, light, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
