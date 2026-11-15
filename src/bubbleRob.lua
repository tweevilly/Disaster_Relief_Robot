-- Disaster Relief Robot (BubbleRob) -- child script for CoppeliaSim
--
-- Scenario: a classroom after an earthquake. The robot explores the room,
-- backs away from obstacles, and reports each trapped "survivor" (a pink
-- cylinder) the first time its ray sensor sees it.

sim = require 'sim'
simUI = require 'simUI'

-- Survivors the robot is searching for: scene path -> name it announces.
local SURVIVOR_SPECS = {
    { path = "/Cate",    name = "Cate" },
    { path = "/Duc",     name = "Duc" },
    { path = "/Brandon", name = "Brandon" },
    { path = "/ThuyVi",  name = "Thuy-Vi" },
}

local BACKUP_SECONDS = 3 -- how long to reverse after the nose sensor fires

function sysCall_init()
    -- Executed once, the first time this script runs.
    bubbleRobBase = sim.getObject('..')                  -- robot body
    leftMotor     = sim.getObject("../leftMotor")
    rightMotor    = sim.getObject("../rightMotor")
    frontSensor   = sim.getObject("../sensingNose")      -- cone proximity sensor (obstacles)
    personSensor  = sim.getObject("../personSensor")     -- ray proximity sensor (survivors)
    graph         = sim.getObject('../graph')

    -- Knowledge representation: one record per survivor, with a "found" flag
    -- so each person is only reported once.
    survivors = {}
    for _, spec in ipairs(SURVIVOR_SPECS) do
        survivors[#survivors + 1] = {
            handle = sim.getObject(spec.path),
            name   = spec.name,
            found  = false,
        }
    end

    minMaxSpeed = { 50 * math.pi / 180, 300 * math.pi / 180 } -- min / max joint speed (rad/s)

    -- Short-term memory: robot reverses until this simulation time.
    backUntilTime = -1

    -- Visualisation of the robot's internal picture of the world.
    robotCollection = sim.createCollection(0)
    sim.addItemToCollection(robotCollection, sim.handle_tree, bubbleRobBase, 0)
    distanceSegment = sim.addDrawingObject(sim.drawing_lines, 4, 0, -1, 1, { 0, 1, 0 })
    robotTrace = sim.addDrawingObject(
        sim.drawing_linestrip + sim.drawing_cyclic, 2, 0, -1, 200,
        { 1, 1, 0 }, nil, nil, { 1, 1, 0 })
    distStream = sim.addGraphStream(graph, 'bubbleRob clearance', 'm', 0, { 1, 0, 0 })

    -- Speed slider UI.
    local xml = '<ui title="' .. sim.getObjectAlias(bubbleRobBase, 1) ..
        ' speed" closeable="false" resizable="false" activate="false">' .. [[
                <hslider minimum="0" maximum="100" on-change="speedChange_callback" id="1"/>
            <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
    ui = simUI.create(xml)
    speed = (minMaxSpeed[1] + minMaxSpeed[2]) * 0.5
    simUI.setSliderValue(ui, 1, 100 * (speed - minMaxSpeed[1]) / (minMaxSpeed[2] - minMaxSpeed[1]))
end

function sysCall_sensing()
    -- Clearance graph: distance from the robot to the nearest obstacle.
    local result, distData = sim.checkDistance(robotCollection, sim.handle_all)
    if result > 0 then
        sim.addDrawingObjectItem(distanceSegment, nil)
        sim.addDrawingObjectItem(distanceSegment, distData)
        sim.setGraphStreamValue(graph, distStream, distData[7])
    end

    -- Path trace.
    local p = sim.getObjectPosition(bubbleRobBase)
    sim.addDrawingObjectItem(robotTrace, p)
end

function speedChange_callback(ui, id, newVal)
    speed = minMaxSpeed[1] + (minMaxSpeed[2] - minMaxSpeed[1]) * newVal / 100
end

function sysCall_actuation()
    -- Reasoning: obstacle ahead -> enter backward mode for a few seconds.
    local obstacle = sim.readProximitySensor(frontSensor)
    if obstacle > 0 then
        backUntilTime = sim.getSimulationTime() + BACKUP_SECONDS
    end

    -- Survivor detection: announce each person once.
    local seen, _, _, detectedObject = sim.readProximitySensor(personSensor)
    if seen > 0 then
        for _, s in ipairs(survivors) do
            if detectedObject == s.handle and not s.found then
                print("I found " .. s.name)
                s.found = true
            end
        end
    end

    -- Locomotion.
    if backUntilTime < sim.getSimulationTime() then
        -- Forward mode: drive straight at the chosen speed.
        sim.setJointTargetVelocity(leftMotor, speed)
        sim.setJointTargetVelocity(rightMotor, speed)
    else
        -- Backward mode: reverse in a curve at reduced speed.
        sim.setJointTargetVelocity(leftMotor, -speed / 2)
        sim.setJointTargetVelocity(rightMotor, -speed / 4)
    end
end

function sysCall_cleanup()
    simUI.destroy(ui)
end
