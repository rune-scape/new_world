shader_type canvas_item;
render_mode unshaded; 

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() { 
    float distance_cut_off = 100.0; //px 
    vec2 at = screen_uv_to_sdf(SCREEN_UV); 
    COLOR.rgb = vec3(texture_sdf(at)/distance_cut_off); 
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
