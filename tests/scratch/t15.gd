extends SceneTree
# Immune enemy attack must not reduce the player's block (user report 2026-10-24).
func _init() -> void:
	var gd := GameData.new()
	gd.load_all()
	var p := Combatant.from_dict("p", {"name": "P", "types": ["ghost"], "max_hp": 100, "sprite": "s"})
	var e := Combatant.from_dict("x", {"name": "X", "types": ["normal"], "max_hp": 50, "sprite": "s", "pattern": "sequence", "actions": [{"type": "attack", "value": 7}]})
	var d: Array[CardData] = []
	for i in 10: d.append(gd.get_card("abri"))
	var r := RandomNumberGenerator.new(); r.seed = 1
	var es: Array[Combatant] = [e]
	var b := Battle.new(p, es, d, 3, 5, r, gd.get_type_chart())
	b.start()
	b.play_card(0)
	print("block after Abri: ", p.block, " intent value vs ghost: ", e.intent.value)
	var before := p.block
	var seen := []
	b.enemy_acted.connect(func(_en: Combatant, _i: EnemyIntent) -> void: seen.append(p.block))
	b.end_turn()
	print("block right after enemy hit: ", seen, " (was ", before, "), block at new turn: ", p.block, " hp ", p.hp)
	quit()
