local Matter = require(game.ReplicatedStorage.Packages.matter)

return {
     Player = Matter.component(),
     Health = Matter.component(),
     weapon = Matter.component(),
     Weight = Matter.component(),
     Inventory = Matter.component(function()
        return {
            items = {}  -- Initialize with an empty list of items
        }
    
    end),
    DamageReduction = Matter.component()
}