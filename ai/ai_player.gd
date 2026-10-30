class_name AiPlayer
extends RefCounted
## The computer's choices: which attack to make next (or none, to end the turn) and when to cast a
## miracle. Stateless; works on a MatchState.
##
## Levels: 0 Novice (takes any fair-looking fight, sometimes stops early), 1 Warlord (good odds, joins
## its regions), 2 Strategist (also weighs the counter-attack and guards its largest region).
##
## Fog of war (MatchState.fog): a computer player reads only what it can see, its own territories
## and their neighbours, like the human. Its attacks and miracles only ever involve those; for a
## territory further away (the Strategist's look past a conquest) it assumes the average stack it
## can see (_seen_dice). The territory counts in the player list are public, as for the human.

const LEVEL_NAMES := ["Novice", "Warlord", "Strategist"]
const MIN_CHANCE := [0.5, 0.57, 0.6]


## The best attack as [from, to], or [] to end the turn.
static func choose_attack(state: MatchState, rng: RandomNumberGenerator) -> Array:
	var p := state.current
	var level: int = state.players[p].ai_level
	if level == 0 and state.attacks_this_turn > 0 and rng.randf() < 0.15:
		return []
	var main_region := {}
	for t in state.largest_region_cells(p):
		main_region[t] = true
	var leader := _leader(state, p)
	var guess := _unseen_guess(state, p)
	var best: Array = []
	var best_score := -INF
	for from in state.territories_of(p):
		if state.dice[from] < 2:
			continue
		for to in state.map.neighbors(from):
			if not state.can_attack(from, to):
				continue
			var chance := DiceOdds.attack_chance(state, from, to)
			var score := chance
			# A full stack that cannot grow anyway should be used.
			if state.dice[from] >= state.max_dice(p):
				score += 0.08
			if level >= 1:
				if _joins_region(state, p, to, main_region):
					score += 0.12
				if state.owners[to] == leader:
					score += 0.04
				if state.dice[to] == 1:
					score += 0.03
			if level >= 2:
				score -= _exposure(state, p, from, to, guess) * 0.25
				# Do not strip the main region's only big defender of a border.
				if main_region.has(from) and _threat(state, p, from) > 0 and state.dice[from] < state.max_dice(p):
					score -= 0.05
			if chance < MIN_CHANCE[level] and not (state.dice[from] >= state.max_dice(p) and chance >= 0.45):
				continue
			score += rng.randf() * (0.08 if level == 0 else 0.02)
			if score > best_score:
				best_score = score
				best = [from, to]
	if best.is_empty() and state.attacks_this_turn == 0 and _desperate(state, p):
		return _boldest_attack(state, 0.3 if state.round_number <= 80 else 0.0)
	return best


## Nothing worth attacking, but waiting gains nothing either: the stacks are (nearly) full, or the
## war has dragged on. Then the best fight on offer is taken (after round 80 even a poor one), so
## a war cannot stall.
static func _desperate(state: MatchState, p: int) -> bool:
	var own := state.territories_of(p)
	var room := own.size() * state.max_dice(p)
	return state.round_number > 60 or float(state.total_dice(p)) >= room * 0.85


static func _boldest_attack(state: MatchState, min_chance: float) -> Array:
	var best: Array = []
	var best_chance := min_chance
	for from in state.territories_of(state.current):
		for to in state.map.neighbors(from):
			if state.can_attack(from, to):
				var chance := DiceOdds.attack_chance(state, from, to)
				if chance > best_chance:
					best_chance = chance
					best = [from, to]
	return best


## A miracle worth casting now, as {god, target}, or {}.
static func choose_miracle(state: MatchState, rng: RandomNumberGenerator) -> Dictionary:
	var p := state.current
	for god_id in state.miracle_gods(p):
		if state.miracle_block_reason(god_id) != "":
			continue
		var m := state.miracle_of(god_id)
		var best := -1
		var best_score := -INF
		for t in state.owners.size():
			if state.miracle_block_reason(god_id, t) != "":
				continue
			var score := 0.0
			match m["kind"]:
				"smite":  # the strongest enemy stack touching our land
					var touches := false
					for nb in state.map.neighbors(t):
						if state.owners[nb] == p:
							touches = true
					if not touches:
						continue
					score = state.dice[t]
				"bless", "ward":  # our most threatened border
					var threat := _threat(state, p, t)
					if threat <= 0:
						continue
					score = threat + (0.5 if m["kind"] == "bless" else 0.0) * state.dice[t]
			score += rng.randf() * 0.1
			if score > best_score:
				best_score = score
				best = t
		if best >= 0:
			return {"god": god_id, "target": best}
	return {}


## The player with the most territories (other than `p`).
static func _leader(state: MatchState, p: int) -> int:
	var best := -1
	var most := -1
	for q in state.alive_players():
		if q == p:
			continue
		var n := state.territories_of(q).size()
		if n > most:
			most = n
			best = q
	return best


## Would taking `to` connect a territory of ours that is not in the main region to it?
static func _joins_region(state: MatchState, p: int, to: int, main_region: Dictionary) -> bool:
	var touches_main := false
	var touches_other := false
	for nb in state.map.neighbors(to):
		if state.owners[nb] != p:
			continue
		if main_region.has(nb):
			touches_main = true
		else:
			touches_other = true
	return touches_main and touches_other


## The dice of territory `t` as player `p` knows them: the real count if `p` can see it, else `guess`.
static func _seen_dice(state: MatchState, p: int, t: int, guess: float) -> float:
	return float(state.dice[t]) if state.can_see(p, t) else guess


## Under fog: the average enemy stack that player `p` can see (3 if none), its guess for the rest.
static func _unseen_guess(state: MatchState, p: int) -> float:
	var total := 0
	var n := 0
	for t in state.owners.size():
		if state.owners[t] != p and state.can_see(p, t):
			total += state.dice[t]
			n += 1
	return float(total) / n if n > 0 else 3.0


## How many more dice than ours the strongest enemy next to territory `t` has (0 if none).
static func _threat(state: MatchState, p: int, t: int) -> int:
	var worst := 0
	for nb in state.map.neighbors(t):
		if state.owners[nb] != p:
			worst = maxi(worst, state.dice[nb] - state.dice[t] + 1)
	return worst


## 0..1: how exposed the conquered territory (with dice-1 dice) and the emptied source would be.
## The conquered territory's other neighbours may lie in the fog: `guess` stands in for their dice.
static func _exposure(state: MatchState, p: int, from: int, to: int, guess: float) -> float:
	var moved := state.dice[from] - 1
	var danger := 0
	for nb in state.map.neighbors(to):
		if state.owners[nb] != p and nb != to and _seen_dice(state, p, nb, guess) > moved:
			danger += 1
	for nb in state.map.neighbors(from):
		if state.owners[nb] != p and nb != to and state.dice[nb] >= 3:
			danger += 1
	return clampf(danger / 4.0, 0.0, 1.0)
