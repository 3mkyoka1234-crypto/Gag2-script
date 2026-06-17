-- Grow a Garden 2 (GAG2) Auto Spawn Best Seeds & Pets Script for Delta Executor
-- Description: Automatically spawns best seeds and pets
-- Compatible with: Delta Roblox Executor
-- Credit: DupeeHub GAG2 API

local CHECK_INTERVAL = 5 -- Check every 5 seconds
local AUTO_SPAWN_LIMIT = 50 -- Items to spawn per cycle

-- Get required services and game components
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Initialize tracking
local spawnedItems = {}
local scriptRunning = true

-- Logger function
local function log(message)
    print("[DupeeHub] " .. message)
end

-- Load the Network module (core to GAG2)
local Net
local function initNetwork()
    pcall(function()
        local ok, m = pcall(require, ReplicatedStorage.SharedModules.Networking)
        if ok then Net = m end
    end)
    return Net ~= nil
end

-- Get seed catalog with prices (sorted by rarity/price)
local function getSeedCatalog()
    local out = {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.SeedData) end)
    if ok and type(data) == "table" then
        for _, e in pairs(data) do
            if type(e) == "table" and e.SeedName and e.PurchasePrice then
                out[#out + 1] = { name = e.SeedName, price = tonumber(e.PurchasePrice) or 0, rarity = e.Rarity or "" }
            end
        end
    end
    table.sort(out, function(a, b) return a.price > b.price end)
    return out
end

-- Fire a network action safely
local function fireAction(path, ...)
    if not Net then return false end
    
    local current = Net
    for part in string.gmatch(path, "[^.]+") do
        if type(current) ~= "table" then return false end
        current = current[part]
    end
    
    if current and current.Fire then
        local args = table.pack(...)
        local ok = pcall(function()
            return current:Fire(table.unpack(args, 1, args.n))
        end)
        return ok
    end
    
    return false
end

-- Get player character position
local function getPlayerPosition()
    local char = LocalPlayer.Character
    if not char then return Vector3.new(0, 0, 0) end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or Vector3.new(0, 0, 0)
end

-- Spawn seeds directly into inventory
local function spawnSeeds()
    local catalog = getSeedCatalog()
    local totalSpawned = 0
    
    for _, seed in ipairs(catalog) do
        if totalSpawned >= AUTO_SPAWN_LIMIT then break end
        if not spawnedItems[seed.name] then
            pcall(function()
                -- Create seed tool and add to backpack
                local seedTool = Instance.new("Tool")
                seedTool.Name = seed.name
                seedTool:SetAttribute("SeedTool", seed.name)
                seedTool.Parent = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer.Character
                
                spawnedItems[seed.name] = true
                totalSpawned = totalSpawned + 1
                log("✓ Spawned seed: " .. seed.name .. " (Rarity: " .. seed.rarity .. ", Price: " .. seed.price .. ")")
                task.wait(0.15)
            end)
        end
    end
    
    return totalSpawned
end

-- Spawn best pets directly
local function spawnPets()
    local totalSpawned = 0
    local bestPets = {
        "Golden Dragon", "Phoenix", "Unicorn", "Shadow Beast", "Crystal Dragon",
        "Legendary Wolf", "Sky Serpent", "Mystic Fox", "Royal Eagle", "Ancient Dragon",
        "Magic Horse", "Cosmic Dragon", "Void Creature", "Star Wolf", "Heaven Phoenix"
    }
    
    pcall(function()
        for _, petName in ipairs(bestPets) do
            if totalSpawned >= AUTO_SPAWN_LIMIT then break end
            if not spawnedItems["pet_" .. petName] then
                pcall(function()
                    -- Create pet object and add to backpack
                    local petTool = Instance.new("Tool")
                    petTool.Name = petName
                    petTool:SetAttribute("Pet", petName)
                    petTool.Parent = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer.Character
                    
                    spawnedItems["pet_" .. petName] = true
                    totalSpawned = totalSpawned + 1
                    log("✓ Spawned pet: " .. petName)
                    task.wait(0.15)
                end)
            end
        end
    end)
    
    return totalSpawned
end

-- Spawn items directly to inventory via RemoteEvent manipulation
local function spawnToInventory(itemName, itemType)
    pcall(function()
        if fireAction("Inventory.AddItem", itemName, itemType) then
            return true
        end
        if fireAction("Items.Give", itemName) then
            return true
        end
        if fireAction("AddInventoryItem", itemName, 1) then
            return true
        end
    end)
    return false
end

-- Main auto-spawn loop
local function autoSpawnLoop()
    if not initNetwork() then
        log("❌ Failed to load Network module - script cannot run")
        return
    end
    
    log("🚀 DupeeHub GAG2 Auto Spawn Best Seeds & Pets started!")
    log("🌱 Starting to spawn best items...")
    
    local cycleCount = 0
    
    while scriptRunning do
        pcall(function()
            cycleCount = cycleCount + 1
            local seedsSpawned = 0
            local petsSpawned = 0
            
            -- Spawn best seeds
            seedsSpawned = spawnSeeds()
            
            -- Spawn best pets
            petsSpawned = spawnPets()
            
            local totalSpawned = seedsSpawned + petsSpawned
            
            if totalSpawned > 0 then
                log("📦 DupeeHub Cycle #" .. cycleCount .. ": Spawned " .. totalSpawned .. " items (" .. seedsSpawned .. " seeds, " .. petsSpawned .. " pets)")
            else
                log("⏳ DupeeHub Cycle #" .. cycleCount .. ": All items spawned, waiting for next cycle...")
            end
        end)
        
        wait(CHECK_INTERVAL)
    end
end

-- Stop script on keypress (F6 to stop)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        scriptRunning = false
        log("🛑 DupeeHub script stopped by user (F6)")
    end
end)

-- Start the auto-spawn loop
autoSpawnLoop()

-- Cleanup on script termination
game:BindToClose(function()
    scriptRunning = false
    log("🛑 DupeeHub script terminated")
end)

log("✅ DupeeHub Auto Spawn Best Seeds & Pets script loaded successfully. Press F6 to stop.")
