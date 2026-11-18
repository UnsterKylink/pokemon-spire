class_name EventScreen
extends Control
## Event room (mouse only, fits 1280x720): title, text, 2 option buttons; after a choice, the option's
## result text + the effects summary and "Continuer". Holds no game state: it emits option_chosen,
## Main applies the effects and calls show_result. Implements: story-005-carte-acte-1 (events, 2 options).
## Story 018: options Main reports unavailable are greyed with their reason ("Il te faut 50 P$"), money hints
## (+40 P$ / -20 P$) are appended to labels without a price, legendary events get a dark/gold frame with the
## legendary's sprite, and a pending card removal opens a DeckPicker (open_removal) that never lets play block.
## Story 033 (cohérence visuelle): the zone's painted backdrop (gym type of the current zone, fallback route; legendary
## events: the legendary backdrop) blurred and darkened behind everything, the event's illustration in front on the
## left (events.json `art`: {"pokemon": slug} official artwork, {"item": id} item art, {"rival": true} the rival's
## current Pokémon; legendary events fall back to their legendary), the text in the white « menu Pokémon » window
## (gold frame for legendaries).

## Emitted once when the player picks option `index`.
signal option_chosen(index: int)
## Emitted by "Continuer" once the result is shown.
signal finished
## Story 018: emitted when the player picks the card to forget (index into RunState.deck); Main applies it.
signal removal_picked(deck_index: int)

const COLOR_BG: Color = UiStyle.BG_DEEP
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_BORDER: Color = Color(0.35, 0.75, 0.42)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const COLOR_SUMMARY: Color = Color(0.55, 1.0, 0.6)
const COLOR_CHOSEN: Color = Color(1.0, 0.86, 0.3)
const PANEL_WIDTH: float = 940.0
const OPTION_SIZE: Vector2 = Vector2(640, 54)
## Story 018: unavailable option reason, money hints, removal picker texts, legendary frame.
const TEXT_NEED_MONEY: String = "Il te faut %s"
const TEXT_REMOVE_TITLE: String = "Choisis une carte à oublier (%d restante%s)"
const TEXT_REMOVE_HINT: String = "Cette carte quitte définitivement ton deck."
const TEXT_LEGENDARY: String = "Pokémon légendaire"
const COLOR_LEG_BG: Color = Color(0.06, 0.05, 0.1)
const COLOR_LEG_PANEL: Color = Color(0.1, 0.08, 0.14)
const COLOR_LEG_BORDER: Color = Color(0.95, 0.75, 0.25)
const COLOR_UNAVAILABLE: Color = Color(0.55, 0.55, 0.6)
const LEG_SPRITE_SIZE: Vector2 = Vector2(150, 150)
## Story 020b: side of the art of an item / potion / ball given by an option.
const GAIN_ART_SIDE: float = 56.0
## Story 033: painted backdrops (BattleBackdrop images), illustration side, window widths with / without art.
const BACKDROP_PATTERN: String = "res://assets/art/backdrops/%s.%s"
const BACKDROP_EXTENSIONS: Array[String] = ["jpg", "png"]
const BACKDROP_FALLBACK: String = "route"
const BACKDROP_LEGENDARY: String = "legendary"
## Downscale factor of the backdrop blur (bigger = blurrier) and the darkening veil over it.
const BACKDROP_BLUR: int = 14
const BACKDROP_VEIL: Color = Color(0.04, 0.06, 0.14, 0.42)
const ART_SIDE: float = 330.0
const PANEL_WIDTH_ART: float = 760.0
const OPTION_WIDTH_ART: float = 680.0
const FRAME_LEGENDARY: Color = Color("#D9A520")
static var _blur_cache: Dictionary = {}

var _event: Dictionary = {}
var _info: Label
var _title: Label
var _text: Label
var _options_box: VBoxContainer
var _option_buttons: Array[Button] = []
var _result: Label
var _summary: Label
var _continue_button: Button
var _chosen: int = -1
var _result_shown: bool = false
var _done: bool = false
var _built: bool = false
var _available: Array[bool] = []
var _bg: ColorRect
var _panel_style: StyleBoxFlat
var _leg_caption: Label
var _leg_sprite: TextureRect
var _picker: DeckPicker
## Story 020b: what the run held when the event opened (ids), to show the art of what the chosen option gave.
var _before: Dictionary = {}
var _gains: HBoxContainer
## Story 033: blurred zone backdrop, illustration (spot + picture), main window, and the art kind shown ("" = none).
var _scene: SceneBackdrop
var _art_box: Control
var _art_rect: TextureRect
var _panel: PanelContainer
var _menu_box: MenuBox
var _art_kind: String = ""


func _ready() -> void:
	_build_ui()


## Displays `event` ({id, title, text, options:[{label, ...}]}); `run` is only read for the HP line.
## Story 018: `data` (optional) gives the legendary's sprite; `availability(index) -> bool` (optional, e.g.
## Main.event_option_available) greys out the options that cannot be chosen.
func setup(event: Dictionary, run: RunState, data: GameData = null, availability: Callable = Callable()) -> void:
	_build_ui()
	_event = event
	_chosen = -1
	_result_shown = false
	_done = false
	_picker.close()
	_title.text = String(event.get("title", ""))
	_text.text = String(event.get("text", ""))
	_set_info(run)
	_before = _holdings(run)
	if _gains != null:
		_gains.visible = false
	_apply_legendary_style(event, data)
	_apply_scene(event, run, data)
	for b: Button in _option_buttons:
		_options_box.remove_child(b)
		b.queue_free()
	_option_buttons.clear()
	_available.clear()
	var options: Array = event.get("options", [])
	for i: int in options.size():
		var option: Dictionary = options[i]
		var ok: bool = bool(availability.call(i)) if availability.is_valid() else true
		_available.append(ok)
		var b := Button.new()
		b.name = "Option%d" % i
		b.text = option_text(option, ok)
		b.custom_minimum_size = OPTION_SIZE if _art_kind.is_empty() else Vector2(OPTION_WIDTH_ART, OPTION_SIZE.y)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not ok
		if not ok:
			b.add_theme_color_override("font_disabled_color", UiStyle.DISABLED_TEXT)  # story 033: greyed, readable
			b.tooltip_text = TEXT_NEED_MONEY % RunHud.format_money(int(option.get("requires_money", 0)))
		b.pressed.connect(choose.bind(i))
		_options_box.add_child(b)
		_option_buttons.append(b)
	_result.visible = false
	_summary.visible = false
	_continue_button.visible = false


## Picks option `index` (same path as a click). Ignored after the first choice.
func choose(index: int) -> void:
	if _chosen >= 0 or index < 0 or index >= _option_buttons.size():
		return
	if index < _available.size() and not _available[index]:
		return
	_chosen = index
	for i: int in _option_buttons.size():
		_option_buttons[i].disabled = true
		if i == index:  # story 033: the chosen option stays lit (green button, dark text)
			_option_buttons[i].add_theme_stylebox_override("disabled", UiStyle.button_box("normal", UiStyle.SUCCESS))
			_option_buttons[i].add_theme_color_override("font_disabled_color", UiStyle.TEXT_DARK)
	option_chosen.emit(index)


## Shows the outcome of the chosen option: its result text and the effects summary ("" = no change).
func show_result(result_text: String, summary: String, run: RunState) -> void:
	_result.text = result_text
	_result.visible = true
	_summary.text = summary if not summary.is_empty() else "Rien ne change."
	_summary.visible = true
	_set_info(run)
	_show_gains(run)
	_continue_button.visible = true
	_result_shown = true


## Story 020b: {"items": [ids], "potions": {id: n}, "balls": {id: n}} held by `run`.
static func _holdings(run: RunState) -> Dictionary:
	var h: Dictionary = {"items": [], "potions": {}, "balls": {}}
	if run == null:
		return h
	for it: ItemData in run.items:
		(h["items"] as Array).append(it.id)
	for p: PotionData in run.potions:
		h["potions"][p.id] = int(h["potions"].get(p.id, 0)) + 1
	for bid: String in run.balls.keys():
		h["balls"][bid] = run.ball_count(bid)
	return h


## Story 020b: shows the official art of every held item / potion / ball the option just gave (tooltip = name).
func _show_gains(run: RunState) -> void:
	var now: Dictionary = _holdings(run)
	var gained: Array[String] = []
	for id: String in now["items"]:
		if not (_before.get("items", []) as Array).has(id):
			gained.append(id)
	for key: String in ["potions", "balls"]:
		var was: Dictionary = _before.get(key, {})
		for id: String in (now[key] as Dictionary).keys():
			for k: int in maxi(0, int(now[key][id]) - int(was.get(id, 0))):
				gained.append(id)
	if _gains == null:
		_gains = HBoxContainer.new()
		_gains.name = "Gains"
		_gains.alignment = BoxContainer.ALIGNMENT_CENTER
		_gains.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_gains.add_theme_constant_override("separation", 10)
		_summary.get_parent().add_child(_gains)
		_summary.get_parent().move_child(_gains, _summary.get_index() + 1)
	for child: Node in _gains.get_children():
		_gains.remove_child(child)
		child.queue_free()
	for id: String in gained:
		_gains.add_child(ItemIcon.make(id, GAIN_ART_SIDE))
	_gains.visible = not gained.is_empty()


## Presses "Continuer" (only once the result is shown).
func press_continue() -> void:
	if not _result_shown or _done:
		return
	_done = true
	finished.emit()


## Story 018: opens the deck picker for a pending event card removal (`remaining` cards still to forget). No cancel:
## the removal was part of the chosen option. Main calls it again after each pick while some remain.
func open_removal(run: RunState, data: GameData, remaining: int) -> void:
	_set_info(run)
	_picker.open(TEXT_REMOVE_TITLE % [remaining, "s" if remaining > 1 else ""], TEXT_REMOVE_HINT, run, data,
			func(_i: int) -> bool: return true)
	_picker.set_cancel_visible(false)


## Story 018: closes the removal picker.
func close_removal() -> void:
	_picker.close()


## Story 018: the removal deck picker (QA).
func get_picker() -> DeckPicker:
	return _picker


## Story 018: true if option `index` was offered as available.
func is_option_available(index: int) -> bool:
	return index >= 0 and index < _available.size() and _available[index]


## Story 018: displayed button text of option `index` ("" if none).
func get_option_text(index: int) -> String:
	return _option_buttons[index].text if index >= 0 and index < _option_buttons.size() else ""


## Story 018: the button label of `option`: its label, plus the money hint when the label shows no price, plus the
## reason when it is unavailable.
static func option_text(option: Dictionary, available: bool) -> String:
	var text: String = String(option.get("label", "")).replace("₽", RunHud.CURRENCY)  # one currency sign on screen
	var has_price: bool = text.contains(RunHud.CURRENCY)
	if not has_price:
		var delta: int = 0
		for e: Variant in option.get("effects", []):
			if not (e is Dictionary):
				continue
			match String((e as Dictionary).get("type", "")):
				"gain_money":
					delta += int((e as Dictionary).get("value", 0))
				"lose_money":
					delta -= int((e as Dictionary).get("value", 0))
		if delta != 0:
			text += "  (%s%s)" % ["+" if delta > 0 else "−", RunHud.format_money(absi(delta))]
	if not available:
		text += "  — " + TEXT_NEED_MONEY % RunHud.format_money(int(option.get("requires_money", 0)))
	return text


## The displayed event definition.
func get_event() -> Dictionary:
	return _event


## Chosen option index, -1 before the choice.
func get_chosen_index() -> int:
	return _chosen


## True once the result is displayed.
func is_result_shown() -> bool:
	return _result_shown


## The effects summary line shown after the choice.
func get_summary_text() -> String:
	return _summary.text


func _set_info(run: RunState) -> void:
	_info.text = "PV %d/%d   |   Deck : %d cartes" % [run.hp, run.max_hp, run.deck.size()]


func _build_ui() -> void:
	if _built:
		return
	_built = true
	UiStyle.style_screen(self)  # story 020: art-bible look
	var bg := ColorRect.new()
	_bg = bg
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_scene = SceneBackdrop.new()
	_scene.name = "SceneBackdrop"
	_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scene)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var row := HBoxContainer.new()
	row.name = "SceneRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	center.add_child(row)
	_art_box = ArtSpot.new()
	_art_box.name = "EventArt"
	_art_box.custom_minimum_size = Vector2(ART_SIDE, ART_SIDE)
	_art_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_box.visible = false
	row.add_child(_art_box)
	_art_rect = TextureRect.new()
	_art_rect.name = "ArtPicture"
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_rect.offset_left = 26.0
	_art_rect.offset_top = 20.0
	_art_rect.offset_right = -26.0
	_art_rect.offset_bottom = -32.0
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art_box.add_child(_art_rect)
	var panel := PanelContainer.new()
	_panel = panel
	panel.name = "EventPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()  # kept for callers of the old look; the window draws _menu_box
	sb.bg_color = COLOR_PANEL
	sb.border_color = COLOR_BORDER
	_panel_style = sb
	_menu_box = UiStyle.menu_panel(UiStyle.FRAME_BLUE, 24.0, 18.0)
	panel.add_theme_stylebox_override("panel", _menu_box)
	row.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	_info = CardView.make_label(18)
	box.add_child(_info)
	_leg_caption = CardView.make_label(20)
	_leg_caption.name = "LegendaryCaption"
	_leg_caption.text = TEXT_LEGENDARY
	_leg_caption.add_theme_color_override("font_color", COLOR_LEG_BORDER)
	_leg_caption.visible = false
	box.add_child(_leg_caption)
	_leg_sprite = TextureRect.new()
	_leg_sprite.name = "LegendarySprite"
	_leg_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_leg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_leg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_leg_sprite.custom_minimum_size = LEG_SPRITE_SIZE
	_leg_sprite.visible = false
	box.add_child(_leg_sprite)
	_title = CardView.make_label(40)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	box.add_child(_title)
	_text = _make_wrapped_label(22)
	box.add_child(_text)
	_options_box = VBoxContainer.new()
	_options_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_box.add_theme_constant_override("separation", 12)
	box.add_child(_options_box)
	_result = _make_wrapped_label(22)
	_result.name = "Result"
	box.add_child(_result)
	_summary = CardView.make_label(24)
	_summary.name = "Summary"
	_summary.add_theme_color_override("font_color", COLOR_SUMMARY)
	box.add_child(_summary)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continuer"
	_continue_button.custom_minimum_size = Vector2(220, 52)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.pressed.connect(press_continue)
	box.add_child(_continue_button)
	_picker = DeckPicker.new()
	_picker.card_picked.connect(_on_removal_picked)
	add_child(_picker)


func _on_removal_picked(deck_index: int) -> void:
	removal_picked.emit(deck_index)


## Story 018: dark/gold frame, caption and large sprite for legendary events; the normal look otherwise.
func _apply_legendary_style(event: Dictionary, data: GameData) -> void:
	var legendary: bool = bool(event.get("legendary", false))
	_bg.color = COLOR_LEG_BG if legendary else COLOR_BG
	_panel_style.bg_color = COLOR_LEG_PANEL if legendary else COLOR_PANEL
	_panel_style.border_color = COLOR_LEG_BORDER if legendary else COLOR_BORDER
	_panel_style.set_border_width_all(5 if legendary else 3)
	_menu_box.frame_color = FRAME_LEGENDARY if legendary else UiStyle.FRAME_BLUE  # story 033: gold frame
	_leg_caption.visible = legendary
	# Story 033: the legendary is the big illustration beside the window (_apply_scene); no small sprite inside it.
	_leg_sprite.texture = null
	_leg_sprite.visible = false
	_text.add_theme_font_size_override("font_size", 21 if legendary else 22)


## The legendary Pokémon of a legendary event: the first enemy of its start_fight encounter ("" if none).
static func _legendary_pokemon_id(event: Dictionary, data: GameData) -> String:
	for option: Variant in event.get("options", []):
		for e: Variant in (option as Dictionary).get("effects", []):
			if e is Dictionary and String((e as Dictionary).get("type", "")) == "start_fight":
				var ids: Array[String] = data.get_encounter_enemy_ids(String((e as Dictionary).get("encounter", "")))
				if not ids.is_empty():
					return ids[0]
	return ""


func _make_wrapped_label(font_size: int) -> Label:
	var l: Label = CardView.make_label(font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_WIDTH - 72, 0)
	return l


## Story 033: zone backdrop + illustration for `event`; the window narrows when there is an illustration.
func _apply_scene(event: Dictionary, run: RunState, data: GameData) -> void:
	var legendary: bool = bool(event.get("legendary", false))
	var backdrop_id: String = BACKDROP_LEGENDARY if legendary else ""
	if backdrop_id.is_empty() and run != null:
		backdrop_id = String(run.current_zone().get("type_id", ""))
	_scene.set_texture(blurred_backdrop(backdrop_id))
	var tex: Texture2D = null
	var kind: String = ""
	var art: Variant = event.get("art", {})
	var art_d: Dictionary = art if art is Dictionary else {}
	var pokemon_id: String = ""
	if art_d.has("item"):
		tex = ItemIcon.texture_for(String(art_d["item"]))
		kind = "item" if tex != null else ""
	elif art_d.has("pokemon"):
		tex = PokemonArt.texture_for(String(art_d["pokemon"]))
		kind = "pokemon" if tex != null else ""
	elif bool(art_d.get("rival", false)) and run != null and data != null and not run.rival_name.is_empty():
		pokemon_id = run.rival_current_form(data)
	if tex == null and pokemon_id.is_empty() and legendary and data != null:
		pokemon_id = _legendary_pokemon_id(event, data)
	if tex == null and not pokemon_id.is_empty() and data != null:
		tex = PokemonArt.texture_for_sprite(String(data.get_pokemon_info(pokemon_id).get("sprite_path", "")))
		kind = "pokemon" if tex != null else ""
	_art_kind = kind
	_art_rect.texture = tex
	_art_box.visible = tex != null
	(_art_box as ArtSpot).glow = FRAME_LEGENDARY if legendary else Color.WHITE
	_art_box.queue_redraw()
	var w: float = PANEL_WIDTH_ART if tex != null else PANEL_WIDTH
	_panel.custom_minimum_size = Vector2(w, 0)
	for l: Label in [_text, _result]:
		l.custom_minimum_size = Vector2(w - 72, 0)


## Story 033: what the event illustration shows: "pokemon", "item" or "" (none). QA.
func get_art_kind() -> String:
	return _art_kind


## Story 033: the painted battle backdrop `backdrop_id` (fallback route), blurred (downscaled then smoothly upscaled)
## for the event background. Cached; null when no image exists.
static func blurred_backdrop(backdrop_id: String) -> Texture2D:
	var id: String = backdrop_id if not backdrop_id.is_empty() else BACKDROP_FALLBACK
	if _blur_cache.has(id):
		return _blur_cache[id]
	var src: Texture2D = null
	for candidate: String in [id, BACKDROP_FALLBACK]:
		for ext: String in BACKDROP_EXTENSIONS:
			var path: String = BACKDROP_PATTERN % [candidate, ext]
			if src == null and ResourceLoader.exists(path):
				src = load(path) as Texture2D
	var out: Texture2D = null
	if src != null:
		var img: Image = src.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var w: int = img.get_width()
			var h: int = img.get_height()
			img.resize(maxi(8, w / BACKDROP_BLUR), maxi(8, h / BACKDROP_BLUR), Image.INTERPOLATE_BILINEAR)
			img.resize(maxi(16, w / 3), maxi(16, h / 3), Image.INTERPOLATE_CUBIC)
			out = ImageTexture.create_from_image(img)
	_blur_cache[id] = out
	return out


## Story 033: full-screen blurred painted backdrop (cover-fit) under a dark veil. Display only.
class SceneBackdrop extends Control:
	var _tex: Texture2D

	## Sets the (blurred) image; null = only the veil over the screen's backdrop.
	func set_texture(tex: Texture2D) -> void:
		_tex = tex
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		var ts: Vector2 = _tex.get_size()
		var k: float = maxf(size.x / ts.x, size.y / ts.y)
		var ds: Vector2 = ts * k
		draw_texture_rect(_tex, Rect2((size - ds) * 0.5, ds), false)
		draw_rect(Rect2(Vector2.ZERO, size), EventScreen.BACKDROP_VEIL)


## Story 033: the soft light spot the event illustration stands on (radial glow + ground shadow). Display only.
class ArtSpot extends Control:
	var glow: Color = Color.WHITE

	func _draw() -> void:
		var c: Vector2 = size * Vector2(0.5, 0.47)
		var r: float = minf(size.x, size.y) * 0.5
		for i: int in 12:
			var f: float = 1.0 - float(i) / 12.0
			draw_circle(c, r * f, Color(glow, 0.05 + 0.02 * float(i)))
		var foot := Vector2(size.x * 0.5, size.y - 26.0)
		var pts := PackedVector2Array()
		for i: int in 32:
			var a: float = TAU * float(i) / 32.0
			pts.append(foot + Vector2(cos(a) * r * 0.55, sin(a) * 12.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.28))
