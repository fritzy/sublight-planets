shader_type canvas_item;
uniform sampler2D surface_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D surface_normal: repeat_enable, filter_linear_mipmap;
uniform sampler2D mountain_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D mountain_normal: repeat_enable, filter_linear_mipmap;

uniform sampler2D desert_texture: repeat_enable;
uniform sampler2D cloud_texture: repeat_enable;
uniform sampler2D cloud_texture2: repeat_enable;
uniform sampler2D ice_texture: repeat_enable;
uniform sampler2D ice_normal: repeat_enable;

uniform vec2 shine_offset = vec2(0.5, 0.5);
uniform float ocean_depth: hint_range(0.0, 2.0) = 1.0;
uniform float speed: hint_range(0.0, 0.3) = 0.1;
uniform float ice_coverage: hint_range(0.0, 1.0) = 0.36;
uniform float cloud_opacity: hint_range(0.0, 1.0) = 1.0;
uniform float cloud_density: hint_range(0.0, 1.0) = 0.5;
uniform float desert_patches: hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float atmosphere_opacity: hint_range(0.0, 1.0) = 0.7;
uniform float mtn_snow_height: hint_range(0.1, 1.0, 0.01) = 0.5;
uniform vec4 desert_color: source_color;
uniform vec4 ground_color: source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 ocean_color: source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 cloud_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float axis: hint_range(-1.571, 1.571) = 0.0;
uniform float orbit: hint_range(-3.14159, 3.14159) = 0.0;

const vec3 light_color = vec3(1.0, 1.0, 1.0);
const float repro_rad = 2.1;

vec3 get_star_pos() {
	return vec3(cos(axis) * sin(orbit), sin(axis) * sin(orbit), cos(orbit));
}

float rand_light(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

vec3 get_globe_normal(vec2 uv, float radius) {
	uv = uv * radius * 2.0 - radius;
	float z = sqrt(1.0 - ( pow(uv.x, 2.0) + pow(uv.y, 2.0) ));
	return  vec3(uv.x, uv.y, z);
}

mat3 create_transformation_matrix(vec3 facing) {
    vec3 up = normalize(vec3(0.0, 1.0, 0.0));
    vec3 right = normalize(cross(up, facing));
	// shadows are inverted vertically unless I negate the facing for up
    vec3 new_up = cross(-facing, right);

    return mat3(
        vec3(right),
        vec3(new_up),
        vec3(facing)
    );
}

vec3 parent_normals(vec3 parent_facing, vec3 child_facing) {
	// not sure why the bias is like this
	child_facing = normalize(child_facing - vec3(0.41));
    mat3 transformation_matrix = create_transformation_matrix(parent_facing);
    vec3 global_facing = transformation_matrix * child_facing;
    return normalize(global_facing);
}

vec2 clamp_distance(vec2 v, float maxDistance) {
    float len = length(v);
    return v / len * min(len, maxDistance);
}

vec3 get_light(vec3 normal, vec3 color, float specular_power, float specular_intensity) {
	vec3 camera_direction = vec3(0.0, 0.0, 1.0);
	//uv = uv * 1.125 * 2.0 - 1.125;
	vec3 light_direction = normalize(get_star_pos());
	vec3 half_vector = normalize( camera_direction + light_direction );
	float diffuse    = max( 0.0, dot( normal, light_direction ) );
	float specular   = pow(max( 0.0, dot( light_direction, normal )), specular_power);
	return color * (diffuse + specular * specular_intensity);
}

vec2 calculate_sphere_uv(vec2 uv, vec2 ratio) {
    vec2 sphere_uv = vec2(repro_rad * (uv.x - 0.5), repro_rad * (uv.y - 0.5));

    sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * repro_rad / PI;
    sphere_uv.y = asin(sphere_uv.y) * repro_rad / PI;
	sphere_uv.x *= cos(sphere_uv.y * PI * 0.25);

    // Scale the UV coordinates by ratio and texture repeat
    sphere_uv *= 0.5 * ratio;
	sphere_uv += 0.5;
    // Wrap the UV coordinates to stay within the [0, 1] range
    //sphere_uv = fract(sphere_uv);

    return sphere_uv;
}

float calculate_cloud_density(vec2 uv, float cloud_alpha, vec2 offset1, vec2 offset2, vec2 offset3) {
	vec2 sphere_uv = calculate_sphere_uv(uv, vec2(0.5, 1.0));
	vec2 cloud_swirl = texture(surface_texture, sphere_uv + offset3).rg * 0.1;
	float clouds = texture(cloud_texture, sphere_uv + offset1).r;
	float clouds2 = texture(cloud_texture2, sphere_uv + offset2).r;
	float cloud_overlap = (clouds2 - clouds + cloud_density);
	cloud_alpha = mix(cloud_alpha, 0.0, step(cloud_overlap, 1.0 - cloud_density));
	return cloud_overlap * cloud_alpha * cloud_opacity;
}


void fragment() {
	vec2 sphere_uv = calculate_sphere_uv(vec2(UV.x, UV.y), vec2(0.5, 1.0));
	vec3 star_pos = get_star_pos();
	// distance from center
	float dist = distance(UV, vec2(0.5, 0.5));
	float _disty = abs(sphere_uv.y);
	float disty2 = abs(sphere_uv.y - 0.5);
	float orbit2 = 0.05 * TIME;

	vec2 off_pos = sphere_uv -
	 vec2(orbit2 / PI, 0.0) + 0.5;

	float height = texture(surface_texture, off_pos).r;
	vec3 surface_norm = texture(surface_normal, off_pos).rgb;
	// sample cellular for mountains
	//float mountain = texture(cloud_texture, off_pos).r;
	float mountain = texture(mountain_texture, off_pos).r;
	vec3 mountain_norm = texture(mountain_normal, off_pos).rgb;
	// ice
	vec3 ice_cracks = texture(ice_texture, off_pos).rgb;
	vec3 ice_norm = texture(ice_normal, off_pos).rgb;
	// sample desert texture for desert splotches
	float deserts = texture(desert_texture, off_pos).r;

	// time offsets for cloud textures
	vec2 cloud_offset1 =  sphere_uv - vec2(orbit2 / PI * 2.1, 0.0) + 0.5;
	vec2 cloud_offset2 =  sphere_uv - vec2(orbit2 / PI * 2.6, 0.0) + 0.5;
	vec2 cloud_offset3 =  sphere_uv - vec2(orbit2 / PI * 2.0, 0.0) + 0.5;

	// start with white
	vec3 color = vec3(1.0, 1.0, 1.0);
	// planet shadow amount

	// cut off the land at different radiuses
	float land_alpha = mix(1.0, 0.0, step(0.477, dist));
	float cloud_alpha = mix(1.0, 0.0, step(0.49, dist));


	// determine if this is a ground pixel , 0.0 or 1.0
	float ground = mix(1.0, 0.0, step(height, ocean_depth));

	// add some mountain ranges
	height += mountain;
	float ocean = mix(1.0, 0.0, step(ocean_depth, height));

	// determine if this is snow based on height sample plus distance to poles
	float snowt = mix(1.0, 0.0,
		step(disty2 * max(
			height,
			ocean * (ocean_depth + height / 4.0) - ocean_depth * 0.25) + ice_coverage,
			0.9
		)
	);

	float land_height = (height - ocean_depth) / (2.0 - ocean_depth - 0.0001);
	float snow_elev = mtn_snow_height;

	vec3 ground_sand_mix = mix(
		ground_color.rgb,
		(desert_color.rgb),
		step(height, ocean_depth + 0.02)
	);
	float desert_step = smoothstep(0.5, 0.6, deserts * (1.0 - abs(sphere_uv.y - 0.5) -mountain));
	ground_sand_mix = mix(ground_sand_mix, desert_color.rgb,  desert_step );



	vec3 ground_snow_mix = mix(
			ground_sand_mix,
			mix(vec3(1.0), ocean_color.rgb, 0.2),
			step(snow_elev, mountain)
		);

	vec3 globe_normal = get_globe_normal(UV, 1.05);
	vec3 ocean_diffuse = get_light(globe_normal, ocean_color.rgb, 150.0, 2.25);
	color = mix(color, ocean_diffuse, ocean);

	// combine ground and mountain normals to generate highlights
	vec3 globe_surface_mountain_norm = parent_normals(
		globe_normal,
		normalize((surface_norm + mountain_norm))
	);
	vec3 lit_ground_color = get_light(globe_surface_mountain_norm, ground_snow_mix, 20.0, 0.1);
	color = mix(color, lit_ground_color, 1.0 - ocean);

	float city_lights = texture(ice_texture, off_pos * 8.0).r;
	city_lights -= texture(surface_texture, off_pos * 4.0).r * 0.7;
	city_lights = step(0.6, city_lights) * step(height - 0.1, ocean_depth + 0.01);
	city_lights = mix(
		city_lights,
		0.0,
		smoothstep(
			0.05,
			0.1,
			distance(
				vec3(0.0),
				lit_ground_color.rgb
			)
		)
	);
	color = mix(
		vec3(0.6, 0.6, 0.2),
		color,
		step(city_lights, ocean)
	);
	

	vec3 globe_ice_norm = parent_normals(globe_normal, ice_norm);
	globe_surface_mountain_norm = mix(globe_surface_mountain_norm, globe_ice_norm, ocean);

	vec3 ice_color = mix(vec3(1.0, 1.0, 1.0), ocean_color.rgb, mix(0.0, ice_cracks.r * 0.25, ocean));
	vec3 ice_diffuse = get_light(
			globe_surface_mountain_norm, ice_color, 200, 0.25
	);
	color = mix(color, ice_diffuse, snowt);


	
	// get the angle of the star and the surface to determine
	// where to check for a cloud to decide where to place a shadow
	vec2 cloud_shadow_off = clamp_distance(
		(star_pos - globe_normal).xy * 0.03,
		0.025
	);
	float cloud_shadow = calculate_cloud_density(UV + cloud_shadow_off, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	color.rgb = mix(color.rgb, vec3(0.0, 0.0, 0.0), cloud_shadow);

	color = mix(color, vec3(0.0), 1.0 - land_alpha);

	float cloud_thickness = calculate_cloud_density(UV, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	vec3 cloud_diffuse = get_light(globe_normal, cloud_color.rgb, 30.0, 0.55);
	color = mix(color, cloud_diffuse, min(cloud_thickness * 1.2, 1.0));



	vec3 atmos_diff = get_light(get_globe_normal(UV, 0.9), ocean_color.rgb, 1.0, 0.8);
	// more intense on the edges
	atmos_diff *= pow(dist * 2.0, 6.0) * atmosphere_opacity;
	// screen blend https://godotshaders.com/snippet/blending-modes/
	color = 1.0 - (1.0 - color) * (1.0 - atmos_diff);
	

	// final color of the pixel
	float atmos_alpha = mix(
		1.0,
		mix(atmosphere_opacity, 0.0, step(0.5, dist)),
		step(0.48, dist)
	);
	COLOR = vec4(color.r, color.g, color.b, atmos_alpha);
	//COLOR.rgba = (vec4(atmos_alpha, atmos_alpha, atmos_alpha, 1.0));
}