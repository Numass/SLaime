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

local Window = LibraryUI:CreateWindow({
    Title = "Slime Encranmentalle",
    SubTitle = "v1.0 By Numass",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 350),
    Theme = "Tomorrow Night Blue",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({
    Title = "Collector",
    Icon = "rbxassetid://7733960981"
})

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

-- Debug toggle
MainTab:AddToggle("DebugToggle", {
    Title = "Debug Mode",
    Default = false,
    Callback = function(value)
        getgenv().Debug = value
        debugPrint("🐛 Debug mode:", value and "enabled" or "disabled")
    end
})

-- Status display
local statusParagraph = MainTab:AddParagraph("StatusParagraph", {
    Title = "Status",
    Content = "Initializing..."
})

-- Update status periodically
spawn(function()
    while true do
        if collectorUpgrade then
            local currentValue = collectorUpgrade.Value
            local status = string.format("Current Collector Value: %d\nOriginal Value: %d\nModified: %s", 
                currentValue, originalValue, modifiedCollector and "Yes" or "No")
            statusParagraph:SetDesc(status)
        else
            statusParagraph:SetDesc("❌ CollectingRadiusUpgrade not found")
        end
        task.wait(2)
    end
end)

debugPrint("✅ Collector Size Modifier loaded successfully!")
