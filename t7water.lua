local component = require('component')
local event = require('event')

function check(tank, slot, amt, name, contains)
    if tank[slot].amount < amt then
        component.redstone.setOutput(1,0)
        error("Fluid in tank slot "..slot.." was less than "..amt.."L.")
    end
    if contains ~= nil and contains then
        if string.find(tank[slot].name, name) == nil then
            component.redstone.setOutput(1,0)
            error("Fluid in tank slot "..slot.." did not contain the string '"..name.."'.")
        end
    else
        if tank[slot].name ~= name then
            component.redstone.setOutput(1,0)
            error("Fluid in tank slot "..slot.."was not '"..name.."'.")
        end
    end
end

-- find hatches/interfaces
local transposer = component.transposer
local interface1 = component.transposer.getFluidInTank(2)
local interface2 = component.transposer.getFluidInTank(5)

function setupChecks() 
    check(interface2, 1, 10000, "helium")
    check(interface2, 2, 7500, "neon")
    check(interface2, 3, 5000, "krypton")
    check(interface2, 4, 2500, "xenon")
    check(interface2, 5, 1440, "superconductor", true)
    check(interface2, 6, 10000, "supercoolant")
    check(interface1, 1, 4608, "molten.neutronium")
end

setupChecks()
print("All initial checks passed, enabling degasser...")
component.redstone.setOutput(1,15)

local proxy = component.proxy(component.transposer.address)

while true do
    local id, _, side, _ = event.pullMultiple("redstone_changed", "interrupted")
    if side ~= nil and side == 2 then
        setupChecks()
        local signal = component.redstone.getInput()[2]
        print("Signal:",signal)
        local bit4 = (signal & 8) >> 3
        local bit3 = (signal & 4) >> 2
        local bit2 = (signal & 2) >> 1
        local bit1 = signal & 1
        print("Bits:",bit4,bit3,bit2,bit1)
        if bit4 ~= 1 then
            if bit4 == 0 and bit3 == 0 and bit2 == 0 and bit1 == 0 then
                print("Transferring 10,000L of Super Coolant")
                proxy.transferFluid(5,1,10000,5)
            else
                -- individual things
                if bit1 == 1 then
                    local nobleGas = (signal & 6) >> 1
                    local amt = 10000 - (nobleGas * 2500)
                    print("Transferring",amt.."L of noble gas", nobleGas)
                    proxy.transferFluid(5,1,amt,nobleGas)
                end
                if bit2 == 1 then
                    print("Transferring 1440L of Molten Superconductor Base")
                    proxy.transferFluid(5,1,1440,4)
                end
                if bit3 == 1 then
                    print("Transferring 4608L of Molten Neutronium")
                    proxy.transferFluid(2,1,4608,0)
                end
            end
        else
            print("Bit 4 was on, no-op")
        end
    end
    if id == "interrupted" then
        print("Interrupt received, exiting...")
        component.redstone.setOutput(1,0)
        break
    end
end