extends Node2D

@export var planet_carousel: Array[PackedScene]
@export var planet_uis: Array[PackedScene]
var planet_idx := 0
var current_planet: Celestial
var current_ui: Control

func _ready() -> void:
	%RightButton.pressed.connect(_handle_right_planet)
	%LeftButton.pressed.connect(_handle_left_planet)

	current_planet = planet_carousel[planet_idx].instantiate()
	$Planets.add_child(current_planet)
	
func _handle_right_planet() -> void:
	await _move_and_remove(current_planet, 1.0)
	planet_idx += 1
	if planet_idx == planet_carousel.size():
		planet_idx = 0
	_load_and_move(1.0)
	print("handle right")

func _handle_left_planet() -> void:
	await _move_and_remove(current_planet, -1.0)
	planet_idx -= 1
	if planet_idx == -1:
		planet_idx = planet_carousel.size() - 1
	_load_and_move(-1.0)
	print("handle left")

func _move_and_remove(planet: Node2D, dir: float) -> void:
	%Camera.rotation = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(planet, "position", Vector2(1200.0 * dir, 0.0), 0.25)
	await tween.finished
	planet.queue_free()
	if current_ui != null:
		current_ui.queue_free()
		current_ui = null

func _load_and_move(dir: float) -> void:
	current_planet = planet_carousel[planet_idx].instantiate()
	%PlanetNameLabel.text = current_planet.celestial_name
	$Planets.add_child(current_planet)
	if planet_uis[planet_idx] != null:
		current_ui = planet_uis[planet_idx].instantiate()
		%PlanetUI.add_child(current_ui)
		current_ui.update_axis.connect(_handle_update_axis)
		current_ui.update_shader_parameter.connect(_handle_update_shader_parameter)

	current_planet.position = Vector2(-dir * 1200.0, 0.0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(current_planet, "position", Vector2(0.0, 0.0), 0.25)
	await tween.finished

func _handle_update_axis(axis: float) -> void:
	%Camera.rotation = axis

func _handle_update_shader_parameter(parameter: StringName, value: Variant) -> void:
	current_planet.set_shader_parameter(parameter, value)
