shader_type canvas_item;
render_mode unshaded;

uniform sampler2D crater1_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D crater1_normal: repeat_enable, filter_linear_mipmap;
uniform sampler2D surface_intensity: repeat_enable;
uniform sampler2D light_gradient;

uniform float axis: hint_range(-1.571, 1.571) = 0.0;
uniform float orbit: hint_range(-1.571, 3.14) = 0.0;

const float repro_rad = 2.0;
const float polar_pinch = 1.0;
const float norm_rad = 1.0;

// get the normal as if the pixel (uv) were on a sphere
// we could just use a sphere normal texture, but this is precise
vec3 get_globe_normal(vec2 uv, float radius) {
	uv = uv * radius * 2.0 - radius;
	// see SBOM file
	float z = sqrt(1.0 - (pow(uv.x, 2.0) + pow(uv.y, 2.0) ));
	return  vec3(uv.x, uv.y, z);
}

// warp the uv (and thus the texture samples) to make them look like they're on a sphere
vec2 calculate_sphere_uv(vec2 uv, vec2 ratio) {
	// center the uv from -0.5 to 0.5
	// for polar coordinates
	vec2 sphere_uv = uv - 0.5;
	// scale by our radius
	sphere_uv *= repro_rad;
	// our radius ratio
	float radius_ratio = repro_rad / PI;
	// warp our xy
	// zoom our x based on our y, pinched at the extremes
	sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y * polar_pinch)) * radius_ratio;
	// pretty simple stretch of the y coordinate based on asin
	sphere_uv.y = asin(sphere_uv.y) * radius_ratio;
	// Scale the UV coordinates by the texture ratio
	sphere_uv *= 0.5 / ratio;
	// non-polar coordinates
	sphere_uv += 0.5;
	return sphere_uv;
}

// generate a rotational matrix based on a vector
// in this case, we're using it to place other nomrals on top of the globe normal
// https://en.wikipedia.org/wiki/Rotation_matrix
mat3 create_transformation_matrix(vec3 facing) {
	vec3 up = normalize(vec3(0.0, 1.0, 0.0));
	vec3 right = normalize(cross(up, facing));
	// -facing for opengl style vs directx
	vec3 new_up = cross(-facing, right);
	return mat3(
		vec3(right),
		vec3(new_up),
		vec3(facing)
	);
}

// used for taking things like mountain normals and placing them
// on "top" of the sphere normal of the globe, rotating it
vec3 parent_normals(vec3 parent_facing, vec3 child_facing) {
	child_facing = normalize(child_facing - vec3(0.5));
	mat3 transformation_matrix = create_transformation_matrix(parent_facing);
	vec3 global_facing = transformation_matrix * child_facing;
	return normalize(global_facing);
}

// clamp the length of a vector by scaling it down
vec2 clamp_vector_length(vec2 v, float maxDistance) {
	float len = length(v);
	return v / len * min(len, maxDistance);
}

// calculate how a light affects the color of a pixel
// given the surface normal, light direction, base color, and specular (shine) parameters
vec3 get_phong_light(vec3 normal, vec3 light_direction, vec3 color, float specular_power, float specular_intensity) {
	// basic lighting effects are really simple
	// it's the dot product of the normal and the light direction
	// basically brighter the closer they are to facing each other
	// https://en.wikipedia.org/wiki/Dot_product
	float diffuse = max(0.0, dot(normal, light_direction));
	// specular shine is just the diffuse scaled by an exponent
	float specular = pow(diffuse, specular_power);
	// when we combine dot product diffuse with a specular shine it's called phong lighting
	// https://en.wikipedia.org/wiki/Phong_reflection_model
	
	float light = (diffuse);// + specular * specular_intensity);
	light = texture(light_gradient, vec2(light, 0.0)).x;
	return color * light;
}

vec3 rotate_axis(vec3 v, vec3 axi, float angle) {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    return v * cos_angle + cross(axi, v) * sin_angle + axi * dot(axi, v) * (1.0 - cos_angle);
}

void fragment() {
	// Warp the UV to make it appear on a sphere
	// use the ratio of our textures

	vec2 sphere_uv = calculate_sphere_uv(vec2(UV.x, UV.y), vec2(2.0, 1.0));
	// calculate the vector of the light based on orbit and axis
	vec3 star_pos = vec3(cos(axis) * sin(orbit), sin(axis) * sin(orbit), cos(orbit));

	// distance from center
	float dist = distance(UV, vec2(0.5, 0.5));
	// distance from equator
	float dist_y = abs(sphere_uv.y - 0.5);
	// planet spin
	float spin = TIME * -0.02;
	// position we sample textures from as they spin "around" the planet
	vec2 off_pos = sphere_uv - vec2(spin / PI, 0.0) + 0.5;
	
	float height = texture(crater1_texture, off_pos).x;
	vec3 crater_norm = texture(crater1_normal, off_pos).rgb;

	float surface_intense = texture(surface_intensity, off_pos).x;
	crater_norm = mix(crater_norm, vec3(0.0, 0.0, 1.0) + 0.5, surface_intense * 0.7);
	//crater_norm = vec3(0.0, 0.0, 1.0);
	vec3 sphere_norm = get_globe_normal(sphere_uv, norm_rad);
	vec3 full_norm = parent_normals(sphere_norm, crater_norm);
	vec3 color = get_phong_light(
		full_norm,
		star_pos,
		vec3(height) * 0.4 + vec3(0.7, 0.65, 0.6) * 0.8,
		20.0, 
		0.5
	);
	height *= 2.0;
	COLOR = vec4(color.r, color.g, color.b, step(dist, 0.5));
}
