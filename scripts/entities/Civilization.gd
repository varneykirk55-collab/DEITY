class_name Civilization
extends RefCounted

var id: int
var civ_name: String
var color: Color
var tech: float = 0.0
var era: int = GameState.Era.STONE
var food: int = 8
var wood: int = 6
var stone: int = 4
var ore: int = 0
var relations: Dictionary = {} # other_id -> Rel
var settlement_ids: Array = []
var alive: bool = true
var faith: float = 0.12


func _init(p_id: int = 0, p_name: String = "Tribe", p_color: Color = Color.WHITE) -> void:
	id = p_id
	civ_name = p_name
	color = p_color


func add_res(kind: String, n: int) -> void:
	match kind:
		"food", "meat":
			food += n
		"wood":
			wood += n
		"stone":
			stone += n
		"ore":
			ore += n
		_:
			wood += n


func spend(w: int, s: int, o: int = 0, f: int = 0) -> bool:
	if wood < w or stone < s or ore < o or food < f:
		return false
	wood -= w
	stone -= s
	ore -= o
	food -= f
	return true


func rel_with(other: int) -> int:
	return int(relations.get(other, GameState.Rel.NEUTRAL))


func set_rel(other: int, r: int) -> void:
	relations[other] = r


func serialize() -> Dictionary:
	return {
		"id": id, "name": civ_name, "color": color.to_html(),
		"tech": tech, "era": era, "food": food, "wood": wood, "stone": stone, "ore": ore,
		"relations": relations, "settlements": settlement_ids, "alive": alive, "faith": faith
	}


static func from_dict(d: Dictionary) -> Civilization:
	var c := Civilization.new(int(d.get("id", 0)), str(d.get("name", "Tribe")), Color.html(str(d.get("color", "#ffffff"))))
	c.tech = float(d.get("tech", 0))
	c.era = int(d.get("era", 0))
	c.food = int(d.get("food", 0))
	c.wood = int(d.get("wood", 0))
	c.stone = int(d.get("stone", 0))
	c.ore = int(d.get("ore", 0))
	c.relations = {}
	var rels = d.get("relations", {})
	if typeof(rels) == TYPE_DICTIONARY:
		for k in rels.keys():
			c.relations[int(k)] = int(rels[k])
	c.settlement_ids = d.get("settlements", [])
	c.alive = bool(d.get("alive", true))
	c.faith = float(d.get("faith", 0.12))
	return c
