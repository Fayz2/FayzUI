local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	PlayerTalentFrame:StripTextures(true)
	PlayerTalentFrame:CreateBackdrop("Transparent")
	PlayerTalentFrame.backdrop:Point("TOPLEFT", 11, -12)
	PlayerTalentFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	do
		local offset

		local talentGroups = GetNumTalentGroups(false, false)
		local petTalentGroups = GetNumTalentGroups(false, true)

		if talentGroups + petTalentGroups > 1 then
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, 32)
			offset = true
		else
			S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
		end

		hooksecurefunc("PlayerTalentFrame_UpdateSpecs", function(_, numTalentGroups, _, numPetTalentGroups)
			if offset and numTalentGroups + numPetTalentGroups <= 1 then
				S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
				offset = nil
			elseif not offset and numTalentGroups + numPetTalentGroups > 1 then
				S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, 32)
				offset = true
			end
		end)
	end

	S:HandleCloseButton(PlayerTalentFrameCloseButton, PlayerTalentFrame.backdrop)

	PlayerTalentFrameStatusFrame:StripTextures()
	PlayerTalentFrameStatusFrame:Point("TOPLEFT", PlayerTalentFrame, "TOPLEFT", 57, -40)
	PlayerTalentFrameStatusFrame:HookScript("OnShow", function(self)
		if GlyphFrame and GlyphFrame:IsShown() then
			self:Hide()
		end
	end)

	S:HandleButton(PlayerTalentFrameActivateButton, true)
	PlayerTalentFrameActivateButton:Point("TOP", PlayerTalentFrame, "TOP", 0, -40)
	PlayerTalentFrameActivateButton:HookScript("OnShow", function(self)
		if GlyphFrame and GlyphFrame:IsShown() then
			self:Hide()
		end
	end)

	PlayerTalentFramePointsBar:StripTextures()
	PlayerTalentFramePreviewBar:StripTextures()

	S:HandleButton(PlayerTalentFrameResetButton)
	PlayerTalentFrameLearnButton:Point("RIGHT", PlayerTalentFrameResetButton, "LEFT", -1, 0)
	S:HandleButton(PlayerTalentFrameLearnButton)

	PlayerTalentFramePreviewBarFiller:StripTextures()

	PlayerTalentFrameScrollFrame:StripTextures()
	PlayerTalentFrameScrollFrame:CreateBackdrop("Default")
	S:HandleScrollBar(PlayerTalentFrameScrollFrameScrollBar)

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["PlayerTalentFrameTalent"..i]
		local icon = _G["PlayerTalentFrameTalent"..i.."IconTexture"]
		local rank = _G["PlayerTalentFrameTalent"..i.."Rank"]

		if talent then
			talent:StripTextures()
			talent:SetTemplate("Default")
			talent:StyleButton()

			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("ARTWORK")

			rank:SetFont(E.LSM:Fetch("font", E.db.general.font), 12, "OUTLINE")
		end
	end

	for i = 1, 4 do
		S:HandleTab(_G["PlayerTalentFrameTab"..i])
	end

	for i = 1, MAX_TALENT_TABS do
		local tab = _G["PlayerSpecTab"..i]
		tab:GetRegions():Hide()

		tab:SetTemplate("Default")
		tab:StyleButton(nil, true)

		tab:GetNormalTexture():SetInside()
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end
end

S:AddCallbackForAddon("Blizzard_TalentUI", "Skin_Blizzard_TalentUI", LoadSkin)