local mod	= DBM:NewMod("DeathswornCaptain", "DBM-Party-Classic", 14)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 7007 $"):sub(12, -3))
mod:SetCreatureID(3872)

mod:RegisterCombat("combat")
