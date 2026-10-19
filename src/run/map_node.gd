class_name MapNode
extends RefCounted
## One room of the act map. Immutable after generation; "visited" lives in ActProgress.
## Implements: story-005-carte-acte-1.

## Unique id, "f<floor>_c<col>" (e.g. "f3_c2").
var id: String = ""
## 1-based floor (1 = first fights, last = boss).
var floor: int = 1
## Column, 0-based.
var col: int = 0
## Room type id from act1.json (wild, elite, center, mart, event, boss).
var room_type: String = ""
## Ids of the nodes of the next floor reachable from this one.
var next: Array[String] = []


## Builds the canonical node id.
static func make_id(node_floor: int, node_col: int) -> String:
	return "f%d_c%d" % [node_floor, node_col]
