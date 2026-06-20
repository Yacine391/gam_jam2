class_name Whirlpool
extends Obstacle

# --- TUNING ---
@export var pull_radius: float = 60.0
@export var rotation_speed: float = 2.0
@export var draw_rings: int = 3
@export var drain_per_second: float = 60.0

var _angle: float = 0.0

func _ready() -> void:
	lethal = false
	speed_penalty = 0.0

func _process(delta: float) -> void:
	_angle += rotation_speed * delta
	queue_redraw()

func check_hit(player_pos: Vector2, player_half_w: float, player_half_h: float) -> bool:
	var dx: float = abs(player_pos.x - position.x)
	var dy: float = abs(player_pos.y - position.y)
	return dx < pull_radius + player_half_w and dy < pull_radius * 0.5 + player_half_h

func _draw() -> void:
	for i: int in draw_rings:
		var r: float = pull_radius * (float(i + 1) / float(draw_rings))
		var alpha: float = 0.6 - float(i) * 0.15
		draw_arc(Vector2.ZERO, r, _angle + float(i) * 0.8,
				_angle + float(i) * 0.8 + TAU * 0.75, 32,
				Color(0.05, 0.3, 0.8, alpha), 3.5)
	draw_circle(Vector2.ZERO, 8.0, Color(0.02, 0.15, 0.6, 0.9))
