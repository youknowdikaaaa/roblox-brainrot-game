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
Conveyor._belt = {} -- { model, entry, mutation, multiplier, x }
Conveyor._surgeLeft = 0
Conveyor._onBuy = nil -- set by BrainrotService: fn(player, beltEntry) -> string|nil

-- The next spawn is a guaranteed mutation (Mutation Surge event).
function Conveyor.grantSurge(count)
	Conveyor._surgeLeft += count
end

function Conveyor.setBuyHandler(handler)
	Conveyor._onBuy = handler
end

-- Pick a random brainrot, weighted by rarity, then a mutation.
local function rollBrainrot()
	local rarity = Catalog.rollRarity(Config.RARITY_WEIGHTS)
	local pool = Catalog.getByRarity(rarity)
	local entry = pool[math.random(1, #pool)]
	local mutationName, multiplier = Catalog.rollMutation(Config.MUTATION_CHANCES)
	if Conveyor._surgeLeft > 0 then
		Conveyor._surgeLeft -= 1
		mutationName, multiplier = "Golden", 3
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
			task.wait(Config.SPAWN_INTERVAL_SECONDS)
			spawnOne()
		end
	end)

	-- Walk the belt: every frame each brainrot steps toward the end.
	RunService.Heartbeat:Connect(function(dt)
		local step = Config.CONVEYOR_SPEED * dt
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
			local current = model:GetPivot().Position
			model:PivotTo(CFrame.new(beltEntry.x, current.Y, current.Z)
				* CFrame.Angles(0, math.rad(90), 0))
		end
	end)
end

return Conveyor
