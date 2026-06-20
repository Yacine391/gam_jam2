class_name Spawner
extends Node

# --- TUNING ---
@export var skull_scene: PackedScene
@export var obstacle_scenes: Array[PackedScene] = []
@export var spawn_ahead: float = 950.0
@export var despawn_behind: float = 450.0
@export var min_gap: float = 180.0
@export var max_gap: float = 330.0
@export var min_y: float = 300.0
@export var max_y: float = 460.0
@export var obstacle_min_y: float = 455.0
@export var obstacle_max_y: float = 485.0
@export var obstacle_start_distance: float = 800.0
@export var obstacle_chance: float = 0.28

var _skull_container: Node2D
var _obstacle_container: Node2D
var _next_spawn_x: float = 0.0

func setup(container: Node2D, start_x: float, obs_container: Node2D = null) -> void:
	_skull_container = container
	_obstacle_container = obs_container
	_next_spawn_x = start_x + 250.0

func update(player_x: float) -> void:
	_spawn_ahead(player_x)
	_despawn_behind(player_x)

func reset(start_x: float) -> void:
	if _skull_container:
		for skull in _skull_container.get_children():
			skull.queue_free()
	if _obstacle_container:
		for obs in _obstacle_container.get_children():
			obs.queue_free()
	_next_spawn_x = start_x + 250.0

func _spawn_ahead(player_x: float) -> void:
	while _next_spawn_x < player_x + spawn_ahead:
		var skull: Skull = skull_scene.instantiate() as Skull
		skull.position = Vector2(_next_spawn_x, randf_range(min_y, max_y))
		_skull_container.add_child(skull)

		if _obstacle_container and obstacle_scenes.size() > 0 \
				and _next_spawn_x > obstacle_start_distance \
				and randf() < obstacle_chance:
			var obs_scene: PackedScene = obstacle_scenes[randi() % obstacle_scenes.size()]
			var obs: Obstacle = obs_scene.instantiate() as Obstacle
			var gap: float = randf_range(60.0, 140.0)
			obs.position = Vector2(_next_spawn_x + gap, randf_range(obstacle_min_y, obstacle_max_y))
			_obstacle_container.add_child(obs)

		_next_spawn_x += randf_range(min_gap, max_gap)

func _despawn_behind(player_x: float) -> void:
	for skull in _skull_container.get_children():
		if skull.position.x < player_x - despawn_behind:
			skull.queue_free()
	if _obstacle_container:
		for obs in _obstacle_container.get_children():
			if obs.position.x < player_x - despawn_behind:
				obs.queue_free()
