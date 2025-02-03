extends Control

@onready var axis_slider:HSlider = %Axis
@onready var orbit_slider:HSlider = %Orbit
var axis := 0.0
var orbit := 0.0

const HPI = PI/2.0
const QPI = PI/4.0

func _ready() -> void:
	axis_slider.value_changed.connect(_update_axis)
	orbit_slider.value_changed.connect(_update_orbit)
	prints(size)
	resized.connect(func(): queue_redraw())
	%LockCamera.toggled.connect(func(_value: bool): queue_redraw())
	#queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y / 2.0)
	#self.position = center
	var radius := float(min(size.x, size.y) / 2.0 - 0.0)
	var tilt := 0.0
	if %LockCamera.button_pressed:
		tilt = -axis
	draw_circle(center, radius - 10.0, Color(150.0, 150.0, 150.0), false, 2.0, true)
	draw_ellipse(center, (radius - 10.0) * 0.2, radius - 10.0, tilt, Color(0.5, 0.5, 0.5), 1)
	draw_ellipse(center, (radius - 10.0) * 0.4, radius - 10.0, tilt, Color(0.5, 0.5, 0.5), 1)
	draw_ellipse(center, (radius - 10.0) * 0.6, radius - 10.0, tilt, Color(0.5, 0.5, 0.5), 1)
	draw_ellipse(center, (radius - 10.0) * 0.8, radius - 10.0, tilt, Color(0.5, 0.5, 0.5), 1)
	var cangle := tilt - HPI
	draw_line(
		center + Vector2(cos(cangle) * radius, sin(cangle) * radius),
		center + Vector2(cos(cangle - PI) * radius, sin(cangle - PI) * radius),
		Color(0.5, 0.5, 0.5),
		1.0,
		true
	)
	#draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.25, 1.0))
	#draw_circle(Vector2.ZERO, radius, Color(0.0, 255.0, 0.0), false, 4.0, true)
	#draw_arc(Vector2.ZERO, radius, HPI, -HPI, 30, Color(0.0, 1.0, 0.0), 4.0, false)
	#draw_arc(Vector2.ZERO, radius, -HPI , -HPI -PI, 30, Color(0.0, 0.5, 0.0), 4.0, false)
	draw_ellipse(center, radius, radius * 0.25, axis + tilt, Color(0.0, 1.0, 0.0))
	#draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	#var orbit_point := Vector2(cos(-orbit) * radius * 0.25, sin(-orbit) * radius)
	var orbit_point := get_ellipse_point(center, radius, radius * 0.25, axis + tilt, -orbit)
	draw_circle(orbit_point, 10.0, Color(255.0, 0.0, 0.0))

	var sun_pos := Vector3(cos(axis) * sin(orbit), sin(axis) * sin(orbit), cos(orbit))
	#draw_arc(center + Vector2(size.x / 2.0, 0.0), radius * 1.5, QPI+HPI, PI+QPI, 30, Color(0.0, 255.0, 0.0))
	#draw_arc(center - Vector2(size.x / 2.0, 0.0), radius * 1.5, QPI+HPI, PI+QPI, 30, Color(0.0, 255.0, 0.0))
	%GasGiant.set_sun_pos(sun_pos)
	if %LockCamera.button_pressed:
		%Camera.rotation = axis
	else:
		%Camera.rotation = 0.0
	#draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(1.0, 1.0, 1.0), false)
	

func get_ellipse_point(center, a, b, rot, angle) -> Vector2:
	var point = Vector2.ZERO
	angle += HPI

	var x = a * cos(angle)
	var y = b * sin(angle)
	
	# Rotate the points by the angle
	var rotated_x = cos(rot) * x - sin(rot) * y
	var rotated_y = sin(rot) * x + cos(rot) * y
	
	point = center + Vector2(rotated_x, rotated_y)
	return point


func draw_ellipse(center: Vector2, a: float, b: float, angle: float, color: Color = Color.WHITE, thickness: int = 2, segments: int = 64) -> void:
	var points = []
	
	for i in range(segments):
		var t = (PI * 2) * i / segments
		#var x = a * cos(t)
		#var y = b * sin(t)
		
		# Rotate the points by the angle
		#var rotated_x = cos(angle) * x - sin(angle) * y
		#var rotated_y = sin(angle) * x + cos(angle) * y
		
		#points.append(center + Vector2(rotated_x, rotated_y))
		points.append(get_ellipse_point(center, a, b, angle, t))
	points.append(points[0])
	draw_polyline(points, color, thickness, true)

func _update_axis(value: float) -> void:
	axis = value
	#self.rotation = axis + HPI
	queue_redraw()

func _update_orbit(value: float) -> void:
	orbit = value
	queue_redraw()
