class_name PlayerPanel
extends PanelContainer
## Beside the map: one row per player in turn order with their colour, gods, territories, dice, the
## reinforcement they would get (largest region), reserve and favour (and in round 1 their head start). The player whose turn it is is
## framed; an eliminated player is dimmed. Hovering a god's portrait explains their powers.
##
## The rows are built once (again only if the players or their gods change); update() only changes
## their texts and looks, so it costs next to nothing after every battle (a phone notices).

const PORTRAIT := 34.0

var _list: VBoxContainer
var viewer: int = -1  ## under fog of war, whose eyes: the other players' dice are not shown
var _portraits: Dictionary = {}  ## god id -> Texture2D
var _rows: Array[_Row] = []
var _built_for := ""  ## the players and gods the rows were built for


## A god's portrait in a row: the picture, and while the god sleeps an eye and the conquests left.
class _Portrait:
	var holder: Control
	var pic: TextureRect
	var eye: Control
	var left: Label


class _Row:
	var panel: PanelContainer
	var box: StyleBoxFlat
	var name_label: Label
	var crown: Control
	var gods: Array[_Portrait] = []
	var stats: HBoxContainer
	var lands: Label
	var reinforce: Label
	var reserve: Label
	var favour: Label
	var note: Label


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
	var key := ""
	for p in state.players:
		key += "%s|%s|%s|%d;" % [p.name, p.primary, p.secondary, p.color_index]
	if key != _built_for:
		_build(state)
		_built_for = key
	var accent: Color = UiTheme.current_palette()["accent"]
	var leader := -1  # the player with the most territories wears the crown (none on a tie)
	var most := 0
	var lands := {}
	for q in state.alive_players():
		var n := state.territories_of(q).size()
		lands[q] = n
		if n > most:
			most = n
			leader = q
		elif n == most:
			leader = -1
	for p in state.players:
		var row := _rows[p.index]
		var active := p.index == state.current and not p.eliminated
		row.box.bg_color = Color(accent, 0.18) if active else Color(0, 0, 0, 0.22)
		row.box.border_color = accent if active else Color(1, 1, 1, 0.1)
		row.box.set_border_width_all(2 if active else 1)
		row.panel.modulate = Color(1, 1, 1, 0.4) if p.eliminated else Color.WHITE
		row.name_label.text = p.name + ("  (fallen)" if p.eliminated else "")
		if row.crown != null:
			row.crown.visible = p.index == leader
		_show_god(row.gods[0], p.primary, true, 0)
		_show_god(row.gods[1], p.secondary, p.secondary_awake, p.conquests)
		row.stats.visible = not p.eliminated
		# Under fog of war the number of lands stays public; another player's dice do not.
		var hidden := state.fog and viewer >= 0 and p.index != viewer
		var fog_tip := "Hidden by the fog of war" if hidden else ""
		if not p.eliminated:
			row.lands.text = "%d lands · %s dice" % [lands.get(p.index, 0), "?" if hidden else str(state.total_dice(p.index))]
			row.lands.tooltip_text = fog_tip
			_set_stat(row.reinforce, "+?" if hidden else "+%d" % state.reinforcement_preview(p.index), fog_tip if hidden else "Reinforcements at the end of the turn")
			_set_stat(row.reserve, "?" if hidden else str(p.reserve), fog_tip if hidden else "Reserve: dice waiting for room")
			_set_stat(row.favour, str(p.favor), "Favour: pays for miracles")
		var note := state.round_number == 1 and p.head_start > 0 and not hidden and not p.eliminated  # what made up for moving later
		row.note.visible = note
		if note:
			row.note.text = "Head start +%d dice" % p.head_start
			row.note.tooltip_text = "Moves %d of %d, so this player began with %d extra dice.
The later in the turn order, the bigger the head start." % [p.index + 1, state.players.size(), p.head_start]


## The rows, built for these players and gods.
func _build(state: MatchState) -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	var accent: Color = UiTheme.current_palette()["accent"]
	for p in state.players:
		var row := _Row.new()
		row.panel = PanelContainer.new()
		row.box = StyleBoxFlat.new()
		row.box.set_corner_radius_all(8)
		row.box.content_margin_left = 8
		row.box.content_margin_right = 8
		row.box.content_margin_top = 4
		row.box.content_margin_bottom = 4
		row.panel.add_theme_stylebox_override("panel", row.box)
		_list.add_child(row.panel)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		row.panel.add_child(col)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		col.add_child(head)
		var swatch := ColorRect.new()
		swatch.color = Looks.player_color(p.color_index)
		swatch.custom_minimum_size = Vector2(12, 12)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(swatch)
		row.name_label = Label.new()
		row.name_label.add_theme_font_size_override("font_size", 15)
		row.name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.name_label.clip_text = true
		head.add_child(row.name_label)
		if Looks.icon("crown") != null:
			row.crown = _icon("crown", 22, "Leads with the most territories")
			head.add_child(row.crown)
		for i in 2:
			var portrait := _portrait()
			head.add_child(portrait.holder)
			row.gods.append(portrait)
		row.stats = HBoxContainer.new()
		row.stats.add_theme_constant_override("separation", 4)
		row.stats.modulate = Color(1, 1, 1, 0.9)
		col.add_child(row.stats)
		row.lands = _stat(row.stats, "")
		row.reinforce = _stat(row.stats, "reinforce")
		row.reserve = _stat(row.stats, "reserve")
		row.favour = _stat(row.stats, "favour")
		row.note = Label.new()
		row.note.mouse_filter = Control.MOUSE_FILTER_PASS
		row.note.add_theme_font_size_override("font_size", 12)
		row.note.add_theme_color_override("font_color", accent)
		col.add_child(row.note)
		_rows.append(row)


func _portrait() -> _Portrait:
	var out := _Portrait.new()
	out.holder = Control.new()
	out.holder.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	out.holder.mouse_filter = Control.MOUSE_FILTER_PASS
	out.pic = TextureRect.new()
	out.pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	out.pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	out.pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	out.pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out.holder.add_child(out.pic)
	if Looks.icon("asleep") != null:
		out.eye = _icon("asleep", 18, "")
		out.eye.position = Vector2(PORTRAIT - 17, PORTRAIT - 15)
		out.holder.add_child(out.eye)
	out.left = Label.new()
	out.left.add_theme_font_size_override("font_size", 12)
	out.left.add_theme_color_override("font_outline_color", Color.BLACK)
	out.left.add_theme_constant_override("outline_size", 4)
	out.left.position = Vector2(3, PORTRAIT - 18)
	out.left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out.holder.add_child(out.left)
	return out


func _show_god(portrait: _Portrait, god_id: String, awake: bool, conquests: int) -> void:
	var g := GodCatalog.god(god_id)
	portrait.pic.texture = _texture(god_id)
	portrait.pic.modulate = Color.WHITE if awake else Color(0.35, 0.35, 0.4)
	var asleep := not awake and portrait.eye != null
	if portrait.eye != null:
		portrait.eye.visible = asleep
	portrait.left.visible = asleep
	portrait.left.text = str(MatchState.AWAKEN_CONQUESTS - conquests)
	var tip := "%s — %s\n%s: %s" % [g.get("name", ""), g.get("title", ""), g.get("boon_name", ""), g.get("boon_text", "")]
	if g.has("bane_name"):
		tip += "\n%s: %s" % [g["bane_name"], g["bane_text"]]
	if not awake:
		tip += "\n(Asleep: wakes after %d conquests — %d so far.)" % [MatchState.AWAKEN_CONQUESTS, conquests]
	portrait.holder.tooltip_text = tip


## An icon with a number after it (no icon art: a short word instead), e.g. the favour flame and "3".
## Returns the label of the number.
func _stat(row: HBoxContainer, icon_name: String) -> Label:
	if icon_name != "" and Looks.icon(icon_name) != null:
		row.add_child(_icon(icon_name, 18, ""))
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_theme_font_size_override("font_size", 12)
	if icon_name != "" and Looks.icon(icon_name) == null:
		l.set_meta("word", {"reinforce": "Reinf. ", "reserve": "Res. ", "favour": "Fav. "}[icon_name])
	row.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size.x = 4
	row.add_child(gap)
	return l


func _set_stat(l: Label, text: String, tip: String) -> void:
	l.text = str(l.get_meta("word", "")) + text
	l.tooltip_text = tip
	var icon := l.get_parent().get_child(l.get_index() - 1) if l.get_index() > 0 else null
	if icon is TextureRect:
		icon.tooltip_text = tip


func _icon(icon_name: String, side: float, tip: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Looks.icon(icon_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # first, or the picture's own size stays the minimum
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(side, side)
	r.size = Vector2(side, side)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.tooltip_text = tip
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


func _texture(god_id: String) -> Texture2D:
	if not _portraits.has(god_id):
		var path := GodCatalog.portrait_path(god_id)
		_portraits[god_id] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[god_id]
