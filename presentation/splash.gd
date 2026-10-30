extends Control
## First screen: the realm's painting with the title, then a fade into the main menu.
## A click or key press skips it.

const DURATION := 2.2
const FADE := 0.45

var _leaving := false


func _ready() -> void:
	Ui.setup_screen(self)
	var title := Label.new()
	title.text = "Mythic Dice Wars"
	title.theme_type_variation = "TitleLabel"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.grow_vertical = Control.GROW_DIRECTION_BOTH
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	Ui.scaled_font(title, 64)
	var sub := Label.new()
	sub.text = "Roll for the favour of the gods"
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sub.offset_top = 56.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.8)
	add_child(sub)
	var timer := create_tween()
	timer.tween_interval(DURATION)
	timer.tween_callback(_leave)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE)
	fade.tween_callback(func() -> void: get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
