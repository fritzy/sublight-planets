@tool
extends Node2D

@onready var outline: Line2D = $Outline
@onready var collision: CollisionPolygon2D = $Collision

@export_tool_button("Mirror")
var mirror_button_action: Callable = func():
	var count := outline.get_point_count()
	for idx:int in range(0, outline.get_point_count() / 2):
		var point := outline.get_point_position(idx)
		prints(idx, idx * 2, Vector2(-point.x, point.y))
		outline.set_point_position(count - idx , Vector2(-point.x, point.y))

@export_tool_button("Flip Y")
var flip_y_button_action: Callable = func():
	var count := outline.get_point_count()
	for idx:int in range(0, count):
		var point := outline.get_point_position(idx)
		prints(idx, Vector2(point.x, -point.y))
		outline.set_point_position(idx, Vector2(point.x, -point.y))

@export_tool_button("Apply Collision")
var collision_button_action: Callable = func():
	print("doing the thing")
	collision.polygon = PackedVector2Array(outline.points)

func _ready() -> void:
	pass
