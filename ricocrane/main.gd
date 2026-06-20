extends Node2D

# --- TUNING ---
@export var camera_x_offset: float = 200.0
@export var camera_y: float = 300.0
@export var bounce_check_tolerance: float = 18.0
@export var start_player_x: float = 200.0
@export var start_player_y: float = 350.0
@export var wave_amplitude: float = 10.0
@export var wave_speed: float = 1.8
@export var wave_frequency: float = 0.015

@onready var player: Player = $Player
@onready var skull_container: Node2D = $SkullContainer
@onready var obstacle_container: Node2D = $ObstacleContainer
@onready var spawner: Spawner = $Spawner
@onready var camera: Camera2D = $Camera2D
@onready var death_wall_poly: Polygon2D = $DeathWallVisual

var _wave_time: float = 0.0

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	death_wall_poly.visible = false
	spawner.setup(skull_container, start_player_x, obstacle_container)
	_start_game()

func _start_game() -> void:
	player.position = Vector2(start_player_x, start_player_y)
	player.reset()
	spawner.reset(start_player_x)
	camera.position = Vector2(start_player_x + camera_x_offset, camera_y)
	GameState.start_game()

func _process(delta: float) -> void:
	_wave_time += delta
	match GameState.state:
		GameState.State.PLAYING:
			player.physics_step(delta)
			spawner.update(player.position.x)
			_check_skull_bounces()
			_check_obstacle_hits()
			_update_camera()
			GameState.report_speed(player.current_speed)
			GameState.add_distance(player.current_speed * delta)
		GameState.State.DEAD:
			_update_camera()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if GameState.state == GameState.State.PLAYING:
		if event.is_action_pressed("ui_accept"):
			player.dive()
		elif event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			player.dive()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_start_game()

	if GameState.state == GameState.State.DEAD:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			_start_game()

func _draw() -> void:
	var wy: float = player.water_line_y
	var cx: float = camera.position.x
	var margin: float = 1200.0

	# Ciel
	draw_rect(Rect2(cx - margin, -800.0, margin * 2.0, wy + 800.0), Color(0.42, 0.72, 1.0))

	# Mer — gradient sur 4 bandes
	draw_rect(Rect2(cx - margin, wy, margin * 2.0, 150.0), Color(0.0, 0.38, 0.88))
	draw_rect(Rect2(cx - margin, wy + 150.0, margin * 2.0, 150.0), Color(0.0, 0.28, 0.75))
	draw_rect(Rect2(cx - margin, wy + 300.0, margin * 2.0, 300.0), Color(0.0, 0.18, 0.58))

	# Vague de fond (lente, large)
	var steps: int = 48
	var wave_bg: PackedVector2Array = PackedVector2Array()
	for i: int in range(steps + 1):
		var x: float = cx - margin + (margin * 2.0 * float(i) / float(steps))
		var y: float = wy + sin(x * wave_frequency * 0.6 + _wave_time * wave_speed * 0.5) * wave_amplitude * 1.4
		wave_bg.append(Vector2(x, y))
	draw_polyline(wave_bg, Color(0.2, 0.55, 0.95, 0.45), 6.0)

	# Vague principale
	var wave_pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(steps + 1):
		var x: float = cx - margin + (margin * 2.0 * float(i) / float(steps))
		var y: float = wy + sin(x * wave_frequency + _wave_time * wave_speed) * wave_amplitude
		wave_pts.append(Vector2(x, y))
	draw_polyline(wave_pts, Color(0.65, 0.92, 1.0, 0.95), 3.0)

	# Ecumes (petits reflets blancs sur les cretes)
	for i: int in range(0, steps, 4):
		var x: float = cx - margin + (margin * 2.0 * float(i) / float(steps))
		var y: float = wy + sin(x * wave_frequency + _wave_time * wave_speed) * wave_amplitude
		if sin(x * wave_frequency + _wave_time * wave_speed) > 0.6:
			draw_circle(Vector2(x, y - 2.0), 3.0, Color(1.0, 1.0, 1.0, 0.6))

func _check_skull_bounces() -> void:
	if player.velocity_y <= 0.0:
		return
	var player_bottom: float = player.get_bottom_y()
	var player_x: float = player.position.x
	for skull: Skull in skull_container.get_children():
		var skull_top: float = skull.get_top_y()
		var h_dist: float = abs(player_x - skull.position.x)
		if h_dist > skull.radius + player.player_width * 0.45:
			continue
		if player_bottom >= skull_top - bounce_check_tolerance \
				and player_bottom <= skull_top + skull.radius * 0.55:
			var is_perfect: bool = skull.is_perfect(player_bottom)
			var boost: float = player.get_bounce_boost(is_perfect)
			player.apply_bounce(boost)
			GameState.register_bounce(is_perfect)
			return

func _check_obstacle_hits() -> void:
	var pp: Vector2 = player.position
	var hw: float = player.player_width * 0.5
	var hh: float = player.player_height * 0.5
	for obs: Obstacle in obstacle_container.get_children():
		if obs.check_hit(pp, hw, hh):
			obs.hit.emit()
			if obs.lethal:
				GameState.trigger_game_over()
			else:
				player.current_speed = maxf(player.minimum_drift,
						player.current_speed - obs.speed_penalty)
			return

func _update_camera() -> void:
	camera.position.x = player.position.x + camera_x_offset
	camera.position.y = camera_y

func _on_game_over(_final_score: float) -> void:
	pass
