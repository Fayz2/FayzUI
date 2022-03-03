local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

-- Altoholic 3.3.002b
-- https://www.curseforge.com/wow/addons/altoholic/files/437603

local function LoadSkin()
	if not E.private.addOnSkins.Altoholic then return end

	local function AltoItem(item)
		local name = item:GetName()
		item:SetTemplate()
		item:StyleButton()

		item:SetNormalTexture("")
		_G[name.."IconTexture"]:SetInside()
		_G[name.."IconTexture"]:SetTexCoord(unpack(E.TexCoords))

		local cooldown = _G[name.."Cooldown"]
		if cooldown then
			E:RegisterCooldown(cooldown)
		end
	end

	local function SkinCollapse(button)
		button:SetNormalTexture(E.Media.Textures.Minus)
		button:SetPushedTexture(nil)
		button:SetHighlightTexture(nil)

		hooksecurefunc(button, "SetNormalTexture", function(_, tex)
			if tex == "Interface\\Buttons\\UI-MinusButton-Up" then
				button:GetNormalTexture():SetTexture(E.Media.Textures.Minus)
			else
				button:GetNormalTexture():SetTexture(E.Media.Textures.Plus)
			end
		end)
	end

	AltoTooltip:HookScript("OnShow", function(self)
		self:SetTemplate("Transparent", nil, true) --ignore updates

		local r, g, b = self:GetBackdropColor()
		self:SetBackdropColor(r, g, b, E.db.tooltip.colorAlpha)
	end)

	AltoholicFrame:StripTextures()
	AltoholicFramePortrait:Kill()
	AltoholicFrame:CreateBackdrop("Transparent")
	AltoholicFrame.backdrop:Point("TOPLEFT", 11, -11)
	AltoholicFrame.backdrop:Point("BOTTOMRIGHT", 0, 9)

	for i = 1, 5 do
		S:HandleTab(_G["AltoholicFrameTab"..i])
	end

	S:HandleEditBox(AltoholicFrame_SearchEditBox)
	S:HandleButton(AltoholicFrame_ResetButton)
	AltoholicFrame_ResetButton:Point("TOPLEFT", "$parent_SearchEditBox", "BOTTOMLEFT", -40, -3)
	S:HandleButton(AltoholicFrame_SearchButton)
	S:HandleCloseButton(AltoholicFrameCloseButton)

	local function ClassesItemItemTexure_SetTexCoord(self, left, right, top, bottom)
		if self.customTexCoord then return end
		self.customTexCoord = true
		self:SetTexCoord(left + 0.02, right - 0.02, top + 0.02, bottom - 0.02)
		self.customTexCoord = nil
	end

	local function ClassesItem_OnShow(self)
		if self.border:IsShown() then
			self:SetBackdropBorderColor(self.border:GetVertexColor())
		else
			self:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end

		local name = self:GetName()
		local icon = _G[self:GetName().."IconTexture"]
		icon:SetInside()

		self.border:SetTexture("")
	end

	for i = 1, 10 do
		local item = _G["AltoholicFrameClassesItem"..i]
		AltoItem(item)

		hooksecurefunc(_G[item:GetName().."IconTexture"], "SetTexCoord", ClassesItemItemTexure_SetTexCoord)

		item:HookScript("OnShow", ClassesItem_OnShow)
	end

	AltoMsgBox:SetTemplate("Transparent")
	S:HandleButton(AltoMsgBoxYesButton)
	S:HandleButton(AltoMsgBoxNoButton)

	AltoAccountSharing:SetTemplate("Transparent")

	S:HandleEditBox(AltoAccountSharing_AccNameEditBox)
	S:HandleButton(AltoAccountSharing_InfoButton)
	S:HandleEditBox(AltoAccountSharing_AccTargetEditBox)
	S:HandleButton(AltoAccountSharing_SendButton)
	S:HandleButton(AltoAccountSharing_CancelButton)

	SkinCollapse(AltoAccountSharing_ToggleAll)

	S:HandleCheckBox(AltoAccountSharing_CheckAll)

	-- AccountSummary
	AltoholicFrameSummaryScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameSummaryScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameSummaryEntry"..i.."Collapse"])
	end

	-- Activity
	AltoholicFrameActivityScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameActivityScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameActivityEntry"..i.."Collapse"])
	end

	-- AuctionHouse
	AltoholicFrameAuctionsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameAuctionsScrollFrameScrollBar)

	for i = 1, 7 do
		AltoItem(_G["AltoholicFrameAuctionsEntry"..i.."Item"])
	end

	-- BagUsage
	AltoholicFrameBagUsageScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameBagUsageScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameBagUsageEntry"..i.."Collapse"])
	end

	-- Calendar
	S:HandleNextPrevButton(AltoholicFrameCalendar_PrevMonth)
	S:HandleNextPrevButton(AltoholicFrameCalendar_NextMonth)

	AltoholicFrameCalendarScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameCalendarScrollFrameScrollBar)

	-- Containers
	S:HandleDropDownBox(AltoholicFrameContainers_SelectContainerView)
	S:HandleDropDownBox(AltoholicFrameContainers_SelectRarity)

	AltoholicFrameContainersScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameContainersScrollFrameScrollBar)

	for i = 1, 7 do
		for j = 1, 14 do
			AltoItem(_G["AltoholicFrameContainersEntry"..i.."Item"..j])
		end
	end

	-- Currencies
	S:HandleDropDownBox(AltoholicFrameCurrencies_SelectCurrencies)

	AltoholicFrameCurrenciesScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameCurrenciesScrollFrameScrollBar)

--[[
	for i = 1, 8 do
		for j = 1, 10 do
			_G["AltoholicFrameCurrenciesEntry"..i.."Item"..j]
		end
	end
]]

	-- Equipment
	AltoholicFrameEquipmentScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameEquipmentScrollFrameScrollBar)

	for i = 1, 7 do
		for j = 1, 10 do
			AltoItem(_G["AltoholicFrameEquipmentEntry"..i.."Item"..j])
		end
	end

	-- GuildBank
	for i = 1, 7 do
		for j = 1, 14 do
			AltoItem(_G["AltoGuildBankEntry"..i.."Item"..j])
		end
	end

	-- GuildBankTabs
	AltoholicFrameGuildBankTabsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameGuildBankTabsScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameGuildBankTabsEntry"..i.."Collapse"])
		S:HandleButton(_G["AltoholicFrameGuildBankTabsEntry"..i.."UpdateTab"])
	end

	-- GuildMembers
	AltoholicFrameGuildMembersScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameGuildMembersScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameGuildMembersEntry"..i.."Collapse"])
	end

	for i = 1, 19 do
		AltoItem(_G["AltoholicFrameGuildMembersItem"..i])
	end

	-- GuildProfessions
	AltoholicFrameGuildProfessionsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameGuildProfessionsScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameGuildProfessionsEntry"..i.."Collapse"])
	end

	-- Mails
	AltoholicFrameMailScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameMailScrollFrameScrollBar)

	for i = 1, 7 do
		AltoItem(_G["AltoholicFrameMailEntry"..i.."Item"])
	end

	-- Pets
	S:HandleDropDownBox(AltoholicFramePets_SelectPetView)
	S:HandleRotateButton(AltoholicFramePetsNormal_ModelFrameRotateLeftButton)
	S:HandleRotateButton(AltoholicFramePetsNormal_ModelFrameRotateRightButton)

	for i = 1, 12 do
		local button = _G["AltoholicFramePetsNormal_Button"..i]
		button:SetTemplate()
		button:StyleButton(nil, true)
		button:GetDisabledTexture():SetInside()
		button:SetNormalTexture("")
		button:GetNormalTexture():SetDrawLayer("BORDER")
		button:GetNormalTexture():SetInside()
		button:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end

	S:HandleNextPrevButton(AltoholicFramePetsNormalPrevPage, nil, nil, true)
	AltoholicFramePetsNormalPrevPage:Size(32)
	S:HandleNextPrevButton(AltoholicFramePetsNormalNextPage, nil, nil, true)
	AltoholicFramePetsNormalNextPage:Size(32)

	AltoholicFramePetsAllInOneScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFramePetsAllInOneScrollFrameScrollBar)

	-- Quests
	AltoholicFrameQuestsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameQuestsScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameQuestsEntry"..i.."Collapse"])
	end

	-- Recipes
	SkinCollapse(AltoholicFrameRecipesInfo_ToggleAll)
	S:HandleDropDownBox(AltoholicFrameRecipesInfo_SelectColor)
	S:HandleDropDownBox(AltoholicFrameRecipesInfo_SelectSubclass)
	S:HandleDropDownBox(AltoholicFrameRecipesInfo_SelectInvSlot)
	
	AltoholicFrameRecipesScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameRecipesScrollFrameScrollBar)
	
	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameRecipesEntry"..i.."Collapse"])
		AltoItem(_G["AltoholicFrameRecipesEntry"..i.."Craft"])

		for j = 1, 8 do
			AltoItem(_G["AltoholicFrameRecipesEntry"..i.."Item"..j])
		end
	end

	-- Reputations
	S:HandleDropDownBox(AltoholicFrameReputations_SelectFaction)
	AltoholicFrameReputationsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameReputationsScrollFrameScrollBar)

	for i = 1, 8 do
		for j = 1, 10 do
			local item = _G["AltoholicFrameReputationsEntry"..i.."Item"..j]
			local bg = _G["AltoholicFrameReputationsEntry"..i.."Item"..j.."_Background"]

			item:SetTemplate()
			item:StyleButton()

			bg:SetDrawLayer("BORDER")
			bg:SetInside()
			bg:SetTexCoord(unpack(E.TexCoords))
		end
	end

	-- Search
	AltoholicFrameSearchScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameSearchScrollFrameScrollBar)

	for i = 1, 7 do
		E:RegisterCooldown(_G["AltoholicFrameSearchEntry"..i.."Cooldown"])
		AltoItem(_G["AltoholicFrameSearchEntry"..i.."Item"])
	end

	-- Skills
	AltoholicFrameSkillsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameSkillsScrollFrameScrollBar)

	for i = 1, 14 do
		SkinCollapse(_G["AltoholicFrameSkillsEntry"..i.."Collapse"])
	end

	-- TabCharacters
	S:HandleDropDownBox(AltoholicTabCharacters_SelectRealm)
	S:HandleDropDownBox(AltoholicTabCharacters_SelectChar)
	
	local tabCharacters = {"_Bags", "_Equipment", "_Quests", "_Talents", "_Auctions", "_Bids", "_Mails", "_Pets", "_Mounts", "_Factions", "_Tokens", "_Cooking", "_FirstAid", "_Prof1", "_Prof2"}
	for _, tab in pairs(tabCharacters) do
		AltoItem(_G["AltoholicTabCharacters"..tab])
	end

	for i = 1, 4 do
		_G["AltoholicTabCharacters_Sort"..i]:StripTextures()
	end

	-- TabGuildBank
	S:HandleDropDownBox(AltoholicTabGuildBank_SelectGuild)
	S:HandleButton(AltoholicTabGuildBank_DeleteGuildButton)
	S:HandleCheckBox(AltoholicTabGuildBank_HideInTooltip)

	for i = 1, 6 do
		_G["AltoholicTabGuildBankMenuItem"..i]:StripTextures()
	end

	-- TabSearch
	for i = 1, 15 do
		_G["AltoholicTabSearchMenuItem"..i]:StripTextures()
	end

	AltoholicSearchMenuScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicSearchMenuScrollFrameScrollBar)
	S:HandleEditBox(AltoholicTabSearch_MinLevel)
	S:HandleEditBox(AltoholicTabSearch_MaxLevel)
	S:HandleDropDownBox(AltoholicTabSearch_SelectRarity)
	S:HandleDropDownBox(AltoholicTabSearch_SelectSlot, 140)
	S:HandleDropDownBox(AltoholicTabSearch_SelectLocation, 200)

	for i = 1, 8 do
		_G["AltoholicTabSearch_Sort"..i]:StripTextures()
	end

	-- TabSummary
	for i = 1, 8 do
		_G["AltoholicTabSummaryMenuItem"..i]:StripTextures()
		_G["AltoholicTabSummary_Sort"..i]:StripTextures()
	end

	SkinCollapse(AltoholicTabSummaryToggleView)

	S:HandleDropDownBox(AltoholicTabSummary_SelectLocation, 200)
	S:HandleButton(AltoholicTabSummary_OptionsDataStore)
	S:HandleButton(AltoholicTabSummary_Options)
	S:HandleButton(AltoholicTabSummary_RequestSharing)

	-- Telents
	for i = 1, 3 do
		AltoItem(_G["AltoholicFrameTalents_SpecIcon"..i])
	end

	S:HandleScrollBar(AltoholicFrameTalents_ScrollFrameScrollBar)

	for i = 1, 40 do
		AltoItem(_G["AltoholicFrameTalents_ScrollFrameTalent"..i])
	end
end

local function LoadAchievementsSkin()
	if not E.private.addOnSkins.Altoholic then return end

	AltoholicFrameAchievementsScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicFrameAchievementsScrollFrameScrollBar)

	for i = 1, 8 do
		for j = 1, 10 do
			_G["AltoholicFrameAchievementsEntry"..i.."Item"..j]:SetTemplate()
			_G["AltoholicFrameAchievementsEntry"..i.."Item"..j]:StyleButton()
			_G["AltoholicFrameAchievementsEntry"..i.."Item"..j.."_Background"]:SetDrawLayer("BORDER")
			_G["AltoholicFrameAchievementsEntry"..i.."Item"..j.."_Background"]:SetInside()
			_G["AltoholicFrameAchievementsEntry"..i.."Item"..j.."_Background"]:SetTexCoord(unpack(E.TexCoords))
		end
	end

	for i = 1, 15 do
		_G["AltoholicTabAchievementsMenuItem"..i]:StripTextures()
	end

	AltoholicAchievementsMenuScrollFrame:StripTextures()
	S:HandleScrollBar(AltoholicAchievementsMenuScrollFrameScrollBar)
end

S:AddCallbackForAddon("Altoholic", "Altoholic", LoadSkin)
S:AddCallbackForAddon("Altoholic_Achievements", "Altoholic_Achievements", LoadAchievementsSkin)