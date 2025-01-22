shader_type canvas_item;

uniform sampler2D flicker_noise: repeat_enable;
uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 highlight: source_color = vec3(1.0, 1.0, 1.0);
uniform float hl_threshold: hint_range(0.0, 1.0) = 0.9;
uniform float hl_intensity: hint_range(0.0, 1.0, 0.01) = 0.8;

void fragment() {
	float flicker = texture(flicker_noise,
		vec2(TIME * 0.7, TIME * 0.7) * 0.2).r * 0.15 - 0.075;
	//flicker = 0.0;
	vec4 grad = texture(TEXTURE, UV);
	vec4 linec = grad * color;

	float is_bright = smoothstep(1.0 - (hl_threshold + flicker), 1.0, linec.a);
	linec.rgb = mix(linec.rgb, highlight, is_bright * hl_intensity + flicker);
	COLOR = vec4(linec.rgb, linec.a + flicker);
	//COLOR.a = 0.0;
	//COLOR = vec4(flicker * 8.0);
}