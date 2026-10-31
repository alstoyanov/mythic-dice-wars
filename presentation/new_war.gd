extends Control
## New War, step 1: the pantheon (which also sets the realm: the menus and the map take its look) and
## the match options. Step 2 is the choice of gods (god_select).

const TILE := Vector2(140, 100)  ## a pantheon's tile (its die and name inside the button's frame), grown with the text
const DIE := 46.0
const TILE_GAP := 10

var _backdrop: MenuBackdrop
var _pantheon_buttons: Dictionary = {}  ## pantheon id -> Button
var _col: VBoxContainer
var _body: BoxContainer  ## the pantheons and the options
var _left: VBoxContainer  ## the pantheons (and, on a phone held sideways, the buttons under them)
var _grid: HFlowContainer
var _options: GridContainer
var _picks: Array[OptionButton] = []
var _buttons: HBoxContainer  ## Back, the book, Next


func _ready() -> void:
	_backdrop = Ui.setup_screen(self)
	_col = Ui.centered_column(self, 10)
	Ui.title(_col, "New War")

	# The pantheons and the options: side by side where the screen is wide enough (a computer, a phone
	# or tablet held sideways), else one above the other. Everything fits on the screen (see _layout).
	_body = BoxContainer.new()
	_body.add_theme_constant_override("separation", 28)
	_col.add_child(_body)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 8)
	_body.add_child(_left)
	var heading := Label.new()
	heading.text = "Choose your pantheon"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_left.add_child(heading)
	_grid = HFlowContainer.new()
	_grid.alignment = FlowContainer.ALIGNMENT_CENTER
	_grid.add_theme_constant_override("h_separation", TILE_GAP)
	_grid.add_theme_constant_override("v_separation", TILE_GAP)
	_left.add_child(_grid)
	var group := ButtonGroup.new()
	for p in GodCatalog.PANTHEONS:
		_grid.add_child(_pantheon_button(p, group))

	_options = GridContainer.new()
	_options.columns = 2
	_options.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_options.add_theme_constant_override("h_separation", 14)
	_options.add_theme_constant_override("v_separation", 6)
	_body.add_child(_options)
	var options := _options
	_option(options, "Players", range(2, 9).map(func(n: int) -> String: return "%d (you and %d %s)" % [n, n - 1, "rival" if n == 2 else "rivals"]),
		GameSettings.players - 2, func(i: int) -> void: GameSettings.players = i + 2)
	var sizes: Array = MapGenerator.SIZES.keys()
	_option(options, "Realm size", sizes.map(func(k: String) -> String:
			return "%s (%d territories)" % [k.capitalize(), MapGenerator.SIZES[k]]),
		sizes.find(GameSettings.map_size), func(i: int) -> void: GameSettings.map_size = sizes[i])
	_option(options, "Board", ["Isometric squares", "Hexagons"], 1 if GameSettings.grid == RealmMap.GRID_HEX else 0,
		func(i: int) -> void: GameSettings.grid = RealmMap.GRID_HEX if i == 1 else RealmMap.GRID_SQUARE)
	_option(options, "Rivals", Array(AiPlayer.LEVEL_NAMES), GameSettings.ai_level,
		func(i: int) -> void: GameSettings.ai_level = i)
	_option(options, "Secondary god", ["Wakes after %d conquests" % MatchState.AWAKEN_CONQUESTS, "Awake from the start"],
		0 if GameSettings.awakening == "milestone" else 1,
		func(i: int) -> void: GameSettings.awakening = "milestone" if i == 0 else "start")
	_option(options, "Turn order", ["Balanced (head start)", "Classic"],
		0 if GameSettings.head_start else 1, func(i: int) -> void: GameSettings.head_start = i == 0)
	_option(options, "Fog of war", ["Off", "On (see only near your land)"],
		1 if GameSettings.fog else 0, func(i: int) -> void: GameSettings.fog = i == 1)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	_col.add_child(row)
	_buttons = row
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void:
		GameSettings.save()
		get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	row.add_child(back)
	var book := IconButton.new(IconButton.Icon.BOOK, false, "Book of the Gods: every pantheon's gods, their powers and stories")
	book.pressed.connect(func() -> void:
		GameSettings.save()
		GodBook.open(get_tree(), "res://presentation/new_war.tscn"))
	row.add_child(book)
	var next := IconButton.new(IconButton.Icon.NEXT, true, "Choose your gods")
	next.pressed.connect(_on_next)
	row.add_child(next)

	Ui.on_resize(_body, _layout)


## Fits the screen without scrolling. A computer or tablet: the tiles beside the options in as many
## columns as fit (4, 3 or 2), else above them. A phone held upright: the tiles above the options, as
## small as needed for 4 or 3 columns. A phone held sideways (little height): 4 columns of smaller
## tiles beside the options, with the buttons under the tiles.
func _layout() -> void:
	var k := UiTheme.ui_scale()
	var room := Ui.panel_content_width()
	var sideways := Ui.is_sideways()
	# The pickers as wide as their longest choice beside the tiles; filling the width below them.
	var natural := 0.0
	for pick in _picks:
		natural = maxf(natural, _natural_width(pick))
	var labels := 0.0
	for i in range(0, _options.get_child_count(), 2):
		labels = maxf(labels, (_options.get_child(i) as Control).get_combined_minimum_size().x)
	var options_w := labels + 14.0 + natural
	# (some room to spare: the realms' frames are wider than the plain panel's margin)
	var beside := room - 28.0 - options_w - 40.0
	var columns := 4
	var tile_w := TILE.x * k
	if sideways:
		tile_w = minf(tile_w, (beside - 3.0 * TILE_GAP) / 4.0)
	else:
		while columns >= 2 and columns * (tile_w + TILE_GAP) - TILE_GAP > beside:
			columns -= 1
	_body.vertical = not sideways and columns < 2
	if _body.vertical:
		columns = 4 if room >= 4.0 * (110.0 + TILE_GAP) else 3
		tile_w = minf(tile_w, (room - (columns - 1) * TILE_GAP) / columns)
	for pick in _picks:
		pick.custom_minimum_size.x = 0.0 if _body.vertical else natural
	_options.add_theme_constant_override("v_separation", 3 if sideways else 6)
	var tile := Vector2(tile_w, tile_w * TILE.y / TILE.x)
	for b: Button in _pantheon_buttons.values():
		b.custom_minimum_size = tile
		(b.get_meta("die") as Control).custom_minimum_size = Vector2.ONE * DIE * tile.x / TILE.x
		# Long names (Mesopotamian) get a smaller font rather than spilling over the frame.
		Ui.fit_font(b.get_meta("name_label"), roundi(18.0 * minf(k, tile.x / TILE.x * 1.15)), tile.x - 20.0, 11)
	_grid.custom_minimum_size.x = columns * (tile.x + TILE_GAP) - TILE_GAP + 1.0
	var home := _left if sideways else _col
	if _buttons.get_parent() != home:
		_buttons.reparent(home)


## How wide a picker must be to show its longest choice.
static func _natural_width(pick: OptionButton) -> float:
	var font := pick.get_theme_font("font")
	var fs := pick.get_theme_font_size("font_size")
	var widest := 0.0
	for i in pick.item_count:
		widest = maxf(widest, font.get_string_size(pick.get_item_text(i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	return widest + 56.0  # the frame and the arrow


func _pantheon_button(p: Dictionary, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.button_pressed = p["id"] == GameSettings.pantheon
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = p["realm"]
	# Kept clear of the frame (some realms' button frames are wide).
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12.0
	box.offset_right = -12.0
	box.offset_top = 12.0
	box.offset_bottom = -8.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var die := TextureRect.new()
	die.texture = DiceArt.face(p["dice"], 1)
	die.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	die.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	die.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(die)
	var name_label := Label.new()
	name_label.text = p["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	b.set_meta("name_label", name_label)
	b.set_meta("die", die)
	Ui.hover_effect(b, "toggle")
	Ui.mark_choice(b)
	b.toggled.connect(func(on: bool) -> void:
		if on and GameSettings.pantheon != p["id"]:
			GameSettings.set_pantheon(p["id"])
			Ui.retheme(self, _backdrop))
	_pantheon_buttons[p["id"]] = b
	return b


func _option(grid: GridContainer, label_text: String, items: Array, selected: int, on_pick: Callable) -> void:
	var l := Label.new()
	l.text = label_text
	grid.add_child(l)
	var pick := OptionButton.new()
	for item in items:
		pick.add_item(str(item))
	pick.selected = maxi(0, selected)
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.clip_text = true  # on a narrow screen a long choice is cut short, not the panel made wider
	pick.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_picks.append(pick)
	pick.item_selected.connect(func(i: int) -> void:
		Sound.play("toggle")
		on_pick.call(i))
	grid.add_child(pick)


func _on_next() -> void:
	GameSettings.save()
	get_tree().change_scene_to_file("res://presentation/god_select.tscn")
