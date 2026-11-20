-- BrainrotFactory: builds the 3D model of one brainrot from its catalog
-- entry. One job only: turn data into a Model. It never touches money,
-- spawning or stealing; the services that call it own those decisions.
--
-- A model is a chunky body, a head, two eyes, a rarity accessory and a
-- BillboardGui label with the name, rarity and money-per-second, so a
-- player can read what a brainrot is worth from across the map.

local Catalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)

local BrainrotFactory = {}

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	return part
end

-- A little crown for gods, a star for secrets, a cap for the rest.
local function addAccessory(model, body, entry, scale)
	if entry.rarity == "BrainrotGod" then
		local crown = makePart("Crown", Vector3.new(1.6 * scale, 0.5 * scale, 1.6 * scale), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		crown.CFrame = body.CFrame * CFrame.new(0, 1.9 * scale, 0)
		crown.Parent = model
	elseif entry.rarity == "Secret" then
		local star = makePart("Star", Vector3.new(1.2 * scale, 1.2 * scale, 0.4 * scale), Color3.fromRGB(40, 230, 190), Enum.Material.Neon)
		star.CFrame = body.CFrame * CFrame.new(0, 2.1 * scale, 0)
		star.Parent = model
	elseif entry.rarity == "Mythic" then
		local gem = makePart("Gem", Vector3.new(0.9 * scale, 0.9 * scale, 0.9 * scale), Color3.fromRGB(255, 60, 90), Enum.Material.Neon)
		gem.CFrame = body.CFrame * CFrame.new(0, 1.9 * scale, 0)
		gem.Parent = model
	else
		local cap = makePart("Cap", Vector3.new(1.8 * scale, 0.4 * scale, 1.8 * scale), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		cap.CFrame = body.CFrame * CFrame.new(0, 1.75 * scale, 0)
		cap.Parent = model
	end
end

-- Rarity glow: rarer brainrots wear a neon aura shell so they read
-- from across the map; a mutation tints the aura its own colour, and
-- gods and secrets also carry a real light. Cheap on purpose: one
-- extra part per rare brainrot, one light only for the top tiers.
local RARITY_GLOW = { Mythic = true, BrainrotGod = true, Secret = true }
local MUTATION_GLOW_COLORS = {
	Golden = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(120, 230, 255),
	Rainbow = Color3.fromRGB(255, 120, 220),
}

local function addGlow(model, body, entry, mutationName)
	local auraColor = MUTATION_GLOW_COLORS[mutationName]
	if not auraColor and RARITY_GLOW[entry.rarity] then
		auraColor = Catalog.RARITY_COLORS[entry.rarity]
	end
	if not auraColor then
		return
	end
	local aura = makePart("Aura", body.Size + Vector3.new(0.5, 0.5, 0.5), auraColor, Enum.Material.Neon)
	aura.Transparency = 0.75
	aura.CFrame = body.CFrame
	aura.Parent = model
	if entry.rarity == "BrainrotGod" or entry.rarity == "Secret" then
		local light = Instance.new("PointLight")
		light.Color = auraColor
		light.Range = 9
		light.Brightness = 1
		light.Parent = body
	end
end

-- The floating label: name on top, rarity coloured, $/s underneath.
local function addLabel(model, body, entry, rateText, mutationName)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0, 22)
	rarityLabel.Size = UDim2.new(1, 0, 0, 20)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = Catalog.RARITY_LABELS[entry.rarity]
		.. (mutationName ~= "Normal" and (" • " .. string.upper(mutationName)) or "")
	rarityLabel.TextColor3 = Catalog.RARITY_COLORS[entry.rarity]
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0, 42)
	rateLabel.Size = UDim2.new(1, 0, 0, 22)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = rateText .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.Parent = gui
end

-- Build the model. kind is "Conveyor" or "Base"; the caller sets the
-- attributes the services need (BrainrotId, Mutation, OwnerId).
function BrainrotFactory.build(entry, mutationName, multiplier)
	local scale = entry.scale
	local rate = Catalog.rateOf(entry, multiplier)
	local model = Instance.new("Model")
	model.Name = entry.name

	local body = makePart("Body", Vector3.new(2.2 * scale, 2.4 * scale, 2.2 * scale), entry.color)
	body.CFrame = CFrame.new(0, 1.2 * scale, 0)
	body.Parent = model

	local head = makePart("Head", Vector3.new(1.8 * scale, 1.4 * scale, 1.8 * scale), entry.color)
	head.CFrame = body.CFrame * CFrame.new(0, 1.9 * scale, 0)
	head.Parent = model

	local eyeLeft = makePart("EyeLeft", Vector3.new(0.4 * scale, 0.5 * scale, 0.2 * scale), Color3.fromRGB(255, 255, 255))
	eyeLeft.CFrame = head.CFrame * CFrame.new(-0.4 * scale, 0.1 * scale, 0.95 * scale)
	eyeLeft.Parent = model

	local eyeRight = makePart("EyeRight", Vector3.new(0.4 * scale, 0.5 * scale, 0.2 * scale), Color3.fromRGB(255, 255, 255))
	eyeRight.CFrame = head.CFrame * CFrame.new(0.4 * scale, 0.1 * scale, 0.95 * scale)
	eyeRight.Parent = model

	local pupilLeft = makePart("PupilLeft", Vector3.new(0.2 * scale, 0.25 * scale, 0.1 * scale), Color3.fromRGB(20, 20, 20))
	pupilLeft.CFrame = head.CFrame * CFrame.new(-0.4 * scale, 0.1 * scale, 1.05 * scale)
	pupilLeft.Parent = model

	local pupilRight = makePart("PupilRight", Vector3.new(0.2 * scale, 0.25 * scale, 0.1 * scale), Color3.fromRGB(20, 20, 20))
	pupilRight.CFrame = head.CFrame * CFrame.new(0.4 * scale, 0.1 * scale, 1.05 * scale)
	pupilRight.Parent = model

	addAccessory(model, body, entry, scale)
	addGlow(model, body, entry, mutationName)
	addLabel(model, body, entry, Catalog.formatMoney(rate), mutationName)

	model.PrimaryPart = body
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Mutation", mutationName)
	model:SetAttribute("Multiplier", multiplier)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.Parent = body

	return model
end

-- Place a built model at a world position, facing the given direction.
function BrainrotFactory.placeAt(model, position, lookAt)
	model:PivotTo(CFrame.lookAt(position, lookAt or (position + Vector3.new(0, 0, 1))))
	model.Parent = workspace
	return model
end

return BrainrotFactory
