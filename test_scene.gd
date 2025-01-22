extends Node2D

@export var ship_parallax_factor = 1.0
@export var planet_parallax_factor = 0.1

var zoom: float = 0.0
var planet_start := 0.1;
var planet_end := 3.0;
var ship_start := 0.000001;
var ship_end := 0.8

func _ready() -> void:
	%GasGiant.scale = Vector2(planet_start, planet_start)
	%Ships.scale = Vector2(ship_start, ship_start)

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		print(%GasGiant.scale)
		print(%Ships.scale)
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(%GasGiant, "scale", Vector2(planet_end, planet_end), 5.0)
		tween.tween_property(%Ships, "scale", Vector2(ship_end, ship_end), 5.0)

func _physics_process2(delta: float) -> void:
	if zoom < 1.0:
		zoom += 0.1 * delta
	else:
		zoom = 1.0
	%GasGiant.scale.x = lerp(planet_start, planet_end, zoom)
	%Ships.scale.x = lerp(ship_start, ship_end, zoom)
	%GasGiant.scale.y = %GasGiant.scale.x
	%Ships.scale.y = %Ships.scale.x
	print(%Ships.scale.x)
