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
- **Step 5: HUD** — gold (+10/s, kill rewards = half the enemy unit cost), population cap 40, fortress HP bars, hero HP + lives,
  spawn buttons with rendered unit portraits (hotkeys Z X C V B N M, dimmed when unaffordable, toast "Not enough gold" / "Population full"),
  skill slots Q E R F + G rage bar (placeholders until step 9). Panels are pinned to screen corners so they never go off-screen.
  Mouse is captured while playing: Esc frees it so the buttons can be clicked. Test: `godot --path . -- --hud-test` (saves `screenshots/step5_*.png`).
- **Step 6: Enemy spawner, win/lose, levels** — `scripts/enemy_spawner.gd` (enemy earns gold, buys cheap-weighted units from the level pool
  up to its pop cap; rules in `data/levels.gd`: swordsman L1, +spearman L2, +archer L3, +shield knight L4, ...; strength x(1+0.11(L-1))).
  Enemy fortress destroyed = VICTORY (unlocks next level, saved to `user://stick_legion.cfg`), your fortress destroyed or hero out of
  lives = DEFEAT; overlay with Next Level / Retry reloads the battle. HUD shows the level and a hero respawn countdown.
  Test: `godot --path . -- --level-test` (saves `screenshots/step6_*.png`, prints LEVEL-TEST results). Main menu / level select: step 10-11.
- **Step 7: Orders, tactical view, health bars** — army orders on keys 1-4 and the "Army orders" panel: Charge (attack enemies, then march on the
  enemy fortress), Hold (form a line in front of your fortress, only fight enemies that come close), Follow (formation behind the hero, fights
  nearby enemies), Retreat (back to the gate, no fighting, heals 8% HP/s). New units obey the current order. Hold Tab for the tactical view: the camera
  rises high over the field, units show big gold/red discs, the hero stands still. Every enemy now has a health bar over its head (allies show one once hurt).
  Test: `godot --path . -- --orders-test` (prints ORDERS-TEST positions/healing, saves `screenshots/step7_*.png`).
