-------------------------------------------------------------------------------
-- Premade Groups Filter
-------------------------------------------------------------------------------
-- Copyright (C) 2015 Elotheon-Arthas-EU
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
-------------------------------------------------------------------------------

local PGF = select(2, ...)
local L = PGF.L
local C = PGF.C

-- /run for i=450,550 do local name = C_LFGList.GetActivityInfo(i); print(i, name) end
PGF.ACTIVITY_TO_DIFFICULTY = {	
	[6] = C.ARENA2V2, -- Arena 2v2
	[7] = C.ARENA3V3, -- Arena 3v3
	
	[494] = C.NORMAL,	 -- Uldir
	[495] = C.HEROIC,	 -- Uldir
	[496] = C.MYTHIC,	 -- Uldir

	[497] = C.NORMAL,	 -- Random Normal Dungeon BfA
	[498] = C.HEROIC,	 -- Random Heroic Dungeon BfA

	[499] = C.MYTHIC,	 -- Atal'Dazar
	[500] = C.HEROIC,	 -- Atal'Dazar
	[501] = C.NORMAL,	 -- Atal'Dazar
	[502] = C.MYTHICPLUS, -- Atal'Dazar

	[503] = C.NORMAL,	 -- Temple of Sethraliss
	[504] = C.MYTHICPLUS, -- Temple of Sethraliss
	[505] = C.HEROIC,	 -- Temple of Sethraliss

	[506] = C.NORMAL,	 -- The Underrot
	[507] = C.MYTHICPLUS, -- The Underrot
	[508] = C.HEROIC,	 -- The Underrot

	[509] = C.NORMAL,	 -- The MOTHERLODE
	[510] = C.MYTHICPLUS, -- The MOTHERLODE
	[511] = C.HEROIC,	 -- The MOTHERLODE

	[512] = C.NORMAL,	 -- Kings' Rest
	[513] = C.MYTHIC,	 -- Kings' Rest
	[514] = C.MYTHICPLUS, -- Kings' Rest
	[515] = C.HEROIC,	 -- Kings' Rest

	[516] = C.NORMAL,	 -- Freehold
	[517] = C.MYTHIC,	 -- Freehold
	[518] = C.MYTHICPLUS, -- Freehold
	[519] = C.HEROIC,	 -- Freehold

	[520] = C.NORMAL,	 -- Shrine of the Storm
	[521] = C.MYTHIC,	 -- Shrine of the Storm
	[522] = C.MYTHICPLUS, -- Shrine of the Storm
	[523] = C.HEROIC,	 -- Shrine of the Storm

	[524] = C.NORMAL,	 -- Tol Dagor
	[525] = C.MYTHIC,	 -- Tol Dagor
	[526] = C.MYTHICPLUS, -- Tol Dagor
	[527] = C.HEROIC,	 -- Tol Dagor

	[528] = C.NORMAL,	 -- Waycrest Manor
	[529] = C.MYTHIC,	 -- Waycrest Manor
	[530] = C.MYTHICPLUS, -- Waycrest Manor
	[531] = C.HEROIC,	 -- Waycrest Manor

	[532] = C.NORMAL,	 -- Siege of Boralus
	[533] = C.MYTHIC,	 -- Siege of Boralus
	[534] = C.MYTHICPLUS, -- Siege of Boralus
	[535] = C.HEROIC,	 -- Siege of Boralus

	[536] = C.NORMAL,	 -- Waycrest Manor
	[537] = C.NORMAL,	 -- Tol Dagor
	[538] = C.NORMAL,	 -- Shrine of the Storm
	[539] = C.NORMAL,	 -- Freehold
	[540] = C.NORMAL,	 -- The MOTHERLODE
	[541] = C.NORMAL,	 -- The Underrot
	[542] = C.NORMAL,	 -- Temple of Sethraliss
	[543] = C.NORMAL,	 -- Atal'Dazar

	[644] = C.MYTHIC,	 -- The Underrot
	[645] = C.MYTHIC,	 -- Temple of Sethraliss
	[646] = C.MYTHIC,	 -- The MOTHERLODE

	[653] = C.NORMAL,	 -- Random Island
	[654] = C.HEROIC,	 -- Random Island
	[655] = C.MYTHIC,	 -- Random Island

	[658] = C.MYTHIC,	 -- Siege of Boralus
	[659] = C.MYTHICPLUS, -- Siege of Boralus
	[660] = C.MYTHIC,	 -- Kings Rest
	[661] = C.MYTHICPLUS, -- Kings Rest
}

-- maps localized shortNames from C_LFGList.GetActivityInfo() to difficulties
PGF.SHORTNAME_TO_DIFFICULTY = {
	[select(2, C_LFGList.GetActivityInfo(46))]  = C.NORMAL,	  -- 10 Normal
	[select(2, C_LFGList.GetActivityInfo(47))]  = C.HEROIC,	  -- 10 Heroic
	[select(2, C_LFGList.GetActivityInfo(48))]  = C.NORMAL,	  -- 25 Normal
	[select(2, C_LFGList.GetActivityInfo(49))]  = C.HEROIC,	  -- 25 Heroic
	[select(2, C_LFGList.GetActivityInfo(425))] = C.NORMAL,	  -- Normal
	[select(2, C_LFGList.GetActivityInfo(435))] = C.HEROIC,	  -- Heroic
	[select(2, C_LFGList.GetActivityInfo(445))] = C.MYTHIC,	  -- Mythic
	[select(2, C_LFGList.GetActivityInfo(459))] = C.MYTHICPLUS,  -- Mythic+
	[select(2, C_LFGList.GetActivityInfo(6))]   = C.ARENA2V2,	-- Arena 2v2
	[select(2, C_LFGList.GetActivityInfo(7))]   = C.ARENA3V3,	-- Arena 3v3
}

function PGF.ExtractNameSuffix(name)
	if GetLocale() == "zhCN" or GetLocale() == "zhTW" then
		-- Chinese clients use different parenthesis
		return name:lower():match("[(（]([^)）]+)[)）]")
	else
		-- however we cannot use the regex above for every language
		-- because the Chinese parenthesis somehow breaks the recognition
		-- of other Western special characters such as Umlauts
		return name:lower():match("%(([^)]+)%)")
	end
end

-- maps localized name suffixes (the value in parens) from C_LFGList.GetActivityInfo() to difficulties
PGF.NAMESUFFIX_TO_DIFFICULTY = {
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(46))]  = C.NORMAL,	  -- XXX (10 Normal)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(47))]  = C.HEROIC,	  -- XXX (10 Heroic)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(48))]  = C.NORMAL,	  -- XXX (25 Normal)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(49))]  = C.HEROIC,	  -- XXX (25 Heroic)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(425))] = C.NORMAL,	  -- XXX (Normal)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(435))] = C.HEROIC,	  -- XXX (Heroic)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(445))] = C.MYTHIC,	  -- XXX (Mythic)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(459))] = C.MYTHICPLUS,  -- XXX (Mythic Keystone)
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(6))]   = C.ARENA2V2,	-- Arena 2v2
	[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(7))]   = C.ARENA3V3,	-- Arena 3v3
	--[PGF.ExtractNameSuffix(C_LFGList.GetActivityInfo(476))] = C.MYTHICPLUS, -- XXX (Mythic+)
}

function PGF.GetDifficulty(activity, name, shortName)
	local difficulty

	-- try to extract from shortName
	difficulty = PGF.SHORTNAME_TO_DIFFICULTY[shortName]
	if PGF.NotEmpty(difficulty) then
		--print("difficulty from shortName:", difficulty)
		return difficulty
	end

	-- try to extract from name
	difficulty = PGF.NAMESUFFIX_TO_DIFFICULTY[PGF.ExtractNameSuffix(name)]
	if PGF.NotEmpty(difficulty) then
		--print("difficulty from name:", difficulty)
		return difficulty
	end

	-- try to find it in our hardcoded table
	difficulty = PGF.ACTIVITY_TO_DIFFICULTY[activity]
	if PGF.NotEmpty(difficulty) then
		--print("difficulty from activity:", difficulty)
		return difficulty
	end

	--print("difficulty not found, assuming normal")
	return C.NORMAL
end
