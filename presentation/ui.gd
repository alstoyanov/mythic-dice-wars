class_name Ui
extends RefCounted
## Helpers for building the menus in code. The look comes from UiTheme.


## Call first in a screen's _ready(): applies the theme, adds the backdrop behind everything and
## fades the screen in. Returns the backdrop so the screen can re-tint it (see retheme()).
static func setup_screen(root: Control, animated: bool = true) -> MenuBackdrop:
	GameSettings.ensure_loaded()
	root.theme = UiTheme.current()
	var window := root.get_window()
	var on_resize := func() -> void: root.theme = UiTheme.current()
	window.size_changed.connect(on_resize)
	root.tree_exiting.connect(func() -> void: window.size_changed.disconnect(on_resize))
	var backdrop := MenuBackdrop.new()
	backdrop.animated = animated
	backdrop.set_look(UiTheme.current_palette(), UiTheme.current_ui())
	root.add_child(backdrop)
	root.move_child(backdrop, 0)
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.25)
	return backdrop


## Re-applies the theme after the look changed (Settings).
static func retheme(root: Control, backdrop: MenuBackdrop) -> void:
	root.theme = UiTheme.current()
	backdrop.set_look(UiTheme.current_palette(), UiTheme.current_ui())


## Adds a centered framed panel with a vertical column to `parent` and returns the column.
static func centered_column(parent: Control, separation: int = 12) -> VBoxContainer:
	# Inside a scroll area: when the window or screen is smaller than the panel, it can be scrolled
	# (by dragging on a touch screen) instead of being cut off.
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	parent.add_child(scroll)
	on_resize(scroll, func() -> void: apply_safe_area(scroll))  # the notch moves when the phone is rotated
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	on_resize(col, func() -> void: col.add_theme_constant_override("separation", mini(separation, 8) if is_short() else separation))
	return col


## Space to keep free around the screen's edges on a phone or tablet (notch, rounded corners, gesture
## bar), as left, top, right, bottom in scaled units. All zero on a computer.
static func safe_margins() -> Vector4:
	if not AppWindow.is_mobile():
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var factor := maxf(1.0, Engine.get_main_loop().root.content_scale_factor)
	return Vector4(safe.position.x, safe.position.y, screen.x - safe.end.x, screen.y - safe.end.y) / factor


## Pulls a full-screen Control in from the unsafe edges (see safe_margins).
static func apply_safe_area(control: Control) -> void:
	var m := safe_margins()
	control.offset_left = m.x
	control.offset_top = m.y
	control.offset_right = -m.z
	control.offset_bottom = -m.w


## Below this width (in scaled units) menus stack their columns: a phone held upright, a narrow window.
const NARROW_WIDTH := 720.0
## Below this height game screens put the board beside their controls: a phone held sideways.
const SHORT_HEIGHT := 600.0


## The part of the screen that can be used, in scaled units (the window minus notch and gesture bar).
static func usable_size() -> Vector2:
	var root := (Engine.get_main_loop() as SceneTree).root
	var m := safe_margins()
	return root.get_visible_rect().size - Vector2(m.x + m.z, m.y + m.w)


static func is_narrow() -> bool:
	return usable_size().x < NARROW_WIDTH


static func is_short() -> bool:
	return usable_size().y < SHORT_HEIGHT


## Narrow or short: menus use smaller titles and margins (see UiTheme).
static func is_compact() -> bool:
	return is_narrow() or is_short()


## Little height but plenty of width (a phone held sideways): menus put things side by side.
static func is_sideways() -> bool:
	var room := usable_size()
	return room.y < SHORT_HEIGHT and room.x > room.y * 1.3


## Calls `apply` now and again whenever the screen changes size (window resized, phone rotated) while
## `node` is in the tree, and when it is moved to another parent. `node` must already be in the tree.
static func on_resize(node: Node, apply: Callable) -> void:
	var viewport := node.get_viewport()
	var handler := func() -> void: apply.call()
	var follow := func() -> void:
		if not viewport.size_changed.is_connected(handler):
			viewport.size_changed.connect(handler)
		apply.call()
	node.tree_entered.connect(follow)
	node.tree_exiting.connect(func() -> void:
		if viewport.size_changed.is_connected(handler):
			viewport.size_changed.disconnect(handler))
	follow.call()


## Room for content inside a centered framed panel (see centered_column) on this screen.
static func panel_content_width() -> float:
	var margin := 16.0 if is_compact() else 26.0  # the panel's inner margin, see UiTheme.build
	return usable_size().x - 2.0 * margin - 16.0


## Shrinks the label's font (from `font_size` down to `min_size`) until its text fits `max_width`.
## If even the smallest size is too wide, the text wraps onto more lines.
static func fit_font(label: Label, font_size: int, max_width: float, min_size: int = 12) -> void:
	var font := label.get_theme_font("font")
	var fs := font_size
	while fs > min_size and font.get_string_size(label.atr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_width:
		fs -= 1
	label.add_theme_font_size_override("font_size", fs)
	var fits := font.get_string_size(label.atr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_width
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if fits else TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 0.0 if fits else max_width


## A label in a centered panel that wraps onto more lines rather than making the panel wider than the screen.
static func wrap_to_screen(label: Label) -> void:
	on_resize(label, func() -> void:
		var font := label.get_theme_font("font")
		var fs := label.get_theme_font_size("font_size")
		var natural := font.get_string_size(label.atr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 4.0
		var room := panel_content_width()
		label.autowrap_mode = TextServer.AUTOWRAP_OFF if natural <= room else TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 0.0 if natural <= room else room)


## A row that turns into a column on a narrow screen (and back when there is room again).
## `column_separation`: the gap once it is a column (default: the same as in the row).
static func flip_row(parent: Control, separation: int, column_separation: int = -1) -> BoxContainer:
	var box := BoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(box)
	on_resize(box, func() -> void:
		box.vertical = is_narrow()
		box.add_theme_constant_override("separation",
			column_separation if box.vertical and column_separation >= 0 else separation))
	return box


## A font size that grows with the window like the theme's text (`size` at the default 900x700).
static func scaled_font(control: Control, size: int, key: String = "font_size") -> void:
	on_resize(control, func() -> void: control.add_theme_font_size_override(key, roundi(size * UiTheme.ui_scale())))


static func title(col: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "TitleLabel"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	wrap_to_screen(l)


## A centered row with a round Back button and a larger round Start button. Returns the row.
static func start_back_row(col: Control, on_start: Callable, on_back: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(on_back)
	row.add_child(back)
	var start := IconButton.new(IconButton.Icon.PLAY, true, "Start")
	start.pressed.connect(on_start)
	row.add_child(start)
	return row


## Buttons lift slightly under the mouse and make a small sound: a tick when the mouse arrives and
## `click_sound` (a name from Sound.SOUNDS) when pressed.
static func hover_effect(b: Control, click_sound: String = "click") -> void:
	if b is BaseButton:
		var button := b as BaseButton
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				Sound.play("hover"))
		button.pressed.connect(func() -> void: Sound.play(click_sound))
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2(1.04, 1.04), 0.08))
	b.mouse_exited.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08))


## Makes a toggle button (in a ButtonGroup) show clearly whether it is the chosen one: a frame in the
## accent colour when chosen, the others dimmed.
static func mark_choice(b: Button) -> void:
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = UiTheme.current_palette()["accent"].lightened(0.2)
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.expand_margin_left = 2
	box.expand_margin_right = 2
	box.expand_margin_top = 2
	box.expand_margin_bottom = 2
	frame.add_theme_stylebox_override("panel", box)
	b.add_child(frame)
	var show := func(on: bool) -> void:
		frame.visible = on
		b.modulate = Color.WHITE if on else Color(0.68, 0.68, 0.68)
	b.toggled.connect(show)
	show.call(b.button_pressed)


static func button(col: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 44)
	b.pressed.connect(on_press)
	hover_effect(b)
	col.add_child(b)
	return b
