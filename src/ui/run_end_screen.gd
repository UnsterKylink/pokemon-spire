class_name RunEndScreen
extends Control
## Story 007 (story-007-champion-evolution-fin-de-partie): end-of-run summary, in two modes.
## Victory (after the Champion and the evolution) and defeat (HP reached 0) show the same summary:
## final Pokémon (sprite, name, types, HP), floors climbed, enemies beaten, battles won, Pokédollars, items,
## and the final deck grouped by card. Story 012: the zone reached ("Zone atteinte 3/8 — Arène Eau"), the badges row
## (BadgeEmblem: earned in their type colour, the others grey) and the floors of the whole run (8 zones). "Nouvelle partie" emits new_run_requested (Main resets the whole run).
## Display only: reads RunState.get_summary() / get_deck_entries(). Mouse only, fits 1280x720.

## Emitted by "Nouvelle partie".
signal new_run_requested

const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_VICTORY: Color = Color(1.0, 0.85, 0.3)
const COLOR_DEFEAT: Color = Color(0.95, 0.38, 0.35)
const COLOR_PANEL: Color = Color(0.16, 0.17, 0.23)
const COLOR_PANEL_BORDER: Color = Color(0.38, 0.4, 0.5)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const SPRITE_SIZE: Vector2 = Vector2(120, 120)
const BADGE_SIDE: float = 30.0
const LEFT_PANEL_WIDTH: float = 470.0
const DECK_COLUMNS: int = 2
const TEXT_VICTORY: String = "Victoire ! Tu as battu le Champion d'arène"
const TEXT_DEFEAT: String = "Défaite…"
const TEXT_VICTORY_SUB: String = "%s a terminé l'acte 1. Bravo, Dresseur !"
const TEXT_DEFEAT_SUB: String = "%s est K.O. La partie est terminée."
## Story 012 (zones): subtitles naming the badges / the zone of the defeat.
const TEXT_VICTORY_SUB_ZONES: String = "%s a remporté les %d badges. Bravo, Dresseur !"
const TEXT_DEFEAT_SUB_ZONES: String = "%s est K.O. en zone %d/%d (Arène %s). La partie est terminée."
const TEXT_BADGES: String = "Badges : %d/%d"
const TEXT_ZONE: String = "%d/%d — Arène %s"
const STAT_ZONE: String = "Zone atteinte"
const TEXT_DECK: String = "Deck final (%d cartes)"
const TEXT_NO_ITEM: String = "aucun"
const STAT_FLOORS: String = "Étages franchis"
const STAT_ENEMIES: String = "Ennemis battus"
const STAT_BATTLES: String = "Combats gagnés"
const STAT_HP: String = "PV"
const STAT_MONEY: String = "Pokédollars"
const STAT_ITEMS: String = "Objets"

var _victory: bool = false
var _built: bool = false
var _title: Label
var _subtitle: Label
var _sprite: TextureRect
var _name_label: Label
var _badges: HBoxContainer
var _stats_grid: GridContainer
var _badge_caption: Label
var _badge_row: HBoxContainer
var _deck_title: Label
var _deck_grid: GridContainer
var _stats: Dictionary = {}  # stat caption -> value text (QA)


func _init() -> void:
	name = "RunEndScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Fills the summary from `run` (read only). `victory` picks the title / colours.
func setup(data: GameData, run: RunState, victory: bool) -> void:
	_build_ui()
	_victory = victory
	var s: Dictionary = run.get_summary()
	_title.text = TEXT_VICTORY if victory else TEXT_DEFEAT
	_title.add_theme_color_override("font_color", COLOR_VICTORY if victory else COLOR_DEFEAT)
	var zone: Dictionary = run.current_zone()
	if zone.is_empty():
		_subtitle.text = (TEXT_VICTORY_SUB if victory else TEXT_DEFEAT_SUB) % String(s["name"])
	elif victory:
		_subtitle.text = TEXT_VICTORY_SUB_ZONES % [String(s["name"]), int(s["badges"])]
	else:
		_subtitle.text = TEXT_DEFEAT_SUB_ZONES % [String(s["name"]), int(s["zone"]), int(s["zone_count"]), String(zone["type_name"])]
	_sprite.texture = CardView.cropped_sprite(String(s["sprite"]))
	_sprite.modulate = Color.WHITE if victory else Color(0.6, 0.6, 0.65, 0.85)
	_name_label.text = String(s["name"])
	var types: Array[String] = []
	types.assign(s["types"])
	CardView.set_badge_row(_badges, types, data.get_type_chart())
	_stats.clear()
	for child: Node in _stats_grid.get_children():
		_stats_grid.remove_child(child)
		child.queue_free()
	var items: Array[String] = []
	items.assign(s["item_names"])
	if not zone.is_empty():
		_add_stat(STAT_ZONE, TEXT_ZONE % [int(s["zone"]), int(s["zone_count"]), String(zone["type_name"])])
	_add_stat(STAT_FLOORS, "%d/%d" % [int(s["floors"]), int(s["total_floors"])])
	_add_stat(STAT_ENEMIES, str(int(s["enemies_defeated"])))
	_add_stat(STAT_BATTLES, str(int(s["battles_won"])))
	_add_stat(STAT_HP, "%d/%d" % [int(s["hp"]), int(s["max_hp"])])
	_add_stat(STAT_MONEY, RunHud.format_money(int(s["money"])))
	_add_stat(STAT_ITEMS, ", ".join(items) if not items.is_empty() else TEXT_NO_ITEM)
	BadgeEmblem.fill_row(_badge_row, run, BADGE_SIDE)
	_badge_caption.text = TEXT_BADGES % [int(s["badges"]), run.zones.size()]
	_badge_caption.visible = _badge_row.visible
	_deck_title.text = TEXT_DECK % int(s["deck_size"])
	for child: Node in _deck_grid.get_children():
		_deck_grid.remove_child(child)
		child.queue_free()
	for entry: Dictionary in run.get_deck_entries():
		var card: CardData = entry["card"]
		var pokemon_name: String = String(run.get_pokemon_info(card.pokemon_id).get("name", "")) if not card.pokemon_id.is_empty() else ""
		var l: Label = CardView.make_label(18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.text = "×%d  %s" % [int(entry["count"]), card.display_label(pokemon_name)]
		l.tooltip_text = "Coût %d : %s" % [card.cost, card.description]
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.add_theme_color_override("font_color", CardView.rarity_color(card.rarity))
		_deck_grid.add_child(l)


## True in victory mode, false in defeat mode.
func is_victory() -> bool:
	return _victory


## Title text (QA).
func get_title_text() -> String:
	return _title.text


## Stat caption -> displayed value ({"Étages franchis": "15/15", ...}) (QA).
func get_stats() -> Dictionary:
	return _stats.duplicate()


## Badges row, for QA: [{earned: bool, tooltip: String}] in zone order.
func get_badge_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for child: Node in _badge_row.get_children():
		slots.append({"earned": (child as BadgeEmblem).is_earned(), "tooltip": (child as Control).tooltip_text})
	return slots


## Deck lines ("×5  Flammette — Reptincel") (QA).
func get_deck_lines() -> Array[String]:
	var lines: Array[String] = []
	for child: Node in _deck_grid.get_children():
		lines.append((child as Label).text)
	return lines


## "Nouvelle partie" (same path as the button).
func press_new_run() -> void:
	new_run_requested.emit()


func _add_stat(caption: String, value: String) -> void:
	_stats[caption] = value
	var c: Label = CardView.make_label(22)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	c.text = caption
	c.add_theme_color_override("font_color", COLOR_CAPTION)
	_stats_grid.add_child(c)
	var v: Label = CardView.make_label(22)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.text = value
	_stats_grid.add_child(v)


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(2)
	sb.border_color = COLOR_PANEL_BORDER
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	return panel


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
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	_title = CardView.make_label(42)
	_title.name = "Title"
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	root.add_child(_title)
	_subtitle = CardView.make_label(22)
	_subtitle.name = "Subtitle"
	root.add_child(_subtitle)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	# Left: final Pokémon + stats.
	var left: PanelContainer = _panel()
	left.custom_minimum_size = Vector2(LEFT_PANEL_WIDTH, 0)
	body.add_child(left)
	var lbox := VBoxContainer.new()
	lbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbox.add_theme_constant_override("separation", 6)
	left.add_child(lbox)
	_sprite = TextureRect.new()
	_sprite.name = "Sprite"
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.custom_minimum_size = SPRITE_SIZE
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lbox.add_child(_sprite)
	_name_label = CardView.make_label(30)
	_name_label.name = "PokemonName"
	lbox.add_child(_name_label)
	_badges = CardView.make_type_badge_row(18)
	lbox.add_child(_badges)
	_stats_grid = GridContainer.new()
	_stats_grid.name = "Stats"
	_stats_grid.columns = 2
	_stats_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_grid.add_theme_constant_override("h_separation", 16)
	_stats_grid.add_theme_constant_override("v_separation", 4)
	lbox.add_child(_stats_grid)
	var badge_box := HBoxContainer.new()
	badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_box.add_theme_constant_override("separation", 12)
	lbox.add_child(badge_box)
	_badge_caption = CardView.make_label(22)
	_badge_caption.name = "BadgeCaption"
	_badge_caption.add_theme_color_override("font_color", COLOR_CAPTION)
	badge_box.add_child(_badge_caption)
	_badge_row = HBoxContainer.new()
	_badge_row.name = "BadgeRow"
	_badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_row.add_theme_constant_override("separation", 6)
	badge_box.add_child(_badge_row)
	# Right: final deck.
	var right: PanelContainer = _panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rbox := VBoxContainer.new()
	rbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rbox.add_theme_constant_override("separation", 8)
	right.add_child(rbox)
	_deck_title = CardView.make_label(26)
	_deck_title.name = "DeckTitle"
	rbox.add_child(_deck_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rbox.add_child(scroll)
	_deck_grid = GridContainer.new()
	_deck_grid.name = "Deck"
	_deck_grid.columns = DECK_COLUMNS
	_deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deck_grid.add_theme_constant_override("h_separation", 18)
	_deck_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_deck_grid)
	var button := Button.new()
	button.name = "NewRunButton"
	button.text = "Nouvelle partie"
	button.custom_minimum_size = Vector2(260, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(press_new_run)
	root.add_child(button)
