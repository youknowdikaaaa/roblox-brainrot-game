-- Game.client: the whole interface of Brainrot Bay, built in code over
-- the 3D world. It shows cash and income, the next brainrot to save
-- for, the brainrots on your base, the lock / rebirth / upgrade
-- buttons, event warnings and feedback messages. It never owns money:
-- every number arrives from the server on StateSync, and every button
-- only fires a RemoteEvent the server validates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage.Remotes

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	return button
end

-- Cash and income, top centre (clear of the top-left Roblox buttons).
local cashLabel = makeLabel(gui, "CashLabel", "Cash: $150",
	UDim2.fromOffset(280, 44), UDim2.new(0.5, -140, 0, 12), 24,
	Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(gui, "IncomeLabel", "Income: $0/s",
	UDim2.fromOffset(280, 30), UDim2.new(0.5, -140, 0, 60), 18,
	Color3.fromRGB(255, 230, 120))

-- Event banner under the cash.
local bannerLabel = makeLabel(gui, "EventBanner", "",
	UDim2.fromOffset(460, 34), UDim2.new(0.5, -230, 0, 96), 20,
	Color3.fromRGB(255, 120, 120))
bannerLabel.Visible = false

-- Feedback messages, centre screen.
local messageLabel = makeLabel(gui, "MessageLabel", "",
	UDim2.fromOffset(460, 36), UDim2.new(0.5, -230, 0.35, 0), 20,
	Color3.fromRGB(255, 255, 255))
messageLabel.Visible = false

-- Carrying indicator, under the message.
local carryingLabel = makeLabel(gui, "CarryingLabel", "",
	UDim2.fromOffset(460, 34), UDim2.new(0.5, -230, 0.35, 44), 20,
	Color3.fromRGB(255, 170, 60))
carryingLabel.Visible = false

-- Next tier to save for, bottom left.
local nextPanel = Instance.new("Frame")
nextPanel.Name = "NextTierPanel"
nextPanel.Size = UDim2.fromOffset(320, 110)
nextPanel.Position = UDim2.new(0, 12, 1, -122)
nextPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
nextPanel.BackgroundTransparency = 0.25
nextPanel.BorderSizePixel = 0
nextPanel.Parent = gui

local nextTitle = makeLabel(nextPanel, "Title", "NEXT TIER",
	UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), 16,
	Color3.fromRGB(255, 230, 120))
nextTitle.BackgroundTransparency = 1
local nextName = makeLabel(nextPanel, "Name", "—",
	UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 26), 20,
	Color3.fromRGB(255, 255, 255))
nextName.BackgroundTransparency = 1
local nextDetail = makeLabel(nextPanel, "Detail", "—",
	UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 54), 16,
	Color3.fromRGB(180, 220, 255))
nextDetail.BackgroundTransparency = 1
local nextBlurb = makeLabel(nextPanel, "Blurb", "—",
	UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 80), 14,
	Color3.fromRGB(200, 200, 200))
nextBlurb.BackgroundTransparency = 1

-- Your base, bottom right.
local basePanel = Instance.new("Frame")
basePanel.Name = "BasePanel"
basePanel.Size = UDim2.fromOffset(300, 190)
basePanel.Position = UDim2.new(1, -312, 1, -202)
basePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
basePanel.BackgroundTransparency = 0.25
basePanel.BorderSizePixel = 0
basePanel.Parent = gui

local baseTitle = makeLabel(basePanel, "Title", "YOUR BASE",
	UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), 16,
	Color3.fromRGB(255, 230, 120))
baseTitle.BackgroundTransparency = 1
local baseList = Instance.new("TextLabel")
baseList.Name = "BaseList"
baseList.Size = UDim2.new(1, -12, 1, -30)
baseList.Position = UDim2.new(0, 6, 0, 28)
baseList.BackgroundTransparency = 1
baseList.Text = "No brainrots yet — buy one off the belt!"
baseList.TextColor3 = Color3.fromRGB(255, 255, 255)
baseList.TextSize = 15
baseList.Font = Enum.Font.SourceSans
baseList.TextXAlignment = Enum.TextXAlignment.Left
baseList.TextYAlignment = Enum.TextYAlignment.Top
baseList.TextWrapped = true
baseList.Parent = basePanel

-- Action buttons, right edge.
local lockButton = makeButton(gui, "LockButton", "LOCK BASE (60s)",
	UDim2.fromOffset(180, 44), UDim2.new(1, -192, 0, 220))
local rebirthButton = makeButton(gui, "RebirthButton", "REBIRTH",
	UDim2.fromOffset(180, 44), UDim2.new(1, -192, 0, 272))
rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 50, 160)
local upgradesButton = makeButton(gui, "UpgradesButton", "UPGRADES",
	UDim2.fromOffset(180, 44), UDim2.new(1, -192, 0, 324))
upgradesButton.BackgroundColor3 = Color3.fromRGB(40, 130, 70)

-- Upgrades panel, hidden until the button is pressed.
local upgradePanel = Instance.new("Frame")
upgradePanel.Name = "UpgradePanel"
upgradePanel.Size = UDim2.fromOffset(320, 150)
upgradePanel.Position = UDim2.new(1, -332, 0, 380)
upgradePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
upgradePanel.BackgroundTransparency = 0.15
upgradePanel.BorderSizePixel = 0
upgradePanel.Visible = false
upgradePanel.Parent = gui

local upgradeTitle = makeLabel(upgradePanel, "Title", "UPGRADES",
	UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), 16,
	Color3.fromRGB(255, 230, 120))
upgradeTitle.BackgroundTransparency = 1
local sneakersButton = makeButton(upgradePanel, "SneakersButton", "Swift Sneakers",
	UDim2.new(1, -12, 0, 44), UDim2.new(0, 6, 0, 34))
local magnetButton = makeButton(upgradePanel, "MagnetButton", "Money Magnet",
	UDim2.new(1, -12, 0, 44), UDim2.new(0, 6, 0, 86))
magnetButton.BackgroundColor3 = Color3.fromRGB(160, 110, 20)

upgradesButton.MouseButton1Click:Connect(function()
	upgradePanel.Visible = not upgradePanel.Visible
end)
lockButton.MouseButton1Click:Connect(function()
	Remotes.LockBase:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	Remotes.Rebirth:FireServer()
end)
sneakersButton.MouseButton1Click:Connect(function()
	Remotes.BuyUpgrade:FireServer("SwiftSneakers")
end)
magnetButton.MouseButton1Click:Connect(function()
	Remotes.BuyUpgrade:FireServer("MoneyMagnet")
end)

-- ------------------------------------------------------------------
-- State updates from the server

local lastMessageId = 0
local bannerUntil = 0

local function showMessage(text)
	messageLabel.Text = text
	messageLabel.Visible = true
	task.delay(4, function()
		messageLabel.Visible = false
	end)
end

Remotes.StateSync.OnClientEvent:Connect(function(state)
	cashLabel.Text = "Cash: " .. Catalog.formatMoney(state.cash)
	incomeLabel.Text = "Income: " .. Catalog.formatMoney(state.incomePerSec) .. "/s"
		.. (state.rebirths > 0 and ("  •  Rebirths: " .. state.rebirths) or "")

	if state.messageId ~= lastMessageId then
		lastMessageId = state.messageId
		if state.message and state.message ~= "" then
			showMessage(state.message)
		end
	end

	if state.carrying then
		carryingLabel.Text = "CARRYING " .. state.carrying .. " — RUN HOME!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end

	if state.lockRemaining and state.lockRemaining > 0 then
		lockButton.Text = "LOCKED (" .. math.ceil(state.lockRemaining) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
	elseif state.lockCooldownRemaining and state.lockCooldownRemaining > 0 then
		lockButton.Text = "LOCK (" .. math.ceil(state.lockCooldownRemaining) .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	else
		lockButton.Text = "LOCK BASE (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	end

	rebirthButton.Text = "REBIRTH — " .. Catalog.formatMoney(state.rebirthCost or 0)

	if state.nextTier then
		nextName.Text = state.nextTier.name
		nextName.TextColor3 = Catalog.RARITY_COLORS[state.nextTier.rarity]
		nextDetail.Text = Catalog.RARITY_LABELS[state.nextTier.rarity]
			.. "  •  " .. Catalog.formatMoney(state.nextTier.cost)
			.. "  •  " .. Catalog.formatMoney(state.nextTier.rate) .. "/s"
		nextBlurb.Text = state.nextTier.blurb
	else
		nextName.Text = "YOU OWN THEM ALL!"
		nextDetail.Text = "Every brainrot is yours. Legend."
		nextBlurb.Text = ""
	end

	if #state.owned == 0 then
		baseList.Text = "No brainrots yet — buy one off the belt!"
	else
		local lines = {}
		for _, owned in ipairs(state.owned) do
			local line = owned.name .. " — " .. Catalog.formatMoney(owned.rate) .. "/s"
			if owned.mutation ~= "Normal" then
				line ..= " (" .. owned.mutation .. ")"
			end
			table.insert(lines, line)
		end
		baseList.Text = table.concat(lines, "\n")
	end

	local sneakersLevel = state.upgrades.SwiftSneakers or 0
	local magnetLevel = state.upgrades.MoneyMagnet or 0
	local sneakersCost = state.upgradeCosts and state.upgradeCosts.SwiftSneakers
	local magnetCost = state.upgradeCosts and state.upgradeCosts.MoneyMagnet
	sneakersButton.Text = "Swift Sneakers Lv" .. sneakersLevel
		.. (sneakersCost and (" — " .. Catalog.formatMoney(sneakersCost)) or " — MAX")
	magnetButton.Text = "Money Magnet Lv" .. magnetLevel
		.. (magnetCost and (" — " .. Catalog.formatMoney(magnetCost)) or " — MAX")
end)

Remotes.EventAlert.OnClientEvent:Connect(function(event)
	bannerLabel.Text = event.text
	bannerLabel.Visible = true
	bannerUntil = os.clock() + (event.secondsLeft or 0) + 2
	task.delay((event.secondsLeft or 0) + 2, function()
		if os.clock() >= bannerUntil then
			bannerLabel.Visible = false
		end
	end)
end)
