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
@export var jetski_color: Color = Color(1.0, 0.55, 0.0)

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
	# Jetski hull (pointy front)
	var hull_pts := PackedVector2Array([
		Vector2(-hw, hh),
		Vector2(hw + 8.0, hh),
		Vector2(hw + 16.0, 0.0),
		Vector2(hw + 8.0, -hh),
		Vector2(-hw, -hh),
	])
	draw_colored_polygon(hull_pts, jetski_color)
	# Hull stripe
	draw_line(Vector2(-hw + 4.0, 0.0), Vector2(hw + 4.0, 0.0), Color(1.0, 0.8, 0.2, 0.5), 3.0)
	# Windshield
	draw_rect(Rect2(-hw * 0.2, -hh - 10.0, player_width * 0.45, 10.0), Color(0.5, 0.88, 1.0, 0.75))
	# Wake trail
	draw_line(Vector2(-hw, 4.0), Vector2(-hw - 28.0, 4.0), Color(1.0, 1.0, 1.0, 0.7), 3.0)
	draw_line(Vector2(-hw, 8.0), Vector2(-hw - 18.0, 9.0), Color(1.0, 1.0, 1.0, 0.4), 2.0)
	# Crab body
	draw_circle(Vector2(0.0, -hh - 15.0), 12.0, Color(0.92, 0.18, 0.08))
	# Crab shell highlight
	draw_circle(Vector2(-3.0, -hh - 18.0), 5.0, Color(1.0, 0.35, 0.2, 0.5))
	# Eye stalks + eyes
	draw_line(Vector2(-5.0, -hh - 23.0), Vector2(-8.0, -hh - 29.0), Color(0.92, 0.18, 0.08), 2.0)
	draw_circle(Vector2(-8.0, -hh - 30.0), 3.5, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(-7.0, -hh - 30.5), 1.2, Color(1.0, 1.0, 1.0))
	draw_line(Vector2(5.0, -hh - 23.0), Vector2(8.0, -hh - 29.0), Color(0.92, 0.18, 0.08), 2.0)
	draw_circle(Vector2(8.0, -hh - 30.0), 3.5, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(7.0, -hh - 30.5), 1.2, Color(1.0, 1.0, 1.0))
	# Crab claws
	draw_line(Vector2(-hw * 0.7, -hh - 10.0), Vector2(-hw - 14.0, -hh - 24.0), Color(0.92, 0.18, 0.08), 3.0)
	draw_circle(Vector2(-hw - 14.0, -hh - 24.0), 6.0, Color(0.92, 0.18, 0.08))
	draw_line(Vector2(-hw - 8.0, -hh - 22.0), Vector2(-hw - 18.0, -hh - 28.0), Color(0.92, 0.18, 0.08), 2.0)
	draw_line(Vector2(hw * 0.7, -hh - 10.0), Vector2(hw + 14.0, -hh - 24.0), Color(0.92, 0.18, 0.08), 3.0)
	draw_circle(Vector2(hw + 14.0, -hh - 24.0), 6.0, Color(0.92, 0.18, 0.08))
	draw_line(Vector2(hw + 8.0, -hh - 22.0), Vector2(hw + 18.0, -hh - 28.0), Color(0.92, 0.18, 0.08), 2.0)
	# Player indicator (white arrow above)
	draw_line(Vector2(0.0, -hh - 46.0), Vector2(0.0, -hh - 54.0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_line(Vector2(-5.0, -hh - 49.0), Vector2(0.0, -hh - 54.0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_line(Vector2(5.0, -hh - 49.0), Vector2(0.0, -hh - 54.0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
