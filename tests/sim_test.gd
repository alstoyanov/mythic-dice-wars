extends SceneTree
## Headless check of the rules and the computer players: plays whole matches between computer
## players with random pantheons and gods, and fails if a match breaks a rule or does not finish.
##   godot --headless --path . -s tests/sim_test.gd [-- --matches=40]

const MAX_TURNS := 3000


func _init() -> void:
	var matches := 40
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--matches="):
			matches = int(arg.get_slice("=", 1))
	var failures := 0 if _test_oath_after_awakening() else 1
	var wins := {}
	var god_wins := {}
	var god_games := {}
	var total_turns := 0
	var t0 := Time.get_ticks_msec()
	for i in matches:
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + i
		var sizes := ["small", "medium", "large"]
		var size: String = sizes[i % 3]
		var players := 2 + i % 7
		var grid := RealmMap.GRID_HEX if i % 2 == 1 else RealmMap.GRID_SQUARE
		var realm := MapGenerator.generate(rng.randi(), MapGenerator.SIZES[size], [1.6, 0.8, 1.2][i % 3], grid)
		if not _check_map(realm, MapGenerator.SIZES[size]):
			failures += 1
			continue
		var defs: Array = []
		for k in players:
			var pan: Dictionary = GodCatalog.PANTHEONS[rng.randi_range(0, GodCatalog.PANTHEONS.size() - 1)]
			var prim := GodCatalog.gods_of(pan["id"], GodCatalog.PRIMARY)
			var sec := GodCatalog.gods_of(pan["id"], GodCatalog.SECONDARY)
			defs.append({"name": "AI %d" % k, "pantheon": pan["id"],
				"primary": prim[rng.randi_range(0, prim.size() - 1)]["id"],
				"secondary": sec[rng.randi_range(0, sec.size() - 1)]["id"],
				"is_ai": true, "ai_level": rng.randi_range(0, 2)})
		var state := MatchState.create(realm, defs, rng, "milestone" if i % 2 == 0 else "start")
		for d in defs:
			for g in [d["primary"], d["secondary"]]:
				god_games[g] = god_games.get(g, 0) + 1.0 / players  # a fair share of a win
		var turns := 0
		while state.winner() < 0 and turns < MAX_TURNS:
			var m := AiPlayer.choose_miracle(state, rng)
			if not m.is_empty():
				state.cast_miracle(m["god"], m["target"])
			var guard := 0
			while guard < 200:
				guard += 1
				var choice := AiPlayer.choose_attack(state, rng)
				if choice.is_empty():
					break
				state.attack(choice[0], choice[1], rng)
				if not _check_state(state):
					failures += 1
					break
				if state.winner() >= 0:
					break
			if state.winner() >= 0:
				break
			state.end_turn(rng)
			turns += 1
		total_turns += turns
		var w := state.winner()
		if w < 0:
			print("match %d (%s, %d players) did not finish after %d turns" % [i, size, players, turns])
			failures += 1
			continue
		var pw := state.players[w]
		wins[pw.pantheon] = wins.get(pw.pantheon, 0) + 1
		god_wins[pw.primary] = god_wins.get(pw.primary, 0) + 1
		god_wins[pw.secondary] = god_wins.get(pw.secondary, 0) + 1
	print("%d matches, %d failures, %.1f turns on average, %d ms" % [matches, failures, float(total_turns) / matches, Time.get_ticks_msec() - t0])
	print("wins by pantheon: ", wins)
	print("god: wins / fair share (1.00 = average)")
	var ids: Array = god_games.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return god_wins.get(a, 0) / god_games[a] > god_wins.get(b, 0) / god_games[b])
	for id in ids:
		print("  %-14s %5.2f  (%d wins)" % [id, god_wins.get(id, 0) / god_games[id], god_wins.get(id, 0)])
	quit(1 if failures > 0 else 0)


func _check_map(m: RealmMap, expected: int) -> bool:
	if m.count() != expected:
		print("%s map has %d territories, expected %d" % [m.grid, m.count(), expected])
		return false
	for t in m.territories:
		if t.cells.is_empty() or t.neighbors.is_empty():
			print("territory %d has no cells or no neighbours" % t.id)
			return false
		if m.territory_at(t.center) != t.id:
			print("territory %d: centre outside" % t.id)
			return false
	# every territory reachable from the first
	var seen := {0: true}
	var stack := [0]
	while not stack.is_empty():
		var t: int = stack.pop_back()
		for nb in m.neighbors(t):
			if not seen.has(nb):
				seen[nb] = true
				stack.append(nb)
	if seen.size() != m.count():
		print("map not connected")
		return false
	return true


func _check_state(s: MatchState) -> bool:
	for t in s.owners.size():
		if s.dice[t] < 1 or s.dice[t] > s.max_dice(s.owners[t]):
			print("territory %d has %d dice" % [t, s.dice[t]])
			return false
	return true


## Regression: a secondary god with an attack limit (Tyr: 4 per turn) wakes after a turn of many attacks;
## the player must still be able to attack (the limit counts from the moment the god wakes).
func _test_oath_after_awakening() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var realm := MapGenerator.generate(rng.randi(), 18, 1.6)
	var defs: Array = [
		{"name": "A", "pantheon": "norse", "primary": "odin", "secondary": "tyr"},
		{"name": "B", "pantheon": "greek", "primary": "athena", "secondary": "ares"}]
	var state := MatchState.create(realm, defs, rng)
	var me := state.current
	state.players[me].conquests = MatchState.AWAKEN_CONQUESTS - 1
	state.attacks_this_turn = 6
	for from in state.territories_of(me):
		for to in state.map.neighbors(from):
			if state.owners[to] != me:
				state.dice[from] = 8
				state.dice[to] = 1
				var r := state.attack(from, to, rng)
				if not r["won"] or not r["awakened"]:
					print("oath test: setup attack did not win and wake Tyr")
					return false
				if state.attacks_left(me) != 4:
					print("oath test: %d attacks left after Tyr woke, expected 4" % state.attacks_left(me))
					return false
				print("oath test: ok")
				return true
	print("oath test: no attack found")
	return false
