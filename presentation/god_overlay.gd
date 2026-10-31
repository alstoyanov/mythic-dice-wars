class_name GodOverlay
extends ScreenOverlay
## A god's page (GodView, as in the Book of the Gods) over the war: a god's portrait was tapped or
## clicked (the player list, the Players page).

var god_id: String


func _init(id: String) -> void:
	super._init()
	god_id = id


func _build() -> void:
	GodView.build(col, god_id, k(), fit, room(), Ui.is_narrow())
	back_row()
