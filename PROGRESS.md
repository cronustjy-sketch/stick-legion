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
- **Step 11: Main menu, settings, credits, pause** — the game now starts on a title screen (`scenes/main_menu.tscn`): 3D backdrop with the hero and a skirmish,
  Play (-> campaign map), Settings, Credits ("A game by Junyuan"; "Created by Junyuan" is also on the title), Quit (hidden on the web). Settings
  (`scripts/settings.gd`, saved to `user://settings.cfg`): master / music / effects volume (audio buses Music and SFX are created for step 12), mouse sensitivity,
  graphics quality Low / Medium / High (Low = fewer trees and rocks, fewer sparks, no unit outlines), fullscreen. In a battle, Esc opens the pause menu
  (Resume / Settings / Level Select / Main Menu); hold Alt to use the mouse on the HUD buttons. The campaign map has a Main Menu button.
  Tests: `godot --path . -- --menu-test` (menu -> settings -> credits -> Play; saves `screenshots/step11_*.png`),
  `godot --path . res://scenes/battle.tscn -- --pause-test`.
- **Fix: start-up crash** — `settings.gd` called `Stickman.reset_material()` while `stickman.gd` called `Settings`, a circular reference that only broke on a clean
  project cache ("Static function reset_material() not found in base Stickman"). Settings now has a `revision` counter and Stickman rebuilds its shared material
  when it changes, so Settings no longer references Stickman. Verified from a deleted `.godot` cache: clean import (no errors), all 51 scripts and 4 scenes load,
  and `godot --path . -- --flow-test` runs main menu -> Play -> level select -> Start -> battle -> buy a unit with zero errors.
- **Story retrofit, part 1: the four STORY.md bosses** — replaced the placeholder bosses: Level 5 **Grask the Butcher** (huge, two cleavers; charges in straight red corridors and
  spins), Level 10 **Siege Master Volk** (stands on a giant siege engine, lobs boulders, red meteor circles, calls catapults), Level 15 **The Twin Blades, Sera and Kade**
  (two fast duelists; dash and flurry; when one falls the other enrages), Level 20 **Corvin, the Crimson King** (3 phases: greatsword combos + slam; at 66% a ring of red
  elite guards; at 33% he fights alone, faster, under a red sky). Boss taunt banners (appear / defeated / Corvin phase 3 line) are STORY.md's exact words. Aldric now wears his gold scarf.
  Data: `data/bosses.gd`, `data/units.gd` (boss_* keys); code: `scripts/boss.gd`, `scripts/siege_engine_model.gd`. Test: `godot --path . res://scenes/battle.tscn -- --boss-level=5|10|15|20`.
- **Story retrofit, part 2: story cards, chapters, endings (STORY.md)** — `data/story.gd` holds every card in STORY.md's words (22 cards: prologue x4, four chapter intros,
  after-boss cards, the Chapter 3 reveal x4, Mira before level 18, the final choice, both endings, credits). `scripts/story_player.gd` plays them: a posed 3D scene using the real
  stickmen (Aldric with his gold scarf, Mira, King Edmar, young Aldric/Corvin, Corvin), a slow camera pan, typed text at the bottom, click/Space/Enter to advance, Skip button
  (the final choice cannot be skipped). Flow (`scripts/story_flow.gd`): Play shows the prologue the first time; starting level 1/6/11/16 shows the chapter intro, level 18 Mira's line;
  after bosses 5/10/15/20 the victory screen offers Continue into the next cards; the final choice (Spare him / End it) leads to the Brothers or the Crown ending, then "A game by Junyuan",
  and unlocks Endless Mode (button on the campaign map; levels 21+). Seen cards and endings are saved; main menu has a Story button (replay seen cards) and "Endings x / 2".
  Chapters (4 x 5 levels, names on the map) and unit unlock levels now follow STORY.md (archer 2, spearman 3, shield knight 4, mage 6, assassin 7, priest 8, giant 11, cavalry 12,
  catapult 13; locked spawn buttons show "Level N"). Mira's random tip on the map. HUD calls the hero Aldric. Scripted tests never touch the save file (`GameState.persist`).
  Tests: `godot --path . res://scenes/story.tscn -- --story-test` (shows all cards, `screenshots/story_card_*.png`);
  `... story.tscn -- --story-ending=spare` / `--story-ending=end` (final choice + ending flow); `... battle.tscn -- --boss-level=15` ends by pressing Continue.
- **Step 12: Sound effects and music** — every sound is synthesised, not sampled: `tools/make_audio.gd` (run `godot --headless --path . --script res://tools/make_audio.gd`)
  writes 26 effects and 4 music loops (menu, battle, boss, story) as WAV files to `audio/` (committed, 3.6 MB). `AudioHub` (autoload, `scripts/audio_hub.gd`) plays them through the
  SFX / Music buses (the volume sliders in Settings control them) with a voice pool, rate limiting, distance fade, and music crossfades; game scripts use the static `Sfx`
  (`scripts/sfx.gd`). Sounds: UI clicks, buying a unit, orders, sword swings/hits/blocks, hero hurt/death, all skills, arrows, fireballs, boulders, explosions, healing, unit deaths, fortress
  cracks and the shield zap, boss warnings / blasts / roars, victory and defeat stingers. Music: menu + map, battle, boss levels, story cards.
  Test: `godot --path . res://scenes/battle.tscn -- --audio-test` (prints which effects played during a fight and the active music).
- **Step 13 (part 1): phone controls** — `scripts/touch_controls.gd`: left joystick (push to the edge to sprint), Attack / Roll / Block buttons, Map (tactical view) toggle, Pause,
  drag on the right side to look around; skill slots, orders and unit buttons are tappable HUD buttons. Shown automatically on mobile browsers, or set Touch controls to "Always on" in
  Settings. Test: `godot --path . res://scenes/battle.tscn -- --touch --touch-test`.
- **Step 13: Web export, tested in a browser and at phone size** — Web preset in `export_presets.cfg` (single-threaded, Compatibility renderer, so it runs on any static host without special headers),
  `tools/export_web.ps1` (build to `build/web/`, 40 MB: 39.5 MB engine wasm + 1 MB game data) and `tools/serve_web.ps1` (local test server, http://localhost:8080). Verified in Chromium:
  title screen with animated 3D backdrop (Quit hidden on the web), Play -> story cards -> campaign map (progress saved in the browser) -> battle with HUD and locked unit buttons.
  At phone size (844x390) with `?touch=1` the touch controls appear and fake touches moved the hero with the joystick and attacked. Touch controls turn on automatically when the main pointer is
  a finger (`(pointer: coarse)`), or with `?touch=1` in the address; phones never try to capture the pointer. See README.md for how to host the build.
- **Published**: the Web build is live on GitHub Pages at https://cronustjy-sketch.github.io/stick-legion/ (branch `gh-pages`, files from `build/web/` plus `.nojekyll`; the `main` branch is unchanged
  by deploys). To update: re-export, copy `build/web/*` into a `gh-pages` checkout, commit, push.
- **Polish pass** — Aldric (`hero` look): no tabard; steel plate armour with back plate, faulds, bracers, greaves and knee plates, a short dark-gold cape and a long gold scarf
  (4 ribbon segments on extra bones, driven in `Stickman._process`: it streams out behind him when he moves and sways when idle); sword visible. Default camera distance 4.8 -> 6.6 (zoom unchanged).
  Fortresses are 98 m apart (was 140) and the terrain/props/orders scale with `FORTRESS_Z`; every battle starts with 4 swordsmen at the gate; the hero spawns outside the gate (the camera used to end up
  inside the walls). The controls panel shows for the first 10 s of level 1 only; a "?" button (top right) toggles it. Fight feel: sparks, bigger hero-hit screen shake, damage numbers (already in), and
  units are thrown back with a small hop when they die. Boot splash, web loading screen and favicon: gold "STICK LEGION" + a low-poly stickman with a gold banner (`ui/splash_art.svg`, `tools/make_splash.gd`
  -> `ui/splash.png`, `icon.svg`; the loading bar is gold, styled via the Web preset's head include). Tests: `battle.tscn -- --start-test`, `-- --look-test` (screenshots of Aldric from behind/side/front).
- **Custom domain** legion.cronuschores.xyz: `CNAME` is on the gh-pages branch and is re-added by every deploy (`tools/deploy_pages.ps1`, source file `tools/pages/CNAME`).
- **Fix: camera glitch while moving (phones/browsers)** — the hero moved on the fixed 60 Hz physics tick while the camera followed in the render frame, so at 30/45/90 fps (phones) he advanced in uneven steps and the
  camera stuttered. The hero now moves every rendered frame (`Hero._process` -> `_tick`) and the camera follow is frame-rate independent (`1 - exp(-14 dt)`). Measured with `-- --touch --jitter-test` at 45 fps:
  hero step spread 2.7 -> 0.0 m/s; camera spread ~7 -> 0.3 m/s.
- **Fix: camera turning when the joystick moves (phones)** — phone browsers add an emulated mouse motion to every finger drag; if the pointer counted as "captured" (e.g. after closing the pause menu) the
  joystick finger spun the camera. The camera now ignores mouse motion whenever touch controls are active, and the pause menu no longer captures the pointer on phones. Test: `battle.tscn -- --touch --joy-test`
  (before: pitch moved -25 deg while the joystick moved; after: 0).
- **Language (English / 中文) and sound on/off** — Settings has a Language list (English, 中文) and a Sound On/Off button (mutes everything), both saved. Every UI string goes through `Loc.t()` / `Loc.f()`;
  the Chinese text is in `data/translations.gd` (HUD, menus, settings, level and chapter names, unit and skill names, all story cards, boss names and taunts). Picking a language in the main menu or map rebuilds the screen
  at once; in a battle's pause menu it applies to the next screen. A bundled subset of Noto Sans SC (`ui/fonts/cjk_subset.ttf`, 197 KB, OFL licence) is the fallback font, so Chinese shows in browsers too.
  `?lang=zh` in the web address opens the game in Chinese. Tests: add `--lang=zh` (e.g. `godot --path . -- --lang=zh --menu-test`). CLAUDE.md now says English by default with a Chinese option.
- **Auto aim + faster attacks** — pressing attack now instantly turns the hero to the best enemy within 6.5 m in ANY direction (beside or behind too; enemies in front are preferred, units before the fortress), re-aims right
  before the blow lands, and "magnetism" lunges him up to 13 m/s to close the gap. Swings are faster (attack speed 1.25 -> 1.6) and chain into the next swing at 72% of the animation; holding the Attack button
  (touch) or the mouse button keeps swinging. Test: `battle.tscn -- --aim-test` (enemies at 90, 180 and -100 degrees all get hit by one press; holding attack = 8 swings in 3 s, was ~5).
