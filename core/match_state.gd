class_name MatchState
extends RefCounted
## The rules and the state of one match: who owns which territory, how many dice stand on it, and
## each player's gods, favour and reserve. Pure logic (no nodes, no drawing): the screens call
## attack(), cast_miracle() and end_turn() and animate the dictionaries they return.
## All randomness comes from the RandomNumberGenerator passed in, so a seed replays a match.

const BASE_MAX_DICE := 8
const RESERVE_CAP := 30
const FAVOR_CAP := 12
## Secondary gods wake after this many conquests (when awakening is "milestone").
const AWAKEN_CONQUESTS := 4
const START_DICE_PER_TERRITORY := 3  # on average, including the one every territory starts with

const FLAG_KEYS := ["reroll_ones_attack", "reroll_ones_defense", "attack_wins_ties", "defense_loses_ties",
	"smart_reinforce", "no_reserve", "no_attack_stronger"]


class PlayerState extends RefCounted:
	var index: int
	var name: String
	var pantheon: String
	var primary: String
	var secondary: String
	var secondary_awake: bool = false
	var is_ai: bool = false
	var ai_level: int = 1
	var reserve: int = 0
	var favor: int = 0
	var conquests: int = 0
	var eliminated: bool = false
	var color_index: int = 0
	var effects: Dictionary = {}  ## the merged boons (and banes) of the awake gods, see MatchState.effects_of
	var miracles_used: Array[String] = []  ## gods whose miracle was cast this turn


var map: RealmMap
var owners: PackedInt32Array = PackedInt32Array()
var dice: PackedInt32Array = PackedInt32Array()
var players: Array[PlayerState] = []
var current: int = 0
var turn: int = 1  ## counts every player's turn
var round_number: int = 1
var attacks_this_turn: int = 0
## Attacks made this turn before the current player's secondary god woke: an attack limit (Tyr,
## Anubis, Ereshkigal) counts only the attacks after it, so waking never ends the turn at once.
var attacks_before_awakening: int = 0
var conquests_this_turn: int = 0
## "milestone" (secondary gods wake after AWAKEN_CONQUESTS conquests) or "start".
var awakening: String = "milestone"
## territory -> {"player": p, "bonus": n}: Guanyin's ward, until that player's next turn.
var wards: Dictionary = {}


## `player_defs`: [{name, pantheon, primary, secondary, is_ai, ai_level}], in seat order. The turn
## order is shuffled, the territories dealt evenly and every player gets the same number of dice.
static func create(realm: RealmMap, player_defs: Array, rng: RandomNumberGenerator, awaken: String = "milestone") -> MatchState:
	var s := MatchState.new()
	s.map = realm
	s.awakening = awaken
	var order: Array = range(player_defs.size())
	_shuffle(order, rng)
	for seat in order:
		var d: Dictionary = player_defs[seat]
		var p := PlayerState.new()
		p.index = s.players.size()
		p.name = d.get("name", "Player")
		p.pantheon = d.get("pantheon", "greek")
		p.primary = d.get("primary", "")
		p.secondary = d.get("secondary", "")
		p.is_ai = d.get("is_ai", false)
		p.ai_level = d.get("ai_level", 1)
		p.color_index = seat
		p.secondary_awake = awaken == "start"
		s.players.append(p)
		s._refresh_effects(p)
	var n := realm.count()
	s.owners.resize(n)
	s.dice.resize(n)
	s.dice.fill(1)
	var deal: Array = range(n)
	_shuffle(deal, rng)
	for i in deal.size():
		s.owners[deal[i]] = i % s.players.size()
	var most := int(ceil(float(n) / s.players.size()))
	var total := most * START_DICE_PER_TERRITORY
	for p in s.players:
		var own := s.territories_of(p.index)
		var extra := total - own.size()
		var guard := 0
		while extra > 0 and guard < 10000:
			guard += 1
			var t: int = own[rng.randi_range(0, own.size() - 1)]
			if s.dice[t] < s.max_dice(p.index):
				s.dice[t] += 1
				extra -= 1
	return s


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# --- Effects ----------------------------------------------------------------------------------

## The merged boons (and, once awake, the secondary god's boon and bane) of player `p`.
func effects_of(p: int) -> Dictionary:
	return players[p].effects


func _refresh_effects(p: PlayerState) -> void:
	var parts: Array[Dictionary] = []
	var primary := GodCatalog.god(p.primary)
	if not primary.is_empty():
		parts.append(primary.get("boon", {}))
	if p.secondary_awake:
		var secondary := GodCatalog.god(p.secondary)
		if not secondary.is_empty():
			parts.append(secondary.get("boon", {}))
			parts.append(secondary.get("bane", {}))
	var fx := {}
	for part in parts:
		for key in part:
			if key == "miracle":
				continue
			var v = part[key]
			if v is bool:
				fx[key] = fx.get(key, false) or v
			elif key == "reinforce_mult":
				fx[key] = fx.get(key, 1.0) * v
			elif key == "max_attacks":
				fx[key] = mini(fx.get(key, 999), v)
			else:
				fx[key] = fx.get(key, 0) + v
	p.effects = fx


func _fx(p: int, key: String, default: Variant = 0) -> Variant:
	return players[p].effects.get(key, default)


func max_dice(p: int) -> int:
	return BASE_MAX_DICE + int(_fx(p, "max_dice_bonus"))


## Gods of player `p` whose miracle can be used (awake), as god ids.
func miracle_gods(p: int) -> Array[String]:
	var out: Array[String] = []
	var player := players[p]
	for id in [player.primary, player.secondary]:
		if id == player.secondary and not player.secondary_awake:
			continue
		if GodCatalog.god(id).get("boon", {}).has("miracle"):
			out.append(id)
	return out


func miracle_of(god_id: String) -> Dictionary:
	return GodCatalog.god(god_id).get("boon", {}).get("miracle", {})


# --- Queries ----------------------------------------------------------------------------------

func territories_of(p: int) -> Array[int]:
	var out: Array[int] = []
	for t in owners.size():
		if owners[t] == p:
			out.append(t)
	return out


func total_dice(p: int) -> int:
	var sum := 0
	for t in owners.size():
		if owners[t] == p:
			sum += dice[t]
	return sum


## The size of the player's largest group of connected territories (their reinforcement).
func largest_region(p: int) -> int:
	return largest_region_cells(p).size()


func largest_region_cells(p: int) -> Array[int]:
	var seen := {}
	var best: Array[int] = []
	for start in owners.size():
		if owners[start] != p or seen.has(start):
			continue
		var group: Array[int] = []
		var stack: Array[int] = [start]
		seen[start] = true
		while not stack.is_empty():
			var t: int = stack.pop_back()
			group.append(t)
			for nb in map.neighbors(t):
				if owners[nb] == p and not seen.has(nb):
					seen[nb] = true
					stack.append(nb)
		if group.size() > best.size():
			best = group
	return best


func is_border(t: int) -> bool:
	for nb in map.neighbors(t):
		if owners[nb] != owners[t]:
			return true
	return false


func alive_players() -> Array[int]:
	var out: Array[int] = []
	for p in players:
		if not p.eliminated:
			out.append(p.index)
	return out


## The winner's index once only one player is left, else -1.
func winner() -> int:
	var alive := alive_players()
	return alive[0] if alive.size() == 1 else -1


## Why `from` may not attack `to` ("" = it may).
func attack_block_reason(from: int, to: int) -> String:
	if from < 0 or to < 0 or owners[from] != current:
		return "Choose one of your territories."
	if owners[to] == current:
		return "That territory is already yours."
	if not map.are_adjacent(from, to):
		return "You can only attack a neighbouring territory."
	if dice[from] < 2:
		return "A territory needs at least 2 dice to attack."
	if attacks_left(current) == 0:
		return "%s: no attacks left this turn (at most %d). End your turn." % [
			_limit_name(current), int(_fx(current, "max_attacks", 999))]
	if _fx(current, "no_attack_stronger", false) and dice[to] > dice[from]:
		return "Cold Patience: you may not attack a larger army."
	return ""


## How many more attacks player `p` may make this turn, -1 = no limit.
func attacks_left(p: int) -> int:
	var limit: int = _fx(p, "max_attacks", -1)
	if limit < 0:
		return -1
	var counted := attacks_this_turn - (attacks_before_awakening if p == current else 0)
	return maxi(0, limit - counted)


## The name of the bane that limits player `p`'s attacks (for messages).
func _limit_name(p: int) -> String:
	var g := GodCatalog.god(players[p].secondary)
	return g.get("bane_name", "Your oath") if g.get("bane", {}).has("max_attacks") else "Your oath"


func can_attack(from: int, to: int) -> bool:
	return attack_block_reason(from, to) == ""


func can_attack_from(from: int) -> bool:
	for to in map.neighbors(from):
		if can_attack(from, to):
			return true
	return false


## The awake gods of player `p` that set effect `key`, as [["God · Power", value], ...]; a god's boon
## and bane are listed separately (Ares gives +2 attack with Bloodlust and -1 defence with Reckless).
func sources(p: int, key: String) -> Array:
	var out: Array = []
	var player := players[p]
	for id in [player.primary, player.secondary]:
		if id == player.secondary and not player.secondary_awake:
			continue
		var g := GodCatalog.god(id)
		for part in [["boon", "boon_name"], ["bane", "bane_name"]]:
			var fx: Dictionary = g.get(part[0], {})
			if fx.has(key):
				out.append(["%s · %s" % [g.get("name", ""), g.get(part[1], "")], fx[key]])
	return out


## The names of the gods behind effect `key` for player `p` ("Odin · Wisdom of the Runes, ...").
func source_names(p: int, key: String) -> String:
	return ", ".join(sources(p, key).map(func(x: Array) -> String: return x[0]))


## The bonuses that would apply to an attack, as [[source, value], ...] for each side; each source names
## the god and power ("Ares · Bloodlust") and, where it only sometimes applies, why it applies now.
func attack_modifiers(from: int, to: int) -> Dictionary:
	var a := owners[from]
	var d := owners[to]
	var att: Array = []
	var def: Array = []
	att.append_array(sources(a, "attack_bonus"))
	if attacks_this_turn == 0:
		for x in sources(a, "first_attack_bonus"):
			att.append([x[0] + " (first attack)", x[1]])
	if dice[from] < dice[to]:
		for x in sources(a, "underdog_bonus"):
			att.append([x[0] + " (larger army)", x[1]])
	if dice[from] >= max_dice(a):
		for x in sources(a, "full_stack_bonus"):
			att.append([x[0] + " (full stack)", x[1]])
	def.append_array(sources(d, "defense_bonus"))
	if wards.has(to) and wards[to]["player"] == d:
		def.append([str(wards[to].get("source", "Ward")) + " (ward)", wards[to]["bonus"]])
	return {"attack": att, "defense": def}


# --- Actions ----------------------------------------------------------------------------------

## Rolls `count` dice. Returns [values, rerolled]: rerolled[i] is true where a 1 was rolled again.
func _roll(count: int, min_face: int, reroll_ones: bool, rng: RandomNumberGenerator) -> Array:
	var values: Array[int] = []
	var rerolled: Array[bool] = []
	for i in count:
		var v := rng.randi_range(maxi(1, min_face), 6)
		var again := v == 1 and reroll_ones
		if again:
			v = rng.randi_range(1, 6)
		values.append(v)
		rerolled.append(again)
	return [values, rerolled]


static func _sum(values: Array) -> int:
	var s := 0
	for v in values:
		s += v[1] if v is Array else v
	return s


## Attacks `to` from `from` (must be allowed, see can_attack). Returns what happened:
## {from, to, attacker, defender, won, attack_rolls, defense_rolls (dice values), attack_rerolled,
##  defense_rerolled (true where a god had a 1 rolled again), attack_total, defense_total,
##  modifiers ({attack, defense}: [[source, value]]), notes ({attack, defense}: what the gods did to the
##  dice), tie (how a tie was decided, "" if none), after ([text]: what the gods did after the battle),
##  gains / losses ({territory: dice}), awakened: bool, eliminated: player or -1}
func attack(from: int, to: int, rng: RandomNumberGenerator) -> Dictionary:
	assert(can_attack(from, to))
	var a := owners[from]
	var d := owners[to]
	var mods := attack_modifiers(from, to)
	var att := _roll(dice[from], _fx(a, "min_attack_face", 1), _fx(a, "reroll_ones_attack", false), rng)
	var def := _roll(dice[to], 1, _fx(d, "reroll_ones_defense", false), rng)
	var att_total := _sum(att[0]) + _sum(mods["attack"])
	var def_total := _sum(def[0]) + _sum(mods["defense"])
	var tie_to_attacker: bool = _fx(a, "attack_wins_ties", false) or _fx(d, "defense_loses_ties", false)
	var won := att_total > def_total or (att_total == def_total and tie_to_attacker)
	attacks_this_turn += 1
	var notes := {"attack": [], "defense": []}
	if int(_fx(a, "min_attack_face", 1)) >= 2:
		notes["attack"].append("%s: no 1s" % source_names(a, "min_attack_face"))
	if _fx(a, "reroll_ones_attack", false):
		notes["attack"].append("%s: 1s rolled again" % source_names(a, "reroll_ones_attack"))
	if _fx(d, "reroll_ones_defense", false):
		notes["defense"].append("%s: 1s rolled again" % source_names(d, "reroll_ones_defense"))
	var tie := ""
	if att_total == def_total:
		if tie_to_attacker:
			var why: Array[String] = []
			for x in sources(a, "attack_wins_ties") + sources(d, "defense_loses_ties"):
				why.append(x[0])
			tie = "A tie, won by the attacker: %s" % ", ".join(why)
		else:
			tie = "A tie: the defender holds"
	var result := {
		"from": from, "to": to, "attacker": a, "defender": d, "won": won,
		"attack_rolls": att[0], "defense_rolls": def[0], "attack_rerolled": att[1], "defense_rerolled": def[1],
		"attack_total": att_total, "defense_total": def_total,
		"modifiers": mods, "notes": notes, "tie": tie, "after": [],
		"losses": {}, "gains": {}, "awakened": false, "eliminated": -1,
	}
	if won:
		var moving := dice[from] - 1
		owners[to] = a
		var bonus: int = _fx(a, "conquest_bonus") if conquests_this_turn == 0 else 0
		dice[to] = mini(moving + bonus, max_dice(a))
		if bonus > 0 and dice[to] > moving:
			result["after"].append("%s: +%d die on the conquered land" % [source_names(a, "conquest_bonus"), dice[to] - moving])
		conquests_this_turn += 1
		dice[from] = 1
		result["gains"][to] = dice[to]
		players[a].conquests += 1
		gain_favor(a, 1)
		gain_favor(d, 1)  # faith grows in defeat
		result["awakened"] = _check_awakening(players[a])
		if territories_of(d).is_empty():
			players[d].eliminated = true
			result["eliminated"] = d
	else:
		dice[from] = 1
		gain_favor(a, 1)
		var reward: int = _fx(d, "defend_reward")
		if reward > 0 and dice[to] < max_dice(d):
			var before := dice[to]
			dice[to] = mini(dice[to] + reward, max_dice(d))
			result["gains"][to] = dice[to] - before
			result["after"].append("%s: +%d die for holding" % [source_names(d, "defend_reward"), dice[to] - before])
		var hubris: int = _fx(a, "hubris")
		if hubris > 0:
			var victims: Array[int] = []
			for t in territories_of(a):
				if t != from and dice[t] > 1:
					victims.append(t)
			if not victims.is_empty():
				var t := victims[rng.randi_range(0, victims.size() - 1)]
				var lost := mini(hubris, dice[t] - 1)
				dice[t] -= lost
				result["losses"][t] = lost
				result["after"].append("%s: another territory loses %d" % [source_names(a, "hubris"), lost])
	return result


func gain_favor(p: int, amount: int) -> void:
	players[p].favor = mini(FAVOR_CAP, players[p].favor + amount + int(_fx(p, "favor_bonus")))


func _check_awakening(p: PlayerState) -> bool:
	if p.secondary_awake or p.secondary == "" or p.conquests < AWAKEN_CONQUESTS:
		return false
	p.secondary_awake = true
	_refresh_effects(p)
	if p.index == current:
		attacks_before_awakening = attacks_this_turn
	# A god who lowers the most dice a territory holds (Hermes): the extra dice go to the reserve.
	var cap := max_dice(p.index)
	for t in owners.size():
		if owners[t] == p.index and dice[t] > cap:
			p.reserve = mini(RESERVE_CAP, p.reserve + dice[t] - cap)
			dice[t] = cap
	return true


## Why the current player may not cast `god_id`'s miracle on `target` ("" = may; target -1 checks
## only favour and once-per-turn).
func miracle_block_reason(god_id: String, target: int = -1) -> String:
	var p := players[current]
	if not miracle_gods(current).has(god_id):
		return "That god grants no miracle."
	var m := miracle_of(god_id)
	if p.miracles_used.has(god_id):
		return "Already used this turn."
	if p.favor < int(m["cost"]):
		return "Needs %d favour." % m["cost"]
	if target < 0:
		return ""
	match m["kind"]:
		"smite":
			if owners[target] == current:
				return "Choose an enemy territory."
			if dice[target] <= 1:
				return "That territory has only 1 die."
		"bless":
			if owners[target] != current:
				return "Choose one of your territories."
			if dice[target] >= max_dice(current):
				return "That territory is full."
		"ward":
			if owners[target] != current:
				return "Choose one of your territories."
	return ""


## Casts a miracle. Returns {god, kind, target, change} (change: dice added, negative for removed).
func cast_miracle(god_id: String, target: int) -> Dictionary:
	assert(miracle_block_reason(god_id, target) == "")
	var p := players[current]
	var m := miracle_of(god_id)
	p.favor -= int(m["cost"])
	p.miracles_used.append(god_id)
	var change := 0
	match m["kind"]:
		"smite":
			var before := dice[target]
			dice[target] = maxi(1, dice[target] - int(m["amount"]))
			change = dice[target] - before
		"bless":
			var before := dice[target]
			dice[target] = mini(max_dice(current), dice[target] + int(m["amount"]))
			change = dice[target] - before
		"ward":
			var g := GodCatalog.god(god_id)
			wards[target] = {"player": current, "bonus": int(m["amount"]),
				"source": "%s · %s" % [g.get("name", ""), g.get("boon_name", "")]}
	return {"god": god_id, "kind": m["kind"], "target": target, "change": change}


## How many dice the current player would get for ending the turn now (before the reserve).
func reinforcement_preview(p: int) -> int:
	var base := largest_region(p) + int(_fx(p, "reinforce_bonus"))
	return maxi(0, int(floor(base * float(_fx(p, "reinforce_mult", 1.0)))))


## Ends the current player's turn: tribute, reinforcements (the largest region, plus the reserve),
## then the next player's turn starts. Returns
## {player, tribute: {t: lost}, placed: {t: added}, reserve, lost, next}.
func end_turn(rng: RandomNumberGenerator) -> Dictionary:
	var p := current
	var player := players[p]
	var out := {"player": p, "tribute": {}, "placed": {}, "reserve": 0, "lost": 0, "next": p}
	var tribute: int = _fx(p, "tribute")
	if tribute > 0:
		var biggest := -1
		for t in territories_of(p):
			if biggest < 0 or dice[t] > dice[biggest]:
				biggest = t
		if biggest >= 0 and dice[biggest] > 1:
			var lost := mini(tribute, dice[biggest] - 1)
			dice[biggest] -= lost
			out["tribute"][biggest] = lost
	var pool := reinforcement_preview(p) + player.reserve
	player.reserve = 0
	var own := territories_of(p)
	var cap := max_dice(p)
	var first: Array[int] = []
	if _fx(p, "smart_reinforce", false):
		for t in own:
			if is_border(t):
				first.append(t)
	while pool > 0:
		var open: Array[int] = []
		for t in first:
			if dice[t] < cap:
				open.append(t)
		if open.is_empty():
			for t in own:
				if dice[t] < cap:
					open.append(t)
		if open.is_empty():
			break
		var t := open[rng.randi_range(0, open.size() - 1)]
		dice[t] += 1
		out["placed"][t] = out["placed"].get(t, 0) + 1
		pool -= 1
	if _fx(p, "no_reserve", false):
		out["lost"] = pool
	else:
		player.reserve = mini(RESERVE_CAP, pool)
		out["lost"] = pool - player.reserve
	out["reserve"] = player.reserve
	_advance()
	out["next"] = current
	return out


func _advance() -> void:
	if winner() >= 0:
		return
	var n := players.size()
	var next := current
	for i in n:
		next = (next + 1) % n
		if not players[next].eliminated:
			break
	if next <= current:
		round_number += 1
	current = next
	turn += 1
	attacks_this_turn = 0
	attacks_before_awakening = 0
	conquests_this_turn = 0
	players[current].miracles_used.clear()
	for t in wards.keys():
		if wards[t]["player"] == current:
			wards.erase(t)
