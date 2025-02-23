// rockyplanet.gshader Copyright 2025 Nathanael C. Fritz
// MIT License (see LICENSE file)
// https://github.com/fritzy/sublight-planets

// Shader to produce a rocky + ocean planet
// rather than using a 3d model, uses calculated normals
// phong lighting based on star position in axis/orbit

shader_type canvas_item; // 2D
// noise textures generated in rocky_planet.gd
uniform sampler2D surface_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D surface_normal: repeat_enable, filter_linear_mipmap;
uniform sampler2D mountain_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D mountain_normal: repeat_enable, filter_linear_mipmap;
uniform sampler2D desert_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D cloud_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D cloud_texture2: repeat_enable, filter_linear_mipmap;
uniform sampler2D ice_texture: repeat_enable, filter_linear_mipmap;
uniform sampler2D ice_normal: repeat_enable, filter_linear_mipmap;
// inputs for adjusting everything
uniform float ocean_depth: hint_range(0.0, 2.0) = 1.0;
uniform float speed: hint_range(0.0, 0.3) = 0.05;
uniform float ice_coverage: hint_range(0.0, 1.0) = 0.36;
uniform float cloud_opacity: hint_range(0.0, 1.0) = 1.0;
uniform float cloud_density: hint_range(0.0, 1.0) = 0.5;
uniform float atmosphere_opacity: hint_range(0.0, 1.0) = 0.7;
uniform float mtn_snow_height: hint_range(0.1, 1.0, 0.01) = 0.5;
uniform vec4 desert_color: source_color;
uniform vec4 ground_color: source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 ocean_color: source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 cloud_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float axis: hint_range(-1.571, 1.571) = 0.0;
uniform float orbit: hint_range(-3.14159, 3.14159) = 0.0;
uniform bool enable_city_lights = true;

// constants for magic values
const float repro_rad = 2.1;
const float polar_pinch = 0.95;

// functions used in the fragment shader have to be declared first
// the main flow of code starts in the fragment() {} function below

// get the normal as if the pixel (uv) were on a sphere
// we could just use a sphere normal texture, but this is precise
vec3 get_globe_normal(vec2 uv, float radius) {
	uv = uv * radius * 2.0 - radius;
	// see SBOM file
	float z = sqrt(1.0 - (pow(uv.x, 2.0) + pow(uv.y, 2.0) ));
	return  vec3(uv.x, uv.y, z);
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
	return color * (diffuse + specular * specular_intensity);
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

// calculate how thick the clouds are at a given uv
// get a dyanamic result by combining samples at moving in different vectors with time
float calculate_cloud_density(vec2 uv, float cloud_alpha, vec2 offset1, vec2 offset2, vec2 offset3) {
	// add some uv offset swirl to the clouds
	// repurpose the surface texture
	vec2 cloud_swirl = (texture(surface_texture, uv + offset3).xy * 0.05 * vec2(0.5, 1.0)) - 0.5;
	// sample a combination of textures
	float clouds = texture(cloud_texture, uv + offset1 + cloud_swirl).r;
	float clouds2 = texture(cloud_texture2, uv + offset2 + cloud_swirl).r;
	// subtract the the clouds from each other to get a dynamic cloud
	float cloud_overlap = (clouds2 - clouds + cloud_density);
	// cut off at the cloud density
	cloud_alpha = mix(cloud_alpha, 0.0, step(cloud_overlap, 1.0 - cloud_density));
	return cloud_overlap * cloud_alpha * cloud_opacity;
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
	float spin = TIME * speed;
	// position we sample textures from as they spin "around" the planet
	vec2 off_pos = sphere_uv - vec2(spin / PI, 0.0) + 0.5;
	// sample land height from surface noise texture and matching normal
	float height = texture(surface_texture, off_pos).r;
	vec3 surface_norm = texture(surface_normal, off_pos).rgb;
	// sample mountain height and normal
	float mountain = texture(mountain_texture, off_pos).r;
	vec3 mountain_norm = texture(mountain_normal, off_pos).rgb;
	// sample ice texture and normal
	vec3 ice_cracks = texture(ice_texture, off_pos).rgb;
	vec3 ice_norm = texture(ice_normal, off_pos).rgb;
	// sample desert texture for desert discoloring
	float deserts = texture(desert_texture, off_pos).r;
	// snow is white with 20% sky/ocean color
	vec3 snow_color = mix(vec3(1.0), ocean_color.rgb, 0.2);
	// time offsets for sampling cloud textures
	vec2 cloud_offset1 =  sphere_uv - vec2(spin / PI * 2.1, 0.0) + 0.5;
	vec2 cloud_offset2 =  sphere_uv - vec2(spin / PI * 2.6, 0.0) + 0.5;
	vec2 cloud_offset3 =  sphere_uv - vec2(spin / PI * 2.0, 0.0) + 0.5;
	// our base color, starting with white
	vec3 color = vec3(1.0, 1.0, 1.0);
	// cut off the land at different radiuses
	float land_alpha = mix(1.0, 0.0, step(0.476, dist));
	float cloud_alpha = mix(1.0, 0.0, step(0.49, dist));

	// --- Land and Sea
	// now our height is 0.0 to 2.0 representing the ground height
	height += mountain;
	// a float of 1.0 for ocean (anything below ocean depth) and 0.0 for land
	float is_ocean = mix(1.0, 0.0, step(ocean_depth, height));
	// calculate some beaches from sea level to slightly above
	// with ground color and desert color
	vec3 ground_sand_mix = mix(
		ground_color.rgb,
		desert_color.rgb,
		step(height, ocean_depth + 0.02)
	);
	// add some desert splotches
	// using the deserts sample, distance from the equator, avoiding mountains
	float desert_step = smoothstep(0.5, 0.6, deserts * (1.0 - dist_y - mountain));
	ground_sand_mix = mix(ground_sand_mix, desert_color.rgb, desert_step);
	// mix in white with some sky/ocean color for mountains
	// where our mountain height is above our mtn_snow_height
	vec3 ground_snow_mix = mix(
		ground_sand_mix,
		snow_color,
		step(mtn_snow_height, mountain)
	);
	// for our uv, calculate our globe normal
	vec3 globe_norm = get_globe_normal(UV, 1.05);
	// get our ocean lighting based on the globe normal, star position, and ocean color
	// pretty shiny
	vec3 ocean_diffuse = get_phong_light(globe_norm, star_pos, ocean_color.rgb, 150.0, 2.25);
	// ocean pixels apply where is_ocean
	color = mix(color, ocean_diffuse, is_ocean);
	// parent our surface + mountain normals to the globe normal
	vec3 globe_surface_mountain_norm = parent_normals(
		globe_norm,
		normalize(surface_norm + mountain_norm + 1.0)
	);
	// calculate our ground lighting with our global normal, surface normal, mountain normal
	// and our combined ground, snow, sand coloring
	// less shiny than the ocean
	vec3 lit_ground_color = get_phong_light(globe_surface_mountain_norm, star_pos, ground_snow_mix, 10.0, 0.3);
	// apply our lit ground color if we're not an ocean pixel
	color = mix(color, lit_ground_color, 1.0 - is_ocean);

	// --- City Lights
	// repurpose our ice cracks noise texture but offset and scale
	// as the basis for our city lights
	float city_lights = texture(ice_texture, off_pos * 8.234).r;
	// prevent lights from showing up in random areas by repurposing our
	// surface height noise texture
	city_lights -= texture(surface_texture, off_pos * 4.782).r * 0.6;
	// keep city lights to just above sea level
	city_lights = step(0.6, city_lights) * step(height - 0.1, ocean_depth + 0.01) * (1.0 - is_ocean);
	// city lights should only be in the dark and fade out with light
	// if colors are just vectors, why not distance?
	city_lights *= 1.0 - smoothstep(0.05, 0.1,
			distance(vec3(0.0), lit_ground_color.rgb));
	// make a yellow light unless not enabled
	color = mix(
		color,
		vec3(0.6, 0.6, 0.2), // yellow lights
		city_lights * float(enable_city_lights) * land_alpha // leave the color alone if no light here
	);

	// --- Polar Ice
	// slap our ice normal onto the globe
	vec3 globe_ice_norm = parent_normals(globe_norm, ice_norm);
	// use our globe_ice_normal where there's ocean,
	// and our surface+mountain normal where there isn't
	globe_surface_mountain_norm = mix(globe_surface_mountain_norm, globe_ice_norm, is_ocean);
	// ice is always white, mixed with the ocean/sky color based on our ice cracks
	// where there is ocean
	vec3 ice_color = mix(
		// on land
		snow_color,
		// mix in ocean / sky color
		ocean_color.rgb,
		// not at all if it's land, and based on the ice cracks sample otherwise
		mix(0.0, ice_cracks.r * 0.25, is_ocean)
	);
	// ice is kind of shiny
	// combine the full global normal with our ice color to get the lit color
	vec3 ice_diffuse = get_phong_light(
		globe_surface_mountain_norm, star_pos, ice_color, 20, 0.4
	);
	// determine if this is snow/ice based on
	// land height, ocean_depth, distance from poles
	// and the ice_coverage uniform
	float is_frozen = mix(1.0, 0.0,
		step(dist_y * max(
			height,
			is_ocean * (ocean_depth + height / 4.0) - ocean_depth * 0.25
		) + ice_coverage,
		0.9)
	);
	// apply our ice where things are frozen
	color = mix(color, ice_diffuse, is_frozen);

	// --- Clouds
	// get the angle of the light (star/sun) and the surface to determine
	// where to check for a cloud to decide where to place a shadow
	// clamp our shadow length so that it doesn't get too crazy at the globe edges
	vec2 cloud_shadow_off = clamp_vector_length(
		(star_pos - globe_norm).xy * 0.03,
		0.025
	) * vec2(2.0, 1.0);
	// apply shadow offset the the current UV and calculate the sphere UV of this offset
	vec2 cloud_shadow_uv = calculate_sphere_uv(UV + cloud_shadow_off, vec2(2.0, 1.0));
	// check to see how much cloud we're shadowed by
	float cloud_shadow = calculate_cloud_density(cloud_shadow_uv, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	// apply the cloud shadow to the ground based on how much cloud we sampled
	color.rgb = mix(color.rgb, vec3(0.0, 0.0, 0.0), cloud_shadow);
	// now that we have our shadow, calculate how much cloud is on our current pixel
	float cloud_thickness = calculate_cloud_density(sphere_uv, cloud_alpha, cloud_offset1, cloud_offset2, cloud_offset3);
	// calculate how the clouds are lit to get the cloud color
	// clouds are a shiny
	vec3 cloud_diffuse = get_phong_light(globe_norm, star_pos, cloud_color.rgb, 30.0, 0.55);
	// apply the cloud color based on how thick they are here
	color = mix(color, cloud_diffuse, min(cloud_thickness * 1.2, 1.0));

	// --- Atmosphere
	// get the atmosphere lighting at a different radius
	// based on the ocean/sky color
	vec3 atmos_diff = get_phong_light(get_globe_normal(UV, 0.9), star_pos, ocean_color.rgb, 1.0, 0.8);
	// exponentially less in the middle than the edges
	// apply how thick we want the atmosphere to show
	atmos_diff *= pow(dist * 2.0, 6.0) * atmosphere_opacity;
	// use a "screen blend" to add the atmosphere to the color so far
	// https://godotshaders.com/snippet/blending-modes/
	color = 1.0 - (1.0 - color) * (1.0 - atmos_diff);
	// apply a lesser alpha to the atmosphere
	// in case there are objects or stars behind this layer
	float atmos_alpha = mix(
		// full opacity for planet
		1.0,
		// atmosphere opacity at the atmosphere layer
		// full alpha beyond
		mix(atmosphere_opacity, 0.0, step(0.5, dist)),
		step(0.48, dist)
	);

	// final color + alpha of the current UV pixel
	COLOR = vec4(color.r, color.g, color.b, atmos_alpha);
}