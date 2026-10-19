class_name SurvivorPlayer
extends CharacterBody2D

const SPEED := 235.0
const RADIUS := 16.0
## Assign an adapter scene with a CharacterVisual2D root to replace the shape.
@export var visual_scene: PackedScene
var visual: CharacterVisual2D
var hp := 100
var max_hp := 100
var damage := 20
var fire_interval := 0.48
var attack_range := 340.0
var shot_cooldown := 0.0
var invulnerability := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	visual = visual_scene.instantiate() as CharacterVisual2D if visual_scene else PrimitiveVisual2D.new()
	assert(visual != null, "Player visual root must extend CharacterVisual2D")
	add_child(visual)
	visual.configure(true)

func tick(delta: float, arena: Rect2, input: Vector2) -> void:
	velocity = input.limit_length() * SPEED
	move_and_slide()
	position = position.clamp(arena.position + Vector2.ONE * RADIUS, arena.end - Vector2.ONE * RADIUS)
	invulnerability = maxf(0.0, invulnerability - delta)
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	visual.set_motion(&"walk" if velocity.length_squared() > 0.0 else &"idle")
	if not input.is_zero_approx():
		visual.set_facing(input)

func take_damage(amount: int) -> bool:
	if invulnerability > 0.0 or hp <= 0:
		return false
	hp = maxi(0, hp - amount)
	invulnerability = 0.75
	return true
