extends Control
## New War, step 2: the primary god (a blessing without a price) and the secondary god (great power
## with a severe flaw), from the chosen pantheon. On a computer or tablet, cards show the portrait and
## the powers; on a phone (no room for six cards) a row of portraits per role, with the chosen god's
## powers under it: the rows one above the other when it is held upright, side by side when sideways.
## Everything fits on the screen.

const CARD_WIDTH := 210.0
const CARD_WIDTH_MAX := 300.0  ## wider where there is room: the text takes fewer lines, the cards less height
const CARD_MARGIN := 13  ## clear of the button's frame (some realms' frames are wide)
const TILE_GAP := 10

var _col: VBoxContainer
var _layout := ""  ## "cards", or "upright" / "sideways" and the width: what the screen is built for now


func _ready() -> void:
	Ui.setup_screen(self)
	_col = Ui.centered_column(self, 10)
	Ui.on_resize(_col, _build)


## (Re)builds the screen for its shape, when that changed (a phone turned).
func _build() -> void:
	var layout := "cards" if not Ui.is_compact() else ("sideways" if Ui.is_sideways() else "upright")
	var key := layout if layout == "cards" else "%s %d" % [layout, Ui.panel_content_width()]  # (cards follow the width themselves)
	if key == _layout:
		return
	_layout = key
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	Ui.title(_col, "Choose your gods")
	var primary := "Primary god — a blessing without a price"
	var secondary := "Secondary god — great power, at a price"
	if layout == "cards":
		_section(_col, primary, GodCatalog.PRIMARY)
		_section(_col, secondary, GodCatalog.SECONDARY)
	else:
		var room := Ui.panel_content_width()
		var rows := BoxContainer.new()
		rows.vertical = layout == "upright"
		rows.add_theme_constant_override("separation", 10 if rows.vertical else 28)
		rows.alignment = BoxContainer.ALIGNMENT_CENTER
		_col.add_child(rows)
		var width := room if rows.vertical else (room - 28.0) / 2.0
		var tile_w := minf(130.0 if rows.vertical else 104.0, (width - 2.0 * TILE_GAP) / 3.0)
		_row(rows, primary, GodCatalog.PRIMARY, tile_w)
		_row(rows, secondary, GodCatalog.SECONDARY, tile_w)
	var note := Label.new()
	note.text = ("The secondary god wakes after %d conquests." % MatchState.AWAKEN_CONQUESTS) \
		if GameSettings.awakening == "milestone" else "Both gods are awake from the start."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.modulate = Color(1, 1, 1, 0.7)
	_col.add_child(note)
	Ui.wrap_to_screen(note)
	Ui.start_back_row(_col, _on_start,
		func() -> void: get_tree().change_scene_to_file("res://presentation/new_war.tscn"))


## A phone's row: the heading, the gods of `role` as portraits, and the chosen one's powers.
func _row(parent: Control, heading_text: String, role: String, tile_w: float) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	parent.add_child(box)
	var width := 3.0 * tile_w + 2.0 * TILE_GAP
	var heading := Label.new()
	heading.text = heading_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", UiTheme.current_palette()["accent"])
	box.add_child(heading)
	Ui.fit_font(heading, heading.get_theme_font_size("font_size"), width, 13)
	var tiles := HBoxContainer.new()
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("separation", TILE_GAP)
	box.add_child(tiles)
	var powers := VBoxContainer.new()
	powers.add_theme_constant_override("separation", 2)
	box.add_child(powers)
	var boon := _text("", 14, Color(0.75, 1.0, 0.75))
	var bane := _text("", 14, Color(1.0, 0.65, 0.6))
	for l in [boon, bane]:
		l.custom_minimum_size.x = width
		powers.add_child(l)
	var show := func(g: Dictionary) -> void:
		boon.text = "%s: %s" % [g["boon_name"], g["boon_text"]]
		bane.visible = g.has("bane_name")
		bane.text = "%s: %s" % [g.get("bane_name", ""), g.get("bane_text", "")]
	var chosen: String = GameSettings.primary if role == GodCatalog.PRIMARY else GameSettings.secondary
	var group := ButtonGroup.new()
	for g in GodCatalog.gods_of(GameSettings.pantheon, role):
		var b := _tile(g, group, role, tile_w)
		tiles.add_child(b)
		b.toggled.connect(func(on: bool) -> void:
			if on:
				show.call(g))
		if g["id"] == chosen:
			show.call(g)
	if boon.text == "":
		show.call(GodCatalog.gods_of(GameSettings.pantheon, role)[0])


## A god on a phone: the portrait and the name.
func _tile(g: Dictionary, group: ButtonGroup, role: String, w: float) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(w, w * 1.12)
	b.button_pressed = g["id"] == (GameSettings.primary if role == GodCatalog.PRIMARY else GameSettings.secondary)
	b.tooltip_text = "%s, %s" % [g["name"], g["title"]]
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 9.0
	box.offset_right = -9.0
	box.offset_top = 9.0
	box.offset_bottom = -7.0
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
	b.tree_entered.connect(func() -> void: Ui.fit_font(name_label, 16, w - 18.0, 10), CONNECT_ONE_SHOT)
	Ui.hover_effect(b, "toggle")
	Ui.mark_choice(b)
	b.toggled.connect(func(on: bool) -> void:
		if not on:
			return
		if role == GodCatalog.PRIMARY:
			GameSettings.primary = g["id"]
		else:
			GameSettings.secondary = g["id"])
	return b


func _section(col: Control, heading_text: String, role: String) -> void:
	var heading := Label.new()
	heading.text = heading_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", UiTheme.current_palette()["accent"])
	col.add_child(heading)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	col.add_child(flow)
	var group := ButtonGroup.new()
	for g in GodCatalog.gods_of(GameSettings.pantheon, role):
		flow.add_child(_card(g, group, role))
	Ui.on_resize(flow, func() -> void:
		var room := Ui.panel_content_width()
		var width := clampf((room - 2 * 10 - 40) / 3.0, CARD_WIDTH, CARD_WIDTH_MAX)
		for card in flow.get_children():
			(card as Control).custom_minimum_size.x = width
		flow.custom_minimum_size.x = minf(3 * (width + 10), room))


func _card(g: Dictionary, group: ButtonGroup, role: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	b.button_pressed = g["id"] == (GameSettings.primary if role == GodCatalog.PRIMARY else GameSettings.secondary)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN)
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	var pic := TextureRect.new()
	var path := GodCatalog.portrait_path(g["id"])
	pic.texture = load(path) if ResourceLoader.exists(path) else null
	pic.custom_minimum_size = Vector2(72, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(pic)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	names.add_child(_text(g["name"], 19))
	names.add_child(_text(g["title"], 12, Color(1, 1, 1, 0.7)))
	box.add_child(_text("%s: %s" % [g["boon_name"], g["boon_text"]], 13, Color(0.75, 1.0, 0.75)))
	if g.has("bane_name"):
		box.add_child(_text("%s: %s" % [g["bane_name"], g["bane_text"]], 13, Color(1.0, 0.65, 0.6)))
	# A card is as tall as its text: the button takes the box's height.
	box.minimum_size_changed.connect(func() -> void:
		b.custom_minimum_size.y = box.get_combined_minimum_size().y + 2 * CARD_MARGIN)
	Ui.hover_effect(b, "toggle")
	Ui.mark_choice(b)
	b.toggled.connect(func(on: bool) -> void:
		if not on:
			return
		if role == GodCatalog.PRIMARY:
			GameSettings.primary = g["id"]
		else:
			GameSettings.secondary = g["id"])
	return b


func _text(t: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l


func _on_start() -> void:
	GameSettings.save()
	get_tree().change_scene_to_file("res://presentation/game_screen.tscn")
