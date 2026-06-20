class_name Mine
extends Obstacle

# --- TUNING ---
@export var radius: float = 22.0
@export var spike_count: int = 8
@export var spike_length: float = 8.0

func check_hit(player_pos: Vector2, player_half_w: float, player_half_h: float) -> bool:
	var dx: float = abs(player_pos.x - position.x)
	var dy: float = abs(player_pos.y - position.y)
	return dx < radius + player_half_w and dy < radius + player_half_h

func _draw() -> void:
	for i: int in spike_count:
		var angle: float = (TAU / float(spike_count)) * float(i)
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		draw_line(dir * (radius - 2.0), dir * (radius + spike_length),
				Color(0.12, 0.12, 0.12), 4.0)
	draw_circle(Vector2.ZERO, radius, Color(0.12, 0.12, 0.12))
	var arm: float = radius * 0.45
	draw_line(Vector2(-arm, -arm), Vector2(arm, arm), Color(0.85, 0.85, 0.85), 2.5)
	draw_line(Vector2(arm, -arm), Vector2(-arm, arm), Color(0.85, 0.85, 0.85), 2.5)
