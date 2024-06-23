@tool
class_name MapShip extends Node2D

var _points := [[-15.0, 15.0], [0.0, -15.0], [15.0, 15.0], [-15.0, 15.0]]
var _vector_points: PackedVector2Array

func _ready() -> void:
	_vector_points = float_array_to_Vector2Array(_points)

func _draw() -> void:
	draw_polyline(_vector_points, Color.WHITE, 2.0)

func float_array_to_Vector2Array(coords : Array) -> PackedVector2Array:
	# Convert the array of floats into a PackedVector2Array.
	var array : PackedVector2Array = []
	for coord in coords:
		array.append(Vector2(coord[0], coord[1]))
	return array