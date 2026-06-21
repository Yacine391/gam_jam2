extends Node

# --- TUNING ---
@export var shake_on_bounce: float = 0.22
@export var shake_on_perfect: float = 0.65
@export var shake_decay: float = 2.8
@export var max_shake_offset: float = 16.0
@export var hitstop_duration: float = 0.055
@export var splash_count: int = 18
@export var splash_color: Color = Color(0.35, 0.82, 1.0, 0.9)

var _trauma: float = 0.0
var _camera: Camera2D
var _player: Node2D
var _noise: FastNoiseLite
var _noise_t: float = 0.0

func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.seed = randi()
	GameState.bounced.connect(_on_bounced)
	GameState.game_started.connect(_on_game_started)
	call_deferred("_find_nodes")

func _find_nodes() -> void:
	_camera = get_viewport().get_camera_2d()
	var node: Node = get_tree().root.find_child("Player", true, false)
	if node is Node2D:
		_player = node as Node2D

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		if _camera and _camera.offset != Vector2.ZERO:
			_camera.offset = Vector2.ZERO
		return
	_trauma = maxf(0.0, _trauma - shake_decay * delta)
	if not _camera:
		return
	_noise_t += delta * 9.0
	var s: float = _trauma * _trauma
	_camera.offset = Vector2(
		_noise.get_noise_2d(_noise_t, 0.0) * max_shake_offset * s,
		_noise.get_noise_2d(0.0, _noise_t) * max_shake_offset * s
	)

func _on_bounced(is_perfect: bool) -> void:
	var add: float = shake_on_perfect if is_perfect else shake_on_bounce
	_trauma = minf(1.0, _trauma + add)
	if is_perfect:
		_do_hitstop()
	if _player:
		_spawn_splash(_player.global_position)

func _on_game_started() -> void:
	_trauma = 0.0
	if _camera:
		_camera.offset = Vector2.ZERO

func _do_hitstop() -> void:
	Engine.time_scale = 0.0
	get_tree().create_timer(hitstop_duration, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0
	)

func _spawn_splash(world_pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.global_position = world_pos + Vector2(0.0, 14.0)
	p.amount = splash_count
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.92
	p.direction = Vector2(0.0, -1.0)
	p.spread = 65.0
	p.gravity = Vector2(0.0, 520.0)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 220.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = splash_color
	get_parent().add_child(p)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3, false, false, false).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)
