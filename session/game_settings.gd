class_name GameSettings
extends RefCounted
## The player's preferences and the choices of the New War screens, kept in user://settings.cfg.

const SETTINGS_PATH := "user://settings.cfg"
const ANIM_SPEEDS := [1.0, 2.0, 6.0]  ## Normal, Fast, Very fast: divides every battle animation.
const ANIM_NAMES := ["Normal", "Fast", "Very fast"]

static var _loaded := false
static var sfx_enabled: bool = true
static var sfx_volume: float = 0.8  ## 0..1
static var fullscreen: bool = false  ## Window mode; applied by the AppWindow autoload.
static var anim_speed: int = 0  ## index into ANIM_SPEEDS (the computer's turns always run at least Fast)
static var show_counts: bool = true  ## a number beside every stack of dice
## How long a battle's result stays on screen: seconds, or WAIT (until the player presses Continue).
const WAIT := -1.0
const HOLDS := [0.8, 1.8, 3.5, WAIT]
const HOLD_NAMES := ["Brief", "Normal", "Long", "Until I press Continue"]
static var battle_hold: int = 1  ## index into HOLDS, for the battles shown on the battle screen
## The computer's attacks (on the player or on each other) on the battle screen too; else only on the map:
## the arrow for MAP_BATTLE seconds, then the outcome.
static var show_ai_battles: bool = false
const MAP_BATTLE := 1.0

# The last New War choices (also the look of the menus: the realm of the chosen pantheon).
static var pantheon: String = "greek"
static var primary: String = "zeus"
static var secondary: String = "ares"
static var players: int = 4  ## 2..8, the player included
static var map_size: String = "medium"  ## see MapGenerator.SIZES
static var grid: String = "square"  ## the board's cells: RealmMap.GRID_SQUARE or GRID_HEX
static var ai_level: int = 1  ## see AiPlayer.LEVEL_NAMES
static var awakening: String = "milestone"  ## when secondary gods wake: "milestone" or "start"
static var head_start: bool = true  ## later players get a head start against the first-mover advantage
static var fog: bool = false  ## fog of war: everyone sees only their own territories and their neighbours

## Online: the war the online lobby sends the game screen to (not saved; "" = a local war).
static var online_match_id: String = ""
# The last choices for an online war the player opens (the online lobby).
const ONLINE_KINDS := ["room", "room-friendly", "room-async"]  ## rated, friendly, long-running (a day per turn)
static var online_players: int = 4  ## 2..6
static var online_size: String = "medium"
static var online_grid: String = "square"
static var online_kind: String = "room"
static var online_visibility: String = "public"  ## public | friends | private


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	sfx_enabled = bool(cfg.get_value("audio", "sfx_enabled", sfx_enabled))
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	anim_speed = clampi(int(cfg.get_value("display", "anim_speed", anim_speed)), 0, ANIM_SPEEDS.size() - 1)
	show_counts = bool(cfg.get_value("display", "show_counts", show_counts))
	battle_hold = clampi(int(cfg.get_value("display", "battle_hold", battle_hold)), 0, HOLDS.size() - 1)
	show_ai_battles = bool(cfg.get_value("display", "show_ai_battles", show_ai_battles))
	var p := str(cfg.get_value("war", "pantheon", pantheon))
	if GodCatalog.pantheon(p)["id"] == p:
		pantheon = p
	primary = str(cfg.get_value("war", "primary", primary))
	secondary = str(cfg.get_value("war", "secondary", secondary))
	players = clampi(int(cfg.get_value("war", "players", players)), 2, 8)
	map_size = str(cfg.get_value("war", "map_size", map_size))
	if not MapGenerator.SIZES.has(map_size):
		map_size = "medium"
	grid = str(cfg.get_value("war", "grid", grid))
	if grid != RealmMap.GRID_HEX:
		grid = RealmMap.GRID_SQUARE
	ai_level = clampi(int(cfg.get_value("war", "ai_level", ai_level)), 0, AiPlayer.LEVEL_NAMES.size() - 1)
	awakening = str(cfg.get_value("war", "awakening", awakening))
	head_start = bool(cfg.get_value("war", "head_start", head_start))
	fog = bool(cfg.get_value("war", "fog", fog))
	online_players = clampi(int(cfg.get_value("online", "players", online_players)), 2, 6)
	online_size = str(cfg.get_value("online", "size", online_size))
	if not MapGenerator.SIZES.has(online_size):
		online_size = "medium"
	online_grid = RealmMap.GRID_HEX if str(cfg.get_value("online", "grid", online_grid)) == RealmMap.GRID_HEX else RealmMap.GRID_SQUARE
	online_kind = str(cfg.get_value("online", "kind", online_kind))
	if not ONLINE_KINDS.has(online_kind):
		online_kind = "room"
	online_visibility = str(cfg.get_value("online", "visibility", online_visibility))
	if not ["public", "friends", "private"].has(online_visibility):
		online_visibility = "public"
	_fix_gods()


## Keeps the chosen gods inside the chosen pantheon (after a pantheon change or an old save).
static func _fix_gods() -> void:
	var g := GodCatalog.god(primary)
	if g.is_empty() or g["pantheon"] != pantheon or g["role"] != GodCatalog.PRIMARY:
		primary = GodCatalog.gods_of(pantheon, GodCatalog.PRIMARY)[0]["id"]
	g = GodCatalog.god(secondary)
	if g.is_empty() or g["pantheon"] != pantheon or g["role"] != GodCatalog.SECONDARY:
		secondary = GodCatalog.gods_of(pantheon, GodCatalog.SECONDARY)[0]["id"]


static func set_pantheon(id: String) -> void:
	pantheon = id
	_fix_gods()


## Seconds a battle's result stays on the battle screen (WAIT: until Continue).
static func result_hold() -> float:
	return HOLDS[battle_hold]


static func animation_factor() -> float:
	return ANIM_SPEEDS[anim_speed]


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "anim_speed", anim_speed)
	cfg.set_value("display", "show_counts", show_counts)
	cfg.set_value("display", "battle_hold", battle_hold)
	cfg.set_value("display", "show_ai_battles", show_ai_battles)
	cfg.set_value("war", "pantheon", pantheon)
	cfg.set_value("war", "primary", primary)
	cfg.set_value("war", "secondary", secondary)
	cfg.set_value("war", "players", players)
	cfg.set_value("war", "map_size", map_size)
	cfg.set_value("war", "grid", grid)
	cfg.set_value("war", "ai_level", ai_level)
	cfg.set_value("war", "awakening", awakening)
	cfg.set_value("war", "head_start", head_start)
	cfg.set_value("war", "fog", fog)
	cfg.set_value("online", "players", online_players)
	cfg.set_value("online", "size", online_size)
	cfg.set_value("online", "grid", online_grid)
	cfg.set_value("online", "kind", online_kind)
	cfg.set_value("online", "visibility", online_visibility)
	cfg.save(SETTINGS_PATH)
