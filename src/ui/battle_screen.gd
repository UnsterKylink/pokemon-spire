class_name BattleScreen
extends Control
## Playable battle screen (mouse only). UI is built from containers in code; all logic lives in Battle.
## Implements: story-001-combat-de-base (écran jouable).
## Interaction: click an attack card to select it, then click the enemy; skill cards play on click.

const PLAYER_ID: String = "salameche"
const ENEMY_ID: String = "rattata"
const SPRITE_SCALE: float = 2.5
const SPRITE_SOURCE_SIZE: float = 96.0
const CARD_SIZE: Vector2 = Vector2(170, 200)
const COLOR_HP_PLAYER: Color = Color(0.3, 0.8, 0.35)
const COLOR_HP_ENEMY: Color = Color(0.9, 0.3, 0.3)
const COLOR_ATTACK: Color = Color(0.85, 0.35, 0.3)
const COLOR_SKILL: Color = Color(0.35, 0.6, 0.95)
const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_SELECTED: Color = Color(1.0, 0.85, 0.3)

var battle: Battle
var selected_index: int = -1

var _data: GameData
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _background: ColorRect
var _player_name: Label
var _player_hp_bar: ProgressBar
var _player_hp_label: Label
var _player_block: Label
var _enemy_panel: VBoxContainer
var _enemy_name: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_label: Label
var _energy_label: Label
var _draw_label: Label
var _discard_label: Label
var _end_turn_button: Button
var _hand_box: HBoxContainer
var _end_box: VBoxContainer
var _message_label: Label
var _restart_button: Button
var _hint_label: Label


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("BattleScreen: could not load game data")
		return
	_build_ui()
	restart()


## Starts a fresh battle (also used by the Rejouer button).
func restart() -> void:
	selected_index = -1
	_rng.randomize()
	var player: Combatant = _data.create_player(PLAYER_ID)
	var enemy: Combatant = _data.create_enemy(ENEMY_ID)
	if player == null or enemy == null:
		return
	battle = Battle.new(player, enemy, _data.get_starter_deck(PLAYER_ID),
			_data.get_energy_per_turn(PLAYER_ID), _data.get_hand_size(PLAYER_ID), _rng)
	battle.state_changed.connect(_refresh)
	battle.start()
	_player_name.text = player.display_name
	_enemy_name.text = enemy.display_name
	_set_sprites(player, enemy)
	_end_box.visible = false
	_refresh()


## Selects (or deselects if already selected) hand card index; skill cards play immediately.
func select_card(index: int) -> void:
	if battle == null or not battle.can_play(index):
		return
	var card: CardData = battle.hand[index]
	if not card.needs_target():
		selected_index = -1
		battle.play_card(index, null)
		return
	selected_index = -1 if selected_index == index else index
	_refresh()


## Clicks the enemy: plays the selected attack card on it, if any.
func click_enemy() -> void:
	if battle == null or selected_index < 0:
		return
	var index: int = selected_index
	selected_index = -1
	if not battle.play_card(index, battle.enemy):
		_refresh()


## Plays hand card index directly on the enemy (QA harness, bypasses selection).
func play_card_direct(index: int) -> bool:
	selected_index = -1
	if battle == null:
		return false
	return battle.play_card(index, battle.enemy)


## Presses the "Fin de tour" button.
func press_end_turn() -> void:
	if battle == null:
		return
	selected_index = -1
	battle.end_turn()


## Clicks empty background: deselects.
func click_background() -> void:
	selected_index = -1
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

	# Arena: player left, enemy right.
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
	player_box.add_child(_make_sprite_holder("PlayerSprite"))
	_player_hp_bar = _make_hp_bar(COLOR_HP_PLAYER)
	player_box.add_child(_player_hp_bar)
	_player_hp_label = _make_label(18)
	player_box.add_child(_player_hp_label)
	_player_block = _make_label(20)
	_player_block.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	player_box.add_child(_player_block)

	_enemy_panel = VBoxContainer.new()
	_enemy_panel.name = "EnemyPanel"
	_enemy_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # receives the click that plays the card
	_enemy_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_panel.gui_input.connect(_on_enemy_input)
	arena.add_child(_enemy_panel)
	_enemy_name = _make_label(28)
	_enemy_panel.add_child(_enemy_name)
	_enemy_panel.add_child(_make_sprite_holder("EnemySprite"))
	_enemy_hp_bar = _make_hp_bar(COLOR_HP_ENEMY)
	_enemy_panel.add_child(_enemy_hp_bar)
	_enemy_hp_label = _make_label(18)
	_enemy_panel.add_child(_enemy_hp_label)

	# Info row.
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 24)
	root.add_child(info)
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

	# End-of-battle overlay.
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


func _make_hp_bar(fill_color: Color) -> ProgressBar:
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
	bar.custom_minimum_size = Vector2(SPRITE_SOURCE_SIZE * SPRITE_SCALE, 20)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return bar


func _make_sprite_holder(node_name: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2.ONE * SPRITE_SOURCE_SIZE * SPRITE_SCALE
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return tr


func _set_sprites(player: Combatant, enemy: Combatant) -> void:
	(find_child("PlayerSprite", true, false) as TextureRect).texture = _load_texture(player.sprite_path)
	(find_child("EnemySprite", true, false) as TextureRect).texture = _load_texture(enemy.sprite_path)


func _load_texture(path: String) -> Texture2D:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		push_error("BattleScreen: cannot load sprite %s" % path)
	return tex


# --- Refresh ---------------------------------------------------------------

func _refresh() -> void:
	if battle == null:
		return
	var p: Combatant = battle.player
	var e: Combatant = battle.enemy
	_player_hp_bar.max_value = p.max_hp
	_player_hp_bar.value = p.hp
	_player_hp_label.text = "PV %d/%d" % [p.hp, p.max_hp]
	_player_block.text = "Protection %d" % p.block
	_enemy_hp_bar.max_value = e.max_hp
	_enemy_hp_bar.value = e.hp
	_enemy_hp_label.text = "PV %d/%d" % [e.hp, e.max_hp]
	_energy_label.text = "Énergie %d/%d" % [battle.energy, battle.max_energy]
	_draw_label.text = "Pioche : %d" % battle.draw_pile.size()
	_discard_label.text = "Défausse : %d" % battle.discard_pile.size()

	var over: bool = battle.state != Battle.State.PLAYER_TURN
	_end_turn_button.disabled = over
	_hint_label.text = "Cliquez sur l'ennemi pour jouer la carte" if selected_index >= 0 else ""
	_enemy_panel.modulate = Color(1.0, 0.9, 0.6) if selected_index >= 0 else Color.WHITE
	_rebuild_hand()
	if over:
		_end_box.visible = true
		_message_label.text = "Victoire !" if battle.state == Battle.State.WON else "Défaite…"


func _rebuild_hand() -> void:
	for child: Node in _hand_box.get_children():
		_hand_box.remove_child(child)
		child.queue_free()
	for i: int in battle.hand.size():
		var card: CardData = battle.hand[i]
		var b := Button.new()
		b.custom_minimum_size = CARD_SIZE
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.clip_text = false
		b.text = "%s\nCoût : %d\n\n%s" % [card.display_name, card.cost, card.description]
		b.disabled = not battle.can_play(i)
		var kind_color: Color = COLOR_SKILL if card.kind == CardData.KIND_SKILL else COLOR_ATTACK
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.18, 0.24)
		sb.set_border_width_all(3)
		sb.border_color = kind_color
		sb.set_corner_radius_all(6)
		if i == selected_index:
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

func _on_enemy_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			click_enemy()


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			click_background()
