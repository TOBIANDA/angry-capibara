shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;
uniform float brightness_boost : hint_range(0.8, 1.5) = 1.12;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.2) * rim_strength;
	ALBEDO = tex.rgb * tint_color.rgb * brightness_boost;
	ROUGHNESS = 0.65;
	SPECULAR = 0.25;
	EMISSION = emission_color + (ALBEDO * 0.16) + vec3(rim * 0.65);
}
