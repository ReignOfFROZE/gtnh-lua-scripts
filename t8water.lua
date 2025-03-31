local component = require('component')
local event = require('event')
local os = require('os')

function Check()
    for slot = 1,6
    do
        if component.transposer.getStackInSlot(4, slot) == nil or component.transposer.getStackInSlot(4, slot).size ~= 3 then
            return false
        end
    end
    return true
end

function CheckSuccess()
    return string.find(component.gt_machine.getSensorInformation()[4], "Yes") ~= nil
end

local sequence = {1,2,3,4,5,6,1,3,5,2,6,4,1,5,2,4,3,6}

local seq = 1

while true do
    local id, _, _, _ = event.pullMultiple("redstone_changed", "interrupted")
    if id == "interrupted" then
        print("Interrupt received, exiting...")
        component.redstone.setOutput(1,0)
        break
    end
    while Check() ~= true do
        print("All quarks not found, waiting...")
        os.sleep(5)
    end
    while CheckSuccess() ~= true and seq <= 18 do
        print("Transferring 1 "..component.transposer.getStackInSlot(4, sequence[seq]).label.." into the machine")
        component.transposer.transferItem(4,1,1,sequence[seq])
        seq = seq + 1
        os.sleep(1)
    end
end