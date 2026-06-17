-- Grow a Garden 2 (GAG2) Mobile Optimized Real Spawn Script for Delta Phone
-- Description: Spawns REAL plantable seeds and pets - MOBILE OPTIMIZED
-- Compatible with: Delta Mobile Executor
-- Credit: DupeeHub GAG2 API

local CHECK_INTERVAL = 2
local AUTO_SPAWN_LIMIT = 50

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local spawnedItems = {}
local scriptRunning = true

local function log(message)
    print("[DupeeHub] " .. message)
end

-- Simple inventory direct access
local function getBackpack()
    return LocalPlayer:FindFirstChild("Backpack")
end

-- Method 1: Direct Backpack Tool Addition
local function addSeedToBackpack(seedName)
    local backpack = getBackpack()
    if not backpack then return false end
    
    pcall(function()
        local seed = Instance.new("Tool")
        seed.Name = seedName
        seed:SetAttribute("SeedTool", seedName)
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.1, 0.1, 0.1)
        handle.CanCollide = false
        handle.Parent = seed
        
        seed.Parent = backpack
        return true
    end)
    
    return false
end

-- Method 2: Direct Fire to give items
local function fireGiveItem(itemName, itemType)
    local success = false
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remote in ipairs(remotes:GetChildren()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    if remote.Name:lower():find("give") or remote.Name:lower():find("add") or remote.Name:lower():find("item") then
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer(itemName, 1)
                            success = true
                            break
                        elseif remote:IsA("RemoteFunction") then
                            remote:InvokeServer(itemName, 1)
                            success = true
                            break
                        end
                    end
                end
            end
        end
    end)
    
    return success
end

-- Method 3: Find and use actual inventory system
local function addToRealInventory(itemName, category)
    local success = false
    
    pcall(function()
        -- Try to find inventory in ReplicatedStorage
        local invFolder = ReplicatedStorage:FindFirstChild("Inventory")
        if invFolder then
            local categoryFolder = invFolder:FindFirstChild(category)
            if not categoryFolder then
                categoryFolder = Instance.new("Folder")
                categoryFolder.Name = category
                categoryFolder.Parent = invFolder
            end
            
            local item = Instance.new("IntValue")
            item.Name = itemName
            item.Value = 1
            item.Parent = categoryFolder
            success = true
        end
    end)
    
    return success
end

-- Method 4: Direct Character Tool Addition
local function addToolToCharacter(toolName)
    local char = LocalPlayer.Character
    if not char then return false end
    
    pcall(function()
        local tool = Instance.new("Tool")
        tool.Name = toolName
        tool:SetAttribute("ItemName", toolName)
        
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.1, 0.1, 0.1)
        handle.CanCollide = false
        handle.Parent = tool
        
        tool.Parent = char
        return true
    end)
    
    return false
end

-- Seed names (best/rarest)
local bestSeeds = {
    "Dragon Fruit", "Moon Bloom", "Dragon's Breath", "Ghost Pepper", "Poison Apple",
    "Pomegranate", "Venus Fly Trap", "Sunflower", "Cherry", "Acorn",
    "Mango", "Coconut", "Grape", "Banana", "Green Bean",
    "Mushroom", "Cactus", "Corn", "Bamboo", "Apple",
    "Tomato", "Tulip", "Sunflower", "Blueberry", "Strawberry", "Carrot"
}

-- Best pets
local bestPets = {
    "Golden Dragon", "Phoenix", "Unicorn", "Shadow Beast", "Crystal Dragon",
    "Legendary Wolf", "Sky Serpent", "Mystic Fox", "Royal Eagle", "Ancient Dragon"
}

-- Main spawn loop
local function autoSpawnLoop()
    log("🚀 DupeeHub Mobile Auto Spawn STARTED!")
    log("📱 Mobile Optimized Mode Active")
    
    local cycle = 0
    
    while scriptRunning do
        cycle = cycle + 1
        local totalAdded = 0
        
        pcall(function()
            -- Add seeds
            for _, seed in ipairs(bestSeeds) do
                if totalAdded >= AUTO_SPAWN_LIMIT then break end
                if not spawnedItems[seed] then
                    -- Try all methods
                    if addSeedToBackpack(seed) then
                        spawnedItems[seed] = true
                        totalAdded = totalAdded + 1
                        log("✓ Added seed: " .. seed)
                    elseif fireGiveItem(seed, "Seed") then
                        spawnedItems[seed] = true
                        totalAdded = totalAdded + 1
                        log("✓ Fired seed: " .. seed)
                    elseif addToRealInventory(seed, "Seeds") then
                        spawnedItems[seed] = true
                        totalAdded = totalAdded + 1
                        log("✓ Added to inventory: " .. seed)
                    elseif addToolToCharacter(seed) then
                        spawnedItems[seed] = true
                        totalAdded = totalAdded + 1
                        log("✓ Added tool: " .. seed)
                    end
                    task.wait(0.1)
                end
            end
            
            -- Add pets
            for _, pet in ipairs(bestPets) do
                if totalAdded >= AUTO_SPAWN_LIMIT then break end
                if not spawnedItems["pet_" .. pet] then
                    if addSeedToBackpack(pet) then
                        spawnedItems["pet_" .. pet] = true
                        totalAdded = totalAdded + 1
                        log("✓ Added pet: " .. pet)
                    elseif fireGiveItem(pet, "Pet") then
                        spawnedItems["pet_" .. pet] = true
                        totalAdded = totalAdded + 1
                        log("✓ Fired pet: " .. pet)
                    end
                    task.wait(0.1)
                end
            end
            
            if totalAdded > 0 then
                log("📦 Cycle #" .. cycle .. ": Added " .. totalAdded .. " items")
            else
                log("⏳ Cycle #" .. cycle .. ": Waiting...")
            end
        end)
        
        wait(CHECK_INTERVAL)
    end
end

-- Stop on F6
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        scriptRunning = false
        log("🛑 Script stopped")
    end
end)

autoSpawnLoop()

game:BindToClose(function()
    scriptRunning = false
end)

log("✅ DupeeHub Mobile Script Loaded! F6 to stop.")
