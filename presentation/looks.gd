class_name Looks
extends RefCounted
## The look of each pantheon's realm: menu palette and interface pictures (from
## assets/themes/<pantheon>/look.json, the same format as the Tile Shifter and Chasm of Knights
## themes), and the colours of the land on the map.

## The land of each realm on the map: top (grass / stone / sand), cliff (the sides), sea (around the island).
const TERRAIN := {
	"greek": {"top": Color("d9d0b8"), "cliff": Color("8c7a62"), "sea": Color("1d4f73")},
	"norse": {"top": Color("c9d6de"), "cliff": Color("5b6675"), "sea": Color("172636")},
	"egyptian": {"top": Color("e2c48c"), "cliff": Color("9c7246"), "sea": Color("1e5560")},
	"chinese": {"top": Color("b6cba3"), "cliff": Color("6e5c4a"), "sea": Color("1f4a4a")},
	"mayan": {"top": Color("93b56c"), "cliff": Color("735e44"), "sea": Color("1b4a3c")},
	"mesopotamian": {"top": Color("ddb688"), "cliff": Color("94654a"), "sea": Color("23485a")},
	"yoruba": {"top": Color("d3b37e"), "cliff": Color("8e4a2e"), "sea": Color("1d4638")},  # savanna on red laterite
}

## The players' colours (seat order).
const PLAYER_COLORS: Array[Color] = [
	Color("d8434a"), Color("3d86cc"), Color("3da864"), Color("e0ac2e"),
	Color("9563cf"), Color("2aaaa4"), Color("e5772d"), Color("d9619f"),
]

static var _cache: Dictionary = {}


static func current() -> Dictionary:
	GameSettings.ensure_loaded()
	return of(GameSettings.pantheon)


## {name, palette: {...}, ui: {...}, terrain: {...}} for a pantheon.
static func of(pantheon: String) -> Dictionary:
	if _cache.has(pantheon):
		return _cache[pantheon]
	var dir := "res://assets/themes/%s/" % pantheon
	var data: Dictionary = {}
	var file := FileAccess.open(dir + "look.json", FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			data = parsed
	var palette := {
		"bg_top": Color("2a2320"), "bg_bottom": Color("0e0b0a"), "panel": Color("352b26e8"),
		"border": Color("c98b5a"), "text": Color("f3ece2"), "accent": Color("e39a5f"),
		"button": Color("4d3b31"), "hover": Color("65503f"), "pressed": Color("3a2c24"),
	}
	for key in data.get("palette", {}):
		palette[key] = Color(str(data["palette"][key]))
	var ui := {
		"background": dir + "background.jpg", "background_game": dir + "background_game.jpg",
		"background_portrait": dir + "background_portrait.jpg",
		"background_portrait_game": dir + "background_portrait_game.jpg",
		"panel": dir + "panel.png", "panel_small": dir + "panel_small.png",
		"button": dir + "button.png", "round": dir + "round.png",
		"panel_margin": int(data.get("panel_margin", 28)),
		"panel_small_margin": int(data.get("panel_small_margin", 14)),
		"button_margin": int(data.get("button_margin", 14)),
		"weather": str(data.get("weather", "none")),
	}
	if data.has("title_font"):
		ui["title_font"] = dir + str(data["title_font"])
	var look := {"palette": palette, "ui": ui, "terrain": TERRAIN.get(pantheon, TERRAIN["greek"]),
		"name": str(data.get("name", GodCatalog.pantheon(pantheon)["name"]))}
	_cache[pantheon] = look
	return look


static func player_color(color_index: int) -> Color:
	return PLAYER_COLORS[color_index % PLAYER_COLORS.size()]


static var _icons: Dictionary = {}
static var _fx: Dictionary = {}

## How a tower's pieces fit together when its layout.json does not say (see tools/generated_art.py
## TOWER_LAYOUT): draw the tray front over the dice; the dice row at 42% of the tray's height, spreading
## a third of its width each way; the tray at its standard size.
const TOWER_LAYOUT := {"front": true, "floor": 0.42, "reach": 0.33, "tray_width": 1.0}

## The dice tower of a pantheon for battles: {tower, tray, tray_front (Texture2D), layout (TOWER_LAYOUT
## with this tower's values)}, or the first pantheon that has one while the others are still being made;
## {} if none exists. Loaded once and kept: decoding the pictures when a battle opens made it stutter
## on a phone (warm_towers loads a war's towers while it starts).
static func tower(pantheon: String) -> Dictionary:
	if not _towers.has(pantheon):
		_towers[pantheon] = _load_tower(pantheon)
	return _towers[pantheon]


## Loads the towers of these pantheons now (before the first battle needs them).
static func warm_towers(pantheons: Array) -> void:
	for p: String in pantheons:
		tower(p)


static var _towers: Dictionary = {}


static func _load_tower(pantheon: String) -> Dictionary:
	for id in [pantheon] + GodCatalog.PANTHEONS.map(func(p: Dictionary) -> String: return p["id"]):
		var dir := "res://assets/towers/%s/" % id
		if ResourceLoader.exists(dir + "tower.png") and ResourceLoader.exists(dir + "tray.png"):
			var t := {"tower": load(dir + "tower.png"), "tray": load(dir + "tray.png"), "layout": TOWER_LAYOUT.duplicate()}
			var file := FileAccess.open(dir + "layout.json", FileAccess.READ)
			if file != null:
				var data = JSON.parse_string(file.get_as_text())
				if data is Dictionary:
					t["layout"].merge(data, true)
			if t["layout"]["front"] and ResourceLoader.exists(dir + "tray_front.png"):
				t["tray_front"] = load(dir + "tray_front.png")
			return t
	return {}


## A HUD icon from assets/ui/icons (favour, reserve, reinforce, crown, ward, smite, bless, awaken, asleep,
## attack, defence, end_turn), or null.
static func icon(icon_name: String) -> Texture2D:
	if not _icons.has(icon_name):
		var path := "res://assets/ui/icons/%s.png" % icon_name
		_icons[icon_name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[icon_name]


## An effect sprite sheet from assets/vfx: one row of square frames (dust, lightning, motes, ward_dome,
## crumble), or null.
static func fx(fx_name: String) -> Texture2D:
	if not _fx.has(fx_name):
		var path := "res://assets/vfx/%s.png" % fx_name
		_fx[fx_name] = load(path) if ResourceLoader.exists(path) else null
	return _fx[fx_name]


static func fx_frames(sheet: Texture2D) -> int:
	return maxi(1, int(round(sheet.get_width() / float(sheet.get_height()))))
