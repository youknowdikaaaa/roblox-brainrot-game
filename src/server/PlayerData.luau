-- PlayerData: the ONE place player state lives on the server. Every
-- other server module reads and writes through here, never through its
-- own copy of a player's cash or base.
--
-- A player's record:
--   cash            number, spendable money
--   plotIndex       number 1..8, the base plot they own
--   slots           array[1..6] of owned brainrot records or nil
--     { id, mutation, multiplier, model (the base copy, server-side) }
--   rebirths        number of rebirths taken
--   upgrades        { SwiftSneakers = level, MoneyMagnet = level }
--   lockUntil       os.clock() timestamp while the base lock holds
--   lockCooldownUntil os.clock() timestamp while lock is recharging
--   carrying        stolen brainrot record being carried, or nil

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Catalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)

local PlayerData = {}
PlayerData._players = {} -- [Player] = record
PlayerData._plotTaken = {} -- [plotIndex] = Player

function PlayerData.newRecord(player, plotIndex)
	return {
		player = player,
		cash = Config.START_CASH,
		plotIndex = plotIndex,
		slots = {},
		rebirths = 0,
		upgrades = { SwiftSneakers = 0, MoneyMagnet = 0 },
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil,
	}
end

-- Claim the first free plot for a joining player. Returns the record.
function PlayerData.addPlayer(player)
	for index = 1, #Config.PLOT_CENTERS do
		if not PlayerData._plotTaken[index] then
			PlayerData._plotTaken[index] = player
			local record = PlayerData.newRecord(player, index)
			PlayerData._players[player] = record
			return record
		end
	end
	-- All eight plots taken: share plot 1 and wait for a free one.
	local record = PlayerData.newRecord(player, 1)
	PlayerData._players[player] = record
	return record
end

function PlayerData.removePlayer(player)
	local record = PlayerData._players[player]
	if record then
		if PlayerData._plotTaken[record.plotIndex] == player then
			PlayerData._plotTaken[record.plotIndex] = nil
		end
		-- Any brainrot the player was carrying goes home to its owner.
		if record.carrying then
			local carried = record.carrying
			record.carrying = nil
			if carried.returnHome then
				carried.returnHome()
			end
		end
	end
	PlayerData._players[player] = nil
end

function PlayerData.get(player)
	return PlayerData._players[player]
end

function PlayerData.all()
	return PlayerData._players
end

function PlayerData.plotCenter(record)
	return Config.PLOT_CENTERS[record.plotIndex]
end

function PlayerData.isBaseLocked(record)
	return os.clock() < record.lockUntil
end

function PlayerData.lockRemaining(record)
	return math.max(0, record.lockUntil - os.clock())
end

function PlayerData.lockCooldownRemaining(record)
	return math.max(0, record.lockCooldownUntil - os.clock())
end

-- First empty slot index, or nil when the base is full.
function PlayerData.freeSlot(record)
	for index = 1, Config.SLOTS_PER_BASE do
		if not record.slots[index] then
			return index
		end
	end
	return nil
end

function PlayerData.ownedIds(record)
	local ids = {}
	for _, slot in ipairs(record.slots) do
		if slot then
			table.insert(ids, slot.id)
		end
	end
	return ids
end

-- Income multiplier from rebirths, upgrades and the event multiplier
-- the caller passes in (1 normally, 2 during Golden Hour).
function PlayerData.incomeMultiplier(record, eventMultiplier)
	local magnet = record.upgrades.MoneyMagnet or 0
	local multiplier = (1 + Config.REBIRTH_INCOME_BONUS * record.rebirths)
	multiplier *= (1 + 0.10 * magnet)
	multiplier *= (eventMultiplier or 1)
	return multiplier
end

-- Money per second of the whole base, before the global multiplier.
function PlayerData.baseRate(record)
	local total = 0
	for _, slot in ipairs(record.slots) do
		if slot then
			local entry = Catalog.getById(slot.id)
			if entry then
				total += Catalog.rateOf(entry, slot.multiplier)
			end
		end
	end
	return total
end

-- Walk speed from the Swift Sneakers upgrade.
function PlayerData.walkSpeed(record)
	local level = record.upgrades.SwiftSneakers or 0
	return Config.NORMAL_WALK_SPEED + 2 * level
end

function PlayerData.rebirthCost(record)
	return Config.REBIRTH_BASE_COST * (2 ^ record.rebirths)
end

-- Apply a rebirth: cash and base reset, income bonus grows forever.
function PlayerData.applyRebirth(record)
	record.cash = 0
	for index, slot in ipairs(record.slots) do
		if slot and slot.model then
			slot.model:Destroy()
		end
		record.slots[index] = nil
	end
	record.rebirths += 1
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.removePlayer(player)
end)

return PlayerData
