class_name EvolutionScreen
extends Control
## Story 007 (story-007-champion-evolution-fin-de-partie): shown after the Champion is beaten.
## Step REVEAL: before -> after (sprites, names, types) and "+N PV max", "Continuer".
## Step CHOOSE: 1 card among the evolved form's offers (EvolutionOffer, drawn with CardView), "Passer" allowed.
## Step DONE: what joined the deck, "Continuer" -> finished (Main then shows the victory screen).
## Display only: the evolution is already applied by Main (RunState.evolve_starter); the picked card is
## emitted with card_chosen and Main adds it, then calls show_result(). Mouse only, fits 1280x720 under the HUD.
## Story 014: also the starter's 2nd step (stage 2 -> 3, same flow); a Pokémon without a next form shows its +PV and
## the card it upgraded (no card choice); setup_team() shows the compact "Évolutions" summary of the team Pokémon
## (one before -> after row each, no card choice, "Continuer" -> finished).

## Emitted when the player picks offer `index` (Main adds the card, then calls show_result).
signal card_chosen(index: int)
## Emitted when the player passes the card choice.
signal skipped
## Emitted by "Continuer" on the DONE step.
signal finished

enum Step { REVEAL, CHOOSE, DONE }

const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const COLOR_PANEL: Color = Color(0.16, 0.17, 0.23)
const COLOR_PANEL_BORDER: Color = Color(0.45, 0.47, 0.58)
const COLOR_AFTER_BORDER: Color = Color(1.0, 0.8, 0.28)
const COLOR_BONUS: Color = Color(0.45, 0.95, 0.5)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const COLOR_CARD_BG: Color = Color(0.18, 0.18, 0.24)
const SPRITE_SIZE: Vector2 = Vector2(168, 168)
const FORM_PANEL_SIZE: Vector2 = Vector2(300, 290)
const CARD_SIZE: Vector2 = Vector2(220, 270)
const TEXT_TITLE_EVOLVED: String = "Quoi ? %s évolue !"
const TEXT_TITLE_STRONGER: String = "%s n'évolue pas — il se renforce !"
const TEXT_EVOLVED_INTO: String = "%s est devenu %s !"
const TEXT_STRONGER: String = "%s gagne en puissance."
const TEXT_HP_BONUS: String = "+%d PV max   (PV %d/%d)"
const TEXT_BEFORE: String = "Avant"
const TEXT_AFTER: String = "Après"
const TEXT_CHOOSE_TITLE: String = "%s peut apprendre une attaque"
const TEXT_CHOOSE_INFO: String = "Choisis 1 carte à ajouter à ton deck (ou passe)."
const TEXT_SKIPPED: String = "Tu n'as pris aucune nouvelle carte."
const TEXT_NONE: String = "Aucune carte à apprendre."
const TEXT_UPGRADED: String = "%s s'améliore : %s+ !"
const TEXT_UPGRADED_INFO: String = "Une de ses cartes est améliorée."
const TEXT_TEAM_TITLE: String = "Évolutions"
const TEXT_TEAM_INFO: String = "Tes Pokémon d'équipe ont gagné en expérience : leurs cartes passent à la forme évoluée."
const TEXT_TEAM_ROW_HP: String = "+%d PV max"
const TEAM_SPRITE_SIZE: Vector2 = Vector2(88, 88)
const TEAM_ROW_SIZE: Vector2 = Vector2(760, 100)

var _data: GameData
var _summary: Dictionary = {}
var _offers: Array[CardData] = []
var _step: Step = Step.REVEAL
var _team_mode: bool = false
var _built: bool = false
var _title: Label
var _info: Label
var _reveal_box: VBoxContainer
var _forms_row: HBoxContainer
var _bonus_label: Label
var _cards_box: HBoxContainer
var _result_label: Label
var _continue_button: Button
var _skip_button: Button


func _init() -> void:
	name = "EvolutionScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the screen. `summary` = RunState.evolve_starter() result, `run` is read for the HP line,
## `offers` = EvolutionOffer.generate(). Starts on the REVEAL step.
func setup(data: GameData, run: RunState, summary: Dictionary, offers: Array[CardData]) -> void:
	_build_ui()
	_data = data
	_summary = summary
	_offers = offers
	var evolved: bool = bool(summary.get("evolved", false))
	_title.text = (TEXT_TITLE_EVOLVED if evolved else TEXT_TITLE_STRONGER) % String(summary.get("from_name", ""))
	_info.text = (TEXT_EVOLVED_INTO % [summary.get("from_name", ""), summary.get("to_name", "")]) if evolved \
			else TEXT_STRONGER % String(summary.get("to_name", ""))
	_bonus_label.text = TEXT_HP_BONUS % [int(summary.get("hp_bonus", 0)), run.hp, run.max_hp]
	for child: Node in _forms_row.get_children():
		_forms_row.remove_child(child)
		child.queue_free()
	if evolved:
		_forms_row.add_child(_form_panel(TEXT_BEFORE, String(summary["from_name"]), String(summary["from_sprite"]),
				summary["from_types"], COLOR_PANEL_BORDER, 0.75))
		var arrow: Label = CardView.make_label(64)
		arrow.text = "→"
		arrow.add_theme_color_override("font_color", COLOR_AFTER_BORDER)
		_forms_row.add_child(arrow)
	_forms_row.add_child(_form_panel(TEXT_AFTER if evolved else "", String(summary.get("to_name", "")),
			String(summary.get("to_sprite", "")), summary.get("to_types", []), COLOR_AFTER_BORDER, 1.0))
	for child: Node in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	for i: int in offers.size():
		_cards_box.add_child(_make_offer_widget(offers[i], i))
	var upgraded: String = String(summary.get("upgraded_card", ""))
	if not evolved and not upgraded.is_empty():
		_bonus_label.text += "\n" + TEXT_UPGRADED % [String(summary.get("to_name", "")), upgraded.trim_suffix("+")]
	_set_step(Step.REVEAL)


## Story 014: the team evolution summary. `rows` = RunState.evolve_team() (already applied by Main); `run` is read for
## the HP line. One row per Pokémon: small sprites, "Avant -> Après" names, its +PV. "Continuer" emits finished.
func setup_team(data: GameData, run: RunState, rows: Array[Dictionary]) -> void:
	_build_ui()
	_data = data
	_team_mode = true
	_offers = []
	_summary = {}
	for child: Node in _forms_row.get_children():
		_forms_row.remove_child(child)
		child.queue_free()
	var list := VBoxContainer.new()
	list.name = "TeamRows"
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", 10)
	_forms_row.add_child(list)
	var total: int = 0
	for row: Dictionary in rows:
		list.add_child(_team_row(row))
		total += int(row.get("hp_bonus", 0))
	_bonus_label.text = TEXT_HP_BONUS % [total, run.hp, run.max_hp] if total > 0 else ""
	_set_step(Step.REVEAL)
	_title.text = TEXT_TEAM_TITLE
	_info.text = TEXT_TEAM_INFO


## True while the screen shows the team summary (setup_team).
func is_team_mode() -> bool:
	return _team_mode


## Current step (REVEAL, CHOOSE or DONE).
func get_step() -> Step:
	return _step


## The offered cards (carried by the evolved form).
func get_offers() -> Array[CardData]:
	return _offers


## Title text (QA).
func get_title_text() -> String:
	return _title.text


## "+15 PV max (PV 90/90)" (QA).
func get_bonus_text() -> String:
	return _bonus_label.text


## Result line of the DONE step (QA).
func get_result_text() -> String:
	return _result_label.text


## "Continuer": REVEAL -> CHOOSE (or DONE if nothing to learn); DONE -> finished. Ignored on CHOOSE.
func press_continue() -> void:
	match _step:
		Step.REVEAL:
			if _team_mode:
				_step = Step.DONE
				finished.emit()
			elif _offers.is_empty():
				var up: String = String(_summary.get("upgraded_card", ""))
				show_result(TEXT_NONE if up.is_empty() else TEXT_UPGRADED % [String(_summary.get("to_name", "")), up.trim_suffix("+")])
			else:
				_set_step(Step.CHOOSE)
		Step.DONE:
			finished.emit()


## Picks offer `index` on the CHOOSE step (same path as the click).
func pick(index: int) -> void:
	if _step != Step.CHOOSE or index < 0 or index >= _offers.size():
		return
	_step = Step.DONE  # one pick only, even before Main answers
	card_chosen.emit(index)


## "Passer" on the CHOOSE step.
func skip() -> void:
	if _step != Step.CHOOSE:
		return
	_step = Step.DONE
	skipped.emit()
	show_result(TEXT_SKIPPED)


## Shows the DONE step with `text` ("Lance-Flammes rejoint ton deck !").
func show_result(text: String) -> void:
	_result_label.text = text
	_set_step(Step.DONE)


func _set_step(step: Step) -> void:
	_step = step
	_reveal_box.visible = step == Step.REVEAL
	_cards_box.visible = step == Step.CHOOSE
	_result_label.visible = step == Step.DONE
	_skip_button.visible = step == Step.CHOOSE
	_continue_button.visible = step != Step.CHOOSE
	var to_name: String = String(_summary.get("to_name", ""))
	match step:
		Step.REVEAL:
			if _team_mode:
				return
			_title.text = (TEXT_TITLE_EVOLVED if bool(_summary.get("evolved", false)) else TEXT_TITLE_STRONGER) \
					% String(_summary.get("from_name", ""))
		Step.CHOOSE:
			_title.text = TEXT_CHOOSE_TITLE % to_name
			_info.text = TEXT_CHOOSE_INFO
		Step.DONE:
			_title.text = TEXT_CHOOSE_TITLE % to_name
			_info.text = ""


func _build_ui() -> void:
	if _built:
		return
	_built = true
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	_title = CardView.make_label(42)
	_title.name = "Title"
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	root.add_child(_title)
	_info = CardView.make_label(22)
	_info.name = "Info"
	root.add_child(_info)
	_reveal_box = VBoxContainer.new()
	_reveal_box.name = "Reveal"
	_reveal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_reveal_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reveal_box.add_theme_constant_override("separation", 18)
	root.add_child(_reveal_box)
	_forms_row = HBoxContainer.new()
	_forms_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_forms_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_forms_row.add_theme_constant_override("separation", 36)
	_reveal_box.add_child(_forms_row)
	_bonus_label = CardView.make_label(32)
	_bonus_label.name = "HpBonus"
	_bonus_label.add_theme_color_override("font_color", COLOR_BONUS)
	_reveal_box.add_child(_bonus_label)
	_cards_box = HBoxContainer.new()
	_cards_box.name = "Cards"
	_cards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_box.add_theme_constant_override("separation", 28)
	root.add_child(_cards_box)
	_result_label = CardView.make_label(30)
	_result_label.name = "Result"
	_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_result_label)
	var buttons := HBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(buttons)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continuer"
	_continue_button.custom_minimum_size = Vector2(220, 52)
	_continue_button.pressed.connect(press_continue)
	buttons.add_child(_continue_button)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = "Passer"
	_skip_button.custom_minimum_size = Vector2(220, 52)
	_skip_button.pressed.connect(skip)
	buttons.add_child(_skip_button)


## One form (before / after): caption, sprite, name, type badges in a bordered panel.
func _form_panel(caption: String, pokemon_name: String, sprite_path: String, types_v: Variant, border: Color,
		sprite_alpha: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = FORM_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var cap: Label = CardView.make_label(18)
	cap.text = caption
	cap.add_theme_color_override("font_color", COLOR_CAPTION)
	box.add_child(cap)
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = CardView.cropped_sprite(sprite_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.custom_minimum_size = SPRITE_SIZE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.modulate.a = sprite_alpha
	box.add_child(sprite)
	var name_label: Label = CardView.make_label(28)
	name_label.name = "PokemonName"
	name_label.text = pokemon_name
	box.add_child(name_label)
	var row: HBoxContainer = CardView.make_type_badge_row(18)
	var types: Array[String] = []
	if types_v is Array:
		for t: Variant in (types_v as Array):
			types.append(String(t))
	CardView.set_badge_row(row, types, _data.get_type_chart())
	box.add_child(row)
	return panel


## One team row: before sprite + name -> after sprite + name, then the row's +PV.
func _team_row(row: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Row_%s" % String(row.get("to_id", ""))
	panel.custom_minimum_size = TEAM_ROW_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(2)
	sb.border_color = COLOR_AFTER_BORDER
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	panel.add_child(h)
	for side: String in ["from", "to"]:
		var sprite := TextureRect.new()
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture = CardView.cropped_sprite(String(row.get(side + "_sprite", "")))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.custom_minimum_size = TEAM_SPRITE_SIZE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.modulate.a = 0.75 if side == "from" else 1.0
		h.add_child(sprite)
		var name_label: Label = CardView.make_label(26)
		name_label.text = String(row.get(side + "_name", ""))
		name_label.custom_minimum_size = Vector2(190, 0)
		h.add_child(name_label)
		if side == "from":
			var arrow: Label = CardView.make_label(40)
			arrow.text = "→"
			arrow.add_theme_color_override("font_color", COLOR_AFTER_BORDER)
			h.add_child(arrow)
	var hp: Label = CardView.make_label(22)
	hp.text = TEXT_TEAM_ROW_HP % int(row.get("hp_bonus", 0)) if int(row.get("hp_bonus", 0)) > 0 else ""
	hp.add_theme_color_override("font_color", COLOR_BONUS)
	h.add_child(hp)
	return panel


## One offered card: CardView button (rarity border) + rarity label.
func _make_offer_widget(card: CardData, index: int) -> Control:
	var col := VBoxContainer.new()
	col.name = "Offer%d" % index
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	var b := Button.new()
	b.name = "Card"
	b.custom_minimum_size = CARD_SIZE
	CardView.fill_card_content(b, card, _data.get_type_chart(), _data.get_pokemon_info)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_BG
	sb.set_border_width_all(5)
	sb.border_color = CardView.rarity_color(card.rarity)
	sb.set_corner_radius_all(8)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = sb.bg_color.lightened(0.15)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_hover)
	b.pressed.connect(pick.bind(index))
	col.add_child(b)
	var rarity: Label = CardView.make_label(20)
	rarity.name = "Rarity"
	rarity.text = CardView.rarity_name(card.rarity) + (" · améliorée" if card.upgraded else "")
	rarity.add_theme_color_override("font_color", CardView.rarity_color(card.rarity))
	col.add_child(rarity)
	return col
