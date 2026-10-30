class_name PlayerPanel
extends PanelContainer
## Beside the map: one row per player in turn order with their colour, gods, territories, dice, the
## reinforcement they would get (largest region), reserve and favour (and in round 1 their head start). The player whose turn it is is
## framed; an eliminated player is dimmed. Hovering a god's portrait explains their powers.

const PORTRAIT := 34.0

var _list: VBoxContainer
var viewer: int = -1  ## under fog of war, whose eyes: the other players' dice are not shown
var _portraits: Dictionary = {}  ## god id -> Texture2D


func _init() -> void:
	theme_type_variation = "TopBar"
	custom_minimum_size = Vector2(250, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)


func update(state: MatchState) -> void:
	for c in _list.get_children():
		c.queue_free()
	var accent: Color = UiTheme.current_palette()["accent"]
	var leader := -1  # the player with the most territories wears the crown (none on a tie)
	var most := 0
	for q in state.alive_players():
		var n := state.territories_of(q).size()
		if n > most:
			most = n
			leader = q
		elif n == most:
			leader = -1
	for p in state.players:
		var active := p.index == state.current and not p.eliminated
		var row := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(accent, 0.18) if active else Color(0, 0, 0, 0.22)
		box.border_color = accent if active else Color(1, 1, 1, 0.1)
		box.set_border_width_all(2 if active else 1)
		box.set_corner_radius_all(8)
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		row.add_theme_stylebox_override("panel", box)
		row.modulate = Color(1, 1, 1, 0.4) if p.eliminated else Color.WHITE
		_list.add_child(row)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		row.add_child(col)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		col.add_child(head)
		var swatch := ColorRect.new()
		swatch.color = Looks.player_color(p.color_index)
		swatch.custom_minimum_size = Vector2(12, 12)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(swatch)
		var name_label := Label.new()
		name_label.text = p.name + ("  (fallen)" if p.eliminated else "")
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		head.add_child(name_label)
		if p.index == leader and Looks.icon("crown") != null:
			head.add_child(_icon("crown", 22, "Leads with the most territories"))
		head.add_child(_portrait(p.primary, true, state))
		head.add_child(_portrait(p.secondary, p.secondary_awake, state, p.conquests))
		if p.eliminated:
			continue
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 4)
		stats.modulate = Color(1, 1, 1, 0.9)
		col.add_child(stats)
		# Under fog of war the number of lands stays public; another player's dice do not.
		var hidden := state.fog and viewer >= 0 and p.index != viewer
		var fog_tip := "Hidden by the fog of war" if hidden else ""
		_stat(stats, "", "%d lands · %s dice" % [state.territories_of(p.index).size(), "?" if hidden else str(state.total_dice(p.index))], fog_tip)
		_stat(stats, "reinforce", "+?" if hidden else "+%d" % state.reinforcement_preview(p.index),
			fog_tip if hidden else "Reinforcements at the end of the turn")
		_stat(stats, "reserve", "?" if hidden else str(p.reserve), fog_tip if hidden else "Reserve: dice waiting for room")
		_stat(stats, "favour", str(p.favor), "Favour: pays for miracles")
		if state.round_number == 1 and p.head_start > 0 and not hidden:  # what made up for moving later
			var note := Label.new()
			note.text = "Head start +%d dice" % p.head_start
			note.tooltip_text = "Moves %d of %d, so this player began with %d extra dice.
The later in the turn order, the bigger the head start." % [p.index + 1, state.players.size(), p.head_start]
			note.mouse_filter = Control.MOUSE_FILTER_PASS
			note.add_theme_font_size_override("font_size", 12)
			note.add_theme_color_override("font_color", accent)
			col.add_child(note)


func _portrait(god_id: String, awake: bool, state: MatchState, conquests: int = 0) -> Control:
	var g := GodCatalog.god(god_id)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var pic := TextureRect.new()
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture = _texture(god_id)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not awake:
		pic.modulate = Color(0.35, 0.35, 0.4)
	holder.add_child(pic)
	if not awake and Looks.icon("asleep") != null:
		var eye := _icon("asleep", 18, "")
		eye.position = Vector2(PORTRAIT - 17, PORTRAIT - 15)
		holder.add_child(eye)
		var left := Label.new()
		left.text = str(MatchState.AWAKEN_CONQUESTS - conquests)
		left.add_theme_font_size_override("font_size", 12)
		left.add_theme_color_override("font_outline_color", Color.BLACK)
		left.add_theme_constant_override("outline_size", 4)
		left.position = Vector2(3, PORTRAIT - 18)
		left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(left)
	var tip := "%s — %s\n%s: %s" % [g.get("name", ""), g.get("title", ""), g.get("boon_name", ""), g.get("boon_text", "")]
	if g.has("bane_name"):
		tip += "\n%s: %s" % [g["bane_name"], g["bane_text"]]
	if not awake:
		tip += "\n(Asleep: wakes after %d conquests — %d so far.)" % [MatchState.AWAKEN_CONQUESTS, conquests]
	holder.tooltip_text = tip
	return holder


## An icon with a number after it (no icon art: a short word instead), e.g. the favour flame and "3".
func _stat(row: HBoxContainer, icon_name: String, text: String, tip: String) -> void:
	if icon_name != "" and Looks.icon(icon_name) != null:
		row.add_child(_icon(icon_name, 18, tip))
	elif icon_name != "":
		text = {"reinforce": "Reinf. ", "reserve": "Res. ", "favour": "Fav. "}[icon_name] + text
	var l := Label.new()
	l.text = text
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_theme_font_size_override("font_size", 12)
	row.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size.x = 4
	row.add_child(gap)


func _icon(icon_name: String, side: float, tip: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Looks.icon(icon_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # first, or the picture's own size stays the minimum
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(side, side)
	r.size = Vector2(side, side)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.tooltip_text = tip
	r.mouse_filter = Control.MOUSE_FILTER_PASS if tip != "" else Control.MOUSE_FILTER_IGNORE
	return r


func _texture(god_id: String) -> Texture2D:
	if not _portraits.has(god_id):
		var path := GodCatalog.portrait_path(god_id)
		_portraits[god_id] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[god_id]
