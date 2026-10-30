class_name DiceArt
extends RefCounted
## Draws dice as small isometric cubes from the flat face pictures (assets/dice/<skin>/face_N.png):
## each visible side of the cube is a face picture mapped onto a parallelogram, shaded by which way it
## faces. No 3D, no prepared sprites: any new dice skin works as soon as its six faces exist.

const SIDE_SHADE := [1.0, 0.8, 0.62]  ## top, left, right
const HEIGHT := 0.62  ## the cube's vertical edge, as a fraction of its width

static var _faces: Dictionary = {}  ## skin -> Array[Texture2D] (index 0 = value 1)


static func faces(skin: String) -> Array:
	if not _faces.has(skin):
		var list: Array = []
		for v in range(1, 7):
			var path := GodCatalog.dice_face_path(skin, v)
			list.append(load(path) if ResourceLoader.exists(path) else null)
		_faces[skin] = list
	return _faces[skin]


static func face(skin: String, value: int) -> Texture2D:
	return faces(skin)[clampi(value, 1, 6) - 1]


## The vertical step between stacked cubes of width `w`.
static func step(w: float) -> float:
	return w * HEIGHT


## Draws one cube standing with its footprint centred on `base` (the middle of its bottom diamond).
## `values`: [top, left, right] face values shown; `tint` multiplies the picture (owner tint, fades).
static func draw_cube(ci: CanvasItem, base: Vector2, w: float, skin: String, values: Array, tint: Color) -> void:
	var h := w * HEIGHT
	var c := base - Vector2(0.0, h)
	var n := c + Vector2(0.0, -w * 0.25)
	var e := c + Vector2(w * 0.5, 0.0)
	var s := c + Vector2(0.0, w * 0.25)
	var wv := c + Vector2(-w * 0.5, 0.0)
	var down := Vector2(0.0, h)
	# A dark body behind the pictures fills the rounded corners, so the cube looks solid.
	var body := Color(tint.r * 0.22, tint.g * 0.2, tint.b * 0.18, tint.a)
	ci.draw_colored_polygon(PackedVector2Array([n, e, e + down, s + down, wv + down, wv]), body)
	var uv := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var quads := [
		PackedVector2Array([n, e, s, wv]),
		PackedVector2Array([wv, s, s + down, wv + down]),
		PackedVector2Array([s, e, e + down, s + down]),
	]
	for i in 3:
		var tex := face(skin, values[i])
		var k: float = SIDE_SHADE[i]
		var col := Color(tint.r * k, tint.g * k, tint.b * k, tint.a)
		if tex == null:
			ci.draw_colored_polygon(quads[i], col)
		else:
			ci.draw_polygon(quads[i], PackedColorArray([col, col, col, col]), uv, tex)


## Where the columns of a stack stand, relative to the stack's centre, for a cube width `w`
## (front column first; drawn back to front).
static func column_offsets(w: float) -> Array[Vector2]:
	return [Vector2(w * 0.3, w * 0.16), Vector2(-w * 0.3, -w * 0.16), Vector2(w * 0.32, -w * 0.33)]


## Draws a stack of `count` dice (columns of up to four) centred on `base`. `seed_value` picks which
## faces show, so a stack keeps its look between frames.
static func draw_stack(ci: CanvasItem, base: Vector2, w: float, count: int, skin: String, tint: Color, seed_value: int) -> void:
	if count <= 0:
		return
	var columns: Array = []
	if count <= 4:
		columns = [[Vector2.ZERO, count]]
	else:
		var offs := column_offsets(w)
		var n_cols := ceili(count / 4.0)
		var per := ceili(float(count) / n_cols)
		var left := count
		for i in n_cols:
			var k := mini(per, left)
			columns.append([offs[i], k])
			left -= k
	# back to front: the column with the smallest y first
	columns.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	var step_h := step(w)
	for col in columns:
		for k in col[1]:
			var hash_v := absi(hash(seed_value * 31 + k * 7 + int(col[0].x * 10.0)))
			var values := [1 + hash_v % 6, 1 + (hash_v / 6) % 6, 1 + (hash_v / 36) % 6]
			draw_cube(ci, base + col[0] - Vector2(0.0, step_h * k), w, skin, values, tint)
