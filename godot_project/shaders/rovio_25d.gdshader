shader_type spatial;
render_mode specular_disabled;

// Shader 2.5D Painterly Lineless ala Rovio Angry Birds 2:
// - Tanpa garis luar hitam spidol (100% lineless, siluet tajam dari rim light & bentuk volumetrik)
// - Bayangan geser ke ungu-plum hangat (menjaga merah crimson & krem tetap pekat, anti pucat/peach)
// - Ambient occlusion hemisfer atas-bawah + kilau kuas (painterly sheen) lembut.

uniform sampler2D albedo_tex : source_color, hint_default_white, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform vec3 shadow_tint : source_color = vec3(0.42, 0.34, 0.48);
uniform vec3 lit_tint : source_color = vec3(1.00, 0.96, 0.90);
uniform vec3 rim_color : source_color = vec3(1.0, 0.82, 0.44);
uniform float rim_strength : hint_range(0.0, 1.2) = 0.32;
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.16;
uniform vec2 uv_scale = vec2(1.0, 1.0);

varying vec3 v_world_normal;

void vertex() {
	v_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV * uv_scale);
	vec3 base_col = tex.rgb * tint_color.rgb;

	// Hemisphere AO: bagian bawah membulat ke bayangan lembut, bagian atas bersih
	float hemi = clamp(v_world_normal.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 ao_tint = mix(vec3(0.68, 0.62, 0.74), vec3(1.03, 1.01, 0.99), smoothstep(0.08, 0.88, hemi));

	// Rim light lembut mengikuti warna lokal (bukan putih kapur) & fokus di tepi atas/samping
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim_edge = smoothstep(0.56, 0.90, 1.0 - ndv);
	float rim_top_mask = smoothstep(-0.35, 0.45, v_world_normal.y);
	vec3 tinted_rim = mix(base_col * 1.45 + vec3(0.06), rim_color, 0.45);
	float rim = rim_edge * rim_top_mask * rim_strength;

	ALBEDO = base_col * ao_tint;
	ROUGHNESS = 0.86;
	EMISSION = emission_color + (tinted_rim * rim * 0.46);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float atten_ndl = ndl * ATTENUATION;

	// Campuran wrap volumetrik lembut + terminator sapuan kuas painterly
	float soft_wrap = smoothstep(-0.32, 0.68, atten_ndl);
	float crisp_band = smoothstep(0.00, 0.24, atten_ndl);
	float shade_factor = mix(soft_wrap, crisp_band, 0.46);

	vec3 shade = mix(shadow_tint, lit_tint, shade_factor);

	// Kilau clay/bulu halus (painterly specular) tanpa bikin warna washout
	vec3 half_v = normalize(LIGHT + VIEW);
	float spec = pow(max(dot(NORMAL, half_v), 0.0), 14.0) * smoothstep(0.05, 0.30, atten_ndl);
	vec3 spec_col = mix(ALBEDO * 1.2, vec3(1.0, 0.95, 0.84), 0.45) * spec * sheen_strength;

	DIFFUSE_LIGHT += (ALBEDO * shade + spec_col) * LIGHT_COLOR * 0.84;
}
