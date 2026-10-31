class_name GodBook
extends Control
## The Book of the Gods: every pantheon and its gods, with what they do in a war and their stories
## (GodLore, from Tile Shifter), to help choose a pantheon. Three pages, each fitting the screen
## without scrolling (a phone held either way): the realms; a realm's story and its gods; a god's
## powers and story. Back (and a phone's back gesture, see go_back) returns to the page before.
## Browsing a realm shows its look (the player's own choice is put back on leaving); "Play with <god>"
## takes that pantheon and god into New War.

const SCENE := "res://presentation/god_book.tscn"
const GAP := 10.0
const MIN_FIT := 0.6  ## a page shrinks to fit the screen down to this much of its size, no further

## Where Back leads from the first page: the screen that opened the book (see open).
static var _return_scene := "res://presentation/main_menu.tscn"

var _backdrop: MenuBackdrop
var _col: VBoxContainer
var _saved_pantheon := ""  ## the player's pantheon when the book opened
var _keep := false  ## "Play with" pressed: the shown pantheon becomes the player's
var _page := "realms"  ## "realms", "gods" or "god"
var _pantheon := ""
var _god := ""
var _fit := 1.0  ## the page's size, made smaller until it fits the screen
var _shown_for := Vector2.ZERO  ## the screen size the page was built for
var _themed := ""  ## the realm whose look is shown


## Opens the book; Back from its first page returns to `from` (a scene path).
static func open(tree: SceneTree, from: String) -> void:
	_return_scene = from
	tree.change_scene_to_file(SCENE)


func _ready() -> void:
	GameSettings.ensure_loaded()
	_saved_pantheon = GameSettings.pantheon
	_pantheon = _saved_pantheon
	_themed = _saved_pantheon
	_backdrop = Ui.setup_screen(self)
	_col = Ui.centered_column(self, 10)
	Ui.on_resize(_col, func() -> void:
		if Ui.usable_size() != _shown_for:  # a phone turned, a window resized: build the page again
			_show(_page))


func _exit_tree() -> void:
	if not _keep:
		GameSettings.pantheon = _saved_pantheon  # browsing only showed the realm


## The page before (Back, or a phone's back gesture via AppWindow).
func go_back() -> void:
	match _page:
		"god":
			_show("gods")
		"gods":
			_show("realms")
		_:
			if not _keep:
				GameSettings.pantheon = _saved_pantheon
			get_tree().change_scene_to_file(_return_scene)


func _play_with() -> void:
	var g := GodCatalog.god(_god)
	_keep = true
	GameSettings.set_pantheon(_pantheon)
	if g["role"] == GodCatalog.PRIMARY:
		GameSettings.primary = _god
	else:
		GameSettings.secondary = _god
	GameSettings.save()
	get_tree().change_scene_to_file("res://presentation/new_war.tscn")


## Shows a page at full size, then smaller until it fits (see _fit_page).
func _show(page: String) -> void:
	_page = page
	_fit = 1.0
	_shown_for = Ui.usable_size()
	_col.modulate.a = 0.0  # shown once it fits
	_build()
	_fit_page.call_deferred()


func _build() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	match _page:
		"realms":
			_build_realms()
		"gods":
			_build_gods()
		"god":
			_build_god()


## Builds the page again a little smaller while it is taller than the screen, then fades it in.
func _fit_page() -> void:
	var page := _page
	while true:
		await get_tree().process_frame
		await get_tree().process_frame  # (wrapped text knows its height once laid out)
		if _page != page or not is_inside_tree():
			return
		var panel := _col.get_parent() as Control
		if panel.get_combined_minimum_size().y <= Ui.usable_size().y - 4.0 or _fit <= MIN_FIT:
			break
		_fit = maxf(MIN_FIT, _fit - 0.07)
		_build()
	create_tween().tween_property(_col, "modulate:a", 1.0, 0.15)


## The shown realm's look (only the look: put back on leaving unless "Play with"); not again while it
## is already shown (that would restart the weather).
func _theme() -> void:
	if _themed == _pantheon:
		return
	_themed = _pantheon
	GameSettings.pantheon = _pantheon
	Ui.retheme(self, _backdrop)


## The page's scale: the screen's (UiTheme.ui_scale) and the fitting's.
func _k() -> float:
	return UiTheme.ui_scale() * _fit


## The width the page's content may take (not too wide to read on a big screen).
func _room() -> float:
	return minf(Ui.panel_content_width(), 1060.0 * UiTheme.ui_scale())


# ───────────────────────── page 1: the realms ─────────────────────────

func _build_realms() -> void:
	_theme()
	_title("Book of the Gods")
	_text(_col, "Choose a realm to meet its gods", 16, Color(1, 1, 1, 0.75), 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	var columns := 2 if Ui.is_narrow() else 4
	var w := minf(230.0 * _k(), (_room() - (columns - 1) * GAP) / columns)
	var h := w * (0.56 if columns == 2 else 0.48)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	_col.add_child(grid)
	for p in GodCatalog.PANTHEONS:
		_realm_tile(grid, p, Vector2(w, h))
	_buttons(false)


func _realm_tile(parent: Control, p: Dictionary, tile: Vector2) -> void:
	var b := Button.new()
	parent.add_child(b)  # first: the labels measure their text with the theme's font
	b.custom_minimum_size = tile
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = p["realm"]
	var box := _inside(b, 8.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var die := TextureRect.new()
	die.texture = DiceArt.face(p["dice"], 1)
	die.custom_minimum_size = Vector2.ONE * tile.y * 0.4
	die.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	die.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	die.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(die)
	var realm := GodLore.realm(p["id"])
	var name_label := _label(box, p["name"], 18, Color.WHITE)
	Ui.fit_font(name_label, roundi(18.0 * _k()), tile.x - 20.0, 11)
	var sub := _label(box, str(realm.get("subtitle", "")), 13, Color(1, 1, 1, 0.65))
	Ui.fit_font(sub, roundi(13.0 * _k()), tile.x - 20.0, 9)
	Ui.hover_effect(b)
	b.pressed.connect(func() -> void:
		_pantheon = p["id"]
		_show("gods"))


# ───────────────────────── page 2: a realm and its gods ─────────────────────────

func _build_gods() -> void:
	_theme()
	var accent: Color = UiTheme.current_palette()["accent"]
	var realm := GodLore.realm(_pantheon)
	_title(str(realm.get("name", GodCatalog.pantheon(_pantheon)["name"])))
	_text(_col, str(realm.get("subtitle", "")), 18, accent, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_text(_col, str(realm.get("about", "")), 15, Color(1, 1, 1, 0.85), _room(), HORIZONTAL_ALIGNMENT_CENTER)
	# The primary and the secondary gods side by side, or one row above the other on a narrow screen.
	var rows := BoxContainer.new()
	rows.vertical = Ui.is_narrow()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 8 if rows.vertical else 28)
	_col.add_child(rows)
	var width := _room() if rows.vertical else (_room() - 28.0) / 2.0
	var w := minf(150.0 * _k(), (width - 2.0 * GAP) / 3.0)
	for role in [GodCatalog.PRIMARY, GodCatalog.SECONDARY]:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		rows.add_child(box)
		var heading := _label(box, "Primary gods — a blessing without a price" if role == GodCatalog.PRIMARY \
			else "Secondary gods — great power, at a price", 15, accent)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ui.fit_font(heading, roundi(15.0 * _k()), 3.0 * w + 2.0 * GAP, 11)
		var tiles := HBoxContainer.new()
		tiles.alignment = BoxContainer.ALIGNMENT_CENTER
		tiles.add_theme_constant_override("separation", int(GAP))
		box.add_child(tiles)
		for g in GodCatalog.gods_of(_pantheon, role):
			_god_tile(tiles, g, w)
	_buttons(false)


func _god_tile(parent: Control, g: Dictionary, w: float) -> void:
	var b := Button.new()
	parent.add_child(b)
	b.custom_minimum_size = Vector2(w, w * 1.15)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = "%s, %s" % [g["name"], g["title"]]
	var box := _inside(b, 9.0)
	var pic := GodView.portrait(g["id"])
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(pic)
	var name_label := _label(box, g["name"], 15, Color.WHITE)
	Ui.fit_font(name_label, roundi(15.0 * _k()), w - 18.0, 10)
	Ui.hover_effect(b)
	b.pressed.connect(func() -> void:
		_god = g["id"]
		_show("god"))


# ───────────────────────── page 3: a god ─────────────────────────

func _build_god() -> void:
	GodView.build(_col, _god, _k(), _fit, _room(), Ui.is_narrow())
	_buttons(true)


# ───────────────────────── parts ─────────────────────────

## Back, and on the god's page "Play with <god>".
func _buttons(play: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	_col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(go_back)
	row.add_child(back)
	if play:
		var b := Button.new()
		b.text = "Play with %s" % GodCatalog.god(_god)["name"]
		b.custom_minimum_size = Vector2(200, 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.tooltip_text = "Start a New War with this pantheon and this god."
		b.pressed.connect(_play_with)
		Ui.hover_effect(b)
		row.add_child(b)


func _title(text: String) -> void:
	GodView.title(_col, text, _fit)


## A box inside a button, clear of its frame.
func _inside(b: Button, margin: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = margin
	box.offset_right = -margin
	box.offset_top = margin
	box.offset_bottom = -margin + 2.0
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	return box


## A one-line label (sized by the caller).
func _label(parent: Control, t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", roundi(font_size * _k()))
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Text that wraps at `width` (0: one line, smaller if it is wider than the page).
func _text(parent: Control, t: String, font_size: int, color: Color, width: float,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return GodView.text(parent, t, font_size, _k(), color, width, _room(), align)
