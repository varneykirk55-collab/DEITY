# DEITY recovery and stabilization

Source: `varneykirk55-collab/god-sim`, branch `arena/d6ff7d74-god-sim`, commit `85d3f2b56c394ccfdcc9405d3e644a70ca789d16`.
Repair branch: `astra/deity-recovery`. The original branch and `main` are not changed or merged.

## Verification boundary

Tested with the official **Godot 4.7.2.stable.official.ed1daf0bf**, Linux x86_64, using the actual engine in headless mode. This is runtime execution, not just source inspection. Editor import, main-menu startup, world-scene startup, and both automated suites pass. The suites contain **96 behavioral checks** (76 recovery + 20 controls/stress); final logs are in `docs/test-results/`.

**Not fully visually or Windows verified.** This environment has no working graphical display/GPU setup. Installing a virtual display through the package manager failed because of environment process-permission restrictions. No Windows executable export, Windows GPU run, manual mouse playthrough, shader-rendered screenshot, or visual animation approval is claimed. Headless execution does not compile/render all GPU paths. Actual visual quality and Windows playability remain acceptance gates.

## Reproduced startup causes

1. `TerrainWorld.gd`: `cone` and `hgt` used inferred types on expressions containing Variant-returning numeric functions; cursor scale also inferred Variant with the warning treated as an error.
2. `HUD.gd`: closure capture variables inferred from untyped array iteration values could not be typed.
3. `Human.gd`: terrain height inferred through a dynamically typed world object could not be typed.
4. `WorldGen.gd`: the land-height expression could not infer a concrete type.
5. `WorldCreate.gd`: `_set_size(int)` conflicted with native `Control._set_size(Vector2)`. This blocked New World even when launching the game scene directly appeared successful.
6. The failed dependencies cascaded into failed GDScript construction and repeated calls on a null terrain. These were consequences of failed compilation, not missing implementations of `new` or `get_biome`.

Repairs add concrete types at the failing sites and rename the world-size selection method. Warning handling remains enabled. No gameplay system was disabled to suppress the failures.

## Significant repairs

| Area | Problem and repair |
|---|---|
| Human cleanup | Dead humans were removed from the only group receiving simulation ticks, leaving their death/cleanup code unreachable. Their own process callback now completes death cleanup. |
| Pause and resume | The pause overlay did not pause the clock. It now preserves/restores previous pause state and cancels dragging. Toolbar Pause preserves selected speed so Space resumes correctly; camera movement is blocked behind the pause menu. |
| Work and construction | Frequent AI reconsideration replaced work/build destinations before arrival. Actors retain valid actions. Gathering prioritizes missing construction supplies instead of repeatedly taking the nearest material. Build sites reject water. |
| Human reproduction | Newborns already joined a civilization during spawning, bypassing the old child-age assignment. Newly allocated IDs now identify births correctly. |
| Plague | Recasting plague reset existing infection timers. Existing infections now retain progress, including after save/load. Cure clears infections. |
| Movement | Simulation uses bounded substeps at accelerated speeds. Human movement limits overshoot, checks land and tries shoreline steering; blocked actors reconsider. Land animals check the next step instead of only their destination. |
| Rendering state/performance | Civilization materials only update when era, color, or heretic status changes. This also fixes same-era identity changes being ignored. Weather emission flags only update when biome weather changes. Spread passes reuse their human lists. |
| Terrain | Brush edits at chunk corners invalidate all four affected chunks. Empty outer chunks skip mesh construction. Picking covers zoomed-out Large worlds and rejects hits outside the world disc. |
| Water mesh | A mesh-normal assertion reproduced downward-facing normals. Triangle winding is corrected and degenerate center-ring triangles removed. Terrain and water top normals pass engine checks. |
| Effects | Expired meteors are freed even without an impact. Meteor trails now have a draw mesh; burst/tornado materials use their configured color; lightning renders from both sides. Rendered appearance remains unverified. |
| Wildlife | Automatic spawning uses species supported by the biome and no longer silently substitutes forest species for unsupported biomes. Land placement rejects water. Extinction does not trigger replacement spawning. |
| Vegetation | Added the missing Clear Plants action under Nature, removing trees and bushes within the brush while preserving stone/ore. Normal gathering continues to preserve resource visuals. |
| Temples | Settlement temple status is recomputed from active, non-burning temples rather than remaining permanently true after destruction. |
| Save/load | Rebuilds terrain chunks/water/underside/cursor for the loaded dimensions; reconfigures camera and weather. Restores infection elapsed time, gender, warrior weapon visibility, construction progress/kind/radius, building HP/burning time, civilization color sequence, world RNG state, bushes and volcano visuals. Existing saves use defaults for newly recorded fields. Save names use filename validation. |
| Repeatability | Added engine-driven regression scenes and a Python runner that rejects nonzero exits, missing summaries, engine errors, warnings, and timeouts. Generated resource/script UID files are retained. |

## Test matrix

| System | Result and scope |
|---|---|
| Editor/main scene | PASS: imports and runs without reported engine errors/warnings. |
| New World | PASS: configuration scene instantiates, both modes and all three size selectors work. |
| Generated worlds | PASS: all sizes generate terrain/nature, multiple biomes, no humans. Fixed-seed coverage, not every seed. |
| Empty world/editing | PASS: ocean start, no nature; raise/lower/island/mountain/valley/lake/volcano/biome brushes, mesh normals and chunk invalidation. River tool is source-reviewed, not independently asserted end-to-end. |
| Nature | PASS: forest/plants, clearing, persistent gathering sources, births, extinction, reintroduction and hunting. |
| Civilizations | PASS: grouping, distinct civilizations, movement, resource delivery, construction, child age, aging/death, all era transitions and building era refresh. Autonomous gathering/construction/progression tested over 120 simulated seconds on controlled land. |
| Religion | PASS: miracle belief increase, temple selection at strong belief, recruitment, majority rebellion state, temple burning and status update. Long-run religious balance remains unverified. |
| Powers | PASS: lightning/eruption execute; tornado/meteor creation and expiry; plague spread through extinction; cure and miracle state changes; rain/storm/snow override states. Visual effects are NOT approved by these tests. |
| Controls | PASS: simulated WASD input, zoom/rotation/pan handlers, toolbar signal, crowd placement, 8x selection and pause/resume. Physical desktop input/manual UX remains untested. |
| Saves | PASS: real JSON write/read, different-size reload, terrain, people, infection, construction, buildings/burning, wildlife, resources, vegetation and civilization era. |
| Stability | PASS: bounded Large-map run with 200+ humans at 8x, no reported errors; death and effect cleanup assertions. No unlimited-population, hours-long soak or FPS guarantee. |
| Windows export/rendering | UNTESTED: Windows runtime, export templates, GPU shader compilation, display scaling, graphical frame rate and visual appearance. |

Initial regression failures were resolved: world-size method collision, water normals and input-test event scheduling. The original plague extinction assertion was too early to include later infections/births; extending to 120 simulated seconds verified eventual extinction. No final behavioral test is marked failed.

## Remaining limitations and incomplete design requirements

- Rain and snow remain visual weather; storms flash light but do not cause independent lightning damage. The separate lightning power does damage. Full ecological weather consequences were not present and are not claimed complete.
- Historical eras update clothing/materials and equipment and restyle buildings, but later-era buildings largely reuse existing silhouettes. Fully distinct Modern Age architecture is incomplete; no graphical redesign was undertaken.
- Navigation is local steering, not pathfinding across complex islands. Isolated resources and major terrain edits can strand citizens. Existing static buildings/resources do not automatically re-anchor to every terrain edit.
- Terrain rivers/lakes are height edits with a global sea-level water surface, not hydrological simulation or elevated inland water.
- Supported animal species do not cover every biome; unsupported environments can correctly have no automatic wildlife. Births are simplified and the original simulation lacks detailed mating/childhood systems.
- Religion retains simplified probabilistic behavior; temples can be burned by individual heretics as well as majority rebellions. Formal rebel factions and takeover outcomes are not a complete political simulation.
- Warfare targeting is tested. Full conquest transfer has pre-existing limitations (including defeated-civilization handling) and is not certified.
- Spread/nearest-neighbor searches still scale poorly at very high populations. The 200+ test establishes bounded behavior, not arbitrary scalability or rendered FPS.
- Save/load restores durable world state, not exact in-flight action targets, particles, temporary weather, camera position or per-agent RNG streams. Malformed external save schema recovery is not comprehensively hardened. Keep backups of valuable saves.
- Human incarnation and dialogue remain intentionally unimplemented in `FutureHooks.gd`.

## Run and reproduce

Open `project.godot` in Godot 4.7.2 standard and press F5. Use New World, select a size/biomes, and Create World. Life → Crowd places humans on land. Nature → Clear Plants removes vegetation. Use the Divine Powers and Religion tabs for powers. WASD moves, wheel zooms, RMB rotates, MMB pans, Esc opens the pause/save menu. Space pauses/resumes; 1/2/3 select 1x/3x/8x.

Optional automated verification from the repository root:

```text
python tools/verify.py "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

Linux uses the equivalent executable path. Each test run writes logs under `docs/test-results`. Tests create and remove a save named `__recovery_smoke__`; do not use that name for a personal world. See `SETUP.md` for normal save locations and Windows export instructions.
