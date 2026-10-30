extends SceneTree
## Balance data: plays many wars between computer players (all Strategists, the default rules: head
## start, the secondary god waking after a few conquests, no fog, a medium realm) and writes one line
## per war to a CSV file, for tools/balance_report.py, which ranks the pantheons, gods and pairs of gods
## and finds the matchups where a god does better against another than its strength explains.
##   godot --headless --path . -s tests/balance_sim.gd -- --mode=duel|ffa --games=500 --seed=1 --out=<file.csv>
## duel: two players; ffa: four. Each player's pantheon, primary and secondary god are drawn at random
## (every pair of gods equally likely). Several runs with different seeds can be merged (the report
## reads every CSV in a folder).

const MAX_TURNS := 3000
const LEVEL := 2  ## Strategist


func _init() -> void:
	var mode := "duel"
	var games := 200
	var seed_base := 1
	var out := "user://balance.csv"
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--mode="):
			mode = value
		elif arg.begins_with("--games="):
			games = int(value)
		elif arg.begins_with("--seed="):
			seed_base = int(value)
		elif arg.begins_with("--out="):
			out = value
	var players := 2 if mode == "duel" else 4
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		print("cannot write ", out)
		quit(1)
		return
	# p0 moves first, p1 second, ...; winner: the index of the winning player (-1: unfinished)
	file.store_line("mode,seed,grid,turns,winner," + ",".join(range(players).map(
		func(k: int) -> String: return "p%d_pantheon,p%d_primary,p%d_secondary" % [k, k, k])))
	var t0 := Time.get_ticks_msec()
	var unfinished := 0
	for i in games:
		var game_seed := seed_base * 1000003 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = game_seed
		var grid := RealmMap.GRID_HEX if rng.randi() % 2 == 1 else RealmMap.GRID_SQUARE
		var realm := MapGenerator.generate(rng.randi(), MapGenerator.SIZES["medium"], 1.2, grid)
		var defs: Array = []
		for k in players:
			var pan: Dictionary = GodCatalog.PANTHEONS[rng.randi_range(0, GodCatalog.PANTHEONS.size() - 1)]
			var prim := GodCatalog.gods_of(pan["id"], GodCatalog.PRIMARY)
			var sec := GodCatalog.gods_of(pan["id"], GodCatalog.SECONDARY)
			defs.append({"name": "AI %d" % k, "pantheon": pan["id"],
				"primary": prim[rng.randi_range(0, prim.size() - 1)]["id"],
				"secondary": sec[rng.randi_range(0, sec.size() - 1)]["id"], "is_ai": true, "ai_level": LEVEL})
		var state := MatchState.create(realm, defs, rng)  # its players are in turn order
		var turns := _play(state, rng)
		var w := state.winner()
		if w < 0:
			unfinished += 1
		var line := "%s,%d,%s,%d,%d" % [mode, game_seed, grid, turns, w]
		for k in players:
			var p := state.players[k]
			line += ",%s,%s,%s" % [p.pantheon, p.primary, p.secondary]
		file.store_line(line)
		if (i + 1) % 100 == 0:
			file.flush()
			print("%d / %d wars, %d ms" % [i + 1, games, Time.get_ticks_msec() - t0])
	file.close()
	print("done: %d wars (%d unfinished) in %d ms -> %s" % [games, unfinished, Time.get_ticks_msec() - t0, out])
	quit(0)


func _play(state: MatchState, rng: RandomNumberGenerator) -> int:
	var turns := 0
	while state.winner() < 0 and turns < MAX_TURNS:
		var m := AiPlayer.choose_miracle(state, rng)
		if not m.is_empty():
			state.cast_miracle(m["god"], m["target"])
		var guard := 0
		while guard < 200 and state.winner() < 0:
			guard += 1
			var choice := AiPlayer.choose_attack(state, rng)
			if choice.is_empty():
				break
			state.attack(choice[0], choice[1], rng)
		if state.winner() < 0:
			state.end_turn(rng)
			turns += 1
	return turns
