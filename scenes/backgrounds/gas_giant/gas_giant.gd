extends Node2D

var star_angle:float = 0.0;

#func _process(delta: float) -> void:
#	star_angle += delta * 0.4
#	star_angle = fmod(star_angle, PI * 2.0)
#	var light_pos := Vector3(sin(star_angle), 0.0, cos(star_angle));

func set_sun_pos(sun_pos: Vector3) -> void:
	%Planet.material.set_shader_parameter("light_direction", sun_pos)
