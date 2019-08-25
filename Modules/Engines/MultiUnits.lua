local TMW 											= TMW
--local strlowerCache  								= TMW.strlowerCache

local A 											= Action
local isEnemy										= A.Bit.isEnemy
--local isPlayer									= A.Bit.isPlayer
--local toStr 										= A.toStr
--local toNum 										= A.toNum
--local InstanceInfo								= A.InstanceInfo
--local TeamCache									= A.TeamCache
--local Azerite 									= LibStub("AzeriteTraits")
--local Pet											= LibStub("PetLibrary")
--local LibRangeCheck  								= LibStub("LibRangeCheck-2.0")
--local SpellRange									= LibStub("SpellRange-1.0")

local _G, pairs, next, setmetatable, table, wipe, abs	= 
	  _G, pairs, next, setmetatable, table, wipe, math.abs
	  
local UnitCanAttack, UnitGUID  					    = UnitCanAttack, UnitGUID -- no need cache since nameplates are dynamic 
-------------------------------------------------------------------------------
-- Locals: MultiUnits
-------------------------------------------------------------------------------	  
local MultiUnits 								= {
	activeUnitPlates 							= {},
	activeUnitCLEU 								= {},
	tempEnemies									= {},
	LastCallInitCLEU							= 0,
	TimeStampCLEU								= 0,
}

-- Nameplates
MultiUnits.AddNameplate							= function(unitID)
	if UnitCanAttack("player", unitID) then 
		MultiUnits.activeUnitPlates[unitID] = unitID
	end
end

MultiUnits.RemoveNameplate						= function(unitID)
    MultiUnits.activeUnitPlates[unitID] = nil 
end

MultiUnits.OnResetNameplates					= function()
	wipe(MultiUnits.activeUnitPlates)
end 

-- CLEU 
MultiUnits.OnEventCLEU							= function(...)
	local ts, event, _, SourceGUID, _, SourceFlags, _, DestGUID, _, DestFlags,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()
	if isEnemy(DestFlags) and (event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or ((event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and auraType == "DEBUFF" and UnitGUID("player") == SourceGUID)) then 
		ts = round(ts, 0)
		-- Create or update 
		if not MultiUnits.activeUnitCLEU[SourceGUID] then
			MultiUnits.activeUnitCLEU[SourceGUID] = setmetatable({ TS = ts }, { __mode == "kv" })
		elseif MultiUnits.activeUnitCLEU[SourceGUID].TS + 1.5 <= ts then
			MultiUnits.activeUnitCLEU[SourceGUID].TS = ts
		end 			
		
		
		if abs(ts - MultiUnits.activeUnitCLEU[SourceGUID].TS) < 0.1 then 
			MultiUnits.activeUnitCLEU[SourceGUID].TS = ts 
			MultiUnits.activeUnitCLEU[SourceGUID][DestGUID] = TMW.time
		end 
	end 
	
	
	if event == "UNIT_DIED" or event == "UNIT_DESTROYED" then 
		for sGUID in pairs(MultiUnits.activeUnitCLEU) do 
			MultiUnits.activeUnitCLEU[sGUID][DestGUID] = nil 
		end 
	end 
end 

MultiUnits.OnInitCLEU							= function()
	if TMW.time ~= MultiUnits.LastCallInitCLEU then 
		MultiUnits.LastCallInitCLEU = TMW.time

		if A.IamRanger and not A.IamHealer then 
			A.Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "COMBAT_LOG_EVENT_UNFILTERED", 	MultiUnits.OnEventCLEU)
			A.Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_ENABLED", 		MultiUnits.OnResetCLEU)
			A.Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_DISABLED", 		function()
				-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
				local LastTimeCasted = A.Unit("player"):GetSpellLastCast(A.LastPlayerCastID) 
				if (LastTimeCasted == 0 or LastTimeCasted > 0.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
					MultiUnits.OnResetCLEU()
				end 
			end)
			return 
		end          
				
		A.Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "COMBAT_LOG_EVENT_UNFILTERED")
		A.Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_ENABLED")
		A.Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_DISABLED")		 
		MultiUnits.OnResetCLEU()
	end 
end 

MultiUnits.OnResetCLEU							= function()
	wipe(MultiUnits.activeUnitCLEU)
	wipe(MultiUnits.tempEnemies)
end 

-- Shared
MultiUnits.OnResetAll							= function()
	MultiUnits.OnResetNameplates()
	MultiUnits.OnResetCLEU()
end 

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------	  
A.Listener:Add("ACTION_EVENT_MULTI_UNITS_ALL", "PLAYER_ENTERING_WORLD",   			MultiUnits.OnResetAll) 
A.Listener:Add("ACTION_EVENT_MULTI_UNITS_ALL", "UPDATE_INSTANCE_INFO", 	  			MultiUnits.OnResetAll) 
A.Listener:Add("ACTION_EVENT_MULTI_UNITS_NAMEPLATES", "NAME_PLATE_UNIT_ADDED",	  	MultiUnits.AddNameplate)
A.Listener:Add("ACTION_EVENT_MULTI_UNITS_NAMEPLATES", "NAME_PLATE_UNIT_REMOVED", 	MultiUnits.RemoveNameplate)
TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 					MultiUnits.OnInitCLEU)

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------	
A.MultiUnits = {}  

-- Nameplates 
function A.MultiUnits.GetActiveUnitPlates(self)
	-- @return table (enemy nameplates) or nil
	-- @usage A.MultiUnits:GetActiveUnitPlates()
	return MultiUnits.activeUnitPlates
end 

function A.MultiUnits.GetBySpell(self, spell, count)
	-- @return number
	-- @usage A.MultiUnits:GetBySpell(@number, @number)
	local total = 0
	local nameplates = self:GetActiveUnitPlates()	
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if type(spell) == "table" then 
				if spell:IsInRange(unitID) then 
					total = total + 1
				end 
			else
				if A.IsInRange(spell, unitID) then 
					total = total + 1
				end 				
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 	
end 
A.MultiUnits.GetBySpell = A.MakeFunctionCachedDynamic(A.MultiUnits.GetBySpell)

function A.MultiUnits.GetByRange(self, range, count)
	-- @return number
	-- @usage A.MultiUnits:GetByRange(@number, @number)
	local total = 0
	local nameplates = self:GetActiveUnitPlates()	
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if not range or A.Unit(unitID):CanInterract(range) then 
				total = total + 1
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 	
end 
A.MultiUnits.GetByRange = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRange)

function A.MultiUnits.GetByRangeInCombat(self, range, count, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeInCombat(@number, @number, @number)
	-- All options are optimal
	local total = 0
	local nameplates = self:GetActiveUnitPlates()
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if A.Unit(unitID):CombatTime() > 0 and (not range or A.Unit(unitID):CanInterract(range)) and (not upTTD or A.Unit(unitID):TimeToDie() >= upTTD) then 
				total = total + 1
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeInCombat = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeInCombat)

function A.MultiUnits.GetByRangeCasting(self, range, count, kickAble, spells)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeCasting(@number, @number, @boolean, @table or @spellName or @spellID)
	-- All options are optimal, spells can be table { 123, "Frost Bolt" } or just single spell without table and it can be noted as spellName, spellID or both
	local total = 0
	local nameplates = self:GetActiveUnitPlates()
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			local castName, castStartTime, castEndTime, notInterruptable, spellID = A.Unit(unitID):IsCasting()
			if castName and (not range or A.Unit(unitID):CanInterract(range)) and (not kickAble or not notInterruptable) then 
				if spells then 
					if type(spells) == "table" then 
						for i = 1, #spells do 
							if type(spells[i]) == "number" then 
								if spellID == spells[i] then 
									total = total + 1
								end 
							else 
								if castName == spells[i] then 
									total = total + 1
								end 
							end 						
						end 
					else
						if type(spells) == "number" then 
							if spellID == spells then 
								total = total + 1
							end 
						else 
							if castName == spells then 
								total = total + 1
							end 
						end 
					end 
				else 
					total = total + 1
				end
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeCasting = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeCasting)

function A.MultiUnits.GetByRangeTaunting(self, range, count, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeTaunting(@number, @number, @number)
	-- All options are optimal
	local total = 0
	local nameplates = self:GetActiveUnitPlates()
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if A.Unit(unitID):CombatTime() > 0 and not A.Unit(unitID):IsPlayer() and not A.Unit(unitID .. "target"):IsTank() and not A.Unit(unitID):IsBoss() and (not range or A.Unit(unitID):CanInterract(range)) and (not upTTD or A.Unit(unitID):TimeToDie() >= upTTD) then 
				total = total + 1
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeTaunting = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeTaunting)

function A.MultiUnits.GetByRangeMissedDoTs(self, range, count, deBuffs, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeMissedDoTs(@number, @number, @table or @number, @number)
	-- deBuffs is required, rest options are optimal
	local total = 0
	local nameplates = self:GetActiveUnitPlates()
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if (not A.IsInPvP or A.Unit(unitID):IsPlayer()) and A.Unit(unitID):CombatTime() > 0 and (not range or A.Unit(unitID):CanInterract(range)) and (not upTTD or A.Unit(unitID):TimeToDie() >= upTTD) and A.Unit(unitID):HasDeBuffs(deBuffs, true) == 0 then 
				total = total + 1
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeMissedDoTs = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeMissedDoTs)

function A.MultiUnits.GetByRangeAppliedDoTs(self, range, count, deBuffs, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeAppliedDoTs(@number, @number, @table or @number, @number)
	-- deBuffs is required, rest options are optimal
	local total = 0
	local nameplates = self:GetActiveUnitPlates()
	
	if nameplates then 
		for unitID in pairs(nameplates) do 
			if A.Unit(unitID):CombatTime() > 0 and (not range or A.Unit(unitID):CanInterract(range)) and (not upTTD or A.Unit(unitID):TimeToDie() >= upTTD) and A.Unit(unitID):HasDeBuffs(deBuffs, true) > 0 then 
				total = total + 1
			end 
			
			if count and total >= count then 
				break 
			end 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeAppliedDoTs = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeAppliedDoTs)

-- CLEU
function A.MultiUnits.GetActiveEnemies(self, timer, skipClear)
	-- @return number 
	-- @usage for range specs, A.MultiUnits:GetActiveEnemies(5) or A.MultiUnits:GetActiveEnemies()
	-- skipClear is argument which will prevent to clear old destinations if it's true
	
	if not A.IamRanger then
		A.Print("[Error] MultiUnits - You're not ranged specialization to use Action.MultiUnits:GetActiveEnemies function!")
	end 
	
	local total, timer = 0, timer or 5
	-- Check what everything is valid to use CLEU 
	if next(MultiUnits.activeUnitCLEU) and A.Unit("target"):IsEnemy() then 
		local tGUID = UnitGUID("target")
		if tGUID then
			-- Count by 'timer' cleaved destinations
			wipe(MultiUnits.tempEnemies)
			
			-- Get sourceGUID and his destinations
			for sGUID, sGUIDdests in pairs(MultiUnits.activeUnitCLEU) do 
				-- If sourceGUID has our targetGUID
				if sGUIDdests[tGUID] then 	
					local counter = 0
					
					for dGUID, dGUIDtime in pairs(sGUIDdests) do 
						if dGUID ~= "TS" then 
							-- Clear old to make less resource eat on the next function use 
							if not skipClear and TMW.time - dGUIDtime > timer then 
								sGUIDdests[dGUID] = nil 
							-- Add counter 
							else 
								counter = counter + 1
							end 
						end 
					end 
					
					-- Put counter in temp which will be used to summary all results and return by sort highest counter
					if counter > 0 then 
						table.insert(MultiUnits.tempEnemies, counter)
					end 
				end 
			end 
			
			-- Summary if something was found 
			if #MultiUnits.tempEnemies > 0 then 
				if #MultiUnits.tempEnemies > 1 then 
					table.sort(MultiUnits.tempEnemies, function(a, b) return a > b end)				
				end 
				
				total = MultiUnits.tempEnemies[1]
			end 
		end 
	end 
	
	-- Alternative search by in combat nameplates by range (in case if CLEU went wrong)
	if total and total <= 0 then 
		total = self:GetByRangeInCombat(40, 10)
	end 
	
	return total or 0
end 
A.MultiUnits.GetActiveEnemies = A.MakeFunctionCachedDynamic(A.MultiUnits.GetActiveEnemies, ACTION_CONST_CACHE_DEFAULT_TIMER_MULTIUNIT_CLEU)