class_name SurvivorBullet
extends Node2D

const SPEED := 720.0
var direction := Vector2.RIGHT
var damage := 20
var remaining_distance := 340.0
var alive := true

func tick(delta: float) -> void:
	if not alive:
		return
	var travel := minf(SPEED * delta, remaining_distance)
	var destination := global_position + direction * travel
	# Sweep the whole movement segment so fast bullets cannot skip enemies.
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 2)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var enemy := hit.collider as SurvivorEnemy
		if enemy:
			enemy.take_damage(damage)
		_retire()
		return
	global_position = destination
	remaining_distance -= travel
	if remaining_distance <= 0.0:
		_retire()

func _retire() -> void:
	alive = false
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color("ffd58a"))
