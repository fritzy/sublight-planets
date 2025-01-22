shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float hpass : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float vpass : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform int radius : hint_range(0, 65, 1) = 65;
render_mode unshaded;

const vec2 OFFSETS[8] = {
	vec2(-0.71, -0.71), vec2(-1, 0), vec2(-0.71, 0.71), vec2(0, -1), vec2(0, 1),
	vec2(0.71, -0.71), vec2(1, 0), vec2(0.71, 0.71)
};


void fragment() {

	//vec4 text = texture(TEXTURE, SCREEN_UV);
	//vec2 size = 10.0 * SCREEN_PIXEL_SIZE;
	float outline = 0.0;
	vec4 blur = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 screen = texture(screen_texture, SCREEN_UV);
	vec4 blur2 = textureLod(screen_texture, SCREEN_UV, 0.7);
	/*
	int iter = 0;
	if (screen.a > 0.001) {
		blur = screen;
	} else {
		for (int id = 0; id <= 50; id++) {
			float scale = (50.0 - float(id)) / 50.0;
			for (int i = 0; i < OFFSETS.length(); i++) {
				iter++;
				vec2 coordinate_offset = SCREEN_UV + (float(id) * SCREEN_PIXEL_SIZE * OFFSETS[i]);
				vec4 color = texture(screen_texture, coordinate_offset);
				blur.rgb = max(blur.rgb, color.rgb);
				//if (color.a > 0.0001) {
				blur.a = max(blur.a, color.a * scale);
				//}
				//blur.a = min(1.0, max(blur.a, color.a * scale));
			}
		}
	}
	*/
	//blur.a = 1.0;
	//blur /= float(iter);
	//blur.rgb /= float(iter);
	//blur.a /= float(iter);
	/*
	float outline = texture(screen_texture, SCREEN_UV + vec2(-size.x, 0)).a;
	outline += texture(screen_texture, SCREEN_UV + vec2(0, size.y)).a;
	outline += texture(screen_texture, SCREEN_UV + vec2(size.x, 0)).a;
	outline += texture(screen_texture, SCREEN_UV + vec2(0, -size.y)).a;
	outline = min(outline, 1.0);
	*/



	if (screen.a > 0.0001) {
		screen.rgb /= screen.a;
	}
	COLOR = blur2;
	//COLOR = vec4(blur.a, blur.a, blur.a, 1.0);
	//COLOR = mix(screen, blur2, blur.a - ceil(screen.a));
	//COLOR = vec4(screen.a,screen.a, screen.a, screen.a);
}
