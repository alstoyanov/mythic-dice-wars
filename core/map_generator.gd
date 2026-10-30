class_name MapGenerator
extends RefCounted
## Makes a random realm: a single island of land (its outline seen from the slanted camera is a
## wobbly ellipse of the requested width : height) of square or hex cells, cut into territories of
## about equal size.
## Deterministic for a given seed.

## Cells per territory on average.
const CELLS_PER_TERRITORY := 22

const SIZES := {
	"small": 18,
	"medium": 28,
	"large": 40,
}


## `territory_count`: how many territories; `aspect`: width / height of the island on screen
## (about 1.6 for a wide window, 0.8 for a phone held upright); `grid`: RealmMap.GRID_SQUARE or GRID_HEX.
static func generate(seed_value: int, territory_count: int, aspect: float = 1.6,
		grid: String = RealmMap.GRID_SQUARE) -> RealmMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	aspect = clampf(aspect, 0.6, 2.4)
	var land_target := float(territory_count * CELLS_PER_TERRITORY)
	# In layout units (RealmMap.layout_pos) the island is an ellipse with semi-axes a (across) and b (down).
	var b := sqrt(land_target * RealmMap.cell_area(grid) / (PI * aspect))
	var a := aspect * b
	var n: int
	if grid == RealmMap.GRID_HEX:
		n = int(ceil(maxf(2.0 * a / 1.5, 2.0 * b / (sqrt(3.0) * RealmMap.HEX_SQUASH)) * 1.3)) + 3
	else:
		n = int(ceil(sqrt(a * a + 4.0 * b * b) * 1.3)) + 2
	var phases := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]

	var m := RealmMap.new()
	m.grid = grid
	m.size = n
	m.cell_territory.resize(n * n)
	m.cell_territory.fill(-1)
	var middle := (RealmMap.layout_pos(grid, Vector2i(0, 0)) + RealmMap.layout_pos(grid, Vector2i(n - 1, n - 1))) / 2.0
	var land := {}
	for y in n:
		for x in n:
			var p := RealmMap.layout_pos(grid, Vector2i(x, y)) - middle
			var ang := atan2(p.y / b, p.x / a)
			var r := 1.0 + 0.14 * sin(3.0 * ang + phases[0]) + 0.08 * sin(5.0 * ang + phases[1]) \
				+ 0.05 * sin(9.0 * ang + phases[2]) + rng.randf_range(-0.04, 0.04)
			var d := sqrt((p.x / a) * (p.x / a) + (p.y / b) * (p.y / b))
			if d <= r:
				land[Vector2i(x, y)] = true
	land = _largest_component(m, land)

	var cells: Array[Vector2i] = []
	cells.assign(land.keys())
	cells.sort()  # dictionary order is insertion order, but be explicit: determinism matters
	var seeds := _spread_seeds(m, cells, territory_count, rng)
	for i in seeds.size():
		var t := RealmMap.Territory.new()
		t.id = i
		t.elevation = rng.randi_range(0, 2)
		m.territories.append(t)
	_grow(m, land, seeds, rng)
	m.finish()
	return m


static func _largest_component(m: RealmMap, land: Dictionary) -> Dictionary:
	var best := {}
	var seen := {}
	var keys: Array = land.keys()
	keys.sort()
	for start in keys:
		if seen.has(start):
			continue
		var part := {}
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			part[cell] = true
			for nb in m.cell_neighbors(cell):
				if land.has(nb) and not seen.has(nb):
					seen[nb] = true
					stack.append(nb)
		if part.size() > best.size():
			best = part
	return best


## Seeds far apart from each other (each next one picked among the five cells farthest from the seeds
## so far, so maps differ).
static func _spread_seeds(m: RealmMap, cells: Array[Vector2i], count: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var seeds: Array[Vector2i] = [cells[rng.randi_range(0, cells.size() - 1)]]
	var nearest := PackedFloat32Array()
	nearest.resize(cells.size())
	nearest.fill(INF)
	while seeds.size() < mini(count, cells.size()):
		var last := seeds[seeds.size() - 1]
		var ranked: Array = []
		for i in cells.size():
			nearest[i] = minf(nearest[i], RealmMap.layout_pos(m.grid, cells[i]).distance_squared_to(RealmMap.layout_pos(m.grid, last)))
			ranked.append([nearest[i], i])
		ranked.sort_custom(func(p: Array, q: Array) -> bool: return p[0] > q[0])
		var pick: int = ranked[rng.randi_range(0, mini(4, ranked.size() - 1))][1]
		seeds.append(cells[pick])
	return seeds


## Territories grow from their seeds one cell at a time; the smallest usually grows next, so they end
## up about the same size, but now and then a random one does, so the shapes are irregular.
static func _grow(m: RealmMap, land: Dictionary, seeds: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	var frontier: Array = []
	for i in seeds.size():
		m.cell_territory[seeds[i].y * m.size + seeds[i].x] = i
		m.territories[i].cells.append(seeds[i])
		frontier.append(_open_neighbors(m, land, seeds[i]))
	var growing: Array[int] = []
	for i in seeds.size():
		growing.append(i)
	while not growing.is_empty():
		var pick: int
		if rng.randf() < 0.7:
			pick = growing[0]
			for i in growing:
				if m.territories[i].cells.size() < m.territories[pick].cells.size():
					pick = i
		else:
			pick = growing[rng.randi_range(0, growing.size() - 1)]
		var options: Array = frontier[pick]
		var claimed := false
		while not options.is_empty() and not claimed:
			var cell: Vector2i = options.pop_at(rng.randi_range(0, options.size() - 1))
			if m.cell_territory[cell.y * m.size + cell.x] != -1:
				continue
			m.cell_territory[cell.y * m.size + cell.x] = pick
			m.territories[pick].cells.append(cell)
			options.append_array(_open_neighbors(m, land, cell))
			claimed = true
		if not claimed:
			growing.erase(pick)


static func _open_neighbors(m: RealmMap, land: Dictionary, cell: Vector2i) -> Array:
	var out: Array = []
	for nb in m.cell_neighbors(cell):
		if land.has(nb) and m.cell_territory[nb.y * m.size + nb.x] == -1:
			out.append(nb)
	return out
