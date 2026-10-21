shader_type spatial;
render_mode unshaded, specular_disabled;

void fragment() {
	float t = TIME * 1.4;
	float n = sin(UV.x * 18.0 + t) * 0.5 + 0.5;
	n *= sin(UV.y * 14.0 - t * 0.7) * 0.5 + 0.5;
	vec3 a = vec3(0.85, 0.22, 0.04);
	vec3 b = vec3(1.0, 0.72, 0.12);
	ALBEDO = mix(a, b, n);
	EMISSION = ALBEDO * 2.4;
}
