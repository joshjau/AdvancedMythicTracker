local addonName, AMT = ...
local API = AMT.API

-- Add this function at the beginning of the file
local function SafeGetDBValue(key, default)
    if not AMT.db then return default end
    return AMT.db[key] or default
end

-- Optimization 1-4, 6-8, 11-18: Local variables and optimizations
local select, GetTime, C_ChallengeMode, C_Scenario, C_ScenarioInfo, BNSendWhisper, SendChatMessage, UnitInRaid, UnitInParty, IsGuildMember, BNIsSelf, math, CreateFrame, Ambiguate, C_BattleNet, C_FriendList = 
    select, GetTime, C_ChallengeMode, C_Scenario, C_ScenarioInfo, BNSendWhisper, SendChatMessage, UnitInRaid, UnitInParty, IsGuildMember, BNIsSelf, math, CreateFrame, Ambiguate, C_BattleNet, C_FriendList

local AMTPrintDebug, AMTFindDungeon = AMT.PrintDebug, AMT.Find_Dungeon
local stringsub, stringmatch, mathfloor = string.sub, string.match, math.floor

local Mplus_AutoResponse = CreateFrame("Frame")
local MplusAR = Mplus_AutoResponse
local MplusAR_runInfo, MplusAR_responseTarget

local function concat(...)
    local t = {}
    for i = 1, select("#", ...) do
        t[i] = tostring(select(i, ...))
    end
    return table.concat(t)
end

local spamPatterns = {
    "^<M%+ Auto Response>",
    "^<Deadly Boss Mods>",
    "^<DBM>",
    "^%[BigWigs%]",
}

local function IsKeyCompleted()
    return select(3, C_Scenario.GetInfo()) == LE_SCENARIO_TYPE_CHALLENGE_MODE and select(3, C_Scenario.GetStepInfo()) == 0
end

-- Update the cachedAMT_DB metatable
local cachedAMT_DB = setmetatable({}, {
    __index = function(t, k)
        local v = SafeGetDBValue(k)
        t[k] = v
        return v
    end
})

-- Update the UpdateCachedAMT_DB function
local function UpdateCachedAMT_DB()
    if not AMT.db then return end
    for k in pairs(cachedAMT_DB) do
        cachedAMT_DB[k] = AMT.db[k]
    end
end

-- Main Mplus_AutoResponse functions
function Mplus_AutoResponse:Init()
    if self.isLoaded then
        AMT:PrintDebug("Mplus_AutoResponse already initialized")
        return
    end
    
    AMT:PrintDebug("Mplus_AutoResponse initialized")
    self.prefix = "<M+ Auto Response>"
    self.spamBase = spamPatterns
    self.whoToReplyTo = {
        [1] = "Friends Only",
        [2] = "Friends and Guild Mates",
        [3] = "All",
    }
    self.DungeonNameType = {
        [1] = "My Language",
        [2] = "English Full Name",
        [3] = "English Abbreviation",
    }
    self.responseTarget = {
        ["friend"] = 1,
        ["guild"] = 2,
        ["unknown"] = 3,
    }
    self.replyInfoType = {
        [1] = "Time",
        [2] = "Trash",
        [3] = "Boss",
        [4] = "Deaths",
    }
    self.started = false
    self.isActive = false
    self.throttle = {}
    self.throttleBN = {}
    self.toReply = {}
    self.runInfo = {
        challengeMapId = nil,
        keyLevel = nil,
        startTime = nil,
        progressTrash = nil,
        progressEncounter = nil,
        numEncounters = nil,
        deaths = nil,
    }
    self.isLoaded = true
    
    MplusAR_runInfo = self.runInfo
    MplusAR_responseTarget = self.responseTarget
end

-- [Other functions like UpdateProgress, CreateResponse, Start, Complete, Reset, FormatSecond, GetKeystoneName, IsSpam remain the same]

-- Main event handler
local function AMT_AutoResponseEventHandler(self, event, ...)
    MplusAR.isActive = select(2, GetWorldElapsedTime(1)) > 0
    
    if event == "CHALLENGE_MODE_START" then
        AMT:PrintDebug(concat(event, " event triggered"))
        if MplusAR.started then MplusAR.Reset() end
        MplusAR.Start()
    elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
        AMT:PrintDebug(concat(event, " event triggered"))
        MplusAR_runInfo.deaths = C_ChallengeMode.GetDeathCount()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        AMT:PrintDebug(concat(event, " event triggered"))
        MplusAR.UpdateProgress()
        MplusAR.Complete()
        MplusAR.Reset()
    elseif event == "CHALLENGE_MODE_RESET" then
        AMT:PrintDebug(concat(event, " event triggered"))
        MplusAR.Reset()
    elseif event == "CHAT_MSG_WHISPER" and MplusAR.isActive then
        AMT:PrintDebug(concat(event, " event triggered"))
        local _, sender, _, _, _, flag, _, _, _, _, _, guid = ...
        if flag ~= "GM" and flag ~= "DEV" then
            local trimmedPlayer = Ambiguate(sender, "none")
            local currentTime = GetTime()
            if not UnitInParty(trimmedPlayer) and not UnitInRaid(trimmedPlayer) and
               (not MplusAR.throttle[sender] or currentTime - MplusAR.throttle[sender] > (cachedAMT_DB.replyCooldown * 60 + 5)) then
                AMT:PrintDebug("Not throttled")
                if cachedAMT_DB.antiSpam and MplusAR.IsSpam(select(1, ...)) then return false end
                if not MplusAR.UpdateProgress() then
                    AMT:PrintDebug("Returning false because not MplusAR.UpdateProgress()")
                    return false
                end
                MplusAR.throttle[sender] = currentTime
                local msg
                if C_BattleNet.GetGameAccountInfoByGUID(guid) or C_FriendList.IsFriend(guid) then
                    AMT:PrintDebug("Whisperer is a friend")
                    if cachedAMT_DB.replyAfterComplete == 1 then
                        MplusAR.toReply[sender] = MplusAR_responseTarget.friend
                    end
                    msg = MplusAR.CreateResponse(MplusAR_responseTarget.friend, IsKeyCompleted())
                elseif IsGuildMember(guid) then
                    AMT:PrintDebug("Whisperer is a guildie")
                    if cachedAMT_DB.replyAfterComplete == 2 then
                        MplusAR.toReply[sender] = MplusAR_responseTarget.guild
                    end
                    msg = MplusAR.CreateResponse(MplusAR_responseTarget.guild, IsKeyCompleted())
                else
                    AMT:PrintDebug("Whisperer is an unknown")
                    if cachedAMT_DB.replyAfterComplete == 3 then
                        MplusAR.toReply[sender] = MplusAR_responseTarget.unknown
                    end
                    msg = MplusAR.CreateResponse(MplusAR_responseTarget.unknown, IsKeyCompleted())
                end
                if msg then
                    AMT:PrintDebug("Sending message")
                    SendChatMessage(msg, "WHISPER", nil, sender)
                end
            end
        end
    elseif event == "CHAT_MSG_BN_WHISPER" and MplusAR.isActive then
        -- [CHAT_MSG_BN_WHISPER handling remains the same]
    end
end

-- Settings and Options
function Mplus_AutoResponse:EnableShowKeys()
    if self.enabled then return end
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_BN_WHISPER")
    self:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
    AMT:PrintDebug("Mplus_AutoResponse - Registering all events")
    self:Init()
    self.enabled = true
    UpdateCachedAMT_DB()
end

function Mplus_AutoResponse:DisableShowKeys()
    if not self.enabled then return end
    self:UnregisterEvent("CHALLENGE_MODE_START")
    self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
    self:UnregisterEvent("CHAT_MSG_WHISPER")
    self:UnregisterEvent("CHAT_MSG_BN_WHISPER")
    self:UnregisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
    AMT:PrintDebug("Mplus_AutoResponse - Unregistering all events")
    self.enabled = false
end

function Mplus_AutoResponse:CreateOptions()
    if _G["AMT_AutoResponse"] then return end

    local f = AMT:CreateOptionsPane("AMT_AutoResponse")
    f.Title:SetText("M+ Auto Response")
    f:SetHeight(490)

    local Main_Settings = CreateFrame("Frame", "AutoResponse_MainSettings", f)
    Main_Settings:SetSize(f:GetWidth() - 40, 120)
    Main_Settings:SetPoint("TOP", f, "TOP", 0, -40)
    Main_Settings.tex = Main_Settings:CreateTexture()
    Main_Settings.tex:SetAllPoints(Main_Settings)
    Main_Settings.tex:SetColorTexture(unpack(AMT.BackgroundClear))

    -- Create whoToReplyTo Dropdown
    local whoToReplyTo = CreateFrame("DropdownButton", nil, Main_Settings, "WowStyle1DropdownTemplate")
    whoToReplyTo:SetWidth(180)
    whoToReplyTo:SetDefaultText(self.whoToReplyTo[SafeGetDBValue("replyAfterComplete", 1)])
    whoToReplyTo:SetPoint("TOPLEFT", 10, -30)
    whoToReplyTo:SetupMenu(function(dropdown, rootDescription)
        for i = 1, #self.whoToReplyTo do
            rootDescription:CreateButton(self.whoToReplyTo[i], function()
                AMT.db.replyAfterComplete = i
                whoToReplyTo:SetSelectionText(function()
                    return self.whoToReplyTo[SafeGetDBValue("replyAfterComplete", 1)]
                end)
            end)
        end
    end)

    local whoToReplyTo_Title = whoToReplyTo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whoToReplyTo_Title:SetPoint("BOTTOMLEFT", whoToReplyTo, "TOPLEFT", 0, 4)
    whoToReplyTo_Title:SetText("Reply To:")

    -- Create Reply Cooldown Slider
    local slider = CreateFrame("Slider", "ReplyCooldownSlider", Main_Settings, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", whoToReplyTo, "BOTTOMLEFT", 0, -30)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(180, 20)
    slider:SetMinMaxValues(1, 5)
    slider:SetValue(SafeGetDBValue("replyCooldown", 1))
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText("1")
    slider.High:SetText("5")
    slider.Text:SetText("|cffffd100Reply Cooldown: |r" .. slider:GetValue() .. " minute(s)")
    slider.Tooltip = "In minutes"
    slider:SetScript("OnValueChanged", function(self, value)
        AMT.db.replyCooldown = value
        slider.Text:SetText("|cffffd100Reply Cooldown: |r" .. value .. " minute(s)")
    end)

    -- Create Dungeon Name Dropdown
    local DungeonNameType = CreateFrame("DropdownButton", nil, Main_Settings, "WowStyle1DropdownTemplate")
    DungeonNameType:SetWidth(180)
    DungeonNameType:SetDefaultText(self.DungeonNameType[SafeGetDBValue("replyKeystoneNameType", 1)])
    DungeonNameType:SetPoint("TOPRIGHT", -10, -30)
    DungeonNameType:SetupMenu(function(dropdown, rootDescription)
        for i = 1, #self.DungeonNameType do
            rootDescription:CreateButton(self.DungeonNameType[i], function()
                AMT.db.replyKeystoneNameType = i
                DungeonNameType:SetSelectionText(function()
                    return self.DungeonNameType[SafeGetDBValue("replyKeystoneNameType", 1)]
                end)
            end)
        end
    end)

    local DungeonNameType_Title = DungeonNameType:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    DungeonNameType_Title:SetPoint("BOTTOMLEFT", DungeonNameType, "TOPLEFT", 0, 4)
    DungeonNameType_Title:SetText("Dungeon Name Format:")

    -- Create Anti-Spam Toggle
    local SpamToggle = AMT.CreateCustomCheckbox(Main_Settings, "AMT_AutoResponse_AntiSpam", 26)
    SpamToggle:SetPoint("TOPRIGHT", DungeonNameType, "BOTTOMRIGHT", -40, -30)
    SpamToggle.Text = SpamToggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SpamToggle.Text:SetPoint("RIGHT", SpamToggle, "LEFT", -10, 0)
    SpamToggle.Text:SetText("Anti-Spam")
    SpamToggle.dbKey = "antiSpam"
    SpamToggle:SetChecked(SafeGetDBValue("antiSpam", false))
    SpamToggle.Tooltip = "Ignore Messages Generated by DBM or BigWigs"
    SpamToggle:SetScript("OnEnter", function(self)
        GameTooltip:Hide()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.Text:GetText(), 1, 1, 1, true)
        GameTooltip:AddLine(self.Tooltip, 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    SpamToggle:SetScript("OnLeave", GameTooltip_Hide)

    -- Create Reply Info Categories
    local categories = {
        "Friends will receive information on...",
        "Guild Mates will receive information on...",
        "Everyone else will receive information on...",
    }

    for i = 1, 3 do
        local Category_Frame = CreateFrame("Frame", "AutoResponse_Category" .. i .. "Info", f)
        Category_Frame:SetSize(Main_Settings:GetWidth(), 100)
        Category_Frame.Border = CreateFrame("Frame", nil, Category_Frame, "DialogBorderNoCenterTemplate")
        Category_Frame.tex = Category_Frame:CreateTexture()
        Category_Frame.tex:SetAllPoints(Category_Frame)
        Category_Frame.text = Category_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        Category_Frame.text:SetText(categories[i])
        Category_Frame.text:SetPoint("TOPLEFT", 14, -14)

        -- Create checkboxes for each category
        for j = 1, 4 do
            local Info_Frame = CreateFrame("Frame", "Cat_" .. i .. "_Type" .. j, Category_Frame)
            if j == 1 then
                Info_Frame:SetPoint("BOTTOMLEFT", Category_Frame, "BOTTOMLEFT", 0, 0)
            else
                local previousFrame = _G["Cat_" .. i .. "_Type" .. (j - 1)]
                Info_Frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 10, 0)
            end
            Info_Frame:SetSize((Category_Frame:GetWidth() / 4) * 0.9, 76)
            Info_Frame.tex = Info_Frame:CreateTexture()
            Info_Frame.tex:SetAllPoints(Info_Frame)
            Info_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))

            -- Checkbox
            local Info_Checkbox = AMT.CreateCustomCheckbox(Info_Frame, nil, 28)
            Info_Checkbox:SetPoint("CENTER")
            Info_Checkbox.dbKey = "replyInfo" .. ({"Friend", "Guild", "Unknown"})[i] .. "." .. self.replyInfoType[j]
            Info_Checkbox:SetChecked(SafeGetDBValue("replyInfo" .. ({"Friend", "Guild", "Unknown"})[i] .. "." .. self.replyInfoType[j], false))

            -- Label
            Info_Checkbox.Text = Info_Checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            Info_Checkbox.Text:SetPoint("BOTTOM", Info_Checkbox, "TOP", 0, 6)
            Info_Checkbox.Text:SetText(self.replyInfoType[j])
            Info_Checkbox.Text:SetJustifyH("CENTER")
        end
    end
    self.OptionFrame = _G["AMT_AutoResponse"]
end

function Mplus_AutoResponse:ShowOptions(state)
    if state then
        self:CreateOptions()
        self.OptionFrame:Show()
        self.OptionFrame:ClearAllPoints()
        self.OptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        if self.OptionFrame then
            self.OptionFrame:Hide()
        end
    end
end

function AMT:AutoResponse_ToggleConfig()
    if Mplus_AutoResponse.OptionFrame and Mplus_AutoResponse.OptionFrame:IsShown() then
        Mplus_AutoResponse:ShowOptions(false)
    else
        Mplus_AutoResponse:ShowOptions(true)
    end
end

do
    local function EnableModule(state)
        if state then
            Mplus_AutoResponse:EnableShowKeys()
            if AMT.db then
                AMT.db["Mplus_AutoResponse"] = true
            end
            AMT:PrintDebug("Mplus_AutoResponse = " .. tostring(SafeGetDBValue("Mplus_AutoResponse", false)))
        else
            Mplus_AutoResponse:DisableShowKeys()
            if AMT.db then
                AMT.db["Mplus_AutoResponse"] = false
            end
            AMT:PrintDebug("Mplus_AutoResponse = " .. tostring(SafeGetDBValue("Mplus_AutoResponse", false)))
        end
    end

    local function OptionToggle_OnClick(self, button)
        AMT:AutoResponse_ToggleConfig()
    end

    local moduleData = {
        name = "M+ Auto Response",
        dbKey = "Mplus_AutoResponse",
        description = "If a whisper is received while in an M+ dungeon, send an automatic reply.",
        toggleFunc = EnableModule,
        categoryID = 2,
        uiOrder = 2,
        optionToggleFunc = OptionToggle_OnClick,
    }

    AMT.Config:AddModule(moduleData)
end

-- Optimization 10: Use a more efficient method for updating cached values
function Mplus_AutoResponse.UpdateCachedValues()
    if not AMT.db then return end
    for key, value in pairs(AMT.db) do
        if Mplus_AutoResponse["cached" .. key] ~= nil then
            Mplus_AutoResponse["cached" .. key] = value
        end
    end
end