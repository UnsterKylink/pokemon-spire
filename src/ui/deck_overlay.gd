class_name DeckOverlay
extends Control
## The ONE deck panel of the game (story 011): owned by Main, opened by the "Deck" button of the RunHud (and by
## the older "Voir le deck" buttons of the map / reward screens, which route here through Main).
## Covers the screen BELOW the HUD (so the HUD, and its Deck button, stay usable), dims it and blocks clicks to it.
## Outside a battle it shows the run's deck; in a battle it has 3 tabs: Deck complet / Pioche / Défausse
## (the draw pile is shown grouped and sorted by name, never in draw order). Identical copies are grouped
## ("×N"), upgraded "+" cards are distinct (gold border, own group) and each card shows its carrying Pokémon.
## Read only: it never changes RunState / Battle. Closes with "Fermer", Escape or the Deck button.
## Implements: story-011-acces-au-deck (story-004/005 overlay, story-009 carrier per card).

enum Tab { DECK, DRAW, DISCARD }

const PANEL_SIZE: Vector2 = Vector2(1180, 612)
const CARD_SIZE: Vector2 = Vector2(170, 200)
const COLUMNS: int = 6
const COLOR_CARD_BG: Color = Color(0.18, 0.18, 0.24)
const COLOR_UPGRADED: Color = Color(0.95, 0.45, 0.85)  # not a rarity colour (rare is gold)
const COLOR_HINT: Color = Color(0.75, 0.77, 0.86)
const TEXT_TITLE_RUN: String = "Ton deck (%d cartes)"
const TEXT_TITLE_BATTLE: String = "Ton deck"
const TEXT_TAB_DECK: String = "Deck complet (%d)"
const TEXT_TAB_DRAW: String = "Pioche (%d)"
const TEXT_TAB_DISCARD: String = "Défausse (%d)"
const TEXT_HINT_DRAW: String = "Cartes triées par nom : l'ordre de pioche reste secret."
const TEXT_EMPTY: String = "Aucune carte."
const TEXT_CLOSE: String = "Fermer"

var _title: Label
var _hint: Label
var _empty: Label
var _grid: GridContainer
var _scroll: ScrollContainer
var _tab_row: HBoxContainer
var _tab_buttons: Array[Button] = []
var _run: RunState
var _battle: Battle
var _data_lookup: Callable
var _chart: TypeChart
var _tab: Tab = Tab.DECK
var _lines: Array[String] = []


func _init() -> void:
	name = "DeckOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_top = RunHud.HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.14, 0.19)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.45, 0.47, 0.58)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 20)
	box.add_child(head)
	_title = CardView.make_label(28)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_tab_row = HBoxContainer.new()
	_tab_row.name = "Tabs"
	_tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tab_row.add_theme_constant_override("separation", 6)
	head.add_child(_tab_row)
	var group := ButtonGroup.new()
	for t: int in Tab.size():
		var b := Button.new()
		b.name = "Tab%d" % t
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(190, 40)
		b.pressed.connect(show_tab.bind(t as Tab))
		_tab_row.add_child(b)
		_tab_buttons.append(b)
	_hint = CardView.make_label(16)
	_hint.add_theme_color_override("font_color", COLOR_HINT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(_hint)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	var holder := VBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(holder)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 8)
	holder.add_child(_grid)
	_empty = CardView.make_label(22)
	_empty.add_theme_color_override("font_color", COLOR_HINT)
	_empty.text = TEXT_EMPTY
	holder.add_child(_empty)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = TEXT_CLOSE
	close_button.custom_minimum_size = Vector2(200, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	box.add_child(close_button)


## Escape closes the panel (and is consumed so nothing below reacts to it).
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Shows the panel on `tab`. `run` supplies the deck; `battle` (null outside a fight) adds the Pioche / Défausse
## tabs. `data` gives the Pokémon names / sprites and the type chart. Read only: nothing is modified.
func open(run: RunState, data: GameData, battle: Battle = null, tab: Tab = Tab.DECK) -> void:
	_run = run
	_battle = battle
	_data_lookup = data.get_pokemon_info
	_chart = data.get_type_chart()
	_tab_row.visible = battle != null
	show_tab(tab if battle != null else Tab.DECK)
	visible = true


## Switches to `tab` (Pioche / Défausse are ignored outside a battle).
func show_tab(tab: Tab) -> void:
	if _run == null or (_battle == null and tab != Tab.DECK):
		tab = Tab.DECK
	_tab = tab
	var deck_n: int = _run.deck.size()
	_tab_buttons[Tab.DECK].text = TEXT_TAB_DECK % deck_n
	_tab_buttons[Tab.DRAW].text = TEXT_TAB_DRAW % (_battle.draw_pile.size() if _battle != null else 0)
	_tab_buttons[Tab.DISCARD].text = TEXT_TAB_DISCARD % (_battle.discard_pile.size() if _battle != null else 0)
	_tab_buttons[tab].set_pressed_no_signal(true)
	_title.text = TEXT_TITLE_BATTLE if _battle != null else TEXT_TITLE_RUN % deck_n
	_hint.text = TEXT_HINT_DRAW if tab == Tab.DRAW else ""
	_hint.visible = tab == Tab.DRAW
	var cards: Array[CardData] = _run.deck
	if tab == Tab.DRAW:
		cards = _battle.draw_pile
	elif tab == Tab.DISCARD:
		cards = _battle.discard_pile
	_fill(cards)
	_scroll.scroll_vertical = 0


## Hides the panel ("Fermer", Escape, Deck button).
func close() -> void:
	visible = false


## True while the panel is shown.
func is_open() -> bool:
	return visible


## Current tab.
func get_tab() -> Tab:
	return _tab


## Tab button titles ("Deck complet (12)", ...), for the QA harness.
func get_tab_titles() -> Array[String]:
	var titles: Array[String] = []
	for b: Button in _tab_buttons:
		titles.append(b.text)
	return titles


## True if the tab row is shown (battle only).
func has_tabs() -> bool:
	return _tab_row.visible


## One text per displayed group ("Griffe — Salamèche ×5 (coût 1) : ..."), for the QA harness.
func get_lines() -> Array[String]:
	return _lines


## Number of card groups displayed in the current tab.
func get_group_count() -> int:
	return _lines.size()


## The scroll container of the card grid (QA: scroll position / range).
func get_scroll() -> ScrollContainer:
	return _scroll


## Groups `cards` by CardData.deck_key() and sorts by name: [{"card": CardData, "count": int}]. The input order
## (draw order for the pile) leaves no trace in the result.
static func group_cards(cards: Array[CardData]) -> Array[Dictionary]:
	var by_key: Dictionary = {}
	var entries: Array[Dictionary] = []
	for c: CardData in cards:
		var key: String = c.deck_key()
		if by_key.has(key):
			by_key[key]["count"] = int(by_key[key]["count"]) + 1
		else:
			var e: Dictionary = {"card": c, "count": 1}
			by_key[key] = e
			entries.append(e)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca: CardData = a["card"]
		var cb: CardData = b["card"]
		var by_name: int = ca.display_name.naturalnocasecmp_to(cb.display_name)
		if by_name != 0:
			return by_name < 0
		return ca.deck_key().naturalnocasecmp_to(cb.deck_key()) < 0)
	return entries


func _fill(cards: Array[CardData]) -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_lines.clear()
	var entries: Array[Dictionary] = group_cards(cards)
	for entry: Dictionary in entries:
		var card: CardData = entry["card"]
		var count: int = int(entry["count"])
		_grid.add_child(_make_cell(card, count))
		var pokemon_name: String = CardView.pokemon_name_of(card, _data_lookup)
		_lines.append("%s ×%d (coût %d) : %s" % [card.display_label(pokemon_name), count, card.cost, card.description])
	_empty.visible = entries.is_empty()


func _make_cell(card: CardData, count: int) -> Control:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	var b := Button.new()
	b.name = "Card_" + card.deck_key()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS  # display only; lets the wheel reach the ScrollContainer
	CardView.fill_card_content(b, card, _chart, _data_lookup)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_BG
	sb.set_border_width_all(4 if card.upgraded else 3)
	sb.border_color = COLOR_UPGRADED if card.upgraded else CardView.rarity_color(card.rarity)
	sb.set_corner_radius_all(6)
	for style: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(style, sb)
	col.add_child(b)
	var n: Label = CardView.make_label(16)
	n.name = "Count"
	n.text = "×%d" % count
	n.add_theme_color_override("font_color", COLOR_UPGRADED if card.upgraded else COLOR_HINT)
	col.add_child(n)
	return col
