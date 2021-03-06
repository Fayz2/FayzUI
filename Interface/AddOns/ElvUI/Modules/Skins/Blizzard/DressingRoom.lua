local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
--WoW API / Variables
local SetDressUpBackground = SetDressUpBackground

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.dressingroom then return end

	DressUpFrame:StripTextures()
	DressUpFrame:CreateBackdrop("Transparent")
	DressUpFrame.backdrop:Point("TOPLEFT", 11, -12)
	DressUpFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(DressUpFrame, "width")

	DressUpFramePortrait:Kill()

	SetDressUpBackground()
	DressUpBackgroundTopLeft:SetDesaturated(true)
	DressUpBackgroundTopRight:SetDesaturated(true)
	DressUpBackgroundBotLeft:SetDesaturated(true)
	DressUpBackgroundBotRight:SetDesaturated(true)

	S:HandleCloseButton(DressUpFrameCloseButton, DressUpFrame.backdrop)

	S:HandleRotateButton(DressUpModelRotateLeftButton)
	DressUpModelRotateLeftButton:Point("TOPLEFT", DressUpFrame, 25, -79)
	S:HandleRotateButton(DressUpModelRotateRightButton)
	DressUpModelRotateRightButton:Point("TOPLEFT", DressUpModelRotateLeftButton, "TOPRIGHT", 3, 0)

	S:HandleButton(DressUpFrameCancelButton)
	DressUpFrameCancelButton:Point("CENTER", DressUpFrame, "TOPLEFT", 300, -422)
	S:HandleButton(DressUpFrameResetButton)
	DressUpFrameResetButton:Point("RIGHT", DressUpFrameCancelButton, "LEFT", -3, 0)

	DressUpModel:CreateBackdrop("Default")
	DressUpModel.backdrop:SetOutside(DressUpBackgroundTopLeft, nil, nil, DressUpModel)
end

S:AddCallback("Skin_DressingRoom", LoadSkin)