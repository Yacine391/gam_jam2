extends Control

var game: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	if game == null:
		return
	var size := get_viewport_rect().size
	_draw_top_hud(size)
	_draw_controls(size)
	if game.race_state == game.RaceState.COUNTDOWN:
		_draw_countdown(size)
	elif game.race_state == game.RaceState.DEAD:
		_draw_dead_overlay(size)
	elif game.race_state == game.RaceState.FINISHED:
		_draw_finish_overlay(size)

func _draw_top_hud(size: Vector2) -> void:
	var panel := Color(0.02, 0.10, 0.18, 0.78)
	draw_rect(Rect2(24, 22, 250, 72), panel)
	draw_rect(Rect2(38, 64, 220, 14), Color(1, 1, 1, 0.16))
	var speed_ratio: float = clamp(float(game.player_speed) / 560.0, 0.0, 1.0)
	draw_rect(Rect2(38, 64, 220.0 * speed_ratio, 14), Color("38e8ff"))
	draw_circle(Vector2(58, 45), 12, Color("38e8ff"))
	draw_line(Vector2(58, 45), Vector2(68, 38), Color("0a2430"), 4)
	draw_string(ThemeDB.fallback_font, Vector2(88, 53), str(int(game.player_speed)), HORIZONTAL_ALIGNMENT_LEFT, 150, 28, Color.WHITE)
	var center := Vector2(size.x * 0.5, 56)
	for i in range(game.TOTAL_LAPS):
		var active: bool = i < game.player_lap
		var c := Color("ffd447") if active else Color(1, 1, 1, 0.28)
		draw_circle(center + Vector2((i - 1) * 34, 0), 11, c)
	var rank_box := Rect2(size.x - 150, 22, 126, 72)
	draw_rect(rank_box, panel)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 133, 70), str(game.player_rank), HORIZONTAL_ALIGNMENT_CENTER, 46, 42, Color("ffd447"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 82, 66), "/", HORIZONTAL_ALIGNMENT_CENTER, 18, 25, Color(1, 1, 1, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 58, 66), str(game.BOT_COUNT + 1), HORIZONTAL_ALIGNMENT_CENTER, 30, 25, Color.WHITE)

func _draw_controls(size: Vector2) -> void:
	var y := size.y - 84.0
	var faded := Color(1, 1, 1, 0.16)
	for x in [82.0, 154.0]:
		draw_circle(Vector2(x, y), 32, faded)
	_draw_arrow(Vector2(82, y), PI, Color(1, 1, 1, 0.58))
	_draw_arrow(Vector2(154, y), 0, Color(1, 1, 1, 0.58))
	draw_circle(Vector2(size.x - 84, y), 38, Color(0.2, 0.9, 1.0, 0.18))
	_draw_arrow(Vector2(size.x - 84, y), -PI * 0.5, Color("38e8ff"))

func _draw_arrow(center: Vector2, angle: float, color: Color) -> void:
	var f := Vector2.from_angle(angle)
	var s := f.rotated(PI * 0.5)
	var pts := PackedVector2Array([center + f * 18, center - f * 12 + s * 12, center - f * 12 - s * 12])
	draw_colored_polygon(pts, color)

func _draw_countdown(size: Vector2) -> void:
	var n := int(ceil(game.countdown))
	if n > 3:
		n = 3
	var center := size * 0.5
	draw_circle(center, 78, Color(0.02, 0.1, 0.18, 0.78))
	draw_string(ThemeDB.fallback_font, center + Vector2(-42, 33), str(max(1, n)), HORIZONTAL_ALIGNMENT_CENTER, 84, 88, Color.WHITE)

func _draw_dead_overlay(size: Vector2) -> void:
	_draw_dim(size)
	var c := size * 0.5
	_draw_skull(c + Vector2(0, -55))
	_draw_restart(c + Vector2(0, 105))

func _draw_finish_overlay(size: Vector2) -> void:
	_draw_dim(size)
	var c := size * 0.5
	_draw_trophy(c + Vector2(0, -50))
	_draw_restart(c + Vector2(0, 105))

func _draw_dim(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.04, 0.08, 0.76))

func _draw_skull(center: Vector2) -> void:
	draw_circle(center, 54, Color("f3ead8"))
	draw_rect(Rect2(center.x - 34, center.y + 30, 68, 35), Color("f3ead8"))
	draw_circle(center + Vector2(-20, -5), 13, Color("18222d"))
	draw_circle(center + Vector2(20, -5), 13, Color("18222d"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, 8), center + Vector2(-8, 24), center + Vector2(8, 24)]), Color("18222d"))
	for x in [-24.0, -8.0, 8.0, 24.0]:
		draw_line(center + Vector2(x, 38), center + Vector2(x, 61), Color("18222d"), 4)

func _draw_trophy(center: Vector2) -> void:
	var gold := Color("ffd447")
	draw_rect(Rect2(center.x - 38, center.y - 46, 76, 68), gold)
	draw_arc(center + Vector2(-40, -20), 30, PI * 0.5, PI * 1.5, 18, gold, 10)
	draw_arc(center + Vector2(40, -20), 30, -PI * 0.5, PI * 0.5, 18, gold, 10)
	draw_rect(Rect2(center.x - 8, center.y + 20, 16, 38), gold)
	draw_rect(Rect2(center.x - 42, center.y + 55, 84, 14), gold)

func _draw_restart(center: Vector2) -> void:
	draw_circle(center, 52, Color(0.15, 0.83, 0.94, 0.2))
	draw_arc(center, 25, -2.4, 2.4, 28, Color("38e8ff"), 7)
	var tip := center + Vector2.from_angle(-2.4) * 25
	var f := Vector2.from_angle(-1.1)
	var s := f.rotated(PI * 0.5)
	draw_colored_polygon(PackedVector2Array([tip + f * 13, tip - f * 8 + s * 8, tip - f * 8 - s * 8]), Color("38e8ff"))
