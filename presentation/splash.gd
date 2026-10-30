extends Control
## First screen: the key art (assets/branding: the wide picture, or the tall one on a screen held
## upright) slowly drawing closer, with the title in the sky above the island; then a fade into the
## main menu. Without the key art, the realm's painting. A click or key press skips it.

const DURATION := 3.0
const FADE := 0.45
const KEY_ART := "res://assets/branding/key_art.jpg"
const KEY_ART_PORTRAIT := "res://assets/branding/key_art_portrait.jpg"

var _leaving := false


func _ready() -> void:
	Ui.setup_screen(self)
	var art := _key_art()
	if art != null:
		_show_art(art)
	var title := Label.new()
	title.text = "Mythic Dice Wars"
	title.theme_type_variation = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := Label.new()
	sub.text = "Roll for the favour of the gods"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.85)
	if art != null:
		# In the calm sky at the top (the key art leaves it free), on a soft shadow and outlined, so it
		# stands out from the bright clouds.
		var shade := TextureRect.new()
		var fade := GradientTexture2D.new()
		fade.gradient = Gradient.new()
		fade.gradient.set_color(0, Color(0, 0, 0, 0.55))
		fade.gradient.set_color(1, Color(0, 0, 0, 0.0))
		fade.fill_from = Vector2(0.5, 0.0)
		fade.fill_to = Vector2(0.5, 1.0)
		shade.texture = fade
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.set_anchors_preset(Control.PRESET_TOP_WIDE)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
		Ui.on_resize(shade, func() -> void: shade.offset_bottom = Ui.usable_size().y * 0.3)
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_TOP_WIDE)
		box.offset_top = Ui.usable_size().y * 0.04 + Ui.safe_margins().y
		box.add_theme_constant_override("separation", 0)
		add_child(box)
		box.add_child(title)
		box.add_child(sub)
		for l in [title, sub]:
			l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.85))
			l.add_theme_constant_override("outline_size", 10 if l == title else 6)
		title.modulate.a = 0.0
		sub.modulate.a = 0.0
		var show := create_tween()
		show.tween_interval(0.3)
		show.tween_property(title, "modulate:a", 1.0, 0.6)
		show.tween_property(sub, "modulate:a", 0.85, 0.4)
	else:
		title.set_anchors_preset(Control.PRESET_CENTER)
		title.grow_horizontal = Control.GROW_DIRECTION_BOTH
		title.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(title)
		sub.set_anchors_preset(Control.PRESET_CENTER)
		sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sub.offset_top = 56.0
		add_child(sub)
	Ui.scaled_font(title, 64)
	Ui.scaled_font(sub, 22)
	var timer := create_tween()
	timer.tween_interval(DURATION)
	timer.tween_callback(_leave)


## The key art that suits the screen's shape, or null if it is missing.
func _key_art() -> Texture2D:
	var room := Ui.usable_size()
	var path := KEY_ART_PORTRAIT if room.y > room.x else KEY_ART
	if not ResourceLoader.exists(path):
		path = KEY_ART
	return load(path) if ResourceLoader.exists(path) else null


## The picture over the whole screen (cropped to fill it), drifting slowly closer.
func _show_art(art: Texture2D) -> void:
	var pic := TextureRect.new()
	pic.texture = art
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pic)
	var drift := func() -> void: pic.pivot_offset = pic.size / 2.0
	pic.resized.connect(drift)
	drift.call()
	pic.create_tween().tween_property(pic, "scale", Vector2(1.06, 1.06), DURATION + FADE).from(Vector2.ONE)


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
