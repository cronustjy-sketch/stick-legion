# CLAUDE.md — Stick Legion (working title) · 3D stickman war game

## What this game is
A **3D stickman war game**. You play a **stickman hero in third person** and fight on the battlefield yourself,
while you **command a stickman army** that spawns from your fortress and fights the enemy army.
Destroy the enemy fortress to win. Lose if your fortress falls or your hero runs out of lives.

This is a NEW game, separate from Ink Blade (墨刃纪元). Never edit any other project.
Creator credit in-game must read **"Junyuan"**. UI text: Chinese with English underneath.

## Engine and target
- **Godot 4.7.2**, standard build, **GDScript only**, static typing (`var hp: float = 60.0`).
- Renderer: **Compatibility** (OpenGL). The dev laptop is an Intel Iris Xe with 16 GB RAM, so it MUST run smoothly there.
- Target: **Web export first** (playable from a link on PC and phone), Windows export second.
- Performance budget: 60+ units on screen at 60 fps on Iris Xe. Low-poly meshes, few draw calls, no real-time shadows
  (use blob shadows), no heavy post-processing. Use MultiMesh or shared meshes/materials for soldiers if needed.
- You are connected to the Godot editor via the `godot` MCP server (run_project, get_debug_output, etc.).

## Art style: low-poly realistic stickmen
- Soldiers are **stick figures with real gear**: dark grey/black stick body (cylinder limbs, sphere head) wearing
  **low-poly armour pieces**: helmets, shoulder plates, chest plates, belts, capes. Each unit type has a clear silhouette.
- Weapons are detailed low-poly models: swords, spears, bows, shields, axes, hammers, staffs.
- Team colours on cloth and trim: **player = gold `#e8b44a` + steel**, **enemy = red `#de4b3f` + dark iron**.
- Flat-shaded / toon materials with a thin dark outline. World is semi-realistic low-poly:
  grass fields, rocks, trees, fortresses with stone walls and towers, mountains in the distance, warm sky.
- Build stickmen **from primitives in code or as .tscn scenes** with a bone-like Node3D hierarchy so they can be
  animated with AnimationPlayer (walk, run, attack, block, hit, die). Make one base rig, reuse it for every unit.
- Existing models from the Ink Blade repo may be reused if they fit (hero_anim, warden_anim, colossus_anim,
  faceless_anim, ender, pk, dragon, sw_* swords). Copy them in; never edit the Ink Blade repo.
  They render dark unless their texture is ALSO used as emission (~0.22) and normals are regenerated.

## Core gameplay
**Battlefield:** a wide 3D valley about 120 m long. Player fortress at one end, enemy fortress at the other.
Open terrain with some cover (rocks, ruins, trees), so it's not just one straight line.

**Hero (third person):**
- WASD move, Shift sprint, Space dodge roll (short invincibility), left click attack (3-hit combo), right click block.
- Skills on Q / E / R / F with cooldowns, ultimate on G when the rage meter is full.
- Camera: over-the-shoulder, mouse to look, scroll to zoom. Hold Tab for a **tactical view** (camera rises high above
  the battlefield) where you can see the whole fight and give orders.
- If the hero dies, he respawns at the fortress after 10 s (3 lives per battle).
- Phone: left joystick to move, buttons for attack / dodge / block / skills.

**Army:**
- Gold is earned over time (+10/s) and by killing enemies. Spend gold to spawn units at your fortress.
- Army cap: 40 population (big units cost more pop).
- Orders (keys 1-4 and buttons): **Charge** (attack enemy fortress), **Hold** (defend a line in front of fortress),
  **Follow** (army follows the hero in formation), **Retreat** (return and heal).
- Units fight with simple, readable AI: find nearest enemy in range, attack on cooldown, ranged units keep distance.

**Starting unit roster** (stats are a starting point, tune by playtesting):
| Unit | HP | DMG | Range (m) | Speed (m/s) | Cooldown | Cost | Pop | Notes |
|---|---|---|---|---|---|---|---|---|
| Swordsman 剑兵 | 60 | 10 | 1.2 | 3.0 | 0.9 | 20 | 1 | cheap melee |
| Archer 弓手 | 36 | 9 | 18 | 2.6 | 1.35 | 30 | 1 | arrows with arc |
| Spearman 长枪兵 | 75 | 12 | 2.2 | 2.8 | 1.1 | 35 | 1 | ×2 vs big units |
| Shield Knight 盾卫 | 240 | 15 | 1.3 | 2.2 | 1.0 | 45 | 1 | 35% armour, blocks arrows |
| Mage 法师 | 42 | 15 | 14 | 2.2 | 2.0 | 60 | 1 | splash 2.5 m |
| Assassin 刺客 | 48 | 20 | 1.0 | 5.5 | 0.6 | 50 | 1 | 30% crit |
| Priest 牧师 | 55 | 0 | 10 | 2.5 | 1.4 | 55 | 1 | heals allies 16 |
| Giant 巨人 | 620 | 38 | 2.8 | 1.4 | 2.2 | 150 | 3 | AOE smash + knockback |
| Cavalry 骑兵 | 170 | 20 | 1.6 | 7.0 | 1.0 | 90 | 2 | charge ×2 first hit |
| Catapult 投石车 | 220 | 50 | 35 | 1.2 | 4.2 | 140 | 3 | ×2 vs fortress |

**Levels:** a campaign of short battles. Each level raises enemy strength
(`enemy multiplier = 1 + 0.11 × (level − 1)`), adds new enemy unit types, and every 5th level has a **boss**
(a huge stickman warlord with special attacks, telegraphed with red ground markers, and a phase 2 at 50% HP).
The enemy fortress is shielded while the boss is alive.

## Rules for the agent
- Keep all unit, hero and level stats in `data/*.gd` dictionaries so balance changes never touch gameplay code.
- Do ONE build step at a time. After each step:
  1. Run the project with the Godot MCP and fix every error in the debug output.
  2. Take a screenshot (debug feature that saves to `screenshots/` a few seconds into gameplay), LOOK at it, and fix
     anything that looks wrong or ugly before moving on.
  3. Test the real path a player takes (main menu → level select → battle), not just one scene.
  4. Commit with "Step N: <name>" and push. Add a line to `PROGRESS.md` saying what was done and how to test it.
- If stuck on something for a long time, write it in PROGRESS.md, skip it, continue.
- Don't touch `.godot/`. Commit `.import` files.

## Folder layout
```
res://
  scenes/    main_menu, level_select, battle, hero, unit, fortress, hud
  scripts/   one script per scene + ai/, combat/
  data/      units.gd, hero.gd, levels.gd, bosses.gd
  models/    rigs, armour pieces, weapons, imported .glb
  ui/        fonts, icons
  screenshots/
```

## Build order
1. Battlefield: terrain, sky, lighting, two fortresses with HP, blob shadows. Screenshot check.
2. Stickman rig: one reusable low-poly armoured stickman with walk / run / attack / hit / die animations.
3. Hero: third-person controls, camera, 3-hit combo, dodge, block.
4. Units + AI: data/units.gd, spawn swordsmen for both teams, they fight and die.
5. HUD: gold, pop, spawn buttons with unit icons, hero HP, fortress HP bars, skill buttons.
6. Enemy spawner + win/lose screens + level progression.
7. Orders (Charge / Hold / Follow / Retreat) + tactical view on Tab.
8. All 10 unit types with their gear and specials (arrows, splash, heal, armour, AOE, charge, catapult).
9. Hero skills Q / E / R / F and the G ultimate, with hit effects (sparks, trails, screen shake, damage numbers).
10. Bosses every 5 levels + 20-level campaign + level-select map.
11. Main menu, settings (volume, graphics quality), credits "Junyuan".
12. Sound effects and music.
13. Web export, test on phone.
