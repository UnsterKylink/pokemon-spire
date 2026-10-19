class_name ActProgress
extends RefCounted
## Where the player is on the act map: current node and visited nodes. Pure logic.
## Implements: story-005-carte-acte-1 (only connected rooms can be chosen; visited rooms are marked).

var graph: MapGraph = null
## Id of the room the player is in; "" before the first choice.
var current_node_id: String = ""
var visited: Array[String] = []


## Starts progress on a graph (nothing entered yet).
static func create(new_graph: MapGraph) -> ActProgress:
	var p := ActProgress.new()
	p.graph = new_graph
	return p


## Rooms the player may enter now: the floor-1 nodes at the start, else the current node's `next`.
func reachable_ids() -> Array[String]:
	if graph == null:
		return []
	if current_node_id.is_empty():
		return graph.start_node_ids()
	var cur: MapNode = graph.get_node(current_node_id)
	if cur == null:
		return []
	var ids: Array[String] = []
	ids.append_array(cur.next)
	return ids


## True if `id` can be entered right now.
func can_enter(id: String) -> bool:
	return reachable_ids().has(id)


## Enters a reachable room: marks it visited and makes it current. False (no change) otherwise.
func enter(id: String) -> bool:
	if not can_enter(id):
		return false
	current_node_id = id
	if not visited.has(id):
		visited.append(id)
	return true


## True if the room was already entered.
func is_visited(id: String) -> bool:
	return visited.has(id)


## The current node or null before the first choice.
func current_node() -> MapNode:
	if graph == null or current_node_id.is_empty():
		return null
	return graph.get_node(current_node_id)


## Floor of the current room, 0 before the first choice.
func current_floor() -> int:
	var cur: MapNode = current_node()
	return cur.floor if cur != null else 0


## True when the player stands on the boss node.
func is_boss_current() -> bool:
	return not current_node_id.is_empty() and current_node_id == graph.boss_id()
