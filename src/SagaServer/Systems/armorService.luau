local components = require(script.Parent.Parent.components)
local Armor = components.Armor
local damageReduction = components.damageReduction
local Player = components.Player
local function armorSystem(world)
    for id,player in world:query(Player) do 
        local reducedDamage = math.max(0,Armor/100)
        world.insert(id,damageReduction:patch({
            current = reducedDamage
        }))

    end
   
end

return armorSystem