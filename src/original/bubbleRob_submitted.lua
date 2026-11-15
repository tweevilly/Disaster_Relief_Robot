sim=require'sim'
simUI=require'simUI'

function sysCall_init()
         
    -- This is executed exactly once, the first time this script is executed
    bubbleRobBase=sim.getObject('..') -- this is bubbleRob's handle
    leftMotor=sim.getObject("../leftMotor") -- Handle of the left motor
    rightMotor=sim.getObject("../rightMotor") -- Handle of the right motor
    frontSensor=sim.getObject("../sensingNose") -- Handle of the proximity sensor
    personSensor=sim.getObject("../personSensor") -- Handle of the ray sensor
    person1=sim.getObject("/Cate")--handle of cylinder
    person2=sim.getObject("/Duc")--handle of cylinder
    person3=sim.getObject("/Brandon")--handle of cylinder
    person4=sim.getObject("/ThuyVi")--handle of cylinder
    
    minMaxSpeed={50*math.pi/180,300*math.pi/180} -- Min and max speeds for each motor
    
    backUntilTime=-1 -- Tells whether bubbleRob is in forward or backward mode
    robotCollection=sim.createCollection(0)
    sim.addItemToCollection(robotCollection,sim.handle_tree,bubbleRobBase,0)
    distanceSegment=sim.addDrawingObject(sim.drawing_lines,4,0,-1,1,{0,1,0})
    robotTrace=sim.addDrawingObject(sim.drawing_linestrip+sim.drawing_cyclic,2,0,-1,200,{1,1,0},nil,nil,{1,1,0})
    graph=sim.getObject('../graph')
    
    --sim.destroyGraphCurve(graph,-1)
    distStream=sim.addGraphStream(graph,'bubbleRob clearance','m',0,{1,0,0})
    -- Create the custom UI:
    xml = '<ui title="'..sim.getObjectAlias(bubbleRobBase,1)..' speed" closeable="false" resizable="false" activate="false">'..[[
                <hslider minimum="0" maximum="100" on-change="speedChange_callback" id="1"/>
            <label text="" style="* {margin-left: 300px;}"/>
        </ui>
        ]]
    ui=simUI.create(xml)
    speed=(minMaxSpeed[1]+minMaxSpeed[2])*0.5
    simUI.setSliderValue(ui,1,100*(speed-minMaxSpeed[1])/(minMaxSpeed[2]-minMaxSpeed[1]))
    
end

function sysCall_sensing()
    --bubbleRob graph
    local result,distData=sim.checkDistance(robotCollection,sim.handle_all)
    if result>0 then
        sim.addDrawingObjectItem(distanceSegment,nil)
        sim.addDrawingObjectItem(distanceSegment,distData)
        sim.setGraphStreamValue(graph,distStream,distData[7])
    end
    local p=sim.getObjectPosition(bubbleRobBase)
    sim.addDrawingObjectItem(robotTrace,p)
end 

function speedChange_callback(ui,id,newVal)
    speed=minMaxSpeed[1]+(minMaxSpeed[2]-minMaxSpeed[1])*newVal/100
end

function sysCall_actuation() 
    -- Read the proximity sensor
    result=sim.readProximitySensor(frontSensor)
    -- If we detect something, we set the backward mode:
    if (result>0) then backUntilTime=sim.getSimulationTime()+3 end
    
    --If we detect people we signal back once  
    result_person, distance, detectedPoint, detectedObject = sim.readProximitySensor(personSensor)
    if result_person > 0 then
        if detectedObject == person1 and not foundIt1 then
            print("I found Cate")
            foundIt1 = true
        end
    end
    if result_person > 0 then
        if detectedObject == person2 and not foundIt2 then
            print("I found Duc")
            foundIt2 = true
        end
    end
    if result_person > 0 then
        if detectedObject == person3 and not foundIt3 then
            print("I found Brandon")
            foundIt3 = true
        end
    end
    if result_person > 0 then
        if detectedObject == person4 and not foundIt4 then
            print("I found Thuy-Vi")
            foundIt4 = true
        end
    end

    if (backUntilTime<sim.getSimulationTime()) then
        -- When in forward mode, move forward at the desired speed
        sim.setJointTargetVelocity(leftMotor,speed)
        sim.setJointTargetVelocity(rightMotor,speed)
    else
        -- When in backward mode, backup in a curve at reduced speed
        sim.setJointTargetVelocity(leftMotor, -speed/2)
        sim.setJointTargetVelocity(rightMotor,-speed/4)
    end
end

function sysCall_cleanup() 
    simUI.destroy(ui)
end 