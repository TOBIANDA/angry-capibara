shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.55;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv * vec2(1.18, 1.0));
	float v = smoothstep(0.45, 0.45 + vignette_softness, dist);
	COLOR = vec4(0.01, 0.02, 0.07, v * vignette_strength);
}
