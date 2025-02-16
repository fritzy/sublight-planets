extends BaseCelestialUI

@onready var sliders = [%OceanDepthSlider, %IceSlider, %AtmosSlider, %CloudSlider, %CloudSlider2]
@onready var pickers = [%GroundColor, %DesertColor, %SkyColor, %CloudColor]

var axis := 0.0
var orbit := 0.0
var lock_axis := false
var rotate := false

func _ready() -> void:
	parameter_map = {
		&"orbit": %OrbitSlider,
		&"axis": %AxisSlider,
		&"ice_coverage": %IceSlider,
		&"ocean_depth": %OceanDepthSlider,
		&"atmosphere_opacity": %AtmosSlider,
		&"cloud_opacity": %CloudSlider,
		&"cloud_density": %CloudSlider2,
		&"mtn_snow_height": %MtnSnowSlider,
		&"desert_patches": %DesertButton,
		&"ocean_color": %SkyColor,
		&"ground_color": %GroundColor,
		&"cloud_color": %CloudColor,
		&"desert_color": %DesertColor,
	}
	button_map = {
		%EarthButton: &"generate_earth",
		%MarsButton: &"generate_mars",
		%RandomButton: &"generate_random",
		%RandParamsButton: &"randomize_params",
		%RandColorButton: &"randomize_colors",
	}
	%OrbitSlider.value_changed.connect(func(value):
		orbit = value
		_update_gizmo()
	)
	%AxisSlider.value_changed.connect(func(value):
		axis = value
		_update_gizmo()
	)
	%TiltToggle.toggled.connect(func(value):
		lock_axis = value
		_update_gizmo()
	)
	%RotateToggle.toggled.connect(func(value):
		rotate = value
	)
	super()

func _process(delta) -> void:
	if rotate:
		orbit += delta * 0.5
		if orbit >= PI:
			orbit = -PI + orbit - PI
		_update_gizmo()
		update_shader_parameter.emit(&"orbit", orbit)

func _update_gizmo() -> void:
	if lock_axis:
		update_axis.emit(axis)
	else:
		update_axis.emit(0.0)
	%SunGizmo.update(axis, orbit, lock_axis)
