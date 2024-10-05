local addonName, AMT = ...
local API = AMT.API

-- Optimization 1: Cache more frequently used functions and values
local CreateFrame = CreateFrame
local CreateAtlasMarkup = CreateAtlasMarkup
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers
local UnitName = UnitName
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local IsInInstance = IsInInstance
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local C_Timer = C_Timer
local wipe = wipe
local tinsert = table.insert
local sort = table.sort
local unpack = unpack
local Round = Round
local math_abs = math.abs

local TEXT_WIDTH = 200
local DEFAULT_POSITION_Y = 400

-- Optimization 2: Use upvalues for frequently accessed AMT properties
local BackgroundClear = AMT.BackgroundClear
local AMT_Font = AMT.AMT_Font
local GroupKeystone_Info = AMT.GroupKeystone_Info
local PrintDebug = AMT.PrintDebug

-- Optimization 3: Preallocate frames
local WorldChange_EventListenerFrame = CreateFrame("Frame")
local PartyKeystone_EventListenerFrame = CreateFrame("Frame")
local GroupKeysFrame = CreateFrame("Button", nil, UIParent)

-- Create a font string to display the message
GroupKeysFrame:SetSize(380, 250)
GroupKeysFrame.tex = GroupKeysFrame:CreateTexture()
GroupKeysFrame.tex:SetAllPoints(GroupKeysFrame)
GroupKeysFrame.tex:SetColorTexture(unpack(AMT.BackgroundClear))
GroupKeysFrame:Hide()

-- Register Frame for clicks to hide the frame if needed
GroupKeysFrame:SetPropagateMouseClicks(true)
GroupKeysFrame:RegisterForClicks("RightButtonUp")
GroupKeysFrame:SetScript("OnClick", function(self, button, down)
	self:Hide()
	AMT:PrintDebug("Hiding GroupKeysFrame")
end)

local Initiated_Text = GroupKeysFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
Initiated_Text:SetPoint("TOP", GroupKeysFrame, "TOP", 0, -10)
Initiated_Text:SetText("Ready Check Initiated")
Initiated_Text:SetFont(AMT.AMT_Font, 36)

--Create the label for Keystone's Dungeon Name Background
local Initiated_Text_Divider = CreateFrame("Frame", "AMT_Initiated_Text_Divider", GroupKeysFrame)
Initiated_Text_Divider:SetPoint("TOP", Initiated_Text, "BOTTOM", 0, 4)
Initiated_Text_Divider:SetSize(420, 19)
Initiated_Text_Divider.tex = Initiated_Text_Divider:CreateTexture(nil, "ARTWORK")
Initiated_Text_Divider.tex:SetAtlas("Adventure-MissionEnd-Line")
Initiated_Text_Divider.tex:SetSize(1, 1)
Initiated_Text_Divider.tex:SetAllPoints(Initiated_Text_Divider)

local PartyKeystones_NameFrame = {}
local PartyKeystones_KeyLevelFrame = {}

local GroupKeystones_Debug = {
	{ playerRoleArt = "GM-icon-role-tank", player = " |c00C69B6DAeonwar|r", level = "32" },
	{ playerRoleArt = "GM-icon-role-healer", player = " |c00F58CBAAeonheals|r", level = "17" },
	{ playerRoleArt = "GM-icon-role-dps", player = " |c0069CCF0Aeonmagus|r", level = "14" },
	{ playerRoleArt = "GM-icon-role-dps", player = " |c00C41F3BAeondeath|r", level = "7" },
	{ playerRoleArt = "GM-icon-role-dps", player = " |c009482C9Aeonlock|r", level = "2" },
}

-- Create the Frames which will store the player name on the left and key level on the right
for i = 1, 5 do
	PartyKeystones_NameFrame[i] = CreateFrame("Frame", nil, GroupKeysFrame)
	PartyKeystones_NameFrame[i]:SetSize(Initiated_Text:GetUnboundedStringWidth() / 6 * 5, 36)
	PartyKeystones_NameFrame[i].tex = PartyKeystones_NameFrame[i]:CreateTexture()
	PartyKeystones_NameFrame[i].tex:SetAllPoints(PartyKeystones_NameFrame[i])
	PartyKeystones_NameFrame[i].tex:SetColorTexture(unpack(AMT.BackgroundClear))
	if i == 1 then
		PartyKeystones_NameFrame[i]:SetPoint("TOPLEFT", GroupKeysFrame, "TOPLEFT", 10, -36 - 20)
	else
		PartyKeystones_NameFrame[i]:SetPoint("TOPLEFT", PartyKeystones_NameFrame[i - 1], "BOTTOMLEFT")
	end

	PartyKeystones_KeyLevelFrame[i] = CreateFrame("Frame", nil, GroupKeysFrame)
	PartyKeystones_KeyLevelFrame[i]:SetSize(Initiated_Text:GetUnboundedStringWidth() / 6, 36)
	PartyKeystones_KeyLevelFrame[i].tex = PartyKeystones_KeyLevelFrame[i]:CreateTexture()
	PartyKeystones_KeyLevelFrame[i].tex:SetAllPoints(PartyKeystones_KeyLevelFrame[i])
	PartyKeystones_KeyLevelFrame[i].tex:SetColorTexture(unpack(AMT.BackgroundClear))
	if i == 1 then
		PartyKeystones_KeyLevelFrame[i]:SetPoint("TOPRIGHT", GroupKeysFrame, "TOPRIGHT", -14, -36 - 20)
	else
		PartyKeystones_KeyLevelFrame[i]:SetPoint("TOPRIGHT", PartyKeystones_KeyLevelFrame[i - 1], "BOTTOMRIGHT")
	end

	local PlayerName = PartyKeystones_NameFrame[i]:CreateFontString(
		"AMT_PartyKeystone_NameText" .. i,
		"ARTWORK",
		"GameFontNormalLarge"
	)
	PlayerName:SetPoint("LEFT", PartyKeystones_NameFrame[i], "LEFT")
	PlayerName:SetText(CreateAtlasMarkup(GroupKeystones_Debug[i].playerRoleArt) .. GroupKeystones_Debug[i].player)
	-- PlayerName:SetText("Temp Name")
	PlayerName:SetFont(AMT.AMT_Font, 28)

	local KeyLevel = PartyKeystones_KeyLevelFrame[i]:CreateFontString(
		"AMT_PartyKeystone_KeyLevelText" .. i,
		"ARTWORK",
		"GameFontNormalLarge"
	)
	KeyLevel:SetPoint("RIGHT", PartyKeystones_KeyLevelFrame[i], "RIGHT")
	KeyLevel:SetText("+" .. GroupKeystones_Debug[i].level)
	KeyLevel:SetFont(AMT.AMT_Font, 28)
end

local PartyKeystones_Text = {}

-- Optimization 4: Use a local table for role art mapping
local roleArtMap = {
	TANK = "GM-icon-role-tank",
	HEALER = "GM-icon-role-healer",
	DAMAGER = "GM-icon-role-dps",
}

-- Optimization 5: Improve ShowRelevantKeysMessage function
local function ShowRelevantKeysMessage()
	wipe(PartyKeystones_Text)
	AMT:AMT_KeystoneRefresh()
	local _, _, _, _, _, _, _, CurrentInstanceID = GetInstanceInfo()
	local RelevantKeystones = {}

	for _, key in ipairs(GroupKeystone_Info) do
		if key.instanceID == CurrentInstanceID then
			tinsert(RelevantKeystones, {
				level = key.level,
				mapID = key.mapID,
				instanceID = key.instanceID,
				name = key.name,
				player = key.player,
				playerName = key.playerName,
				playerClass = key.playerClass,
				playerRole = "",
				playerRoleArt = "",
			})
		end
	end

	if #RelevantKeystones > 1 then
		sort(RelevantKeystones, function(a, b) return a.level > b.level end)
	end

	local GroupSize = GetNumGroupMembers()
	local SelectedPlayer = GroupSize > 0 and {"player"} or {}
	for i = 2, GroupSize do
		tinsert(SelectedPlayer, "party" .. (i - 1))
	end

	for _, player in ipairs(RelevantKeystones) do
		for i = 1, #SelectedPlayer do
			local playerName = UnitName(SelectedPlayer[i])
			if playerName == player.playerName then
				local playerRole = UnitGroupRolesAssigned(SelectedPlayer[i])
				player.playerRole = playerRole
				player.playerRoleArt = roleArtMap[playerRole] or ""
				break
			end
		end
	end

	for i = 1, 5 do
		local PlayerName = _G["AMT_PartyKeystone_NameText" .. i]
		local KeyLevel = _G["AMT_PartyKeystone_KeyLevelText" .. i]
		if RelevantKeystones[i] then
			PlayerName:SetText(CreateAtlasMarkup(RelevantKeystones[i].playerRoleArt) .. RelevantKeystones[i].player)
			KeyLevel:SetText("+" .. RelevantKeystones[i].level)
		else
			PlayerName:SetText("")
			KeyLevel:SetText("")
		end
	end

	if #RelevantKeystones > 0 then
		GroupKeysFrame:LoadPosition()
		GroupKeysFrame:Show()
		C_Timer.After(30, function()
			GroupKeysFrame:Hide()
			PrintDebug("Hiding GroupKeysFrame")
		end)
	end
end

--If Ready Check is detected while in a group and in a dungeon
local function AMT_PartyKeystoneEventHandler(self, event, ...)
	local inInstance, instanceType = IsInInstance()
	if event == "READY_CHECK" and inInstance and IsInGroup() and not IsInRaid() then
		ShowRelevantKeysMessage()
		AMT:PrintDebug("Showing GroupKeysFrame")
	elseif event == "WORLD_STATE_TIMER_START" then
		GroupKeysFrame:Hide()
		AMT:PrintDebug("Hiding GroupKeysFrame")
	end
end

--If loading into new zone
local function AMT_WorldEventHandler(self, event, ...)
	if AMT.DetailsEnabled then
		PartyKeystone_EventListenerFrame:RegisterEvent("READY_CHECK")
		PartyKeystone_EventListenerFrame:RegisterEvent("WORLD_STATE_TIMER_START")
		PartyKeystone_EventListenerFrame:SetScript("OnEvent", AMT_PartyKeystoneEventHandler)
		AMT:PrintDebug("Registering READY_CHECK for KeyEvents")
	else
		WorldChange_EventListenerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		AMT:PrintDebug("Unregistering Events due to Details! being disabled")
	end
end

local ADDON_LOADED = CreateFrame("Frame")
ADDON_LOADED:RegisterEvent("ADDON_LOADED")

ADDON_LOADED:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if name == addonName and AMT.DefaultValues["ShowRelevantKeys"] and AMT.dbLoaded then
		WorldChange_EventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		WorldChange_EventListenerFrame:SetScript("OnEvent", AMT_WorldEventHandler)
		GroupKeysFrame:LoadPosition()
		self:UnregisterEvent(event)
		AMT:PrintDebug("Unregistering " .. event .. " for KeyEvents")
	end
end)

-- Optimization 6: Simplify GroupKeysFrame methods
function GroupKeysFrame:OnDragStart()
	self:SetMovable(true)
	self:SetDontSavePosition(true)
	self:SetClampedToScreen(true)
	self:StartMoving()
end

function GroupKeysFrame:OnDragStop()
	self:StopMovingOrSizing()

	local centerX, centerY = self:GetCenter()
	local uiCenterX, uiCenterY = UIParent:GetCenter()
	local left, top = self:GetLeft(), self:GetTop()

	left, top = Round(left), Round(top)

	self:ClearAllPoints()

	if math_abs(uiCenterX - centerX) <= 48 then
		self:SetPoint("TOP", UIParent, "BOTTOM", 0, top)
		AMT_DB.GroupKeysFrame_PositionX = -1
	else
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		AMT_DB.GroupKeysFrame_PositionX = left
	end
	AMT_DB.GroupKeysFrame_PositionY = top

	if self.OptionFrame then
		local button = self.OptionFrame:FindWidget("ResetButton")
		if button then button:Enable() end
	end
end

function GroupKeysFrame:IsFocused()
	return (self:IsShown() and self:IsMouseOver())
		or (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

function GroupKeysFrame:LoadPosition()
	self:ClearAllPoints()
	local x, y = AMT_DB.GroupKeysFrame_PositionX, AMT_DB.GroupKeysFrame_PositionY
	if x and y then
		if x > 0 then
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		else
			self:SetPoint("TOP", UIParent, "BOTTOM", 0, y)
		end
	else
		self:SetPoint("CENTER", UIParent, "CENTER", 0, DEFAULT_POSITION_Y)
	end
end

local function Options_ResetPosition_ShouldEnable(self)
	if AMT_DB.GroupKeysFrame_PositionX and AMT_DB.GroupKeysFrame_PositionY then
		return true
	else
		return false
	end
end

local function Options_ResetPosition_OnClick(self)
	self:Disable()
	AMT_DB.GroupKeysFrame_PositionX = nil
	AMT_DB.GroupKeysFrame_PositionY = nil
	GroupKeysFrame:LoadPosition()
end

function GroupKeysFrame:ShowExampleText()
	for i = 1, 5 do
		local PlayerName = _G["AMT_PartyKeystone_NameText" .. i]
		PlayerName:SetText(CreateAtlasMarkup(GroupKeystones_Debug[i].playerRoleArt) .. GroupKeystones_Debug[i].player)

		local KeyLevel = _G["AMT_PartyKeystone_KeyLevelText" .. i]
		KeyLevel:SetText("+" .. GroupKeystones_Debug[i].level)
	end
	GroupKeysFrame:LoadPosition()
	GroupKeysFrame:Show()
end

---- Edit Mode
function GroupKeysFrame:EnterEditMode()
	if not self.enabled then
		return
	end

	-- self:Init()
	GroupKeysFrame:LoadPosition()
	GroupKeysFrame:Show()

	if not self.Selection then
		local uiName = "Relevant Mythic+ Keystones"
		local hideLabel = true
		self.Selection = AMT.CreateEditModeSelection(self, uiName, hideLabel)
		print("setting self.selection")
	end

	self.isEditing = true
	self:SetScript("OnUpdate", nil)
	-- FadeFrame(self, 0, 1)
	self.Selection:ShowHighlighted()
	self:ShowExampleText()
end

function GroupKeysFrame:ExitEditMode()
	if self.Selection then
		self.Selection:Hide()
	end
	self:ShowOptions(false)
	self.isEditing = false
	self:CloseImmediately()
	-- GroupKeysFrame:Hide()
end

local OPTIONS_SCHEMATIC = {
	title = "Relevant Mythic+ Keystones",
	widgets = {
		{ type = "Divider" },
		{
			type = "UIPanelButton",
			label = "Reset To Default Position",
			onClickFunc = Options_ResetPosition_OnClick,
			stateCheckFunc = Options_ResetPosition_ShouldEnable,
			widgetKey = "ResetButton",
		},
	},
}

function GroupKeysFrame:CreateOptions()
	self.OptionFrame = AMT.SetupSettingsDialog(self, OPTIONS_SCHEMATIC)
end

function GroupKeysFrame:CloseImmediately()
	if self.voHandle then
		StopSound(self.voHandle)
	end
	-- FadeFrame(self, 0, 0)
	self.lastName = nil
	self:Hide()
end

function GroupKeysFrame:ShowOptions(state)
	if state then
		self:CreateOptions()
		self.OptionFrame:Show()
		if self.OptionFrame.requireResetPosition then
			self.OptionFrame.requireResetPosition = false
			self.OptionFrame:ClearAllPoints()
			self.OptionFrame:SetPoint("LEFT", UIParent, "CENTER", TEXT_WIDTH * 0.5, 0)
		end
	else
		if self.OptionFrame then
			self.OptionFrame:Hide()
		end
		if not API.IsInEditMode() then
			self:CloseImmediately()
		end
	end
end

function GroupKeysFrame:EnableShowKeys()
	if self.enabled then
		return
	end
	WorldChange_EventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	WorldChange_EventListenerFrame:SetScript("OnEvent", AMT_WorldEventHandler)

	self.enabled = true
end

function GroupKeysFrame:DisableShowKeys()
	if self.enabled then
		WorldChange_EventListenerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	self.enabled = false
end

-- Optimization 7: Simplify module registration
do
	local function EnableModule(state)
		if state then
			GroupKeysFrame:EnableShowKeys()
			AMT.DefaultValues["ShowRelevantKeys"] = not AMT.DefaultValues["ShowRelevantKeys"]
		else
			GroupKeysFrame:DisableShowKeys()
		end
		PrintDebug("ShowRelevantKeys = " .. tostring(AMT.db["ShowRelevantKeys"]))
	end

	local function OptionToggle_OnClick(self, button)
		if GroupKeysFrame.OptionFrame and GroupKeysFrame.OptionFrame:IsShown() then
			GroupKeysFrame:ShowOptions(false)
			GroupKeysFrame:ExitEditMode()
		else
			GroupKeysFrame:EnterEditMode()
			GroupKeysFrame:ShowOptions(true)
		end
	end

	AMT.Config:AddModule({
		name = "Show Relevant Mythic+ Keys",
		dbKey = "ShowRelevantKeys",
		description = "When a ready check is initiated while inside of a dungeon, if you or party members have an eligible Mythic+ Keystone the list of these players and key levels will be displayed on screen\nRight click the pop-up to hide it.",
		toggleFunc = EnableModule,
		categoryID = 2,
		uiOrder = 1,
		optionToggleFunc = OptionToggle_OnClick,
	})
end