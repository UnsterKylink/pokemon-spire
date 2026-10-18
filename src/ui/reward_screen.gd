class_name RewardScreen
extends Control
## Post-victory reward screen (mouse only, built from containers, fits 1280x720).
## Shows the offered cards (stolen one marked), "Passer", and a scrollable deck overlay.
## Holds no game state: it emits card_chosen / skipped and Main applies the result.
## Implements: story-004-recompenses-vol-attaque (criteria 1, 2, 3, 5).

## Emitted when the player picks an offered card.
signal card_chosen(card: CardData)
## Emitted when the player passes.
signal skipped

const CARD_SIZE: Vector2 = Vector2(220, 270)
const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_STOLEN: Color = Color(1.0, 0.6, 0.2)
const COLOR_ATTACK_BG: Color = Color(0.18, 0.18, 0.24)

var _data: GameData
var _run: RunState
var _offers: Array[RewardOffer] = []
var _title: Label
var _info: Label
var _cards_box: HBoxContainer
var _deck_overlay: Control
var _deck_list: VBoxContainer
var _deck_title: Label
var _done: bool = false
var _built: bool = false


func _ready() -> void:
	_build_ui()


## Fills the screen. `run` is only read (HP, deck) to display it.
func setup(data: GameData, run: RunState, offers: Array[RewardOffer]) -> void:
	_build_ui()
	_data = data
	_run = run
	_offers = offers
	_done = false
	_title.text = "Victoire ! Choisis une carte"
	_info.text = "PV %d/%d   |   Deck : %d cartes" % [run.hp, run.max_hp, run.deck.size()]
	for child: Node in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	for i: int in offers.size():
		_cards_box.add_child(_make_offer_widget(offers[i], i))
	close_deck()


## The offers currently displayed.
func get_offers() -> Array[RewardOffer]:
	return _offers


## Picks offer `index` (same path as the mouse click). Ignored while the deck overlay is open.
func pick(index: int) -> void:
	if _done or is_deck_open() or index < 0 or index >= _offers.size():
		return
	_done = true
	card_chosen.emit(_offers[index].card)


## Passes without taking a card (same path as the "Passer" button).
func skip() -> void:
	if _done or is_deck_open():
		return
	_done = true
	skipped.emit()


## Opens the deck overlay ("Voir le deck").
func open_deck() -> void:
	for child: Node in _deck_list.get_children():
		_deck_list.remove_child(child)
		child.queue_free()
	_deck_title.text = "Ton deck (%d cartes)" % _run.deck.size()
	for entry: Dictionary in _run.get_deck_entries():
		var card: CardData = entry["card"]
		var l: Label = CardView.make_label(22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text = "%s ×%d  (coût %d) : %s" % [card.display_name, int(entry["count"]), card.cost, card.description]
		l.add_theme_color_override("font_color", CardView.rarity_color(card.rarity))
		_deck_list.add_child(l)
	_deck_overlay.visible = true


## Closes the deck overlay ("Fermer").
func close_deck() -> void:
	_deck_overlay.visible = false


## True while the deck overlay is shown.
func is_deck_open() -> bool:
	return _deck_overlay.visible


## Lines of the deck overlay ("Griffe ×5 ..."), for the QA harness.
func get_deck_lines() -> Array[String]:
	var lines: Array[String] = []
	for child: Node in _deck_list.get_children():
		lines.append((child as Label).text)
	return lines


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
	_title = CardView.make_label(44)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	root.add_child(_title)
	_info = CardView.make_label(22)
	root.add_child(_info)
	_cards_box = HBoxContainer.new()
	_cards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_box.add_theme_constant_override("separation", 28)
	root.add_child(_cards_box)
	var buttons := HBoxContainer.new()
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	root.add_child(buttons)
	var skip_button := Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Passer"
	skip_button.custom_minimum_size = Vector2(200, 52)
	skip_button.pressed.connect(skip)
	buttons.add_child(skip_button)
	var deck_button := Button.new()
	deck_button.name = "DeckButton"
	deck_button.text = "Voir le deck"
	deck_button.custom_minimum_size = Vector2(200, 52)
	deck_button.pressed.connect(open_deck)
	buttons.add_child(deck_button)
	_build_deck_overlay()


func _build_deck_overlay() -> void:
	_deck_overlay = Control.new()
	_deck_overlay.name = "DeckOverlay"
	_deck_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deck_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_overlay.visible = false
	add_child(_deck_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_deck_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 560)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.14, 0.19)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.45, 0.47, 0.58)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_deck_title = CardView.make_label(30)
	box.add_child(_deck_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_deck_list = VBoxContainer.new()
	_deck_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_deck_list)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(200, 48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close_deck)
	box.add_child(close_button)


## One offer: ribbon (stolen) / card button / rarity label.
func _make_offer_widget(offer: RewardOffer, index: int) -> Control:
	var card: CardData = offer.card
	var col := VBoxContainer.new()
	col.name = "Offer%d" % index
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	var ribbon: Label = CardView.make_label(18)
	ribbon.name = "Ribbon"
	ribbon.custom_minimum_size = Vector2(CARD_SIZE.x, 30)
	if offer.stolen:
		ribbon.text = "Attaque volée à %s" % offer.source_pokemon_name
		ribbon.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = COLOR_STOLEN
		rsb.set_corner_radius_all(6)
		ribbon.add_theme_stylebox_override("normal", rsb)
	col.add_child(ribbon)
	var b := Button.new()
	b.name = "Card"
	b.custom_minimum_size = CARD_SIZE
	CardView.fill_card_content(b, card, _data.get_type_chart())
	var border: Color = COLOR_STOLEN if offer.stolen else CardView.rarity_color(card.rarity)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_ATTACK_BG
	sb.set_border_width_all(5)
	sb.border_color = border
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
	rarity.text = CardView.rarity_name(card.rarity)
	rarity.add_theme_color_override("font_color", CardView.rarity_color(card.rarity))
	col.add_child(rarity)
	return col
