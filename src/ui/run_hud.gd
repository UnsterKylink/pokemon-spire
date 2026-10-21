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
const COLOR_BAR: Color = Color(0.08, 0.09, 0.12)
const COLOR_BAR_BORDER: Color = Color(0.32, 0.34, 0.44)
const COLOR_MONEY: Color = Color(1.0, 0.84, 0.3)
const COLOR_CAPTION: Color = Color(0.62, 0.64, 0.74)
const COLOR_CHIP_BG: Color = Color(0.16, 0.17, 0.23)
const COLOR_POTION: Color = Color(0.55, 0.82, 1.0)
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
const TEXT_NO_ITEM: String = "aucun"
const TEXT_POTIONS: String = "Potions :"
const TEXT_EMPTY_SLOT: String = "— vide —"
const TEXT_POTION_HINT: String = "Clique pour l'utiliser (sans coût d'énergie)."
const TEXT_POTION_LATER: String = "Utilisable pendant ton tour, en combat."

var _money: Label
var _items_box: HBoxContainer
var _badges_box: HBoxContainer
var _badges_caption: Label
var _potions_box: HBoxContainer
var _chips: Dictionary = {}  # item id -> PanelContainer (display only)
var _deck_button: Button


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
	sb.border_width_bottom = 2
	sb.border_color = COLOR_BAR_BORDER
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
	row.add_child(_caption(TEXT_ITEMS))
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(scroll)
	_items_box = HBoxContainer.new()
	_items_box.name = "Items"
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_items_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_items_box)
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
	var potions: Array[PotionData] = battle.potions if battle != null else run.potions
	for i: int in maxi(run.max_potions(), potions.size()):
		_potions_box.add_child(_make_potion_slot(potions, i, battle))


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
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CHIP_BG
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	var l: Label = CardView.make_label(15)
	l.text = text
	l.add_theme_color_override("font_color", border.lerp(Color.WHITE, 0.35))
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
	sb.set_corner_radius_all(8)
	if index >= potions.size():
		b.text = TEXT_EMPTY_SLOT
		b.disabled = true
		sb.border_color = COLOR_EMPTY.darkened(0.3)
		b.add_theme_color_override("font_disabled_color", COLOR_EMPTY)
	else:
		var p: PotionData = potions[index]
		b.text = p.display_name
		var usable: bool = battle != null and battle.can_use_potion(index)
		b.disabled = not usable
		b.tooltip_text = "%s\n%s\n%s" % [p.display_name, p.description, TEXT_POTION_HINT if usable else TEXT_POTION_LATER]
		sb.border_color = COLOR_POTION if usable else COLOR_POTION.darkened(0.35)
		b.add_theme_color_override("font_color", COLOR_POTION)
		b.add_theme_color_override("font_disabled_color", COLOR_POTION.darkened(0.15))
		b.pressed.connect(press_potion.bind(index))
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = COLOR_CHIP_BG.lightened(0.15)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", sb)
	return b
