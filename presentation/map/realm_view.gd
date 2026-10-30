class_name RealmView
extends Control
## The isometric map: the island of territories drawn as raised blocks of land in their owner's
## colour, with each territory's dice standing on it as a little tower of cubes. The cells are
## diamonds (a square grid) or flattened hexagons (a hex grid), see RealmMap.grid; both are drawn the
## same way from the cell's outline (_shape), which edges border which neighbour (_edge_dir) and which
## edges face the camera and show a cliff (_front).
##
## Everything is drawn in code from the RealmMap (no tile sprites yet; docs/art_prompts/
## lists the art that will replace the flat colours). Shows what it was last told (refresh()), not
## the live MatchState, so the game screen decides when a battle's outcome appears.
##
## Input: click / tap a territory (territory_clicked); mouse wheel, pinch or trackpad to zoom; drag to
## pan; right click to cancel. When zoomed out (or for a huge stack) a stack shrinks to one die and a
## number; hovering or selecting a territory shows its full tower again.

signal territory_clicked(territory: int)
signal cancelled
signal hovered(territory: int)

const TW2 := 16.0  ## half the width of a square cell's diamond (world units)
const TH2 := 8.0  ## half its height
const HEX_R := 13.0  ## a hex cell's corner radius (about the same area as a diamond)
const LIFT := 5.0  ## height of one elevation step
const BASE := 14.0  ## thickness of the island below the lowest land
const DIE := 16.0  ## width of one die on the map
const COMPACT_BELOW := 12.0  ## on-screen die width below which stacks collapse to a single die
const DRAG_START := 10.0

var state: MatchState
var realm: RealmMap
var terrain: Dictionary = Looks.TERRAIN["greek"]

## What is shown (copied from the state by refresh()).
var owners: PackedInt32Array = PackedInt32Array()
var dice: PackedInt32Array = PackedInt32Array()

var selected: int = -1
var targets: Array[int] = []  ## highlighted (attack or miracle targets)
var target_color: Color = Color(1.0, 0.85, 0.3)
var hover: int = -1
var arrow: Vector2i = Vector2i(-1, -1)  ## an attack being fought: from, to
var interactive: bool = true

var _order: Array[Vector2i] = []  ## cells in drawing order (back to front)
var _shape: PackedVector2Array = PackedVector2Array()  ## a cell's top outline around its centre
## For edge i (corner i to corner i+1): the index in RealmMap.cell_neighbors() of the cell across it.
var _edge_dir: Array[int] = []
## The edges facing the camera, drawn as cliffs: [corner a, corner b, shade 0..1].
var _front: Array = []
var _jitter: Dictionary = {}  ## cell -> brightness variation
var _bounds: Rect2
var _zoom: float = 1.0
var _pan: Vector2 = Vector2.ZERO
var _xf: Transform2D = Transform2D.IDENTITY
var _time: float = 0.0
var _flashes: Array[Dictionary] = []  ## {t, color, age, life}
var _floaters: Array[Dictionary] = []  ## {t, text, color, age, life}
var _press_pos: Vector2
var _pressing: bool = false
var _dragging: bool = false
var _touches: Dictionary = {}  ## touch index -> position
var _pinch_dist: float = 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func setup(match_state: MatchState, realm_terrain: Dictionary) -> void:
	state = match_state
	realm = match_state.map
	terrain = realm_terrain
	_order.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for y in realm.size:
		for x in realm.size:
			var c := Vector2i(x, y)
			if realm.territory_at(c) >= 0:
				_order.append(c)
				_jitter[c] = rng.randf_range(-0.045, 0.045)
	_build_shape()
	_order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var pa := _cell_center(a)
		var pb := _cell_center(b)
		return pa.y < pb.y or (pa.y == pb.y and pa.x < pb.x))
	var half := Vector2.ZERO
	for v in _shape:
		half = Vector2(maxf(half.x, absf(v.x)), maxf(half.y, absf(v.y)))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in _order:
		var p := _cell_center(c)
		lo = Vector2(minf(lo.x, p.x - half.x), minf(lo.y, p.y - half.y - LIFT * 2.0 - DIE * 3.0))
		hi = Vector2(maxf(hi.x, p.x + half.x), maxf(hi.y, p.y + half.y + BASE + 6.0))
	_bounds = Rect2(lo, hi - lo)
	refresh()
	resized.connect(_update_transform)
	_update_transform()


## Shows the state as it is now.
func refresh() -> void:
	owners = state.owners.duplicate()
	dice = state.dice.duplicate()
	queue_redraw()


func reset_view() -> void:
	_zoom = 1.0
	_pan = Vector2.ZERO
	_update_transform()


# --- Geometry -----------------------------------------------------------------------------------

func _cell_center(c: Vector2i) -> Vector2:
	if realm.grid == RealmMap.GRID_HEX:
		return Vector2(c.x * 1.5 * HEX_R, (c.y + 0.5 * (c.x & 1)) * sqrt(3.0) * HEX_R * RealmMap.HEX_SQUASH)
	return Vector2((c.x - c.y) * TW2, (c.x + c.y) * TH2)


func _build_shape() -> void:
	if realm.grid == RealmMap.GRID_HEX:
		# Flat-topped: corner 0 on the right, then clockwise on screen (y points down).
		var h := sqrt(3.0) / 2.0 * HEX_R * RealmMap.HEX_SQUASH
		_shape = PackedVector2Array([Vector2(HEX_R, 0.0), Vector2(HEX_R / 2.0, h), Vector2(-HEX_R / 2.0, h),
			Vector2(-HEX_R, 0.0), Vector2(-HEX_R / 2.0, -h), Vector2(HEX_R / 2.0, -h)])
		# edges: lower right, down, lower left, upper left, up, upper right (see RealmMap.HEX_DIRS_*)
		_edge_dir = [0, 5, 4, 3, 2, 1]
		_front = [[2, 3, 0.88], [1, 2, 0.74], [0, 1, 0.6]]
	else:
		_shape = PackedVector2Array([Vector2(0.0, -TH2), Vector2(TW2, 0.0), Vector2(0.0, TH2), Vector2(-TW2, 0.0)])
		# edges: N-E borders (0,-1), E-S (1,0), S-W (0,1), W-N (-1,0) (see RealmMap.DIRS)
		_edge_dir = [3, 0, 2, 1]
		_front = [[3, 2, 0.88], [2, 1, 0.68]]


func _lift(t: int) -> float:
	var l := realm.territories[t].elevation * LIFT
	if t == selected:
		l += 4.0
	return l


## The middle of a territory's dice tower footing, in world units.
func territory_anchor(t: int) -> Vector2:
	return _cell_center(realm.territories[t].center) - Vector2(0.0, _lift(t))


## The same point on screen (in this control's coordinates).
func territory_screen_pos(t: int) -> Vector2:
	return _xf * territory_anchor(t)


func _update_transform() -> void:
	if realm == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var fit := minf(size.x / _bounds.size.x, size.y / _bounds.size.y) * 0.96
	var s := fit * _zoom
	var origin := size / 2.0 - _bounds.get_center() * s + _pan
	_xf = Transform2D(0.0, Vector2(s, s), 0.0, origin)
	queue_redraw()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _xf.affine_inverse() * screen_pos
	_zoom = clampf(_zoom * factor, 1.0, 4.0)
	_update_transform()
	var after := _xf * before
	_pan += screen_pos - after
	_clamp_pan()
	_update_transform()


func _clamp_pan() -> void:
	var limit := size * 0.5 * _zoom
	_pan = _pan.clamp(-limit, limit)
	if _zoom <= 1.001:
		_pan = Vector2.ZERO


## The territory under a point on screen, -1 for none.
func territory_at_screen(p: Vector2) -> int:
	var w := _xf.affine_inverse() * p
	for i in range(_order.size() - 1, -1, -1):
		var c := _order[i]
		var t := realm.territory_at(c)
		if Geometry2D.is_point_in_polygon(w - (_cell_center(c) - Vector2(0.0, _lift(t))), _shape):
			return t
	return -1


# --- Effects ------------------------------------------------------------------------------------

func flash(t: int, color: Color, life: float = 0.6) -> void:
	_flashes.append({"t": t, "color": color, "age": 0.0, "life": life})


func float_text(t: int, text: String, color: Color, life: float = 1.2) -> void:
	_floaters.append({"t": t, "text": text, "color": color, "age": 0.0, "life": life})


func _process(delta: float) -> void:
	_time += delta
	for list in [_flashes, _floaters]:
		for i in range(list.size() - 1, -1, -1):
			list[i]["age"] += delta
			if list[i]["age"] >= list[i]["life"]:
				list.remove_at(i)
	queue_redraw()


# --- Input --------------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_dist = 0.0
		if _touches.size() >= 2:
			_dragging = true  # a pinch is never a tap
		return
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var pts: Array = _touches.values()
			var dist: float = (pts[0] as Vector2).distance_to(pts[1])
			if _pinch_dist > 0.0 and dist > 0.0:
				_zoom_at(((pts[0] as Vector2) + pts[1]) / 2.0, dist / _pinch_dist)
			_pinch_dist = dist
		return
	if event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
		return
	if event is InputEventPanGesture:
		_pan -= event.delta * 8.0
		_clamp_pan()
		_update_transform()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.12)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.12)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			cancelled.emit()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_dragging = false
				_press_pos = mb.position
			else:
				if _pressing and not _dragging and _touches.size() < 2 and interactive:
					territory_clicked.emit(territory_at_screen(mb.position))
				_pressing = false
				_dragging = false
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _pressing and _touches.size() < 2:
			if not _dragging and mm.position.distance_to(_press_pos) > DRAG_START and _zoom > 1.001:
				_dragging = true
			if _dragging:
				_pan += mm.relative
				_clamp_pan()
				_update_transform()
		var t := territory_at_screen(mm.position)
		if t != hover:
			hover = t
			hovered.emit(t)
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hover != -1:
		hover = -1
		hovered.emit(-1)
		queue_redraw()


# --- Drawing ------------------------------------------------------------------------------------

func _top_color(t: int) -> Color:
	var p := owners[t]
	var base: Color = terrain["top"]
	var col := base.lerp(Looks.player_color(state.players[p].color_index), 0.6)
	if t == selected:
		col = col.lightened(0.28)
	elif targets.has(t):
		col = col.lerp(target_color, 0.25 + 0.15 * sin(_time * 6.0))
	elif t == hover and interactive:
		col = col.lightened(0.12)
	for f in _flashes:
		if f["t"] == t:
			var k: float = 1.0 - f["age"] / f["life"]
			col = col.lerp(f["color"], k * 0.75)
	return col


func _draw() -> void:
	if realm == null:
		return
	draw_set_transform_matrix(_xf)
	var cliff: Color = terrain["cliff"]
	var shadow := Color(0, 0, 0, 0.28)
	var n_corners := _shape.size()
	var shadow_shape := PackedVector2Array()
	for v in _shape:
		shadow_shape.append(v * 1.08 + Vector2(4.0, BASE + 10.0))
	for c in _order:  # the island's shadow on the sea below
		draw_colored_polygon(_offset(shadow_shape, _cell_center(c)), shadow)
	var dark := cliff.darkened(0.45)
	for c in _order:
		var t := realm.territory_at(c)
		var lift := _lift(t)
		var center := _cell_center(c) - Vector2(0.0, lift)
		var top_pts := _offset(_shape, center)
		var depth := Vector2(0.0, lift + BASE)
		for face in _front:
			var a: Vector2 = top_pts[face[0]]
			var b: Vector2 = top_pts[face[1]]
			var k: float = face[2]
			var upper := cliff.darkened(1.0 - k)
			var lower := dark.darkened((1.0 - k) * 0.6)
			draw_polygon(PackedVector2Array([a, b, b + depth, a + depth]),
				PackedColorArray([upper, upper, lower, lower]))
		var top := _top_color(t)
		var j: float = _jitter[c]
		draw_colored_polygon(top_pts, Color(top.r + j, top.g + j, top.b + j, 1.0))
		# Edges: a dark line between territories, a light rim along the coast, gold around the selection.
		var around := realm.cell_neighbors(c)
		for i in n_corners:
			var other := realm.territory_at(around[_edge_dir[i]])
			if other == t:
				continue
			var a: Vector2 = top_pts[i]
			var b: Vector2 = top_pts[(i + 1) % n_corners]
			if t == selected or (other == selected and other >= 0):
				draw_line(a, b, Color(1.0, 0.86, 0.4), 2.2, true)
			elif other < 0:
				draw_line(a, b, Color(1, 1, 1, 0.35), 1.0, true)
			else:
				draw_line(a, b, Color(0.08, 0.06, 0.05, 0.75), 1.3, true)
	_draw_arrow()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_stacks()
	_draw_floaters()


static func _offset(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(points.size())
	for i in points.size():
		out[i] = points[i] + by
	return out


func _draw_arrow() -> void:
	if arrow.x < 0:
		return
	var a := territory_anchor(arrow.x)
	var b := territory_anchor(arrow.y)
	var mid := (a + b) / 2.0 - Vector2(0.0, a.distance_to(b) * 0.35 + 10.0)
	var pts := PackedVector2Array()
	for i in 17:
		var k := i / 16.0
		pts.append(a.lerp(mid, k).lerp(mid.lerp(b, k), k))
	var col := Color(1.0, 0.9, 0.55, 0.95)
	draw_polyline(pts, Color(0, 0, 0, 0.5), 4.0, true)
	draw_polyline(pts, col, 2.2, true)
	var dir := (pts[16] - pts[14]).normalized()
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([b, b - dir * 7.0 + side * 4.0, b - dir * 7.0 - side * 4.0]), col)


## The dice, drawn on screen (so the numbers stay sharp at any zoom), back to front.
func _draw_stacks() -> void:
	var scale := _xf.get_scale().x
	var w := DIE * scale
	var compact := w < COMPACT_BELOW
	var order: Array = range(realm.count())
	order.sort_custom(func(a: int, b: int) -> bool:
		var ca := realm.territories[a].center
		var cb := realm.territories[b].center
		return ca.x + ca.y < cb.x + cb.y)
	var font := UiTheme.bold_font()
	for t: int in order:
		var p := owners[t]
		var player := state.players[p]
		var skin: String = GodCatalog.pantheon(player.pantheon)["dice"]
		var base := territory_screen_pos(t)
		var full := not compact or t == hover or t == selected or t == arrow.x or t == arrow.y
		var shown := dice[t] if full else 1
		var tint := Color.WHITE.lerp(Looks.player_color(player.color_index), 0.18)
		var cube_w := w if full else maxf(w, 9.0)
		DiceArt.draw_stack(self, base, cube_w, shown, skin, tint, t * 97)
		if GameSettings.show_counts or not full or dice[t] > 4:
			_draw_count(t, base, cube_w, font, Looks.player_color(player.color_index))


func _draw_count(t: int, base: Vector2, w: float, font: Font, color: Color) -> void:
	var r := clampf(w * 0.5, 7.0, 13.0)
	var at := base + Vector2(w * 0.75 + r * 0.4, -r * 0.2)
	if state.wards.has(t) and state.wards[t]["player"] == owners[t]:
		draw_arc(at, r + 4.0, 0.0, TAU, 24, Color(0.75, 0.9, 1.0, 0.9), 2.0, true)
	draw_circle(at, r + 1.5, Color(0, 0, 0, 0.6))
	draw_circle(at, r, color.darkened(0.25))
	var text := str(dice[t])
	var fs := int(r * 1.35)
	var size_t := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(font, at + Vector2(-size_t.x / 2.0, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


func _draw_floaters() -> void:
	var font := UiTheme.bold_font()
	for f in _floaters:
		var k: float = f["age"] / f["life"]
		var pos := territory_screen_pos(f["t"]) + Vector2(0.0, -30.0 - 40.0 * k)
		var col: Color = f["color"]
		col.a = 1.0 - k * k
		var fs := 22
		var text: String = f["text"]
		var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string_outline(font, pos - Vector2(sz.x / 2.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, col.a * 0.8))
		draw_string(font, pos - Vector2(sz.x / 2.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
