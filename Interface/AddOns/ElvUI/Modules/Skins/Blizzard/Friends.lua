local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumWhoResults = GetNumWhoResults
local GetWhoInfo = GetWhoInfo
local GUILDMEMBERS_TO_DISPLAY = GUILDMEMBERS_TO_DISPLAY
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.friends then return end

	-- Friends Frame
	FriendsFrame:StripTextures(true)
	FriendsFrame:CreateBackdrop("Transparent")
	FriendsFrame.backdrop:Point("TOPLEFT", 11, -12)
	FriendsFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetUIPanelWindowInfo(FriendsFrame, "width")

	S:HandleCloseButton(FriendsFrameCloseButton, FriendsFrame.backdrop)

	S:HandleDropDownBox(FriendsFrameStatusDropDown, 70)
	FriendsFrameStatusDropDown:Point("TOPLEFT", FriendsListFrame, "TOPLEFT", 13, -44)
	S:HandleEditBox(FriendsFrameBroadcastInput)
	FriendsFrameBroadcastInput:Width(224)
	FriendsFrameBroadcastInput:Point("TOPLEFT", FriendsFrameStatusDropDown, "TOPRIGHT", 13, -3)

	for i = 1, 5 do
		S:HandleTab(_G["FriendsFrameTab"..i])
	end

	-- Friends List Frame
	for i = 1, 2 do
		local tab = _G["FriendsTabHeaderTab"..i]
		tab:StripTextures()
		tab:CreateBackdrop("Default", true)
		tab.backdrop:Point("TOPLEFT", 3, -7)
		tab.backdrop:Point("BOTTOMRIGHT", -2, -1)

		tab:HookScript("OnEnter", S.SetModifiedBackdrop)
		tab:HookScript("OnLeave", S.SetOriginalBackdrop)
	end

	for i = 1, 11 do
		_G["FriendsFrameFriendsScrollFrameButton"..i.."SummonButtonIcon"]:SetTexCoord(unpack(E.TexCoords))
		_G["FriendsFrameFriendsScrollFrameButton"..i.."SummonButtonNormalTexture"]:SetAlpha(0)
		_G["FriendsFrameFriendsScrollFrameButton"..i.."SummonButton"]:StyleButton()
	end

	FriendsFrameFriendsScrollFrame:Point("TOPLEFT", FriendsFrame, 19, -98)
	S:HandleScrollBar(FriendsFrameFriendsScrollFrameScrollBar)

	FriendsFrameAddFriendButton:Point("BOTTOMLEFT", FriendsFrame, 16, 82)
	FriendsFrameAddFriendButton:Height(22)

	FriendsFrameSendMessageButton:Point("BOTTOMRIGHT", FriendsFrame, -40, 82)
	FriendsFrameSendMessageButton:Height(22)

	S:HandleButton(FriendsFrameAddFriendButton, true)
	S:HandleButton(FriendsFrameSendMessageButton, true)

	-- Ignore List Frame
	S:HandleScrollBar(FriendsFrameIgnoreScrollFrameScrollBar)

	FriendsFrameIgnorePlayerButton:Point("BOTTOMLEFT", FriendsFrame, 17, 82)
	FriendsFrameIgnorePlayerButton:Height(22)

	FriendsFrameUnsquelchButton:Point("BOTTOMRIGHT", FriendsFrame, -40, 82)
	FriendsFrameUnsquelchButton:Height(22)

	S:HandleButton(FriendsFrameIgnorePlayerButton, true)
	S:HandleButton(FriendsFrameUnsquelchButton, true)

	-- Who Frame
	WhoFrameColumnHeader3:ClearAllPoints()
	WhoFrameColumnHeader3:SetPoint("TOPLEFT", 20, -70)

	WhoFrameColumnHeader4:ClearAllPoints()
	WhoFrameColumnHeader4:SetPoint("LEFT", WhoFrameColumnHeader3, "RIGHT", -2, -0)
	WhoFrameColumn_SetWidth(WhoFrameColumnHeader4, 48)

	WhoFrameColumnHeader1:ClearAllPoints()
	WhoFrameColumnHeader1:SetPoint("LEFT", WhoFrameColumnHeader4, "RIGHT", -2, -0)
	WhoFrameColumn_SetWidth(WhoFrameColumnHeader1, 105)

	WhoFrameColumnHeader2:ClearAllPoints()
	WhoFrameColumnHeader2:SetPoint("LEFT", WhoFrameColumnHeader1, "RIGHT", -2, -0)

	for i = 1, 4 do
		local header = _G["WhoFrameColumnHeader"..i]
		header:StripTextures()
		header:StyleButton()
	end

	S:HandleDropDownBox(WhoFrameDropDown)

	do
		local button, level, name, class

		for i = 1, 17 do
			button = _G["WhoFrameButton"..i]
			level = _G["WhoFrameButton"..i.."Level"]
			name = _G["WhoFrameButton"..i.."Name"]
			class = _G["WhoFrameButton"..i.."Class"]

			button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
			button.icon:Point("LEFT", 45, 0)
			button.icon:Size(15)
			button.icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")

			button:CreateBackdrop("Default", true)
			button.backdrop:SetAllPoints(button.icon)
			S:HandleButtonHighlight(button)

			level:ClearAllPoints()
			level:SetPoint("TOPLEFT", 11, -1)

			name:SetSize(100, 14)
			name:ClearAllPoints()
			name:SetPoint("LEFT", 85, 0)

			class:Hide()
		end
	end

	WhoListScrollFrame:StripTextures()
	S:HandleScrollBar(WhoListScrollFrameScrollBar)

	S:HandleEditBox(WhoFrameEditBox)
	WhoFrameEditBox:Point("BOTTOM", -12, 107)
	WhoFrameEditBox:Size(326, 18)

	S:HandleButton(WhoFrameWhoButton)
	WhoFrameWhoButton:ClearAllPoints()
	WhoFrameWhoButton:SetPoint("BOTTOMLEFT", 16, 82)
	S:HandleButton(WhoFrameAddFriendButton)
	WhoFrameAddFriendButton:SetPoint("LEFT", WhoFrameWhoButton, "RIGHT", 3, 0)
	WhoFrameAddFriendButton:SetPoint("RIGHT", WhoFrameGroupInviteButton, "LEFT", -3, 0)
	S:HandleButton(WhoFrameGroupInviteButton)

	hooksecurefunc("WhoList_Update", function()
		local numWhos = GetNumWhoResults()
		if numWhos == 0 then return end

		numWhos = numWhos > WHOS_TO_DISPLAY and WHOS_TO_DISPLAY or numWhos

		local _, level, classFileName
		local button, buttonText, classTextColor, levelTextColor

		for i = 1, numWhos do
			button = _G["WhoFrameButton"..i]
			_, _, level, _, _, _, classFileName = GetWhoInfo(button.whoIndex)

			if classFileName then
				classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
				button.icon:Show()
				button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))
			else
				classTextColor = HIGHLIGHT_FONT_COLOR
				button.icon:Hide()
			end

			levelTextColor = GetQuestDifficultyColor(level)

			buttonText = _G["WhoFrameButton"..i.."Name"]
			buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
			buttonText = _G["WhoFrameButton"..i.."Level"]
			buttonText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)
			buttonText = _G["WhoFrameButton"..i.."Class"]
			buttonText:SetTextColor(1.0, 1.0, 1.0)
		end
	end)

	-- Guild Frame
	GuildFrameColumnHeader3:ClearAllPoints()
	GuildFrameColumnHeader3:SetPoint("TOPLEFT", 20, -70)

	GuildFrameColumnHeader4:ClearAllPoints()
	GuildFrameColumnHeader4:SetPoint("LEFT", GuildFrameColumnHeader3, "RIGHT", -2, -0)
	WhoFrameColumn_SetWidth(GuildFrameColumnHeader4, 48)

	GuildFrameColumnHeader1:ClearAllPoints()
	GuildFrameColumnHeader1:SetPoint("LEFT", GuildFrameColumnHeader4, "RIGHT", -2, -0)
	WhoFrameColumn_SetWidth(GuildFrameColumnHeader1, 105)

	GuildFrameColumnHeader2:ClearAllPoints()
	GuildFrameColumnHeader2:SetPoint("LEFT", GuildFrameColumnHeader1, "RIGHT", -2, -0)
	WhoFrameColumn_SetWidth(GuildFrameColumnHeader2, 127)

	do
		local button, level, name, class, statusButton, statusName

		for i = 1, GUILDMEMBERS_TO_DISPLAY do
			button = _G["GuildFrameButton"..i]
			level = _G["GuildFrameButton"..i.."Level"]
			name = _G["GuildFrameButton"..i.."Name"]
			class = _G["GuildFrameButton"..i.."Class"]
			statusButton = _G["GuildFrameGuildStatusButton"..i]
			statusName = _G["GuildFrameGuildStatusButton"..i.."Name"]

			button.icon = button:CreateTexture("$parentIcon", "ARTWORK")
			button.icon:Point("LEFT", 48, 0)
			button.icon:Size(15)
			button.icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")

			button:CreateBackdrop("Default", true)
			button.backdrop:SetAllPoints(button.icon)

			S:HandleButtonHighlight(button)
			S:HandleButtonHighlight(statusButton)

			level:ClearAllPoints()
			level:SetPoint("TOPLEFT", 10, -1)

			name:SetSize(100, 14)
			name:ClearAllPoints()
			name:SetPoint("LEFT", 85, 0)

			class:Hide()

			statusName:ClearAllPoints()
			statusName:SetPoint("LEFT", 10, 0)
		end
	end

	hooksecurefunc("GuildStatus_Update", function()
		local _, online, classFileName
		local button, classTextColor

		if FriendsFrame.playerStatusFrame then
			local level, buttonText, levelTextColor

			for i = 1, GUILDMEMBERS_TO_DISPLAY do
				button = _G["GuildFrameButton"..i]
				_, _, _, level, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(button.guildIndex)
				if classFileName then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
						levelTextColor = GetQuestDifficultyColor(level)
						buttonText = _G["GuildFrameButton"..i.."Name"]
						buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						buttonText = _G["GuildFrameButton"..i.."Level"]
						buttonText:SetTextColor(levelTextColor.r, levelTextColor.g, levelTextColor.b)
					end
					button.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFileName]))
				end
			end
		else
			for i = 1, GUILDMEMBERS_TO_DISPLAY do
				button = _G["GuildFrameGuildStatusButton"..i]
				_, _, _, _, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(button.guildIndex)
				if classFileName then
					if online then
						classTextColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName] or RAID_CLASS_COLORS[classFileName]
						_G["GuildFrameGuildStatusButton"..i.."Name"]:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
						_G["GuildFrameGuildStatusButton"..i.."Online"]:SetTextColor(1.0, 1.0, 1.0)
					end
				end
			end
		end
	end)

	GuildFrameLFGFrame:StripTextures()
	GuildFrameLFGFrame:SetTemplate("Default")
	S:HandleCheckBox(GuildFrameLFGButton)

	for i = 1, 4 do
		local header = _G["GuildFrameColumnHeader"..i]
		header:StripTextures()
		header:StyleButton()

		header = _G["GuildFrameGuildStatusColumnHeader"..i]
		header:StripTextures()
		header:StyleButton()
	end

	GuildListScrollFrame:StripTextures()
	S:HandleScrollBar(GuildListScrollFrameScrollBar)

	S:HandleNextPrevButton(GuildFrameGuildListToggleButton)

	S:HandleButton(GuildFrameGuildInformationButton)
	S:HandleButton(GuildFrameAddMemberButton)
	S:HandleButton(GuildFrameControlButton)

	-- Member Detail Frame
	GuildMemberDetailFrame:StripTextures()
	GuildMemberDetailFrame:CreateBackdrop("Transparent")
	GuildMemberDetailFrame:Point("TOPLEFT", GuildFrame, "TOPRIGHT", -30, -13)

	S:HandleCloseButton(GuildMemberDetailCloseButton)

	S:HandleButton(GuildMemberRemoveButton)
	GuildMemberRemoveButton:SetPoint("BOTTOMLEFT", 8, 7)
	S:HandleButton(GuildMemberGroupInviteButton)
	GuildMemberGroupInviteButton:SetPoint("LEFT", GuildMemberRemoveButton, "RIGHT", 3, 0)

	S:HandleNextPrevButton(GuildFramePromoteButton)
	S:HandleNextPrevButton(GuildFrameDemoteButton)
	GuildFrameDemoteButton:SetPoint("LEFT", GuildFramePromoteButton, "RIGHT", 2, 0)

	GuildMemberNoteBackground:SetTemplate("Default")
	GuildMemberOfficerNoteBackground:SetTemplate("Default")

	-- Info Frame
	GuildInfoFrame:StripTextures()
	GuildInfoFrame:CreateBackdrop("Transparent")
	GuildInfoFrame.backdrop:Point("TOPLEFT", 3, -6)
	GuildInfoFrame.backdrop:Point("BOTTOMRIGHT", -2, 3)

	GuildInfoTextBackground:SetTemplate("Default")
	S:HandleScrollBar(GuildInfoFrameScrollFrameScrollBar)

	S:HandleCloseButton(GuildInfoCloseButton)

	S:HandleButton(GuildInfoSaveButton)
	GuildInfoSaveButton:SetPoint("BOTTOMLEFT", 104, 11)

	S:HandleButton(GuildInfoCancelButton)
	GuildInfoCancelButton:SetPoint("LEFT", GuildInfoSaveButton, "RIGHT", 3, 0)

	S:HandleButton(GuildInfoGuildEventButton)
	GuildInfoGuildEventButton:SetPoint("RIGHT", GuildInfoSaveButton, "LEFT", -28, 0)

	-- GuildEventLog Frame
	GuildEventLogFrame:StripTextures()
	GuildEventLogFrame:CreateBackdrop("Transparent")
	GuildEventLogFrame.backdrop:Point("TOPLEFT", 3, -6)
	GuildEventLogFrame.backdrop:Point("BOTTOMRIGHT", -1, 5)

	GuildEventFrame:SetTemplate("Default")

	S:HandleScrollBar(GuildEventLogScrollFrameScrollBar)
	S:HandleCloseButton(GuildEventLogCloseButton)

	GuildEventLogCancelButton:Point("BOTTOMRIGHT", GuildEventLogFrame, "BOTTOMRIGHT", -9, 9)
	S:HandleButton(GuildEventLogCancelButton)

	-- Control Frame
	GuildControlPopupFrame:StripTextures()
	GuildControlPopupFrame:CreateBackdrop("Transparent")
	GuildControlPopupFrame.backdrop:Point("TOPLEFT", 3, -6)
	GuildControlPopupFrame.backdrop:Point("BOTTOMRIGHT", -27, 27)

	S:HandleDropDownBox(GuildControlPopupFrameDropDown, 185)
	GuildControlPopupFrameDropDownButton:SetSize(16, 16)

	local function SkinPlusMinus(f, minus)
		f:SetNormalTexture("")
		f.SetNormalTexture = E.noop
		f:SetPushedTexture("")
		f.SetPushedTexture = E.noop
		f:SetHighlightTexture("")
		f.SetHighlightTexture = E.noop
		f:SetDisabledTexture("")
		f.SetDisabledTexture = E.noop

		f.Text = f:CreateFontString(nil, "OVERLAY")
		f.Text:FontTemplate(nil, 22)
		f.Text:Point("LEFT", 5, 0)
		if minus then
			f.Text:SetText("-")
		else
			f.Text:SetText("+")
		end
	end

	GuildControlPopupFrameAddRankButton:Point("LEFT", GuildControlPopupFrameDropDown, "RIGHT", -8, 3)
	SkinPlusMinus(GuildControlPopupFrameAddRankButton)
	SkinPlusMinus(GuildControlPopupFrameRemoveRankButton, true)

	S:HandleEditBox(GuildControlPopupFrameEditBox)
	GuildControlPopupFrameEditBox.backdrop:Point("TOPLEFT", 0, -5)
	GuildControlPopupFrameEditBox.backdrop:Point("BOTTOMRIGHT", 0, 5)

	for i = 1, 17 do
		local checkbox = _G["GuildControlPopupFrameCheckbox"..i]
		if checkbox then
			S:HandleCheckBox(checkbox)
		end
	end

	S:HandleEditBox(GuildControlWithdrawGoldEditBox)
	GuildControlWithdrawGoldEditBox.backdrop:Point("TOPLEFT", 0, -5)
	GuildControlWithdrawGoldEditBox.backdrop:Point("BOTTOMRIGHT", 0, 5)

	for i = 1, MAX_GUILDBANK_TABS do
		local tab = _G["GuildBankTabPermissionsTab"..i]

		tab:StripTextures()
		tab:CreateBackdrop("Default")
		tab.backdrop:Point("TOPLEFT", 3, -10)
		tab.backdrop:Point("BOTTOMRIGHT", -2, 4)
	end

	GuildControlPopupFrameTabPermissions:SetTemplate("Default")

	S:HandleCheckBox(GuildControlTabPermissionsViewTab)
	S:HandleCheckBox(GuildControlTabPermissionsDepositItems)
	S:HandleCheckBox(GuildControlTabPermissionsUpdateText)

	S:HandleEditBox(GuildControlWithdrawItemsEditBox)
	GuildControlWithdrawItemsEditBox.backdrop:Point("TOPLEFT", 0, -5)
	GuildControlWithdrawItemsEditBox.backdrop:Point("BOTTOMRIGHT", 0, 5)

	S:HandleButton(GuildControlPopupAcceptButton)
	S:HandleButton(GuildControlPopupFrameCancelButton)

	-- Channel Frame
	ChannelFrameVerticalBar:Kill()

	S:HandleCheckBox(ChannelFrameAutoJoinParty)
	S:HandleCheckBox(ChannelFrameAutoJoinBattleground)

	S:HandleButton(ChannelFrameNewButton)

	ChannelListScrollFrame:StripTextures()
	S:HandleScrollBar(ChannelListScrollFrameScrollBar)

	for i = 1, MAX_DISPLAY_CHANNEL_BUTTONS do
		local button = _G["ChannelButton"..i]
		button:StripTextures()
		S:HandleButtonHighlight(button)

		_G["ChannelButton"..i.."Collapsed"]:SetTextColor(1, 1, 1)
	end

	for i = 1, 22 do
		S:HandleButtonHighlight(_G["ChannelMemberButton"..i])
	end

	ChannelRosterScrollFrame:StripTextures()
	S:HandleScrollBar(ChannelRosterScrollFrameScrollBar)

	ChannelFrameDaughterFrame:StripTextures()
	ChannelFrameDaughterFrame:SetTemplate("Transparent")

	S:HandleEditBox(ChannelFrameDaughterFrameChannelName)
	S:HandleEditBox(ChannelFrameDaughterFrameChannelPassword)

	S:HandleCloseButton(ChannelFrameDaughterFrameDetailCloseButton)

	S:HandleButton(ChannelFrameDaughterFrameCancelButton)
	S:HandleButton(ChannelFrameDaughterFrameOkayButton)

	-- Raid Frame
	S:HandleButton(RaidFrameConvertToRaidButton)
	S:HandleButton(RaidFrameRaidInfoButton)
	S:HandleButton(RaidFrameNotInRaidRaidBrowserButton)

	-- Raid Info Frame
	RaidInfoFrame:StripTextures(true)
	RaidInfoFrame:SetTemplate("Transparent")

	RaidInfoInstanceLabel:StripTextures()
	RaidInfoIDLabel:StripTextures()

	S:HandleCloseButton(RaidInfoCloseButton)

	S:HandleScrollBar(RaidInfoScrollFrameScrollBar)

	S:HandleButton(RaidInfoExtendButton)
	S:HandleButton(RaidInfoCancelButton)
end

S:AddCallback("Skin_Friends", LoadSkin)