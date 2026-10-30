class_name GodBook
extends Control
## The Book of the Gods: every pantheon and its gods, with what they do in a war and their stories
## (GodLore, from Tile Shifter), to help choose a pantheon. Browsing a pantheon shows its realm's look
## (the player's own choices are put back on leaving); "Play with <god>" takes that pantheon and god
## into New War.

const SCENE := "res://presentation/god_book.tscn"
const TAB := Vector2(104, 78)  ## a pantheon's tab (die and name), grown with the text
const THUMB := 92.0  ## a god's portrait in the list
const PORTRAIT := 150.0  ## the chosen god's portrait
const LIST_GAP := 8

## Where Back leads: the screen that opened the book (see open).
static var _return_scene := "res://presentation/main_menu.tscn"

var _backdrop: MenuBackdrop
var _saved_pantheon := ""  ## the player's pantheon when the book opened
var _keep := false  ## "Play with" pressed: the shown pantheon becomes the player's
var _pantheon := ""
var _god := ""
var _realm_line: Label
var _about: Label
var _list: VBoxContainer  ## the gods of the shown pantheon
var _detail: VBoxContainer  ## the chosen god
var _lore_scroll: ScrollContainer
var _play: Button


## Opens the book; Back returns to `from` (a scene path).
static func open(tree: SceneTree, from: String) -> void:
	_return_scene = from
	tree.change_scene_to_file(SCENE)


func _ready() -> void:
	GameSettings.ensure_loaded()
	_saved_pantheon = GameSettings.pantheon
	_backdrop = Ui.setup_screen(self)
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "Book of the Gods")

	var tabs := HFlowContainer.new()
	tabs.alignment = FlowContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	col.add_child(tabs)
	var group := ButtonGroup.new()
	for p in GodCatalog.PANTHEONS:
		tabs.add_child(_tab(p, group))
	Ui.on_resize(tabs, func() -> void:
		var k := UiTheme.ui_scale()
		tabs.custom_minimum_size.x = minf(GodCatalog.PANTHEONS.size() * (TAB.x * k + 8.0), Ui.panel_content_width()))

	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", 0)
	col.add_child(intro)
	_realm_line = Label.new()
	_realm_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_child(_realm_line)
	Ui.scaled_font(_realm_line, 18)
	_about = Label.new()
	_about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_about.modulate = Color(1, 1, 1, 0.8)
	intro.add_child(_about)
	Ui.scaled_font(_about, 15)

	# The gods beside the chosen one where there is room, else above (and the page scrolls).
	var body := BoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	col.add_child(body)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	body.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	_detail = VBoxContainer.new()
	right.add_child(_detail)
	_lore_scroll = ScrollContainer.new()
	_lore_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_lore_scroll)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void: _leave(_return_scene))
	row.add_child(back)
	_play = Button.new()
	_play.custom_minimum_size = Vector2(220, 44)
	_play.tooltip_text = "Start a New War with this pantheon and this god."
	_play.pressed.connect(_play_with)
	Ui.hover_effect(_play)
	row.add_child(_play)

	Ui.on_resize(body, func() -> void:
		var k := UiTheme.ui_scale()
		var room := Ui.panel_content_width()
		var list_w := 3 * (THUMB * k + 20.0 + LIST_GAP)
		var side := room >= list_w + 24.0 + 420.0 * k
		body.vertical = not side
		_about.custom_minimum_size.x = minf(760.0 * k, room)
		right.custom_minimum_size.x = minf(560.0 * k, room - (list_w + 24.0 if side else 0.0))
		# Beside the list, the story scrolls in the room the screen leaves; above it (a phone), the
		# whole page scrolls instead, so the story takes its full height.
		if side:
			_lore_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			_lore_scroll.custom_minimum_size.y = clampf(Ui.usable_size().y - 520.0 * k, 110.0, 520.0)
		else:
			_lore_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_lore_scroll.custom_minimum_size.y = 0.0)

	_show_pantheon(_saved_pantheon, GameSettings.primary)


func _exit_tree() -> void:
	if not _keep:
		GameSettings.pantheon = _saved_pantheon  # browsing only showed the realm


func _leave(scene: String) -> void:
	if not _keep:
		GameSettings.pantheon = _saved_pantheon
	get_tree().change_scene_to_file(scene)


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


func _tab(p: Dictionary, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.button_pressed = p["id"] == GameSettings.pantheon
	b.tooltip_text = p["realm"]
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8.0
	box.offset_right = -8.0
	box.offset_top = 9.0
	box.offset_bottom = -6.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
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
	Ui.hover_effect(b, "toggle")
	Ui.mark_choice(b)
	b.toggled.connect(func(on: bool) -> void:
		if on and _pantheon != p["id"]:
			_show_pantheon(p["id"], ""))
	b.tree_entered.connect(func() -> void:
		Ui.on_resize(b, func() -> void:
			var k := UiTheme.ui_scale()
			b.custom_minimum_size = TAB * k
			die.custom_minimum_size = Vector2(34, 34) * k
			Ui.fit_font(name_label, roundi(15.0 * k), TAB.x * k - 16.0, 10)), CONNECT_ONE_SHOT)
	return b


## Shows a pantheon in its realm's look, with `god_id` chosen (or its first god).
func _show_pantheon(pantheon_id: String, god_id: String) -> void:
	_pantheon = pantheon_id
	GameSettings.pantheon = pantheon_id  # only the look; put back on leaving unless "Play with"
	Ui.retheme(self, _backdrop)
	var realm := GodLore.realm(pantheon_id)
	_realm_line.text = "%s · %s" % [realm.get("name", GodCatalog.pantheon(pantheon_id)["name"]), realm.get("subtitle", "")]
	_realm_line.add_theme_color_override("font_color", UiTheme.current_palette()["accent"])
	_about.text = str(realm.get("about", ""))
	if GodCatalog.god(god_id).get("pantheon", "") != pantheon_id:
		god_id = GodCatalog.gods_of(pantheon_id, GodCatalog.PRIMARY)[0]["id"]
	for c in _list.get_children():
		c.queue_free()
	var group := ButtonGroup.new()
	for role in [GodCatalog.PRIMARY, GodCatalog.SECONDARY]:
		var heading := Label.new()
		heading.text = "Primary gods — a blessing without a price" if role == GodCatalog.PRIMARY \
			else "Secondary gods — great power, at a price"
		heading.add_theme_color_override("font_color", UiTheme.current_palette()["accent"])
		_list.add_child(heading)
		Ui.scaled_font(heading, 15)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", LIST_GAP)
		_list.add_child(row)
		for g in GodCatalog.gods_of(pantheon_id, role):
			row.add_child(_god_button(g, group, g["id"] == god_id))
	_show_god(god_id)


func _god_button(g: Dictionary, group: ButtonGroup, pressed: bool) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.button_pressed = pressed
	b.tooltip_text = "%s, %s" % [g["name"], g["title"]]
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 9.0
	box.offset_right = -9.0
	box.offset_top = 9.0
	box.offset_bottom = -9.0
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var pic := TextureRect.new()
	var path := GodCatalog.portrait_path(g["id"])
	pic.texture = load(path) if ResourceLoader.exists(path) else null
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	var name_label := Label.new()
	name_label.text = g["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	Ui.hover_effect(b, "toggle")
	Ui.mark_choice(b)
	b.toggled.connect(func(on: bool) -> void:
		if on:
			_show_god(g["id"]))
	b.tree_entered.connect(func() -> void:
		Ui.on_resize(b, func() -> void:
			var k := UiTheme.ui_scale()
			var w := THUMB * k + 18.0
			b.custom_minimum_size = Vector2(w, THUMB * k + 26.0 * k + 22.0)
			Ui.fit_font(name_label, roundi(15.0 * k), w - 18.0, 10)), CONNECT_ONE_SHOT)
	return b


func _show_god(god_id: String) -> void:
	_god = god_id
	var g := GodCatalog.god(god_id)
	var lore := GodLore.god(god_id)
	for c in _detail.get_children():
		c.queue_free()
	for c in _lore_scroll.get_children():
		c.queue_free()
	_play.text = "Play with %s" % g["name"]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	_detail.add_child(head)
	var pic := TextureRect.new()
	var path := GodCatalog.portrait_path(god_id)
	pic.texture = load(path) if ResourceLoader.exists(path) else null
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	head.add_child(pic)
	Ui.on_resize(pic, func() -> void: pic.custom_minimum_size = Vector2.ONE * PORTRAIT * UiTheme.ui_scale())
	var facts := VBoxContainer.new()
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts.add_theme_constant_override("separation", 4)
	head.add_child(facts)
	var name_label := _text(facts, g["name"], 30)
	name_label.theme_type_variation = "TitleLabel"  # the realm's title font
	var primary: bool = g["role"] == GodCatalog.PRIMARY
	_text(facts, "%s · %s god" % [g["title"], "Primary" if primary else "Secondary"], 15, Color(1, 1, 1, 0.75))
	_text(facts, "%s: %s" % [g["boon_name"], g["boon_text"]], 15, Color(0.75, 1.0, 0.75))
	if g.has("bane_name"):
		_text(facts, "%s: %s" % [g["bane_name"], g["bane_text"]], 15, Color(1.0, 0.65, 0.6))

	var story := VBoxContainer.new()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 8)
	_lore_scroll.add_child(story)
	_text(story, str(lore.get("lore", "")), 16)
	if str(lore.get("did_you_know", "")) != "":
		_text(story, "Did you know? " + str(lore["did_you_know"]), 15, Color(1, 1, 1, 0.8))
	_lore_scroll.scroll_vertical = 0


func _text(parent: Control, t: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	Ui.scaled_font(l, font_size)
	return l
