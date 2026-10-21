class_name RewardScreen
extends Control
## Post-victory reward screen (mouse only, built from containers, fits 1280x720).
## Shows the offered cards (stolen one marked), "Passer", and a scrollable deck overlay.
## Holds no game state: it emits card_chosen / skipped and Main applies the result.
## Implements: story-004-recompenses-vol-attaque (criteria 1, 2, 3, 5).
## Story 006: a "Butin" row shows what the fight paid (Pokédollars, held item, potion), see set_loot.

## Emitted when the player picks an offered card.
signal card_chosen(card: CardData)
## Emitted when the player passes.
signal skipped
## Emitted by "Voir le deck" (Main opens the single deck panel).
signal deck_requested

const CARD_SIZE: Vector2 = Vector2(220, 270)
const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_STOLEN: Color = Color(1.0, 0.6, 0.2)
const COLOR_ATTACK_BG: Color = Color(0.18, 0.18, 0.24)
const COLOR_LOOT_BG: Color = Color(0.16, 0.17, 0.23)
const COLOR_LOOT_CAPTION: Color = Color(0.7, 0.72, 0.82)
const COLOR_POTION: Color = Color(0.55, 0.82, 1.0)
const TEXT_LOOT: String = "Butin :"

var _data: GameData
var _run: RunState
var _offers: Array[RewardOffer] = []
var _title: Label
var _info: Label
var _cards_box: HBoxContainer
var _loot_box: HBoxContainer
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


## Shows the loot of the fight (Main.get_last_loot(): {"money": int, "item": ItemData|null, "potion":
## PotionData|null}, already applied to the run). Empty dict = no loot row (debug fights).
func set_loot(loot: Dictionary) -> void:
	_build_ui()
	for child: Node in _loot_box.get_children():
		_loot_box.remove_child(child)
		child.queue_free()
	_loot_box.visible = not loot.is_empty()
	if loot.is_empty():
		return
	var caption: Label = CardView.make_label(22)
	caption.text = TEXT_LOOT
	caption.add_theme_color_override("font_color", COLOR_LOOT_CAPTION)
	_loot_box.add_child(caption)
	_loot_box.add_child(_loot_chip("+" + RunHud.format_money(int(loot.get("money", 0))), "Pokédollars",
			RunHud.COLOR_MONEY))
	var item: ItemData = loot.get("item", null)
	if item != null:
		_loot_box.add_child(_loot_chip("Objet : " + item.display_name, item.description, CardView.rarity_color(item.rarity)))
	var potion: PotionData = loot.get("potion", null)
	if potion != null:
		_loot_box.add_child(_loot_chip("Potion : " + potion.display_name, potion.description, COLOR_POTION))


## Texts of the loot chips ("+15 P$", "Objet : Restes", ...), for the QA harness.
func get_loot_texts() -> Array[String]:
	var texts: Array[String] = []
	for child: Node in _loot_box.get_children():
		if child is PanelContainer:
			texts.append(((child as PanelContainer).get_child(0).get_child(0) as Label).text)
	return texts


## The offers currently displayed.
func get_offers() -> Array[RewardOffer]:
	return _offers


## Picks offer `index` (same path as the mouse click).
func pick(index: int) -> void:
	if _done or index < 0 or index >= _offers.size():
		return
	_done = true
	card_chosen.emit(_offers[index].card)


## Passes without taking a card (same path as the "Passer" button).
func skip() -> void:
	if _done:
		return
	_done = true
	skipped.emit()


## "Voir le deck": asks Main to open the single deck panel (story 011).
func open_deck() -> void:
	deck_requested.emit()


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
	_loot_box = HBoxContainer.new()
	_loot_box.name = "Loot"
	_loot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_loot_box.add_theme_constant_override("separation", 14)
	_loot_box.visible = false
	root.add_child(_loot_box)
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
	CardView.fill_card_content(b, card, _data.get_type_chart(), _data.get_pokemon_info)  # stolen card shows the defeated Pokémon
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


## One loot chip: bold text + smaller description, coloured border, tooltip = description.
func _loot_chip(text: String, description: String, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.tooltip_text = description
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_LOOT_BG
	sb.set_border_width_all(2)
	sb.border_color = accent
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(box)
	var l: Label = CardView.make_label(20)
	l.text = text
	l.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.25))
	box.add_child(l)
	if description != "Pokédollars":
		var d: Label = CardView.make_label(14)
		d.text = description
		d.add_theme_color_override("font_color", COLOR_LOOT_CAPTION)
		box.add_child(d)
	return chip
