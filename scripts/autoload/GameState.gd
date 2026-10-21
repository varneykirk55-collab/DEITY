extends Node
## Global run configuration, simulation clock, and shared constants.

enum WorldMode { GENERATED, EMPTY }
enum WorldSize { SMALL, MEDIUM, LARGE }

enum Biome {
	OCEAN, ARCTIC, TROPICAL, MOUNTAINOUS, TEMPERATE, RAINFOREST,
	WETLAND, SAVANNA, DESERT, ROCKY, GRASSLAND, VOLCANIC
}

enum Era { STONE, BRONZE, IRON, MEDIEVAL, RENAISSANCE, INDUSTRIAL, MODERN }

enum ToolId {
	NONE,
	RAISE, LOWER, MOUNTAIN, VALLEY, ISLAND, LAKE, RIVER,
	PAINT, FOREST, VEGETATION, VOLCANO,
	SPAWN_TREE, SPAWN_ANIMAL,
	SPAWN_HUMAN_1, SPAWN_HUMAN_5, SPAWN_HUMAN_20, INSPECT,
	BOOST_TECH, ENCOURAGE,
	LIGHTNING, TORNADO, METEOR, ERUPT, KILL, KILL_GROUP, RAIN, STORM, SNOW,
	MIRACLE, PLAGUE, CURE, REMOVE_VEGETATION
}

enum HumanState { IDLE, WALK, GATHER, BUILD, HUNT, FIGHT, FLEE, DIE, REBEL }
enum Rel { NEUTRAL, FRIENDLY, HOSTILE }

const VERSION := "1.0.0"
const SAVE_DIR := "user://saves"
const SETTINGS_PATH := "user://settings.cfg"

const BIOME_NAMES := [
	"Ocean", "Arctic Tundra", "Tropical Islands", "Mountainous Islands",
	"Temperate Forests", "Rainforests", "Wetlands", "Savannas",
	"Deserts", "Rocky Mountains", "Grasslands", "Volcanic Regions"
]

const ERA_NAMES := [
	"Stone Age", "Bronze Age", "Iron Age", "Medieval Age",
	"Renaissance", "Industrial Age", "Modern Age"
]

const ERA_TECH := [0.0, 70.0, 180.0, 340.0, 560.0, 860.0, 1280.0]

const CIV_COLORS := [
	Color(0.86, 0.22, 0.22),
	Color(0.20, 0.42, 0.86),
	Color(0.92, 0.74, 0.16),
	Color(0.18, 0.68, 0.32),
	Color(0.72, 0.28, 0.78),
	Color(0.18, 0.72, 0.78),
	Color(0.90, 0.48, 0.16),
	Color(0.86, 0.38, 0.62),
	Color(0.42, 0.78, 0.36),
	Color(0.55, 0.40, 0.22),
	Color(0.95, 0.95, 0.95),
	Color(0.15, 0.15, 0.18)
]

const BIOME_COLORS := [
	Color(0.12, 0.38, 0.62),
	Color(0.86, 0.91, 0.95),
	Color(0.22, 0.62, 0.28),
	Color(0.40, 0.46, 0.36),
	Color(0.30, 0.54, 0.22),
	Color(0.10, 0.36, 0.14),
	Color(0.34, 0.42, 0.22),
	Color(0.66, 0.60, 0.28),
	Color(0.84, 0.70, 0.38),
	Color(0.50, 0.48, 0.45),
	Color(0.46, 0.70, 0.28),
	Color(0.22, 0.16, 0.14)
]

const SIZE_RADIUS := { WorldSize.SMALL: 78.0, WorldSize.MEDIUM: 118.0, WorldSize.LARGE: 156.0 }
const SIZE_GRID := { WorldSize.SMALL: 96, WorldSize.MEDIUM: 128, WorldSize.LARGE: 160 }

var world_mode: int = WorldMode.GENERATED
var world_size: int = WorldSize.MEDIUM
var biomes_selected: Array = [Biome.TEMPERATE, Biome.GRASSLAND, Biome.TROPICAL, Biome.ARCTIC]
var world_seed: int = 0
var world_name: String = "New World"
var load_path: String = ""

var time_scale: float = 1.0
var paused: bool = false
var sim_time: float = 0.0
var world: Node3D = null

var master_volume: float = 1.0
var mouse_sensitivity: float = 1.0
var fullscreen: bool = false

var _id_seq: int = 1
var _civ_color_idx: int = 0


func _ready() -> void:
	_ensure_save_dir()
	load_settings()
	apply_display()


func next_id() -> int:
	_id_seq += 1
	return _id_seq


func reset_ids(start: int = 1) -> void:
	_id_seq = start


func next_civ_color() -> Color:
	var c: Color = CIV_COLORS[_civ_color_idx % CIV_COLORS.size()]
	_civ_color_idx += 1
	return c


func reset_run() -> void:
	time_scale = 1.0
	paused = false
	sim_time = 0.0
	world = null
	_civ_color_idx = 0


func sim_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * time_scale


func radius() -> float:
	match world_size:
		WorldSize.SMALL:
			return 78.0
		WorldSize.LARGE:
			return 156.0
		_:
			return 118.0


func grid() -> int:
	match world_size:
		WorldSize.SMALL:
			return 96
		WorldSize.LARGE:
			return 160
		_:
			return 128


func era_from_tech(tech: float) -> int:
	var era: int = Era.STONE
	for i in range(ERA_TECH.size()):
		if tech >= ERA_TECH[i]:
			era = i
	return era


func biome_supports_trees(b: int) -> bool:
	return b in [Biome.TROPICAL, Biome.TEMPERATE, Biome.RAINFOREST, Biome.WETLAND, Biome.SAVANNA, Biome.GRASSLAND, Biome.MOUNTAINOUS, Biome.ARCTIC]


func weather_for_biome(b: int) -> String:
	match b:
		Biome.ARCTIC:
			return "snow"
		Biome.RAINFOREST, Biome.WETLAND:
			return "rain"
		Biome.DESERT, Biome.VOLCANIC:
			return "dry"
		_:
			return "clear"


func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("saves"):
		dir.make_dir_recursive("saves")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", 1.0))
	mouse_sensitivity = float(cfg.get_value("input", "mouse_sensitivity", 1.0))
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	AudioServer.set_bus_volume_db(0, linear_to_db(max(master_volume, 0.001)))
