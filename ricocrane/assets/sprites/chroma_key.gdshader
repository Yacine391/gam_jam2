shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.3;
uniform float feather   : hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float dist = length(col.rgb - key_color);
	float alpha = smoothstep(threshold - feather, threshold + feather, dist);
	COLOR = vec4(col.rgb, col.a * alpha);
}
