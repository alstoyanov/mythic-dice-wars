class_name RealmView
extends Control
## The isometric map: the island of territories drawn as raised blocks of land in their owner's
## colour, with each territory's dice standing on it as a little tower of cubes. The cells are
## diamonds (a square grid) or flattened hexagons (a hex grid), see RealmMap.grid; both are drawn the
## same way from the cell's outline (_shape), which edges border which neighbour (_edge_dir) and which
## edges face the camera and show a cliff (_front).
##
## Everything is drawn in code, in flat colours, from the RealmMap (docs/art_prompts/
## lists the art that will replace the flat colours). Shows what it was last told (refresh()), not
## the live MatchState, so the game screen decides when a battle's outcome appears.
##
## Fog of war (MatchState.fog): a territory the viewer cannot see is drawn as grey mist,
## without its owner's colour, dice, pennant or effects (is_seen).
##
## Input: click / tap a territory (territory_clicked); mouse wheel, pinch or trackpad to zoom; drag to
## pan; right click to cancel. When zoomed out (or for a huge stack) a stack shrinks to one die and a
## number; hovering or selecting a territory shows its full tower again.
##
## Drawing is in three layers, so a phone does not redraw the whole island every frame: the land (one
## mesh, built once per war: the territories take their colour from a palette of one pixel each, so a
## conquest changes a pixel, not the mesh; zooming only moves it; the selection, the targets and the
## hover are a small mesh of their own over it), the pieces on it (the arrow, and the pennants, dice and numbers as one mesh drawn from DiceArt.atlas), and
## the effects (flashes, dust, numbers rising; drawn only while one plays). Nothing moves while nothing
## happens, and the map is a handful of draw calls (the Compatibility renderer does not batch polygons:
## drawn one by one, the map was thousands). queue_redraw() on this control rebuilds the land and pieces.

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
const MIST := Color(0.6, 0.63, 0.69)  ## the ground of a territory hidden by the fog of war

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
var viewer: int = -1  ## whose eyes the map shows under fog of war (-1: everything)

var _order: Array[Vector2i] = []  ## cells in drawing order (back to front)
var _shape: PackedVector2Array = PackedVector2Array()  ## a cell's top outline around its centre
## For edge i (corner i to corner i+1): the index in RealmMap.cell_neighbors() of the cell across it.
var _edge_dir: Array[int] = []
## The edges facing the camera, drawn as cliffs: [corner a, corner b, shade 0..1].
var _front: Array = []
var _jitter: Dictionary = {}  ## cell -> brightness variation
var _seen: PackedByteArray = PackedByteArray()  ## per territory: 1 if the viewer sees it (refresh)
var _capitals: Dictionary = {}  ## player -> territory with their pennant (the heart of their largest region)
var _effects: Array[Dictionary] = []  ## {t, sheet, age, life, size, rise}
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
var _land: _Layer
var _pieces: _Layer
var _fx: _Layer
var _fx_shown := false  ## the effects layer has something drawn (it must be cleared once they end)
var _land_mesh: ArrayMesh  ## the island, in world units (MeshBuilder), built once
var _land_dirty := true
var _palette_img: Image  ## one pixel per territory: its ground colour (and a last white one)
var _palette: ImageTexture
var _marks_mesh: ArrayMesh  ## the selection (raised, outlined in gold), the targets and the hover
## Per cell (in _order): the territory, and its edges to other territories as [corner, other territory].
var _cell_edges: Array = []
var _pieces_mesh: ArrayMesh  ## pennants, dice and number discs, on screen (kept while drawn)
var _fx_mesh: ArrayMesh  ## the flashes


## A layer of the map: a control over the whole view that draws with one of the view's functions.
class _Layer extends Control:
	var paint: Callable

	func _init(p: Callable) -> void:
		paint = p
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		paint.call(self)


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_land = _Layer.new(_paint_land)
	_land.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # the palette: one exact colour per territory
	_pieces = _Layer.new(_paint_pieces)
	_fx = _Layer.new(_paint_fx)
	for layer in [_land, _pieces, _fx]:
		add_child(layer)


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
	_cell_edges.clear()
	for c in _order:
		var t := realm.territory_at(c)
		var around := realm.cell_neighbors(c)
		var edges: Array = []
		for i in _shape.size():
			var other := realm.territory_at(around[_edge_dir[i]])
			if other != t:
				edges.append([i, other])
		_cell_edges.append([t, edges])
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
	_seen = state.visible_to(viewer)
	_update_palette()
	_capitals.clear()
	for p in state.alive_players():
		var best := -1
		for t in state.largest_region_cells(p):
			if best < 0 or dice[t] > dice[best] or (dice[t] == dice[best] and t < best):
				best = t
		if best >= 0:
			_capitals[p] = best
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
	_land.queue_redraw()  # the same land mesh, moved
	_pieces.queue_redraw()


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


## Does the viewer see territory `t` now (as of the last refresh)? Always true without fog.
func is_seen(t: int) -> bool:
	return t >= 0 and t < _seen.size() and _seen[t] == 1


# --- Effects (none over a territory hidden in the fog) ------------------------------------------

func flash(t: int, color: Color, life: float = 0.6) -> void:
	if not is_seen(t):
		return
	_flashes.append({"t": t, "color": color, "age": 0.0, "life": life})


func float_text(t: int, text: String, color: Color, life: float = 1.2) -> void:
	if not is_seen(t):
		return
	_floaters.append({"t": t, "text": text, "color": color, "age": 0.0, "life": life})


## Plays an effect sheet (Looks.fx: dust, lightning, motes, ward_dome, crumble) over a territory.
## `size`: world units across; `rise`: how far above the dice footing its centre sits (world units).
func play_fx(fx_name: String, t: int, life: float = 0.7, size: float = 48.0, rise: float = 14.0) -> void:
	var sheet := Looks.fx(fx_name)
	if sheet != null and is_seen(t):
		_effects.append({"t": t, "sheet": sheet, "age": 0.0, "life": life, "size": size, "rise": rise,
			"name": fx_name, "seed": randi()})


## Only the effects move: their layer is redrawn while one plays (and once more to clear it).
func _process(delta: float) -> void:
	_time += delta
	for list in [_flashes, _floaters, _effects]:
		for i in range(list.size() - 1, -1, -1):
			list[i]["age"] += delta
			if list[i]["age"] >= list[i]["life"]:
				list.remove_at(i)
	var busy := not (_flashes.is_empty() and _floaters.is_empty() and _effects.is_empty())
	if busy or _fx_shown:
		_fx.queue_redraw()
		_fx_shown = busy


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

## The owner's colour for a territory's ground: the realm's ground colour, tinted (mist if hidden).
func _owner_color(t: int) -> Color:
	if not is_seen(t):
		return (terrain["top"] as Color).lerp(MIST, 0.7)
	return (terrain["top"] as Color).lerp(Looks.player_color(state.players[owners[t]].color_index), 0.6)


## What is laid over a territory's ground: selection, attack targets, hover (alpha 0 = none). Flashes
## are drawn on the effects layer.
func _overlay(t: int) -> Color:
	if t == selected:
		return Color(1, 1, 1, 0.3)
	if targets.has(t):
		return Color(target_color, 0.32)
	if t == hover and interactive:
		return Color(1, 1, 1, 0.14)
	return Color(1, 1, 1, 0)


## Asked to redraw (by refresh, the game screen, a selection): the marks and the pieces are rebuilt (and
## the land, after a refresh).
func _draw() -> void:
	if realm == null:
		return
	_land.queue_redraw()
	_pieces.queue_redraw()


## The island: its shadow, every cell's cliffs and top in its owner's colour, the edges (one mesh,
## rebuilt after a refresh); over it the marks (rebuilt every time: a few cells).
func _paint_land(ci: CanvasItem) -> void:
	if realm == null:
		return
	if _land_dirty or _land_mesh == null:
		_land_mesh = _build_land()
		_land_dirty = false
	_marks_mesh = _build_marks()
	ci.draw_set_transform_matrix(_xf)
	if _land_mesh != null:
		ci.draw_mesh(_land_mesh, _palette)
	if _marks_mesh != null:
		ci.draw_mesh(_marks_mesh, null)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## The cells' raise (elevation; the selected territory is drawn raised more by the marks).
func _ground_lift(t: int) -> float:
	return realm.territories[t].elevation * LIFT


## The colours of the territories' ground, as the palette the land mesh is drawn with.
func _update_palette() -> void:
	var n := realm.count()
	if _palette_img == null:
		_palette_img = Image.create(n + 1, 1, false, Image.FORMAT_RGBA8)
		_palette_img.set_pixel(n, 0, Color.WHITE)
	for t in n:
		_palette_img.set_pixel(t, 0, _owner_color(t))
	if _palette == null:
		_palette = ImageTexture.create_from_image(_palette_img)
	else:
		_palette.update(_palette_img)
	_land.queue_redraw()


## The palette pixel of territory `t` (realm.count() = white), as a texture coordinate.
func _palette_uv(t: int) -> Vector2:
	return Vector2((t + 0.5) / (realm.count() + 1.0), 0.5)


func _build_land() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.uv = _palette_uv(realm.count())
	var shadow := Color(0, 0, 0, 0.28)
	var shadow_shape := PackedVector2Array()
	for v in _shape:
		shadow_shape.append(v * 1.08 + Vector2(4.0, BASE + 10.0))
	for c in _order:  # the island's shadow on the sea below
		mb.polygon(_offset(shadow_shape, _cell_center(c)), shadow)
	var white := _palette_uv(realm.count())
	for i in _order.size():
		var c := _order[i]
		var t: int = _cell_edges[i][0]
		_add_cell(mb, c, t, _ground_lift(t), Color.WHITE, _palette_uv(t))
		mb.uv = white
		var top_pts := _offset(_shape, _cell_center(c) - Vector2(0.0, _ground_lift(t)))
		# Edges: a dark line between territories, a light rim along the coast.
		for edge in _cell_edges[i][1]:
			var a: Vector2 = top_pts[edge[0]]
			var b: Vector2 = top_pts[(edge[0] + 1) % top_pts.size()]
			if edge[1] < 0:
				mb.line(a, b, Color(1, 1, 1, 0.35), 1.0)
			else:
				mb.line(a, b, Color(0.08, 0.06, 0.05, 0.75), 1.3)
	return mb.build()


## One cell: its cliffs facing the camera and its top. `top_uv`: the top's colour from the palette
## (the land mesh); else `top` is the colour itself.
func _add_cell(mb: MeshBuilder, c: Vector2i, t: int, lift: float, top: Color, top_uv := Vector2(-1.0, -1.0)) -> void:
	var cliff: Color = terrain["cliff"]
	var dark := cliff.darkened(0.45)
	var top_pts := _offset(_shape, _cell_center(c) - Vector2(0.0, lift))
	var depth := Vector2(0.0, lift + BASE)
	for face in _front:
		var a: Vector2 = top_pts[face[0]]
		var b: Vector2 = top_pts[face[1]]
		var k: float = face[2]
		var upper := cliff.darkened(1.0 - k)
		var lower := dark.darkened((1.0 - k) * 0.6)
		mb.quad(a, b, b + depth, a + depth, upper, upper, lower, lower)
	var j: float = _jitter[c]
	if top_uv.x >= 0.0:
		mb.uv = top_uv
		var k := 1.0 + j * 1.6  # the cell's brightness, multiplied with its territory's colour
		mb.polygon(top_pts, Color(k, k, k, 1.0))
	else:
		mb.polygon(top_pts, Color(top.r + j, top.g + j, top.b + j, 1.0))


## Over the land: the targets and the hovered territory tinted, and the selected territory raised, lit
## and outlined in gold.
func _build_marks() -> ArrayMesh:
	var marked := {}
	for t in targets:
		marked[t] = true
	if hover >= 0 and interactive:
		marked[hover] = true
	if selected >= 0:
		marked[selected] = true
	if marked.is_empty():
		return null
	var mb := MeshBuilder.new()
	for i in _order.size():
		var t: int = _cell_edges[i][0]
		if not marked.has(t):
			continue
		var c := _order[i]
		var over := _overlay(t)
		var lift := _lift(t)
		if t == selected:
			_add_cell(mb, c, t, lift, _owner_color(t))
		var top_pts := _offset(_shape, _cell_center(c) - Vector2(0.0, lift))
		if over.a > 0.0:
			mb.polygon(top_pts, over)
		if t == selected:
			for edge in _cell_edges[i][1]:
				mb.line(top_pts[edge[0]], top_pts[(edge[0] + 1) % top_pts.size()], Color(1.0, 0.86, 0.4), 2.2)
	return mb.build()


static func _offset(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(points.size())
	for i in points.size():
		out[i] = points[i] + by
	return out


## On the land: the attack arrow, the pennants, the dice and their numbers, the wards.
func _paint_pieces(ci: CanvasItem) -> void:
	if realm == null:
		return
	ci.draw_set_transform_matrix(_xf)
	_draw_arrow(ci)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_stacks(ci)


func _draw_arrow(ci: CanvasItem) -> void:
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
	ci.draw_polyline(pts, Color(0, 0, 0, 0.5), 4.0, true)
	ci.draw_polyline(pts, col, 2.2, true)
	var dir := (pts[16] - pts[14]).normalized()
	var side := Vector2(-dir.y, dir.x)
	ci.draw_colored_polygon(PackedVector2Array([b, b - dir * 7.0 + side * 4.0, b - dir * 7.0 - side * 4.0]), col)


## The pennants, the dice and the discs of their numbers, drawn on screen (so the numbers stay sharp at
## any zoom) as one mesh from DiceArt.atlas (one draw call), back to front; then the numbers' text.
func _draw_stacks(ci: CanvasItem) -> void:
	var scale := _xf.get_scale().x
	var w := DIE * scale
	var compact := w < COMPACT_BELOW
	var screen := {}
	for t in realm.count():
		screen[t] = territory_screen_pos(t)
	var order: Array = range(realm.count())
	order.sort_custom(func(a: int, b: int) -> bool: return screen[a].y < screen[b].y)
	var mb := MeshBuilder.new()
	mb.uv = DiceArt.white_uv()
	for p in _capitals:
		var t: int = _capitals[p]
		if is_seen(t):
			_add_pennant(mb, screen[t] + Vector2(-w * 0.95, w * 0.1), scale, Looks.player_color(state.players[p].color_index))
	var counts: Array = []
	for t: int in order:
		if not is_seen(t):
			continue
		var player := state.players[owners[t]]
		var skin: String = GodCatalog.pantheon(player.pantheon)["dice"]
		var full := not compact or t == hover or t == selected or t == arrow.x or t == arrow.y
		var shown := dice[t] if full else 1
		var tint := Color.WHITE.lerp(Looks.player_color(player.color_index), 0.18)
		var cube_w := w if full else maxf(w, 9.0)
		DiceArt.add_stack(mb, screen[t], cube_w, shown, skin, tint, t * 97)
		if GameSettings.show_counts or not full or dice[t] > 4:
			counts.append([t, cube_w])
	mb.uv = DiceArt.white_uv()
	for c in counts:
		var t: int = c[0]
		var at_r := _count_at(screen[t], c[1])
		mb.circle(at_r[0], at_r[1] + 1.5, Color(0, 0, 0, 0.6))
		mb.circle(at_r[0], at_r[1], Looks.player_color(state.players[owners[t]].color_index).darkened(0.25))
	_pieces_mesh = mb.build()
	if _pieces_mesh != null:
		ci.draw_mesh(_pieces_mesh, DiceArt.atlas())
	var font := UiTheme.bold_font()
	for c in counts:
		_draw_count_text(ci, c[0], screen[c[0]], c[1], font)
	_draw_wards(ci, scale)


## A small pennant in the player's colour on the heart of their largest region.
func _add_pennant(mb: MeshBuilder, foot: Vector2, scale: float, color: Color) -> void:
	var pole := 30.0 * scale
	var top := foot - Vector2(0.0, pole)
	mb.line(foot, top, Color(0.18, 0.12, 0.08), maxf(1.5, 1.6 * scale))
	mb.circle(top, maxf(1.5, 1.4 * scale), Color(0.9, 0.75, 0.35), 8)
	var length := 16.0 * scale
	var height := 8.0 * scale
	var shape := PackedVector2Array([top + Vector2(0.0, 1.0 * scale), top + Vector2(length * 0.5, 2.2 * scale),
		top + Vector2(length, 1.6 * scale), top + Vector2(length, 1.0 * scale + height * 0.15 + 1.6 * scale),
		top + Vector2(length * 0.5, 1.0 * scale + height * 0.58 + 1.2 * scale), top + Vector2(0.0, 1.0 * scale + height)])
	mb.polygon(shape, color)
	mb.polyline(shape + PackedVector2Array([shape[0]]), color.darkened(0.45), maxf(1.0, 0.8 * scale))


## A dome of light over each warded territory (the last frame of the ward effect), or a ring.
func _draw_wards(ci: CanvasItem, scale: float) -> void:
	var sheet := Looks.fx("ward_dome")
	for t in state.wards:
		if state.wards[t]["player"] != owners[t] or not is_seen(t):
			continue
		if sheet == null:
			continue
		var n := Looks.fx_frames(sheet)
		var side := 46.0 * scale
		var c := territory_screen_pos(t) - Vector2(0.0, 12.0 * scale)
		var region := Rect2((n - 1) * sheet.get_height(), 0, sheet.get_height(), sheet.get_height())
		var rect := Rect2(c - Vector2(side, side) / 2.0, Vector2(side, side))
		ci.draw_texture_rect_region(sheet, rect, region, Color(1.3, 1.5, 1.8, 0.85))
		# a glowing rim where the dome meets the ground
		var foot := territory_screen_pos(t) + Vector2(0.0, 2.0 * scale)
		ci.draw_set_transform(foot, 0.0, Vector2(1.0, 0.42))
		ci.draw_arc(Vector2.ZERO, side * 0.42, 0.0, TAU, 36, Color(0.7, 0.9, 1.0, 0.4), 5.0 * scale, true)
		ci.draw_arc(Vector2.ZERO, side * 0.42, 0.0, TAU, 36, Color(0.9, 0.97, 1.0, 0.8), 1.6 * scale, true)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _count_at(base: Vector2, w: float) -> Array:
	var r := clampf(w * 0.5, 7.0, 13.0)
	return [base + Vector2(w * 0.75 + r * 0.4, -r * 0.2), r]


func _draw_count_text(ci: CanvasItem, t: int, base: Vector2, w: float, font: Font) -> void:
	var at_r := _count_at(base, w)
	var at: Vector2 = at_r[0]
	var r: float = at_r[1]
	if state.wards.has(t) and state.wards[t]["player"] == owners[t] and Looks.fx("ward_dome") == null:
		ci.draw_arc(at, r + 4.0, 0.0, TAU, 24, Color(0.75, 0.9, 1.0, 0.9), 2.0, true)
	var text := str(dice[t])
	var fs := int(r * 1.35)
	var size_t := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	ci.draw_string(font, at + Vector2(-size_t.x / 2.0, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## The effects: flashes over territories, effect sheets (dust, lightning, motes…) and rising numbers.
func _paint_fx(ci: CanvasItem) -> void:
	if realm == null:
		return
	if not _flashes.is_empty():
		var mb := MeshBuilder.new()
		for f in _flashes:
			var t: int = f["t"]
			var k: float = 1.0 - f["age"] / f["life"]
			var col := Color(f["color"], k * 0.75)
			var lift := _lift(t)
			for c in realm.territories[t].cells:
				mb.polygon(_offset(_shape, _cell_center(c) - Vector2(0.0, lift)), col)
		_fx_mesh = mb.build()
		ci.draw_set_transform_matrix(_xf)
		ci.draw_mesh(_fx_mesh, null)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_effects(ci, _xf.get_scale().x)
	_draw_floaters(ci)


func _draw_effects(ci: CanvasItem, scale: float) -> void:
	for e in _effects:
		var sheet: Texture2D = e["sheet"]
		var n := Looks.fx_frames(sheet)
		var frame := mini(n - 1, int(e["age"] / e["life"] * n))
		var side: float = e["size"] * scale
		var c := territory_screen_pos(e["t"]) - Vector2(0.0, e["rise"] * scale)
		var tint := Color.WHITE
		match e["name"]:
			"dust":
				tint = Color(1.9, 1.7, 1.4)  # the painted dust is dark: lift it to a sandy cloud
			"lightning":
				_draw_bolt(ci, territory_screen_pos(e["t"]), side, e["age"] / e["life"], e["seed"], scale)
				tint = Color(1.6, 1.7, 2.0)
		ci.draw_texture_rect_region(sheet, Rect2(c - Vector2(side, side) / 2.0, Vector2(side, side)),
			Rect2(frame * sheet.get_height(), 0, sheet.get_height(), sheet.get_height()), tint)


## A jagged bolt from the sky onto `foot`, bright at first, flickering out (with the lightning sheet).
func _draw_bolt(ci: CanvasItem, foot: Vector2, length: float, k: float, seed_value: int, scale: float) -> void:
	if k > 0.6 or (k > 0.25 and int(k * 40.0) % 3 == 0):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts := PackedVector2Array()
	var top := foot - Vector2(rng.randf_range(-0.2, 0.2) * length, length * 1.3)
	for i in 9:
		var f := i / 8.0
		var p := top.lerp(foot, f)
		if i > 0 and i < 8:
			p.x += rng.randf_range(-0.12, 0.12) * length
		pts.append(p)
	var fade := 1.0 - k / 0.6
	ci.draw_polyline(pts, Color(0.55, 0.75, 1.0, 0.35 * fade), 9.0 * scale, true)
	ci.draw_polyline(pts, Color(0.8, 0.9, 1.0, 0.8 * fade), 3.5 * scale, true)
	ci.draw_polyline(pts, Color(1, 1, 1, fade), 1.5 * scale, true)
	ci.draw_circle(foot, length * 0.18 * fade, Color(0.85, 0.92, 1.0, 0.35 * fade))


func _draw_floaters(ci: CanvasItem) -> void:
	var font := UiTheme.bold_font()
	for f in _floaters:
		var k: float = f["age"] / f["life"]
		var pos := territory_screen_pos(f["t"]) + Vector2(0.0, -30.0 - 40.0 * k)
		var col: Color = f["color"]
		col.a = 1.0 - k * k
		var fs := 22
		var text: String = f["text"]
		var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		ci.draw_string_outline(font, pos - Vector2(sz.x / 2.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, col.a * 0.8))
		ci.draw_string(font, pos - Vector2(sz.x / 2.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
