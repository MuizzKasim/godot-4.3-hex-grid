shader_type spatial;

#include "res://Shaders/perturb.gdshaderinc"

uniform sampler2D noise_texture; 
uniform float noise_scale = 1.0;          
uniform float displacement_strength = 0.5;   

void vertex() {
    VERTEX = perturb_vertex(VERTEX, MODEL_MATRIX, noise_texture, noise_scale, displacement_strength);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
