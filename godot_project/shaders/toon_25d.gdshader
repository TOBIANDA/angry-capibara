shader_type spatial;
render_mode specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform vec3 shadow_tint : source_color = vec3(0.46, 0.44, 0.58);
uniform vec3 lit_tint : source_color = vec3(0.96, 0.92, 0.86);
uniform vec3 rim_color : source_color = vec3(1.0, 0.80, 0.42);
uniform float rim_strength : hint_range(0.0, 1.2) = 0.28;
uniform vec2 uv_scale = vec2(1.0, 1.0);

void fragment() {
	vec4 tex = texture(albedo_tex, UV * uv_scale);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = smoothstep(0.68, 0.92, 1.0 - ndv) * rim_strength;
	ALBEDO = tex.rgb * tint_color.rgb;
	ROUGHNESS = 0.92;
	EMISSION = emission_color + (rim_color * rim * 0.42);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// 2-band cel-shading ala ilustrasi 2.5D (hangat tanpa overexpose, bayangan ungu-teal lembut)
	float band = smoothstep(0.05, 0.16, ndl * ATTENUATION);
	float hi = smoothstep(0.72, 0.82, ndl * ATTENUATION) * 0.08;
	vec3 shade = mix(shadow_tint, lit_tint, band) + vec3(hi);
	DIFFUSE_LIGHT += ALBEDO * shade * LIGHT_COLOR * 0.76;
}
