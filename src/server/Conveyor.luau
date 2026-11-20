-- Conveyor: the brainrot spawner walkway. Every few seconds a new
-- brainrot appears at the arch and walks the belt to the far end,
-- where it despawns. Clicking one buys it: the click goes to
-- BrainrotService, which owns money and bases. This module owns only
-- the belt: spawning, walking, despawning, and the surge counter that
-- makes the next few spawns guaranteed mutations.

local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Catalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local Factory = require(script.Parent.BrainrotFactory)

local Conveyor = {}
Conveyor._belt = {} -- { model, entry, mutation, multiplier, x, phase }
Conveyor._surgeLeft = 0
Conveyor._onBuy = nil -- set by BrainrotService: fn(player, beltEntry) -> string|nil
Conveyor._rushSpawnDivisor = 1
Conveyor._rushSpeedMultiplier = 1
Conveyor._lucky = false
Conveyor._announce = nil -- set by EventService: fn(entry) on Mythic+ spawns

-- The next spawn is a guaranteed mutation (Mutation Surge event).
function Conveyor.grantSurge(count)
	Conveyor._surgeLeft += count
end

-- Brainrot Rush: the belt spawns faster and walks faster.
function Conveyor.setRush(active)
	if active then
		Conveyor._rushSpawnDivisor = Config.RUSH_SPAWN_DIVISOR
		Conveyor._rushSpeedMultiplier = Config.RUSH_SPEED_MULTIPLIER
	else
		Conveyor._rushSpawnDivisor = 1
		Conveyor._rushSpeedMultiplier = 1
	end
end

-- Lucky Mutation: mutation odds jump while the event runs.
function Conveyor.setLucky(active)
	Conveyor._lucky = active
end

function Conveyor.setAnnounceHandler(handler)
	Conveyor._announce = handler
end

function Conveyor.setBuyHandler(handler)
	Conveyor._onBuy = handler
end

-- Pick a random brainrot, weighted by rarity, then a mutation.
local function rollBrainrot()
	local rarity = Catalog.rollRarity(Config.RARITY_WEIGHTS)
	local pool = Catalog.getByRarity(rarity)
	local entry = pool[math.random(1, #pool)]
	local chances = Conveyor._lucky and Config.LUCKY_MUTATION_CHANCES or Config.MUTATION_CHANCES
	local mutationName, multiplier = Catalog.rollMutation(chances)
	if Conveyor._surgeLeft > 0 then
		Conveyor._surgeLeft -= 1
		mutationName, multiplier = "Golden", 3
	end
	-- A Mythic-or-better spawn is server news, not a quiet roll.
	if Conveyor._announce
		and (rarity == "Mythic" or rarity == "BrainrotGod" or rarity == "Secret") then
		Conveyor._announce(entry)
	end
	return entry, mutationName, multiplier
end

local function spawnOne()
	if #Conveyor._belt >= Config.MAX_ON_BELT then
		return
	end
	local entry, mutationName, multiplier = rollBrainrot()
	local model = Factory.build(entry, mutationName, multiplier)
	model:SetAttribute("Kind", "Conveyor")
	Factory.placeAt(
		model,
		Vector3.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y, Config.CONVEYOR_Z),
		Vector3.new(Config.CONVEYOR_END_X, Config.CONVEYOR_Y, Config.CONVEYOR_Z)
	)

	local beltEntry = {
		model = model,
		entry = entry,
		mutation = mutationName,
		multiplier = multiplier,
		x = Config.CONVEYOR_START_X,
		phase = math.random() * math.pi * 2,
	}
	table.insert(Conveyor._belt, beltEntry)

	local click = model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
	if click then
		click.MouseClick:Connect(function(player)
			if Conveyor._onBuy then
				Conveyor._onBuy(player, beltEntry)
			end
		end)
	end
end

-- Remove a belt entry and its model (bought, or walked off the end).
function Conveyor.remove(beltEntry)
	for index, other in ipairs(Conveyor._belt) do
		if other == beltEntry then
			table.remove(Conveyor._belt, index)
			break
		end
	end
	if beltEntry.model then
		beltEntry.model:Destroy()
	end
end

function Conveyor.start()
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL_SECONDS / Conveyor._rushSpawnDivisor)
			spawnOne()
		end
	end)

	-- Walk the belt: every frame each brainrot steps toward the end.
	RunService.Heartbeat:Connect(function(dt)
		local step = Config.CONVEYOR_SPEED * Conveyor._rushSpeedMultiplier * dt
		local now = os.clock()
		for index = #Conveyor._belt, 1, -1 do
			local beltEntry = Conveyor._belt[index]
			if not beltEntry.model or not beltEntry.model.Parent then
				table.remove(Conveyor._belt, index)
				continue
			end
			beltEntry.x += step
			if beltEntry.x >= Config.CONVEYOR_END_X then
				Conveyor.remove(beltEntry)
				continue
			end
			local model = beltEntry.model
			-- A little bounce and wobble so the belt reads as alive;
			-- the Rush multiplier makes the steps bigger, the bob stays.
			local bob = math.sin(now * 3 + beltEntry.phase) * 0.15
			local tilt = math.sin(now * 2 + beltEntry.phase) * 0.08
			model:PivotTo(CFrame.new(beltEntry.x, Config.CONVEYOR_Y + bob, Config.CONVEYOR_Z)
				* CFrame.Angles(0, math.rad(90), tilt))
		end
	end)
end

return Conveyor
