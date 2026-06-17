-- Grow a Garden 2 (GAG2) Auto Best Seeds & Pets Script for Delta Executor
-- Description: Automatically gives best seeds and pets
-- Compatible with: Delta Roblox Executor
-- Credit: DupeeHub GAG2 API

local CHECK_INTERVAL = 5 -- Check every 5 seconds
local AUTO_GIVE_LIMIT = 50 -- Items to give per cycle

-- Get required services and game components
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Initialize tracking
local givenItems = {}
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

-- Get seed catalog with prices
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

-- Get gear/pet catalog
local function getGearCatalog()
    local out, seen = {}, {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.GearShopData) end)
    if ok and data and type(data.Data) == "table" then
        for _, e in pairs(data.Data) do
            if type(e) == "table" and e.ItemName and not e.RobuxOnly then
                if not seen[e.ItemName] then seen[e.ItemName] = true; out[#out + 1] = e.ItemName end
            end
        end
    end
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

-- Give seeds to inventory
local function giveSeeds()
    local catalog = getSeedCatalog()
    local totalGiven = 0
    
    for _, seed in ipairs(catalog) do
        if totalGiven >= AUTO_GIVE_LIMIT then break end
        if not givenItems[seed.name] then
            pcall(function()
                -- Try purchasing the seed (which adds to inventory)
                if fireAction("SeedShop.PurchaseSeed", seed.name) then
                    givenItems[seed.name] = true
                    totalGiven = totalGiven + 1
                    log("✓ Gave seed: " .. seed.name .. " (Rarity: " .. seed.rarity .. ")")
                    task.wait(0.2)
                end
            end)
        end
    end
    
    return totalGiven
end

-- Give best pets
local function givePets()
    local totalGiven = 0
    
    pcall(function()
        -- Request pet slot expansion
        if fireAction("Pets.RequestPurchasePetSlot") then
            log("✓ Purchased pet slot")
            task.wait(0.3)
        end
    end)
    
    pcall(function()
        -- Get all wild pets and tame them
        local wildPets = {}
        local map = workspace:FindFirstChild("Map")
        if map then
            local ref = map:FindFirstChild("WildPetRef")
            if ref then
                for _, p in ipairs(ref:GetChildren()) do
                    if p:IsA("BasePart") then
                        table.insert(wildPets, p)
                    end
                end
            end
        end
        
        for _, petPart in ipairs(wildPets) do
            if totalGiven >= AUTO_GIVE_LIMIT then break end
            if fireAction("Pets.WildPetTame", petPart) then
                totalGiven = totalGiven + 1
                log("✓ Tamed pet from: " .. petPart:GetAttribute("PetName"))
                task.wait(0.3)
            end
        end
    end)
    
    return totalGiven
end

-- Main auto-give loop
local function autoGiveLoop()
    if not initNetwork() then
        log("❌ Failed to load Network module - script cannot run")
        return
    end
    
    log("🚀 DupeeHub GAG2 Auto Best Seeds & Pets started!")
    log("🌱 Starting to give best items...")
    
    local cycleCount = 0
    
    while scriptRunning do
        pcall(function()
            cycleCount = cycleCount + 1
            local seedsGiven = 0
            local petsGiven = 0
            
            -- Give best seeds
            seedsGiven = giveSeeds()
            
            -- Give best pets
            petsGiven = givePets()
            
            local totalGiven = seedsGiven + petsGiven
            
            if totalGiven > 0 then
                log("📦 DupeeHub Cycle #" .. cycleCount .. ": Gave " .. totalGiven .. " items (" .. seedsGiven .. " seeds, " .. petsGiven .. " pets)")
            else
                log("⏳ DupeeHub Cycle #" .. cycleCount .. ": Searching for more items...")
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

-- Start the auto-give loop
autoGiveLoop()

-- Cleanup on script termination
game:BindToClose(function()
    scriptRunning = false
    log("🛑 DupeeHub script terminated")
end)

log("✅ DupeeHub Auto Best Seeds & Pets script loaded successfully. Press F6 to stop.")
