extends CanvasLayer

# --- TUNING ---
@export var title_font_size: int = 72
@export var body_font_size: int = 28
@export var fade_in_duration: float = 0.35

var _best_score: float = 0.0

var _panel: Control
var _score_label: Label
var _best_label: Label
var _tween: Tween

func _ready() -> void:
	layer = 10
	_build_ui()
	hide()
	GameState.game_over.connect(_on_game_over)
	GameState.game_started.connect(_on_game_started)

func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.05, 0.18, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(bg)

	# Neon top border
	var border := ColorRect.new()
	border.color = Color(0.0, 0.9, 1.0, 0.8)
	border.set_anchors_preset(Control.PRESET_TOP_WIDE)
	border.offset_bottom = 4.0
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(border)

	var title := _lbl("RICOCRÂNE", title_font_size, Color(0.0, 0.9, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -500.0
	title.offset_right = 500.0
	title.offset_top = 110.0
	title.offset_bottom = 110.0 + title_font_size + 8
	_panel.add_child(title)

	var tagline := _lbl("Rebondis de crâne en crâne !", 22, Color(0.65, 0.92, 1.0))
	tagline.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tagline.offset_left = -400.0
	tagline.offset_right = 400.0
	tagline.offset_top = 200.0
	tagline.offset_bottom = 236.0
	_panel.add_child(tagline)

	_score_label = _lbl("", body_font_size, Color(1.0, 0.85, 0.0))
	_score_label.set_anchors_preset(Control.PRESET_CENTER)
	_score_label.offset_left = -400.0
	_score_label.offset_right = 400.0
	_score_label.offset_top = -30.0
	_score_label.offset_bottom = body_font_size + 10.0
	_panel.add_child(_score_label)

	_best_label = _lbl("", 22, Color(1.0, 0.55, 0.0))
	_best_label.set_anchors_preset(Control.PRESET_CENTER)
	_best_label.offset_left = -400.0
	_best_label.offset_right = 400.0
	_best_label.offset_top = 30.0
	_best_label.offset_bottom = 62.0
	_panel.add_child(_best_label)

	var prompt := _lbl("◆  Clic ou [R] pour rejouer  ◆", body_font_size, Color(0.9, 0.9, 1.0))
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -400.0
	prompt.offset_right = 400.0
	prompt.offset_top = -100.0
	prompt.offset_bottom = -100.0 + body_font_size + 8
	_panel.add_child(prompt)

func _lbl(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.modulate = color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _on_game_over(final_score: float) -> void:
	if final_score > _best_score:
		_best_score = final_score
	_score_label.text = "Score : %d" % int(final_score)
	_best_label.text = "Meilleur : %d" % int(_best_score)
	show()
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), fade_in_duration)

func _on_game_started() -> void:
	hide()
