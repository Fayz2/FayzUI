local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local function LoadSkin()
	if not E.private.addOnSkins.Overachiever then return end

	for i = 3, 5 do
		S:HandleTab(_G["AchievementFrameTab" .. i])
	end

	local leftFrame = _G["Overachiever_LeftFrame"]
	for _, childFrame in ipairs({leftFrame:GetChildren()}) do
		for _, component in ipairs({childFrame:GetChildren()}) do
			local objType = component:GetObjectType()
			if objType == "Button" then
				S:HandleButton(component)
			elseif objType == "EditBox" then
				S:HandleEditBox(component)
			elseif objType == "CheckButton" then
				S:HandleCheckBox(component)
			elseif objType == "Frame" and string.find(component:GetName(), "Drop") then
				S:HandleDropDownBox(component)
			end
		end
	end

	local containers = {
		"Overachiever_SearchFrame",
		"Overachiever_SuggestionsFrame",
		"Overachiever_WatchFrame"
	}

	for _, name in ipairs(containers) do
		local container = _G[name]
		local frameBorder, scrollFrame = container:GetChildren()
		local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
		container:StripTextures()
		frameBorder:StripTextures()
		scrollFrame:CreateBackdrop("Default")
		scrollFrame.backdrop:Point("TOPLEFT", 0, 2)
		scrollFrame.backdrop:Point("BOTTOMRIGHT", -3, -3)
		S:HandleScrollBar(scrollBar)
	end
end

S:AddCallbackForAddon("Overachiever_Tabs", "Overachiever", LoadSkin)