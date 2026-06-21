extends Node

signal game_started
signal game_over(final_score: float)
signal race_finished(player_position: int)
signal tsunami_triggered
signal score_changed(score: float)
signal speed_changed(speed: float)
signal bounced(is_perfect: bool)
signal combo_changed(combo: int)
signal combo_lost
signal race_position_changed(pos: int)

const POINTS_PER_BOUNCE: float = 100.0
const PERFECT_MULTIPLIER: float = 2.0

enum State { IDLE, PLAYING, DEAD, TSUNAMI, RACE_FINISHED }

var state: State = State.IDLE
var score: float = 0.0
var combo: int = 0
var distance: float = 0.0
var race_position: int = 1
var best_score: float = 0.0

func start_game() -> void:
	state = State.PLAYING
	score = 0.0
	combo = 0
	distance = 0.0
	race_position = 1
	game_started.emit()

func add_distance(d: float) -> void:
	if state != State.PLAYING:
		return
	distance += d

func report_speed(speed: float) -> void:
	if state != State.PLAYING:
		return
	speed_changed.emit(speed)

func update_race_position(pos: int) -> void:
	if race_position != pos:
		race_position = pos
		race_position_changed.emit(pos)

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

func trigger_tsunami() -> void:
	if state == State.DEAD or state == State.TSUNAMI or state == State.RACE_FINISHED:
		return
	state = State.TSUNAMI
	tsunami_triggered.emit()

func trigger_game_over() -> void:
	if state == State.DEAD or state == State.TSUNAMI or state == State.RACE_FINISHED:
		return
	state = State.DEAD
	if score > best_score:
		best_score = score
	game_over.emit(score)

func trigger_race_finished(pos: int) -> void:
	if state == State.RACE_FINISHED:
		return
	state = State.RACE_FINISHED
	if score > best_score:
		best_score = score
	race_finished.emit(pos)
