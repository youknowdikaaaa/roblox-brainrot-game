-- Config: every tuning number for Brainrot Bay lives here, so the
-- other modules never hard-code a price, a timer or a map coordinate.
-- The map layout must match default.project.json: the conveyor runs
-- along X at Z = -20, and the eight base plots sit in two rows.

local Config = {}

-- Money
Config.START_CASH = 150
Config.INCOME_TICK_SECONDS = 1
Config.SELL_REFUND_FRACTION = 0.5

-- Conveyor (brainrot spawner walkway)
Config.CONVEYOR_START_X = -58
Config.CONVEYOR_END_X = 58
Config.CONVEYOR_Z = -20
Config.CONVEYOR_Y = 1
Config.CONVEYOR_SPEED = 3 -- studs per second
Config.SPAWN_INTERVAL_SECONDS = 7
Config.MAX_ON_BELT = 8

-- Bases: one plot per player, six brainrot slots each.
-- Plot centers, in the same order as Plot1..Plot8 in the place file.
Config.PLOT_CENTERS = {
	Vector3.new(-54, 0, -75),
	Vector3.new(-18, 0, -75),
	Vector3.new(18, 0, -75),
	Vector3.new(54, 0, -75),
	Vector3.new(-54, 0, 75),
	Vector3.new(-18, 0, 75),
	Vector3.new(18, 0, 75),
	Vector3.new(54, 0, 75),
}
Config.PLOT_HALF_WIDTH = 12
Config.PLOT_HALF_DEPTH = 10
Config.SLOTS_PER_BASE = 6
-- Slot offsets inside a plot, two rows of three.
Config.SLOT_OFFSETS = {
	Vector3.new(-7, 0, -4),
	Vector3.new(0, 0, -4),
	Vector3.new(7, 0, -4),
	Vector3.new(-7, 0, 4),
	Vector3.new(0, 0, 4),
	Vector3.new(7, 0, 4),
}

-- Stealing
Config.LOCK_DURATION_SECONDS = 60
Config.LOCK_COOLDOWN_SECONDS = 120
Config.CARRY_WALK_SPEED = 12
Config.NORMAL_WALK_SPEED = 16
Config.SLAP_DISTANCE = 6 -- owner this close to a thief drops the catch

-- Events
Config.WAVE_FIRST_AFTER_SECONDS = 150
Config.WAVE_EVERY_SECONDS = 180
Config.WAVE_WARN_SECONDS = 10
Config.WAVE_SWEEP_SECONDS = 25
Config.WAVE_CASH_LOSS_FRACTION = 0.05
Config.GOLDEN_FIRST_AFTER_SECONDS = 240
Config.GOLDEN_EVERY_SECONDS = 300
Config.GOLDEN_DURATION_SECONDS = 60
Config.GOLDEN_MULTIPLIER = 2
Config.SURGE_FIRST_AFTER_SECONDS = 120
Config.SURGE_EVERY_SECONDS = 240
Config.SURGE_GUARANTEED_MUTATIONS = 3

-- Brainrot Rush: the belt speeds up and spawns twice as fast.
Config.RUSH_FIRST_AFTER_SECONDS = 200
Config.RUSH_EVERY_SECONDS = 360
Config.RUSH_DURATION_SECONDS = 45
Config.RUSH_SPAWN_DIVISOR = 2
Config.RUSH_SPEED_MULTIPLIER = 1.5
-- Lucky Mutation: mutation odds jump for a minute.
Config.LUCKY_FIRST_AFTER_SECONDS = 300
Config.LUCKY_EVERY_SECONDS = 420
Config.LUCKY_DURATION_SECONDS = 60
Config.LUCKY_MUTATION_CHANCES = {
	{ name = "Rainbow", chance = 0.03, multiplier = 10 },
	{ name = "Diamond", chance = 0.10, multiplier = 5 },
	{ name = "Golden", chance = 0.25, multiplier = 3 },
}
-- Buy combo: buy several brainrots inside one window for a cash bonus.
Config.COMBO_WINDOW_SECONDS = 20
Config.COMBO_MIN_COUNT = 3
Config.COMBO_BONUS_FRACTION = 0.10 -- +10% of the bought brainrot's cost

-- Rebirths and upgrades
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_INCOME_BONUS = 0.25 -- +25% income per rebirth, forever
Config.UPGRADES = {
	SwiftSneakers = {
		displayName = "Swift Sneakers",
		description = "+2 walk speed per level, outrun the wave",
		maxLevel = 5,
		costs = { 1000, 5000, 25000, 100000, 500000 },
	},
	MoneyMagnet = {
		displayName = "Money Magnet",
		description = "+10% income per level, every brainrot pays more",
		maxLevel = 5,
		costs = { 2000, 10000, 50000, 250000, 1000000 },
	},
}

-- Rarity roll weights for the conveyor spawner.
Config.RARITY_WEIGHTS = {
	Common = 40,
	Rare = 25,
	Epic = 15,
	Legendary = 10,
	Mythic = 6,
	BrainrotGod = 3,
	Secret = 1,
}

-- Mutation roll chances; a mutation multiplies the brainrot's $/s.
Config.MUTATION_CHANCES = {
	{ name = "Rainbow", chance = 0.01, multiplier = 10 },
	{ name = "Diamond", chance = 0.04, multiplier = 5 },
	{ name = "Golden", chance = 0.10, multiplier = 3 },
}

return Config
