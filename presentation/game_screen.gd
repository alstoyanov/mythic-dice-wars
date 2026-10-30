extends Control
## A war: the map, the players, the battle dice and the turn buttons. Runs the turns: waits for the
## human's clicks, plays the computer players' turns, animates battles and reinforcements, and shows
## the end. The rules are MatchState's; this screen only asks and shows.

var state: MatchState
var human: int = -1  ## the human's player index in turn order
var rng := RandomNumberGenerator.new()

var _layout: GameLayout
var _view: RealmView
var _battle: BattlePanel
var _players: PlayerPanel
var _end: EndOverlay
var _status: Label
var _gods_line: Label
var _banner: Label
var _end_turn: Button
var _miracle_buttons: Dictionary = {}  ## god id -> Button
var _busy := false
var _miracle := ""  ## the god whose miracle is being aimed, "" when none
var _over := false


func _ready() -> void:
	Ui.setup_screen(self, false)
	rng.randomize()
	_new_match()
	_build_ui()
	_view.setup(state, Looks.current()["terrain"])
	_update_hud()
	_begin_turn.call_deferred()


func _new_match() -> void:
	var room := Ui.usable_size()
	var aspect := 0.85 if room.x < room.y else 1.7
	var realm := MapGenerator.generate(rng.randi(), MapGenerator.SIZES[GameSettings.map_size], aspect)
	var defs: Array = [{"name": "You", "pantheon": GameSettings.pantheon, "primary": GameSettings.primary,
		"secondary": GameSettings.secondary, "is_ai": false}]
	# Opponents: other pantheons first, every god at most once.
	var pantheons: Array = []
	for p in GodCatalog.PANTHEONS:
		if p["id"] != GameSettings.pantheon:
			pantheons.append(p["id"])
	pantheons.shuffle()
	var used := {GameSettings.primary: true, GameSettings.secondary: true}
	for i in GameSettings.players - 1:
		var pan: String = pantheons[i % pantheons.size()] if i < pantheons.size() else GodCatalog.PANTHEONS[rng.randi_range(0, 5)]["id"]
		var prim := _pick_god(pan, GodCatalog.PRIMARY, used)
		var sec := _pick_god(pan, GodCatalog.SECONDARY, used)
		defs.append({"name": GodCatalog.god(prim)["name"], "pantheon": pan, "primary": prim, "secondary": sec,
			"is_ai": true, "ai_level": GameSettings.ai_level})
	state = MatchState.create(realm, defs, rng, GameSettings.awakening)
	for p in state.players:
		if not p.is_ai:
			human = p.index


func _pick_god(pantheon: String, role: String, used: Dictionary) -> String:
	var options := GodCatalog.gods_of(pantheon, role).filter(func(g: Dictionary) -> bool: return not used.has(g["id"]))
	if options.is_empty():
		options = GodCatalog.gods_of(pantheon, role)
	var id: String = options[rng.randi_range(0, options.size() - 1)]["id"]
	used[id] = true
	return id


func _build_ui() -> void:
	var board := Control.new()
	board.clip_contents = true
	_view = RealmView.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.add_child(_view)
	_view.territory_clicked.connect(_on_territory_clicked)
	_view.cancelled.connect(_cancel)
	_view.hovered.connect(_on_hovered)

	_battle = BattlePanel.new()
	_battle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_battle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_battle.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_battle.offset_bottom = -6.0
	board.add_child(_battle)

	_banner = Label.new()
	_banner.theme_type_variation = "TitleLabel"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 10.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	board.add_child(_banner)

	_end = EndOverlay.new()
	board.add_child(_end)

	_players = PlayerPanel.new()
	_layout = GameLayout.new(board, _players, true)
	add_child(_layout)
	_status = _layout.add_text(17)
	_gods_line = _layout.add_text(13, 0.8)
	var me := state.players[human]
	_gods_line.text = "%s — %s   ·   %s — %s" % [GodCatalog.god(me.primary)["name"], GodCatalog.god(me.primary)["boon_name"],
		GodCatalog.god(me.secondary)["name"], GodCatalog.god(me.secondary)["boon_name"]]

	for god_id in [me.primary, me.secondary]:
		var m: Dictionary = GodCatalog.god(god_id).get("boon", {}).get("miracle", {})
		if m.is_empty():
			continue
		var g := GodCatalog.god(god_id)
		var b := _layout.add_button("%s (%d)" % [g["boon_name"], m["cost"]], _on_miracle.bind(god_id))
		b.tooltip_text = g["boon_text"]
		_miracle_buttons[god_id] = b
	var center := _layout.add_button("Re-centre", func() -> void: _view.reset_view())
	center.tooltip_text = "Zoom: mouse wheel or pinch. Pan: drag."
	_layout.add_button("Leave", _leave)
	_end_turn = _layout.add_button("End turn", _on_end_turn)
	_end_turn.custom_minimum_size.x = 150


# --- Turns --------------------------------------------------------------------------------------

func _begin_turn() -> void:
	if _over:
		return
	_update_hud()
	if _check_end():
		return
	var p := state.players[state.current]
	if p.is_ai:
		_run_ai_turn()
	else:
		var left := state.attacks_left(human)
		_say("Your turn. Choose one of your territories with 2 or more dice, then a neighbour to attack."
			+ (" (%d attacks this turn.)" % left if left >= 0 else ""))


func _run_ai_turn() -> void:
	_busy = true
	_update_hud()
	var speed := maxf(GameSettings.animation_factor(), 2.0)
	var p := state.players[state.current]
	_say("%s is moving…" % p.name)
	await get_tree().create_timer(0.35 / speed).timeout
	var m := AiPlayer.choose_miracle(state, rng)
	if not m.is_empty():
		await _cast(m["god"], m["target"], speed)
	var guard := 0
	while guard < 120 and not _over:
		guard += 1
		var choice := AiPlayer.choose_attack(state, rng)
		if choice.is_empty():
			break
		await _attack(choice[0], choice[1], speed)
		if _check_end():
			_busy = false
			return
	await _finish_turn(speed)
	_busy = false
	_begin_turn()


func _attack(from: int, to: int, speed: float) -> void:
	_view.selected = from
	_view.targets.clear()
	_view.arrow = Vector2i(from, to)
	var result := state.attack(from, to, rng)
	await _battle.play(result, state, speed)
	_view.arrow = Vector2i(-1, -1)
	_view.selected = -1
	_view.refresh()
	if result["won"]:
		Sound.play("conquer")
		_view.flash(to, Color(1.0, 0.9, 0.5), 0.7 / speed)
	else:
		Sound.play("repelled")
		_view.flash(from, Color(0.1, 0.1, 0.1), 0.6 / speed)
		for t in result["gains"]:
			_view.float_text(t, "+%d" % result["gains"][t], Color(0.7, 1.0, 0.7))
	for t in result["losses"]:
		_view.float_text(t, "-%d" % result["losses"][t], Color(1.0, 0.55, 0.5))
	_battle.hide_panel(speed)
	_update_hud()
	if result["awakened"]:
		var a := state.players[result["attacker"]]
		await _show_banner("%s awakens for %s!" % [GodCatalog.god(a.secondary)["name"], a.name], speed)
	if result["eliminated"] >= 0:
		var fallen := state.players[result["eliminated"]]
		await _show_banner("%s has fallen" % fallen.name, speed)


func _cast(god_id: String, target: int, speed: float) -> void:
	var r := state.cast_miracle(god_id, target)
	Sound.play("miracle")
	var g := GodCatalog.god(god_id)
	var colors := {"smite": Color(0.75, 0.85, 1.0), "bless": Color(0.6, 1.0, 0.6), "ward": Color(0.7, 0.9, 1.0)}
	_view.flash(target, colors[r["kind"]], 0.9 / speed)
	_view.refresh()
	var text: String = ("%+d" % r["change"]) if r["kind"] != "ward" else "Ward"
	_view.float_text(target, text, colors[r["kind"]])
	_say("%s calls on %s: %s." % [state.players[state.current].name, g["name"], g["boon_name"]])
	_update_hud()
	await get_tree().create_timer(0.8 / speed).timeout


func _finish_turn(speed: float) -> void:
	var r := state.end_turn(rng)
	for t in r["tribute"]:
		_view.float_text(t, "-%d tribute" % r["tribute"][t], Color(1.0, 0.55, 0.5))
	for t in r["placed"]:
		_view.float_text(t, "+%d" % r["placed"][t], Color(0.75, 1.0, 0.7), 1.0)
	if not r["placed"].is_empty():
		Sound.play("reinforce")
	_view.refresh()
	await get_tree().create_timer(0.6 / speed).timeout


func _check_end() -> bool:
	if _over:
		return true
	var w := state.winner()
	var human_out := state.players[human].eliminated
	if w < 0 and not human_out:
		return false
	_over = true
	_busy = true
	_view.interactive = false
	for b in _layout.buttons.get_children():
		b.queue_free()
	_layout.add_button("New war", func() -> void: get_tree().change_scene_to_file("res://presentation/game_screen.tscn"))
	_layout.add_button("Main menu", _leave)
	if w == human:
		Sound.play_later("win", 0.4)
		_end.play_win("Victory!", "The realm kneels before %s." % GodCatalog.god(state.players[human].primary)["name"])
		_say("You conquered the realm in %d rounds." % state.round_number)
	else:
		Sound.play_later("lose", 0.4)
		var by := state.players[w].name if w >= 0 else "your rivals"
		_end.play_lose("Defeat", "Your pantheon has fallen to %s." % by)
		_say("Your last territory has fallen.")
	return true


# --- Human input --------------------------------------------------------------------------------

func _human_turn() -> bool:
	return not _busy and not _over and state.current == human


func _on_territory_clicked(t: int) -> void:
	if not _human_turn():
		return
	if _miracle != "":
		if t < 0:
			_cancel()
			return
		var reason := state.miracle_block_reason(_miracle, t)
		if reason != "":
			_say(reason)
			return
		var god_id := _miracle
		_miracle = ""
		_view.targets.clear()
		_busy = true
		await _cast(god_id, t, GameSettings.animation_factor())
		_busy = false
		_update_hud()
		_say("Your turn.")
		return
	if t < 0:
		_cancel()
		return
	var sel := _view.selected
	if state.owners[t] == human:
		if t == sel:
			_cancel()
		elif state.dice[t] < 2:
			_say("A territory needs at least 2 dice to attack.")
		elif not state.can_attack_from(t):
			_say(_why_not_from(t))
		else:
			_select(t)
		return
	if sel < 0:
		_say("First choose one of your territories to attack from.")
		return
	var reason := state.attack_block_reason(sel, t)
	if reason != "":
		_say(reason)
		return
	_busy = true
	await _attack(sel, t, GameSettings.animation_factor())
	_busy = false
	_update_hud()
	if not _check_end():
		_say(_turn_hint())


## Why no attack can start from territory `t` (it has 2+ dice): the first rule that stops it.
func _why_not_from(t: int) -> String:
	for nb in state.map.neighbors(t):
		if state.owners[nb] != human:
			return state.attack_block_reason(t, nb)
	return "All its neighbours are already yours."


## What to do now, on the human's turn: attack (and how many attacks are left), or end the turn.
func _turn_hint() -> String:
	var left := state.attacks_left(human)
	if left == 0:
		return "%s: no attacks left this turn. End your turn." % state._limit_name(human)
	var can_any := false
	for t in state.territories_of(human):
		if state.can_attack_from(t):
			can_any = true
			break
	if not can_any:
		return "No attack is possible now. End your turn."
	if left > 0:
		return "Attack again (%d left this turn), or end your turn." % left
	return "Attack again, or end your turn."


func _select(t: int) -> void:
	Sound.play("select")
	_view.selected = t
	_view.targets.clear()
	for nb in state.map.neighbors(t):
		if state.can_attack(t, nb):
			_view.targets.append(nb)
	_view.target_color = Color(1.0, 0.5, 0.35)
	_view.queue_redraw()
	var left := state.attacks_left(human)
	_say("Attack a highlighted neighbour (or choose another territory)."
		+ (" %d attacks left this turn." % left if left >= 0 else ""))


func _cancel() -> void:
	_view.selected = -1
	_view.targets.clear()
	_miracle = ""
	_view.queue_redraw()


func _on_hovered(t: int) -> void:
	if not _human_turn() or t < 0 or _view.selected < 0 or _miracle != "":
		return
	if _view.targets.has(t):
		var chance := DiceOdds.attack_chance(state, _view.selected, t)
		var percent := ">99%" if chance > 0.995 else ("<1%" if chance < 0.005 else "%d%%" % roundi(chance * 100.0))
		_say("%d dice against %d — %s chance to win." % [state.dice[_view.selected], state.dice[t], percent])


func _on_miracle(god_id: String) -> void:
	if not _human_turn():
		return
	var reason := state.miracle_block_reason(god_id)
	if reason != "":
		_say(reason)
		return
	_cancel()
	_miracle = god_id
	var kind: String = state.miracle_of(god_id)["kind"]
	for t in state.owners.size():
		if state.miracle_block_reason(god_id, t) == "":
			_view.targets.append(t)
	_view.target_color = Color(0.6, 0.85, 1.0)
	_view.queue_redraw()
	_say("Choose an enemy territory to strike." if kind == "smite" else "Choose one of your territories.")


func _on_end_turn() -> void:
	if not _human_turn():
		return
	_cancel()
	_busy = true
	await _finish_turn(GameSettings.animation_factor())
	_busy = false
	_begin_turn()


func _leave() -> void:
	get_tree().change_scene_to_file("res://presentation/main_menu.tscn")


# --- HUD ----------------------------------------------------------------------------------------

func _say(text: String) -> void:
	_status.text = text


func _update_hud() -> void:
	_players.update(state)
	var mine := state.current == human and not _busy and not _over
	if _end_turn != null and is_instance_valid(_end_turn):
		_end_turn.disabled = not mine
		_end_turn.text = "End turn (+%d)" % state.reinforcement_preview(human) if not state.players[human].eliminated else "End turn"
	for god_id in _miracle_buttons:
		var b: Button = _miracle_buttons[god_id]
		if not is_instance_valid(b):
			continue
		var awake := state.miracle_gods(human).has(god_id)
		b.visible = awake
		b.disabled = not mine or state.miracle_block_reason(god_id) != "" if state.current == human else true
		b.text = "%s (%d / %d favour)" % [GodCatalog.god(god_id)["boon_name"], state.miracle_of(god_id)["cost"], state.players[human].favor]


func _show_banner(text: String, speed: float) -> void:
	_banner.text = text
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.2 / speed)
	tw.tween_interval(1.0 / speed)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.3 / speed)
	await tw.finished
