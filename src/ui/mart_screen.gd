class_name MartScreen
extends Control
## Poké Mart room (mouse, built in code, fits the 1280x(720 - RunHud.HEIGHT) area): cards (CardView), held
## items and potions with their prices; sold-out slots stay visible ("Vendu"), unaffordable / impossible ones
## are disabled with the reason as tooltip. "Retirer une carte (prix)" opens the deck picker; "Quitter" goes back
## to the map. Holds no game state: it reads the visit's ShopInventory and emits buy_requested / remove_requested,
## Main applies them and calls refresh. Implements: story-006-objets-et-services (criterion 5).

## The player clicked an article: kind = ShopEntry.KIND_CARD / KIND_ITEM / KIND_POTION / KIND_BALL (story 017), index in that list.
signal buy_requested(kind: String, index: int)
## The player picked deck[deck_index] in the removal picker.
signal remove_requested(deck_index: int)
## "Quitter".
signal finished

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_ACCENT: Color = Color(0.36, 0.6, 1.0)
const COLOR_TILE_BG: Color = Color(0.17, 0.18, 0.24)
const COLOR_PRICE: Color = Color(1.0, 0.84, 0.3)
const COLOR_TOO_EXPENSIVE: Color = Color(1.0, 0.42, 0.38)
const COLOR_SOLD: Color = Color(0.55, 0.56, 0.62)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const COLOR_STATUS: Color = Color(0.55, 1.0, 0.6)
const COLOR_POTION: Color = Color(0.55, 0.82, 1.0)
const CARD_SIZE: Vector2 = Vector2(170, 200)
const TILE_SIZE: Vector2 = Vector2(224, 118)
## Story 017: the Poké Balls row (lower tiles so the row fits above the buttons).
const BALL_TILE_SIZE: Vector2 = Vector2(600, 92)
const TEXT_BALLS: String = "Poké Balls"
const TEXT_BAG_FULL: String = "Sac de Balls plein (%d/%d)."
const TEXT_TITLE: String = "Poké Mart"
const TEXT_SOLD: String = "Vendu"
const TEXT_NO_MONEY: String = "Pas assez de Pokédollars."
const TEXT_OWNED: String = "Déjà possédé."
const TEXT_BELT_FULL: String = "Ceinture de potions pleine (%d/%d)."
const TEXT_REMOVE: String = "Retirer une carte (%s)"
const TEXT_REMOVE_TITLE: String = "Retirer une carte — %s"
const TEXT_REMOVE_HINT: String = "Choisis la carte à retirer définitivement de ton deck."
const TEXT_WELCOME: String = "Bienvenue ! Clique sur un article pour l'acheter."

var _data: GameData
var _run: RunState
var _shop: ShopInventory
var _info: Label
var _status: Label
var _cards_box: HBoxContainer
var _items_box: HBoxContainer
var _potions_box: HBoxContainer
var _balls_box: HBoxContainer
var _balls_col: VBoxContainer
var _remove_button: Button
var _picker: DeckPicker
var _done: bool = false
var _built: bool = false


func _init() -> void:
	name = "MartScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the screen with the visit's stock. `run` and `shop` are only read.
func setup(data: GameData, run: RunState, shop: ShopInventory) -> void:
	_build_ui()
	_data = data
	_run = run
	_shop = shop
	_done = false
	_picker.close()
	refresh(TEXT_WELCOME)


## Redraws every article / button from the inventory and the run; `status` = feedback line ("" keeps it).
func refresh(status: String = "") -> void:
	if not status.is_empty():
		_status.text = status
	_info.text = "PV %d/%d   |   Deck : %d cartes   |   Potions %d/%d   |   Balls %d/%d" % [_run.hp, _run.max_hp,
			_run.deck.size(), _run.potions.size(), _run.max_potions(), _run.ball_total(), _run.max_balls()]
	_clear(_cards_box)
	for i: int in _shop.cards.size():
		_cards_box.add_child(_make_card_slot(i))
	_clear(_items_box)
	for i: int in _shop.items.size():
		var e: ShopEntry = _shop.items[i]
		var reason: String = TEXT_OWNED if not e.sold and _run.has_item(e.item.id) else ""
		_items_box.add_child(_make_tile(e, i, _shop.can_buy_item(i), reason, CardView.rarity_color(e.item.rarity)))
	_clear(_potions_box)
	for i: int in _shop.potions.size():
		var e: ShopEntry = _shop.potions[i]
		var full: bool = _run.potions.size() >= _run.max_potions()
		var reason: String = TEXT_BELT_FULL % [_run.potions.size(), _run.max_potions()] if not e.sold and full else ""
		_potions_box.add_child(_make_tile(e, i, _shop.can_buy_potion(i), reason, COLOR_POTION))
	_clear(_balls_box)
	_balls_col.visible = not _shop.balls.is_empty()
	for i: int in _shop.balls.size():
		var e: ShopEntry = _shop.balls[i]
		var bag_full: bool = _run.ball_total() >= _run.max_balls()
		var reason: String = TEXT_BAG_FULL % [_run.ball_total(), _run.max_balls()] if not e.sold and bag_full else ""
		var tile: Button = _make_tile(e, i, _shop.can_buy_ball(i), reason, BallIcon.color_of(e.ball.id).lightened(0.3))
		tile.custom_minimum_size = BALL_TILE_SIZE
		var icon: BallIcon = BallIcon.make(e.ball.id, 22)
		icon.position = Vector2(10, 9)
		icon.size = Vector2(22, 22)
		icon.modulate = Color(1, 1, 1, 0.45) if tile.disabled else Color.WHITE
		tile.add_child(icon)
		_balls_box.add_child(tile)
	var price: String = RunHud.format_money(_shop.removal_price())
	_remove_button.text = TEXT_REMOVE % price
	_remove_button.disabled = not _shop.can_remove_card(0)
	_remove_button.tooltip_text = TEXT_REMOVE_HINT if not _remove_button.disabled else TEXT_NO_MONEY


## Clicks card article `index` (same path as the mouse). Ignored if it cannot be bought.
func buy_card(index: int) -> void:
	if not _done and not _picker.is_open() and _shop.can_buy_card(index):
		buy_requested.emit(ShopEntry.KIND_CARD, index)


## Clicks held-item article `index`.
func buy_item(index: int) -> void:
	if not _done and not _picker.is_open() and _shop.can_buy_item(index):
		buy_requested.emit(ShopEntry.KIND_ITEM, index)


## Clicks potion article `index`.
func buy_potion(index: int) -> void:
	if not _done and not _picker.is_open() and _shop.can_buy_potion(index):
		buy_requested.emit(ShopEntry.KIND_POTION, index)


## Story 017: clicks ball article `index` (refused when sold, unaffordable or the bag is full).
func buy_ball(index: int) -> void:
	if not _done and not _picker.is_open() and _shop.can_buy_ball(index):
		buy_requested.emit(ShopEntry.KIND_BALL, index)


## "Retirer une carte": opens the deck picker (if the removal is affordable).
func open_remove() -> void:
	if _done or _remove_button.disabled:
		return
	_picker.open(TEXT_REMOVE_TITLE % RunHud.format_money(_shop.removal_price()), TEXT_REMOVE_HINT, _run, _data,
			_shop.can_remove_card, "", "Annuler")


## Picks deck[deck_index] in the removal picker (same path as a click): closes it and asks Main to remove it.
func remove(deck_index: int) -> void:
	if _done or not _picker.is_open() or not _shop.can_remove_card(deck_index):
		return
	_picker.close()
	remove_requested.emit(deck_index)


## Closes the removal picker without removing anything.
func cancel_remove() -> void:
	_picker.close()


## "Quitter" (back to the map).
func leave() -> void:
	if _done:
		return
	_done = true
	_picker.close()
	finished.emit()


## The removal picker (QA harness).
func get_picker() -> DeckPicker:
	return _picker


## The feedback line.
func get_status_text() -> String:
	return _status.text


func _clear(box: Container) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _price_label(e: ShopEntry, can_buy: bool) -> Label:
	var l: Label = CardView.make_label(18)
	l.name = "Price"
	if e.sold:
		l.text = TEXT_SOLD
		l.add_theme_color_override("font_color", COLOR_SOLD)
	else:
		l.text = RunHud.format_money(e.price)
		l.add_theme_color_override("font_color", COLOR_PRICE if _run.money >= e.price else COLOR_TOO_EXPENSIVE)
	if not can_buy and not e.sold and _run.money >= e.price:
		l.add_theme_color_override("font_color", COLOR_SOLD)
	return l


func _make_card_slot(index: int) -> Control:
	var e: ShopEntry = _shop.cards[index]
	var can_buy: bool = _shop.can_buy_card(index)
	var col := VBoxContainer.new()
	col.name = "CardSlot%d" % index
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	var b := Button.new()
	b.name = "Card"
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	CardView.fill_card_content(b, e.card, _data.get_type_chart(), _data.get_pokemon_info)
	b.disabled = not can_buy
	b.tooltip_text = "%s — %s" % [CardView.rarity_name(e.card.rarity), e.get_description()]
	if not e.sold and _run.money < e.price:
		b.tooltip_text += "\n" + TEXT_NO_MONEY
	_style_button(b, CardView.rarity_color(e.card.rarity), e.sold)
	(b.get_node("Content") as Control).modulate = Color(1, 1, 1, 0.4) if b.disabled else Color.WHITE
	b.pressed.connect(buy_card.bind(index))
	col.add_child(b)
	col.add_child(_price_label(e, can_buy))
	return col


func _make_tile(e: ShopEntry, index: int, can_buy: bool, reason: String, accent: Color) -> Button:
	var b := Button.new()
	b.name = "%s%d" % [e.kind.capitalize(), index]
	b.custom_minimum_size = TILE_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not can_buy
	var tip: String = "%s\n%s" % [e.get_name(), e.get_description()]
	if not reason.is_empty():
		tip += "\n" + reason
	elif not e.sold and _run.money < e.price:
		tip += "\n" + TEXT_NO_MONEY
	b.tooltip_text = tip
	_style_button(b, accent, e.sold)
	var margin := MarginContainer.new()
	margin.name = "Content"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8 if side == "left" or side == "right" else 5)
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)
	var n: Label = CardView.make_label(18)
	n.text = e.get_name()
	n.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.3))
	box.add_child(n)
	var d: Label = CardView.make_label(13)  # story 020: 3-line descriptions fit the 118 px tile
	d.text = e.get_description()
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(d)
	var price: Label = _price_label(e, can_buy)
	if not reason.is_empty() and not e.sold:
		price.text = "%s · %s" % [price.text, TEXT_OWNED.trim_suffix(".") if reason == TEXT_OWNED else ("Sac plein" if e.kind == ShopEntry.KIND_BALL else "Pleine")]
	box.add_child(price)
	margin.modulate = Color(1, 1, 1, 0.45) if b.disabled else Color.WHITE
	if e.kind == ShopEntry.KIND_ITEM:
		b.pressed.connect(buy_item.bind(index))
	elif e.kind == ShopEntry.KIND_BALL:
		b.pressed.connect(buy_ball.bind(index))
	else:
		b.pressed.connect(buy_potion.bind(index))
	return b


func _style_button(b: Button, border: Color, sold: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_TILE_BG
	sb.set_border_width_all(3)
	sb.border_color = border
	sb.set_corner_radius_all(8)
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = COLOR_TILE_BG.lightened(0.15)
	hover.border_color = Color(1.0, 0.85, 0.3)
	var dis: StyleBoxFlat = sb.duplicate()
	dis.bg_color = Color(0.12, 0.12, 0.15)
	dis.border_color = border.darkened(0.6) if sold else border.darkened(0.4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", dis)


func _caption(text: String) -> Label:
	var l: Label = CardView.make_label(18)
	l.text = text
	l.add_theme_color_override("font_color", COLOR_CAPTION)
	return l


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
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	var title: Label = CardView.make_label(34)
	title.text = TEXT_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	header.add_child(title)
	_status = CardView.make_label(18)
	_status.name = "Status"
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.add_theme_color_override("font_color", COLOR_STATUS)
	header.add_child(_status)
	_info = CardView.make_label(18)
	header.add_child(_info)
	root.add_child(_caption("Cartes"))
	_cards_box = HBoxContainer.new()
	_cards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", 18)
	root.add_child(_cards_box)
	var goods := HBoxContainer.new()
	goods.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goods.alignment = BoxContainer.ALIGNMENT_CENTER
	goods.add_theme_constant_override("separation", 36)
	root.add_child(goods)
	var items_col := VBoxContainer.new()
	items_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_col.add_child(_caption("Objets tenus"))
	_items_box = HBoxContainer.new()
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.add_theme_constant_override("separation", 10)
	items_col.add_child(_items_box)
	goods.add_child(items_col)
	var potions_col := VBoxContainer.new()
	potions_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	potions_col.add_child(_caption("Potions"))
	_potions_box = HBoxContainer.new()
	_potions_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_potions_box.add_theme_constant_override("separation", 10)
	potions_col.add_child(_potions_box)
	goods.add_child(potions_col)
	_balls_col = VBoxContainer.new()
	_balls_col.name = "BallsRow"
	_balls_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balls_col.add_child(_caption(TEXT_BALLS))
	_balls_box = HBoxContainer.new()
	_balls_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balls_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_balls_box.add_theme_constant_override("separation", 10)
	_balls_col.add_child(_balls_box)
	root.add_child(_balls_col)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	root.add_child(buttons)
	_remove_button = Button.new()
	_remove_button.name = "RemoveButton"
	_remove_button.custom_minimum_size = Vector2(320, 50)
	_remove_button.focus_mode = Control.FOCUS_NONE
	_remove_button.pressed.connect(open_remove)
	buttons.add_child(_remove_button)
	var leave_button := Button.new()
	leave_button.name = "LeaveButton"
	leave_button.text = "Quitter"
	leave_button.custom_minimum_size = Vector2(220, 50)
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.pressed.connect(leave)
	buttons.add_child(leave_button)
	_picker = DeckPicker.new()
	_picker.card_picked.connect(remove)
	_picker.cancelled.connect(cancel_remove)
	add_child(_picker)
