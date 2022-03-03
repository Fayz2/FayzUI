local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local select = select
--WoW API / Variables

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.arenaregistrar then return end

	ArenaRegistrarFrame:CreateBackdrop("Transparent")
	ArenaRegistrarFrame.backdrop:Point("TOPLEFT", 11, -12)
	ArenaRegistrarFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(ArenaRegistrarFrame, "width")

	ArenaRegistrarFrame:StripTextures(true)

	S:HandleCloseButton(ArenaRegistrarFrameCloseButton, ArenaRegistrarFrame.backdrop)

	ArenaRegistrarGreetingFrame:StripTextures()

	select(1, ArenaRegistrarGreetingFrame:GetRegions()):SetTextColor(1, 1, 1)
	RegistrationText:SetTextColor(1, 1, 1)

	ArenaRegistrarFrameGoodbyeButton:Point("BOTTOMRIGHT", -39, 81)
	S:HandleButton(ArenaRegistrarFrameGoodbyeButton)

	local registrarButton
	for i = 1, MAX_TEAM_BORDERS do
		registrarButton = select(3, _G["ArenaRegistrarButton"..i]:GetRegions())
		registrarButton:SetTextColor(1, 1, 1)
	end

	ArenaRegistrarPurchaseText:SetTextColor(1, 1, 1)

	ArenaRegistrarFrameCancelButton:Point("BOTTOMRIGHT", -39, 81)
	ArenaRegistrarFramePurchaseButton:Point("BOTTOMLEFT", 21, 81)
	S:HandleButton(ArenaRegistrarFrameCancelButton)
	S:HandleButton(ArenaRegistrarFramePurchaseButton)

	select(6, ArenaRegistrarFrameEditBox:GetRegions()):Kill()
	select(7, ArenaRegistrarFrameEditBox:GetRegions()):Kill()
	S:HandleEditBox(ArenaRegistrarFrameEditBox)
	ArenaRegistrarFrameEditBox:Height(18)

	PVPBannerFrame:CreateBackdrop("Transparent")
	PVPBannerFrame.backdrop:Point("TOPLEFT", 11, -12)
	PVPBannerFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(PVPBannerFrame, "width")

	PVPBannerFrame:StripTextures()

	PVPBannerFramePortrait:Kill()

	PVPBannerFrameCustomizationFrame:StripTextures()

	for i = 1, 2 do
		_G["PVPBannerFrameCustomization"..i]:StripTextures()
		S:HandleNextPrevButton(_G["PVPBannerFrameCustomization"..i.."LeftButton"])
		S:HandleNextPrevButton(_G["PVPBannerFrameCustomization"..i.."RightButton"])
	end

	local pickerButton
	for i = 1, 3 do
		pickerButton = _G["PVPColorPickerButton"..i]
		S:HandleButton(pickerButton)
		if i == 2 then
			pickerButton:Point("TOP", PVPBannerFrameCustomization2, "BOTTOM", 0, -33)
		elseif i == 3 then
			pickerButton:Point("TOP", PVPBannerFrameCustomization2, "BOTTOM", 0, -59)
		end
	end

	S:HandleButton(PVPBannerFrameAcceptButton)
	S:HandleButton(PVPBannerFrameCancelButton)
	S:HandleButton((select(4, PVPBannerFrame:GetChildren())))

	S:HandleCloseButton(PVPBannerFrameCloseButton, PVPBannerFrame.backdrop)
end

S:AddCallback("Skin_ArenaRegistrar", LoadSkin)