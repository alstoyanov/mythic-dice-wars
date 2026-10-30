class_name PlayerPanel
extends PanelContainer
## Beside the map: one row per player in turn order with their colour, gods, territories, dice, the
## reinforcement they would get (largest region), reserve and favour. The player whose turn it is is
## framed; an eliminated player is dimmed. Hovering a god's portrait explains their powers.

const PORTRAIT := 34.0

var _list: VBoxContainer
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
		head.add_child(_portrait(p.primary, true, state))
		head.add_child(_portrait(p.secondary, p.secondary_awake, state, p.conquests))
		if p.eliminated:
			continue
		var stats := Label.new()
		stats.add_theme_font_size_override("font_size", 12)
		stats.modulate = Color(1, 1, 1, 0.85)
		stats.text = "Lands %d · Dice %d · +%d per turn\nReserve %d · Favour %d" % [
			state.territories_of(p.index).size(), state.total_dice(p.index),
			state.reinforcement_preview(p.index), p.reserve, p.favor]
		if not p.secondary_awake:
			stats.text += " · %s wakes in %d" % [GodCatalog.god(p.secondary).get("name", ""),
				MatchState.AWAKEN_CONQUESTS - p.conquests]
		col.add_child(stats)


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
	var tip := "%s — %s\n%s: %s" % [g.get("name", ""), g.get("title", ""), g.get("boon_name", ""), g.get("boon_text", "")]
	if g.has("bane_name"):
		tip += "\n%s: %s" % [g["bane_name"], g["bane_text"]]
	if not awake:
		tip += "\n(Asleep: wakes after %d conquests — %d so far.)" % [MatchState.AWAKEN_CONQUESTS, conquests]
	holder.tooltip_text = tip
	return holder


func _texture(god_id: String) -> Texture2D:
	if not _portraits.has(god_id):
		var path := GodCatalog.portrait_path(god_id)
		_portraits[god_id] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[god_id]
