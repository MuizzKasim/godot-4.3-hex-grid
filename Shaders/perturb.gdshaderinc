vec3 perturb_vertex(vec3 vertex, mat4 model_matrix, sampler2D noise_texture, float noise_scale, float displacement_strength) {
    vec3 world_pos = (model_matrix * vec4(vertex, 1.0)).xyz;
    vec2 uv = world_pos.xz * noise_scale;
    float noise_value = texture(noise_texture, uv).r;
	float perturb = noise_value * displacement_strength * 2.0 -1.0;
    vertex.xz += perturb;

    return vertex;
}
