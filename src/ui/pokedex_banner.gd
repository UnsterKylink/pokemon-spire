class_name PokedexBanner
extends Control
## Story 025 (story-025-pokedex): the short banner « Palier du Pokédex débloqué : <nom> » shown at the top of the screen
## when a Pokédex milestone (pokedex_rewards.json) is reached during a run (on the capture, or on the next screen when
## the capture happened in a battle). Owned by Main, drawn above every screen, never takes the mouse; fades out after
## PokedexRewards.banner_seconds. Display only.

const TEXT_TITLE: String = "Palier du Pokédex débloqué : %s"
const TEXT_NEXT_RUN: String = "%s Actif dès la prochaine partie."
const WIDTH: float = 760.0
const TOP: float = 70.0
const FADE_SECONDS: float = 0.35

var _panel: PanelContainer
var _title: Label
var _body: Label
var _tween: Tween
var _texts: PackedStringArray = PackedStringArray()


func _init() -> void:
	name = "PokedexBanner"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mb: MenuBox = UiStyle.menu_panel(UiStyle.ACCENT_YELLOW, 22.0, 12.0)
	_panel.add_theme_stylebox_override("panel", mb)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -WIDTH * 0.5
	_panel.offset_right = WIDTH * 0.5
	_panel.offset_top = TOP
	add_child(_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)
	_title = CardView.make_label(22)
	_title.name = "Title"
	_title.add_theme_font_override("font", UiStyle.font_title())
	_title.add_theme_color_override("font_color", UiStyle.TEXT_DARK)
	_title.add_theme_constant_override("outline_size", 0)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_body = CardView.make_label(17)
	_body.name = "Body"
	_body.add_theme_color_override("font_color", UiStyle.TEXT_SUB)
	_body.add_theme_constant_override("outline_size", 0)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)


## Shows the banner for `milestones` (PokedexRewards entries: name, description) for `seconds` (<= 0 = stays until
## hide_banner, QA shots). Several milestones at once are joined on one line.
func show_milestones(milestones: Array[Dictionary], seconds: float) -> void:
	if milestones.is_empty():
		return
	var names: PackedStringArray = PackedStringArray()
	var descs: PackedStringArray = PackedStringArray()
	for m: Dictionary in milestones:
		names.append(String(m.get("name", "")))
		descs.append(String(m.get("description", "")))
	_title.text = TEXT_TITLE % ", ".join(names)
	_body.text = TEXT_NEXT_RUN % " ".join(descs)
	_texts = PackedStringArray([_title.text, _body.text])
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = true
	modulate.a = 1.0
	if seconds <= 0.0:
		return
	_tween = create_tween()
	_tween.tween_interval(seconds)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(hide_banner)


## Hides the banner at once.
func hide_banner() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	_texts = PackedStringArray()


## Texts on show (title, body) — empty when hidden (QA).
func get_texts() -> PackedStringArray:
	return _texts.duplicate() if visible else PackedStringArray()
