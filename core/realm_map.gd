class_name RealmMap
extends RefCounted
## The land of one match: a square grid of cells, grouped into territories. The grid is drawn
## isometrically (see RealmView), but the rules only care about which territories touch.
## Cells that belong to no territory are sky / sea (-1).


class Territory extends RefCounted:
	var id: int
	var cells: Array[Vector2i] = []
	var neighbors: PackedInt32Array = PackedInt32Array()
	## The cell the dice stand on: the one deepest inside the territory.
	var center: Vector2i
	## 0..2: the territory is drawn raised by this many steps (looks only, no rules).
	var elevation: int = 0


var size: int = 0  ## The grid is size x size cells.
var cell_territory: PackedInt32Array = PackedInt32Array()
var territories: Array[Territory] = []

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func count() -> int:
	return territories.size()


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < size and c.y < size


## The territory of a cell, -1 for sky / sea or outside the grid.
func territory_at(c: Vector2i) -> int:
	if not in_bounds(c):
		return -1
	return cell_territory[c.y * size + c.x]


func are_adjacent(a: int, b: int) -> bool:
	return territories[a].neighbors.has(b)


func neighbors(t: int) -> PackedInt32Array:
	return territories[t].neighbors


## Fills in neighbours and centres from the cells (MapGenerator calls it once the cells are dealt).
func finish() -> void:
	for t in territories:
		t.neighbors = PackedInt32Array()
	for t in territories:
		var seen := {}
		for c in t.cells:
			for d in DIRS:
				var other := territory_at(c + d)
				if other >= 0 and other != t.id and not seen.has(other):
					seen[other] = true
					t.neighbors.append(other)
		t.neighbors.sort()
		t.center = _deepest_cell(t)


## The cell farthest (in steps) from the territory's edge; ties go to the one nearest the middle.
func _deepest_cell(t: Territory) -> Vector2i:
	var dist := {}
	var queue: Array[Vector2i] = []
	for c in t.cells:
		for d in DIRS:
			if territory_at(c + d) != t.id:
				dist[c] = 0
				queue.append(c)
				break
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for d in DIRS:
			var n := c + d
			if territory_at(n) == t.id and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var mid := Vector2.ZERO
	for c in t.cells:
		mid += Vector2(c)
	mid /= float(t.cells.size())
	var best := t.cells[0]
	var best_score := -INF
	for c in t.cells:
		var score: float = dist.get(c, 0) * 10.0 - Vector2(c).distance_to(mid)
		if score > best_score:
			best_score = score
			best = c
	return best
