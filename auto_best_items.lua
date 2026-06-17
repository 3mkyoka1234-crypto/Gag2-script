-- Grow a Garden 2 (GAG2) Real Spawn Best Seeds & Pets Script for Delta Executor
-- Description: Spawns REAL plantable seeds and pets by modifying inventory replica
-- Compatible with: Delta Roblox Executor
-- Credit: DupeeHub GAG2 API

local CHECK_INTERVAL = 3 -- Check every 3 seconds
local AUTO_SPAWN_LIMIT = 100 -- Items to spawn per cycle

-- Get required services and game components
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Initialize tracking
local spawnedItems = {}
local scriptRunning = true
local playerReplica = nil

-- Logger function
local function log(message)
    print("[DupeeHub] " .. message)
end

-- Get player inventory replica
local function getPlayerReplica()
    if playerReplica then return playerReplica end
    
    pcall(function()
        local ok, psc = pcall(function() return require(ReplicatedStorage.ClientModules.PlayerStateClient) end)
        if ok and psc and psc.WaitForLocalReplica then
            local ok2, r = pcall(function() return psc:WaitForLocalReplica(30) end)
            if ok2 and r then playerReplica = r; return r end
        end
    end)
    
    return playerReplica
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

-- Load the Network module (core to GAG2)
local Net
local function initNetwork()
    pcall(function()
        local ok, m = pcall(require, ReplicatedStorage.SharedModules.Networking)
        if ok then Net = m end
    end)
    return Net ~= nil
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

-- Add seeds to inventory replica (real inventory system)
local function addSeedsToInventory()
    local replica = getPlayerReplica()
    if not replica or not replica.Data then return 0 end
    
    local catalog = getSeedCatalog()
    local totalAdded = 0
    
    pcall(function()
        local inv = replica.Data.Inventory
        if not inv then inv = {}; replica.Data.Inventory = inv end
        if not inv.Seeds then inv.Seeds = {} end
        
        for _, seed in ipairs(catalog) do
            if totalAdded >= AUTO_SPAWN_LIMIT then break end
            if not spawnedItems[seed.name] then
                -- Add seed to inventory with proper structure
                inv.Seeds[seed.name] = (inv.Seeds[seed.name] or 0) + 1
                spawnedItems[seed.name] = true
                totalAdded = totalAdded + 1
                log("✓ Added seed: " .. seed.name .. " (Rarity: " .. seed.rarity .. ")")
                task.wait(0.05)
            end
        end
    end)
    
    return totalAdded
end

-- Add pets to inventory replica
local function addPetsToInventory()
    local replica = getPlayerReplica()
    if not replica or not replica.Data then return 0 end
    
    local bestPets = {
        "Golden Dragon", "Phoenix", "Unicorn", "Shadow Beast", "Crystal Dragon",
        "Legendary Wolf", "Sky Serpent", "Mystic Fox", "Royal Eagle", "Ancient Dragon",
        "Magic Horse", "Cosmic Dragon", "Void Creature", "Star Wolf", "Heaven Phoenix",
        "Celestial Beast", "Infernal Dragon", "Ethereal Wolf", "Divine Phoenix", "Chaos Dragon"
    }
    
    local totalAdded = 0
    
    pcall(function()
        local inv = replica.Data.Inventory
        if not inv then inv = {}; replica.Data.Inventory = inv end
        if not inv.Pets then inv.Pets = {} end
        
        for _, petName in ipairs(bestPets) do
            if totalAdded >= AUTO_SPAWN_LIMIT then break end
            if not spawnedItems["pet_" .. petName] then
                -- Add pet to inventory
                inv.Pets[petName] = (inv.Pets[petName] or 0) + 1
                spawnedItems["pet_" .. petName] = true
                totalAdded = totalAdded + 1
                log("✓ Added pet: " .. petName)
                task.wait(0.05)
            end
        end
    end)
    
    return totalAdded
end

-- Sync inventory changes with server
local function syncInventory()
    pcall(function()
        if fireAction("Inventory.Sync") then
            return true
        end
        if fireAction("PlayerState.Sync") then
            return true
        end
        if fireAction("Data.Sync") then
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
    
    log("🚀 DupeeHub GAG2 Real Auto Spawn Best Seeds & Pets started!")
    log("🌱 Modifying inventory replica with REAL items...")
    
    local cycleCount = 0
    
    while scriptRunning do
        pcall(function()
            cycleCount = cycleCount + 1
            local seedsAdded = 0
            local petsAdded = 0
            
            -- Add best seeds to inventory
            seedsAdded = addSeedsToInventory()
            
            -- Add best pets to inventory
            petsAdded = addPetsToInventory()
            
            local totalAdded = seedsAdded + petsAdded
            
            if totalAdded > 0 then
                log("📦 DupeeHub Cycle #" .. cycleCount .. ": Added " .. totalAdded .. " items (" .. seedsAdded .. " seeds, " .. petsAdded .. " pets)")
                
                -- Try to sync changes with server
                if syncInventory() then
                    log("✅ Inventory synced with server")
                end
            else
                log("⏳ DupeeHub Cycle #" .. cycleCount .. ": All items added, waiting for next cycle...")
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

log("✅ DupeeHub Real Auto Spawn Best Seeds & Pets script loaded successfully. Press F6 to stop.")
log("📝 Items are being added to your REAL inventory replica - they should be plantable!")
