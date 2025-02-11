extends Control
class_name BaseCelestialUI

signal update_shader_parameter(StringName, Variant)
signal update_axis(float)
signal button_pressed(StringName)

var parameter_map: Dictionary[StringName, Variant] = {}
var button_map: Dictionary[Button, Variant] = {}

func _ready() -> void:
	connect_parameter_inputs()
	connect_buttons()

func handle_updated_shader_parameters(parameters: Dictionary[StringName, Variant]) -> void:
	for pname in parameters:
		if not parameter_map.has(pname):
			continue
		var control = parameter_map[pname]
		if control is Slider:
			control.set_value_no_signal(parameters[pname])
		elif control is ColorPickerButton:
			control.color = parameters[pname]
		elif control is CheckButton:
			control.button_pressed = bool(parameters[pname])

func connect_parameter_inputs() -> void:
	for parameter in parameter_map:
		var control = parameter_map[parameter]
		if control is Slider:
			control.value_changed.connect(
				func(value):
					update_shader_parameter.emit(parameter, value)
			)
		elif control is ColorPickerButton:
			control.color_changed.connect(
				func(value):
					update_shader_parameter.emit(parameter, value)
			)
		elif control is CheckButton:
			control.toggled.connect(
				func(value):
					prints(parameter, value)
					var output := float(value)
					update_shader_parameter.emit(parameter, output)
			)

func connect_buttons() -> void:
	for button: Button in button_map:
		var parameter = button_map[button]
		if parameter is StringName:
			button.pressed.connect(
				func():
					button_pressed.emit(parameter)
			)
		elif parameter is Callable:
			button.pressed.connect(parameter)
