extends Node2D

const MOVE_SPEED = 150.0
const ZOOM_SPEED = 0.5
var _zoom_accel = 0.0

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed('ui_up'):
		%Camera.position.y -= MOVE_SPEED * delta / %Camera.zoom.x
	if Input.is_action_pressed('ui_down'):
		%Camera.position.y += MOVE_SPEED * delta / %Camera.zoom.x
	if Input.is_action_pressed('ui_right'):
		%Camera.position.x += MOVE_SPEED * delta / %Camera.zoom.x
	if Input.is_action_pressed('ui_left'):
		%Camera.position.x -= MOVE_SPEED * delta / %Camera.zoom.x
	if Input.is_action_pressed('zoom_out'):
		_zoom_accel += min(0.1 * delta, ZOOM_SPEED)
		%Camera.zoom.x -= _zoom_accel * delta
		%Camera.zoom.y -= _zoom_accel * delta
	elif Input.is_action_pressed('zoom_in'):
		_zoom_accel += min(0.1 * delta, ZOOM_SPEED)
		%Camera.zoom.x += _zoom_accel * delta
		%Camera.zoom.y += _zoom_accel * delta
	else:
		_zoom_accel = 0.0

func _ready() -> void:
	var num_planets := 9
	var o_radius := 240.0
	for p in range(num_planets):
		var planet := MapPlanet.new()
		var type = randi_range(0, 1)
		prints("type", type)
		var size = 10.0
		if (type == 1):
			#rocky
			size = randf_range(20.0, 50.0)
			planet.radius = size
			o_radius += 100 + size * 10
			planet.orbit_radius = o_radius
			var num_moons = randi_range(0, 2)
			var moon_rad = planet.radius
			for m in range(num_moons):
				moon_rad += 50.0
				var moon := MapPlanet.new()
				moon.radius = randf_range(5.0, 10.0)
				moon.orbit_radius = moon_rad
				moon.orbit_angle = randf() * TAU
				planet.add_child(moon)
			#planet.orbit_angle = randf() * TAU
		else:
			#gas
			size = randf_range(70.0, 100.0)
			planet.radius = size
			#o_radius += size * 6.0
			o_radius += 100 + size * 10
			planet.orbit_radius = o_radius
			var num_moons = randi_range(2, 5)
			var moon_rad = planet.radius
			for m in range(num_moons):
				moon_rad += 50.0
				var moon := MapPlanet.new()
				moon.radius = randf_range(5.0, 15.0)
				moon.orbit_radius = moon_rad
				moon.orbit_angle = randf() * TAU
				planet.add_child(moon)
		o_radius += size * 5
		planet.orbit_angle = randf() * TAU
		%Sun.add_child(planet)
		var button: Button = Button.new()
		button.text = "Planet %d" % p
		%PlanetButtons.add_child(button)
		button.connect('pressed', zoom_to.bind(planet))
	%SunButton.connect('pressed', zoom_to.bind(%Sun))
	prints("from map", $MapSystem/StarSystem/Sun/Celestial.material.get_shader_parameter('noise1/noise/seed'))
	#prints("from map", $MapSystem/StarSystem/Sun2/Celestial.material.get_shader_parameter('noise1/noise/seed'))


func zoom_to(planet) -> void:
	print("pressed button")
	var camera: Camera2D = %Camera
	var tween := create_tween()
	var dist = camera.position.distance_to(planet.position)
	var time = dist / 4000.0
	var zoom_out = 0.1
	if planet == %Sun:
		zoom_out = 0.050
	tween.tween_property(camera, 'zoom', Vector2(zoom_out, zoom_out), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, 'position', Vector2(planet.position), min(time, 1.25)).set_trans(Tween.TRANS_SINE)
	#if planet != %Sun:
	tween.tween_property(camera, 'zoom', Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	#camera.position = Vector2(planet.position)
