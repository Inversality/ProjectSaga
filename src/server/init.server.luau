local jecs = require(game.ReplicatedStorage.Packages.jecs)
local world = jecs.World.new()


local Position = world:component()
local Velocity = world:component()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DocumentService = require(game.ReplicatedStorage.Packages.DocumentService)  -- Assuming it's stored in ReplicatedStorage
local Guard = require(game.ReplicatedStorage.Packages.Guard)  -- Guard for data validation


local entityCache = {}
local state = {}

-- Function to get or create an entity for the player
function ref(player)
    -- Check if the player already has an entity in the cache
    if entityCache[player] then
        return entityCache[player]  -- Return the cached entity
    else
        -- Create a new entity
        local newEntity = world:entity()  -- Assuming `world:createEntity` exists in your ECS
        entityCache[player] = newEntity  -- Cache the entity for future reference
        return newEntity  -- Return the newly created entity
    end
end


-- Define the DataSchema and Guard system for validation
type DataSchema = {
    inventory: table,
}

local DataInterface = {
    inventory = Guard.List,  -- Ensures that the inventory is an array (list of items)
}

-- Data validation function
local function dataCheck(value): DataSchema
    assert(type(value) == "table", "Data must be a table")
    local Value: any = value

    return {
        inventory = DataInterface.inventory(Value.inventory),  -- Ensure empty table is treated as array
    }
end
-- Set up the DocumentStore for storing player data
local store = DocumentService.DocumentStore.new({
    dataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData"),  -- The actual DataStore
    check = Guard.Check(dataCheck),  -- Validate data using the Guard system
    default = {
        inventory = {},  -- Explicitly set the default inventory to be an array
    },
    migrations = {},  -- If you need to migrate older versions of data
    lockSessions = true,  -- Enable session locking to prevent data conflicts
 })

 
 local components = {
    Health = world:component(),
    Armor = world:component(),
    Weight = world:component(),
    WalkSpeed = world:component(),
    Stamina = world:component(),
    Inventory = world:component(),
    damageReduction = world:component(),
}


-- Handle when a player joins
Players.PlayerAdded:Connect(function(Player)
    local playerEntity = ref(Player) 
    -- Get the player's document using their UserId
    local document = store:GetDocument(tostring(Player.UserId))
    local result = document:Open()

    -- Handle locked session case and attempt to steal the document
    if not result.success and result.reason == "SessionLockedError" then
        document:Steal()
        result = document:Open()
    end

    -- Handle document opening errors
    if not result.success then
        if result.reason == "BackwardsCompatibilityError" then
            Player:Kick("You joined an old server which does not support your saved data. Please try joining another server. If this persists, contact a developer.")
        elseif result.reason == "RobloxAPIError" then
            Player:Kick("Failed to load data due to a Roblox service issue. Try again later.")
        else
            Player:Kick("Failed to load data: " .. result.reason .. ". Please screenshot this message and report it to a developer.")
        end
        return  -- Return early to prevent further execution
    end

    -- Retrieve the player's inventorpy from the document, or create a new empty inventory
    local playerInventory = result.data.inventory



    local t = {
        Health = { current = 100, max = 100 },
        Armor = {current = 0, max = 75},
        Weight = { current = 100, max = 100 },
        WalkSpeed = { current = 16, max = 16 },
        Stamina = { current = 50, max = 50 },
        Inventory = { items = playerInventory },
        damageReduction = {current = 0, max = .5}
    }

    for entity_name, data in pairs(t) do
      
        world:set(playerEntity, components[entity_name], data)
        
    end
end)
-- Handle when a player leaves
Players.PlayerRemoving:Connect(function(Player)
    local playerEntity = entityCache[Player]
    local inventoryComponent = world:get(playerEntity, components.Inventory)

        if inventoryComponent then
            -- Save the inventory to the document and close it to release the session lock
            
            local document = store:GetDocument(tostring(Player.UserId))
            
            document:Read().data.inventory = inventoryComponent.items 
          
            local success, err = document:Close()  -- Close instead of Save
            
            if not success then
                warn("Failed to save and close inventory for player " .. Player.UserId .. ": " .. err)
            end
        end

        
         world:delete(playerEntity)
        
   
end)
