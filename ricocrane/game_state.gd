extends Node

signal game_started
signal game_over
signal score_changed(score: float)
signal combo_changed(combo: int)
signal bounced(is_perfect: bool)

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
	score = distance * maxf(1.0, float(combo))
	score_changed.emit(score)

func register_bounce(is_perfect: bool) -> void:
	if state != State.PLAYING:
		return
	combo += 1
	combo_changed.emit(combo)
	bounced.emit(is_perfect)

func reset_combo() -> void:
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(combo)

func trigger_game_over() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	game_over.emit()
