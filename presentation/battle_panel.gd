class_name BattlePanel
extends PanelContainer
## The dice of a battle, shown over the bottom of the map: both armies' dice tumble (their faces flick
## through the skin's six pictures), settle on what was rolled, then the totals, the gods' bonuses and
## the outcome appear. A placeholder for the dice tower animation (see the design document §8.3).

const FACE := 44.0

var _rows: Array[HFlowContainer] = []
var _names: Array[Label] = []
var _totals: Array[Label] = []
var _mods: Array[Label] = []
var _verdict: Label
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	theme_type_variation = "TopBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_rng.randomize()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	for side in 2:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 2)
		row.add_child(box)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		box.add_child(head)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_label)
		var total := Label.new()
		total.add_theme_font_size_override("font_size", 26)
		head.add_child(total)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 3)
		flow.add_theme_constant_override("v_separation", 3)
		flow.custom_minimum_size = Vector2(4 * (FACE + 3), FACE)
		box.add_child(flow)
		var mods := Label.new()
		mods.add_theme_font_size_override("font_size", 13)
		mods.modulate = Color(1, 1, 1, 0.85)
		box.add_child(mods)
		_names.append(name_label)
		_totals.append(total)
		_rows.append(flow)
		_mods.append(mods)
		if side == 0:
			var vs := Label.new()
			vs.text = "vs"
			vs.add_theme_font_size_override("font_size", 18)
			vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			vs.modulate = Color(1, 1, 1, 0.6)
			row.add_child(vs)
	_verdict = Label.new()
	_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verdict.add_theme_font_size_override("font_size", 18)
	col.add_child(_verdict)


## Plays the battle `result` (from MatchState.attack); `speed` divides every duration.
func play(result: Dictionary, state: MatchState, speed: float) -> void:
	var sides := [[result["attacker"], result["attack_rolls"], result["attack_total"], result["modifiers"]["attack"]],
		[result["defender"], result["defense_rolls"], result["defense_total"], result["modifiers"]["defense"]]]
	var rects: Array = [[], []]
	var skins: Array[String] = []
	for i in 2:
		var player := state.players[sides[i][0]]
		var color := Looks.player_color(player.color_index)
		_names[i].text = player.name
		_names[i].add_theme_color_override("font_color", color.lightened(0.3))
		_totals[i].text = ""
		_mods[i].text = ""
		var skin: String = GodCatalog.pantheon(player.pantheon)["dice"]
		skins.append(skin)
		for c in _rows[i].get_children():
			c.queue_free()
		for v in sides[i][1]:
			var r := TextureRect.new()
			r.custom_minimum_size = Vector2(FACE, FACE)
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			r.texture = DiceArt.face(skin, _rng.randi_range(1, 6))
			r.pivot_offset = Vector2(FACE, FACE) / 2.0
			_rows[i].add_child(r)
			rects[i].append(r)
	_verdict.text = ""
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12 / speed)
	Sound.play("roll")
	# Tumble: faces flick and wobble, then settle left to right.
	var tumble := 0.55 / speed
	var elapsed := 0.0
	while elapsed < tumble:
		for i in 2:
			for r: TextureRect in rects[i]:
				r.texture = DiceArt.face(skins[i], _rng.randi_range(1, 6))
				r.rotation = _rng.randf_range(-0.35, 0.35)
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06
	for i in 2:
		for k in rects[i].size():
			var r: TextureRect = rects[i][k]
			r.texture = DiceArt.face(skins[i], sides[i][1][k])
			r.rotation = 0.0
		var parts: Array[String] = []
		for m in sides[i][3]:
			parts.append("%s %+d" % [m[0], m[1]])
		_mods[i].text = ", ".join(parts)
		_totals[i].text = str(sides[i][2])
	var won: bool = result["won"]
	var winner := 0 if won else 1
	_totals[winner].add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	_totals[1 - winner].add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_verdict.text = "Conquered!" if won else "Repelled!"
	await get_tree().create_timer(0.7 / speed).timeout


func hide_panel(speed: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15 / speed)
	tw.tween_callback(func() -> void: visible = false)
