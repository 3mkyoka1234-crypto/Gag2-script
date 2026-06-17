-- Grow a Garden 2 (GAG2) Auto Mail Script for Delta Executor
-- Description: Automatically mails seeds and pets to target account
-- Compatible with: Delta Roblox Executor
-- Credit: DubeHub GAG2 API

local RECIPIENT_USERNAME = "your_username_here" -- Change this to your target username
local CHECK_INTERVAL = 8 -- Check inventory every 8 seconds
local SEND_LIMIT = 25 -- Items to mail per cycle

-- Get required services and game components
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Initialize tracking
local mailedItems = {}
local scriptRunning = true

-- Logger function
local function log(message)
    print("[DubeHub] " .. message)
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

-- Get player inventory data
local function getInventoryData()
    local data = {}
    pcall(function()
        local ok, psc = pcall(function() return require(ReplicatedStorage.ClientModules.PlayerStateClient) end)
        if ok and psc and psc.WaitForLocalReplica then
            local ok2, r = pcall(function() return psc:WaitForLocalReplica(30) end)
            if ok2 and r and r.Data and r.Data.Inventory then
                data = r.Data.Inventory
            end
        end
    end)
    return data
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

-- Extract item names from inventory category
local function getItemsFromCategory(category)
    local items = {}
    local inv = getInventoryData()
    
    if inv and inv[category] then
        for k, v in pairs(inv[category]) do
            local name
            if type(v) == "table" then
                name = v.Name or v.ItemName or v.Type or tostring(k)
            else
                name = tostring(k)
            end
            if name then
                table.insert(items, name)
            end
        end
    end
    
    return items
end

-- Send mail via network
local function sendMailToPlayer(itemName)
    if not Net then return false end
    
    if mailedItems[itemName] then
        return false
    end
    
    local success = false
    pcall(function()
        -- Try different mail APIs
        if fireAction("Mailbox.SendMail", RECIPIENT_USERNAME, itemName) then
            success = true
        elseif fireAction("Mail.Send", RECIPIENT_USERNAME, itemName) then
            success = true
        elseif fireAction("Gifts.SendGift", RECIPIENT_USERNAME, itemName) then
            success = true
        end
    end)
    
    if success then
        mailedItems[itemName] = true
        log("✓ Mailed " .. itemName .. " to " .. RECIPIENT_USERNAME)
    end
    
    return success
end

-- Main auto-mail loop
local function autoMailLoop()
    if not initNetwork() then
        log("❌ Failed to load Network module - script cannot run")
        return
    end
    
    log("🚀 GAG2 Auto-Mail script started!")
    log("📧 Target account: " .. RECIPIENT_USERNAME)
    
    local cycleCount = 0
    
    while scriptRunning do
        pcall(function()
            cycleCount = cycleCount + 1
            local totalMailed = 0
            
            -- Get seeds
            local seeds = getItemsFromCategory("Seeds")
            for _, seed in ipairs(seeds) do
                if totalMailed >= SEND_LIMIT then break end
                if not mailedItems[seed] then
                    if sendMailToPlayer(seed) then
                        totalMailed = totalMailed + 1
                        task.wait(0.3)
                    end
                end
            end
            
            -- Get pets
            local pets = getItemsFromCategory("Pets")
            for _, pet in ipairs(pets) do
                if totalMailed >= SEND_LIMIT then break end
                if not mailedItems[pet] then
                    if sendMailToPlayer(pet) then
                        totalMailed = totalMailed + 1
                        task.wait(0.3)
                    end
                end
            end
            
            if totalMailed > 0 then
                log("📬 Cycle #" .. cycleCount .. ": Mailed " .. totalMailed .. " items")
            else
                log("⏳ Cycle #" .. cycleCount .. ": No items to mail")
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
        log("🛑 Script stopped by user (F6)")
    end
end)

-- Start the auto-mail loop
autoMailLoop()

-- Cleanup on script termination
game:BindToClose(function()
    scriptRunning = false
    log("🛑 Script terminated")
end)

log("✅ Script loaded successfully. Press F6 to stop.")
