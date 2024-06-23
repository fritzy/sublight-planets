extends Node2D

func _process(_delta: float) -> void:
	var xscale: float = 1.0 / %Camera.zoom.x
	scale = Vector2.ONE * xscale
	var rect = %Camera.get_viewport_rect()
	#var campos = %Camera.get_screen_center_position()
	#var rect := get_viewport().get_visible_rect()
	position.x = rect.position.x - rect.size.x / 2 * xscale
	position.y = rect.position.y - rect.size.y / 2 * xscale

func _draw() -> void:
	var random = RandomNumberGenerator.new()
	random.randomize()
	var rect := get_viewport().get_visible_rect()
	#rect.position.x = rect.position.x - rect.size.x / 2
	#rect.position.y = rect.position.y - rect.size.y / 2
	#position.x = rect.position.x - rect.size.x / 2
	#position.y =rect.position.y - rect.size.y / 2
	draw_rect(rect, Color.BLACK)
	for i in range(500):
		var x := random.randf() * rect.size.x
		var y := 0.0
		for yi in range(3):
			y += random.randf() * rect.size.y / 3.0 
		draw_rect(Rect2(x, y, 2, 2), Color.WHITE)


	#draw_arc(Vector2(100.0, 100.0), 300.0, 0.0, TAU, 30, Color.BLACK)
