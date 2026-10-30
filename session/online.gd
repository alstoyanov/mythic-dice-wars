extends Node
## The player's Mytholore account (autoload "Online"), used for online wars. Everything else plays
## offline without it. Talks to the Mytholore Game Server over HTTPS (REST) and keeps the login in
## user://online.cfg: the refresh token, never the password. (The same server and account as Chasm of
## Knights and Tile Shifter.)
##
## Every call that talks to the server is a coroutine: `var r := await Online.api("GET", "/api/v1/me")`.
## Results are {"status": int, "data": Dictionary}; status 0 means the server could not be reached.

## Emitted after logging in or out (also when the server ended the session).
signal account_changed
signal _refresh_done

const GAME_ID := "mythic-dice-wars"
const CLIENT_VERSION := "1.0.0"  ## Sent as X-Client-Version; the server can require a minimum.
const MATCH_PROTOCOL := 1  ## The online match messages this build speaks.
const CONFIG_PATH := "user://online.cfg"
const DEFAULT_SERVER := "https://games.mytholore.com"  ## Another (a local development server) can be set on the account screen.
const TIMEOUT := 15.0
## HTTPRequest.Result values in words, for error messages.
const RESULT_NAMES := {
	HTTPRequest.RESULT_CANT_CONNECT: "cannot connect",
	HTTPRequest.RESULT_CANT_RESOLVE: "unknown host name",
	HTTPRequest.RESULT_CONNECTION_ERROR: "connection error",
	HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: "secure connection (https) failed",
	HTTPRequest.RESULT_NO_RESPONSE: "no response",
	HTTPRequest.RESULT_REQUEST_FAILED: "request failed",
	HTTPRequest.RESULT_TIMEOUT: "timed out",
}

var server_url: String = DEFAULT_SERVER
var config_path: String = CONFIG_PATH  ## Where the login is kept (tests use another file).
var user_id: String = ""
var display_name: String = ""
var email: String = ""
var email_verified: bool = true  ## false: a password account whose address is not confirmed yet

var _refresh_token := ""
var _access_token := ""
var _access_until := 0.0  # unix seconds
var _refreshing := false


func _ready() -> void:
	# --online-profile=NAME (after "--" on the command line): this window keeps its login in a file of
	# its own, so two game windows on one computer can be logged in as two different accounts.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--online-profile="):
			config_path = "user://online_%s.cfg" % arg.substr(17).validate_filename()
	_load()
	if is_logged_in():
		_check_session()


## Logged in on this device (the session may still turn out to be ended when the server is asked).
func is_logged_in() -> bool:
	return _refresh_token != ""


## The X-Client-Id platform part for this build.
func platform() -> String:
	if OS.has_feature("web"):
		return "web"
	match OS.get_name():
		"Android":
			return "android"
		"macOS":
			return "macos"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return "linux"
	return "windows"


## ws:// or wss:// URL of a server path.
func ws_url(path: String) -> String:
	var base := server_url
	if base.begins_with("https://"):
		base = "wss://" + base.substr(8)
	elif base.begins_with("http://"):
		base = "ws://" + base.substr(7)
	return base + path


## A page of the server's website (account pages), for OS.shell_open.
func web_url(path: String) -> String:
	return server_url + path


func set_server(url: String) -> void:
	url = url.strip_edges().trim_suffix("/")
	if url == "" or url == server_url:
		return
	if not (url.begins_with("http://") or url.begins_with("https://")):
		# No scheme typed: a local server (an IP address, localhost or a port) speaks plain http,
		# a real domain https.
		var host := url.get_slice("/", 0)
		var local := host.get_slice(":", 0).is_valid_ip_address() or host.begins_with("localhost") or host.contains(":")
		url = ("http://" if local else "https://") + url
	if is_logged_in():
		_clear_session()  # a login belongs to one server
	server_url = url
	_save()
	account_changed.emit()


# ---------- account ----------

## Logs in with email and password. Returns {"ok": bool, "message": String}.
func login(p_email: String, password: String) -> Dictionary:
	var r := await _http("POST", "/api/v1/auth/login",
		{"email": p_email.strip_edges(), "password": password, "device_name": _device_name()}, false)
	if r["status"] == 200:
		_take_tokens(r["data"])
		account_changed.emit()
		return {"ok": true, "message": ""}
	return {"ok": false, "message": error_text(r)}


## Signing in through the website, with Google or a password there (no password typed into the game):
## the server hands out a code and a page; the player opens the page, logs in and confirms the code,
## while the game asks every few seconds (poll_web_sign_in) whether it is signed in. Returns
## {ok, message} and, when ok, the server's {device_code, user_code, verification_uri_complete,
## interval, expires_in}.
func start_web_sign_in() -> Dictionary:
	var r := await _http("POST", "/api/v1/auth/device", {"device_name": _device_label()}, false)
	if r["status"] != 200:
		return {"ok": false, "message": error_text(r)}
	var out: Dictionary = r["data"]
	out["ok"] = true
	return out


## "pending" (not confirmed yet, or the network hiccuped), "done" (logged in now) or "gone" (refused,
## expired or the server forgot it: start again).
func poll_web_sign_in(device_code: String) -> String:
	var r := await _http("POST", "/api/v1/auth/device/token", {"device_code": device_code}, false)
	match int(r["status"]):
		200:
			_take_tokens(r["data"])
			account_changed.emit()
			return "done"
		410:
			return "gone"
	return "pending"


## Updates the name and the email confirmation from the server (the account screen shows them).
func refresh_profile() -> void:
	var r := await api("GET", "/api/v1/me")
	if r["status"] == 200:
		var before := [user_id, display_name, email, email_verified]
		_take_user(r["data"])
		_save()
		if before != [user_id, display_name, email, email_verified]:
			account_changed.emit()


## Sends the email confirmation link again. {ok, message}.
func resend_confirmation() -> Dictionary:
	var r := await api("POST", "/api/v1/auth/email/resend")
	if r["status"] >= 200 and r["status"] < 300:
		return {"ok": true, "message": ""}
	return {"ok": false, "message": error_text(r)}


## Ends the session on the server (if it can be reached) and forgets it here.
func logout() -> void:
	var token := _refresh_token
	_clear_session()
	account_changed.emit()
	if token != "":
		await _http("POST", "/api/v1/auth/logout", {"refresh_token": token}, false)


## An authenticated API call; refreshes the access token when needed. `headers`: extra ones
## ("If-Match: \"3\"").
func api(method: String, path: String, body: Variant = null, headers: PackedStringArray = []) -> Dictionary:
	if not is_logged_in():
		return {"status": 401, "data": {"title": "Not logged in"}}
	if not await _ensure_access():
		return {"status": 401 if not is_logged_in() else 0, "data": {}}
	var r := await _http(method, path, body, true, headers)
	if r["status"] == 401 and await _refresh():
		r = await _http(method, path, body, true, headers)
	return r


# ---------- friends (shared by every game) and open games (rooms) ----------

## {friend_code, friends: [{user_id, display_name, since}], incoming: […], outgoing: […]} in "data".
func friends() -> Dictionary:
	return await api("GET", "/api/v1/me/friends")


## By friend code, or by user id (a player met in a match). "data": {status: PENDING | ACCEPTED, user}.
func add_friend(code: String, user_id: String = "") -> Dictionary:
	return await api("POST", "/api/v1/me/friends", {"user_id": user_id} if user_id != "" else {"friend_code": code})


func accept_friend(user_id: String) -> Dictionary:
	return await api("POST", "/api/v1/me/friends/%s/accept" % user_id)


## Removes a friend, declines a request or takes one back.
func remove_friend(user_id: String) -> Dictionary:
	return await api("DELETE", "/api/v1/me/friends/%s" % user_id)


## The open games this player may join: "data": {items: [room…]} (see open_game()).
func open_games() -> Dictionary:
	return await api("GET", "/api/v1/games/%s/rooms" % GAME_ID)


## Opens a war: `mode` "room" (rated), "room-friendly" or "room-async" (a day per turn); `settings`
## {players (2-6), size, grid, turn_order, awakening}; `visibility`: "public" (anyone sees it), "friends"
## or "private" (joined with its code only). "data": {room_code, status, visibility, host, settings,
## seats, seats_taken, …}.
func open_game(mode: String, settings: Dictionary, visibility: String) -> Dictionary:
	return await api("POST", "/api/v1/games/%s/rooms" % GAME_ID, {"mode": mode, "protocol": MATCH_PROTOCOL,
		"visibility": visibility, "settings": settings})


## Joins a game by its code; once it is full "data" has status STARTED and the match_id.
func join_game(code: String) -> Dictionary:
	return await api("POST", "/api/v1/games/%s/rooms/%s/join" % [GAME_ID, code.strip_edges().to_upper()])


## A war this player opened or joined: status WAITING until it is full, then STARTED with the match_id.
func game_room(code: String) -> Dictionary:
	return await api("GET", "/api/v1/games/%s/rooms/%s" % [GAME_ID, code])


## Closes the host's own war, or leaves one joined (before it starts).
func close_game(code: String) -> Dictionary:
	return await api("DELETE", "/api/v1/games/%s/rooms/%s" % [GAME_ID, code])


## A short message for a failed call, for the player.
func error_text(r: Dictionary) -> String:
	if r["status"] == 0:
		# The technical reason and the address help to find the cause (firewall, wrong address, https).
		return tr("Cannot reach the server. Check your connection.") + "
%s (%s)" % [server_url, str(r.get("reason", ""))]
	var data: Dictionary = r["data"]
	match str(data.get("code", "")):
		"invalid_credentials":
			return tr("Wrong email or password.")
		"too_many_attempts", "rate_limited":
			return tr("Too many attempts. Please wait a moment.")
		"client_outdated":
			return tr("This version of the game is too old for online play. Please update it.")
		"maintenance", "draining":
			return tr("The server is under maintenance. Please try again later.")
		"account_banned":
			return tr("This account is banned from online play.")
		"unknown_friend_code":
			return tr("There is no player with this friend code.")
		"own_friend_code":
			return tr("That is your own friend code.")
		"too_many_friends":
			return tr("You have too many friends and requests.")
		"already_in_match":
			return tr("You are already in a match.")
	var detail := str(data.get("detail", ""))
	return detail if detail != "" else str(data.get("title", tr("Something went wrong.")))


# ---------- tokens ----------

func _check_session() -> void:
	if await _ensure_access():
		var r := await _http("GET", "/api/v1/me", null, true)
		if r["status"] == 200:
			user_id = str(r["data"].get("id", user_id))
			display_name = str(r["data"].get("display_name", display_name))
			email = str(r["data"].get("email", email))
			_save()
			account_changed.emit()


func _ensure_access() -> bool:
	if _access_token != "" and Time.get_unix_time_from_system() < _access_until - 30.0:
		return true
	return await _refresh()


## Swaps the refresh token for a new pair. One refresh at a time: the server treats a reused
## refresh token as stolen.
func _refresh() -> bool:
	if _refreshing:
		await _refresh_done
		return _access_token != ""
	_refreshing = true
	# Another copy of the game on this computer (same login file) may have refreshed already: the server
	# replaced that token, and sending the old one again would end the session as a stolen token.
	if not _adopt_stored_session():
		_refreshing = false
		_refresh_done.emit()
		return false
	var r := await _http("POST", "/api/v1/auth/refresh", {"refresh_token": _refresh_token}, false)
	_refreshing = false
	if r["status"] == 200:
		_take_tokens(r["data"])
	elif r["status"] == 401 or r["status"] == 403:
		_clear_session()  # ended on the server (logged out elsewhere, expired, banned)
		account_changed.emit()
	_refresh_done.emit()
	return r["status"] == 200


## Takes over a newer refresh token of the same account from the login file (written by another copy
## of the game that refreshed or logged out). Returns false if the session ended there.
func _adopt_stored_session() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(config_path) != OK:
		return true
	var stored := str(cfg.get_value("session", "refresh_token", ""))
	var stored_email := str(cfg.get_value("session", "email", ""))
	if stored == _refresh_token or (stored_email != email and stored != ""):
		return true  # nothing new, or another account's login: keep ours
	if stored == "":  # logged out (or the session was ended) in the other copy
		_clear_session()
		account_changed.emit()
		return false
	_refresh_token = stored
	return true


func _take_tokens(data: Dictionary) -> void:
	_access_token = str(data.get("access_token", ""))
	_access_until = Time.get_unix_time_from_system() + float(data.get("expires_in", 900))
	var rt := str(data.get("refresh_token", ""))
	if rt != "":
		_refresh_token = rt
	var user: Variant = data.get("user", null)
	if user is Dictionary:
		_take_user(user)
	_save()


func _take_user(user: Dictionary) -> void:
	user_id = str(user.get("id", user_id))
	display_name = str(user.get("display_name", display_name))
	email = str(user.get("email", "")) if user.get("email", null) != null else ""
	email_verified = bool(user.get("email_verified", email_verified))


func _clear_session() -> void:
	_refresh_token = ""
	_access_token = ""
	_access_until = 0.0
	user_id = ""
	display_name = ""
	email = ""
	_save()


func _device_name() -> String:
	return "Mythic Dice Wars (%s)" % OS.get_name()


## The device as the website's confirmation page names it: "Pixel 9", "Windows", "a web browser".
func _device_label() -> String:
	if OS.has_feature("web"):
		return "a web browser"
	var model := OS.get_model_name()
	return model if model != "" and model != "GenericDevice" else OS.get_name()


# ---------- HTTP ----------

func _http(method: String, path: String, body: Variant, with_auth: bool, extra: PackedStringArray = []) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = TIMEOUT
	add_child(req)
	var headers := PackedStringArray([
		"Accept: application/json",
		"X-Client-Id: %s.%s" % [GAME_ID, platform()],
		"X-Client-Version: " + CLIENT_VERSION,
	])
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if with_auth:
		headers.append("Authorization: Bearer " + _access_token)
	headers.append_array(extra)
	var methods := {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PUT": HTTPClient.METHOD_PUT,
		"PATCH": HTTPClient.METHOD_PATCH, "DELETE": HTTPClient.METHOD_DELETE}
	var err := req.request(server_url + path, headers, methods.get(method, HTTPClient.METHOD_GET), payload)
	if err != OK:
		req.queue_free()
		push_warning("Online: %s %s%s could not start: %s" % [method, server_url, path, error_string(err)])
		return {"status": 0, "data": {}, "reason": error_string(err)}
	var res: Array = await req.request_completed
	req.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS:
		var reason: String = RESULT_NAMES.get(res[0], "error %d" % res[0])
		push_warning("Online: %s %s%s failed: %s" % [method, server_url, path, reason])
		return {"status": 0, "data": {}, "reason": reason}
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text) if text.strip_edges().begins_with("{") else null  # 204: no body
	return {"status": int(res[1]), "data": parsed if parsed is Dictionary else {}}


# ---------- storage ----------

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(config_path) != OK:
		return
	server_url = str(cfg.get_value("server", "url", server_url))
	_refresh_token = str(cfg.get_value("session", "refresh_token", ""))
	user_id = str(cfg.get_value("session", "user_id", ""))
	display_name = str(cfg.get_value("session", "display_name", ""))
	email = str(cfg.get_value("session", "email", ""))
	email_verified = bool(cfg.get_value("session", "email_verified", true))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("server", "url", server_url)
	cfg.set_value("session", "refresh_token", _refresh_token)
	cfg.set_value("session", "user_id", user_id)
	cfg.set_value("session", "display_name", display_name)
	cfg.set_value("session", "email", email)
	cfg.set_value("session", "email_verified", email_verified)
	cfg.save(config_path)
