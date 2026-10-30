class_name IconButton
extends Button
## A round button with an icon drawn in code (no image files), coloured from the current theme.
## `primary` makes it the main action of a screen (accent fill, larger).

enum Icon { PLAY, BACK, NEXT, CLOSE, SETTINGS, HELP, QUIT, INFO, SOUND, MUSIC, BOOK, CREATURE, RESTART, ONLINE, PLAYERS }

var icon_kind: Icon = Icon.PLAY
var primary: bool = false


class Glyph extends Control:
	var kind: IconButton.Icon = IconButton.Icon.PLAY
	var is_primary: bool = false

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var p := UiTheme.current_palette()
		var col: Color = p["button"] if is_primary else p["accent"]
		if is_primary:
			col = p["bg_bottom"]
		var c := size / 2.0
		var r := minf(size.x, size.y) * 0.24
		match kind:
			IconButton.Icon.PLAY:  # right-pointing triangle, nudged right so it looks centred
				var o := Vector2(r * 0.15, 0.0)
				draw_colored_polygon(PackedVector2Array([
					c + o + Vector2(-r * 0.8, -r), c + o + Vector2(r * 1.1, 0.0), c + o + Vector2(-r * 0.8, r)]), col)
			IconButton.Icon.NEXT:  # arrow pointing right
				var w := maxf(3.0, r * 0.32)
				draw_line(c + Vector2(-r, 0.0), c + Vector2(r * 0.85, 0.0), col, w, true)
				draw_line(c + Vector2(r * 0.85, 0.0), c + Vector2(r * 0.1, -r * 0.85), col, w, true)
				draw_line(c + Vector2(r * 0.85, 0.0), c + Vector2(r * 0.1, r * 0.85), col, w, true)
			IconButton.Icon.SETTINGS:  # a gear: ring with eight teeth
				var w := maxf(2.5, r * 0.28)
				draw_arc(c, r * 0.62, 0.0, TAU, 32, col, w, true)
				draw_circle(c, r * 0.2, col)
				for i in 8:
					var d := Vector2.from_angle(i * TAU / 8.0)
					draw_line(c + d * r * 0.8, c + d * r * 1.2, col, w * 1.3, true)
			IconButton.Icon.HELP:  # a question mark
				var w := maxf(2.5, r * 0.3)
				draw_arc(c + Vector2(0.0, -r * 0.35), r * 0.55, PI * 1.05, PI * 2.0 + PI * 0.55, 24, col, w, true)
				draw_line(c + Vector2(r * 0.2, r * 0.05), c + Vector2(0.0, r * 0.3), col, w, true)
				draw_line(c + Vector2(0.0, r * 0.3), c + Vector2(0.0, r * 0.5), col, w, true)
				draw_circle(c + Vector2(0.0, r * 0.95), w * 0.7, col)
			IconButton.Icon.QUIT:  # a power symbol
				var w := maxf(2.5, r * 0.3)
				draw_arc(c, r * 0.95, -PI / 2.0 + 0.6, -PI / 2.0 + TAU - 0.6, 32, col, w, true)
				draw_line(c + Vector2(0.0, -r * 1.15), c + Vector2(0.0, -r * 0.1), col, w, true)
			IconButton.Icon.INFO:  # a circled "i"
				var w := maxf(2.5, r * 0.28)
				draw_arc(c, r * 1.05, 0.0, TAU, 32, col, w, true)
				draw_circle(c + Vector2(0.0, -r * 0.5), w * 0.75, col)
				draw_line(c + Vector2(0.0, -r * 0.1), c + Vector2(0.0, r * 0.55), col, w * 1.2, true)
			IconButton.Icon.SOUND:  # a speaker with two waves
				var w := maxf(2.5, r * 0.26)
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-r * 1.0, -r * 0.35), c + Vector2(-r * 0.45, -r * 0.35), c + Vector2(r * 0.1, -r * 0.9),
					c + Vector2(r * 0.1, r * 0.9), c + Vector2(-r * 0.45, r * 0.35), c + Vector2(-r * 1.0, r * 0.35)]), col)
				draw_arc(c + Vector2(r * 0.1, 0.0), r * 0.65, -0.75, 0.75, 12, col, w, true)
				draw_arc(c + Vector2(r * 0.1, 0.0), r * 1.1, -0.75, 0.75, 12, col, w, true)
			IconButton.Icon.MUSIC:  # a musical note
				var w := maxf(2.5, r * 0.28)
				draw_circle(c + Vector2(-r * 0.35, r * 0.75), r * 0.4, col)
				draw_line(c + Vector2(r * 0.03, r * 0.7), c + Vector2(r * 0.03, -r * 1.0), col, w, true)
				draw_line(c + Vector2(r * 0.03, -r * 1.0), c + Vector2(r * 0.8, -r * 0.5), col, w * 1.3, true)
			IconButton.Icon.CLOSE:  # a cross
				var w := maxf(3.0, r * 0.32)
				draw_line(c + Vector2(-r, -r) * 0.8, c + Vector2(r, r) * 0.8, col, w, true)
				draw_line(c + Vector2(-r, r) * 0.8, c + Vector2(r, -r) * 0.8, col, w, true)
			IconButton.Icon.BOOK:  # an open book
				var w := maxf(2.0, r * 0.2)
				for side in [-1.0, 1.0]:
					draw_polyline(PackedVector2Array([c + Vector2(0.0, -r * 0.6), c + Vector2(side * r * 1.1, -r * 0.8),
						c + Vector2(side * r * 1.1, r * 0.7), c + Vector2(0.0, r * 0.9), c + Vector2(0.0, -r * 0.6)]), col, w, true)
					for k in 3:
						var y := -r * 0.35 + k * r * 0.35
						draw_line(c + Vector2(side * r * 0.25, y), c + Vector2(side * r * 0.85, y - r * 0.12), col, w * 0.6, true)
			IconButton.Icon.CREATURE:  # a paw print
				draw_circle(c + Vector2(0.0, r * 0.45), r * 0.55, col)
				for k in 4:
					var a := deg_to_rad(-150.0 + k * 40.0)
					draw_circle(c + Vector2(0.0, r * 0.3) + Vector2.from_angle(a) * r * 1.0, r * 0.24, col)
			IconButton.Icon.RESTART:  # a circular arrow
				var w := maxf(3.0, r * 0.3)
				draw_arc(c, r * 0.85, -PI * 0.35, PI * 1.45, 28, col, w, true)
				var tip := c + Vector2.from_angle(-PI * 0.35) * r * 0.85
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-r * 0.55, -r * 0.1), tip + Vector2(r * 0.25, -r * 0.45),
					tip + Vector2(r * 0.15, r * 0.4)]), col)
			IconButton.Icon.ONLINE:  # a globe: outline, a meridian and two parallels
				var w := maxf(2.0, r * 0.2)
				draw_arc(c, r * 1.05, 0.0, TAU, 32, col, w, true)
				var meridian := PackedVector2Array()
				for i in 25:
					var a := i * TAU / 24.0
					meridian.append(c + Vector2(cos(a) * r * 0.45, sin(a) * r * 1.05))
				draw_polyline(meridian, col, w, true)
				draw_line(c + Vector2(-r * 1.05, 0.0), c + Vector2(r * 1.05, 0.0), col, w, true)
				for y in [-0.55, 0.55]:
					var half := sqrt(1.0 - y * y) * r * 1.05 * 0.92
					draw_line(c + Vector2(-half, y * r), c + Vector2(half, y * r), col, w * 0.8, true)
			IconButton.Icon.PLAYERS:  # two people, one behind the other: other players' games, friends
				for k in 2:
					var o := Vector2(-r * 0.5, -r * 0.18) if k == 0 else Vector2(r * 0.3, r * 0.12)
					var s := 0.8 if k == 0 else 1.0
					var tone := Color(col, 0.6) if k == 0 else col
					draw_circle(c + o + Vector2(0.0, -r * 0.42 * s), r * 0.36 * s, tone)
					var shoulders := PackedVector2Array()
					for i in 13:
						var a := PI + i * PI / 12.0
						shoulders.append(c + o + Vector2(cos(a) * r * 0.68 * s, r * 0.78 * s + sin(a) * r * 0.6 * s))
					draw_colored_polygon(shoulders, tone)
			IconButton.Icon.BACK:  # arrow pointing left
				var w := maxf(3.0, r * 0.32)
				draw_line(c + Vector2(r, 0.0), c + Vector2(-r * 0.85, 0.0), col, w, true)
				draw_line(c + Vector2(-r * 0.85, 0.0), c + Vector2(-r * 0.1, -r * 0.85), col, w, true)
				draw_line(c + Vector2(-r * 0.85, 0.0), c + Vector2(-r * 0.1, r * 0.85), col, w, true)
		# A switched-off sound or music button is crossed out.
		var button := get_parent() as BaseButton
		if (kind == IconButton.Icon.SOUND or kind == IconButton.Icon.MUSIC) \
				and button != null and button.toggle_mode and not button.button_pressed:
			draw_line(c + Vector2(-r, r) * 1.1, c + Vector2(r, -r) * 1.1, col, maxf(3.0, r * 0.3), true)


## Just the drawn icon, without the round button (a label-like symbol), `size` units square.
static func glyph(kind: Icon, size: float, tip: String = "") -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.tooltip_text = tip
	var g := Glyph.new()
	g.kind = kind
	holder.add_child(g)
	return holder


func _init(kind: Icon = Icon.PLAY, is_primary: bool = false, tip: String = "") -> void:
	icon_kind = kind
	primary = is_primary
	tooltip_text = tip
	theme_type_variation = "IconButtonPrimary" if is_primary else "IconButton"
	custom_minimum_size = Vector2(76, 76) if is_primary else Vector2(60, 60)
	focus_mode = Control.FOCUS_NONE
	var g := Glyph.new()
	g.kind = kind
	g.is_primary = is_primary
	add_child(g)
	toggled.connect(func(_on: bool) -> void: g.queue_redraw())  # the crossed-out look follows the state
	Ui.hover_effect(self, _click_sound(kind))


## The sound a button makes when pressed (see Sound.SOUNDS).
static func _click_sound(kind: Icon) -> String:
	match kind:
		Icon.PLAY:
			return "start"
		Icon.BACK, Icon.CLOSE:
			return "back"
		Icon.RESTART:
			return "start"
		Icon.SOUND, Icon.MUSIC:
			return "toggle"
	return "click"
