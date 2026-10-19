class_name CardView
extends RefCounted
## Shared UI helpers to draw cards, type badges and labels (battle hand and reward screen).
## Implements: story-001/003 card look, story-004 rarity display, story-009 carrying Pokémon on cards.

const COLOR_TEXT_LIGHT: Color = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.1, 0.1, 0.12)
const RARITY_NAMES: Dictionary = {"starter": "Départ", "common": "Commune", "uncommon": "Peu commune", "rare": "Rare"}
const RARITY_COLORS: Dictionary = {
	"starter": Color(0.6, 0.6, 0.65), "common": Color(0.85, 0.85, 0.9),
	"uncommon": Color(0.35, 0.85, 0.65), "rare": Color(1.0, 0.8, 0.25)}
## Story 009: size (px) of the carrying Pokémon's sprite on a card, and the label of skill cards.
const CARD_POKEMON_SPRITE_SIZE: float = 44.0
const TEXT_TEAM: String = "Équipe"
const COLOR_TEAM: Color = Color(0.6, 0.75, 0.95)
const COLOR_POKEMON_NAME: Color = Color(1.0, 0.92, 0.7)

## Cache of cropped card icons (path -> Texture2D): pure display cache, no game state.
static var _cropped_cache: Dictionary = {}


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
## Button keeps click/hover/disabled): name, cost + type badge (attacks), carrying Pokémon, description.
## `pokemon_lookup(pokemon_id) -> Dictionary` ({name, sprite_path, ...}, e.g. GameData.get_pokemon_info)
## gives the Pokémon shown on attack cards (story 009); skills show "Équipe". The widget owns no state.
static func fill_card_content(b: Button, card: CardData, chart: TypeChart, pokemon_lookup: Callable = Callable()) -> void:
	var margin := MarginContainer.new()
	margin.name = "Content"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	b.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	var name_label: Label = make_label(17)
	name_label.name = "CardName"
	name_label.text = card.display_name
	box.add_child(name_label)
	var cost_row := HBoxContainer.new()
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 6)
	box.add_child(cost_row)
	var cost_label: Label = make_label(15)
	cost_label.text = "Coût : %d" % card.cost
	cost_row.add_child(cost_label)
	if not card.type_id.is_empty():
		var badge: PanelContainer = make_type_badge(13)
		set_badge(badge, card.type_id, chart)
		cost_row.add_child(badge)
	box.add_child(_make_pokemon_row(card, pokemon_lookup))
	var desc: Label = make_label(14)
	desc.name = "CardDescription"
	desc.text = card.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(desc)


## Name of the Pokémon carrying `card` via `pokemon_lookup` ("" for skills / no lookup; falls back to the id).
static func pokemon_name_of(card: CardData, pokemon_lookup: Callable) -> String:
	if card.pokemon_id.is_empty():
		return ""
	var info: Dictionary = _lookup(card.pokemon_id, pokemon_lookup)
	var n: String = String(info.get("name", ""))
	return n if not n.is_empty() else card.pokemon_id


## Row "sprite + French name" of the carrying Pokémon, or "Équipe" for skills (fixed height so cards align).
static func _make_pokemon_row(card: CardData, pokemon_lookup: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "PokemonRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.custom_minimum_size = Vector2(0, CARD_POKEMON_SPRITE_SIZE)
	var label: Label = make_label(14)
	label.name = "PokemonName"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if card.pokemon_id.is_empty():
		label.text = TEXT_TEAM
		label.add_theme_color_override("font_color", COLOR_TEAM)
	else:
		var info: Dictionary = _lookup(card.pokemon_id, pokemon_lookup)
		var path: String = String(info.get("sprite_path", ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			var sprite := TextureRect.new()
			sprite.name = "PokemonSprite"
			sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.custom_minimum_size = Vector2.ONE * CARD_POKEMON_SPRITE_SIZE
			sprite.texture = cropped_sprite(path)
			row.add_child(sprite)
		label.text = pokemon_name_of(card, pokemon_lookup)
		label.add_theme_color_override("font_color", COLOR_POKEMON_NAME)
	row.add_child(label)
	return row


## Sprite at `path` cropped to its opaque pixels (the 96 px sources have wide transparent margins, so a
## 44 px card icon would otherwise be tiny). Cached per path; falls back to the plain texture.
static func cropped_sprite(path: String) -> Texture2D:
	if _cropped_cache.has(path):
		return _cropped_cache[path]
	var tex: Texture2D = load(path) as Texture2D
	var result: Texture2D = tex
	if tex != null:
		var img: Image = tex.get_image()
		if img != null and not img.is_compressed():
			var used: Rect2i = img.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(used)
				result = atlas
	_cropped_cache[path] = result
	return result


static func _lookup(pokemon_id: String, pokemon_lookup: Callable) -> Dictionary:
	if not pokemon_lookup.is_valid():
		return {}
	var v: Variant = pokemon_lookup.call(pokemon_id)
	return v if v is Dictionary else {}


## French rarity label ("Commune", "Peu commune", "Rare").
static func rarity_name(rarity: String) -> String:
	return String(RARITY_NAMES.get(rarity, rarity))


## Rarity colour (used for the reward card border).
static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)
