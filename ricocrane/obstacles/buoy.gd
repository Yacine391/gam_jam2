class_name Buoy
extends Obstacle

# --- TUNING ---
@export var width: float = 18.0
@export var height: float = 36.0
@export var bob_frequency: float = 0.9
@export var bob_amplitude: float = 8.0

var _base_y: float = 0.0
var _time: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
	lethal = false
	speed_penalty = 80.0
	_base_y = position.y
	_phase = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * bob_frequency + _phase) * bob_amplitude

func check_hit(player_pos: Vector2, player_half_w: float, player_half_h: float) -> bool:
	var dx: float = abs(player_pos.x - position.x)
	var dy: float = abs(player_pos.y - position.y)
	return dx < width * 0.5 + player_half_w and dy < height * 0.5 + player_half_h

func _draw() -> void:
	var hw: float = width * 0.5
	var hh: float = height * 0.5
	draw_rect(Rect2(-hw, -hh, width, height), Color(0.9, 0.25, 0.1))
	draw_circle(Vector2(0.0, -hh - 6.0), 6.0, Color(0.95, 0.85, 0.1))
	draw_line(Vector2(0.0, hh), Vector2(0.0, hh + 20.0), Color(0.6, 0.5, 0.3), 2.0)
