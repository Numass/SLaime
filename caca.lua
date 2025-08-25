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

local AutoTab = Window:AddTab({
    Title = "Auto",
    Icon = "rbxassetid://7733964370"
})

local BlessingTab = Window:AddTab({
    Title = "Blessing",
    Icon = "rbxassetid://7733955511"
})

local BotTab = Window:AddTab({
    Title = "Bot",
    Icon = "rbxassetid://7733964370"
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

-- Button to set RoombaSizeUpgrade to 5000
UsefulTab:AddButton({
    Title = "Max Roomba Size (5000)",
    Description = "Set RoombaSizeUpgrade to 5000",
    Callback = function()
        debugPrint("🚀 Setting RoombaSizeUpgrade to 5000...")
        if setUpgradeValue("RoombaSizeUpgrade", 5000) then
            debugPrint("✅ Successfully set RoombaSizeUpgrade to 5000")
        else
            debugPrint("❌ Failed to set RoombaSizeUpgrade")
        end
    end
})

-- Status display for useful features
local usefulStatusParagraph = UsefulTab:AddParagraph("UsefulStatusParagraph", {
    Title = "Useful Status",
    Content = "Initializing..."
})

-- ========== AUTO TAB ========== --
-- Information Section
AutoTab:AddSection("Information")

AutoTab:AddParagraph("AutoWelcomeParagraph", {
    Title = "Auto Features",
    Content = "Automate various game actions for enhanced gameplay!"
})

AutoTab:AddParagraph("AutoInfo", {
    Title = "How it works",
    Content = "These features automatically trigger game events when certain conditions are met."
})

-- Variables for auto features
local luckyRushEnabled = false
local luckyRushCooldown = nil
local luckyRushRemote = nil

-- Get auto feature references
local function getAutoReferences()
    local success, cooldown, remote = pcall(function()
        local cooldown = player:WaitForChild("plrdata"):WaitForChild("LuckyRushCooldown2")
        local remote = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("LuckyRushActivated")
        return cooldown, remote
    end)
    
    if success then
        return cooldown, remote
    else
        debugPrint("❌ Failed to get auto references:", cooldown)
        return nil, nil
    end
end

-- Initialize auto references
spawn(function()
    luckyRushCooldown, luckyRushRemote = getAutoReferences()
    if luckyRushCooldown and luckyRushRemote then
        debugPrint("✅ Found Lucky Rush references")
    else
        debugPrint("⚠️ Some auto features may not be available")
    end
end)

-- Auto Features Section
AutoTab:AddSection("Lucky Rush Features")

-- Lucky Rush auto toggle
AutoTab:AddToggle("LuckyRushToggle", {
    Title = "Auto Lucky Rush",
    Description = "Automatically activate Lucky Rush when cooldown reaches 0 (with R key simulation)",
    Default = false,
    Callback = function(enabled)
        luckyRushEnabled = enabled
        if enabled then
            debugPrint("🍀 Auto Lucky Rush enabled")
            spawn(function()
                while luckyRushEnabled do
                    if luckyRushCooldown and luckyRushRemote then
                        if luckyRushCooldown.Value == 0 then
                            pcall(function()
                                -- Simulate R key press
                                local VirtualInputManager = game:GetService("VirtualInputManager")
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                                task.wait(0.1) -- Small delay
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                                
                                -- Fire the remote event
                                luckyRushRemote:FireServer()
                                debugPrint("🚀 Lucky Rush activated automatically with R key simulation!")
                            end)
                        end
                    end
                    task.wait(1) -- Check every second
                end
            end)
        else
            debugPrint("❌ Auto Lucky Rush disabled")
        end
    end
})

-- Golden Bob Section
AutoTab:AddSection("Golden Bob")

-- Variables for Golden Bob
local goldenBobEnabled = false
local goldenBobCoroutine = nil

-- Auto Golden Bob toggle
AutoTab:AddToggle("GoldenBobToggle", {
    Title = "Auto Golden Bob",
    Description = "Automatically collect golden bob every minute",
    Default = false,
    Callback = function(enabled)
        goldenBobEnabled = enabled
        if enabled then
            debugPrint("🟡 Auto Golden Bob enabled")
            -- Start the golden bob collection loop
            goldenBobCoroutine = spawn(function()
                while goldenBobEnabled do
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GoldBarCollected"):FireServer()
                        debugPrint("🟡 Golden Bar collected")
                    end)
                    task.wait(60) -- Wait 1 minute
                end
            end)
        else
            debugPrint("❌ Auto Golden Bob disabled")
            goldenBobEnabled = false
            if goldenBobCoroutine then
                goldenBobCoroutine = nil
            end
        end
    end
})

-- Manual Golden Bob button
AutoTab:AddButton({
    Title = "Collect Golden Bob Now",
    Description = "Manually trigger golden bob collection",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GoldBarCollected"):FireServer()
            debugPrint("🟡 Manual Golden Bob collected")
        end)
    end
})

-- Status display for auto features
local autoStatusParagraph = AutoTab:AddParagraph("AutoStatusParagraph", {
    Title = "Auto Status",
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
                
                -- Count unlocked gamepasses
                local gamepassCount = 0
                local unlockedGamepasses = 0
                if playerGamepasses then
                    for _, gamepassName in ipairs(gamepassNames) do
                        local gamepass = playerGamepasses:FindFirstChild(gamepassName)
                        if gamepass and gamepass:IsA("BoolValue") then
                            gamepassCount = gamepassCount + 1
                            if gamepass.Value then
                                unlockedGamepasses = unlockedGamepasses + 1
                            end
                        end
                    end
                end
                
                local status = string.format("Boosts Found: %d\nRoombas: %d/%d unlocked\nGamepasses: %d/%d unlocked\nAuto Boosts: %s\nAuto Unlock: %s", 
                    boostCount, unlockedRoombas, roombaCount, unlockedGamepasses, gamepassCount,
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

-- Update status periodically for auto features
spawn(function()
    while true do
        pcall(function()
            if luckyRushCooldown and autoStatusParagraph then
                local cooldownValue = luckyRushCooldown.Value
                local status = string.format("Lucky Rush Cooldown: %d\nAuto Lucky: %s\nAuto Golden Bob: %s", 
                    cooldownValue, luckyRushEnabled and "ON" or "OFF", goldenBobEnabled and "ON" or "OFF")
                
                pcall(function()
                    autoStatusParagraph:SetContent(status)
                end)
            end
            

        end)
        task.wait(1)
    end
end)

-- ========== BLESSING TAB ========== --
-- Information Section
BlessingTab:AddSection("Information")

BlessingTab:AddParagraph("BlessingWelcomeParagraph", {
    Title = "Blessing System",
    Content = "Automated blessing management with webhook notifications!"
})

BlessingTab:AddParagraph("BlessingInfo", {
    Title = "How it works",
    Content = "This system automatically opens blessing UI, detects rolled cards, picks your preferred blessing, and sends webhook notifications when successful."
})

-- Blessing Variables
local RS = game:GetService("ReplicatedStorage")
local Events = RS:WaitForChild("Events")
local ActivateBlessing = Events:WaitForChild("ActivateBlessing")
local BlessingReturnInfo = Events:WaitForChild("BlessingReturnInfo")
local AddBlessing = Events:WaitForChild("AddBlessing")
local RerollBlessing = Events:FindFirstChild("RerollBlessing")

local BlessingGui = player.PlayerGui:WaitForChild("Blessing")
local ActivateButton = BlessingGui:WaitForChild("BlessingIcon"):WaitForChild("ActivateBlessing")
local BlessingsContainer = BlessingGui:WaitForChild("Blessings")
local BlessingsValue = player:WaitForChild("plrdata"):WaitForChild("Blessings")

-- Blessing Settings
local blessingSettings = {
    enabled = false,
    targetBlessing = "Fortune",
    checkInterval = 0.1,
    receiveTimeout = 0.6,
    webhookEnabled = false,
    webhookUrl = "",
    webhookPingMessage = "",
    rerollEnabled = false,
    rerollDelay = 0.1,
    selectedRerollBlessings = {"GemChance"},
    autoRerollList = {"GemChance", "CorruptedSlimeValue", "GemValue", "SlimeValue", "ExpMultiplier"}
}

-- Blessing State
local blessingState = {
    awaiting = false,
    busy = false,
    lastPickedBlessing = "",
    totalBlessingsUsed = 0,
    successfulPicks = 0,
    lastActivationTime = 0,
    stuckDetectionTimeout = 5,
    crashRecoveryAttempts = 0,
    maxCrashRecoveryAttempts = 3
}

-- Bot Settings
local botSettings = {
    positionLocked = false,
    noclipEnabled = false,
    lockPosition = Vector3.new(0, 0, 0),
    maxDistance = 50,
    teleportFallback = true
}

-- Bot State
local botState = {
    originalPosition = nil,
    noclipConnection = nil,
    positionCheckConnection = nil
}

-- Available blessing types
local blessingTypes = {
    "Fortune", "GemChance", "CorruptedSlimeValue", 
    "GemValue", "SlimeValue", "ExpMultiplier", "ShinyChance", "PlayerSpeed", "BeamPower", "HolyBeam"
}

-- Rerollable blessing types
local rerollableBlessingTypes = {
    "CorruptedSlimeValue", "GemValue", "SlimeValue", 
    "ExpMultiplier"
}

-- Enhanced webhook function with multiple HTTP methods and better error handling
local function sendWebhook(title, description, color, includePing)
    if not blessingSettings.webhookUrl or blessingSettings.webhookUrl == "" then
        debugPrint("⚠️ Please set your Discord webhook URL first!")
        return false
    end
    
    debugPrint("📤 Attempting to send webhook notification...")
    debugPrint("🔗 Webhook URL length:", #blessingSettings.webhookUrl)
    
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 3447003,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    -- Add ping message if specified and this is for target blessing
    if includePing and blessingSettings.webhookPingMessage ~= "" then
        data["content"] = blessingSettings.webhookPingMessage
    end
    
    -- Enhanced JSON encoding for Zenith compatibility
    local function safeJsonEncode(data)
        -- First try HttpService
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONEncode(data)
        end)
        
        if success and result then
            return result
        end
        
        -- Fallback: Manual JSON encoding for webhook data
        debugPrint("⚠️ HttpService JSON encoding failed, using manual encoding")
        
        if type(data) ~= "table" then
            return '{"content":"' .. tostring(data) .. '"}'
        end
        
        -- Handle embeds structure manually
        if data.embeds and #data.embeds > 0 then
            local embed = data.embeds[1]
            local title = tostring(embed.title or "Blessing Notification")
            local description = tostring(embed.description or "Check game for details")
            local color = tonumber(embed.color) or 3447003
            
            -- Escape quotes and newlines
            title = title:gsub('"', '\\"'):gsub('\n', '\\n')
            description = description:gsub('"', '\\"'):gsub('\n', '\\n')
            
            return string.format('{"embeds":[{"title":"%s","description":"%s","color":%d}]}', 
                title, description, color)
        end
        
        return '{"content":"Blessing notification - check game for details"}'
    end
    
    local jsonPayload = safeJsonEncode(data)
    debugPrint("📤 Webhook payload ready, length:", #jsonPayload)
    
    -- Prioritize working methods based on test results (request and http_request work in Zenith)
    local methods = {
        {"request", function() return request end},
        {"http_request", function() return http_request end},
        {"syn.request", function() return syn and syn.request end},
        {"httprequest", function() return httprequest end}
    }
    
    for i, methodInfo in ipairs(methods) do
        local methodName, getMethod = methodInfo[1], methodInfo[2]
        local success, httpFunc = pcall(getMethod)
        
        if success and httpFunc then
            debugPrint("🔄 Attempting webhook via:", methodName)
            
            local requestSuccess, response = pcall(function()
                return httpFunc({
                    Url = blessingSettings.webhookUrl,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = jsonPayload
                })
            end)
            
            if requestSuccess and response then
                -- Check for successful response
                local statusCode = response.StatusCode or response.status_code or 200
                if statusCode >= 200 and statusCode < 300 then
                    debugPrint("✅ Webhook delivered successfully via", methodName)
                    debugPrint("📊 Status:", statusCode)
                    return true
                else
                    debugPrint("⚠️ HTTP error", statusCode, "with", methodName)
                    if response.Body then
                        debugPrint("Response:", tostring(response.Body):sub(1, 100))
                    end
                end
            else
                debugPrint("❌ Request failed with", methodName)
                if response then
                    debugPrint("Error:", tostring(response):sub(1, 100))
                end
            end
        end
    end
    
    debugPrint("❌ All webhook delivery attempts failed")
    debugPrint("🔗 Webhook URL:", blessingSettings.webhookUrl:sub(1, 50) .. "...")
    return false
end

-- Get current blessing count for specific type
local function getCurrentBlessingCount(blessingType)
    local success, count = pcall(function()
        local plrdata = player:FindFirstChild("plrdata")
        if not plrdata then return 0 end
        local blessingData = plrdata:FindFirstChild("BlessingData")
        if not blessingData then return 0 end
        local specificBlessing = blessingData:FindFirstChild(blessingType)
        return specificBlessing and specificBlessing.Value or 0
    end)
    return success and count or 0
end

-- Get blessing script environment for perfect integration
local envPick = nil
do
    local s = BlessingGui:FindFirstChild("BlessingScript")
    if s and typeof(getsenv) == "function" then
        local ok, env = pcall(getsenv, s)
        if ok and type(env) == "table" and type(env.BlessingPicked) == "function" then
            envPick = env.BlessingPicked
        end
    end
end

-- Choose best card from available options
local function chooseCard(cards)
    if type(cards) == "table" and #cards > 0 then
        for _, c in ipairs(cards) do
            if typeof(c) == "Instance" and c:IsDescendantOf(BlessingsContainer) then
                if c.Name == blessingSettings.targetBlessing then
                    return c
                end
            end
        end
        return cards[1] -- fallback to first
    end
    return scanVisibleCards()
end

-- Scan visible cards in UI
local function scanVisibleCards()
    for _, c in ipairs(BlessingsContainer:GetChildren()) do
        if c:IsA("Frame") and c.Visible and c:FindFirstChild("Button") then
            return c
        end
    end
    return nil
end

-- Get total blessing count from player.Blessings
local function getTotalBlessingCount(blessingType)
    local success, count = pcall(function()
        local playerBlessings = player:FindFirstChild("Blessings")
        if not playerBlessings then return 0 end
        local specificBlessing = playerBlessings:FindFirstChild(blessingType)
        return specificBlessing and specificBlessing.Value or 0
    end)
    return success and count or 0
end

-- Scan for visible blessing cards
local function scanVisibleCards()
    if not BlessingGui or not BlessingGui.Visible then return nil end
    
    -- Try to find any visible blessing card in the GUI
    local function findCards(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("GuiObject") then
                -- Check if this looks like a blessing card
                if child.Name:find("Card") or child.Name:find("Blessing") then
                    -- Try to extract blessing info from the card
                    local nameLabel = child:FindFirstChild("Name") or child:FindFirstChildOfClass("TextLabel")
                    if nameLabel and nameLabel.Text and nameLabel.Text ~= "" then
                        -- Create a mock blessing object
                        return {
                            Name = nameLabel.Text,
                            GuiObject = child
                        }
                    end
                end
                -- Recursively search children
                local found = findCards(child)
                if found then return found end
            end
        end
        return nil
    end
    
    return findCards(BlessingGui)
end

-- Crash handler for stuck blessing cards
local function handleStuckCards()
    debugPrint("🚨 [CrashHandler] Detecting stuck cards, attempting recovery...")
    
    -- Reset states
    blessingState.awaiting = false
    blessingState.busy = false
    blessingState.crashRecoveryAttempts = blessingState.crashRecoveryAttempts + 1
    
    -- Try to find and pick any visible card
    local visibleCard = scanVisibleCards()
    if visibleCard then
        debugPrint("🔧 [CrashHandler] Found stuck card:", visibleCard.Name, "- attempting to pick")
        
        -- Force pick the card
        if envPick then
            pcall(envPick, visibleCard)
        else
            pcall(function() AddBlessing:FireServer(visibleCard) end)
        end
        
        blessingState.lastPickedBlessing = visibleCard.Name
        blessingState.successfulPicks = blessingState.successfulPicks + 1
        
        -- Send webhook if it's target blessing
        if blessingSettings.webhookEnabled and visibleCard.Name == blessingSettings.targetBlessing then
            local currentCount = getCurrentBlessingCount(visibleCard.Name)
            local totalCount = getTotalBlessingCount(visibleCard.Name)
            local description = string.format(
                "**Blessing Picked:** %s (Crash Recovery)\n**Current Count:** %d\n**Total Count:** %d\n**Total Blessings Remaining:** %d\n**Session Picks:** %d",
                visibleCard.Name, currentCount, totalCount, BlessingsValue.Value, blessingState.successfulPicks
            )
            sendWebhook("🚨 Target Blessing Acquired (Recovery)!", description, 16776960, true) -- Orange color
        end
        
        task.delay(0.5, function() 
            blessingState.busy = false 
        end)
    else
        debugPrint("❌ [CrashHandler] No visible cards found, forcing UI refresh")
        -- Try to close and reopen blessing UI
        pcall(function()
            if BlessingGui.Visible then
                BlessingGui.Visible = false
                task.wait(0.1)
                BlessingGui.Visible = true
            end
        end)
    end
end

-- Handle blessing card selection
local function handleBlessingPick(cards)
    if not blessingState.awaiting then return end
    blessingState.awaiting = false
    blessingState.crashRecoveryAttempts = 0 -- Reset crash recovery counter on successful pick
    
    if blessingState.busy then return end
    local pick = chooseCard(cards)
    if not pick then
        debugPrint("❌ [AutoBlessing] No pickable card found.")
        handleStuckCards() -- Try crash recovery
        return
    end
    
    blessingState.busy = true
    blessingState.lastPickedBlessing = pick.Name
    blessingState.successfulPicks = blessingState.successfulPicks + 1
    
    debugPrint("✅ [AutoBlessing] Picking card:", pick.Name)
    
    -- Pick the blessing
    if envPick then
        pcall(envPick, pick)
    else
        pcall(function() AddBlessing:FireServer(pick) end)
    end
    
    -- Send webhook notification only for target blessing
    if blessingSettings.webhookEnabled and pick.Name == blessingSettings.targetBlessing then
        local currentCount = getCurrentBlessingCount(pick.Name)
        local totalCount = getTotalBlessingCount(pick.Name)
        local description = string.format(
            "**Blessing Picked:** %s\n**Current Count:** %d\n**Total Count:** %d\n**Total Blessings Remaining:** %d\n**Session Picks:** %d",
            pick.Name, currentCount, totalCount, BlessingsValue.Value, blessingState.successfulPicks
        )
        
        sendWebhook("🎯 Target Blessing Acquired!", description, 65280, true) -- Green color with ping
    end
    
    task.delay(0.25, function() 
        blessingState.busy = false 
    end)
end

-- Reroll specific blessings (matching RerollBless.lua implementation)
local function rerollBlessings()
    if not blessingSettings.rerollEnabled or not RerollBlessing then
        debugPrint("❌ Reroll not enabled or RerollBlessing remote not found")
        return
    end
    
    spawn(function()
        while blessingSettings.rerollEnabled do
            for _, blessing in ipairs(blessingSettings.selectedRerollBlessings) do
                if not blessingSettings.rerollEnabled then break end
                
                pcall(function()
                    RerollBlessing:FireServer(blessing)
                    debugPrint("🔄 Rerolled blessing:", blessing)
                end)
                
                task.wait(blessingSettings.rerollDelay)
            end
        end
    end)
end

-- Main blessing automation loop with crash detection
local function startBlessingAutomation()
    spawn(function()
        while blessingSettings.enabled do
            task.wait(blessingSettings.checkInterval)
            
            -- Check for stuck state
            local currentTime = tick()
            if blessingState.awaiting and (currentTime - blessingState.lastActivationTime) > blessingState.stuckDetectionTimeout then
                if blessingState.crashRecoveryAttempts < blessingState.maxCrashRecoveryAttempts then
                    debugPrint("⚠️ [AutoBlessing] Stuck state detected, attempting crash recovery")
                    handleStuckCards()
                else
                    debugPrint("❌ [AutoBlessing] Max crash recovery attempts reached, resetting state")
                    blessingState.awaiting = false
                    blessingState.busy = false
                    blessingState.crashRecoveryAttempts = 0
                end
            end
            
            if BlessingsValue.Value > 0 and not blessingState.busy and not blessingState.awaiting then
                blessingState.awaiting = true
                blessingState.totalBlessingsUsed = blessingState.totalBlessingsUsed + 1
                blessingState.lastActivationTime = currentTime
                
                -- Try clicking the actual ActivateBlessing button first
                if ActivateButton.Visible and ActivateButton.Active then
                    pcall(function() firesignal(ActivateButton.MouseButton1Click) end)
                else
                    -- Fallback: fire the remote directly if GUI not ready
                    pcall(function() ActivateBlessing:FireServer() end)
                end
                
                debugPrint("🎲 [AutoBlessing] Activated blessing roll")
                
                -- Fallback timeout with crash detection
                task.delay(blessingSettings.receiveTimeout, function()
                    if not blessingState.awaiting then return end
                    debugPrint("⏰ [AutoBlessing] Timeout reached, checking for stuck cards")
                    handleStuckCards()
                end)
            end
        end
    end)
end

-- Event connections
BlessingReturnInfo.OnClientEvent:Connect(handleBlessingPick)

-- Blessing Features Section
BlessingTab:AddSection("Blessing Features")

-- Auto Blessing Toggle
local autoBlessingToggle = BlessingTab:AddToggle("AutoBlessingToggle", {
    Title = "Auto Blessing",
    Description = "Automatically use blessings when available",
    Default = false,
    Callback = function(enabled)
        blessingSettings.enabled = enabled
        if enabled then
            debugPrint("✅ Auto blessing enabled")
            startBlessingAutomation()
        else
            debugPrint("❌ Auto blessing disabled")
        end
    end
})

-- Target Blessing Dropdown
local targetBlessingDropdown = BlessingTab:AddDropdown("TargetBlessingDropdown", {
    Title = "Target Blessing",
    Description = "Preferred blessing to pick",
    Values = blessingTypes,
    Multi = false,
    Default = 1,
    Callback = function(value)
        blessingSettings.targetBlessing = value
        debugPrint("🎯 Target blessing set to:", value)
    end
})

-- Check Interval Slider
local intervalSlider = BlessingTab:AddSlider("IntervalSlider", {
    Title = "Check Interval (seconds)",
    Description = "How often to check for available blessings",
    Default = 0.1,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(value)
        blessingSettings.checkInterval = value
        debugPrint("⏱️ Check interval set to:", value, "seconds")
    end
})

-- Webhook Section
BlessingTab:AddSection("Webhook Settings")

-- Webhook Toggle
local webhookToggle = BlessingTab:AddToggle("WebhookToggle", {
    Title = "Enable Webhooks",
    Description = "Send notifications when blessings are picked",
    Default = false,
    Callback = function(enabled)
        blessingSettings.webhookEnabled = enabled
        debugPrint("📡 Webhooks", enabled and "enabled" or "disabled")
    end
})

-- Webhook URL Input
BlessingTab:AddInput("WebhookUrlInput", {
    Title = "Webhook URL",
    Description = "Discord webhook URL for notifications",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Finished = true,
    Callback = function(value)
        blessingSettings.webhookUrl = value
        debugPrint("📡 Webhook URL updated")
    end
})

-- Webhook Ping Message Input
BlessingTab:AddInput("WebhookPingInput", {
    Title = "Ping Message",
    Description = "Custom ping message when target blessing is acquired",
    Default = "",
    Placeholder = "@everyone Target blessing found!",
    Finished = true,
    Callback = function(value)
        blessingSettings.webhookPingMessage = value
        debugPrint("📡 Webhook ping message updated")
    end
})

-- Test Webhook Button
BlessingTab:AddButton({
    Title = "Test Webhook",
    Description = "Send a test message to verify webhook",
    Callback = function()
        if blessingSettings.webhookUrl ~= "" then
            sendWebhook("🧪 Test Message", "Webhook connection successful!", 65280, false)
            debugPrint("📡 Test webhook sent")
        else
            debugPrint("❌ No webhook URL configured")
        end
    end
})

-- Reroll Section
BlessingTab:AddSection("Reroll Settings")

-- Reroll Blessing Dropdown
local rerollBlessingDropdown = BlessingTab:AddDropdown("RerollBlessingDropdown", {
    Title = "Blessings to Reroll",
    Description = "Select which blessings to continuously reroll",
    Values = rerollableBlessingTypes,
    Multi = true,
    Default = {"CorruptedSlimeValue", "GemValue", "SlimeValue", "ExpMultiplier"},

    Callback = function(value)
        blessingSettings.selectedRerollBlessings = value
        debugPrint("🔄 Reroll blessings set to:", table.concat(value, ", "))
    end
})

-- Auto Reroll Toggle
local rerollToggle = BlessingTab:AddToggle("RerollToggle", {
    Title = "Auto Reroll",
    Description = "Automatically reroll selected blessing",
    Default = false,
    Callback = function(enabled)
        blessingSettings.rerollEnabled = enabled
        if enabled then
            debugPrint("🔄 Auto reroll enabled for:", table.concat(blessingSettings.selectedRerollBlessings, ", "))
            rerollBlessings()
        else
            debugPrint("❌ Auto reroll disabled")
        end
    end
})

-- Reroll Delay Slider
local rerollDelaySlider = BlessingTab:AddSlider("RerollDelaySlider", {
    Title = "Reroll Delay (seconds)",
    Description = "Delay between reroll attempts",
    Default = 0.1,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(value)
        blessingSettings.rerollDelay = value
        debugPrint("🔄 Reroll delay set to:", value, "seconds")
    end
})

-- Manual Actions Section
BlessingTab:AddSection("Manual Actions")

-- Manual Blessing Button
BlessingTab:AddButton({
    Title = "Use Blessing Now",
    Description = "Manually trigger blessing usage",
    Callback = function()
        if BlessingsValue.Value > 0 and not blessingState.busy and not blessingState.awaiting then
            blessingState.awaiting = true
            ActivateBlessing:FireServer()
            debugPrint("🎲 Manual blessing activated")
        else
            debugPrint("❌ Cannot use blessing right now")
        end
    end
})

-- Manual Reroll Button
BlessingTab:AddButton({
    Title = "Reroll Selected Blessing",
    Description = "Manually reroll the selected blessing once",
    Callback = function()
        if RerollBlessing then
            for _, blessing in ipairs(blessingSettings.selectedRerollBlessings) do
                pcall(function()
                    RerollBlessing:FireServer(blessing)
                    debugPrint("🔄 Manual reroll:", blessing)
                end)
                task.wait(0.1)
            end
        else
            debugPrint("❌ RerollBlessing remote not found")
        end
    end
})

-- Status Section
BlessingTab:AddSection("Status")

-- Blessing Status Display
local blessingStatusParagraph = BlessingTab:AddParagraph("BlessingStatusParagraph", {
    Title = "Blessing Status",
    Content = "Initializing..."
})

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

-- Update status periodically for blessings
spawn(function()
    while true do
        pcall(function()
            if blessingStatusParagraph then
                local currentBlessings = BlessingsValue.Value
                local status = string.format(
                    "Available Blessings: %d\nAuto Blessing: %s\nTarget: %s\nLast Picked: %s\nSession Picks: %d\nWebhook: %s\nReroll: %s (%s)\nCrash Recovery: %d/%d attempts",
                    currentBlessings,
                    blessingSettings.enabled and "ON" or "OFF",
                    blessingSettings.targetBlessing,
                    blessingState.lastPickedBlessing ~= "" and blessingState.lastPickedBlessing or "None",
                    blessingState.successfulPicks,
                    blessingSettings.webhookEnabled and "ON" or "OFF",
                    blessingSettings.rerollEnabled and "ON" or "OFF",
                    table.concat(blessingSettings.selectedRerollBlessings, ", "),
                    blessingState.crashRecoveryAttempts,
                    blessingState.maxCrashRecoveryAttempts
                )
                
                pcall(function()
                    blessingStatusParagraph:SetContent(status)
                end)
            end
        end)
        task.wait(2)
    end
end)

-- ========== BOT TAB ========== --
-- Services for Bot functionality
local RunService = game:GetService("RunService")

-- Bot Functions
local function enableNoclip()
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then return end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if botState.noclipConnection then
        botState.noclipConnection:Disconnect()
    end
    
    botState.noclipConnection = RunService.Stepped:Connect(function()
        if botSettings.noclipEnabled and character then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    debugPrint("🚫 Noclip enabled")
end

local function disableNoclip()
    if botState.noclipConnection then
        botState.noclipConnection:Disconnect()
        botState.noclipConnection = nil
    end
    
    if player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    debugPrint("✅ Noclip disabled")
end

local function lockPosition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = player.Character.HumanoidRootPart
    botState.originalPosition = rootPart.Position
    botSettings.lockPosition = rootPart.Position
    
    if botState.positionCheckConnection then
        botState.positionCheckConnection:Disconnect()
    end
    
    botState.positionCheckConnection = RunService.Heartbeat:Connect(function()
        if botSettings.positionLocked and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local currentRootPart = player.Character.HumanoidRootPart
            local distance = (currentRootPart.Position - botSettings.lockPosition).Magnitude
            
            if distance > botSettings.maxDistance and botSettings.teleportFallback then
                debugPrint("📍 Distance exceeded, teleporting back to locked position")
                currentRootPart.CFrame = CFrame.new(botSettings.lockPosition)
            end
        end
    end)
    
    debugPrint("🔒 Position locked at:", botSettings.lockPosition)
end

local function unlockPosition()
    if botState.positionCheckConnection then
        botState.positionCheckConnection:Disconnect()
        botState.positionCheckConnection = nil
    end
    
    debugPrint("🔓 Position unlocked")
end

-- Bot Tab Setup
BotTab:AddSection("Movement Control")

-- Position Lock Toggle
local positionLockToggle = BotTab:AddToggle("PositionLockToggle", {
    Title = "Lock Position",
    Description = "Lock your current position and prevent movement beyond set distance",
    Default = false,
    Callback = function(enabled)
        botSettings.positionLocked = enabled
        if enabled then
            lockPosition()
        else
            unlockPosition()
        end
    end
})

-- Noclip Toggle
local noclipToggle = BotTab:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Description = "Enable noclip to walk through walls and objects",
    Default = false,
    Callback = function(enabled)
        botSettings.noclipEnabled = enabled
        if enabled then
            enableNoclip()
        else
            disableNoclip()
        end
    end
})

-- Teleport Fallback Toggle
local teleportFallbackToggle = BotTab:AddToggle("TeleportFallbackToggle", {
    Title = "Teleport Fallback",
    Description = "Automatically teleport back if you go too far from locked position",
    Default = true,
    Callback = function(enabled)
        botSettings.teleportFallback = enabled
        debugPrint("📍 Teleport fallback:", enabled and "enabled" or "disabled")
    end
})

-- Max Distance Slider
local maxDistanceSlider = BotTab:AddSlider("MaxDistanceSlider", {
    Title = "Max Distance",
    Description = "Maximum distance before teleport fallback triggers",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        botSettings.maxDistance = value
        debugPrint("📏 Max distance set to:", value)
    end
})

BotTab:AddSection("Manual Actions")

-- Manual Teleport to Locked Position
BotTab:AddButton({
    Title = "Teleport to Locked Position",
    Description = "Manually teleport back to your locked position",
    Callback = function()
        if botState.originalPosition and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(botSettings.lockPosition)
            debugPrint("📍 Teleported to locked position")
        else
            debugPrint("❌ No locked position set")
        end
    end
})

-- Reset Position Lock
BotTab:AddButton({
    Title = "Reset Position Lock",
    Description = "Set current position as new locked position",
    Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            botSettings.lockPosition = player.Character.HumanoidRootPart.Position
            botState.originalPosition = botSettings.lockPosition
            debugPrint("🔄 Position lock reset to current location")
        else
            debugPrint("❌ Character not found")
        end
    end
})

BotTab:AddSection("Status")

-- Bot Status Display
local botStatusParagraph = BotTab:AddParagraph("BotStatusParagraph", {
    Title = "Bot Status",
    Content = "Initializing..."
})

-- Update bot status periodically
spawn(function()
    while true do
        pcall(function()
            if botStatusParagraph then
                local status = string.format(
                    "Position Lock: %s\nNoclip: %s\nTeleport Fallback: %s\nMax Distance: %d\nLocked Position: %s",
                    botSettings.positionLocked and "ON" or "OFF",
                    botSettings.noclipEnabled and "ON" or "OFF",
                    botSettings.teleportFallback and "ON" or "OFF",
                    botSettings.maxDistance,
                    botState.originalPosition and string.format("%.1f, %.1f, %.1f", botSettings.lockPosition.X, botSettings.lockPosition.Y, botSettings.lockPosition.Z) or "Not Set"
                )
                
                pcall(function()
                    botStatusParagraph:SetContent(status)
                end)
            end
        end)
        task.wait(2)
    end
end)

debugPrint("✅ Slime Incremental Hub loaded successfully!")
debugPrint("🛡️ Anti-AFK protection is active")
debugPrint("🎯 Blessing system integrated with webhook support")
debugPrint("🤖 Bot movement controls available")
