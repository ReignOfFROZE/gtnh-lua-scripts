local event = require('event')
local string = require('string')
local component = require('component')

local ITEM_TRANSPOSER = component.proxy("a5a5e7e5-e30d-49f8-a7bb-a152568efd1e", "transposer")
local FLUID_TRANSPOSER = component.proxy("55cda2c9-4dc0-4705-a304-b34af9097867", "transposer")

local SPATIAL_SIDE = 4
local TACHYON_SIDE = 0
local FLUID_TRASH_SIDE = 5
local FLUID_INTERFACE_SIDE = 1
local ITEM_BUS_SIDE = 2
local ITEM_TRASH_SIDE = 0

local AE2 = component.me_interface

function Reset()
    FLUID_TRANSPOSER.transferFluid(SPATIAL_SIDE, FLUID_TRASH_SIDE, 16384000)
    FLUID_TRANSPOSER.transferFluid(TACHYON_SIDE, FLUID_TRASH_SIDE, 16384000)
    ITEM_TRANSPOSER.transferItem(ITEM_BUS_SIDE, ITEM_TRASH_SIDE, 64)
end

function MoveFluids()
    FLUID_TRANSPOSER.transferFluid(SPATIAL_SIDE, FLUID_INTERFACE_SIDE, FLUID_TRANSPOSER.getFluidInTank(SPATIAL_SIDE, 1).amount)
    FLUID_TRANSPOSER.transferFluid(TACHYON_SIDE, FLUID_INTERFACE_SIDE, FLUID_TRANSPOSER.getFluidInTank(TACHYON_SIDE, 1).amount)
    ITEM_TRANSPOSER.transferItem(ITEM_BUS_SIDE, ITEM_TRASH_SIDE, 64)
end

while true do
    ::rewait::
    local spatialLevel = FLUID_TRANSPOSER.getFluidInTank(SPATIAL_SIDE, 1).amount
    local tachyonLevel = FLUID_TRANSPOSER.getFluidInTank(TACHYON_SIDE, 1).amount
    local item = ITEM_TRANSPOSER.getStackInSlot(ITEM_BUS_SIDE, 1)
    if spatialLevel == 0 or tachyonLevel == 0 then
        Reset()
        local id, _, _, _, signal = event.pullMultiple("redstone_changed", "interrupted")

        if id == "interrupted" then
            break
        end

        if signal == 0 then
            goto rewait
        else
            spatialLevel = FLUID_TRANSPOSER.getFluidInTank(SPATIAL_SIDE, 1).amount
            tachyonLevel = FLUID_TRANSPOSER.getFluidInTank(TACHYON_SIDE, 1).amount
            item = ITEM_TRANSPOSER.getStackInSlot(ITEM_BUS_SIDE, 1)
        end
    end
    local diff = spatialLevel - tachyonLevel
    local count = diff * 144
    local plasma = "drop of "..string.gsub(item.label, " Dust", "").." Plasma"
    local craftables = AE2.getCraftables({["label"] = plasma})
    if #craftables > 0 then
        local craft = craftables[1].request(count)

        while craft.isComputing() == true do
            os.sleep(1)
        end
        if craft.hasFailed() then
            print("Failed to request " .. plasma .. " x " .. count)
        else
            print("Requested " .. plasma .. " x " .. count)
            MoveFluids()
            os.sleep(5)
        end
    end
end