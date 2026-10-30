class_name DiceOdds
extends RefCounted
## Exact chances for battles: the distribution of the sum of n dice, for plain dice, dice whose 1s are
## rolled again, and dice that never show 1. Used by the computer players and the attack preview.

enum Mode { PLAIN, REROLL_ONES, NO_ONES }

static var _dists: Dictionary = {}  ## [mode, n] -> PackedFloat64Array indexed by the sum
static var _chances: Dictionary = {}


static func _face(mode: int) -> PackedFloat64Array:
	var f := PackedFloat64Array()
	f.resize(7)
	match mode:
		Mode.PLAIN:
			for v in range(1, 7):
				f[v] = 1.0 / 6.0
		Mode.REROLL_ONES:  # a 1 is rolled again once: P(1) = 1/36, others 1/6 + 1/36
			f[1] = 1.0 / 36.0
			for v in range(2, 7):
				f[v] = 1.0 / 6.0 + 1.0 / 36.0
		Mode.NO_ONES:
			for v in range(2, 7):
				f[v] = 1.0 / 5.0
	return f


static func distribution(n: int, mode: int) -> PackedFloat64Array:
	var key := Vector2i(mode, n)
	if _dists.has(key):
		return _dists[key]
	var d := PackedFloat64Array([1.0])
	var face := _face(mode)
	for i in n:
		var next := PackedFloat64Array()
		next.resize(d.size() + 6)
		for s in d.size():
			if d[s] == 0.0:
				continue
			for v in range(1, 7):
				next[s + v] += d[s] * face[v]
		d = next
	_dists[key] = d
	return d


## The chance that `att_n` dice (+ `bonus`, which may be negative) beat `def_n` dice.
static func win_chance(att_n: int, att_mode: int, def_n: int, def_mode: int, bonus: int, ties_win: bool) -> float:
	var key := "%d %d %d %d %d %s" % [att_n, att_mode, def_n, def_mode, bonus, ties_win]
	if _chances.has(key):
		return _chances[key]
	var a := distribution(att_n, att_mode)
	var d := distribution(def_n, def_mode)
	var p := 0.0
	for sa in a.size():
		if a[sa] == 0.0:
			continue
		for sd in d.size():
			if d[sd] == 0.0:
				continue
			var at := sa + bonus
			if at > sd or (ties_win and at == sd):
				p += a[sa] * d[sd]
	_chances[key] = p
	return p


## The chance an attack in `state` from `from` to `to` succeeds, with every god's effect counted.
static func attack_chance(state: MatchState, from: int, to: int) -> float:
	var a := state.owners[from]
	var d := state.owners[to]
	var fa := state.effects_of(a)
	var fd := state.effects_of(d)
	var att_mode := Mode.PLAIN
	if fa.get("min_attack_face", 1) >= 2:
		att_mode = Mode.NO_ONES
	elif fa.get("reroll_ones_attack", false):
		att_mode = Mode.REROLL_ONES
	var def_mode := Mode.REROLL_ONES if fd.get("reroll_ones_defense", false) else Mode.PLAIN
	var mods := state.attack_modifiers(from, to)
	var bonus := MatchState._sum(mods["attack"]) - MatchState._sum(mods["defense"])
	var ties: bool = fa.get("attack_wins_ties", false) or fd.get("defense_loses_ties", false)
	return win_chance(state.dice[from], att_mode, state.dice[to], def_mode, bonus, ties)
