extends Node
## End to end against a Mytholore Game Server (a local one by default): two new accounts, a war of two
## opened by one and joined by the other. Player A plays through the real game screen (this test does
## the clicking); player B is a bot on an OnlineWar of its own. Checks that the server never refuses an
## action the game's own rules allowed, that the war ends with places and points, and that its replay
## exists. Takes screenshots on the way (needs a window, not --headless):
##   godot --path . res://tests/online_e2e.tscn -- --server=http://127.0.0.1:8097 --out=<folder> [--players=3]

const TIMEOUT := 300.0

var server := "http://127.0.0.1:8097"
var out := ""
var players := 2
var screen: Node
var bots: Array[OnlineWar] = []
var _t := 0.0
var _tick := 0.0
var _shots := {}
var _started := 0.0
var _done := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			server = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
		elif arg.begins_with("--players="):
			players = clampi(int(arg.get_slice("=", 1)), 2, 6)
	get_window().size = Vector2i(1280, 800)
	GameSettings.ensure_loaded()
	GameSettings.anim_speed = 2  # very fast
	GameSettings.battle_hold = 0  # brief
	GameSettings.show_ai_battles = false
	var stamp := Time.get_unix_time_from_system()
	Online.config_path = "user://online_e2e_a.cfg"
	Online.set_server(server)
	if not await _register(Online, "e2e.a.%d@example.com" % stamp, "Ana"):
		return
	var others: Array[Node] = []
	for i in players - 1:
		var o: Node = load("res://session/online.gd").new()
		o.config_path = "user://online_e2e_%d.cfg" % i
		add_child(o)
		o.server_url = server
		if not await _register(o, "e2e.%d.%d@example.com" % [i, stamp], ["Ben", "Cleo", "Dev", "Eli", "Fay"][i]):
			return
		others.append(o)
	if out != "":  # the lobby and its "open a war" form, logged in
		var lobby: Node = load("res://presentation/online_lobby.tscn").instantiate()
		add_child(lobby)
		await get_tree().create_timer(2.5).timeout
		await _shot_now("online_lobby")
		lobby._show_create()
		await get_tree().create_timer(0.6).timeout
		await _shot_now("online_create")
		lobby._mode = 0
		lobby.queue_free()
		await get_tree().process_frame
	var opened: Dictionary = await Online.open_game("room", {"players": players, "size": "small", "grid": "square"}, "private")
	if opened["status"] != 201:
		_fail("opening the war: %s" % Online.error_text(opened))
		return
	var code := str(opened["data"]["room_code"])
	var match_id := ""
	for o in others:
		var joined: Dictionary = await o.join_game(code)
		if joined["status"] != 200:
			_fail("joining: %s" % o.error_text(joined))
			return
		if joined["data"].get("match_id", null) != null:
			match_id = str(joined["data"]["match_id"])
	if match_id == "":
		_fail("the war did not start")
		return
	print("E2E: war %s of %d (code %s)" % [match_id, players, code])
	var pantheons := [["norse", "odin", "hel"], ["yoruba", "obatala", "esu"], ["mayan", "chaak", "kukulkan"],
		["egyptian", "isis", "sekhmet"], ["chinese", "guan_yu", "sun_wukong"]]
	for i in others.size():
		var war := OnlineWar.new(match_id, others[i])
		war.choice = {"pantheon": pantheons[i][0], "primary": pantheons[i][1], "secondary": pantheons[i][2]}
		add_child(war)
		bots.append(war)
	GameSettings.set_pantheon("greek")
	GameSettings.primary = "athena"
	GameSettings.secondary = "ares"
	GameSettings.online_match_id = match_id
	screen = load("res://presentation/game_screen.tscn").instantiate()
	add_child(screen)
	_started = _t


func _register(o: Node, email: String, name: String) -> bool:
	var r: Dictionary = await o._http("POST", "/api/v1/auth/register",
		{"email": email, "password": "a long enough password", "display_name": name, "birth_year": 1990}, false)
	if r["status"] != 202 and r["status"] != 201:
		_fail("registering %s: %d %s" % [email, r["status"], o.error_text(r)])
		return false
	o._take_tokens(r["data"])
	return true


func _process(delta: float) -> void:
	_t += delta
	if _done or screen == null:
		return
	if _t - _started > TIMEOUT:
		_fail("the war did not end in %d s" % TIMEOUT)
		return
	_shot_once("online_waiting", screen.online != null and screen.state == null and _t - _started > 1.5)
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	for war in bots:
		_bot(war)
	if screen.state != null:
		_shot_once("online_war", true)
	if screen._battle != null and screen._battle.visible:
		_shot_once("online_battle", true)
	if screen._over:
		_finish()
		return
	if screen._human_turn():
		_shot_once("online_my_turn", true)
		var a := _pick_attack(screen.state, screen.human)
		if a.is_empty():
			screen._on_end_turn()
		else:
			screen._on_territory_clicked(a[0])
			screen._on_territory_clicked(a[1])


## A simple player: an attack with more dice than the defender, else the end of the turn.
static func _pick_attack(s: MatchState, me: int) -> Array:
	for from in s.territories_of(me):
		for to in s.map.neighbors(from):
			if s.can_attack(from, to) and s.dice[from] > s.dice[to]:
				return [from, to]
	return []


func _bot(war: OnlineWar) -> void:
	while war.has_steps():
		war.next_step()
	if war.can_act():
		var a := _pick_attack(war.state, war.seat)
		if a.is_empty():
			war.end_turn()
		else:
			war.attack(a[0], a[1])


func _finish() -> void:
	_done = true
	await get_tree().create_timer(2.5).timeout
	_shot_once("online_end", true)
	var r: Dictionary = screen.online.my_result()
	var refused: int = screen.online.refused
	for war in bots:
		refused += war.refused
	var replay: Dictionary = await Online.api("GET", "/api/v1/games/%s/matches/%s/replay" % [Online.GAME_ID, screen.online.match_id])
	var steps: int = replay["data"].get("steps", []).size() if replay["status"] == 200 else -1
	print("E2E: A finished %s of %d, %s points, rating %s → %s, rated %s; %d actions in the replay; %d refused" % [
		r.get("place", "?"), r.get("players", 0), r.get("points", 0), r.get("rating_before", "-"), r.get("rating_after", "-"),
		r.get("rated", false), steps, refused])
	var ok: bool = r.has("place") and steps > 0 and refused == 0
	print("E2E: ", "OK" if ok else "FAILED")
	get_tree().quit(0 if ok else 1)


func _shot_once(name: String, when: bool) -> void:
	if not when or _shots.has(name) or out == "":
		return
	_shots[name] = true
	await _shot_now(name)


func _shot_now(name: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))


func _fail(message: String) -> void:
	_done = true
	print("E2E: FAILED: ", message)
	get_tree().quit(1)
