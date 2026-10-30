extends Control


func _ready() -> void:
	Ui.setup_screen(self)
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "Credits")
	var text := Label.new()
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = minf(560.0, Ui.panel_content_width())
	text.text = """Design and code: Alexander Stoyanov
Dice, gods and realm art: Mytholore art, AI-assisted (Gemini)
Interface sounds: Kenney (CC0) · Game sounds: Chasm of Knights (placeholders)
Fonts: PT Serif and the realm title fonts (SIL Open Font License)
Made with Godot Engine"""
	col.add_child(text)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	var holder := CenterContainer.new()
	holder.add_child(back)
	col.add_child(holder)
