class_name SurvivorEnemy
extends CharacterBody2D

signal defeated(enemy: SurvivorEnemy)
@export var visual_scene: PackedScene
var visual: CharacterVisual2D
var hp := 26
var max_hp := 26
var speed := 64.0
var contact_damage := 8
var alive := true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	visual = visual_scene.instantiate() as CharacterVisual2D if visual_scene else PrimitiveVisual2D.new()
	assert(visual != null, "Enemy visual root must extend CharacterVisual2D")
	add_child(visual)
	visual.configure(false)

func tick(_delta: float, target: Vector2) -> void:
	if not alive:
		return
	var direction := position.direction_to(target)
	velocity = direction * speed
	move_and_slide()
	visual.set_facing(direction)
	visual.set_motion(&"walk")

func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	if hp <= 0:
		alive = false
		collision_layer = 0
		visual.set_motion(&"death")
		defeated.emit(self)
		queue_free()
	queue_redraw()

func _draw() -> void:
	if hp < max_hp and alive:
		draw_rect(Rect2(-16, -24, 32, 3), Color("263347"))
		draw_rect(Rect2(-16, -24, 32.0 * maxf(0.0, float(hp) / max_hp), 3), Color("ed7e73"))
