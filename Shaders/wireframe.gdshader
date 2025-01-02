shader_type spatial;
render_mode unshaded, wireframe, cull_disabled;

#include "res://Shaders/perturb.gdshaderinc"

uniform sampler2D noise_texture; 
uniform float noise_scale = 1.0;            
uniform float displacement_strength = 0.5;    
uniform vec4 albedo : source_color = vec4(0.0,0.0,0.0,1.0);

void vertex() {
	VERTEX = perturb_vertex(VERTEX, MODEL_MATRIX, noise_texture, noise_scale, displacement_strength);
}

void fragment() {
	ALBEDO = albedo.rgb;
}
