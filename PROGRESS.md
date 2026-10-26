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
- **Step 8: All 10 unit types** — Swordsman, Archer (arrows on an arc, backs away from close enemies), Spearman (x2 vs big units), Shield Knight (35% armour,
  frontal shield blocks arrows), Mage (fireball, 2.5 m splash), Assassin (30% crit x2), Priest (heals the most wounded friend/hero 16 HP), Giant (2.1x scale,
  ground smash 3.2 m + knockback), Cavalry (horse + lance rider, first hit after a run-up deals x2), Catapult (boulders, 3 m splash, x2 vs fortresses).
  Specials are driven by keys in `data/units.gd`; projectiles in `scripts/projectile.gd`; visuals via `VisualFactory` (stickman rig, `cavalry_model.gd`, `catapult_model.gd`).
  HUD has all 10 spawn buttons (Z X C V B N M , . /); enemy levels bring cavalry (L5), giant (L7), catapult (L9).
  Test: `godot --path . -- --units-test` (prints UNITS-TEST results, saves `screenshots/step8_*.png`).
- **Step 9: Hero skills + hit effects** — Q Whirlwind (3 spins, 3.6 m), E Shield Dash (invincible charge + knockback), R War Cry (heals hero + nearby army,
  army damage +35% for 8 s), F Ground Slam (5 m area + knockback), G Legion Wrath (full rage meter: 10 m blast, heals army, +40% damage for 10 s).
  Rage fills when the hero deals/takes damage. All values in `data/hero.gd` (SKILLS, RAGE). HUD skill slots show key, name and a cooldown cover; rage bar beside G.
  Effects (`scripts/effects.gd`): spark bursts on hits, floating damage numbers (white hits, gold heavy, red when the hero is hurt, green heals), expanding rings
  for area skills, camera shake (`HeroCamera.shake`), and a fading sword trail (`scripts/weapon_trail.gd`).
  Test: `godot --path . -- --skills-test` (prints SKILLS-TEST results, saves `screenshots/step9_*.png`).
- **Step 10: Bosses, 20-level campaign, level-select map** — the game now starts on the campaign map (`scenes/level_select.tscn`, click a level or use
  arrow keys + Enter; boss levels are the big red nodes; progress is saved). 20 named levels (`data/levels.gd`): enemy strength x(1+0.11(L-1)),
  enemy fortress HP +8% per level, new enemy unit types as you go. Levels 5/10/15/20 are boss fights (`data/bosses.gd`, `scripts/boss.gd`): a huge warlord with
  telegraphed attacks (red circles that fill up before the blow: slam, sweep, meteors, summon), phase 2 at 50% HP (faster, more attacks, "enraged"),
  a boss health bar at the top, and the enemy fortress is behind a blue shield dome until the boss dies. End screens offer Next Level / Retry / Level Select;
  winning level 20 shows CAMPAIGN COMPLETE.
  Tests (battle tests now need the scene: `godot --path . res://scenes/battle.tscn -- --boss-test`): `--boss-test` (BOSS-TEST lines, `screenshots/step10_*.png`);
  `godot --path . -- --select-test` (the map, then starts level 7).
