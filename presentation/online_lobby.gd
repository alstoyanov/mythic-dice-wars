extends Control
## Online wars (the lobby), on the Mytholore Game Server:
##  * the pantheon and gods the player brings to their next war (every player picks their own);
##  * quick wars against random players: a ranked duel, or a ranked war of four;
##  * the wars other players have opened (2 to 6 players), joining one by its code, and opening one's
##    own: how many players, rated / friendly / long-running (a day per turn), the realm, who may join;
##  * wars in progress (after closing the game, or long-running ones) to return to.
## Once a war has all its players, the game screen plays it (GameSettings.online_match_id).

const POLL_SECONDS := 2.0  ## a room or a search: how often to ask whether the war has started
const REFRESH_SECONDS := 6.0  ## the list of open wars
const VISIBILITIES := ["public", "friends", "private"]
const KIND_NAMES := {"room": "Rated", "room-friendly": "Friendly", "room-async": "Long-running"}
const SIZE_NAMES := {"small": "Small realm", "medium": "Medium realm", "large": "Large realm"}
const SCENE := "res://presentation/online_lobby.tscn"

enum Mode { LIST, CREATE, WAITING, SEARCHING }

var _backdrop: MenuBackdrop
var _mode := Mode.LIST
var _list: VBoxContainer  ## the open wars
var _active_box: VBoxContainer  ## wars in progress to return to
var _status: Label
var _code_edit: LineEdit
var _room := {}  ## the war this player opened or joined, while it fills up
var _ticket := {}  ## a search for a quick war: {ticket_id, mode, since}
var _wait_label: Label
var _wait := 0.0
var _dots := 0
var _busy := false
var _leaving := false  ## off to the war: the room is not left on the way out
var _picks := {}  ## the "open a war" choices: name -> OptionButton


func _ready() -> void:
	GameSettings.ensure_loaded()
	_backdrop = Ui.setup_screen(self)
	if not Online.is_logged_in():
		get_tree().change_scene_to_file.call_deferred("res://presentation/account.tscn")
		return
	_show_list()


func _exit_tree() -> void:
	if _leaving:
		return
	if _mode == Mode.WAITING and _room.has("room_code"):
		Online.close_game(str(_room["room_code"]))
	if _mode == Mode.SEARCHING and _ticket.has("ticket_id"):
		Online.api("DELETE", "/api/v1/games/%s/matches/queue/%s" % [Online.GAME_ID, _ticket["ticket_id"]])


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or _busy:
		return
	match _mode:
		Mode.LIST:
			_wait = REFRESH_SECONDS
			_refresh()
		Mode.WAITING:
			_wait = POLL_SECONDS
			_dots = (_dots + 1) % 4
			_poll_room()
		Mode.SEARCHING:
			_wait = POLL_SECONDS
			_dots = (_dots + 1) % 4
			_poll_search()


func _clear() -> void:
	for child in get_children():
		if child != _backdrop:
			child.queue_free()
	_list = null
	_active_box = null
	_wait_label = null
	_status = null


func _say(text: String, error: bool = false) -> void:
	if _status != null and is_instance_valid(_status):
		_status.text = text
		_status.modulate = Color("ffb0a0") if error else Color(1, 1, 1, 0.8)


func _text(col: Control, text: String, font_size: int = 16, alpha: float = 1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.modulate = Color(1, 1, 1, alpha)
	col.add_child(l)
	Ui.scaled_font(l, font_size)
	Ui.on_resize(l, func() -> void: l.custom_minimum_size.x = minf(620.0 * UiTheme.ui_scale(), Ui.panel_content_width()))
	return l


# ---------- the lobby ----------

func _show_list() -> void:
	_mode = Mode.LIST
	_clear()
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "Online wars")
	_gods_picker(col)

	_active_box = VBoxContainer.new()
	_active_box.add_theme_constant_override("separation", 6)
	col.add_child(_active_box)

	_text(col, "Quick war against random players (rated)", 14, 0.75)
	var quick := Ui.flip_row(col, 12, 8)
	Ui.button(quick, "Ranked duel", func() -> void: _search("ranked-duel"))
	Ui.button(quick, "Ranked war of four", func() -> void: _search("ranked-four"))

	_text(col, "Open wars: join one, or open your own for 2 to 6 players", 14, 0.75)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	Ui.on_resize(scroll, func() -> void:
		scroll.custom_minimum_size = Vector2(minf(620.0 * UiTheme.ui_scale(), Ui.panel_content_width()), clampf(Ui.usable_size().y * 0.22, 90.0, 260.0)))
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_text(_list, "Looking for open wars…", 15, 0.7)

	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	join_row.add_theme_constant_override("separation", 10)
	col.add_child(join_row)
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "War code"
	_code_edit.max_length = 8
	_code_edit.custom_minimum_size = Vector2(160, 44)
	_code_edit.text_submitted.connect(func(t: String) -> void: _join(t))
	join_row.add_child(_code_edit)
	var join := Button.new()
	join.text = "Join"
	join.custom_minimum_size = Vector2(90, 44)
	join.pressed.connect(func() -> void: _join(_code_edit.text))
	Ui.hover_effect(join)
	join_row.add_child(join)

	_status = _text(col, "", 15)
	var buttons := Ui.flip_row(col, 12, 8)
	Ui.button(buttons, "Open a war", _show_create)
	Ui.button(buttons, "Rankings", func() -> void:
		OS.shell_open(Online.web_url("/account/leaderboards/%s/points" % Online.GAME_ID)))
	Ui.button(buttons, "Account", func() -> void: get_tree().change_scene_to_file("res://presentation/account.tscn"))

	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(back_row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	back_row.add_child(back)
	_wait = 0.0
	_load_active()


## The pantheon and the two gods the player brings: chosen here, sent to the server when a war begins.
func _gods_picker(col: Control) -> void:
	_text(col, "Your pantheon and gods for the next war", 14, 0.75)
	var row := Ui.flip_row(col, 8, 6)
	var pan := OptionButton.new()
	var prim := OptionButton.new()
	var sec := OptionButton.new()
	for p in GodCatalog.PANTHEONS:
		pan.add_item(p["name"])
	pan.select(maxi(0, GodCatalog.PANTHEONS.map(func(p: Dictionary) -> String: return p["id"]).find(GameSettings.pantheon)))
	var fill := func() -> void:
		for pair in [[prim, GodCatalog.PRIMARY, GameSettings.primary], [sec, GodCatalog.SECONDARY, GameSettings.secondary]]:
			var pick: OptionButton = pair[0]
			pick.clear()
			var gods := GodCatalog.gods_of(GameSettings.pantheon, pair[1])
			for i in gods.size():
				var g: Dictionary = gods[i]
				pick.add_item("%s (%s)" % [g["name"], g["boon_name"]])
				pick.set_item_tooltip(i, g["boon_text"] + (("\n" + g["bane_name"] + ": " + g["bane_text"]) if g.has("bane_name") else ""))
				if g["id"] == pair[2]:
					pick.select(i)
	fill.call()
	pan.item_selected.connect(func(i: int) -> void:
		GameSettings.set_pantheon(GodCatalog.PANTHEONS[i]["id"])
		GameSettings.save()
		Ui.retheme(self, _backdrop)
		fill.call())
	prim.item_selected.connect(func(i: int) -> void:
		GameSettings.primary = GodCatalog.gods_of(GameSettings.pantheon, GodCatalog.PRIMARY)[i]["id"]
		GameSettings.save())
	sec.item_selected.connect(func(i: int) -> void:
		GameSettings.secondary = GodCatalog.gods_of(GameSettings.pantheon, GodCatalog.SECONDARY)[i]["id"]
		GameSettings.save())
	for b in [pan, prim, sec]:
		row.add_child(b)
	var book := IconButton.new(IconButton.Icon.BOOK, false, "Book of the Gods: every god's powers and story")
	book.pressed.connect(func() -> void: GodBook.open(get_tree(), SCENE))
	row.add_child(book)


## Wars in progress of this game: back into a real-time one, or into a long-running one.
func _load_active() -> void:
	var r: Dictionary = await Online.api("GET", "/api/v1/me/matches/active")
	if _mode != Mode.LIST or _active_box == null or not is_instance_valid(_active_box) or r["status"] != 200:
		return
	for item: Dictionary in r["data"].get("items", []):
		if str(item.get("game_id", "")) != Online.GAME_ID:
			continue
		var names: Array[String] = []
		for o: Dictionary in item.get("opponents", []):
			names.append(str(o.get("display_name", "")))
		var text := ("Your long-running war against %s%s" if item.get("async", false) else "Your war against %s%s") % [
			", ".join(names), " — your turn!" if item.get("to_act_me", false) else ""]
		var b := Ui.button(_active_box, text, _start_war.bind(str(item["match_id"])))
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _refresh() -> void:
	_busy = true
	var r: Dictionary = await Online.open_games()
	_busy = false
	if _mode != Mode.LIST or _list == null or not is_instance_valid(_list):
		return
	for child in _list.get_children():
		child.queue_free()
	if r["status"] != 200:
		_text(_list, Online.error_text(r), 15, 0.8)
		return
	var items: Array = r["data"].get("items", [])
	if items.is_empty():
		_text(_list, "No open wars right now. Open one, and others can join it.", 15, 0.7)
	for item: Dictionary in items:
		_list.add_child(_war_row(item))


func _war_row(item: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", roundi(15 * UiTheme.ui_scale()))
	var host := str(item.get("host", {}).get("display_name", ""))
	var who := "Your war" if item.get("mine", false) else (("★ " if item.get("friend", false) else "") + host)
	text.text = "%s — %d of %d players\n%s" % [who, int(item.get("seats_taken", 1)), int(item.get("seats", 2)),
		settings_text(str(item.get("mode", "")), item.get("settings", {}))]
	row.add_child(text)
	var code := str(item.get("room_code", ""))
	var b := Button.new()
	b.custom_minimum_size = Vector2(90, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if item.get("mine", false):  # opened on another device, or left behind: it can be closed
		b.text = "Close"
		b.pressed.connect(func() -> void:
			await Online.close_game(code)
			_wait = 0.0)
	else:
		b.text = "Join"
		b.pressed.connect(func() -> void: _join(code))
	Ui.hover_effect(b)
	row.add_child(b)
	return row


## "Rated · Medium realm, hexagons · balanced turn order": a war's settings, for the player.
static func settings_text(mode: String, s: Dictionary) -> String:
	var parts: Array[String] = [KIND_NAMES.get(mode, "Rated"), "%s, %s" % [SIZE_NAMES.get(str(s.get("size", "medium")), "Medium realm"),
		"hexagons" if str(s.get("grid", "")) == "hex" else "squares"]]
	if str(s.get("turn_order", "balanced")) == "classic":
		parts.append("classic turn order")
	if str(s.get("awakening", "milestone")) == "start":
		parts.append("both gods awake")
	return " · ".join(parts)


func _join(code: String) -> void:
	code = code.strip_edges().to_upper()
	if code == "" or _busy:
		return
	_busy = true
	_say("Joining…")
	var r: Dictionary = await Online.join_game(code)
	_busy = false
	if r["status"] != 200:
		_say("There is no open war with this code." if r["status"] == 404 else Online.error_text(r), true)
		_wait = 0.0
		return
	_room = r["data"]
	if str(_room.get("status", "")) == "STARTED" and _room.get("match_id", null) != null:
		_start_war(str(_room["match_id"]))
	else:
		_show_waiting()


func _start_war(match_id: String) -> void:
	_leaving = true
	GameSettings.online_match_id = match_id
	get_tree().change_scene_to_file("res://presentation/game_screen.tscn")


# ---------- opening a war ----------

func _show_create() -> void:
	_mode = Mode.CREATE
	_clear()
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "Open a war")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	_picks.clear()
	_pick(grid, "players", "Players", range(2, 7).map(func(n: int) -> String: return "%d" % n), GameSettings.online_players - 2)
	_pick(grid, "kind", "Kind", ["Rated (rating and ranking points)", "Friendly (not rated)", "Long-running (a day per turn, rated)"],
		GameSettings.ONLINE_KINDS.find(GameSettings.online_kind))
	var sizes: Array = MapGenerator.SIZES.keys()
	_pick(grid, "size", "Realm size", sizes.map(func(k: String) -> String: return "%s (%d territories)" % [k.capitalize(), MapGenerator.SIZES[k]]),
		sizes.find(GameSettings.online_size))
	_pick(grid, "grid", "Board", ["Isometric squares", "Hexagons"], 1 if GameSettings.online_grid == RealmMap.GRID_HEX else 0)
	_pick(grid, "turn_order", "Turn order", ["Balanced (head start)", "Classic"], 0 if GameSettings.head_start else 1)
	_pick(grid, "awakening", "Secondary god", ["Wakes after %d conquests" % MatchState.AWAKEN_CONQUESTS, "Awake from the start"],
		0 if GameSettings.awakening == "milestone" else 1)
	_pick(grid, "visibility", "Who can join", ["Anyone", "Friends", "Only with the code"], VISIBILITIES.find(GameSettings.online_visibility))
	_status = _text(col, "Every player brings their own pantheon and gods. Fog of war is for wars against the computer.", 14, 0.65)
	Ui.start_back_row(col, _create, _show_list)


func _pick(grid: GridContainer, key: String, label_text: String, items: Array, selected: int) -> void:
	var l := Label.new()
	l.text = label_text
	grid.add_child(l)
	var pick := OptionButton.new()
	for item in items:
		pick.add_item(str(item))
	pick.selected = maxi(0, selected)
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.item_selected.connect(func(_i: int) -> void: Sound.play("toggle"))
	grid.add_child(pick)
	_picks[key] = pick


func _create() -> void:
	if _busy:
		return
	var sizes: Array = MapGenerator.SIZES.keys()
	GameSettings.online_players = _picks["players"].selected + 2
	GameSettings.online_kind = GameSettings.ONLINE_KINDS[_picks["kind"].selected]
	GameSettings.online_size = sizes[_picks["size"].selected]
	GameSettings.online_grid = RealmMap.GRID_HEX if _picks["grid"].selected == 1 else RealmMap.GRID_SQUARE
	GameSettings.online_visibility = VISIBILITIES[_picks["visibility"].selected]
	GameSettings.save()
	var settings := {"players": GameSettings.online_players, "size": GameSettings.online_size, "grid": GameSettings.online_grid,
		"turn_order": "classic" if _picks["turn_order"].selected == 1 else "balanced",
		"awakening": "start" if _picks["awakening"].selected == 1 else "milestone"}
	_busy = true
	_say("Opening your war…")
	var r: Dictionary = await Online.open_game(GameSettings.online_kind, settings, GameSettings.online_visibility)
	_busy = false
	if r["status"] != 201:
		_say(Online.error_text(r), true)
		return
	_room = r["data"]
	_show_waiting()


# ---------- waiting for the war to fill ----------

func _show_waiting() -> void:
	_mode = Mode.WAITING
	_clear()
	var col := Ui.centered_column(self, 12)
	var mine := str(_room.get("host", {}).get("user_id", "")) == Online.user_id
	Ui.title(col, "Your war is open" if mine else "You joined a war")
	_text(col, settings_text(str(_room.get("mode", "")), _room.get("settings", {})), 16, 0.85)
	_text(col, "War code", 14, 0.7)
	var code := str(_room.get("room_code", ""))
	var code_label := _text(col, code, 40)
	code_label.add_theme_color_override("font_color", Color("ffd98a"))
	var copy := Ui.button(col, "Copy the code", func() -> void:
		DisplayServer.clipboard_set(code)
		_say("The code is copied."))
	copy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if mine:
		_text(col, _visibility_text(str(_room.get("visibility", "private"))), 15, 0.8)
	_wait_label = _text(col, _players_text(), 20)
	_status = _text(col, "", 14)
	var leave := Ui.button(col, "Close the war" if mine else "Leave", func() -> void:
		_mode = Mode.LIST  # so that leaving does not close it twice
		await Online.close_game(code)
		_room = {}
		_show_list())
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_wait = POLL_SECONDS


func _players_text() -> String:
	return "%d of %d players are here — waiting for the others%s" % [int(_room.get("seats_taken", 1)), int(_room.get("seats", 2)), ".".repeat(_dots)]


func _visibility_text(visibility: String) -> String:
	match visibility:
		"public":
			return "Every player sees your war in the open wars and can join it."
		"friends":
			return "Your friends see your war in their open wars. Others can join with its code."
	return "Nobody sees your war in the list: give its code to the players you want."


func _poll_room() -> void:
	_busy = true
	var r: Dictionary = await Online.game_room(str(_room.get("room_code", "")))
	_busy = false
	if _mode != Mode.WAITING:
		return
	if r["status"] == 200:
		_room = r["data"]
		if _wait_label != null and is_instance_valid(_wait_label):
			_wait_label.text = _players_text()
		if str(_room.get("status", "")) == "STARTED" and _room.get("match_id", null) != null:
			_start_war(str(_room["match_id"]))
	elif r["status"] == 404:  # expired (30 minutes), closed by its host, or the server restarted
		_mode = Mode.LIST
		_room = {}
		_show_list()
		_say("The war was closed before it filled up.", true)


# ---------- quick wars ----------

func _search(mode: String) -> void:
	if _busy:
		return
	_busy = true
	_say("Looking for players…")
	var r: Dictionary = await Online.api("POST", "/api/v1/games/%s/matches/join" % Online.GAME_ID, {"mode": mode, "protocol": Online.MATCH_PROTOCOL})
	_busy = false
	if r["status"] == 409 and str(r["data"].get("code", "")) == "already_in_match":
		_say("You are already in a war: return to it above.", true)
		_load_active()
		return
	if r["status"] != 202:
		_say(Online.error_text(r), true)
		return
	_ticket = r["data"]
	_ticket["mode"] = mode
	_ticket["since"] = Time.get_unix_time_from_system()
	if str(_ticket.get("status", "")) == "MATCHED" and _ticket.get("match_id", null) != null:
		_start_war(str(_ticket["match_id"]))
		return
	_mode = Mode.SEARCHING
	_clear()
	var col := Ui.centered_column(self, 14)
	Ui.title(col, "Ranked duel" if mode == "ranked-duel" else "Ranked war of four")
	_text(col, "Looking for players of about your rating. The longer it takes, the wider the search.", 15, 0.8)
	_wait_label = _text(col, "Searching", 20)
	_status = _text(col, "", 14)
	var cancel := Ui.button(col, "Cancel", func() -> void:
		_mode = Mode.LIST
		await Online.api("DELETE", "/api/v1/games/%s/matches/queue/%s" % [Online.GAME_ID, _ticket.get("ticket_id", "")])
		_ticket = {}
		_show_list())
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_wait = POLL_SECONDS


func _poll_search() -> void:
	_busy = true
	var r: Dictionary = await Online.api("GET", "/api/v1/games/%s/matches/queue/%s" % [Online.GAME_ID, _ticket.get("ticket_id", "")])
	_busy = false
	if _mode != Mode.SEARCHING:
		return
	var waited := int(Time.get_unix_time_from_system() - float(_ticket.get("since", 0.0)))
	if _wait_label != null and is_instance_valid(_wait_label):
		_wait_label.text = "Searching%s  (%d:%02d)" % [".".repeat(_dots), waited / 60, waited % 60]
	if r["status"] == 200:
		match str(r["data"].get("status", "")):
			"MATCHED":
				_start_war(str(r["data"]["match_id"]))
			"CANCELLED":
				_mode = Mode.LIST
				_show_list()
				_say("The search was cancelled.", true)
	elif r["status"] == 404:  # the search ran out (10 minutes)
		_mode = Mode.LIST
		_show_list()
		_say("Nobody was found in time. Try again, or open a war.", true)
