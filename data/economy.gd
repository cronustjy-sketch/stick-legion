class_name EconomyData
extends RefCounted
## Gold and population rules. Tune here, never in gameplay code.

const START_GOLD: float = 100.0
const INCOME_PER_SECOND: float = 10.0
const KILL_REWARD_FACTOR: float = 0.5  # killing an enemy pays this share of its cost
const POP_CAP: int = 40

## Hotkeys for the spawn buttons, in the order of UnitData.HUMANOID_ORDER.
const SPAWN_KEYS: Array[Key] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M]
