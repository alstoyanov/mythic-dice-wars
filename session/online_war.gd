class_name OnlineWar
extends Node
## One online war on the Mytholore Game Server, over a WebSocket.
##
## The server is the host: it deals the land, rolls every die and checks every action (a Go port of
## MatchState). This session mirrors what it sends into a MatchState (`state`) that the game screen
## draws exactly like a local war, and queues the actions the server announces, so the screen plays
## them one after another: next_step() takes the oldest and brings `state` to the position after it.
## Every action's events end with the whole public state, so the mirror never drifts.
##
## Before the war every player chooses a pantheon and gods: this session sends the player's choice
## (GameSettings.pantheon / primary / secondary) as soon as the server asks for it.

signal waiting(text: String)  ## connecting, the others still choosing… (a line for the waiting screen)
signal war_ready  ## the war has begun: `realm` and `state` are known, the screen can be built
signal step_arrived  ## a new action is in the queue
signal resynced  ## the state jumped (after a lost connection): redraw without animating
signal notice(text: String)  ## something to tell the player (a refused action, a player disconnected…)
signal finished  ## GAME_OVER arrived (`result`); play the queue to its end first
signal failed(message: String)  ## the war cannot go on

enum Stage { CONNECTING, CHOOSING, PLAYING, OVER, FAILED }

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
const RECONNECT_TRIES := 6
const SYNC_RETRY_SECONDS := 3.0

var online: Node
var match_id: String
var stage: Stage = Stage.CONNECTING
var seat: int = -1
var realm: RealmMap
var state: MatchState
var settings: Dictionary = {}
var mode: String = ""
var async: bool = false
var seats: Array = []  ## [{seat, user: {id, display_name}, connected}]
var result: Dictionary = {}  ## the GAME_OVER payload: placements, rated, rating_changes, stats
var deadline: float = 0.0  ## unix seconds of the current turn's deadline, 0 = none
## The gods to bring: {pantheon, primary, secondary}; empty = the player's choice in GameSettings.
var choice: Dictionary = {}
var refused := 0  ## actions the server refused (the local rules should never allow one)

var _ws := WebSocketPeer.new()
var _ws_open := false
var _hello_sent := false
var _reconnects := 0
var _queue: Array[Dictionary] = []
var _seq := -1  ## the last action received
var _sent := false  ## an action of this player is on its way
var _gods_sent := false
var _client_seq := 0
var _sync_asked := false
var _sync_at := 0.0


func _init(p_match_id: String, p_online: Node = null) -> void:
	match_id = p_match_id
	online = p_online if p_online != null else Online


func _ready() -> void:
	waiting.emit(tr("Connecting…"))
	_connect()


func _exit_tree() -> void:
	if _ws_open:
		_ws.close()


# ---------- what the screen asks ----------

## May the player act now (their turn, nothing on its way, every announced action shown)?
func can_act() -> bool:
	return stage == Stage.PLAYING and not _sent and _queue.is_empty() and state != null \
		and state.current == seat and not state.players[seat].eliminated


func has_steps() -> bool:
	return not _queue.is_empty()


## The oldest announced action, with `state` brought to the position after it:
## {seat, kind ("attack" | "miracle" | "end" | "left"), result (as MatchState returns it), timeout, why}.
func next_step() -> Dictionary:
	var step: Dictionary = _queue.pop_front()
	apply_snapshot(state, step["snapshot"], _names())
	return step


func seconds_left() -> int:
	if deadline <= 0.0 or stage != Stage.PLAYING:
		return -1
	return maxi(0, int(deadline - Time.get_unix_time_from_system()))


func player_name(p: int) -> String:
	for s: Dictionary in seats:
		if int(s.get("seat", -1)) == p:
			return str(s.get("user", {}).get("display_name", tr("Player %d") % (p + 1)))
	return tr("Player %d") % (p + 1)


## This player's finishing place and the points and rating it brought ({} until the war is over).
func my_result() -> Dictionary:
	var out := {}
	for pl: Dictionary in result.get("placements", []):
		if int(pl.get("seat", -1)) == seat:
			out["place"] = int(pl.get("placement", 0))
	for st: Dictionary in result.get("stats", []):
		if int(st.get("seat", -1)) == seat and str(st.get("key", "")) == "points":
			out["points"] = int(st.get("delta", 0))
	for c: Dictionary in result.get("rating_changes", []):
		if int(c.get("seat", -1)) == seat:
			out["rating_before"] = roundi(float(c.get("before", 0)))
			out["rating_after"] = roundi(float(c.get("after", 0)))
	out["players"] = seats.size()
	out["rated"] = bool(result.get("rated", false))
	return out


# ---------- actions ----------

func attack(from: int, to: int) -> void:
	_act({"kind": "attack", "from": from, "to": to})


func cast(god_id: String, target: int) -> void:
	_act({"kind": "miracle", "god": god_id, "target": target})


func end_turn() -> void:
	_act({"kind": "end"})


func resign() -> void:
	if stage == Stage.PLAYING or stage == Stage.CHOOSING:
		_send("RESIGN")


func _act(action: Dictionary) -> void:
	if not can_act():
		return
	_sent = true
	_send("MAKE_MOVE", {"action": action})


# ---------- connection ----------

func _connect() -> void:
	var r: Dictionary = await online.api("POST", "/api/v1/ws-tickets", {"game_id": online.GAME_ID, "match_id": match_id})
	if r["status"] != 200:
		_connection_lost(online.error_text(r))
		return
	var url: String = online.ws_url("/ws/games/%s/matches/%s?ticket=%s" % [online.GAME_ID, match_id, str(r["data"]["ticket"]).uri_encode()])
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 21
	_hello_sent = false
	if _ws.connect_to_url(url) != OK:
		_connection_lost(tr("Cannot reach the server. Check your connection."))
		return
	_ws_open = true


func _process(_delta: float) -> void:
	if not _ws_open:
		return
	if _sync_asked and Time.get_ticks_msec() - _sync_at > SYNC_RETRY_SECONDS * 1000.0:
		_request_sync()
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _hello_sent:
				_hello_sent = true
				_send("CONNECT", {"protocol": online.MATCH_PROTOCOL})
			while _ws.get_available_packet_count() > 0:
				var msg: Variant = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
				if msg is Dictionary:
					_on_message(msg)
		WebSocketPeer.STATE_CLOSED:
			_ws_open = false
			if stage != Stage.OVER and stage != Stage.FAILED:
				_connection_lost(tr("The connection was lost."))


func _send(type: String, payload: Dictionary = {}) -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_client_seq += 1
	_ws.send_text(JSON.stringify({"type": type, "client_seq": _client_seq, "payload": payload}))


func _request_sync() -> void:
	_sync_asked = true
	_sync_at = Time.get_ticks_msec()
	_send("REQUEST_SYNC")


## Reconnects a few times (the server keeps the seat for a while), then gives up.
func _connection_lost(message: String) -> void:
	if stage == Stage.OVER or stage == Stage.FAILED:
		return
	_reconnects += 1
	if _reconnects > RECONNECT_TRIES:
		_fail(message)
		return
	if state != null:
		notice.emit(tr("Connection lost. Reconnecting…"))
	else:
		waiting.emit(tr("Connection lost. Reconnecting…"))
	await get_tree().create_timer(1.5 * _reconnects).timeout
	if is_inside_tree() and stage != Stage.OVER and stage != Stage.FAILED:
		_connect()


func _fail(message: String) -> void:
	stage = Stage.FAILED
	if _ws_open:
		_ws.close()
	failed.emit(message)


# ---------- messages ----------

func _on_message(msg: Dictionary) -> void:
	var p: Dictionary = msg.get("payload", {}) if msg.get("payload", {}) is Dictionary else {}
	var seq := int(msg.get("seq", 0))
	match str(msg.get("type", "")):
		"CONNECTED":
			seat = int(p.get("seat", -1))
			seats = p.get("seats", [])
			settings = p.get("settings", {}) if p.get("settings", {}) is Dictionary else {}
			mode = str(p.get("mode", ""))
			async = bool(p.get("async", false))
			_reconnects = 0
			_take_turn(p.get("turn", {}))
		"STATE_SYNC":
			_sync_asked = false
			_sent = false
			_take_turn(p.get("turn", {}))
			_on_view(p.get("view", {}), seq)
		"MOVE_ACCEPTED":
			_take_turn(p.get("turn", {}))
			_on_action(p, seq)
		"INVALID_MOVE":
			_sent = false
			refused += 1
			notice.emit(str(p.get("message", tr("That is not allowed now."))))
			_request_sync()
		"GAME_OVER":
			result = p
			stage = Stage.OVER
			_ws_open = false
			_ws.close()
			finished.emit()
		"MATCH_CANCELLED":
			_fail(tr("Not everyone connected in time. The war was cancelled."))
		"PLAYER_DISCONNECTED":
			if int(p.get("seat", -1)) != seat:
				notice.emit(tr("%s lost the connection and has %d seconds to come back.") % [
					player_name(int(p.get("seat", -1))), int(p.get("grace_seconds", 0))])
		"PLAYER_RECONNECTED":
			if int(p.get("seat", -1)) != seat:
				notice.emit(tr("%s is back.") % player_name(int(p.get("seat", -1))))
		"TURN_TIMEOUT":
			var who := int(p.get("seat", -1))
			if str(p.get("policy", "")) == "lose":
				notice.emit(tr("%s missed the deadline and leaves the war.") % player_name(who))
			elif who == seat:
				notice.emit(tr("Your time ran out: your turn ended."))
		"ERROR":
			match str(p.get("code", "")):
				"server_restarting":
					notice.emit(tr("The server is restarting. Reconnecting…"))
				"rate_limited":
					_sent = false


func _take_turn(turn: Variant) -> void:
	if turn is Dictionary and turn.has("deadline"):
		deadline = Time.get_unix_time_from_datetime_string(str(turn["deadline"]).substr(0, 19))
	elif turn is Dictionary:
		deadline = 0.0


## A full view (on connecting, and after a lost connection): the realm, the state, and the gods to send.
func _on_view(view: Dictionary, seq: int) -> void:
	if view.is_empty():
		return
	if realm == null:
		realm = realm_from(view.get("map", {}))
		state = MatchState.new()
		state.map = realm
		state.awakening = str(settings.get("awakening", "milestone"))
	if seq < _seq:
		return  # older than what was already received
	var behind := seq > _seq and not _queue.is_empty()
	_seq = seq
	_queue.clear()
	apply_snapshot(state, view, _names())
	_update_stage(view)
	if behind or stage == Stage.PLAYING:
		resynced.emit()


## An action announced by the server (anyone's, this player's included).
func _on_action(p: Dictionary, seq: int) -> void:
	if seq <= _seq or state == null:
		if state == null:
			_request_sync()
		return
	_seq = seq
	var events: Array = p.get("events", []) if p.get("events", []) is Array else []
	var snapshot: Dictionary = {}
	var step := {"seat": int(p.get("seat", -1)), "kind": "", "result": {}, "timeout": false}
	for ev: Dictionary in events:
		match str(ev.get("type", "")):
			"state":
				snapshot = ev.get("state", {})
			"battle":
				step["kind"] = "attack"
				step["result"] = _battle_result(ev.get("result", {}))
			"miracle":
				step["kind"] = "miracle"
				step["result"] = _numbers(ev.get("result", {}))
			"turn_ended":
				step["kind"] = "end"
				step["timeout"] = bool(ev.get("timeout", false))
				step["result"] = _turn_result(ev.get("result", {}))
			"left":
				step["kind"] = "left"
				step["why"] = str(ev.get("why", ""))
				step["seat"] = int(ev.get("seat", -1))
	if int(p.get("seat", -1)) == seat:
		_sent = false
	if snapshot.is_empty():
		_request_sync()
		return
	if stage != Stage.PLAYING:  # before the war: the choices, then the deal
		apply_snapshot(state, snapshot, _names())
		_update_stage(snapshot)
		return
	step["snapshot"] = snapshot
	_queue.append(step)
	step_arrived.emit()


func _update_stage(view: Dictionary) -> void:
	match str(view.get("phase", "")):
		"CHOOSING":
			stage = Stage.CHOOSING
			var mine: Dictionary = {}
			var ready := 0
			for p: Dictionary in view.get("players", []):
				if bool(p.get("chosen", false)) or bool(p.get("out", false)):
					ready += 1
				if int(p.get("seat", -1)) == seat:
					mine = p
			if not mine.is_empty() and not bool(mine.get("chosen", false)) and not _gods_sent:
				_gods_sent = true
				var gods := choice if not choice.is_empty() else {"pantheon": GameSettings.pantheon,
					"primary": GameSettings.primary, "secondary": GameSettings.secondary}
				_send("MAKE_MOVE", {"action": {"kind": "gods", "pantheon": gods["pantheon"],
					"primary": gods["primary"], "secondary": gods["secondary"]}})
			waiting.emit(tr("The war begins when everyone has chosen their gods (%d of %d ready).") % [
				ready + (0 if mine.get("chosen", false) or not _gods_sent else 1), view.get("players", []).size()])
		"PLAYING", "OVER":
			if stage != Stage.PLAYING and stage != Stage.OVER:
				stage = Stage.PLAYING
				war_ready.emit()


func _names() -> Dictionary:
	var out := {}
	for s: Dictionary in seats:
		out[int(s.get("seat", -1))] = str(s.get("user", {}).get("display_name", ""))
	return out


# ---------- the server's state, as a MatchState ----------

## The realm of a view: rows of letters (a territory each) and '.' for sea.
static func realm_from(m: Dictionary) -> RealmMap:
	var r := RealmMap.new()
	r.grid = str(m.get("grid", RealmMap.GRID_SQUARE))
	r.size = int(m.get("size", 0))
	r.cell_territory.resize(r.size * r.size)
	r.cell_territory.fill(-1)
	var rows: Array = m.get("rows", [])
	var count := 0
	for row: String in rows:
		for ch in row:
			if ch != ".":
				count = maxi(count, ALPHABET.find(ch) + 1)
	var elevation: Array = m.get("elevation", [])
	for t in count:
		var terr := RealmMap.Territory.new()
		terr.id = t
		terr.elevation = int(elevation[t]) if t < elevation.size() else 0
		r.territories.append(terr)
	for y in mini(rows.size(), r.size):
		var row: String = rows[y]
		for x in mini(row.length(), r.size):
			if row[x] == ".":
				continue
			var t := ALPHABET.find(row[x])
			r.cell_territory[y * r.size + x] = t
			r.territories[t].cells.append(Vector2i(x, y))
	r.finish()
	return r


## Brings `s` to the server's public state `snap` (a view or the "state" event of an action).
static func apply_snapshot(s: MatchState, snap: Dictionary, names: Dictionary) -> void:
	var owners: Array = snap.get("owners", [])
	s.owners = PackedInt32Array(owners.map(func(v: Variant) -> int: return int(v)))
	var dice: Array = snap.get("dice", [])
	s.dice = PackedInt32Array(dice.map(func(v: Variant) -> int: return int(v)))
	var ps: Array = snap.get("players", [])
	while s.players.size() < ps.size():
		var np := MatchState.PlayerState.new()
		np.index = s.players.size()
		np.color_index = np.index
		s.players.append(np)
	for d: Dictionary in ps:
		var p: MatchState.PlayerState = s.players[int(d.get("seat", 0))]
		p.name = str(names.get(p.index, "")) if str(names.get(p.index, "")) != "" else "Player %d" % (p.index + 1)
		p.is_ai = false
		var gods_changed := false
		for key in ["pantheon", "primary", "secondary"]:
			if d.has(key) and str(d[key]) != str(p.get(key)):
				p.set(key, str(d[key]))
				gods_changed = true
		if bool(d.get("awake", false)) != p.secondary_awake:
			p.secondary_awake = bool(d.get("awake", false))
			gods_changed = true
		p.favor = int(d.get("favor", 0))
		p.reserve = int(d.get("reserve", 0))
		p.conquests = int(d.get("conquests", 0))
		p.head_start = int(d.get("head_start", 0))
		p.eliminated = bool(d.get("out", false))
		var used: Array[String] = []
		for g: Variant in d.get("miracles_used", []):
			used.append(str(g))
		p.miracles_used = used
		if gods_changed:
			s._refresh_effects(p)
	s.current = int(snap.get("current", 0))
	s.turn = int(snap.get("turn", 1))
	s.round_number = int(snap.get("round", 1))
	s.attacks_this_turn = int(snap.get("attacks_this_turn", 0))
	s.attacks_before_awakening = int(snap.get("attacks_before_awakening", 0))
	s.conquests_this_turn = int(snap.get("conquests_this_turn", 0))
	s.wards.clear()
	for w: Variant in snap.get("wards", []):
		var t := int(w[0])
		var owner := int(w[1])
		s.wards[t] = {"player": owner, "bonus": int(w[2]), "source": _ward_source(s, owner)}


## "Guanyin · Mercy": the god whose ward protects a player's territory.
static func _ward_source(s: MatchState, p: int) -> String:
	if p < 0 or p >= s.players.size():
		return "Ward"
	for id in [s.players[p].primary, s.players[p].secondary]:
		var g := GodCatalog.god(id)
		if str(g.get("boon", {}).get("miracle", {}).get("kind", "")) == "ward":
			return "%s · %s" % [g["name"], g["boon_name"]]
	return "Ward"


## JSON numbers are floats; the screens expect ints (and dictionaries keyed by territory).
static func _numbers(v: Variant) -> Variant:
	if v is float:
		return int(v)
	if v is Array:
		return (v as Array).map(func(x: Variant) -> Variant: return _numbers(x))
	if v is Dictionary:
		var out := {}
		for k: Variant in v:
			out[k] = _numbers(v[k])
		return out
	return v


static func _keyed(d: Variant) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for k: Variant in d:
			out[int(k)] = int(d[k])
	return out


## A battle in MatchState.attack's format.
static func _battle_result(r: Dictionary) -> Dictionary:
	var out: Dictionary = _numbers(r)
	out["gains"] = _keyed(r.get("gains", {}))
	out["losses"] = _keyed(r.get("losses", {}))
	for key in ["attack_rerolled", "defense_rerolled"]:
		out[key] = (r.get(key, []) as Array).map(func(x: Variant) -> bool: return bool(x))
	out["won"] = bool(r.get("won", false))
	out["awakened"] = bool(r.get("awakened", false))
	return out


## The end of a turn in MatchState.end_turn's format.
static func _turn_result(r: Dictionary) -> Dictionary:
	var out: Dictionary = _numbers(r)
	out["placed"] = _keyed(r.get("placed", {}))
	out["tribute"] = _keyed(r.get("tribute", {}))
	return out
