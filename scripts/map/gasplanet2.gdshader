shader_type canvas_item;

uniform sampler2D gas1_texture: repeat_enable;
uniform sampler2D gas2_texture: repeat_enable;
uniform sampler2D gas3_texture: repeat_enable;
uniform sampler2D gas4_texture: repeat_enable;
uniform sampler2D gas_gradient: repeat_enable;
const float repro_rad = 1.57;
uniform float intensity: hint_range(0.001, 0.5) = 0.012;
uniform float planet_radius: hint_range(0.33, 1.0) = 0.77;
uniform vec2 sun_pos = vec2(0.5, 0.5);

vec3 normal_diffuse(vec3 normal, vec2 light_pos, vec2 uv) {
	vec2 lightDir = normalize(light_pos - uv);
	float diff = max(dot(normal.rg, lightDir), 0.0);
	return diff * vec3(1.0, 1.0, 1.0);
}

vec2 calculate_sphere_uv(vec2 uv) {
	float rad = repro_rad * (1.0 / planet_radius);
	vec2 sphere_uv = vec2(rad * (uv.x - 0.5), rad * (uv.y - 0.5));
	sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * rad / PI;
	sphere_uv.y = asin(sphere_uv.y) * rad / PI;
	return sphere_uv;
}

void fragment() {
	//float ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	//vec2 uv = vec2(UV.x * ratio, UV.y);
	vec2 sphere_uv = calculate_sphere_uv(UV);
	float gas_sample1 = texture(gas1_texture, vec2(sphere_uv.x +  TIME * 0.03, sphere_uv.y)).r;
	float gas_sample2 = texture(gas2_texture, vec2(sphere_uv.x + TIME * 0.02, sphere_uv.y)).r;
	float gas_sample3 = texture(gas3_texture, vec2(sphere_uv.x + TIME * 0.005, sphere_uv.y + TIME * 0.05)).r;
	float gas_sample4 = texture(gas4_texture, vec2(sphere_uv.x + TIME * -0.005, sphere_uv.y) - TIME * 0.05).r;
	float sample_area = (gas_sample3 + gas_sample4);
	float sample = (gas_sample1 * 1.0 + gas_sample2 * 1.0 - 1.0)  / 2.0 * intensity * (sample_area + 0.2);
	float dist = distance(UV, vec2(0.5, 0.5));
	float samp_y = (sphere_uv.y + 1.0) / 2.0;
	vec3 band_color = texture(gas_gradient, vec2(samp_y + sample, 0.0)).rgb;
	//band_color -= (gas_sample1 + gas_sample2) / 8.0;
	vec2 light_pos = sun_pos;
	float light_dist = distance(UV, light_pos);

	float planet_shadow = smoothstep((planet_radius * .8), 0.05, light_dist);
	float planet_shine = smoothstep((planet_radius * .20), 0.01, light_dist);
	float alpha = step(dist, planet_radius - 0.26);
	band_color *= planet_shadow;
	//band_color += planet_shine * 0.4;
	// softer edge
	band_color *= smoothstep(0.5, 0.42, dist);

	COLOR.rgb = band_color;
	//COLOR.rgb = vec3(sample_area);
	//COLOR.rgb = vec3(0.5 + (gas_sample1 * 0.5) - (gas_sample2 * 0.5));
	COLOR.a = alpha;
}