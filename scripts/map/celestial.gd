@tool
class_name MapCelestial extends Node2D

@export var radius: float = 20.0:
	set(value):
		radius = value
		print ("set radius")
		queue_redraw()

var _coords: PackedVector2Array = []
@export var orbit_radius := 70.0:
	set(value):
		orbit_radius = value
		update_position()
@export_range(0.0, TAU) var orbit_angle := 0.0:
	set(value):
		orbit_angle = value
		update_position()

func _ready() -> void:
	update_position()
	modulate = Color.GREEN

func _draw() -> void:
	#generate_circle()
	#draw_polyline(_coords, Color.WHITE, 2.0)
	draw_circle(Vector2.ZERO, radius, Color.WHITE, 2.0)

func update_position() -> void:
	position = Vector2(cos(orbit_angle) * orbit_radius, sin(orbit_angle) * orbit_radius)
	

func generate_circle(segments: int = 30) -> void:
	_coords = []
	for i in segments:
		var angle = TAU * (float(i) / float(segments))
		_coords.push_back(Vector2(cos(angle) * radius, sin(angle) * radius))
	_coords.push_back(Vector2(cos(0.0) * radius, sin(0.0) * radius))
