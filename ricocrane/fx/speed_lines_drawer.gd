extends Node2D

# --- TUNING ---
@export var speed_threshold: float = 180.0
@export var speed_max: float = 480.0
@export var line_count: int = 22
@export var line_color: Color = Color(0.85, 0.95, 1.0, 0.22)
@export var line_width: float = 2.0

var _current_speed: float = 0.0
var _time: float = 0.0
var _angles: Array[float] = []
var _start_norms: Array[float] = []
var _len_norms: Array[float] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for i in range(line_count):
		_angles.append(_rng.randf_range(0.0, TAU))
		_start_norms.append(_rng.randf_range(0.25, 0.75))
		_len_norms.append(_rng.randf_range(0.06, 0.22))
	GameState.speed_changed.connect(_on_speed_changed)
	GameState.game_started.connect(_on_game_started)

func _on_speed_changed(speed: float) -> void:
	_current_speed = speed

func _on_game_started() -> void:
	_current_speed = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var intensity: float = clampf(
		(_current_speed - speed_threshold) / (speed_max - speed_threshold), 0.0, 1.0
	)
	if intensity < 0.01:
		return

	var vp: Vector2 = get_viewport().get_visible_rect().size
	var cx: float = vp.x * 0.5
	var cy: float = vp.y * 0.42
	var max_r: float = maxf(vp.x, vp.y) * 0.72

	var col := line_color
	col.a = line_color.a * intensity * intensity

	for i in range(line_count):
		var angle: float = _angles[i] + _time * 0.18
		var s: float = _start_norms[i]
		var l: float = _len_norms[i] * intensity
		var p1 := Vector2(cx + cos(angle) * s * max_r,
						  cy + sin(angle) * s * max_r)
		var p2 := Vector2(cx + cos(angle) * (s + l) * max_r,
						  cy + sin(angle) * (s + l) * max_r)
		draw_line(p1, p2, col, line_width)
