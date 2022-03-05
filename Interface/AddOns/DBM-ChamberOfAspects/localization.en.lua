local L

----------------------------
--  The Obsidian Sanctum  --
----------------------------
--  Shadron  --
---------------
L = DBM:GetModLocalization("Shadron")

L:SetGeneralLocalization({
	name = "Shadron"
})

----------------
--  Tenebron  --
----------------
L = DBM:GetModLocalization("Tenebron")

L:SetGeneralLocalization({
	name = "Tenebron"
})

----------------
--  Vesperon  --
----------------
L = DBM:GetModLocalization("Vesperon")

L:SetGeneralLocalization({
	name = "Vesperon"
})

------------------
--  Sartharion  --
------------------
L = DBM:GetModLocalization("Sartharion")

L:SetGeneralLocalization({
	name = "Sartharion"
})

L:SetWarningLocalization({
	WarningTenebron			= "Tenebron incoming",
	WarningShadron			= "Shadron incoming",
	WarningVesperon			= "Vesperon incoming",
	WarningFireWall			= "Fire Wall",
	WarningWhelpsSoon		= "Tenebron Whelps Soon",
	WarningPortalSoon		= "Shadron Portal Soon",
	WarningReflectSoon		= "Vesperon Reflect Soon",
	WarningVesperonPortal	= "Vesperon's portal",
	WarningTenebronPortal	= "Tenebron's portal",
	WarningShadronPortal	= "Shadron's portal"
})

L:SetTimerLocalization({
	TimerTenebron			= "Tenebron arrives",
	TimerShadron			= "Shadron arrives",
	TimerVesperon			= "Vesperon arrives",
	TimerTenebronWhelps		= "Tenebron Whelps",
	TimerShadronPortal		= "Shadron Portal",
	TimerVesperonPortal		= "Vesperon Portal",
	TimerVesperonPortal2	= "Vesperon Portal 2"
})

L:SetOptionLocalization({
	AnnounceFails			= "Post player fails for Fire Wall and Shadow Fissure to raid chat<br/>(requires announce to be enabled and leader/promoted status)",
	TimerTenebron			= "Show timer for Tenebron's arrival",
	TimerShadron			= "Show timer for Shadron's arrival",
	TimerVesperon			= "Show timer for Vesperon's arrival",
	TimerTenebronWhelps		= "Show timer for Tenebron Whelps",
	TimerShadronPortal		= "Show timer for Shadron Portal",
	TimerVesperonPortal		= "Show timer for Vesperon Portal",
	TimerVesperonPortal2	= "Show timer for Vesperon Portal 2",
	WarningFireWall			= "Show special warning for Fire Wall",
	WarningTenebron			= "Announce Tenebron incoming",
	WarningShadron			= "Announce Shadron incoming",
	WarningVesperon			= "Announce Vesperon incoming",
	WarningWhelpsSoon		= "Announce Tenebron Whelps soon",
	WarningPortalSoon		= "Announce Shadron Portal soon",
	WarningReflectSoon		= "Announce Vesperon Reflect soon",
	WarningTenebronPortal	= "Show special warning for Tenebron's portal",
	WarningShadronPortal	= "Show special warning for Shadron's portal",
	WarningVesperonPortal	= "Show special warning for Vesperon's portal"
})

L:SetMiscLocalization({
	Wall			= "The lava surrounding %s churns!",
	Portal			= "%s begins to open a Twilight Portal!",
	NameTenebron	= "Tenebron",
	NameShadron		= "Shadron",
	NameVesperon	= "Vesperon",
	FireWallOn		= "Fire Wall: %s",
	VoidZoneOn		= "Shadow Fissure: %s",
	VoidZones		= "Shadow Fissure fails (this try): %s",
	FireWalls		= "Fire Wall fails (this try): %s"
})

------------------------
--  The Ruby Sanctum  --
------------------------
--  Baltharus the Warborn  --
-----------------------------
L = DBM:GetModLocalization("Baltharus")

L:SetGeneralLocalization({
	name = "Baltharus the Warborn"
})

L:SetWarningLocalization({
	WarningSplitSoon	= "Split soon"
})

L:SetOptionLocalization({
	WarningSplitSoon	= "Show pre-warning for Split",
	RangeFrame			= "Show range frame (12 yards)",
	SetIconOnBrand		= DBM_CORE_L.AUTO_ICONS_OPTION_TEXT:format(74505)
})

-------------------------
--  Saviana Ragefire  --
-------------------------
L = DBM:GetModLocalization("Saviana")

L:SetGeneralLocalization({
	name = "Saviana Ragefire"
})

L:SetOptionLocalization({
	RangeFrame				= "Show range frame (10 yards)",
	beaconIcon				= DBM_CORE_L.AUTO_ICONS_OPTION_TEXT:format(74453)
})

--------------------------
--  General Zarithrian  --
--------------------------
L = DBM:GetModLocalization("Zarithrian")

L:SetGeneralLocalization({
	name = "General Zarithrian"
})

L:SetWarningLocalization({
	WarnAdds	= "New adds",
	warnCleaveArmor	= "%s on >%s< (%s)"		-- Cleave Armor on >args.destName< (args.amount)
})

L:SetTimerLocalization({
	TimerAdds	= "New adds",
	AddsArrive	= "Adds arrive in"
})

L:SetOptionLocalization({
	WarnAdds		= "Announce new adds",
	TimerAdds		= "Show timer for new adds",
	AddsArrive		= "Show timer for adds arrival",
	CancelBuff		= "Remove $spell:10278 and $spell:642 if used to remove $spell:74367",
	warnCleaveArmor	= DBM_CORE_L.AUTO_ANNOUNCE_OPTIONS.spell:format(74367)
})

L:SetMiscLocalization({
	SummonMinions	= "Turn them to ash, minions!"
})

-------------------------------------
--  Halion the Twilight Destroyer  --
-------------------------------------
L = DBM:GetModLocalization("Halion")

L:SetGeneralLocalization({
	name = "Halion the Twilight Destroyer"
})

L:SetWarningLocalization({
	TwilightCutterCast	= "Casting Twilight Cutter: 5 sec"
})

L:SetOptionLocalization({
	TwilightCutterCast		= "Show warning when $spell:74769 is being cast",
	AnnounceAlternatePhase	= "Show warnings/timers for phase you aren't in as well",
	SetIconOnConsumption	= "Set icons on $spell:74562 or $spell:74792 targets"--So we can use single functions for both versions of spell.
})

L:SetMiscLocalization({
	Halion					= "Halion",
	MeteorCast				= "The heavens burn!",
	Phase2					= "You will find only suffering within the realm of twilight! Enter if you dare!",
	Phase3					= "I am the light and the darkness! Cower, mortals, before the herald of Deathwing!",
	twilightcutter			= "Beware the shadow!", --"The orbiting spheres pulse with dark energy!". Can't use this since on Warmane it triggers twice, 5s prior and on cutter.
	Kill					= "Relish this victory, mortals, for it will be your last. This world will burn with the master's return!"
})
