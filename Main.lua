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

PGF.lastSearchEntryReset = time()
PGF.previousSearchExpression = ""
PGF.currentSearchExpression = ""
PGF.previousSearchLeaders = {}
PGF.currentSearchLeaders = {}
PGF.declinedGroups = {}

function PGF.GetExpressionFromMinMaxModel(model, key)
	local exp = ""
	if model[key].act then
		if PGF.NotEmpty(model[key].min) then exp = exp .. " and " .. key .. ">=" .. model[key].min end
		if PGF.NotEmpty(model[key].max) then exp = exp .. " and " .. key .. "<=" .. model[key].max end
	end
	return exp
end

function PGF.GetExpressionFromIlvlModel(model)
	local exp = PGF.GetExpressionFromMinMaxModel(model, "ilvl")
	if model.noilvl.act and PGF.NotEmpty(exp) then
		exp = " and (" .. exp:gsub("^ and ", "") .. " or ilvl==0)"
	end
	return exp
end

function PGF.GetExpressionFromDifficultyModel(model)
	return model.difficulty.act and (" and " .. C.DIFFICULTY_STRING[model.difficulty.val]) or ""
end

function PGF.GetExpressionFromAdvancedExpression(model)
	return (model.expression and model.expression ~= "") and (" and ( " .. model.expression .. " ) ") or ""
end

function PGF.GetModel()
	local tab = PVEFrame.activeTabIndex
	local category = LFGListFrame.SearchPanel.categoryID or LFGListFrame.CategorySelection.selectedCategory
	local filters = LFGListFrame.SearchPanel.filters or LFGListFrame.CategorySelection.selectedFilters or 0
	if not tab then return nil end
	if not category then return nil end
	if filters < 0 then filters = "n" .. filters end
	local modelKey = "t" .. tab .. "c" .. category .. "f" .. filters
	if PremadeGroupsFilterState[modelKey] == nil then
		local defaultState = {}
		PGF.Table_UpdateWithDefaults(defaultState, C.MODEL_DEFAULT)
		PremadeGroupsFilterState[modelKey] = defaultState
	end
	return PremadeGroupsFilterState[modelKey]
end

function PGF.GetExpressionFromModel()
	local model = PGF.GetModel()
	if not model then return "true" end
	local exp = "true" -- start with neutral element
	exp = exp .. PGF.GetExpressionFromDifficultyModel(model)
	exp = exp .. PGF.GetExpressionFromIlvlModel(model)
	exp = exp .. PGF.GetExpressionFromMinMaxModel(model, "members")
	exp = exp .. PGF.GetExpressionFromMinMaxModel(model, "tanks")
	exp = exp .. PGF.GetExpressionFromMinMaxModel(model, "heals")
	exp = exp .. PGF.GetExpressionFromMinMaxModel(model, "dps")
	exp = exp .. PGF.GetExpressionFromMinMaxModel(model, "defeated")
	exp = exp .. PGF.GetExpressionFromAdvancedExpression(model)
	exp = exp:gsub("^true and ", "")
	return exp
end

function PGF.ResetSearchEntries()
	-- make sure to wait at least some time between two resets
	if time() - PGF.lastSearchEntryReset > C.SEARCH_ENTRY_RESET_WAIT then
		PGF.previousSearchLeaders = PGF.Table_Copy_Shallow(PGF.currentSearchLeaders)
		PGF.currentSearchLeaders = {}
		PGF.previousSearchExpression = PGF.currentSearchExpression
		PGF.lastSearchEntryReset = time()
	end
end

local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
	local playerRole = GetSpecializationRole(GetSpecialization());
	return roles[roleRemainingKeyLookup[playerRole]] > 0;
end

function PGF.SortByFriendsAndAge(searchResultID1, searchResultID2)
	local searchResultInfo1 = C_LFGList.GetSearchResultInfo(searchResultID1);
	local searchResultInfo2 = C_LFGList.GetSearchResultInfo(searchResultID2);

	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(searchResultID1);
	local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(searchResultID2);

	if hasRemainingRole1 ~= hasRemainingRole2 then return hasRemainingRole1 end

	if searchResultInfo1.numBNetFriends ~= searchResultInfo2.numBNetFriends then
		return searchResultInfo1.numBNetFriends > searchResultInfo2.numBNetFriends
	end
	if searchResultInfo1.numCharFriends ~= searchResultInfo2.numCharFriends then
		return searchResultInfo1.numCharFriends > searchResultInfo2.numCharFriends
	end
	if searchResultInfo1.numGuildMates ~= searchResultInfo2.numGuildMates then
		return searchResultInfo1.numGuildMates > searchResultInfo2.numGuildMates
	end

	return searchResultInfo1.age < searchResultInfo2.age
end

local myGroup = {TANK = 1, HEALER = 1, DAMAGER = 3}
local function checkMyGroup()
	myGroup.TANK, myGroup.HEALER, myGroup.DAMAGER = 1, 1, 3
	local myRole = GetSpecializationRole(GetSpecialization())
	if not myRole then return end
	myGroup[myRole] = myGroup[myRole] - 1
	for i = 1, 4 do
		local unit = "party"..i
		if UnitExists(unit) then
			local role = UnitGroupRolesAssigned(unit)
			if not myGroup[role] then role = "DAMAGER" end
			myGroup[role] = myGroup[role] - 1
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("ROLE_CHANGED_INFORM")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:SetScript("OnEvent", checkMyGroup)


local env = {}

local function DoFilterSearchResults(results)
	--print(debugstack())
	--print("filtering, size is "..#results)

	PGF.ResetSearchEntries()
	local exp = PGF.GetExpressionFromModel()
	PGF.currentSearchExpression = exp
	local model = PGF.GetModel()
	if not model or not model.enabled then return false end
	if not results or #results == 0 then return false end
	if exp == "true" then return false end -- skip trivial expression

	-- loop backwards through the results list so we can remove elements from the table
	for idx = #results, 1, -1 do
		local resultID = results[idx]
		local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
		-- /dump C_LFGList.GetSearchResultInfo(select(2, C_LFGList.GetSearchResults())[1])
		-- name and comment are now protected strings like "|Ks1969|k0000000000000000|k" which can only be printed
		local defeatedBossNames = C_LFGList.GetSearchResultEncounterInfo(resultID)
		local memberCounts = C_LFGList.GetSearchResultMemberCounts(resultID)
		local numGroupDefeated, numPlayerDefeated, maxBosses, matching, groupAhead, groupBehind = PGF.GetLockoutInfo(searchResultInfo.activityID, resultID)
		local avName, avShortName, _, _, _, _, _, avMaxPlayers, avDisplayType, avOrderIndex, avUseHonorLevel, avShowQuickJoin = C_LFGList.GetActivityInfo(searchResultInfo.activityID)
		local difficulty = PGF.GetDifficulty(searchResultInfo.activityID, avName, avShortName)

		table.wipe(env)
		env.activity = searchResultInfo.activityID
		env.activityname = avName:lower()
		env.leader = searchResultInfo.leaderName and searchResultInfo.leaderName:lower() or ""
		env.age = math.floor(searchResultInfo.age / 60) -- age in minutes
		env.ilvl = searchResultInfo.requiredItemLevel or 0
		env.hlvl = searchResultInfo.requiredHonorLevel or 0
		env.members = searchResultInfo.numMembers
		env.tanks = memberCounts.TANK
		env.heals = memberCounts.HEALER
		env.healers = memberCounts.HEALER
		env.dps = memberCounts.DAMAGER + memberCounts.NOROLE
		env.normal = difficulty == C.NORMAL
		env.heroic = difficulty == C.HEROIC
		env.mythic = difficulty == C.MYTHIC
		env.mythicplus = difficulty == C.MYTHICPLUS
		env.declined = PGF.IsDeclinedGroup(searchResultInfo)
		env.smart = avMaxPlayers ~= 5 or ((env.tanks <= myGroup.TANK) and (env.healers <= myGroup.HEALER) and (env.dps <= myGroup.DAMAGER))

		local aID = searchResultInfo.activityID
		env.arena2v2 = aID == 6 or aID == 491
		env.arena3v3 = aID == 7 or aID == 490

		setmetatable(env, { __index = function(table, key) return 0 end }) -- set non-initialized values to 0
		if PGF.DoesPassThroughFilter(env, exp) then
			-- leaderName is usually still nil at this point if the group is new, but we can live with that
			if searchResultInfo.leaderName then PGF.currentSearchLeaders[searchResultInfo.leaderName] = true end
		else
			table.remove(results, idx)
		end
	end
	-- sort by age
	table.sort(results, PGF.SortByFriendsAndAge)
	LFGListFrame.SearchPanel.totalResults = #results
	return true
end

local function GetDeclinedGroupsKey(searchResultInfo)
	return searchResultInfo.activityID .. searchResultInfo.leaderName
end

local function IsDeclinedGroup(searchResultInfo)
    if searchResultInfo.leaderName then -- leaderName is not available for brand new groups
        local lastDeclined = PGF.declinedGroups[GetDeclinedGroupsKey(searchResultInfo)] or 0
        if lastDeclined > time() - C.DECLINED_GROUPS_RESET then
            return true
        end
    end
    return false
end

function PGF.OnLFGListApplicationStatusUpdated(id, newStatus)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(id)
	if newStatus == "declined" and searchResultInfo.leaderName then -- leaderName is not available for brand new groups
		PGF.declinedGroups[GetDeclinedGroupsKey(searchResultInfo)] = time()
	end
end

local function OnLFGListSearchEntryUpdate(self)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(self.resultID)
	-- try once again to update the leaderName (this information is not immediately available)
	if searchResultInfo.leaderName then PGF.currentSearchLeaders[searchResultInfo.leaderName] = true end
	-- self.ActivityName:SetText("[" .. searchResultInfo.activityID .. "/" .. self.resultID .. "] " .. self.ActivityName:GetText()) -- DEBUG
	if not searchResultInfo.isDelisted then
		-- color name if new
		if PGF.currentSearchExpression ~= "true"						-- not trivial search
		and PGF.currentSearchExpression == PGF.previousSearchExpression -- and the same search
		and (searchResultInfo.leaderName and not PGF.previousSearchLeaders[searchResultInfo.leaderName]) then -- and leader is new
			local color = C.COLOR_ENTRY_NEW
			self.Name:SetTextColor(color.R, color.G, color.B)
		end
		-- color name if declined
        if IsDeclinedGroup(searchResultInfo) then
            local color = C.COLOR_ENTRY_DECLINED
            self.Name:SetTextColor(color.R, color.G, color.B)
		end
		-- color activity if lockout
		local numGroupDefeated, numPlayerDefeated, maxBosses, matching, groupAhead, groupBehind = PGF.GetLockoutInfo(searchResultInfo.activityID, self.resultID)
		local color
		if numPlayerDefeated > 0 and numPlayerDefeated == maxBosses then
			color = C.COLOR_LOCKOUT_FULL
		elseif numPlayerDefeated > 0 and groupAhead == 0 and groupBehind == 0 then
			color = C.COLOR_LOCKOUT_MATCH
		end
		if color then
			self.ActivityName:SetTextColor(color.R, color.G, color.B)
		end
	end
end

local roles = {}
local classInfo = {}
function PGF.OnLFGListSearchEntryOnEnter(self)
	local resultID = self.resultID
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
	local _, _, _, _, _, _, _, _, displayType = C_LFGList.GetActivityInfo(searchResultInfo.activityID)

	-- do not show members where Blizzard already does that
	if displayType == LE_LFG_LIST_DISPLAY_TYPE_CLASS_ENUMERATE then return end
	if searchResultInfo.isDelisted or not GameTooltip:IsShown() then return end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(CLASS_ROLES)

	table.wipe(roles)
	for i = 1, searchResultInfo.numMembers do
		local role, class, classLocalized = C_LFGList.GetSearchResultMemberInfo(resultID, i)
		if not classInfo[class] then
			classInfo[class] = {
				name = classLocalized,
				color = (RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR).colorStr
			}
		end
		if not roles[role] then roles[role] = {} end
		if not roles[role][class] then roles[role][class] = 0 end
		roles[role][class] = roles[role][class] + 1
	end

	for role, classes in pairs(roles) do
		GameTooltip:AddLine(_G[role]..": ")
		for class, count in pairs(classes) do
			local text = "   "
			if count > 1 then text = text .. count .. " " else text = text .. "   " end
			text = text .. "|c" .. classInfo[class].color ..  classInfo[class].name .. "|r "
			GameTooltip:AddLine(text)
		end
	end
	GameTooltip:Show()
end

hooksecurefunc("LFGListSearchEntry_Update", OnLFGListSearchEntryUpdate)
hooksecurefunc("LFGListSearchEntry_OnEnter", PGF.OnLFGListSearchEntryOnEnter)
hooksecurefunc("LFGListUtil_SortSearchResults", DoFilterSearchResults)
