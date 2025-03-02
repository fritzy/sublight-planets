extends Celestial

@export var gradients: Array[GradientTexture1D] = []

func _ready() -> void:
	pass

func set_jupiter_gradient() -> void:
	$Planet.material.set_shader_parameter(&"gas_gradient", gradients[0])

func set_neptune_gradient() -> void:
	$Planet.material.set_shader_parameter(&"gas_gradient", gradients[1])

func set_saturn_gradient() -> void:
	$Planet.material.set_shader_parameter(&"gas_gradient", gradients[2])