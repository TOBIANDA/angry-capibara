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

	// Harmoni gamut woodblock/washi: redam saturasi neon digital berlebih agar selaras palet DESIGN.md
	float lum = dot(base_col, vec3(0.299, 0.587, 0.114));
	float max_c = max(base_col.r, max(base_col.g, base_col.b));
	float min_c = min(base_col.r, min(base_col.g, base_col.b));
	float sat = (max_c > 0.001) ? (max_c - min_c) / max_c : 0.0;
	base_col = mix(base_col, vec3(lum) * vec3(1.02, 0.98, 0.92), smoothstep(0.54, 0.96, sat) * 0.28);

	// Hemisphere AO: bagian bawah membulat ke bayangan netral-hangat (anti cast magenta di awan/putih)
	float hemi = clamp(v_world_normal.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 ao_tint = mix(vec3(0.76, 0.74, 0.76), vec3(1.02, 1.00, 0.98), smoothstep(0.08, 0.88, hemi));

	// Rim light lembut mengikuti warna lokal (bukan putih kapur) & fokus di tepi atas/samping
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim_edge = smoothstep(0.62, 0.93, 1.0 - ndv);
	float rim_top_mask = smoothstep(-0.35, 0.45, v_world_normal.y) * (1.0 - smoothstep(0.85, 0.99, v_world_normal.y) * 0.45);
	vec3 tinted_rim = mix(base_col * 1.10 + vec3(0.02), rim_color, 0.40);
	float rim = rim_edge * rim_top_mask * rim_strength;

	ALBEDO = base_col * ao_tint;
	ROUGHNESS = 0.86;
	EMISSION = emission_color + (tinted_rim * rim * 0.32);
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
