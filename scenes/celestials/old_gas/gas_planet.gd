@tool 
extends Node2D

func _ready() -> void:
	var noise_seed := randi()

	var gas1_tex := NoiseTexture2D.new()
	gas1_tex.seamless = true
	var noise1 := FastNoiseLite.new()
	noise1.frequency = 0.01
	noise1.domain_warp_enabled = true
	noise1.domain_warp_amplitude = 50.0
	noise1.domain_warp_frequency = 0.05
	noise1.domain_warp_fractal_octaves = 5
	noise1.domain_warp_fractal_lacunarity = 6
	noise1.domain_warp_fractal_gain = 0.7
	gas1_tex.noise = noise1
	gas1_tex.noise.seed = noise_seed
	var gas1_norm = gas1_tex.duplicate()
	gas1_norm.as_normal_map = true
	$Planet.material.set_shader_parameter('gas1_texture', gas1_tex)
	$Planet.material.set_shader_parameter('gas1_normal', gas1_norm)

	var gas2_tex := NoiseTexture2D.new()
	gas2_tex.seamless = true
	var noise2 := FastNoiseLite.new()
	gas2_tex.noise = noise2
	noise2.frequency = 0.0046
	noise2.fractal_gain = 0.35
	noise2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise2.domain_warp_enabled = false
	#noise2.domain_warp_amplitude = 20.0
	#noise2.domain_warp_frequency = 0.08
	#noise2.domain_warp_fractal_octaves = 9.0
	#noise2.domain_warp_fractal_lacunarity = 4.0
	gas2_tex.noise.seed = noise_seed
	#gas2_tex.noise.fractal_weighted_strength = 0.98;
	#gas2_tex.noise.frequency = 0.0048
	var gas2_norm = gas2_tex.duplicate()
	gas2_norm.as_normal_map = true
	$Planet.material.set_shader_parameter('gas2_texture', gas2_tex)
	$Planet.material.set_shader_parameter('gas2_normal', gas2_norm)


	var gas3_tex := NoiseTexture2D.new()
	gas3_tex.seamless = true
	var noise3 := FastNoiseLite.new()
	gas3_tex.noise = noise3
	#noise3.frequency = 0.0071
	noise3.frequency = 0.003
	noise3.fractal_gain = 0.3
	noise3.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise3.domain_warp_enabled = false
	#noise2.domain_warp_amplitude = 20.0
	#noise2.domain_warp_frequency = 0.08
	#noise2.domain_warp_fractal_octaves = 9.0
	#noise2.domain_warp_fractal_lacunarity = 4.0
	gas3_tex.noise.seed = noise_seed + 1
	#gas2_tex.noise.fractal_weighted_strength = 0.98;
	#gas2_tex.noise.frequency = 0.0048
	$Planet.material.set_shader_parameter('gas3_texture', gas3_tex)
