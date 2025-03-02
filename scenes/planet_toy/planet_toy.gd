extends Node2D

@export var planet_carousel: Array[PackedScene]
@export var planet_uis: Array[PackedScene]
var planet_idx := 0
var planets: Array[Celestial]
var uis: Array[BaseCelestialUI]
var current_planet: Celestial
var current_ui: BaseCelestialUI

func _ready() -> void:
	%RightButton.pressed.connect(_handle_right_planet)
	%LeftButton.pressed.connect(_handle_left_planet)
	%VisibilityButton.pressed.connect(_handle_visibility_button)

	_load_planets()
	_show_planet()

func _handle_visibility_button():
	print(%BaseUI)
	%BaseUI.visible = not %BaseUI.visible
	%PlanetUI.visible = not %PlanetUI.visible
	
func _handle_right_planet() -> void:
	await _move_and_hide(current_planet, 1.0)
	planet_idx += 1
	if planet_idx == planet_carousel.size():
		planet_idx = 0
	_show_and_move(1.0)
	print("handle right")

func _handle_left_planet() -> void:
	await _move_and_hide(current_planet, -1.0)
	planet_idx -= 1
	if planet_idx == -1:
		planet_idx = planet_carousel.size() - 1
	_show_and_move(-1.0)
	print("handle left")

func _input(event):
	if event.is_action_pressed("toggle_border"):
		var is_borderless := DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, 0)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, not is_borderless)
	if event.is_action("exit_game"):
		get_tree().quit()

func _move_and_hide(planet: Node2D, dir: float) -> void:
	%Camera.rotation = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(planet, "position", Vector2(1200.0 * dir, 0.0), 0.75)
	if current_ui != null:
		tween.tween_property(current_ui, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.75)
	await tween.finished
	_hide_planet()

func _show_and_move(dir: float) -> void:
	_show_planet()
	current_planet.position = Vector2(-dir * 1200.0, 0.0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(current_planet, "position", Vector2(0.0, 0.0), 0.75)
	if current_ui != null:
		current_ui.modulate = Color(1.0, 1.0, 1.0, 0.0)
		tween.tween_property(current_ui, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75)
	await tween.finished

func _load_planets() -> void:
	for planet_scene: PackedScene in planet_carousel:
		var planet: Celestial = planet_scene.instantiate()
		planets.push_back(planet)
		$Planets.add_child(planet)
		planet.visible = false
		planet.set_process_mode(Node.PROCESS_MODE_DISABLED)
	var pidx := 0
	for ui_scene: PackedScene in planet_uis:
		if ui_scene == null:
			uis.push_back(null)
			continue
		var ui: BaseCelestialUI = ui_scene.instantiate()
		%PlanetUI.add_child(ui)
		ui.visible = false
		ui.set_process_mode(Node.PROCESS_MODE_DISABLED)
		ui.update_axis.connect(_handle_update_axis)
		ui.update_shader_parameter.connect(_handle_update_shader_parameter)
		ui.button_pressed.connect(_handle_button_pressed)
		planets[pidx].updated_shader_parameters.connect(ui.handle_updated_shader_parameters)
		uis.push_back(ui)
		pidx += 1

func _show_planet() -> void:
	current_planet = planets[planet_idx]
	current_planet.visible = true
	current_planet.set_process_mode(Node.PROCESS_MODE_INHERIT)
	%PlanetNameLabel.text = current_planet.celestial_name
	if uis[planet_idx] != null:
		current_ui = uis[planet_idx]
		current_ui.visible = true
		current_ui.set_process_mode(Node.PROCESS_MODE_INHERIT)

func _hide_planet() -> void:
	current_planet.visible = false
	current_planet.set_process_mode(Node.PROCESS_MODE_DISABLED)
	if current_ui != null:
		current_ui.visible = false
		current_ui.set_process_mode(Node.PROCESS_MODE_DISABLED)
		current_ui = null

func _handle_update_axis(axis: float) -> void:
	%Camera.rotation = axis

func _handle_update_shader_parameter(parameter: StringName, value: Variant) -> void:
	current_planet.set_shader_parameter(parameter, value)

func _handle_button_pressed(method: StringName) -> void:
	print('Button %s' % method)
	current_planet.call(method)
