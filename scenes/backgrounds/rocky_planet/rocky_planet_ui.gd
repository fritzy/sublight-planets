extends BaseCelestialUI

@onready var sliders = [%OceanDepthSlider, %IceSlider, %AtmosSlider, %CloudSlider, %CloudSlider2]
@onready var pickers = [%GroundColor, %DesertColor, %SkyColor, %CloudColor]

func _ready() -> void:
	parameter_map = {
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
	super()
