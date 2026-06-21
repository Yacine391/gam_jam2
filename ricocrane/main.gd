extends Node2D

const TAU_F := TAU
const TRACK_OUTER := Vector2(720.0, 420.0)
const TRACK_INNER := Vector2(410.0, 170.0)
const TRACK_MIDDLE := Vector2(565.0, 295.0)
const BEACH_OUTER := Vector2(790.0, 490.0)
const PLAYER_RADIUS := 24.0
const TOTAL_LAPS := 3
const BOT_COUNT := 5

enum RaceState { COUNTDOWN, PLAYING, TSUNAMI, DEAD, FINISHED }

@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/HUDControl
@onready var music: AudioStreamPlayer = $Music
@onready var bomb_sfx: AudioStreamPlayer = $BombSFX
@onready var splash_sfx: AudioStreamPlayer = $SplashSFX
@onready var finish_sfx: AudioStreamPlayer = $FinishSFX

var race_state: RaceState = RaceState.COUNTDOWN
var player_position := Vector2(TRACK_MIDDLE.x, 0.0)
var player_heading := PI * 0.5
var player_speed := 0.0
var player_progress := 0.0
var previous_angle := 0.0
var player_lap := 0
var player_rank := 1
var countdown := 3.4
var tsunami_time := 0.0
var death_time := 0.0
var finish_time := 0.0
var camera_shake := 0.0
var wake_points: Array[Vector2] = []
var bots: Array[Dictionary] = []
var bombs: Array[Dictionary] = []
var boosts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	hud.game = self
	_setup_race()
	if not music.playing:
		music.play()
	queue_redraw()

func _setup_race() -> void:
	race_state = RaceState.COUNTDOWN
	player_position = Vector2(TRACK_MIDDLE.x, 0.0)
	player_heading = PI * 0.5
	player_speed = 0.0
	player_progress = 0.0
	previous_angle = 0.0
	player_lap = 0
	player_rank = 1
	countdown = 3.4
	tsunami_time = 0.0
	death_time = 0.0
	finish_time = 0.0
	camera_shake = 0.0
	wake_points.clear()
	_create_bots()
	_create_bombs()
	_create_boosts()
	camera.position = player_position
	hud.queue_redraw()
	queue_redraw()

func _create_bots() -> void:
	bots.clear()
	var colors: Array[Color] = [
		Color("ff4f6d"), Color("ffd447"), Color("7ee081"),
		Color("b98cff"), Color("ff934f")
	]
	for i in range(BOT_COUNT):
		var lane: float = float((i % 3) - 1) * 32.0
		bots.append({
			"progress": -0.16 - float(i) * 0.13,
			"speed": 0.56 + rng.randf_range(-0.035, 0.045),
			"lane": lane,
			"target_lane": lane,
			"color": colors[i],
			"wobble": rng.randf_range(0.0, TAU_F)
		})

func _create_bombs() -> void:
	bombs.clear()
	var data: Array = [
		[0.72, -38.0], [1.55, 30.0], [2.48, -12.0],
		[3.34, 40.0], [4.20, -36.0], [5.18, 14.0]
	]
	for item in data:
		bombs.append({"angle": item[0], "lane": item[1], "active": true, "pulse": rng.randf_range(0.0, TAU_F)})

func _create_boosts() -> void:
	boosts.clear()
	for angle in [1.12, 2.95, 4.72]:
		boosts.append({"angle": angle, "lane": 0.0, "cooldown": 0.0})

func _physics_process(delta: float) -> void:
	match race_state:
		RaceState.COUNTDOWN:
			countdown -= delta
			if countdown <= 0.0:
				race_state = RaceState.PLAYING
		RaceState.PLAYING:
			_update_player(delta)
			_update_bots(delta)
			_update_progress()
			_check_bombs()
			_check_boosts(delta)
			_check_bot_collisions()
		RaceState.TSUNAMI:
			_update_tsunami(delta)
		RaceState.DEAD:
			death_time += delta
		RaceState.FINISHED:
			finish_time += delta
	_update_camera(delta)
	hud.queue_redraw()
	queue_redraw()

func _update_player(delta: float) -> void:
	var throttle: float = Input.get_axis("brake", "accelerate")
	var steering: float = Input.get_axis("steer_left", "steer_right")
	if throttle > 0.0:
		player_speed = move_toward(player_speed, 430.0, 235.0 * delta)
	elif throttle < 0.0:
		player_speed = move_toward(player_speed, 75.0, 310.0 * delta)
	else:
		player_speed = move_toward(player_speed, 155.0, 65.0 * delta)
	var steer_power: float = lerpf(1.9, 1.15, clampf(player_speed / 430.0, 0.0, 1.0))
	player_heading += steering * steer_power * delta
	var forward: Vector2 = Vector2.from_angle(player_heading)
	player_position += forward * player_speed * delta
	_keep_player_on_track(delta)
	_update_wake(forward)

func _keep_player_on_track(delta: float) -> void:
	var outer_value: float = _ellipse_value(player_position, TRACK_OUTER)
	var inner_value: float = _ellipse_value(player_position, TRACK_INNER)
	if outer_value > 1.0:
		player_speed = move_toward(player_speed, 85.0, 500.0 * delta)
		player_position = _project_to_ellipse(player_position, TRACK_OUTER * 0.985)
		camera_shake = max(camera_shake, 3.0)
	if inner_value < 1.0:
		player_speed = move_toward(player_speed, 85.0, 500.0 * delta)
		player_position = _project_to_ellipse(player_position, TRACK_INNER * 1.035)
		camera_shake = max(camera_shake, 3.0)

func _update_wake(forward: Vector2) -> void:
	wake_points.push_front(player_position - forward * 22.0)
	if wake_points.size() > 18:
		wake_points.pop_back()

func _update_bots(delta: float) -> void:
	for i in range(bots.size()):
		var bot: Dictionary = bots[i]
		bot.progress = float(bot.progress) + float(bot.speed) * delta
		bot.wobble = float(bot.wobble) + delta * 1.7
		if rng.randf() < 0.006:
			bot.target_lane = rng.randf_range(-42.0, 42.0)
		bot.lane = move_toward(float(bot.lane), float(bot.target_lane), 22.0 * delta)
		bots[i] = bot

func _update_progress() -> void:
	var angle: float = fposmod(atan2(player_position.y / TRACK_MIDDLE.y, player_position.x / TRACK_MIDDLE.x), TAU_F)
	if previous_angle > 5.5 and angle < 0.65 and player_speed > 80.0:
		player_lap += 1
		if player_lap >= TOTAL_LAPS:
			race_state = RaceState.FINISHED
			player_speed = 0.0
			finish_sfx.play()
	player_progress = float(player_lap) * TAU_F + angle
	previous_angle = angle
	var rank: int = 1
	for bot in bots:
		if float(bot.progress) > player_progress:
			rank += 1
	player_rank = rank

func _check_bombs() -> void:
	for i in range(bombs.size()):
		if not bool(bombs[i].active):
			continue
		var bomb_pos: Vector2 = _track_position(float(bombs[i].angle), float(bombs[i].lane))
		if player_position.distance_to(bomb_pos) < 42.0:
			bombs[i].active = false
			_start_tsunami()
			return

func _check_boosts(delta: float) -> void:
	for i in range(boosts.size()):
		var boost: Dictionary = boosts[i]
		boost.cooldown = maxf(0.0, float(boost.cooldown) - delta)
		var boost_pos: Vector2 = _track_position(float(boost.angle), float(boost.lane))
		if float(boost.cooldown) <= 0.0 and player_position.distance_to(boost_pos) < 52.0:
			player_speed = minf(560.0, player_speed + 155.0)
			boost.cooldown = 2.5
			camera_shake = max(camera_shake, 5.0)
		boosts[i] = boost

func _check_bot_collisions() -> void:
	for bot in bots:
		var bot_pos: Vector2 = _bot_position(bot)
		if player_position.distance_to(bot_pos) < 42.0:
			var push: Vector2 = (player_position - bot_pos).normalized()
			if push == Vector2.ZERO:
				push = Vector2.RIGHT
			player_position += push * 9.0
			player_speed *= 0.83
			camera_shake = max(camera_shake, 4.0)

func _start_tsunami() -> void:
	race_state = RaceState.TSUNAMI
	tsunami_time = 0.0
	player_speed = 0.0
	camera_shake = 16.0
	bomb_sfx.play()

func _update_tsunami(delta: float) -> void:
	tsunami_time += delta
	if tsunami_time > 0.55:
		var t: float = clampf((tsunami_time - 0.55) / 1.65, 0.0, 1.0)
		player_position = player_position.lerp(Vector2(0.0, BEACH_OUTER.y + 85.0), t * 0.055)
		player_heading = lerp_angle(player_heading, PI * 0.5, delta * 4.0)
	if tsunami_time > 2.35:
		race_state = RaceState.DEAD
		death_time = 0.0
		splash_sfx.play()

func _update_camera(delta: float) -> void:
	var target: Vector2 = player_position
	if race_state == RaceState.TSUNAMI:
		target = player_position.lerp(Vector2.ZERO, 0.18)
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 5.5))
	if camera_shake > 0.1:
		camera.offset = Vector2(rng.randf_range(-camera_shake, camera_shake), rng.randf_range(-camera_shake, camera_shake))
		camera_shake = move_toward(camera_shake, 0.0, delta * 25.0)
	else:
		camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_setup_race()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if race_state == RaceState.DEAD or race_state == RaceState.FINISHED:
			_setup_race()

func _draw() -> void:
	_draw_world()
	_draw_boosts()
	_draw_bombs()
	_draw_bots()
	_draw_player()
	if race_state == RaceState.TSUNAMI:
		_draw_tsunami()

func _draw_world() -> void:
	draw_rect(Rect2(-1800.0, -1300.0, 3600.0, 2600.0), Color("086fa8"))
	for y in range(-1200, 1201, 90):
		var offset: float = sin(float(y) * 0.02) * 45.0
		for x in range(-1700, 1701, 180):
			draw_arc(Vector2(float(x) + offset, float(y)), 32.0, 0.1, 2.7, 12, Color(0.35, 0.85, 1.0, 0.18), 2.0)
	var beach: PackedVector2Array = _ellipse_polygon(BEACH_OUTER, 96)
	draw_colored_polygon(beach, Color("f4cf86"))
	var outer_track: PackedVector2Array = _ellipse_polygon(TRACK_OUTER, 96)
	draw_colored_polygon(outer_track, Color("18a9d6"))
	var inner_island: PackedVector2Array = _ellipse_polygon(TRACK_INNER, 96)
	draw_colored_polygon(inner_island, Color("f5d99c"))
	draw_polyline(_closed_polyline(_ellipse_polygon(TRACK_OUTER, 96)), Color(0.85, 0.98, 1.0, 0.9), 9.0)
	draw_polyline(_closed_polyline(_ellipse_polygon(TRACK_INNER, 96)), Color(0.85, 0.98, 1.0, 0.85), 7.0)
	_draw_start_line()
	_draw_island_details()
	_draw_chicken_buoy(Vector2(-115.0, 25.0))
	_draw_bald_beach_ball(Vector2(185.0, -45.0))

func _draw_start_line() -> void:
	var x1: float = TRACK_INNER.x + 5.0
	var x2: float = TRACK_OUTER.x - 5.0
	var steps: int = 8
	for i in range(steps):
		var x: float = lerpf(x1, x2, float(i) / float(steps))
		var w: float = (x2 - x1) / float(steps)
		draw_rect(Rect2(x, -12.0, w, 12.0), Color.WHITE if i % 2 == 0 else Color("202735"))
		draw_rect(Rect2(x, 0.0, w, 12.0), Color("202735") if i % 2 == 0 else Color.WHITE)

func _draw_island_details() -> void:
	for p in [Vector2(-270, -70), Vector2(-220, 70), Vector2(260, 55), Vector2(80, -85)]:
		draw_circle(p, 8.0, Color("e9b866"))
		draw_line(p + Vector2(0, -4), p + Vector2(0, -34), Color("8b5a32"), 5.0)
		for a in [-2.5, -1.9, -1.2, -0.6]:
			draw_line(p + Vector2(0, -31), p + Vector2.from_angle(a) * 28.0 + Vector2(0, -31), Color("2f9f62"), 5.0)

func _draw_chicken_buoy(pos: Vector2) -> void:
	draw_circle(pos, 22.0, Color("f7f3df"))
	draw_circle(pos + Vector2(12, -13), 12.0, Color("f7f3df"))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(22, -15), pos + Vector2(34, -10), pos + Vector2(22, -6)]), Color("f4ad27"))
	draw_circle(pos + Vector2(15, -16), 2.5, Color("1d2630"))
	draw_circle(pos + Vector2(8, -28), 4.0, Color("ee4d5a"))

func _draw_bald_beach_ball(pos: Vector2) -> void:
	draw_circle(pos, 24.0, Color("ffd2ad"))
	draw_arc(pos, 24.0, 0.0, TAU_F, 32, Color("ef6f61"), 4.0)
	draw_circle(pos + Vector2(-8, -3), 2.4, Color("302b2b"))
	draw_circle(pos + Vector2(8, -3), 2.4, Color("302b2b"))
	draw_arc(pos + Vector2(0, 5), 8.0, 0.25, 2.9, 12, Color("302b2b"), 2.0)

func _draw_boosts() -> void:
	for boost in boosts:
		var pos: Vector2 = _track_position(float(boost.angle), float(boost.lane))
		var tangent: Vector2 = _track_tangent(float(boost.angle))
		var normal: Vector2 = tangent.rotated(PI * 0.5)
		var alpha: float = 0.35 if float(boost.cooldown) > 0.0 else 0.9
		for offset: float in [-18.0, 0.0, 18.0]:
			var center: Vector2 = pos + normal * offset
			var pts: PackedVector2Array = PackedVector2Array([center + tangent * 18.0, center - tangent * 10.0 + normal * 9.0, center - tangent * 10.0 - normal * 9.0])
			draw_colored_polygon(pts, Color(1.0, 0.88, 0.2, alpha))

func _draw_bombs() -> void:
	for bomb in bombs:
		if not bool(bomb.active):
			continue
		var pos: Vector2 = _track_position(float(bomb.angle), float(bomb.lane))
		var pulse: float = 1.0 + sin(float(Time.get_ticks_msec()) * 0.006 + float(bomb.pulse)) * 0.1
		draw_circle(pos, 19.0 * pulse, Color("242735"))
		draw_circle(pos - Vector2(6, 6), 5.0, Color(1.0, 1.0, 1.0, 0.25))
		draw_line(pos + Vector2(10, -13), pos + Vector2(20, -26), Color("5b3f2f"), 4.0)
		draw_circle(pos + Vector2(22, -28), 5.0 + sin(Time.get_ticks_msec() * 0.012) * 2.0, Color("ffb52e"))

func _draw_bots() -> void:
	for bot in bots:
		var pos: Vector2 = _bot_position(bot)
		var angle: float = fposmod(float(bot.progress), TAU_F)
		var tangent: Vector2 = _track_tangent(angle)
		_draw_jetski(pos, tangent.angle(), bot["color"] as Color, false)

func _draw_player() -> void:
	for i in range(wake_points.size() - 1, -1, -1):
		var alpha: float = (1.0 - float(i) / float(maxi(1, wake_points.size()))) * 0.55
		draw_circle(wake_points[i], 5.0 + float(i) * 0.35, Color(1.0, 1.0, 1.0, alpha))
	_draw_jetski(player_position, player_heading, Color("32e6ff"), true)

func _draw_jetski(pos: Vector2, heading: float, color: Color, is_player: bool) -> void:
	var forward: Vector2 = Vector2.from_angle(heading)
	var side: Vector2 = forward.rotated(PI * 0.5)
	var hull: PackedVector2Array = PackedVector2Array([
		pos + forward * 29.0,
		pos - forward * 22.0 + side * 15.0,
		pos - forward * 28.0,
		pos - forward * 22.0 - side * 15.0
	])
	draw_colored_polygon(hull, color)
	draw_polyline(_closed_polyline(hull), Color(0.04, 0.15, 0.22, 0.9), 3.0)
	draw_line(pos - forward * 4.0, pos + forward * 14.0, Color(1.0, 1.0, 1.0, 0.55), 4.0)
	draw_circle(pos - forward * 3.0, 9.0, Color("d14f42") if is_player else Color("f2d3a0"))
	if is_player:
		draw_arc(pos, 35.0, -2.55, -0.6, 16, Color.WHITE, 3.0)

func _draw_tsunami() -> void:
	var t: float = clampf(tsunami_time / 2.1, 0.0, 1.0)
	var wave_x: float = lerpf(-1150.0, 1150.0, t)
	var crest: PackedVector2Array = PackedVector2Array()
	for i in range(30):
		var y: float = -760.0 + float(i) * 52.0
		var x: float = wave_x + sin(float(i) * 0.7 + tsunami_time * 8.0) * 34.0
		crest.append(Vector2(x, y))
	var body: PackedVector2Array = PackedVector2Array(crest)
	body.append(Vector2(-1400.0, 760.0))
	body.append(Vector2(-1400.0, -760.0))
	draw_colored_polygon(body, Color(0.0, 0.35, 0.72, 0.93))
	draw_polyline(crest, Color(0.85, 0.98, 1.0, 1.0), 22.0)

func _track_position(angle: float, lane: float) -> Vector2:
	var radius: Vector2 = TRACK_MIDDLE + Vector2(lane, lane * 0.58)
	return Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

func _track_tangent(angle: float) -> Vector2:
	return Vector2(-TRACK_MIDDLE.x * sin(angle), TRACK_MIDDLE.y * cos(angle)).normalized()

func _bot_position(bot: Dictionary) -> Vector2:
	var angle: float = fposmod(float(bot.progress), TAU_F)
	var lane: float = float(bot.lane) + sin(float(bot.wobble)) * 5.0
	return _track_position(angle, lane)

func _ellipse_value(point: Vector2, radius: Vector2) -> float:
	return (point.x * point.x) / (radius.x * radius.x) + (point.y * point.y) / (radius.y * radius.y)

func _project_to_ellipse(point: Vector2, radius: Vector2) -> Vector2:
	var angle: float = atan2(point.y / radius.y, point.x / radius.x)
	return Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

func _ellipse_polygon(radius: Vector2, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var a: float = TAU_F * float(i) / float(segments)
		points.append(Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return points

func _closed_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = PackedVector2Array(points)
	if points.size() > 0:
		closed.append(points[0])
	return closed
