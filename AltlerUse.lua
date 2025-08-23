-- Auto Amulet Roller for Slime Incremental
-- Created by Numass

getgenv().Debug = true

local function debugPrint(...)
    if getgenv().Debug == true then
        -- Safe printing to avoid table printing issues in Zenith
        local args = {...}
        local safeArgs = {}
        for i, arg in ipairs(args) do
            if type(arg) == "table" then
                safeArgs[i] = "[Table]"
            else
                safeArgs[i] = tostring(arg)
            end
        end
        print("[AMULET DEBUG]", unpack(safeArgs))
    end
end

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Discord Webhook URL (replace with your webhook)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408771835461369898/95NY-91EgV9QuqIbZ5xOlYXvQ6iNu901dZ-zw7wM6ZcIgqkwfk1gZiW3Fychc9ZZ1l15"

-- Auto roller variables
local autoRollEnabled = false
local isRolling = false

-- Configuration for amulet comparison
local amuletConfig = {
    priorityStat = "Slimes", -- Which stat to prioritize (Slimes, Exp, Gems, MoveSpeed, GiantChance, CorruptChance)
    requireSpecialForNew = false, -- Only take new if it has special amulets
    requireBetterStats = true, -- Only take new if stats are actually better
    specialAmulets = {
        "Golden", "Purple", "Black", "Rainbow", "Corrupted", "Giant", 
        "Shiny", "Glitched", "Mythical", "Legendary", "Epic", "Rare"
    }
}

-- Amulet stat names mapping
local statNames = {
    ["Slimes"] = "Slimes Multiplier",
    ["Exp"] = "Experience Multiplier", 
    ["Gems"] = "Gems Multiplier",
    ["MoveSpeed"] = "Move Speed Bonus",
    ["GiantChance"] = "Giant Chance Multiplier",
    ["CorruptChance"] = "Glitch Chance Bonus"
}

-- Function to send Discord webhook
local function sendWebhook(title, description, color)
    if WEBHOOK_URL == "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE" or WEBHOOK_URL == "" then
        debugPrint("⚠️ Please set your Discord webhook URL first!")
        debugPrint("💡 Use: getgenv().AmuletRoller.setWebhook('your_webhook_url')")
        return false
    end
    
    debugPrint("📤 Attempting to send webhook notification...")
    debugPrint("🔗 Webhook URL length:", #WEBHOOK_URL)
    
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 3447003,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    -- Enhanced JSON encoding for Zenith compatibility
     local function safeJsonEncode(data)
         -- First try HttpService
         local success, result = pcall(function()
             return HttpService:JSONEncode(data)
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
             local title = tostring(embed.title or "Amulet Analysis")
             local description = tostring(embed.description or "Check game for details")
             local color = tonumber(embed.color) or 3447003
             
             -- Escape quotes and newlines
             title = title:gsub('"', '\\"'):gsub('\n', '\\n')
             description = description:gsub('"', '\\"'):gsub('\n', '\\n')
             
             return string.format('{"embeds":[{"title":"%s","description":"%s","color":%d}]}', 
                 title, description, color)
         end
         
         return '{"content":"Amulet analysis completed - check game for details"}'
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
                     Url = WEBHOOK_URL,
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
     debugPrint("🔗 Webhook URL:", WEBHOOK_URL:sub(1, 50) .. "...")
     debugPrint("💡 Try: getgenv().ZenithFix.testWebhook('your_url') for diagnostics")
     return false
end

-- Function to set webhook URL
local function setWebhookUrl(url)
    WEBHOOK_URL = url or ""
    debugPrint("🔗 Webhook URL updated")
end

-- Function to test webhook
local function testWebhook()
    debugPrint("🧪 Testing webhook connection...")
    return sendWebhook("🧪 Test Notification", "This is a test message from the Amulet Roller!", 3447003)
end

-- Function to get amulet information from GUI
local function getAmuletInfo(amuletFrame)
    if not amuletFrame or not amuletFrame:FindFirstChild("BoostList") then
        debugPrint("⚠️ Invalid amulet frame or missing BoostList")
        return nil
    end
    
    local success, result = pcall(function()
        local boostList = amuletFrame.BoostList
        local amuletData = {
            name = amuletFrame.Name,
            stats = {},
            isSpecial = false,
            specialType = "None"
        }
        
        -- Check for Special frame (proper special amulet detection)
        local specialFrame = amuletFrame:FindFirstChild("Special")
        if specialFrame then
            amuletData.isSpecial = true
            amuletData.specialType = "Special"
            debugPrint("🌟 Found special amulet:", amuletFrame.Name)
        end
        
        -- Extract stats from each boost element using ContentText
        for statName, displayName in pairs(statNames) do
            local statElement = boostList:FindFirstChild(statName)
            if statElement then
                -- Use ContentText instead of Text (as user specified) with error handling
                local statText = ""
                local success2, textResult = pcall(function()
                    return statElement.ContentText or statElement.Text or ""
                end)
                
                if success2 then
                    statText = textResult
                else
                    debugPrint("⚠️ Failed to get text from", statName, "element:", textResult)
                    statText = "0"
                end
                
                local statValue = statText:match("[%d%.]+")
                
                -- Check for gradient quality indicators with error handling
                local tier = "Common"
                local gradientIcon = ""
                
                -- Check for PurpleGradient (over average)
                local purpleSuccess, purpleGradient = pcall(function()
                    return statElement:FindFirstChild("PurpleGradient")
                end)
                if purpleSuccess and purpleGradient then
                    tier = "Over Average"
                    gradientIcon = "🟣"
                    debugPrint("🟣 Found PurpleGradient on", statName, ":", statText)
                end
                
                -- Check for GoldenGradient (significantly over average)
                local goldenSuccess, goldenGradient = pcall(function()
                    return statElement:FindFirstChild("GoldenGradient")
                end)
                if goldenSuccess and goldenGradient then
                    tier = "Significantly Over Average"
                    gradientIcon = "🟡"
                    debugPrint("🟡 Found GoldenGradient on", statName, ":", statText)
                end
                
                amuletData.stats[statName] = {
                    value = tonumber(statValue) or 0,
                    text = statText,
                    tier = tier,
                    gradientIcon = gradientIcon
                }
            end
        end
        
        return amuletData
    end)
    
    if not success then
        debugPrint("❌ Error in getAmuletInfo:", result)
        -- Return a safe default structure instead of nil
        return {
            name = amuletFrame and amuletFrame.Name or "Unknown",
            stats = {},
            isSpecial = false,
            specialType = "None"
        }
    end
    
    -- Validate the result structure before returning
    if not result or type(result) ~= "table" then
        debugPrint("⚠️ Invalid result structure from getAmuletInfo")
        return {
            name = amuletFrame and amuletFrame.Name or "Unknown",
            stats = {},
            isSpecial = false,
            specialType = "None"
        }
    end
    
    -- Ensure stats table exists
    if not result.stats or type(result.stats) ~= "table" then
        result.stats = {}
    end
    
    return result
end

-- Function to analyze amulets and determine if we should keep old or take new
local function analyzeAmulets()
    local success, result = pcall(function()
        local amuletsGui = playerGui:FindFirstChild("AmuletsGui")
        if not amuletsGui then
            debugPrint("❌ AmuletsGui not found")
            return false
        end
        
        local droppedGui = amuletsGui:FindFirstChild("DroppedAmuletsGui")
        if not droppedGui or not droppedGui.Visible then
            debugPrint("❌ DroppedAmuletsGui not found or not visible")
            return false
        end
        
        local leftAmulets = droppedGui:FindFirstChild("LeftAmulets")
        local rightAmulets = droppedGui:FindFirstChild("RightAmulets")
        
        if not leftAmulets or not rightAmulets then
            debugPrint("❌ Left or Right amulets container not found")
            return false
        end
        
        debugPrint("🔍 Starting amulet analysis...")
        
        -- Get old amulets (left side)
        debugPrint("📦 Analyzing left amulets...")
        local oldAmulets = {}
        local leftSuccess, leftError = pcall(function()
            for _, child in pairs(leftAmulets:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "UIListLayout" then
                    debugPrint("🔍 Processing left amulet:", child.Name)
                    local amuletSuccess, amuletInfo = pcall(getAmuletInfo, child)
                    if amuletSuccess and amuletInfo then
                        table.insert(oldAmulets, amuletInfo)
                        debugPrint("✅ Left amulet processed:", amuletInfo.name)
                    else
                        debugPrint("⚠️ Failed to process left amulet:", child.Name, amuletInfo or "unknown error")
                    end
                end
            end
        end)
        
        if not leftSuccess then
            debugPrint("❌ Error processing left amulets:", leftError)
        end
        debugPrint("📦 Found", #oldAmulets, "left amulets")
        
        -- Get new amulets (right side)
        debugPrint("✨ Analyzing right amulets...")
        local newAmulets = {}
        local rightSuccess, rightError = pcall(function()
            for _, child in pairs(rightAmulets:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "UIListLayout" then
                    debugPrint("🔍 Processing right amulet:", child.Name)
                    local amuletSuccess, amuletInfo = pcall(getAmuletInfo, child)
                    if amuletSuccess and amuletInfo then
                        table.insert(newAmulets, amuletInfo)
                        debugPrint("✅ Right amulet processed:", amuletInfo.name)
                    else
                        debugPrint("⚠️ Failed to process right amulet:", child.Name, amuletInfo or "unknown error")
                    end
                end
            end
        end)
        
        if not rightSuccess then
            debugPrint("❌ Error processing right amulets:", rightError)
        end
        debugPrint("✨ Found", #newAmulets, "right amulets")
    
    -- Perform detailed comparison first
        debugPrint("⚖️ Comparing amulet sets...")
        local comparison = compareAmuletSets(oldAmulets, newAmulets)
        debugPrint("⚖️ Comparison completed:", comparison.recommendation)
    
    -- Create 3 separate embeds as requested by user
    
    -- Embed 1: Left Amulets (Current/Old)
    local leftDescription = "**📦 Current Amulets (LEFT SIDE)**\n\n"
    if #oldAmulets == 0 then
        leftDescription = leftDescription .. "*No current amulets*\n"
    else
        for i, amulet in ipairs(oldAmulets) do
            local specialIcon = amulet.isSpecial and "⭐" or ""
            local specialText = amulet.isSpecial and string.format(" [%s]", amulet.specialType) or ""
            leftDescription = leftDescription .. string.format("**%d. %s%s%s**\n", i, specialIcon, amulet.name, specialText)
            for statName, statData in pairs(amulet.stats) do
                leftDescription = leftDescription .. string.format("  • %s%s %s: %s [%s]\n", 
                    statData.gradientIcon or "", statData.gradientIcon and " " or "",
                    statNames[statName], statData.text, statData.tier)
            end
            leftDescription = leftDescription .. "\n"
        end
    end
    
    -- Embed 2: Right Amulets (New)
    local rightDescription = "**✨ New Rolled Amulets (RIGHT SIDE)**\n\n"
    if #newAmulets == 0 then
        rightDescription = rightDescription .. "*No new amulets rolled*\n"
    else
        for i, amulet in ipairs(newAmulets) do
            local specialIcon = amulet.isSpecial and "⭐" or ""
            local specialText = amulet.isSpecial and string.format(" [%s]", amulet.specialType) or ""
            rightDescription = rightDescription .. string.format("**%d. %s%s%s**\n", i, specialIcon, amulet.name, specialText)
            for statName, statData in pairs(amulet.stats) do
                rightDescription = rightDescription .. string.format("  • %s%s %s: %s [%s]\n", 
                    statData.gradientIcon or "", statData.gradientIcon and " " or "",
                    statNames[statName], statData.text, statData.tier)
            end
            rightDescription = rightDescription .. "\n"
        end
    end
    
    -- Embed 3: Analysis and Decision
    local analysisDescription = "**📊 ANALYSIS & DECISION**\n\n"
    analysisDescription = analysisDescription .. string.format("**Priority Stat (%s):**\n", amuletConfig.priorityStat)
    analysisDescription = analysisDescription .. string.format("• Old: %.2f\n• New: %.2f\n\n", 
        comparison.oldPriorityStat, comparison.newPriorityStat)
    analysisDescription = analysisDescription .. string.format("**Total Score:**\n• Old: %.2f\n• New: %.2f\n\n", 
        comparison.oldTotalScore, comparison.newTotalScore)
    analysisDescription = analysisDescription .. string.format("**Special Amulets:**\n• Old: %d\n• New: %d\n\n", 
        comparison.oldSpecialCount, comparison.newSpecialCount)
    analysisDescription = analysisDescription .. string.format("**🎯 RECOMMENDATION: %s**", comparison.recommendation)
    
    -- Add @everyone ping if we should take new amulets
    if comparison.shouldTakeNew then
        analysisDescription = "@everyone\n\n" .. analysisDescription
    end
    
    -- Send 3 separate webhook messages
        debugPrint("📡 Sending webhook 1/3: Left Amulets...")
        sendWebhook("📦 Left Amulets (Current)", leftDescription, 3447003) -- Blue
        task.wait(0.5) -- Small delay between messages
        debugPrint("📡 Sending webhook 2/3: Right Amulets...")
        sendWebhook("✨ Right Amulets (New)", rightDescription, 15844367) -- Gold
        task.wait(0.5)
        debugPrint("📡 Sending webhook 3/3: Analysis & Decision...")
        local analysisColor = comparison.shouldTakeNew and 65280 or 15158332 -- Green if take new, Red if keep old
        sendWebhook("📊 Analysis & Decision", analysisDescription, analysisColor)
        debugPrint("📡 All webhooks sent successfully")
    
    debugPrint("📊 Found", #oldAmulets, "old amulets and", #newAmulets, "new amulets")
    
        return {
            oldAmulets = oldAmulets,
            newAmulets = newAmulets,
            comparison = comparison,
            shouldTakeNew = comparison.shouldTakeNew
        }
    end)
    
    if not success then
        debugPrint("❌ Error in analyzeAmulets:", result)
        return nil
    end
    
    return result
end

-- Function to compare amulet sets based on configuration
local function compareAmuletSets(oldAmulets, newAmulets)
    local function getAmuletSetScore(amulets)
        local totalScore = 0
        local priorityStatTotal = 0
        local specialCount = 0
        
        -- Add error handling for amulets parameter
        if not amulets or type(amulets) ~= "table" then
            debugPrint("⚠️ Invalid amulets parameter in getAmuletSetScore")
            return 0, 0, 0
        end
        
        for _, amulet in ipairs(amulets) do
            -- Add nil check for amulet
            if not amulet then
                debugPrint("⚠️ Nil amulet found in amulets list")
                goto continue
            end
            
            if amulet.isSpecial then
                specialCount = specialCount + 1
            end
            
            -- Add nil check for amulet.stats
            if not amulet.stats or type(amulet.stats) ~= "table" then
                debugPrint("⚠️ Invalid or missing stats for amulet:", amulet.name or "unknown")
                goto continue
            end
            
            for statName, statData in pairs(amulet.stats) do
                -- Add nil check for statData
                if not statData or type(statData) ~= "table" then
                    debugPrint("⚠️ Invalid statData for stat:", statName)
                    goto continue_stat
                end
                
                local baseScore = statData.value or 0
                
                -- Apply tier multipliers
                if statData.tier == "Legendary" then
                    baseScore = baseScore * 4
                elseif statData.tier == "Epic" then
                    baseScore = baseScore * 3
                elseif statData.tier == "Rare" then
                    baseScore = baseScore * 2
                end
                
                totalScore = totalScore + baseScore
                
                -- Track priority stat separately
                if statName == amuletConfig.priorityStat then
                    priorityStatTotal = priorityStatTotal + baseScore
                end
                
                ::continue_stat::
            end
            
            ::continue::
        end
        
        return totalScore, priorityStatTotal, specialCount
    end
    
    -- Add error handling for score calculation
    local oldTotalScore, oldPriorityStat, oldSpecialCount = 0, 0, 0
    local newTotalScore, newPriorityStat, newSpecialCount = 0, 0, 0
    
    local success1, oldScore1, oldScore2, oldScore3 = pcall(getAmuletSetScore, oldAmulets)
    if success1 then
        oldTotalScore, oldPriorityStat, oldSpecialCount = oldScore1, oldScore2, oldScore3
    else
        debugPrint("❌ Error calculating old amulet scores:", oldScore1)
    end
    
    local success2, newScore1, newScore2, newScore3 = pcall(getAmuletSetScore, newAmulets)
    if success2 then
        newTotalScore, newPriorityStat, newSpecialCount = newScore1, newScore2, newScore3
    else
        debugPrint("❌ Error calculating new amulet scores:", newScore1)
    end
    
    -- Determine if we should take new amulets based on configuration
    local shouldTakeNew = false
    local recommendation = "Keep OLD amulets"
    
    -- Check if new amulets meet requirements
    local hasSpecialRequirement = not amuletConfig.requireSpecialForNew or newSpecialCount > oldSpecialCount
    local hasBetterStats = not amuletConfig.requireBetterStats or newPriorityStat > oldPriorityStat
    
    if hasSpecialRequirement and hasBetterStats then
        shouldTakeNew = true
        recommendation = "Take NEW amulets"
    elseif amuletConfig.requireSpecialForNew and newSpecialCount <= oldSpecialCount then
        recommendation = "Keep OLD (new lacks special amulets)"
    elseif amuletConfig.requireBetterStats and newPriorityStat <= oldPriorityStat then
        recommendation = string.format("Keep OLD (new %s stat not better)", amuletConfig.priorityStat)
    end
    
    return {
        oldTotalScore = oldTotalScore,
        newTotalScore = newTotalScore,
        oldPriorityStat = oldPriorityStat,
        newPriorityStat = newPriorityStat,
        oldSpecialCount = oldSpecialCount,
        newSpecialCount = newSpecialCount,
        shouldTakeNew = shouldTakeNew,
        recommendation = recommendation
    }
end

-- Function to count amulet frames on the right side
local function countRightAmuletFrames()
    local amuletsGui = playerGui:FindFirstChild("AmuletsGui")
    if not amuletsGui then 
        debugPrint("🔍 AmuletsGui not found")
        return 0 
    end
    
    local droppedGui = amuletsGui:FindFirstChild("DroppedAmuletsGui")
    if not droppedGui then 
        debugPrint("🔍 DroppedAmuletsGui not found")
        return 0 
    end
    
    debugPrint("🔍 DroppedAmuletsGui visible:", droppedGui.Visible)
    
    local rightContainer = droppedGui:FindFirstChild("RightAmulets")
    if not rightContainer then 
        debugPrint("🔍 RightAmulets container not found")
        -- Debug: List all children of DroppedAmuletsGui
        debugPrint("🔍 Available children in DroppedAmuletsGui:")
        for _, child in pairs(droppedGui:GetChildren()) do
            debugPrint("  -", child.Name, "(", child.ClassName, ")")
        end
        return 0 
    end
    
    local frameCount = 0
    local totalChildren = 0
    for _, child in pairs(rightContainer:GetChildren()) do
        totalChildren = totalChildren + 1
        debugPrint("🔍 Child:", child.Name, "Type:", child.ClassName, "Visible:", child.Visible)
        if child:IsA("Frame") and child.Visible and child.Name ~= "UIListLayout" then
            frameCount = frameCount + 1
            debugPrint("✅ Counted frame:", child.Name)
        end
    end
    
    debugPrint("🔍 RightAmulets container has", totalChildren, "total children,", frameCount, "visible frames")
    return frameCount
end

-- Function to simulate F key press for rolling with intelligent auto-decision
local function rollAmulet(autoMode)
    if isRolling then
        debugPrint("⚠️ Already rolling, please wait...")
        return
    end
    
    -- Check if player is near the altar
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        debugPrint("❌ Character not found")
        return false
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local altarPosition = Vector3.new(5.953, 25, 193.02) -- Altar position from the script
    local distance = (humanoidRootPart.Position - altarPosition).Magnitude
    
    if distance > 20 then
        debugPrint("⚠️ Too far from altar (distance:", math.floor(distance), ")")
        return false
    end
    
    isRolling = true
    debugPrint("🎲 Rolling amulet with F key spamming...")
    
    -- Spam F key until GUI appears (as user requested)
    local maxSpamTime = 10
    local spamStartTime = tick()
    local guiAppeared = false
    
    while tick() - spamStartTime < maxSpamTime and not guiAppeared do
        -- Spam F key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        task.wait(0.1)
        
        -- Check if GUI appeared
        local amuletsGui = playerGui:FindFirstChild("AmuletsGui")
        if amuletsGui then
            local droppedGui = amuletsGui:FindFirstChild("DroppedAmuletsGui")
            if droppedGui and droppedGui.Visible then
                guiAppeared = true
                debugPrint("✅ Amulet GUI appeared after", math.floor((tick() - spamStartTime) * 10) / 10, "seconds")
                break
            end
        end
    end
    
    if not guiAppeared then
        debugPrint("❌ Failed to trigger amulet roll after F key spamming")
        isRolling = false
        return false
    end
    
    -- Analyze the amulets
    debugPrint("🔍 Starting amulet analysis...")
    local analysis = analyzeAmulets()
    if analysis then
        debugPrint("✅ Amulet analysis completed successfully")
        debugPrint("📊 Recommendation:", analysis.comparison.recommendation)
        
        local rightFrameCount = countRightAmuletFrames()
        
        -- Auto mode decision making
        if autoMode then
            -- Stop conditions: 3-4 frames on right OR better stats
            if rightFrameCount >= 3 or analysis.comparison.shouldTakeNew then
                debugPrint("🛑 STOPPING AUTO ROLL - Good amulets detected!")
                
                -- Send webhook with @everyone ping
                local webhookSuccess = sendWebhook("🚨 AUTO ROLL STOPPED", 
                    string.format("**ATTENTION REQUIRED!** @everyone\n\n" ..
                    "Right Frames: %d\n" ..
                    "Stats Better: %s\n" ..
                    "Recommendation: %s\n\n" ..
                    "Please check your amulets and make a decision!", 
                    rightFrameCount, 
                    tostring(analysis.comparison.shouldTakeNew),
                    analysis.comparison.recommendation), 
                    15158332) -- Red color
                
                if not webhookSuccess then
                    debugPrint("❌ Failed to send Discord notification!")
                end
                
                isRolling = false
                return "STOP" -- Signal to stop auto rolling
            else
                -- Stats are worse, take old and continue
                debugPrint("📉 Stats worse than current, taking old and continuing...")
                chooseAmulets(false) -- Take old amulets
                task.wait(2)
                isRolling = false
                return "CONTINUE" -- Signal to continue rolling
            end
        else
            -- Manual mode - NEVER click NEW button, just ping Discord and continue rolling
            debugPrint("🤔 Manual mode - making decision based on analysis")
            if analysis.comparison.shouldTakeNew then
                debugPrint("🚨 Better amulets detected! Discord pinged - continuing to roll for even better ones...")
                -- Discord ping already sent in analyzeAmulets function
                chooseAmulets(false) -- Take old amulets and continue rolling
                task.wait(2)
            else
                debugPrint("✅ Taking OLD amulets (keeping current)")
                chooseAmulets(false) -- Take old amulets
                task.wait(2)
            end
            isRolling = false
            return "MANUAL_COMPLETE" -- Signal manual roll completion
        end
    else
        debugPrint("❌ Failed to analyze amulets - continuing with fallback behavior")
        -- Fallback: take old amulets to continue rolling
        task.wait(1)
        chooseAmulets(false) -- Take old amulets
        task.wait(2)
    end
    
    isRolling = false
    return true
end

-- Function to check if player has enough resources
local function hasEnoughResources()
    local playerData = player:FindFirstChild("plrdata")
    if not playerData then
        return false
    end
    
    local pValue = playerData:FindFirstChild("P")
    local slimesValue = playerData:FindFirstChild("Slimes")
    
    return pValue and slimesValue and pValue.Value >= 10 and slimesValue.Value >= 1e21
end

-- Function to start intelligent auto rolling
local function startIntelligentAutoRoll()
    if autoRollEnabled then
        debugPrint("⚠️ Auto roller already enabled")
        return
    end
    
    autoRollEnabled = true
    debugPrint("🚀 Intelligent auto amulet roller started")
    debugPrint("🎯 Will automatically reroll bad stats and stop when good amulets are found")
    
    spawn(function()
        local rollCount = 0
        
        while autoRollEnabled do
            if not isRolling then
                -- Check if player has enough resources to roll
                if not hasEnoughResources() then
                    debugPrint("⏳ Waiting for resources...")
                    task.wait(10) -- Wait longer if can't roll
                else
                    rollCount = rollCount + 1
                    debugPrint(string.format("🎲 Auto Roll #%d", rollCount))
                    
                    -- Roll amulet with auto mode enabled
                    local result = rollAmulet(true)
                    
                    if result == "STOP" then
                        debugPrint("🎉 Auto roller stopped - Good amulets found!")
                        autoRollEnabled = false
                        break
                    elseif result == "CONTINUE" then
                        debugPrint("🔄 Continuing to next roll...")
                        task.wait(3) -- Wait before next roll
                    else
                        -- Something went wrong, wait and try again
                        task.wait(5)
                    end
                end
            else
                task.wait(1)
            end
        end
        
        debugPrint(string.format("📊 Auto rolling session completed after %d rolls", rollCount))
    end)
end

-- Function to start basic auto rolling (legacy)
local function startAutoRoll()
    if autoRollEnabled then
        debugPrint("⚠️ Auto roller already enabled")
        return
    end
    
    autoRollEnabled = true
    debugPrint("🚀 Basic auto amulet roller started")
    
    spawn(function()
        while autoRollEnabled do
            if not isRolling then
                -- Check if player has enough resources to roll
                if not hasEnoughResources() then
                    debugPrint("⚠️ Not enough resources to roll (need 10 P and 1e21 Slimes)")
                    task.wait(10) -- Wait longer if can't roll
                else
                    local rollSuccess = rollAmulet(false)
                    if rollSuccess then
                        -- Wait for the choice GUI to disappear (indicating choice was made)
                        local maxChoiceWait = 30
                        local choiceWaitTime = 0
                        
                        while choiceWaitTime < maxChoiceWait do
                            local amuletsGui = playerGui:FindFirstChild("AmuletsGui")
                            if amuletsGui then
                                local droppedGui = amuletsGui:FindFirstChild("DroppedAmuletsGui")
                                if not droppedGui or not droppedGui.Visible then
                                    debugPrint("✅ Choice completed, ready for next roll")
                                    break
                                end
                            end
                            task.wait(1)
                            choiceWaitTime = choiceWaitTime + 1
                        end
                        
                        if choiceWaitTime >= maxChoiceWait then
                            debugPrint("⚠️ Choice timeout, continuing anyway")
                        end
                        
                        task.wait(3) -- Additional wait between rolls
                    else
                        task.wait(5) -- Wait if roll failed
                    end
                end
            else
                task.wait(1)
            end
        end
    end)
end

-- Function to stop auto rolling
local function stopAutoRoll()
    autoRollEnabled = false
    debugPrint("🛑 Auto amulet roller stopped")
end

-- Manual roll function
local function manualRoll()
    debugPrint("🎯 Manual amulet roll triggered")
    local result = rollAmulet(false)
    debugPrint("🎯 Manual roll result:", result)
    return result
end

-- Note: chooseAmulets function is defined earlier in the script with robust implementation

-- Export functions for external use
getgenv().AmuletRoller = {
    startAuto = startAutoRoll,
    startIntelligent = startIntelligentAutoRoll,
    stopAuto = stopAutoRoll,
    manualRoll = manualRoll,
    analyzeAmulets = analyzeAmulets,
    chooseAmulets = chooseAmulets,
    isEnabled = function() return autoRollEnabled end,
    isRolling = function() return isRolling end,
    setWebhook = function(url) WEBHOOK_URL = url end,
    testWebhook = testWebhook,
    hasResources = hasEnoughResources,
    
    -- Configuration functions
    getConfig = function() return amuletConfig end,
    setPriorityStat = function(stat) amuletConfig.priorityStat = stat end,
    setRequireSpecial = function(enabled) amuletConfig.requireSpecialForNew = enabled end,
    setRequireBetterStats = function(enabled) amuletConfig.requireBetterStats = enabled end,
    addSpecialAmulet = function(name) table.insert(amuletConfig.specialAmulets, name) end,
    removeSpecialAmulet = function(name)
        for i, amuletName in ipairs(amuletConfig.specialAmulets) do
            if amuletName == name then
                table.remove(amuletConfig.specialAmulets, i)
                break
            end
        end
    end,
    getSpecialAmulets = function() return amuletConfig.specialAmulets end
}

-- Simple UI Creation Function
local function createSimpleUI()
    -- Check if UI already exists
    if game.CoreGui:FindFirstChild("AmuletRollerUI") then
        game.CoreGui.AmuletRollerUI:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AmuletRollerUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.Size = UDim2.new(0, 300, 0, 440)
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = mainFrame
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 0, 0, 10)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Font = Enum.Font.GothamBold
    title.Text = "🎲 Amulet Roller"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = mainFrame
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 10, 0, 50)
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Status: Ready"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Create buttons function
    local function createButton(name, text, position, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = mainFrame
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.BorderSizePixel = 0
        button.Position = position
        button.Size = UDim2.new(1, -20, 0, 35)
        button.Font = Enum.Font.Gotham
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(callback)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
        
        return button
    end
    
    -- Intelligent Auto Roll Button
    createButton("IntelligentAutoButton", "🧠 Start Intelligent Auto Roll", UDim2.new(0, 10, 0, 80), function()
        statusLabel.Text = "Status: Intelligent Auto Rolling..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        getgenv().AmuletRoller.startIntelligent()
    end)
    
    -- Basic Auto Roll Button
    createButton("BasicAutoButton", "⚙️ Start Basic Auto Roll", UDim2.new(0, 10, 0, 125), function()
        statusLabel.Text = "Status: Basic Auto Rolling..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        getgenv().AmuletRoller.startAuto()
    end)
    
    -- Stop Button
    createButton("StopButton", "🛑 Stop Auto Roll", UDim2.new(0, 10, 0, 170), function()
        statusLabel.Text = "Status: Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        getgenv().AmuletRoller.stopAuto()
    end)
    
    -- Manual Roll Button
    createButton("ManualButton", "🎯 Manual Roll", UDim2.new(0, 10, 0, 215), function()
        statusLabel.Text = "Status: Manual Rolling..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        getgenv().AmuletRoller.manualRoll()
        task.wait(2)
        statusLabel.Text = "Status: Ready"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    -- Webhook Input
    local webhookLabel = Instance.new("TextLabel")
    webhookLabel.Parent = mainFrame
    webhookLabel.BackgroundTransparency = 1
    webhookLabel.Position = UDim2.new(0, 10, 0, 260)
    webhookLabel.Size = UDim2.new(1, -20, 0, 20)
    webhookLabel.Font = Enum.Font.Gotham
    webhookLabel.Text = "Discord Webhook URL:"
    webhookLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    webhookLabel.TextSize = 12
    webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local webhookInput = Instance.new("TextBox")
    webhookInput.Parent = mainFrame
    webhookInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    webhookInput.BorderSizePixel = 0
    webhookInput.Position = UDim2.new(0, 10, 0, 285)
    webhookInput.Size = UDim2.new(1, -20, 0, 30)
    webhookInput.Font = Enum.Font.Gotham
    webhookInput.PlaceholderText = "Paste your Discord webhook URL here..."
    webhookInput.Text = ""
    webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    webhookInput.TextSize = 12
    webhookInput.TextWrapped = true
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 5)
    inputCorner.Parent = webhookInput
    
    -- Set Webhook Button
    createButton("SetWebhookButton", "🔗 Set Webhook", UDim2.new(0, 10, 0, 325), function()
        if webhookInput.Text ~= "" then
            getgenv().AmuletRoller.setWebhook(webhookInput.Text)
            statusLabel.Text = "Status: Webhook Set!"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(2)
            statusLabel.Text = "Status: Ready"
        end
    end)
    
    -- Test Webhook Button
    createButton("TestWebhookButton", "🧪 Test Webhook", UDim2.new(0, 10, 0, 365), function()
        statusLabel.Text = "Status: Testing webhook..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        local success = getgenv().AmuletRoller.testWebhook()
        if success then
            statusLabel.Text = "Status: Webhook test successful!"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            statusLabel.Text = "Status: Webhook test failed!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(3)
        statusLabel.Text = "Status: Ready"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Parent = mainFrame
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    debugPrint("🎨 Simple UI created! Look for the Amulet Roller window.")
end

-- Add UI creation to exports
getgenv().AmuletRoller.createUI = createSimpleUI

debugPrint("✅ Auto Amulet Roller loaded successfully!")
debugPrint("📝 Usage:")
debugPrint("  - getgenv().AmuletRoller.createUI() -- Create simple UI")
debugPrint("  - getgenv().AmuletRoller.startIntelligent() -- Start intelligent auto rolling")
debugPrint("  - getgenv().AmuletRoller.startAuto() -- Start basic auto rolling")
debugPrint("  - getgenv().AmuletRoller.stopAuto() -- Stop auto rolling")
debugPrint("  - getgenv().AmuletRoller.manualRoll() -- Manual roll")
debugPrint("  - getgenv().AmuletRoller.setWebhook('your_webhook_url') -- Set Discord webhook")
debugPrint("  - getgenv().AmuletRoller.testWebhook() -- Test webhook connection")

-- Auto-create UI on load
task.wait(1)
createSimpleUI()

return getgenv().AmuletRoller
