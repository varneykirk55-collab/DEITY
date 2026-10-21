shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_always;

uniform vec4 water_color : source_color = vec4(0.10, 0.42, 0.70, 0.88);
uniform vec4 highlight : source_color = vec4(0.55, 0.82, 1.0, 1.0);

void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.35 + TIME * 0.8) * 0.06 + cos(VERTEX.z * 0.28 + TIME * 0.6) * 0.05;
}

void fragment() {
	float n = sin(UV.x * 48.0 + TIME * 0.7) * 0.04 + sin(UV.y * 36.0 - TIME * 0.55) * 0.04;
	ALBEDO = mix(water_color.rgb, highlight.rgb, 0.18 + n);
	ALPHA = water_color.a;
	ROUGHNESS = 0.14;
	METALLIC = 0.22;
}
