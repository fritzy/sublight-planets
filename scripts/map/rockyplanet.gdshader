shader_type canvas_item;
uniform sampler2D surface_texture: repeat_enable;
uniform sampler2D desert_texture: repeat_enable;
uniform sampler2D cloud_texture: repeat_enable;
uniform sampler2D cloud_texture2: repeat_enable;
uniform sampler2D ice_texture: repeat_enable;
uniform float shine_offset: hint_range(0.0, 1.0) = 0.5;
uniform float ocean_depth: hint_range(0.0, 1.0) = 0.5;
uniform float speed: hint_range(0.0, 0.3) = 0.1;
uniform float ice_coverage: hint_range(0.0, 1.0) = 0.36;
uniform float cloud_opacity: hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float desert_patches: hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float atmosphere_opacity: hint_range(0.0, 1.0) = 0.7;
uniform float mtn_snow_height: hint_range(0.0, 1.2) = 0.886;
uniform vec4 desert_color: source_color;
uniform vec4 ground_color: source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 ocean_color: source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 cloud_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);

// for each pixel, this is run with the pixel's UV coord
void fragment() {

	// -- sample the texture for a sphere
	vec2 sphere_uv = vec2(2.0 * (UV.x - 0.5), 2.0 * (UV.y - 0.5));
	sphere_uv.x = asin(sphere_uv.x / sqrt(1.0 - sphere_uv.y * sphere_uv.y)) * 2.0 / PI;
	sphere_uv.y = asin(sphere_uv.y) * 2.0 / PI;
	// distance from center
	float dist = distance(UV, vec2(0.5, 0.5));
	float disty = abs(sphere_uv.y);
	// distance from shiny spot
	float light_dist = distance(UV, vec2(shine_offset, 0.5));
	// sample surface texture for land height
	float height = texture(surface_texture, sphere_uv + vec2(speed, 0.0) * TIME).r;
	// ice
	float ice_cracks = texture(ice_texture, sphere_uv + vec2(speed, 0.0) * TIME).r;
	// sample desert texture for desert splotches
	float deserts = texture(desert_texture, sphere_uv + vec2(speed, 0.0) * TIME).r;
	// sample cloud texture
	float clouds = texture(cloud_texture, sphere_uv + vec2(speed * 0.4, 0.0) * TIME).r;
	float clouds2 = texture(cloud_texture2, sphere_uv + vec2(speed * 0.6, 0.0) * TIME).r;
	// start with white
	vec3 color = vec3(1.0, 1.0, 1.0);
	// planet shadow amount
	float fade = clamp(0.65 - light_dist * 1.4, 0.0, 1.0);
	// deserts are on the equator
	float desert_fade = 1.0 - pow(disty + 2.0, 3.5);
	// amount of glare
	float shine = clamp(.25 - light_dist, 0.0, 1.0) * 2.0;
	// cut off the land at a radius
	float land_alpha = mix(1.0, 0.0, step(0.4, dist));
	// cut off the clouds at a radius
	float cloud_alpha = mix(1.0, 0.0, step(0.415, dist));
	// cutt off the atmosphere at a radius
	float atmos_alpha = mix(1.0, 0.0, step(0.43, dist));
	// determine if this is an ocean pixel, 0.0 or 1.0
	float ocean = mix(1.0, 0.0, step(ocean_depth, height));
	// determine if this is a ground pixel , 0.0 or 1.0
	float ground = mix(1.0, 0.0, step(height, ocean_depth - .01));
	// determine if this is desert using desert range from uv.y center
	// and desert texture sample
	float desert = mix(1.0, 0.0, step(deserts + (0.4 - disty), 0.9));
	// determine if this is snow based on height sample plus distance to poles
	float snowt = mix(1.0, 0.0,
		step(pow(disty, 1)
		 * max(height, ocean * (ocean_depth - height) * 2.0)
		+ mix(0.0, 0.4, step(mtn_snow_height, height))
		+ ice_coverage, 0.9));
	// mix the ground color with the desert color
	vec3 ground_sand_mix = mix(ground_color.rgb * (height * 1.0 + 1.0)
		,(desert_color.rgb + ground_color.rgb * 0.5) * (deserts + 1.0) * 1.2,
		//1.0);
		clamp(1.0 - pow(disty * 4.0, 1.4), 0.0, 5.0));
	ground_sand_mix.rgb = max(ground_sand_mix.rgb, ground_color.rgb * 1.4);
	//vec3 ground_sand_mix = ground_color.rgb * height * 4.0 + (desert_color.rgb * deserts * 1.5 * desert_fade);
	// if this is ocean, draw it with extra shine
	color = mix(color, ocean_color.rgb + shine * 3.4, ocean);
	// if this is ground draw our mixed ground color
	color = mix(color, ground_sand_mix, ground);
	// if this is snow/ice apply it to the color
	color = mix(color, vec3(2.0 - ice_cracks), snowt);
	// if this is a desert splotch, draw that color
	color = mix(color, desert_color.rgb + deserts * 1.1, desert
		* mod(ocean + 1.0, 2.0)
		* mod(snowt + 1.0, 2.0)
		* desert_patches
	);
	// cut off the color at the land radius
	color = color * land_alpha;
	//float intensity = fade;
	// apply cloud color based on cloud sample, cut off at cloud radius

	float cloud_overlap = clouds2 - clouds + 0.5;
	if (cloud_overlap < 0.54) {
		cloud_alpha = 0.0;
	}

	color = mix(color, cloud_color.rgb * 3.0, cloud_overlap * cloud_alpha * cloud_opacity);
	// reverse shadow for atmosphere, more intense at the edges
	float fade2 = clamp(0.75 - pow(dist * 2.5, 18.5), 0.0, 1.0);
	// apply the atmosophere to the color
	color = color + (ocean_color.rgb * (4.0 - fade2 * 5.0) * atmosphere_opacity);
	// apply the planet shadow
	color *= fade;
	// final color of the pixel
	COLOR = vec4(color.r, color.g, color.b, atmos_alpha);
}