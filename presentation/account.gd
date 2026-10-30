extends Control
## Online account: log in to play online wars against other players (2 to 6), with ratings and
## ranking points on the Mytholore website. Nothing else needs an account: the game plays offline.
## "Sign in with Google" signs the game in through the website (Online.start_web_sign_in): no password
## to invent or type. Accounts with a password, and password resets, are made on the website too.

var _backdrop: MenuBackdrop
var _email: LineEdit
var _password: LineEdit
var _message: Label
var _login_button: Button
var _web: Dictionary = {}  ## a sign-in through the website in progress (Online.start_web_sign_in)
var _web_wait := 0.0
var _web_until := 0.0
var _polling := false
var _popup: JavaScriptObject  ## the browser build's tab for the website, opened at the click


func _ready() -> void:
	_backdrop = Ui.setup_screen(self)
	Online.account_changed.connect(func() -> void:
		_web = {}
		_build())
	_build()
	if Online.is_logged_in():
		Online.refresh_profile()  # the email may have been confirmed since


func _process(delta: float) -> void:
	if _web.is_empty() or _polling:
		return
	_web_wait -= delta
	if _web_wait > 0.0:
		return
	if Time.get_unix_time_from_system() > _web_until:
		_web = {}
		_build()
		_show_message(tr("The sign-in has expired. Please try again."))
		return
	_web_wait = float(_web.get("interval", 3))
	_polling = true
	var answer: String = await Online.poll_web_sign_in(str(_web.get("device_code", "")))
	_polling = false
	if answer == "gone" and not _web.is_empty():
		_web = {}
		_build()
		_show_message(tr("The sign-in was cancelled. Please try again."))


func _build() -> void:
	for child in get_children():
		if child != _backdrop:
			child.queue_free()
	var col := Ui.centered_column(self, 12)
	Ui.title(col, tr("Online account"))
	var intro := Label.new()
	intro.text = tr("An account is only needed for online wars. Everything else plays offline.")
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.modulate = Color(1, 1, 1, 0.75)
	col.add_child(intro)
	Ui.wrap_to_screen(intro)

	if Online.is_logged_in():
		_build_logged_in(col)
	elif not _web.is_empty():
		_build_web_wait(col)
	else:
		_build_login(col)
	_build_server(col)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	row.add_child(back)


func _build_logged_in(col: Control) -> void:
	var who := Label.new()
	who.text = tr("Logged in as %s") % Online.display_name
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(who)
	Ui.scaled_font(who, 22)
	Ui.wrap_to_screen(who)
	if Online.email != "":
		var mail := Label.new()
		mail.text = Online.email
		mail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mail.modulate = Color(1, 1, 1, 0.7)
		col.add_child(mail)
		Ui.on_resize(mail, func() -> void: mail.visible = not Ui.is_short())  # a phone held sideways has little height
	if not Online.email_verified and Online.email != "":
		var confirm := Label.new()
		confirm.text = tr("Please confirm your email address: we sent you a link.")
		confirm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		confirm.add_theme_color_override("font_color", Color("ffcf6e"))
		col.add_child(confirm)
		Ui.wrap_to_screen(confirm)
		var resend := Ui.button(col, tr("Send the link again"), func() -> void: pass)
		resend.pressed.connect(func() -> void:
			resend.disabled = true
			var r: Dictionary = await Online.resend_confirmation()
			if is_instance_valid(confirm):
				confirm.text = tr("Sent. Check your inbox (and the spam folder).") if r["ok"] else r["message"])
	Ui.button(col, tr("Online wars"), func() -> void: get_tree().change_scene_to_file("res://presentation/online_lobby.tscn"))
	Ui.button(col, tr("My account page"), func() -> void: OS.shell_open(Online.web_url("/account/")))
	Ui.button(col, tr("Log out"), func() -> void: Online.logout())


func _build_login(col: Control) -> void:
	var google := Ui.button(col, tr("Sign in with Google"), _start_web_sign_in)
	google.custom_minimum_size.y = 52
	var note := Label.new()
	note.text = tr("No password needed: the sign-in opens in your browser.")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.modulate = Color(1, 1, 1, 0.65)
	col.add_child(note)
	Ui.scaled_font(note, 14)
	Ui.wrap_to_screen(note)
	Ui.on_resize(note, func() -> void: note.visible = not Ui.is_short())
	var or_label := Label.new()
	or_label.text = tr("or with email and password")
	or_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	or_label.modulate = Color(1, 1, 1, 0.6)
	col.add_child(or_label)
	Ui.scaled_font(or_label, 14)
	_email = _field(col, tr("Email"), false)
	_email.text = Online.email
	_password = _field(col, tr("Password"), true)
	_email.text_submitted.connect(func(_t: String) -> void: _password.grab_focus())
	_password.text_submitted.connect(func(_t: String) -> void: _login())
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color("ff8a7a"))
	_message.visible = false
	col.add_child(_message)
	_login_button = Ui.button(col, tr("Log in"), _login)
	var links := Ui.flip_row(col, 12, 4)
	_link(links, tr("Create an account"), "/account/register")
	_link(links, tr("Forgot your password?"), "/account/forgot")
	if _email.text != "":
		_password.grab_focus.call_deferred()


## Waiting for the player to confirm in the browser: the code to compare, the page again, cancel.
func _build_web_wait(col: Control) -> void:
	var text := Label.new()
	text.text = tr("Finish signing in in your browser. Check that the page shows this code:")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(text)
	Ui.wrap_to_screen(text)
	var code := Label.new()
	code.text = str(_web.get("user_code", ""))
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.add_theme_color_override("font_color", Color("ffd98a"))
	col.add_child(code)
	Ui.scaled_font(code, 40)
	var wait := Label.new()
	wait.text = tr("Waiting for you to confirm…")
	wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wait.modulate = Color(1, 1, 1, 0.7)
	col.add_child(wait)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color("ff8a7a"))
	_message.visible = false
	col.add_child(_message)
	var row := Ui.flip_row(col, 12, 8)
	Ui.button(row, tr("Open the page again"), func() -> void: OS.shell_open(str(_web.get("verification_uri_complete", ""))))
	Ui.button(row, tr("Cancel"), func() -> void:
		_web = {}
		_build())


func _start_web_sign_in() -> void:
	# The browser build opens the tab now, while the click still counts: a tab opened after waiting for
	# the server would be stopped by the popup blocker. It is pointed at the page once the code is here.
	if OS.has_feature("web"):
		_popup = JavaScriptBridge.get_interface("window").open("", "_blank")
	var r: Dictionary = await Online.start_web_sign_in()
	if not r["ok"]:
		if _popup != null:
			_popup.close()
		_show_message(r["message"])
		return
	var url := str(r["verification_uri_complete"])
	if _popup != null:
		_popup.location.href = url
	else:
		OS.shell_open(url)
	_web = r
	_web_wait = float(r.get("interval", 3))
	_web_until = Time.get_unix_time_from_system() + float(r.get("expires_in", 600))
	_build()


func _build_server(col: Control) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var label := Label.new()
	label.text = tr("Server")
	label.modulate = Color(1, 1, 1, 0.6)
	row.add_child(label)
	Ui.scaled_font(label, 14)
	var server := LineEdit.new()
	server.text = Online.server_url
	server.placeholder_text = Online.DEFAULT_SERVER
	server.custom_minimum_size = Vector2(260, 0)
	server.tooltip_text = tr("The address of the Mytholore server. Changing it logs you out.")
	server.text_submitted.connect(func(t: String) -> void: Online.set_server(t))
	server.focus_exited.connect(func() -> void: Online.set_server(server.text))
	row.add_child(server)
	Ui.scaled_font(server, 14)
	# Room for the label and the reset button beside it, also on a small phone.
	Ui.on_resize(server, func() -> void:
		server.custom_minimum_size.x = minf(260.0 * UiTheme.ui_scale(), Ui.panel_content_width() - 110.0))
	# Another server is set (a local test server): one click goes back to the real one.
	if Online.server_url != Online.DEFAULT_SERVER:
		var reset := Button.new()
		reset.tooltip_text = tr("Use the default server") + " (" + Online.DEFAULT_SERVER + ")"
		reset.focus_mode = Control.FOCUS_NONE
		reset.add_child(IconButton.glyph(IconButton.Icon.RESTART, 32.0))
		reset.get_child(0).set_anchors_preset(Control.PRESET_FULL_RECT)
		reset.get_child(0).mouse_filter = Control.MOUSE_FILTER_IGNORE
		reset.pressed.connect(func() -> void: Online.set_server(Online.DEFAULT_SERVER))
		Ui.hover_effect(reset)
		row.add_child(reset)
		Ui.on_resize(reset, func() -> void: reset.custom_minimum_size = Vector2.ONE * 36.0 * UiTheme.ui_scale())


func _field(col: Control, placeholder: String, secret: bool) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.custom_minimum_size = Vector2(320, 44)
	e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD if secret else LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	col.add_child(e)
	Ui.on_resize(e, func() -> void: e.custom_minimum_size.x = minf(320.0 * UiTheme.ui_scale(), Ui.panel_content_width()))
	return e


func _link(row: Control, text: String, path: String) -> void:
	var b := LinkButton.new()
	b.text = text
	b.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	b.pressed.connect(func() -> void: OS.shell_open(Online.web_url(path)))
	row.add_child(b)
	Ui.scaled_font(b, 15)


func _login() -> void:
	if _email.text.strip_edges() == "" or _password.text == "":
		_show_message(tr("Enter your email and password."))
		return
	_login_button.disabled = true
	_login_button.text = tr("Logging in…")
	var r: Dictionary = await Online.login(_email.text, _password.text)
	if r["ok"]:
		return  # account_changed rebuilds the screen
	if is_instance_valid(_login_button):
		_login_button.disabled = false
		_login_button.text = tr("Log in")
		_show_message(r["message"])


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true
