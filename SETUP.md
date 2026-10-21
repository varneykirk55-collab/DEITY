# DEITY — Setup (Godot 4.7.2)

## Requirements

- Windows 10/11 PC (the target platform)
- [Godot 4.7.2 standard](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)  
  Download `Godot_v4.7.2-stable_win64.exe.zip`
- Optional: 4.7.2 export templates for a standalone `.exe`

The project uses GDScript only (not the .NET build).

## Run from source

1. Unzip this repository.
2. Open Godot 4.7.2.
3. **Import** → choose `project.godot`.
4. Renderer should be **Forward Plus** (set in `project.godot`).
5. Press **Play** (F5).

If the editor asks to generate `.uid` files or import the SVG icon, accept. That is normal on first open.

## First session (acceptance)

1. **New World** → Generated → Medium → keep the default biomes → **Create World**.
2. Confirm: land, water, trees, animals. **No humans.**
3. Terrain tab: raise an island, paint a desert next to grass.
4. Life tab: spawn a crowd of humans on land.
5. Speed 3x. Watch them walk, gather (trees/rocks remain), and form a named settlement with buildings.
6. Nature tab: spawn animals. Hunt happens when a civ needs food. If you smite every animal of a species, it stays extinct until you spawn it again.
7. Divine Powers: lightning, meteor, tornado. Religion: plague a group, then cure.
8. Esc → **Save World**, quit, **Load World** — the same terrain, people, and civs return.

Empty World: New World → Empty → Create. You get ocean. Use Island / Raise / Mountain to sculpt, then spawn life.

## Exporting a Windows build

1. In Godot: **Editor → Manage Export Templates** → install 4.7.2.
2. **Project → Export → Windows Desktop** (preset included).
3. Export to `build/DEITY.exe` with **Embed PCK** enabled.

## Save location

Godot user data, not the repo folder:

- Windows: `%APPDATA%/Godot/app_userdata/DEITY/saves/`
- Files: `*.deity.json`

## Troubleshooting

- **Pink terrain / water:** shaders failed to import. Reopen the project so `assets/shaders/*.gdshader` import.
- **No shadows / dark world:** GPU without Forward Plus — Project Settings → Rendering → Renderer → `gl_compatibility` (visuals will be simpler).
- **Slow Large maps:** use Medium, or Time → 1x, and avoid huge forest brushes.
- **Load list empty:** save at least once from the in-game pause menu.

## Not in this build

Human incarnation (third-person walk) and speaking with individuals are reserved. See `scripts/game/FutureHooks.gd`. Divine powers stay unrestricted regardless.

## Recovery verification

See [RECOVERY_REPORT.md](docs/RECOVERY_REPORT.md) for repairs, passed runtime tests, remaining feature gaps and the Windows visual acceptance boundary. Run `python tools/verify.py "PATH_TO_GODOT_EXECUTABLE"` to repeat the automated checks. Nature → Clear Plants removes trees/bushes. The original branch has not been merged.
