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
