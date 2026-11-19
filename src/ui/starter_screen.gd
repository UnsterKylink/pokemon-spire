class_name StarterScreen
extends Control
## Start-of-run screen: the player picks one of the proposed starter Pokémon (mouse only, containers,
## fits 1280x720). Holds no game state: it emits starter_chosen and Main builds the run.
## Implements: story-010-pokemon-premieres-routes (starter choice).

## Emitted when the player clicks a proposal.
signal starter_chosen(pokemon_id: String)
## Story 026: the chosen difficulty level changed (selector arrows).
signal level_changed(level: int)

const SPRITE_SIZE: Vector2 = Vector2(180, 180)  # story 033: official artwork
const CARD_SIZE: Vector2 = Vector2(330, 420)
## Story 025: a Pokédex milestone can propose more starters; the cards shrink so the row stays within this width.
const ROW_MAX_WIDTH: float = 1220.0
const CARD_GAP: int = 24
const COLOR_BG: Color = UiStyle.BG_DEEP
## Story 026: card height when the difficulty selector + modifier panel are shown (the column stays within 720 px).
const CARD_HEIGHT_WITH_LEVELS: float = 360.0
## Story 026: artwork size in that compact layout; the modifier list uses MODIFIER_COLUMNS columns of MODIFIER_COL_WIDTH px.
const SPRITE_SIZE_WITH_LEVELS: Vector2 = Vector2(140, 140)
const MODIFIER_COLUMNS: int = 2
const MODIFIER_COL_WIDTH: float = 530.0
const TEXT_LEVEL: String = "Difficulté : %d"
const TEXT_LEVEL_TITLE: String = "Difficulté"
const TEXT_LEVEL_LOCKED: String = "Niveau max débloqué : %d / %d — gagne une partie complète pour débloquer le suivant."
const TEXT_MODIFIERS_HEADER: String = "Modificateurs actifs (cumulés) :"

var _choices: Array[String] = []
var _cards_box: HBoxContainer
var _title: Label
var _done: bool = false
var _built: bool = false
## Story 026: difficulty selector (hidden until setup_difficulty).
var _difficulty: Difficulty
var _level: int = 0
var _max_selectable: int = 0
var _level_box: VBoxContainer
var _level_label: Label
var _level_prev: Button
var _level_next: Button
var _level_hint: Label
var _modifiers_label: Label
var _modifiers_grid: GridContainer
var _sprite_size: Vector2 = SPRITE_SIZE
var _card_height: float = CARD_SIZE.y


func _ready() -> void:
	_build_ui()


## Shows one large clickable card per id in `choices`.
func setup(data: GameData, choices: Array[String]) -> void:
	_build_ui()
	_choices = choices.duplicate()
	_done = false
	for child: Node in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	var width: float = minf(CARD_SIZE.x, (ROW_MAX_WIDTH - CARD_GAP * maxi(0, _choices.size() - 1)) / maxf(1.0, _choices.size()))
	for i: int in _choices.size():
		var w: Button = _make_choice_widget(data, _choices[i], i)
		w.custom_minimum_size = Vector2(width, _card_height)
		_cards_box.add_child(w)


## Story 026: shows the difficulty selector: levels 0..`max_selectable` of `table` (clamped to its max_level), starting on
## `default_level` (-1 = the highest selectable). Call after setup(); without it the run is level 0.
func setup_difficulty(table: Difficulty, max_selectable: int, default_level: int = -1) -> void:
	_build_ui()
	_difficulty = table
	_max_selectable = clampi(max_selectable, 0, table.max_level if table != null else 0)
	_level_box.visible = table != null
	_card_height = CARD_HEIGHT_WITH_LEVELS if table != null else CARD_SIZE.y
	_sprite_size = SPRITE_SIZE_WITH_LEVELS if table != null else SPRITE_SIZE
	for child: Node in _cards_box.get_children():
		(child as Control).custom_minimum_size.y = _card_height
		var sprite: Control = child.find_child("Sprite", true, false) as Control
		if sprite != null:
			sprite.custom_minimum_size = _sprite_size
	set_level(_max_selectable if default_level < 0 else default_level)


## Story 026: the lines of the modifier panel (QA).
func get_modifier_lines() -> Array[String]:
	var out: Array[String] = []
	for c: Node in _modifiers_grid.get_children():
		if not c.is_queued_for_deletion():
			out.append((c as Label).text)
	return out


## Story 026: the chosen difficulty level (0 without a selector).
func get_level() -> int:
	return _level


## Story 026: selects `level` (clamped to 0..max selectable) and refreshes the modifier list.
func set_level(level: int) -> void:
	var lvl: int = clampi(level, 0, _max_selectable)
	var changed: bool = lvl != _level
	_level = lvl
	if _level_label != null and _difficulty != null:
		_level_label.text = TEXT_LEVEL % _level
		_level_prev.disabled = _level <= 0
		_level_next.disabled = _level >= _max_selectable
		_level_hint.text = TEXT_LEVEL_LOCKED % [_max_selectable, _difficulty.max_level]
		var lines: Array[String] = _difficulty.describe_lines(_level)
		_modifiers_label.text = TEXT_MODIFIERS_HEADER if _level > 0 else lines[0]
		for c: Node in _modifiers_grid.get_children():
			_modifiers_grid.remove_child(c)
			c.queue_free()
		if _level > 0:
			for line: String in lines:
				var l := Label.new()
				l.text = line
				l.custom_minimum_size = Vector2(MODIFIER_COL_WIDTH, 0)
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.mouse_filter = Control.MOUSE_FILTER_IGNORE
				l.add_theme_font_size_override("font_size", 12)
				UiStyle.dark_label(l)
				_modifiers_grid.add_child(l)
		_level_box.tooltip_text = "\n".join(lines)
	if changed:
		level_changed.emit(_level)


## The proposed Pokémon ids, left to right.
func get_choices() -> Array[String]:
	return _choices


## Chooses proposal `index` (same path as the mouse click).
func choose(index: int) -> void:
	if _done or index < 0 or index >= _choices.size():
		return
	_done = true
	starter_chosen.emit(_choices[index])


func _make_choice_widget(data: GameData, pokemon_id: String, index: int) -> Button:
	var info: Dictionary = data.get_pokemon_info(pokemon_id)
	var b := Button.new()
	b.name = "Choice%d" % index
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	# Story 033: each proposal is a white « menu Pokémon » card (blue frame; hover / press = yellow frame).
	b.add_theme_stylebox_override("normal", UiStyle.menu_panel(UiStyle.FRAME_BLUE, 0.0, 0.0))
	b.add_theme_stylebox_override("hover", UiStyle.menu_panel(UiStyle.ACCENT_YELLOW, 0.0, 0.0))
	b.add_theme_stylebox_override("pressed", UiStyle.menu_panel(UiStyle.ACCENT_YELLOW.darkened(0.15), 0.0, 0.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(choose.bind(index))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.custom_minimum_size = _sprite_size
	PokemonArt.apply(sprite, String(info["sprite_path"]))  # story 033: official artwork
	sprite.custom_minimum_size = _sprite_size
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(sprite)
	var name_label: Label = CardView.make_label(28)
	name_label.name = "PokemonName"
	name_label.text = String(info["name"])
	box.add_child(name_label)
	var row: HBoxContainer = CardView.make_type_badge_row(18)
	var types: Array[String] = []
	types.assign(info["types"])
	CardView.set_badge_row(row, types, data.get_type_chart())
	box.add_child(row)
	var deck_label: Label = CardView.make_label(18)
	deck_label.name = "DeckLine"
	deck_label.text = _deck_line(data, pokemon_id)
	deck_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(deck_label)
	return b


## "Deck : 5× Griffe, 4× Abri, 1× Écrasement" from the data-driven template.
func _deck_line(data: GameData, pokemon_id: String) -> String:
	var cards: Dictionary = data.get_starter_cards_for_type(data.get_primary_type(pokemon_id))
	var tmpl: Dictionary = data.get_starter_deck_template()
	if cards.is_empty() or tmpl.is_empty():
		return ""
	return "Deck : %d× %s, %d× %s, %d× %s" % [int(tmpl["basic_count"]), (cards["basic"] as CardData).display_name,
			int(tmpl["skill_count"]), data.get_card(String(tmpl["skill"])).display_name,
			int(tmpl["strong_count"]), (cards["strong"] as CardData).display_name]


func _build_ui() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)  # story 020: art-bible look
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)
	_title = CardView.make_label(36)
	_title.name = "Title"
	_title.text = "Choisis ton Pokémon de départ"
	column.add_child(_title)
	_cards_box = HBoxContainer.new()
	_cards_box.name = "Cards"
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", CARD_GAP)
	column.add_child(_cards_box)
	_build_level_selector(column)


## Story 026: « Difficulté : ◀ N ▶ » + the cumulative modifier list in a white panel (hidden until setup_difficulty).
func _build_level_selector(column: VBoxContainer) -> void:
	column.add_theme_constant_override("separation", 14)
	_level_box = VBoxContainer.new()
	_level_box.name = "LevelSelector"
	_level_box.visible = false
	_level_box.add_theme_constant_override("separation", 6)
	column.add_child(_level_box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	_level_box.add_child(row)
	_level_prev = Button.new()
	_level_prev.name = "LevelPrev"
	_level_prev.text = "◀"
	_level_prev.custom_minimum_size = Vector2(48, 40)
	UiStyle.apply_button(_level_prev)
	_level_prev.pressed.connect(func() -> void: set_level(_level - 1))
	row.add_child(_level_prev)
	_level_label = CardView.make_label(26)
	_level_label.name = "LevelLabel"
	_level_label.custom_minimum_size = Vector2(240, 0)
	UiStyle.apply_label(_level_label, "title")
	row.add_child(_level_label)
	_level_next = Button.new()
	_level_next.name = "LevelNext"
	_level_next.text = "▶"
	_level_next.custom_minimum_size = Vector2(48, 40)
	UiStyle.apply_button(_level_next)
	_level_next.pressed.connect(func() -> void: set_level(_level + 1))
	row.add_child(_level_next)
	_level_hint = CardView.make_label(14)
	_level_hint.name = "LevelHint"
	_level_hint.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	_level_box.add_child(_level_hint)
	var panel := PanelContainer.new()
	panel.name = "ModifiersPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiStyle.menu_sub_panel(UiStyle.FRAME_BLUE, 8.0))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_level_box.add_child(panel)
	var pbox := VBoxContainer.new()
	pbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pbox.add_theme_constant_override("separation", 2)
	panel.add_child(pbox)
	_modifiers_label = Label.new()
	_modifiers_label.name = "Modifiers"
	_modifiers_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modifiers_label.add_theme_font_size_override("font_size", 13)
	UiStyle.dark_label(_modifiers_label, UiStyle.TEXT_SUB)
	pbox.add_child(_modifiers_label)
	_modifiers_grid = GridContainer.new()
	_modifiers_grid.name = "ModifierList"
	_modifiers_grid.columns = MODIFIER_COLUMNS
	_modifiers_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modifiers_grid.add_theme_constant_override("h_separation", 18)
	_modifiers_grid.add_theme_constant_override("v_separation", 1)
	pbox.add_child(_modifiers_grid)
