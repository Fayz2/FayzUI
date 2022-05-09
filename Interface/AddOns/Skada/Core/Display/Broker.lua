local Skada = Skada
local L = LibStub("AceLocale-3.0"):GetLocale("Skada")

local name = L["Data Text"]
local mod = Skada:NewModule(name)

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LibWindow = LibStub("LibWindow-1.1")

local tsort, format = table.sort, string.format
local CloseDropDownMenus = CloseDropDownMenus

local WrapTextInColorCode = Skada.WrapTextInColorCode
local RGBPercToHex = Skada.RGBPercToHex

local FONT_FLAGS = Skada.fontFlags
if not FONT_FLAGS then
	FONT_FLAGS = {
		[""] = L.None,
		["OUTLINE"] = L["Outline"],
		["THICKOUTLINE"] = L["Thick outline"],
		["MONOCHROME"] = L["Monochrome"],
		["OUTLINEMONOCHROME"] = L["Outlined monochrome"]
	}
	Skada.fontFlags = FONT_FLAGS
end

local function sortDataset(win)
	tsort(win.dataset, function(a, b)
		if not a or a.value == nil then
			return false
		elseif not b or b.value == nil then
			return true
		else
			return a.value > b.value
		end
	end)
end

local function formatLabel(win, data)
	if win.db.isusingclasscolors and data.class then
		return WrapTextInColorCode(data.text or data.label or L.Unknown, Skada.classcolors[data.class].colorStr)
	elseif data.color and data.color.colorStr then
		return WrapTextInColorCode(data.text or data.label or L.Unknown, data.color.colorStr)
	elseif data.color then
		return WrapTextInColorCode(data.text or data.label or L.Unknown, RGBPercToHex(data.color.r or 1, data.color.g or 1, data.color.b or 1, data.color.a or 1, true))
	else
		return data.text or data.label or L.Unknown
	end
end

local function formatValue(win, data)
	return data.valuetext
end

local function clickHandler(win, frame, button)
	if not win.obj then
		return
	end

	if button == "LeftButton" and IsShiftKeyDown() then
		Skada:OpenMenu(win)
	elseif button == "LeftButton" then
		Skada:ModeMenu(win)
	elseif button == "RightButton" then
		Skada:SegmentMenu(win)
	end
end

local function tooltipHandler(win, tooltip)
	if win.db.useframe then
		Skada:SetTooltipPosition(tooltip, win.frame, nil, win)
	end

	-- Default color.
	local color = win.db.textcolor or {r = 1, g = 1, b = 1}

	tooltip:AddLine(win.metadata.title)

	sortDataset(win)
	if #win.dataset > 0 then
		tooltip:AddLine(" ")
		local n = 0 -- used to fix spots starting from 2
		for i, data in ipairs(win.dataset) do
			if data.id and not data.ignore and i < 30 then
				n = n + 1
				local label = formatLabel(win, data)
				local value = formatValue(win, data)

				if win.metadata.showspots and Skada.db.profile.showranks then
					label = format("%s. %s", n, label)
				end

				tooltip:AddDoubleLine(label or "", value or "", color.r, color.g, color.b, color.r, color.g, color.b)
			end
		end
	end

	tooltip:AddLine(" ")
	tooltip:AddLine(L["Hint: Left-Click to set active mode."], 0, 1, 0)
	tooltip:AddLine(L["Right-Click to set active set."], 0, 1, 0)
	tooltip:AddLine(L["Shift+Left-Click to open menu."], 0, 1, 0)

	tooltip:Show()
end

local ttactive = false

function mod:Create(win, isnew)
	-- Optional internal frame
	if not win.frame then
		win.frame = CreateFrame("Frame", win.db.name .. "BrokerFrame", UIParent)
		win.frame:SetHeight(win.db.height or 30)
		win.frame:SetWidth(win.db.width or 200)
		win.frame:SetPoint("CENTER", 0, 0)

		-- Register with LibWindow-1.1.
		LibWindow.RegisterConfig(win.frame, win.db)

		-- Restore window position.
		if isnew then
			LibWindow.SavePosition(win.frame)
		else
			LibWindow.RestorePosition(win.frame)
		end

		local title = win.frame:CreateFontString("frameTitle", 6)
		title:SetPoint("CENTER", 0, 0)
		win.frame.title = title

		win.frame:EnableMouse(true)
		win.frame:SetMovable(true)
		win.frame:RegisterForDrag("LeftButton")
		win.frame:SetScript("OnMouseUp", function(frame, button) clickHandler(win, frame, button) end)
		win.frame:SetScript("OnEnter", function(frame) tooltipHandler(win, GameTooltip) end)
		win.frame:SetScript("OnLeave", function(frame) GameTooltip:Hide() end)
		win.frame:SetScript("OnDragStart", function(frame)
			if not win.db.barslocked then
				GameTooltip:Hide()
				frame.isDragging = true
				frame:StartMoving()
			end
		end)
		win.frame:SetScript("OnDragStop", function(frame)
			frame:StopMovingOrSizing()
			frame.isDragging = false
			LibWindow.SavePosition(frame)
		end)
	end

	-- LDB object
	if not win.obj then
		win.obj = LDB:NewDataObject("Skada: " .. win.db.name, {
			type = "data source",
			text = "",
			OnTooltipShow = function(tooltip) tooltipHandler(win, tooltip) end,
			OnClick = function(frame, button) clickHandler(win, frame, button) end
		})
	end

	mod:ApplySettings(win)
end

function mod:IsShown(win)
	if win and win.frame and win.db.useframe then
		return win.frame:IsShown() and true or false
	end
end

function mod:Show(win)
	if self:IsShown(win) == false then
		win.frame:Show()
	end
end

function mod:Hide(win)
	if self:IsShown(win) == true then
		win.frame:Hide()
	end
end

function mod:Destroy(win)
	if win and win.frame then
		if win.obj then
			if win.obj.text then
				win.obj.text = " "
			end
			win.obj = nil
		end
		win.frame:Hide()
		win.frame = nil
	end
end

function mod:Wipe(win)
	win.text = " "
end

function mod:SetTitle(win, title)
end

function mod:Update(win)
	if win.obj then
		win.obj.text = ""
	end
	sortDataset(win)
	if #win.dataset > 0 then
		local data = win.dataset[1]
		if data.id then
			local label = (formatLabel(win, data) or "") .. " - " .. (formatValue(win, data) or "")

			if win.obj then
				win.obj.text = label
			end
			if win.db.useframe then
				win.frame.title:SetText(label)
			end
		end
	end
end

function mod:OnInitialize()
end

function mod:ApplySettings(win)
	if win.db.useframe then
		local title = win.frame.title
		local db = win.db

		win.frame:SetMovable(not win.db.barslocked)
		win.frame:SetHeight(win.db.height or 30)
		win.frame:SetWidth(win.db.width or 200)
		local fbackdrop = {}
		fbackdrop.bgFile = Skada:MediaFetch("background", db.background.texture)
		fbackdrop.tile = db.background.tile
		fbackdrop.tileSize = db.background.tilesize
		win.frame:SetBackdrop(fbackdrop)
		win.frame:SetBackdropColor(
			db.background.color.r,
			db.background.color.g,
			db.background.color.b,
			db.background.color.a
		)

		Skada:ApplyBorder(
			win.frame,
			db.background.bordertexture,
			db.background.bordercolor,
			db.background.borderthickness
		)

		local color = db.textcolor or {r = 1, g = 1, b = 1, a = 1}
		title:SetTextColor(color.r, color.g, color.b, color.a)
		title:SetFont(Skada:MediaFetch("font", db.barfont), db.barfontsize, db.barfontflags)
		title:SetText(win.metadata.title or "Skada")
		title:SetWordWrap(false)
		title:SetJustifyH("CENTER")
		title:SetJustifyV("MIDDLE")
		title:SetHeight(win.db.height or 30)

		win.frame:SetScale(db.scale)
		win.frame:SetFrameStrata(db.strata)

		if db.hidden and win.frame:IsShown() then
			win.frame:Hide()
		elseif not db.hidden and not win.frame:IsShown() then
			win.frame:Show()
		end
	else
		win.frame:Hide()
	end
	self:Update(win)
end

function mod:AddDisplayOptions(win, options)
	local db = win.db
	options.main = {
		type = "group",
		name = L["Data Text"],
		desc = format(L["Options for %s."], L["Data Text"]),
		order = 10,
		get = function(i)
			return db[i[#i]]
		end,
		set = function(i, val)
			db[i[#i]] = val
			Skada:ApplySettings(db.name)
		end,
		args = {
			useframe = {
				type = "toggle",
				name = L["Use frame"],
				desc = L.opt_useframe_desc,
				order = 10,
				width = "double"
			},
			barfont = {
				type = "select",
				dialogControl = "LSM30_Font",
				name = L["Font"],
				desc = format(L["The font used by %s."], L["Bars"]),
				values = Skada:MediaList("font"),
				order = 20
			},
			barfontflags = {
				type = "select",
				name = L["Font Outline"],
				desc = L["Sets the font outline."],
				values = FONT_FLAGS,
				order = 30
			},
			barfontsize = {
				type = "range",
				name = L["Font Size"],
				desc = format(L["The font size of %s."], L["Bars"]),
				min = 5,
				max = 32,
				step = 1,
				order = 40,
				width = "double"
			},
			color = {
				type = "color",
				name = L["Text Color"],
				desc = L["Choose the default color."],
				hasAlpha = true,
				get = function()
					local c = db.textcolor or Skada.windowdefaults.textcolor
					return c.r, c.g, c.b, c.a or 1
				end,
				set = function(i, r, g, b, a)
					db.textcolor = db.textcolor or {}
					db.textcolor.r, db.textcolor.g, db.textcolor.b, db.textcolor.a = r, g, b, a
					Skada:ApplySettings(db.name)
				end,
				disabled = function() return db.isusingclasscolors end,
				order = 50,
			},
			isusingclasscolors = {
				type = "toggle",
				name = L["Class Colors"],
				desc = L["When possible, bar text will be colored according to player class."],
				order = 60
			},
		}
	}

	options.window = Skada:FrameSettings(db, true)
end

function mod:OnInitialize()
	self.name = name
	self.description = L.mod_broker_desc
	Skada:AddDisplaySystem("broker", self)
end