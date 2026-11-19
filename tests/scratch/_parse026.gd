extends SceneTree
func _initialize() -> void:
	for p: String in ["res://src/run/difficulty.gd","res://src/data/game_data.gd","res://src/run/run_state.gd","res://src/run/save_game.gd","res://src/run/player_stats.gd","res://src/run/special_fights.gd","res://src/run/shop_inventory.gd","res://src/run/game_settings.gd","res://src/main.gd","res://src/ui/starter_screen.gd","res://src/ui/title_screen.gd","res://src/ui/run_hud.gd","res://src/ui/run_end_screen.gd","res://src/ui/pokedex_screen.gd","res://src/ui/card_face.gd","res://src/ui/options_panel.gd","res://tools/balance/sim_run.gd","res://tools/balance/simulate.gd","res://tools/qa/battle_walkthrough.gd"]:
		var s: Script = load(p)
		print(p, " ", s != null and s.can_instantiate())
	quit()
