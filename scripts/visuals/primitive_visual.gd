class_name PrimitiveVisual2D
extends CharacterVisual2D

var is_player := false
var facing := Vector2.RIGHT

func configure(value: bool) -> void:
	is_player = value
	queue_redraw()

func set_facing(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		facing = direction.normalized()
		queue_redraw()

func _draw() -> void:
	if is_player:
		draw_circle(Vector2.ZERO, 16.0, Color("65e4cb"))
		draw_circle(Vector2.ZERO, 10.0, Color("153d43"))
		draw_line(facing * 8.0, facing * 25.0, Color("dcfff6"), 7.0)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -15), Vector2(15, 0), Vector2(0, 15), Vector2(-15, 0)
		]), Color("ed7e73"))
		draw_circle(facing * 5.0, 4.0, Color("482d3d"))
