extends Node

signal game_started
signal game_over(final_score: float)
signal score_changed(score: float)
signal speed_changed(speed: float)
signal bounced(is_perfect: bool)
signal combo_changed(combo: int)
signal combo_lost

# --- TUNING ---
const POINTS_PER_BOUNCE: float = 100.0
const PERFECT_MULTIPLIER: float = 2.0

enum State { IDLE, PLAYING, DEAD }

var state: State = State.IDLE
var score: float = 0.0
var combo: int = 0
var distance: float = 0.0

func start_game() -> void:
	state = State.PLAYING
	score = 0.0
	combo = 0
	distance = 0.0
	game_started.emit()

func add_distance(d: float) -> void:
	if state != State.PLAYING:
		return
	distance += d

func report_speed(speed: float) -> void:
	if state != State.PLAYING:
		return
	speed_changed.emit(speed)

func register_bounce(is_perfect: bool) -> void:
	if state != State.PLAYING:
		return
	combo += 1
	var points: float = POINTS_PER_BOUNCE * float(combo)
	if is_perfect:
		points *= PERFECT_MULTIPLIER
	score += points
	score_changed.emit(score)
	combo_changed.emit(combo)
	bounced.emit(is_perfect)

func reset_combo() -> void:
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(combo)
	combo_lost.emit()

func trigger_game_over() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	game_over.emit(score)
