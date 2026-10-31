extends Node
## How much a war costs: a large realm of eight players (no turns played while measuring). With vsync
## off, the frames per second each case reaches (the main menu for comparison; idle; the map rebuilt
## every frame; zooming), the GPU draw calls, and how long one rebuild of the map takes. Needs a window:
##   godot --path . res://tests/perf_check.tscn

const SECONDS := 3.0

var screen: Node
var _phases := ["main menu", "war, idle", "war, selection changed every frame", "war, zooming"]
var _phase := -1
var _t := 0.0
var _frames := 0
var _calls := 0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	get_window().size = Vector2i(1280, 720)
	GameSettings.ensure_loaded()
	GameSettings.online_match_id = ""
	GameSettings.players = 8
	GameSettings.map_size = "large"
	GameSettings.fog = false
	_next()


func _next() -> void:
	if _phase >= 0:
		print("PERF %-30s %6.0f frames per second (%5.2f ms each), %d draw calls" % [_phases[_phase], _frames / SECONDS,
			1000.0 * SECONDS / maxi(1, _frames), _calls / maxi(1, _frames)])
	_phase += 1
	_t = 0.0
	_frames = 0
	_calls = 0
	if _phase >= _phases.size():
		var view: RealmView = screen._view
		var t0 := Time.get_ticks_usec()
		for i in 10:
			view._build_land()
		print("PERF building the land mesh (once per war): %.1f ms" % ((Time.get_ticks_usec() - t0) / 10000.0))
		t0 = Time.get_ticks_usec()
		for i in 10:
			view.refresh()
		print("PERF refreshing the map after a battle: %.2f ms" % ((Time.get_ticks_usec() - t0) / 10000.0))
		t0 = Time.get_ticks_usec()
		for i in 10:
			screen._players.update(screen.state)
		print("PERF updating the player list: %.2f ms" % ((Time.get_ticks_usec() - t0) / 10000.0))
		t0 = Time.get_ticks_usec()
		for i in 10:
			view._build_marks()
		print("PERF one rebuild of the marks (a tap): %.2f ms" % ((Time.get_ticks_usec() - t0) / 10000.0))
		get_tree().quit()
		return
	if _phase == 0:
		screen = load("res://presentation/main_menu.tscn").instantiate()
		add_child(screen)
	elif _phase == 1:
		screen.queue_free()
		screen = load("res://presentation/game_screen.tscn").instantiate()
		add_child(screen)
		screen._over = true  # no turns are played while measuring


func _process(delta: float) -> void:
	_t += delta
	if _t > 1.0:  # after a second to settle
		_calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_frames += 1
	if _phase == 2:
		screen._view.selected = _frames % screen.state.map.count()
		screen._view.queue_redraw()
	elif _phase == 3:
		screen._view._zoom_at(Vector2(640, 360), 1.004 if int(_t * 2.0) % 2 == 0 else 1.0 / 1.004)
	if _t > 1.0 + SECONDS:
		_next()
