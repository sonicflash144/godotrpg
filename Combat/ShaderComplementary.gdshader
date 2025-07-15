shader_type canvas_item;
uniform bool active = false;

void fragment() {
	vec4 previous_color = texture(TEXTURE, UV);
	vec4 new_color = previous_color;
	if (active == true) {
		new_color.rgb = vec3(1.0) - previous_color.rgb;
	}
	COLOR = new_color;
}