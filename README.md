> Recovery branch: actual Godot 4.7.2 headless runtime verification is recorded in [docs/RECOVERY_REPORT.md](docs/RECOVERY_REPORT.md). Windows graphics and manual playtesting remain unverified.

# DEITY

A playable 3D god simulator for **Godot 4.7.2**. You are an omnipotent deity: you create the land, introduce humanity, then watch civilizations live, gather, build, worship, fight, and fall — or you intervene with unrestricted divine power.

Belief never limits your powers.

## Open in Godot 4.7.2

1. Install [Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) (standard build, not .NET).
2. Launch Godot → **Import** → select `project.godot` in this folder.
3. Press **F5** (or Play). The main menu is the run scene.

Windows export: **Project → Export → Windows Desktop**. Install the 4.7.2 export templates if prompted. `export_presets.cfg` is already included.

Full setup notes: [`SETUP.md`](SETUP.md).

## How to play

**Create a world**

- **New World** → Generated (continents, biomes, trees, wildlife, resources, **no humans**) or Empty (ocean only).
- Sizes: Small / Medium / Large. Medium is the intended default.
- Combine biomes. You can paint different biomes onto the same map in-game.

**Camera**

| Input | Action |
| --- | --- |
| WASD / arrows | Move |
| Mouse wheel | Zoom |
| Right-drag | Rotate |
| Middle-drag | Pan |
| Q / E | Yaw |
| R | Reset pitch/yaw |
| Left click | Use the selected tool |
| Esc | Pause / save / settings |
| Space | Pause simulation |
| 1 / 2 / 3 | 1x / 3x / 8x speed |

**Toolbar**

1. **Terrain** — raise, lower, mountains, valleys, islands, lakes, rivers, biome paint, forests, plants, volcanoes. Brushes have size and strength.
2. **Nature** — trees and animals (pick a species on the bottom row).
3. **Life** — spawn 1 / 5 / 20 humans, inspect.
4. **Civilization** — inspect, boost tech, encourage (grant resources).
5. **Divine Powers** — lightning, tornado, meteor, erupt, smite, rain, storm, snow. No mana.
6. **Religion** — miracle, plague, cure. Belief is simulated; it does not gate tools.
7. **Time** — pause, 1x, 3x, 8x.

Humans do not appear until you spawn them. They gather (resource nodes stay in the world), form settlements, construct buildings, hunt, reproduce, age, and advance through historical eras. Nearby civilizations can go to war. Heretics recruit and can burn temples. Plague spreads and can be cured.

Saves write to `user://saves/*.deity.json` (Godot user data folder). Load from the pause menu or the main menu.

## What is implemented

| System | Status |
| --- | --- |
| Main menu, New / Load / Settings / Exit | Yes |
| Generated + empty worlds, S/M/L sizes | Yes |
| Combinable biomes + in-world paint | Yes |
| Smooth heightmap terrain (not voxels) + brushes | Yes |
| Circular disc world, ocean rim, stylized shaders | Yes |
| Overhead god camera + HUD toolbar | Yes |
| Human spawn, autonomous AI, gathering, building | Yes |
| Civilizations, names, colors, resources, eras | Yes |
| Stone → Modern progression (Stone/Bronze/Iron fully used; later eras restyle) | Yes |
| Wildlife, biome species, hunt, reproduce, extinction | Yes |
| Warfare, death (war, age, smite, plague) | Yes |
| Lightning, tornado, meteor, volcano, rain/storm/snow | Yes |
| Plague + cure with visible infection | Yes |
| Belief, temples, heretics, rebellions | Yes |
| Powers remain available with zero believers | Yes |
| Local save / load | Yes |
| Human incarnation / dialogue | **Not in this build** (hooks only) |

Visuals are stylized low-poly meshes built at runtime (no cubes-as-final-art). Characters are rigged primitives with walk / gather / build / fight / death / torch animations. Buildings change silhouette by era.

## Project layout

```
project.godot
scenes/ui/MainMenu.tscn
scenes/ui/WorldCreate.tscn
scenes/game/GameWorld.tscn
scripts/autoload/   GameState.gd, Gfx.gd
scripts/world/      TerrainWorld.gd, WorldGen.gd, WeatherFx.gd
scripts/entities/   Human, Animal, Building, Settlement, Civilization, ResourceNode
scripts/god/        GodCamera, ToolController, DivineFX
scripts/ui/         menus, HUD
scripts/save/       SaveLoad.gd
assets/shaders/     terrain, water, lava
```

## Performance notes

Human decisions run on a staggered timer, not every frame. Terrain rebuilds dirty chunks only. Vegetation and characters share primitive meshes and cached materials. Distant simulation still updates, but animation cost is small. Large worlds with hundreds of humans are intended for a Windows desktop GPU; use Medium if in doubt.

## License

Project sources are provided as-is for this simulator.
