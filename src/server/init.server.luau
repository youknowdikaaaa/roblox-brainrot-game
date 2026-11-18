-- init.server: boots Brainrot Bay. Order matters: the world first
-- (it makes the wave wall the events need), then the services.

local WorldBuilder = require(script.Parent.WorldBuilder)
local Conveyor = require(script.Parent.Conveyor)
local BrainrotService = require(script.Parent.BrainrotService)
local EventService = require(script.Parent.EventService)

local waveWall = WorldBuilder.buildAll()
EventService.start(waveWall)
BrainrotService.start()
Conveyor.start()

print("Brainrot Bay is live: buy brainrots, guard your base, outrun the wave.")
