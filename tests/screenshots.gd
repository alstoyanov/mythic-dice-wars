extends Node
## Opens every screen and saves a picture of each (needs a window, not --headless):
##   godot --path . res://tests/screenshots.tscn -- --out=<folder> [--size=1280x800] [--pantheon=norse] [--grid=hex] [--fog=on|off]
## Also a smoke test: a script error on any screen shows in the output.

const SCREENS := ["splash", "main_menu", "new_war", "god_select", "god_book", "settings", "help", "game_screen"]


var root: Window


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Stay alive while the screens replace each other: leave the current scene's place.
	root = get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	get_tree().current_scene = null
	var out := "user://screenshots"
	var win_size := Vector2i(1280, 800)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
		elif arg.begins_with("--size="):
			var parts := arg.get_slice("=", 1).split("x")
			win_size = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--grid="):
			GameSettings.ensure_loaded()
			GameSettings.grid = arg.get_slice("=", 1)
		elif arg.begins_with("--fog="):
			GameSettings.ensure_loaded()
			GameSettings.fog = arg.get_slice("=", 1) == "on"
		elif arg.begins_with("--pantheon="):
			GameSettings.ensure_loaded()
			GameSettings.set_pantheon(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out)
	GameSettings.ensure_loaded()
	GameSettings.battle_hold = 1  # results shown for a moment, never waiting (except below)
	GameSettings.awakening = "start"  # both gods awake, so their bonuses show in the battles
	root.size = win_size
	DisplayServer.window_set_size(win_size)
	await get_tree().process_frame
	var suffix := "_%dx%d" % [win_size.x, win_size.y]
	for screen in SCREENS:
		get_tree().change_scene_to_file("res://presentation/%s.tscn" % screen)
		for i in 40:
			await get_tree().process_frame
		await get_tree().create_timer(0.6).timeout
		_save(out, screen + suffix)
	# A battle in progress and a later state of the war: play a few computer turns.
	var game := get_tree().current_scene
	if game != null and game.get("state") != null:
		var state: MatchState = game.state
		var view: RealmView = game._view
		var mine := state.territories_of(game.human)
		for t in mine:
			if state.can_attack_from(t):
				game._select(t)
				break
		await get_tree().create_timer(0.3).timeout
		_save(out, "game_selected" + suffix)
		view._zoom_at(view.size / 2.0, 2.2)
		await get_tree().create_timer(0.3).timeout
		_save(out, "game_zoomed" + suffix)
		view.reset_view()
		game._cancel()
		GameSettings.anim_speed = 0
		var waited := 0.0
		while (state.current != game.human or game._busy) and waited < 30.0 and not game._over:
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		var best := []
		var best_p := -1.0
		for t in state.territories_of(game.human):
			for nb in state.map.neighbors(t):
				if state.can_attack(t, nb) and DiceOdds.attack_chance(state, t, nb) > best_p:
					best_p = DiceOdds.attack_chance(state, t, nb)
					best = [t, nb]
		if not best.is_empty() and not game._over:
			game._on_territory_clicked(best[0])
			game._on_hovered(best[1])
			await get_tree().create_timer(0.3).timeout
			_save(out, "game_human_turn" + suffix)
			GameSettings.battle_hold = GameSettings.HOLDS.find(GameSettings.WAIT)  # this one waits for Continue
			game._on_territory_clicked(best[1])
			await get_tree().create_timer(0.75).timeout
			_save(out, "game_battle" + suffix)
			await get_tree().create_timer(1.6).timeout
			_save(out, "game_battle_end" + suffix)
			game._battle.accept()
			GameSettings.battle_hold = 1
		await get_tree().create_timer(2.0).timeout
		_save(out, "game_later" + suffix)
		# The map's effects: lightning, golden motes, dust and a ward, zoomed in on four territories.
		if not game._over:
			view._zoom_at(view.size / 2.0, 1.8)
			var some: Array = range(state.map.count())
			some.sort_custom(func(x: int, y: int) -> bool:
				return view.territory_screen_pos(x).distance_to(view.size / 2.0) < view.territory_screen_pos(y).distance_to(view.size / 2.0))
			state.wards[some[3]] = {"player": state.owners[some[3]], "bonus": 5}
			view.refresh()
			view.play_fx("lightning", some[0], 3.0, 80.0, 34.0)
			view.play_fx("motes", some[1], 3.0, 60.0, 18.0)
			view.play_fx("dust", some[2], 3.0, 60.0, 10.0)
			await get_tree().create_timer(0.5).timeout
			_save(out, "game_fx" + suffix)
	get_tree().quit()


func _save(out: String, name: String) -> void:
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [out, name]
	img.save_png(path)
	print("saved ", path)
