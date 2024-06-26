extends Node2D

@onready var shine_slider = $Sliders/ShineSlider
@onready var ice_slider = $Sliders/IceSlider
@onready var ocean_depth_slider = $Sliders/OceanDepthSlider
@onready var ground_color = $GroundColor
@onready var sky_color = $SkyColor
@onready var desert_color = $DesertColor
@onready var planet: ShaderMaterial = $Planet.material

func _ready() -> void:
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