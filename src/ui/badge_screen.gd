class_name BadgeScreen
extends Control
## Story 012 (story-012-structure-8-arenes): shown after a gym win (after its card reward). "Tu as gagné le Badge X !",
## the beaten Champion and the gym type, the badge drawn large (BadgeEmblem), the badge's bonus, what it unlocks /
## what comes next, the progress "Badges : n/8" with the row of badges, and "Continuer" ("Terminer" on the last zone).
## Display only: Main has already awarded the badge (RunState.award_badge); the button emits finished and Main calls
## badge_continue(). Mouse only, fits 1280x720 under the HUD.

## Emitted once by "Continuer" / "Terminer".
signal finished

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_BODY: Color = Color(0.92, 0.92, 0.95)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const COLOR_BONUS: Color = Color(0.45, 0.95, 0.5)
const PANEL_WIDTH: float = 760.0
const EMBLEM_SIDE: float = 150.0
const ROW_BADGE_SIDE: float = 30.0
const TEXT_TITLE: String = "Tu as gagné le %s !"
const TEXT_LEADER: String = "Tu as battu %s, Champion de l'arène"
const TEXT_BONUS: String = "Bonus : %s"
const TEXT_NO_BONUS: String = "Bonus : aucun"
const TEXT_UNLOCK_WILD: String = "Débloqué : de nouveaux groupes de Pokémon sauvages dans les zones suivantes."
const TEXT_UNLOCK_ELITE: String = "Débloqué : de nouveaux combats d'élite dans les zones suivantes."
const TEXT_EVOLUTION: String = "%s va évoluer !"
const TEXT_NEXT_ZONE: String = "Prochaine étape : Zone %d — Arène %s"
const TEXT_LAST_ZONE: String = "C'était la dernière arène !"
const TEXT_PROGRESS: String = "Badges : %d/%d"
const TEXT_CONTINUE: String = "Continuer"
const TEXT_FINISH: String = "Terminer"

var _built: bool = false
var _done: bool = false
var _panel_style: StyleBoxFlat
var _title: Label
var _leader: Label
var _type_row: HBoxContainer
var _emblem: BadgeEmblem
var _bonus: Label
var _unlock: Label
var _progress: Label
var _badge_row: HBoxContainer
var _button: Button


func _init() -> void:
	name = "BadgeScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the screen with `badge` (the dict of RunState.award_badge, already in run.badges). Reads `run` / `data` only.
func setup(data: GameData, run: RunState, badge: Dictionary) -> void:
	_build_ui()
	_done = false
	var color: Color = badge.get("color", Color.WHITE)
	_panel_style.border_color = color
	_title.text = TEXT_TITLE % String(badge.get("name", ""))
	_title.add_theme_color_override("font_color", color.lightened(0.25))
	_leader.text = TEXT_LEADER % String(badge.get("leader", ""))
	var types: Array[String] = [String(badge.get("type_id", ""))]
	CardView.set_badge_row(_type_row, types, data.get_type_chart())
	_emblem.set_badge(color, true)
	_emblem.tooltip_text = BadgeEmblem.tooltip_of(badge)
	var bonus_text: String = String(badge.get("bonus_text", ""))
	_bonus.text = TEXT_BONUS % bonus_text if not bonus_text.is_empty() else TEXT_NO_BONUS
	_unlock.text = "\n".join(unlock_lines(data, run, badge))
	_unlock.visible = not _unlock.text.is_empty()
	_progress.text = TEXT_PROGRESS % [run.badges.size(), run.zones.size()]
	BadgeEmblem.fill_row(_badge_row, run, ROW_BADGE_SIDE)
	_button.text = TEXT_FINISH if run.is_final_zone() else TEXT_CONTINUE


## The "unlock / next" lines for `badge`: new wild / elite pools (zones.json unlock_pools), the starter's evolution when
## zones.json evolution_after_badges lists this badge, then the next zone (or "last gym").
static func unlock_lines(data: GameData, run: RunState, badge: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var unlocks: Dictionary = badge.get("unlocks", {})
	if not (unlocks.get("wild", []) as Array).is_empty():
		lines.append(TEXT_UNLOCK_WILD)
	if not (unlocks.get("elite", []) as Array).is_empty():
		lines.append(TEXT_UNLOCK_ELITE)
	if data.get_evolution_after_badges().has(int(badge.get("index", 0))) and not run.evolution_applied:
		lines.append(TEXT_EVOLUTION % run.display_name)
	if run.is_final_zone():
		lines.append(TEXT_LAST_ZONE)
	else:
		var next: Dictionary = run.zones[run.zone_index + 1]
		lines.append(TEXT_NEXT_ZONE % [int(next["number"]), String(next["type_name"])])
	return lines


## Presses the button (same path as a click); once only.
func press_continue() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## Displayed title ("Tu as gagné le Badge Roche !").
func get_title_text() -> String:
	return _title.text


## Displayed Champion line.
func get_leader_text() -> String:
	return _leader.text


## Displayed bonus line.
func get_bonus_text() -> String:
	return _bonus.text


## Displayed unlock / next-zone lines.
func get_unlock_text() -> String:
	return _unlock.text


## Displayed progress ("Badges : 1/8").
func get_progress_text() -> String:
	return _progress.text


## Button text ("Continuer" / "Terminer").
func get_button_text() -> String:
	return _button.text


func _build_ui() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)  # story 020: art-bible look
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
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
	_panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_title = CardView.make_label(38)
	_title.name = "Title"
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	box.add_child(_title)
	var leader_row := HBoxContainer.new()
	leader_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leader_row.alignment = BoxContainer.ALIGNMENT_CENTER
	leader_row.add_theme_constant_override("separation", 10)
	box.add_child(leader_row)
	_leader = CardView.make_label(22)
	_leader.name = "Leader"
	_leader.add_theme_color_override("font_color", COLOR_BODY)
	leader_row.add_child(_leader)
	_type_row = CardView.make_type_badge_row(18)
	leader_row.add_child(_type_row)
	_emblem = BadgeEmblem.create(EMBLEM_SIDE, Color.WHITE, true, " ")
	_emblem.name = "Emblem"
	box.add_child(_emblem)
	_bonus = CardView.make_label(22)
	_bonus.name = "Bonus"
	_bonus.add_theme_color_override("font_color", COLOR_BONUS)
	box.add_child(_bonus)
	_unlock = CardView.make_label(18)
	_unlock.name = "Unlock"
	_unlock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unlock.custom_minimum_size = Vector2(PANEL_WIDTH - 48, 0)
	_unlock.add_theme_color_override("font_color", COLOR_CAPTION)
	box.add_child(_unlock)
	_progress = CardView.make_label(22)
	_progress.name = "Progress"
	_progress.add_theme_color_override("font_color", COLOR_BODY)
	box.add_child(_progress)
	_badge_row = HBoxContainer.new()
	_badge_row.name = "BadgeRow"
	_badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_badge_row.add_theme_constant_override("separation", 8)
	box.add_child(_badge_row)
	_button = Button.new()
	_button.name = "ContinueButton"
	_button.custom_minimum_size = Vector2(240, 54)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.focus_mode = Control.FOCUS_NONE
	_button.add_theme_font_size_override("font_size", 22)
	_button.pressed.connect(press_continue)
	box.add_child(_button)
