local _, AMT = ...
local API = AMT.API
local IS_TWW = AMT.IsGame_11_0_0

local tremove, pairs, select, sqrt, floor = table.remove, pairs, select, math.sqrt, math.floor
local GetPhysicalScreenSize, GetMouseFoci = GetPhysicalScreenSize, GetMouseFoci

do -- Table
	function API.Mixin(object, ...)
		for i = 1, select("#", ...) do
			for k, v in pairs(select(i, ...)) do
				object[k] = v
			end
		end
		return object
	end

	API.CreateFromMixins = function(...)
		return API.Mixin({}, ...)
	end

	function API.RemoveValueFromList(tbl, v)
		for i = #tbl, 1, -1 do
			if tbl[i] == v then
				return tremove(tbl, i) and true
			end
		end
		return false
	end

	function API.ReverseList(list)
		if not list then return end
		local left, right = 1, #list
		while left < right do
			list[left], list[right] = list[right], list[left]
			left, right = left + 1, right - 1
		end
		return list
	end
end

do --Pixel
	local screenHeight
	local function GetScreenHeight()
		if not screenHeight then
			_, screenHeight = GetPhysicalScreenSize()
		end
		return screenHeight
	end

	local basePixelCache = {}
	function API.GetPixelForScale(scale, pixelSize)
		local basePixel = basePixelCache[scale]
		if not basePixel then
			basePixel = 768 / GetScreenHeight() / scale
			basePixelCache[scale] = basePixel
		end
		return pixelSize and basePixel * pixelSize or basePixel
	end

	function API.GetPixelForWidget(widget, pixelSize)
		return API.GetPixelForScale(widget:GetEffectiveScale(), pixelSize)
	end
end

do --Math
	function API.Clamp(value, min, max)
		return value > max and max or value < min and min or value
	end

	function API.Lerp(startValue, endValue, amount)
		return startValue + (endValue - startValue) * amount
	end

	function API.GetPointsDistance2D(x1, y1, x2, y2)
		local dx, dy = x2 - x1, y2 - y1
		return sqrt(dx * dx + dy * dy)
	end

	API.Round = floor
end

do --Game UI
	local editModeFrame
	function API.IsInEditMode()
		editModeFrame = editModeFrame or _G.EditModeManagerFrame
		return editModeFrame and editModeFrame:IsShown()
	end
end

do --System
	if IS_TWW then
		function API.GetMouseFocus()
			local objects = GetMouseFoci()
			return objects and objects[1]
		end
	else
		API.GetMouseFocus = GetMouseFocus
	end
end

-- [Unmodified System section...]
