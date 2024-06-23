@tool
class_name MapPlanet extends MapCelestial

@export var orbit_speed := 0.05

func disabled_physics_process(delta: float) -> void:
	orbit_angle += orbit_speed * delta
	update_position()
