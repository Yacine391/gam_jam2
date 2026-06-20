extends Node2D

# --- TUNING ---
@export var death_wall_speed: float = 80.0
@export var death_wall_start_offset: float = 320.0
@export var camera_x_offset: float = 200.0
@export var camera_y: float = 300.0
@export var bounce_check_tolerance: float = 18.0
@export var start_player_x: float = 200.0
@export var start_player_y: float = 350.0

@onready var player: Player = $Player
@onready var skull_container: Node2D = $SkullContainer
@onready var spawner: Spawner = $Spawner
@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD
@onready var death_wall_poly: Polygon2D = $DeathWallVisual

var _death_wall_x: float = 0.0

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	death_wall_poly.polygon = PackedVector2Array([
		Vector2(-50.0, -600.0),
		Vector2(0.0,  -600.0),
		Vector2(0.0,   900.0),
		Vector2(-50.0,  900.0),
	])
	death_wall_poly.color = Color(0.9, 0.1, 0.1, 0.85)
	spawner.setup(skull_container, start_player_x)
	_start_game()

func _start_game() -> void:
	player.position = Vector2(start_player_x, start_player_y)
	player.reset()
	_death_wall_x = start_player_x - death_wall_start_offset
	death_wall_poly.position.x = _death_wall_x
	spawner.reset(start_player_x)
	camera.position = Vector2(start_player_x + camera_x_offset, camera_y)
	GameState.start_game()

func _process(delta: float) -> void:
	match GameState.state:
		GameState.State.PLAYING:
			player.physics_step(delta)
			spawner.update(player.position.x)
			_update_death_wall(delta)
			_check_skull_bounces()
			_check_game_over()
			_update_camera()
			hud.update_speed(player.current_speed)
			GameState.add_distance(player.current_speed * delta)
		GameState.State.DEAD:
			_update_camera()

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

func _update_death_wall(delta: float) -> void:
	_death_wall_x += death_wall_speed * delta
	death_wall_poly.position.x = _death_wall_x

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

func _check_game_over() -> void:
	if player.current_speed < player.min_speed:
		GameState.trigger_game_over()
	elif player.position.x <= _death_wall_x:
		GameState.trigger_game_over()

func _update_camera() -> void:
	camera.position.x = player.position.x + camera_x_offset
	camera.position.y = camera_y

func _on_game_over() -> void:
	pass
