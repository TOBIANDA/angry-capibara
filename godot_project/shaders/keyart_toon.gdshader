shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_boost : hint_range(0.0, 3.0) = 1.05;
uniform vec3 rim_color : source_color = vec3(1.0, 0.84, 0.48);
uniform float rim_strength : hint_range(0.0, 1.5) = 0.34;
uniform float brightness_boost : hint_range(0.5, 1.4) = 0.86;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	// Rim-light tipis tajam hanya di tepi siluet (tidak memutihkan wajah!)
	float rim = smoothstep(0.68, 0.93, 1.0 - ndv) * rim_strength;
	ALBEDO = tex.rgb * tint_color.rgb * brightness_boost;
	ROUGHNESS = 0.78;
	SPECULAR = 0.12;
	EMISSION = (emission_color * emission_boost) + (ALBEDO * 0.05) + (rim_color * rim * 0.65);
}
