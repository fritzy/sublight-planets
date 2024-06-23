@tool
extends Node2D

func _ready() -> void:
	pass

func _draw() -> void:
	draw_circle(Vector2.ZERO, 250.0, Color.GREEN, false, 2.0)
