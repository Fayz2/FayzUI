local Skada = Skada

local pairs, format, max = pairs, string.format, math.max
local GetSpellInfo, cacheTable, T = Skada.GetSpellInfo, Skada.cacheTable, Skada.Table
local PercentToRGB = Skada.PercentToRGB
local _

-- ================== --
-- Damage Done Module --
-- ================== --

Skada:AddLoadableModule("Damage", function(L)
	if Skada:IsDisabled("Damage") then return end

	local mod = Skada:NewModule(L["Damage"])
	local playermod = mod:NewModule(L["Damage spell list"])
	local spellmod = playermod:NewModule(L["Damage spell details"])
	local sdetailmod = playermod:NewModule(L["Damage Breakdown"])
	local targetmod = mod:NewModule(L["Damage target list"])
	local tdetailmod = targetmod:NewModule(L["Damage spell list"])
	local UnitGUID, GetTime = UnitGUID, GetTime
	local new, del = Skada.newTable, Skada.delTable
	local spellschools = Skada.spellschools
	local ignoredSpells = Skada.dummyTable -- Edit Skada\Core\Tables.lua

	-- damage miss types
	local missTypes = Skada.missTypes
	if not missTypes then
		missTypes = {"ABSORB", "BLOCK", "DEFLECT", "DODGE", "EVADE", "IMMUNE", "MISS", "PARRY", "REFLECT", "RESIST"}
		Skada.missTypes = missTypes
	end

	-- spells on the list below are ignored when it comes
	-- to updating player's active time.
	local blacklist = {
		[7294] = true, -- Retribution Aura (Rank 1)
		[10298] = true, -- Retribution Aura (Rank 2)
		[10299] = true, -- Retribution Aura (Rank 3)
		[10300] = true, -- Retribution Aura (Rank 4)
		[10301] = true, -- Retribution Aura (Rank 5)
		[27150] = true, -- Retribution Aura (Rank 6)
		[54043] = true, -- Retribution Aura (Rank 7)
		[30482] = true, -- Molten Armor (Rank 1)
		[34913] = true, -- Molten Armor (Rank 1)
		[43043] = true, -- Molten Armor (Rank 2)
		[43044] = true, -- Molten Armor (Rank 3)
		[43045] = true, -- Molten Armor (Rank 2)
		[43046] = true, -- Molten Armor (Rank 3)
		[324] = true, -- Lightning Shield (Rank 1)
		[325] = true, -- Lightning Shield (Rank 2)
		[905] = true, -- Lightning Shield (Rank 3)
		[945] = true, -- Lightning Shield (Rank 4)
		[8134] = true, -- Lightning Shield (Rank 5)
		[10431] = true, -- Lightning Shield (Rank 6)
		[10432] = true, -- Lightning Shield (Rank 7)
		[25469] = true, -- Lightning Shield (Rank 8)
		[25472] = true, -- Lightning Shield (Rank 9)
		[49280] = true, -- Lightning Shield (Rank 10)
		[49281] = true, -- Lightning Shield (Rank 11)
		[2947] = true, -- Fire Shield (Rank 1)
		[8316] = true, -- Fire Shield (Rank 2)
		[8317] = true, -- Fire Shield (Rank 3)
		[11770] = true, -- Fire Shield (Rank 4)
		[11771] = true, -- Fire Shield (Rank 5)
		[27269] = true, -- Fire Shield (Rank 6)
		[47983] = true -- Fire Shield (Rank 7)
	}

	-- spells on the list below are used to update player's active time
	-- no matter their role or damage amount, since pets aren't considered.
	local whitelist = {
		-- The Oculus
		[49840] = true, -- Shock Lance (Amber Drake)
		[50232] = true, -- Searing Wrath (Ruby Drake)
		[50341] = true, -- Touch the Nightmare (Emerald Drake)
		[50344] = true, -- Dream Funnel (Emerald Drake)
		-- Eye of Eternity: Wyrmrest Skytalon
		[56091] = true, -- Flame Spike
		[56092] = true, -- Engulf in Flames
		-- Naxxramas: Instructor Razuvious
		[61696] = true, -- Blood Strike (Death Knight Understudy)
		-- Ulduar - Flame Leviathan
		[62306] = true, -- Salvaged Demolisher: Hurl Boulder
		[62308] = true, -- Salvaged Demolisher: Ram
		[62490] = true, -- Salvaged Demolisher: Hurl Pyrite Barrel
		[62634] = true, -- Salvaged Demolisher Mechanic Seat: Mortar
		[64979] = true, -- Salvaged Demolisher Mechanic Seat: Anti-Air Rocket
		[62345] = true, -- Salvaged Siege Engine: Ram
		[62346] = true, -- Salvaged Siege Engine: Steam Rush
		[62522] = true, -- Salvaged Siege Engine: Electroshock
		[62358] = true, -- Salvaged Siege Turret: Fire Cannon
		[62359] = true, -- Salvaged Siege Turret: Anti-Air Rocket
		[62974] = true, -- Salvaged Chopper: Sonic Horn
		-- Icecrown Citadel
		[69399] = true, -- Cannon Blast (Gunship Battle Cannons)
		[70175] = true, -- Incinerating Blast (Gunship Battle Cannons)
		[70539] = 5.5, -- Regurgitated Ooze (Mutated Abomination)
		[70542] = true -- Mutated Slash (Mutated Abomination)
	}

	local function log_spellcast(set, playerid, playername, playerflags, spellname, spellschool)
		if not set or (set == Skada.total and not Skada.db.profile.totalidc) then return end

		local player = Skada:GetPlayer(set, playerid, playername, playerflags)
		if player and player.damagespells then
			local spell = player.damagespells[spellname] or player.damagespells[spellname..L["DoT"]]
			if spell then
				-- because some DoTs don't have an initial damage
				-- we start from 1 and not from 0 if casts wasn't
				-- previously set. Otherwise we just increment.
				spell.casts = (spell.casts or 1) + 1

				-- fix possible missing spell school.
				if not spell.school and spellschool then
					spell.school = spellschool
				end
			end
		end
	end

	local function log_damage(set, dmg, tick)
		local player = Skada:GetPlayer(set, dmg.playerid, dmg.playername, dmg.playerflags)
		if not player then return end

		-- update activity
		if whitelist[dmg.spellid] ~= nil then
			Skada:AddActiveTime(player, (dmg.amount > 0), tonumber(whitelist[dmg.spellid]))
		elseif player.role ~= "HEALER" and not dmg.petname then
			Skada:AddActiveTime(player, (dmg.amount > 0 and not blacklist[dmg.spellid]))
		end

		-- add absorbed damage to total damage
		local absorbed = dmg.absorbed or 0

		player.damage = (player.damage or 0) + dmg.amount
		player.totaldamage = (player.totaldamage or 0) + dmg.amount + absorbed

		set.damage = (set.damage or 0) + dmg.amount
		set.totaldamage = (set.totaldamage or 0) + dmg.amount + absorbed

		-- add the damage overkill
		if (dmg.overkill or 0) > 0 then
			set.overkill = (set.overkill or 0) + dmg.overkill
			player.overkill = (player.overkill or 0) + dmg.overkill
		end

		-- saving this to total set may become a memory hog deluxe.
		if set == Skada.total and not Skada.db.profile.totalidc then return end

		-- spell
		local spellname = dmg.spellname .. (tick and L["DoT"] or "")
		local spell = player.damagespells and player.damagespells[spellname]
		if not spell then
			player.damagespells = player.damagespells or {}
			spell = {id = dmg.spellid, school = dmg.spellschool, amount = 0, total = 0}
			player.damagespells[spellname] = spell
		elseif dmg.spellid and dmg.spellid ~= spell.id then
			if dmg.spellschool and dmg.spellschool ~= spell.school then
				spellname = spellname .. " (" .. (spellschools[dmg.spellschool] and spellschools[dmg.spellschool].name or OTHER) .. ")"
			else
				spellname = GetSpellInfo(dmg.spellid)
			end
			if not player.damagespells[spellname] then
				player.damagespells[spellname] = {id = dmg.spellid, school = dmg.spellschool, amount = 0, total = 0}
			end
			spell = player.damagespells[spellname]
		elseif not spell.school and dmg.spellschool then
			spell.school = dmg.spellschool
		end

		-- start casts count for non DoTs.
		if dmg.spellid ~= 6603 and not tick then
			spell.casts = spell.casts or 1
		end

		spell.count = (spell.count or 0) + 1
		spell.amount = spell.amount + dmg.amount
		spell.total = spell.total + dmg.amount

		if (dmg.overkill or 0) > 0 then
			spell.overkill = (spell.overkill or 0) + dmg.overkill
		end

		if dmg.critical then
			spell.critical = (spell.critical or 0) + 1
			spell.criticalamount = (spell.criticalamount or 0) + dmg.amount

			if not spell.criticalmax or dmg.amount > spell.criticalmax then
				spell.criticalmax = dmg.amount
			end

			if not spell.criticalmin or dmg.amount < spell.criticalmin then
				spell.criticalmin = dmg.amount
			end
		elseif dmg.misstype ~= nil then
			spell[dmg.misstype] = (spell[dmg.misstype] or 0) + 1
		elseif dmg.glancing then
			spell.glancing = (spell.glancing or 0) + 1
		else
			spell.hit = (spell.hit or 0) + 1
			spell.hitamount = (spell.hitamount or 0) + dmg.amount
			if not spell.hitmax or dmg.amount > spell.hitmax then
				spell.hitmax = dmg.amount
			end
			if not spell.hitmin or dmg.amount < spell.hitmin then
				spell.hitmin = dmg.amount
			end
		end

		if (dmg.blocked or 0) > 0 then
			spell.blocked = (spell.blocked or 0) + dmg.blocked
		end

		if (dmg.resisted or 0) > 0 then
			spell.resisted = (spell.resisted or 0) + dmg.resisted
		end

		-- target
		if dmg.dstName then
			local target = spell.targets and spell.targets[dmg.dstName]
			if not target then
				spell.targets = spell.targets or {}
				spell.targets[dmg.dstName] = {amount = 0, total = 0}
				target = spell.targets[dmg.dstName]
			end
			target.amount = target.amount + dmg.amount
			target.total = target.total + dmg.amount + absorbed
			if (dmg.overkill or 0) > 0 then
				target.overkill = (target.overkill or 0) + dmg.overkill
			end
		end
	end

	local dmg = {}
	local extraATT

	local function SpellCast(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		if srcGUID and dstGUID then
			local spellid, spellname, spellschool = ...
			if spellid and spellname and not ignoredSpells[spellid] then
				srcGUID, srcName = Skada:FixMyPets(srcGUID, srcName, srcFlags)
				Skada:DispatchSets(log_spellcast, srcGUID, srcName, srcFlags, spellname, spellschool)
			end
		end
	end

	local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		if srcGUID ~= dstGUID then
			-- handle extra attacks
			if eventtype == "SPELL_EXTRA_ATTACKS" then
				local spellid, spellname, _, amount = ...

				if spellid and spellname and not ignoredSpells[spellid] then
					extraATT = extraATT or T.get("Damage_ExtraAttacks")
					if not extraATT[srcName] then
						extraATT[srcName] = new()
						extraATT[srcName].proc = spellname
						extraATT[srcName].count = amount
						extraATT[srcName].time = GetTime()
					end
				end

				return
			end

			if eventtype == "SWING_DAMAGE" then
				dmg.spellid, dmg.spellname, dmg.spellschool = 6603, L["Melee"], 0x01
				dmg.amount, dmg.overkill, _, dmg.resisted, dmg.blocked, dmg.absorbed, dmg.critical, dmg.glancing = ...

				-- an extra attack?
				if extraATT and extraATT[srcName] then
					if not extraATT[srcName].spellname then -- queue spell
						extraATT[srcName].spellname = dmg.spellname
					elseif dmg.spellname == L["Melee"] and extraATT[srcName].time < (GetTime() - 5) then -- expired proc
						extraATT[srcName] = del(extraATT[srcName])
					elseif dmg.spellname == L["Melee"] then -- valid damage contribution
						dmg.spellname = extraATT[srcName].spellname .. " (" .. extraATT[srcName].proc .. ")"
						extraATT[srcName].count = max(0, extraATT[srcName].count - 1)
						if extraATT[srcName].count == 0 then -- no procs left
							extraATT[srcName] = del(extraATT[srcName])
						end
					end
				end
			else
				dmg.spellid, dmg.spellname, dmg.spellschool, dmg.amount, dmg.overkill, _, dmg.resisted, dmg.blocked, dmg.absorbed, dmg.critical, dmg.glancing = ...
			end

			if dmg.spellid and dmg.spellname and not ignoredSpells[dmg.spellid] then
				dmg.playerid = srcGUID
				dmg.playername = srcName
				dmg.playerflags = srcFlags

				dmg.dstGUID = dstGUID
				dmg.dstName = dstName
				dmg.dstFlags = dstFlags

				dmg.misstype = nil
				dmg.petname = nil
				Skada:FixPets(dmg)

				Skada:DispatchSets(log_damage, dmg, eventtype == "SPELL_PERIODIC_DAMAGE")
			end
		end
	end

	local function SpellMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
		if srcGUID ~= dstGUID then
			local amount

			if eventtype == "SWING_MISSED" then
				dmg.spellid, dmg.spellname, dmg.spellschool = 6603, L["Melee"], 0x01
				dmg.misstype, amount = ...
			else
				dmg.spellid, dmg.spellname, dmg.spellschool, dmg.misstype, amount = ...
			end

			if dmg.spellid and dmg.spellname and not ignoredSpells[dmg.spellid] then
				dmg.playerid = srcGUID
				dmg.playername = srcName
				dmg.playerflags = srcFlags

				dmg.dstGUID = dstGUID
				dmg.dstName = dstName
				dmg.dstFlags = dstFlags

				dmg.amount = 0
				dmg.overkill = 0
				dmg.resisted = nil
				dmg.blocked = nil
				dmg.absorbed = nil
				dmg.critical = nil
				dmg.glancing = nil

				if dmg.misstype == "ABSORB" then
					dmg.absorbed = amount or 0
				elseif dmg.misstype == "BLOCK" then
					dmg.blocked = amount or 0
				elseif dmg.misstype == "RESIST" then
					dmg.resisted = amount or 0
				end

				dmg.petname = nil
				Skada:FixPets(dmg)

				Skada:DispatchSets(log_damage, dmg, eventtype == "SPELL_PERIODIC_MISSED")
			end
		end
	end

	local function damage_tooltip(win, id, label, tooltip)
		local set = win:GetSelectedSet()
		local actor = set and set:GetActor(label, id)
		if actor then
			local totaltime = set:GetTime()
			local activetime = actor:GetTime(true)
			local dps, damage = actor:GetDPS()

			tooltip:AddDoubleLine(L["Activity"], Skada:FormatPercent(activetime, totaltime), nil, nil, nil, 1, 1, 1)
			tooltip:AddDoubleLine(L["Segment Time"], Skada:FormatTime(totaltime), 1, 1, 1)
			tooltip:AddDoubleLine(L["Active Time"], Skada:FormatTime(activetime), 1, 1, 1)
			tooltip:AddDoubleLine(L["Damage Done"], Skada:FormatNumber(damage), 1, 1, 1)

			local suffix = Skada:FormatTime(Skada.db.profile.timemesure == 1 and activetime or totaltime)
			tooltip:AddDoubleLine(Skada:FormatNumber(damage) .. "/" .. suffix, Skada:FormatNumber(dps), 1, 1, 1)
		end
	end

	local function playermod_tooltip(win, id, label, tooltip)
		local set = win:GetSelectedSet()
		if not set then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local spell = actor and actor.damagespells and actor.damagespells[enemy and id or label]
		if spell then
			tooltip:AddLine(actor.name .. " - " .. label)
			if spell.school and spellschools[spell.school] then
				tooltip:AddLine(spellschools(spell.school))
			end

			if spell.casts then
				tooltip:AddDoubleLine(L["Casts"], spell.casts, 1, 1, 1)
			end

			-- show the aura uptime in case of a debuff.
			if actor.GetAuraUptime then
				local uptime, activetime = actor:GetAuraUptime(spell.id)
				if (uptime or 0) > 0 then
					uptime = 100 * (uptime / activetime)
					tooltip:AddDoubleLine(L["Uptime"], Skada:FormatPercent(uptime), nil, nil, nil, PercentToRGB(uptime))
				end
			end

			local separator = nil

			if spell.hitmin then
				tooltip:AddLine(" ")
				separator = true

				local spellmin = spell.hitmin
				if spell.criticalmin and spell.criticalmin < spellmin then
					spellmin = spell.criticalmin
				end
				tooltip:AddDoubleLine(L["Minimum"], Skada:FormatNumber(spellmin), 1, 1, 1)
			end

			if (spell.count or 0) > 1 then
				if not separator then
					tooltip:AddLine(" ")
					separator = true
				end

				local amount = Skada.db.profile.absdamage and spell.total or spell.amount
				tooltip:AddDoubleLine(L["Average"], Skada:FormatNumber(amount / spell.count), 1, 1, 1)
			end

			if spell.hitmax then
				if not separator then
					tooltip:AddLine(" ")
					separator = true
				end

				local spellmax = spell.hitmax
				if spell.criticalmax and spell.criticalmax > spellmax then
					spellmax = spell.criticalmax
				end
				tooltip:AddDoubleLine(L["Maximum"], Skada:FormatNumber(spellmax), 1, 1, 1)
			end
		end
	end

	local function spellmod_tooltip(win, id, label, tooltip)
		if label == L["Critical Hits"] or label == L["Normal Hits"] then
			local set = win:GetSelectedSet()
			local actor = set and set:GetPlayer(win.actorid, win.actorname)
			local spell = actor.damagespells and actor.damagespells[win.spellname]
			if spell then
				tooltip:AddLine(actor.name .. " - " .. win.spellname)
				if spell.school and spellschools[spell.school] then
					tooltip:AddLine(spellschools(spell.school))
				end

				if label == L["Critical Hits"] and spell.criticalamount then
					if spell.criticalmin then
						tooltip:AddDoubleLine(L["Minimum"], Skada:FormatNumber(spell.criticalmin), 1, 1, 1)
					end
					tooltip:AddDoubleLine(L["Average"], Skada:FormatNumber(spell.criticalamount / spell.critical), 1, 1, 1)
					if spell.criticalmax then
						tooltip:AddDoubleLine(L["Maximum"], Skada:FormatNumber(spell.criticalmax), 1, 1, 1)
					end
				elseif label == L["Normal Hits"] and spell.hitamount then
					if spell.hitmin then
						tooltip:AddDoubleLine(L["Minimum"], Skada:FormatNumber(spell.hitmin), 1, 1, 1)
					end
					tooltip:AddDoubleLine(L["Average"], Skada:FormatNumber(spell.hitamount / spell.hit), 1, 1, 1)
					if spell.hitmax then
						tooltip:AddDoubleLine(L["Maximum"], Skada:FormatNumber(spell.hitmax), 1, 1, 1)
					end
				end
			end
		end
	end

	function playermod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = L["actor damage"](label)
	end

	function playermod:Update(win, set)
		win.title = L["actor damage"](win.actorname or L["Unknown"])
		if not set or not win.actorname then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local total = actor and actor:GetDamage() or 0


		if total > 0 and actor.damagespells then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for spellname, spell in pairs(actor.damagespells) do
				nr = nr + 1
				local d = win:nr(nr)

				d.id = spellname
				d.spellschool = spell.school

				if enemy then
					d.spellid = spellname
					d.label, _, d.icon = GetSpellInfo(spellname)
				else
					d.spellid = spell.id
					d.label = spellname
					_, _, d.icon = GetSpellInfo(spell.id)
				end

				d.value = Skada.db.profile.absdamage and spell.total or spell.amount
				d.valuetext = Skada:FormatValueCols(
					mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
					actortime and Skada:FormatNumber(d.value / actortime),
					mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
				)

				if win.metadata and d.value > win.metadata.maxvalue then
					win.metadata.maxvalue = d.value
				end
			end
		end
	end

	function targetmod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = format(L["%s's targets"], label)
	end

	function targetmod:Update(win, set)
		win.title = format(L["%s's targets"], win.actorname or L["Unknown"])

		local actor = set and set:GetActor(win.actorname, win.actorid)
		if not actor then return end

		local total = actor:GetDamage()
		local targets = (total > 0) and actor:GetDamageTargets()

		if targets then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for targetname, target in pairs(targets) do
				nr = nr + 1
				local d = win:nr(nr)

				d.id = target.id or targetname
				d.label = targetname
				d.class = target.class
				d.role = target.role
				d.spec = target.spec

				d.value = Skada.db.profile.absdamage and target.total or target.amount
				d.valuetext = Skada:FormatValueCols(
					mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
					actortime and Skada:FormatNumber(d.value / actortime),
					mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
				)

				if win.metadata and d.value > win.metadata.maxvalue then
					win.metadata.maxvalue = d.value
				end
			end
		end
	end

	local function add_detail_bar(win, nr, title, value, total, percent, fmt)
		nr = nr + 1
		local d = win:nr(nr)

		d.id = title
		d.label = title
		d.value = value
		d.valuetext = Skada:FormatValueCols(
			mod.metadata.columns.Damage and (fmt and Skada:FormatNumber(value) or value),
			(mod.metadata.columns.sPercent and percent) and Skada:FormatPercent(d.value, total)
		)
		return nr
	end

	function spellmod:Enter(win, id, label)
		win.spellid, win.spellname = id, label
		win.title = format("%s: %s", win.actorname or L["Unknown"], format(L["%s's damage breakdown"], label))
	end

	function spellmod:Update(win, set)
		win.title = format("%s: %s", win.actorname or L["Unknown"], format(L["%s's damage breakdown"], win.spellname or L["Unknown"]))
		if not set or not win.spellname then return end

		-- details only available for players
		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local spell = actor and actor.damagespells and actor.damagespells[enemy and win.spellid or win.spellname]
		if spell then
			if win.metadata then
				if enemy then
					win.metadata.maxvalue = Skada.db.profile.absdamage and spell.total or spell.amount or 0
				else
					win.metadata.maxvalue = spell.count
				end
			end

			if enemy then
				local amount = Skada.db.profile.absdamage and spell.total or spell.amount
				local nr = add_detail_bar(win, 0, L["Damage"], amount, nil, nil, true)

				if spell.total ~= spell.amount then
					nr = add_detail_bar(win, nr, L["ABSORB"], spell.total - spell.amount, nil, nil, true)
				end
			else
				local nr = add_detail_bar(win, 0, L["Hits"], spell.count)
				win.dataset[nr].value = win.dataset[nr].value + 1 -- to be always first

				if (spell.casts or 0) > 0 then
					nr = add_detail_bar(win, nr, L["Casts"], spell.casts)
					win.dataset[nr].value = win.dataset[nr].value * 1e3 -- to be always first
				end

				if (spell.hit or 0) > 0 then
					nr = add_detail_bar(win, nr, L["Normal Hits"], spell.hit, spell.count, true)
				end

				if (spell.critical or 0) > 0 then
					nr = add_detail_bar(win, nr, L["Critical Hits"], spell.critical, spell.count, true)
				end

				if (spell.glancing or 0) > 0 then
					nr = add_detail_bar(win, nr, L["Glancing"], spell.glancing, spell.count, true)
				end

				for i = 1, #missTypes do
					local misstype = missTypes[i]
					if misstype and spell[misstype] then
						nr = add_detail_bar(win, nr, L[misstype], spell[misstype], spell.count, true)
					end
				end
			end
		end
	end

	function sdetailmod:Enter(win, id, label)
		win.spellid, win.spellname = id, label
		win.title = format(L["%s's <%s> damage"], win.actorname or L["Unknown"], label)
	end

	function sdetailmod:Update(win, set)
		win.title = format(L["%s's <%s> damage"], win.actorname or L["Unknown"], win.spellname or L["Unknown"])
		if not win.spellname then return end

		-- only available for players
		local actor = set and set:GetPlayer(win.actorid, win.actorname)
		local spell = actor and actor.damagespells and actor.damagespells[win.spellname]
		if spell then
			local absorbed = max(0, spell.total - spell.amount)
			local blocked = spell.blocked or 0
			local resisted = spell.resisted or 0
			local total = spell.amount + absorbed + blocked + resisted
			if win.metadata then
				win.metadata.maxvalue = total
			end

			local nr = add_detail_bar(win, 0, L["Total"], total, nil, nil, true)
			win.dataset[nr].value = win.dataset[nr].value + 1 -- to be always first

			if total ~= spell.amount then
				nr = add_detail_bar(win, nr, L["Damage"], spell.amount, total, true, true)
			end

			if (spell.overkill or 0) > 0 then
				nr = add_detail_bar(win, nr, L["Overkill"], spell.overkill, total, true, true)
			end

			if absorbed > 0 then
				nr = add_detail_bar(win, nr, L["ABSORB"], absorbed, total, true, true)
			end

			if blocked > 0 then
				nr = add_detail_bar(win, nr, L["BLOCK"], blocked, total, true, true)
			end

			if resisted > 0 then
				nr = add_detail_bar(win, nr, L["RESIST"], resisted, total, true, true)
			end
		end
	end

	function tdetailmod:Enter(win, id, label)
		win.targetid, win.targetname = id, label
		win.title = L["actor damage"](win.actorname or L["Unknown"], label)
	end

	function tdetailmod:Update(win, set)
		win.title = L["actor damage"](win.actorname or L["Unknown"], win.targetname or L["Unknown"])
		if not set or not win.targetname then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local targets = actor and actor:GetDamageTargets()
		if targets then
			local total = targets[win.targetname] and targets[win.targetname].amount or 0
			if Skada.db.profile.absdamage and targets[win.targetname].total then
				total = targets[win.targetname].total
			end

			if total > 0 and actor.damagespells then
				if win.metadata then
					win.metadata.maxvalue = 0
				end

				local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
				for spellname, spell in pairs(actor.damagespells) do
					if spell.targets and spell.targets[win.targetname] then
						nr = nr + 1
						local d = win:nr(nr)

						if enemy then
							d.spellid = spellname
							d.label, _, d.icon = GetSpellInfo(spellname)
							d.id = d.label
						else
							d.id = spellname
							d.spellid = spell.id
							d.label = spellname
							_, _, d.icon = GetSpellInfo(spell.id)
						end

						d.spellschool = spell.school

						d.value = spell.targets[win.targetname].amount
						if Skada.db.profile.absdamage then
							d.value = spell.targets[win.targetname].total or d.value
						end

						d.valuetext = Skada:FormatValueCols(
							mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
							actortime and Skada:FormatNumber(d.value / actortime),
							mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
						)

						if win.metadata and d.value > win.metadata.maxvalue then
							win.metadata.maxvalue = d.value
						end
					end
				end
			end
		end
	end

	function mod:Update(win, set)
		win.title = win.class and format("%s (%s)", L["Damage"], L[win.class]) or L["Damage"]

		local total = set and set:GetDamage() or 0

		if total > 0 then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local nr = 0

			-- players
			for i = 1, #set.players do
				local player = set.players[i]
				if player and (not win.class or win.class == player.class) then
					local dps, amount = player:GetDPS()
					if amount > 0 then
						nr = nr + 1
						local d = win:nr(nr)

						d.id = player.id or player.name
						d.label = player.name
						d.text = player.id and Skada:FormatName(player.name, player.id)
						d.class = player.class
						d.role = player.role
						d.spec = player.spec

						if Skada.forPVP and set.type == "arena" then
							d.color = Skada.classcolors(set.gold and "ARENA_GOLD" or "ARENA_GREEN")
						end

						d.value = amount
						d.valuetext = Skada:FormatValueCols(
							self.metadata.columns.Damage and Skada:FormatNumber(d.value),
							self.metadata.columns.DPS and Skada:FormatNumber(dps),
							self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
						)

						if win.metadata and d.value > win.metadata.maxvalue then
							win.metadata.maxvalue = d.value
						end
					end
				end
			end

			-- arena enemies
			if Skada.forPVP and set.type == "arena" and set.enemies then
				for i = 1, #set.enemies do
					local enemy = set.enemies[i]
					if enemy and not enemy.fake and (not win.class or win.class == enemy.class) then
						local dps, amount = enemy:GetDPS()
						if amount > 0 then
							nr = nr + 1
							local d = win:nr(nr)

							d.id = enemy.id or enemy.name
							d.label = enemy.name
							d.text = nil
							d.class = enemy.class
							d.role = enemy.role
							d.spec = enemy.spec
							d.color = Skada.classcolors(set.gold and "ARENA_GREEN" or "ARENA_GOLD")

							d.value = amount
							d.valuetext = Skada:FormatValueCols(
								self.metadata.columns.Damage and Skada:FormatNumber(d.value),
								self.metadata.columns.DPS and Skada:FormatNumber(dps),
								self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
							)

							if win.metadata and d.value > win.metadata.maxvalue then
								win.metadata.maxvalue = d.value
							end
						end
					end
				end
			end
		end
	end

	local function feed_personal_dps()
		local set = Skada:GetSet("current")
		local actor = set and set:GetPlayer(Skada.userGUID, Skada.userName)
		return format("%s %s", Skada:FormatNumber(actor and actor:GetDPS() or 0), L["DPS"])
	end

	local function feed_raid_dps()
		local set = Skada:GetSet("current")
		return format("%s %s", Skada:FormatNumber(set and set:GetDPS() or 0), L["DPS"])
	end

	function mod:OnEnable()
		spellmod.metadata = {tooltip = spellmod_tooltip}
		playermod.metadata = {click1 = spellmod, click2 = sdetailmod, post_tooltip = playermod_tooltip}
		targetmod.metadata = {click1 = tdetailmod}
		self.metadata = {
			showspots = true,
			post_tooltip = damage_tooltip,
			click1 = playermod,
			click2 = targetmod,
			click4 = Skada.FilterClass,
			click4_label = L["Toggle Class Filter"],
			columns = {Damage = true, DPS = true, Percent = true, sDPS = false, sPercent = true},
			icon = [[Interface\Icons\spell_fire_firebolt]]
		}

		-- no total click.
		playermod.nototal = true
		targetmod.nototal = true

		local compare = Skada:GetModule(L["Comparison"], true)
		if compare then
			self.metadata.click3 = compare.SetActor
			self.metadata.click3_label = L["Damage Comparison"]
			compare.nototal = true -- no total click.
		end

		local flags_src_dst = {src_is_interesting = true, dst_is_not_interesting = true}

		Skada:RegisterForCL(
			SpellCast,
			"SPELL_CAST_START",
			"SPELL_CAST_SUCCESS",
			flags_src_dst
		)

		Skada:RegisterForCL(
			SpellDamage,
			"DAMAGE_SHIELD",
			"DAMAGE_SPLIT",
			"RANGE_DAMAGE",
			"SPELL_BUILDING_DAMAGE",
			"SPELL_DAMAGE",
			"SPELL_EXTRA_ATTACKS",
			"SPELL_PERIODIC_DAMAGE",
			"SWING_DAMAGE",
			flags_src_dst
		)

		Skada:RegisterForCL(
			SpellMissed,
			"DAMAGE_SHIELD_MISSED",
			"RANGE_MISSED",
			"SPELL_BUILDING_MISSED",
			"SPELL_MISSED",
			"SPELL_PERIODIC_MISSED",
			"SWING_MISSED",
			flags_src_dst
		)

		Skada:AddFeed(L["Damage: Personal DPS"], feed_personal_dps)
		Skada:AddFeed(L["Damage: Raid DPS"], feed_raid_dps)
		Skada:AddMode(self, L["Damage Done"])

		-- table of ignored spells:
		if Skada.ignoredSpells and Skada.ignoredSpells.damage then
			ignoredSpells = Skada.ignoredSpells.damage
		end
	end

	function mod:OnDisable()
		Skada:RemoveFeed(L["Damage: Personal DPS"])
		Skada:RemoveFeed(L["Damage: Raid DPS"])
		Skada:RemoveMode(self)
	end

	function mod:AddToTooltip(set, tooltip)
		if not set then return end
		local dps, amount = set:GetDPS()
		tooltip:AddDoubleLine(L["Damage"], Skada:FormatNumber(amount), 1, 1, 1)
		tooltip:AddDoubleLine(L["DPS"], Skada:FormatNumber(dps), 1, 1, 1)
	end

	function mod:GetSetSummary(set)
		if not set then return end
		local dps, amount = set:GetDPS()
		return Skada:FormatValueCols(
			self.metadata.columns.Damage and Skada:FormatNumber(amount),
			self.metadata.columns.DPS and Skada:FormatNumber(dps)
		), amount
	end

	function mod:SetComplete(set)
		T.clear(dmg)
		T.free("Damage_ExtraAttacks", extraATT, nil, del)

		-- clean set from garbage before it is saved.
		if (set.totaldamage or 0) == 0 then return end
		for i = 1, #set.players do
			local p = set.players[i]
			if p and p.totaldamage == 0 then
				p.damagespells = nil
			elseif p and p.damagespells then
				for spellname, spell in pairs(p.damagespells) do
					if (spell.total or 0) == 0 or (spell.count or 0) == 0 then
						p.damagespells[spellname] = nil
					end
				end
				-- nothing left?
				if next(p.damagespells) == nil then
					p.damagespells = nil
				end
			end
		end
	end
end)

-- ============================= --
-- Damage done per second module --
-- ============================= --

Skada:AddLoadableModule("DPS", function(L)
	if Skada:IsDisabled("Damage", "DPS") then return end

	local mod = Skada:NewModule(L["DPS"])

	local function dps_tooltip(win, id, label, tooltip)
		local set = win:GetSelectedSet()
		local actor = set and set:GetActor(label, id)
		if actor then
			local totaltime = set:GetTime()
			local activetime = actor:GetTime(true)
			local dps, damage = actor:GetDPS()
			tooltip:AddLine(actor.name .. " - " .. L["DPS"])
			tooltip:AddDoubleLine(L["Segment Time"], Skada:FormatTime(totaltime), 1, 1, 1)
			tooltip:AddDoubleLine(L["Active Time"], Skada:FormatTime(activetime), 1, 1, 1)
			tooltip:AddDoubleLine(L["Damage Done"], Skada:FormatNumber(damage), 1, 1, 1)

			local suffix = Skada:FormatTime(Skada.db.profile.timemesure == 1 and activetime or totaltime)
			tooltip:AddDoubleLine(Skada:FormatNumber(damage) .. "/" .. suffix, Skada:FormatNumber(dps), 1, 1, 1)
		end
	end

	function mod:Update(win, set)
		win.title = win.class and format("%s (%s)", L["DPS"], L[win.class]) or L["DPS"]

		local total = set and set:GetDPS() or 0

		if total > 0 then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local nr = 0

			-- players
			for i = 1, #set.players do
				local player = set.players[i]
				if player and (not win.class or win.class == player.class) then
					local dps = player:GetDPS()

					if dps > 0 then
						nr = nr + 1
						local d = win:nr(nr)

						d.id = player.id or player.name
						d.label = player.name
						d.text = player.id and Skada:FormatName(player.name, player.id)
						d.class = player.class
						d.role = player.role
						d.spec = player.spec

						if Skada.forPVP and set.type == "arena" then
							d.color = Skada.classcolors(set.gold and "ARENA_GOLD" or "ARENA_GREEN")
						end

						d.value = dps
						d.valuetext = Skada:FormatValueCols(
							self.metadata.columns.DPS and Skada:FormatNumber(d.value),
							self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
						)

						if win.metadata and d.value > win.metadata.maxvalue then
							win.metadata.maxvalue = d.value
						end
					end
				end
			end

			-- arena enemies
			if Skada.forPVP and set.type == "arena" and set.enemies and set.GetEnemyDamage then
				for i = 1, #set.enemies do
					local enemy = set.enemies[i]
					if enemy and not enemy.fake and (not win.class or win.class == enemy.class) then
						local dps = enemy:GetDPS()

						if dps > 0 then
							nr = nr + 1
							local d = win:nr(nr)

							d.id = enemy.id or enemy.name
							d.label = enemy.name
							d.text = nil
							d.class = enemy.class
							d.role = enemy.role
							d.spec = enemy.spec
							d.color = Skada.classcolors(set.gold and "ARENA_GREEN" or "ARENA_GOLD")

							d.value = dps
							d.valuetext = Skada:FormatValueCols(
								self.metadata.columns.DPS and Skada:FormatNumber(d.value),
								self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
							)

							if win.metadata and d.value > win.metadata.maxvalue then
								win.metadata.maxvalue = d.value
							end
						end
					end
				end
			end
		end
	end

	function mod:OnEnable()
		self.metadata = {
			showspots = true,
			tooltip = dps_tooltip,
			columns = {DPS = true, Percent = true},
			icon = [[Interface\Icons\achievement_bg_topdps]]
		}

		local parentmod = Skada:GetModule(L["Damage"], true)
		if parentmod then
			self.metadata.click1 = parentmod.metadata.click1
			self.metadata.click2 = parentmod.metadata.click2
			self.metadata.click4 = parentmod.metadata.click4
			self.metadata.click4_label = parentmod.metadata.click4_label
		end

		Skada:AddMode(self, L["Damage Done"])
	end

	function mod:OnDisable()
		Skada:RemoveMode(self, L["Damage Done"])
	end

	function mod:GetSetSummary(set)
		return Skada:FormatNumber(set and set:GetDPS() or 0)
	end
end)

-- =========================== --
-- Damage Done By Spell Module --
-- =========================== --

Skada:AddLoadableModule("Damage Done By Spell", function(L)
	if Skada:IsDisabled("Damage", "Damage Done By Spell") then return end

	local mod = Skada:NewModule(L["Damage Done By Spell"])
	local sourcemod = mod:NewModule(L["Damage spell sources"])

	function sourcemod:Enter(win, id, label)
		win.spellname = label
		win.title = format(L["%s's sources"], label)
	end

	function sourcemod:Update(win, set)
		win.title = format(L["%s's sources"], win.spellname or L["Unknown"])
		if win.spellname then
			wipe(cacheTable)
			local total = 0

			for i = 1, #set.players do
				local player = set.players[i]
				if
					player and
					player.damagespells and
					player.damagespells[win.spellname] and
					(player.damagespells[win.spellname].total or 0) > 0
				then
					cacheTable[player.name] = {
						id = player.id,
						class = player.class,
						role = player.role,
						spec = player.spec,
						amount = player.damagespells[win.spellname].amount,
						time = mod.metadata.columns.sDPS and player:GetTime()
					}
					if Skada.db.profile.absdamage then
						cacheTable[player.name].amount = player.damagespells[win.spellname].total
					end

					total = total + cacheTable[player.name].amount
				end
			end

			if total > 0 then
				if win.metadata then
					win.metadata.maxvalue = 0
				end

				local nr = 0
				for playername, player in pairs(cacheTable) do
					nr = nr + 1
					local d = win:nr(nr)

					d.id = player.id or playername
					d.label = playername
					d.text = player.id and Skada:FormatName(playername, player.id)
					d.class = player.class
					d.role = player.role
					d.spec = player.spec

					d.value = player.amount
					d.valuetext = Skada:FormatValueCols(
						mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
						player.time and Skada:FormatNumber(d.value / player.time),
						mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end
		end
	end

	function mod:Update(win, set)
		win.title = L["Damage Done By Spell"]

		local total = set and set:GetDamage() or 0
		if total == 0 then return end

		wipe(cacheTable)

		for i = 1, #set.players do
			local player = set.players[i]
			if player and player.damagespells then
				for spellname, spell in pairs(player.damagespells) do
					if spell.total > 0 then
						if not cacheTable[spellname] then
							cacheTable[spellname] = {id = spell.id, school = spell.school, amount = 0}
						end
						if Skada.db.profile.absdamage then
							cacheTable[spellname].amount = cacheTable[spellname].amount + spell.total
						else
							cacheTable[spellname].amount = cacheTable[spellname].amount + spell.amount
						end
					end
				end
			end
		end

		if win.metadata then
			win.metadata.maxvalue = 0
		end

		local settime, nr = self.metadata.columns.DPS and set:GetTime(), 0
		for spellname, spell in pairs(cacheTable) do
			nr = nr + 1
			local d = win:nr(nr)

			d.id = spellname
			d.spellid = spell.id
			d.label = spellname
			_, _, d.icon = GetSpellInfo(spell.id)
			d.spellschool = spell.school

			d.value = spell.amount
			d.valuetext = Skada:FormatValueCols(
				self.metadata.columns.Damage and Skada:FormatNumber(d.value),
				settime and Skada:FormatNumber(d.value / settime),
				self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
			)

			if win.metadata and d.value > win.metadata.maxvalue then
				win.metadata.maxvalue = d.value
			end
		end
	end

	function mod:OnEnable()
		sourcemod.metadata = {showspots = true}
		self.metadata = {
			showspots = true,
			click1 = sourcemod,
			columns = {Damage = true, DPS = false, Percent = true, sDPS = false, sPercent = true},
			icon = [[Interface\Icons\spell_nature_lightning]]
		}
		Skada:AddMode(self, L["Damage Done"])
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end
end)

-- ==================== --
-- Useful Damage Module --
-- ==================== --
--
-- this module uses the data from Damage module and
-- show the "effective" damage and dps by substructing
-- the overkill from the amount of damage done.
--

Skada:AddLoadableModule("Useful Damage", function(L)
	if Skada:IsDisabled("Damage", "Useful Damage") then return end

	local mod = Skada:NewModule(L["Useful Damage"])
	local playermod = mod:NewModule(L["Damage spell list"])
	local targetmod = mod:NewModule(L["Damage target list"])
	local detailmod = targetmod:NewModule(L["More Details"])

	function playermod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = L["actor damage"](label)
	end

	function playermod:Update(win, set)
		win.title = L["actor damage"](win.actorname or L["Unknown"])
		if not set or not win.actorname then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local total = actor and actor:GetDamage(true) or 0

		if total > 0 and actor.damagespells then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for spellname, spell in pairs(actor.damagespells) do
				nr = nr + 1
				local d = win:nr(nr)

				if enemy then
					d.spellid = spellname
					d.label, _, d.icon = GetSpellInfo(spellname)
					d.id = d.label
				else
					d.id = spellname
					d.spellid = spell.id
					d.label = spellname
					_, _, d.icon = GetSpellInfo(spell.id)
				end

				d.spellschool = spell.school

				d.value = Skada.db.profile.absdamage and spell.total or spell.amount
				if spell.overkill then
					d.value = max(0, d.value - spell.overkill)
				end

				d.valuetext = Skada:FormatValueCols(
					mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
					actortime and Skada:FormatNumber(d.value / actortime),
					mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
				)

				if win.metadata and d.value > win.metadata.maxvalue then
					win.metadata.maxvalue = d.value
				end
			end
		end
	end

	function targetmod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = format(L["%s's targets"], label)
	end

	function targetmod:Update(win, set)
		win.title = format(L["%s's targets"], win.actorname or L["Unknown"])
		if not set or not win.actorname then return end

		local actor = set:GetActor(win.actorname, win.actorid)
		local total = actor and actor:GetDamage(true) or 0
		local targets = (total > 0) and actor:GetDamageTargets()

		if targets then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for targetname, target in pairs(targets) do
				nr = nr + 1
				local d = win:nr(nr)

				d.id = target.id or targetname
				d.label = targetname
				d.class = target.class
				d.role = target.role
				d.spec = target.spec

				d.value = Skada.db.profile.absdamage and target.total or target.amount
				if target.overkill then
					d.value = max(0, d.value - target.overkill)
				end

				d.valuetext = Skada:FormatValueCols(
					mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
					actortime and Skada:FormatNumber(d.value / actortime),
					mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
				)

				if win.metadata and d.value > win.metadata.maxvalue then
					win.metadata.maxvalue = d.value
				end
			end
		end
	end

	function detailmod:Enter(win, id, label, tooltip)
		win.targetid, win.targetname = id, label
		win.title = format(L["Useful damage on %s"], label)
	end

	function detailmod:Update(win, set)
		win.title = format(L["Useful damage on %s"], win.targetname or L["Unknown"])
		if not set or not win.targetname then return end

		local actor, enemy = set:GetActor(win.targetname, win.targetid)
		local total = actor and actor:GetDamageTaken() or 0
		local sources = (total > 0) and actor:GetDamageSources()

		if sources then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for sourcename, source in pairs(sources) do
				local amount = source.amount or 0
				if Skada.db.profile.absdamage and source.total then
					amount = source.total
				end
				if sources.overkill then
					amount = max(0, amount - source.overkill)
				end

				if amount > 0 then
					nr = nr + 1
					local d = win:nr(nr)

					d.id = source.id or sourcename
					d.label = sourcename
					d.text = (source.id and enemy) and Skada:FormatName(sourcename, source.id)
					d.class = source.class
					d.role = source.role
					d.spec = source.spec

					d.value = amount
					d.valuetext = Skada:FormatValueCols(
						mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
						actortime and Skada:FormatNumber(d.value / actortime),
						mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end
		end
	end

	function mod:Update(win, set)
		win.title = win.class and format("%s (%s)", L["Useful Damage"], L[win.class]) or L["Useful Damage"]

		local total = set and set:GetDamage(true) or 0
		if total > 0 then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local nr = 0

			-- players
			for i = 1, #set.players do
				local player = set.players[i]
				if player and (not win.class or win.class == player.class) then
					local dps, amount = player:GetDPS(true)

					if amount > 0 then
						nr = nr + 1
						local d = win:nr(nr)

						d.id = player.id or player.name
						d.label = player.name
						d.text = player.id and Skada:FormatName(player.name, player.id)
						d.class = player.class
						d.role = player.role
						d.spec = player.spec

						if Skada.forPVP and set.type == "arena" then
							d.color = Skada.classcolors(set.gold and "ARENA_GOLD" or "ARENA_GREEN")
						end

						d.value = amount
						d.valuetext = Skada:FormatValueCols(
							self.metadata.columns.Damage and Skada:FormatNumber(d.value),
							self.metadata.columns.DPS and Skada:FormatNumber(dps),
							self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
						)

						if win.metadata and d.value > win.metadata.maxvalue then
							win.metadata.maxvalue = d.value
						end
					end
				end
			end

			-- arena enemies
			if Skada.forPVP and set.type == "arena" and set.enemies then
				for i = 1, #set.enemies do
					local enemy = set.enemies[i]
					if enemy and not enemy.fake and (not win.class or win.class == enemy.class) then
						local dps, amount = enemy:GetDPS(true)

						if amount > 0 then
							nr = nr + 1
							local d = win:nr(nr)

							d.id = enemy.id or enemy.name
							d.label = enemy.name
							d.text = nil
							d.class = enemy.class
							d.role = enemy.role
							d.spec = enemy.spec
							d.color = Skada.classcolors(set.gold and "ARENA_GREEN" or "ARENA_GOLD")

							d.value = amount
							d.valuetext = Skada:FormatValueCols(
								self.metadata.columns.Damage and Skada:FormatNumber(d.value),
								self.metadata.columns.DPS and Skada:FormatNumber(dps),
								self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
							)

							if win.metadata and d.value > win.metadata.maxvalue then
								win.metadata.maxvalue = d.value
							end
						end
					end
				end
			end
		end
	end

	function mod:OnEnable()
		detailmod.metadata = {showspots = true}
		targetmod.metadata = {click1 = detailmod}
		self.metadata = {
			showspots = true,
			click1 = playermod,
			click2 = targetmod,
			click4 = Skada.FilterClass,
			click4_label = L["Toggle Class Filter"],
			columns = {Damage = true, DPS = true, Percent = true, sDPS = false, sPercent = true},
			icon = [[Interface\Icons\spell_shaman_stormearthfire]]
		}

		-- no total click.
		playermod.nototal = true
		targetmod.nototal = true

		Skada:AddMode(self, L["Damage Done"])
	end

	function mod:OnDisable()
		Skada:RemoveMode(self)
	end

	function mod:GetSetSummary(set)
		if not set then return end
		local dps, damage = set:GetDPS(true)
		return Skada:FormatValueCols(
			self.metadata.columns.Damage and Skada:FormatNumber(damage),
			self.metadata.columns.DPS and Skada:FormatNumber(dps)
		), damage
	end
end)

-- =============== --
-- Overkill Module --
-- =============== --

Skada:AddLoadableModule("Overkill", function(L)
	if Skada:IsDisabled("Damage", "Overkill") then return end

	local mod = Skada:NewModule(L["Overkill"])
	local playermod = mod:NewModule(L["Overkill spell list"])
	local targetmod = mod:NewModule(L["Overkill target list"])
	local detailmod = targetmod:NewModule(L["Overkill spell list"])

	function playermod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = format(L["%s's overkill spells"], label)
	end

	function playermod:Update(win, set)
		win.title = format(L["%s's overkill spells"], win.actorname or L["Unknown"])
		if not set or not win.actorname then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		local total = actor and actor.overkill or 0
		if total > 0 and actor.damagespells then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for spellname, spell in pairs(actor.damagespells) do
				if (spell.overkill or 0) > 0 then
					nr = nr + 1
					local d = win:nr(nr)

					if enemy then
						d.spellid = spellname
						d.label, _, d.icon = GetSpellInfo(spellname)
						d.id = d.label
					else
						d.id = spellname
						d.spellid = spell.id
						d.label = spellname
						_, _, d.icon = GetSpellInfo(spell.id)
					end

					d.spellschool = spell.school

					d.value = spell.overkill
					d.valuetext = Skada:FormatValueCols(
						mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
						actortime and Skada:FormatNumber(d.value / actortime),
						mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end
		end
	end

	function targetmod:Enter(win, id, label)
		win.actorid, win.actorname = id, label
		win.title = format(L["%s's overkill targets"], label)
	end

	function targetmod:Update(win, set)
		win.title = format(L["%s's overkill targets"], win.actorname or L["Unknown"])
		if not set or not win.actorname then return end

		local actor = set:GetActor(win.actorname, win.actorid)
		local total = actor and actor.overkill or 0
		local targets = (total > 0) and actor:GetDamageTargets()

		if targets then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for targetname, target in pairs(targets) do
				if (target.overkill or 0) > 0 then
					nr = nr + 1
					local d = win:nr(nr)

					d.id = target.id or targetname
					d.label = targetname
					d.class = target.class
					d.role = target.role
					d.spec = target.spec

					d.value = target.overkill
					d.valuetext = Skada:FormatValueCols(
						mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
						actortime and Skada:FormatNumber(d.value / actortime),
						mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end
		end
	end

	function detailmod:Enter(win, id, label)
		win.targetid, win.targetname = id, label
		win.title = format(L["%s's overkill spells"], win.actorname or L["Unknown"])
	end

	function detailmod:Update(win, set)
		win.title = format(L["%s's overkill spells"], win.actorname or L["Unknown"])
		if not set or not win.targetname then return end

		local actor, enemy = set:GetActor(win.actorname, win.actorid)
		if not actor or (actor.overkill or 0) == 0 then return end

		local targets = actor:GetDamageTargets()
		local total = (targets and targets[win.targetname]) and targets[win.targetname].overkill or 0

		if total > 0 and actor.damagespells then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local actortime, nr = mod.metadata.columns.sDPS and actor:GetTime(), 0
			for spellname, spell in pairs(actor.damagespells) do
				if spell.targets and spell.targets[win.targetname] and (spell.targets[win.targetname].overkill or 0) > 0 then
					nr = nr + 1
					local d = win:nr(nr)

					if enemy then
						d.spellid = spellname
						d.label, _, d.icon = GetSpellInfo(spellname)
						d.id = d.label
					else
						d.id = spellname
						d.spellid = spell.id
						d.label = spellname
						_, _, d.icon = GetSpellInfo(spell.id)
					end

					d.spellschool = spell.school

					d.value = spell.targets[win.targetname].overkill
					d.valuetext = Skada:FormatValueCols(
						mod.metadata.columns.Damage and Skada:FormatNumber(d.value),
						actortime and Skada:FormatNumber(d.value / actortime),
						mod.metadata.columns.sPercent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end
		end
	end

	function mod:Update(win, set)
		win.title = win.class and format("%s (%s)", L["Overkill"], L[win.class]) or L["Overkill"]

		local total = set:GetOverkill()
		if total > 0 then
			if win.metadata then
				win.metadata.maxvalue = 0
			end

			local nr = 0

			-- players
			for i = 1, #set.players do
				local player = set.players[i]
				if player and player.overkill and (not win.class or win.class == player.class) then
					nr = nr + 1
					local d = win:nr(nr)

					d.id = player.id or player.name
					d.label = player.name
					d.text = player.id and Skada:FormatName(player.name, player.id)
					d.class = player.class
					d.role = player.role
					d.spec = player.spec

					if Skada.forPVP and set.type == "arena" then
						d.color = Skada.classcolors(set.gold and "ARENA_GOLD" or "ARENA_GREEN")
					end

					d.value = player.overkill
					d.valuetext = Skada:FormatValueCols(
						self.metadata.columns.Damage and Skada:FormatNumber(d.value),
						self.metadata.columns.DPS and Skada:FormatNumber(d.value / max(1, player:GetTime())),
						self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
					)

					if win.metadata and d.value > win.metadata.maxvalue then
						win.metadata.maxvalue = d.value
					end
				end
			end

			-- arena enemies
			if Skada.forPVP and set.type == "arena" and set.enemies and set.GetEnemyOverkill then
				for i = 1, #set.enemies do
					local enemy = set.enemies[i]
					if enemy and not enemy.fake and enemy.overkill and (not win.class or win.class == enemy.class) then
						nr = nr + 1
						local d = win:nr(nr)

						d.id = enemy.id or enemy.name
						d.label = enemy.name
						d.text = nil
						d.class = enemy.class
						d.role = enemy.role
						d.spec = enemy.spec
						d.color = Skada.classcolors(set.gold and "ARENA_GREEN" or "ARENA_GOLD")

						d.value = enemy.overkill
						d.valuetext = Skada:FormatValueCols(
							self.metadata.columns.Damage and Skada:FormatNumber(d.value),
							self.metadata.columns.DPS and Skada:FormatNumber(d.value / max(1, enemy:GetTime())),
							self.metadata.columns.Percent and Skada:FormatPercent(d.value, total)
						)

						if win.metadata and d.value > win.metadata.maxvalue then
							win.metadata.maxvalue = d.value
						end
					end
				end
			end
		end
	end

	function mod:OnEnable()
		targetmod.metadata = {click1 = detailmod}
		self.metadata = {
			showspots = true,
			click1 = playermod,
			click2 = targetmod,
			click4 = Skada.FilterClass,
			click4_label = L["Toggle Class Filter"],
			columns = {Damage = true, DPS = false, Percent = true, sDPS = false, sPercent = true},
			icon = [[Interface\Icons\spell_fire_incinerate]]
		}

		-- no total click.
		playermod.nototal = true
		targetmod.nototal = true

		Skada:AddMode(self, L["Damage Done"])
	end

	function mod:OnDisable()
		Skada:RemoveMode(self, L["Damage Done"])
	end

	function mod:GetSetSummary(set)
		local overkill = set:GetOverkill()
		return Skada:FormatNumber(overkill), overkill
	end
end)