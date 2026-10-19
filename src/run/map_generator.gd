class_name MapGenerator
extends RefCounted
## Builds the act map (StS-like): random non-crossing upward paths, then weighted room types
## under data-driven constraints. Everything comes from the act config (act1.json).
## Implements: story-005-carte-acte-1.


## Generates a map from `config` (GameData.get_act_config()). `seed_value` 0 = random;
## the seed actually used is always stored in MapGraph.seed. Same seed + config = same map.
static func generate(config: Dictionary, seed_value: int) -> MapGraph:
	var map_cfg: Dictionary = config["map"]
	var used_seed: int = seed_value
	if used_seed == 0:
		var seeder := RandomNumberGenerator.new()
		seeder.randomize()
		used_seed = maxi(1, int(seeder.randi()))
	var rng := RandomNumberGenerator.new()
	rng.seed = used_seed
	var graph := MapGraph.new()
	graph.seed = used_seed
	graph.floors = int(map_cfg["floors"])
	graph.width = int(map_cfg["width"])
	_build_paths(graph, map_cfg, rng)
	_assign_room_types(graph, config, rng)
	return graph


static func _build_paths(graph: MapGraph, map_cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var width: int = graph.width
	var last_regular: int = graph.floors - 1
	# Distinct start columns on floor 1 (partial Fisher-Yates).
	var cols: Array[int] = []
	for c: int in width:
		cols.append(c)
	var start_count: int = int(map_cfg["start_nodes"])
	for i: int in start_count:
		var j: int = rng.randi_range(i, cols.size() - 1)
		var tmp: int = cols[i]
		cols[i] = cols[j]
		cols[j] = tmp
	var start_cols: Array[int] = cols.slice(0, start_count)
	# The boss sits in the middle column of the last floor.
	var boss_col: int = floori((width - 1) / 2.0)
	var boss := _ensure_node(graph, graph.floors, boss_col)
	var path_count: int = maxi(int(map_cfg["paths"]), start_count)
	for p: int in path_count:
		# First paths cover every start column, extra ones pick a random start.
		var col: int = start_cols[p] if p < start_count else start_cols[rng.randi_range(0, start_count - 1)]
		var node := _ensure_node(graph, 1, col)
		for f: int in range(1, last_regular):
			var target_col: int = _pick_next_col(graph, f, col, rng)
			var target := _ensure_node(graph, f + 1, target_col)
			if not node.next.has(target.id):
				node.next.append(target.id)
			node = target
			col = target_col
		if not node.next.has(boss.id):
			node.next.append(boss.id)
	for n: MapNode in graph.nodes.values():
		n.next.sort()


## Picks col-1/col/col+1 on the next floor without crossing an edge of another node of floor `f`.
## Going straight never crosses (edges of left nodes end <= col, of right nodes >= col).
static func _pick_next_col(graph: MapGraph, f: int, col: int, rng: RandomNumberGenerator) -> int:
	var options: Array[int] = []
	for d: int in [-1, 0, 1]:
		var c: int = col + d
		if c >= 0 and c < graph.width and not _crosses(graph, f, col, c):
			options.append(c)
	if options.is_empty():
		return col
	return options[rng.randi_range(0, options.size() - 1)]


static func _crosses(graph: MapGraph, f: int, from_col: int, to_col: int) -> bool:
	for other: MapNode in graph.get_floor_nodes(f):
		if other.col == from_col:
			continue
		for next_id: String in other.next:
			var nc: int = graph.get_node(next_id).col
			if (other.col < from_col and nc > to_col) or (other.col > from_col and nc < to_col):
				return true
	return false


static func _ensure_node(graph: MapGraph, f: int, col: int) -> MapNode:
	var id: String = MapNode.make_id(f, col)
	var existing: MapNode = graph.get_node(id)
	if existing != null:
		return existing
	var n := MapNode.new()
	n.id = id
	n.floor = f
	n.col = col
	graph.nodes[id] = n
	return n


static func _assign_room_types(graph: MapGraph, config: Dictionary, rng: RandomNumberGenerator) -> void:
	var placement: Dictionary = config["placement"]
	var forced: Dictionary = placement["forced_floors"]
	var no_consecutive: Array = placement["no_consecutive"]
	var room_types: Dictionary = config["room_types"]
	var type_ids: Array = room_types.keys()
	type_ids.sort()
	# Forced floors first, so neighbours of a forced floor can respect no_consecutive.
	for f: int in range(1, graph.floors + 1):
		if forced.has(str(f)):
			for n: MapNode in graph.get_floor_nodes(f):
				n.room_type = String(forced[str(f)])
	for f: int in range(1, graph.floors + 1):
		if forced.has(str(f)):
			continue
		for n: MapNode in graph.get_floor_nodes(f):
			var blocked: Array[String] = []
			for pid: String in graph.parent_ids(n.id):
				blocked.append(graph.get_node(pid).room_type)
			for cid: String in n.next:
				blocked.append(graph.get_node(cid).room_type)
			var candidates: Array[String] = []
			var weights: Array[float] = []
			for tid: String in type_ids:
				var def: Dictionary = room_types[tid]
				var w: float = float(def["weight"])
				if w <= 0.0 or f < int(def["min_floor"]) or f > int(def.get("max_floor", graph.floors)):
					continue
				if no_consecutive.has(tid) and blocked.has(tid):
					continue
				candidates.append(tid)
				weights.append(w)
			if candidates.is_empty():
				# Constraints cannot all hold: fall back to the heaviest type allowed on this floor.
				for tid: String in type_ids:
					var def: Dictionary = room_types[tid]
					if float(def["weight"]) > 0.0 and f >= int(def["min_floor"]) \
							and f <= int(def.get("max_floor", graph.floors)):
						candidates.append(tid)
						weights.append(float(def["weight"]))
			n.room_type = _weighted_pick(candidates, weights, rng)


static func _weighted_pick(candidates: Array[String], weights: Array[float], rng: RandomNumberGenerator) -> String:
	if candidates.is_empty():
		return ""
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll: float = rng.randf() * total
	for i: int in candidates.size():
		if roll < weights[i]:
			return candidates[i]
		roll -= weights[i]
	return candidates[candidates.size() - 1]
