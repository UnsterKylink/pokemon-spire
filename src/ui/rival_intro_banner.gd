class_name RivalIntroBanner
extends Control
## Story 018: overlay shown on the battle screen before a rival fight: "{name} te défie !" (or "Dernier combat contre
## {name} avant le Conseil 4" for the pre-league fight), the rival's current starter sprite, the team's sprites,
## "Rencontre n/4" and a taunt line, then "Combattre !". Display only: it reads the info dictionary built by Main
## and emits dismissed; it never touches the battle. Click, Entrée / Espace or the gamepad accept button closes it.
## Implements: story-018-rival-et-evenements (rival intro).

## Emitted once when the banner is closed.
signal dismissed

const TEXT_TITLE: String = "%s te défie !"
const TEXT_TITLE_FINAL: String = "Dernier combat contre %s avant le Conseil 4"
const TEXT_ENCOUNTER: String = "Rencontre %d/%d"
const TEXT_TEAM: String = "%s mène son équipe"
const TEXT_SOLO: String = "Son starter : %s"
const TEXT_FIGHT: String = "Combattre !"
## Taunt lines (no rival text in rival.json): picked by encounter number, the last one for the pre-league fight.
const TAUNTS: Array[String] = [
	"« Mon starter a l'avantage du type. Tu n'as aucune chance ! »",
	"« Je me suis entraîné depuis notre dernier combat. Cette fois, je ne perdrai pas ! »",
	"« Tu as encore progressé ? Moi aussi. Voyons qui est le meilleur ! »",
	"« Avant le Conseil 4, il faudra me passer sur le corps. Dernier round ! »",
]
const PANEL_WIDTH: float = 660.0
const SPRITE_SIZE: Vector2 = Vector2(150, 150)
const TEAM_SPRITE_SIZE: Vector2 = Vector2(56, 56)
const COLOR_DIM: Color = Color(0.0, 0.0, 0.0, 0.7)
const COLOR_PANEL: Color = Color(0.12, 0.08, 0.17)
const COLOR_BORDER: Color = Color(0.72, 0.42, 0.95)
const COLOR_TITLE: Color = Color(0.9, 0.75, 1.0)
const COLOR_SUB: Color = Color(0.78, 0.8, 0.88)
const COLOR_TAUNT: Color = Color(1.0, 0.9, 0.55)

var _title: Label
var _sprite: TextureRect
var _team_row: HBoxContainer
var _team_label: Label
var _encounter: Label
var _taunt: Label
var _closed: bool = false


func _init() -> void:
	name = "RivalIntroBanner"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = COLOR_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(4)
	sb.border_color = COLOR_BORDER
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_title = CardView.make_label(34)
	_title.name = "Title"
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(PANEL_WIDTH - 44, 0)
	box.add_child(_title)
	_encounter = CardView.make_label(18)
	_encounter.add_theme_color_override("font_color", COLOR_SUB)
	box.add_child(_encounter)
	_sprite = TextureRect.new()
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.custom_minimum_size = SPRITE_SIZE
	box.add_child(_sprite)
	_team_label = CardView.make_label(18)
	_team_label.add_theme_color_override("font_color", COLOR_SUB)
	box.add_child(_team_label)
	_team_row = HBoxContainer.new()
	_team_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_team_row.add_theme_constant_override("separation", 10)
	box.add_child(_team_row)
	_taunt = CardView.make_label(20)
	_taunt.add_theme_color_override("font_color", COLOR_TAUNT)
	_taunt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_taunt.custom_minimum_size = Vector2(PANEL_WIDTH - 44, 0)
	box.add_child(_taunt)
	var button := Button.new()
	button.name = "FightButton"
	button.text = TEXT_FIGHT
	button.custom_minimum_size = Vector2(220, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(dismiss)
	box.add_child(button)


## Fills the banner. `info`: {name, sprite (path of the rival's current starter), current_name, number, total, final: bool,
## team: Array of sprite paths (whole team, starter first)}.
func setup(info: Dictionary) -> void:
	var rival_name: String = String(info.get("name", ""))
	var final: bool = bool(info.get("final", false))
	var number: int = int(info.get("number", 1))
	var total: int = int(info.get("total", 1))
	_title.text = (TEXT_TITLE_FINAL if final else TEXT_TITLE) % rival_name
	_encounter.text = TEXT_ENCOUNTER % [number, total]
	_sprite.texture = _load(String(info.get("sprite", "")))
	_sprite.visible = _sprite.texture != null
	var team_size: int = (info.get("team", []) as Array).size()
	_team_label.text = (TEXT_TEAM if team_size > 1 else TEXT_SOLO) % String(info.get("current_name", ""))
	for child: Node in _team_row.get_children():
		_team_row.remove_child(child)
		child.queue_free()
	for path: Variant in info.get("team", []):
		var t := TextureRect.new()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = TEAM_SPRITE_SIZE
		t.texture = _load(String(path))
		_team_row.add_child(t)
	_team_row.visible = _team_row.get_child_count() > 1
	_taunt.text = TAUNTS[TAUNTS.size() - 1] if final else TAUNTS[clampi(number - 1, 0, TAUNTS.size() - 2)]


## Closes the banner (button, click, accept key). Ignored after the first call.
func dismiss() -> void:
	if _closed:
		return
	_closed = true
	visible = false
	dismissed.emit()
	queue_free()


## The title line (QA).
func get_title_text() -> String:
	return _title.text


## The taunt line (QA).
func get_taunt_text() -> String:
	return _taunt.text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		dismiss()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		dismiss()
		get_viewport().set_input_as_handled()


static func _load(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return CardView.cropped_sprite(path)
