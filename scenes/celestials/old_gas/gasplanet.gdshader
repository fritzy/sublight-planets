shader_type canvas_item;

uniform sampler2D gas1_texture: repeat_enable;
uniform sampler2D gas1_normal: repeat_enable;
uniform sampler2D gas2_texture: repeat_enable;
uniform sampler2D gas2_normal: repeat_enable;
uniform sampler2D gas3_texture: repeat_enable;
uniform sampler2D ring1_texture: repeat_enable;
uniform sampler2D ring2_texture: repeat_enable;
uniform sampler2D ring3_texture: repeat_enable;

uniform vec3 cloud_color: source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 cloud_color2: source_color = vec3(0.2, 0.2, 0.8);
uniform vec3 storm_color: source_color = vec3(1.0, 0.0, 0.0);
uniform vec4 ring1_color: source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 ring2_color: source_color = vec4(1.0, 0.0, 0.0, 1.0);

const float repro_rad = 2.0;

uniform float amplitude: hint_range(0.0, 1.0) = 0.25;
uniform float planet_radius: hint_range(0.33, 1.0) = 0.77;

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

	float speed = 0.004;
	float cloud_speed = 0.030;
	float storm_speed = 0.02;
	float storm_speed2 = 0.01;

	vec2 sphere_uv = calculate_sphere_uv(UV);
	sphere_uv /= SCREEN_PIXEL_SIZE;
	sphere_uv *= 1.0 / 1024.0;
	vec2 cloud_offset = vec2(sphere_uv.x / 4.0 + (cloud_speed * TIME), sphere_uv.y);
	vec2 storm_offset = vec2(sphere_uv.x / 2.2 + (storm_speed * TIME), sphere_uv.y);
	vec2 storm_offset2 = vec2(sphere_uv.x / 2.2 + (storm_speed2 * TIME), sphere_uv.y);

	float center_dist = distance(UV, vec2(0.5, 0.5));
	float planet_alpha = mix(1.0, 0.0, step(planet_radius / 2.0, center_dist));
	vec4 base_color = vec4(1.0, 1.0, 1.0, planet_alpha);

	vec2 light_pos = vec2(0.55, 0.5);
	float light_dist = distance(UV, light_pos);

	float planet_shadow = smoothstep((planet_radius * .55), 0.05, light_dist);
	float planet_shine = smoothstep((planet_radius * .20), 0.01, light_dist);

	vec3 cloud2_sample = texture(gas2_texture, storm_offset).rgb;
	vec3 cloud3_sample = texture(gas3_texture, storm_offset2).rgb;
	vec3 mixed_storm_sample = (((cloud2_sample + cloud3_sample) / 2.0) - 0.5) * 2.0;

	float up_height = texture(gas1_texture, vec2(storm_offset.x, storm_offset.y - .04)).r;
	float down_height = texture(gas2_texture, vec2(storm_offset.x, storm_offset.y + .04)).r;
	float y_offset = (down_height - up_height) * 0.5;

	float eased_storm = 1.0 - cos((mixed_storm_sample.r * PI) / 2.0);
	//eased_storm = mixed_storm_sample.r - 0.5;


	//float show_red = mix(1.0, 0.0, step(0.8, eased_storm / amplitude));
	float show_red  = mix(0.0, 0.75, step(0.1 * (amplitude + 0.0001), abs(eased_storm)* amplitude));
	//eased_storm = mixed_storm_sample.r;

	vec3 cloud1_sample = texture(gas1_texture, vec2(cloud_offset.x, cloud_offset.y + (y_offset) * amplitude)).rgb;

	base_color.rgb = mix(
		//cloud1_sample * cloud_color,
		mix(cloud_color, cloud_color2, cloud1_sample),
		storm_color,
		//show_red * abs(eased_storm * 3.0)
		0.0
	 ) * planet_shadow * 1.2;
	 base_color.rgb += planet_shine * 0.4;

	vec2 center = vec2(0.5, 0.5);
	float outer_radius = 0.5;
	float yscale = 3.0;
	float inner_radius = (planet_radius / 2.0) + 0.085;
	float perspective_factor = 0.33;
    float distance_from_center = length((UV - center) * vec2(1.0, yscale));
	float ring_bounds = 1.0;

    float perspective = mix(1.0, perspective_factor, UV.y - 0.5);

    if (distance_from_center < inner_radius || distance_from_center > outer_radius / perspective) {
		ring_bounds = 0.0;
    }
	float lower = mix(0.0, 1.0, step(0.5, UV.y));


	vec2 uv = UV;


    // Convert to polar coordinates
    vec2 centered_uv = uv - vec2(0.5);
	centered_uv.y *= 3.0;
    float radius = length(centered_uv);
    float angle1 = atan(centered_uv.y, centered_uv.x);
    float angle2 = atan(centered_uv.y, centered_uv.x);
    float angle3 = atan(centered_uv.y, centered_uv.x);

    // Rotate by the time-based rotation speed
    angle1 += TIME * -0.005;
    vec2 circular_uv1 = vec2(angle1 / (2.0 * PI), radius);
	circular_uv1.y *= 2.0;

    angle2 += TIME * -0.01;
    vec2 circular_uv2 = vec2(angle2 / (2.0 * PI), radius);
	circular_uv2.y *= 1.0;

    angle3 += TIME * -0.02;
    vec2 circular_uv3 = vec2(angle3 / (2.0 * PI), radius);
	circular_uv3.y *= 2.0;

    // Sample the texture using the circular UVs
    vec4 ring1_sample = texture(ring1_texture, circular_uv1);
    vec4 ring2_sample = texture(ring2_texture, circular_uv2);
	vec2 nuv = circular_uv3;
    vec3 ring3_norm = texture(ring3_texture, vec2(nuv.x + 0.2 + 0.01 * TIME, nuv.y)).rgb;
    vec3 ring4_norm = texture(ring3_texture, vec2(nuv.x - 0.01 * TIME, nuv.y)).rgb;
	ring1_sample.a = ring_bounds;
	ring2_sample.a = ring_bounds;

	ring3_norm = ring3_norm * 2.0 - 1.0;
	ring4_norm = ring4_norm * 2.0 - 1.0;
	vec3 ring_norm = vec3(ring3_norm.x + ring4_norm.x, ring3_norm.y + ring4_norm.y, max(ring3_norm.z, ring4_norm.z));
	ring_norm = normalize(ring_norm);
	ring_norm = ring_norm * 0.5 + 0.5;


	vec2 ring_light_pos = vec2(light_pos);
	ring_light_pos.x *= 1.17;
	ring_light_pos.y += 0.34;
	vec3 ring_diffuse = normal_diffuse(ring_norm.rgb, ring_light_pos * 8.0, circular_uv3);
	float ring_light_dist = distance(UV, ring_light_pos);
	float ring_shadow = smoothstep(0.75, 0.05, ring_light_dist);
	float ring_shine = smoothstep(0.45, 0.05, ring_light_dist);

	float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453 + TIME * 0.001);
	vec4 ring_total = mix(ring1_color, ring2_color, ring2_sample) * ring_diffuse.r * ring_shadow * 1.5
		+ mix(0.0, ring_diffuse.r * ring_shine * 0.3 * step(0.2, noise), step(0.85, ring_diffuse.r));
	ring_total += ring_shine * 0.3;
	//ring_total += 4.0 * step(0.95, noise);

	float mix_sample = texture(gas1_texture, vec2(0.5, circular_uv2.y * 8.0)).r * 1.8;
	ring_total.a = ring_bounds;

	base_color = mix(base_color, ring_total, ring_bounds * mix_sample * max(lower, (1.0 - planet_alpha)));

	COLOR = base_color;
	//COLOR.rgb = vec3(ring_shadow);
}