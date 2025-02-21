shader_type canvas_item;

uniform sampler2D nebula_area1: repeat_enable;
uniform sampler2D nebula_area2: repeat_enable;
uniform vec3 nebula_color: source_color;

float rand_star(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float starmap(vec2 coord, vec2 uv) {
	float size = 30.0;
	float prob = 0.98;
	vec2 pos = floor(1.0 / size * coord.xy);
	float color = 0.0;
	float starValue = rand_star(pos);

	if (starValue > prob)
	{
		vec2 center = size * pos + vec2(size, size) * 0.5;
		float t = 0.9 + 0.2 * sin(TIME * 3.0 + (starValue - prob) / (1.0 - prob) * 45.0);
		color = 1.0 - distance(coord.xy, center) / (0.5 * size);
		color = color * t / (abs(coord.y - center.y)) * t / (abs(coord.x - center.x));
	}
	else if (rand_star(uv.xy / 20.0) > 0.996)
	{
		float r = rand_star(uv.xy);
		color = r * (0.85 * sin(TIME * 0.2 * (r * 5.0) + 720.0 * r) + 0.95);
	}
	return color;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float nsample1 = texture(nebula_area1,vec2(uv.x * 0.25, uv.y * 1.0)).r;
	float nsample2 = texture(nebula_area2, vec2(uv.x * 0.25, uv.y * 1.0)).r;
	float area = nsample1 + nsample2;
	float dist = distance(vec2(0.0), uv);
	float star = starmap(FRAGCOORD.xy, UV);
	//area *= smoothstep(0.9, 0.0, dist) * 2.0;
	area *= smoothstep(0.7,0.8, area);
	area = area * 0.5;
	COLOR.rgb = vec3(area) * nebula_color + star;
	COLOR.a = 0.4;
}
