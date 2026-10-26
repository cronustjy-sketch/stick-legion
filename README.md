# Stick Legion

A 3D stickman war game made with Godot 4.7.2 (Compatibility renderer, GDScript). You are **Aldric**, a stickman hero in third person,
fighting on the battlefield while commanding an army that spawns from your fortress. Destroy the enemy fortress to win.
Created by **Junyuan**.

**Play it in your browser: <https://cronustjy-sketch.github.io/stick-legion/>** (works on phones too; the first load downloads about 40 MB).

## Controls

| | Keyboard + mouse | Phone |
|---|---|---|
| Move / sprint | WASD / Shift | left joystick (push to the edge to sprint) |
| Attack (3-hit combo) | left click | Attack button |
| Block | right click | Block button |
| Dodge roll | Space | Roll button |
| Skills | Q E R F, ultimate G (full rage) | tap the skill slots |
| Look / zoom | mouse / scroll | drag on the right side |
| Army orders | 1 Charge, 2 Hold, 3 Follow, 4 Retreat | tap the order buttons |
| Buy units | Z X C V B N M , . / | tap the unit buttons |
| Tactical view | hold Tab | Map button |
| Pause / menu | Esc (hold Alt to use the mouse on the HUD) | II button |

## Run it

Open the project in Godot 4.7.2 and press F5 (starts on the main menu), or:

    godot --path .

## Web export

1. Install the Godot 4.7.2 **export templates** (Editor > Manage Export Templates).
2. `powershell -ExecutionPolicy Bypass -File tools/export_web.ps1 -Godot "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"`
   (or use Project > Export > Web). The build goes to `build/web/` (single-threaded, so it works on any static host).
3. Test it locally: `powershell -ExecutionPolicy Bypass -File tools/serve_web.ps1`, then open <http://localhost:8080>.
4. Upload the contents of `build/web/` to any static host (itch.io "HTML5" project, GitHub Pages, Cloudflare Pages, ...).

The public copy lives on the `gh-pages` branch (GitHub Pages). To update it after a new export, copy the files of `build/web/` into a checkout of that branch (plus an empty `.nojekyll` file), commit and push.

## Sound

All sound effects and music are synthesised by `tools/make_audio.gd` (no samples); the generated WAV files are in `audio/`.

## Project notes

`CLAUDE.md` is the design brief, `STORY.md` the story, `PROGRESS.md` the build log.
