class_name LeagueScreen
extends Control
## Story 013 (story-013-conseil-4-ethernatos): the league screen, shown after badge 8 and between two league fights.
## Three variants, all from RunState (display only):
##  - intro (no league fight won yet): "Route Victoire" / "Le Conseil 4 t'attend";
##  - intermission (after a win): "Victoire contre <Nom> !" and the heal "+X PV récupérés" (Main.get_last_league_heal);
##  - final-boss intro (current stage = last): "<Boss> surgit !", dark purple / red palette and the boss sprite.
## Every variant lists the league fights in order (marker beaten / current / upcoming, name, title, type chips) with
## the current one highlighted, and a button "Affronter <Nom>" that emits finished (Main calls league_continue()).
## Mouse only, fits 1280x720 under the HUD.

## Emitted once by "Affronter <Nom>".
signal finished

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_ROW: Color = Color(0.18, 0.19, 0.25)
const COLOR_BODY: Color = Color(0.92, 0.92, 0.95)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const COLOR_DIM: Color = Color(0.5, 0.52, 0.6)
const COLOR_BEATEN: Color = Color(0.4, 0.85, 0.5)
const COLOR_HEAL: Color = Color(0.45, 0.95, 0.5)
const COLOR_TITLE: Color = Color(1.0, 0.85, 0.3)
const COLOR_LEAGUE_BORDER: Color = Color(0.85, 0.7, 0.3)
## Final-boss palette (intro of the last fight and its row in the list).
const COLOR_BOSS_BG: Color = Color(0.08, 0.03, 0.08)
const COLOR_BOSS_PANEL: Color = Color(0.16, 0.05, 0.13)
const COLOR_BOSS_ROW: Color = Color(0.25, 0.08, 0.18)
const COLOR_BOSS_BORDER: Color = Color(0.85, 0.2, 0.35)
const COLOR_BOSS_TITLE: Color = Color(1.0, 0.42, 0.52)
const PANEL_WIDTH: float = 820.0
const ROW_HEIGHT: float = 40.0
const MARKER_SIDE: float = 26.0
const BOSS_SPRITE_SIDE: float = 84.0
const TEXT_INTRO_TITLE: String = "Route Victoire"
const TEXT_INTRO_SUB: String = "Le Conseil 4 t'attend"
const TEXT_WIN_TITLE: String = "Victoire contre %s !"
const TEXT_BOSS_TITLE: String = "%s surgit !"
const TEXT_BOSS_SUB: String = "Une puissance colossale se dresse sur la Route Victoire…"
const TEXT_HEAL: String = "+%d PV récupérés (PV %d/%d)"
const TEXT_LIST: String = "Combat %d/%d"
const TEXT_BEATEN: String = "Vaincu"
const TEXT_CURRENT: String = "Prochain combat"
const TEXT_UPCOMING: String = "À venir"
const TEXT_BUTTON: String = "Affronter %s"

## Progress marker of a row: green disc + check (beaten), accent disc + arrow (current), grey ring (upcoming).
class Marker extends Control:
	var state: String = "upcoming"
	var accent: Color = Color.WHITE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.5 - 1.0
		match state:
			"beaten":
				draw_circle(c, r, COLOR_BEATEN)
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.5, 0.0), c + Vector2(-r * 0.12, r * 0.4),
						c + Vector2(r * 0.55, -r * 0.4)]), Color.WHITE, 3.0, true)
			"current":
				draw_circle(c, r, accent)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.5), c + Vector2(r * 0.55, 0.0),
						c + Vector2(-r * 0.3, r * 0.5)]), Color.WHITE)
			_:
				draw_arc(c, r - 1.0, 0.0, TAU, 32, COLOR_DIM, 2.0, true)

var _built: bool = false
var _done: bool = false
var _boss_intro: bool = false
var _bg: ColorRect
var _panel_style: StyleBoxFlat
var _title: Label
var _subtitle: Label
var _heal: Label
var _boss_sprite: TextureRect
var _list_caption: Label
var _list: VBoxContainer
var _button: Button
var _rows: Array[Dictionary] = []  # QA: {name, title, status}


func _init() -> void:
	name = "LeagueScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the screen from `run` (RunState.league / league_stage / league_fights_won, read only). `last_heal` = HP
## restored after the last win (Main.get_last_league_heal), -1 on the intro (no heal line).
func setup(data: GameData, run: RunState, last_heal: int) -> void:
	_build_ui()
	_done = false
	var stage: int = clampi(run.league_stage, 0, maxi(run.league.size() - 1, 0))
	var fight: Dictionary = run.league[stage] if not run.league.is_empty() else {}
	var intro: bool = run.league_fights_won == 0
	_boss_intro = String(fight.get("kind", "")) == "final_boss"
	var accent: Color = COLOR_BOSS_BORDER if _boss_intro else COLOR_LEAGUE_BORDER
	_bg.color = COLOR_BOSS_BG if _boss_intro else COLOR_BG
	_panel_style.bg_color = COLOR_BOSS_PANEL if _boss_intro else COLOR_PANEL
	_panel_style.border_color = accent
	if _boss_intro:
		_title.text = TEXT_BOSS_TITLE % String(fight.get("name", ""))
		_subtitle.text = TEXT_BOSS_SUB
	elif intro:
		_title.text = TEXT_INTRO_TITLE
		_subtitle.text = TEXT_INTRO_SUB
	else:
		_title.text = TEXT_WIN_TITLE % String((run.league[stage - 1] as Dictionary)["name"]) if stage > 0 else ""
		_subtitle.text = ""
	_title.add_theme_color_override("font_color", COLOR_BOSS_TITLE if _boss_intro else COLOR_TITLE)
	_subtitle.visible = not _subtitle.text.is_empty()
	_heal.text = TEXT_HEAL % [last_heal, run.hp, run.max_hp] if last_heal >= 0 and not intro else ""
	_heal.visible = not _heal.text.is_empty()
	_boss_sprite.visible = false
	if _boss_intro:
		var ids: Array[String] = data.get_encounter_enemy_ids(String(fight.get("encounter", "")))
		if not ids.is_empty():
			var path: String = String(data.get_pokemon_info(ids[0]).get("sprite_path", ""))
			_boss_sprite.texture = CardView.cropped_sprite(path) if not path.is_empty() else null
			_boss_sprite.visible = _boss_sprite.texture != null
	_list_caption.text = TEXT_LIST % [stage + 1, run.league.size()]
	_list_caption.visible = not _boss_intro  # the final-boss intro needs the room for the sprite (fits 1280x720)
	_fill_list(data, run, stage)
	_button.text = TEXT_BUTTON % String(fight.get("name", ""))


## Presses "Affronter <Nom>" (same path as a click); once only.
func press_continue() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## Displayed title ("Route Victoire" / "Victoire contre Agatha !" / "Éthernatos surgit !").
func get_title_text() -> String:
	return _title.text


## Displayed subtitle ("" when hidden).
func get_subtitle_text() -> String:
	return _subtitle.text if _subtitle.visible else ""


## Displayed heal line ("+25 PV récupérés (PV 120/146)"; "" on the intro).
func get_heal_text() -> String:
	return _heal.text if _heal.visible else ""


## Button text ("Affronter Agatha").
func get_button_text() -> String:
	return _button.text


## True when the current fight is the final boss (distinct palette).
func is_boss_intro() -> bool:
	return _boss_intro


## The listed fights, for QA: [{name, title, status ("Vaincu" | "Prochain combat" | "À venir")}].
func get_rows() -> Array[Dictionary]:
	return _rows.duplicate(true)


func _fill_list(data: GameData, run: RunState, stage: int) -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	for i: int in run.league.size():
		var f: Dictionary = run.league[i]
		var state: String = "beaten" if i < run.league_fights_won else ("current" if i == stage else "upcoming")
		var status: String = TEXT_BEATEN if state == "beaten" else (TEXT_CURRENT if state == "current" else TEXT_UPCOMING)
		_rows.append({"name": String(f["name"]), "title": String(f["title"]), "status": status})
		_list.add_child(_make_row(data, f, state, status))


func _make_row(data: GameData, f: Dictionary, state: String, status: String) -> PanelContainer:
	var boss: bool = String(f.get("kind", "")) == "final_boss"
	var type_color: Color = data.get_type_color(String(f.get("type_id", "")))
	var accent: Color = COLOR_BOSS_BORDER if boss else type_color
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BOSS_ROW if boss else COLOR_ROW
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	if state == "current":
		sb.set_border_width_all(3)
		sb.border_color = accent
		sb.bg_color = sb.bg_color.lerp(accent, 0.18)
	elif state == "beaten":
		sb.bg_color = sb.bg_color.darkened(0.25)
	row.add_theme_stylebox_override("panel", sb)
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)
	row.add_child(box)
	var marker := Marker.new()
	marker.state = state
	marker.accent = accent
	marker.custom_minimum_size = Vector2(MARKER_SIDE, MARKER_SIDE)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(marker)
	var name_label: Label = CardView.make_label(22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size = Vector2(150, 0)
	name_label.text = "%d. %s" % [int(f["index"]), String(f["name"])]
	var name_color: Color = COLOR_BOSS_TITLE if boss else COLOR_BODY
	name_label.add_theme_color_override("font_color", COLOR_DIM if state == "beaten" else name_color)
	box.add_child(name_label)
	var title_label: Label = CardView.make_label(18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.custom_minimum_size = Vector2(190, 0)
	title_label.text = String(f["title"])
	title_label.add_theme_color_override("font_color", COLOR_DIM if state == "beaten" else COLOR_CAPTION)
	box.add_child(title_label)
	var types: Array[String] = []
	types.assign(f.get("type_ids", [String(f.get("type_id", ""))]))
	var chips: HBoxContainer = CardView.make_type_badge_row(16)
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips.alignment = BoxContainer.ALIGNMENT_BEGIN
	CardView.set_badge_row(chips, types, data.get_type_chart())
	if state == "beaten":
		chips.modulate = Color(1, 1, 1, 0.55)
	box.add_child(chips)
	var status_label: Label = CardView.make_label(18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.text = status
	# Current = gold (boss: its red), not the type colour: dark types (Ténèbres) are unreadable on the panel.
	var current_color: Color = COLOR_BOSS_TITLE if boss else COLOR_TITLE
	var status_color: Color = COLOR_BEATEN if state == "beaten" else (current_color if state == "current" else COLOR_DIM)
	status_label.add_theme_color_override("font_color", status_color)
	box.add_child(status_label)
	return row


func _build_ui() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)  # story 020: art-bible look
	_bg = ColorRect.new()
	_bg.color = COLOR_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = COLOR_PANEL
	_panel_style.set_border_width_all(3)
	_panel_style.set_corner_radius_all(12)
	_panel_style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_title = CardView.make_label(38)
	_title.name = "Title"
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	box.add_child(_title)
	_subtitle = CardView.make_label(22)
	_subtitle.name = "Subtitle"
	_subtitle.add_theme_color_override("font_color", COLOR_BODY)
	box.add_child(_subtitle)
	_heal = CardView.make_label(22)
	_heal.name = "Heal"
	_heal.add_theme_color_override("font_color", COLOR_HEAL)
	box.add_child(_heal)
	_boss_sprite = TextureRect.new()
	_boss_sprite.name = "BossSprite"
	_boss_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boss_sprite.custom_minimum_size = Vector2.ONE * BOSS_SPRITE_SIDE
	_boss_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_sprite.visible = false
	box.add_child(_boss_sprite)
	_list_caption = CardView.make_label(18)
	_list_caption.name = "ListCaption"
	_list_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_list_caption.add_theme_color_override("font_color", COLOR_CAPTION)
	box.add_child(_list_caption)
	_list = VBoxContainer.new()
	_list.name = "Fights"
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", 6)
	box.add_child(_list)
	_button = Button.new()
	_button.name = "ContinueButton"
	_button.custom_minimum_size = Vector2(280, 54)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.focus_mode = Control.FOCUS_NONE
	_button.add_theme_font_size_override("font_size", 22)
	_button.pressed.connect(press_continue)
	box.add_child(_button)
