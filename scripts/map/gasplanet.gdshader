shader_type canvas_item;

uniform sampler2D gas1_texture: repeat_enable;
uniform sampler2D gas1_normal: repeat_enable;
uniform sampler2D gas2_texture: repeat_enable;
uniform sampler2D gas2_normal: repeat_enable;
uniform sampler2D gas3_texture: repeat_enable;

uniform vec3 cloud_color: source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 cloud_color2: source_color = vec3(0.2, 0.2, 0.8);
uniform vec3 storm_color: source_color = vec3(1.0, 0.0, 0.0);

const float repro_rad = 2.0;

uniform float amplitude: hint_range(0.0, 1.0) = 0.25;
uniform float planet_radius: hint_range(0.33, 1.0) = 0.77;

vec2 calculate_sphere_uv(vec2 uv) {
	float rad = repro_rad * (1.0 / planet_radius);
	vec2 sphere_uv = vec2(rad * (uv.x - 0.5), rad * (uv.y - 0.5));
	sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * rad / PI;
	sphere_uv.y = asin(sphere_uv.y) * rad / PI;
	return sphere_uv;
}

void fragment() {

	float speed = 0.004;
	float cloud_speed = 0.015;
	float storm_speed = 0.02;
	float storm_speed2 = 0.01;

	vec2 sphere_uv = calculate_sphere_uv(UV);
	vec2 cloud_offset = vec2(sphere_uv.x / 4.0 + (cloud_speed * TIME), sphere_uv.y);
	vec2 storm_offset = vec2(sphere_uv.x / 2.2 + (storm_speed * TIME), sphere_uv.y);
	vec2 storm_offset2 = vec2(sphere_uv.x / 2.2 + (storm_speed2 * TIME), sphere_uv.y);

	float center_dist = distance(UV, vec2(0.5, 0.5));
	float planet_alpha = mix(1.0, 0.0, step(planet_radius / 2.0, center_dist));
	vec4 base_color = vec4(1.0, 1.0, 1.0, planet_alpha);

	float light_dist = distance(UV, vec2(0.55, 0.5));

	float planet_shadow = smoothstep((planet_radius * .55), 0.05, light_dist);

	vec3 cloud2_sample = texture(gas2_texture, storm_offset).rgb;
	vec3 cloud3_sample = texture(gas3_texture, storm_offset2).rgb;
	vec3 mixed_storm_sample = (((cloud2_sample + cloud3_sample) / 2.0) - 0.5) * 2.0;

	float up_height = texture(gas2_texture, vec2(storm_offset.x, storm_offset.y - .04)).r;
	float down_height = texture(gas2_texture, vec2(storm_offset.x, storm_offset.y + .04)).r;
	float y_offset = down_height - up_height;

	float eased_storm = 1.0 - cos((mixed_storm_sample.r * PI) / 2.0);
	//eased_storm = mixed_storm_sample.r - 0.5;


	//float show_red = mix(1.0, 0.0, step(0.8, eased_storm / amplitude));
	float show_red  = mix(0.0, 0.75, step(0.1 * (amplitude + 0.0001), abs(eased_storm)* amplitude));
	//eased_storm = mixed_storm_sample.r;

	vec3 cloud1_sample = texture(gas1_texture, vec2(cloud_offset.x, cloud_offset.y + eased_storm * amplitude)).rgb;

	base_color.rgb = mix(
		//cloud1_sample * cloud_color,
		mix(cloud_color, cloud_color2, cloud1_sample),
		storm_color,
		//(abs(eased_storm )) * amplitude * show_red
		show_red * abs(eased_storm * 3.0)
	 ) * planet_shadow * 1.2;

	 //base_color.rgb = mix(cloud_color, cloud_color2, cloud1_sample);
	 //base_color.rgb += storm_color * show_red;

	//float base_clouds = texture(gas1_texture, cloud_offset).r;
	//COLOR.rgb = mix(cloud_color, cloud_color2, base_clouds) * planet_shadow;
	//COLOR.a = planet_alpha;
	COLOR = base_color;
}