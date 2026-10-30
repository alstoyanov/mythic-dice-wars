class_name MenuBackdrop
extends Control
## Full-screen background for every screen.
##
## A look with an interface theme (Looks "ui") shows its picture, scaled to cover the screen:
## the full picture behind the menus (`animated`), and on the game screens a blurred, darker one, or
## the ground the top-down board lies on. On a screen taller than wide (a phone held upright) the
## theme's portrait picture is used if it has one; turning the phone switches between them. Over the menus drifts the theme's weather: "haze" (warm
## light specks rising), "dust", "snow", "rain", "sand", "petals" (plum blossom) or "leaves" (autumn). A look without a theme gets a dark gradient
## in its palette and, when `animated`, faint dice that slowly tumble down.

const COUNT := 16
const WEATHER_COUNT := {"haze": 45, "dust": 40, "snow": 150, "rain": 170, "sand": 110, "petals": 26, "leaves": 18}

var animated: bool = true
var palette: Dictionary = {}
var ui: Dictionary = {}
var _tiles: Array[Dictionary] = []
var _picture: Texture2D
var _paths: Array[String] = ["", ""]  ## the picture for a wide screen, and for a tall one ("" = none)
var _shown_path := ""
var _tiled := false
var _weather := ""
var _drops: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # pictures are drawn smaller than they are
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # the ground is a repeating tile
	_rng.randomize()
	resized.connect(_pick_picture)
	for i in COUNT:
		_tiles.append({
			"x": _rng.randf(), "y": _rng.randf(),
			"speed": _rng.randf_range(0.015, 0.05),
			"rot": _rng.randf_range(0.0, TAU), "spin": _rng.randf_range(-0.4, 0.4),
			"size": _rng.randf_range(0.04, 0.11),
		})


func set_palette(p: Dictionary) -> void:
	set_look(p, {})


## The look's palette and interface theme (see the class description).
func set_look(p: Dictionary, theme_ui: Dictionary) -> void:
	palette = p
	ui = theme_ui
	_tiled = false
	if animated:
		_paths = [ui.get("background", ""), ui.get("background_portrait", "")]
	else:
		_paths = [ui.get("background_game", ""), ui.get("background_portrait_game", "")]
	_shown_path = "-"
	_pick_picture()
	_weather = ui.get("weather", "none") if animated and _picture != null else ""
	_drops.clear()
	for i in WEATHER_COUNT.get(_weather, 0):
		_drops.append(_new_drop(true))
	queue_redraw()


## The wide or the tall picture, whichever suits the screen's shape now.
func _pick_picture() -> void:
	var tall := size.y > size.x * 1.15 and _paths[1] != ""
	var path: String = _paths[1] if tall else _paths[0]
	if path == _shown_path:
		return
	_shown_path = path
	_picture = load(path) if path != "" and ResourceLoader.exists(path) else null
	queue_redraw()


func _new_drop(anywhere: bool) -> Dictionary:
	var d := {"x": _rng.randf(), "y": _rng.randf() if anywhere else -0.05, "phase": _rng.randf() * TAU,
		"size": _rng.randf_range(0.5, 1.0)}
	match _weather:
		"haze", "dust":
			d["vy"] = -_rng.randf_range(0.006, 0.02) if _weather == "haze" else _rng.randf_range(-0.006, 0.006)
			d["vx"] = _rng.randf_range(-0.006, 0.006)
			if not anywhere:
				d["y"] = 1.05 if _weather == "haze" else _rng.randf()
		"snow":
			d["vy"] = _rng.randf_range(0.03, 0.08)
			d["vx"] = _rng.randf_range(-0.01, 0.01)
		"petals", "leaves":
			d["vy"] = _rng.randf_range(0.025, 0.05) * (0.8 if _weather == "leaves" else 1.0)
			d["vx"] = _rng.randf_range(0.01, 0.03)  # a light breeze
			d["spin"] = _rng.randf_range(-1.5, 1.5)
			d["tint"] = _rng.randf()
		"rain":
			d["vy"] = _rng.randf_range(0.9, 1.3)
			d["vx"] = -0.22 * d["vy"]
		"sand":
			d["vx"] = _rng.randf_range(0.12, 0.3)
			d["vy"] = _rng.randf_range(-0.01, 0.01)
			d["y"] = _rng.randf_range(0.45, 1.0)
			if not anywhere:
				d["x"] = -0.05
	return d


func _process(delta: float) -> void:
	if not animated:
		return
	if _picture == null:
		for t in _tiles:
			t["y"] += t["speed"] * delta
			t["rot"] += t["spin"] * delta
			if t["y"] > 1.15:
				t["y"] = -0.15
	for i in _drops.size():
		var d: Dictionary = _drops[i]
		d["x"] += d["vx"] * delta
		d["y"] += d["vy"] * delta
		d["phase"] += delta
		if d["y"] > 1.05 or d["y"] < -0.08 or d["x"] > 1.08 or d["x"] < -0.08:
			_drops[i] = _new_drop(false)
	queue_redraw()


func _draw() -> void:
	if _picture != null:
		_draw_picture()
		_draw_weather()
		return
	var top: Color = palette["bg_top"]
	var bottom: Color = palette["bg_bottom"]
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	if not animated:
		return
	var accent: Color = palette["accent"]
	for t in _tiles:
		var side: float = t["size"] * minf(size.x, size.y)
		draw_set_transform(Vector2(t["x"] * size.x, t["y"] * size.y), t["rot"], Vector2.ONE)
		draw_rect(Rect2(-side / 2.0, -side / 2.0, side, side), Color(accent, 0.07))
		draw_rect(Rect2(-side / 2.0, -side / 2.0, side, side), Color(accent, 0.16), false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The picture covering the whole screen (cropped at the sides or top and bottom, never stretched),
## or the ground repeated across it; behind the menus, darker towards the bottom so text stays readable.
func _draw_picture() -> void:
	if _tiled:
		draw_texture_rect(_picture, Rect2(Vector2.ZERO, size), true, Color.WHITE)
		return
	var pic := _picture.get_size()
	var s := maxf(size.x / pic.x, size.y / pic.y)
	var drawn := pic * s
	draw_texture_rect(_picture, Rect2((size - drawn) / 2.0, drawn), false)
	if animated:
		var top := Color(0, 0, 0, 0.12)
		var bottom := Color(0, 0, 0, 0.45)
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))


func _draw_weather() -> void:
	var unit := minf(size.x, size.y) / 700.0  # sizes follow the screen
	for d in _drops:
		var p := Vector2(d["x"] * size.x, d["y"] * size.y)
		var k: float = d["size"]
		match _weather:
			"haze", "dust":
				var flicker := 0.55 + 0.45 * sin(d["phase"] * 1.3)
				var warm := Color(1.0, 0.86, 0.6) if _weather == "haze" else Color(0.95, 0.9, 0.8)
				draw_circle(p, (5.0 + 5.0 * k) * unit, Color(warm, 0.05 * flicker))
				draw_circle(p, (1.2 + 1.6 * k) * unit, Color(warm, 0.55 * flicker))
			"snow":
				p.x += sin(d["phase"] * 0.9 + d["x"] * 9.0) * 10.0 * unit
				draw_circle(p, (1.0 + 2.2 * k) * unit, Color(1, 1, 1, 0.45 + 0.4 * k))
			"petals", "leaves":  # swaying as it falls, turning so it flickers between face and edge
				p.x += sin(d["phase"] * 0.7 + d["x"] * 7.0) * 18.0 * unit
				var turn: float = d["phase"] * d["spin"]
				var col := Color(1.0, 0.72, 0.78).lerp(Color(1.0, 0.92, 0.94), d["tint"])
				if _weather == "leaves":
					col = Color(0.85, 0.45, 0.15).lerp(Color(0.95, 0.72, 0.3), d["tint"])
					k *= 1.6
				draw_set_transform(p, turn, Vector2(1.0, 0.35 + 0.65 * absf(sin(d["phase"] * 1.7 + d["tint"] * 6.0))))
				draw_circle(Vector2.ZERO, (3.5 + 3.0 * k) * unit, Color(col, 0.75))
				draw_circle(Vector2((1.5 + 1.2 * k) * unit, 0.0), (2.2 + 2.0 * k) * unit, Color(col, 0.75))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"rain":
				var along := Vector2(d["vx"], d["vy"]).normalized() * (16.0 + 18.0 * k) * unit
				draw_line(p, p + along, Color(0.78, 0.84, 0.95, 0.22 + 0.2 * k), maxf(1.0, unit))
			"sand":
				p.y += sin(d["phase"] * 2.0 + d["x"] * 6.0) * 6.0 * unit
				draw_line(p, p + Vector2((6.0 + 10.0 * k) * unit, 0.0), Color(0.95, 0.82, 0.6, 0.3 + 0.25 * k),
					maxf(1.0, 1.5 * unit))
