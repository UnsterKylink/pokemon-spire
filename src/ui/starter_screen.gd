class_name StarterScreen
extends Control
## Start-of-run screen: the player picks one of the proposed starter Pokémon (mouse only, containers,
## fits 1280x720). Holds no game state: it emits starter_chosen and Main builds the run.
## Implements: story-010-pokemon-premieres-routes (starter choice).

## Emitted when the player clicks a proposal.
signal starter_chosen(pokemon_id: String)

const SPRITE_SIZE: Vector2 = Vector2(144, 144)
const CARD_SIZE: Vector2 = Vector2(330, 420)
const COLOR_BG: Color = UiStyle.BG_DEEP

var _choices: Array[String] = []
var _cards_box: HBoxContainer
var _title: Label
var _done: bool = false
var _built: bool = false


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
	for i: int in _choices.size():
		_cards_box.add_child(_make_choice_widget(data, _choices[i], i))


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
	UiStyle.apply_button(b, UiStyle.BG_PANEL_LIGHT)  # story 020: raised panel-coloured choice
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
	sprite.texture = CardView.cropped_sprite(String(info["sprite_path"]))  # 96 px sources have wide margins
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.custom_minimum_size = SPRITE_SIZE
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
	_cards_box.add_theme_constant_override("separation", 24)
	column.add_child(_cards_box)
