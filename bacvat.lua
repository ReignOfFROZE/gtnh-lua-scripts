local component = require("component")
local sides = require("sides")
local event = require("event")
local hatches = {}

print("Discovering hatches ...")
for address, name in component.list("transposer", true) do
    local proxy = component.proxy(address)
    print("Found transposer @ " .. address)
    for _, side in ipairs({ 0, 1, 2, 3, 4, 5 }) do
        if proxy.getInventoryName(side) == "gt.blockmachines" then
            local capacity = proxy.getTankCapacity(side)
            if capacity ~= 0 then
                print("Found hatch on side " .. sides[side] .. " with capacity " .. capacity)
                table.insert(hatches, { proxy, side, capacity / 2 })
            end
        end
    end
end

function rebalance()
    for _, hatch in ipairs(hatches) do
        local proxy, side, half = table.unpack(hatch)
        local potentialSinkSides = { 0, 2, 3, 4, 5 }
        local sinkSide = nil
        local level = proxy.getFluidInTank(side)[1].amount
        if level > half then
            for _, candidate in ipairs(potentialSinkSides) do
                if proxy.getTankCapacity(candidate) == 16000 then
                    sinkSide = candidate
                    break
                end
            end
            if sinkSide ~= nil then
                print("Transferring " ..
                level - half ..
                "L of fluid from tank on side " ..
                side .. " to tank on side " .. sinkSide .. " of transposer " .. proxy.address)
                proxy.transferFluid(side, sinkSide, level - half)
            end
        end
    end
end

rebalance()
while true do
    local id, _, _, _ = event.pullMultiple("redstone_changed", "interrupted")
    if id == "interrupted" then
        print("Interrupt received, exiting...")
        break
    end
    rebalance()
end
