local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local unpack = unpack
local lower, match, trim = string.lower, string.match, string.trim

local GetContainerItemQuestInfo = GetContainerItemQuestInfo
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor

local ITEM_QUALITY_POOR = ITEM_QUALITY_POOR
local ITEM_QUALITY_UNCOMMON = ITEM_QUALITY_UNCOMMON

-- AdiBags 1.1 beta 7
-- https://www.curseforge.com/wow/addons/adibags/files/452440

local function LoadSkin()
	if not E.private.addOnSkins.AdiBags then return end

	local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags", true)
	if not AdiBags then return end

	hooksecurefunc(AdiBags, "ResetBagPositions", function(self)
		self.db.profile.scale = 1
		self:LayoutBags()
	end)

	local function SkinContainer(frame)
		frame:SetTemplate("Transparent")
		S:HandleCloseButton(frame.CloseButton)
		frame.BagSlotPanel:SetTemplate("Transparent")

		local icon
		for _, bag in pairs(frame.BagSlotPanel.buttons) do
			icon = _G[bag:GetName().."IconTexture"]
			bag.oldTex = icon:GetTexture()

			bag:StripTextures()
			bag:CreateBackdrop("Default", true)
			bag.backdrop:SetAllPoints()
			bag:StyleButton()
			icon:SetTexture(bag.oldTex)
			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
		end
	end

	S:RawHook(AdiBags, "CreateContainerFrame", function(self, ...)
		local frame = S.hooks[self].CreateContainerFrame(self, ...)

		SkinContainer(frame)

		return frame
	end)

	local LayeredRegionClass = AdiBags:GetClass("LayeredRegion")
	hooksecurefunc(LayeredRegionClass.prototype, "AddWidget", function(self, widget)
		if widget:IsObjectType("Button") then
			if widget:GetText() then
				S:HandleButton(widget)
			else
				widget:StyleButton(true, true)
				widget:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
				widget:GetCheckedTexture():SetTexCoord(unpack(E.TexCoords))
			end
		elseif widget.editBox and widget.editBox.clearButton then
			widget.editBox:DisableDrawLayer("BACKGROUND")
			S:HandleEditBox(widget.editBox)

			S:HandleButton(widget.editBox.clearButton)
		end
	end)

	local ItemButtonClass = AdiBags:GetClass("ItemButton")
	hooksecurefunc(ItemButtonClass.prototype, "OnCreate", function(self)
		self.NormalTexture:SetTexture(nil)
		self:SetTemplate("Default", true)
		self:StyleButton()

		E:RegisterCooldown(self.Cooldown)

		self.IconTexture:SetInside()
	end)

	hooksecurefunc(ItemButtonClass.prototype, "Update", function(self)
		if self.texture then
			self.IconTexture:SetTexCoord(unpack(E.TexCoords))
		else
			self.IconTexture:SetTexture(nil)
		end
	end)

	hooksecurefunc(ItemButtonClass.prototype, "UpdateBorder", function(self)
		if not self.hasItem then return end

		local profileDB = AdiBags.db.profile
		local isQuestItem, questId, isActive = GetContainerItemQuestInfo(self.bag, self.slot)
		local _, _, quality = GetItemInfo(self.itemId)

		if profileDB.questIndicator and (questId and not isActive) then
			self.IconQuestTexture:SetAlpha(1)
			self.IconQuestTexture:SetInside()
			self.IconQuestTexture:SetTexCoord(unpack(E.TexCoords))
		else
			self.IconQuestTexture:SetAlpha(0)
		end

		if questId and not isActive then
			self:SetBackdropBorderColor(1, 1, 0)
		elseif questId or isQuestItem then
			self:SetBackdropBorderColor(1, 0.2, 0.2)
		elseif profileDB.qualityHighlight and quality then
			if quality >= ITEM_QUALITY_UNCOMMON then
				self:SetBackdropBorderColor(GetItemQualityColor(quality))
			elseif quality == ITEM_QUALITY_POOR and profileDB.dimJunk then
				local c = 1 - 0.5 * profileDB.qualityOpacity
				self:SetBackdropBorderColor(c, c, c)
			else
				self:SetBackdropBorderColor(unpack(E["media"].bordercolor))
			end
		else
			self:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)

	local AdiBags_SearchHighlight = AdiBags:GetModule("SearchHighlight")
	hooksecurefunc(AdiBags_SearchHighlight, "UpdateButton", function(self, event, button)
		if not self.widget then return end

		local text = self.widget:GetText()
		if not text then return end

		text = trim(text)
		if text == "" then return end

		local name = button.itemId and GetItemInfo(button.itemId)

		if name and not match(lower(name), lower(text)) then
			button:SetBackdropBorderColor(unpack(E["media"].bordercolor))
		end
	end)
end

S:AddCallbackForAddon("AdiBags", "AdiBags", LoadSkin)