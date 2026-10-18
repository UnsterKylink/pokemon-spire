class_name BattleScreen
extends Control
## Playable battle screen (mouse only). UI is built from containers in code; all logic lives in Battle.
## Implements: story-001-combat-de-base (écran jouable), story-002-intentions-et-multi-ennemis.
## Interaction: click an attack card to select it, then click a living enemy; skill cards play on click.

const PLAYER_ID: String = "salameche"
const SPRITE_SOURCE_SIZE: float = 96.0
## Enemy sprite scale by number of enemies (index 0 = 1 enemy). Chosen so 3 enemies fit 1280x720.
const ENEMY_SPRITE_SCALES: Array[float] = [2.5, 2.0, 1.6]
const PLAYER_SPRITE_SCALE: float = 2.5
const CARD_SIZE: Vector2 = Vector2(170, 200)
const ENCOUNTER_ARG_PREFIX: String = "--encounter="
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


## Widgets of one enemy slot (typed refs, no find_child).
class EnemyView extends RefCounted:
	var panel: VBoxContainer
	var name_label: Label
	var intent_label: Label
	var sprite: TextureRect
	var hp_bar: ProgressBar
	var hp_label: Label
	var block_label: Label


var _battle: Battle
var _selected_index: int = -1
var _encounter_order: Array[String] = []
var _encounter_id: String = ""

var _data: GameData
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _background: ColorRect
var _player_name: Label
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
var _end_turn_button: Button
var _hand_box: HBoxContainer
var _end_box: VBoxContainer
var _end_dim: ColorRect
var _message_label: Label
var _restart_button: Button
var _hint_label: Label


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("BattleScreen: could not load game data")
		return
	_encounter_order = _data.get_encounter_order()
	if _encounter_order.is_empty():
		push_error("BattleScreen: no encounter defined")
		return
	_build_ui()
	var first_id: String = _encounter_order[0]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ENCOUNTER_ARG_PREFIX):
			var requested: String = arg.substr(ENCOUNTER_ARG_PREFIX.length())
			if _encounter_order.has(requested):
				first_id = requested
			else:
				push_error("BattleScreen: unknown encounter '%s' in --encounter, using '%s'" % [requested, first_id])
	start_encounter(first_id)


## Read-only access for the QA harness.
func get_battle() -> Battle:
	return _battle


## Index of the selected hand card, or -1.
func get_selected_index() -> int:
	return _selected_index


## Id of the encounter currently being played.
func get_encounter_id() -> String:
	return _encounter_id


## Starts a fresh battle (fresh player) on the given encounter id.
func start_encounter(encounter_id: String) -> void:
	if _data == null or not _encounter_order.has(encounter_id):
		push_error("BattleScreen: unknown encounter '%s'" % encounter_id)
		return
	_selected_index = -1
	_encounter_id = encounter_id
	_rng.randomize()
	var player: Combatant = _data.create_player(PLAYER_ID)
	var enemies: Array[Combatant] = _data.create_enemies(encounter_id)
	if player == null or enemies.is_empty():
		return
	_battle = Battle.new(player, enemies, _data.get_starter_deck(PLAYER_ID),
			_data.get_energy_per_turn(PLAYER_ID), _data.get_hand_size(PLAYER_ID), _rng)
	_build_enemy_views(_battle.enemies)
	_player_name.text = player.display_name
	_player_sprite.texture = _load_texture(player.sprite_path)
	_end_box.visible = false
	_end_dim.visible = false
	_battle.state_changed.connect(_refresh)
	_battle.start()
	_refresh()


## Rejouer: next encounter (wrapping) after a victory, same encounter otherwise. Fresh player.
func restart() -> void:
	var id: String = _encounter_id
	if _battle != null and _battle.state == Battle.State.WON:
		var next: int = (_encounter_order.find(_encounter_id) + 1) % _encounter_order.size()
		id = _encounter_order[next]
	start_encounter(id)


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
	_player_name = _make_label(28)
	player_box.add_child(_player_name)
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
	_restart_button.text = "Rejouer"
	_restart_button.custom_minimum_size = Vector2(200, 56)
	_restart_button.pressed.connect(restart)
	_end_box.add_child(_restart_button)


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	return l


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
		_enemy_views.append(v)


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
	_encounter_label.text = "Combat %d/%d" % [_encounter_order.find(_encounter_id) + 1, _encounter_order.size()]
	_energy_label.text = "Énergie %d/%d" % [_battle.energy, _battle.max_energy]
	_draw_label.text = "Pioche : %d" % _battle.draw_pile.size()
	_discard_label.text = "Défausse : %d" % _battle.discard_pile.size()

	var over: bool = _battle.state != Battle.State.PLAYER_TURN
	_end_turn_button.disabled = over
	_hint_label.text = "Choisissez une cible" if _selected_index >= 0 else ""
	for i: int in _enemy_views.size():
		_refresh_enemy(_enemy_views[i], _battle.enemies[i])
	_rebuild_hand()
	if over:
		_end_box.visible = true
		_end_dim.visible = true
		_message_label.text = "Victoire !" if _battle.state == Battle.State.WON else "Défaite…"


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
	for i: int in _battle.hand.size():
		var card: CardData = _battle.hand[i]
		var b := Button.new()
		b.custom_minimum_size = CARD_SIZE
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = false
		b.text = "%s\nCoût : %d\n\n%s" % [card.display_name, card.cost, card.description]
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
		_hand_box.add_child(b)


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
