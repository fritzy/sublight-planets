@tool
extends Node3D

@export_tool_button("Redirect", "Callable")
var redirect_action = redirect

func redirect():
	#$RayCast3D3.target_position = $RayCast3D1.target_position.project($RayCast3D2.target_position);
	$RayCast3D3.target_position = $RayCast3D1.target_position
	$RayCast3D3.rotation = $RayCast3D1.target_position
	prints($RayCast3D1.target_position, $RayCast3D2.target_position, $RayCast3D3.target_position)

