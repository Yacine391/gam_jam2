extends Node3D

const TAU_F := TAU
const BOT_COUNT := 5
const TOTAL_LAPS := 3
const MAX_BOMB_HITS := 3
const TRACK_WIDTH := 15.0
const PLAYER_Y := 0.55
const TIDE_CYCLE := 18.0
const TIDE_MAX_HEIGHT := 1.35

const ITEM_NONE := 0
const ITEM_ROCKET := 1
const ITEM_OIL := 2
const ITEM_BOOST := 3
const ITEM_CHICKEN := 4
const ITEM_ILYAS := 5

const CHARACTER_COUNT := 6
const CHARACTER_COLORS: Array[Color] = [Color("6cdf55"), Color("ff8b3d"), Color("f4f4f4"), Color("55dded"), Color("ffd447"), Color("9c79ff")]

var map_id := -1
var selected_character := 0
var character_selected := false
var race_started := false
var race_finished := false
var dead := false
var player_progress := 0.0
var player_speed := 0.0
var player_lane := 0.0
var player_lap := 0
var bomb_hits := 0
var held_item := ITEM_NONE
var stun_time := 0.0
var slow_time := 0.0
var boost_time := 0.0
var invincible_time := 0.0
var wave_time := 0.0
var death_time := 0.0
var countdown_time := 0.0
var countdown_phase := 0
var race_go := false
var item_roll_time := 0.0
var item_roll_final := ITEM_NONE
var item_roll_visual := ITEM_NONE
var item_roll_tick := 0.0
var mouse_use_was_down := false
var tide_time := 0.0
var tide_level := 0.0
var tide_current := 0.0
var tide_cycle_index := 0
var rng := RandomNumberGenerator.new()

var maps: Array[Dictionary] = [
	{
		"points": PackedVector2Array([Vector2(-52, -8), Vector2(-39, -31), Vector2(-8, -38), Vector2(24, -31), Vector2(50, -8), Vector2(42, 20), Vector2(14, 34), Vector2(-16, 29), Vector2(-43, 16)]),
		"bombs": 7, "boxes": 9, "color": Color("43b7e8"), "islands": 2
	},
	{
		"points": PackedVector2Array([Vector2(-55, -20), Vector2(-20, -34), Vector2(10, -20), Vector2(47, -32), Vector2(57, 0), Vector2(29, 18), Vector2(9, 39), Vector2(-24, 30), Vector2(-48, 11), Vector2(-22, -2)]),
		"bombs": 10, "boxes": 11, "color": Color("41d39d"), "islands": 4
	},
	{
		"points": PackedVector2Array([Vector2(-58, -18), Vector2(-25, -40), Vector2(8, -26), Vector2(41, -39), Vector2(58, -13), Vector2(37, 7), Vector2(55, 29), Vector2(18, 39), Vector2(-7, 18), Vector2(-34, 38), Vector2(-56, 12), Vector2(-30, -2)]),
		"bombs": 13, "boxes": 13, "color": Color("9b6cff"), "islands": 6
	}
]

var player: Node3D
var bots: Array[Dictionary] = []
var bombs: Array[Dictionary] = []
var boxes: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var oils: Array[Dictionary] = []
var camera: Camera3D
var world_root: Node3D
var water_mesh: MeshInstance3D
var hud: CanvasLayer
var item_display: Control
var traffic_display: Control
var tide_display: Control
var minimap: Control
var lap_label: Label
var finish_overlay: Control
var item_panel_style: StyleBoxFlat
var traffic_panel_style: StyleBoxFlat
var hit_icons: Array[ColorRect] = []
var lap_icons: Array[ColorRect] = []
var start_overlay: Control
var death_overlay: ColorRect
var chicken_tex: Texture2D
var ilyas_tex: Texture2D

func _ready() -> void:
	rng.randomize()
	chicken_tex = load("res://Gemini_Generated_Image_hbcexrhbcexrhbce.png")
	ilyas_tex = load("res://ilias1.grosy@epitech.eu.jpg")
	_build_environment()
	_build_hud()
	_show_character_select()

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("7dd9ff")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	e.ambient_light_energy = 0.85
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58.0
	add_child(camera)
	world_root = Node3D.new()
	world_root.name = "World"
	add_child(world_root)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	item_display = Control.new()
	item_display.position = Vector2(1070, 500)
	item_display.size = Vector2(180, 180)
	item_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_display.pivot_offset = item_display.size * 0.5
	item_panel_style = _panel_style(Color(0.03, 0.08, 0.16, 0.88), 28.0)
	item_display.draw.connect(_draw_item_display)
	hud.add_child(item_display)
	traffic_display = Control.new()
	traffic_display.position = Vector2(545, 55)
	traffic_display.size = Vector2(190, 92)
	traffic_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	traffic_panel_style = _panel_style(Color(0.03, 0.05, 0.08, 0.92), 18.0)
	traffic_display.draw.connect(_draw_traffic_light)
	hud.add_child(traffic_display)
	tide_display = Control.new()
	tide_display.position = Vector2(292, 24)
	tide_display.size = Vector2(170, 70)
	tide_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tide_display.draw.connect(_draw_tide_display)
	hud.add_child(tide_display)
	minimap = Control.new()
	minimap.position = Vector2(24, 82)
	minimap.size = Vector2(240, 205)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(_draw_minimap)
	hud.add_child(minimap)
	lap_label = Label.new()
	lap_label.position = Vector2(86, 290)
	lap_label.size = Vector2(120, 44)
	lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lap_label.add_theme_font_size_override("font_size", 28)
	lap_label.add_theme_color_override("font_color", Color.WHITE)
	lap_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	lap_label.add_theme_constant_override("shadow_offset_x", 3)
	lap_label.add_theme_constant_override("shadow_offset_y", 3)
	hud.add_child(lap_label)
	for i in range(MAX_BOMB_HITS):
		var h := ColorRect.new()
		h.position = Vector2(34 + i * 42, 32)
		h.size = Vector2(30, 30)
		h.color = Color("ffdf45")
		hit_icons.append(h)
		hud.add_child(h)
	for i in range(TOTAL_LAPS):
		var l := ColorRect.new()
		l.position = Vector2(1100 + i * 42, 32)
		l.size = Vector2(30, 30)
		l.color = Color(1, 1, 1, 0.28)
		lap_icons.append(l)
		hud.add_child(l)
	death_overlay = ColorRect.new()
	death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_overlay.color = Color(0.02, 0.08, 0.16, 0.0)
	death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(death_overlay)

func _draw_traffic_light() -> void:
	if map_id < 0 or countdown_phase > 2:
		return
	traffic_display.draw_style_box(traffic_panel_style, Rect2(Vector2.ZERO, traffic_display.size))
	var colors: Array[Color] = [Color("ff3b3b"), Color("ffad2f"), Color("43f06b")]
	for i in range(3):
		var alpha: float = 1.0 if i == countdown_phase else 0.18
		var c: Color = colors[i]
		c.a = alpha
		traffic_display.draw_circle(Vector2(39 + i * 56, 46), 22.0, c)
		traffic_display.draw_arc(Vector2(39 + i * 56, 46), 22.0, 0.0, TAU_F, 32, Color(1, 1, 1, 0.45), 3.0)


func _draw_tide_display() -> void:
	if map_id < 0:
		return
	var panel := _panel_style(Color(0.02, 0.08, 0.16, 0.84), 18.0)
	tide_display.draw_style_box(panel, Rect2(Vector2.ZERO, tide_display.size))
	var fill_height: float = 46.0 * tide_level
	var water_rect := Rect2(Vector2(12, 58.0 - fill_height), Vector2(146, fill_height))
	tide_display.draw_rect(water_rect, Color(0.12, 0.65, 0.92, 0.9), true)
	for line_index in range(3):
		var y: float = 20.0 + float(line_index) * 14.0
		var amplitude: float = 3.0 + tide_level * 4.0
		var pts := PackedVector2Array()
		for x_index in range(25):
			var x: float = 14.0 + float(x_index) * 6.0
			var phase: float = float(x_index) * 0.55 + tide_time * 3.0 + float(line_index)
			pts.append(Vector2(x, y + sin(phase) * amplitude))
		for point_index in range(pts.size() - 1):
			tide_display.draw_line(pts[point_index], pts[point_index + 1], Color.WHITE, 3.0, true)
	var arrow_x: float = 82.0 + tide_current * 28.0
	tide_display.draw_colored_polygon(PackedVector2Array([Vector2(arrow_x, 10), Vector2(arrow_x - 9.0 * signf(tide_current), 17), Vector2(arrow_x - 9.0 * signf(tide_current), 3)]), Color("ffe34d"))

func _draw_item_display() -> void:
	var shown: int = item_roll_visual if item_roll_time > 0.0 else held_item
	if shown == ITEM_NONE:
		return
	item_display.draw_style_box(item_panel_style, Rect2(Vector2(5, 5), Vector2(170, 170)))
	var center := Vector2(90, 90)
	if shown == ITEM_ROCKET:
		item_display.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -50), center + Vector2(27, 25), center, center + Vector2(-27, 25)]), Color("ff5a42"))
		item_display.draw_circle(center + Vector2(0, 28), 14.0, Color("ffd447"))
	elif shown == ITEM_OIL:
		item_display.draw_circle(center + Vector2(-18, 8), 34.0, Color("15151f"))
		item_display.draw_circle(center + Vector2(23, 16), 27.0, Color("15151f"))
		item_display.draw_circle(center + Vector2(7, -16), 30.0, Color("252537"))
	elif shown == ITEM_BOOST:
		item_display.draw_colored_polygon(PackedVector2Array([center + Vector2(12, -57), center + Vector2(-26, 5), center + Vector2(-3, 5), center + Vector2(-18, 56), center + Vector2(34, -12), center + Vector2(8, -12)]), Color("ffe34d"))
	elif shown == ITEM_CHICKEN and chicken_tex != null:
		item_display.draw_texture_rect(chicken_tex, Rect2(25, 25, 130, 130), false)
	elif shown == ITEM_ILYAS and ilyas_tex != null:
		item_display.draw_texture_rect(ilyas_tex, Rect2(25, 25, 130, 130), false)

func _draw_minimap() -> void:
	if map_id < 0:
		return
	var panel := _panel_style(Color(0.02, 0.06, 0.12, 0.82), 18.0)
	minimap.draw_style_box(panel, Rect2(Vector2.ZERO, minimap.size))
	var points: PackedVector2Array = maps[map_id]["points"]
	var samples := PackedVector2Array()
	for i in range(96):
		var t: float = float(i) / 96.0
		var wp: Vector2 = _sample_curve_points(points, t)
		samples.append(Vector2(120, 102) + wp * 1.55)
	for i in range(samples.size()):
		var j: int = (i + 1) % samples.size()
		minimap.draw_line(samples[i], samples[j], Color(1, 1, 1, 0.9), 5.0, true)
	var pp: Vector2 = _sample_curve_points(points, fposmod(player_progress, TAU_F) / TAU_F)
	minimap.draw_circle(Vector2(120, 102) + pp * 1.55, 7.0, Color("ff334f"))
	var bot_colors: Array[Color] = [Color("ffd447"), Color("70e37a"), Color("9c79ff"), Color("ff8b3d"), Color("55dded")]
	for i in range(bots.size()):
		var bp: Vector2 = _sample_curve_points(points, fposmod(float(bots[i].progress), TAU_F) / TAU_F)
		minimap.draw_circle(Vector2(120, 102) + bp * 1.55, 5.0, bot_colors[i])

func _panel_style(color: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(1, 1, 1, 0.45)
	return style

func _show_character_select() -> void:
	start_overlay = Control.new()
	start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(start_overlay)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("70d8f4")
	start_overlay.add_child(bg)
	for i in range(CHARACTER_COUNT):
		var button := Button.new()
		var col: int = i % 3
		var row: int = int(i / 3)
		button.position = Vector2(235 + col * 285, 105 + row * 270)
		button.size = Vector2(220, 220)
		button.text = ""
		button.flat = true
		button.pressed.connect(_select_character.bind(i))
		start_overlay.add_child(button)
		var portrait := Control.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.position = button.position
		portrait.size = button.size
		portrait.draw.connect(_draw_character_portrait.bind(portrait, i, false))
		start_overlay.add_child(portrait)

func _select_character(index: int) -> void:
	selected_character = index
	character_selected = true
	start_overlay.queue_free()
	start_overlay = null
	_show_map_select()

func _draw_character_portrait(node: Control, character_id: int, small: bool) -> void:
	var size: Vector2 = node.size
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * (0.34 if not small else 0.38)
	node.draw_circle(center, minf(size.x, size.y) * 0.46, Color(1, 1, 1, 0.22))
	node.draw_circle(center, radius, CHARACTER_COLORS[character_id])
	if character_id == 0:
		for side in [-1.0, 1.0]:
			node.draw_colored_polygon(PackedVector2Array([center + Vector2(side * radius * 0.45, -radius * 0.72), center + Vector2(side * radius * 0.76, -radius * 1.15), center + Vector2(side * radius * 0.12, -radius * 0.88)]), Color("ffe07a"))
	elif character_id == 1:
		for side in [-1.0, 1.0]:
			node.draw_colored_polygon(PackedVector2Array([center + Vector2(side * radius * 0.42, -radius * 0.62), center + Vector2(side * radius * 0.9, -radius * 1.08), center + Vector2(side * radius * 0.15, -radius * 0.88)]), Color("ff8b3d"))
		node.draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.46, radius * 0.34), center + Vector2(radius * 0.46, radius * 0.34), center + Vector2(0, radius * 0.88)]), Color("fff2d6"))
	elif character_id == 2:
		node.draw_circle(center + Vector2(-radius * 0.68, -radius * 0.66), radius * 0.34, Color("171722"))
		node.draw_circle(center + Vector2(radius * 0.68, -radius * 0.66), radius * 0.34, Color("171722"))
	elif character_id == 3:
		node.draw_circle(center + Vector2(0, -radius * 0.52), radius * 0.42, Color("55dded"))
	elif character_id == 4:
		for side in [-1.0, 1.0]:
			node.draw_colored_polygon(PackedVector2Array([center + Vector2(side * radius * 0.48, -radius * 0.55), center + Vector2(side * radius * 0.84, -radius * 1.0), center + Vector2(side * radius * 0.12, -radius * 0.82)]), Color("ffd447"))
	elif character_id == 5:
		node.draw_circle(center + Vector2(0, -radius * 0.72), radius * 0.28, Color("dcbcff"))
	var eye_y: float = center.y - radius * 0.15
	if character_id == 5:
		node.draw_circle(Vector2(center.x, eye_y), radius * 0.23, Color.WHITE)
		node.draw_circle(Vector2(center.x, eye_y), radius * 0.09, Color("171722"))
	else:
		for side in [-1.0, 1.0]:
			node.draw_circle(Vector2(center.x + side * radius * 0.3, eye_y), radius * 0.18, Color.WHITE)
			node.draw_circle(Vector2(center.x + side * radius * 0.3, eye_y), radius * 0.07, Color("171722"))
	node.draw_arc(center + Vector2(0, radius * 0.24), radius * 0.28, 0.15, PI - 0.15, 18, Color("171722"), maxf(3.0, radius * 0.07))

func _show_map_select() -> void:
	start_overlay = Control.new()
	start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(start_overlay)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("70d8f4")
	start_overlay.add_child(bg)
	for i in range(3):
		var card := Button.new()
		card.position = Vector2(120 + i * 390, 150)
		card.size = Vector2(300, 390)
		card.text = ""
		card.flat = true
		card.modulate = maps[i].color
		card.pressed.connect(_select_map.bind(i))
		start_overlay.add_child(card)
		var preview := Control.new()
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.position = card.position
		preview.size = card.size
		preview.draw.connect(_draw_map_preview.bind(preview, i))
		start_overlay.add_child(preview)

func _draw_map_preview(node: Control, index: int) -> void:
	var data: Dictionary = maps[index]
	var source: PackedVector2Array = data["points"]
	var pts := PackedVector2Array()
	for i in range(72):
		var t: float = float(i) / 72.0
		var world_p: Vector2 = _sample_curve_points(source, t)
		pts.append(Vector2(150, 190) + world_p * 2.05)
	node.draw_circle(Vector2(150, 190), 145.0, Color(1, 1, 1, 0.16))
	for i in range(pts.size()):
		var next_i: int = (i + 1) % pts.size()
		node.draw_line(pts[i], pts[next_i], Color.WHITE, 20.0, true)
		node.draw_line(pts[i], pts[next_i], Color(0.08, 0.45, 0.72, 0.95), 11.0, true)
	for j in range(3 + index * 2):
		node.draw_circle(Vector2(58 + j * 36, 340), 8.0, Color("ff574d"))

func _select_map(index: int) -> void:
	map_id = index
	start_overlay.queue_free()
	start_overlay = null
	_build_map()
	_start_race()

func _build_map() -> void:
	for child in world_root.get_children():
		child.queue_free()
	bots.clear()
	bombs.clear()
	boxes.clear()
	projectiles.clear()
	oils.clear()
	water_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 130)
	water_mesh.mesh = plane
	water_mesh.material_override = _mat(Color("178fc8"), 0.35, 0.12)
	world_root.add_child(water_mesh)
	_build_decorative_islands()
	_build_track_buoys()
	_build_track_guides()
	_build_beach()
	_build_finish_line()
	player = _make_jetski(Color("ff334f"), selected_character)
	world_root.add_child(player)
	var bot_character_ids: Array[int] = []
	for character_id in range(CHARACTER_COUNT):
		if character_id != selected_character:
			bot_character_ids.append(character_id)
	for i in range(BOT_COUNT):
		var bot_character: int = bot_character_ids[i]
		var bot_node := _make_jetski([Color("ffd447"), Color("70e37a"), Color("9c79ff"), Color("ff8b3d"), Color("55dded")][i], bot_character)
		world_root.add_child(bot_node)
		bots.append({"node": bot_node, "character": bot_character, "progress": fposmod(-0.4 - i * 0.33, TAU_F), "lap": -1, "speed": 0.37 + rng.randf_range(-0.025, 0.04), "lane": float((i % 3) - 1) * 3.2, "slow": 0.0, "stun": 0.0, "hits": 0, "dead": false, "item": ITEM_NONE, "item_cd": rng.randf_range(1.0, 4.0)})
	var map_data: Dictionary = maps[map_id]
	var bomb_count: int = int(map_data["bombs"])
	var box_count: int = int(map_data["boxes"])
	for i in range(bomb_count):
		var p: float = TAU_F * float(i + 1) / float(bomb_count + 1) + rng.randf_range(-0.12, 0.12)
		var lane: float = rng.randf_range(-TRACK_WIDTH * 0.34, TRACK_WIDTH * 0.34)
		var n: Node3D = _make_bomb()
		world_root.add_child(n)
		bombs.append({"node": n, "progress": p, "lane": lane, "active": true, "cooldown": 0.0})
	for i in range(box_count):
		var p: float = TAU_F * (float(i) + 0.5) / float(box_count)
		var lane: float = float([-4.4, 0.0, 4.4][i % 3])
		var n: Node3D = _make_mystery_box()
		world_root.add_child(n)
		boxes.append({"node": n, "progress": p, "lane": lane, "cooldown": 0.0})

func _build_track_buoys() -> void:
	for i in range(96):
		var a := TAU_F * float(i) / 96.0
		for side in [-1.0, 1.0]:
			var p := _track_position(a, side * TRACK_WIDTH * 0.55)
			var buoy := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.28
			mesh.bottom_radius = 0.38
			mesh.height = 1.0
			buoy.mesh = mesh
			buoy.position = p + Vector3(0, 0.35, 0)
			buoy.material_override = _mat(Color("ff6b55") if i % 2 == 0 else Color.WHITE, 0.5, 0.0)
			world_root.add_child(buoy)


func _build_track_guides() -> void:
	var sample_count: int = 220 if map_id == 2 else 170
	for side in [-1.0, 1.0]:
		for i in range(sample_count):
			var a: float = TAU_F * float(i) / float(sample_count)
			var b: float = TAU_F * float(i + 1) / float(sample_count)
			var start: Vector3 = _track_position(a, side * TRACK_WIDTH * 0.50)
			var finish: Vector3 = _track_position(b, side * TRACK_WIDTH * 0.50)
			_add_track_guide_segment(start, finish, i, side)
	for i in range(sample_count):
		if i % 5 >= 3:
			continue
		var a: float = TAU_F * float(i) / float(sample_count)
		var center: Vector3 = _track_position(a, 0.0)
		var marker := MeshInstance3D.new()
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.28, 0.07, 1.15)
		marker.mesh = marker_mesh
		marker.position = center + Vector3(0, 0.06, 0)
		marker.rotation.y = _track_yaw(a)
		marker.material_override = _mat(Color(1.0, 1.0, 1.0, 0.82), 0.35, 0.0)
		world_root.add_child(marker)

func _add_track_guide_segment(start: Vector3, finish: Vector3, index: int, side: float) -> void:
	var delta: Vector3 = finish - start
	var length: float = delta.length()
	if length <= 0.01:
		return
	var guide := MeshInstance3D.new()
	var guide_mesh := BoxMesh.new()
	guide_mesh.size = Vector3(0.20, 0.10, length + 0.10)
	guide.mesh = guide_mesh
	guide.position = (start + finish) * 0.5 + Vector3(0, 0.08, 0)
	guide.rotation.y = atan2(delta.x, delta.z)
	var guide_color := Color("fff4b8") if index % 2 == 0 else Color("ffffff")
	if side < 0.0:
		guide_color = Color("b9efff") if index % 2 == 0 else Color("ffffff")
	guide.material_override = _mat(guide_color, 0.35, 0.0)
	world_root.add_child(guide)

func _build_beach() -> void:
	var beach := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(38.0, 1.0, 15.0)
	beach.mesh = cube
	beach.position = Vector3(0, -0.1, 49)
	beach.material_override = _mat(Color("f7d184"), 0.95, 0.0)
	world_root.add_child(beach)

func _build_finish_line() -> void:
	var root := Node3D.new()
	var center: Vector3 = _track_position(0.0, 0.0) + Vector3(0, 0.08, 0)
	var tangent: Vector3 = _track_tangent(0.0)
	var normal := Vector3(-tangent.z, 0, tangent.x)
	for i in range(12):
		var tile := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.25, 0.12, 1.25)
		tile.mesh = mesh
		tile.position = center + normal * (-6.9 + float(i) * 1.25)
		tile.rotation.y = atan2(tangent.x, tangent.z)
		tile.material_override = _mat(Color.WHITE if i % 2 == 0 else Color("15151f"), 0.5, 0.0)
		root.add_child(tile)
	world_root.add_child(root)

func _start_race() -> void:
	_reset_race()

func _reset_race() -> void:
	race_started = true
	race_finished = false
	dead = false
	race_go = false
	countdown_time = 0.0
	countdown_phase = 0
	player_progress = 0.0
	player_speed = 0.0
	player_lane = 0.0
	player_lap = 0
	bomb_hits = 0
	held_item = ITEM_NONE
	item_roll_time = 0.0
	item_roll_final = ITEM_NONE
	item_roll_visual = ITEM_NONE
	item_roll_tick = 0.0
	mouse_use_was_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	stun_time = 0.0
	slow_time = 0.0
	boost_time = 0.0
	invincible_time = 1.2
	wave_time = 0.0
	tide_time = 0.0
	tide_level = 0.0
	tide_current = 0.0
	tide_cycle_index = 0
	if water_mesh != null:
		water_mesh.position.y = 0.0
	death_time = 0.0
	death_overlay.color.a = 0.0
	if finish_overlay != null:
		finish_overlay.queue_free()
		finish_overlay = null
	for i in range(bots.size()):
		bots[i].lap = -1
		bots[i].hits = 0
		bots[i].dead = false
		var bot_node: Node3D = bots[i].node
		bot_node.visible = true
	traffic_display.visible = true
	traffic_display.queue_redraw()
	item_display.queue_redraw()
	_update_hud()

func _update_countdown(delta: float) -> void:
	countdown_time += delta
	if countdown_time < 1.5:
		countdown_phase = 0
	elif countdown_time < 3.0:
		countdown_phase = 1
	elif countdown_time < 3.8:
		countdown_phase = 2
		race_go = true
	else:
		countdown_phase = 3
		race_go = true
		traffic_display.visible = false
	traffic_display.queue_redraw()

func _physics_process(delta: float) -> void:
	if not race_started or map_id < 0:
		return
	if dead:
		_update_death(delta)
		_update_camera(delta)
		return
	if race_finished:
		return
	_handle_mouse_item_use()
	_update_countdown(delta)
	_update_tide(delta)
	_update_item_roll(delta)
	_update_player(delta)
	_update_bots(delta)
	_update_boxes(delta)
	_update_bombs(delta)
	_update_projectiles(delta)
	_update_oils(delta)
	_update_camera(delta)
	_update_hud()

func _update_tide(delta: float) -> void:
	if race_go:
		tide_time += delta
	var cycle_position: float = fposmod(tide_time, TIDE_CYCLE)
	var new_cycle_index: int = int(floor(tide_time / TIDE_CYCLE))
	if new_cycle_index != tide_cycle_index:
		tide_cycle_index = new_cycle_index
	if cycle_position < 5.0:
		tide_level = 0.0
	elif cycle_position < 9.0:
		tide_level = smoothstep(0.0, 1.0, (cycle_position - 5.0) / 4.0)
	elif cycle_position < 13.0:
		tide_level = 1.0
	else:
		tide_level = 1.0 - smoothstep(0.0, 1.0, (cycle_position - 13.0) / 5.0)
	var direction: float = -1.0 if tide_cycle_index % 2 == 0 else 1.0
	tide_current = direction * tide_level
	if water_mesh != null:
		water_mesh.position.y = tide_level * TIDE_MAX_HEIGHT
		water_mesh.rotation.y = sin(tide_time * 0.25) * 0.015 * tide_level
	tide_display.queue_redraw()

func _update_player(delta: float) -> void:
	stun_time = maxf(0.0, stun_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	boost_time = maxf(0.0, boost_time - delta)
	invincible_time = maxf(0.0, invincible_time - delta)
	wave_time = maxf(0.0, wave_time - delta)
	var z_pressed: bool = Input.is_key_pressed(KEY_Z)
	var s_pressed: bool = Input.is_key_pressed(KEY_S)
	var q_pressed: bool = Input.is_key_pressed(KEY_Q)
	var d_pressed: bool = Input.is_key_pressed(KEY_D)
	var throttle: float = float(int(z_pressed) - int(s_pressed))
	var steer: float = float(int(d_pressed) - int(q_pressed))
	var can_rev: bool = countdown_phase >= 1
	if stun_time > 0.0:
		player_speed = move_toward(player_speed, 0.0, delta * 1.8)
	elif can_rev:
		var max_speed: float = 0.58 if boost_time > 0.0 else 0.42
		max_speed *= lerpf(1.0, 0.76, tide_level)
		if slow_time > 0.0:
			max_speed *= 0.52
		if throttle > 0.0:
			player_speed = move_toward(player_speed, max_speed, delta * 0.36)
		elif throttle < 0.0:
			player_speed = move_toward(player_speed, -0.12, delta * 0.4)
		else:
			player_speed = move_toward(player_speed, 0.0, delta * 0.2)
		player_lane = clampf(player_lane + steer * delta * 10.0, -TRACK_WIDTH * 0.42, TRACK_WIDTH * 0.42)
	if race_go and tide_level > 0.05:
		var steering_resistance: float = 0.45 if absf(steer) > 0.1 else 1.0
		player_lane = clampf(player_lane + tide_current * delta * 3.8 * steering_resistance, -TRACK_WIDTH * 0.42, TRACK_WIDTH * 0.42)
	if race_go:
		player_progress += player_speed * delta
	if player_progress >= TAU_F:
		player_progress -= TAU_F
		player_lap += 1
		if player_lap >= TOTAL_LAPS:
			race_finished = true
			_show_finish_ranking()
	if player_progress < 0.0:
		player_progress += TAU_F
	player.position = _track_position(player_progress, player_lane) + Vector3(0, PLAYER_Y + tide_level * TIDE_MAX_HEIGHT, 0)
	player.rotation.y = _track_yaw(player_progress)
	if wave_time > 0.0:
		player.position.y += sin(Time.get_ticks_msec() * 0.025) * 0.45

func _update_bots(delta: float) -> void:
	for i in range(bots.size()):
		var b: Dictionary = bots[i]
		var node: Node3D = b.node
		if bool(b.dead):
			node.position = Vector3(-12.0 + float(i) * 4.5, 1.1, 50.0)
			node.rotation.x += delta * 1.5
			bots[i] = b
			continue
		b.slow = maxf(0.0, float(b.slow) - delta)
		b.stun = maxf(0.0, float(b.stun) - delta)
		b.item_cd = float(b.item_cd) - delta
		var speed := float(b.speed) if race_go else 0.0
		if float(b.slow) > 0.0:
			speed *= 0.45
		speed *= lerpf(1.0, 0.80, tide_level)
		if float(b.stun) > 0.0:
			speed = 0.0
		var old_progress: float = float(b.progress)
		var next_progress: float = old_progress + speed * delta
		if next_progress >= TAU_F:
			next_progress -= TAU_F
			b.lap = int(b.lap) + 1
		b.progress = next_progress
		if rng.randf() < 0.004:
			b.lane = clampf(float(b.lane) + rng.randf_range(-2.5, 2.5), -TRACK_WIDTH * 0.4, TRACK_WIDTH * 0.4)
		if race_go and tide_level > 0.05:
			b.lane = clampf(float(b.lane) + tide_current * delta * 2.8, -TRACK_WIDTH * 0.4, TRACK_WIDTH * 0.4)
		node.position = _track_position(float(b.progress), float(b.lane)) + Vector3(0, PLAYER_Y + tide_level * TIDE_MAX_HEIGHT, 0)
		node.rotation.y = _track_yaw(float(b.progress))
		if int(b.item) != ITEM_NONE and float(b.item_cd) <= 0.0 and rng.randf() < 0.018:
			_bot_use_item(i)
		bots[i] = b

func _update_boxes(delta: float) -> void:
	for i in range(boxes.size()):
		var b: Dictionary = boxes[i]
		b.cooldown = maxf(0.0, float(b.cooldown) - delta)
		var n: Node3D = b.node
		n.position = _track_position(float(b.progress), float(b.lane)) + Vector3(0, 1.15 + tide_level * TIDE_MAX_HEIGHT + sin(tide_time * 3.0 + float(i)) * 0.12, 0)
		n.rotation.y += delta * 1.8
		n.visible = float(b.cooldown) <= 0.0
		if n.visible and held_item == ITEM_NONE and item_roll_time <= 0.0 and _progress_distance(player_progress, float(b.progress)) < 0.065 and absf(player_lane - float(b.lane)) < 2.3:
			_start_item_roll()
			b.cooldown = 5.0
		for j in range(bots.size()):
			var bot: Dictionary = bots[j]
			if n.visible and int(bot.item) == ITEM_NONE and _progress_distance(float(bot.progress), float(b.progress)) < 0.05 and absf(float(bot.lane) - float(b.lane)) < 2.1:
				bot.item = _random_item()
				bot.item_cd = rng.randf_range(0.7, 2.0)
				bots[j] = bot
				b.cooldown = 5.0
		boxes[i] = b

func _update_bombs(delta: float) -> void:
	for i in range(bombs.size()):
		var b: Dictionary = bombs[i]
		b.cooldown = maxf(0.0, float(b.cooldown) - delta)
		var n: Node3D = b.node
		n.position = _track_position(float(b.progress), float(b.lane)) + Vector3(0, 0.65 + tide_level * TIDE_MAX_HEIGHT, 0)
		n.rotation.y += 0.03
		n.visible = float(b.cooldown) <= 0.0
		if not n.visible:
			bombs[i] = b
			continue
		if invincible_time <= 0.0 and _progress_distance(player_progress, float(b.progress)) < 0.055 and absf(player_lane - float(b.lane)) < 2.2:
			b.cooldown = 3.0
			bombs[i] = b
			_hit_player_bomb()
			return
		for j in range(bots.size()):
			var bot: Dictionary = bots[j]
			if bool(bot.dead):
				continue
			if _progress_distance(float(bot.progress), float(b.progress)) < 0.055 and absf(float(bot.lane) - float(b.lane)) < 2.2:
				b.cooldown = 3.0
				bot.hits = int(bot.hits) + 1
				bot.progress = fposmod(float(bot.progress) - 0.42, TAU_F)
				bot.stun = 1.0
				bot.slow = 1.8
				if int(bot.hits) >= MAX_BOMB_HITS:
					bot.dead = true
				bots[j] = bot
				break
		bombs[i] = b

func _hit_player_bomb() -> void:
	bomb_hits += 1
	player_progress = fposmod(player_progress - 0.42, TAU_F)
	player_speed = 0.02
	wave_time = 1.25
	invincible_time = 1.8
	stun_time = 0.7
	if bomb_hits >= MAX_BOMB_HITS:
		dead = true
		death_time = 0.0

func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Dictionary = projectiles[i]
		p.progress = fposmod(float(p.progress) + float(p.speed) * delta, TAU_F)
		p.life = float(p.life) - delta
		var n: Node3D = p.node
		n.position = _track_position(float(p.progress), float(p.lane)) + Vector3(0, 1.0 + tide_level * TIDE_MAX_HEIGHT, 0)
		if bool(p.from_player):
			for j in range(bots.size()):
				if _progress_distance(float(p.progress), float(bots[j].progress)) < 0.055 and absf(float(p.lane) - float(bots[j].lane)) < 2.5:
					bots[j].stun = 1.8 if int(p.kind) == ITEM_ILYAS else 1.0
					bots[j].slow = 2.6 if int(p.kind) == ITEM_CHICKEN else 1.2
					_flash_special(int(p.kind), n.position)
					p.life = 0.0
		else:
			if invincible_time <= 0.0 and _progress_distance(float(p.progress), player_progress) < 0.055 and absf(float(p.lane) - player_lane) < 2.5:
				stun_time = 1.2
				slow_time = 2.0
				invincible_time = 1.5
				p.life = 0.0
		if float(p.life) <= 0.0:
			n.queue_free()
			projectiles.remove_at(i)
		else:
			projectiles[i] = p

func _update_oils(delta: float) -> void:
	for i in range(oils.size() - 1, -1, -1):
		var o: Dictionary = oils[i]
		o.life = float(o.life) - delta
		var n: Node3D = o.node
		n.position = _track_position(float(o.progress), float(o.lane)) + Vector3(0, 0.08 + tide_level * TIDE_MAX_HEIGHT, 0)
		if bool(o.from_player):
			for j in range(bots.size()):
				if _progress_distance(float(o.progress), float(bots[j].progress)) < 0.05 and absf(float(o.lane) - float(bots[j].lane)) < 2.4:
					bots[j].slow = 2.5
					o.life = 0.0
		else:
			if _progress_distance(float(o.progress), player_progress) < 0.05 and absf(float(o.lane) - player_lane) < 2.4:
				slow_time = 2.5
				o.life = 0.0
		if float(o.life) <= 0.0:
			n.queue_free()
			oils.remove_at(i)
		else:
			oils[i] = o

func _handle_mouse_item_use() -> void:
	var mouse_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_down and not mouse_use_was_down and race_started and not race_finished and not dead:
		_try_use_player_item()
	mouse_use_was_down = mouse_down

func _input(event: InputEvent) -> void:
	if map_id < 0 or start_overlay != null:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE and race_started and not race_finished:
			_try_use_player_item()
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			_build_map()
			_reset_race()

func _try_use_player_item() -> void:
	if item_roll_time > 0.0:
		return
	if held_item == ITEM_NONE:
		return
	_use_player_item()

func _use_player_item() -> void:
	match held_item:
		ITEM_BOOST:
			boost_time = 1.8
		ITEM_OIL:
			_spawn_oil(player_progress - 0.07, player_lane, true)
		ITEM_ROCKET, ITEM_CHICKEN, ITEM_ILYAS:
			_spawn_projectile(player_progress + 0.06, player_lane, true, held_item)
	held_item = ITEM_NONE
	item_display.scale = Vector2(1.22, 1.22)
	var use_tween: Tween = create_tween()
	use_tween.set_trans(Tween.TRANS_BACK)
	use_tween.set_ease(Tween.EASE_OUT)
	use_tween.tween_property(item_display, "scale", Vector2.ONE, 0.22)
	_update_hud()

func _bot_use_item(index: int) -> void:
	var b: Dictionary = bots[index]
	match int(b.item):
		ITEM_BOOST:
			b.speed = minf(0.52, float(b.speed) + 0.05)
		ITEM_OIL:
			_spawn_oil(float(b.progress) - 0.06, float(b.lane), false)
		ITEM_ROCKET, ITEM_CHICKEN, ITEM_ILYAS:
			_spawn_projectile(float(b.progress) + 0.05, float(b.lane), false, int(b.item))
	b.item = ITEM_NONE
	b.item_cd = rng.randf_range(2.0, 5.0)
	bots[index] = b

func _spawn_projectile(progress: float, lane: float, from_player: bool, kind: int) -> void:
	var n := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55 if kind == ITEM_ROCKET else 0.8
	sphere.height = sphere.radius * 2.0
	n.mesh = sphere
	n.material_override = _mat(Color("ff5733") if kind == ITEM_ROCKET else Color("ffd447"), 0.35, 0.2)
	world_root.add_child(n)
	projectiles.append({"node": n, "progress": progress, "lane": lane, "speed": 0.85 if from_player else 0.72, "life": 4.5, "from_player": from_player, "kind": kind})

func _spawn_oil(progress: float, lane: float, from_player: bool) -> void:
	var n := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.45
	cyl.bottom_radius = 1.6
	cyl.height = 0.08
	n.mesh = cyl
	n.position = _track_position(progress, lane) + Vector3(0, 0.08, 0)
	n.material_override = _mat(Color(0.03, 0.03, 0.05, 0.85), 0.15, 0.0)
	world_root.add_child(n)
	oils.append({"node": n, "progress": progress, "lane": lane, "life": 7.0, "from_player": from_player})

func _flash_special(kind: int, pos: Vector3) -> void:
	if kind != ITEM_CHICKEN and kind != ITEM_ILYAS:
		return
	var s := Sprite3D.new()
	s.texture = chicken_tex if kind == ITEM_CHICKEN else ilyas_tex
	s.position = pos + Vector3(0, 3.0, 0)
	s.pixel_size = 0.006
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world_root.add_child(s)
	var tween := create_tween()
	tween.tween_property(s, "position:y", s.position.y + 5.0, 0.9)
	tween.parallel().tween_property(s, "modulate:a", 0.0, 0.9)
	tween.finished.connect(s.queue_free)

func _random_item() -> int:
	var r := rng.randf()
	if r < 0.36:
		return ITEM_ROCKET
	if r < 0.62:
		return ITEM_OIL
	if r < 0.86:
		return ITEM_BOOST
	if r < 0.94:
		return ITEM_CHICKEN
	return ITEM_ILYAS

func _update_camera(delta: float) -> void:
	if player == null:
		return
	var tangent := _track_tangent(player_progress)
	var target := player.position - tangent * 12.0 + Vector3(0, 9.5, 0)
	if dead:
		target = Vector3(0, 13, 58)
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 4.5))
	camera.look_at(player.position + tangent * 7.0, Vector3.UP)

func _update_death(delta: float) -> void:
	death_time += delta
	var t := clampf(death_time / 2.2, 0.0, 1.0)
	player.position = player.position.lerp(Vector3(0, 1.1, 50), t * 0.08)
	player.rotation.x += delta * 2.0
	death_overlay.color.a = clampf((death_time - 1.0) * 0.35, 0.0, 0.68)

func _update_hud() -> void:
	for i in range(hit_icons.size()):
		hit_icons[i].color = Color("ff4b4b") if i < bomb_hits else Color("ffdf45")
	for i in range(lap_icons.size()):
		lap_icons[i].color = Color("4dff9b") if i < player_lap else Color(1, 1, 1, 0.28)
	lap_label.text = str(mini(player_lap, TOTAL_LAPS)) + "/" + str(TOTAL_LAPS)
	item_display.queue_redraw()
	minimap.queue_redraw()
	tide_display.queue_redraw()

func _show_finish_ranking() -> void:
	finish_overlay = Control.new()
	finish_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(finish_overlay)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.05, 0.1, 0.9)
	finish_overlay.add_child(bg)
	var racers: Array[Dictionary] = []
	racers.append({"character": selected_character, "player": true, "dead": false, "score": float(player_lap) * TAU_F + player_progress})
	for i in range(bots.size()):
		var bot: Dictionary = bots[i]
		var score: float = float(int(bot.lap)) * TAU_F + float(bot.progress)
		if bool(bot.dead):
			score -= 1000.0
		racers.append({"character": int(bot.character), "player": false, "dead": bool(bot.dead), "score": score})
	racers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	var ranking := Control.new()
	ranking.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ranking.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking.draw.connect(_draw_finish_ranking.bind(ranking, racers))
	finish_overlay.add_child(ranking)
	for i in range(racers.size()):
		var portrait := Control.new()
		portrait.position = Vector2(420, 119 + float(i) * 88.0)
		portrait.size = Vector2(64, 64)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.draw.connect(_draw_character_portrait.bind(portrait, int(racers[i].character), true))
		ranking.add_child(portrait)

func _draw_finish_ranking(node: Control, racers: Array[Dictionary]) -> void:
	var medal_colors: Array[Color] = [Color("ffd447"), Color("d9e1ea"), Color("d68a4a"), Color("5b7290"), Color("5b7290"), Color("5b7290")]
	for i in range(racers.size()):
		var row_y: float = 115.0 + float(i) * 88.0
		var row_rect := Rect2(Vector2(325, row_y), Vector2(630, 72))
		var row_style := _panel_style(Color(0.08, 0.13, 0.22, 0.96), 24.0)
		node.draw_style_box(row_style, row_rect)
		var medal_center := Vector2(375, row_y + 36)
		node.draw_circle(medal_center, 24.0, medal_colors[i])
		for pip in range(i + 1):
			var angle: float = -PI * 0.5 + TAU_F * float(pip) / float(i + 1)
			node.draw_circle(medal_center + Vector2(cos(angle), sin(angle)) * 11.0, 3.8, Color("171722"))
		var ski_color: Color = Color("ff334f") if bool(racers[i].player) else CHARACTER_COLORS[int(racers[i].character)].darkened(0.15)
		node.draw_rect(Rect2(Vector2(535, row_y + 22), Vector2(285, 28)), ski_color, true)
		node.draw_colored_polygon(PackedVector2Array([Vector2(820, row_y + 22), Vector2(900, row_y + 36), Vector2(820, row_y + 50)]), ski_color)
		if bool(racers[i].dead):
			node.draw_line(Vector2(880, row_y + 16), Vector2(920, row_y + 56), Color("ff4b4b"), 8.0)
			node.draw_line(Vector2(920, row_y + 16), Vector2(880, row_y + 56), Color("ff4b4b"), 8.0)
	var restart_center := Vector2(640, 655)
	node.draw_arc(restart_center, 28.0, -PI * 0.2, PI * 1.55, 32, Color.WHITE, 7.0)
	node.draw_colored_polygon(PackedVector2Array([restart_center + Vector2(-31, -18), restart_center + Vector2(-6, -21), restart_center + Vector2(-20, 2)]), Color.WHITE)

func _start_item_roll() -> void:
	item_roll_final = _random_item()
	item_roll_visual = ITEM_ROCKET
	item_roll_time = 1.25
	item_roll_tick = 0.0
	item_display.scale = Vector2(0.7, 0.7)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(item_display, "scale", Vector2.ONE, 0.28)
	item_display.queue_redraw()

func _update_item_roll(delta: float) -> void:
	if item_roll_time <= 0.0:
		return
	item_roll_time = maxf(0.0, item_roll_time - delta)
	item_roll_tick -= delta
	if item_roll_tick <= 0.0:
		item_roll_tick = 0.09
		item_roll_visual = rng.randi_range(ITEM_ROCKET, ITEM_ILYAS)
		item_display.rotation = rng.randf_range(-0.12, 0.12)
		item_display.queue_redraw()
	if item_roll_time <= 0.0:
		held_item = item_roll_final
		item_roll_visual = held_item
		item_display.rotation = 0.0
		item_display.queue_redraw()

func _track_position(progress: float, lane: float) -> Vector3:
	var data: Dictionary = maps[map_id]
	var points: PackedVector2Array = data["points"]
	var t: float = fposmod(progress, TAU_F) / TAU_F
	var center2: Vector2 = _sample_curve_points(points, t)
	var tangent2: Vector2 = _sample_curve_tangent(points, t)
	var normal2 := Vector2(-tangent2.y, tangent2.x).normalized()
	var final2: Vector2 = center2 + normal2 * lane
	return Vector3(final2.x, 0.0, final2.y)

func _track_tangent(progress: float) -> Vector3:
	var data: Dictionary = maps[map_id]
	var points: PackedVector2Array = data["points"]
	var t: float = fposmod(progress, TAU_F) / TAU_F
	var tangent2: Vector2 = _sample_curve_tangent(points, t)
	return Vector3(tangent2.x, 0.0, tangent2.y).normalized()

func _track_yaw(progress: float) -> float:
	var tangent := _track_tangent(progress)
	return atan2(tangent.x, tangent.z)

func _sample_curve_points(points: PackedVector2Array, t: float) -> Vector2:
	var count: int = points.size()
	var scaled: float = fposmod(t, 1.0) * float(count)
	var i1: int = int(floor(scaled)) % count
	var local_t: float = scaled - floor(scaled)
	var i0: int = (i1 - 1 + count) % count
	var i2: int = (i1 + 1) % count
	var i3: int = (i1 + 2) % count
	return _catmull_rom(points[i0], points[i1], points[i2], points[i3], local_t)

func _sample_curve_tangent(points: PackedVector2Array, t: float) -> Vector2:
	var epsilon := 0.001
	var before: Vector2 = _sample_curve_points(points, t - epsilon)
	var after: Vector2 = _sample_curve_points(points, t + epsilon)
	return (after - before).normalized()

func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

func _progress_distance(a: float, b: float) -> float:
	var d := absf(a - b)
	return minf(d, TAU_F - d)

func _make_jetski(color: Color, character_id: int) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.7, 0.65, 3.4)
	body.mesh = box
	body.material_override = _mat(color, 0.3, 0.18)
	root.add_child(body)
	var nose := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.15
	cone.bottom_radius = 0.8
	cone.height = 1.8
	nose.mesh = cone
	nose.rotation_degrees.x = 90
	nose.position.z = 2.15
	nose.material_override = _mat(color.lightened(0.15), 0.28, 0.2)
	root.add_child(nose)
	_add_character_driver(root, character_id)
	return root

func _build_decorative_islands() -> void:
	var data: Dictionary = maps[map_id]
	var count: int = int(data["islands"])
	for i in range(count):
		var island := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var radius: float = 4.5 + float(i % 3) * 1.8
		cyl.top_radius = radius
		cyl.bottom_radius = radius + 1.0
		cyl.height = 0.7
		island.mesh = cyl
		var angle: float = TAU_F * float(i) / float(maxi(1, count)) + float(map_id) * 0.37
		var dist: float = 17.0 + float((i * 7) % 15)
		island.position = Vector3(cos(angle) * dist, 0.05, sin(angle) * dist)
		island.material_override = _mat(Color("f3c978"), 0.95, 0.0)
		world_root.add_child(island)

func _add_character_driver(root: Node3D, character_id: int) -> void:
	var color: Color = CHARACTER_COLORS[character_id]
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.58
	body_mesh.height = 1.25
	body.mesh = body_mesh
	body.position = Vector3(0, 1.05, -0.28)
	body.scale = Vector3(1.0, 1.25, 0.85)
	body.material_override = _mat(color.darkened(0.08), 0.65, 0.0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.5
	head_mesh.height = 1.0
	head.mesh = head_mesh
	head.position = Vector3(0, 1.78, -0.18)
	head.material_override = _mat(color, 0.6, 0.0)
	root.add_child(head)
	if character_id in [1, 4]:
		for side in [-1.0, 1.0]:
			var ear := MeshInstance3D.new()
			var ear_mesh := CylinderMesh.new()
			ear_mesh.top_radius = 0.02
			ear_mesh.bottom_radius = 0.2
			ear_mesh.height = 0.55
			ear.mesh = ear_mesh
			ear.position = Vector3(side * 0.34, 2.2, -0.2)
			ear.rotation_degrees.z = side * -28.0
			ear.material_override = _mat(color, 0.55, 0.0)
			root.add_child(ear)
	elif character_id == 0:
		for side in [-1.0, 1.0]:
			var horn := MeshInstance3D.new()
			var horn_mesh := CylinderMesh.new()
			horn_mesh.top_radius = 0.02
			horn_mesh.bottom_radius = 0.12
			horn_mesh.height = 0.5
			horn.mesh = horn_mesh
			horn.position = Vector3(side * 0.31, 2.26, -0.2)
			horn.rotation_degrees.z = side * -22.0
			horn.material_override = _mat(Color("ffe07a"), 0.5, 0.0)
			root.add_child(horn)
	elif character_id == 2:
		for side in [-1.0, 1.0]:
			var ear := MeshInstance3D.new()
			var ear_mesh := SphereMesh.new()
			ear_mesh.radius = 0.22
			ear_mesh.height = 0.44
			ear.mesh = ear_mesh
			ear.position = Vector3(side * 0.38, 2.16, -0.2)
			ear.material_override = _mat(Color("171722"), 0.65, 0.0)
			root.add_child(ear)
	elif character_id == 3:
		var top_eye := MeshInstance3D.new()
		var top_eye_mesh := SphereMesh.new()
		top_eye_mesh.radius = 0.24
		top_eye_mesh.height = 0.48
		top_eye.mesh = top_eye_mesh
		top_eye.position = Vector3(0, 2.23, -0.1)
		top_eye.material_override = _mat(color, 0.5, 0.0)
		root.add_child(top_eye)
	elif character_id == 5:
		var antenna := MeshInstance3D.new()
		var antenna_mesh := CylinderMesh.new()
		antenna_mesh.top_radius = 0.05
		antenna_mesh.bottom_radius = 0.08
		antenna_mesh.height = 0.55
		antenna.mesh = antenna_mesh
		antenna.position = Vector3(0, 2.24, -0.18)
		antenna.material_override = _mat(Color("dcbcff"), 0.4, 0.0)
		root.add_child(antenna)
	var eye_count: int = 1 if character_id == 5 else 2
	for eye_index in range(eye_count):
		var side: float = 0.0 if eye_count == 1 else (-1.0 if eye_index == 0 else 1.0)
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.16 if eye_count == 2 else 0.23
		eye_mesh.height = eye_mesh.radius * 2.0
		eye.mesh = eye_mesh
		eye.position = Vector3(side * 0.21, 1.9, 0.25)
		eye.material_override = _mat(Color.WHITE, 0.3, 0.0)
		root.add_child(eye)
		var pupil := MeshInstance3D.new()
		var pupil_mesh := SphereMesh.new()
		pupil_mesh.radius = 0.065 if eye_count == 2 else 0.09
		pupil_mesh.height = pupil_mesh.radius * 2.0
		pupil.mesh = pupil_mesh
		pupil.position = Vector3(side * 0.21, 1.9, 0.39)
		pupil.material_override = _mat(Color("171722"), 0.2, 0.0)
		root.add_child(pupil)

func _make_bomb() -> Node3D:
	var root := Node3D.new()
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	ball.mesh = sphere
	ball.material_override = _mat(Color("171722"), 0.15, 0.15)
	root.add_child(ball)
	var fuse := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.16
	cyl.height = 0.8
	fuse.mesh = cyl
	fuse.position.y = 1.05
	fuse.rotation_degrees.z = 20
	fuse.material_override = _mat(Color("ff6a3d"), 0.4, 0.1)
	root.add_child(fuse)
	return root

func _make_mystery_box() -> Node3D:
	var root := Node3D.new()
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	cube.mesh = box
	cube.material_override = _mat(Color("ffd83d"), 0.25, 0.25)
	root.add_child(cube)
	for axis in [Vector3(1.08, 0, 0), Vector3(-1.08, 0, 0), Vector3(0, 0, 1.08), Vector3(0, 0, -1.08)]:
		var dot := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.5
		dot.mesh = s
		dot.position = axis
		dot.material_override = _mat(Color.WHITE, 0.3, 0.0)
		root.add_child(dot)
	return root

func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m
