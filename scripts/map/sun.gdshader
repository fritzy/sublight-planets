shader_type canvas_item;

uniform float star_radius: hint_range(0.0, 1.0) = 0.8;
// noise with dark spots
uniform sampler2D noise1: repeat_enable;
// cellular for flame highlights
uniform sampler2D noise2: repeat_enable;
uniform sampler2D noise3: repeat_enable;

uniform vec3 baseColor: source_color;
uniform vec3 highColor: source_color;

// for every pixel
void fragment() {
	// sample noise1 moving left slowly
	float n1sample = texture(noise1, UV + vec2(0.01, 0.0) * TIME).r;
	// sample it again, but only at the center so as to be the same for every
	// fragement to get flaring random noise
	float n1intensity = texture(noise2, vec2(0.1, 0.0) * TIME).r;
	// flame highlights heading opposite directions
	float n2sample = texture(noise2, UV + vec2(0.05, 0.0) * TIME).r;
	float n3sample = texture(noise3, UV + vec2(-0.05, 0.0) * TIME).r;
	// distance from center
	float dist = distance(UV, vec2(0.5, 0.5));

	// the radius of the sun
	// alpha pixels outside of 0.4 from the center
	float alpha = mix(1.0, 0.0, step(star_radius / 2.0, dist));
	// us noise1 intensity sample to get an intensity
	float mult = 0.4 + n1intensity * .4;
	// base sample is red sun with dark spots
	vec3 color1 = baseColor * n1sample;
	// orange-yellow for highlights from noise 2 and 3
	vec3 high1 = highColor * n2sample;
	vec3 high2 = highColor * n3sample;
	// generate our highlight
	vec3 color2 = high1 * high2 * 5.0;
	// add the highlight to the base red based on intensity
	vec3 color3 = vec3(color1.r + color2.r * mult, color1.g + color2.g * mult, color1.b + color2.b * mult);
	// fade based on the distance
	//vec3 color3 = color1;
	float fade = 0.36 - dist;
	// apply our color
	COLOR = vec4(color3.r, color3.g, color3.b, alpha); // * n2sample;
	// fade and flicker
	COLOR.rgb *= fade * 10.0 + (n1intensity * 0.7);
	
	// get average color
	float avg = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	// green
	//COLOR.rgb = vec3(0.0, avg, 0.0);

}
