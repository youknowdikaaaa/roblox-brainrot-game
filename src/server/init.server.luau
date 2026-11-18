-- init.server: boots Brainrot Bay. Order matters: the world first
-- (it makes the wave wall the events need), then the services.

local WorldBuilder = require(script.WorldBuilder)
local Conveyor = require(script.Conveyor)
local BrainrotService = require(script.BrainrotService)
local EventService = require(script.EventService)

local waveWall = WorldBuilder.buildAll()
EventService.start(waveWall)
BrainrotService.start()
Conveyor.start()

print("Brainrot Bay is live: buy brainrots, guard your base, outrun the wave.")
