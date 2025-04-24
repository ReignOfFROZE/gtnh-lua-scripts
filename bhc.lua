local component = require('component')
local event = require('event')
local os = require('os')
local math = require('math')

local TIMEOUT = 60 * 5

local AE2 = component.me_interface

local SPACETIME_SIDE = 5
local CONTROLLER_SIDE = 4
local PRIMARY_REDSTONE_ADDRESS = "8c79c435-bf26-470f-9314-7b667357b687"
local INPUT_WATCHER_ADDRESS = "168cc206-05ae-43cd-8496-3a192db37590"

local primaryRedstone = component.proxy(PRIMARY_REDSTONE_ADDRESS, "redstone")

local SEED_SLOT = 1
local COLLAPSER_SLOT = 2

local count = 0

local spacetimeQuery = {
    ["label"] = "drop of Molten SpaceTime"
}

local mainRedstone = component.proxy(PRIMARY_REDSTONE_ADDRESS, "redstone")
local inputRedstone = component.proxy(INPUT_WATCHER_ADDRESS, "redstone")

local flag = false

function Seed()
    while component.transposer.getStackInSlot(0,1) == nil do
        os.sleep(1)
    end
    component.transposer.transferItem(0,1,1,SEED_SLOT)
end

function Collapse()
    mainRedstone.setOutput(SPACETIME_SIDE, 0)
    while component.transposer.getStackInSlot(0,2) == nil do
        primaryRedstone.setOutput(CONTROLLER_SIDE, 15)
        os.sleep(1)
    end
    primaryRedstone.setOutput(CONTROLLER_SIDE, 0)
    component.transposer.transferItem(0,1,1,COLLAPSER_SLOT)
    count = 0
end

while true do
    local id, address, signal = nil, nil, nil
    if inputRedstone.getInput(5) == 0 then
        while address ~= INPUT_WATCHER_ADDRESS or signal ~= 15 do
            id, address, _, _, signal = event.pullMultiple("redstone_changed", "interrupted")

            if id == "interrupted" then
                mainRedstone.setOutput(SPACETIME_SIDE, 0)
                flag = true
                break
            end
        end
    end
    if flag then
        break
    end
    print("Enabling black hole")
    Seed()
    -- collapser loop
    while true do
        local id, _, _, _, signal = event.pullMultiple("redstone_changed", "interrupted")
        if id == "interrupted" then
            mainRedstone.setOutput(SPACETIME_SIDE, 0)
            flag = true
            break
        end
        if signal == 15 then
            count = count + 1
            print(count.."s have passed")
            if count >= 81 then
                local storedSpacetime = AE2.getItemsInNetwork(spacetimeQuery)
                if #storedSpacetime >= 1 then
                    if storedSpacetime[1].size >= 2^math.floor((count - 81) / 30) then
                        mainRedstone.setOutput(SPACETIME_SIDE, 15)
                    else
                        print("Not enough spacetime, collapsing")
                        Collapse()
                        break
                    end
                end
            end
            if count % TIMEOUT == 0 then
                Collapse()
                break
            end
        end
    end
    if flag then
        break
    end
end