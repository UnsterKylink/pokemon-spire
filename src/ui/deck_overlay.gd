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
## Story 017: an "Équipe" tab (always available) lists every Pokémon carrying deck cards -- the starter first, then the
## team in deck order -- with sprite, name, types, card count, evolution progress (RunState.team_progress) and a
## "Capturé" tag for the captured ones (RunState.captured, or a pre-evolution of it).

enum Tab { DECK, DRAW, DISCARD, TEAM }

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
const TEXT_TAB_TEAM: String = "Équipe (%d)"
const TEXT_TITLE_TEAM: String = "Ton équipe"
const TEXT_HINT_TEAM: String = "Chaque Pokémon porte ses cartes ; il entre sur le terrain quand tu joues l'une d'elles."
const TEXT_TEAM_CARDS: String = "%d carte%s"
const TEXT_TEAM_STARTER: String = "Pokémon de départ"
const TEXT_TEAM_PROGRESS: String = "Évolution : %d/%d combats"
const TEXT_TEAM_FINAL: String = "Forme finale"
const TEXT_TEAM_CAPTURED: String = "Capturé"
const COLOR_TEAM_ROW: Color = Color(0.17, 0.18, 0.24)
const COLOR_CAPTURED: Color = Color(0.45, 1.0, 0.55)
const COLOR_STARTER: Color = Color(1.0, 0.84, 0.3)
const TEAM_SPRITE_SIDE: float = 64.0

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
var _team_box: VBoxContainer
var _data: GameData


func _init() -> void:
	UiStyle.style_screen(self)  # story 020: art-bible look
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
		b.custom_minimum_size = Vector2(176, 40)
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
	_team_box = VBoxContainer.new()
	_team_box.name = "Team"
	_team_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_box.add_theme_constant_override("separation", 8)
	_team_box.visible = false
	holder.add_child(_team_box)
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
	_data = data
	_data_lookup = data.get_pokemon_info
	_chart = data.get_type_chart()
	_tab_row.visible = true  # story 017: Deck / Équipe outside a battle, + Pioche / Défausse in a battle
	_tab_buttons[Tab.DRAW].visible = battle != null
	_tab_buttons[Tab.DISCARD].visible = battle != null
	show_tab(tab if battle != null or tab == Tab.TEAM else Tab.DECK)
	visible = true


## Switches to `tab` (Pioche / Défausse are ignored outside a battle).
func show_tab(tab: Tab) -> void:
	if _run == null or (_battle == null and tab != Tab.DECK and tab != Tab.TEAM):
		tab = Tab.DECK
	_tab = tab
	var deck_n: int = _run.deck.size()
	_tab_buttons[Tab.DECK].text = TEXT_TAB_DECK % deck_n
	_tab_buttons[Tab.DRAW].text = TEXT_TAB_DRAW % (_battle.draw_pile.size() if _battle != null else 0)
	_tab_buttons[Tab.DISCARD].text = TEXT_TAB_DISCARD % (_battle.discard_pile.size() if _battle != null else 0)
	var team: Array[Dictionary] = team_rows(_run, _data) if _data != null else []
	_tab_buttons[Tab.TEAM].text = TEXT_TAB_TEAM % team.size()
	_tab_buttons[tab].set_pressed_no_signal(true)
	_title.text = TEXT_TITLE_BATTLE if _battle != null else TEXT_TITLE_RUN % deck_n
	_hint.text = TEXT_HINT_DRAW if tab == Tab.DRAW else ""
	_hint.visible = tab == Tab.DRAW
	_grid.visible = tab != Tab.TEAM
	_team_box.visible = tab == Tab.TEAM
	if tab == Tab.TEAM:
		_title.text = TEXT_TITLE_TEAM
		_hint.text = TEXT_HINT_TEAM
		_hint.visible = true
		_fill_team(team)
		_scroll.scroll_vertical = 0
		return
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


## Story 017: the team rows (starter first, then RunState.team_carriers order): {id, name, sprite, types: Array[String],
## cards: int, starter: bool, captured: bool, progress: String ("Évolution : 1/3 combats", "Forme finale" or "")}. Read only.
static func team_rows(run: RunState, data: GameData) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var ids: Array[String] = [run.starter_pokemon_id]
	ids.append_array(run.team_carriers())
	var steps: Array[int] = data.get_team_evolution_battles()
	for pid: String in ids:
		if pid.is_empty():
			continue
		var info: Dictionary = data.get_pokemon_info(pid)
		var starter: bool = pid == run.starter_pokemon_id
		var n: int = 0
		for c: CardData in run.deck:
			if c.pokemon_id == pid or (starter and c.pokemon_id.is_empty()):
				n += 1
		var progress: String = ""
		if not starter:
			var prog: Dictionary = run.team_progress.get(pid, {})
			var stage: int = int(prog.get("stage", 0))
			if data.get_evolution(pid).is_empty():
				progress = TEXT_TEAM_FINAL
			elif stage < steps.size():
				progress = TEXT_TEAM_PROGRESS % [mini(int(prog.get("battles", 0)), steps[stage]), steps[stage]]
		var types: Array[String] = []
		for t: Variant in info.get("types", []):
			types.append(String(t))
		rows.append({"id": pid, "name": String(info.get("name", pid)), "sprite": String(info.get("sprite_path", "")),
				"types": types, "cards": n, "starter": starter, "captured": not starter and _is_captured(run, data, pid),
				"progress": progress})
	return rows


## True if `pid` was captured, or evolved from a captured Pokémon (RunState.captured keeps the captured form's id).
static func _is_captured(run: RunState, data: GameData, pid: String) -> bool:
	for cid: String in run.captured:
		var cur: String = cid
		for guard: int in 4:
			if cur == pid:
				return true
			var evo: Dictionary = data.get_evolution(cur)
			if evo.is_empty():
				break
			cur = String(evo.get("id", ""))
	return false


func _fill_team(rows: Array[Dictionary]) -> void:
	for child: Node in _team_box.get_children():
		_team_box.remove_child(child)
		child.queue_free()
	_lines.clear()
	for row: Dictionary in rows:
		_team_box.add_child(_make_team_row(row))
		_lines.append("%s | %s | %s%s%s" % [row["name"], "/".join(PackedStringArray(row["types"])),
				TEXT_TEAM_CARDS % [int(row["cards"]), "s" if int(row["cards"]) > 1 else ""],
				" | " + String(row["progress"]) if not String(row["progress"]).is_empty() else "",
				" | " + TEXT_TEAM_CAPTURED if bool(row["captured"]) else (" | " + TEXT_TEAM_STARTER if bool(row["starter"]) else "")])
	_empty.visible = rows.is_empty()


func _make_team_row(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Team_" + String(row["id"])
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_TEAM_ROW
	sb.set_border_width_all(2)
	sb.border_color = COLOR_STARTER if bool(row["starter"]) else (COLOR_CAPTURED if bool(row["captured"]) else COLOR_HINT.darkened(0.4))
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 16)
	panel.add_child(h)
	var sprite := TextureRect.new()
	sprite.texture = CardView.cropped_sprite(String(row["sprite"]))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = Vector2.ONE * TEAM_SPRITE_SIDE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sprite)
	var name_col := VBoxContainer.new()
	name_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_col.alignment = BoxContainer.ALIGNMENT_CENTER
	name_col.custom_minimum_size = Vector2(260, 0)
	h.add_child(name_col)
	var n: Label = CardView.make_label(22)
	n.text = String(row["name"])
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_col.add_child(n)
	var badges: HBoxContainer = CardView.make_type_badge_row(14)
	badges.alignment = BoxContainer.ALIGNMENT_BEGIN
	CardView.set_badge_row(badges, row["types"], _chart)
	name_col.add_child(badges)
	var cards: Label = CardView.make_label(18)
	cards.text = TEXT_TEAM_CARDS % [int(row["cards"]), "s" if int(row["cards"]) > 1 else ""]
	cards.custom_minimum_size = Vector2(110, 0)
	h.add_child(cards)
	var prog: Label = CardView.make_label(18)
	prog.text = TEXT_TEAM_STARTER if bool(row["starter"]) else String(row["progress"])
	prog.add_theme_color_override("font_color", COLOR_STARTER if bool(row["starter"]) else COLOR_HINT)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(prog)
	if bool(row["captured"]):
		var tag := PanelContainer.new()
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = COLOR_CAPTURED.darkened(0.55)
		tsb.set_border_width_all(2)
		tsb.border_color = COLOR_CAPTURED
		tsb.set_corner_radius_all(8)
		tsb.content_margin_left = 10
		tsb.content_margin_right = 10
		tag.add_theme_stylebox_override("panel", tsb)
		var tl: Label = CardView.make_label(16)
		tl.text = TEXT_TEAM_CAPTURED
		tl.add_theme_color_override("font_color", COLOR_CAPTURED.lightened(0.3))
		tag.add_child(tl)
		h.add_child(tag)
	return panel


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
	_grid.visible = true
	_team_box.visible = false
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
