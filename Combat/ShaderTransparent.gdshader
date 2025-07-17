shader_type canvas_item;
uniform int effect_type = 0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 final_color = base_color;

	if (effect_type == 1) {
		// Fully transparent
		final_color = vec4(1.0, 1.0, 1.0, 0.0);
	} 
	else if (effect_type == 2) {
		// Semi-transparent
		final_color.a = base_color.a * 0.5;
	} 
	else if (effect_type == 3) {
		vec3 glow_color = vec3(1.0); // White glow
		float luminance = dot(base_color.rgb, vec3(0.299, 0.587, 0.114)); // Perceived brightness
		float glow_strength = smoothstep(0.2, 0.8, luminance); // Only glow brighter areas
		final_color.rgb = base_color.rgb + glow_color * glow_strength * 0.5;
		final_color.rgb = clamp(final_color.rgb, 0.0, 1.0);
		final_color.a = base_color.a;
	}

	COLOR = final_color;
}