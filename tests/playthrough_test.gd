extends SceneTree
## Full deterministic playthrough. Uses normal movement input, real spawning,
## cooldowns, bullets and enemy damage; never changes player or enemy stats.

var game: SurvivorGame
var waypoint := 0
var last_wave := 0
var frames := 0
const ROUTE := [Vector2(280, 230), Vector2(1000, 230), Vector2(1000, 520), Vector2(280, 520)]
const ACTIONS := ["ui_left", "ui_right", "ui_up", "ui_down"]

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	game = load("res://scenes/main.tscn").instantiate() as SurvivorGame
	root.add_child(game)
	game.rng.seed = 472

func _process(_delta: float) -> bool:
	if game == null:
		return false
	frames += 1
	for action in ACTIONS:
		Input.action_release(action)
	if game.wave != last_wave:
		last_wave = game.wave
		print("PLAYTHROUGH: wave %d, HP %d, kills %d" % [game.wave, game.player.hp, game.kills])
	if game.state == SurvivorGame.State.UPGRADE:
		# Alternate both available upgrades through the same key handler as play.
		var event := InputEventKey.new()
		event.keycode = KEY_LEFT if game.level % 2 == 0 else KEY_RIGHT
		event.pressed = true
		game._unhandled_key_input(event)
	elif game.state == SurvivorGame.State.WON:
		print("PLAYTHROUGH PASS: 5 waves, %d kills, HP %d, %.1f combat seconds" % [game.kills, game.player.hp, game.elapsed])
		quit(0)
	elif game.state == SurvivorGame.State.LOST or frames > 36000:
		push_error("PLAYTHROUGH FAIL: state %d, wave %d, HP %d, kills %d" % [game.state, game.wave, game.player.hp, game.kills])
		quit(1)
	else:
		var target: Vector2 = ROUTE[waypoint]
		if game.player.position.distance_to(target) < 24.0:
			waypoint = (waypoint + 1) % ROUTE.size()
			target = ROUTE[waypoint]
		var direction := steer(target)
		if absf(direction.x) > 0.1:
			Input.action_press("ui_right" if direction.x > 0 else "ui_left")
		if absf(direction.y) > 0.1:
			Input.action_press("ui_down" if direction.y > 0 else "ui_up")
	return false

func steer(target: Vector2) -> Vector2:
	var best_score := -INF
	var best := Vector2.ZERO
	for x in range(-1, 2):
		for y in range(-1, 2):
			var direction := Vector2(x, y).normalized()
			var future := game.player.position + direction * SurvivorPlayer.SPEED * 0.5
			if not game.ARENA.grow(-24).has_point(future):
				continue
			var clearance := 180.0
			for enemy in game.enemies:
				var predicted := enemy.position + enemy.position.direction_to(game.player.position) * enemy.speed * 0.5
				clearance = minf(clearance, future.distance_to(predicted))
			var progress := game.player.position.distance_to(target) - future.distance_to(target)
			var score := minf(clearance, 145.0) * 1.5 + progress * 0.45
			if clearance < 65:
				score -= (65.0 - clearance) * 8.0
			if score > best_score:
				best_score = score
				best = direction
	return best
