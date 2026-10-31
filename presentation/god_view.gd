class_name GodView
extends RefCounted
## A god's page: the name, title and role, the portrait, the powers in a war and the story (GodLore).
## Shown by the Book of the Gods and over a war (GodOverlay: a god's portrait tapped or clicked).


## Adds the page to `col`. `k`: the size (UiTheme.ui_scale times the fitting's `fit`); `room`: the
## width it may take; `narrow`: the portrait beside the powers with the story under both (a phone held
## upright), else the portrait beside everything.
static func build(col: VBoxContainer, god_id: String, k: float, fit: float, room: float, narrow: bool) -> void:
	var g := GodCatalog.god(god_id)
	var lore := GodLore.god(god_id)
	var accent: Color = UiTheme.current_palette()["accent"]
	title(col, g["name"], fit)
	var primary: bool = g["role"] == GodCatalog.PRIMARY
	text(col, "%s · %s god" % [g["title"], "Primary" if primary else "Secondary"], 16, k, accent, 0.0, room,
		HORIZONTAL_ALIGNMENT_CENTER)
	var side := minf(room * 0.34, 130.0 * k) if narrow else minf(room * 0.3, 230.0 * k)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	col.add_child(body)
	var pic := portrait(god_id)
	pic.custom_minimum_size = Vector2(side, side * (1.0 if narrow else 1.25))
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(pic)
	var text_w := room - side - 14.0
	var facts := VBoxContainer.new()
	facts.add_theme_constant_override("separation", 4 if narrow else 8)
	body.add_child(facts)
	text(facts, "%s: %s" % [g["boon_name"], g["boon_text"]], 15, k, Color(0.75, 1.0, 0.75), text_w, room)
	if g.has("bane_name"):
		text(facts, "%s: %s" % [g["bane_name"], g["bane_text"]], 15, k, Color(1.0, 0.65, 0.6), text_w, room)
	var story: Control = facts if not narrow else col
	var story_w := text_w if not narrow else room
	text(story, str(lore.get("lore", "")), 16, k, Color.WHITE, story_w, room)
	if str(lore.get("did_you_know", "")) != "":
		text(story, "Did you know? " + str(lore["did_you_know"]), 15, k, Color(1, 1, 1, 0.75), story_w, room)


## A page's title in the realm's title font, a little smaller when the page was shrunk to fit.
static func title(col: Control, t: String, fit: float) -> void:
	Ui.title(col, t)
	if fit < 1.0:
		var l := col.get_child(col.get_child_count() - 1) as Label
		l.add_theme_font_size_override("font_size", roundi(l.get_theme_font_size("font_size") * maxf(fit, 0.8)))


static func portrait(god_id: String) -> TextureRect:
	var pic := TextureRect.new()
	var path := GodCatalog.portrait_path(god_id)
	pic.texture = load(path) if ResourceLoader.exists(path) else null
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pic


## Text that wraps at `width` (0: one line, smaller if it is wider than `room`), `font_size` times `k`.
static func text(parent: Control, t: String, font_size: int, k: float, color: Color, width: float, room: float,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", roundi(font_size * k))
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = width
	else:
		Ui.fit_font(l, roundi(font_size * k), room, 11)
	return l
