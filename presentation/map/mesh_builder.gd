class_name MeshBuilder
extends RefCounted
## Collects many small 2D shapes (polygons, lines, circles) into one mesh, drawn with a single
## CanvasItem.draw_mesh: one draw call instead of one per shape. Phones need this: the Compatibility
## renderer does not batch draw_polygon calls, and the map has thousands of shapes.
## Shapes are drawn in the order they are added. With a texture, `uv` picks the spot of it a flat
## shape uses (a white spot, so the vertex colour shows as it is).

var verts := PackedVector2Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()
var uv := Vector2.ZERO  ## the texture spot for flat shapes


## A convex polygon in one colour (a fan of triangles).
func polygon(points: PackedVector2Array, color: Color) -> void:
	for i in range(1, points.size() - 1):
		_tri(points[0], points[i], points[i + 1], color, color, color)


## A quad a-b-c-d with a colour per corner.
func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	_tri(a, b, c, ca, cb, cc)
	_tri(a, c, d, ca, cc, cd)


## A quad with its own texture coordinates (a die face from the atlas).
func textured_quad(points: PackedVector2Array, quad_uvs: PackedVector2Array, color: Color) -> void:
	for idx in [0, 1, 2, 0, 2, 3]:
		verts.append(points[idx])
		colors.append(color)
		uvs.append(quad_uvs[idx])


## A straight line `width` wide (in the mesh's units).
func line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var d := b - a
	if d.length_squared() < 0.0001:
		return
	var side := Vector2(-d.y, d.x).normalized() * (width / 2.0)
	quad(a + side, b + side, b - side, a - side, color, color, color, color)


func polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in points.size() - 1:
		line(points[i], points[i + 1], color, width)


func circle(center: Vector2, radius: float, color: Color, segments: int = 16) -> void:
	var prev := center + Vector2(radius, 0.0)
	for i in range(1, segments + 1):
		var a := TAU * i / segments
		var p := center + Vector2(cos(a), sin(a)) * radius
		_tri(center, prev, p, color, color, color)
		prev = p


func is_empty() -> bool:
	return verts.is_empty()


## The mesh of everything added (null if nothing was).
func build() -> ArrayMesh:
	if verts.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _tri(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	verts.append(a)
	verts.append(b)
	verts.append(c)
	colors.append(ca)
	colors.append(cb)
	colors.append(cc)
	uvs.append(uv)
	uvs.append(uv)
	uvs.append(uv)
