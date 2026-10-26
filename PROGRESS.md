# Progress

- **Step 1: Battlefield** — flat-shaded valley terrain (120 m between fortresses, dirt road, rocky sides), warm sky,
  mountains, MultiMesh trees/rocks, blob shadows (no real-time shadows), two stone fortresses with HP + HP bar.
  Test: open the project in Godot 4.7.2 and press F5 (runs `scenes/battle.tscn`). In debug builds a screenshot is
  saved to `screenshots/` 3 s after start. `Fortress.take_damage(n)` lowers the HP bar.
  Note: the camera is a temporary overview camera; the hero camera replaces it in step 3.
- **Step 1 fixes** — English only (no Chinese anywhere; CLAUDE.md updated), longer valley (140 m between fortresses),
  48 m wide open grass field with trees/rocks only at the edges, blue gradient sky with drifting low-poly clouds,
  both fortress labels the same on-screen size just above each fortress. Test: press F5.
- **Step 2: Stickman rig** — one reusable armoured stickman: 16-bone Skeleton3D + ONE skinned low-poly mesh per
  unit (1 draw call + outline pass; team colours baked as vertex colours, meshes cached per unit/team). Gear pieces
  (helmets, shoulder plates, chest plates/robes, belts, capes) and weapons (sword, dagger, spear, staff, axe, hammer,
  round + tower shield, bow) come from `UnitData.LOOKS` in `data/units.gd`. Animations (idle, walk, run, attack
  per style swing/thrust/shoot/cast, block, hit, die) are built in code in `scripts/stickman_anims.gd`.
  Test: `godot --path . res://scenes/rig_showcase.tscn` (add `-- --closeup` for a close view); screenshots go to
  `screenshots/`. Use: `var s := Stickman.new(); s.setup("swordsman", 0); add_child(s); s.play("walk")`.
- **Step 2b: Rig look pass** — chunkier stickmen (limbs ~1.6x, head 1.4x, shorter legs), bright gold tabard/cape/plume + steel
  vs deep red tabard/cape/plume + dark iron, all gear skinned to the bones it sits on, thicker dark outline.
  Test: `godot --path . res://scenes/rig_showcase.tscn` saves `screenshots/step2b_*.png` (lineups, far view,
  one frozen mid-attack duel per unit type) and quits.
- **Step 3: Hero** — third-person hero (`scripts/hero.gd`, tuning in `data/hero.gd`): WASD move, Shift sprint, Space dodge roll
  (somersault, invincible for the first 0.42 s), left click 3-hit combo (chop / slash / overhead slam, clicks are buffered,
  light lunge + aim assist), right click block (75% damage cut from the front, slower strafing). Over-the-shoulder camera
  (`scripts/hero_camera.gd`): mouse look (click to capture, Esc to release), scroll zoom. Hits go through the
  `hittable_enemy` group (fortress + 3 debug `TrainingDummy`s in front of the player fortress, replaced in step 4).
  Hero has 150 HP and 3 lives with a 10 s respawn (no HUD yet). Tab tactical view comes in step 7, skills in step 9.
  Test by hand: F5. Scripted test: `godot --path . -- --hero-test` (presses real input actions, saves `screenshots/step3_*.png`,
  prints `HERO-TEST` results: full combo = 62 damage, fortress takes damage, invincible while rolling).
- **Step 4: Units + AI** — `scripts/unit.gd`: any `UnitData` soldier with the shared rig. AI: nearest enemy in aggro range
  (enemy units also hunt the hero), otherwise march on the enemy fortress; walk until in range, attack on cooldown with the
  strike timed to the animation; friends spread out instead of stacking; death anim then the body disappears after 6 s.
  `Battle.spawn_unit(key, team)` spawns at a fortress gate (enemy strength = `UnitData.level_multiplier(level)`). Until the HUD
  and enemy spawner exist (steps 5-6) the battle auto-spawns a swordsman per team every 2.5 s (max 14 each) so you can watch
  armies fight; the hero can join in (`hittable_enemy` group). Scripted test: `godot --path . -- --battle-test` (two armies of 10,
  saves `screenshots/step4_*.png`, prints BATTLE-TEST counts; stays at 60 fps).
