extends Control


func _ready() -> void:
	Ui.setup_screen(self)
	var col := Ui.centered_column(self, 14)
	Ui.title(col, "Mythic Dice Wars")
	var realm := Label.new()
	realm.text = "%s — %s and %s" % [GodCatalog.pantheon(GameSettings.pantheon)["realm"],
		GodCatalog.god(GameSettings.primary)["name"], GodCatalog.god(GameSettings.secondary)["name"]]
	realm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm.modulate = Color(1, 1, 1, 0.75)
	col.add_child(realm)
	Ui.button(col, "New War", func() -> void: get_tree().change_scene_to_file("res://presentation/new_war.tscn"))
	var quick := Ui.button(col, "Quick War", func() -> void: get_tree().change_scene_to_file("res://presentation/game_screen.tscn"))
	quick.tooltip_text = "Straight into a war with your last choices."
	var book := Ui.button(col, "Book of the Gods", func() -> void:
		GodBook.open(get_tree(), "res://presentation/main_menu.tscn"))
	book.tooltip_text = "Every pantheon and its gods: their powers and their stories."

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	_icon(row, IconButton.Icon.SETTINGS, "Settings",
		func() -> void: get_tree().change_scene_to_file("res://presentation/settings.tscn"))
	_icon(row, IconButton.Icon.HELP, "How to play",
		func() -> void: get_tree().change_scene_to_file("res://presentation/help.tscn"))
	_icon(row, IconButton.Icon.INFO, "Credits",
		func() -> void: get_tree().change_scene_to_file("res://presentation/credits.tscn"))
	if not (OS.has_feature("web") or OS.has_feature("mobile")):
		_icon(row, IconButton.Icon.QUIT, "Quit", func() -> void: get_tree().quit())


func _icon(row: Control, kind: IconButton.Icon, tip: String, on_press: Callable) -> void:
	var b := IconButton.new(kind, false, tip)
	b.pressed.connect(on_press)
	row.add_child(b)
