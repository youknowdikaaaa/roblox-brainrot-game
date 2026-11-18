-- BrainrotService: the game loop's brain. It owns buying, base
-- placement, the income tick, stealing, base locks, rebirths and
-- upgrades, and it syncs every player's state to their client.
-- PlayerData holds the state; Conveyor owns the belt; EventService
-- owns the timed events. This module wires them together.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local PlayerData = require(script.Parent.PlayerData)
local Factory = require(script.Parent.BrainrotFactory)
local Conveyor = require(script.Parent.Conveyor)
local EventService = require(script.Parent.EventService)

local Remotes = ReplicatedStorage.Remotes
local BuyBrainrotRemote = Remotes.BuyBrainrot
local LockBaseRemote = Remotes.LockBase
local RebirthRemote = Remotes.Rebirth
local BuyUpgradeRemote = Remotes.BuyUpgrade
local StateSyncRemote = Remotes.StateSync

local BrainrotService = {}
BrainrotService._messageId = 0

-- ------------------------------------------------------------------
-- Messages and sync

function BrainrotService.sendMessage(record, text)
	BrainrotService._messageId += 1
	record.message = text
	record.messageId = BrainrotService._messageId
	BrainrotService.syncPlayer(record)
end

function BrainrotService.syncPlayer(record)
	local player = record.player
	if not player or not player.Parent then
		return
	end
	local owned = {}
	for _, slot in ipairs(record.slots) do
		if slot then
			local entry = Catalog.getById(slot.id)
			table.insert(owned, {
				id = slot.id,
				name = entry and entry.name or slot.id,
				rarity = entry and entry.rarity or "Common",
				mutation = slot.mutation,
				rate = entry and Catalog.rateOf(entry, slot.multiplier) or 0,
			})
		end
	end
	local nextTier = Catalog.getNextTier(PlayerData.ownedIds(record))
	StateSyncRemote:FireClient(player, {
		cash = math.floor(record.cash),
		incomePerSec = math.floor(PlayerData.baseRate(record)
			* PlayerData.incomeMultiplier(record, EventService.getIncomeMultiplier())),
		rebirths = record.rebirths,
		rebirthCost = PlayerData.rebirthCost(record),
		upgrades = record.upgrades,
		upgradeCosts = {
			SwiftSneakers = Config.UPGRADES.SwiftSneakers.costs[(record.upgrades.SwiftSneakers or 0) + 1],
			MoneyMagnet = Config.UPGRADES.MoneyMagnet.costs[(record.upgrades.MoneyMagnet or 0) + 1],
		},
		lockRemaining = PlayerData.lockRemaining(record),
		lockCooldownRemaining = PlayerData.lockCooldownRemaining(record),
		owned = owned,
		nextTier = nextTier and {
			name = nextTier.name,
			rarity = nextTier.rarity,
			cost = nextTier.cost,
			rate = nextTier.rate,
			blurb = nextTier.blurb,
		} or nil,
		carrying = record.carrying and record.carrying.name or nil,
		plotIndex = record.plotIndex,
		message = record.message,
		messageId = record.messageId or 0,
	})
end

function BrainrotService.syncAll()
	for _, record in pairs(PlayerData.all()) do
		BrainrotService.syncPlayer(record)
	end
end

-- ------------------------------------------------------------------
-- Plot visuals

local function plotGate(plotIndex)
	return workspace:FindFirstChild("Plot" .. plotIndex .. "Gate")
end

function BrainrotService.setGateVisual(plotIndex, locked)
	local gate = plotGate(plotIndex)
	if gate then
		if locked then
			gate.Color = Color3.fromRGB(255, 40, 40)
			gate.Transparency = 0
		else
			gate.Transparency = 0.25
		end
	end
end

function BrainrotService.updatePlotSign(record)
	local floor = workspace:FindFirstChild("Plot" .. record.plotIndex .. "Floor")
	if not floor then
		return
	end
	local sign = floor:FindFirstChild("OwnerSign")
	if not sign then
		return
	end
	local label = sign:FindFirstChild("OwnerName")
	if label then
		local text = "BASE " .. record.plotIndex .. " — " .. record.player.Name
		if PlayerData.isBaseLocked(record) then
			text ..= " [LOCKED]"
		end
		label.Text = text
	end
end

-- ------------------------------------------------------------------
-- Buying and base placement

local function slotPosition(record, slotIndex)
	local center = PlayerData.plotCenter(record)
	return center + Config.SLOT_OFFSETS[slotIndex] + Vector3.new(0, 1, 0)
end

-- Build the base copy of a brainrot on a slot and wire its steal click.
local function placeOnBase(record, slotIndex, entry, mutationName, multiplier)
	local model = Factory.build(entry, mutationName, multiplier)
	model:SetAttribute("Kind", "Base")
	model:SetAttribute("OwnerId", record.player.UserId)
	model:SetAttribute("SlotIndex", slotIndex)
	Factory.placeAt(model, slotPosition(record, slotIndex), PlayerData.plotCenter(record))

	local click = model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
	if click then
		click.MouseClick:Connect(function(clickingPlayer)
			BrainrotService.trySteal(clickingPlayer, model)
		end)
	end

	record.slots[slotIndex] = {
		id = entry.id,
		mutation = mutationName,
		multiplier = multiplier,
		model = model,
	}
	return model
end

-- The Conveyor's buy handler: a click on a walking brainrot.
local function buyBrainrot(player, beltEntry)
	local record = PlayerData.get(player)
	if not record then
		return
	end
	local entry = beltEntry.entry
	local slotIndex = PlayerData.freeSlot(record)
	if not slotIndex then
		BrainrotService.sendMessage(record, "Your base is full! Sell or rebirth first.")
		return
	end
	if record.cash < entry.cost then
		BrainrotService.sendMessage(record, "Need " .. Catalog.formatMoney(entry.cost) .. " for " .. entry.name .. "!")
		return
	end
	record.cash -= entry.cost
	Conveyor.remove(beltEntry)
	placeOnBase(record, slotIndex, entry, beltEntry.mutation, beltEntry.multiplier)
	BrainrotService.sendMessage(record, "Bought " .. entry.name .. " for " .. Catalog.formatMoney(entry.cost) .. "!")
	BrainrotService.syncPlayer(record)
end

-- ------------------------------------------------------------------
-- Stealing

-- A stolen brainrot rides above the thief's head until the thief
-- reaches their own base, the owner slaps them, or they die.
local function startCarrying(thiefRecord, ownerRecord, slotIndex, model, entry)
	local thief = thiefRecord.player
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	humanoid.WalkSpeed = Config.CARRY_WALK_SPEED

	local carried = {
		name = entry.name,
		entry = entry,
		ownerRecord = ownerRecord,
		slotIndex = slotIndex,
		model = model,
		thief = thief,
	}
	carried.returnHome = function()
		if carried.model and carried.model.Parent then
			placeOnBase(ownerRecord, slotIndex, entry,
				model:GetAttribute("Mutation"), model:GetAttribute("Multiplier"))
			carried.model:Destroy()
		end
		if thiefRecord.carrying == carried then
			thiefRecord.carrying = nil
			local hum = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = PlayerData.walkSpeed(thiefRecord)
			end
		end
	end
	thiefRecord.carrying = carried
	BrainrotService.sendMessage(thiefRecord, "You stole " .. entry.name .. "! Run home!")
	BrainrotService.sendMessage(ownerRecord, thief.Name .. " stole your " .. entry.name .. "! Catch them!")
	return true
end

function BrainrotService.trySteal(player, model)
	local thiefRecord = PlayerData.get(player)
	if not thiefRecord or thiefRecord.carrying then
		return
	end
	if model:GetAttribute("Kind") ~= "Base" then
		return
	end
	local ownerId = model:GetAttribute("OwnerId")
	if ownerId == player.UserId then
		return
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	local ownerRecord = owner and PlayerData.get(owner)
	if not ownerRecord then
		return
	end
	if PlayerData.isBaseLocked(ownerRecord) then
		BrainrotService.sendMessage(thiefRecord, "That base is LOCKED. Wait it out!")
		return
	end
	local slotIndex = model:GetAttribute("SlotIndex")
	local entry = Catalog.getById(model:GetAttribute("BrainrotId"))
	if not entry then
		return
	end
	-- Lift it off the owner's base.
	ownerRecord.slots[slotIndex] = nil
	local mutationName = model:GetAttribute("Mutation")
	local multiplier = model:GetAttribute("Multiplier")
	if startCarrying(thiefRecord, ownerRecord, slotIndex, model, entry) then
		BrainrotService.syncPlayer(ownerRecord)
		BrainrotService.syncPlayer(thiefRecord)
	else
		-- Carrying failed (no character): put the same model back.
		ownerRecord.slots[slotIndex] = {
			id = entry.id,
			mutation = mutationName,
			multiplier = multiplier,
			model = model,
		}
		Factory.placeAt(model, slotPosition(ownerRecord, slotIndex), PlayerData.plotCenter(ownerRecord))
	end
end

-- Every frame: carry the stolen brainrot above the thief, check for a
-- slap from the owner, a safe arrival home, or a dead thief.
local function watchCarrying(dt)
	for _, record in pairs(PlayerData.all()) do
		local carried = record.carrying
		if carried then
			local thief = record.player
			local character = thief.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local head = character and character:FindFirstChild("Head")
			if not humanoid or humanoid.Health <= 0 or not head then
				carried.returnHome()
				continue
			end
			if carried.model and carried.model.Parent then
				carried.model:PivotTo(CFrame.new(head.Position + Vector3.new(0, 4, 0)))
			end
			-- Owner slap: owner this close drops the catch.
			local owner = carried.ownerRecord.player
			local ownerChar = owner and owner.Character
			local ownerRoot = ownerChar and ownerChar:FindFirstChild("HumanoidRootPart")
			local thiefRoot = character:FindFirstChild("HumanoidRootPart")
			if ownerRoot and thiefRoot
				and (ownerRoot.Position - thiefRoot.Position).Magnitude <= Config.SLAP_DISTANCE then
				carried.returnHome()
				BrainrotService.sendMessage(record, "SLAPPED! " .. carried.name .. " went home.")
				BrainrotService.sendMessage(carried.ownerRecord, "You got " .. carried.name .. " back!")
				continue
			end
			-- Safe arrival: thief inside their own plot with a free slot.
			local center = PlayerData.plotCenter(record)
			local pos = thiefRoot and thiefRoot.Position or head.Position
			local inside = math.abs(pos.X - center.X) <= Config.PLOT_HALF_WIDTH
				and math.abs(pos.Z - center.Z) <= Config.PLOT_HALF_DEPTH
			if inside then
				local slotIndex = PlayerData.freeSlot(record)
				if slotIndex then
					local model = carried.model
					local entry = carried.entry
					local mutationName = model:GetAttribute("Mutation")
					local multiplier = model:GetAttribute("Multiplier")
					record.carrying = nil
					humanoid.WalkSpeed = PlayerData.walkSpeed(record)
					model:Destroy()
					placeOnBase(record, slotIndex, entry, mutationName, multiplier)
					BrainrotService.sendMessage(record, "Stolen " .. entry.name .. " is yours now!")
					BrainrotService.syncPlayer(record)
					BrainrotService.syncPlayer(carried.ownerRecord)
				end
			end
		end
	end
end

-- ------------------------------------------------------------------
-- Locks, rebirths, upgrades

local function onLockBase(player)
	local record = PlayerData.get(player)
	if not record then
		return
	end
	if PlayerData.lockCooldownRemaining(record) > 0 then
		BrainrotService.sendMessage(record, "Lock recharging: "
			.. math.ceil(PlayerData.lockCooldownRemaining(record)) .. "s left.")
		return
	end
	record.lockUntil = os.clock() + Config.LOCK_DURATION_SECONDS
	record.lockCooldownUntil = record.lockUntil + Config.LOCK_COOLDOWN_SECONDS
	BrainrotService.setGateVisual(record.plotIndex, true)
	BrainrotService.updatePlotSign(record)
	BrainrotService.sendMessage(record, "Base locked for " .. Config.LOCK_DURATION_SECONDS .. "s!")
	task.delay(Config.LOCK_DURATION_SECONDS, function()
		BrainrotService.setGateVisual(record.plotIndex, false)
		BrainrotService.updatePlotSign(record)
	end)
end

local function onRebirth(player)
	local record = PlayerData.get(player)
	if not record then
		return
	end
	local cost = PlayerData.rebirthCost(record)
	if record.cash < cost then
		BrainrotService.sendMessage(record, "Rebirth needs " .. Catalog.formatMoney(cost) .. "!")
		return
	end
	record.cash -= cost
	PlayerData.applyRebirth(record)
	BrainrotService.sendMessage(record, "REBIRTH #" .. record.rebirths
		.. "! Income +" .. math.floor(Config.REBIRTH_INCOME_BONUS * 100) .. "% forever.")
	BrainrotService.syncPlayer(record)
end

local function onBuyUpgrade(player, upgradeId)
	local record = PlayerData.get(player)
	if not record then
		return
	end
	local upgrade = Config.UPGRADES[upgradeId]
	if not upgrade then
		return
	end
	local level = record.upgrades[upgradeId] or 0
	if level >= upgrade.maxLevel then
		BrainrotService.sendMessage(record, upgrade.displayName .. " is maxed out!")
		return
	end
	local cost = upgrade.costs[level + 1]
	if record.cash < cost then
		BrainrotService.sendMessage(record, "Need " .. Catalog.formatMoney(cost) .. " for " .. upgrade.displayName .. "!")
		return
	end
	record.cash -= cost
	record.upgrades[upgradeId] = level + 1
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and upgradeId == "SwiftSneakers" then
		humanoid.WalkSpeed = PlayerData.walkSpeed(record)
	end
	BrainrotService.sendMessage(record, upgrade.displayName .. " level " .. (level + 1) .. "!")
	BrainrotService.syncPlayer(record)
end

-- ------------------------------------------------------------------
-- Income tick and boot

local function incomeTick()
	while true do
		task.wait(Config.INCOME_TICK_SECONDS)
		local eventMultiplier = EventService.getIncomeMultiplier()
		for _, record in pairs(PlayerData.all()) do
			local income = PlayerData.baseRate(record)
				* PlayerData.incomeMultiplier(record, eventMultiplier)
			record.cash += income
		end
		BrainrotService.syncAll()
	end
end

function BrainrotService.start()
	Conveyor.setBuyHandler(buyBrainrot)
	LockBaseRemote.OnServerEvent:Connect(onLockBase)
	RebirthRemote.OnServerEvent:Connect(onRebirth)
	BuyUpgradeRemote.OnServerEvent:Connect(onBuyUpgrade)

	local function setupPlayer(player)
		local record = PlayerData.addPlayer(player)
		BrainrotService.updatePlotSign(record)
		BrainrotService.syncPlayer(record)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = PlayerData.walkSpeed(record)
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	RunService.Heartbeat:Connect(watchCarrying)
	task.spawn(incomeTick)
end

return BrainrotService
