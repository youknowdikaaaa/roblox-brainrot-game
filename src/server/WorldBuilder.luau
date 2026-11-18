-- WorldBuilder: the decorations the place file does not carry. It runs
-- once at boot: the big BRAINROT BAY sign on the conveyor arch, the
-- fountain's sparkles, the owner name signs over each base plot, and
-- the slime wave wall the EventService sweeps across the map.
-- One job: make the static world feel alive. It never touches money.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

-- A text sign on the arch beam over the conveyor entrance.
function WorldBuilder.buildArchSign()
	local beam = workspace:FindFirstChild("ArchBeam")
	if not beam then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ArchSign"
	gui.Face = Enum.NormalId.Right
	gui.Parent = beam

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 40, 90)
	label.BorderSizePixel = 0
	label.Text = "BRAINROT BAY"
	label.TextColor3 = Color3.fromRGB(255, 220, 60)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
end

-- Sparkles over the fountain so the middle of the map reads as a
-- landmark, not an empty square.
function WorldBuilder.buildFountainEffects()
	local water = workspace:FindFirstChild("FountainWater")
	if not water then
		return
	end
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "FountainSparkles"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
	sparkles.Size = NumberSequence.new(0.4)
	sparkles.Rate = 24
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Speed = NumberRange.new(2, 5)
	sparkles.Parent = water
end

-- One floating owner sign per plot. BrainrotService updates the text
-- when a player claims or leaves a plot.
function WorldBuilder.buildPlotSigns()
	for index, center in ipairs(Config.PLOT_CENTERS) do
		local floor = workspace:FindFirstChild("Plot" .. index .. "Floor")
		if floor then
			local gui = Instance.new("BillboardGui")
			gui.Name = "OwnerSign"
			gui.Adornee = floor
			gui.Size = UDim2.fromOffset(160, 40)
			gui.StudsOffset = Vector3.new(0, 7, 0)
			gui.AlwaysOnTop = true
			gui.Parent = floor

			local label = Instance.new("TextLabel")
			label.Name = "OwnerName"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 0.4
			label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			label.Text = "BASE " .. index .. " — EMPTY"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextScaled = true
			label.Font = Enum.Font.SourceSansBold
			label.Parent = gui
		end
	end
end

-- The slime wave wall: a tall translucent slab, parked out of sight
-- until EventService sweeps it across the map.
function WorldBuilder.buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "SlimeWave"
	wall.Size = Vector3.new(2, 30, 240)
	wall.Color = Color3.fromRGB(60, 200, 90)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.4
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CFrame = CFrame.new(-300, 15, 0)
	wall.Parent = workspace
	return wall
end

function WorldBuilder.buildAll()
	WorldBuilder.buildArchSign()
	WorldBuilder.buildFountainEffects()
	WorldBuilder.buildPlotSigns()
	return WorldBuilder.buildWaveWall()
end

return WorldBuilder
