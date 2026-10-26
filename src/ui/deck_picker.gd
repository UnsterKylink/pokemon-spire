class_name DeckPicker
extends Control
## Full-screen "pick a card of the deck" overlay: dimmed background, title + hint, scrollable grid of the
## eligible cards (identical copies grouped, "×N"), and a cancel button. Used by the Centre Pokémon (upgrade)
## and the Poké Mart (removal). Reads RunState only; emits card_picked(deck_index) / cancelled.
## Implements: story-006-objets-et-services (criteria 4, 5).

## Emitted when a card is clicked: the index (into RunState.deck) of the first copy of that group.
signal card_picked(deck_index: int)
## Emitted by the cancel button.
signal cancelled

const PANEL_SIZE: Vector2 = Vector2(1180, 620)
const CARD_SIZE: Vector2 = Vector2(170, 200)
const COLUMNS: int = 6
const COLOR_CARD_BG: Color = Color(0.18, 0.18, 0.24)
const COLOR_HINT: Color = Color(0.75, 0.77, 0.86)

var _title: Label
var _hint: Label
var _empty: Label
var _grid: GridContainer
var _cancel: Button
var _indices: Array[int] = []


func _init() -> void:
	UiStyle.style_screen(self)  # story 020: art-bible look
	name = "DeckPicker"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
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
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.13, 0.14, 0.19)
	ps.set_border_width_all(2)
	ps.border_color = Color(0.45, 0.47, 0.58)
	ps.set_corner_radius_all(10)
	ps.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_title = CardView.make_label(28)
	box.add_child(_title)
	_hint = CardView.make_label(18)
	_hint.add_theme_color_override("font_color", COLOR_HINT)
	box.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var holder := VBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 8)
	holder.add_child(_grid)
	_empty = CardView.make_label(22)
	_empty.add_theme_color_override("font_color", COLOR_HINT)
	holder.add_child(_empty)
	_cancel = Button.new()
	_cancel.name = "CancelButton"
	_cancel.custom_minimum_size = Vector2(200, 46)
	_cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cancel.focus_mode = Control.FOCUS_NONE
	_cancel.pressed.connect(cancel)
	box.add_child(_cancel)


## Shows the cards of `run.deck` for which `eligible(deck_index) -> bool` is true (identical copies grouped).
## `empty_text` is shown when none is eligible.
func open(title: String, hint: String, run: RunState, data: GameData, eligible: Callable,
		empty_text: String = "", cancel_text: String = "Retour") -> void:
	_title.text = title
	_hint.text = hint
	_cancel.text = cancel_text
	_cancel.visible = true
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_indices.clear()
	var groups: Dictionary = {}  # deck_key -> [first index, count]
	var order: Array[String] = []
	for i: int in run.deck.size():
		if not bool(eligible.call(i)):
			continue
		var key: String = run.deck[i].deck_key()
		if groups.has(key):
			groups[key][1] = int(groups[key][1]) + 1
		else:
			groups[key] = [i, 1]
			order.append(key)
	for key: String in order:
		var index: int = int(groups[key][0])
		_indices.append(index)
		_grid.add_child(_make_cell(run.deck[index], index, int(groups[key][1]), data))
	_empty.text = empty_text if order.is_empty() else ""
	_empty.visible = order.is_empty()
	visible = true


## Story 018: shows / hides the cancel button (hidden for a mandatory pick, e.g. an event card removal).
## open() shows it again.
func set_cancel_visible(shown: bool) -> void:
	_cancel.visible = shown


## Picks the card group starting at `deck_index` (same path as a click). Ignored if not offered.
func pick(deck_index: int) -> void:
	if visible and _indices.has(deck_index):
		card_picked.emit(deck_index)


## Presses the cancel button.
func cancel() -> void:
	if visible:
		cancelled.emit()


## Hides the overlay.
func close() -> void:
	visible = false


## True while shown.
func is_open() -> bool:
	return visible


## Deck indices offered (first copy of each group), for the QA harness.
func get_offered_indices() -> Array[int]:
	return _indices


func _make_cell(card: CardData, deck_index: int, count: int, data: GameData) -> Control:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 2)
	var b := Button.new()
	b.name = "Card%d" % deck_index
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	CardView.fill_card_content(b, card, data.get_type_chart(), data.get_pokemon_info)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_BG
	sb.set_border_width_all(3)
	sb.border_color = CardView.rarity_color(card.rarity)
	sb.set_corner_radius_all(6)
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = COLOR_CARD_BG.lightened(0.15)
	hover.border_color = Color(1.0, 0.85, 0.3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(pick.bind(deck_index))
	col.add_child(b)
	var n: Label = CardView.make_label(16)
	n.text = "×%d" % count
	n.add_theme_color_override("font_color", COLOR_HINT)
	col.add_child(n)
	return col
