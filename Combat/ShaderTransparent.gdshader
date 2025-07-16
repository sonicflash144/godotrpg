shader_type canvas_item;

uniform int effect_type = 0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 final_color = base_color;

	if (effect_type == 1) {
		// Fully transparent
		final_color = vec4(1.0, 1.0, 1.0, 0.0);
	} else if (effect_type == 2) {
		// Semi-transparent
		final_color.a = base_color.a * 0.5;
	}

	COLOR = final_color;
}
