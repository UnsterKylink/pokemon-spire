class_name CardView
extends RefCounted
## Shared UI helpers to draw cards, type badges and labels (battle hand and reward screen).
## Implements: story-001/003 card look, story-004 rarity display, story-009 carrying Pokémon on cards,
## story-020 redesigned card face (CardFace, design/art-bible.md).

const COLOR_TEXT_LIGHT: Color = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.1, 0.1, 0.12)
const RARITY_NAMES: Dictionary = {"starter": "Départ", "common": "Commune", "uncommon": "Peu commune", "rare": "Rare"}
## Rarity colours: same values as UiStyle.RARITY_COLORS (story 020 art bible).
const RARITY_COLORS: Dictionary = UiStyle.RARITY_COLORS
## Story 020: folder (next to assets/sprites/pokemon/) of the official artworks shown on cards.
const ARTWORK_DIR: String = "artwork"
## Story 009: size (px) of the carrying Pokémon's sprite on a card, and the label of skill cards.
const CARD_POKEMON_SPRITE_SIZE: float = 44.0
const TEXT_TEAM: String = "Équipe"
const COLOR_TEAM: Color = Color(0.6, 0.75, 0.95)
const COLOR_POKEMON_NAME: Color = Color(1.0, 0.92, 0.7)

## Story 018/020: legendary card look (gold double frame, gold name banner, "Légendaire" ribbon; drawn by CardFace).
const TEXT_LEGENDARY: String = "Légendaire"
const COLOR_LEGENDARY: Color = UiStyle.LEGENDARY
const COLOR_LEGENDARY_INNER: Color = UiStyle.LEGENDARY_INNER

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
	var sb: StyleBoxFlat = UiStyle.badge(color)  # story 020: dark outline (art bible §4)
	badge.add_theme_stylebox_override("panel", sb)
	var text: Label = badge.get_node("Text") as Label
	text.text = chart.get_type_name(type_id)
	text.add_theme_color_override("font_color", COLOR_TEXT_DARK if color.get_luminance() > 0.5 else COLOR_TEXT_LIGHT)


## Adds the card visuals to a Button as a child "Content" (a CardFace, art bible §7; every node ignores the mouse so
## the Button keeps click/hover/disabled): type-coloured frame, cost gem, name banner, the carrier Pokémon's official
## artwork (fallback: its sprite, then nothing), type pill, carrier name ("Équipe" for skills), description, rarity gem.
## `pokemon_lookup(pokemon_id) -> Dictionary` ({name, sprite_path, ...}, e.g. GameData.get_pokemon_info). The face is
## inset by CardFace.INSET px so the caller's own border (rarity / selection) stays visible. Owns no state.
static func fill_card_content(b: Button, card: CardData, chart: TypeChart, pokemon_lookup: Callable = Callable()) -> void:
	var known_type: bool = chart != null and not card.type_id.is_empty() and chart.is_known_type(card.type_id)
	var color: Color = UiStyle.type_color(card.type_id, chart) if known_type else UiStyle.SKILL
	var type_text: String = chart.get_type_name(card.type_id) if known_type else ""
	var carrier: String = TEXT_TEAM
	var tex: Texture2D = null
	var pixel: bool = false
	if not card.pokemon_id.is_empty():
		carrier = pokemon_name_of(card, pokemon_lookup)
		var sprite_path: String = String(_lookup(card.pokemon_id, pokemon_lookup).get("sprite_path", ""))
		var art_path: String = artwork_path(sprite_path)
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			tex = cropped_sprite(art_path)
		elif not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
			tex = cropped_sprite(sprite_path)
			pixel = true
	var face: CardFace = CardFace.create(card, color, type_text, carrier, tex, pixel)
	b.add_child(face)
	b.mouse_entered.connect(func() -> void: face.set_hovered(not b.disabled))
	b.mouse_exited.connect(face.set_hovered.bind(false))


## Story 020: official artwork path of a Pokémon from its sprite path (assets/sprites/pokemon/<slug>.png ->
## assets/sprites/artwork/<slug>.png); "" when the sprite path is empty.
static func artwork_path(sprite_path: String) -> String:
	if sprite_path.is_empty():
		return ""
	return sprite_path.get_base_dir().get_base_dir().path_join(ARTWORK_DIR).path_join(sprite_path.get_file())


## Name of the Pokémon carrying `card` via `pokemon_lookup` ("" for skills / no lookup; falls back to the id).
static func pokemon_name_of(card: CardData, pokemon_lookup: Callable) -> String:
	if card.pokemon_id.is_empty():
		return ""
	var info: Dictionary = _lookup(card.pokemon_id, pokemon_lookup)
	var n: String = String(info.get("name", ""))
	return n if not n.is_empty() else card.pokemon_id


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


## Story 018: rarity label of a card ("Légendaire" for legendary cards, else rarity_name).
static func card_rarity_name(card: CardData) -> String:
	return TEXT_LEGENDARY if card.legendary else rarity_name(card.rarity)


## French rarity label ("Commune", "Peu commune", "Rare").
static func rarity_name(rarity: String) -> String:
	return String(RARITY_NAMES.get(rarity, rarity))


## Rarity colour (used for the reward card border); see UiStyle.rarity_color.
static func rarity_color(rarity: String) -> Color:
	return UiStyle.rarity_color(rarity)
