extends SceneTree
## Integration tests using real game actors, physics queries, and UI state.

var game: SurvivorGame
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func sync_physics() -> void:
	await physics_frame
	await process_frame

func reset_game() -> void:
	game.restart()
	game.set_physics_process(false)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate() as SurvivorGame
	root.add_child(game)
	game.set_physics_process(false)
	await sync_physics()
	check(game.player.hp == 100 and game.wave == 1, "initial health and wave")
	check(game.player.visual is CharacterVisual2D, "replaceable player visual contract")
	var start := game.player.position
	game.player.tick(1.0 / 60.0, game.ARENA, Vector2.ONE)
	check(game.player.velocity.length() <= SurvivorPlayer.SPEED + 0.01, "diagonal movement is normalized")
	check(game.player.position != start, "movement changes player position")
	game.player.position = Vector2(-1000, 9999)
	game.player.tick(1.0 / 60.0, game.ARENA, Vector2.ZERO)
	check(game.ARENA.has_point(game.player.position), "arena clamps movement")
	reset_game()
	game._auto_fire()
	check(game.bullets.is_empty(), "no fire without a target")
	var far := game.spawn_enemy()
	far.position = game.player.position + Vector2(400, 0)
	check(game.nearest_enemy() == null, "enemies outside range are ignored")
	var near := game.spawn_enemy()
	near.position = game.player.position + Vector2(75, 0)
	far.position = game.player.position + Vector2(150, 0)
	check(game.nearest_enemy() == near, "nearest in-range enemy selected")
	await sync_physics()
	game._auto_fire()
	check(game.bullets.size() == 1, "auto fire creates a bullet")
	var bullet := game.bullets[0]
	check(bullet.direction.is_equal_approx(Vector2.RIGHT), "bullet aimed at target")
	game._auto_fire()
	check(game.bullets.size() == 1, "cooldown prevents extra shot")
	bullet.tick(0.2)
	check(near.hp == 6 and far.hp == 26, "swept bullet damages first target only")
	check(not bullet.alive, "bullet removed on hit")
	await sync_physics()
	game.player.shot_cooldown = 0.0
	game._auto_fire()
	game.bullets.back().tick(0.2)
	check(not near.alive and game.kills == 1 and game.xp == 1, "lethal bullet awards experience once")
	near.take_damage(100)
	check(game.kills == 1, "dead enemy cannot reward twice")
	var hp := game.player.hp
	game.player.take_damage(8)
	game.player.take_damage(8)
	check(game.player.hp == hp - 8, "contact damage respects invulnerability")
	var expired := SurvivorBullet.new()
	expired.position = Vector2(100, 200)
	expired.remaining_distance = 10.0
	game.add_child(expired)
	expired.tick(1.0)
	check(not expired.alive and is_equal_approx(expired.position.x, 110.0), "bullet expires exactly at range limit")
	await sync_physics()
	reset_game()
	for i in range(5):
		game.spawn_enemy().take_damage(999)
	game._resolve_progress()
	check(game.state == SurvivorGame.State.UPGRADE and game.level == 2, "five kills open first upgrade")
	var time_before := game.elapsed
	var spawn_before := game.spawned
	game._physics_process(10.0)
	check(game.elapsed == time_before and game.spawned == spawn_before, "upgrade pauses combat and spawning")
	var left := InputEventKey.new()
	left.keycode = KEY_LEFT
	left.pressed = true
	game._unhandled_key_input(left)
	check(game.player.damage == 28 and game.state == SurvivorGame.State.PLAYING, "damage choice applies and resumes")
	game.choose_upgrade(1)
	check(is_equal_approx(game.player.fire_interval, 0.48), "choice ignored outside upgrade state")
	for i in range(8):
		# Progress testing avoids exceeding the current wave's spawn quota.
		if game.spawned >= game.WAVE_COUNTS[game.wave - 1] and game.enemies.is_empty():
			game._resolve_progress()
		game.spawn_enemy().take_damage(999)
	game._resolve_progress()
	check(game.state == SurvivorGame.State.UPGRADE, "next experience threshold triggers upgrade")
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	game._unhandled_key_input(right)
	check(is_equal_approx(game.player.fire_interval, 0.4), "speed choice increases shots per second by 20 percent")
	# Exercise all 86 spawns, wave boundaries, upgrades and terminal victory.
	reset_game()
	var visited: Array[int] = []
	var safe_spawns := true
	var safety := 0
	while game.state != SurvivorGame.State.WON and safety < 150:
		safety += 1
		if game.state == SurvivorGame.State.UPGRADE:
			game.choose_upgrade(safety % 2)
			continue
		if not game.wave in visited:
			visited.append(game.wave)
		if game.spawned < game.WAVE_COUNTS[game.wave - 1]:
			var enemy := game.spawn_enemy()
			safe_spawns = safe_spawns and enemy.position.distance_to(game.player.position) >= 180.0
			enemy.take_damage(999)
		game._resolve_progress()
	check(safe_spawns, "all 86 enemies spawn at a safe distance")
	check(visited == [1, 2, 3, 4, 5], "all five waves visited in order")
	check(game.state == SurvivorGame.State.WON and game.kills == 86, "fifth wave ends game after 86 enemies")
	check(game.hud.overlay.visible and game.hud.restart_button.visible, "victory presents restart choice")
	time_before = game.elapsed
	game._physics_process(1.0)
	check(game.elapsed == time_before, "victory stops combat")
	var up := InputEventKey.new()
	up.keycode = KEY_UP
	up.pressed = true
	game._unhandled_key_input(up)
	check(game.wave == 1 and game.kills == 0 and game.level == 1 and game.xp == 0, "restart resets progress")
	check(game.player.hp == 100 and game.player.damage == 20 and is_equal_approx(game.player.fire_interval, 0.48), "restart resets player stats")
	check(game.enemies.is_empty() and game.bullets.is_empty() and not game.hud.overlay.visible, "restart clears actors and modal")
	game.set_physics_process(false)
	game.player.hp = 0
	game._physics_process(0.016)
	check(game.state == SurvivorGame.State.LOST and game.hud.restart_button.visible, "death ends game with restart choice")
	game.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
