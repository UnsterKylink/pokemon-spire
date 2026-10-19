class_name DeckOverlay
extends Control
## Full-screen "Voir le deck" overlay: dimmed background + scrollable list of the run's deck + "Fermer".
## Shared by RewardScreen and MapScreen. Only reads RunState; holds no game state.
## Implements: story-004-recompenses-vol-attaque (deck overlay), reused by story-005-carte-acte-1;
## story-009: one line per (card, Pokémon), e.g. "Griffe — Salamèche ×5 (coût 1) : ...".

const PANEL_SIZE: Vector2 = Vector2(820, 560)

var _list: VBoxContainer
var _title: Label


func _init() -> void:
	name = "DeckOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_title = CardView.make_label(30)
	box.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(200, 48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	box.add_child(close_button)


## Fills the list from `run` (read only) and shows the overlay.
func open(run: RunState) -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_title.text = "Ton deck (%d cartes)" % run.deck.size()
	for entry: Dictionary in run.get_deck_entries():
		var card: CardData = entry["card"]
		var l: Label = CardView.make_label(22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var pokemon_name: String = String(run.get_pokemon_info(card.pokemon_id).get("name", "")) if not card.pokemon_id.is_empty() else ""
		l.text = "%s ×%d (coût %d) : %s" % [card.display_label(pokemon_name), int(entry["count"]), card.cost, card.description]
		l.add_theme_color_override("font_color", CardView.rarity_color(card.rarity))
		_list.add_child(l)
	visible = true


## Hides the overlay ("Fermer").
func close() -> void:
	visible = false


## True while the overlay is shown.
func is_open() -> bool:
	return visible


## Text of each deck line ("Griffe — Salamèche ×5 ..."), for the QA harness.
func get_lines() -> Array[String]:
	var lines: Array[String] = []
	for child: Node in _list.get_children():
		lines.append((child as Label).text)
	return lines
