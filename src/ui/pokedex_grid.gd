class_name PokedexGrid
extends Control
## Story 025 (story-025-pokedex): the thumbnail grid of the Pokédex screen, built for ~900 entries: ONE control that
## draws only the rows visible in its ScrollContainer (no node per Pokémon), loads the official artworks lazily (at
## most LOADS_PER_FRAME new textures per frame, only for visible cells) into a bounded LRU cache (CACHE_SIZE textures,
## cropped to their used rect). Cells: number, artwork (seen) or dark silhouette with « ??? » (never seen), a small Poké
## Ball badge when caught, highlight on hover / selection. Click / Entrée selects (entry_selected); arrows move the
## selection. Display only: reads a Pokedex, never writes it.

signal entry_selected(slug: String)

const CELL_SIZE: Vector2 = Vector2(108, 126)
const CELL_GAP: float = 8.0
const ART_SIDE: float = 80.0
const LOADS_PER_FRAME: int = 4
const CACHE_SIZE: int = 260
const FONT_NUMBER: int = 13
const FONT_NAME: int = 14
const TEXT_UNKNOWN: String = "???"
const TEXT_NUMBER: String = "N° %03d"
const COLOR_CELL: Color = Color("#EAF1FC")
const COLOR_CELL_UNSEEN: Color = Color("#D5DCEA")
const COLOR_HOVER: Color = Color("#FFE58A")
const COLOR_SELECTED: Color = UiStyle.ACCENT_YELLOW
const COLOR_RIM: Color = Color("#9DB4DB")
const COLOR_SILHOUETTE: Color = Color(0.1, 0.12, 0.2, 0.92)
const COLOR_TEXT: Color = UiStyle.TEXT_DARK
const COLOR_MUTED: Color = UiStyle.TEXT_SUB

## Shared texture cache (slug -> Texture2D) and its use order (oldest first); survives the screen (same launch).
static var _cache: Dictionary = {}
static var _lru: Array[String] = []

var _entries: Array[Dictionary] = []
var _dex: Pokedex
var _columns: int = 1
var _hover: int = -1
var _selected: int = -1
var _scroll: ScrollContainer
var _cell_box: StyleBoxFlat
var _font: Font
var _font_bold: Font
var _loads_total: int = 0


func _init() -> void:
	name = "PokedexGrid"
	mouse_filter = Control.MOUSE_FILTER_PASS  # the wheel still reaches the ScrollContainer
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_box = StyleBoxFlat.new()
	_cell_box.set_corner_radius_all(10)
	_cell_box.set_border_width_all(2)
	_font = UiStyle.font_body()
	_font_bold = UiStyle.font_bold()


func _ready() -> void:
	_scroll = get_parent() as ScrollContainer
	if _scroll == null and get_parent() != null:
		_scroll = get_parent().get_parent() as ScrollContainer
	if _scroll != null:
		_scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: queue_redraw())
		_scroll.resized.connect(_relayout)
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw())


## Shows `entries` (PokedexCatalog entries) against `dex`; keeps the selection when its slug is still listed.
func set_entries(entries: Array[Dictionary], dex: Pokedex) -> void:
	var keep: String = selected_slug()
	_entries = entries
	_dex = dex
	_hover = -1
	_selected = -1
	for i: int in _entries.size():
		if String(_entries[i]["slug"]) == keep:
			_selected = i
	_relayout()
	if _scroll != null:
		_scroll.scroll_vertical = 0
	queue_redraw()


## Number of entries listed.
func entry_count() -> int:
	return _entries.size()


## Slugs listed, in order (QA).
func get_slugs() -> PackedStringArray:
	var out := PackedStringArray()
	for e: Dictionary in _entries:
		out.append(String(e["slug"]))
	return out


## Slug of the selected entry ("" when none).
func selected_slug() -> String:
	return String(_entries[_selected]["slug"]) if _selected >= 0 and _selected < _entries.size() else ""


## Selects `slug` (scrolls to it) and emits entry_selected. False if not listed.
func select_slug(slug: String) -> bool:
	for i: int in _entries.size():
		if String(_entries[i]["slug"]) == slug:
			_select(i)
			return true
	return false


## Columns of the current layout.
func get_columns() -> int:
	return _columns


## Textures loaded since the start of the launch (QA: lazy loading).
func loaded_texture_count() -> int:
	return _loads_total


## Size of the shared texture cache (QA).
static func cache_size() -> int:
	return _cache.size()


## Index range [first, last) of the entries in the visible rows (plus one row of margin).
func visible_range() -> Vector2i:
	var row_h: float = CELL_SIZE.y + CELL_GAP
	var top: float = float(_scroll.scroll_vertical) if _scroll != null else 0.0
	var height: float = _scroll.size.y if _scroll != null else size.y
	var first_row: int = maxi(0, int(floor(top / row_h)) - 1)
	var last_row: int = int(ceil((top + height) / row_h)) + 1
	return Vector2i(mini(first_row * _columns, _entries.size()), mini(last_row * _columns, _entries.size()))


## Loads every texture of the visible rows now (QA shots: no half-loaded grid).
func load_visible_now() -> void:
	var r: Vector2i = visible_range()
	for i: int in range(r.x, r.y):
		_texture_for(String(_entries[i]["slug"]), String(_entries[i]["sprite_path"]), true)
	queue_redraw()


func _relayout() -> void:
	var width: float = _scroll.size.x - 14.0 if _scroll != null else size.x
	_columns = maxi(1, int(floor((width + CELL_GAP) / (CELL_SIZE.x + CELL_GAP))))
	var rows: int = ceili(float(_entries.size()) / float(_columns))
	custom_minimum_size = Vector2(_columns * (CELL_SIZE.x + CELL_GAP) - CELL_GAP, maxf(0.0, rows * (CELL_SIZE.y + CELL_GAP) - CELL_GAP))
	queue_redraw()


func _cell_rect(i: int) -> Rect2:
	var used_w: float = _columns * (CELL_SIZE.x + CELL_GAP) - CELL_GAP
	var x0: float = maxf(0.0, (size.x - used_w) * 0.5)
	return Rect2(Vector2(x0 + (i % _columns) * (CELL_SIZE.x + CELL_GAP), (i / _columns) * (CELL_SIZE.y + CELL_GAP)), CELL_SIZE)


func _index_at(pos: Vector2) -> int:
	var used_w: float = _columns * (CELL_SIZE.x + CELL_GAP) - CELL_GAP
	var x0: float = maxf(0.0, (size.x - used_w) * 0.5)
	var col: int = int(floor((pos.x - x0) / (CELL_SIZE.x + CELL_GAP)))
	var row: int = int(floor(pos.y / (CELL_SIZE.y + CELL_GAP)))
	if col < 0 or col >= _columns or row < 0:
		return -1
	var i: int = row * _columns + col
	if i >= _entries.size() or not _cell_rect(i).has_point(pos):
		return -1
	return i


func _process(_delta: float) -> void:
	if _entries.is_empty() or not is_visible_in_tree():
		return
	var budget: int = LOADS_PER_FRAME
	var r: Vector2i = visible_range()
	for i: int in range(r.x, r.y):
		if budget <= 0:
			break
		var slug: String = String(_entries[i]["slug"])
		if not _cache.has(slug):
			_texture_for(slug, String(_entries[i]["sprite_path"]), true)
			budget -= 1
	if budget < LOADS_PER_FRAME:
		queue_redraw()


## Cached texture of `slug` (null when not loaded yet and `load_now` is false).
func _texture_for(slug: String, sprite_path: String, load_now: bool) -> Texture2D:
	if _cache.has(slug):
		_lru.erase(slug)
		_lru.append(slug)
		return _cache[slug]
	if not load_now:
		return null
	var tex: Texture2D = null
	var art: String = CardView.artwork_path(sprite_path)
	var path: String = art if not art.is_empty() and ResourceLoader.exists(art) else sprite_path
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
		var img: Image = tex.get_image() if tex != null else null
		if img != null and not img.is_compressed():
			var used: Rect2i = img.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(used)
				tex = atlas
	_cache[slug] = tex
	_lru.append(slug)
	_loads_total += 1
	while _lru.size() > CACHE_SIZE:
		_cache.erase(_lru.pop_front())
	return tex


func _draw() -> void:
	if _entries.is_empty():
		return
	var r: Vector2i = visible_range()
	for i: int in range(r.x, r.y):
		_draw_cell(i)


func _draw_cell(i: int) -> void:
	var e: Dictionary = _entries[i]
	var slug: String = String(e["slug"])
	var seen: bool = _dex != null and _dex.is_seen(slug)
	var caught: bool = _dex != null and _dex.is_caught(slug)
	var rect: Rect2 = _cell_rect(i)
	_cell_box.bg_color = COLOR_CELL if seen else COLOR_CELL_UNSEEN
	_cell_box.border_color = COLOR_SELECTED if i == _selected else (COLOR_HOVER if i == _hover else COLOR_RIM)
	_cell_box.set_border_width_all(4 if i == _selected else 2)
	draw_style_box(_cell_box, rect)
	draw_string(_font_bold, rect.position + Vector2(8, 17), TEXT_NUMBER % int(e["dex"]), HORIZONTAL_ALIGNMENT_LEFT, -1,
			FONT_NUMBER, COLOR_MUTED)
	var tex: Texture2D = _texture_for(slug, String(e["sprite_path"]), false)
	var art_rect := Rect2(rect.position + Vector2((CELL_SIZE.x - ART_SIDE) * 0.5, 20.0), Vector2(ART_SIDE, ART_SIDE))
	if tex != null:
		var ts: Vector2 = tex.get_size()
		var k: float = minf(ART_SIDE / maxf(ts.x, 1.0), ART_SIDE / maxf(ts.y, 1.0))
		var ds: Vector2 = ts * k
		draw_texture_rect(tex, Rect2(art_rect.position + (art_rect.size - ds) * 0.5, ds), false,
				Color.WHITE if seen else COLOR_SILHOUETTE)
	var label: String = String(e["name"]) if seen else TEXT_UNKNOWN
	draw_string(_font_bold if seen else _font, Vector2(rect.position.x + 4.0, rect.end.y - 8.0), label,
			HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE.x - 8.0, FONT_NAME, COLOR_TEXT if seen else COLOR_MUTED)
	if caught:
		BallIcon.draw_ball(self, rect.position + Vector2(CELL_SIZE.x - 15.0, 15.0), 9.0, "poke_ball")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h: int = _index_at((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var i: int = _index_at(mb.position)
			if i >= 0:
				grab_focus()
				_select(i)
				accept_event()
	elif event.is_action_pressed("ui_right"):
		_move(1)
	elif event.is_action_pressed("ui_left"):
		_move(-1)
	elif event.is_action_pressed("ui_down"):
		_move(_columns)
	elif event.is_action_pressed("ui_up"):
		_move(-_columns)
	elif event.is_action_pressed("ui_accept") and _selected >= 0:
		entry_selected.emit(selected_slug())
		accept_event()


func _move(step: int) -> void:
	if _entries.is_empty():
		return
	_select(clampi(maxi(_selected, 0) + step if _selected >= 0 else 0, 0, _entries.size() - 1))
	accept_event()


func _select(i: int) -> void:
	_selected = i
	_ensure_visible(i)
	queue_redraw()
	entry_selected.emit(selected_slug())


func _ensure_visible(i: int) -> void:
	if _scroll == null:
		return
	var rect: Rect2 = _cell_rect(i)
	if rect.position.y < _scroll.scroll_vertical:
		_scroll.scroll_vertical = int(rect.position.y)
	elif rect.end.y > _scroll.scroll_vertical + _scroll.size.y:
		_scroll.scroll_vertical = int(rect.end.y - _scroll.size.y)
