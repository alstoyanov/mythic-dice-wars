class_name ScreenOverlay
extends Control
## A page over the whole screen while the war goes on underneath: a dimmed backdrop and a framed
## panel that fits the screen without scrolling (built at full size, then smaller until it fits, like
## the Book of the Gods). Its Back button, Esc and a phone's back gesture (the screen's go_back, see
## close_top) close it. Subclasses fill `col` in _build(); several can be open, the newest on top.

signal closed

const MIN_FIT := 0.55  ## a page shrinks to fit the screen down to this much of its size, no further

var col: VBoxContainer
var fit := 1.0  ## the page's size, made smaller until it fits the screen
var _center: CenterContainer
var _built_for := Vector2.ZERO


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # the map underneath is not touched
	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.02, 0.04, 0.82)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	var panel := PanelContainer.new()
	_center.add_child(panel)
	col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)


func _ready() -> void:
	Ui.on_resize(self, func() -> void:
		Ui.apply_safe_area(_center)
		if Ui.usable_size() != _built_for:  # a phone turned, a window resized: fit it again
			show_page())


## Builds the page at full size, then smaller until it fits; it fades in once it does.
func show_page() -> void:
	fit = 1.0
	_built_for = Ui.usable_size()
	col.modulate.a = 0.0
	rebuild()
	_fit_page.call_deferred()


## Builds the page again at its present size (its contents changed).
func rebuild() -> void:
	for c in col.get_children():
		col.remove_child(c)
		c.queue_free()
	_build()


## Fills `col` (subclasses), sized by k() and room().
func _build() -> void:
	pass


func _fit_page() -> void:
	while true:
		await get_tree().process_frame
		await get_tree().process_frame  # (wrapped text knows its height once laid out)
		if not is_inside_tree():
			return
		var panel := col.get_parent() as Control
		if panel.get_combined_minimum_size().y <= Ui.usable_size().y - 4.0 or fit <= MIN_FIT:
			break
		fit = maxf(MIN_FIT, fit - 0.07)
		rebuild()
	create_tween().tween_property(col, "modulate:a", 1.0, 0.15)


## The page's scale: the screen's (UiTheme.ui_scale) and the fitting's.
func k() -> float:
	return UiTheme.ui_scale() * fit


## The width the page's content may take (not too wide to read on a big screen).
func room() -> float:
	return minf(Ui.panel_content_width(), 1060.0 * UiTheme.ui_scale())


## A centered row with a Back button that closes the page; returns the row for more buttons.
func back_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(close)
	row.add_child(back)
	return row


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_top(get_parent())  # the newest page, whichever page hears the key first
		get_viewport().set_input_as_handled()


## Closes the newest page open in `parent`; returns it (null if none was open).
static func close_top(parent: Node) -> ScreenOverlay:
	for i in range(parent.get_child_count() - 1, -1, -1):
		var c := parent.get_child(i)
		if c is ScreenOverlay and not c.is_queued_for_deletion():
			(c as ScreenOverlay).close()
			return c
	return null
