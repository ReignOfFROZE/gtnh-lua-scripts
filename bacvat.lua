local component = require("component")

function DiscoverHatches() 
    local proxies = {}
    local i = 1
    for key, value in pairs(component.list()) do
        if value == "gt_machine" then
            proxies[i] = component.proxy(key, "gt_machine")

        end
    end

    return nil
end

DiscoverHatches()