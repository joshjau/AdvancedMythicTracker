local addonName, AMT = ...
local API = AMT.API

-- Optimization 1: Cache frequently used functions
local CreateFrame, IsInRaid, IsInGroup, InCombatLockdown, ClearRaidMarker = CreateFrame, IsInRaid, IsInGroup, InCombatLockdown, ClearRaidMarker
local tinsert, format, pairs, ipairs = table.insert, string.format, pairs, ipairs

local WorldMarkerCycler = CreateFrame("Frame")
WorldMarkerCycler:RegisterEvent("ADDON_LOADED")

local order = {}

function WorldMarkerCycler:Placer_Init()
	local Placer_Button = _G["WorldMarker_Placer"] or CreateFrame("Button", "WorldMarker_Placer", nil, "SecureActionButtonTemplate")
	
	Placer_Button:SetAttribute("pressAndHoldAction", true)
	Placer_Button:SetAttribute("typerelease", "macro")
	
	Placer_Button:HookScript("PreClick", function(self)
		if not (IsInRaid() or IsInGroup()) then return end
	end)
	
	Placer_Button:HookScript("PostClick", function(self)
		if not (IsInRaid() or IsInGroup()) or not self:GetAttribute("enableMarkers") then
			AMT:PrintDebug("Marker placement disabled or not in group/raid")
			return
		end
		
		local markerIndex = self:GetAttribute("WorldMarker_Previous")
		local markerInfo = AMT.WorldMarkers[markerIndex]
		if markerInfo then
			local markerNum = "GM-raidMarker" .. markerInfo.textAtlas
			AMT:PrintDebug(CreateAtlasMarkup(markerNum) .. " Marker Placed")
		end
	end)
	
	Placer_Button:SetAttribute("WorldMarker_Current", order[1])
	Placer_Button:SetAttribute("WorldMarker_Previous", 0)

	-- Optimization 2: Use string concatenation instead of table creation
	local body = "order = " .. table.concat(order, ",")
	SecureHandlerExecute(Placer_Button, body)

	SecureHandlerWrapScript(
		Placer_Button,
		"PreClick",
		Placer_Button,
		[=[
			if not self:GetAttribute("enableMarkers") then
				self:SetAttribute("macrotext", "")   
				return
			end
			self:SetAttribute("macrotext", "/wm [@cursor]"..self:GetAttribute("WorldMarker_Current"))
			local current = self:GetAttribute("WorldMarker_Current")
			local previous = self:GetAttribute("WorldMarker_Previous")
			local nextIndex = (previous == 0 and current == order[1]) and 2 or (i % #order + 1)
			self:SetAttribute("WorldMarker_Previous", current)
			self:SetAttribute("WorldMarker_Current", order[nextIndex])
		]=]
	)
end

function WorldMarkerCycler:Remover_Init()
	if _G["WorldMarker_Remover"] then return end

	local Remover_Button = CreateFrame("Button", "WorldMarker_Remover", nil, "SecureActionButtonTemplate")
	Remover_Button:SetAttribute("type", "macro")
	Remover_Button:SetScript("PreClick", function(self)
		if not InCombatLockdown() then
			local Placer_Button = _G["WorldMarker_Placer"]
			Placer_Button:SetAttribute("WorldMarker_Current", order[1])
			Placer_Button:SetAttribute("WorldMarker_Previous", 0)
		end
		ClearRaidMarker()
	end)
end

function WorldMarkerCycler:Init()
	self:Placer_Init()
	self:Remover_Init()
end

WorldMarkerCycler:SetScript("OnEvent", function(self, event, loadedAddonName)
	if loadedAddonName == addonName then
		self:UnregisterEvent(event)
		order = AMT_DB.WorldMarkerCycler_Order
		self:Init()
	end
end)

function WorldMarkerCycler:IsFocused()
	return (self:IsShown() and self:IsMouseOver()) or
		   (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

-- Optimization 3: Simplify ShowOptions function
function WorldMarkerCycler:ShowOptions(state)
	if not state then
		if self.OptionFrame then
			self.OptionFrame:Hide()
		end
		return
	end

	self:CreateOptions()
	for i, marker in ipairs(AMT.WorldMarkers) do
		local checkbox = _G["AMT_Cycler_" .. marker.icon .. "_Button"]
		checkbox:SetChecked(AMT_DB["Cycler_" .. marker.icon])
	end
	self.OptionFrame:Show()
	self.OptionFrame.requireResetPosition = false
	self.OptionFrame:ClearAllPoints()
	self.OptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

local function ToggleWorldMarker(self)
	local new_WorldMarkerCycler_Order = {}
	for _, marker in ipairs(AMT.WorldMarkers) do
		if AMT_DB["Cycler_" .. marker.icon] then
			tinsert(new_WorldMarkerCycler_Order, marker.wmID)
		end
	end
	AMT_DB.WorldMarkerCycler_Order = new_WorldMarkerCycler_Order
	order = AMT_DB.WorldMarkerCycler_Order
	WorldMarkerCycler:Init()
end

-- Optimization 4: Cache CreateAtlasMarkup function
local CreateAtlasMarkup = CreateAtlasMarkup

function WorldMarkerCycler:CreateOptions()
	if _G["AMT_Cycler_OptionsPane"] then
		self.OptionFrame = _G["AMT_Cycler_OptionsPane"]
		return
	end

	local f = AMT:CreateOptionsPane("AMT_Cycler_OptionsPane")
	f.Title:SetText("World Marker Cycler Options")

	for i, marker in ipairs(AMT.WorldMarkers) do
		local WM_Frame = CreateFrame("Frame", "WMFrame" .. i, f)
		WM_Frame:SetPoint("LEFT", i == 1 and f or _G["WMFrame" .. (i-1)], i == 1 and "LEFT" or "RIGHT", i == 1 and 28 or 0, i == 1 and -16 or 0)
		WM_Frame:SetSize(48, 100)
		
		local tex = WM_Frame:CreateTexture()
		tex:SetAllPoints(WM_Frame)
		tex:SetColorTexture(unpack(AMT.BackgroundClear))

		local WM_Icon = WM_Frame:CreateFontString("WMIcon_" .. i, "OVERLAY", "GameFontNormalLarge")
		WM_Icon:SetText(CreateAtlasMarkup("GM-raidMarker" .. (#AMT.WorldMarkers + 1 - i), 32, 32))
		WM_Icon:SetPoint("TOP", WM_Frame, "TOP", 0, -8)

		local WM_Button = AMT.CreateCustomCheckbox(WM_Frame, "AMT_Cycler_" .. marker.icon .. "_Button", 28)
		WM_Button:SetPoint("TOP", WM_Icon, "BOTTOM", 0, -8)
		WM_Button.dbKey = "Cycler_" .. marker.icon
		WM_Button.onClickFunc = ToggleWorldMarker
	end

	self.OptionFrame = f
end

function WorldMarkerCycler:CloseImmediately()
	if self.voHandle then
		StopSound(self.voHandle)
	end
	self.lastName = nil
end

function AMT:WorldMarkerCycler_ToggleConfig()
	WorldMarkerCycler:ShowOptions(not (WorldMarkerCycler.OptionFrame and WorldMarkerCycler.OptionFrame:IsShown()))
end

do
	local function EnableModule(state)
		local Placer_Button = _G["WorldMarker_Placer"]
		AMT.DefaultValues["WorldMarkerCycler"] = not AMT.DefaultValues["WorldMarkerCycler"]
		Placer_Button:SetAttribute("enableMarkers", AMT.db["WorldMarkerCycler"])
		AMT:PrintDebug("WorldMarkerCycler = " .. tostring(AMT.db["WorldMarkerCycler"]))
	end

	local function OptionToggle_OnClick()
		WorldMarkerCycler:ShowOptions(not (WorldMarkerCycler.OptionFrame and WorldMarkerCycler.OptionFrame:IsShown()))
	end

	local moduleData = {
		name = "World Marker Cycler",
		dbKey = "WorldMarkerCycler",
		description = "Assign a keybind and cycle through all available world markers with each click. Placing each marker at your mouse location. By default all world markers are enabled, but you can configure which world markers it should cycle through.\n\nAlternatively, type '/amt wm' to access the same menu.",
		toggleFunc = EnableModule,
		categoryID = 1,
		uiOrder = 1,
		optionToggleFunc = OptionToggle_OnClick,
	}

	AMT.Config:AddModule(moduleData)
end