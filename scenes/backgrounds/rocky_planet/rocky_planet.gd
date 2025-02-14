@tool
extends Celestial

#@onready var shine_slider = %RockyPlanetUI/%ShineSlider
#@onready var ice_slider = %RockyPlanetUI/%IceSlider
#@onready var ocean_depth_slider = %RockyPlanetUI/%OceanDepthSlider
#@onready var ground_color = %RockyPlanetUI/%GroundColor
#@onready var sky_color = %RockyPlanetUI/%SkyColor
#@onready var desert_color = %RockyPlanetUI/%DesertColor
#@onready var desert_button = %RockyPlanetUI/%DesertButton
#@onready var atmos_slider = %RockyPlanetUI/%AtmosSlider
#@onready var cloud_slider = %RockyPlanetUI/%CloudSlider
#@onready var mtn_snow_slider = %RockyPlanetUI/%MtnSnowSlider
#@onready var cloud_dense_slider = %RockyPlanetUI/%CloudSlider2
#@onready var cloud_color = %RockyPlanetUI/%CloudColor
#@onready var rand_color_button = %RockyPlanetUI/%RandColorButton
#@onready var rand_params_button = %RockyPlanetUI/%RandParamsButton

#@onready var reset_button = %RockyPlanetUI/%ResetButton

#@onready var earth_button = %RockyPlanetUI/%EarthButton
#@onready var mars_button = %RockyPlanetUI/%MarsButton
#@onready var random_button = %RockyPlanetUI/%RandomButton

var mouse_over: bool = false;

var surface_gradient: Gradient;
var mtn_gradient: Gradient;
var cloud_gradient: Gradient;
var cloud2_gradient: Gradient;
var ice_gradient: Gradient;
var texture_seed := randi()

const packed_fields = [
	'shine_offset',
	'ocean_depth',
	'speed',
	'ice_coverage',
	'cloud_opacity',
	'desert_patches',
	'atmosphere_opacity',
	'mtn_snow_height',
	'desert_color',
	'ground_color',
	'ocean_color',
	'cloud_color',
]
const packed_version = 1.0
const packed_planet_type = 1.0

var current_values: PackedFloat32Array = [];


@onready var planet: ShaderMaterial = $Planet.material

func _ready() -> void:


	surface_gradient = Gradient.new()
	surface_gradient.offsets = PackedFloat32Array([0.157, 0.357, 0.622, 0.891])
	surface_gradient.colors = PackedColorArray([Color.BLACK, Color(0.34, 0.34, 0.34), Color(0.69, 0.69, 0.69), Color.WHITE])

	mtn_gradient = Gradient.new()
	mtn_gradient.offsets = PackedFloat32Array([0.447, 1.0])
	mtn_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])

	cloud_gradient = Gradient.new()
	cloud_gradient.offsets = PackedFloat32Array([0.543, 1.0])
	cloud_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])

	cloud2_gradient = Gradient.new()
	cloud2_gradient.offsets = PackedFloat32Array([0.477, 0.719])
	cloud2_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])

	ice_gradient = Gradient.new()
	ice_gradient.offsets = PackedFloat32Array([0.503, 0.784, 1.0])
	ice_gradient.colors = PackedColorArray([Color.BLACK, Color(0.34, 0.34, 0.34), Color.WHITE])

	#%RockyPlanetUI/%NotifyPanel.position.y = -%RockyPlanetUI/%NotifyPanel.size.y
	
	if OS.has_feature('web'):
		load_from_url()
	else:
		generate_earth()
		update_inputs()

	#shine_slider.value_changed.connect(_set_shine)
	#ice_slider.value_changed.connect(_set_ice)
	#sky_color.color_changed.connect(_set_sky_color)
	#ground_color.color_changed.connect(_set_ground_color)
	#cloud_color.color_changed.connect(func(color): planet.set_shader_parameter('cloud_color', color))
	#desert_color.color_changed.connect(_set_desert_color)
	#ocean_depth_slider.value_changed.connect(_set_ocean_depth)
	#atmos_slider.value_changed.connect(func(value): planet.set_shader_parameter('atmosphere_opacity', value))
	#cloud_slider.value_changed.connect(func(value): planet.set_shader_parameter('cloud_opacity', value))
	#cloud_dense_slider.value_changed.connect(func(value): planet.set_shader_parameter('cloud_density', value))
	#mtn_snow_slider.value_changed.connect(func(value): planet.set_shader_parameter('mtn_snow_height', value))
	#reset_button.pressed.connect(func(): regenerate(true))
	#desert_button.toggled.connect(_desert_toggled)
	#rand_color_button.pressed.connect(randomize_colors)
	#rand_params_button.pressed.connect(randomize_params)
	#earth_button.pressed.connect(generate_earth)
	#mars_button.pressed.connect(generate_mars)
	#random_button.pressed.connect(generate_random)
	#%RockyPlanetUI/%VisibilityButton.toggled.connect(toggle_panel_visiblity)
	#%RockyPlanetUI/%CameraButton.pressed.connect(take_screenshot)
	#%Planet.mouse_entered.connect(func(): mouse_over = true)
	#%Planet.mouse_exited.connect(func(): mouse_over = false)
	#%RockyPlanetUI/%ShareButton.pressed.connect(copy_planet_link)

	#show_notification("Welcome to Sublight Planets by @fritzy")

func update_inputs() -> void:
	var props := planet.get_property_list()
	var parameters: Dictionary[StringName, Variant] = {}
	for property in props:
		if String(property.name).begins_with("shader_parameter"):
			#prints(property.name, property.type)
			if property.type != Variant.Type.TYPE_OBJECT:
				var pname = String(property.name).substr(17)
				parameters[StringName(pname)] = planet.get(property.name)
	updated_shader_parameters.emit(
		parameters
	)

func load_from_url() -> void:
	var window = JavaScriptBridge.get_interface('window')
	var data = window.getPlanetData()
	print(data)
	if data:
		load_packed_value(data)
	else:
		print("no data")
		generate_earth()
		update_inputs()


func copy_planet_link() -> void:
	var data = save_packed_value().uri_encode()
	var link = "https://fritzy.itch.io/sublight-planets?planet_data=%s" % data
	DisplayServer.clipboard_set(link)
	var window = JavaScriptBridge.get_interface('window')
	window.navigator.clipboard.readText()
	show_notification("Copied this planet link to clipboard for sharing!")

func refresh_data() -> void:
	var data = save_packed_value()
	%DataInput.text = data

func save_packed_value() -> String:
	var saved_value: PackedFloat32Array = []
	var values := get_shader_params()
	saved_value.push_back(packed_version) # version
	saved_value.push_back(packed_planet_type) # planet
	saved_value.push_back(texture_seed) # planet
	for field in packed_fields:
		if field.ends_with('_color'):
			saved_value.push_back(values[field].r)
			saved_value.push_back(values[field].g)
			saved_value.push_back(values[field].b)
		else:
			saved_value.push_back(values[field])
	return Marshalls.raw_to_base64(saved_value.to_byte_array())

func load_packed_value(data) -> void:
	var bytearray := Marshalls.base64_to_raw(data)
	var floats := Array(bytearray.to_float32_array())
	var values = {}
	var version = floats.pop_front()
	var planet_type = floats.pop_front()
	texture_seed = int(floats.pop_front())
	var value
	for field in packed_fields:
		if field.ends_with('_color'):
			value = Color(floats.pop_front(), floats.pop_front(), floats.pop_front())
		else:
			value = floats.pop_front()
		values[field] = value
		#planet.set_shader_parameter(field, value)
	set_shader_values(values)
	update_inputs()
	regenerate()
	
func take_screenshot() -> void:
	if %RockyPlanetUI/%VisibilityButton.button_pressed:
		%RockyPlanetUI/%DisplayPanel.visible = false
		%RockyPlanetUI/%NotifyPanel.visible = false
		await get_tree().create_timer(0.5).timeout
	var image := get_viewport().get_texture().get_image()
	if OS.has_feature('web'):
		var buf := image.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buf, 'sublight-screenshot.png', 'image/png')
		show_notification('Downloading screenshot "sublight-screenshot.png"')
	else:
		var save_path = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		var dir = DirAccess.open(save_path)
		var files = []
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					#print("Found file: " + file_name)
					if file_name.begins_with('sublight-screenshot-'):
						files.push_back(file_name)
				file_name = dir.get_next()
		var id = 1;
		if files.size() > 0:
			files.sort()
			var file_name = files.pop_back()
			var parts = file_name.split('-');
			# it's okay to have trailing characters
			id = parts[2].to_int() + 1
		var img_file_name = "%s/%s" % [OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), 'sublight-screenshot-%d.png' % id]
		image.save_png(img_file_name)
		%RockyPlanetUI/%NotifyPanel.visible = true
		show_notification("Saved screenshot: %s" % img_file_name)
	await get_tree().create_timer(1.0).timeout
	%RockyPlanetUI/%DisplayPanel.visible = true
	%RockyPlanetUI/%NotifyPanel.visible = true

func toggle_panel_visiblity(toggle: bool) -> void:
	%RockyPlanetUI/%PresetPanel.visible = not toggle
	%RockyPlanetUI/%ParamPanel.visible = not toggle
	%RockyPlanetUI/%ColorPanel.visible = not toggle
	# panel not sizing correctly after visiblity toggle
	%RockyPlanetUI/%ColorPanel.set_size(%RockyPlanetUI/%ColorPanel.get_minimum_size())
	%RockyPlanetUI/%ParamPanel.set_size(%RockyPlanetUI/%ParamPanel.get_minimum_size())
	%RockyPlanetUI/%PresetPanel.set_size(%RockyPlanetUI/%PresetPanel.get_minimum_size())

#func _set_shine(value) -> void:
#	planet.set_shader_parameter('shine_offset', shine_slider.value)

#func _set_ice(value) -> void:
#	planet.set_shader_parameter('ice_coverage', ice_slider.value)

func _input(event):
	# Mouse in viewport coordinates.
	if mouse_over and %Planet.button_pressed and (event is InputEventMouseMotion or event is InputEventMouseButton):
		var pos = %Planet.get_local_mouse_position()
		var width = %Planet.size.x
		var height = %Planet.size.y
		planet.set_shader_parameter('shine_offset', Vector2(pos.x / width, pos.y / height))

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

func randomize_colors() -> void:
	var params := ['ocean_color', 'ground_color', 'desert_color', 'cloud_color']
	for param in params:
		planet.set_shader_parameter(param, Color(randf(), randf(), randf()))
	update_inputs()

func randomize_params() -> void:
	#planet.set_shader_parameter('shine_offset', randf())
	planet.set_shader_parameter('ice_coverage', randf())
	#planet.set_shader_parameter('ocean_color', randf())
	planet.set_shader_parameter('ocean_depth', randf() * 2.0)
	planet.set_shader_parameter('atmosphere_opacity', randf())
	planet.set_shader_parameter('cloud_opacity', randf())
	#planet.set_shader_parameter('mtn_snow_height', randf())
	planet.set_shader_parameter('desert_patches', float(bool(randi_range(0, 1))))
	regenerate_clouds()
	update_inputs()

func regenerate(new_seed: bool = false) -> void:
	if new_seed:
		texture_seed = randi()
	regenerate_ground()
	regenerate_desert()
	regenerate_clouds()
	regenerate_ice()

func _unhandled_input(event) -> void:
	if event.is_action_pressed('ui_accept'):
		print_shader_params()

func get_shader_params() -> Dictionary:
	var out: Dictionary = {}
	var list = planet.get_property_list()
	for item in list:
		if item.name.begins_with('shader_parameter/') and not item.name.ends_with('texture') and not item.name.ends_with('texture2'):
			var parts = item.name.split('/')
			var value = planet.get_shader_parameter(parts[1])
			out[parts[1]] = value
	return out

func print_shader_params() -> void:
	var list = planet.get_property_list()
	for item in list:
		if item.name.begins_with('shader_parameter/') and not item.name.ends_with('texture') and not item.name.ends_with('texture2'):
			var parts = item.name.split('/')
			prints(parts[1], '=', planet.get_shader_parameter(parts[1]))

func generate_earth() -> void:
	var values := {
		shine_offset = Vector2(0.6, 0.5),
		ocean_depth = 0.7,
		speed = 0.05,
		ice_coverage = 0.51,
		cloud_density = 0.36,
		cloud_opacity = 0.7,
		desert_patches = 1,
		atmosphere_opacity = 0.25,
		mtn_snow_height = 1.54,
		desert_color = Color(0.6328, 0.6218, 0.2917, 1),
		ground_color = Color(0.2131, 0.4805, 0.1276, 1),
		ocean_color = Color(0, 0.2277, 0.5703, 1),
		cloud_color = Color(1, 1, 1, 1),
	}
	set_shader_values(values)
	update_inputs()
	regenerate(true)

func generate_mars() -> void:
	var values := {
		shine_offset = Vector2(0.41, 0.5),
		ocean_depth = 0,
		speed = 0.05,
		ice_coverage = 0.44,
		cloud_opacity = 0.1,
		cloud_density = 0.5,
		desert_patches = 0,
		atmosphere_opacity = 0.14,
		mtn_snow_height = 2.0,

		desert_color = Color(0.4805, 0.1702, 0.0488, 1),
		ground_color = Color(0.4727, 0.141, 0.0868, 1),
		ocean_color = Color(0.0665, 0.2287, 0.4727, 1),
		cloud_color = Color(0.457, 0.3304, 0.0303, 1),
	}
	set_shader_values(values)
	update_inputs()
	regenerate(true)

func generate_random() -> void:
	randomize_params()
	randomize_colors()
	regenerate(true)

func set_shader_values(values: Dictionary) -> void:
	for param in values:
		planet.set_shader_parameter(param, values[param])

func regenerate_ground() -> void:
	var texture := NoiseTexture2D.new()
	texture.width = 1024;
	texture.height = 512;
	texture.seamless = true
	texture.color_ramp = surface_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.0054
	#noise.frequency = 0.0054
	noise.seed = texture_seed
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('surface_texture', texture)
	var normal: NoiseTexture2D = texture.duplicate()
	normal.as_normal_map = true
	await normal.changed
	planet.set_shader_parameter('surface_normal', normal)

	var mtn_texture := NoiseTexture2D.new()
	mtn_texture.width = 1024;
	mtn_texture.height = 512;
	mtn_texture.seamless = true
	mtn_texture.color_ramp = mtn_gradient
	var noise2 = FastNoiseLite.new()
	noise2.noise_type = FastNoiseLite.TYPE_CELLULAR

	noise2.frequency = 0.0238
	noise2.fractal_lacunarity = 2.5
	noise2.fractal_gain = 0.8
	noise2.fractal_weighted_strength = 0.5

	noise2.seed = texture_seed
	mtn_texture.noise = noise2
	await mtn_texture.changed
	planet.set_shader_parameter('mountain_texture', mtn_texture)
	var mtn_normal: NoiseTexture2D = mtn_texture.duplicate()
	mtn_normal.as_normal_map = true
	await mtn_normal.changed
	planet.set_shader_parameter('mountain_normal', mtn_normal)

func regenerate_desert() -> void:
	var texture := NoiseTexture2D.new()
	texture.width = 1024;
	texture.height = 512;
	texture.seamless = true
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.0087
	noise.seed = texture_seed
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('desert_texture', texture)

func regenerate_clouds() -> void:
	#var density = min(cloud_density, 0.9)
	var density = 0.5;
	prints("regenerating clouds", density)
	var texture := NoiseTexture2D.new()
	texture.width = 1024;
	texture.height = 512;
	texture.seamless = true
	#texture.color_ramp =l cloud_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	#noise.domain_warp_enabled = true
	# 0.0193
	#noise.frequency = 0.0383 * max(1.0 - density, 0.5)
	noise.frequency = 0.0175
	noise.seed = texture_seed
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('cloud_texture', texture)

	var texture2 := NoiseTexture2D.new()
	texture2.width = 1024;
	texture2.height = 512;
	texture2.seamless = true
	cloud2_gradient = Gradient.new()
	cloud2_gradient.offsets = PackedFloat32Array([min(0.9 * (1.0 - density), 0.7), 0.719])
	print(cloud2_gradient.offsets)
	cloud2_gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])
	texture2.color_ramp = cloud2_gradient
	var noise2 = FastNoiseLite.new()
	noise2.domain_warp_enabled = true
	noise2.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# 0.0039
	noise2.frequency = 0.0039
	noise2.seed = texture_seed
	texture2.noise = noise2
	await texture2.changed
	planet.set_shader_parameter('cloud_texture2', texture2)

func regenerate_ice() -> void:
	var texture := NoiseTexture2D.new()
	texture.width = 1024;
	texture.height = 512;
	texture.seamless = true
	texture.color_ramp = ice_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.0524
	noise.seed = texture_seed
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('ice_texture', texture)

func show_notification(text: String) -> void:
	%RockyPlanetUI/%NotifyLabel.text = text
	print(text)
	var tween := create_tween()
	tween.tween_property(%RockyPlanetUI/%NotifyPanel, 'position:y', 0.0, 0.5)
	tween.tween_property(%RockyPlanetUI/%NotifyPanel, 'position:y', -%RockyPlanetUI/%NotifyPanel.size.y, 0.5).set_delay(3.0)
