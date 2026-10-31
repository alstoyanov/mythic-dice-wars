extends Node
## How smoothly the battle screen opens: plays the same 8-against-8 battle a few times over a war
## (vsync off) and prints for each how long building the screen took, the slowest frame while it
## played, and the draw calls. With --split, first how long loading its pictures takes on their own
## (the war's screen normally loads them as it starts). Needs a window:
##   godot --path . res://tests/battle_perf.tscn [-- --size=720x1280] [--split]

const RUNS := 4

var screen: Node
var _watching := false
var _slowest := 0.0
var _calls := 0
var _frames := 0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var win := Vector2i(1280, 720)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):
			var parts := arg.get_slice("=", 1).split("x")
			win = Vector2i(int(parts[0]), int(parts[1]))
	get_window().size = win
	GameSettings.ensure_loaded()
	GameSettings.online_match_id = ""
	GameSettings.players = 4
	GameSettings.fog = false
	screen = load("res://presentation/game_screen.tscn").instantiate()
	add_child(screen)
	screen._over = true
	await get_tree().create_timer(1.0).timeout
	var state: MatchState = screen.state
	var result := {
		"attacker": 0, "defender": 1, "won": true,
		"attack_rolls": [6, 5, 4, 3, 2, 1, 6, 5], "defense_rolls": [1, 2, 3, 4, 5, 6, 1, 2],
		"attack_total": 34, "defense_total": 26,
		"modifiers": {"attack": [["Bloodlust", 2]], "defense": []},
	}
	if "--split" in OS.get_cmdline_user_args():  # what the first battle's time goes on
		var t := Time.get_ticks_usec()
		for p in [0, 1]:
			Looks.tower(state.players[p].pantheon)
		print("PERF   loading the towers: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
		t = Time.get_ticks_usec()
		for p in [0, 1]:
			DiceArt.faces(GodCatalog.pantheon(state.players[p].pantheon)["dice"])
		print("PERF   loading the dice faces: %.1f ms" % ((Time.get_ticks_usec() - t) / 1000.0))
		var keep := [Looks.tower(state.players[0].pantheon), Looks.tower(state.players[1].pantheon)]
		set_meta("keep", keep)
		await get_tree().create_timer(0.3).timeout
	for run in RUNS:
		var panel: BattlePanel = screen._battle
		_slowest = 0.0
		_calls = 0
		_frames = 0
		_watching = true
		var t0 := Time.get_ticks_usec()
		panel.play(result, state, 1.0)  # builds the screen, then animates on its own
		var build := (Time.get_ticks_usec() - t0) / 1000.0
		await get_tree().create_timer(1.6).timeout
		_watching = false
		print("PERF battle %d: building %.1f ms, slowest frame %.1f ms, %d frames, %d draw calls" % [
			run + 1, build, _slowest, _frames, _calls / maxi(1, _frames)])
		await panel.hide_panel(1.0)
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _process(delta: float) -> void:
	if not _watching:
		return
	_slowest = maxf(_slowest, delta * 1000.0)
	_frames += 1
	_calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
