extends Node
## Autoload "AppWindow": keeps the game in a window or fullscreen as the player chose.
## F11 or Alt+Enter toggles at any time; Settings offers the same choice. The choice is remembered.

signal fullscreen_changed(fullscreen: bool)


const MENU_SCENE := "res://presentation/main_menu.tscn"
const SPLASH_SCENE := "res://presentation/splash.tscn"


## Android and iOS (not a phone's web browser: that is "web").
static func is_mobile() -> bool:
	return OS.has_feature("mobile")


## The editor can run the game inside its own panel ("embedded"), which only supports a window. On a
## phone or tablet the app is always full screen.
static func can_fullscreen() -> bool:
	return DisplayServer.get_name() != "embedded" and not is_mobile()


func _ready() -> void:
	GameSettings.ensure_loaded()
	if is_mobile():
		_scale_for_screen()
		get_window().size_changed.connect(_scale_for_screen)
	else:
		get_window().min_size = Vector2i(480, 640)  # below this the menus would be cut off
	if can_fullscreen():
		_apply()


## Phone screens have very many pixels per inch: scale everything so buttons and text stay a
## comfortable size to touch and read (160 dpi is the classic "1x"). But never so much that fewer than
## MIN_SHORT x MIN_LONG scaled units remain: the screens are laid out for at least that much room.
## The factor does not depend on which way the phone is held, so rotating it keeps every size.
const MIN_SHORT := 460.0
const MIN_LONG := 760.0


func _scale_for_screen() -> void:
	var dpi := float(DisplayServer.screen_get_dpi())
	var px := Vector2(DisplayServer.window_get_size())
	var short_side := minf(px.x, px.y)
	var long_side := maxf(px.x, px.y)
	if short_side <= 0.0:
		return
	var factor := minf(dpi / 160.0, minf(short_side / MIN_SHORT, long_side / MIN_LONG))
	get_window().content_scale_factor = clampf(factor, 1.0, 3.5)


## The Android back button and the iOS equivalent: go to the menu, or leave from the menu.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var scene := get_tree().current_scene
		var path := scene.scene_file_path if scene != null else ""
		if path == MENU_SCENE or path == SPLASH_SCENE or path == "":
			get_tree().quit()
		else:
			get_tree().change_scene_to_file(MENU_SCENE)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	set_fullscreen(not GameSettings.fullscreen)


func set_fullscreen(on: bool) -> void:
	if not can_fullscreen():
		fullscreen_changed.emit(GameSettings.fullscreen)  # lets Settings put its drop-down back
		return
	GameSettings.fullscreen = on
	GameSettings.save()
	_apply()
	fullscreen_changed.emit(on)


func _apply() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if GameSettings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
