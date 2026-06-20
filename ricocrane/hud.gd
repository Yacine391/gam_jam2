class_name HUD
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var speed_label: Label = $SpeedLabel
@onready var combo_label: Label = $ComboLabel
@onready var perfect_label: Label = $PerfectLabel
@onready var game_over_panel: Control = $GameOverPanel

var _perfect_timer: float = 0.0

func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.bounced.connect(_on_bounced)
	GameState.game_over.connect(_on_game_over)
	GameState.game_started.connect(_on_game_started)
	game_over_panel.hide()
	perfect_label.hide()

func _process(delta: float) -> void:
	if _perfect_timer > 0.0:
		_perfect_timer -= delta
		if _perfect_timer <= 0.0:
			perfect_label.hide()

func update_speed(speed: float) -> void:
	speed_label.text = "Speed: %d" % int(speed)

func _on_score_changed(score: float) -> void:
	score_label.text = "Score: %d" % int(score)

func _on_combo_changed(combo: int) -> void:
	if combo > 1:
		combo_label.text = "x%d COMBO!" % combo
		combo_label.modulate = Color(1.0, 0.85, 0.0)
	elif combo == 1:
		combo_label.text = "x1"
		combo_label.modulate = Color(1.0, 1.0, 1.0)
	else:
		combo_label.text = ""

func _on_bounced(is_perfect: bool) -> void:
	if is_perfect:
		perfect_label.show()
		_perfect_timer = 0.7

func _on_game_over() -> void:
	game_over_panel.show()

func _on_game_started() -> void:
	game_over_panel.hide()
	perfect_label.hide()
	score_label.text = "Score: 0"
	combo_label.text = ""
