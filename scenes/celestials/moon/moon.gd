extends Celestial

var regenerate_button = _regenerate

func _ready() -> void:
	pass

func _regenerate() -> void:
	print("regenerate")
	var texture := NoiseTexture2D.new()
	texture.width = 1024;
	texture.height = 512;
	texture.invert = true
	texture.seamless = true
	texture.normalize = false
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.03
	noise.fractal_lacunarity = 2.2
	noise.fractal_gain = 0.7
	noise.fractal_weighted_strength = 0.0
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	#noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	#noise.fractal_lacunarity = 2.1
	#noise.fractal_gain = 0.42
	#noise.frequency = 0.0054
	noise.seed = randi()
	print(noise.seed)
	texture.noise = noise
	await texture.changed
	$Planet.material.set_shader_parameter('crater1_texture', texture)
	print(1)
	var normal: NoiseTexture2D = texture.duplicate()
	normal.as_normal_map = true
	normal.bump_strength = 6.3
	await normal.changed
	$Planet.material.set_shader_parameter('crater1_normal', normal)
	print(2)