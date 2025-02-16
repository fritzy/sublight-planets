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
const float repro_rad = 2.25;

vec3 get_star_pos() {
	return vec3(cos(axis) * sin(orbit), sin(axis) * sin(orbit), cos(orbit));
}

vec2 clamp_distance(vec2 point1, vec2 point2) {
	vec2 start = point2 - point1;
	float l = length(start);
	float cl = min(l, 0.5);
	return (normalize(start) * cl) + point1;
}

vec3 get_globe_normal(vec2 uv) {
	uv = uv * 1.125 * 2.0 - 1.125;
	float z = sqrt(1.0 - ( pow(uv.x, 2.0) + pow(uv.y, 2.0) ));
	return  vec3(uv.x, uv.y, z);
}

mat3 create_transformation_matrix(vec3 facing) {
    // Choose an initial up vector
    // Assuming y-axis as up
    vec3 up = normalize(vec3(0., 1., 0.));
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


vec3 get_light(vec3 normal, vec3 color, float specular_power, float specular_intensity) {
	vec3 camera_direction = vec3(0.0, 0.0, 1.0);
	//uv = uv * 1.125 * 2.0 - 1.125;
	vec3 light_direction = normalize(get_star_pos());
	vec3 half_vector = normalize( camera_direction + light_direction );
	float diffuse    = max( 0.0, dot( normal, light_direction ) );
	float specular   = pow(max( 0.0, dot( light_direction, normal )), specular_power);
	return color * (diffuse + specular * specular_intensity);
}

vec3 normal_diffuse(vec3 normal, vec2 light_pos, vec2 uv) {
	vec2 lightDir = normalize(light_pos - uv);
	float diff = max(dot(normal.rg, lightDir), 0.0);
	return diff * vec3(1.0, 1.0, 1.0);
}

vec3 rotate_y(vec3 v, float angle) {
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    return vec3(
        v.z * sinAngle + v.x * cosAngle,
        v.y,
        v.z * cosAngle - v.x * sinAngle
    );
}

vec3 poor_mans_normal(sampler2D img, vec2 uv, float scale) {
    vec2 offset_x = vec2(scale, 0.0);
    vec2 offset_y = vec2(0.0, scale);

    float heightL = texture(img, uv - offset_x).r;
    float heightR = texture(img, uv + offset_x).r;
    float heightD = texture(img, uv - offset_y).r;
    float heightU = texture(img, uv + offset_y).r;

    vec3 normal = vec3(heightL - heightR, heightD - heightU, 2.0 * scale);
    normal = normalize(normal);
    return normal;
}
vec3 poor_mans_normal2(sampler2D texture, vec2 uv, float scale) {
	float ups = 0.003;
	float vps = .003;

	// poor man's normal
	float mount_pu = texture(texture, uv + vec2(ups, 0.0)).r;
	float mount_mu = texture(texture, uv - vec2(ups, 0.0)).r;
	float mount_pv = texture(texture, uv + vec2(0.0, vps)).r;
	float mount_mv = texture(texture, uv - vec2(0.0, vps)).r;

	float du = (mount_mu - mount_pu) * scale;
	float dv = (mount_mv - mount_pv) * scale;
	vec3 mN = normalize(vec3(dv, du, 0.4));

    // Rotate the normal by -90 degrees around the x-axis
	 //vec3(cos(axis) * sin(orbit), sin(axis) * sin(orbit), cos(orbit));
    float angle = 0.0;
	float rot = 1.0 * TIME;
	mat3 rotationMatrix = create_transformation_matrix(
		 vec3(cos(rot) * cos(angle), cos(rot) * sin(angle), sin(rot))
	);
    mN = rotationMatrix * mN;

	return mN;
}

float normal_diffuse2(vec3 normal, vec3 normal2, vec2 light_pos, vec2 uv) {
	normal = normal * 2.0 - 1.0;
	normal2 = normal2 * 2.0 - 1.0;
	vec3 combined = normalize(normal + normal2);
	vec2 light_dir = normalize(light_pos - uv);
	float diffuse = max(dot(combined, vec3(light_dir, 0.0)), 0.0);
	return diffuse;
}

vec3 diffuse_light(sampler2D texture, vec2 texture_uv, vec2 uv, float scale, vec2 light_pos) {
	vec3 normal = poor_mans_normal(texture, texture_uv, scale);
	return normal_diffuse(normal, light_pos, uv);
}

vec2 calculate_ray_offset(vec3 normal, vec3 ray_vector, float distance) {
    // Normalize the input vectors
    normal = normalize(normal);
    ray_vector = normalize(ray_vector);
	vec3 camera_vector = vec3(0.0, 0.0, 1.0);

    // Compute the intersection point
    float cos_theta = dot(normal, ray_vector);
    float sin_theta = sqrt(1.0 - cos_theta * cos_theta);

    // Compute the travel distance along the ray
    float travel_distance = distance / cos_theta;

    // Compute the offset in the direction of the ray
    vec3 offset_vector = ray_vector * travel_distance;

    // Project the offset vector onto the surface plane
    vec3 surface_offset_vector = offset_vector - normal * dot(normal, offset_vector);

    // Convert the 3D surface offset vector to a 2D offset
    vec2 offset = vec2(surface_offset_vector.x, surface_offset_vector.z);

    return offset;
}


vec2 calculate_sphere_uv(vec2 uv, vec2 ratio) {
    vec2 sphere_uv = vec2(repro_rad * (uv.x - 0.5), repro_rad * (uv.y - 0.5));

    sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * repro_rad / PI;
    sphere_uv.y = asin(sphere_uv.y) * repro_rad / PI;

	sphere_uv.x *= cos(sphere_uv.y * PI * 0.25);

    // Define a scaling factor to repeat the texture less frequently
    float scale_factor = 0.5;

    // Scale the UV coordinates
    sphere_uv *= scale_factor;
	sphere_uv *= ratio;
	//sphere_uv.y *= 0.5;
	sphere_uv += 0.5;
    // Wrap the UV coordinates to stay within the [0, 1] range
    sphere_uv = fract(sphere_uv);

    return sphere_uv;
}



vec3 reproject_normal(vec3 n1, vec3 n2) {
    return normalize(n1 + n2);
}

float calculate_cloud_density(vec2 uv, float cloud_alpha, vec2 offset1, vec2 offset2, vec2 offset3) {
	vec2 sphere_uv = calculate_sphere_uv(uv, vec2(0.5, 1.0));
	//vec2 sphere_uv = uv;
	//vec2 cloud_swirl_offset1 = offset2 * 1.4;
	vec2 cloud_swirl = texture(surface_texture, sphere_uv + offset3).rg * 0.1;
	float clouds = texture(cloud_texture, sphere_uv + offset1).r;
	float clouds2 = texture(cloud_texture2, sphere_uv + offset2).r;
	float cloud_overlap = (clouds2 - clouds + cloud_density);
	cloud_alpha = mix(cloud_alpha, 0.0, step(cloud_overlap, 1.0 - cloud_density));
	return cloud_overlap * cloud_alpha * cloud_opacity;
	//return sphere_uv.y;
}

// for each pixel, this is run with the pixel's UV coord
void fragment() {
	// -- sample the texture for a sphere
	vec2 sphere_uv = calculate_sphere_uv(vec2(UV.x, UV.y), vec2(0.5, 1.0));
	//sphere_uv.x *= 0.5;
	// distance from center
	float dist = distance(UV, vec2(0.5, 0.5));
	float disty = abs(sphere_uv.y);
	float disty2 = abs(sphere_uv.y - 0.5);
	float orbit2 = 0.05 * TIME;
	//vec2 off_pos = sphere_uv + vec2(speed, 0.0) * TIME;
	//vec2 off_pos = sphere_uv;
	vec2 off_pos = sphere_uv -
	 vec2(orbit2 / PI, 0.0) + 0.5;
	// distance from shiny spot
	//vec2 light_pos = clamp_distance(vec2(0.5, 0.5), shine_offset);
	//float light_dist = distance(UV, light_pos);
	// sample surface texture for land height
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
	//float fade = clamp(0.65 - light_dist * 1.4, 0.0, 1.0);
	// deserts are on the equator
	float desert_fade = 1.0 - pow(disty + 2.0, 3.5);
	// amount of glare
	//float shine = smoothstep(0.2, 0.00, light_dist);
	// cut off the land at a radius
	float land_alpha = mix(1.0, 0.0, step(0.46, dist));
	// cut off the clouds at a radius
	float cloud_alpha = mix(1.0, 0.0, step(0.475, dist));
	// cut off the atmosphere at a radius
	float atmos_alpha = mix(1.0, 0.0, step(0.5, dist));
	// determine if this is an ocean pixel, 0.0 or 1.0

	// determine if this is a ground pixel , 0.0 or 1.0
	float ground = mix(1.0, 0.0, step(height, ocean_depth));

	// overall planet shadow / light
	//float planet_shadow = smoothstep(0.6, 0.05, light_dist);

	// add some mountain ranges
	height += mountain;
	float ocean = mix(1.0, 0.0, step(ocean_depth, height));

	//float desert = mix(1.0, 0.0, step(deserts + (0.4 - disty), 1.00));
	// determine if this is snow based on height sample plus distance to poles
	float snowt = mix(1.0, 0.0,
		step(disty2
		* max(height, ocean * ((ocean_depth + height / 4.0) - ocean_depth))
		+ ice_coverage, 0.9));

	// mix the ground color with the desert color
	// normalize land based on remaining height from sea level
	vec3 ground_mod = (ground_color.rgb * 1.0) + (smoothstep(0.2, 0.55, abs(disty - 0.5)) * desert_color.rgb * 0.5);

	float r = (height - ocean_depth) / (2.0 - ocean_depth - 0.0001);
	float land_height = r;
	//float sand_height = land_height + 0.1;
	float snow_elev = mtn_snow_height;
	//sand_height = land_height + 0.15;

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



	// if this is ocean, draw it with extra shine
	//color = mix(color, ocean_color.rgb + shine * 3.4, ocean);
	//vec3 ocean_diffuse = diffuse_light(desert_texture, off_pos, UV, 0.9, light_pos);
	vec3 globe_normal = get_globe_normal(UV);
	vec3 ocean_diffuse = get_light(globe_normal, ocean_color.rgb, 150.0, 2.25);
	//color = mix(color, ocean_color.rgb + (shine * ocean_diffuse) + shine * 1.2, ocean);
	color = mix(color, ocean_diffuse, ocean);

	// combine ground and mountain normals to generate highlights
	//float ground_diffuse = normal_diffuse2(surface_norm, mountain_norm, light_pos, UV);
	vec3 globe_surface_mountain_norm = parent_normals(
		globe_normal,
		//parent_normals(surface_norm, mountain_norm)
		normalize((surface_norm + mountain_norm))
	);
	vec3 lit_ground_color = get_light(
		globe_surface_mountain_norm,
		ground_snow_mix,
		20.0,
		  0.1);
	// if this is ground draw our mixed ground color (not ocean)
	//color = mix(color, ground_sand_mix + shine * 0.2, 1.0 - ocean);
	color = mix(color, lit_ground_color, 1.0 - ocean);
	// apply light and shadow
	//color = mix(color, color * ground_diffuse * ground * (shine * 0.8 + planet_shadow * 4.4), 0.34);
	// if this is snow/ice apply it to the color

	vec3 globe_ice_norm = parent_normals(globe_normal, ice_norm);
	globe_surface_mountain_norm = mix(globe_surface_mountain_norm, globe_ice_norm, ocean);

	//ice_cracks.y *= -1.0;
	vec3 ice_color = mix(vec3(1.0, 1.0, 1.0), ocean_color.rgb, mix(0.0, ice_cracks.r * 0.25, ocean));
	vec3 ice_diffuse = get_light(
			globe_surface_mountain_norm, ice_color, 200, 0.25
	);

	//vec3 ice_diffuse = diffuse_light(ice_texture, off_pos, UV, -0.4, light_pos);
	color = mix(color, ice_diffuse, snowt);
	//	ice_cracks, color, 20, 0.25
	//);
	//vec3 ice_diffuse = diffuse_light(ice_texture, off_pos, UV, -0.4, light_pos);
	//color = mix(color, vec3(1.0 - ice_cracks * 0.5), snowt);
	//color = color + (shine * 2.0) * ice_diffuse * snowt;

/*
	// if this is a desert splotch, draw that color
	float is_desert_patch =  desert_patches * desert * mod(ocean + 1.0, 2.0) * mod(snowt + 1.0, 2.0);
	color = mix(
		color,
		desert_color.rgb * 0.5 + (desert_color.rgb * 0.7),
		is_desert_patch
	);
	vec3 desert_diffuse = diffuse_light(desert_texture, off_pos, UV, 0.3, light_pos);
	// don't use shine on desert light diffusing, just use the planet shadow
	color += (planet_shadow) * desert_diffuse * desert_patches * desert * mod(ocean + 1.0, 2.0) * mod(snowt + 1.0, 2.0);
	vec2 lightDir = light_pos - UV;
	color -= 0.4 * calculate_cloud_density(sphere_uv + lightDir * 0.1, cloud_alpha, cloud_offset1, cloud_offset2);

	// cut off the color at the land radius
	color = color * land_alpha;
	*/

	vec2 cloud_shadow_offset =
		clamp(
			calculate_ray_offset(globe_normal, get_star_pos(), 0.01),
			vec2(-0.025, -0.025), vec2(0.025, 0.025)
		);
	float cloud_shadow = calculate_cloud_density(UV + cloud_shadow_offset, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	color.rgb = mix(color.rgb, vec3(0.0, 0.0, 0.0), cloud_shadow);

	float cloud_thickness = calculate_cloud_density(UV, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	vec2 cloud_off = vec2(-speed * 1.0, 0) * TIME;
	vec3 cloud_norm1 = poor_mans_normal(cloud_texture, sphere_uv + cloud_offset1, 1.0);
	vec3 cloud_norm2 = poor_mans_normal(cloud_texture2, sphere_uv + cloud_offset2, 1.0);
	vec3 total_cloud_norm = parent_normals(
		get_globe_normal(UV),
		cloud_norm1
	);

	vec3 cloud_diffuse = get_light(globe_normal, cloud_color.rgb, 30.0, 0.55);
	//vec3 cloud_diffuse2 = get_light(cloud_norm2, ground_snow_mix, 200.0, 0.25);
	//vec3 cloud_diffuse1 = diffuse_light(cloud_texture, sphere_uv + vec2(speed * 1.5, 0.0) * TIME, UV, 0.4, light_pos);
	//vec3 cloud_diffuse2 = diffuse_light(cloud_texture2, off_pos, UV, 0.4, light_pos);
	//vec3 total_cloud_diffuse = (cloud_diffuse1 + cloud_diffuse2);

	color = mix(color, cloud_diffuse, min(cloud_thickness * 1.2, 1.0));
	/*
	color = mix(color,
		min(cloud_color.rgb + (shine * 0.2) + ((shine + planet_shadow) * total_cloud_diffuse * -0.5), vec3(1.0)) * 1.0,
		min(cloud_thickness * 1.2, 1.0)
		);
	*/
	// reverse shadow for atmosphere, more intense at the edges
	float atmos_intensity = smoothstep(0.3, 0.5, dist) + 0.1;

	// apply the atmosophere to the color
	//color = color + (ocean_color.rgb * atmos_intensity * 2.0 * atmosphere_opacity);

	//color *= planet_shadow;

	// final color of the pixel
	COLOR = vec4(color.r, color.g, color.b, atmos_alpha);
	//COLOR.rgb = mix(vec3(1.0, 1.0, 1.0), desert_color.rgb, deserts * (1.0 - abs(sphere_uv.y - 0.5)));
	//COLOR.rgb = ocean_diffuse;
	//COLOR.rgb = vec3(sphere_uv.y);
}
