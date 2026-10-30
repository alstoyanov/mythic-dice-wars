extends Control
## New War, step 1: the pantheon (which also sets the realm: the menus and the map take its look) and
## the match options. Step 2 is the choice of gods (god_select).

var _backdrop: MenuBackdrop
var _pantheon_buttons: Dictionary = {}  ## pantheon id -> Button


func _ready() -> void:
	_backdrop = Ui.setup_screen(self)
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "New War")

	var heading := Label.new()
	heading.text = "Choose your pantheon"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	var grid := HFlowContainer.new()
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	Ui.on_resize(grid, func() -> void:
		grid.custom_minimum_size.x = minf(4 * 150 + 10, Ui.panel_content_width()))
	var group := ButtonGroup.new()
	for p in GodCatalog.PANTHEONS:
		grid.add_child(_pantheon_button(p, group))

	var options := GridContainer.new()
	options.columns = 2
	options.add_theme_constant_override("h_separation", 14)
	options.add_theme_constant_override("v_separation", 6)
	col.add_child(options)
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
	_option(options, "Fog of war", ["Off", "On (see only next to your land)"],
		1 if GameSettings.fog else 0, func(i: int) -> void: GameSettings.fog = i == 1)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void:
		GameSettings.save()
		get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	row.add_child(back)
	var next := IconButton.new(IconButton.Icon.NEXT, true, "Choose your gods")
	next.pressed.connect(_on_next)
	row.add_child(next)


func _pantheon_button(p: Dictionary, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(140, 92)
	b.button_pressed = p["id"] == GameSettings.pantheon
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = p["realm"]
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var die := TextureRect.new()
	die.texture = DiceArt.face(p["dice"], 1)
	die.custom_minimum_size = Vector2(52, 52)
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
	pick.item_selected.connect(func(i: int) -> void:
		Sound.play("toggle")
		on_pick.call(i))
	grid.add_child(pick)


func _on_next() -> void:
	GameSettings.save()
	get_tree().change_scene_to_file("res://presentation/god_select.tscn")
