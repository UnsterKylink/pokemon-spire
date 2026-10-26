class_name EventScreen
extends Control
## Event room (mouse only, fits 1280x720): title, text, 2 option buttons; after a choice, the option's
## result text + the effects summary and "Continuer". Holds no game state: it emits option_chosen,
## Main applies the effects and calls show_result. Implements: story-005-carte-acte-1 (events, 2 options).
## Story 018: options Main reports unavailable are greyed with their reason ("Il te faut 50 P$"), money hints
## (+40 P$ / -20 P$) are appended to labels without a price, legendary events get a dark/gold frame with the
## legendary's sprite, and a pending card removal opens a DeckPicker (open_removal) that never lets play block.

## Emitted once when the player picks option `index`.
signal option_chosen(index: int)
## Emitted by "Continuer" once the result is shown.
signal finished
## Story 018: emitted when the player picks the card to forget (index into RunState.deck); Main applies it.
signal removal_picked(deck_index: int)

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_BORDER: Color = Color(0.35, 0.75, 0.42)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const COLOR_SUMMARY: Color = Color(0.55, 1.0, 0.6)
const COLOR_CHOSEN: Color = Color(1.0, 0.86, 0.3)
const PANEL_WIDTH: float = 940.0
const OPTION_SIZE: Vector2 = Vector2(640, 54)
## Story 018: unavailable option reason, money hints, removal picker texts, legendary frame.
const TEXT_NEED_MONEY: String = "Il te faut %s"
const TEXT_REMOVE_TITLE: String = "Choisis une carte à oublier (%d restante%s)"
const TEXT_REMOVE_HINT: String = "Cette carte quitte définitivement ton deck."
const TEXT_LEGENDARY: String = "Pokémon légendaire"
const COLOR_LEG_BG: Color = Color(0.06, 0.05, 0.1)
const COLOR_LEG_PANEL: Color = Color(0.1, 0.08, 0.14)
const COLOR_LEG_BORDER: Color = Color(0.95, 0.75, 0.25)
const COLOR_UNAVAILABLE: Color = Color(0.55, 0.55, 0.6)
const LEG_SPRITE_SIZE: Vector2 = Vector2(150, 150)
## Story 020b: side of the art of an item / potion / ball given by an option.
const GAIN_ART_SIDE: float = 56.0

var _event: Dictionary = {}
var _info: Label
var _title: Label
var _text: Label
var _options_box: VBoxContainer
var _option_buttons: Array[Button] = []
var _result: Label
var _summary: Label
var _continue_button: Button
var _chosen: int = -1
var _result_shown: bool = false
var _done: bool = false
var _built: bool = false
var _available: Array[bool] = []
var _bg: ColorRect
var _panel_style: StyleBoxFlat
var _leg_caption: Label
var _leg_sprite: TextureRect
var _picker: DeckPicker
## Story 020b: what the run held when the event opened (ids), to show the art of what the chosen option gave.
var _before: Dictionary = {}
var _gains: HBoxContainer


func _ready() -> void:
	_build_ui()


## Displays `event` ({id, title, text, options:[{label, ...}]}); `run` is only read for the HP line.
## Story 018: `data` (optional) gives the legendary's sprite; `availability(index) -> bool` (optional, e.g.
## Main.event_option_available) greys out the options that cannot be chosen.
func setup(event: Dictionary, run: RunState, data: GameData = null, availability: Callable = Callable()) -> void:
	_build_ui()
	_event = event
	_chosen = -1
	_result_shown = false
	_done = false
	_picker.close()
	_title.text = String(event.get("title", ""))
	_text.text = String(event.get("text", ""))
	_set_info(run)
	_before = _holdings(run)
	if _gains != null:
		_gains.visible = false
	_apply_legendary_style(event, data)
	for b: Button in _option_buttons:
		_options_box.remove_child(b)
		b.queue_free()
	_option_buttons.clear()
	_available.clear()
	var options: Array = event.get("options", [])
	for i: int in options.size():
		var option: Dictionary = options[i]
		var ok: bool = bool(availability.call(i)) if availability.is_valid() else true
		_available.append(ok)
		var b := Button.new()
		b.name = "Option%d" % i
		b.text = option_text(option, ok)
		b.custom_minimum_size = OPTION_SIZE
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not ok
		if not ok:
			b.add_theme_color_override("font_disabled_color", COLOR_UNAVAILABLE)
			b.tooltip_text = TEXT_NEED_MONEY % RunHud.format_money(int(option.get("requires_money", 0)))
		b.pressed.connect(choose.bind(i))
		_options_box.add_child(b)
		_option_buttons.append(b)
	_result.visible = false
	_summary.visible = false
	_continue_button.visible = false


## Picks option `index` (same path as a click). Ignored after the first choice.
func choose(index: int) -> void:
	if _chosen >= 0 or index < 0 or index >= _option_buttons.size():
		return
	if index < _available.size() and not _available[index]:
		return
	_chosen = index
	for i: int in _option_buttons.size():
		_option_buttons[i].disabled = true
		if i == index:
			_option_buttons[i].add_theme_color_override("font_disabled_color", COLOR_CHOSEN)
	option_chosen.emit(index)


## Shows the outcome of the chosen option: its result text and the effects summary ("" = no change).
func show_result(result_text: String, summary: String, run: RunState) -> void:
	_result.text = result_text
	_result.visible = true
	_summary.text = summary if not summary.is_empty() else "Rien ne change."
	_summary.visible = true
	_set_info(run)
	_show_gains(run)
	_continue_button.visible = true
	_result_shown = true


## Story 020b: {"items": [ids], "potions": {id: n}, "balls": {id: n}} held by `run`.
static func _holdings(run: RunState) -> Dictionary:
	var h: Dictionary = {"items": [], "potions": {}, "balls": {}}
	if run == null:
		return h
	for it: ItemData in run.items:
		(h["items"] as Array).append(it.id)
	for p: PotionData in run.potions:
		h["potions"][p.id] = int(h["potions"].get(p.id, 0)) + 1
	for bid: String in run.balls.keys():
		h["balls"][bid] = run.ball_count(bid)
	return h


## Story 020b: shows the official art of every held item / potion / ball the option just gave (tooltip = name).
func _show_gains(run: RunState) -> void:
	var now: Dictionary = _holdings(run)
	var gained: Array[String] = []
	for id: String in now["items"]:
		if not (_before.get("items", []) as Array).has(id):
			gained.append(id)
	for key: String in ["potions", "balls"]:
		var was: Dictionary = _before.get(key, {})
		for id: String in (now[key] as Dictionary).keys():
			for k: int in maxi(0, int(now[key][id]) - int(was.get(id, 0))):
				gained.append(id)
	if _gains == null:
		_gains = HBoxContainer.new()
		_gains.name = "Gains"
		_gains.alignment = BoxContainer.ALIGNMENT_CENTER
		_gains.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_gains.add_theme_constant_override("separation", 10)
		_summary.get_parent().add_child(_gains)
		_summary.get_parent().move_child(_gains, _summary.get_index() + 1)
	for child: Node in _gains.get_children():
		_gains.remove_child(child)
		child.queue_free()
	for id: String in gained:
		_gains.add_child(ItemIcon.make(id, GAIN_ART_SIDE))
	_gains.visible = not gained.is_empty()


## Presses "Continuer" (only once the result is shown).
func press_continue() -> void:
	if not _result_shown or _done:
		return
	_done = true
	finished.emit()


## Story 018: opens the deck picker for a pending event card removal (`remaining` cards still to forget). No cancel:
## the removal was part of the chosen option. Main calls it again after each pick while some remain.
func open_removal(run: RunState, data: GameData, remaining: int) -> void:
	_set_info(run)
	_picker.open(TEXT_REMOVE_TITLE % [remaining, "s" if remaining > 1 else ""], TEXT_REMOVE_HINT, run, data,
			func(_i: int) -> bool: return true)
	_picker.set_cancel_visible(false)


## Story 018: closes the removal picker.
func close_removal() -> void:
	_picker.close()


## Story 018: the removal deck picker (QA).
func get_picker() -> DeckPicker:
	return _picker


## Story 018: true if option `index` was offered as available.
func is_option_available(index: int) -> bool:
	return index >= 0 and index < _available.size() and _available[index]


## Story 018: displayed button text of option `index` ("" if none).
func get_option_text(index: int) -> String:
	return _option_buttons[index].text if index >= 0 and index < _option_buttons.size() else ""


## Story 018: the button label of `option`: its label, plus the money hint when the label shows no price, plus the
## reason when it is unavailable.
static func option_text(option: Dictionary, available: bool) -> String:
	var text: String = String(option.get("label", "")).replace("₽", RunHud.CURRENCY)  # one currency sign on screen
	var has_price: bool = text.contains(RunHud.CURRENCY)
	if not has_price:
		var delta: int = 0
		for e: Variant in option.get("effects", []):
			if not (e is Dictionary):
				continue
			match String((e as Dictionary).get("type", "")):
				"gain_money":
					delta += int((e as Dictionary).get("value", 0))
				"lose_money":
					delta -= int((e as Dictionary).get("value", 0))
		if delta != 0:
			text += "  (%s%s)" % ["+" if delta > 0 else "−", RunHud.format_money(absi(delta))]
	if not available:
		text += "  — " + TEXT_NEED_MONEY % RunHud.format_money(int(option.get("requires_money", 0)))
	return text


## The displayed event definition.
func get_event() -> Dictionary:
	return _event


## Chosen option index, -1 before the choice.
func get_chosen_index() -> int:
	return _chosen


## True once the result is displayed.
func is_result_shown() -> bool:
	return _result_shown


## The effects summary line shown after the choice.
func get_summary_text() -> String:
	return _summary.text


func _set_info(run: RunState) -> void:
	_info.text = "PV %d/%d   |   Deck : %d cartes" % [run.hp, run.max_hp, run.deck.size()]


func _build_ui() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)  # story 020: art-bible look
	var bg := ColorRect.new()
	_bg = bg
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
	sb.border_color = COLOR_BORDER
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	_panel_style = sb
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_info = CardView.make_label(18)
	box.add_child(_info)
	_leg_caption = CardView.make_label(20)
	_leg_caption.name = "LegendaryCaption"
	_leg_caption.text = TEXT_LEGENDARY
	_leg_caption.add_theme_color_override("font_color", COLOR_LEG_BORDER)
	_leg_caption.visible = false
	box.add_child(_leg_caption)
	_leg_sprite = TextureRect.new()
	_leg_sprite.name = "LegendarySprite"
	_leg_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_leg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_leg_sprite.custom_minimum_size = LEG_SPRITE_SIZE
	_leg_sprite.visible = false
	box.add_child(_leg_sprite)
	_title = CardView.make_label(40)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	box.add_child(_title)
	_text = _make_wrapped_label(22)
	box.add_child(_text)
	_options_box = VBoxContainer.new()
	_options_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_box.add_theme_constant_override("separation", 12)
	box.add_child(_options_box)
	_result = _make_wrapped_label(22)
	_result.name = "Result"
	box.add_child(_result)
	_summary = CardView.make_label(24)
	_summary.name = "Summary"
	_summary.add_theme_color_override("font_color", COLOR_SUMMARY)
	box.add_child(_summary)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continuer"
	_continue_button.custom_minimum_size = Vector2(220, 52)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.pressed.connect(press_continue)
	box.add_child(_continue_button)
	_picker = DeckPicker.new()
	_picker.card_picked.connect(_on_removal_picked)
	add_child(_picker)


func _on_removal_picked(deck_index: int) -> void:
	removal_picked.emit(deck_index)


## Story 018: dark/gold frame, caption and large sprite for legendary events; the normal look otherwise.
func _apply_legendary_style(event: Dictionary, data: GameData) -> void:
	var legendary: bool = bool(event.get("legendary", false))
	_bg.color = COLOR_LEG_BG if legendary else COLOR_BG
	_panel_style.bg_color = COLOR_LEG_PANEL if legendary else COLOR_PANEL
	_panel_style.border_color = COLOR_LEG_BORDER if legendary else COLOR_BORDER
	_panel_style.set_border_width_all(5 if legendary else 3)
	_leg_caption.visible = legendary
	_leg_sprite.texture = null
	if legendary and data != null:
		var path: String = String(data.get_pokemon_info(_legendary_pokemon_id(event, data)).get("sprite_path", ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			_leg_sprite.texture = CardView.cropped_sprite(path)
	_leg_sprite.visible = _leg_sprite.texture != null
	# The sprite costs ~160 px: tighter text keeps the result + "Continuer" inside 720 px.
	_text.add_theme_font_size_override("font_size", 20 if legendary else 22)


## The legendary Pokémon of a legendary event: the first enemy of its start_fight encounter ("" if none).
static func _legendary_pokemon_id(event: Dictionary, data: GameData) -> String:
	for option: Variant in event.get("options", []):
		for e: Variant in (option as Dictionary).get("effects", []):
			if e is Dictionary and String((e as Dictionary).get("type", "")) == "start_fight":
				var ids: Array[String] = data.get_encounter_enemy_ids(String((e as Dictionary).get("encounter", "")))
				if not ids.is_empty():
					return ids[0]
	return ""


func _make_wrapped_label(font_size: int) -> Label:
	var l: Label = CardView.make_label(font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_WIDTH - 56, 0)
	return l
