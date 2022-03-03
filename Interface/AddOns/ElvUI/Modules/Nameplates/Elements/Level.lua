local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

--Lua functions
--WoW API / Variables

function NP:UpdateElement_Level(frame)
	if not self.db.units[frame.UnitType].showLevel then return end

	local level, r, g, b = self:UnitLevel(frame)

	if self.db.units[frame.UnitType].healthbar.enable or frame.isTarget then
		frame.Level:SetText(level)
	else
		frame.Level:SetFormattedText(" [%s]", level)
	end
	frame.Level:SetTextColor(r, g, b)
end

function NP:ConfigureElement_Level(frame)
	local level = frame.Level

	level:ClearAllPoints()

	if self.db.units[frame.UnitType].healthbar.enable or (self.db.alwaysShowTargetHealth and frame.isTarget) then
		level:SetJustifyH("RIGHT")
		level:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", 0, E.Border*2)
	else
		level:SetPoint("LEFT", frame.Name, "RIGHT")
		level:SetJustifyH("LEFT")
	end
	level:SetFont(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
end

function NP:ConstructElement_Level(frame)
	local level = frame:CreateFontString(nil, "OVERLAY")
	level:SetFont(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
	return level
end