class_name CenterScreen
extends Control
## Centre Pokémon room (mouse, built in code, fits the 1280x(720 - RunHud.HEIGHT) area): the player picks ONE
## service — "Se soigner (+X PV)" or "Améliorer une carte" (deck picker of the upgradable cards -> before/after
## preview -> confirm) — then "Continuer" back to the map. Holds no game state: it emits heal_chosen /
## upgrade_chosen(deck_index), Main applies them through RunState and calls show_result.
## Implements: story-006-objets-et-services (criterion 4).
## Steps: CHOOSE -> (heal) DONE | CHOOSE -> PICK -> PREVIEW -> (confirm) DONE; "Retour" goes back one step.

## The player chose to heal.
signal heal_chosen
## The player confirmed the upgrade of deck[deck_index].
signal upgrade_chosen(deck_index: int)
## "Continuer" after the service.
signal finished

enum Step { CHOOSE, PICK, PREVIEW, WAITING, DONE }

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_ACCENT: Color = Color(0.93, 0.48, 0.68)
const COLOR_BODY: Color = Color(0.92, 0.92, 0.95)
const COLOR_RESULT: Color = Color(0.55, 1.0, 0.6)
const COLOR_UPGRADE: Color = Color(0.45, 0.95, 0.55)
const COLOR_CARD_BG: Color = Color(0.18, 0.18, 0.24)
const PANEL_WIDTH: float = 900.0
const OPTION_SIZE: Vector2 = Vector2(400, 120)
const PREVIEW_CARD_SIZE: Vector2 = Vector2(220, 270)
const TEXT_TITLE: String = "Centre Pokémon"
const TEXT_WELCOME: String = "« Bienvenue au Centre Pokémon ! » Choisis UN service avant de repartir."
const TEXT_HEAL: String = "Se soigner (+%d PV)\n%d %% des PV max"
const TEXT_UPGRADE: String = "Améliorer une carte\nUne carte du deck devient « + »"
const TEXT_NO_UPGRADE: String = "Améliorer une carte\nAucune carte améliorable"
const TEXT_PICK_TITLE: String = "Améliorer une carte"
const TEXT_PICK_HINT: String = "Choisis la carte à améliorer (une seule fois par carte)."
const TEXT_PREVIEW_TITLE: String = "Améliorer « %s » ?"

var _data: GameData
var _run: RunState
var _step: Step = Step.CHOOSE
var _preview_index: int = -1
var _info: Label
var _body: Label
var _heal_button: Button
var _upgrade_button: Button
var _result: Label
var _continue_button: Button
var _picker: DeckPicker
var _preview: Control
var _preview_title: Label
var _preview_row: HBoxContainer
var _preview_delta: Label
var _built: bool = false


func _init() -> void:
	name = "CenterScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the screen. `run` is only read; `heal_amount` = HP "Se soigner" would restore, `heal_percent` its rule.
func setup(data: GameData, run: RunState, heal_amount: int, heal_percent: float) -> void:
	_build_ui()
	_data = data
	_run = run
	_step = Step.CHOOSE
	_preview_index = -1
	_heal_button.text = TEXT_HEAL % [heal_amount, roundi(heal_percent)]
	var can_upgrade: bool = not _upgradable_indices().is_empty()
	_upgrade_button.text = TEXT_UPGRADE if can_upgrade else TEXT_NO_UPGRADE
	_upgrade_button.disabled = not can_upgrade
	_heal_button.disabled = false
	_result.visible = false
	_continue_button.visible = false
	_picker.close()
	_preview.visible = false
	_refresh_info()


## Current step (CHOOSE, PICK, PREVIEW, WAITING, DONE).
func get_step() -> Step:
	return _step


## "Se soigner" (same path as the click). Only while choosing.
func choose_heal() -> void:
	if _step != Step.CHOOSE:
		return
	_step = Step.WAITING
	heal_chosen.emit()


## "Améliorer une carte": opens the picker of the upgradable cards. Only while choosing.
func open_upgrade() -> void:
	if _step != Step.CHOOSE or _upgrade_button.disabled:
		return
	_step = Step.PICK
	_picker.open(TEXT_PICK_TITLE, TEXT_PICK_HINT, _run, _data, _run.can_upgrade_card, "", "Retour")


## Picks deck[deck_index] in the picker and shows the before / after preview.
func pick_card(deck_index: int) -> void:
	if _step != Step.PICK or not _run.can_upgrade_card(deck_index):
		return
	var after: CardData = _run.preview_upgrade(deck_index)
	if after == null:
		return
	_step = Step.PREVIEW
	_preview_index = deck_index
	_picker.close()
	_fill_preview(_run.deck[deck_index], after)
	_preview.visible = true


## Confirms the previewed upgrade (Main applies it, then calls show_result).
func confirm_upgrade() -> void:
	if _step != Step.PREVIEW:
		return
	_step = Step.WAITING
	_preview.visible = false
	upgrade_chosen.emit(_preview_index)


## "Retour": preview -> picker, picker -> choice.
func back() -> void:
	match _step:
		Step.PREVIEW:
			_preview.visible = false
			_step = Step.CHOOSE
			open_upgrade()
		Step.PICK:
			_picker.close()
			_step = Step.CHOOSE


## Shows the outcome of the service and the "Continuer" button (options locked).
func show_result(text: String) -> void:
	_step = Step.DONE
	_picker.close()
	_preview.visible = false
	_heal_button.disabled = true
	_upgrade_button.disabled = true
	_result.text = text
	_result.visible = true
	_continue_button.visible = true
	_refresh_info()


## "Continuer" (only once a service was used).
func press_continue() -> void:
	if _step != Step.DONE:
		return
	_step = Step.WAITING
	finished.emit()


## The deck picker (QA harness).
func get_picker() -> DeckPicker:
	return _picker


## Result text ("" before the choice).
func get_result_text() -> String:
	return _result.text if _result.visible else ""


## Text of the two option buttons [heal, upgrade].
func get_option_texts() -> Array[String]:
	return [_heal_button.text, _upgrade_button.text]


func _upgradable_indices() -> Array[int]:
	var out: Array[int] = []
	for i: int in _run.deck.size():
		if _run.can_upgrade_card(i):
			out.append(i)
	return out


func _refresh_info() -> void:
	_info.text = "PV %d/%d   |   Deck : %d cartes" % [_run.hp, _run.max_hp, _run.deck.size()]


func _fill_preview(before: CardData, after: CardData) -> void:
	_preview_title.text = TEXT_PREVIEW_TITLE % before.display_name
	for child: Node in _preview_row.get_children():
		_preview_row.remove_child(child)
		child.queue_free()
	_preview_row.add_child(_preview_card("Avant", before, CardView.rarity_color(before.rarity)))
	var arrow: Label = CardView.make_label(48)
	arrow.text = "→"
	arrow.add_theme_color_override("font_color", COLOR_UPGRADE)
	_preview_row.add_child(arrow)
	_preview_row.add_child(_preview_card("Après", after, COLOR_UPGRADE))
	var parts: PackedStringArray = PackedStringArray()
	if after.damage != before.damage:
		parts.append("Dégâts %d → %d" % [before.damage, after.damage])
	if after.block != before.block:
		parts.append("Protection %d → %d" % [before.block, after.block])
	if after.cost != before.cost:
		parts.append("Coût %d → %d" % [before.cost, after.cost])
	_preview_delta.text = "   |   ".join(parts)


func _preview_card(caption: String, card: CardData, border: Color) -> Control:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	var cap: Label = CardView.make_label(20)
	cap.text = caption
	cap.add_theme_color_override("font_color", border)
	col.add_child(cap)
	var b := Button.new()
	b.custom_minimum_size = PREVIEW_CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardView.fill_card_content(b, card, _data.get_type_chart(), _data.get_pokemon_info)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_BG
	sb.set_border_width_all(5)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	col.add_child(b)
	return col


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
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(3)
	sb.border_color = COLOR_ACCENT
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var title: Label = CardView.make_label(42)
	title.text = TEXT_TITLE
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	box.add_child(title)
	_info = CardView.make_label(20)
	box.add_child(_info)
	_body = CardView.make_label(22)
	_body.text = TEXT_WELCOME
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(PANEL_WIDTH - 60, 0)
	_body.add_theme_color_override("font_color", COLOR_BODY)
	box.add_child(_body)
	var options := HBoxContainer.new()
	options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 28)
	box.add_child(options)
	_heal_button = _make_option("HealButton", choose_heal)
	options.add_child(_heal_button)
	_upgrade_button = _make_option("UpgradeButton", open_upgrade)
	options.add_child(_upgrade_button)
	_result = CardView.make_label(24)
	_result.name = "Result"
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.custom_minimum_size = Vector2(PANEL_WIDTH - 60, 0)
	_result.add_theme_color_override("font_color", COLOR_RESULT)
	box.add_child(_result)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continuer"
	_continue_button.custom_minimum_size = Vector2(240, 52)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.pressed.connect(press_continue)
	box.add_child(_continue_button)
	_picker = DeckPicker.new()
	_picker.card_picked.connect(pick_card)
	_picker.cancelled.connect(back)
	add_child(_picker)
	_build_preview()


func _make_option(node_name: String, action: Callable) -> Button:
	var b := Button.new()
	b.name = node_name
	b.custom_minimum_size = OPTION_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.17, 0.22)
	sb.set_border_width_all(3)
	sb.border_color = COLOR_ACCENT
	sb.set_corner_radius_all(10)
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = sb.bg_color.lightened(0.15)
	var dis: StyleBoxFlat = sb.duplicate()
	dis.bg_color = Color(0.14, 0.14, 0.17)
	dis.border_color = COLOR_ACCENT.darkened(0.55)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", dis)
	b.pressed.connect(action)
	return b


func _build_preview() -> void:
	_preview = Control.new()
	_preview.name = "UpgradePreview"
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.visible = false
	add_child(_preview)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.13, 0.14, 0.19)
	ps.set_border_width_all(2)
	ps.border_color = COLOR_UPGRADE
	ps.set_corner_radius_all(10)
	ps.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_preview_title = CardView.make_label(30)
	box.add_child(_preview_title)
	_preview_row = HBoxContainer.new()
	_preview_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_row.add_theme_constant_override("separation", 30)
	box.add_child(_preview_row)
	_preview_delta = CardView.make_label(22)
	_preview_delta.add_theme_color_override("font_color", COLOR_UPGRADE)
	box.add_child(_preview_delta)
	var buttons := HBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	var confirm := Button.new()
	confirm.name = "ConfirmButton"
	confirm.text = "Améliorer"
	confirm.custom_minimum_size = Vector2(200, 50)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(confirm_upgrade)
	buttons.add_child(confirm)
	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "Retour"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(back)
	buttons.add_child(back_button)
