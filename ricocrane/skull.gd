class_name Skull
extends Node2D

# --- TUNING ---
@export var bob_frequency: float = 1.2
@export var bob_amplitude: float = 10.0
@export var perfect_window: float = 8.0
@export var radius: float = 28.0

var _base_y: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
	_base_y = position.y
	_phase = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * bob_frequency + _phase) * bob_amplitude

func get_top_y() -> float:
	return position.y - radius

func is_perfect(player_bottom_y: float) -> bool:
	return abs(player_bottom_y - get_top_y()) < perfect_window

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.88, 0.88, 0.82))
	var eye_r: float = radius * 0.18
	draw_circle(Vector2(-radius * 0.28, -radius * 0.1), eye_r, Color(0.08, 0.08, 0.08))
	draw_circle(Vector2(radius * 0.28, -radius * 0.1), eye_r, Color(0.08, 0.08, 0.08))
	draw_circle(Vector2(0.0, radius * 0.2), radius * 0.1, Color(0.12, 0.12, 0.12))
	draw_line(
		Vector2(-radius * 0.3, radius * 0.45),
		Vector2(radius * 0.3, radius * 0.45),
		Color(0.1, 0.1, 0.1), 2.0
	)
	# Perfect-zone indicator: yellow arc at top
	draw_arc(Vector2.ZERO, radius + 5.0, -PI * 0.6, -PI * 0.4, 10,
			Color(1.0, 1.0, 0.0, 0.7), 4.0)
