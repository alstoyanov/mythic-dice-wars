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


## Adds one cube standing with its footprint centred on `base` (the middle of its bottom diamond) to a
## mesh drawn with atlas(). `values`: [top, left, right] face values shown; `tint` multiplies the picture
## (owner tint, fades). A whole map of stacks is then one draw call.
static func add_cube(mb: MeshBuilder, base: Vector2, w: float, skin: String, values: Array, tint: Color) -> void:
	atlas()
	var h := w * HEIGHT
	var c := base - Vector2(0.0, h)
	var n := c + Vector2(0.0, -w * 0.25)
	var e := c + Vector2(w * 0.5, 0.0)
	var s := c + Vector2(0.0, w * 0.25)
	var wv := c + Vector2(-w * 0.5, 0.0)
	var down := Vector2(0.0, h)
	var row: int = _atlas_rows.get(skin, -1)
	# A dark body behind the pictures fills the rounded corners, so the cube looks solid.
	mb.uv = _white_uv
	mb.polygon(PackedVector2Array([n, e, e + down, s + down, wv + down, wv]), Color(tint.r * 0.22, tint.g * 0.2, tint.b * 0.18, tint.a))
	var quads := [
		PackedVector2Array([n, e, s, wv]),
		PackedVector2Array([wv, s, s + down, wv + down]),
		PackedVector2Array([s, e, e + down, s + down]),
	]
	for i in 3:
		var k: float = SIDE_SHADE[i]
		var col := Color(tint.r * k, tint.g * k, tint.b * k, tint.a)
		if row < 0:  # a skin without its pictures: plain faces
			mb.polygon(quads[i], col)
			continue
		var r := _face_rect(row, clampi(values[i], 1, 6) - 1)
		mb.textured_quad(quads[i], PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)]), col)


## The spot of the atlas that is plain white (for flat shapes in the same mesh as the dice).
static func white_uv() -> Vector2:
	atlas()
	return _white_uv


# --- One picture for every die on the map --------------------------------------------------------

const ATLAS_FACE := 96  ## pixels per face in the atlas (the map draws dice at 10 to 70 px)
const ATLAS_PAD := 8  ## room around each face, so the small mipmaps do not bleed into the next one
static var _atlas: Texture2D
static var _atlas_rows: Dictionary = {}  ## dice skin -> row in the atlas
static var _atlas_size := Vector2.ONE
static var _white_uv := Vector2.ZERO  ## a white spot for the dark body (tinted by the vertex colour)


## Every pantheon's six faces in one texture (a row per skin, with mipmaps), built once.
static func atlas() -> Texture2D:
	if _atlas != null:
		return _atlas
	var skins: Array[String] = []
	for p in GodCatalog.PANTHEONS:
		if not skins.has(p["dice"]):
			skins.append(p["dice"])
	var cell := ATLAS_FACE + 2 * ATLAS_PAD
	var img := Image.create(cell * 7, cell * skins.size(), false, Image.FORMAT_RGBA8)
	for r in skins.size():
		var ok := true
		for v in 6:
			var t := face(skins[r], v + 1)
			if t == null:
				ok = false
				break
			var f := t.get_image()
			if f.is_compressed():
				f.decompress()
			f.convert(Image.FORMAT_RGBA8)
			f.resize(ATLAS_FACE, ATLAS_FACE, Image.INTERPOLATE_LANCZOS)
			img.blit_rect(f, Rect2i(0, 0, ATLAS_FACE, ATLAS_FACE), Vector2i(v * cell + ATLAS_PAD, r * cell + ATLAS_PAD))
		if ok:
			_atlas_rows[skins[r]] = r
	# The 7th column of the first row: white, for the dice bodies.
	img.fill_rect(Rect2i(6 * cell, 0, cell, cell), Color.WHITE)
	img.generate_mipmaps()
	_atlas = ImageTexture.create_from_image(img)
	_atlas_size = Vector2(img.get_width(), img.get_height())
	_white_uv = Vector2((6 * cell + cell / 2.0) / _atlas_size.x, (cell / 2.0) / _atlas_size.y)
	return _atlas


## A face's place in the atlas, in UV (0..1) coordinates.
static func _face_rect(row: int, index: int) -> Rect2:
	var cell := ATLAS_FACE + 2 * ATLAS_PAD
	return Rect2(Vector2(index * cell + ATLAS_PAD, row * cell + ATLAS_PAD) / _atlas_size, Vector2(ATLAS_FACE, ATLAS_FACE) / _atlas_size)


## Where the columns of a stack stand, relative to the stack's centre, for a cube width `w`
## (front column first; drawn back to front).
static func column_offsets(w: float) -> Array[Vector2]:
	return [Vector2(w * 0.3, w * 0.16), Vector2(-w * 0.3, -w * 0.16), Vector2(w * 0.32, -w * 0.33)]


## Adds a stack of `count` dice (columns of up to four) centred on `base`. `seed_value` picks which
## faces show, so a stack keeps its look between frames.
static func add_stack(mb: MeshBuilder, base: Vector2, w: float, count: int, skin: String, tint: Color, seed_value: int) -> void:
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
			add_cube(mb, base + col[0] - Vector2(0.0, step_h * k), w, skin, values, tint)
