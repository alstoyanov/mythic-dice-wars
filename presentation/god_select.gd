extends Control
## New War, step 2: the primary god (a blessing without a price) and the secondary god (great power
## with a severe flaw), from the chosen pantheon. Cards show the portrait and the powers.

const CARD_WIDTH := 210.0
const CARD_WIDTH_MAX := 300.0  ## wider where there is room: the text takes fewer lines, the cards less height
const CARD_MARGIN := 13  ## clear of the button's frame (some realms' frames are wide)


func _ready() -> void:
	Ui.setup_screen(self)
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "Choose your gods")
	_section(col, "Primary god — a blessing without a price", GodCatalog.PRIMARY)
	_section(col, "Secondary god — great power, at a price", GodCatalog.SECONDARY)
	var note := Label.new()
	note.text = ("The secondary god wakes after %d conquests." % MatchState.AWAKEN_CONQUESTS) \
		if GameSettings.awakening == "milestone" else "Both gods are awake from the start."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.modulate = Color(1, 1, 1, 0.7)
	col.add_child(note)
	Ui.start_back_row(col, _on_start,
		func() -> void: get_tree().change_scene_to_file("res://presentation/new_war.tscn"))


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
