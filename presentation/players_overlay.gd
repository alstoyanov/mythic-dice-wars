class_name PlayersOverlay
extends ScreenOverlay
## Every player on one page over the war (the Players button; on a phone the side list does not fit):
## colour and name, territories and dice, the reinforcement they would get, reserve and favour, and
## both gods as portraits that open the god's page (GodOverlay). The player whose turn it is is framed,
## a fallen one dimmed, the leader crowned. One column on a narrow screen, two elsewhere; it follows
## the war while open (refresh).

const GAP := 8.0

var state: MatchState
var viewer: int = -1  ## under fog of war, whose eyes: the other players' dice are not shown


func _init(match_state: MatchState, viewer_index: int) -> void:
	super._init()
	state = match_state
	viewer = viewer_index


## The war changed (a battle, a turn): show it as it is now.
func refresh() -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		rebuild()


func _build() -> void:
	GodView.title(col, "Players", fit)
	var current := state.players[state.current]
	var whose := "Your turn" if current.index == viewer else "%s's turn" % current.name
	GodView.text(col, "Round %d · %s" % [state.round_number, whose], 16, k(),
		UiTheme.current_palette()["accent"], 0.0, room(), HORIZONTAL_ALIGNMENT_CENTER)
	# One column on a narrow screen; on a short one (a phone held sideways) three for many players, so
	# the cards keep a readable size; else two.
	var columns := 1 if Ui.is_narrow() or state.players.size() < 3 else 2
	if columns == 2 and Ui.is_sideways() and state.players.size() > 4:
		columns = 3
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	col.add_child(grid)
	var width := minf((room() - (columns - 1) * GAP) / columns, 520.0 * k())
	var leader := _leader()
	for p in state.players:
		_card(grid, p, width, p.index == leader)
	back_row()


## The player with the most territories (-1 on a tie).
func _leader() -> int:
	var leader := -1
	var most := 0
	for q in state.alive_players():
		var n := state.territories_of(q).size()
		if n > most:
			most = n
			leader = q
		elif n == most:
			leader = -1
	return leader


func _card(parent: Control, p: MatchState.PlayerState, width: float, leads: bool) -> void:
	var accent: Color = UiTheme.current_palette()["accent"]
	var active := p.index == state.current and not p.eliminated
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(8)
	box.bg_color = Color(accent, 0.18) if active else Color(0, 0, 0, 0.3)
	box.border_color = accent if active else Color(1, 1, 1, 0.12)
	box.set_border_width_all(2 if active else 1)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		box.set_content_margin(side, 8.0 * k())
	card.add_theme_stylebox_override("panel", box)
	card.custom_minimum_size.x = width
	card.modulate = Color(1, 1, 1, 0.45) if p.eliminated else Color.WHITE
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8.0 * k()))
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", int(3.0 * k()))
	row.add_child(info)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	info.add_child(head)
	var swatch := ColorRect.new()
	swatch.color = Looks.player_color(p.color_index)
	swatch.custom_minimum_size = Vector2.ONE * 14.0 * k()
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(swatch)
	var name_label := _label(head, p.name + ("  (fallen)" if p.eliminated else ""), 18)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if leads and Looks.icon("crown") != null:
		head.add_child(_icon("crown", 22.0, "Leads with the most territories"))
	if not p.eliminated:
		var hidden := state.fog and viewer >= 0 and p.index != viewer  # another player's dice, under the fog
		_label(info, "%d lands · %s dice" % [state.territories_of(p.index).size(),
			"?" if hidden else str(state.total_dice(p.index))], 14)
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 4)
		info.add_child(stats)
		_stat(stats, "reinforce", "+?" if hidden else "+%d" % state.reinforcement_preview(p.index), "Reinf. ",
			"Reinforcements at the end of the turn")
		_stat(stats, "reserve", "?" if hidden else str(p.reserve), "Res. ", "Reserve: dice waiting for room")
		_stat(stats, "favour", str(p.favor), "Fav. ", "Favour: pays for miracles")
		if state.round_number == 1 and p.head_start > 0 and not hidden:
			var note := _label(info, "Head start +%d dice" % p.head_start, 13)
			note.add_theme_color_override("font_color", accent)

	_god(row, p.primary, true, 0)
	_god(row, p.secondary, p.secondary_awake, p.conquests)


## A god's portrait with the name under it; tapped, the god's page. Asleep: darker, with the conquests left.
func _god(parent: Control, god_id: String, awake: bool, conquests: int) -> void:
	var g := GodCatalog.god(god_id)
	var side := 62.0 * k()
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.custom_minimum_size = Vector2(side, side + 18.0 * k())
	b.tooltip_text = "%s — %s: %s" % [g["name"], g["boon_name"], g["boon_text"]]
	if not awake:
		b.tooltip_text += "\n(Asleep: wakes after %d conquests — %d so far.)" % [MatchState.AWAKEN_CONQUESTS, conquests]
	b.pressed.connect(func() -> void: get_parent().add_child(GodOverlay.new(god_id)))
	parent.add_child(b)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var pic := GodView.portrait(god_id)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.modulate = Color.WHITE if awake else Color(0.4, 0.4, 0.45)
	box.add_child(pic)
	if not awake:
		var left := _label(pic, "zzz %d" % (MatchState.AWAKEN_CONQUESTS - conquests), 12)
		left.add_theme_color_override("font_outline_color", Color.BLACK)
		left.add_theme_constant_override("outline_size", 4)
		left.position = Vector2(3.0, 2.0)
	var name_label := _label(box, g["name"], 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ui.fit_font(name_label, roundi(13.0 * k()), side + 6.0, 9)
	Ui.hover_effect(b)


func _stat(parent: Control, icon_name: String, value: String, word: String, tip: String) -> void:
	if Looks.icon(icon_name) != null:
		parent.add_child(_icon(icon_name, 18.0, tip))
		word = ""
	var l := _label(parent, word + value, 14)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	var gap := Control.new()
	gap.custom_minimum_size.x = 6.0
	parent.add_child(gap)


func _label(parent: Control, t: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", roundi(font_size * k()))
	parent.add_child(l)
	return l


func _icon(icon_name: String, side: float, tip: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Looks.icon(icon_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2.ONE * side * k()
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.tooltip_text = tip
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r
