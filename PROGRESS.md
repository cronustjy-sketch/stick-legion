# Progress

- **Step 1: Battlefield** — flat-shaded valley terrain (120 m between fortresses, dirt road, rocky sides), warm sky,
  mountains, MultiMesh trees/rocks, blob shadows (no real-time shadows), two stone fortresses with HP + HP bar.
  Test: open the project in Godot 4.7.2 and press F5 (runs `scenes/battle.tscn`). In debug builds a screenshot is
  saved to `screenshots/` 3 s after start. `Fortress.take_damage(n)` lowers the HP bar.
  Note: the camera is a temporary overview camera; the hero camera replaces it in step 3.
