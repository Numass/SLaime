getgenv().Debug = true

local Fluent, LibraryUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
end)

if not Fluent then
    warn("Failed to load Fluent UI", LibraryUI)
    return
end

-- Debug system
if not getgenv then
    getfenv().getgenv = function() return _G end
end

if getgenv().Debug == nil then
    getgenv().Debug = false
end

local function debugPrint(...)
    if getgenv().Debug == true then
        print("[DEBUG]", ...)
    end
end

-- Anti-AFK Script (Auto-runs on load)
local function startAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    -- Prevent idle kick
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        debugPrint("🔄 Anti-AFK: Prevented idle kick")
    end)
    
    -- Additional anti-AFK measures
    spawn(function()
        while true do
            task.wait(300) -- Every 5 minutes
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Small movement to prevent AFK
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:Move(Vector3.new(0.1, 0, 0.1))
                    task.wait(0.1)
                    humanoid:Move(Vector3.new(-0.1, 0, -0.1))
                    debugPrint("🔄 Anti-AFK: Performed movement")
                end
            end
        end
    end)
    
    debugPrint("✅ Anti-AFK system activated")
end

-- Start Anti-AFK immediately
startAntiAFK()

local Window = LibraryUI:CreateWindow({
    Title = "Slime Incremental Hub",
    SubTitle = "v1.2 By Numass",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Theme = "Tomorrow Night Blue",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({
    Title = "Collector",
    Icon = "rbxassetid://7733960981"
})

local UpgradeTab = Window:AddTab({
    Title = "Upgrades",
    Icon = "rbxassetid://7733964370"
})

local UsefulTab = Window:AddTab({
    Title = "Useful",
    Icon = "rbxassetid://7733955511"
})

-- ========== COLLECTOR TAB ========== --
-- Information Section
MainTab:AddSection("Information")

MainTab:AddParagraph("WelcomeParagraph", {
    Title = "Welcome",
    Content = "Collector Size Modifier - Increase your collection range!"
})

MainTab:AddParagraph("CollectorInfo", {
    Title = "How it works",
    Content = "This script modifies the CollectingRadiusUpgrade value to increase your collector size. Higher values = larger collection range."
})

-- Collector Features Section
MainTab:AddSection("Collector Features")

-- Variables
local player = game:GetService("Players").LocalPlayer
local collectorUpgrade = nil
local originalValue = 0
local modifiedCollector = false

-- Function to get collector upgrade reference
local function getCollectorUpgrade()
    local success, result = pcall(function()
        return player:WaitForChild("plrupgrades"):WaitForChild("CollectingRadiusUpgrade")
    end)
    
    if success then
        return result
    else
        debugPrint("❌ Failed to find CollectingRadiusUpgrade:", result)
        return nil
    end
end

-- Initialize collector upgrade reference
spawn(function()
    collectorUpgrade = getCollectorUpgrade()
    if collectorUpgrade then
        originalValue = collectorUpgrade.Value
        debugPrint("✅ Found CollectingRadiusUpgrade, original value:", originalValue)
    end
end)

-- Slider for collector size
local collectorSlider = MainTab:AddSlider("CollectorSlider", {
    Title = "Collector Size Multiplier",
    Description = "Adjust the collector radius (1 = normal, higher = bigger)",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        if collectorUpgrade then
            -- Calculate new value based on original + multiplier
            local newValue = originalValue + (value * 10) -- Each point adds 10 to the upgrade
            collectorUpgrade.Value = newValue
            debugPrint("🔧 Set CollectingRadiusUpgrade to:", newValue, "(multiplier:", value, ")")
            modifiedCollector = true
        else
            debugPrint("❌ CollectingRadiusUpgrade not found")
        end
    end
})

-- Toggle for auto-max collector
local autoMaxToggle = MainTab:AddToggle("AutoMaxToggle", {
    Title = "Auto Max Collector",
    Default = false,
    Callback = function(enabled)
        if enabled then
            spawn(function()
                while autoMaxToggle and enabled do
                    if collectorUpgrade then
                        collectorUpgrade.Value = 999999 -- Set to very high value
                        debugPrint("🚀 Auto-maxed collector size")
                    end
                    task.wait(1) -- Check every second
                end
            end)
        else
            debugPrint("❌ Auto Max Collector disabled")
        end
    end
})

-- Button to reset collector size
MainTab:AddButton({
    Title = "Reset Collector Size",
    Description = "Reset collector to original size",
    Callback = function()
        if collectorUpgrade then
            collectorUpgrade.Value = originalValue
            collectorSlider:SetValue(1)
            debugPrint("🔄 Reset collector to original value:", originalValue)
            modifiedCollector = false
        else
            debugPrint("❌ CollectingRadiusUpgrade not found")
        end
    end
})

-- Status display for collector
local collectorStatusParagraph = MainTab:AddParagraph("CollectorStatusParagraph", {
    Title = "Collector Status",
    Content = "Initializing..."
})

-- ========== UPGRADE TAB ========== --
-- Information Section
UpgradeTab:AddSection("Information")

UpgradeTab:AddParagraph("UpgradeWelcomeParagraph", {
    Title = "Upgrade Maxer",
    Content = "Max out all your upgrades instantly!"
})

UpgradeTab:AddParagraph("UpgradeInfo", {
    Title = "How it works",
    Content = "This script directly manipulates upgrade values in your player data. Use with caution!"
})

-- Variables for upgrades
local playerUpgrades = nil
local upgradeRemote = nil
local autoMaxEnabled = false

-- Get upgrade references
local function getUpgradeReferences()
    local success, result = pcall(function()
        local upgrades = player:WaitForChild("plrupgrades")
        local remote = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("Upgrade")
        return upgrades, remote
    end)
    
    if success then
        return result
    else
        debugPrint("❌ Failed to get upgrade references:", result)
        return nil, nil
    end
end

-- Initialize upgrade references
spawn(function()
    playerUpgrades, upgradeRemote = getUpgradeReferences()
    if playerUpgrades and upgradeRemote then
        debugPrint("✅ Found upgrade references")
    end
end)

-- Upgrade names from the decompiled script
local upgradeNames = {
    "LevelMultiplierUpgrade",
    "MaxCapUpgrade",
    "SlimeTierUpgrade",
    "SlimeValueUpgrade",
    "SpawnRateUpgrade",
    "SlimeValueUpgrade2",
    "ShinyChanceUpgrade",
    "CollectingRadiusUpgrade",
    "PlayerMovespeedUpgrade",
    "MoreSlimesUpgrade",
    "GemValueUpgrade",
    "GemSpawnChanceUpgrade",
    "GemTierUpgrade",
    "GemValueUpgrade2",
    "HolyBeamUpgrade",
    "HolyBeamCooldownUpgrade",
    "LongerHolyBeamUpgrade",
    "BeamUpgrade",
    "BeamCooldownUpgrade",
    "BeamSizeUpgrade",
    "ShinyMultiplierUpgrade",
    "MoreSlimesUpgrade2",
    "RoombaUpgrade",
    "RoombaSpeedUpgrade",
    "RoombaSizeUpgrade",
    "AutoHolyBeamUpgrade",
    "ShinyChanceUpgrade2",
    "SlimeTierUpgrade2",
    "GiantSlimeChanceUpgrade",
    "TitanicSlimeChanceUpgrade",
    "LevelMultiplierUpgrade2",
    "CorruptedSlimeValueUpgrade",
    "CorruptedSlimeCooldownUpgrade",
    "CorruptedSlimeMaxCapUpgrade",
    "CorruptChanceUpgrade",
    "CorruptPowerUpgrade",
    "LevelMultiplierUpgrade3",
    "MoreSlimesUpgrade3",
    "VoidUpgrade",
    "VoidCooldownUpgrade",
    "VoidDurationUpgrade",
    "VoidMultiplierUpgrade",
    "LuckyRushUpgrade",
    "LuckyRushPowerUpgrade",
    "LuckyRushCooldownUpgrade",
    "AutoVoidUpgrade",
    "GodlySlimeChanceUpgrade",
    "StardustMultiplierUpgrade",
    "FallingStarsLuckUpgrade",
    "StardustMachineCooldownUpgrade",
    "MoreFallingStarsUpgrade"
}

-- Upgrade Features Section
UpgradeTab:AddSection("Upgrade Features")

-- Function to set upgrade value
local function setUpgradeValue(upgradeName, value)
    if playerUpgrades then
        local upgrade = playerUpgrades:FindFirstChild(upgradeName)
        if upgrade then
            upgrade.Value = value
            debugPrint("🔧 Set", upgradeName, "to:", value)
            return true
        else
            debugPrint("❌ Upgrade not found:", upgradeName)
            return false
        end
    else
        debugPrint("❌ Player upgrades not found")
        return false
    end
end

-- Function to max all upgrades
local function maxAllUpgrades()
    local maxValue = 999999
    local successCount = 0
    
    for _, upgradeName in ipairs(upgradeNames) do
        if setUpgradeValue(upgradeName, maxValue) then
            successCount = successCount + 1
        end
        task.wait(0.01) -- Small delay to prevent lag
    end
    
    debugPrint("✅ Maxed", successCount, "out of", #upgradeNames, "upgrades")
    return successCount
end

-- Button to max all upgrades
UpgradeTab:AddButton({
    Title = "Max All Upgrades",
    Description = "Set all upgrades to maximum value (999999)",
    Callback = function()
        debugPrint("🚀 Maxing all upgrades...")
        local count = maxAllUpgrades()
        debugPrint("🎉 Completed! Maxed", count, "upgrades")
    end
})

-- Slider for custom upgrade value
local customValue = 1000
local valueSlider = UpgradeTab:AddSlider("ValueSlider", {
    Title = "Custom Upgrade Value",
    Description = "Set custom value for all upgrades",
    Default = 1000,
    Min = 1,
    Max = 999999,
    Rounding = 1,
    Callback = function(value)
        customValue = value
        debugPrint("📊 Custom value set to:", value)
    end
})

-- Button to set custom value
UpgradeTab:AddButton({
    Title = "Set Custom Value",
    Description = "Apply custom value to all upgrades",
    Callback = function()
        debugPrint("🔧 Setting all upgrades to:", customValue)
        local successCount = 0
        
        for _, upgradeName in ipairs(upgradeNames) do
            if setUpgradeValue(upgradeName, customValue) then
                successCount = successCount + 1
            end
            task.wait(0.01)
        end
        
        debugPrint("✅ Set", successCount, "upgrades to value:", customValue)
    end
})

-- Auto Max Toggle
local autoMaxUpgradeToggle = UpgradeTab:AddToggle("AutoMaxUpgradeToggle", {
    Title = "Auto Max Upgrades",
    Default = false,
    Callback = function(enabled)
        autoMaxEnabled = enabled
        if enabled then
            debugPrint("🔄 Auto max upgrades enabled")
            spawn(function()
                while autoMaxEnabled do
                    maxAllUpgrades()
                    task.wait(5) -- Check every 5 seconds
                end
            end)
        else
            debugPrint("❌ Auto max upgrades disabled")
        end
    end
})

-- Individual Upgrade Section
UpgradeTab:AddSection("Individual Upgrades")

-- Dropdown for selecting specific upgrade
local selectedUpgrade = upgradeNames[1]
local upgradeDropdown = UpgradeTab:AddDropdown("UpgradeDropdown", {
    Title = "Select Upgrade",
    Values = upgradeNames,
    Multi = false,
    Default = 1,
    Callback = function(value)
        selectedUpgrade = value
        debugPrint("🎯 Selected upgrade:", value)
    end
})

-- Input for specific upgrade value
local specificValue = 100
UpgradeTab:AddInput("SpecificValueInput", {
    Title = "Specific Value",
    Default = "100",
    Placeholder = "Enter value...",
    Numeric = true,
    Finished = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue > 0 then
            specificValue = numValue
            debugPrint("📝 Specific value updated to:", numValue)
        else
            debugPrint("❌ Invalid value entered:", value)
            specificValue = 100 -- fallback to default
        end
    end
})

-- Button to set specific upgrade
UpgradeTab:AddButton({
    Title = "Set Selected Upgrade",
    Description = "Apply specific value to selected upgrade",
    Callback = function()
        debugPrint("🎯 Attempting to set", selectedUpgrade, "to value:", specificValue)
        if setUpgradeValue(selectedUpgrade, specificValue) then
            debugPrint("✅ Successfully set", selectedUpgrade, "to:", specificValue)
        else
            debugPrint("❌ Failed to set", selectedUpgrade)
        end
    end
})

-- Status display for upgrades
local upgradeStatusParagraph = UpgradeTab:AddParagraph("UpgradeStatusParagraph", {
    Title = "Upgrade Status",
    Content = "Initializing..."
})

-- ========== USEFUL TAB ========== --
-- Information Section
UsefulTab:AddSection("Information")

UsefulTab:AddParagraph("UsefulWelcomeParagraph", {
    Title = "Useful Features",
    Content = "Boost your gameplay with these helpful tools!"
})

UsefulTab:AddParagraph("UsefulInfo", {
    Title = "How it works",
    Content = "These features manipulate PlayerBoosts and RoombasUnlocked to enhance your game experience."
})

-- Variables for useful features
local playerBoosts = nil
local roombasUnlocked = nil
local allBoostsEnabled = false
local roombasUnlockedEnabled = false

-- Get useful references
local function getUsefulReferences()
    local success, boosts, roombas = pcall(function()
        local boosts = player:WaitForChild("PlayerBoosts")
        local roombas = player:WaitForChild("RoombasUnlocked")
        return boosts, roombas
    end)
    
    if success then
        return boosts, roombas
    else
        debugPrint("❌ Failed to get useful references:", boosts)
        return nil, nil
    end
end

-- Initialize useful references
spawn(function()
    playerBoosts, roombasUnlocked = getUsefulReferences()
    if playerBoosts and roombasUnlocked then
        debugPrint("✅ Found PlayerBoosts and RoombasUnlocked")
    else
        debugPrint("⚠️ Some useful features may not be available")
    end
end)

-- Useful Features Section
UsefulTab:AddSection("Boost Features")

-- Function to set all boosts
local function setAllBoosts(value)
    if not playerBoosts then
        debugPrint("❌ PlayerBoosts not found")
        return 0
    end
    
    local successCount = 0
    for _, child in pairs(playerBoosts:GetChildren()) do
        if child:IsA("IntValue") then
            child.Value = value
            successCount = successCount + 1
            debugPrint("🔧 Set boost", child.Name, "to:", value)
        end
    end
    
    debugPrint("✅ Set", successCount, "boosts to:", value)
    return successCount
end

-- Toggle for auto boosts
UsefulTab:AddToggle("AutoBoostsToggle", {
    Title = "Auto Max Boosts (1000)",
    Default = false,
    Callback = function(enabled)
        allBoostsEnabled = enabled
        if enabled then
            debugPrint("🔄 Auto max boosts enabled")
            spawn(function()
                while allBoostsEnabled do
                    setAllBoosts(1000)
                    task.wait(5) -- Check every 5 seconds
                end
            end)
        else
            debugPrint("❌ Auto max boosts disabled")
        end
    end
})

-- Button to manually set boosts
UsefulTab:AddButton({
    Title = "Set All Boosts to 1000",
    Description = "Manually set all PlayerBoosts to 1000",
    Callback = function()
        debugPrint("🚀 Setting all boosts to 1000...")
        local count = setAllBoosts(1000)
        debugPrint("🎉 Set", count, "boosts to 1000")
    end
})

-- Roomba Features Section
UsefulTab:AddSection("Roomba Features")

-- Function to unlock all roombas
local function unlockAllRoombas()
    if not roombasUnlocked then
        debugPrint("❌ RoombasUnlocked not found")
        return 0
    end
    
    local successCount = 0
    for _, child in pairs(roombasUnlocked:GetChildren()) do
        if child:IsA("BoolValue") then
            child.Value = true
            successCount = successCount + 1
            debugPrint("🔧 Unlocked roomba:", child.Name)
        elseif child:IsA("IntValue") then
            child.Value = 1
            successCount = successCount + 1
            debugPrint("🔧 Set roomba", child.Name, "to: 1")
        end
    end
    
    debugPrint("✅ Unlocked", successCount, "roombas")
    return successCount
end

-- Toggle for auto unlock roombas
UsefulTab:AddToggle("AutoUnlockRoombasToggle", {
    Title = "Auto Unlock All Roombas",
    Default = false,
    Callback = function(enabled)
        roombasUnlockedEnabled = enabled
        if enabled then
            debugPrint("🔄 Auto unlock roombas enabled")
            spawn(function()
                while roombasUnlockedEnabled do
                    unlockAllRoombas()
                    task.wait(5) -- Check every 5 seconds
                end
            end)
        else
            debugPrint("❌ Auto unlock roombas disabled")
        end
    end
})

-- Button to manually unlock roombas
UsefulTab:AddButton({
    Title = "Unlock All Roombas",
    Description = "Manually unlock all roombas",
    Callback = function()
        debugPrint("🚀 Unlocking all roombas...")
        local count = unlockAllRoombas()
        debugPrint("🎉 Unlocked", count, "roombas")
    end
})

-- Status display for useful features
local usefulStatusParagraph = UsefulTab:AddParagraph("UsefulStatusParagraph", {
    Title = "Useful Status",
    Content = "Initializing..."
})

-- ========== SHARED FEATURES ========== --
-- Debug toggle (shared between tabs)
MainTab:AddToggle("DebugToggle", {
    Title = "Debug Mode",
    Default = true,
    Callback = function(value)
        getgenv().Debug = value
        debugPrint("🐛 Debug mode:", value and "enabled" or "disabled")
    end
})

-- Update status periodically for useful features
spawn(function()
    while true do
        pcall(function()
            if playerBoosts and roombasUnlocked and usefulStatusParagraph then
                local boostCount = 0
                local roombaCount = 0
                local unlockedRoombas = 0
                
                -- Count boosts
                for _, child in pairs(playerBoosts:GetChildren()) do
                    if child:IsA("IntValue") then
                        boostCount = boostCount + 1
                    end
                end
                
                -- Count roombas
                for _, child in pairs(roombasUnlocked:GetChildren()) do
                    if child:IsA("BoolValue") or child:IsA("IntValue") then
                        roombaCount = roombaCount + 1
                        if (child:IsA("BoolValue") and child.Value) or (child:IsA("IntValue") and child.Value > 0) then
                            unlockedRoombas = unlockedRoombas + 1
                        end
                    end
                end
                
                local status = string.format("Boosts Found: %d\nRoombas: %d/%d unlocked\nAuto Boosts: %s\nAuto Unlock: %s", 
                    boostCount, unlockedRoombas, roombaCount, 
                    allBoostsEnabled and "ON" or "OFF",
                    roombasUnlockedEnabled and "ON" or "OFF")
                
                pcall(function()
                    usefulStatusParagraph:SetContent(status)
                end)
            end
        end)
        task.wait(3)
    end
end)

-- Update status periodically for collector
spawn(function()
    while true do
        pcall(function()
            if collectorUpgrade and collectorStatusParagraph then
                local currentValue = collectorUpgrade.Value
                local status = string.format("Current Collector Value: %d\nOriginal Value: %d\nModified: %s", 
                    currentValue, originalValue, modifiedCollector and "Yes" or "No")
                
                pcall(function()
                    collectorStatusParagraph:SetContent(status)
                end)
            end
        end)
        task.wait(2)
    end
end)

-- Update status periodically for upgrades
spawn(function()
    while true do
        pcall(function()
            if playerUpgrades and upgradeStatusParagraph then
                local upgradeCount = 0
                local totalValue = 0
                
                for _, upgradeName in ipairs(upgradeNames) do
                    local upgrade = playerUpgrades:FindFirstChild(upgradeName)
                    if upgrade then
                        upgradeCount = upgradeCount + 1
                        totalValue = totalValue + upgrade.Value
                    end
                end
                
                local avgValue = upgradeCount > 0 and math.floor(totalValue / upgradeCount) or 0
                local status = string.format("Found: %d/%d upgrades\nAverage Value: %d\nAuto Max: %s", 
                    upgradeCount, #upgradeNames, avgValue, autoMaxEnabled and "ON" or "OFF")
                
                pcall(function()
                    upgradeStatusParagraph:SetContent(status)
                end)
            end
        end)
        task.wait(3)
    end
end)

debugPrint("✅ Slime Incremental Hub loaded successfully!")
debugPrint("🛡️ Anti-AFK protection is active")
