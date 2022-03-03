local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule("NamePlates")

--Lua functions
--WoW API / Variables

function NP:UpdateElement_RaidIcon(frame)
	local icon = frame.RaidIcon
	icon:ClearAllPoints()
	if frame.HealthBar:IsShown() then
		icon:SetPoint("RIGHT", frame.HealthBar, "LEFT", -6, 0)
	else
		icon:SetPoint("BOTTOM", frame.Name, "TOP", 0, 3)
	end
end