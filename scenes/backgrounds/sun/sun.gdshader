shader_type canvas_item;
uniform sampler2D gas1_texture: repeat_enable;
uniform sampler2D gas2_texture: repeat_enable;
uniform sampler2D zoom_texture: repeat_enable;
uniform sampler2D gas3_texture: repeat_enable;
uniform sampler2D gas4_texture: repeat_enable;

uniform vec3 sun_color: source_color = vec3(1.0, 0.87, 0.03);
uniform vec3 sun_color2: source_color = vec3(0.85, 0.11, 0.1);
//uniform vec3 sun_color3: source_color;
uniform float flame_brightness: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float flame_warp: hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float flame_warp_speed: hint_range(0.0, 0.5, 0.001) = 0.1;
uniform float flame_merge_speed: hint_range(0.0, 0.5, 0.001) = 0.1;
uniform float core_merge_speed: hint_range(0.0, 0.2, 0.001) = 0.05;

vec2 calculate_sphere_uv(vec2 uv) {
	float rad = 0.9 * (1.0 / 0.5);
	vec2 sphere_uv = vec2(rad * (uv.x - 0.5), rad * (uv.y - 0.5));
	sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * rad / PI;
	sphere_uv.y = asin(sphere_uv.y) * rad / PI;
	return sphere_uv;
}

vec2 rotate_uv(vec2 uv, float angle) {
	uv -= vec2(0.5);
	uv *= mat2(
		vec2(cos(angle), -sin(angle)),
		vec2(sin(angle), cos(angle))
	);
	uv += vec2(0.5);
	return uv;
}
float exponential_smoothstep(float edge0, float edge1, float x, float exponent) {
    // Clamp the input value
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);

    // Apply the exponential dropoff
    return pow(x, exponent) * (3.0 - 2.0 * pow(x, exponent));
}

float zoom_tunnel(vec2 uv) {
	uv -= 0.5;
	vec3 ray_direction = vec3(uv, 1.0);
	float tunnel_radius = 0.2;
	float ray_length = tunnel_radius / length(ray_direction.xy);
	vec3 intersection = ray_direction * ray_length;
	float thea = 1.0 * atan(intersection.y / intersection.x) / PI;
	vec2 p = vec2(thea, intersection.z);
	p.y += TIME * flame_warp_speed;
	float dist = pow(length(uv), 0.5);
	return texture(zoom_texture, p).r * dist;
}

float smoothstep_min(float edge0, float edge1, float x, float min_val) {
    // Perform smoothstep calculation
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    float smooth_value = t * t * (3.0 - 2.0 * t);

    // Scale the smoothstep result to the desired minimum value
    return smooth_value * (1.0 - min_val) + min_val;
}

void fragment() {
	float dist = distance(UV, vec2(0.5, 0.5));
	//vec2 uv = calculate_sphere_uv(UV);
	vec2 uv = vec2(UV);
	uv -= vec2(0.5);
	uv *= 1.0 + zoom_tunnel(UV) * flame_warp;
	uv += vec2(0.5);

	float sample = texture(gas1_texture, rotate_uv(uv, TIME * flame_merge_speed)).r;
	float sample2 = texture(gas2_texture, rotate_uv(uv, TIME * -flame_merge_speed)).r;

	vec2 sun_uv = calculate_sphere_uv(UV);
	//vec2 sun_uv = UV;
	vec3 sun1 = texture(gas3_texture, vec2(sun_uv.x + TIME * core_merge_speed, sun_uv.y)).rgb * sun_color;
	vec3 sun2 = texture(gas4_texture, vec2(sun_uv.x - TIME * core_merge_speed, sun_uv.y)).rgb * sun_color;
	vec3 sun3 = texture(gas3_texture, vec2(sun_uv.x, sun_uv.y + TIME * core_merge_speed)).rgb * sun_color2;
	vec3 sun4 = texture(gas4_texture, vec2(sun_uv.x, sun_uv.y - TIME * core_merge_speed)).rgb * sun_color2;
	float brightness = texture(gas4_texture, vec2(0.5, TIME * 0.08)).r;
	vec3 sun_sample = max(sun_color * 0.1, ((sun1 + sun2) + (sun3 + sun4)) * 0.8);

	float alpha = step(dist, 0.5);
	//alpha = step(0.4, alpha);
	float dropoff = (dist - 0.4) / (0.5 - 0.4);
	dropoff = dropoff * dropoff * 1.3;
	//dropoff = smoothstep(0.0, 1.0, dropoff);
	//float dropoff = smoothstep_min(0.4, 0.5, dist, 0.2);
	float smooth_alpha = 1.0 - dropoff;
	smooth_alpha -= sun1.r + sun2.r * 0.3;
	smooth_alpha = clamp(0.0, 1.0, smooth_alpha);
	//smooth_alpha *= (zoom1 + zoom2);
	smooth_alpha *= step(0.3, dist);
	smooth_alpha *= smooth_alpha * step(dist, 0.5);
	float area = smooth_alpha * step(smooth_alpha, 0.99) * alpha * (sample * sample2);
	float flames = smooth_alpha * (sample) * 6.2;
	flames *= (sample2);

	vec3 sun = sun_sample * smoothstep(0.4, 0.38, dist);
	sun *= smoothstep_min(0.4, 0.3, dist, 0.3);
	COLOR.rgb = vec3((sun_color2 + sun_color) * flame_brightness * flames + sun);
	COLOR.rgb *= 0.7 + brightness * 0.3;
	COLOR.a = clamp(sun.r + sun.g + sun.b + flames + smooth_alpha, 0.0, 1.0);

}
