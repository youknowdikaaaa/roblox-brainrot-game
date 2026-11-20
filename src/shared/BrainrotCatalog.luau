-- BrainrotCatalog: the whole cast of Brainrot Bay. Every character is
-- an original joke, not a copy of any published brainrot: a name, a
-- rarity on the ladder, a price, a money-per-second rate, a body colour,
-- a size scale and a one-line blurb the HUD can show.
-- Rarities, cheapest first: Common, Rare, Epic, Legendary, Mythic,
-- BrainrotGod, Secret. Mutations (Golden x3, Diamond x5, Rainbow x10)
-- multiply the rate; see Config.MUTATION_CHANCES.

local BrainrotCatalog = {}

BrainrotCatalog.RARITY_ORDER = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"BrainrotGod",
	"Secret",
}

BrainrotCatalog.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 170, 30),
	Mythic = Color3.fromRGB(255, 60, 90),
	BrainrotGod = Color3.fromRGB(255, 230, 0),
	Secret = Color3.fromRGB(40, 230, 190),
}

BrainrotCatalog.RARITY_LABELS = {
	Common = "COMMON",
	Rare = "RARE",
	Epic = "EPIC",
	Legendary = "LEGENDARY",
	Mythic = "MYTHIC",
	BrainrotGod = "BRAINROT GOD",
	Secret = "SECRET",
}

-- id, name, rarity, cost, $/s, body colour, size scale, blurb.
BrainrotCatalog.BRAINROTS = {
	{
		id = "pipino",
		name = "Pipino Picklefoot",
		rarity = "Common",
		cost = 50,
		rate = 1,
		color = Color3.fromRGB(90, 180, 80),
		scale = 1.0,
		blurb = "A pickle with feet. He walks. That is the whole joke.",
	},
	{
		id = "barnaby",
		name = "Barnaby the Bureaucratic Banana",
		rarity = "Common",
		cost = 90,
		rate = 2,
		color = Color3.fromRGB(250, 225, 90),
		scale = 1.0,
		blurb = "Files forms in triplicate. Peels himself for lunch.",
	},
	{
		id = "bongo",
		name = "Bongo Bananapeel",
		rarity = "Common",
		cost = 120,
		rate = 3,
		color = Color3.fromRGB(250, 220, 60),
		scale = 1.0,
		blurb = "Slips on himself daily. Somehow still employed.",
	},
	{
		id = "gary",
		name = "Gary the Grapefruit Couch",
		rarity = "Common",
		cost = 160,
		rate = 4,
		color = Color3.fromRGB(255, 130, 160),
		scale = 1.1,
		blurb = "A couch that is also a grapefruit. Sits on itself.",
	},
	{
		id = "wobbles",
		name = "Sir Wobblesworth",
		rarity = "Common",
		cost = 200,
		rate = 5,
		color = Color3.fromRGB(200, 160, 220),
		scale = 1.1,
		blurb = "Knighted for wobbling. Never stopped since.",
	},
	{
		id = "noodle",
		name = "Noodle Ned",
		rarity = "Common",
		cost = 250,
		rate = 6,
		color = Color3.fromRGB(240, 210, 140),
		scale = 0.9,
		blurb = "One long noodle, zero thoughts, great vibes.",
	},
	{
		id = "crumbcake",
		name = "Captain Crumbcake",
		rarity = "Rare",
		cost = 500,
		rate = 12,
		color = Color3.fromRGB(190, 130, 70),
		scale = 1.1,
		blurb = "Sailed the seven ovens. Came back crumbs.",
	},
	{
		id = "duchess",
		name = "Duchess Dumpling",
		rarity = "Rare",
		cost = 700,
		rate = 16,
		color = Color3.fromRGB(240, 220, 200),
		scale = 1.0,
		blurb = "Steamed, stuffed, and somehow royalty.",
	},
	{
		id = "llamacorn",
		name = "Luna Llamacorn",
		rarity = "Rare",
		cost = 900,
		rate = 20,
		color = Color3.fromRGB(220, 180, 255),
		scale = 1.1,
		blurb = "Half llama, half unicorn, all drama.",
	},
	{
		id = "reginald",
		name = "Sir Reginald the Rectangular Egg",
		rarity = "Rare",
		cost = 1100,
		rate = 25,
		color = Color3.fromRGB(250, 245, 220),
		scale = 1.0,
		blurb = "An egg. Rectangular. Knighted anyway.",
	},
	{
		id = "picklejar",
		name = "Professor Picklejar",
		rarity = "Rare",
		cost = 1400,
		rate = 30,
		color = Color3.fromRGB(80, 160, 90),
		scale = 1.0,
		blurb = "Holds a PhD in being pickled. Tenure denied.",
	},
	{
		id = "dodo",
		name = "Disco Dodo",
		rarity = "Rare",
		cost = 1500,
		rate = 32,
		color = Color3.fromRGB(255, 120, 200),
		scale = 1.0,
		blurb = "Extinct on land, alive on the dance floor.",
	},
	{
		id = "baguette",
		name = "Baron von Baguette",
		rarity = "Epic",
		cost = 3000,
		rate = 60,
		color = Color3.fromRGB(220, 170, 90),
		scale = 1.2,
		blurb = "Crusty on the outside, richer on the inside.",
	},
	{
		id = "queso",
		name = "Queen Queso",
		rarity = "Epic",
		cost = 4500,
		rate = 85,
		color = Color3.fromRGB(255, 200, 40),
		scale = 1.2,
		blurb = "Rules the cheese drawer with an iron ladle.",
	},
	{
		id = "mustard",
		name = "Madame Mustard",
		rarity = "Epic",
		cost = 5500,
		rate = 100,
		color = Color3.fromRGB(255, 215, 0),
		scale = 1.1,
		blurb = "Squeezes into every sandwich. Runs the deli now.",
	},
	{
		id = "tortellini",
		name = "Turbo Tortellini",
		rarity = "Epic",
		cost = 6500,
		rate = 120,
		color = Color3.fromRGB(255, 150, 60),
		scale = 1.0,
		blurb = "Faster than the sauce. Nobody knows how.",
	},
	{
		id = "tso",
		name = "General Tso's Leftovers",
		rarity = "Epic",
		cost = 7200,
		rate = 135,
		color = Color3.fromRGB(230, 110, 50),
		scale = 1.1,
		blurb = "Second-day chicken. First-class general.",
	},
	{
		id = "avocado",
		name = "Agent Avocado",
		rarity = "Epic",
		cost = 8000,
		rate = 150,
		color = Color3.fromRGB(120, 190, 60),
		scale = 1.1,
		blurb = "Licensed to guac. Always ripe, never sorry.",
	},
	{
		id = "guacamole",
		name = "El Grande Guacamole",
		rarity = "Legendary",
		cost = 15000,
		rate = 280,
		color = Color3.fromRGB(90, 160, 50),
		scale = 1.3,
		blurb = "The big one. Dips chips. Dips economies.",
	},
	{
		id = "butterknife",
		name = "Baroness Butterknife",
		rarity = "Legendary",
		cost = 20000,
		rate = 360,
		color = Color3.fromRGB(240, 235, 200),
		scale = 1.2,
		blurb = "Spreads butter. Spreads influence. Never spreads thin.",
	},
	{
		id = "sockpuppet",
		name = "Sultan Sockpuppet",
		rarity = "Legendary",
		cost = 25000,
		rate = 450,
		color = Color3.fromRGB(150, 90, 200),
		scale = 1.2,
		blurb = "A sock with a crown and a five-year plan.",
	},
	{
		id = "donutstorm",
		name = "Doctor Donutstorm",
		rarity = "Legendary",
		cost = 35000,
		rate = 600,
		color = Color3.fromRGB(255, 130, 170),
		scale = 1.2,
		blurb = "Prescribes sprinkles. Side effects: wealth.",
	},
	{
		id = "jellybean",
		name = "The Honorable Judge Jellybean",
		rarity = "Legendary",
		cost = 42000,
		rate = 720,
		color = Color3.fromRGB(255, 90, 140),
		scale = 1.2,
		blurb = "Presides over the candy court. Verdict: delicious.",
	},
	{
		id = "moonpie",
		name = "Madame Moonpie",
		rarity = "Legendary",
		cost = 50000,
		rate = 850,
		color = Color3.fromRGB(200, 200, 255),
		scale = 1.3,
		blurb = "Baked on the moon. Tastes like rent money.",
	},
	{
		id = "lasagna",
		name = "Lord Lasagna",
		rarity = "Mythic",
		cost = 100000,
		rate = 1600,
		color = Color3.fromRGB(220, 90, 60),
		scale = 1.4,
		blurb = "Twelve layers of pure authority.",
	},
	{
		id = "meatball",
		name = "Grandma's Meatball of Destiny",
		rarity = "Mythic",
		cost = 150000,
		rate = 2300,
		color = Color3.fromRGB(190, 100, 60),
		scale = 1.4,
		blurb = "One bite rewrites your family tree.",
	},
	{
		id = "gherkin",
		name = "The Great Gherkin",
		rarity = "Mythic",
		cost = 200000,
		rate = 3000,
		color = Color3.fromRGB(60, 140, 70),
		scale = 1.4,
		blurb = "He saw the brine. The brine saw him back.",
	},
	{
		id = "eggplant",
		name = "Emperor Eggplant",
		rarity = "Mythic",
		cost = 350000,
		rate = 5000,
		color = Color3.fromRGB(120, 60, 180),
		scale = 1.4,
		blurb = "Purple, proud, and permanently in charge.",
	},
	{
		id = "croissant",
		name = "Count Croissant",
		rarity = "Mythic",
		cost = 500000,
		rate = 7000,
		color = Color3.fromRGB(240, 200, 120),
		scale = 1.5,
		blurb = "Flaky, French, and filthy rich.",
	},
	{
		id = "zorp",
		name = "Zorp the Unbothered",
		rarity = "BrainrotGod",
		cost = 1000000,
		rate = 13000,
		color = Color3.fromRGB(255, 220, 0),
		scale = 1.6,
		blurb = "A god. Mostly naps. Earns anyway.",
	},
	{
		id = "pope",
		name = "The Almighty Pickle Pope",
		rarity = "BrainrotGod",
		cost = 1500000,
		rate = 20000,
		color = Color3.fromRGB(90, 200, 110),
		scale = 1.6,
		blurb = "Blesses the brine. The brine blesses back.",
	},
	{
		id = "spaghetti",
		name = "Mama Spaghetti Monster",
		rarity = "BrainrotGod",
		cost = 2500000,
		rate = 30000,
		color = Color3.fromRGB(255, 180, 60),
		scale = 1.6,
		blurb = "Every strand is a pension plan.",
	},
	{
		id = "ian",
		name = "Invisible Ian",
		rarity = "Secret",
		cost = 5000000,
		rate = 55000,
		color = Color3.fromRGB(200, 230, 255),
		scale = 1.0,
		blurb = "You cannot see him. Your wallet can.",
	},
	{
		id = "goldfish",
		name = "The Tax Collector's Goldfish",
		rarity = "Secret",
		cost = 7500000,
		rate = 85000,
		color = Color3.fromRGB(255, 170, 60),
		scale = 1.0,
		blurb = "Swims in gold. Audits your base. Always wins.",
	},
	{
		id = "bossbaby",
		name = "The Final Boss Baby",
		rarity = "Secret",
		cost = 10000000,
		rate = 120000,
		color = Color3.fromRGB(255, 200, 210),
		scale = 0.8,
		blurb = "Small. Suited. Ends runs. Prints money.",
	},
}

-- Look up a brainrot by id; returns nil when there is none.
function BrainrotCatalog.getById(id)
	for _, entry in ipairs(BrainrotCatalog.BRAINROTS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- All brainrots of one rarity, cheapest first.
function BrainrotCatalog.getByRarity(rarity)
	local out = {}
	for _, entry in ipairs(BrainrotCatalog.BRAINROTS) do
		if entry.rarity == rarity then
			table.insert(out, entry)
		end
	end
	return out
end

-- The cheapest brainrot the player does not own yet: the next tier
-- the HUD points at. Nil when the player owns the whole cast.
function BrainrotCatalog.getNextTier(ownedIds)
	local owned = {}
	for _, id in ipairs(ownedIds) do
		owned[id] = true
	end
	for _, entry in ipairs(BrainrotCatalog.BRAINROTS) do
		if not owned[entry.id] then
			return entry
		end
	end
	return nil
end

-- Roll a rarity from Config.RARITY_WEIGHTS.
function BrainrotCatalog.rollRarity(weights)
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end
	local roll = math.random() * total
	for _, rarity in ipairs(BrainrotCatalog.RARITY_ORDER) do
		roll -= weights[rarity] or 0
		if roll <= 0 then
			return rarity
		end
	end
	return "Common"
end

-- Roll a mutation; returns "Normal" most of the time.
function BrainrotCatalog.rollMutation(chances)
	local roll = math.random()
	for _, mutation in ipairs(chances) do
		if roll < mutation.chance then
			return mutation.name, mutation.multiplier
		end
	end
	return "Normal", 1
end

-- Money per second of one owned brainrot, mutation included.
function BrainrotCatalog.rateOf(entry, mutationMultiplier)
	return entry.rate * (mutationMultiplier or 1)
end

-- Pretty money: 1234 -> "$1,234", 1200000 -> "$1.20M".
function BrainrotCatalog.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 10000 then
		return string.format("$%.1fK", amount / 1000)
	end
	local text = tostring(amount)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return BrainrotCatalog
