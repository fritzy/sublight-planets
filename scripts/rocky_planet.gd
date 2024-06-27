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
@onready var cloud_color = %CloudColor
@onready var rand_color_button = %RandColorButton
@onready var rand_params_button = %RandParamsButton

@onready var reset_button = %ResetButton

@onready var earth_button = %EarthButton
@onready var mars_button = %MarsButton
@onready var random_button = %RandomButton

var surface_gradient: Gradient;
var cloud_gradient: Gradient;
var cloud2_gradient: Gradient;
var ice_gradient: Gradient;

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

	ice_gradient = Gradient.new()
	ice_gradient.offsets = PackedFloat32Array([0.503, 0.784, 1.0])
	ice_gradient.colors = PackedColorArray([Color.BLACK, Color(0.34, 0.34, 0.34), Color.WHITE])

	%NotifyPanel.position.y = -%NotifyPanel.size.y
	
	generate_earth()
	update_inputs()

	shine_slider.value_changed.connect(_set_shine)
	ice_slider.value_changed.connect(_set_ice)
	sky_color.color_changed.connect(_set_sky_color)
	ground_color.color_changed.connect(_set_ground_color)
	cloud_color.color_changed.connect(func(color): planet.set_shader_parameter('cloud_color', color))
	desert_color.color_changed.connect(_set_desert_color)
	ocean_depth_slider.value_changed.connect(_set_ocean_depth)
	atmos_slider.value_changed.connect(func(value): planet.set_shader_parameter('atmosphere_opacity', value))
	cloud_slider.value_changed.connect(func(value): planet.set_shader_parameter('cloud_opacity', value))
	cloud_dense_slider.drag_ended.connect(func(value): cloud_density = cloud_dense_slider.value)
	mtn_snow_slider.value_changed.connect(func(value): planet.set_shader_parameter('mtn_snow_height', value))
	reset_button.pressed.connect(regenerate)
	desert_button.toggled.connect(_desert_toggled)
	rand_color_button.pressed.connect(randomize_colors)
	rand_params_button.pressed.connect(randomize_params)
	earth_button.pressed.connect(generate_earth)
	mars_button.pressed.connect(generate_mars)
	random_button.pressed.connect(generate_random)
	%VisibilityButton.toggled.connect(toggle_panel_visiblity)
	%CameraButton.pressed.connect(take_screenshot)

	show_notification("Sublight Planet Generator")

func update_inputs() -> void:
	shine_slider.value = planet.get_shader_parameter('shine_offset')
	ice_slider.value = planet.get_shader_parameter('ice_coverage')
	sky_color.color = planet.get_shader_parameter('ocean_color')
	ground_color.color = planet.get_shader_parameter('ground_color')
	cloud_color.color = planet.get_shader_parameter('cloud_color')
	desert_color.color = planet.get_shader_parameter('desert_color')
	ocean_depth_slider.value = planet.get_shader_parameter('ocean_depth')
	atmos_slider.value = planet.get_shader_parameter('atmosphere_opacity')
	cloud_slider.value = planet.get_shader_parameter('cloud_opacity')
	cloud_dense_slider.value = cloud_density
	mtn_snow_slider.value = planet.get_shader_parameter('mtn_snow_height')
	var dpatches: float = planet.get_shader_parameter('desert_patches')
	if dpatches > 0.1:
		desert_button.button_pressed = true
	else:
		desert_button.button_pressed = false
	
func take_screenshot() -> void:
	if %VisibilityButton.button_pressed:
		%DisplayPanel.visible = false
		%NotifyPanel.visible = false
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
		%NotifyPanel.visible = true
		show_notification("Saved screenshot: %s" % img_file_name)
	await get_tree().create_timer(1.0).timeout
	%DisplayPanel.visible = true
	%NotifyPanel.visible = true

func toggle_panel_visiblity(toggle: bool) -> void:
	%PresetPanel.visible = not toggle
	%ParamPanel.visible = not toggle
	%ColorPanel.visible = not toggle
	# panel not sizing correctly after visiblity toggle
	%ColorPanel.set_size(%ColorPanel.get_minimum_size())
	%ParamPanel.set_size(%ParamPanel.get_minimum_size())
	%PresetPanel.set_size(%PresetPanel.get_minimum_size())

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

func randomize_colors() -> void:
	var pickers = [%GroundColor, %DesertColor, %SkyColor, %CloudColor]
	for picker in pickers:
		picker.color = Color(randf(), randf(), randf())
		picker.color_changed.emit(picker.color)

func randomize_params() -> void:
	var sliders = [%ShineSlider, %OceanDepthSlider, %IceSlider, %AtmosSlider, %CloudSlider, %CloudSlider2]
	for slider in sliders:
		slider.value = randf_range(slider.min_value, slider.max_value)
	var toggles = [%DesertButton]
	for toggle in toggles:
		toggle.button_pressed = bool(randi_range(0, 1))

func regenerate() -> void:
	regenerate_ground()
	regenerate_desert()
	regenerate_clouds()
	regenerate_ice()

func _unhandled_input(event) -> void:
	if event.is_action_pressed('ui_accept'):
		print_shader_params()

func print_shader_params() -> void:
	var list = planet.get_property_list()
	for item in list:
		if item.name.begins_with('shader_parameter/') and not item.name.ends_with('texture') and not item.name.ends_with('texture2'):
			var parts = item.name.split('/')
			prints(parts[1], '=', planet.get_shader_parameter(parts[1]))

func generate_earth() -> void:
	var values := {
		shine_offset = 0.716,
		ocean_depth = 0.62,
		speed = 0.1,
		ice_coverage = 0.671,
		cloud_opacity = 0.6,
		desert_patches = 1.0,
		atmosphere_opacity = 0.54,
		mtn_snow_height = 0.886,
		desert_color = Color(0.7256, 0.5762, 0.1574, 1),
		ground_color = Color(0.3594, 0.7091, 0.1637, 1),
		ocean_color = Color(0.0032, 0.318, 0.792, 1),
		cloud_color = Color(1, 1, 1, 1),
	}
	cloud_density = 0.5
	set_shader_values(values)
	update_inputs()
	regenerate()

func generate_mars() -> void:
	var values := {
		shine_offset = 0.41,
		ocean_depth = 0,
		speed = 0.1,
		ice_coverage = 0.64,
		cloud_opacity = 0.1,
		desert_patches = 0,
		atmosphere_opacity = 0.14,
		mtn_snow_height = 1.09380529158938,
		desert_color = Color(0.7256, 0.4637, 0.1574, 1),
		ground_color = Color(0.7091, 0.1765, 0.1637, 1),
		ocean_color = Color(0.6602, 0.4768, 0.0877, 1),
		cloud_color = Color(0.8762, 0.918, 0.1542, 1),
	}
	cloud_density = 0.5
	set_shader_values(values)
	update_inputs()
	regenerate()

func generate_random() -> void:
	randomize_params()
	randomize_colors()
	regenerate()

func set_shader_values(values: Dictionary) -> void:
	for param in values:
		planet.set_shader_parameter(param, values[param])

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
	planet.set_shader_parameter('surface_texture', texture)

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

func regenerate_ice() -> void:
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	texture.color_ramp = ice_gradient
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.0524
	noise.seed = randi()
	texture.noise = noise
	await texture.changed
	planet.set_shader_parameter('ice_texture', texture)

func show_notification(text: String) -> void:
	%NotifyLabel.text = text
	print(text)
	var tween := create_tween()
	tween.tween_property(%NotifyPanel, 'position:y', 0.0, 0.5)
	tween.tween_property(%NotifyPanel, 'position:y', -%NotifyPanel.size.y, 0.5).set_delay(3.0)