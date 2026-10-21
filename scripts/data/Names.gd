class_name Names
extends RefCounted

const CIV_A := ["Val", "Ash", "Iron", "Sun", "Moon", "Storm", "River", "Stone", "Gold", "Wild", "High", "Deep", "Red", "White", "Oak", "Frost", "Amber", "Silver", "Dawn", "Dusk", "Sky", "Wolf", "Bear", "Eagle", "Coral", "Sand"]
const CIV_B := ["oria", "heim", "hold", "crest", "haven", "fall", "gate", "wood", "burg", "stead", "vale", "ridge", "spire", "ford", "watch", "march", "reach", "moor", "field", "port", "shire", "keep", "light", "shade"]
const HUMAN_F := ["Ara", "Bren", "Cala", "Dara", "Esi", "Fara", "Gila", "Hana", "Iri", "Juna", "Kira", "Lena", "Mira", "Nia", "Ora", "Pia", "Rina", "Sila", "Tia", "Uma", "Vera", "Wila", "Yara", "Zia"]
const HUMAN_M := ["Anu", "Bor", "Cor", "Dal", "Eko", "Fen", "Gar", "Hal", "Ivo", "Jor", "Kai", "Lor", "Mek", "Ned", "Orn", "Pax", "Quin", "Raf", "Sol", "Tor", "Ulv", "Vex", "Wren", "Yan"]
const TEMPLE := ["Shrine of the Sky", "Temple of Dawn", "Hall of Voices", "Stone of Witness", "Sanctum", "The Open Hand", "Hearth of Faith"]


static func civ(rng: RandomNumberGenerator) -> String:
	return CIV_A[rng.randi() % CIV_A.size()] + CIV_B[rng.randi() % CIV_B.size()]


static func human(rng: RandomNumberGenerator) -> String:
	if rng.randf() < 0.5:
		return HUMAN_F[rng.randi() % HUMAN_F.size()]
	return HUMAN_M[rng.randi() % HUMAN_M.size()]


static func world(rng: RandomNumberGenerator) -> String:
	var a := ["Verdant", "Azure", "Prime", "First", "Hallowed", "Nameless", "Living", "New", "Elder", "Bright"]
	var b := ["Realm", "World", "Expanse", "Garden", "Cradle", "Sphere", "Terra", "Isle"]
	return a[rng.randi() % a.size()] + " " + b[rng.randi() % b.size()]


static func temple(rng: RandomNumberGenerator) -> String:
	return TEMPLE[rng.randi() % TEMPLE.size()]
