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
