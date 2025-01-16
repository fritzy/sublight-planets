shader_type canvas_item;
uniform sampler2D gas1_texture: repeat_enable;
uniform sampler2D gas2_texture: repeat_enable;
uniform sampler2D zoom_texture: repeat_enable;
uniform sampler2D gas3_texture: repeat_enable;
uniform sampler2D gas4_texture: repeat_enable;

uniform vec3 sun_color: source_color;
uniform vec3 sun_color2: source_color;
uniform vec3 sun_color3: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
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
	p.y += TIME * 0.1;
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
	vec2 uv = UV;
	uv -= vec2(0.5);
	uv *= 1.0 + zoom_tunnel(UV) * 0.45;
	uv += vec2(0.5);

	float sample = texture(gas1_texture, rotate_uv(uv, TIME * 0.1)).r;
	float sample2 = texture(gas2_texture, rotate_uv(uv, TIME * -0.1)).r;
	
	vec3 sun1 = texture(gas3_texture, vec2(UV.x + TIME * 0.05, UV.y)).rgb * sun_color;
	vec3 sun2 = texture(gas4_texture, vec2(UV.x - TIME * 0.05, UV.y)).rgb * sun_color;
	vec3 sun3 = texture(gas3_texture, vec2(UV.x, UV.y + TIME * 0.05)).rgb * sun_color2;
	vec3 sun4 = texture(gas4_texture, vec2(UV.x, UV.y - TIME * 0.05)).rgb * sun_color2;
	vec3 sun_sample = max(sun_color2, (sun1 + sun2 + sun3 + sun4) * 0.8);
	
	float alpha = step(dist, 0.5);
	//alpha = step(0.4, alpha);
	float dropoff = (dist - 0.4) / (0.5 - 0.4);
	dropoff = dropoff * dropoff;
	//float dropoff = smoothstep_min(0.4, 0.5, dist, 0.2);
	float smooth_alpha = 1.0 - dropoff;
	//smooth_alpha *= (zoom1 + zoom2);
	smooth_alpha *= step(0.3, dist);
	smooth_alpha *= smooth_alpha * step(dist, 0.5);
	float area = smooth_alpha * step(smooth_alpha, 0.99) * alpha * (sample * sample2);
	float flames = smooth_alpha * (sample * sample2) * 2.2;

	vec3 sun = sun_sample * step(dist, 0.4);
	sun *= smoothstep_min(0.4, 0.3, dist, 0.3);
	COLOR.rgb = vec3(sun_color3 * flames + sun);	
	//COLOR.rgb = vec3(zoom_tunnel(UV));
	// Called for every pixel the material is visible on.
}

/*
void fragment() { // Get the UV coordinates
	vec2 uv = UV - 0.5;
	vec3 ray_direction = vec3(uv, 1.0);
	float tunnel_radius = 0.5;
	float ray_length = tunnel_radius / length(ray_direction.xy);
	vec3 intersection = ray_direction * ray_length;
	float thea = 1.0 * atan(intersection.y / intersection.x) / PI;
	vec2 p = vec2(thea, intersection.z);
	p.y += TIME;
	float dist = pow(length(uv), 1.5);
	vec4 pixel = texture(gas2_texture, p) * dist;
	COLOR.rgb = pixel.rgb * 2.0;
}
*/

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
