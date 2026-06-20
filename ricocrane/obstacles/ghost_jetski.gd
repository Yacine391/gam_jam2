class_name GhostJetski
extends Obstacle

# --- TUNING ---
@export var width: float = 58.0
@export var height: float = 22.0
@export var drift_speed: float = -45.0
@export var bob_frequency: float = 0.7
@export var bob_amplitude: float = 6.0

var _base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_time += delta
	position.x += drift_speed * delta
	position.y = _base_y + sin(_time * bob_frequency) * bob_amplitude

func check_hit(player_pos: Vector2, player_half_w: float, player_half_h: float) -> bool:
	var dx: float = abs(player_pos.x - position.x)
	var dy: float = abs(player_pos.y - position.y)
	return dx < width * 0.5 + player_half_w and dy < height * 0.5 + player_half_h

func _draw() -> void:
	var hw: float = width * 0.5
	var hh: float = height * 0.5
	draw_rect(Rect2(-hw, -hh, width, height), Color(0.7, 0.7, 0.8, 0.45))
	draw_rect(Rect2(-hw, -hh, width, height), Color(0.8, 0.8, 1.0, 0.6), false, 2.0)
	draw_rect(Rect2(-hw * 0.5, -hh - 8.0, hw, 8.0), Color(0.6, 0.6, 0.75, 0.4))
	draw_line(Vector2(-hw, 0.0), Vector2(-hw - 14.0, 6.0), Color(0.8, 0.8, 1.0, 0.5), 3.0)
