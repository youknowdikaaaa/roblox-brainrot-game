-- EventService: the timed tension. Five events keep the map moving:
-- the Slime Wave sweeps the map and punishes anyone caught outside
-- their own base, Golden Hour doubles every brainrot's income for a
-- minute, Mutation Surge makes the next spawns guaranteed Golden,
-- Brainrot Rush doubles belt spawns and speed, and Lucky Mutation
-- boosts mutation odds for a minute. Mythic-or-better spawns also
-- get a server-wide announcement via the Conveyor's announce hook.
-- It broadcasts every event to all clients so the HUD can warn the
-- player, and it answers getIncomeMultiplier for the income tick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local PlayerData = require(script.Parent.PlayerData)
local Conveyor = require(script.Parent.Conveyor)

local EventService = {}
EventService._incomeMultiplier = 1
EventService._waveWall = nil

function EventService.getIncomeMultiplier()
	return EventService._incomeMultiplier
end

local function alert(kind, text, secondsLeft)
	ReplicatedStorage.Remotes.EventAlert:FireAllClients({
		kind = kind,
		text = text,
		secondsLeft = secondsLeft or 0,
	})
end

-- Is this player standing inside their own plot (the wave's safe zone)?
local function insideOwnPlot(player)
	local record = PlayerData.get(player)
	if not record then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local center = PlayerData.plotCenter(record)
	return math.abs(root.Position.X - center.X) <= Config.PLOT_HALF_WIDTH
		and math.abs(root.Position.Z - center.Z) <= Config.PLOT_HALF_DEPTH
end

local function runWave()
	local wall = EventService._waveWall
	if not wall then
		return
	end
	alert("wave", "SLIME WAVE INCOMING! Get to your base!", Config.WAVE_WARN_SECONDS)
	task.wait(Config.WAVE_WARN_SECONDS)

	alert("wave", "SLIME WAVE! Run home or lose 5% of your cash!", Config.WAVE_SWEEP_SECONDS)
	local zapped = {}
	local startX = -130
	local endX = 130
	local steps = 100
	for step = 0, steps do
		local x = startX + (endX - startX) * (step / steps)
		wall.CFrame = CFrame.new(x, 15, 0)
		for _, player in ipairs(Players:GetPlayers()) do
			if not zapped[player] and not insideOwnPlot(player) then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) <= 4 then
					zapped[player] = true
					local record = PlayerData.get(player)
					if record then
						local loss = math.floor(record.cash * Config.WAVE_CASH_LOSS_FRACTION)
						record.cash -= loss
						if character then
							character:PivotTo(CFrame.new(0, 3, 40))
						end
					end
				end
			end
		end
		task.wait(Config.WAVE_SWEEP_SECONDS / steps)
	end
	wall.CFrame = CFrame.new(-300, 15, 0)
	alert("wave", "The wave passed. Check your base!", 0)
end

local function runGoldenHour()
	EventService._incomeMultiplier = Config.GOLDEN_MULTIPLIER
	alert("golden", "GOLDEN HOUR! All income x2 for 60s!", Config.GOLDEN_DURATION_SECONDS)
	task.wait(Config.GOLDEN_DURATION_SECONDS)
	EventService._incomeMultiplier = 1
	alert("golden", "Golden Hour over. Back to normal rates.", 0)
end

local function runSurge()
	Conveyor.grantSurge(Config.SURGE_GUARANTEED_MUTATIONS)
	alert("surge", "MUTATION SURGE! The next 3 brainrots are guaranteed Golden!", 0)
end

local function runRush()
	Conveyor.setRush(true)
	alert("rush", "BRAINROT RUSH! Belt x2 speed, spawns twice as fast for 45s!", Config.RUSH_DURATION_SECONDS)
	task.wait(Config.RUSH_DURATION_SECONDS)
	Conveyor.setRush(false)
	alert("rush", "Rush over. Belt back to normal speed.", 0)
end

local function runLucky()
	Conveyor.setLucky(true)
	alert("lucky", "LUCKY MUTATION! Mutation odds boosted for 60s — watch the belt!", Config.LUCKY_DURATION_SECONDS)
	task.wait(Config.LUCKY_DURATION_SECONDS)
	Conveyor.setLucky(false)
	alert("lucky", "Lucky Mutation over. Odds back to normal.", 0)
end

function EventService.start(waveWall)
	EventService._waveWall = waveWall
	-- Mythic-or-better spawns are server news.
	Conveyor.setAnnounceHandler(function(entry)
		alert("mythic", "MYTHIC SPAWN! " .. entry.name
			.. " (" .. Catalog.RARITY_LABELS[entry.rarity] .. ") is on the belt!", 0)
	end)
	task.spawn(function()
		task.wait(Config.WAVE_FIRST_AFTER_SECONDS)
		while true do
			runWave()
			task.wait(Config.WAVE_EVERY_SECONDS)
		end
	end)
	task.spawn(function()
		task.wait(Config.GOLDEN_FIRST_AFTER_SECONDS)
		while true do
			runGoldenHour()
			task.wait(Config.GOLDEN_EVERY_SECONDS)
		end
	end)
	task.spawn(function()
		task.wait(Config.SURGE_FIRST_AFTER_SECONDS)
		while true do
			runSurge()
			task.wait(Config.SURGE_EVERY_SECONDS)
		end
	end)
	task.spawn(function()
		task.wait(Config.RUSH_FIRST_AFTER_SECONDS)
		while true do
			runRush()
			task.wait(Config.RUSH_EVERY_SECONDS)
		end
	end)
	task.spawn(function()
		task.wait(Config.LUCKY_FIRST_AFTER_SECONDS)
		while true do
			runLucky()
			task.wait(Config.LUCKY_EVERY_SECONDS)
		end
	end)
end

return EventService
