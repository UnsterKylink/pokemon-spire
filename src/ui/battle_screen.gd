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
## Story 017 (capture): in wild fights with balls, "Capturer" (info row) toggles a capture mode where each capturable enemy
## shows one button per ball carried with its success chance ("Poké Ball 34 %"); a click throws it (throw_ball, the one
## path also used by Main.battle_use_ball). "Capturé !" / "Raté… (34 %)" float over the target; a captured enemy leaves
## the arena (the enemy slots are rebuilt). Trainer fights (gym / elite / league): the button is disabled with the reason.

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
## Fit-in-720p layout (story 016 fix): outer margins, vertical gaps between the rows and inside the fighter panels.
const SCREEN_MARGIN_X: int = 16
const SCREEN_MARGIN_Y: int = 8
const ROW_SEPARATION: int = 4
const PANEL_SEPARATION: int = 2
## Extra height of the hand row over the card height (selected card border stays inside).
const HAND_EXTRA_HEIGHT: float = 4.0
const END_TURN_SIZE: Vector2 = Vector2(160, 44)
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
## Story 016: status feedback (own float per target, so it never hides "Super efficace !"), start height in the sprite.
const STATUS_FLOAT_Y: float = 0.3
## Status colours are lightened for the floating text (purple poison is too dark on the background).
const STATUS_FLOAT_LIGHTEN: float = 0.3
## Added value of a stackable status ("Brûlure +3") / a non-stackable status applied ("Paralysie !").
const TEXT_STATUS_ADDED: String = "%s +%d"
const TEXT_STATUS_APPLIED: String = "%s !"
## Status damage at the end of the turn: amount, status name.
const TEXT_STATUS_TICK: String = "-%d PV (%s)"
const TEXT_STATUS_IMMUNE: String = "Immunisé !"
## Paralysis: an enemy action / a card of the player fails (status name).
const TEXT_STATUS_FAILED: String = "Raté ! (%s)"
## Lost turn (sleep / freeze) by status id; other ids fall back to TEXT_STATUS_APPLIED with the skip_label.
const TEXT_SKIPPED: Dictionary = {"sleep": "Dort…", "freeze": "Gelé !"}
const TEXT_WOKE: String = "Réveillé !"
const TEXT_THAWED: String = "Dégelé !"
## Info row when the player's team is asleep / frozen at the start of its turn (by status id, fallback for other ids);
## %d = energy lost this turn (Battle.energy_lost, from statuses.json player_energy_loss).
const TEXT_PLAYER_LOST_TURN: Dictionary = {"sleep": "Ton équipe dort : −%d énergie ce tour",
		"freeze": "Ton équipe est gelée : −%d énergie ce tour"}
const TEXT_PLAYER_LOST_TURN_OTHER: String = "Ton équipe est entravée : −%d énergie ce tour"
## A non-refreshing status (paralysis) re-applied while active: nothing happens (status name).
const TEXT_STATUS_UNCHANGED: String = "%s : sans effet"
const COLOR_LOST_TURN: Color = Color(0.75, 0.7, 1.0)
const INTENT_FONT_SIZE: int = 22
## Story 017: capture mode texts / colours / sizes.
const TEXT_CAPTURE: String = "Capturer"
const TEXT_CAPTURE_CANCEL: String = "Annuler"
const TEXT_CAPTURE_TIP: String = "Lancer une Poké Ball sur un Pokémon sauvage (%d énergie ; la Ball est perdue même en cas d'échec)."
const TEXT_CAPTURE_CANCEL_TIP: String = "Quitter le mode capture."
const TEXT_CAPTURE_TRAINER: String = "Impossible de capturer un Pokémon de Dresseur."
const TEXT_CAPTURE_NONE: String = "Aucun Pokémon capturable dans ce combat."
const TEXT_CAPTURE_NO_ENERGY: String = "Pas assez d'énergie (%d requise)."
const TEXT_CAPTURE_WAIT: String = "Attends ton tour."
const TEXT_CAPTURE_HINT: String = "Ball : %d énergie"
const TEXT_BALL_CHANCE: String = "%s %d %%"
const TEXT_BALL_TIP: String = "%s ×%d — %d %% de chances de capturer %s.\n%s"
const TEXT_NOT_CAPTURABLE: String = "Non capturable"
const TEXT_CAPTURED: String = "Capturé !"
const TEXT_CAPTURE_FAILED: String = "Raté… (%d %%)"
const COLOR_CAPTURE: Color = Color(1.0, 0.45, 0.45)
const COLOR_CAPTURED: Color = Color(0.45, 1.0, 0.55)
const COLOR_CAPTURE_FAILED: Color = Color(1.0, 0.62, 0.5)
const COLOR_CAPTURE_BG: Color = Color(0.1, 0.11, 0.15, 0.92)
const MODULATE_CAPTURABLE: Color = Color(1.0, 0.85, 0.85)
const CAPTURE_BUTTON_SIZE: Vector2 = Vector2(120, 44)
const BALL_BUTTON_HEIGHT: float = 28.0
const BALL_BUTTON_ICON: float = 16.0
const CAPTURE_FLOAT_Y: float = 0.9
const INTENT_FONT_MIN: int = 14


## A floating feedback label and its running tween (one per target, reused).
class FloatText extends RefCounted:
	var label: Label
	var tween: Tween
	## Bumped on every show/hide so a deferred show that was superseded does nothing.
	var serial: int = 0
	## Story 016: messages gathered during one frame (several statuses can change at once), shown together.
	var pending: PackedStringArray = PackedStringArray()
	var pending_colors: Array[Color] = []


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
	var status_chips: StatusChipRow
	var status_float: FloatText
	## Story 017: the enemy shown in this slot, and the capture overlay over its sprite (capture mode only).
	var combatant: Combatant
	var capture_box: VBoxContainer


## Story 013: league trainer header colours.
const COLOR_HEADER_BG: Color = Color(0.1, 0.11, 0.16, 0.92)
const COLOR_BOSS_HEADER: Color = Color(0.85, 0.2, 0.35)
const COLOR_BOSS_HEADER_BG: Color = Color(0.2, 0.05, 0.14, 0.95)

var _trainer_header: PanelContainer
var _trainer_style: StyleBoxFlat
var _trainer_label: Label
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
var _player_status_float: FloatText
var _player_chips: StatusChipRow
## Story 016: status that made the player lose the current turn ("" = normal turn); _pending_lost_turn waits for turn_started.
var _lost_turn_status: String = ""
var _pending_lost_turn: String = ""
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
## Story 017: capture mode.
var _capture_button: Button
var _capture_mode: bool = false
var _capture_float: FloatText
var _last_throw_chance: float = 0.0


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


## Story 016: status feedback text currently shown over enemy enemy_index ("" if none).
func get_enemy_status_float_text(enemy_index: int) -> String:
	if enemy_index < 0 or enemy_index >= _enemy_views.size():
		return ""
	return _visible_float_text(_enemy_views[enemy_index].status_float)


## Story 016: status feedback text currently shown over the active Pokémon ("" if none).
func get_player_status_float_text() -> String:
	return _visible_float_text(_player_status_float)


## Story 016: status chip texts under enemy enemy_index (empty if none / bad index).
func get_enemy_status_chips(enemy_index: int) -> PackedStringArray:
	if enemy_index < 0 or enemy_index >= _enemy_views.size():
		return PackedStringArray()
	return _enemy_views[enemy_index].status_chips.get_chip_texts()


## QA: global rectangles of the hand card buttons, left to right (layout checks: the full card must fit the window).
func get_hand_card_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for child: Node in _hand_box.get_children():
		if child is Control and not child.is_queued_for_deletion():
			out.append((child as Control).get_global_rect())
	return out


## Story 016: status chip texts under the player's panel.
func get_player_status_chips() -> PackedStringArray:
	return _player_chips.get_chip_texts()


## Story 016: text of the info-row hint ("Choisissez une cible", lost turn message, turn bonus or "").
func get_hint_text() -> String:
	return _hint_label.text


## Story 017: true while the capture mode is on (ball buttons shown over the capturable enemies).
func is_capture_mode() -> bool:
	return _capture_mode


## Story 017: presses "Capturer" / "Annuler" (same path as the mouse). Ignored while the button is hidden / disabled.
func toggle_capture_mode() -> void:
	if _battle == null or not _capture_button.visible or _capture_button.disabled:
		return
	_capture_mode = not _capture_mode
	_selected_index = -1
	_refresh()


## Story 017: throws `ball` (id or index into Battle.ball_ids()) at enemies[enemy_index] -- the ball buttons of the capture
## mode and Main.battle_use_ball both come here. Returns Battle.use_ball's result ({used: false, ...} when refused).
func throw_ball(ball: Variant, enemy_index: int) -> Dictionary:
	if _battle == null or not _battle.can_use_ball(ball, enemy_index):
		return {"used": false, "success": false, "chance": 0.0, "roll": 1.0}
	_selected_index = -1
	return _battle.use_ball(ball, enemy_index)


## Story 017, QA: state of the capture button {visible, disabled, text, tooltip}.
func get_capture_button_state() -> Dictionary:
	return {"visible": _capture_button.visible, "disabled": _capture_button.disabled, "text": _capture_button.text,
			"tooltip": _capture_button.tooltip_text}


## Story 017, QA: texts of the capture overlay of enemy enemy_index ("Poké Ball 34 %", or "Non capturable"); empty
## outside the capture mode.
func get_enemy_capture_texts(enemy_index: int) -> PackedStringArray:
	var out := PackedStringArray()
	if enemy_index < 0 or enemy_index >= _enemy_views.size() or not _enemy_views[enemy_index].capture_box.visible:
		return out
	for child: Node in _enemy_views[enemy_index].capture_box.get_children():
		if child is Button:
			out.append((child as Button).text)
		elif child is Label:
			out.append((child as Label).text)
	return out


## Story 017, QA: the capture feedback currently shown ("Capturé !" / "Raté… (34 %)", "" if none).
func get_capture_float_text() -> String:
	return _visible_float_text(_capture_float)


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
	_hide_float(_player_status_float)
	_hide_float(_capture_float)
	_capture_mode = false
	_pending_items.clear()
	_lost_turn_status = ""
	_pending_lost_turn = ""
	_player_chips.bind(player, _data.get_status_book())
	_end_box.visible = false
	_end_dim.visible = false
	_battle.state_changed.connect(_refresh)
	_battle.hit_resolved.connect(_on_hit_resolved)
	_battle.battle_won.connect(_on_battle_won)
	_battle.active_pokemon_changed.connect(_on_active_pokemon_changed)
	_battle.item_triggered.connect(_on_item_triggered)
	_battle.potion_used.connect(_on_potion_used)
	_battle.status_applied.connect(_on_status_applied)
	_battle.status_ticked.connect(_on_status_ticked)
	_battle.status_blocked.connect(_on_status_blocked)
	_battle.turn_skipped.connect(_on_turn_skipped)
	_battle.status_removed.connect(_on_status_removed)
	_battle.status_unchanged.connect(_on_status_unchanged)
	_battle.turn_started.connect(_on_turn_started)
	_battle.ball_thrown.connect(_on_ball_thrown)
	_battle.capture_succeeded.connect(_on_capture_succeeded)
	_battle.capture_failed.connect(_on_capture_failed)
	_battle.start()
	_refresh_active_pokemon(player)
	_refresh()


## Story 013: shows the opponent trainer above the arena ("Agatha — Conseil 4"), framed in `accent` (type colour);
## `boss` uses the final-boss palette. An empty text hides it. Display only (Main calls it for league fights).
func set_trainer_header(text: String, accent: Color, boss: bool = false) -> void:
	_trainer_label.text = text
	_trainer_style.border_color = COLOR_BOSS_HEADER if boss else accent
	_trainer_style.bg_color = COLOR_BOSS_HEADER_BG if boss else COLOR_HEADER_BG
	_trainer_label.add_theme_color_override("font_color", COLOR_BOSS_HEADER.lightened(0.35) if boss else accent.lightened(0.45))
	_trainer_header.visible = not text.is_empty()


## Story 018: shows the rival intro banner over the battle (info: see RivalIntroBanner.setup). Display only.
func show_rival_intro(info: Dictionary) -> RivalIntroBanner:
	var banner := RivalIntroBanner.new()
	add_child(banner)
	banner.setup(info)
	return banner


## Story 018: the rival intro banner while shown (null otherwise).
func get_rival_intro() -> RivalIntroBanner:
	var n: Node = get_node_or_null("RivalIntroBanner")
	return n as RivalIntroBanner if n != null and not n.is_queued_for_deletion() else null


## Story 013: the trainer header text ("" when hidden).
func get_trainer_header_text() -> String:
	return _trainer_label.text if _trainer_header.visible else ""


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
	_capture_mode = false
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


## QA-ONLY CHEAT: applies `value` of status `status_id` through Battle.apply_status (immunities and feedback
## included) to enemy `target_index`, or to the player when -1. Returns false when refused. Never called by the game.
func qa_apply_status(target_index: int, status_id: String, value: int) -> bool:
	if _battle == null:
		return false
	var target: Combatant = _battle.player
	if target_index >= 0:
		if target_index >= _battle.enemies.size():
			return false
		target = _battle.enemies[target_index]
	var ok: bool = _battle.apply_status(target, status_id, value)
	_refresh()
	return ok


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
	_capture_mode = false
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
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, SCREEN_MARGIN_X)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, SCREEN_MARGIN_Y)
	add_child(margin)

	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", ROW_SEPARATION)
	margin.add_child(root)

	# Arena: player left, enemies (1..3) right.
	var arena := HBoxContainer.new()
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(arena)

	var player_box := VBoxContainer.new()
	player_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER
	player_box.add_theme_constant_override("separation", PANEL_SEPARATION)
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
	# HP and block share one row (saves a line of height, story 016 fit-in-720p fix).
	var player_hp_row := _make_hp_row()
	player_box.add_child(player_hp_row)
	_player_hp_label = _make_label(18)
	player_hp_row.add_child(_player_hp_label)
	_player_block = _make_label(18)
	_player_block.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	player_hp_row.add_child(_player_block)
	_player_chips = StatusChipRow.new()
	player_box.add_child(_player_chips)

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
	info.add_theme_constant_override("separation", 18)
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
	# Story 017: the hint never widens the row (the capture button joined it): it shrinks with an ellipsis instead.
	_hint_label.clip_text = true
	_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hint_label.custom_minimum_size = Vector2(40, 0)
	info.add_child(_hint_label)
	_capture_button = Button.new()
	_capture_button.name = "CaptureButton"
	_capture_button.text = TEXT_CAPTURE
	_capture_button.custom_minimum_size = CAPTURE_BUTTON_SIZE
	_capture_button.add_theme_color_override("font_color", COLOR_CAPTURE)
	_capture_button.visible = false
	_capture_button.pressed.connect(toggle_capture_mode)
	info.add_child(_capture_button)
	_end_turn_button = Button.new()
	_end_turn_button.text = "Fin de tour"
	_end_turn_button.custom_minimum_size = END_TURN_SIZE
	_end_turn_button.pressed.connect(press_end_turn)
	info.add_child(_end_turn_button)

	# Hand.
	_hand_box = HBoxContainer.new()
	_hand_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_box.name = "HandBox"
	_hand_box.custom_minimum_size = Vector2(0, CARD_SIZE.y + HAND_EXTRA_HEIGHT)
	_hand_box.add_theme_constant_override("separation", 12)
	root.add_child(_hand_box)

	# Story 013: league trainer header, centred at the top over the arena (hidden outside the league).
	_trainer_header = PanelContainer.new()
	_trainer_header.name = "TrainerHeader"
	_trainer_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trainer_header.anchor_left = 0.5
	_trainer_header.anchor_right = 0.5
	_trainer_header.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_trainer_header.offset_top = 6
	_trainer_style = StyleBoxFlat.new()
	_trainer_style.bg_color = COLOR_HEADER_BG
	_trainer_style.set_border_width_all(2)
	_trainer_style.set_corner_radius_all(10)
	_trainer_style.content_margin_left = 16
	_trainer_style.content_margin_right = 16
	_trainer_style.content_margin_top = 1
	_trainer_style.content_margin_bottom = 1
	_trainer_header.add_theme_stylebox_override("panel", _trainer_style)
	_trainer_header.visible = false
	add_child(_trainer_header)
	_trainer_label = _make_label(18)
	_trainer_label.name = "TrainerLabel"
	_trainer_header.add_child(_trainer_label)

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
	_player_status_float = _make_float_text()
	_capture_float = _make_float_text()


func _make_label(font_size: int) -> Label:
	return CardView.make_label(font_size)


## Centred row holding the "PV x/y" and "Protection n" labels of a fighter.
func _make_hp_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	return row


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
		_free_float(old.status_float)
	_enemy_views.clear()
	var scale_index: int = clampi(enemies.size(), 1, ENEMY_SPRITE_SCALES.size()) - 1
	var sprite_scale: float = ENEMY_SPRITE_SCALES[scale_index]
	for i: int in enemies.size():
		var v := EnemyView.new()
		v.panel = VBoxContainer.new()
		v.panel.name = "Enemy%d" % i
		v.panel.mouse_filter = Control.MOUSE_FILTER_STOP  # receives the click that plays the card
		v.panel.alignment = BoxContainer.ALIGNMENT_CENTER
		v.panel.add_theme_constant_override("separation", PANEL_SEPARATION)
		v.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.panel.gui_input.connect(_on_enemy_input.bind(i))
		_enemies_box.add_child(v.panel)
		v.name_label = _make_label(24)
		v.name_label.text = enemies[i].display_name
		v.panel.add_child(v.name_label)
		v.type_badge = CardView.make_type_badge_row()
		_set_badge_row(v.type_badge, enemies[i].type_ids)
		v.panel.add_child(v.type_badge)
		v.intent_label = _make_label(INTENT_FONT_SIZE)
		v.intent_label.clip_text = true  # never widens the slot; the font shrinks to fit first (_fit_intent_font)
		v.panel.add_child(v.intent_label)
		v.sprite = _make_sprite_holder("EnemySprite%d" % i, sprite_scale)
		v.sprite.texture = _load_texture(enemies[i].sprite_path)
		v.panel.add_child(v.sprite)
		v.hp_bar = _make_hp_bar(COLOR_HP_ENEMY, sprite_scale)
		v.panel.add_child(v.hp_bar)
		var hp_row := _make_hp_row()
		hp_row.mouse_filter = Control.MOUSE_FILTER_PASS
		v.panel.add_child(hp_row)
		v.hp_label = _make_label(18)
		hp_row.add_child(v.hp_label)
		v.block_label = _make_label(18)
		v.block_label.add_theme_color_override("font_color", COLOR_INTENT_BLOCK)
		hp_row.add_child(v.block_label)
		v.status_chips = StatusChipRow.new()
		v.panel.add_child(v.status_chips)
		v.status_chips.bind(enemies[i], _data.get_status_book())
		v.float_text = _make_float_text()
		v.status_float = _make_float_text()
		v.combatant = enemies[i]
		v.capture_box = VBoxContainer.new()
		v.capture_box.name = "Capture"
		v.capture_box.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.capture_box.alignment = BoxContainer.ALIGNMENT_CENTER
		v.capture_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.capture_box.add_theme_constant_override("separation", 4)
		v.capture_box.visible = false
		v.sprite.add_child(v.capture_box)
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
	if _views_stale():
		_build_enemy_views(_battle.enemies)
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


# --- Status feedback (story 016) --------------------------------------------------

func _on_status_applied(target: Combatant, status_id: String, value: int) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def == null:
		return
	var text: String = TEXT_STATUS_ADDED % [def.display_name, value] if def.stackable else TEXT_STATUS_APPLIED % def.display_name
	_queue_status_float(target, text, def.color)


func _on_status_ticked(target: Combatant, status_id: String, amount: int) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def != null:
		_queue_status_float(target, TEXT_STATUS_TICK % [amount, def.display_name], def.color)


## Immunity, or (player only) a card that fizzled because of paralysis: the player still has the status and is not immune.
func _on_status_blocked(target: Combatant, status_id: String) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def == null:
		return
	if target == _battle.player and def.skip_chance > 0.0 and target.has_status(status_id) and not _battle.is_immune(target, status_id):
		_queue_status_float(target, TEXT_STATUS_FAILED % def.display_name, def.color)
	else:
		_queue_status_float(target, TEXT_STATUS_IMMUNE, COLOR_IMMUNE)


func _on_turn_skipped(target: Combatant, status_id: String) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def == null:
		return
	var text: String = TEXT_STATUS_FAILED % def.display_name
	if def.skip_turns > 0:
		text = String(TEXT_SKIPPED.get(status_id, TEXT_STATUS_APPLIED % def.skip_label))
	# The lost turn is shown before the "Réveillé !" / "Dégelé !" of the same frame (the status is consumed first).
	_queue_status_float(target, text, def.color, TEXT_WOKE if def.wake_on_damage else TEXT_THAWED)
	if target == _battle.player:
		_pending_lost_turn = status_id


func _on_status_unchanged(target: Combatant, status_id: String) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def != null:
		_queue_status_float(target, TEXT_STATUS_UNCHANGED % def.display_name, COLOR_IMMUNE)


## Only waking up and thawing get a message; expiries and cures just remove the chip.
func _on_status_removed(target: Combatant, status_id: String) -> void:
	var def: StatusData = _data.get_status(status_id)
	if def == null or _battle.state != Battle.State.PLAYER_TURN:
		return
	if def.wake_on_damage:
		_queue_status_float(target, TEXT_WOKE, def.color)
	elif not def.thaw_types.is_empty():
		_queue_status_float(target, TEXT_THAWED, def.color)


func _on_turn_started() -> void:
	_lost_turn_status = _pending_lost_turn
	_pending_lost_turn = ""


## Gathers the status messages of `target` for this frame; they are shown together (one line each, own colour) at
## the end of it. `before` = insert the line before that already-queued text (if present) instead of appending it.
func _queue_status_float(target: Combatant, text: String, color: Color, before: String = "") -> void:
	var f: FloatText = _player_status_float
	if target != _battle.player:
		var idx: int = _battle.enemies.find(target)
		if idx < 0 or idx >= _enemy_views.size():
			return
		f = _enemy_views[idx].status_float
	if f.pending.is_empty():
		_flush_status_float.call_deferred(f, target)
	var at: int = f.pending.find(before) if not before.is_empty() else -1
	if at < 0:
		at = f.pending.size()
	f.pending.insert(at, text)
	f.pending_colors.insert(at, color.lightened(STATUS_FLOAT_LIGHTEN))


func _flush_status_float(f: FloatText, target: Combatant) -> void:
	if f.pending.is_empty() or not is_inside_tree() or _battle == null:
		return
	var lines: PackedStringArray = f.pending.duplicate()
	var colors: Array[Color] = f.pending_colors.duplicate()
	f.pending.clear()
	f.pending_colors.clear()
	var anchor: Control = _player_sprite
	if target != _battle.player:
		var idx: int = _battle.enemies.find(target)
		if idx < 0 or idx >= _enemy_views.size():
			return
		anchor = _enemy_views[idx].sprite
	# One coloured line per message: the float label itself only sizes the block (transparent text); child labels,
	# anchored to 1/n of its height each, draw the lines and inherit its drift / fade.
	for child: Node in f.label.get_children():
		f.label.remove_child(child)
		child.queue_free()
	var multi: bool = lines.size() > 1
	f.label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0) if multi else Color.BLACK)
	if multi:
		for i: int in lines.size():
			var line: Label = _make_label(FLOAT_FONT_SIZE)
			line.text = lines[i]
			line.add_theme_color_override("font_color", colors[i])
			line.add_theme_color_override("font_outline_color", Color.BLACK)
			line.add_theme_constant_override("outline_size", 8)
			line.anchor_right = 1.0
			line.anchor_top = float(i) / lines.size()
			line.anchor_bottom = float(i + 1) / lines.size()
			f.label.add_child(line)
	_show_float(f, anchor, "\n".join(lines), Color(0, 0, 0, 0) if multi else colors[0], STATUS_FLOAT_Y)


# --- Capture (story 017) ------------------------------------------------------------

func _on_ball_thrown(_target: Combatant, _ball: BallData, chance: float) -> void:
	_last_throw_chance = chance


## The target already left Battle.enemies: the float goes where its sprite was, then the slots are rebuilt.
func _on_capture_succeeded(target: Combatant) -> void:
	var rect := Rect2()
	for v: EnemyView in _enemy_views:
		if v.combatant == target:
			rect = v.sprite.get_global_rect()
	_build_enemy_views(_battle.enemies)
	_show_float(_capture_float, null, TEXT_CAPTURED, COLOR_CAPTURED, CAPTURE_FLOAT_Y, rect)


func _on_capture_failed(target: Combatant) -> void:
	for v: EnemyView in _enemy_views:
		if v.combatant == target:
			_show_float(_capture_float, v.sprite, TEXT_CAPTURE_FAILED % roundi(_last_throw_chance * 100.0), COLOR_CAPTURE_FAILED,
					CAPTURE_FLOAT_Y)


## True when the enemy slots no longer match Battle.enemies (a capture removed one).
func _views_stale() -> bool:
	if _enemy_views.size() != _battle.enemies.size():
		return true
	for i: int in _enemy_views.size():
		if _enemy_views[i].combatant != _battle.enemies[i]:
			return true
	return false


func _any_capturable() -> bool:
	for i: int in _battle.enemies.size():
		if _battle.is_capturable(i):
			return true
	return false


## Shows / enables "Capturer" and leaves the capture mode when it is no longer possible.
func _refresh_capture_button() -> void:
	var has_balls: bool = not _battle.ball_ids().is_empty()
	var cost: int = _battle.ball_energy_cost()
	_capture_button.visible = has_balls
	var reason: String = ""
	if not _battle.capture_allowed:
		reason = TEXT_CAPTURE_TRAINER
	elif _battle.state != Battle.State.PLAYER_TURN:
		reason = TEXT_CAPTURE_WAIT
	elif not _any_capturable():
		reason = TEXT_CAPTURE_NONE
	elif _battle.energy < cost:
		reason = TEXT_CAPTURE_NO_ENERGY % cost
	if not has_balls or not reason.is_empty():
		_capture_mode = false
	_capture_button.disabled = not reason.is_empty()
	_capture_button.text = TEXT_CAPTURE_CANCEL if _capture_mode else TEXT_CAPTURE
	_capture_button.tooltip_text = reason if not reason.is_empty() else (TEXT_CAPTURE_CANCEL_TIP if _capture_mode
			else TEXT_CAPTURE_TIP % cost)


## Capture overlay of one enemy: one button per ball carried with its chance, or "Non capturable".
func _refresh_capture_box(v: EnemyView, enemy_index: int) -> void:
	for child: Node in v.capture_box.get_children():
		v.capture_box.remove_child(child)
		child.queue_free()
	v.capture_box.visible = _capture_mode and v.combatant.is_alive()
	if not v.capture_box.visible:
		return
	if not _battle.is_capturable(enemy_index):
		var l: Label = _make_label(16)
		l.text = TEXT_NOT_CAPTURABLE
		l.add_theme_color_override("font_color", COLOR_IMMUNE.lightened(0.3))
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		v.capture_box.add_child(l)
		return
	var book: Dictionary = _data.get_ball_book()
	for bid: String in _battle.ball_ids():
		var def: BallData = book.get(bid, null)
		if def == null:
			continue
		var pct: int = roundi(_battle.capture_chance(bid, enemy_index) * 100.0)
		var usable: bool = _battle.can_use_ball(bid, enemy_index)
		var b := Button.new()
		b.name = "Ball_" + bid
		b.text = TEXT_BALL_CHANCE % [def.display_name, pct]
		b.custom_minimum_size = Vector2(0, BALL_BUTTON_HEIGHT)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 15)
		b.disabled = not usable
		var accent: Color = BallIcon.color_of(bid).lightened(0.25)
		var sb := StyleBoxFlat.new()
		sb.bg_color = COLOR_CAPTURE_BG
		sb.set_border_width_all(2)
		sb.border_color = accent
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 6.0 + BALL_BUTTON_ICON + 4.0
		sb.content_margin_right = 8
		var hover: StyleBoxFlat = sb.duplicate()
		hover.bg_color = COLOR_CAPTURE_BG.lightened(0.2)
		hover.border_color = COLOR_SELECTED
		var dis: StyleBoxFlat = sb.duplicate()
		dis.border_color = accent.darkened(0.5)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_stylebox_override("disabled", dis)
		b.add_theme_color_override("font_color", Color.WHITE)
		var icon: BallIcon = BallIcon.make(bid, BALL_BUTTON_ICON)
		icon.position = Vector2(6, (BALL_BUTTON_HEIGHT - BALL_BUTTON_ICON) * 0.5)
		icon.size = Vector2.ONE * BALL_BUTTON_ICON
		b.add_child(icon)
		var why: String = TEXT_CAPTURE_TIP % _battle.ball_energy_cost() if usable else TEXT_CAPTURE_NO_ENERGY % _battle.ball_energy_cost()
		b.tooltip_text = TEXT_BALL_TIP % [def.display_name, _battle.ball_count(bid), pct, v.combatant.display_name, why]
		b.pressed.connect(throw_ball.bind(bid, enemy_index))
		v.capture_box.add_child(b)


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
## Story 017: `anchor` may be null, then `at_rect` (global) is used (the captured enemy's slot is already gone).
func _show_float(f: FloatText, anchor: Control, text: String, color: Color, y_ratio: float = 0.0, at_rect: Rect2 = Rect2()) -> void:
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
	if not is_inside_tree() or my_serial != f.serial or not is_instance_valid(f.label) or (anchor != null and not is_instance_valid(anchor)):
		return
	f.label.modulate = Color.WHITE
	f.label.visible = true
	f.label.reset_size()
	var r: Rect2 = anchor.get_global_rect() if anchor != null else at_rect
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
	f.pending.clear()
	f.pending_colors.clear()
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


## Story 016: a lost turn ("Dort", "Gelé") takes the colour of the status that causes it.
func _intent_color(intent: EnemyIntent, enemy: Combatant = null) -> Color:
	if not intent.skip_label.is_empty() and enemy != null:
		for sid: String in enemy.status_ids():
			var def: StatusData = _data.get_status(sid)
			if def != null and def.skip_turns > 0:
				return def.color.lightened(STATUS_FLOAT_LIGHTEN)
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
	_hint_label.remove_theme_color_override("font_color")
	if _selected_index < 0 and not over and not _lost_turn_status.is_empty():
		_hint_label.text = String(TEXT_PLAYER_LOST_TURN.get(_lost_turn_status, TEXT_PLAYER_LOST_TURN_OTHER)) % _battle.energy_lost
		_hint_label.add_theme_color_override("font_color", COLOR_LOST_TURN)
	elif _selected_index < 0 and _battle.turn_damage_bonus > 0 and not over:
		_hint_label.text = TEXT_TURN_BONUS % _battle.turn_damage_bonus
	if _views_stale():
		_build_enemy_views(_battle.enemies)
	_refresh_capture_button()
	if _capture_mode:
		_hint_label.text = TEXT_CAPTURE_HINT % _battle.ball_energy_cost()
		_hint_label.add_theme_color_override("font_color", COLOR_CAPTURE)
	for i: int in _enemy_views.size():
		_refresh_enemy(_enemy_views[i], _battle.enemies[i])
		_refresh_capture_box(_enemy_views[i], i)
	_player_chips.refresh()
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
		v.intent_label.add_theme_color_override("font_color", _intent_color(e.intent, e))
		_fit_intent_font(v.intent_label)
	elif e.is_alive():
		v.intent_label.text = ""
	else:
		v.intent_label.text = "K.O."
		v.intent_label.add_theme_color_override("font_color", COLOR_KO)
	if not e.is_alive():
		v.panel.modulate = MODULATE_KO
	elif _selected_index >= 0:
		v.panel.modulate = MODULATE_TARGETABLE
	elif _capture_mode and _battle.is_capturable(_battle.enemies.find(e)):
		v.panel.modulate = MODULATE_CAPTURABLE
	else:
		v.panel.modulate = Color.WHITE


## Story 016: long intents ("Attaque 13 + Brûlure 4") shrink their font so they fit the enemy slot (3 enemies at 1280).
func _fit_intent_font(label: Label) -> void:
	var n: int = maxi(_enemy_views.size(), 1)
	var sep: int = _enemies_box.get_theme_constant("separation")
	var box_w: float = _enemies_box.size.x
	if box_w <= 0.0:
		box_w = get_viewport_rect().size.x * 2.0 / 3.0  # before the first layout: the arena gives the enemies 2/3
	var max_w: float = (box_w - sep * (n - 1)) / float(n) - 4.0
	var font: Font = label.get_theme_font("font")
	var font_size: int = INTENT_FONT_SIZE
	while font_size > INTENT_FONT_MIN and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)


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
