extends Control
## A war: the map, the players, the battle dice and the turn buttons. Runs the turns: waits for the
## human's clicks, plays the computer players' turns, animates battles and reinforcements, and shows
## the end. The rules are MatchState's; this screen only asks and shows.
##
## Online (GameSettings.online_match_id set by the online lobby) the server runs the rules: an
## OnlineWar mirrors its state into `state`, the player's clicks become actions sent to it, and every
## action it announces (the player's own and the other players') is shown here one after another,
## with the same animations as a local war.

var state: MatchState
var human: int = -1  ## the human's player index in turn order (online: their seat)
var rng := RandomNumberGenerator.new()
var online: OnlineWar  ## the online war, or null for a local one

var _layout: GameLayout
var _view: RealmView
var _battle: BattlePanel
var _players: PlayerPanel
var _end: EndOverlay
var _status: Label
var _gods_line: Label
var _clock: Label  ## online: the time left in the player's turn
var _banner: Label
var _end_turn: Button
var _miracle_buttons: Dictionary = {}  ## god id -> Button
var _busy := false
var _miracle := ""  ## the god whose miracle is being aimed, "" when none
var _over := false
var _pumping := false  ## online: showing the actions the server announced
var _waiting: Control  ## online: the panel shown until the war begins
var _wait_text: Label
var _clock_wait := 0.0


func _ready() -> void:
	Ui.setup_screen(self, false)
	rng.randomize()
	if GameSettings.online_match_id != "":
		_start_online(GameSettings.online_match_id)
		return
	_new_match()
	_build_ui()
	_view.viewer = human  # under fog of war the map and the player list show what the player sees
	_players.viewer = human
	_view.setup(state, Looks.current()["terrain"])
	_update_hud()
	_begin_turn.call_deferred()


func _new_match() -> void:
	var room := Ui.usable_size()
	var aspect := 0.85 if room.x < room.y else 1.7
	var realm := MapGenerator.generate(rng.randi(), MapGenerator.SIZES[GameSettings.map_size], aspect, GameSettings.grid)
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
		var pan: String = pantheons[i % pantheons.size()] if i < pantheons.size() else GodCatalog.PANTHEONS[rng.randi_range(0, GodCatalog.PANTHEONS.size() - 1)]["id"]
		var prim := _pick_god(pan, GodCatalog.PRIMARY, used)
		var sec := _pick_god(pan, GodCatalog.SECONDARY, used)
		defs.append({"name": GodCatalog.god(prim)["name"], "pantheon": pan, "primary": prim, "secondary": sec,
			"is_ai": true, "ai_level": GameSettings.ai_level})
	state = MatchState.create(realm, defs, rng, GameSettings.awakening, GameSettings.head_start)
	state.fog = GameSettings.fog
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
	if online != null:
		_clock = _layout.add_text(13, 0.9)
	_battle = BattlePanel.new()  # over the whole screen, above the layout
	add_child(_battle)
	var me := state.players[human]
	_gods_line.text = "%s — %s   ·   %s — %s" % [GodCatalog.god(me.primary)["name"], GodCatalog.god(me.primary)["boon_name"],
		GodCatalog.god(me.secondary)["name"], GodCatalog.god(me.secondary)["boon_name"]]

	for god_id in [me.primary, me.secondary]:
		var m: Dictionary = GodCatalog.god(god_id).get("boon", {}).get("miracle", {})
		if m.is_empty():
			continue
		var g := GodCatalog.god(god_id)
		var b := _layout.add_button("%s (%d)" % [g["boon_name"], m["cost"]], _on_miracle.bind(god_id))
		_icon(b, {"smite": "smite", "bless": "bless", "ward": "ward"}[m["kind"]])
		b.tooltip_text = g["boon_text"]
		_miracle_buttons[god_id] = b
	var center := _layout.add_button("Re-centre", func() -> void: _view.reset_view())
	center.tooltip_text = "Zoom: mouse wheel or pinch. Pan: drag."
	_layout.add_button("Leave", _leave)
	_end_turn = _layout.add_button("End turn", _on_end_turn)
	_icon(_end_turn, "end_turn")
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
		_say(_head_start_note() + "Your turn. Choose one of your territories with 2 or more dice, then a neighbour to attack."
			+ (" (%d attacks this turn.)" % left if left >= 0 else ""))


## On the player's first turn: where they stand in the turn order and the head start that makes up for it.
func _head_start_note() -> String:
	if state.round_number != 1:
		return ""
	var n := state.players.size()
	var given := 0
	for p in state.players:
		given += p.head_start
	if given == 0:
		return "You move %s of %d (classic order, no head start). " % [_ordinal(human + 1), n]
	if human == 0:
		return "You move first, so your rivals got a head start of extra dice. "
	return "You move %s of %d, so you got a head start of %d dice. " % [_ordinal(human + 1), n, state.players[human].head_start]


static func _ordinal(k: int) -> String:
	if k % 100 in [11, 12, 13]:
		return "%dth" % k
	return "%d%s" % [k, {1: "st", 2: "nd", 3: "rd"}.get(k % 10, "th")]


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
	# Under fog of war a battle is shown only if the player sees at least one of the two territories.
	var seen := _view.is_seen(from) or _view.is_seen(to)
	var result := state.attack(from, to, rng)
	await _show_battle(result, speed, seen)


## Shows a battle that has been fought (`state` is already after it): the battle screen for the
## player's own attacks (or every battle, if chosen in Settings), else the arrow on the map; then the
## outcome on the map.
func _show_battle(result: Dictionary, speed: float, seen: bool) -> void:
	var from: int = result["from"]
	var to: int = result["to"]
	if seen:
		_view.selected = from if _view.is_seen(from) else -1
		_view.arrow = Vector2i(from, to)
	_view.targets.clear()
	var involves_player: bool = result["attacker"] == human or result["defender"] == human
	if not seen:  # a battle somewhere in the fog: nothing to show
		pass
	elif result["attacker"] == human or GameSettings.show_ai_battles:
		await _battle.play(result, state, speed)
		var hold := GameSettings.result_hold()
		if hold != GameSettings.WAIT and not involves_player:
			hold /= speed  # battles between rivals follow the animation speed
		if hold == GameSettings.WAIT and involves_player:
			_say("Press Continue (or click anywhere, Enter or Space).")
		elif hold == GameSettings.WAIT:
			hold = GameSettings.HOLDS[0] / speed  # no waiting on battles between rivals
		await _battle.hold(hold)
		await _battle.hide_panel(speed)
	else:  # another player's attack: only the arrow on the map for a second, then the outcome
		await get_tree().create_timer(GameSettings.MAP_BATTLE).timeout
	_view.arrow = Vector2i(-1, -1)
	_view.selected = -1
	_view.refresh()
	if not seen:
		pass
	elif result["won"]:
		Sound.play("conquer")
		_view.play_fx("dust", to, 0.8 / speed, 60.0, 10.0)
		_view.flash(to, Color(1.0, 0.9, 0.5), 0.7 / speed)
	else:
		Sound.play("repelled")
		_view.play_fx("dust", from, 0.6 / speed, 40.0, 8.0)
		_view.flash(from, Color(0.1, 0.1, 0.1), 0.6 / speed)
		for t in result["gains"]:
			_view.float_text(t, "+%d" % result["gains"][t], Color(0.7, 1.0, 0.7))
	for t in result["losses"]:
		_view.float_text(t, "-%d" % result["losses"][t], Color(1.0, 0.55, 0.5))
		_view.play_fx("crumble", t, 0.6, 30.0, 12.0)
	_update_hud()
	if result["awakened"]:  # the gods are no secret, even in the fog
		var a := state.players[result["attacker"]]
		_view.play_fx("motes", to, 1.2, 80.0, 20.0)
		await _show_banner("%s awakens for %s!" % [GodCatalog.god(a.secondary)["name"], a.name], speed)
	if result["eliminated"] >= 0:
		var fallen := state.players[result["eliminated"]]
		await _show_banner("%s has fallen" % fallen.name, speed)


func _cast(god_id: String, target: int, speed: float) -> void:
	var caster := state.current
	var r := state.cast_miracle(god_id, target)
	await _show_cast(r, caster, speed)


## Shows a miracle that has been cast (`state` is already after it).
func _show_cast(r: Dictionary, caster: int, speed: float) -> void:
	var target: int = r["target"]
	Sound.play("miracle")
	var g := GodCatalog.god(r["god"])
	var colors := {"smite": Color(0.75, 0.85, 1.0), "bless": Color(0.6, 1.0, 0.6), "ward": Color(0.7, 0.9, 1.0)}
	_view.flash(target, colors[r["kind"]], 0.9 / speed)
	match r["kind"]:
		"smite":
			_view.play_fx("lightning", target, 0.7, 80.0, 34.0)
			_view.play_fx("dust", target, 0.8, 50.0, 8.0)
		"bless":
			_view.play_fx("motes", target, 1.0, 60.0, 18.0)
		"ward":
			_view.play_fx("ward_dome", target, 0.9, 46.0, 12.0)
	_view.refresh()
	var text: String = ("%+d" % r["change"]) if r["kind"] != "ward" else "Ward"
	_view.float_text(target, text, colors[r["kind"]])
	_say("%s calls on %s: %s." % [state.players[caster].name, g["name"], g["boon_name"]])
	_update_hud()
	await get_tree().create_timer(0.8 / speed).timeout


func _finish_turn(speed: float) -> void:
	var r := state.end_turn(rng)
	await _show_end_turn(r, speed)


## Shows the end of a turn (`state` is already after it): tribute and reinforcements.
func _show_end_turn(r: Dictionary, speed: float) -> void:
	for t in r["tribute"]:
		_view.float_text(t, "-%d tribute" % r["tribute"][t], Color(1.0, 0.55, 0.5))
		_view.play_fx("crumble", t, 0.6, 30.0, 12.0)
	for t in r["placed"]:
		_view.float_text(t, "+%d" % r["placed"][t], Color(0.75, 1.0, 0.7), 1.0)
	if not r["placed"].is_empty() and (r["player"] == human or not state.fog):
		Sound.play("reinforce")
	_view.refresh()
	await get_tree().create_timer(0.6 / speed).timeout


func _check_end() -> bool:
	if online != null:
		return _over  # an online war ends when the server says so (_online_end)
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
	if online != null:
		return not _busy and not _over and not _pumping and online.can_act()
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
		if online != null:
			online.cast(god_id, t)
			_update_hud()
			return
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
	if online != null:  # the server fights the battle; it comes back as an announced action
		_view.arrow = Vector2i(sel, t)
		_view.targets.clear()
		_view.queue_redraw()
		online.attack(sel, t)
		_update_hud()
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
	if _view == null:
		return
	_view.selected = -1
	_view.targets.clear()
	_miracle = ""
	_view.queue_redraw()


func _on_hovered(t: int) -> void:
	if not _human_turn() or t < 0:
		return
	if not _view.is_seen(t):
		_say("Hidden by the fog of war: you see only your own land and its neighbours.")
		return
	if _view.selected < 0 or _miracle != "":
		return
	if _view.targets.has(t):
		var chance := DiceOdds.attack_chance(state, _view.selected, t)
		var percent := ">99%" if chance > 0.995 else ("<1%" if chance < 0.005 else "%d%%" % roundi(chance * 100.0))
		var text := "%d dice against %d — %s chance to win." % [state.dice[_view.selected], state.dice[t], percent]
		# What the gods add to this fight, both sides.
		var mods := state.attack_modifiers(_view.selected, t)
		var parts: Array[String] = []
		for m in mods["attack"]:
			parts.append("you %+d %s" % [m[1], m[0]])
		for m in mods["defense"]:
			parts.append("they %+d %s" % [m[1], m[0]])
		if not parts.is_empty():
			text += "  (" + "; ".join(parts) + ")"
		_say(text)


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
	if online != null:
		online.end_turn()
		_update_hud()
		return
	_busy = true
	await _finish_turn(GameSettings.animation_factor())
	_busy = false
	_begin_turn()


## Puts a HUD icon (Looks.icon) at the front of a button, if the icon exists.
static func _icon(b: Button, icon_name: String) -> void:
	var tex := Looks.icon(icon_name)
	if tex == null:
		return
	b.icon = tex
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 26)
	b.add_theme_constant_override("h_separation", 8)


func _unhandled_input(event: InputEvent) -> void:
	if _battle != null and _battle.waiting and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_battle.accept()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	if online != null:
		_leave_online()
		return
	get_tree().change_scene_to_file("res://presentation/main_menu.tscn")


# --- HUD ----------------------------------------------------------------------------------------

func _say(text: String) -> void:
	if _status != null:
		_status.text = text
	elif _wait_text != null:
		_wait_text.text = text


func _update_hud() -> void:
	if _players == null:
		return
	_players.update(state)
	var mine := _human_turn()
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


# --- Online -------------------------------------------------------------------------------------

func _start_online(match_id: String) -> void:
	_waiting = Control.new()
	_waiting.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_waiting)
	var col := Ui.centered_column(_waiting, 14)
	Ui.title(col, "Online war")
	_wait_text = Label.new()
	_wait_text.text = "Connecting…"
	_wait_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_wait_text)
	Ui.wrap_to_screen(_wait_text)
	var gods := Label.new()
	gods.text = "You: %s — %s and %s" % [GodCatalog.pantheon(GameSettings.pantheon)["name"],
		GodCatalog.god(GameSettings.primary).get("name", ""), GodCatalog.god(GameSettings.secondary).get("name", "")]
	gods.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gods.modulate = Color(1, 1, 1, 0.75)
	col.add_child(gods)
	Ui.button(col, "Leave", _leave_online)
	online = OnlineWar.new(match_id)
	add_child(online)
	online.waiting.connect(func(text: String) -> void:
		if _wait_text != null:
			_wait_text.text = text)
	online.war_ready.connect(_online_begin)
	online.step_arrived.connect(_pump)
	online.resynced.connect(func() -> void:
		if _view != null and not _pumping:
			_cancel()
			_view.refresh()
			_update_hud()
			_online_prompt())
	online.notice.connect(func(text: String) -> void:
		if text != "":
			_say(text))
	online.finished.connect(func() -> void:
		if not _pumping:
			_online_end())
	online.failed.connect(_online_failed)


## The war has begun: the screen is built from the server's realm and state.
func _online_begin() -> void:
	state = online.state
	human = online.seat
	if _waiting != null:
		_waiting.queue_free()
		_waiting = null
		_wait_text = null
	_build_ui()
	_view.setup(state, Looks.current()["terrain"])
	_update_hud()
	_online_prompt()
	_pump()


## Shows the actions the server announced, one after another (the other players' and the player's own).
func _pump() -> void:
	if _pumping or online == null or _view == null:
		return
	_pumping = true
	_update_hud()
	while online.has_steps():
		var step := online.next_step()
		var mine: bool = step["seat"] == human
		var speed := GameSettings.animation_factor() if mine else maxf(GameSettings.animation_factor(), 2.0)
		match str(step["kind"]):
			"attack":
				await _show_battle(step["result"], speed, true)
			"miracle":
				await _show_cast(step["result"], step["seat"], speed)
			"end":
				if bool(step.get("timeout", false)) and not mine:
					_say("%s ran out of time." % state.players[step["seat"]].name)
				await _show_end_turn(step["result"], speed)
			"left":
				_view.refresh()
				var why: String = {"resigned": "has left the war", "disconnected": "lost the connection and left the war",
					"timeout": "missed the deadline and left the war"}.get(str(step.get("why", "")), "has left the war")
				await _show_banner("%s %s" % [state.players[step["seat"]].name, why], speed)
			_:
				_view.refresh()
		_update_hud()
	_pumping = false
	_update_hud()
	if online.stage == OnlineWar.Stage.OVER:
		_online_end()
	else:
		_online_prompt()


## What to do now: the player's turn (and its time), or whose turn it is.
func _online_prompt() -> void:
	if _over or state == null:
		return
	if state.players[human].eliminated:
		_say("Your pantheon has fallen. You can watch the war to its end, or leave.")
	elif online.can_act():
		var left := state.attacks_left(human)
		_say(_head_start_note() + "Your turn. Choose one of your territories with 2 or more dice, then a neighbour to attack."
			+ (" (%d attacks this turn.)" % left if left >= 0 else ""))
	else:
		_say("%s is moving…" % state.players[state.current].name)


func _process(delta: float) -> void:
	if online == null or _clock == null:
		return
	_clock_wait -= delta
	if _clock_wait > 0.0:
		return
	_clock_wait = 0.5
	var left := online.seconds_left()
	if left < 0 or _over:
		_clock.text = ""
	elif state.current == human and not state.players[human].eliminated:
		_clock.text = "Your time: %s" % _duration(left)
		_clock.modulate = Color(1, 0.6, 0.5) if left <= 10 else Color(1, 1, 1, 0.9)
	else:
		_clock.text = "%s's time: %s" % [state.players[state.current].name, _duration(left)]
		_clock.modulate = Color(1, 1, 1, 0.7)


static func _duration(s: int) -> String:
	if s >= 3600:
		return "%d h %02d min" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%d:%02d" % [s / 60, s % 60]
	return "%d s" % s


## The war is over: the player's place, the points and the rating it brought.
func _online_end() -> void:
	if _over:
		return
	_over = true
	_busy = true
	if _view == null:  # it ended before it began (everyone else left while choosing)
		_online_failed("The war ended before it began.")
		return
	_view.interactive = false
	for b in _layout.buttons.get_children():
		b.queue_free()
	_layout.add_button("Online wars", func() -> void: _to_lobby())
	_layout.add_button("Replay on the website", func() -> void:
		OS.shell_open(Online.web_url("/account/matches/%s/%s" % [Online.GAME_ID, online.match_id])))
	_layout.add_button("Main menu", func() -> void:
		GameSettings.online_match_id = ""
		get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	var r := online.my_result()
	var place: int = r.get("place", 0)
	var n: int = r.get("players", state.players.size())
	var parts: Array[String] = []
	if r.get("rated", false):
		parts.append("+%d ranking points" % r.get("points", 0))
		if r.has("rating_after"):
			parts.append("rating %d → %d (%+d)" % [r["rating_before"], r["rating_after"], r["rating_after"] - r["rating_before"]])
	else:
		parts.append("a friendly war: no points or rating")
	var detail := " · ".join(parts)
	if place == 1:
		Sound.play_later("win", 0.4)
		_end.play_win("Victory!", "You won a war of %d. %s" % [n, detail])
		_say("You conquered the realm in %d rounds." % state.round_number)
	elif place > 0:
		Sound.play_later("lose", 0.4)
		_end.play_lose("%s of %d" % [_ordinal(place), n], detail)
		_say("The war is over: you finished %s of %d." % [_ordinal(place), n])
	else:
		_end.play_lose("The war was cancelled", "No result was recorded.")
		_say("The war was cancelled.")


func _online_failed(message: String) -> void:
	_over = true
	if _waiting == null:
		_waiting = Control.new()
		_waiting.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_waiting)
		var col := Ui.centered_column(_waiting, 14)
		Ui.title(col, "Online war")
		_wait_text = Label.new()
		_wait_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(_wait_text)
		Ui.wrap_to_screen(_wait_text)
		Ui.button(col, "Online wars", _to_lobby)
	_wait_text.text = message


## Leaving a war in progress: confirm, then resign (the player is placed below everyone still fighting).
func _leave_online() -> void:
	var playing := online != null and online.stage in [OnlineWar.Stage.PLAYING, OnlineWar.Stage.CHOOSING] \
		and not _over and (state == null or not state.players[human].eliminated)
	if not playing:
		_to_lobby()
		return
	var ask := ConfirmationDialog.new()
	ask.title = "Leave the war?"
	ask.dialog_text = "If you leave, you resign: you are placed below everyone still fighting, and your land stays for the others to take."
	ask.ok_button_text = "Resign and leave"
	ask.cancel_button_text = "Stay"
	add_child(ask)
	ask.confirmed.connect(func() -> void:
		online.resign()
		await get_tree().create_timer(0.3).timeout
		_to_lobby())
	ask.popup_centered()


func _to_lobby() -> void:
	GameSettings.online_match_id = ""
	get_tree().change_scene_to_file("res://presentation/online_lobby.tscn")
