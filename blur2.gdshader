shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 glow_color: source_color;
uniform float glow_radius: hint_range(1.0, 10.0, 1.0) = 10.0;
uniform float glow_shift: hint_range(0.0, 10.0, 0.1) = 3.4;
uniform float glow_power: hint_range(0.0, 10.0, 0.1) = 6.0;

void fragment() {
   //SCREEN_PIXEL_SIZE;
	vec4 screen = texture(screen_texture, SCREEN_UV);
	vec4 glow = vec4(0.0);
	float alpha = 0.0;
	float count = 0.0;
	for (float x = -glow_radius; x <= glow_radius; x += 1.0) {
		for (float y = -glow_radius; y <= glow_radius; y += 1.0) {
			vec2 offset = vec2(x, y) * glow_shift * SCREEN_PIXEL_SIZE;
			glow += texture(screen_texture, SCREEN_UV + offset); // * glow_color;
			count += 1.0;
		}
	}
	glow *= glow_power / count;
	glow.a *= max(screen.a, max(max(glow.r, glow.g), glow.b));
	if (screen.a < 0.0001) {
		//glow.rgb = glow_color.rgb;
	}
	screen.rgb /= screen.a > 0.0001 ? screen.a : 1.0;
	COLOR.rgba = glow;
	//COLOR.a = alpha;
	//COLOR = screen;
}
