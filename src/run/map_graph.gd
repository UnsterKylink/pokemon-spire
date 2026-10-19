class_name MapGraph
extends RefCounted
## The generated act map: nodes by id, edges stored in MapNode.next. Pure data, no nodes.
## Implements: story-005-carte-acte-1.

## Number of floors (last one holds the single boss node).
var floors: int = 0
## Number of columns.
var width: int = 0
## Seed that produced this map (always set, even when a random one was requested).
var seed: int = 0
## id (String) -> MapNode.
var nodes: Dictionary = {}


## The node with this id, or null (no error) if unknown.
func get_node(id: String) -> MapNode:
	return nodes.get(id, null)


## Nodes of a 1-based floor, sorted by column.
func get_floor_nodes(floor_number: int) -> Array[MapNode]:
	var result: Array[MapNode] = []
	for n: MapNode in nodes.values():
		if n.floor == floor_number:
			result.append(n)
	result.sort_custom(func(a: MapNode, b: MapNode) -> bool: return a.col < b.col)
	return result


## Ids of the floor-1 nodes (where the player starts), sorted by column.
func start_node_ids() -> Array[String]:
	var ids: Array[String] = []
	for n: MapNode in get_floor_nodes(1):
		ids.append(n.id)
	return ids


## Id of the single boss node ("" if the graph is empty).
func boss_id() -> String:
	var last: Array[MapNode] = get_floor_nodes(floors)
	return last[0].id if not last.is_empty() else ""


## Ids of the nodes that lead to `id` (previous floor).
func parent_ids(id: String) -> Array[String]:
	var ids: Array[String] = []
	for n: MapNode in nodes.values():
		if n.next.has(id):
			ids.append(n.id)
	ids.sort()
	return ids
