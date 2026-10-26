class_name RunHud
extends PanelContainer
## Permanent run bar (top of the screen, HEIGHT px): Pokédollars, held items (chips, tooltip = description)
## the gym badges (story 012: one BadgeEmblem slot per zone, earned = type colour + tooltip, else a grey outline)
## and the potion belt (max_potions slots). Owned by Main and shown above every run screen (map, battle,
## reward, event, Centre, Mart, act end). Reads RunState / Battle only; a click on a usable potion emits
## potion_pressed and Main asks the battle to drink it. Implements: story-006-objets-et-services (criteria 2, 6).

## Emitted when a usable potion slot is clicked (index into the shown potion list).
signal potion_pressed(index: int)
## Emitted by the "Deck" button (story 011): Main opens / closes the single deck panel.
signal deck_pressed

const HEIGHT: float = 44.0
## Currency suffix. The default font has no "₽" glyph (it only renders through OS font fallback, absent on
## web / bare Linux), so the HUD uses the ASCII "P$". Change it here only.
const CURRENCY: String = "P$"
const COLOR_BAR: Color = UiStyle.BG_PANEL
const COLOR_BAR_BORDER: Color = UiStyle.OUTLINE
const COLOR_MONEY: Color = UiStyle.ACCENT_YELLOW
const COLOR_CAPTION: Color = UiStyle.TEXT_MUTED
const COLOR_CHIP_BG: Color = UiStyle.BG_PANEL_LIGHT
const COLOR_POTION: Color = UiStyle.BLOCK_BLUE
const COLOR_EMPTY: Color = Color(0.45, 0.46, 0.52)
const COLOR_FLASH: Color = Color(1.0, 0.85, 0.3)
const POTION_SLOT_SIZE: Vector2 = Vector2(112, 32)
## Story 012: side of a badge slot in the bar.
const BADGE_SLOT_SIDE: float = 22.0
const FLASH_DURATION: float = 0.7
const TEXT_DECK: String = "Deck"
const TEXT_DECK_TIP: String = "Voir ton deck (Échap pour fermer)."
const TEXT_DECK_BLOCKED: String = "Termine d'abord le choix de carte en cours."
const TEXT_BADGES: String = "Badges :"
const TEXT_ITEMS: String = "Objets :"
## Story 013: league progress next to the badges ("Conseil 4 :" + "1/6"), only during the league.
const TEXT_LEAGUE: String = "Conseil 4 :"
const TEXT_LEAGUE_VALUE: String = "%d/%d"
const TEXT_LEAGUE_TIP: String = "Combat %d/%d : %s — %s"
const COLOR_LEAGUE: Color = Color(1.0, 0.85, 0.3)
const TEXT_NO_ITEM: String = "aucun"
## Story 012: chip shown when the item chips do not all fit in the bar ("+3"; tooltip = the hidden items).
const TEXT_MORE_ITEMS: String = "+%d"
const TEXT_POTIONS: String = "Potions :"
const TEXT_EMPTY_SLOT: String = "— vide —"
const TEXT_POTION_HINT: String = "Clique pour l'utiliser (sans coût d'énergie)."
const TEXT_POTION_LATER: String = "Utilisable pendant ton tour, en combat."
## Story 017: Poké Balls carried ("Balls : 3" + one drawn icon per ball; tooltip = each kind and its count).
const TEXT_BALLS: String = "Balls :"
const TEXT_BALLS_TIP: String = "Poké Balls : %d/%d"
const TEXT_BALLS_LINE: String = "%s ×%d"
const TEXT_BALLS_NONE: String = "Aucune Ball. Achète-en au Poké Mart ou gagne-en en combat."
const TEXT_BALLS_HINT: String = "En combat sauvage : bouton « Capturer »."
const BALL_ICON_SIDE: float = 14.0

var _money: Label
var _items_box: HBoxContainer
var _items_scroll: ScrollContainer
var _more_chip: PanelContainer
var _badges_box: HBoxContainer
var _badges_caption: Label
var _league_caption: Label
var _league_value: Label
var _potions_box: HBoxContainer
var _chips: Dictionary = {}  # item id -> PanelContainer (display only)
var _deck_button: Button
## Story 017: balls indicator (caption + count + icons; the box carries the tooltip).
var _balls_box: HBoxContainer
var _balls_value: Label
var _balls_icons: HBoxContainer
## Story 017: ball id -> BallData (GameData.get_ball_book), set by Main; only used for the tooltip names.
var ball_book: Dictionary = {}


## Formats an amount of Pokédollars ("50 P$").
static func format_money(amount: int) -> String:
	return "%d %s" % [amount, CURRENCY]


func _init() -> void:
	name = "RunHud"
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, HEIGHT)
	offset_bottom = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BAR
	sb.border_width_bottom = 3
	sb.border_color = COLOR_BAR_BORDER
	sb.shadow_color = UiStyle.SHADOW
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	_money = CardView.make_label(22)
	_money.name = "Money"
	_money.custom_minimum_size = Vector2(96, 0)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_money.add_theme_color_override("font_color", COLOR_MONEY)
	_money.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_money.add_theme_constant_override("outline_size", 6)
	_money.mouse_filter = Control.MOUSE_FILTER_STOP
	_money.tooltip_text = "Pokédollars"
	row.add_child(_money)
	_badges_caption = _caption(TEXT_BADGES)
	row.add_child(_badges_caption)
	_badges_box = HBoxContainer.new()
	_badges_box.name = "Badges"
	_badges_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badges_box.add_theme_constant_override("separation", 3)
	row.add_child(_badges_box)
	_league_caption = _caption(TEXT_LEAGUE)
	_league_caption.name = "LeagueCaption"
	_league_caption.visible = false
	row.add_child(_league_caption)
	_league_value = CardView.make_label(18)
	_league_value.name = "LeagueProgress"
	_league_value.add_theme_color_override("font_color", COLOR_LEAGUE)
	_league_value.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_league_value.add_theme_constant_override("outline_size", 5)
	_league_value.mouse_filter = Control.MOUSE_FILTER_STOP
	_league_value.visible = false
	row.add_child(_league_value)
	row.add_child(_caption(TEXT_ITEMS))
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(scroll)
	_items_scroll = scroll
	scroll.resized.connect(_fit_items)
	_items_box = HBoxContainer.new()
	_items_box.name = "Items"
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_items_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_items_box)
	_balls_box = HBoxContainer.new()
	_balls_box.name = "Balls"
	_balls_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_balls_box.add_theme_constant_override("separation", 4)
	row.add_child(_balls_box)
	var balls_caption: Label = _caption(TEXT_BALLS)
	balls_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balls_box.add_child(balls_caption)
	_balls_value = CardView.make_label(18)
	_balls_value.name = "BallsValue"
	_balls_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balls_box.add_child(_balls_value)
	_balls_icons = HBoxContainer.new()
	_balls_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balls_icons.add_theme_constant_override("separation", 1)
	_balls_box.add_child(_balls_icons)
	row.add_child(_caption(TEXT_POTIONS))
	_potions_box = HBoxContainer.new()
	_potions_box.name = "Potions"
	_potions_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_potions_box.add_theme_constant_override("separation", 6)
	row.add_child(_potions_box)
	_deck_button = Button.new()
	_deck_button.name = "DeckButton"
	_deck_button.text = TEXT_DECK
	_deck_button.tooltip_text = TEXT_DECK_TIP
	_deck_button.custom_minimum_size = Vector2(90, 32)
	_deck_button.focus_mode = Control.FOCUS_NONE
	_deck_button.add_theme_font_size_override("font_size", 17)
	UiStyle.apply_button(_deck_button, UiStyle.ACCENT_BLUE)
	for state: String in ["normal", "hover", "pressed", "disabled"]:  # story 020: compact relief for the 44 px bar
		var dsb: StyleBoxFlat = _deck_button.get_theme_stylebox(state)
		dsb.content_margin_top = 1.0 if state != "pressed" else 3.0
		dsb.content_margin_bottom = 3.0 if state != "pressed" else 1.0
		dsb.border_width_bottom = 4 if state != "pressed" else 2
	_deck_button.pressed.connect(press_deck)
	row.add_child(_deck_button)


## Redraws the bar from `run` (read only). In a battle pass it: its potion list is shown and the slots the
## battle allows (Battle.can_use_potion) become clickable; elsewhere the potions are display-only.
func refresh(run: RunState, battle: Battle = null) -> void:
	if run == null:
		return
	_money.text = format_money(run.money)
	BadgeEmblem.fill_row(_badges_box, run, BADGE_SLOT_SIDE)
	_badges_caption.visible = _badges_box.visible
	var in_league: bool = run.is_in_league()
	_league_caption.visible = in_league
	_league_value.visible = in_league
	if in_league:
		var fight: Dictionary = run.current_league_fight()
		_league_value.text = TEXT_LEAGUE_VALUE % [run.league_stage + 1, run.league.size()]
		_league_value.tooltip_text = TEXT_LEAGUE_TIP % [run.league_stage + 1, run.league.size(), String(fight["name"]),
				String(fight["title"])]
	for child: Node in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	_chips.clear()
	if run.items.is_empty():
		var none: Label = _caption(TEXT_NO_ITEM)
		none.add_theme_color_override("font_color", COLOR_EMPTY)
		_items_box.add_child(none)
	for item: ItemData in run.items:
		var chip: PanelContainer = _make_chip(item.display_name, "%s\n%s" % [item.display_name, item.description],
				CardView.rarity_color(item.rarity))
		_chips[item.id] = chip
		_items_box.add_child(chip)
	for child: Node in _potions_box.get_children():
		_potions_box.remove_child(child)
		child.queue_free()
	_more_chip = null
	if not run.items.is_empty():
		_more_chip = _make_chip(TEXT_MORE_ITEMS % 0, "", COLOR_CAPTION)
		_more_chip.name = "MoreItems"
		_more_chip.visible = false
		_items_box.add_child(_more_chip)
	_fit_items()
	var potions: Array[PotionData] = battle.potions if battle != null else run.potions
	for i: int in maxi(run.max_potions(), potions.size()):
		_potions_box.add_child(_make_potion_slot(potions, i, battle))
	_refresh_balls(run)


## Story 017: "Balls : N", one icon per ball carried (kind colours), tooltip = "Poké Ball ×2" lines.
func _refresh_balls(run: RunState) -> void:
	for child: Node in _balls_icons.get_children():
		_balls_icons.remove_child(child)
		child.queue_free()
	var total: int = run.ball_total()
	_balls_value.text = str(total)
	_balls_value.add_theme_color_override("font_color", COLOR_POTION if total > 0 else COLOR_EMPTY)
	var lines: PackedStringArray = PackedStringArray([TEXT_BALLS_TIP % [total, run.max_balls()]])
	for bid: String in run.balls.keys():
		var n: int = run.ball_count(bid)
		var def: BallData = ball_book.get(bid, null)
		lines.append(TEXT_BALLS_LINE % [def.display_name if def != null else bid, n])
		for k: int in n:
			_balls_icons.add_child(BallIcon.make(bid, BALL_ICON_SIDE))
	lines.append(TEXT_BALLS_HINT if total > 0 else TEXT_BALLS_NONE)
	_balls_box.tooltip_text = "\n".join(lines)


## Story 017: balls indicator text ("Balls : 3") and tooltip, for the QA harness.
func get_balls_text() -> String:
	return "%s %s" % [TEXT_BALLS, _balls_value.text]


## Story 017: tooltip of the balls indicator, for the QA harness.
func get_balls_tooltip() -> String:
	return _balls_box.tooltip_text


## Briefly highlights the chip of `item` (an item effect just fired). Display only.
func flash_item(item: ItemData) -> void:
	var chip: PanelContainer = _chips.get(item.id, null)
	if chip == null or not is_instance_valid(chip):
		return
	chip.self_modulate = COLOR_FLASH * 1.6
	var t: Tween = chip.create_tween()
	t.tween_property(chip, "self_modulate", Color.WHITE, FLASH_DURATION)


## Presses the Deck button (same path as the mouse). Ignored while it is disabled.
func press_deck() -> void:
	if not _deck_button.disabled:
		deck_pressed.emit()


## Enables / disables the Deck button. Main disables it while a modal card picker (Centre upgrade, Mart removal)
## is open, so the deck panel never stacks on top of a picker.
func set_deck_enabled(enabled: bool) -> void:
	_deck_button.disabled = not enabled
	_deck_button.tooltip_text = TEXT_DECK_TIP if enabled else TEXT_DECK_BLOCKED


## True if the Deck button is clickable now.
func is_deck_enabled() -> bool:
	return not _deck_button.disabled


## Clicks potion slot `index` (same path as the mouse). Ignored for disabled / empty slots.
func press_potion(index: int) -> void:
	var slot: Button = _potion_button(index)
	if slot != null and not slot.disabled:
		potion_pressed.emit(index)


## Displayed money text ("50 P$"), for the QA harness.
func get_money_text() -> String:
	return _money.text


## Names on the item chips, for the QA harness.
func get_item_names() -> Array[String]:
	var names: Array[String] = []
	for id: String in _chips:
		names.append(((_chips[id] as PanelContainer).get_child(0) as Label).text)
	return names


## Story 013: league progress shown in the bar ("Conseil 4 : 1/6"), "" outside the league.
func get_league_text() -> String:
	return "%s %s" % [_league_caption.text, _league_value.text] if _league_value.visible else ""


## Badge slots, for the QA harness: [{earned: bool, tooltip: String}] in zone order.
func get_badge_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for child: Node in _badges_box.get_children():
		if child.is_queued_for_deletion():
			continue
		var e: BadgeEmblem = child as BadgeEmblem
		slots.append({"earned": e.is_earned(), "tooltip": e.tooltip_text})
	return slots


## Text of each potion slot ("— vide —" for empty ones), for the QA harness.
func get_potion_texts() -> Array[String]:
	var texts: Array[String] = []
	for child: Node in _potions_box.get_children():
		texts.append((child as Button).text)
	return texts


## True if potion slot `index` is clickable now.
func is_potion_usable(index: int) -> bool:
	var slot: Button = _potion_button(index)
	return slot != null and not slot.disabled


## Story 012: keeps the item chips that fit in the bar's item area (in order) and folds the others into a "+N" chip
## whose tooltip lists them (every item stays reachable by tooltip).
func _fit_items() -> void:
	if _more_chip == null or not is_instance_valid(_more_chip) or _items_scroll == null:
		return
	var avail: float = _items_scroll.size.x
	if avail <= 0.0:
		return
	var sep: float = float(_items_box.get_theme_constant("separation"))
	var chips: Array[PanelContainer] = []
	for id: String in _chips:
		chips.append(_chips[id])
	var total: float = 0.0
	for chip: PanelContainer in chips:
		total += chip.get_combined_minimum_size().x + sep
	var all_fit: bool = total - sep <= avail
	var more_w: float = _more_chip.get_combined_minimum_size().x + sep + 12.0  # room for a two-digit count
	var used: float = 0.0
	var hidden: Array[String] = []
	for chip: PanelContainer in chips:
		var w: float = chip.get_combined_minimum_size().x + sep
		var fits: bool = all_fit or (hidden.is_empty() and used + w + more_w <= avail)
		chip.visible = fits
		if fits:
			used += w
		else:
			hidden.append(chip.tooltip_text)
	_more_chip.visible = not hidden.is_empty()
	((_more_chip.get_child(0)) as Label).text = TEXT_MORE_ITEMS % hidden.size()
	_more_chip.tooltip_text = "\n\n".join(hidden)


## Item chips actually shown in the bar, plus the "+N" overflow text if any, for the QA harness.
func get_visible_item_texts() -> Array[String]:
	var texts: Array[String] = []
	for child: Node in _items_box.get_children():
		if child is PanelContainer and (child as Control).visible:
			texts.append(((child as PanelContainer).get_child(0) as Label).text)
	return texts


func _potion_button(index: int) -> Button:
	if index < 0 or index >= _potions_box.get_child_count():
		return null
	return _potions_box.get_child(index) as Button


func _caption(text: String) -> Label:
	var l: Label = CardView.make_label(15)
	l.text = text
	l.add_theme_color_override("font_color", COLOR_CAPTION)
	return l


func _make_chip(text: String, tooltip: String, border: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.tooltip_text = tooltip
	var sb: StyleBoxFlat = UiStyle.badge(border.darkened(0.55).lerp(COLOR_CHIP_BG, 0.35))  # story 020: rarity tint
	sb.border_width_bottom = 3
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", sb)
	var l: Label = CardView.make_label(15)
	l.text = text
	l.add_theme_color_override("font_color", border.lerp(Color.WHITE, 0.55))
	chip.add_child(l)
	return chip


func _make_potion_slot(potions: Array[PotionData], index: int, battle: Battle) -> Button:
	var b := Button.new()
	b.name = "Potion%d" % index
	b.custom_minimum_size = POTION_SLOT_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.clip_text = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CHIP_BG
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(UiStyle.BADGE_RADIUS)
	sb.anti_aliasing = true
	b.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	if index >= potions.size():
		b.text = TEXT_EMPTY_SLOT
		b.disabled = true
		sb.bg_color = UiStyle.BG_DEEP
		sb.border_color = UiStyle.OUTLINE
		b.add_theme_color_override("font_disabled_color", COLOR_EMPTY)
	else:
		var p: PotionData = potions[index]
		b.text = p.display_name
		var usable: bool = battle != null and battle.can_use_potion(index)
		b.disabled = not usable
		b.tooltip_text = "%s\n%s\n%s" % [p.display_name, p.description, TEXT_POTION_HINT if usable else TEXT_POTION_LATER]
		sb.border_color = UiStyle.OUTLINE
		if usable:
			sb.bg_color = UiStyle.ACCENT_BLUE
			b.add_theme_constant_override("outline_size", 4)
		b.add_theme_color_override("font_color", UiStyle.TEXT)
		b.add_theme_color_override("font_disabled_color", COLOR_POTION.darkened(0.15))
		b.pressed.connect(press_potion.bind(index))
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = COLOR_CHIP_BG.lightened(0.15)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", sb)
	return b
