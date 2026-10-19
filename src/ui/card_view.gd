class_name CardView
extends RefCounted
## Shared UI helpers to draw cards, type badges and labels (battle hand and reward screen).
## Implements: story-001/003 card look, story-004 rarity display.

const COLOR_TEXT_LIGHT: Color = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.1, 0.1, 0.12)
const RARITY_NAMES: Dictionary = {"starter": "Départ", "common": "Commune", "uncommon": "Peu commune", "rare": "Rare"}
const RARITY_COLORS: Dictionary = {
	"starter": Color(0.6, 0.6, 0.65), "common": Color(0.85, 0.85, 0.9),
	"uncommon": Color(0.35, 0.85, 0.65), "rare": Color(1.0, 0.8, 0.25)}


## Centered label with the given font size that ignores the mouse.
static func make_label(font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	return l


## Small rounded badge (PanelContainer + Label "Text"); fill it with set_badge.
static func make_type_badge(font_size: int = 16) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "TypeBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var text: Label = make_label(font_size)
	text.name = "Text"
	badge.add_child(text)
	return badge


## Row of badges for a Pokémon (1-2 types, side by side, centred); fill it with set_badge_row.
static func make_type_badge_row(font_size: int = 16) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "TypeBadgeRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.set_meta("font_size", font_size)
	return row


## Rebuilds the row with one badge per known type id (hidden when the Pokémon has none).
static func set_badge_row(row: HBoxContainer, type_ids: Array[String], chart: TypeChart) -> void:
	for child: Node in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var font_size: int = int(row.get_meta("font_size", 16))
	for type_id: String in type_ids:
		var badge: PanelContainer = make_type_badge(font_size)
		set_badge(badge, type_id, chart)
		row.add_child(badge)
	row.visible = row.get_child_count() > 0


## Fills a badge with the type's French name and colour (hidden when the type is empty/unknown).
static func set_badge(badge: PanelContainer, type_id: String, chart: TypeChart) -> void:
	badge.visible = chart.is_known_type(type_id)
	if not badge.visible:
		return
	var color: Color = chart.get_type_color(type_id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 1.0
	badge.add_theme_stylebox_override("panel", sb)
	var text: Label = badge.get_node("Text") as Label
	text.text = chart.get_type_name(type_id)
	text.add_theme_color_override("font_color", COLOR_TEXT_DARK if color.get_luminance() > 0.5 else COLOR_TEXT_LIGHT)


## Adds the card visuals to a Button as a child "Content" (all children ignore the mouse so the
## Button keeps click/hover/disabled): name, cost, type badge (attacks), description.
static func fill_card_content(b: Button, card: CardData, chart: TypeChart) -> void:
	var margin := MarginContainer.new()
	margin.name = "Content"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var name_label: Label = make_label(18)
	name_label.name = "CardName"
	name_label.text = card.display_name
	box.add_child(name_label)
	var cost_label: Label = make_label(16)
	cost_label.text = "Coût : %d" % card.cost
	box.add_child(cost_label)
	if not card.type_id.is_empty():
		var badge: PanelContainer = make_type_badge(14)
		set_badge(badge, card.type_id, chart)
		box.add_child(badge)
	var desc: Label = make_label(15)
	desc.name = "CardDescription"
	desc.text = card.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(desc)


## French rarity label ("Commune", "Peu commune", "Rare").
static func rarity_name(rarity: String) -> String:
	return String(RARITY_NAMES.get(rarity, rarity))


## Rarity colour (used for the reward card border).
static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)
