class_name BattleScreen
extends Control
## Playable battle screen (mouse only). UI is built from containers in code; all logic lives in Battle.
## Implements: story-001-combat-de-base (écran jouable), story-002-intentions-et-multi-ennemis,
## story-003-types (type badges, "Super efficace !" feedback),
## story-009-cartes-pokemon-switch (active Pokémon on the left, "<Nom>, à toi !", cards show their Pokémon).
## Story 006: potions are drunk through use_potion (the slots live in Main's RunHud); held-item triggers and
## potions show a short floating text over the active Pokémon; the "Attaque +" turn bonus shows in the info row.
## Story 004: the screen no longer owns game state; Main gives it a Battle (built from RunState) via
## setup() and listens to battle_won / defeat_acknowledged.
## Interaction: click an attack card to select it, then click a living enemy; skill cards play on click.

## Emitted when the player wins; carries the ids of the enemies of this battle (all defeated).
signal battle_won(defeated_ids: Array[String])
## Emitted by the "Continuer" button of the defeat overlay (story 007: Main then shows the defeat summary).
signal defeat_acknowledged

const SPRITE_SOURCE_SIZE: float = 96.0
## Enemy sprite scale by number of enemies (index 0 = 1 enemy). Chosen so 3 enemies fit 1280x720.
## Story 006: scales lowered (2.5 -> 2.0) so the arena still fits under the RunHud bar.
const ENEMY_SPRITE_SCALES: Array[float] = [2.0, 2.0, 1.6]
const PLAYER_SPRITE_SCALE: float = 2.0
const CARD_SIZE: Vector2 = Vector2(170, 200)
## Hand layout: normal / tight card spacing and the usable width (1280 minus side margins).
const HAND_SEPARATION: int = 12
const HAND_SEPARATION_TIGHT: int = 6
const HAND_MAX_WIDTH: float = 1240.0
const COLOR_HP_PLAYER: Color = Color(0.3, 0.8, 0.35)
const COLOR_HP_ENEMY: Color = Color(0.9, 0.3, 0.3)
const COLOR_ATTACK: Color = Color(0.85, 0.35, 0.3)
const COLOR_SKILL: Color = Color(0.35, 0.6, 0.95)
const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_SELECTED: Color = Color(1.0, 0.85, 0.3)
const COLOR_INTENT_ATTACK: Color = Color(1.0, 0.4, 0.35)
const COLOR_INTENT_BLOCK: Color = Color(0.4, 0.7, 1.0)
const COLOR_INTENT_BUFF: Color = Color(1.0, 0.9, 0.3)
const COLOR_KO: Color = Color(0.6, 0.6, 0.6)
const MODULATE_KO: Color = Color(0.45, 0.45, 0.45, 0.55)
const MODULATE_TARGETABLE: Color = Color(1.0, 0.9, 0.6)
const COLOR_TEXT_LIGHT: Color = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.1, 0.1, 0.12)
const COLOR_SUPER_EFFECTIVE: Color = Color(0.35, 1.0, 0.4)
const COLOR_NOT_VERY_EFFECTIVE: Color = Color(0.72, 0.72, 0.76)
const TEXT_SUPER_EFFECTIVE: String = "Super efficace !"
const TEXT_NOT_VERY_EFFECTIVE: String = "Ce n'est pas très efficace…"
## %s = display name of the immune target (story 008).
const TEXT_IMMUNE: String = "Ça n'affecte pas %s…"
const COLOR_IMMUNE: Color = Color(0.55, 0.58, 0.68)
## Effectiveness feedback: total visible time (s), final fade (s), upward drift (px).
const FLOAT_DURATION: float = 1.2
const FLOAT_FADE: float = 0.4
const FLOAT_RISE: float = 24.0
const FLOAT_SCREEN_MARGIN: float = 8.0
const FLOAT_FONT_SIZE: int = 22
## Story 009: caption above the active Pokémon, switch feedback (%s = Pokémon name).
const TEXT_ACTIVE_CAPTION: String = "Pokémon actif"
const TEXT_SWITCH: String = "%s, à toi !"
const COLOR_SWITCH: Color = Color(1.0, 0.85, 0.35)
const COLOR_ACTIVE_CAPTION: Color = Color(0.7, 0.72, 0.82)
## Story 006: item / potion feedback ("Bandeau !" / "Potion : Attaque +"), shown mid-sprite / low on the sprite.
const TEXT_ITEM: String = "%s !"
const TEXT_POTION: String = "Potion : %s"
const TEXT_TURN_BONUS: String = "Attaque +%d ce tour"
const COLOR_ITEM: Color = Color(1.0, 0.72, 0.35)
const COLOR_POTION: Color = Color(0.55, 0.85, 1.0)
const ITEM_FLOAT_Y: float = 0.42
const POTION_FLOAT_Y: float = 0.7


## A floating feedback label and its running tween (one per target, reused).
class FloatText extends RefCounted:
	var label: Label
	var tween: Tween
	## Bumped on every show/hide so a deferred show that was superseded does nothing.
	var serial: int = 0


## Widgets of one enemy slot (typed refs, no find_child).
class EnemyView extends RefCounted:
	var panel: VBoxContainer
	var name_label: Label
	var intent_label: Label
	var sprite: TextureRect
	var hp_bar: ProgressBar
	var hp_label: Label
	var block_label: Label
	var type_badge: HBoxContainer
	var float_text: FloatText


var _battle: Battle
var _selected_index: int = -1
var _deck_size: int = 0
var _encounter_id: String = ""

var _data: GameData

var _background: ColorRect
var _player_name: Label
var _player_type_badge: HBoxContainer
var _player_float: FloatText
var _switch_float: FloatText
var _item_float: FloatText
var _potion_float: FloatText
var _pending_items: Array[String] = []
var _player_caption: Label
var _float_layer: Control
var _player_sprite: TextureRect
var _player_hp_bar: ProgressBar
var _player_hp_label: Label
var _player_block: Label
var _enemies_box: HBoxContainer
var _enemy_views: Array[EnemyView] = []
var _encounter_label: Label
var _energy_label: Label
var _draw_label: Label
var _discard_label: Label
var _deck_label: Label
var _end_turn_button: Button
var _hand_box: HBoxContainer
var _end_box: VBoxContainer
var _end_dim: ColorRect
var _message_label: Label
var _restart_button: Button
var _hint_label: Label


func _ready() -> void:
	_build_ui()


## Read-only access for the QA harness.
func get_battle() -> Battle:
	return _battle


## Index of the selected hand card, or -1.
func get_selected_index() -> int:
	return _selected_index


## Id of the encounter currently being played.
func get_encounter_id() -> String:
	return _encounter_id


## Text of the effectiveness label currently shown over enemy enemy_index ("" if none).
func get_enemy_float_text(enemy_index: int) -> String:
	if enemy_index < 0 or enemy_index >= _enemy_views.size():
		return ""
	return _visible_float_text(_enemy_views[enemy_index].float_text)


## Text of the effectiveness label currently shown over the player ("" if none).
func get_player_float_text() -> String:
	return _visible_float_text(_player_float)


## Text of the "<Nom>, à toi !" label currently shown over the active Pokémon ("" if none).
func get_switch_float_text() -> String:
	return _visible_float_text(_switch_float)


## Text of the held-item feedback currently shown ("" if none).
func get_item_float_text() -> String:
	return _visible_float_text(_item_float)


## Text of the potion feedback currently shown ("" if none).
func get_potion_float_text() -> String:
	return _visible_float_text(_potion_float)


## Drinks potion `index` of the battle (player's turn only, no energy cost). False if not possible.
func use_potion(index: int) -> bool:
	if _battle == null or not _battle.can_use_potion(index):
		return false
	_selected_index = -1
	return _battle.use_potion(index)


## Displays `battle` (built by Main from RunState) and starts it. Call once, after add_child.
## `run` is only read, for the deck size shown in the info row.
func setup(battle: Battle, data: GameData, run: RunState, encounter_id: String) -> void:
	_data = data
	_battle = battle
	_deck_size = run.deck.size()
	_selected_index = -1
	_encounter_id = encounter_id
	var player: Combatant = _battle.player
	_build_enemy_views(_battle.enemies)
	_hide_float(_player_float)
	_hide_float(_switch_float)
	_hide_float(_item_float)
	_hide_float(_potion_float)
	_pending_items.clear()
	_end_box.visible = false
	_end_dim.visible = false
	_battle.state_changed.connect(_refresh)
	_battle.hit_resolved.connect(_on_hit_resolved)
	_battle.battle_won.connect(_on_battle_won)
	_battle.active_pokemon_changed.connect(_on_active_pokemon_changed)
	_battle.item_triggered.connect(_on_item_triggered)
	_battle.potion_used.connect(_on_potion_used)
	_battle.start()
	_refresh_active_pokemon(player)
	_refresh()


## Presses "Continuer" on the defeat overlay (QA harness / button). Ignored unless the battle is lost.
func press_defeat_continue() -> void:
	if _battle != null and _battle.state == Battle.State.LOST:
		defeat_acknowledged.emit()


## Old name of press_defeat_continue (the button was "Rejouer" before story 007).
func press_restart() -> void:
	press_defeat_continue()


func _on_battle_won() -> void:
	var ids: Array[String] = []
	for e: Combatant in _battle.enemies:
		ids.append(e.id)
	battle_won.emit(ids)


## Selects (or deselects if already selected) hand card index; cards without target play immediately.
func select_card(index: int) -> void:
	if _battle == null or not _battle.can_play(index):
		return
	var card: CardData = _battle.hand[index]
	if not card.needs_target():
		_selected_index = -1
		_battle.play_card(index)
		return
	_selected_index = -1 if _selected_index == index else index
	_refresh()


## Clicks enemy enemy_index: plays the selected attack card on it, if any. Dead enemies ignore clicks.
func click_enemy(enemy_index: int) -> void:
	if _battle == null or _selected_index < 0 or not _battle.is_valid_target(enemy_index):
		return
	var index: int = _selected_index
	_selected_index = -1
	if not _battle.play_card(index, enemy_index):
		_refresh()


## Plays hand card index directly (QA harness, bypasses selection). Targets enemy_index,
## or the first living enemy when -1.
func play_card_direct(index: int, enemy_index: int = -1) -> bool:
	_selected_index = -1
	if _battle == null:
		return false
	var target: int = enemy_index if enemy_index >= 0 else _battle.first_living_enemy()
	return _battle.play_card(index, target)


## QA-ONLY: replaces the hand with the given card ids (and refills energy) so a walkthrough
## can stage a matchup. Never called by the game itself.
func qa_force_hand(card_ids: Array[String]) -> void:
	if _battle == null:
		return
	_battle.hand.clear()
	for cid: String in card_ids:
		var c: CardData = _data.get_card(cid)
		if c != null:
			_battle.hand.append(c)
	_battle.energy = _battle.max_energy
	_selected_index = -1
	_refresh()


## Presses the "Fin de tour" button.
func press_end_turn() -> void:
	if _battle == null:
		return
	_selected_index = -1
	_battle.end_turn()


## Clicks empty background: deselects.
func click_background() -> void:
	_selected_index = -1
	_refresh()


# --- UI construction -------------------------------------------------------

func _build_ui() -> void:
	_background = ColorRect.new()
	_background.color = COLOR_BG
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	_background.gui_input.connect(_on_background_input)
	add_child(_background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	# Arena: player left, enemies (1..3) right.
	var arena := HBoxContainer.new()
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(arena)

	var player_box := VBoxContainer.new()
	player_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER
	player_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(player_box)
	_player_caption = _make_label(16)
	_player_caption.text = TEXT_ACTIVE_CAPTION
	_player_caption.add_theme_color_override("font_color", COLOR_ACTIVE_CAPTION)
	player_box.add_child(_player_caption)
	_player_name = _make_label(28)
	player_box.add_child(_player_name)
	_player_type_badge = CardView.make_type_badge_row()
	player_box.add_child(_player_type_badge)
	_player_sprite = _make_sprite_holder("PlayerSprite", PLAYER_SPRITE_SCALE)
	player_box.add_child(_player_sprite)
	_player_hp_bar = _make_hp_bar(COLOR_HP_PLAYER, PLAYER_SPRITE_SCALE)
	player_box.add_child(_player_hp_bar)
	_player_hp_label = _make_label(18)
	player_box.add_child(_player_hp_label)
	_player_block = _make_label(20)
	_player_block.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	player_box.add_child(_player_block)

	_enemies_box = HBoxContainer.new()
	_enemies_box.name = "EnemiesBox"
	_enemies_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemies_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemies_box.size_flags_stretch_ratio = 2.0
	_enemies_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemies_box.add_theme_constant_override("separation", 8)
	arena.add_child(_enemies_box)

	# Info row.
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 24)
	root.add_child(info)
	_encounter_label = _make_label(20)
	_encounter_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	info.add_child(_encounter_label)
	_energy_label = _make_label(26)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_energy_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	info.add_child(_energy_label)
	_draw_label = _make_label(18)
	info.add_child(_draw_label)
	_discard_label = _make_label(18)
	info.add_child(_discard_label)
	_deck_label = _make_label(18)
	info.add_child(_deck_label)
	_hint_label = _make_label(18)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_hint_label)
	_end_turn_button = Button.new()
	_end_turn_button.text = "Fin de tour"
	_end_turn_button.custom_minimum_size = Vector2(160, 48)
	_end_turn_button.pressed.connect(press_end_turn)
	info.add_child(_end_turn_button)

	# Hand.
	_hand_box = HBoxContainer.new()
	_hand_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_box.custom_minimum_size = Vector2(0, CARD_SIZE.y + 10)
	_hand_box.add_theme_constant_override("separation", 12)
	root.add_child(_hand_box)

	# End-of-battle overlay: dim the arena so the message stays readable.
	_end_dim = ColorRect.new()
	_end_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_end_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_dim.visible = false
	add_child(_end_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_end_box = VBoxContainer.new()
	_end_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_box.visible = false
	center.add_child(_end_box)
	_message_label = _make_label(64)
	_message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_message_label.add_theme_constant_override("outline_size", 12)
	_end_box.add_child(_message_label)
	_restart_button = Button.new()
	_restart_button.text = "Continuer"
	_restart_button.custom_minimum_size = Vector2(200, 56)
	_restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_restart_button.pressed.connect(press_defeat_continue)
	_end_box.add_child(_restart_button)

	# Floating feedback layer (never intercepts the mouse). It sits just below the
	# end-of-battle dim so the Victoire / Défaite message always stays on top.
	_float_layer = Control.new()
	_float_layer.name = "FloatLayer"
	_float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float_layer)
	move_child(_float_layer, _end_dim.get_index())
	_player_float = _make_float_text()
	_switch_float = _make_float_text()
	_item_float = _make_float_text()
	_potion_float = _make_float_text()


func _make_label(font_size: int) -> Label:
	return CardView.make_label(font_size)


func _make_type_badge(font_size: int = 16) -> PanelContainer:
	return CardView.make_type_badge(font_size)


func _set_badge_row(row: HBoxContainer, type_ids: Array[String]) -> void:
	CardView.set_badge_row(row, type_ids, _data.get_type_chart())


func _make_float_text() -> FloatText:
	var f := FloatText.new()
	f.label = _make_label(FLOAT_FONT_SIZE)
	f.label.add_theme_color_override("font_outline_color", Color.BLACK)
	f.label.add_theme_constant_override("outline_size", 8)
	f.label.visible = false
	_float_layer.add_child(f.label)
	return f


func _make_hp_bar(fill_color: Color, sprite_scale: float) -> ProgressBar:
	var bar := ProgressBar.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.25)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(SPRITE_SOURCE_SIZE * sprite_scale, 20)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return bar


func _make_sprite_holder(node_name: String, sprite_scale: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2.ONE * SPRITE_SOURCE_SIZE * sprite_scale
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return tr


## Rebuilds the enemy slots for a new battle (scale depends on the enemy count).
func _build_enemy_views(enemies: Array[Combatant]) -> void:
	for child: Node in _enemies_box.get_children():
		_enemies_box.remove_child(child)
		child.queue_free()
	for old: EnemyView in _enemy_views:
		_free_float(old.float_text)
	_enemy_views.clear()
	var scale_index: int = clampi(enemies.size(), 1, ENEMY_SPRITE_SCALES.size()) - 1
	var sprite_scale: float = ENEMY_SPRITE_SCALES[scale_index]
	for i: int in enemies.size():
		var v := EnemyView.new()
		v.panel = VBoxContainer.new()
		v.panel.name = "Enemy%d" % i
		v.panel.mouse_filter = Control.MOUSE_FILTER_STOP  # receives the click that plays the card
		v.panel.alignment = BoxContainer.ALIGNMENT_CENTER
		v.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.panel.gui_input.connect(_on_enemy_input.bind(i))
		_enemies_box.add_child(v.panel)
		v.name_label = _make_label(24)
		v.name_label.text = enemies[i].display_name
		v.panel.add_child(v.name_label)
		v.type_badge = CardView.make_type_badge_row()
		_set_badge_row(v.type_badge, enemies[i].type_ids)
		v.panel.add_child(v.type_badge)
		v.intent_label = _make_label(22)
		v.panel.add_child(v.intent_label)
		v.sprite = _make_sprite_holder("EnemySprite%d" % i, sprite_scale)
		v.sprite.texture = _load_texture(enemies[i].sprite_path)
		v.panel.add_child(v.sprite)
		v.hp_bar = _make_hp_bar(COLOR_HP_ENEMY, sprite_scale)
		v.panel.add_child(v.hp_bar)
		v.hp_label = _make_label(18)
		v.panel.add_child(v.hp_label)
		v.block_label = _make_label(18)
		v.block_label.add_theme_color_override("font_color", COLOR_INTENT_BLOCK)
		v.panel.add_child(v.block_label)
		v.float_text = _make_float_text()
		_enemy_views.append(v)


# --- Active Pokémon (story 009) ------------------------------------------------

## Shows the active Pokémon (battle.player identity: name, type badges, sprite) on the left.
func _refresh_active_pokemon(p: Combatant) -> void:
	_player_name.text = p.display_name
	_set_badge_row(_player_type_badge, p.type_ids)
	_player_sprite.texture = _load_texture(p.sprite_path)


## A card brought another Pokémon in (fired before the hit): update the left panel, show
## "<Nom>, à toi !" over it (never blocks input) and redraw the enemy intents (recomputed by Battle).
func _on_active_pokemon_changed(_old_id: String, _new_id: String) -> void:
	var p: Combatant = _battle.player
	_refresh_active_pokemon(p)
	_show_float(_switch_float, _player_sprite, TEXT_SWITCH % p.display_name, COLOR_SWITCH)
	for i: int in _enemy_views.size():
		_refresh_enemy(_enemy_views[i], _battle.enemies[i])


# --- Item / potion feedback (story 006) ------------------------------------------

## Several items can fire on the same action (e.g. Bandeau + Lunettes Choix): their names are gathered and
## shown once, at the end of the frame.
func _on_item_triggered(item: ItemData) -> void:
	if _pending_items.is_empty():
		_flush_item_float.call_deferred()
	if not _pending_items.has(item.display_name):
		_pending_items.append(item.display_name)


func _flush_item_float() -> void:
	if _pending_items.is_empty() or not is_inside_tree():
		return
	var text: String = "  ".join(_pending_items.map(func(n: String) -> String: return TEXT_ITEM % n))
	_pending_items.clear()
	_show_float(_item_float, _player_sprite, text, COLOR_ITEM, ITEM_FLOAT_Y)


func _on_potion_used(potion: PotionData) -> void:
	_show_float(_potion_float, _player_sprite, TEXT_POTION % potion.display_name, COLOR_POTION, POTION_FLOAT_Y)


# --- Effectiveness feedback ------------------------------------------------

func _on_hit_resolved(target: Combatant, _amount: int, multiplier: float) -> void:
	if is_equal_approx(multiplier, 1.0):
		return
	var f: FloatText = null
	var anchor: Control = null
	if target == _battle.player:
		f = _player_float
		anchor = _player_sprite
	else:
		var idx: int = _battle.enemies.find(target)
		if idx < 0 or idx >= _enemy_views.size():
			return
		f = _enemy_views[idx].float_text
		anchor = _enemy_views[idx].sprite
	var text: String = TEXT_SUPER_EFFECTIVE
	var color: Color = COLOR_SUPER_EFFECTIVE
	if multiplier <= 0.0:
		text = TEXT_IMMUNE % target.display_name
		color = COLOR_IMMUNE
	elif multiplier < 1.0:
		text = TEXT_NOT_VERY_EFFECTIVE
		color = COLOR_NOT_VERY_EFFECTIVE
	_show_float(f, anchor, text, color)


## Shows the floating label over `anchor` for FLOAT_DURATION s (drifts up, fades at the end).
## `y_ratio` = start height inside the anchor (0 = its top). Any previous tween of the same label is killed
## first; nothing here blocks input or logic.
func _show_float(f: FloatText, anchor: Control, text: String, color: Color, y_ratio: float = 0.0) -> void:
	if f.tween != null and f.tween.is_valid():
		f.tween.kill()
	f.label.text = text
	f.label.add_theme_color_override("font_color", color)
	f.serial += 1
	var my_serial: int = f.serial
	f.label.visible = false
	# Wait one frame so container layout has settled (e.g. right after a new encounter
	# rebuilt the enemy slots); otherwise the anchor rect is stale.
	await get_tree().process_frame
	if not is_inside_tree() or my_serial != f.serial or not is_instance_valid(f.label) or not is_instance_valid(anchor):
		return
	f.label.modulate = Color.WHITE
	f.label.visible = true
	f.label.reset_size()
	var r: Rect2 = anchor.get_global_rect()
	var start: Vector2 = Vector2(r.get_center().x - f.label.size.x * 0.5, r.position.y + 8.0 + r.size.y * y_ratio)
	# Keep the whole text on screen (the rightmost enemy slot is near the edge).
	var screen_w: float = get_viewport_rect().size.x
	start.x = clampf(start.x, FLOAT_SCREEN_MARGIN, maxf(FLOAT_SCREEN_MARGIN, screen_w - f.label.size.x - FLOAT_SCREEN_MARGIN))
	f.label.global_position = start
	f.tween = f.label.create_tween()
	f.tween.set_parallel(true)
	f.tween.tween_property(f.label, "global_position:y", start.y - FLOAT_RISE, FLOAT_DURATION)
	f.tween.tween_property(f.label, "modulate:a", 0.0, FLOAT_FADE).set_delay(FLOAT_DURATION - FLOAT_FADE)
	f.tween.chain().tween_callback(f.label.hide)


func _hide_float(f: FloatText) -> void:
	if f == null:
		return
	f.serial += 1
	if f.tween != null and f.tween.is_valid():
		f.tween.kill()
	f.label.visible = false


func _free_float(f: FloatText) -> void:
	if f == null:
		return
	_hide_float(f)
	f.label.queue_free()


func _visible_float_text(f: FloatText) -> String:
	if f == null or not f.label.visible:
		return ""
	return f.label.text


func _load_texture(path: String) -> Texture2D:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_error("BattleScreen: cannot load sprite %s" % path)
	return tex


func _intent_color(intent: EnemyIntent) -> Color:
	match intent.type:
		EnemyIntent.TYPE_ATTACK:
			return COLOR_INTENT_ATTACK
		EnemyIntent.TYPE_BLOCK:
			return COLOR_INTENT_BLOCK
	return COLOR_INTENT_BUFF


# --- Refresh ---------------------------------------------------------------

func _refresh() -> void:
	if _battle == null:
		return
	var p: Combatant = _battle.player
	_player_hp_bar.max_value = p.max_hp
	_player_hp_bar.value = p.hp
	_player_hp_label.text = "PV %d/%d" % [p.hp, p.max_hp]
	_player_block.text = "Protection %d" % p.block
	var count: int = _battle.enemies.size()
	_encounter_label.text = "Combat : %d ennemi%s" % [count, "s" if count > 1 else ""]
	_energy_label.text = "Énergie %d/%d" % [_battle.energy, _battle.max_energy]
	_draw_label.text = "Pioche : %d" % _battle.draw_pile.size()
	_discard_label.text = "Défausse : %d" % _battle.discard_pile.size()
	_deck_label.text = "Deck : %d cartes" % _deck_size

	var over: bool = _battle.state != Battle.State.PLAYER_TURN
	_end_turn_button.disabled = over
	_hint_label.text = "Choisissez une cible" if _selected_index >= 0 else ""
	if _selected_index < 0 and _battle.turn_damage_bonus > 0 and not over:
		_hint_label.text = TEXT_TURN_BONUS % _battle.turn_damage_bonus
	for i: int in _enemy_views.size():
		_refresh_enemy(_enemy_views[i], _battle.enemies[i])
	_rebuild_hand()
	# Victory goes straight to the reward screen (Main); the overlay is for defeat only.
	if _battle.state == Battle.State.LOST:
		_end_box.visible = true
		_end_dim.visible = true
		_message_label.text = "Défaite…"


func _refresh_enemy(v: EnemyView, e: Combatant) -> void:
	v.hp_bar.max_value = e.max_hp
	v.hp_bar.value = e.hp
	v.hp_label.text = "PV %d/%d" % [e.hp, e.max_hp]
	v.block_label.text = "Protection %d" % e.block if e.block > 0 else ""
	if e.is_alive() and e.intent != null and _battle.state == Battle.State.PLAYER_TURN:
		v.intent_label.text = e.intent.display_text()
		v.intent_label.add_theme_color_override("font_color", _intent_color(e.intent))
	elif e.is_alive():
		v.intent_label.text = ""
	else:
		v.intent_label.text = "K.O."
		v.intent_label.add_theme_color_override("font_color", COLOR_KO)
	if not e.is_alive():
		v.panel.modulate = MODULATE_KO
	elif _selected_index >= 0:
		v.panel.modulate = MODULATE_TARGETABLE
	else:
		v.panel.modulate = Color.WHITE


func _rebuild_hand() -> void:
	for child: Node in _hand_box.get_children():
		_hand_box.remove_child(child)
		child.queue_free()
	var n: int = _battle.hand.size()
	# Large hands (badge / item draw bonuses): tighten spacing, then narrow the cards to fit the width.
	var sep: int = HAND_SEPARATION if n <= 6 else HAND_SEPARATION_TIGHT
	_hand_box.add_theme_constant_override("separation", sep)
	var card_size: Vector2 = CARD_SIZE
	if n > 0:
		var fit_w: float = floorf((HAND_MAX_WIDTH - sep * (n - 1)) / float(n))
		card_size.x = minf(CARD_SIZE.x, fit_w)
	for i: int in n:
		var card: CardData = _battle.hand[i]
		var b := Button.new()
		b.custom_minimum_size = card_size
		_fill_card_content(b, card)
		b.disabled = not _battle.can_play(i)
		var kind_color: Color = COLOR_SKILL if card.kind == CardData.KIND_SKILL else COLOR_ATTACK
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.18, 0.24)
		sb.set_border_width_all(3)
		sb.border_color = kind_color
		sb.set_corner_radius_all(6)
		if i == _selected_index:
			sb.bg_color = Color(0.35, 0.3, 0.1)
			sb.set_border_width_all(5)
			sb.border_color = COLOR_SELECTED
		var sb_hover: StyleBoxFlat = sb.duplicate()
		sb_hover.bg_color = sb.bg_color.lightened(0.12)
		var sb_disabled: StyleBoxFlat = sb.duplicate()
		sb_disabled.bg_color = Color(0.13, 0.13, 0.16)
		sb_disabled.border_color = kind_color.darkened(0.5)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb_hover)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_stylebox_override("disabled", sb_disabled)
		b.pressed.connect(select_card.bind(i))
		var content: Control = b.get_node("Content") as Control
		content.modulate = Color(1, 1, 1, 0.45) if b.disabled else Color.WHITE
		_hand_box.add_child(b)


## Builds the visual content of a card button (shared look, see CardView).
func _fill_card_content(b: Button, card: CardData) -> void:
	CardView.fill_card_content(b, card, _data.get_type_chart(), _data.get_pokemon_info)


# --- Input -----------------------------------------------------------------

func _on_enemy_input(event: InputEvent, enemy_index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			click_enemy(enemy_index)


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			click_background()
