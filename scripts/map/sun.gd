class_name MapSun extends Node2D

@onready var button = %Celestial
@onready var label = $'MapLabel'

@export_range(0.0, 1.0) var radius: float = 0.8:
	set(value):
		radius = value
		if button:
			button.material.set_shader_parameter('star_radius', value)


func _ready() -> void:
	button.connect('pressed', _pressed)
	button.connect('mouse_entered', _focus_entered)
	button.connect('focus_entered', _focus_entered)
	button.connect('mouse_exited', _focus_exited)
	button.connect('focus_exited', _focus_exited)
	label.visible = false
	button.material.set_shader_parameter('star_radius', radius)
	print("ready")
	reset_base_noise()
	reset_highlight_noise(2)
	reset_highlight_noise(3)

func _pressed() -> void:
	print("pressed that sun")
	reset_base_noise()
	reset_highlight_noise(2)
	reset_highlight_noise(3)

func _focus_entered() -> void:
	print("focused")
	label.visible = true

func _focus_exited() -> void:
	print("unfocused")
	label.visible = false

func reset_base_noise() -> void:
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	var color_ramp = Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.0, 0.048, 0.561])
	color_ramp.colors = PackedColorArray([Color.BLACK, Color(0.41, 0.41, 0.41), Color.WHITE])
	texture.color_ramp = color_ramp
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	texture.noise = noise
	await texture.changed
	button.material.set_shader_parameter('noise1', texture)

func reset_highlight_noise(which: int) -> void:
	var param := "noise%d" % [which]
	var texture := NoiseTexture2D.new()
	texture.seamless = true
	var color_ramp = Gradient.new()
	color_ramp.offsets = PackedFloat32Array([0.33, 0.704, 1.0])
	color_ramp.colors = PackedColorArray([Color.BLACK, Color(0.41, 0.41, 0.41), Color.WHITE])
	texture.color_ramp = color_ramp
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = randi()
	noise.frequency = 0.0086
	texture.noise = noise
	await texture.changed
	button.material.set_shader_parameter(param, texture)
