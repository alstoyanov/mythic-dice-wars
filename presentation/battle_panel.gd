class_name BattlePanel
extends Control
## A battle, shown over the whole screen. The map dims, the attacker slides in from the left and the
## defender from the right (on a tall screen: from the top and the bottom), each with their pantheon's
## dice tower (Looks.tower; a pantheon without one borrows another's). The dice tumble out of the
## tower's arch into the tray, their faces flicking through the skin's six pictures, and settle on what
## was rolled; both rolls stay in view. Each side's total is then taken apart: the dice, every god's
## bonus or penalty by name, and what the gods did to the dice themselves (a 1 rolled again is marked
## on the die). The outcome follows, with what the gods did after the battle. The result stays for a
## while (Settings) or until the player presses Continue (hold()); then everything fades back to the map.

signal accepted

## Sizes in "arena units"; the whole arena is scaled to the room on screen.
const ARENA := Vector2(236.0, 224.0)
const TOWER_H := 168.0
const TRAY_W := 206.0
const DIE_MAX := 52.0  ## a die in the tray when there are only a few (they shrink to fit up to ten)
const FACE := 44.0  ## a die in the plain row (no tower art)
const PLUS := Color(0.72, 1.0, 0.72)
const MINUS := Color(1.0, 0.62, 0.58)
const NOTE := Color(0.8, 0.88, 1.0)
const GOLD := Color(1.0, 0.86, 0.35)
const MARGIN := 24.0

var waiting := false  ## showing a result until Continue is pressed

var _scrim: ColorRect
var _stage: Control  ## everything but the scrim; rebuilt for every battle (it depends on the screen's shape)
var _continue: Button
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # the map underneath is not clickable during a battle
	_rng.randomize()
	_scrim = ColorRect.new()
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.color = Color(0.02, 0.02, 0.04, 0.94)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)


func _gui_input(event: InputEvent) -> void:
	if waiting and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept()


## Plays the battle `result` (from MatchState.attack); `speed` divides every animation.
func play(result: Dictionary, state: MatchState, speed: float) -> void:
	for c in _stage.get_children():
		c.queue_free()
	var sides := [
		[result["attacker"], result["attack_rolls"], result["attack_total"], result["modifiers"]["attack"],
			result.get("attack_rerolled", []), result.get("notes", {}).get("attack", [])],
		[result["defender"], result["defense_rolls"], result["defense_total"], result["modifiers"]["defense"],
			result.get("defense_rerolled", []), result.get("notes", {}).get("defense", [])]]
	var room := size
	var tall := room.y > room.x * 1.1
	var bottom := 150.0 if not tall else 140.0  # the verdict, the after-effects and Continue
	var halves: Array[Rect2] = []
	if tall:
		var h := (room.y - bottom - MARGIN) / 2.0
		halves = [Rect2(MARGIN, MARGIN * 0.5, room.x - 2.0 * MARGIN, h), Rect2(MARGIN, MARGIN * 0.5 + h, room.x - 2.0 * MARGIN, h)]
	else:
		var w := (room.x - 3.0 * MARGIN) / 2.0
		halves = [Rect2(MARGIN, MARGIN, w, room.y - bottom - MARGIN), Rect2(2.0 * MARGIN + w, MARGIN, w, room.y - bottom - MARGIN)]

	var dice: Array = [[], []]
	var skins: Array[String] = []
	var totals: Array[Label] = []
	var breakdowns: Array[VBoxContainer] = []
	var side_nodes: Array[Control] = []
	var big := 1.0 if not tall else 0.8  # text size
	for i in 2:
		var player := state.players[sides[i][0]]
		var skin: String = GodCatalog.pantheon(player.pantheon)["dice"]
		skins.append(skin)
		var half := halves[i]
		var side := Control.new()
		side.position = half.position
		side.size = half.size
		side.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(side)
		side_nodes.append(side)
		# Header: name, sword or shield, total.
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		head.size = Vector2(half.size.x, 56.0 * big)
		head.alignment = BoxContainer.ALIGNMENT_CENTER
		side.add_child(head)
		var name_label := Label.new()
		name_label.text = player.name
		name_label.add_theme_font_size_override("font_size", roundi(28 * big))
		name_label.add_theme_color_override("font_color", Looks.player_color(player.color_index).lightened(0.3))
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.add_theme_constant_override("outline_size", 6)
		head.add_child(name_label)
		var icon_tex := Looks.icon("attack" if i == 0 else "defence")
		if icon_tex != null:
			var icon := TextureRect.new()
			icon.texture = icon_tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(40, 40) * big
			head.add_child(icon)
		var total := Label.new()
		total.add_theme_font_size_override("font_size", roundi(52 * big))
		total.add_theme_color_override("font_outline_color", Color.BLACK)
		total.add_theme_constant_override("outline_size", 8)
		total.custom_minimum_size.x = 70 * big
		head.add_child(total)
		totals.append(total)
		# The arena (tower, tray, dice), as big as the half allows after the header and the breakdown.
		var lines: int = 1 + sides[i][3].size() + sides[i][5].size()
		var text_h: float = (22.0 * big) * lines + 10.0
		var avail := Vector2(half.size.x * 0.92, half.size.y - head.size.y - text_h)
		var art := Looks.tower(player.pantheon)
		var k := clampf(minf(avail.x / ARENA.x, avail.y / ARENA.y), 0.5, 3.2)
		var arena := Control.new()
		arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
		side.add_child(arena)
		var arena_size: Vector2
		if art.is_empty():
			arena_size = Vector2(avail.x, minf(avail.y, FACE * k * 2.4))
			arena.position = Vector2((half.size.x - arena_size.x) / 2.0, head.size.y)
			for n in sides[i][1].size():
				var r := _die(FACE * k, skin)
				arena.add_child(r)
				var per_row := maxi(1, int(arena_size.x / (FACE * k * 1.1)))
				r.position = Vector2((n % per_row) * FACE * k * 1.1, (n / per_row) * FACE * k * 1.1)
				dice[i].append(r)
		else:
			arena_size = ARENA * k
			arena.position = Vector2((half.size.x - arena_size.x) / 2.0, head.size.y)
			dice[i] = _build_arena(arena, art, sides[i][1].size(), skin, k)
		var breakdown := VBoxContainer.new()
		breakdown.add_theme_constant_override("separation", 0)
		breakdown.position = Vector2(half.size.x * 0.1, head.size.y + arena_size.y + 6.0)
		breakdown.size = Vector2(half.size.x * 0.8, text_h)
		side.add_child(breakdown)
		breakdowns.append(breakdown)
	# "vs" between the two sides.
	var vs := Label.new()
	vs.text = "VS"
	vs.add_theme_font_size_override("font_size", roundi(40 * big))
	vs.add_theme_color_override("font_color", GOLD)
	vs.add_theme_color_override("font_outline_color", Color.BLACK)
	vs.add_theme_constant_override("outline_size", 8)
	vs.size = Vector2(120, 60)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.position = (Vector2(room.x - MARGIN - 50.0, halves[1].position.y) if tall else Vector2(room.x / 2.0, room.y * 0.4)) - vs.size / 2.0
	vs.pivot_offset = vs.size / 2.0
	_stage.add_child(vs)
	# Bottom: the verdict, what the gods did afterwards, Continue.
	var foot := VBoxContainer.new()
	foot.add_theme_constant_override("separation", 2)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.position = Vector2(MARGIN, room.y - bottom)
	foot.size = Vector2(room.x - 2.0 * MARGIN, bottom - 8.0)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(foot)
	var verdict := Label.new()
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.add_theme_font_size_override("font_size", roundi(40 * big))
	verdict.add_theme_color_override("font_outline_color", Color.BLACK)
	verdict.add_theme_constant_override("outline_size", 8)
	foot.add_child(verdict)
	var after := VBoxContainer.new()
	after.add_theme_constant_override("separation", 0)
	foot.add_child(after)
	_continue = Button.new()
	_continue.text = "Continue"
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.custom_minimum_size = Vector2(180, 44)
	_continue.modulate.a = 0.0
	_continue.disabled = true
	_continue.pressed.connect(accept)
	Ui.hover_effect(_continue)
	foot.add_child(_continue)

	# Entrance: the map dims, the two sides slide in, "VS" pops.
	visible = true
	modulate.a = 1.0
	_scrim.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_scrim, "modulate:a", 1.0, 0.25 / speed)
	for i in 2:
		var s := side_nodes[i]
		var home := s.position
		s.position += (Vector2(0.0, -room.y * 0.5) if tall else Vector2(-room.x * 0.5, 0.0)) * (1.0 if i == 0 else -1.0)
		s.modulate.a = 0.0
		tw.tween_property(s, "position", home, 0.4 / speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 1.0, 0.3 / speed)
	vs.scale = Vector2.ZERO
	tw.tween_property(vs, "scale", Vector2.ONE, 0.35 / speed).set_delay(0.2 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.3 / speed).timeout
	Sound.play("roll")
	for i in 2:
		_drop_dice(dice[i], i * 0.05 / speed, speed)

	# Tumble: faces flick and wobble while the dice drop into their trays.
	var tumble := 0.8 / speed
	var elapsed := 0.0
	while elapsed < tumble:
		for i in 2:
			for r: TextureRect in dice[i]:
				r.texture = DiceArt.face(skins[i], _rng.randi_range(1, 6))
				r.rotation = _rng.randf_range(-0.5, 0.5)
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06
	for i in 2:
		var rerolled: Array = sides[i][4]
		for k in dice[i].size():
			var r: TextureRect = dice[i][k]
			r.texture = DiceArt.face(skins[i], sides[i][1][k])
			r.rotation = 0.0
			if k < rerolled.size() and rerolled[k]:
				_mark_reroll(r, sides[i][5])
		var notes: Array = sides[i][5].duplicate()
		if not rerolled.has(true):  # say so when a reroll rule had nothing to do
			notes = notes.map(func(n: String) -> String: return n + " (no 1s this time)" if n.ends_with("1s rolled again") else n)
		_fill_breakdown(breakdowns[i], sides[i][1], sides[i][3], notes, big)
		totals[i].text = str(sides[i][2])
	var won: bool = result["won"]
	var winner := 0 if won else 1
	totals[winner].add_theme_color_override("font_color", GOLD)
	totals[1 - winner].add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	verdict.text = "Conquered!" if won else "Repelled!"
	verdict.add_theme_color_override("font_color", GOLD if won else Color(0.85, 0.9, 1.0))
	verdict.pivot_offset = Vector2(foot.size.x / 2.0, 24.0)
	verdict.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(verdict, "scale", Vector2.ONE, 0.3 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tie: String = result.get("tie", "")
	if tie != "":
		_line(after, tie, NOTE, roundi(17 * big), HORIZONTAL_ALIGNMENT_CENTER)
	for text: String in result.get("after", []):
		_line(after, text, PLUS if "+" in text else MINUS, roundi(17 * big), HORIZONTAL_ALIGNMENT_CENTER)


## Keeps the result on screen for `seconds`, or with GameSettings.WAIT until Continue is pressed
## (or accept() is called: a click anywhere, Enter or Space).
func hold(seconds: float) -> void:
	if seconds != GameSettings.WAIT:
		await get_tree().create_timer(seconds).timeout
		return
	waiting = true
	_continue.disabled = false
	create_tween().tween_property(_continue, "modulate:a", 1.0, 0.2)
	_continue.grab_focus.call_deferred()
	await accepted
	waiting = false


func accept() -> void:
	if waiting:
		accepted.emit()


## Fades back to the map.
func hide_panel(speed: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25 / speed)
	await tw.finished
	visible = false
	modulate.a = 1.0


## Where a side's total comes from: the dice, then each god's bonus or penalty by name, then what the
## gods did to the dice themselves.
func _fill_breakdown(box: VBoxContainer, rolls: Array, mods: Array, notes: Array, big: float) -> void:
	var dice_sum := 0
	for v in rolls:
		dice_sum += v
	_line(box, "%d  from the dice" % dice_sum, Color(1, 1, 1, 0.9), roundi(18 * big))
	for m in mods:
		_line(box, "%+d  %s" % [m[1], m[0]], PLUS if m[1] > 0 else MINUS, roundi(18 * big))
	for n: String in notes:
		_line(box, n, NOTE, roundi(16 * big))


func _line(box: Control, text: String, color: Color, font_size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	box.add_child(l)


## A die whose 1 a god had rolled again: a gold frame and a small "1→" in its corner.
func _mark_reroll(r: TextureRect, notes: Array) -> void:
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = GOLD
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", box)
	r.add_child(frame)
	var was := Label.new()
	was.text = "1→"
	was.add_theme_font_size_override("font_size", maxi(11, roundi(r.size.x * 0.28)))
	was.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	was.add_theme_color_override("font_outline_color", Color.BLACK)
	was.add_theme_constant_override("outline_size", 5)
	was.position = Vector2(-6, -r.size.x * 0.32)
	was.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(was)
	r.tooltip_text = "Rolled a 1, rolled again. " + " ".join(notes)


func _die(side: float, skin: String) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(side, side)
	r.size = Vector2(side, side)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.texture = DiceArt.face(skin, _rng.randi_range(1, 6))
	r.pivot_offset = Vector2(side, side) / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


## Lays out one side's tower, tray, dice and the tray's rim at scale `k`. The dice wait in the tower's
## arch (see _drop_dice) and remember their places in the tray. Returns the dice.
func _build_arena(arena: Control, art: Dictionary, count: int, skin: String, k: float) -> Array:
	var area := ARENA * k
	arena.custom_minimum_size = area
	arena.size = area
	var tower: Texture2D = art["tower"]
	var tray: Texture2D = art["tray"]
	var tower_size := Vector2(TOWER_H * tower.get_width() / float(tower.get_height()), TOWER_H) * k
	var tray_size := Vector2(TRAY_W, TRAY_W * tray.get_height() / float(tray.get_width())) * k
	var tray_pos := Vector2((area.x - tray_size.x) / 2.0, area.y - tray_size.y)
	_picture(arena, tower, Rect2(Vector2((area.x - tower_size.x) / 2.0, 0.0), tower_size))
	_picture(arena, tray, Rect2(tray_pos, tray_size))
	var dice_layer := Control.new()
	dice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(dice_layer)
	if art.has("tray_front"):
		var front: Texture2D = art["tray_front"]
		var front_size := Vector2(tray_size.x, tray_size.x * front.get_height() / float(front.get_width()))
		_picture(arena, front, Rect2(Vector2(tray_pos.x, area.y - front_size.y), front_size))
	# Places in the tray: one row for up to five dice; more go in two staggered rows (the back row a
	# little smaller and higher). The dice are as big as the spacing allows.
	var centre := tray_pos + Vector2(tray_size.x / 2.0, tray_size.y * 0.42)
	var reach := tray_size.x * 0.33
	var two_rows := count > 5
	var back := ceili(count / 2.0) if two_rows else count
	var front := count - back
	var step := 0.0
	if two_rows:
		step = 2.0 * reach / (back - 0.5 if front == back else back - 1.0)
	elif count > 1:
		step = 2.0 * reach / (count - 1.0)
	var die := DIE_MAX * k if step == 0.0 else minf(DIE_MAX * k, step * 0.94)
	if not two_rows and count > 1:
		reach = step * (count - 1) / 2.0
	var spawn := Vector2(area.x / 2.0, tower_size.y * 0.86)
	var out: Array = []
	for i in count:
		var in_back := i < back
		var j := i if in_back else i - back
		var x := centre.x - reach + j * step + (0.0 if in_back else step / 2.0)
		if count == 1:
			x = centre.x
		var y := centre.y
		if two_rows:
			y += -tray_size.y * 0.15 if in_back else tray_size.y * 0.1
		var side := die * (0.92 if in_back and two_rows else 1.0)
		var r := _die(side, skin)
		dice_layer.add_child(r)
		r.position = spawn - Vector2(side, side) / 2.0
		r.scale = Vector2(0.4, 0.4)
		r.modulate.a = 0.0
		r.set_meta("goal", Vector2(x, y) - Vector2(side, side) / 2.0)
		r.set_meta("hop", 26.0 * k)
		out.append(r)
	return out


## Sends the dice from the tower's arch hopping into their places (one after another).
func _drop_dice(dice: Array, delay: float, speed: float) -> void:
	for i in dice.size():
		var r: TextureRect = dice[i]
		if not r.has_meta("goal"):
			continue
		var start := r.position
		var goal: Vector2 = r.get_meta("goal")
		var hop: float = r.get_meta("hop")
		var tw := r.create_tween()
		tw.tween_interval(delay + 0.05 * i / speed)
		tw.tween_callback(func() -> void: r.modulate.a = 1.0)
		tw.tween_method(func(t: float) -> void:
			r.position = start.lerp(goal, t) - Vector2(0.0, sin(t * PI) * hop)
			r.scale = Vector2.ONE * lerpf(0.4, 1.0, t), 0.0, 1.0, 0.45 / speed).set_ease(Tween.EASE_OUT)


func _picture(parent: Control, tex: Texture2D, rect: Rect2) -> void:
	var p := TextureRect.new()
	p.texture = tex
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_SCALE
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
