extends Node

# --- TUNING ---
@export var volume_music: float = 0.65
@export var volume_sfx: float = 1.0
@export var volume_perfect: float = 1.0

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _sfx_bonk: AudioStreamPlayer = $SfxBonk
@onready var _sfx_perfect: AudioStreamPlayer = $SfxPerfect
@onready var _sfx_splash: AudioStreamPlayer = $SfxSplash
@onready var _sfx_combo_up: AudioStreamPlayer = $SfxComboUp
@onready var _sfx_combo_lost: AudioStreamPlayer = $SfxComboLost
@onready var _sfx_game_over: AudioStreamPlayer = $SfxGameOver

func _ready() -> void:
	GameState.game_started.connect(_on_game_started)
	GameState.game_over.connect(_on_game_over)
	GameState.bounced.connect(_on_bounced)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.combo_lost.connect(_on_combo_lost)
	_music_player.finished.connect(_on_music_finished)

func _on_game_started() -> void:
	_music_player.volume_db = linear_to_db(volume_music)
	_music_player.play()

func _on_game_over(_score: float) -> void:
	_music_player.stop()
	_play_sfx(_sfx_game_over, volume_sfx)

func _on_bounced(is_perfect: bool) -> void:
	if is_perfect:
		_play_sfx(_sfx_perfect, volume_perfect)
	else:
		_play_sfx(_sfx_bonk, volume_sfx)

func _on_combo_changed(combo: int) -> void:
	if combo > 1:
		_play_sfx(_sfx_combo_up, volume_sfx)

func _on_combo_lost() -> void:
	_play_sfx(_sfx_combo_lost, volume_sfx)
	_play_sfx(_sfx_splash, volume_sfx)

func _on_music_finished() -> void:
	_music_player.play()

func _play_sfx(player: AudioStreamPlayer, vol: float) -> void:
	if player.stream == null:
		return
	player.volume_db = linear_to_db(vol)
	player.play()
