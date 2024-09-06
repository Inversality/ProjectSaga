local components = require(script.Parent.Parent.components)
local Player = components.Player
local Health = components.Health
local Weight = components.Weight
local affectsWalkspeed = {Health, Weight}

-- Define the callbacks for adjusting walk speed based on component data
local walkspeedCallbacks = {
    Health = function(data)
        -- Return a modifier based on current health (minimum modifier of 0.8)
        return math.max(0.8, data.value / data.max)
    end,
    Weight = function(data)
        -- Return a modifier based on weight (minimum modifier of 0.7)
        return math.max(0.7, math.min(math.max(data.current,100) / (math.min(data.max,100)),1))
    end
}

local function walkSpeedService(world) 
    -- Query for entities with a Player component
    for id, playerComponent in world:query(Player) do
        -- Fetch the components that affect walk speed
        local results = {world:get(id, unpack(affectsWalkspeed))}

        -- Initialize walk speed modifier
        local modifier = 1

        -- Loop through the results and adjust the modifier based on each component
        for i, component in ipairs(affectsWalkspeed) do
            local componentData = results[i]
            if componentData then
                local callback = walkspeedCallbacks[tostring(component)]
                if callback then
                    modifier *= callback(componentData)
                end
            end
        end

        -- Here, you would apply the walk speed modifier to the player
        -- Example: playerComponent.walkSpeed = baseWalkSpeed * modifier
    end
end

return walkSpeedService
