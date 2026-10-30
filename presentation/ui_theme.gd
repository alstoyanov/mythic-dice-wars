class_name UiTheme
extends RefCounted
## The look of all menus and HUD text: a dark identity with gold-ish accents, tinted by the board
## look the player chose in Settings. Built in code, so there is nothing to import; to restyle a
## look, edit its palette. Custom type variations: "TitleLabel", "TopBar".

## Fonts: PT Serif (SIL Open Font License, assets/fonts/OFL-PTSerif.txt) for text; each realm's
## theme brings its own title font. A browser has no system fonts, so the web build depends on these.
const FONT_REGULAR := "res://assets/fonts/PTSerif-Regular.ttf"
const FONT_BOLD := "res://assets/fonts/PTSerif-Bold.ttf"
## Used only if the bundled files are missing.
const FALLBACK_FONT_NAMES := ["Georgia", "Palatino Linotype", "Book Antiqua", "Cambria", "Times New Roman", "serif"]

## Palette of the realm of the chosen pantheon (Looks: bg_top/bg_bottom the backdrop gradient,
## panel/border framed panels, text/accent font colours, button/hover/pressed button fills).
static func current_palette() -> Dictionary:
	return Looks.current()["palette"]


static func current() -> Theme:
	return build(current_palette(), ui_scale(), Ui.is_compact(), current_ui())


## The interface theme of the chosen realm (Looks "ui"): pictures for the frames and buttons, the
## background and weather (see MenuBackdrop), a title font.
static func current_ui() -> Dictionary:
	return Looks.current()["ui"]


## Text grows with the window (1.0 at the default 900x700, at most 1.8).
static func ui_scale() -> float:
	var win := Vector2(DisplayServer.window_get_size())
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		win = tree.root.get_visible_rect().size  # what the screens lay out in (scaled units on a phone)
	return clampf(minf(win.x / 900.0, win.y / 700.0), 1.0, 1.8)


## `compact`: a phone-sized screen, with a smaller title and tighter panel margins. `ui`: a look's
## interface theme; its pictures replace the flat frames and buttons (on a phone, the slimmer frame).
static func build(p: Dictionary, scale: float = 1.0, compact: bool = false, ui: Dictionary = {}) -> Theme:
	var t := Theme.new()
	var fonts := _fonts()
	var font: Font = fonts["regular"]
	var bold: Font = fonts["bold"]
	t.default_font = font
	t.default_font_size = roundi(18.0 * scale)

	var text: Color = p["text"]
	var accent: Color = p["accent"]
	var border: Color = p["border"]

	t.set_color("font_color", "Label", text)

	# Buttons (OptionButton shares them).
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, _box(p["button"], border.darkened(0.35), 8, 2, Vector2(18, 9)))
		t.set_stylebox("hover", type, _box(p["hover"], accent, 8, 2, Vector2(18, 9)))
		t.set_stylebox("pressed", type, _box(p["pressed"], accent, 8, 2, Vector2(18, 9)))
		t.set_stylebox("disabled", type, _box(Color(p["button"], 0.4), Color(border, 0.2), 8, 2, Vector2(18, 9)))
		t.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), accent, 8, 2, Vector2(18, 9)))
		t.set_color("font_color", type, text)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, accent)
		t.set_color("font_focus_color", type, text)
		t.set_color("font_disabled_color", type, Color(text, 0.4))
		if ui.has("button"):
			var m: int = ui["button_margin"]
			for state in STATE_TINTS:
				t.set_stylebox(state, type, _picture(ui["button"], m, Vector2(maxf(18.0, m), 9.0), STATE_TINTS[state]))
			t.set_stylebox("focus", type, StyleBoxEmpty.new())

	# Round icon buttons (see IconButton).
	t.set_type_variation("IconButton", "Button")
	t.set_type_variation("IconButtonPrimary", "Button")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill: Color = p["button"]
		var line: Color = border.darkened(0.2)
		var fill2: Color = p["accent"].darkened(0.1)
		if state == "hover":
			fill = p["hover"]
			line = accent
			fill2 = p["accent"].lightened(0.15)
		elif state == "pressed":
			fill = p["pressed"]
			line = accent
			fill2 = p["accent"].darkened(0.3)
		elif state == "focus":
			fill = Color(0, 0, 0, 0)
			fill2 = Color(0, 0, 0, 0)
		t.set_stylebox(state, "IconButton", _box(fill, line, 40, 2, Vector2.ZERO, 6))
		if ui.has("round"):  # the whole medallion stretched over the (square) button
			t.set_stylebox(state, "IconButton", StyleBoxEmpty.new() if state == "focus"
				else _picture(ui["round"], 0, Vector2.ZERO, STATE_TINTS.get(state, Color.WHITE)))
		t.set_stylebox(state, "IconButtonPrimary", _box(fill2, border, 48, 3, Vector2.ZERO, 8))

	# Switches (CheckButton): text in the menu colours, icons from the default theme.
	for type in ["CheckButton", "CheckBox"]:
		t.set_color("font_color", type, text)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, text)
		t.set_color("font_hover_pressed_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, text)

	# Text fields (the online account's email and password).
	t.set_stylebox("normal", "LineEdit", _box(Color(0, 0, 0, 0.35), border.darkened(0.3), 6, 2, Vector2(12, 8)))
	t.set_stylebox("focus", "LineEdit", _box(Color(0, 0, 0, 0), accent, 6, 2, Vector2(12, 8)))
	t.set_stylebox("read_only", "LineEdit", _box(Color(0, 0, 0, 0.2), Color(border, 0.3), 6, 2, Vector2(12, 8)))
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_placeholder_color", "LineEdit", Color(text, 0.45))
	t.set_color("caret_color", "LineEdit", accent)
	t.set_color("selection_color", "LineEdit", Color(accent, 0.35))

	# Volume sliders.
	t.set_stylebox("slider", "HSlider", _box(Color(0, 0, 0, 0.35), border.darkened(0.3), 5, 1, Vector2(0, 3)))
	t.set_stylebox("grabber_area", "HSlider", _box(accent.darkened(0.15), accent, 5, 1, Vector2(0, 3)))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(accent, accent, 5, 1, Vector2(0, 3)))

	# Language buttons (flag on a frame; the chosen language is the pressed one).
	t.set_type_variation("FlagButton", "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var frame := _box(Color(0, 0, 0, 0.25), border.darkened(0.3), 8, 2, Vector2(6, 6))
		if state == "hover":
			frame = _box(Color(0, 0, 0, 0.25), accent, 8, 2, Vector2(6, 6))
		elif state == "pressed" or state == "hover_pressed":
			frame = _box(Color(p["button"], 0.9), accent, 8, 4, Vector2(6, 6))
		elif state == "focus":
			frame = _box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0, Vector2(6, 6))
		t.set_stylebox(state, "FlagButton", frame)

	# Drop-down list of an OptionButton.
	t.set_stylebox("panel", "PopupMenu", _box(Color(p["panel"], 1.0), border, 6, 2, Vector2(6, 6)))
	if ui.has("panel_small"):
		var pm: int = ui["panel_small_margin"]
		t.set_stylebox("panel", "PopupMenu", _picture(ui["panel_small"], pm, Vector2(pm, pm), Color.WHITE))
	t.set_stylebox("hover", "PopupMenu", _box(p["hover"], Color(0, 0, 0, 0), 4, 0, Vector2(8, 4)))
	t.set_color("font_color", "PopupMenu", text)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)

	# Framed panels.
	var panel_margin := Vector2(16, 14) if compact else Vector2(26, 22)  # Ui.panel_content_width() relies on these
	t.set_stylebox("panel", "PanelContainer", _box(p["panel"], border, 14, 2, panel_margin, 10))
	t.set_type_variation("TopBar", "PanelContainer")
	t.set_stylebox("panel", "TopBar", _box(Color(p["panel"], 0.85), border.darkened(0.2), 12, 2,
		Vector2(12, 6) if compact else Vector2(18, 8), 6))
	if ui.has("panel"):
		var big: int = ui["panel_margin"]
		var small: int = ui["panel_small_margin"]
		if compact:
			t.set_stylebox("panel", "PanelContainer", _picture(ui["panel_small"], small, panel_margin, Color.WHITE))
		else:
			t.set_stylebox("panel", "PanelContainer", _picture(ui["panel"], big,
				Vector2(maxf(panel_margin.x, big + 2), maxf(panel_margin.y, big + 2)), Color.WHITE))
		t.set_stylebox("panel", "TopBar", _picture(ui["panel_small"], small,
			Vector2(small + 6, small - 2), Color.WHITE))

	# Title.
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", _title_font(ui, bold))
	t.set_font_size("font_size", "TitleLabel", roundi((32.0 if compact else 44.0) * scale))
	t.set_color("font_color", "TitleLabel", accent)
	t.set_color("font_outline_color", "TitleLabel", Color(0, 0, 0, 0.7))
	t.set_constant("outline_size", "TitleLabel", 6)

	# Long texts (Help).
	t.set_color("default_color", "RichTextLabel", text)
	t.set_font("bold_font", "RichTextLabel", bold)
	t.set_color("font_selected_color", "RichTextLabel", Color.WHITE)
	return t


## Button states of a pictured button: the same picture, lighter under the mouse, darker when pressed.
const STATE_TINTS := {
	"normal": Color.WHITE, "hover": Color(1.3, 1.22, 1.12), "pressed": Color(0.75, 0.72, 0.7),
	"disabled": Color(1, 1, 1, 0.45),
}
static var _pictures: Dictionary = {}


## A picture drawn in nine pieces: corners of `margin` pixels keep their size, the edges and the middle
## repeat (so a border pattern keeps its shape on a big panel); margin 0: the whole picture stretches.
## `content`: room kept free for the text.
static func _picture(path: String, margin: int, content: Vector2, tint: Color) -> StyleBoxTexture:
	if not _pictures.has(path):
		_pictures[path] = load(path) if ResourceLoader.exists(path) else null
	var b := StyleBoxTexture.new()
	b.texture = _pictures[path]
	b.set_texture_margin_all(margin)
	if margin > 0:
		b.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		b.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	b.content_margin_left = content.x
	b.content_margin_right = content.x
	b.content_margin_top = content.y
	b.content_margin_bottom = content.y
	b.modulate_color = tint
	return b


## The look's title font, falling back to PT Serif Bold (and its fallbacks) for missing characters.
static func _title_font(ui: Dictionary, bold: Font) -> Font:
	var path: String = ui.get("title_font", "")
	if path == "" or not ResourceLoader.exists(path):
		return bold
	var font: FontFile = load(path)
	if font.fallbacks.is_empty():
		var fallbacks: Array[Font] = [bold]
		font.fallbacks = fallbacks
	return font


## The regular and bold font, loaded once. Falls back to system fonts if the bundled ones are missing.
static var _font_cache: Dictionary = {}


static func _fonts() -> Dictionary:
	if not _font_cache.is_empty():
		return _font_cache
	if ResourceLoader.exists(FONT_REGULAR) and ResourceLoader.exists(FONT_BOLD):
		_font_cache = {"regular": load(FONT_REGULAR), "bold": load(FONT_BOLD)}
	else:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(FALLBACK_FONT_NAMES)
		var embolden := FontVariation.new()
		embolden.base_font = system
		embolden.variation_embolden = 0.7
		_font_cache = {"regular": system, "bold": embolden}
	return _font_cache


## The bold text font (for numbers drawn on the map).
static func bold_font() -> Font:
	return _fonts()["bold"]


## The current realm's title font.
static func title_font() -> Font:
	return _title_font(current_ui(), bold_font())


static func _box(bg: Color, line: Color, radius: int, line_width: int, margin: Vector2, shadow: int = 0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = line
	b.set_border_width_all(line_width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = margin.x
	b.content_margin_right = margin.x
	b.content_margin_top = margin.y
	b.content_margin_bottom = margin.y
	if shadow > 0:
		b.shadow_size = shadow
		b.shadow_color = Color(0, 0, 0, 0.45)
		b.shadow_offset = Vector2(0, 3)
	return b
