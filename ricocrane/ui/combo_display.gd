extends CanvasLayer

# --- TUNING ---
@export var base_font_size: int = 52
@export var max_font_size: int = 96
@export var pulse_duration: float = 0.14
@export var fade_out_delay: float = 1.2

var _root: Control
var _label: Label
var _tween: Tween
var _hide_timer: float = 0.0
var _has_text: bool = false

func _ready() -> void:
	layer = 6
	_build_ui()
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.combo_lost.connect(_on_combo_lost)
	GameState.game_started.connect(_on_game_started)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", base_font_size)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -350.0
	_label.offset_right = 350.0
	_label.offset_top = -80.0
	_label.offset_bottom = 80.0
	_label.modulate = Color(1.0, 0.9, 0.0, 0.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_label)

func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0 and _has_text:
			_fade_out()

func _on_combo_changed(combo: int) -> void:
	if combo <= 1:
		_fade_out()
		return

	var t: float = clampf(float(combo - 2) / 12.0, 0.0, 1.0)
	var fs: int = int(lerp(float(base_font_size), float(max_font_size), t))
	_label.add_theme_font_size_override("font_size", fs)

	# Color shifts magenta as combo climbs
	var r: float = 1.0
	var g: float = lerpf(0.9, 0.1, t)
	var b: float = lerpf(0.0, 0.9, t * t)
	_label.text = "×%d COMBO!" % combo
	_has_text = true
	_hide_timer = fade_out_delay

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate", Color(r, g, b, 1.0), 0.05)
	_tween.tween_property(_label, "scale", Vector2(1.25, 1.25), 0.0)
	_tween.tween_property(_label, "scale", Vector2(1.0, 1.0), pulse_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_combo_lost() -> void:
	if not _has_text:
		return
	_hide_timer = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate", Color(1.0, 0.15, 0.15, 1.0), 0.05)
	_tween.tween_property(_label, "scale", Vector2(0.85, 0.85), 0.08)
	_tween.tween_property(_label, "modulate:a", 0.0, 0.22)
	_tween.tween_callback(func() -> void:
		_label.text = ""
		_label.scale = Vector2.ONE
		_has_text = false
	)

func _on_game_started() -> void:
	if _tween:
		_tween.kill()
	_label.text = ""
	_label.modulate = Color(1.0, 0.9, 0.0, 0.0)
	_label.scale = Vector2.ONE
	_has_text = false
	_hide_timer = 0.0

func _fade_out() -> void:
	_has_text = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void:
		_label.text = ""
		_label.scale = Vector2.ONE
	)
