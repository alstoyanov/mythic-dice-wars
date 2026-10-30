extends Control


func _ready() -> void:
	Ui.setup_screen(self)
	var col := Ui.centered_column(self, 12)
	Ui.title(col, "Settings")

	var sound := CheckButton.new()
	sound.text = "Sound effects"
	sound.button_pressed = GameSettings.sfx_enabled
	sound.toggled.connect(func(on: bool) -> void:
		GameSettings.sfx_enabled = on
		Sound.apply()
		Sound.play("toggle"))
	col.add_child(sound)

	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = GameSettings.sfx_volume
	volume.custom_minimum_size = Vector2(260, 24)
	volume.value_changed.connect(func(v: float) -> void:
		GameSettings.sfx_volume = v
		Sound.apply())
	col.add_child(volume)

	var counts := CheckButton.new()
	counts.text = "Show the number of dice on every territory"
	counts.button_pressed = GameSettings.show_counts
	counts.toggled.connect(func(on: bool) -> void:
		GameSettings.show_counts = on
		Sound.play("toggle"))
	col.add_child(counts)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var l := Label.new()
	l.text = "Battle speed"
	row.add_child(l)
	var speed := OptionButton.new()
	for n in GameSettings.ANIM_NAMES:
		speed.add_item(n)
	speed.selected = GameSettings.anim_speed
	speed.item_selected.connect(func(i: int) -> void: GameSettings.anim_speed = i)
	row.add_child(speed)

	var hold_row := HBoxContainer.new()
	hold_row.add_theme_constant_override("separation", 12)
	col.add_child(hold_row)
	var hold_label := Label.new()
	hold_label.text = "Battle result shown"
	hold_row.add_child(hold_label)
	var hold := OptionButton.new()
	for n in GameSettings.HOLD_NAMES:
		hold.add_item(n)
	hold.selected = GameSettings.battle_hold
	hold.item_selected.connect(func(i: int) -> void: GameSettings.battle_hold = i)
	hold_row.add_child(hold)

	var rivals := CheckButton.new()
	rivals.text = "Show battles between rivals too"
	rivals.tooltip_text = "Off: battles you are not in are shown only on the map (an arrow, then the outcome)."
	rivals.button_pressed = GameSettings.hold_rivals
	rivals.toggled.connect(func(on: bool) -> void:
		GameSettings.hold_rivals = on
		Sound.play("toggle"))
	col.add_child(rivals)

	if AppWindow.can_fullscreen():
		var full := CheckButton.new()
		full.text = "Full screen (F11)"
		full.button_pressed = GameSettings.fullscreen
		full.toggled.connect(func(on: bool) -> void: AppWindow.set_fullscreen(on))
		col.add_child(full)

	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void:
		GameSettings.save()
		get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	var holder := CenterContainer.new()
	holder.add_child(back)
	col.add_child(holder)
