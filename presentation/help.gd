extends Control
## How to play, and every god's powers.


func _ready() -> void:
	Ui.setup_screen(self)
	var col := Ui.centered_column(self, 10)
	Ui.title(col, "How to play")
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = false
	text.scroll_active = true
	text.text = _rules() + _gods()
	col.add_child(text)
	Ui.on_resize(text, func() -> void:
		text.custom_minimum_size = Vector2(minf(720.0, Ui.panel_content_width()), minf(460.0, Ui.usable_size().y - 220.0)))
	var back := IconButton.new(IconButton.Icon.BACK, false, "Back")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://presentation/main_menu.tscn"))
	var holder := CenterContainer.new()
	holder.add_child(back)
	col.add_child(holder)


func _rules() -> String:
	return """[b]Goal.[/b] Rule the whole realm: take every territory, or be the last pantheon standing.

[b]Your turn.[/b] Click one of your territories with 2 or more dice, then a neighbouring enemy territory. Both sides roll all their dice; the higher total (plus the gods' bonuses) wins. Ties go to the defender.
• [b]Win:[/b] the territory is yours. All your dice but one move in; one stays behind.
• [b]Lose:[/b] your territory keeps only 1 die.
Attack as often as you like, then press [b]End turn[/b].

[b]Reinforcements.[/b] When your turn ends you get one die for each territory in your largest group of connected territories, placed at random on your land (at most 8 per territory). Dice that do not fit wait in your reserve (up to %d) for next turn.

[b]Turn order and the head start.[/b] The order is drawn at random when the war begins; the list of players beside the map is in that order. Moving first is a big edge: you strike before anyone has reinforced. So with [b]Turn order: Balanced[/b] (the default, in New War) everyone after the first player begins with a [b]head start[/b] of extra dice, placed like reinforcements. The later you move, the bigger it is:
• The first player gets none.
• The last player gets about two thirds of one turn's reinforcements.
• Everyone in between gets a share in proportion (with 4 players: none, about a fifth, almost half, two thirds).
Your head start is shown under your name during the first round. [b]Classic[/b] turns it off, and the first player wins far more often (about 4 wars in 5 with 2 players).

[b]Fog of war[/b] (an option in New War, off by default). You see only your own territories and the territories next to them. Everything further away lies under grey mist: you cannot see who holds it or how many dice stand there.
• The fog moves with you: conquer a territory and you see its neighbours too; lose one and its surroundings may vanish into the mist.
• You see a battle only if you can see at least one of the two territories. Battles deep in the fog happen unseen.
• In the list of players you still see how many lands each rival holds (and their gods and favour), but not their dice, reinforcements or reserve.
• Miracles can only target territories you can see.
• The computer players are bound by the same fog. They only know what their own land lets them see; where they cannot see, they guess.

[b]Gods.[/b] Your [b]primary god[/b] blesses you from the first turn. Your [b]secondary god[/b] is mighty but brings a flaw, and (by default) wakes only after your %d-th conquest. A limit on attacks counts from the moment the god wakes. Some gods grant a [b]miracle[/b]: an active power paid with [b]favour[/b], once per turn. You gain favour for every battle you fight and every territory you lose.

[b]Map.[/b] Zoom with the mouse wheel or a pinch, drag to look around, right-click to cancel a choice. Hover a target to see your chance to win and what the gods add.

[b]Battles.[/b] Every battle you fight in fills the screen: both armies' dice tumble out of their towers. Under each tray the total is taken apart: the dice, then every god's bonus or penalty by name. A die with a gold frame was a 1 that a god had rolled again. In Settings you choose how long the result stays, or to wait until you press Continue (or click anywhere), and whether to watch the battles between your rivals too.

""" % [MatchState.RESERVE_CAP, MatchState.AWAKEN_CONQUESTS]


func _gods() -> String:
	var out := ""
	for p in GodCatalog.PANTHEONS:
		out += "[b][font_size=20]%s — %s[/font_size][/b]\n" % [p["name"], p["realm"]]
		for g in GodCatalog.GODS:
			if g["pantheon"] != p["id"]:
				continue
			out += "[b]%s[/b] (%s) — [color=#bfe8bf]%s:[/color] %s" % [g["name"], g["role"], g["boon_name"], g["boon_text"]]
			if g.has("bane_name"):
				out += " [color=#f0a49c]%s:[/color] %s" % [g["bane_name"], g["bane_text"]]
			out += "\n"
		out += "\n"
	return out
