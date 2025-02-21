extends Control
class_name SunGizmo

var axis := 0.0
var lock_axis := false
var orbit := 0.0

const HPI = PI/2.0
const QPI = PI/4.0

func update(_axis: float, _orbit: float, _lock: float) -> void:
	axis = _axis
	orbit = _orbit
	lock_axis = _lock
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y / 2.0)
	#self.position = center
	var radius := float(min(size.x, size.y) / 2.0 - 0.0)
	var tilt := 0.0
	if lock_axis:
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
	draw_ellipse(center, radius, radius * 0.25, axis + tilt, Color(0.0, 1.0, 0.0))
	var orbit_point := get_ellipse_point(center, radius, radius * 0.25, axis + tilt, -orbit)
	draw_circle(orbit_point, 10.0, Color(255.0, 0.0, 0.0))

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
		points.append(get_ellipse_point(center, a, b, angle, t))
	points.append(points[0])
	draw_polyline(points, color, thickness, true)
