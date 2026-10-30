class_name RealmMap
extends RefCounted
## The land of one match: a grid of cells, grouped into territories. The rules only care about which
## territories touch. Cells that belong to no territory are sky / sea (-1).
##
## Two kinds of grid (GRID_SQUARE, GRID_HEX), both stored as size x size cells:
##  * square: 4 neighbours, drawn as isometric diamonds;
##  * hex: flat-topped hexagons in columns, every odd column shifted half a cell down ("odd-q"),
##    6 neighbours, drawn from the same slanted camera (squashed by HEX_SQUASH).


class Territory extends RefCounted:
	var id: int
	var cells: Array[Vector2i] = []
	var neighbors: PackedInt32Array = PackedInt32Array()
	## The cell the dice stand on: the one deepest inside the territory.
	var center: Vector2i
	## 0..2: the territory is drawn raised by this many steps (looks only, no rules).
	var elevation: int = 0


const GRID_SQUARE := "square"
const GRID_HEX := "hex"
## How much the hexagons are flattened by the slanted camera (1 = seen from straight above).
const HEX_SQUASH := 0.62

var grid: String = GRID_SQUARE
var size: int = 0  ## The grid is size x size cells.
var cell_territory: PackedInt32Array = PackedInt32Array()
var territories: Array[Territory] = []

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Hex neighbours in the order: lower right, upper right, up, upper left, lower left, down.
const HEX_DIRS_EVEN: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, 1)]
const HEX_DIRS_ODD: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]


## The cells next to `c` (they may be outside the grid): 4 on a square grid (in DIRS order), 6 on a
## hex grid (in HEX_DIRS order).
static func cell_neighbors_of(grid_kind: String, c: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = DIRS
	if grid_kind == GRID_HEX:
		dirs = HEX_DIRS_ODD if c.x & 1 else HEX_DIRS_EVEN
	var out: Array[Vector2i] = []
	for d in dirs:
		out.append(c + d)
	return out


func cell_neighbors(c: Vector2i) -> Array[Vector2i]:
	return cell_neighbors_of(grid, c)


## Where a cell lies on screen, in units where one cell covers cell_area() (the generator's island
## outline; RealmView scales the same layout).
static func layout_pos(grid_kind: String, c: Vector2i) -> Vector2:
	if grid_kind == GRID_HEX:
		return Vector2(c.x * 1.5, (c.y + 0.5 * (c.x & 1)) * sqrt(3.0) * HEX_SQUASH)
	return Vector2(c.x - c.y, (c.x + c.y) / 2.0)


static func cell_area(grid_kind: String) -> float:
	return 1.5 * sqrt(3.0) * HEX_SQUASH if grid_kind == GRID_HEX else 1.0


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
			for n in cell_neighbors(c):
				var other := territory_at(n)
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
		for n in cell_neighbors(c):
			if territory_at(n) != t.id:
				dist[c] = 0
				queue.append(c)
				break
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for n in cell_neighbors(c):
			if territory_at(n) == t.id and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var mid := Vector2.ZERO
	for c in t.cells:
		mid += layout_pos(grid, c)
	mid /= float(t.cells.size())
	var best := t.cells[0]
	var best_score := -INF
	for c in t.cells:
		var score: float = dist.get(c, 0) * 10.0 - layout_pos(grid, c).distance_to(mid)
		if score > best_score:
			best_score = score
			best = c
	return best
