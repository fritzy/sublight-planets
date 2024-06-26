extends Node2D

@onready var shine_slider = %ShineSlider
@onready var ice_slider = %IceSlider
@onready var ocean_depth_slider = %OceanDepthSlider
@onready var ground_color = %GroundColor
@onready var sky_color = %SkyColor
@onready var desert_color = %DesertColor
@onready var desert_button = %DesertButton
@onready var atmos_slider = %AtmosSlider
@onready var cloud_slider = %CloudSlider
@onready var mtn_snow_slider = %MtnSnowSlider
@onready var cloud_dense_slider = %CloudSlider2

@onready var reset_button = %ResetButton

var surface_gradient: Gradient;
var cloud_gradient: Gradient;
var cloud2_gradient: Gradient;

var cloud_density := 0.5:
	set(value):
		cloud_density = value
		regenerate_clouds()


@onready var planet: ShaderMaterial = $Planet.material

func _ready() -> void:

	surface_gradient = Gradient.new()
	surface_gradient.offsets = PackedFloat32Array([0.157, 0.357, 0.622, 0.891])
	surface_gradient.colors = PackedColorArray([Color.BLACK, Color(0.34, 0.34, 0.34), Color(0.69, 0.69, 0.69), Color.WHITE])

	cloud_gradient = Gradient.new()
	cloud_gradient.offsets = PackedFloat32Array([0.543, 1.0])
	cloud_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])

	cloud2_gradient = Gradient.new()
	cloud2_gradient.offsets = PackedFloat32Array([0.477, 0.719])
	cloud2_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])

	shine_slider.value = planet.get_shader_parameter('shine_offset')
	shine_slider.value_changed.connect(_set_shine)
	ice_slider.value = planet.get_shader_parameter('ice_coverage')
	ice_slider.value_changed.connect(_set_ice)
	sky_color.color = planet.get_shader_parameter('ocean_color')
	sky_color.color_changed.connect(_set_sky_color)
	ground_color.color = planet.get_shader_parameter('ground_color')
	ground_color.color_changed.connect(_set_ground_color)
	desert_color.color = planet.get_shader_parameter('desert_color')
	desert_color.color_changed.connect(_set_desert_color)
	ocean_depth_slider.value = planet.get_shader_parameter('ocean_depth')
	ocean_depth_slider.value_changed.connect(_set_ocean_depth)

	atmos_slider.value = planet.get_shader_parameter('atmosphere_opacity')
	atmos_slider.value_changed.connect(func(value): planet.set_shader_parameter('atmosphere_opacity', value))

	cloud_slider.value = planet.get_shader_parameter('cloud_opacity')
	cloud_slider.value_changed.connect(func(value): planet.set_shader_parameter('cloud_opacity', value))

	cloud_dense_slider.value = cloud_density
	cloud_dense_slider.value_changed.connect(func(value): cloud_density = value)

	mtn_snow_slider.value = planet.get_shader_parameter('mtn_snow_height')
	mtn_snow_slider.value_changed.connect(func(value): planet.set_shader_parameter('mtn_snow_height', value))

	reset_button.pressed.connect(regenerate)

	var dpatches: float = planet.get_shader_parameter('desert_patches')
	if dpatches > 0.1:
		desert_button.button_pressed = true
	else:
		desert_button.button_pressed = false
	desert_button.toggled.connect(_desert_toggled)

func _set_shine(value) -> void:
	planet.set_shader_parameter('shine_offset', shine_slider.value)

func _set_ice(value) -> void:
	planet.set_shader_parameter('ice_coverage', ice_slider.value)

func _set_sky_color(value) -> void:
	planet.set_shader_parameter('ocean_color', value)

func _set_ground_color(value) -> void:
	planet.set_shader_parameter('ground_color', value)

func _set_desert_color(value) -> void:
	planet.set_shader_parameter('desert_color', value)

func _set_ocean_depth(value) -> void:
	planet.set_shader_parameter('ocean_depth', value)

func _desert_toggled(value) -> void:
	if value:
		planet.set_shader_parameter('desert_patches', 1.0)
	else:
		planet.set_shader_parameter('desert_patches', 0.0)

func regenerate() -> void:
	regenerate_ground()
	regenerate_desert()
	regenerate_clouds()

func regenerate_ground() -> void:
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	texture.color_ramp = surface_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.0054
	noise.seed = randi()
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('surface', texture)

func regenerate_desert() -> void:
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.0087
	noise.seed = randi()
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('desert_texture', texture)

func regenerate_clouds() -> void:
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	texture.color_ramp = cloud_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	# 0.0193
	noise.frequency = 0.0386 * (1.0 - cloud_density)
	noise.seed = randi()
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('cloud_texture', texture)

	var texture2 := NoiseTexture2D.new()
	texture2.seamless = true
	cloud2_gradient = Gradient.new()
	cloud2_gradient.offsets = PackedFloat32Array([min(0.9 * (1.0 - cloud_density), 0.70), 0.719])
	print(cloud2_gradient.offsets)
	cloud2_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])
	texture2.color_ramp = cloud2_gradient
	var noise2 = FastNoiseLite.new()
	noise2.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# 0.0039
	noise2.frequency = noise.frequency * 0.2027253
	noise2.seed = randi()
	texture2.noise = noise2
	await texture2.changed
	planet.set_shader_parameter('cloud_texture2', texture2)
