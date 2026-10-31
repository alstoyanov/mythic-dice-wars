class_name EndOverlay
extends Control
## Drawn on top of a game view when the game ends: confetti and a banner for a win, a red vignette,
## drifting ash and a banner for a loss. Works with every view because it only draws over it.
## The knights' own victory / defeat animations live in the views.

const CONFETTI_COLORS: Array[Color] = [Color("ffd23f"), Color("ff5d73"), Color("46c36b"), Color("4cc9f0"), Color("f6f2e8"), Color("c77dff")]

const TITLE_SIZE := 52
const DETAIL_SIZE := 22

var _mode := ""  # "", "win" or "lose"
var _t: float = 0.0
var _pieces: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _banner: PanelContainer
var _title: Label
var _detail: Label
var _mesh: ArrayMesh  ## the pieces drawn now (kept while drawn)


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()

	_banner = PanelContainer.new()
	_banner.theme_type_variation = "TopBar"
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.position.y = 18.0
	_banner.visible = false
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(col)
	_title = Label.new()
	_title.theme_type_variation = "TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_detail = Label.new()
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_detail)
	add_child(_banner)
	_banner.resized.connect(func() -> void: _banner.pivot_offset = _banner.size / 2.0)
	resized.connect(func() -> void:
		if _mode != "":
			_fit_banner())


## The banner's texts shrink until they fit across the board (a phone, a small window).
func _fit_banner() -> void:
	var room := size.x - 80.0  # the banner's frame and margins, the title's outline, a little air
	Ui.fit_font(_title, TITLE_SIZE, room, 22)
	Ui.fit_font(_detail, DETAIL_SIZE, room, 13)


## Removes any running effect (undo, restart).
func clear() -> void:
	_mode = ""
	_pieces.clear()
	_banner.visible = false
	queue_redraw()


## Hides the banner but lets the effect play on (a card about the result takes its place).
func hide_banner() -> void:
	_banner.visible = false


func play_win(title: String, detail: String) -> void:
	_start("win", title, detail)
	var accent: Color = UiTheme.current_palette()["accent"]
	_title.modulate = accent
	# A burst from both lower corners, then a gentle rain from the top.
	for i in 90:
		var from_left := i % 2 == 0
		var origin := Vector2(0.0 if from_left else size.x, size.y)
		var dir := Vector2(_rng.randf_range(0.25, 0.9) * (1.0 if from_left else -1.0), _rng.randf_range(-1.0, -0.35)).normalized()
		_spawn(origin, dir * _rng.randf_range(450.0, 1100.0), 0.0)
	for i in 70:
		_spawn(Vector2(_rng.randf() * size.x, -20.0), Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(60.0, 160.0)), _rng.randf_range(0.2, 3.5))


func play_lose(title: String, detail: String) -> void:
	_start("lose", title, detail)
	_title.modulate = Color("ff7b6b")
	for i in 60:
		_spawn(Vector2(_rng.randf() * size.x, -20.0), Vector2(_rng.randf_range(-20.0, 20.0), _rng.randf_range(30.0, 90.0)), _rng.randf_range(0.0, 3.0))


func _start(mode: String, title: String, detail: String) -> void:
	clear()
	_mode = mode
	_t = 0.0
	_title.text = title
	_detail.text = detail
	_detail.visible = detail != ""
	_fit_banner()
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(0.5, 0.5)
	var tw := _banner.create_tween().set_parallel(true)
	tw.tween_property(_banner, "modulate:a", 1.0, 0.35).set_delay(0.5)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.5).set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner.rotation = 0.0
	if mode == "lose":  # a short wobble as it lands
		var wobble := _banner.create_tween()
		wobble.tween_interval(0.95)
		wobble.tween_property(_banner, "rotation", 0.04, 0.06)
		wobble.tween_property(_banner, "rotation", -0.04, 0.08)
		wobble.tween_property(_banner, "rotation", 0.0, 0.06)


func _spawn(pos: Vector2, vel: Vector2, delay: float) -> void:
	var win := _mode == "win"
	_pieces.append({
		"pos": pos, "vel": vel, "delay": delay + (0.45 if win else 0.5),
		"rot": _rng.randf() * TAU, "spin": _rng.randf_range(-8.0, 8.0),
		"w": _rng.randf_range(7.0, 14.0) if win else _rng.randf_range(6.0, 16.0),
		"h": _rng.randf_range(4.0, 8.0) if win else _rng.randf_range(6.0, 16.0),
		"col": CONFETTI_COLORS[_rng.randi_range(0, CONFETTI_COLORS.size() - 1)] if win else Color(0.55, 0.55, 0.6),
		"life": 0.0,
	})


func _process(delta: float) -> void:
	if _mode == "":
		return
	_t += delta
	var gravity := 900.0 if _mode == "win" else 0.0
	for p in _pieces:
		if p["delay"] > 0.0:
			p["delay"] -= delta
			continue
		p["life"] += delta
		if _mode == "win":
			p["vel"] = p["vel"] + Vector2(0.0, gravity * delta)
			p["vel"].x *= 1.0 - 0.6 * delta  # air drag
			p["vel"].y = minf(p["vel"].y, 380.0)
		p["pos"] += p["vel"] * delta
		p["rot"] += p["spin"] * delta
		if p["pos"].y > size.y + 30.0:  # recycle at the top so the effect keeps going
			p["pos"] = Vector2(_rng.randf() * size.x, -20.0)
			p["vel"] = Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(60.0, 160.0))
	queue_redraw()


func _draw() -> void:
	if _mode == "lose":
		# Red edges that pulse once, then settle.
		var a := (0.5 * sin(minf(_t, 1.2) / 1.2 * PI) + 0.22) * minf(_t * 3.0, 1.0)
		var edge := minf(size.x, size.y) * 0.28
		var red := Color(0.8, 0.1, 0.1, a)
		var clear := Color(0.8, 0.1, 0.1, 0.0)
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, edge), Vector2(0, edge)]),
			PackedColorArray([red, red, clear, clear]))
		draw_polygon(PackedVector2Array([Vector2(0, size.y - edge), Vector2(size.x, size.y - edge), size, Vector2(0, size.y)]),
			PackedColorArray([clear, clear, red, red]))
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(edge, 0), Vector2(edge, size.y), Vector2(0, size.y)]),
			PackedColorArray([red, clear, clear, red]))
		draw_polygon(PackedVector2Array([Vector2(size.x - edge, 0), Vector2(size.x, 0), size, Vector2(size.x - edge, size.y)]),
			PackedColorArray([clear, red, red, clear]))
	# Every piece in one mesh: one draw call (a phone would make one per piece).
	var mb := MeshBuilder.new()
	for p in _pieces:
		if p["delay"] > 0.0:
			continue
		var fade := minf(p["life"] * 4.0, 1.0)
		var col: Color = p["col"]
		col.a = fade * (0.9 if _mode == "win" else 0.45)
		var rot: float = p["rot"]
		var x: Vector2 = Vector2.from_angle(rot) * (p["w"] / 2.0)
		var y: Vector2 = Vector2.from_angle(rot + PI / 2.0) * (p["h"] / 2.0)
		var at: Vector2 = p["pos"]
		mb.quad(at - x - y, at + x - y, at + x + y, at - x + y, col, col, col, col)
	_mesh = mb.build()
	if _mesh != null:
		draw_mesh(_mesh, null)
