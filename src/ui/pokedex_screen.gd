class_name PokedexScreen
extends Control
## Story 025 (story-025-pokedex): the Pokédex screen, opened from the title screen (« Pokédex »). « Menu Pokémon » look
## (UiStyle.style_screen): a header window (title, counters « Vus : X / Capturés : Y / Total : Z », « Retour »), the
## generation tabs Gén. 1-9 and « Paliers », the filters (type: 18 + Tous; Tous / Vus / Capturés), the thumbnail grid
## (PokedexGrid: lazy, ~900 entries) and a side window that shows either the selected Pokémon's sheet (big official
## artwork, name + national number, type pills, taught cards as mini cards, times seen / caught — an unseen Pokémon
## shows only its silhouette and number) or the milestone list with progress (pokedex_rewards.json).
## Display only: reads Pokedex / PokedexCatalog / PokedexRewards, emits back_requested (Retour / Échap) and Main acts.

signal back_requested

const STATUS_ALL: String = "all"
const STATUS_SEEN: String = "seen"
const STATUS_CAUGHT: String = "caught"
const STATUSES: Array[String] = [STATUS_ALL, STATUS_SEEN, STATUS_CAUGHT]
const STATUS_TEXTS: Array[String] = ["Tous", "Vus", "Capturés"]
const SIDE_WIDTH: float = 410.0
const DETAIL_ART: Vector2 = Vector2(210, 190)
const MINI_CARD: Vector2 = Vector2(128, 150)
const TEXT_TITLE: String = "Pokédex"
const TEXT_COUNTERS: String = "Vus : %d   /   Capturés : %d   /   Total : %d"
const TEXT_BACK: String = "Retour"
const TEXT_GEN: String = "Gén. %d"
const TEXT_MILESTONES: String = "Paliers"
const TEXT_ALL_TYPES: String = "Tous les types"
const TEXT_TYPE: String = "Type :"
const TEXT_SHOW: String = "Afficher :"
const TEXT_LIST_INFO: String = "Génération %d — %d Pokémon affichés (%d vus, %d capturés)"
const TEXT_EMPTY: String = "Aucun Pokémon ne correspond à ces filtres."
const TEXT_NUMBER: String = "N° %03d"
const TEXT_UNKNOWN: String = "???"
const TEXT_UNSEEN_HINT: String = "Jamais rencontré. Croise-le en partie pour remplir sa fiche."
const TEXT_TEACHES: String = "Cartes enseignées"
const TEXT_NO_CARD: String = "Aucune carte."
const TEXT_STATS: String = "Vu : %d fois   ·   Capturé : %d fois"
const TEXT_PICK_HINT: String = "Choisis un Pokémon dans la grille pour voir sa fiche."
const TEXT_MS_TITLE: String = "Paliers du Pokédex"
const TEXT_MS_INTRO: String = "Récompenses permanentes selon le nombre d'espèces capturées, appliquées au début de chaque nouvelle partie."
const TEXT_MS_PROGRESS: String = "%d / %d capturés"
const TEXT_MS_DONE: String = "Débloqué"
const COLOR_DONE: Color = UiStyle.INK_GREEN

var _data: GameData
var _catalog: PokedexCatalog
var _dex: Pokedex
var _rewards: PokedexRewards
var _generation: int = 1
var _type_id: String = ""
var _status: String = STATUS_ALL
var _built: bool = false
var _counters: Label
var _gen_buttons: Array[Button] = []
var _ms_button: Button
var _status_buttons: Array[Button] = []
var _type_select: OptionButton
var _type_ids: Array[String] = []
var _list_info: Label
var _empty_label: Label
var _grid: PokedexGrid
var _scroll: ScrollContainer
var _side_box: VBoxContainer
var _side_mode: String = "detail"
var _detail_slug: String = ""
var _back_button: Button
var _tooltip: KeywordTooltip


func _init() -> void:
	name = "PokedexScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build()


## Fills the screen. `dex` null = an empty Pokédex. Starts on generation 1, no filter, the hint in the side window.
func setup(data: GameData, catalog: PokedexCatalog, dex: Pokedex, rewards: PokedexRewards) -> void:
	_build()
	_data = data
	_catalog = catalog
	_dex = dex if dex != null else Pokedex.new()
	_rewards = rewards if rewards != null else PokedexRewards.new()
	_type_ids = data.get_type_chart().get_type_ids() if data != null else ([] as Array[String])
	_type_select.clear()
	_type_select.add_item(TEXT_ALL_TYPES)
	for t: String in _type_ids:
		_type_select.add_item(data.get_type_chart().get_type_name(t))
	_type_select.select(0)
	var slugs: PackedStringArray = _catalog.slugs()
	_counters.text = TEXT_COUNTERS % [_dex.seen_total(slugs), _dex.caught_total(slugs), _catalog.size()]
	_side_mode = "detail"
	_detail_slug = ""
	_refresh_grid()
	_show_hint()
	(func() -> void:
		if is_instance_valid(_grid) and _grid.is_inside_tree():
			_grid.grab_focus()).call_deferred()


## Header counter text (QA).
func get_counter_text() -> String:
	return _counters.text if _counters != null else ""


## Shows generation `g` (1..9).
func select_generation(g: int) -> void:
	_generation = clampi(g, 1, PokedexCatalog.GENERATION_COUNT)
	for i: int in _gen_buttons.size():
		_gen_buttons[i].set_pressed_no_signal(i + 1 == _generation)
	_refresh_grid()


## Type filter: `type_id` of types.json, "" = every type.
func set_type_filter(type_id: String) -> void:
	_type_id = type_id if _type_ids.has(type_id) else ""
	_type_select.select(_type_ids.find(_type_id) + 1 if not _type_id.is_empty() else 0)
	_refresh_grid()


## Status filter: "all", "seen" or "caught".
func set_status_filter(status: String) -> void:
	_status = status if STATUSES.has(status) else STATUS_ALL
	for i: int in _status_buttons.size():
		_status_buttons[i].set_pressed_no_signal(STATUSES[i] == _status)
	_refresh_grid()


## The thumbnail grid (QA).
func get_grid() -> PokedexGrid:
	return _grid


## Slugs listed in the grid (QA).
func get_listed_slugs() -> PackedStringArray:
	return _grid.get_slugs()


## Opens the sheet of `slug` in the side window (selects it in the grid when listed). False if unknown.
func open_detail(slug: String) -> bool:
	if _catalog == null or not _catalog.has(slug):
		return false
	if not _grid.select_slug(slug):
		_show_detail(slug)
	return true


## Slug of the sheet on show ("" when the side window shows the hint or the milestones).
func get_detail_slug() -> String:
	return _detail_slug if _side_mode == "detail" else ""


## Shows the milestone list in the side window.
func show_milestones() -> void:
	_side_mode = "milestones"
	_ms_button.set_pressed_no_signal(true)
	_clear_side()
	var title: Label = _side_label(26, UiStyle.TEXT_DARK)
	title.text = TEXT_MS_TITLE
	title.add_theme_font_override("font", UiStyle.font_title())
	var intro: Label = _side_label(15, UiStyle.TEXT_SUB)
	intro.text = TEXT_MS_INTRO
	var caught: int = _dex.caught_total(_catalog.slugs())
	for m: Dictionary in _rewards.milestones:
		var done: bool = caught >= int(m["caught"])
		var row := PanelContainer.new()
		row.name = "Milestone_" + String(m["id"])
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", UiStyle.menu_sub_panel(COLOR_DONE if done else UiStyle.FRAME_BLUE, 8.0))
		_side_box.add_child(row)
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_theme_constant_override("separation", 2)
		row.add_child(col)
		var head := HBoxContainer.new()
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(head)
		var n: Label = CardView.make_label(18)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.add_theme_font_override("font", UiStyle.font_bold())
		n.text = "%d — %s" % [int(m["caught"]), String(m["name"])]
		head.add_child(n)
		var state: Label = CardView.make_label(15)
		state.add_theme_font_override("font", UiStyle.font_bold())
		state.text = TEXT_MS_DONE if done else TEXT_MS_PROGRESS % [mini(caught, int(m["caught"])), int(m["caught"])]
		state.add_theme_color_override("font_color", COLOR_DONE if done else UiStyle.TEXT_SUB)
		head.add_child(state)
		var d: Label = CardView.make_label(14)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.text = String(m["description"])
		col.add_child(d)
		var bar := ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.max_value = float(m["caught"])
		bar.value = float(mini(caught, int(m["caught"])))
		var fill := StyleBoxFlat.new()
		fill.bg_color = COLOR_DONE if done else UiStyle.ACCENT_BLUE
		fill.set_corner_radius_all(4)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#C9D3E6")
		bg.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", bg)
		col.add_child(bar)


## True when the side window shows the milestones (QA).
func is_milestones_shown() -> bool:
	return _side_mode == "milestones"


## Échap: closes the milestones / sheet first, else back to the title. Always true (handled).
func handle_cancel() -> bool:
	if _tooltip != null:
		_tooltip.visible = false
	back_requested.emit()
	return true


## « Retour ».
func press_back() -> void:
	back_requested.emit()


func _refresh_grid() -> void:
	if _catalog == null:
		return
	var list: Array[Dictionary] = _catalog.filtered(_generation, _type_id, _status, _dex)
	_grid.set_entries(list, _dex)
	var seen_n: int = 0
	var caught_n: int = 0
	for e: Dictionary in list:
		seen_n += 1 if _dex.is_seen(String(e["slug"])) else 0
		caught_n += 1 if _dex.is_caught(String(e["slug"])) else 0
	_list_info.text = TEXT_LIST_INFO % [_generation, list.size(), seen_n, caught_n]
	_empty_label.visible = list.is_empty()


func _on_grid_selected(slug: String) -> void:
	_show_detail(slug)


func _show_hint() -> void:
	_clear_side()
	var hint: Label = _side_label(17, UiStyle.TEXT_SUB)
	hint.text = TEXT_PICK_HINT
	hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _show_detail(slug: String) -> void:
	var e: Dictionary = _catalog.get_entry(slug)
	if e.is_empty():
		return
	_side_mode = "detail"
	_ms_button.set_pressed_no_signal(false)
	_detail_slug = slug
	_clear_side()
	var seen: bool = _dex.is_seen(slug)
	var number: Label = _side_label(16, UiStyle.TEXT_SUB)
	number.name = "Number"
	number.text = TEXT_NUMBER % int(e["dex"])
	number.add_theme_font_override("font", UiStyle.font_bold())
	var art := TextureRect.new()
	art.name = "Artwork"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PokemonArt.apply(art, String(e["sprite_path"]))
	art.custom_minimum_size = DETAIL_ART
	if not seen:
		art.self_modulate = PokedexGrid.COLOR_SILHOUETTE
	_side_box.add_child(art)
	var name_label: Label = _side_label(28, UiStyle.TEXT_DARK)
	name_label.name = "PokemonName"
	name_label.add_theme_font_override("font", UiStyle.font_title())
	name_label.text = String(e["name"]) if seen else TEXT_UNKNOWN
	if not seen:
		var hint: Label = _side_label(15, UiStyle.TEXT_SUB)
		hint.text = TEXT_UNSEEN_HINT
		return
	var types: Array[String] = []
	types.assign(e["types"])
	var row: HBoxContainer = CardView.make_type_badge_row(16)
	CardView.set_badge_row(row, types, _data.get_type_chart())
	_side_box.add_child(row)
	var stats: Label = _side_label(16, UiStyle.TEXT_DARK)
	stats.name = "Stats"
	stats.text = TEXT_STATS % [_dex.seen_count(slug), _dex.caught_count(slug)]
	var teach_title: Label = _side_label(17, UiStyle.TEXT_SUB)
	teach_title.text = TEXT_TEACHES
	teach_title.add_theme_font_override("font", UiStyle.font_bold())
	var cards := HBoxContainer.new()
	cards.name = "Cards"
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 10)
	_side_box.add_child(cards)
	var carrier: String = String((e["ids"] as Array[String])[0]) if not (e["ids"] as Array[String]).is_empty() else ""
	for cid: String in e["teaches"]:
		if cards.get_child_count() >= 3:
			break
		var card: CardData = _data.get_card(cid)
		if card == null:
			continue
		if not carrier.is_empty():
			card = card.with_pokemon(carrier)
		var b := Button.new()
		b.name = "Card_" + cid
		b.custom_minimum_size = MINI_CARD
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		CardView.fill_card_content(b, card, _data.get_type_chart(), _data.get_pokemon_info)
		b.mouse_entered.connect(_show_card_tip.bind(b, card))
		b.mouse_exited.connect(func() -> void: _tooltip.visible = false)
		cards.add_child(b)
	if cards.get_child_count() == 0:
		var none: Label = _side_label(15, UiStyle.TEXT_SUB)
		none.text = TEXT_NO_CARD


func _show_card_tip(b: Button, card: CardData) -> void:
	var entries: Array[Dictionary] = CardView.card_keywords(card, _data.get_talent_book())
	_tooltip.show_for(entries, b.get_global_rect())


func _clear_side() -> void:
	if _tooltip != null:
		_tooltip.visible = false
	for c: Node in _side_box.get_children():
		_side_box.remove_child(c)
		c.queue_free()


func _side_label(font_size: int, color: Color) -> Label:
	var l: Label = CardView.make_label(font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(SIDE_WIDTH - 50.0, 0)
	l.add_theme_color_override("font_color", color)
	_side_box.add_child(l)
	return l


func _build() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var main := VBoxContainer.new()
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_theme_constant_override("separation", 8)
	margin.add_child(main)
	# Header window: title, counters, back.
	var header := PanelContainer.new()
	header.name = "Header"
	header.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.ACCENT_RED, 16.0, 6.0))
	main.add_child(header)
	var head_row := HBoxContainer.new()
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_theme_constant_override("separation", 18)
	header.add_child(head_row)
	var title: Label = CardView.make_label(34)
	title.name = "Title"
	title.text = TEXT_TITLE
	title.add_theme_font_override("font", UiStyle.font_title())
	title.add_theme_color_override("font_color", UiStyle.ACCENT_RED)
	head_row.add_child(title)
	_counters = CardView.make_label(20)
	_counters.name = "Counters"
	_counters.add_theme_font_override("font", UiStyle.font_bold())
	_counters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counters.add_theme_color_override("font_color", UiStyle.TEXT_DARK)
	head_row.add_child(_counters)
	_back_button = Button.new()
	_back_button.name = "Back"
	_back_button.text = TEXT_BACK
	_back_button.custom_minimum_size = Vector2(150, 44)
	_back_button.add_theme_font_override("font", UiStyle.font_title())
	_back_button.add_theme_font_size_override("font_size", 21)
	UiStyle.apply_button(_back_button, UiStyle.ACCENT_BLUE)
	_back_button.pressed.connect(press_back)
	head_row.add_child(_back_button)
	# Generation tabs + milestones.
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabs.add_theme_constant_override("separation", 6)
	main.add_child(tabs)
	var gen_group := ButtonGroup.new()
	for g: int in range(1, PokedexCatalog.GENERATION_COUNT + 1):
		var b: Button = _toggle("Gen%d" % g, TEXT_GEN % g, 96.0)
		b.button_group = gen_group
		b.set_pressed_no_signal(g == 1)
		b.pressed.connect(select_generation.bind(g))
		tabs.add_child(b)
		_gen_buttons.append(b)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	_ms_button = _toggle("Milestones", TEXT_MILESTONES, 150.0)
	_ms_button.pressed.connect(func() -> void:
		if _side_mode == "milestones":
			_ms_button.set_pressed_no_signal(false)
			if _detail_slug.is_empty():
				_side_mode = "detail"
				_show_hint()
			else:
				_show_detail(_detail_slug)
		else:
			show_milestones())
	tabs.add_child(_ms_button)
	# Body: grid window + side window.
	var body := HBoxContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	main.add_child(body)
	var grid_panel := PanelContainer.new()
	grid_panel.name = "GridPanel"
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.FRAME_BLUE, 14.0, 10.0))
	body.add_child(grid_panel)
	var grid_col := VBoxContainer.new()
	grid_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_col.add_theme_constant_override("separation", 6)
	grid_panel.add_child(grid_col)
	var filters := HBoxContainer.new()
	filters.name = "Filters"
	filters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filters.add_theme_constant_override("separation", 8)
	grid_col.add_child(filters)
	var type_label: Label = CardView.make_label(16)
	type_label.text = TEXT_TYPE
	type_label.add_theme_font_override("font", UiStyle.font_bold())
	filters.add_child(type_label)
	_type_select = OptionButton.new()
	_type_select.name = "TypeFilter"
	_type_select.custom_minimum_size = Vector2(170, 36)
	_type_select.item_selected.connect(func(i: int) -> void:
		_type_id = _type_ids[i - 1] if i > 0 and i - 1 < _type_ids.size() else ""
		_refresh_grid())
	filters.add_child(_type_select)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filters.add_child(gap)
	var show_label: Label = CardView.make_label(16)
	show_label.text = TEXT_SHOW
	show_label.add_theme_font_override("font", UiStyle.font_bold())
	filters.add_child(show_label)
	var st_group := ButtonGroup.new()
	for i: int in STATUSES.size():
		var b: Button = _toggle("Status_" + STATUSES[i], STATUS_TEXTS[i], 100.0)
		b.button_group = st_group
		b.set_pressed_no_signal(i == 0)
		b.pressed.connect(set_status_filter.bind(STATUSES[i]))
		filters.add_child(b)
		_status_buttons.append(b)
	_list_info = CardView.make_label(14)
	_list_info.name = "ListInfo"
	_list_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_list_info.add_theme_color_override("font_color", UiStyle.TEXT_SUB)
	grid_col.add_child(_list_info)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_col.add_child(_scroll)
	_grid = PokedexGrid.new()
	_grid.entry_selected.connect(_on_grid_selected)
	_scroll.add_child(_grid)
	_empty_label = CardView.make_label(17)
	_empty_label.text = TEXT_EMPTY
	_empty_label.visible = false
	grid_col.add_child(_empty_label)
	var side := PanelContainer.new()
	side.name = "Side"
	side.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	side.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.FRAME_BLUE, 14.0, 10.0))
	body.add_child(side)
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(side_scroll)
	_side_box = VBoxContainer.new()
	_side_box.name = "SideBox"
	_side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_side_box.add_theme_constant_override("separation", 8)
	side_scroll.add_child(_side_box)
	_tooltip = KeywordTooltip.new()
	add_child(_tooltip)


func _toggle(node_name: String, text: String, width: float) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(width, 38)
	b.add_theme_font_override("font", UiStyle.font_bold())
	b.add_theme_font_size_override("font_size", 17)
	UiStyle.apply_button(b, UiStyle.ACCENT_BLUE)
	var pressed: StyleBox = UiStyle.button_box("normal", UiStyle.ACCENT_RED)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	return b
