class_name EconomyData
extends RefCounted
## Gold, population, Diggers, gold rocks and boss timing. Tune here, never in gameplay code.
## There is no passive income: gold comes from Diggers (and a share of every kill).

const START_GOLD: float = 1000.0
const KILL_REWARD_FACTOR: float = 0.3  # killing an enemy pays this share of its cost
const POP_CAP: int = 40

## Hotkeys for the spawn buttons, in the order of UnitData.ALL_ORDER (Digger first, then the army).
const SPAWN_KEYS: Array[Key] = [KEY_T, KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA, KEY_PERIOD, KEY_SLASH]
const SPAWN_KEY_LABELS: Array[String] = ["T", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"]

# --- Diggers and gold rocks ---------------------------------------------------------------------------
const DIGGER_CARRY: float = 50.0  # gold carried home per trip (the Armory "Digger load" upgrade raises it)
const DIGGER_MINE_TIME: float = 4.0  # seconds of swinging the pickaxe per trip
const DIGGER_DEFEND_RANGE: float = 3.0  # a Digger fights back at enemies this close, then goes back to work
const DIGGER_LIMIT: int = 8  # per side
const DIGGERS_PER_ROCK: int = 2
const DELIVERY_Z_FROM_FORTRESS: float = 7.5  # gold is handed over this far in front of the fortress centre

const ROCK_GOLD: float = 1500.0
const ROCK_GOLD_RICH: float = 3000.0  # the two rocks in the middle of the map
const ROCK_MIN_SCALE: float = 0.35  # a nearly empty rock is this fraction of its full size
const ROCKS_NEAR_FORTRESS_MIN: int = 4
const ROCKS_NEAR_FORTRESS_MAX: int = 6
const ROCK_NEAR_X: Vector2 = Vector2(8.0, 25.0)  # |x| range beside the road
const ROCK_NEAR_Z: Vector2 = Vector2(13.0, 29.0)  # distance in front of the fortress centre
const ROCK_SPACING: float = 7.0
const ROCK_MID_X: float = 11.0  # the two rich rocks sit at (+-ROCK_MID_X, 0)

# --- Enemy economy (the enemy buys Diggers too; see scripts/enemy_spawner.gd) ---------------------------
const ENEMY_START_GOLD_BASE: float = 500.0
const ENEMY_START_GOLD_PER_LEVEL: float = 20.0
const ENEMY_TRICKLE_BASE: float = 2.0  # small trickle so a raided enemy never freezes completely (gold per second)
const ENEMY_TRICKLE_PER_LEVEL: float = 0.7
const ENEMY_DIGGERS_BASE: int = 3
const ENEMY_DIGGERS_LEVELS_PER_EXTRA: int = 5  # one more Digger every N levels

# --- Boss timing -----------------------------------------------------------------------------------------
const BOSS_FORTRESS_FRACTION: float = 0.6  # the boss comes out when the enemy fortress drops below this share of its HP...
const BOSS_LATEST_SECONDS: float = 180.0  # ...or after this long, whichever is first
const BOSS_WARNING_SECONDS: float = 5.0
