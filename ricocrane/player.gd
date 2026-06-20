class_name Player
extends Node2D

# --- TUNING ---
@export var initial_speed: float = 220.0
@export var friction: float = 18.0
@export var minimum_drift: float = 40.0
@export var gravity: float = 700.0
@export var water_bounce_damping: float = 0.25
@export var dive_force: float = 480.0
@export var water_line_y: float = 500.0
@export var player_width: float = 52.0
@export var player_height: float = 22.0
@export var bounce_boost_min: float = 160.0
@export var bounce_boost_max: float = 300.0
@export var bounce_vertical_multiplier: float = 3.0

var current_speed: float = 0.0
var velocity_y: float = 0.0
var _on_water: bool = false

func _ready() -> void:
	current_speed = initial_speed

func reset() -> void:
	current_speed = initial_speed
	velocity_y = 0.0
	_on_water = false

func physics_step(delta: float) -> void:
	current_speed = maxf(minimum_drift, current_speed - friction * delta)
	position.x += current_speed * delta

	velocity_y += gravity * delta
	position.y += velocity_y * delta

	if position.y >= water_line_y:
		position.y = water_line_y
		if velocity_y > 20.0 and not _on_water:
			GameState.reset_combo()
			_on_water = true
		velocity_y = -velocity_y * water_bounce_damping
	else:
		_on_water = false

func dive() -> void:
	velocity_y = dive_force

func apply_bounce(boost: float) -> void:
	velocity_y = -boost * bounce_vertical_multiplier
	current_speed += boost
	_on_water = false

func get_bottom_y() -> float:
	return position.y + player_height * 0.5

func get_bounce_boost(is_perfect: bool) -> float:
	if is_perfect:
		return bounce_boost_max
	return randf_range(bounce_boost_min, lerp(bounce_boost_min, bounce_boost_max, 0.6))

func _draw() -> void:
	var hw: float = player_width * 0.5
	var hh: float = player_height * 0.5
	draw_rect(Rect2(-hw, -hh, player_width, player_height), Color(1.0, 0.55, 0.0))
	draw_circle(Vector2(0.0, -hh - 9.0), 9.0, Color(1.0, 0.2, 0.2))
	draw_circle(Vector2(-5.0, -hh - 16.0), 2.5, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2(5.0, -hh - 16.0), 2.5, Color(0.0, 0.0, 0.0))
