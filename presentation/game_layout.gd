class_name GameLayout
extends MarginContainer
## The frame shared by the Solo and Battle screens: a framed bar of texts (fill `info`), the board, an
## optional side panel (the move log) and the buttons (fill `buttons`; they wrap onto a second line
## when there is no room).
##
## An upright or roomy screen gets the texts on top, the board in the middle with the side panel
## beside it and the buttons at the bottom. A short, wide screen (a phone held sideways) gets the board
## at full height on the left, with the texts, side panel and buttons stacked on the right. The layout
## follows the window when it is resized or the phone is rotated; the game itself is untouched.

## Beside the board in the upright layout, the side panel only appears from this width on.
const SIDE_PANEL_MIN_WIDTH := 700.0

var info: VBoxContainer
var buttons: HFlowContainer

var _bar: PanelContainer
var _board: Control
var _side: Control
var _side_wanted: bool
var _sideways := -1  # -1 until first arranged, then 0 or 1


func _init(board: Control, side_panel: Control = null, side_wanted: bool = false) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_board = board
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side = side_panel
	_side_wanted = side_wanted
	_bar = PanelContainer.new()
	_bar.theme_type_variation = "TopBar"
	info = VBoxContainer.new()
	_bar.add_child(info)
	buttons = HFlowContainer.new()
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)


func _ready() -> void:
	Ui.on_resize(self, _arrange)


## A label for `info` that wraps when the line is too long for the screen.
func add_text(font_size: int, alpha: float = 1.0) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.modulate = Color(1, 1, 1, alpha)
	info.add_child(l)
	return l


func add_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(90, 44)
	b.pressed.connect(on_press)
	Ui.hover_effect(b)
	buttons.add_child(b)
	return b


func _arrange() -> void:
	var room := Ui.usable_size()
	var gap := 8 if Ui.is_compact() else 16
	for side in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, gap)
	Ui.apply_safe_area(self)
	var sideways := 1 if Ui.is_sideways() else 0
	if sideways != _sideways:
		_sideways = sideways
		_rebuild(sideways == 1, room)
	if _side != null:
		_side.visible = _side_wanted and (sideways == 1 or room.x >= SIDE_PANEL_MIN_WIDTH)


## Moves the parts into a fresh set of containers for the chosen arrangement.
func _rebuild(sideways: bool, room: Vector2) -> void:
	for part: Control in [_bar, _board, _side, buttons]:
		if part != null and part.get_parent() != null:
			part.get_parent().remove_child(part)
	for old in get_children():
		remove_child(old)
		old.queue_free()
	if sideways:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		row.add_child(_board)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		column.custom_minimum_size.x = clampf(room.x * 0.36, 240.0, 340.0)
		row.add_child(column)
		column.add_child(_bar)
		var spacer := Control.new()  # pushes the buttons down when there is no side panel to fill the space
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if _side != null:
			_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
			column.add_child(_side)
			spacer.visible = not _side_wanted
		column.add_child(spacer)
		column.add_child(buttons)
	else:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		add_child(col)
		col.add_child(_bar)
		var middle := HBoxContainer.new()
		middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
		middle.add_theme_constant_override("separation", 12)
		col.add_child(middle)
		middle.add_child(_board)
		if _side != null:
			_side.size_flags_vertical = Control.SIZE_FILL
			middle.add_child(_side)
		col.add_child(buttons)
