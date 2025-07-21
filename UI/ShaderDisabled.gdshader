shader_type canvas_item;

uniform float darkness_strength : hint_range(0.0, 1.0) = 0.5;
uniform bool enabled = false;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    if (enabled) {
        color.rgb = mix(color.rgb, vec3(0.0), darkness_strength);
    }

    COLOR = color;
}