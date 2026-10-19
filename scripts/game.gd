class_name SurvivorGame
extends Node2D

enum State { PLAYING, UPGRADE, WON, LOST }
const ARENA := Rect2(48, 114, 1184, 518)
const WAVE_COUNTS := [8, 12, 16, 22, 28]
const WAVE_HEALTH := [26, 36, 50, 64, 82]
const WAVE_SPEED := [64.0, 73.0, 82.0, 91.0, 100.0]

@export var player_scene: PackedScene = preload("res://scenes/player.tscn")
@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var state := State.PLAYING
var player: SurvivorPlayer
var hud: SurvivorHUD
var enemies: Array[SurvivorEnemy] = []
var bullets: Array[SurvivorBullet] = []
var wave := 1
var spawned := 0
var kills := 0
var level := 1
var xp := 0
var xp_goal := 5
var pending_upgrades := 0
var spawn_timer := 1.2
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	hud = SurvivorHUD.new()
	add_child(hud)
	hud.upgrade_chosen.connect(choose_upgrade)
	hud.restart_requested.connect(restart)
	restart()

func restart() -> void:
	# Remove old actors immediately from the world before the next physics tick.
	for actor in enemies:
		if is_instance_valid(actor):
			remove_child(actor)
			actor.queue_free()
	for bullet in bullets:
		if is_instance_valid(bullet):
			remove_child(bullet)
			bullet.queue_free()
	enemies.clear()
	bullets.clear()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	player = player_scene.instantiate() as SurvivorPlayer
	player.position = ARENA.get_center()
	add_child(player)
	wave = 1
	spawned = 0
	kills = 0
	level = 1
	xp = 0
	xp_goal = 5
	pending_upgrades = 0
	spawn_timer = 1.2
	elapsed = 0.0
	state = State.PLAYING
	hud.hide_modal()
	_refresh_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if state == State.UPGRADE:
		if event.is_action_pressed("ui_left"):
			choose_upgrade(0)
		elif event.is_action_pressed("ui_right"):
			choose_upgrade(1)
	elif state == State.WON or state == State.LOST:
		if event.is_action_pressed("ui_up"):
			restart()

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	elapsed += delta
	player.tick(delta, ARENA, Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	spawn_timer -= delta
	if spawned < WAVE_COUNTS[wave - 1] and spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = maxf(0.28, 0.8 - wave * 0.08)
	for enemy in enemies:
		if enemy.alive:
			enemy.tick(delta, player.position)
			if enemy.position.distance_squared_to(player.position) < 30.0 * 30.0:
				player.take_damage(enemy.contact_damage)
	if player.hp <= 0:
		_finish(false)
		return
	_auto_fire()
	# Damage emits signals that remove enemies, so iterate a separate bullet list.
	for bullet in bullets.duplicate():
		if is_instance_valid(bullet) and bullet.alive:
			bullet.tick(delta)
	bullets = bullets.filter(func(bullet: SurvivorBullet): return is_instance_valid(bullet) and bullet.alive)
	_resolve_progress()
	_refresh_hud()

func spawn_enemy() -> SurvivorEnemy:
	var enemy := enemy_scene.instantiate() as SurvivorEnemy
	enemy.max_hp = WAVE_HEALTH[wave - 1]
	enemy.hp = enemy.max_hp
	enemy.speed = WAVE_SPEED[wave - 1]
	enemy.contact_damage = 7 + wave
	# Choose an edge point with a safe distance from the player, even near corners.
	var location := Vector2.ZERO
	for attempt in range(24):
		match rng.randi_range(0, 3):
			0: location = Vector2(rng.randf_range(68, 1212), 134)
			1: location = Vector2(rng.randf_range(68, 1212), 612)
			2: location = Vector2(68, rng.randf_range(134, 612))
			3: location = Vector2(1212, rng.randf_range(134, 612))
		if location.distance_to(player.position) >= 180.0:
			break
	if location.distance_to(player.position) < 180.0:
		location = ARENA.position + Vector2(20, 20)
		if location.distance_to(player.position) < 180.0:
			location = ARENA.end - Vector2(20, 20)
	enemy.position = location
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	enemies.append(enemy)
	spawned += 1
	return enemy

func nearest_enemy() -> SurvivorEnemy:
	var nearest: SurvivorEnemy
	var best := player.attack_range * player.attack_range
	for enemy in enemies:
		if not enemy.alive:
			continue
		var distance := player.position.distance_squared_to(enemy.position)
		if distance <= best:
			best = distance
			nearest = enemy
	return nearest

func _auto_fire() -> void:
	if player.shot_cooldown > 0.0:
		return
	var target := nearest_enemy()
	if target == null:
		return
	var bullet := SurvivorBullet.new()
	bullet.direction = player.position.direction_to(target.position)
	bullet.position = player.position
	bullet.damage = player.damage
	bullet.remaining_distance = player.attack_range
	add_child(bullet)
	bullets.append(bullet)
	player.shot_cooldown = player.fire_interval
	player.visual.set_facing(bullet.direction)
	player.visual.play_attack()

func _on_enemy_defeated(enemy: SurvivorEnemy) -> void:
	enemies.erase(enemy)
	kills += 1
	xp += 1
	while xp >= xp_goal:
		xp -= xp_goal
		level += 1
		xp_goal += 3
		pending_upgrades += 1

func _resolve_progress() -> void:
	if state != State.PLAYING:
		return
	# The fifth wave ends immediately; no meaningless upgrade after victory.
	if wave == 5 and spawned == WAVE_COUNTS[4] and enemies.is_empty():
		_finish(true)
		return
	if pending_upgrades > 0:
		state = State.UPGRADE
		_set_visuals_paused(true)
		hud.show_upgrade(level, player.damage, player.fire_interval)
	elif spawned == WAVE_COUNTS[wave - 1] and enemies.is_empty():
		wave += 1
		spawned = 0
		spawn_timer = 1.8

func choose_upgrade(index: int) -> void:
	if state != State.UPGRADE or index not in [0, 1]:
		return
	if index == 0:
		player.damage += 8
	else:
		player.fire_interval /= 1.2
	pending_upgrades -= 1
	_set_visuals_paused(false)
	state = State.PLAYING
	hud.hide_modal()
	_resolve_progress()
	_refresh_hud()

func _finish(won: bool) -> void:
	state = State.WON if won else State.LOST
	if not won:
		player.visual.set_motion(&"death")
	_set_visuals_paused(true)
	hud.show_result(won, kills, elapsed, level)
	_refresh_hud()

func _set_visuals_paused(paused: bool) -> void:
	player.visual.set_playback_paused(paused)
	for enemy in enemies:
		enemy.visual.set_playback_paused(paused)

func _refresh_hud() -> void:
	hud.update_status(wave, spawned, WAVE_COUNTS[wave - 1], enemies.size(), player, level, xp, xp_goal)

func _draw() -> void:
	draw_rect(ARENA, Color("0c1726"))
	for x in range(48, 1233, 48):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color("142134"))
	for y in range(114, 633, 48):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color("142134"))
	draw_rect(ARENA, Color("2a4054"), false, 2.0)
