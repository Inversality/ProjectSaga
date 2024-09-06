local Matter = require(game.ReplicatedStorage.Packages.matter)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DocumentStore = require(game.ReplicatedStorage.Packages.DocumentService)  -- Assuming it's stored in ReplicatedStorage
local Guard = require(game.ReplicatedStorage.Packages.Guard)  -- Guard for data validation


-- Load components
local components = require(script.components)
local Health = components.Health
local WalkSpeed = components.WalkSpeed
local Stamina = components.Stamina
local Inventory = components.Inventory
local Weight = components.Weight
local Armor = components.Armor 
local PlayerData = components.PlayerData 
local damageReduction = components.damageReduction 

local world = Matter.World.new()
local Plasma = require(game.ReplicatedStorage.Packages.plasma)

local debugger = Matter.Debugger.new(Plasma) -- Pass Plasma into the debugger!
local widgets = debugger:getWidgets()
local state = {}
local loop = Matter.Loop.new(world, state, widgets)

debugger:autoInitialize(loop)
-- Dictionary to track player entities
local playerEntities = {}

-- Load systems dynamically
local systems = {}
for _, child in ipairs(script.Systems:GetChildren()) do
    if child:IsA("ModuleScript") then
        table.insert(systems, require(child))
    end
end

-- Schedule systems for the loop
loop:scheduleSystems(systems)
loop:begin({
    default = RunService.Heartbeat
})

-- Define the DataSchema and Guard system for validation
type DataSchema = {
    inventory: table,
}

local DataInterface = {
    inventory = Guard.Array,  -- Ensures that the inventory is an array (list of items)
}

-- Data validation function
local function dataCheck(value: unknown): DataSchema
    assert(type(value) == "table", "Data must be a table")
    local Value: any = value

    return {
        inventory = DataInterface.inventory(Value.inventory),
    }
end

-- Set up the DocumentStore for storing player data
local store = DocumentStore.new({
   dataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData"),  -- The actual DataStore
   check = Guard.Check(dataCheck),  -- Validate data using the Guard system
   default = {
       inventory = {},  -- Empty inventory for new players
   },
   migrations = {},  -- If you need to migrate older versions of data
   lockSessions = true,  -- Enable session locking to prevent data conflicts
})

-- Handle when a player joins
Players.PlayerAdded:Connect(function(Player)
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

    -- Retrieve the player's inventory from the document, or create a new empty inventory
    local playerInventory = document.data.inventory

    local PlayerData = Matter.component(function(userId)
        return { userId = userId }
    end)
    
    -- Spawn the player entity and store its ID
    local playerEntityId = world:spawn(
        PlayerData(Player.UserId),
        Health({ current = 100, max = 100 }),
        Armor({current = 0, max = 75}),
        Weight({ current = 100, max = 100 }),
        WalkSpeed({ current = 16, max = 16 }),
        Stamina({ current = 50, max = 50 }),
        Inventory({ items = playerInventory }),  -- Load items from the document or initialize an empty inventory
        damageReduction({current = 0, max = .5})
    )

    -- Store the player entity ID in a dictionary for later reference
    playerEntities[Player.UserId] = playerEntityId
end)

-- Handle when a player leaves
Players.PlayerRemoving:Connect(function(Player)
    local playerEntityId = playerEntities[Player.UserId]
    if playerEntityId then
        -- Retrieve the player's inventory component
        local inventoryComponent = world:get(playerEntityId, Inventory)
        
        if inventoryComponent then
            -- Save the inventory to the document
            local document = store:GetDocument(tostring(Player.UserId))
            document.data.inventory = inventoryComponent.items  -- Ensure consistency in property name
            local success, err = document:Save()
            
            if not success then
                warn("Failed to save inventory for player " .. Player.UserId .. ": " .. err)
            end
        end

        -- Despawn the player entity
        world:despawn(playerEntityId)

        -- Clean up the player entity reference from the dictionary
        playerEntities[Player.UserId] = nil
    end
end)
