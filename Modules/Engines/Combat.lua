-------------------------------------------------------------------------------------
-- Combat is special written tracker for Action addon which can't work outside
-- This tracker tracks UnitCooldown, TTD, DPS, HPS, Absorb, DR, CombatTime, 
-- Loss of Control, Flying spells, Count spells, Last spells, Amount spells
-- And timers since last time for many things above 
-------------------------------------------------------------------------------------
local TMW 										= TMW
local A 										= Action

--local strlowerCache  							= TMW.strlowerCache
local isEnemy									= A.Bit.isEnemy
local isPlayer									= A.Bit.isPlayer
--local toStr 									= A.toStr
--local toNum 									= A.toNum
local strElemBuilder							= A.strElemBuilder
--local InstanceInfo							= A.InstanceInfo
local TeamCache									= A.TeamCache
local FriendlyGUIDs								= TeamCache.Friendly.GUIDs
local DRData 									= LibStub("DRList-1.1")

local huge 										= math.huge 
local abs 										= math.abs 
local math_max									= math.max 

local _G, type, pairs, table, strsub, wipe, bitband = 
	  _G, type, pairs, table, strsub, wipe, bit.band

local UnitGUID, UnitHealth, UnitHealthMax, UnitAffectingCombat, UnitInAnyGroup, UnitDebuff	= 
	  UnitGUID, UnitHealth, UnitHealthMax, UnitAffectingCombat, UnitInAnyGroup, UnitDebuff
	  
	  
local InCombatLockdown, CombatLogGetCurrentEventInfo = 
	  InCombatLockdown, CombatLogGetCurrentEventInfo 

local GetSpellInfo								= _G.GetSpellInfo

local skipedFirstEnter 							= false 

-------------------------------------------------------------------------------
-- Locals: CombatTracker
-------------------------------------------------------------------------------
local CombatTracker 							= {
	Data			 						= {}, -- setmetatable({}, { __mode == "kv" })
	Doubles 								= {
		[3]  								= "Holy + Physical",
		[5]  								= "Fire + Physical",
		[9]  								= "Nature + Physical",
		[17] 								= "Frost + Physical",
		[33] 								= "Shadow + Physical",
		[65] 								= "Arcane + Physical",
		[127]								= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
	},
	AddToData 								= function(self, GUID)
		if not self.Data[GUID] then
			self.Data[GUID] 				= {
				-- RealTime Damage 
				RealDMG 					= { 
					-- Damage Taken
					LastHit_Taken 			= 0,                             
					dmgTaken 				= 0,
					dmgTaken_S 				= 0,
					dmgTaken_P 				= 0,
					dmgTaken_M 				= 0,
					hits_taken 				= 0,                
					-- Damage Done
					LastHit_Done 			= 0,  
					dmgDone 				= 0,
					dmgDone_S 				= 0,
					dmgDone_P 				= 0,
					dmgDone_M 				= 0,
					hits_done 				= 0,
				},  
				-- Sustain Damage 
				DMG 						= {
					-- Damage Taken
					dmgTaken 				= 0,
					dmgTaken_S 				= 0,
					dmgTaken_P 				= 0,
					dmgTaken_M 				= 0,
					hits_taken 				= 0,
					lastHit_taken 			= 0,
					-- Damage Done
					dmgDone 				= 0,
					dmgDone_S 				= 0,
					dmgDone_P 				= 0,
					dmgDone_M 				= 0,
					hits_done 				= 0,
					lastHit_done 			= 0,
				},
				-- Sustain Healing 
				HPS 						= {
					-- Healing taken
					heal_taken 				= 0,
					heal_hits_taken 		= 0,
					heal_lasttime 			= 0,
					-- Healing Done
					heal_done 				= 0,
					heal_hits_done 			= 0,
					heal_lasttime_done 		= 0,
				},
				-- DS: Last N sec (Only Taken) 
				DS 							= {},
				-- DR: Diminishing
				DR 							= {},
				-- Absorb (Only Taken)       
				absorb_total				= 0,
				absorb_spells 				= {},
				-- Shared 
				combat_time 				= TMW.time,
				spell_value 				= {},
				spell_lastcast_time 		= {},
				spell_counter 				= {},			
			}
		end	
	end,
}

-- Classic: RealUnitHealth
local RealUnitHealth 			= {
	DamageTaken					= {},	-- log damage and healing taken (includes regen as healing only if can be received by events which provide unitID)
	CachedHealthMax				= {},	-- used to display when unit received damage at pre pared full health 
	CachedHealthMaxTemprorary 	= {},	-- used to display when unit received damage at any health percentage 
	SavedHealthPercent			= {},	-- used for post out 
	isHealthWasMaxOnGUID 		= {},	-- used to determine state from which substract recorded taken damage 
}

local function logDefaultGUIDatMaxHealth()
	if TeamCache.Friendly.Size > 0 then
		local unit = TeamCache.Friendly.Type
		for i = 1, TeamCache.Friendly.Size do		
			-- unit 
			CombatTracker.logHealthMax(strElemBuilder(nil, unit, i))
			CombatTracker.logHealthMax(strElemBuilder(nil, unit, "pet", i))			
			-- unittarget
			CombatTracker.logHealthMax(strElemBuilder(nil, unit, i, "target"))
			CombatTracker.logHealthMax(strElemBuilder(nil, unit, "pet", i, "target"))
		end
	end	
end 

local function logDefaultGUIDatMaxHealthTarget()
	CombatTracker.logHealthMax("target")
	CombatTracker.logHealthMax("targettarget")
end 

local function logDefaultGUIDatMaxHealthMouseover()
	CombatTracker.logHealthMax("mouseover")
	CombatTracker.logHealthMax("mouseovertarget")
end 

--[[ This Logs the UnitHealthMax (Real) for every unit ]]
CombatTracker.logHealthMax						= function(...)
	local unitID 	= ...
	if UnitInAnyGroup(unitID) or UnitIsUnit(unitID, "player") or UnitIsUnit(unitID, "pet") then 
		return 
	end 
	
	local GUID 		= UnitGUID(unitID)
	if not GUID then 
		return 
	end 
	
	local curr_hp, max_hp = UnitHealth(unitID), UnitHealthMax(unitID)
	if curr_hp <= 0 then 
		return 
	end 		
	
	if curr_hp == max_hp then 			
		-- Reset summary damage log to accurate calculate real health 
		RealUnitHealth.DamageTaken[GUID] = 0 	
		RealUnitHealth.CachedHealthMax[GUID] = nil 
		RealUnitHealth.SavedHealthPercent[GUID]	= curr_hp 
		RealUnitHealth.isHealthWasMaxOnGUID[GUID] = true 
		--print(UnitName(unitID), "MAX HEALTH!")		
	elseif not RealUnitHealth.CachedHealthMax[GUID] and CombatTracker.Data[GUID] then  	
		-- Always reset damage taken and remember percent out of combat 
		if RealUnitHealth.DamageTaken[GUID] ~= 0 and not UnitAffectingCombat(unitID) then 
			RealUnitHealth.DamageTaken[GUID] = 0  
			RealUnitHealth.SavedHealthPercent[GUID] = curr_hp 
			--print(UnitName(unitID), "Out of combat, DamageTaken: ", RealUnitHealth.DamageTaken[GUID])
			return 
		end 
		
		-- Always update percent because out of combat unit gaining health
		if RealUnitHealth.DamageTaken[GUID] == 0 then 
			if (not RealUnitHealth.SavedHealthPercent[GUID] or curr_hp > RealUnitHealth.SavedHealthPercent[GUID]) and not UnitAffectingCombat(unitID) then 
				--print(UnitName(unitID), "Out of combat, SavedPercent: ", curr_hp, "from", RealUnitHealth.SavedHealthPercent[GUID] or "nil")
				RealUnitHealth.SavedHealthPercent[GUID] = curr_hp 		
			end 
		else 			
			if RealUnitHealth.isHealthWasMaxOnGUID[GUID] then 
				RealUnitHealth.CachedHealthMax[GUID] = RealUnitHealth.DamageTaken[GUID] * max_hp / (max_hp - curr_hp)
				RealUnitHealth.CachedHealthMaxTemprorary[GUID] = RealUnitHealth.CachedHealthMax[GUID]		
				--print(UnitName(unitID), "In combat, MaxHP PRE:", RealUnitHealth.CachedHealthMax[GUID]) 
			else 
				if not RealUnitHealth.SavedHealthPercent[GUID] then 
					RealUnitHealth.DamageTaken[GUID] = 0
					RealUnitHealth.SavedHealthPercent[GUID] = curr_hp
					--print(UnitName(unitID), "In combat, SavedPercent (wasn't existed before):", RealUnitHealth.SavedHealthPercent[GUID])
					--print(UnitName(unitID), "In combat, DamageTaken: ", RealUnitHealth.DamageTaken[GUID])
				elseif RealUnitHealth.SavedHealthPercent[GUID] > curr_hp and not RealUnitHealth.CachedHealthMaxTemprorary[GUID] then   
					RealUnitHealth.CachedHealthMaxTemprorary[GUID] = RealUnitHealth.DamageTaken[GUID] * RealUnitHealth.SavedHealthPercent[GUID] / (RealUnitHealth.SavedHealthPercent[GUID] - curr_hp)
					RealUnitHealth.CachedHealthMax[GUID] = RealUnitHealth.CachedHealthMaxTemprorary[GUID]
					--print(UnitName(unitID), "In combat, MaxHP POST POST (percent of health has been decreased):", RealUnitHealth.CachedHealthMaxTemprorary[GUID])
				end 
			end 
		end 
	end 	
end 

--[[ ENVIRONMENTAL ]] 
CombatTracker.logEnvironmentalDamage			= function(...)
	local Data = CombatTracker.Data	
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags, _,_, Amount = CombatLogGetCurrentEventInfo()
	-- Classic: RealUnitHealth log taken
	RealUnitHealth.DamageTaken[DestGUID] = (RealUnitHealth.DamageTaken[DestGUID] or 0) + Amount
	-- Taken 
	Data[DestGUID].DMG.dmgTaken = Data[DestGUID].DMG.dmgTaken + Amount
end 

--[[ This Logs the damage for every unit ]]
CombatTracker.logDamage 						= function(...) 
	local Data = CombatTracker.Data	
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags,_, spellID, spellName, school, Amount = CombatLogGetCurrentEventInfo()	
	-- Update last hit time
	-- Taken 
	Data[DestGUID].DMG.lastHit_taken = TMW.time
	-- Done 
	Data[SourceGUID].DMG.lastHit_done = TMW.time
	-- Classic: RealUnitHealth log taken
	if not FriendlyGUIDs[DestGUID] then 
		RealUnitHealth.DamageTaken[DestGUID] = (RealUnitHealth.DamageTaken[DestGUID] or 0) + Amount	
	end 
	-- Filter by School   
	if CombatTracker.Doubles[school] then
		-- Taken 
		Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
		Data[DestGUID].DMG.dmgTaken_M = Data[DestGUID].DMG.dmgTaken_M + Amount
		-- Done 
		Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
		Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
		-- Real Time Damage 
		Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount
		Data[DestGUID].RealDMG.dmgTaken_M = Data[DestGUID].RealDMG.dmgTaken_M + Amount
		Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
		Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount        
	elseif school == 1 then
		-- Pysichal
		-- Taken 
		Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
		-- Done 
		Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
		-- Real Time Damage 
		Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount        
		Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount        
	else
		-- Magic
		-- Taken
		Data[DestGUID].DMG.dmgTaken_M = Data[DestGUID].DMG.dmgTaken_M + Amount
		-- Done 
		Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
		-- Real Time Damage        
		Data[DestGUID].RealDMG.dmgTaken_M = Data[DestGUID].RealDMG.dmgTaken_M + Amount        
		Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
	end
	-- Totals
	-- Taken 
	Data[DestGUID].DMG.dmgTaken = Data[DestGUID].DMG.dmgTaken + Amount
	Data[DestGUID].DMG.hits_taken = Data[DestGUID].DMG.hits_taken + 1   
	-- Done 
	Data[SourceGUID].DMG.hits_done = Data[SourceGUID].DMG.hits_done + 1
	Data[SourceGUID].DMG.dmgDone = Data[SourceGUID].DMG.dmgDone + Amount
	-- Spells (Only Taken by Player)
	if isPlayer(destFlags) then
		if spellID ~= 0 then 
			if not Data[DestGUID].spell_value[spellID] then 
				Data[DestGUID].spell_value[spellID] = {}
			end 		
			Data[DestGUID].spell_value[spellID].Amount 	= (Data[DestGUID].spell_value[spellID].Amount or 0) + Amount
			Data[DestGUID].spell_value[spellID].TMW 	= TMW.time 
		end 
		if spellName then 
			if not Data[DestGUID].spell_value[spellName] then 
				Data[DestGUID].spell_value[spellName] = {}
			end 
			Data[DestGUID].spell_value[spellName].Amount 	= (Data[DestGUID].spell_value[spellName].Amount or 0) + Amount
			Data[DestGUID].spell_value[spellName].TIME 		= TMW.time
		end 
	end 
	-- Real Time Damage 
	-- Taken
	Data[DestGUID].RealDMG.LastHit_Taken = TMW.time     
	Data[DestGUID].RealDMG.dmgTaken = Data[DestGUID].RealDMG.dmgTaken + Amount
	Data[DestGUID].RealDMG.hits_taken = Data[DestGUID].RealDMG.hits_taken + 1 
	-- Done 
	Data[SourceGUID].RealDMG.LastHit_Done = TMW.time     
	Data[SourceGUID].RealDMG.dmgDone = Data[SourceGUID].RealDMG.dmgDone + Amount
	Data[SourceGUID].RealDMG.hits_done = Data[SourceGUID].RealDMG.hits_done + 1 
	if isPlayer(destFlags) then
		-- DS (Only Taken)
		table.insert(Data[DestGUID].DS, {TIME = TMW.time, Amount = Amount})
		-- Garbage 
		if TMW.time - Data[DestGUID].DS[1].TIME > 10 then 
			for i = #Data[DestGUID].DS, 1, -1 do 
				if TMW.time - Data[DestGUID].DS[i].TIME > 10 then 
					table.remove(Data[DestGUID].DS, i)
				end 
			end 
		end 
	end 
end

--[[ This Logs the swings (damage) for every unit ]]
CombatTracker.logSwing 							= function(...) 
	local Data 							= CombatTracker.Data
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags,_, Amount = CombatLogGetCurrentEventInfo()
	-- Update last  hit time
	Data[DestGUID].DMG.lastHit_taken = TMW.time
	Data[SourceGUID].DMG.lastHit_done = TMW.time
	-- Classic: RealUnitHealth log taken
	if not FriendlyGUIDs[DestGUID] then 
		RealUnitHealth.DamageTaken[DestGUID] = (RealUnitHealth.DamageTaken[DestGUID] or 0) + Amount	
	end 
	-- Damage 
	Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
	Data[DestGUID].DMG.dmgTaken = Data[DestGUID].DMG.dmgTaken + Amount
	Data[DestGUID].DMG.hits_taken = Data[DestGUID].DMG.hits_taken + 1
	Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
	Data[SourceGUID].DMG.dmgDone = Data[SourceGUID].DMG.dmgDone + Amount
	Data[SourceGUID].DMG.hits_done = Data[SourceGUID].DMG.hits_done + 1
	-- Real Time Damage 
	-- Taken
	Data[DestGUID].RealDMG.LastHit_Taken = TMW.time 
	Data[DestGUID].RealDMG.dmgTaken_S = Data[DestGUID].RealDMG.dmgTaken_S + Amount
	Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount
	Data[DestGUID].RealDMG.dmgTaken = Data[DestGUID].RealDMG.dmgTaken + Amount
	Data[DestGUID].RealDMG.hits_taken = Data[DestGUID].RealDMG.hits_taken + 1  
	-- Done 
	Data[SourceGUID].RealDMG.LastHit_Done = TMW.time     
	Data[SourceGUID].RealDMG.dmgDone_S = Data[SourceGUID].RealDMG.dmgDone_S + Amount
	Data[SourceGUID].RealDMG.dmgDone_P = Data[SourceGUID].RealDMG.dmgDone_P + Amount   
	Data[SourceGUID].RealDMG.dmgDone = Data[SourceGUID].RealDMG.dmgDone + Amount
	Data[SourceGUID].RealDMG.hits_done = Data[SourceGUID].RealDMG.hits_done + 1 
	if isPlayer(destFlags) then 
		-- DS (Only Taken)
		table.insert(Data[DestGUID].DS, {TIME = TMW.time, Amount = Amount})
		-- Garbage 
		if TMW.time - Data[DestGUID].DS[1].TIME > 10 then 
			for i = #Data[DestGUID].DS, 1, -1 do 
				if TMW.time - Data[DestGUID].DS[i].TIME > 10 then 
					table.remove(Data[DestGUID].DS, i)
				end 
			end 
		end 
	end 
end

--[[ This Logs the healing for every unit ]]
CombatTracker.logHealing			 			= function(...) 
	local Data = CombatTracker.Data
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags,_, spellID, spellName, _, Amount = CombatLogGetCurrentEventInfo()
	-- Update last  hit time
	-- Taken 
	Data[DestGUID].HPS.heal_lasttime = TMW.time
	-- Done 
	Data[SourceGUID].HPS.heal_lasttime_done = TMW.time
	-- Classic: RealUnitHealth log taken
	if not FriendlyGUIDs[DestGUID] then 
		local compare = (RealUnitHealth.DamageTaken[DestGUID] or 0) - Amount
		if compare <= 0 then 
			RealUnitHealth.DamageTaken[DestGUID] = 0
		else 
			RealUnitHealth.DamageTaken[DestGUID] = compare
		end 	
	end 
	-- Totals    
	-- Taken 
	Data[DestGUID].HPS.heal_taken = Data[DestGUID].HPS.heal_taken + Amount
	Data[DestGUID].HPS.heal_hits_taken = Data[DestGUID].HPS.heal_hits_taken + 1
	-- Done   
	Data[SourceGUID].HPS.heal_done = Data[SourceGUID].HPS.heal_done + Amount
	Data[SourceGUID].HPS.heal_hits_done = Data[SourceGUID].HPS.heal_hits_done + 1   
	-- Spells (Only Taken)
	if isPlayer(destFlags) then 
		if spellID ~= 0 then 
			if not Data[DestGUID].spell_value[spellID] then 
				Data[DestGUID].spell_value[spellID] = {}
			end 		
			Data[DestGUID].spell_value[spellID].Amount 	= (Data[DestGUID].spell_value[spellID].Amount or 0) + Amount
			Data[DestGUID].spell_value[spellID].TMW 	= TMW.time 
		end 
		if spellName then 
			if not Data[DestGUID].spell_value[spellName] then 
				Data[DestGUID].spell_value[spellName] = {}
			end 
			Data[DestGUID].spell_value[spellName].Amount 	= (Data[DestGUID].spell_value[spellName].Amount or 0) + Amount
			Data[DestGUID].spell_value[spellName].TIME 		= TMW.time
		end 
	end 
end

--[[ This Logs the shields for every unit ]]
CombatTracker.logAbsorb 						= function(...) 
	local Data = CombatTracker.Data
	local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()    
	if auraType == "BUFF" and Amount then
		if spellID ~= 0 then 
			Data[DestGUID].absorb_spells[spellID] 	= (Data[DestGUID].absorb_spells[spellID] or 0) + Amount 
		end 
		if spellName then 
			Data[DestGUID].absorb_spells[spellName] = (Data[DestGUID].absorb_spells[spellName] or 0) + Amount      
		end 
		Data[DestGUID].absorb_total					= Data[DestGUID].absorb_total + Amount
	end    
end

CombatTracker.logUpdateAbsorb 					= function(...) 
	local Data = CombatTracker.Data
	local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, spellName, _, Amount = CombatLogGetCurrentEventInfo()    

	local calc 
	if spellID ~= 0 then 	
		calc = (Data[DestGUID].absorb_spells[spellID] or 0) - Amount
		if calc <= 0 then 
			Data[DestGUID].absorb_spells[spellID] 	= 0
		else 
			Data[DestGUID].absorb_spells[spellID] 	= calc
		end 
	end 
	if spellName then 
		calc = (Data[DestGUID].absorb_spells[spellName] or 0) - Amount  
		if calc <= 0 then 
			Data[DestGUID].absorb_spells[spellName] = 0
		else 	
			Data[DestGUID].absorb_spells[spellName] = calc   
		end 
	end 
	
	calc = Data[DestGUID].absorb_total - Amount 
	if calc <= 0 then 
		Data[DestGUID].absorb_total					= 0
	else 
		Data[DestGUID].absorb_total					= calc
	end 
end

CombatTracker.remove_logAbsorb 					= function(...) 
	local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()
	if auraType == "BUFF" then
		local Data = CombatTracker.Data
		if Data[DestGUID].absorb_spells[spellName] then 
			local compare = Data[DestGUID].absorb_total - Data[DestGUID].absorb_spells[spellName]
			if compare <= 0 then 
				Data[DestGUID].absorb_total			= 0
			else 
				Data[DestGUID].absorb_total			= compare
			end 
		end 
	
		if spellID ~= 0 then 
			Data[DestGUID].absorb_spells[spellID] 	= nil  
		end 
		Data[DestGUID].absorb_spells[spellName] 	= nil      
	end
end

--[[ This Logs the last cast and amount for every unit ]]
CombatTracker.logLastCast 						= function(...) 
	local Data = CombatTracker.Data
	local _,_,_, SourceGUID, _, sourceFlags,_, DestGUID, _,_,_, spellID, spellName = CombatLogGetCurrentEventInfo()
	if isPlayer(sourceFlags) then 
		-- LastCast time
		if spellID ~= 0 then 
			Data[SourceGUID].spell_lastcast_time[spellID] 	= TMW.time 
		end 
		Data[SourceGUID].spell_lastcast_time[spellName]	 	= TMW.time 
		-- Counter 
		if spellID ~= 0 then 
			Data[SourceGUID].spell_counter[spellID] 		= (Data[SourceGUID].spell_counter[spellID] or 0) + 1
		end 
		Data[SourceGUID].spell_counter[spellName] 			= (Data[SourceGUID].spell_counter[spellName] or 0) + 1
	end 
end 

--[[ This Logs the reset on death for every unit ]]
CombatTracker.logDied							= function(...)
	local _,_,_,_,_,_,_, DestGUID, _, destFlags = CombatLogGetCurrentEventInfo()
	CombatTracker.Data[DestGUID] 					= nil
	RealUnitHealth.DamageTaken[DestGUID]			= nil 
	RealUnitHealth.CachedHealthMax[DestGUID] 		= nil
	RealUnitHealth.isHealthWasMaxOnGUID[DestGUID] 	= nil
	RealUnitHealth.SavedHealthPercent[DestGUID] 	= nil 
	if not isPlayer(destFlags) then 
		RealUnitHealth.CachedHealthMaxTemprorary[DestGUID] = nil 
	end 
end	

--[[ This Logs the DR (Diminishing) ]]
CombatTracker.logDR								= function(EVENT, DestGUID, destFlags, spellName)
	if isEnemy(destFlags) then 
		local drCat = DRData:GetCategoryBySpellID(spellName) -- this works for spellName
		if drCat and (DRData:IsPVE(drCat) or isPlayer(destFlags)) then			
			local dr = CombatTracker.Data[DestGUID].DR[drCat]				
			if EVENT == "SPELL_AURA_APPLIED" then 
				-- If something is applied, and the timer is expired,
				-- reset the timer in preparation for the effect falling off
				
				-- Here is has a small bug due specific of release through SPELL_AURA_REFRESH event 
				-- As soon as unit receive applied debuff aura (DR) e.g. this event SPELL_AURA_APPLIED he WILL NOT be diminished until next events such as SPELL_AURA_REFRESH or SPELL_AURA_REMOVED will be triggered
				-- Why this released like that by DRData Lib - I don't know and this probably can be tweaked however I don't have time to pay attention on it 
				-- What's why I added in 1.1 thing named 'Application' so feel free to use it to solve this bug
				if dr and dr.diminished ~= 100 and dr.reset < TMW.time then						
					dr.diminished = 100
					dr.application = 0
					dr.reset = 0
					-- No reason to this:
					--dr.applicationMax = DRData:GetApplicationMax(drCat) 
				end			
			else
				if not dr then
					-- If there isn't already a table, make one
					-- Start it at 1th application because the unit just got diminished
					local diminishedNext, applicationNext, applicationMaxNext = DRData:NextDR(100, drCat)
					if not CombatTracker.Data[DestGUID].DR[drCat] then 
						CombatTracker.Data[DestGUID].DR[drCat] = {}
					end 

					CombatTracker.Data[DestGUID].DR[drCat].diminished = diminishedNext
					CombatTracker.Data[DestGUID].DR[drCat].application = applicationNext
					CombatTracker.Data[DestGUID].DR[drCat].applicationMax = applicationMaxNext
					CombatTracker.Data[DestGUID].DR[drCat].reset = TMW.time + DRData:GetResetTime(drCat)				
				else
					-- Diminish the unit by one tick
					-- Ticks go 100 -> 0						
					if dr.diminished and dr.diminished ~= 0 then
						dr.diminished, dr.application, dr.applicationMax = DRData:NextDR(dr.diminished, drCat)
						dr.reset = TMW.time + DRData:GetResetTime(drCat)
					end
				end				
			end 
		end 
	end 
end 

--[[ These are the events we're looking for and its respective action ]]
CombatTracker.OnEventCLEU 						= {
	["SPELL_DAMAGE"] 						= CombatTracker.logDamage,
	["DAMAGE_SHIELD"] 						= CombatTracker.logDamage,
	["DAMAGE_SPLIT"]						= CombatTracker.logDamage,
	["SPELL_PERIODIC_DAMAGE"] 				= CombatTracker.logDamage,
	["SPELL_BUILDING_DAMAGE"] 				= CombatTracker.logDamage,
	["RANGE_DAMAGE"] 						= CombatTracker.logDamage,
	["SWING_DAMAGE"] 						= CombatTracker.logSwing,
	["ENVIRONMENTAL_DAMAGE"]				= CombatTracker.logEnvironmentalDamage,
	["SPELL_HEAL"] 							= CombatTracker.logHealing,
	["SPELL_PERIODIC_HEAL"] 				= CombatTracker.logHealing,
	["SPELL_AURA_APPLIED"] 					= CombatTracker.logAbsorb,   
	["SPELL_AURA_REFRESH"] 					= CombatTracker.logAbsorb, 
	--["SPELL_ABSORBED"] 					= CombatTracker.logUpdateAbsorb,  -- TODO: Is broken wowpedia tip for args? Why 15th arg amount is a string type??
	["SPELL_AURA_REMOVED"] 					= CombatTracker.remove_logAbsorb,  
	["SPELL_CAST_SUCCESS"] 					= CombatTracker.logLastCast,
	["UNIT_DIED"] 							= CombatTracker.logDied,
	["UNIT_DESTROYED"]						= CombatTracker.logDied,
	["UNIT_DISSIPATES"]						= CombatTracker.logDied,
}

CombatTracker.OnEventDR							= {
	["SPELL_AURA_REMOVED"]					= CombatTracker.logDR,
	["SPELL_AURA_APPLIED"]					= CombatTracker.logDR,
	["SPELL_AURA_REFRESH"]					= CombatTracker.logDR,
}				

-------------------------------------------------------------------------------
-- Locals: UnitTracker
-------------------------------------------------------------------------------
local UnitTracker 								= {
	Data 								= setmetatable({}, { __mode == "kv" }),
	isRegistered 						= {
		[GetSpellInfo(ACTION_CONST_SPELLID_FREEZING_TRAP)] = true,
	},
	isBlink								= {
		[GetSpellInfo(1953)] = true, 
	},
	-- OnEvent 
	UNIT_SPELLCAST_SUCCEEDED			= function(self, SourceGUID, sourceFlags, spellName)
		if self.isRegistered[spellName] and (not self.isRegistered[spellName].inPvP or A.IsInPvP) and (not self.isRegistered[spellName].isFriendly or not isEnemy(sourceFlags)) then		
			if not self.Data[SourceGUID] then 
				self.Data[SourceGUID] = {}
			end 
			
			if not self.Data[SourceGUID][spellName] then 
				self.Data[SourceGUID][spellName] = {}
			end 
			
			self.Data[SourceGUID][spellName].start 			= TMW.time 
			self.Data[SourceGUID][spellName].expire 		= TMW.time + self.isRegistered[spellName].Timer 
			self.Data[SourceGUID][spellName].isFlying 		= true 
			self.Data[SourceGUID][spellName].blackListCLEU 	= self.isRegistered[spellName].blackListCLEU			
		end
	end,
	UNIT_SPELLCAST_SUCCEEDED_PLAYER		= function(self, unitID, spellID)
		if unitID == "player" then 
			local GUID 		= UnitGUID(unitID)
			local spellName = A.GetSpellInfo(spellID)

			if not self.Data[GUID] then 
				self.Data[GUID] = {}
			end 	

			if not self.Data[GUID][spellName] then 
				self.Data[GUID][spellName] = {}
			end 				
			
			if not self.Data[GUID][spellName].isFlying then 
				self.Data[GUID][spellName].start 	= TMW.time 
				self.Data[GUID][spellName].isFlying = true 
			end 
		end 
	end, 
	SPELL_CAST_SUCCESS					= function(self, SourceGUID, sourceFlags, spellName)
		if self.isBlink[spellName] and A.IsInPvP and isEnemy(sourceFlags) and isPlayer(sourceFlags) then 
			if not self.Data[SourceGUID] then 
				self.Data[SourceGUID] = {}
			end 
			
			self.Data[SourceGUID].Blink = TMW.time + 15					
		end 
	end, 
	UNIT_DIED							= function(self, DestGUID)
		self.Data[DestGUID] = nil 
	end,
	RESET_IS_FLYING						= function(self, EVENT, SourceGUID, spellName)
		-- Makes exception for events with _CREATE _FAILED _START since they are point less to be triggered		
		if self.Data[SourceGUID] then 
			if self.Data[SourceGUID][spellName] and self.Data[SourceGUID][spellName].isFlying and (not self.Data[SourceGUID][spellName].blackListCLEU or not self.Data[SourceGUID][spellName].blackListCLEU[EVENT]) and EVENT:match("SPELL") and not EVENT:match("_START") and not EVENT:match("_FAILED") and not EVENT:match("_CREATE") then 
				self.Data[SourceGUID][spellName].isFlying = false 
			end 
		end 
	end, 
}

-------------------------------------------------------------------------------
-- Locals: LossOfControl
-------------------------------------------------------------------------------
local LossOfControl								= {	
	Data 										= {
		["SCHOOL_INTERRUPT"]					= {
			["PHYSICAL"] 						= 0,
			["HOLY"] 							= 0,
			["FIRE"] 							= 0,
			["NATURE"] 							= 0,
			["FROST"] 							= 0,
			["SHADOW"] 							= 0,
			["ARCANE"] 							= 0,
		},	 
		["BANISH"] 								= { Applied = {}, Result = 0 },
		["CHARM"] 								= { Applied = {}, Result = 0 },
		--["CYCLONE"]								= { Applied = {}, Result = 0 },
		--["DAZE"]								= { Applied = {}, Result = 0 },
		["DISARM"]								= { Applied = {}, Result = 0 },
		["DISORIENT"]							= { Applied = {}, Result = 0 },
		["FREEZE"]								= { Applied = {}, Result = 0 },
		["HORROR"]								= { Applied = {}, Result = 0 },
		["INCAPACITATE"]						= { Applied = {}, Result = 0 },
		--["INTERRUPT"]							= { Applied = {}, Result = 0 },
		--["PACIFY"]								= { Applied = {}, Result = 0 },
		--["PACIFYSILENCE"]						= { Applied = {}, Result = 0 }, 
		["POLYMORPH"]							= { Applied = {}, Result = 0 },
		--["POSSESS"]								= { Applied = {}, Result = 0 },
		["SAP"]									= { Applied = {}, Result = 0 },
		["SHACKLE_UNDEAD"]						= { Applied = {}, Result = 0 },
		["SLEEP"]								= { Applied = {}, Result = 0 },
		["SNARE"]								= { Applied = {}, Result = 0 }, 
		["TURN_UNDEAD"]							= { Applied = {}, Result = 0 }, 
		["ROOT"]								= { Applied = {}, Result = 0 }, 
		--["CONFUSE"]								= { Applied = {}, Result = 0 }, 
		["STUN"]								= { Applied = {}, Result = 0 },
		["SILENCE"]								= { Applied = {}, Result = 0 },
		["FEAR"]								= { Applied = {}, Result = 0 }, 
	},
	Aura										= {
		-- [[ ROOT ]] 
		-- Entangling Roots
		[GetSpellInfo(339)]						= "ROOT",
		-- Feral Charge Effect
		[GetSpellInfo(19675)]					= "ROOT",
		-- Improved Wing Clip
		[GetSpellInfo(19229)]					= "ROOT",
		-- Entrapment
		[GetSpellInfo(19185)]					= "ROOT",
		-- Boar Charge
		[GetSpellInfo(25999)]					= "ROOT",
		-- Frost Nova
		[GetSpellInfo(122)]						= "ROOT",
		-- Frostbite
		[GetSpellInfo(12494)]					= "ROOT",
		-- Improved Hamstring
		[GetSpellInfo(23694)]					= "ROOT",
		-- Trap
		[GetSpellInfo(8312)]					= "ROOT",
		-- Mobility Malfunction
		[GetSpellInfo(8346)]					= "ROOT",
		-- Net-o-Matic
		[GetSpellInfo(13099)]					= "ROOT",
		-- Fire Blossom
		[GetSpellInfo(19636)]					= "ROOT",
		-- Paralyze
		[GetSpellInfo(23414)]					= "ROOT",
		-- Chains of Ice
		[GetSpellInfo(113)]						= "ROOT",
		-- Grasping Vines
		[GetSpellInfo(8142)]					= "ROOT",
		-- Soul Drain
		[GetSpellInfo(7295)]					= "ROOT",
		-- Net
		[GetSpellInfo(6533)]					= "ROOT",
		-- Electrified Net
		[GetSpellInfo(11820)]					= "ROOT",
		-- Ice Blast
		[GetSpellInfo(11264)]					= "ROOT",
		-- Earthgrab
		[GetSpellInfo(8377)]					= "ROOT",
		-- Web Spray
		[GetSpellInfo(12252)]					= "ROOT",
		-- Web
		[GetSpellInfo(745)]						= "ROOT",
		-- Web Explosion
		[GetSpellInfo(15474)]					= "ROOT",
		-- Hooked Net
		[GetSpellInfo(14030)]					= "ROOT",
		-- Encasing Webs
		[GetSpellInfo(4962)]					= "ROOT",
		
		-- [[ SNARE ]]
		-- Wing Clip
		[GetSpellInfo(2974)]					= "SNARE",
		-- Concussive Shot
		[GetSpellInfo(5116)]					= "SNARE",
		-- Dazed
		[GetSpellInfo(15571)]					= "SNARE", -- FIX ME: Can be DAZE 
		-- Frost Trap
		[GetSpellInfo(13809)]					= "SNARE",
		-- Frost Trap Aura
		[GetSpellInfo(13810)]					= "SNARE",
		-- Blizzard
		[GetSpellInfo(10)]						= "SNARE",
		-- Cone of Cold
		[GetSpellInfo(120)]						= "SNARE",
		-- Frostbolt
		[GetSpellInfo(116)]						= "SNARE",
		-- Blast Wave
		[GetSpellInfo(11113)]					= "SNARE",
		-- Mind Flay
		[GetSpellInfo(15407)]					= "SNARE",
		-- Crippling Poison
		[GetSpellInfo(3409)]					= "SNARE",
		-- Frost Shock
		[GetSpellInfo(8056)]					= "SNARE",
		-- Earthbind
		[GetSpellInfo(3600)]					= "SNARE",
		-- Curse of Exhaustion
		[GetSpellInfo(18223)]					= "SNARE",
		-- Aftermath
		[GetSpellInfo(18118)]					= "SNARE",
		-- Cripple
		[GetSpellInfo(89)]						= "SNARE",
		-- Hamstring
		[GetSpellInfo(1715)]					= "SNARE",
		-- Long Daze
		[GetSpellInfo(12705)]					= "SNARE",
		-- Piercing Howl
		[GetSpellInfo(12323)]					= "SNARE",
		-- Curse of Shahram
		[GetSpellInfo(16597)]					= "SNARE",
		-- Magma Shackles
		[GetSpellInfo(19496)]					= "SNARE",		
		-- Suppression Aura
		[GetSpellInfo(22247)]					= "SNARE",	
		-- Thunderclap
		[GetSpellInfo(15548)]					= "SNARE",	
		-- Slow
		[GetSpellInfo(13747)]					= "SNARE",
		-- Brood Affliction: Blue
		[GetSpellInfo(23153)]					= "SNARE",
		-- Molten Metal
		[GetSpellInfo(5213)]					= "SNARE",
		-- Melt Ore
		[GetSpellInfo(5159)]					= "SNARE",		
		-- Frostbolt Volley
		[GetSpellInfo(8398)]					= "SNARE",	
		-- Hail Storm
		[GetSpellInfo(10734)]					= "SNARE",	
		-- Twisted Tranquility
		[GetSpellInfo(21793)]					= "SNARE",	
		-- Frost Shot
		[GetSpellInfo(12551)]					= "SNARE",	
		-- Icicle
		[GetSpellInfo(11131)]					= "SNARE",	
		-- Chilled
		[GetSpellInfo(18101)]					= "SNARE",	
		
		-- [[ STUN ]]
		-- Pounce
		[GetSpellInfo(9005)]					= "STUN",
		-- Bash
		[GetSpellInfo(5211)]					= "STUN",
		-- Starfire Stun
		[GetSpellInfo(16922)]					= "STUN",
		-- Improved Concussive Shot
		[GetSpellInfo(19410)]					= "STUN",
		-- Intimidation
		[GetSpellInfo(24394)]					= "STUN",
		-- Impact
		[GetSpellInfo(12355)]					= "STUN",
		-- Hammer of Justice
		[GetSpellInfo(853)]						= "STUN",
		-- Stun
		[GetSpellInfo(20170)]					= "STUN",
		-- Blackout
		[GetSpellInfo(15269)]					= "STUN",
		-- Kidney Shot
		[GetSpellInfo(408)]						= "STUN",
		-- Cheap Shot
		[GetSpellInfo(1833)]					= "STUN",
		-- Inferno Effect
		[GetSpellInfo(22703)]					= "STUN",
		-- Pyroclasm
		[GetSpellInfo(18093)]					= "STUN",
		-- War Stomp
		[GetSpellInfo(19482)]					= "STUN",
		-- Charge Stun
		[GetSpellInfo(7922)]					= "STUN",
		-- Intercept Stun
		[GetSpellInfo(20253)]					= "STUN",
		-- Mace Stun Effect
		[GetSpellInfo(5530)]					= "STUN",
		-- Revenge Stun
		[GetSpellInfo(12798)]					= "STUN",
		-- Concussion Blow 
		[GetSpellInfo(12809)]					= "STUN",
		-- Stun
		[GetSpellInfo(56)]						= "STUN",
		-- Tidal Charm 
		[GetSpellInfo(835)]						= "STUN",
		-- Rough Copper Bomb
		[GetSpellInfo(4064)]					= "STUN",
		-- Large Copper Bomb
		[GetSpellInfo(4065)]					= "STUN",
		-- Small Bronze Bomb
		[GetSpellInfo(4066)]					= "STUN",
		-- Big Bronze Bomb
		[GetSpellInfo(4067)]					= "STUN",
		-- Iron Grenade
		[GetSpellInfo(4068)]					= "STUN",
		-- Big Iron Bomb
		[GetSpellInfo(4069)]					= "STUN",
		-- The Big One
		[GetSpellInfo(12562)]					= "STUN",
		-- Mithril Frag Bomb
		[GetSpellInfo(12421)]					= "STUN",
		-- Dark Iron Bomb
		[GetSpellInfo(19784)]					= "STUN",
		-- Thorium Grenade
		[GetSpellInfo(19769)]					= "STUN",
		-- M73 Frag Grenade
		[GetSpellInfo(13808)]					= "STUN",
		-- Knockdown
		[GetSpellInfo(15753)]					= "STUN",
		-- Enveloping Winds 
		[GetSpellInfo(15535)]					= "STUN",
		-- Highlord's Justice
		[GetSpellInfo(20683)]					= "STUN",
		-- Crusader's Hammer
		[GetSpellInfo(17286)]					= "STUN",
		-- Might of Shahram
		[GetSpellInfo(16600)]					= "STUN",
		-- Smite Demon
		[GetSpellInfo(13907)]					= "STUN",
		-- Ground Stomp
		[GetSpellInfo(19364)]					= "STUN",
		-- Pyroclast Barrage
		[GetSpellInfo(19641)]					= "STUN",
		-- Fist of Ragnaros
		[GetSpellInfo(20277)]					= "STUN",
		-- Brood Power: Green
		[GetSpellInfo(22289)]					= "STUN",
		-- Time Stop 
		[GetSpellInfo(23171)]					= "STUN",
		-- Tail Lash
		[GetSpellInfo(23364)]					= "STUN",
		-- Aura of Nature
		[GetSpellInfo(25043)]					= "STUN",
		-- Shield Slam
		[GetSpellInfo(8242)]					= "STUN",
		-- Rhahk'Zor Slam
		[GetSpellInfo(6304)]					= "STUN",
		-- Smite Slam
		[GetSpellInfo(6435)]					= "STUN",
		-- Smite Stomp
		[GetSpellInfo(6435)]					= "STUN",
		-- Axe Toss
		[GetSpellInfo(6466)]					= "STUN",
		-- Thundercrack
		[GetSpellInfo(8150)]					= "STUN",
		-- Fel Stomp
		[GetSpellInfo(7139)]					= "STUN",
		-- Ravage
		[GetSpellInfo(8391)]					= "STUN",
		-- Smoke Bomb
		[GetSpellInfo(7964)]					= "STUN",
		-- Backhand
		[GetSpellInfo(6253)]					= "STUN",
		-- Rampage
		[GetSpellInfo(8285)]					= "STUN",
		-- Enveloping Winds
		[GetSpellInfo(6728)]					= "STUN",
		-- Ground Tremor
		[GetSpellInfo(6524)]					= "STUN",
		-- Summon Shardlings
		[GetSpellInfo(21808)]					= "STUN",
		-- Petrify
		[GetSpellInfo(11020)]					= "STUN",
		-- Freeze Solid
		[GetSpellInfo(11836)]					= "STUN",
		-- Lash
		[GetSpellInfo(25852)]					= "STUN",
		-- Paralyzing Poison
		[GetSpellInfo(3609)]					= "STUN",
		-- Hand of Thaurissan
		[GetSpellInfo(17492)]					= "STUN",
		-- Drunken Stupor
		[GetSpellInfo(14870)]					= "STUN",
		-- Chest Pains
		[GetSpellInfo(6945)]					= "STUN",
		-- Skull Crack
		[GetSpellInfo(3551)]					= "STUN",
		-- Snap Kick
		[GetSpellInfo(15618)]					= "STUN",
		-- Throw Axe
		[GetSpellInfo(16075)]					= "STUN",
		-- Crystallize
		[GetSpellInfo(16104)]					= "STUN",
		-- Stun Bomb
		[GetSpellInfo(16497)]					= "STUN",
		-- Ground Smash
		[GetSpellInfo(12734)]					= "STUN",
		-- Burning Winds
		[GetSpellInfo(17293)]					= "STUN",
		-- Ice Tomb
		[GetSpellInfo(16869)]					= "STUN",
		-- Sacrifice
		[GetSpellInfo(22651)]					= "STUN",
		
		-- [[ DISARM ]]
		-- Riposte
		[GetSpellInfo(14251)]					= "DISARM",
		-- Disarm
		[GetSpellInfo(676)]						= "DISARM",		
		-- Dropped Weapon
		[GetSpellInfo(23365)]					= "DISARM",	
		
		-- [[ SLEEP ]]
		-- Hibernate
		[GetSpellInfo(2637)]					= "SLEEP",
		-- Wyvern Sting
		[GetSpellInfo(19386)]					= "SLEEP",
		-- Sleep
		[GetSpellInfo(9159)]					= "SLEEP",
		-- Dreamless Sleep Potion
		[GetSpellInfo(15822)]					= "SLEEP",
		-- Calm Dragonkin
		[GetSpellInfo(19872)]					= "SLEEP",
		-- Druid's Slumber
		[GetSpellInfo(8040)]					= "SLEEP",
		-- Naralex's Nightmare
		[GetSpellInfo(7967)]					= "SLEEP",
		-- Deep Sleep
		[GetSpellInfo(9256)]					= "SLEEP",
		-- Enchanting Lullaby
		[GetSpellInfo(16798)]					= "SLEEP",
		-- Crystalline Slumber
		[GetSpellInfo(3636)]					= {"STUN", "SLEEP"},
		
		-- [[ INCAPACITATE ]] 
		-- Mangle
		[GetSpellInfo(22570)]					= "INCAPACITATE",
		-- Repentance
		[GetSpellInfo(20066)]					= "INCAPACITATE",
		-- Gouge
		[GetSpellInfo(1776)]					= "INCAPACITATE",
		-- Reckless Charge
		[GetSpellInfo(13327)]					= "INCAPACITATE",
		
		-- [[ FREEZE ]] 
		-- Freezing Trap Effect
		[GetSpellInfo(3355)]					= "FREEZE",
		-- Freeze
		[GetSpellInfo(5276)]					= {"STUN", "FREEZE"},
		
		-- [[ DISORIENT ]]
		-- Scatter Shot
		[GetSpellInfo(19503)]					= "DISORIENT",
		-- Blind
		[GetSpellInfo(2094)]					= "DISORIENT",
		-- Glimpse of Madness
		[GetSpellInfo(26108)]					= "DISORIENT",
		-- Ancient Despair
		[GetSpellInfo(19369)]					= "DISORIENT",
		
		-- [[ SILENCE ]]
		-- Counterspell - Silenced
		[GetSpellInfo(18469)]					= "SILENCE",
		-- Silence 
		[GetSpellInfo(15487)]					= "SILENCE",
		-- Kick - Silenced
		[GetSpellInfo(18425)]					= "SILENCE",
		-- Spell Lock (Felhunter)
		[GetSpellInfo(24259)]					= "SILENCE",
		-- Arcane Bomb
		[GetSpellInfo(19821)]					= "SILENCE",
		-- Silence (Silent Fang sword)
		[GetSpellInfo(18278)]					= "SILENCE",
		-- Soul Burn
		[GetSpellInfo(19393)]					= "SILENCE",
		-- Screams of the Past
		[GetSpellInfo(7074)]					= "SILENCE",
		-- Sonic Burst
		[GetSpellInfo(8281)]					= "SILENCE",
		-- Putrid Stench
		[GetSpellInfo(12946)]					= "SILENCE",	
		-- Banshee Shriek
		[GetSpellInfo(16838)]					= "SILENCE",		
		
		-- [[ HORROR ]] (on mechanic Fleeing)
		-- Psychic Scream
		[GetSpellInfo(8122)]					= {"FEAR", "HORROR"},
		-- Howl of Terror
		[GetSpellInfo(5484)]					= {"FEAR", "HORROR"},
		-- Death Coil
		[GetSpellInfo(6789)]					= {"FEAR", "HORROR"},
		-- Intimidating Shout
		[GetSpellInfo(5246)]					= {"FEAR", "HORROR"},
		-- Flash Bomb
		[GetSpellInfo(5134)]					= {"FEAR", "HORROR"},
		-- Corrupted Fear
		[GetSpellInfo(21330)]					= {"FEAR", "HORROR"},
		-- Bellowing Roar
		[GetSpellInfo(18431)]					= {"FEAR", "HORROR"},	
		-- Terrify
		[GetSpellInfo(7399)]					= {"FEAR", "HORROR"},		
		-- Repulsive Gaze
		[GetSpellInfo(21869)]					= {"FEAR", "HORROR"},	
		
		-- [[ FEAR ]]
		-- Fear
		[GetSpellInfo(5782)]					= "FEAR",
		
		-- [[ TURN_UNDEAD ]]
		-- Turn Undead
		[GetSpellInfo(2878)]					= {"FEAR", "TURN_UNDEAD"},
		
		-- [[ POLYMORPH ]]
		-- Polymorph
		[GetSpellInfo(118)]						= "POLYMORPH",
		-- Polymorph: Sheep
		[GetSpellInfo(851)]						= "POLYMORPH",
		-- Polymorph: Cow
		[GetSpellInfo(28270)]					= "POLYMORPH",
		-- Polymorph: Turtle
		[GetSpellInfo(28271)]					= "POLYMORPH",
		-- Polymorph: Pig
		[GetSpellInfo(28272)]					= "POLYMORPH",
		-- Polymorph: Chicken
		[GetSpellInfo(228)]						= "POLYMORPH",
		-- Polymorph Backfire
		[GetSpellInfo(28406)]					= "POLYMORPH",
		-- Greater Polymorph
		[GetSpellInfo(22274)]					= "POLYMORPH",
		-- Hex
		[GetSpellInfo(17172)]					= "POLYMORPH",
		-- Hex of Jammal'an
		[GetSpellInfo(12480)]					= "POLYMORPH",
		
		-- [[ CHARM ]]
		-- Mind Control
		[GetSpellInfo(605)]						= "CHARM",
		-- Seduction
		[GetSpellInfo(6358)]					= "CHARM",
		-- Gnomish Mind Control Cap
		[GetSpellInfo(13181)]					= "CHARM",
		-- Dominion of Soul
		[GetSpellInfo(16053)]					= "CHARM",
		-- Dominate Mind
		[GetSpellInfo(15859)]					= "CHARM",
		-- Shadow Command
		[GetSpellInfo(22667)]					= "CHARM",
		-- Creature of Nightmare
		[GetSpellInfo(25806)]					= "CHARM",
		-- Cause Insanity
		[GetSpellInfo(12888)]					= "CHARM",
		-- Domination
		[GetSpellInfo(17405)]					= "CHARM",
		-- Possess
		[GetSpellInfo(17244)]					= "CHARM",
		-- Arugal's Curse
		[GetSpellInfo(7621)]					= {"POLYMORPH", "CHARM"},
		
		-- [[ SHACKLE_UNDEAD ]]
		-- Shackle Undead 
		[GetSpellInfo(9484)]					= "SHACKLE_UNDEAD",
		
		-- [[ SAP ]]
		-- Sap
		[GetSpellInfo(6770)]					= {"INCAPACITATE", "SAP"},
		
		-- [[ BANISH ]] 
		-- Banish
		[GetSpellInfo(710)]						= "BANISH",
	},
	Interrupt									= {
		-- Shield Bash 
		[GetSpellInfo(72)]						= 6,
		-- Pummel
		[GetSpellInfo(6552)]					= 4,
		-- Kick
		[GetSpellInfo(1766)]					= 5,
		-- Counterspell
		[GetSpellInfo(2139)]					= 10,
		-- Earth Shock 
		[GetSpellInfo(8042)]					= 2,
		-- Spell Lock
		[GetSpellInfo(19647)]					= 8,
		-- Feral Charge
		[GetSpellInfo(19675)]					= 4,
	},
	BitBandSchool								= {
		[0x1]									= "PHYSICAL",
		[0x2]									= "HOLY",
		[0x4]									= "FIRE",
		[0x8]									= "NATURE",
		[0x10]									= "FROST",
		[0x20]									= "SHADOW",
		[0x40]									= "ARCANE",
	},
	Enumerate									= function(self, action, aura, ...)
		local Expiration = 0
		if action == "Add" then 
			local _, Name, expirationTime
			for j = 1, huge do 
				Name, _, _, _, _, expirationTime = UnitDebuff("player", j)
				if not Name then 
					Expiration = 0
					break 
				elseif Name == aura then 
					Expiration = expirationTime == 0 and huge or expirationTime
					break
				end 
			end 
		end 
		
		local isTable = type(self.Aura[aura]) == "table"
		for i = 1, isTable and #self.Aura[aura] or 1 do
			local locType = isTable and self.Aura[aura][i] or self.Aura[aura]
			if Expiration > self.Data[locType].Result then 
				-- Applied more longer duration than previous
				self.Data[locType].Result = Expiration
				self.Data[locType].Applied[aura] = Expiration	
			elseif Expiration == 0 then 
				-- Removed 
				self.Data[locType].Applied[aura] = nil
				
				-- Recheck if persistent another loss of control and update expirationTime, otherwise 0 if nothing
				local maxExpiration = 0
				if next(self.Data[locType].Applied) then 					
					for k, v in pairs(self.Data[locType].Applied) do 
						if maxExpiration == 0 or v > maxExpiration then 
							maxExpiration = v 
						end 
					end 					
				end 
				
				self.Data[locType].Result = maxExpiration				
			else	
				-- Applied more shorter duration if previous is longer 
				self.Data[locType].Applied[aura] = Expiration
			end 
		end 
	end, 
	OnEventInterrupt 							= function(self, spellName, lockSchool) 
		self.Data["SCHOOL_INTERRUPT"][lockSchool] = TMW.time + self.Interrupt[spellName]
	end, 
}

LossOfControl.OnEvent 							= {
	-- Add 
	SPELL_AURA_APPLIED 							= function(aura) LossOfControl:Enumerate("Add", aura) end,
	SPELL_AURA_APPLIED_DOSE 					= function(aura) LossOfControl:Enumerate("Add", aura) end, 
	SPELL_AURA_REFRESH 							= function(aura) LossOfControl:Enumerate("Add", aura) end,
	-- Remove 
	SPELL_AURA_REMOVED							= function(aura) LossOfControl:Enumerate("Remove", aura) end, 
	--SPELL_AURA_REMOVED_DOSE 					= function(aura) LossOfControl:Enumerate("Remove", aura) end, -- FIX ME: Do we need this?
	-- Interrupt
	SPELL_INTERRUPT								= function(spellName, lockSchool) LossOfControl:OnEventInterrupt(spellName, lockSchool) end,
}

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local COMBAT_LOG_EVENT_UNFILTERED 				= function(...)	
	local _, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, spellSchool, auraType = CombatLogGetCurrentEventInfo()
	
	-- Add the unit to our data if we dont have it
	CombatTracker:AddToData(SourceGUID)
	CombatTracker:AddToData(DestGUID) 
	
	-- Trigger 
	if CombatTracker.OnEventCLEU[EVENT] then  
		CombatTracker.OnEventCLEU[EVENT](...)
	end 
	
	-- Diminishing (DR-Tracker)
	if CombatTracker.OnEventDR[EVENT] and auraType == "DEBUFF" then 
		CombatTracker.OnEventDR[EVENT](EVENT, DestGUID, destFlags, spellName)
	end 
	
	-- Loss of Control (Classic only)
	if LossOfControl.OnEvent[EVENT] then 
		if auraType == "DEBUFF" and spellName and LossOfControl.Aura[spellName] and UnitGUID("player") == DestGUID then 
			LossOfControl.OnEvent[EVENT](spellName)
		end 
		
		if EVENT == "SPELL_INTERRUPT" and spellSchool and LossOfControl.Interrupt[spellName] and UnitGUID("player") == DestGUID then 
			local lockSchool = LossOfControl.BitBandSchool[spellSchool] 
			if lockSchool then 
				LossOfControl.OnEvent[EVENT](spellName, lockSchool)
			end 
		end 
	end 
		
	-- PvP players tracker
	if EVENT == "SPELL_CAST_SUCCESS" then  
		-- Blink 
		UnitTracker:SPELL_CAST_SUCCESS(SourceGUID, sourceFlags, spellName)
		-- Other
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(SourceGUID, sourceFlags, spellName)
	end 
	
	if EVENT == "SPELL_MISSED" or EVENT == "SPELL_CREATE" then 
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(SourceGUID, sourceFlags, spellName)
	end 

	-- Reset isFlying
	if EVENT == "UNIT_DIED" or EVENT == "UNIT_DESTROYED" then 
		UnitTracker:UNIT_DIED(DestGUID)
	else 
		local firstFive = strsub(EVENT, 1, 5)
		if firstFive == "SPELL" then 
			UnitTracker:RESET_IS_FLYING(EVENT, SourceGUID, spellName)
		end 
	end 
end 

local UNIT_SPELLCAST_SUCCEEDED					= function(...)
	local unitID, _, spellID = ...
	if unitID == "player" then  
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED_PLAYER(unitID, spellID)
	end 
end

TMW:RegisterCallback("TMW_ACTION_ENTERING",											function()
	if skipedFirstEnter then 
		if not InCombatLockdown() then 
			wipe(UnitTracker.Data)
			wipe(CombatTracker.Data)
			wipe(RealUnitHealth.DamageTaken)
			wipe(RealUnitHealth.CachedHealthMax)
			wipe(RealUnitHealth.isHealthWasMaxOnGUID)
			wipe(RealUnitHealth.CachedHealthMaxTemprorary)
			wipe(RealUnitHealth.SavedHealthPercent)
			logDefaultGUIDatMaxHealthTarget()
		end 
	else 
		skipedFirstEnter = true 
	end 
end)
TMW:RegisterCallback("TMW_ACTION_GROUP_UPDATE",										logDefaultGUIDatMaxHealth			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_TARGET_CHANGED",				logDefaultGUIDatMaxHealthTarget		)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UPDATE_MOUSEOVER_UNIT",				logDefaultGUIDatMaxHealthMouseover	)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "NAME_PLATE_UNIT_ADDED",				CombatTracker.logHealthMax			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_TARGET",						function(...) 
	local unitID = ... 
	CombatTracker.logHealthMax(strElemBuilder(nil, unitID, "target"))
end)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_HEALTH",						CombatTracker.logHealthMax			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_HEALTH_FREQUENT",				CombatTracker.logHealthMax			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_MAXHEALTH",						CombatTracker.logHealthMax			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED", 		COMBAT_LOG_EVENT_UNFILTERED			) 
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_SPELLCAST_SUCCEEDED", 			UNIT_SPELLCAST_SUCCEEDED			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(UnitTracker.Data)
		wipe(CombatTracker.Data)		
	end 
end)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	if A.CombatTracker:GetSpellLastCast("player", A.LastPlayerCastName) > 1.5 and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(UnitTracker.Data)   		
		wipe(CombatTracker.Data) 
	else 
		local GUID = UnitGUID("player")
		if CombatTracker.Data[GUID] then 
			CombatTracker.Data[GUID].combat_time = TMW.time 
		end 
	end 
end)

-------------------------------------------------------------------------------
-- API: CombatTracker
-------------------------------------------------------------------------------
A.CombatTracker									= {
	--[[ Returns the real unit max health ]]
	-- Same functional as on retail (only during recorded logs!)
	UnitHealthMax								= function(self, unitID)
		-- @return number (0 in case if unit dead or if it's not recorded by logs)		
		-- Exception for self because we can self real hp by this func 
		if UnitInAnyGroup(unitID) or UnitIsUnit("player", unitID) or UnitIsUnit("pet", unitID) then 
			return UnitHealthMax(unitID)
		end 
			
		local GUID = UnitGUID(unitID)		
		if RealUnitHealth.CachedHealthMax[GUID] then 
			-- Pre out 			
			return RealUnitHealth.CachedHealthMax[GUID] 
		elseif RealUnitHealth.CachedHealthMaxTemprorary[GUID] then 
			-- Post out 
			return RealUnitHealth.CachedHealthMaxTemprorary[GUID] 
		elseif RealUnitHealth.DamageTaken[GUID] and RealUnitHealth.DamageTaken[GUID] > 0 then			
			-- Broken out 
			local curr_value = RealUnitHealth.DamageTaken[GUID] / (1 - (UnitHealth(unitID) / UnitHealthMax(unitID))) 
			if curr_value > 0 then
				return curr_value				 					
			end 			
		end 

		return 0 
	end,
	--[[ Returns the real unit health ]]
	-- Same functional as on retail (only during recorded logs!)
	UnitHealth									= function(self, unitID)
		-- @return number (0 in case if unit dead or if it's not recorded by logs)
		-- Exception for self because we can self real hp by this func 
		if UnitInAnyGroup(unitID) or UnitIsUnit("player", unitID) or UnitIsUnit("pet", unitID) then  
			return UnitHealth(unitID)
		end 
		
		local GUID = UnitGUID(unitID)		
		
		-- Unit wiped or not recorded 
		if not RealUnitHealth.DamageTaken[GUID] then 
			return 0 
		end 		
		
		if RealUnitHealth.CachedHealthMax[GUID] then 
			-- Pre out 
			local curr_value = RealUnitHealth.CachedHealthMax[GUID] - RealUnitHealth.DamageTaken[GUID] 
			--print("PRE OUT UnitHealth(", unitID, "): ", curr_value)
			if curr_value > 0 then 
				return curr_value
			else 
				return abs(curr_value)	
			end 			
			-- Way which more accurate (in case if CLEU missed something in damage / healing log) but required more performance 
			--return UnitHealth(unitID) * RealUnitHealth.CachedHealthMax[GUID] / UnitHealthMax(unitID)
		elseif RealUnitHealth.CachedHealthMaxTemprorary[GUID] then 
			-- Post out 
			local curr_value = RealUnitHealth.CachedHealthMaxTemprorary[GUID] - RealUnitHealth.DamageTaken[GUID]
			--print("POST POST OUT UnitHealth(", unitID, "): ", curr_value)
			if curr_value > 0 then 
				return curr_value
			else 
				return abs(curr_value)
			end 
		elseif RealUnitHealth.DamageTaken[GUID] > 0 then 
			-- Broken out
			local curr_hp, max_hp = UnitHealth(unitID), UnitHealthMax(unitID)
			local curr_value = (RealUnitHealth.DamageTaken[GUID] / (1 - (curr_hp / max_hp))) - RealUnitHealth.DamageTaken[GUID] 
			--print("BROKEN OUT UnitHealth(", unitID, "): ", curr_value)
			if curr_value > 0 then 
				return (curr_hp == max_hp or curr_value == huge) and 0 or curr_value
			else 
				return abs((curr_hp == max_hp or curr_value == huge) and 0 or curr_value)
			end 			
		end 
		
		return 0 
	end,
	--[[ Returns the total ammount of time a unit is in-combat for ]]
	CombatTime									= function(self, unitID)
		-- @return number, GUID 
		local unit = unitID or "player"
		local GUID = UnitGUID(unit)
		if CombatTracker.Data[GUID] and ((UnitIsUnit(unit, "player") and InCombatLockdown()) or UnitAffectingCombat(unit)) then     
			return TMW.time - CombatTracker.Data[GUID].combat_time, GUID	               
		end		
		return 0, GUID		
	end, 
	--[[ Get Last X seconds incoming DMG (10 sec max) ]] 
	GetLastTimeDMGX								= function(self, unitID, X)
		local timer 							= X and X or 5
		local GUID, Amount 						= UnitGUID(unitID), 0    
		local Data 								= CombatTracker.Data
		if Data[GUID] and #Data[GUID].DS > 0 then        
			for i = 1, #Data[GUID].DS do
				if Data[GUID].DS[i].TIME >= TMW.time - timer then
					Amount = Amount + Data[GUID].DS[i].Amount 
				end
			end    
		end
		return Amount	
	end, 
	--[[ Get RealTime DMG Taken ]]
	GetRealTimeDMG								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)
		local Data 								= CombatTracker.Data
		if Data[GUID] and combatTime > 0 and Data[GUID].RealDMG.LastHit_Taken > 0 then 
			local realtime 	= TMW.time - Data[GUID].RealDMG.LastHit_Taken
			Hits 			= Data[GUID].RealDMG.hits_taken        
			-- Remove a unit if it hasnt recived dmg for more then our gcd
			if realtime > A.GetGCD() + A.GetCurrentGCD() + 1 then 
				-- Damage Taken 
				Data[GUID].RealDMG.dmgTaken = 0
				Data[GUID].RealDMG.dmgTaken_S = 0
				Data[GUID].RealDMG.dmgTaken_P = 0
				Data[GUID].RealDMG.dmgTaken_M = 0
				Data[GUID].RealDMG.hits_taken = 0
				Data[GUID].RealDMG.lastHit_taken = 0  
			elseif Hits > 0 then                     
				total 	= Data[GUID].RealDMG.dmgTaken / Hits
				phys 	= Data[GUID].RealDMG.dmgTaken_P / Hits
				magic 	= Data[GUID].RealDMG.dmgTaken_M / Hits     
				swing 	= Data[GUID].RealDMG.dmgTaken_S / Hits 
			end
		end
		return total, Hits, phys, magic, swing
	end,
	--[[ Get RealTime DMG Done ]]	
	GetRealTimeDPS								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)
		local Data 								= CombatTracker.Data
		if Data[GUID] and combatTime > 0 and Data[GUID].RealDMG.LastHit_Done > 0 then   
			local realtime 	= TMW.time - Data[GUID].RealDMG.LastHit_Done
			Hits 			= Data[GUID].RealDMG.hits_done
			-- Remove a unit if it hasnt done dmg for more then our gcd
			if realtime >  A.GetGCD() + A.GetCurrentGCD() + 1 then 
				-- Damage Done
				Data[GUID].RealDMG.dmgDone = 0
				Data[GUID].RealDMG.dmgDone_S = 0
				Data[GUID].RealDMG.dmgDone_P = 0
				Data[GUID].RealDMG.dmgDone_M = 0
				Data[GUID].RealDMG.hits_done = 0
				Data[GUID].RealDMG.LastHit_Done = 0 
			elseif Hits > 0 then                         
				total 	= Data[GUID].RealDMG.dmgDone / Hits
				phys 	= Data[GUID].RealDMG.dmgDone_P / Hits
				magic 	= Data[GUID].RealDMG.dmgDone_M / Hits  
				swing 	= Data[GUID].RealDMG.dmgDone_S / Hits 
			end
		end
		return total, Hits, phys, magic, swing
	end,	
	--[[ Get DMG Taken ]]
	GetDMG										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)
		local Data 								= CombatTracker.Data
		if Data[GUID] then
			-- Remove a unit if it hasn't recived dmg for more then 5 sec
			if TMW.time - Data[GUID].DMG.lastHit_taken > 5 then   
				-- Damage Taken 
				Data[GUID].DMG.dmgTaken = 0
				Data[GUID].DMG.dmgTaken_S = 0
				Data[GUID].DMG.dmgTaken_P = 0
				Data[GUID].DMG.dmgTaken_M = 0
				Data[GUID].DMG.hits_taken = 0
				Data[GUID].DMG.lastHit_taken = 0            
			elseif combatTime > 0 then
				total 	= Data[GUID].DMG.dmgTaken / combatTime
				phys 	= Data[GUID].DMG.dmgTaken_P / combatTime
				magic 	= Data[GUID].DMG.dmgTaken_M / combatTime
				Hits 	= Data[GUID].DMG.hits_taken or 0
			end
		end
		return total, Hits, phys, magic 
	end,
	--[[ Get DMG Done ]]
	GetDPS										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local GUID 								= UnitGUID(unitID)
		local Data 								= CombatTracker.Data
		if Data[GUID] then
			Hits = Data[GUID].DMG.hits_done        
			-- Remove a unit if it hasn't done dmg for more then 5 sec
			if TMW.time - Data[GUID].DMG.lastHit_done > 5 then                    
				-- Damage Done
				Data[GUID].DMG.dmgDone = 0
				Data[GUID].DMG.dmgDone_S = 0
				Data[GUID].DMG.dmgDone_P = 0
				Data[GUID].DMG.dmgDone_M = 0
				Data[GUID].DMG.hits_done = 0
				Data[GUID].DMG.lastHit_done = 0            
			elseif Hits > 0 then
				total 	= Data[GUID].DMG.dmgDone / Hits
				phys 	= Data[GUID].DMG.dmgDone_P / Hits
				magic 	= Data[GUID].DMG.dmgDone_M / Hits            
			end
		end
		return total, Hits, phys, magic
	end,
	--[[ Get Heal Taken ]]
	GetHEAL										= function(self, unitID)
		local total, Hits 						= 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)
		local Data 								= CombatTracker.Data
		if Data[GUID] then
			-- Remove a unit if it hasn't recived heal for more then 5 sec
			if TMW.time - Data[GUID].HPS.heal_lasttime > 5 then            
				-- Heal Taken 
				Data[GUID].HPS.heal_taken = 0
				Data[GUID].HPS.heal_hits_taken = 0
				Data[GUID].HPS.heal_lasttime = 0            
			elseif combatTime > 0 then
				Hits 	= Data[GUID].HPS.heal_hits_taken
				total 	= Data[GUID].HPS.heal_taken / Hits                              
			end
		end
		return total, Hits      
	end,
	--[[ Get Heal Done ]]	
	GetHPS										= function(self, unitID)
		local total, Hits 						= 0, 0
		local GUID 								= UnitGUID(unitID)   
		local Data 								= CombatTracker.Data
		if Data[GUID] then
			Hits = Data[GUID].HPS.heal_hits_done
			-- Remove a unit if it hasn't done heal for more then 5 sec
			if TMW.time - Data[GUID].HPS.heal_lasttime_done > 5 then            
				-- Healing Done
				Data[GUID].HPS.heal_done = 0
				Data[GUID].HPS.heal_hits_done = 0
				Data[GUID].HPS.heal_lasttime_done = 0
			elseif Hits > 0 then             
				total = Data[GUID].HPS.heal_done / Hits 
			end
		end
		return total, Hits      
	end,	
	--[[ Get Spell Amount Taken with time ]]
	GetSpellAmountX								= function(self, unitID, spell, X) 
		local timer 							= X or 5 			
		local total 							= 0
		local GUID 								= UnitGUID(unitID)   
		local Data 								= CombatTracker.Data
		if type(spell) == "number" then 
			spell = A.GetSpellInfo(spell)
		end 
		if Data[GUID] and Data[GUID].spell_value[spell] then
			if TMW.time - Data[GUID].spell_value[spell].TIME <= timer then 
				total = Data[GUID].spell_value[spell].Amount
			else
				Data[GUID].spell_value[spell] = nil
			end 
		end		
		return total  
	end,
	--[[ Get Spell Amount Taken over time (if didn't called upper function with timer) ]]
	GetSpellAmount								= function(self, unitID, spell)
		local GUID 								= UnitGUID(unitID) 
		local Data 								= CombatTracker.Data
		if type(spell) == "number" then 
			spell = A.GetSpellInfo(spell)
		end 		
		return (Data[GUID] and Data[GUID].spell_value[spell] and Data[GUID].spell_value[spell].Amount) or 0
	end,	
	--[[ This is tracks CLEU spells only if they was applied/missed/reflected e.g. received in any form by end unit to feedback that info ]]
	--[[ Instead of this function for spells which have flying but wasn't received by end unit, since spell still in the fly, you need use A.UnitCooldown ]]		
	GetSpellLastCast 							= function(self, unitID, spell)
		-- @return number, number 
		-- time in seconds since last cast, timestamp of start 
		local GUID 								= UnitGUID(unitID) 
		local Data 								= CombatTracker.Data
		if type(spell) == "number" then 
			spell = A.GetSpellInfo(spell)
		end 		
		if Data[GUID] and Data[GUID].spell_lastcast_time[spell] then 
			local start = Data[GUID].spell_lastcast_time[spell] or 0
			return TMW.time - start, start 
		end 
		return huge, 0 -- huge in Classic! Retail will be 0 
	end,
	--[[ Get Count Spell of total used during fight ]]
	GetSpellCounter								= function(self, unitID, spell)
		local counter 							= 0
		local GUID 								= UnitGUID(unitID)
		local Data 								= CombatTracker.Data
		if type(spell) == "number" then 
			spell = A.GetSpellInfo(spell)
		end 		
		if Data[GUID] then
			counter = Data[GUID].spell_counter[spell] or 0
		end 
		return counter
	end,
	--[[ Get Absorb Taken ]]
	GetAbsorb									= function(self, unitID, spell)
		local GUID	 							= UnitGUID(unitID)
		local Data 								= CombatTracker.Data
		if type(spell) == "number" then 
			spell = A.GetSpellInfo(spell)
		end 		
		if GUID and Data[GUID] then 
			if spell and Data[GUID].absorb_spells[spell] then 		
				return Data[GUID].absorb_spells[spell]
			else
				return Data[GUID].absorb_total
			end 
		end 
			
		return 0
	end,
	--[[ Get DR: Diminishing (only enemy) ]]
	GetDR 										= function(self, unitID, drCat)
		-- @return Tick (number: 100% -> 0%), Remain (number: 0 -> 18), Application (number: 0 -> 5), ApplicationMax (number: 0 -> 5)
		--[[ drCat accepts:
			"root"         
			"random_root"
			"stun"      		-- PvE unlocked     
			"opener_stun"
			"random_stun"		-- PvE unlocked
			"disorient"      
			"disarm" 			-- added in original DRList		   
			"silence"        
			"fear"   
			"incapacitate"   
			"knockback" 
			"death_coil"
			"mind_control"
			"frost_shock"
			"entrapment"
			"charge"	
		]]
		local GUID 								= UnitGUID(unitID)
		local Data 								= CombatTracker.Data
		-- Default 100% means no DR at all, and 0 if no ticks then no remaning time, Application is how much DR was applied and how much by that category can be applied totally 
		local DR_Tick, DR_Remain, DR_Application, DR_ApplicationMax = 100, 0, 0, DRData:GetApplicationMax(drCat)  	
		-- About Tick:
		-- Ticks go like 100 -> 50 -> 25 -> 0 or for Taunt 100 -> 65 -> 42 -> 27 -> 0
		-- 100 no DR, 0 full DR 
		if Data[GUID] and Data[GUID].DR and Data[GUID].DR[drCat] and Data[GUID].DR[drCat].reset and Data[GUID].DR[drCat].reset >= TMW.time then 
			DR_Tick 			= Data[GUID].DR[drCat].diminished
			DR_Remain 			= Data[GUID].DR[drCat].reset - TMW.time
			DR_Application 		= Data[GUID].DR[drCat].application
			DR_ApplicationMax 	= Data[GUID].DR[drCat].applicationMax
		end 
		
		return DR_Tick, DR_Remain, DR_Application, DR_ApplicationMax	
	end, 
	--[[ Time To Die ]]
	TimeToDieX									= function(self, unitID, X)
		local UNIT 								= unitID and unitID or "target"
		local ttd 								= A.CombatTracker:UnitHealth(UNIT) - ( A.CombatTracker:UnitHealthMax(UNIT) * (X / 100) )
		local DMG, Hits 						= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = ttd / DMG
			if ttd <= 0 then 
				return 500
			end 			
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
	TimeToDie									= function(self, unitID)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.CombatTracker:UnitHealthMax(UNIT)
		local DMG, Hits 						= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = A.CombatTracker:UnitHealth(UNIT) / DMG
			if ttd <= 0 then 
				return 500
			end 
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
	TimeToDieMagicX								= function(self, unitID, X)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.CombatTracker:UnitHealth(UNIT) - ( A.CombatTracker:UnitHealthMax(UNIT) * (X / 100) )
		local _, Hits, _, DMG 					= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = ttd / DMG
			if ttd <= 0 then 
				return 100
			end 			
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500 
	end,
	TimeToDieMagic								= function(self, unitID)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.CombatTracker:UnitHealthMax(UNIT)
		local _, Hits, _, DMG 					= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = A.CombatTracker:UnitHealth(UNIT) / DMG
			if ttd <= 0 then 
				return 100
			end 			
		end  
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
	--[[ Debug Real Health ]]
	Debug 										= function(self, command)
		local cmd = command:lower()
		if cmd == "wipe" then 
			local GUID = UnitGUID("target")
			if GUID then 
				RealUnitHealth.DamageTaken[GUID] = nil 
				RealUnitHealth.CachedHealthMax[GUID] = nil 
				RealUnitHealth.isHealthWasMaxOnGUID[GUID] = nil 
				RealUnitHealth.CachedHealthMaxTemprorary[GUID] = nil 
				RealUnitHealth.SavedHealthPercent[GUID] = nil 
				logDefaultGUIDatMaxHealthTarget()
			end 
		elseif cmd == "data" then 
			return RealUnitHealth
		end 
	end, 
}

-------------------------------------------------------------------------------
-- API: UnitCooldown
-------------------------------------------------------------------------------
A.UnitCooldown 									= {
	Register							= function(self, spellName, timer, isFriendlyArg, inPvPArg, CLEUbl)	
		-- unit accepts "arena", "raid", "party", their number 		
		-- isFriendlyArg, inPvPArg are optional		
		-- CLEUbl is a table = { ['Event_CLEU'] = true, } which to skip and don't reset by them in fly
		if UnitTracker.isBlink[spellName] then 
			A.Print("[Error] Can't register Blink or Shrimmer because they are already registered. Please use function Action.UnitCooldown:GetBlinkOrShrimmer(unitID)")
			return 
		end 		
		
		local inPvP 	 = inPvPArg 
		local isFriendly = isFriendlyArg
		
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		UnitTracker.isRegistered[spellName] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl } 	
	end,
	UnRegister							= function(self, spellName)	
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		UnitTracker.isRegistered[spellName] = nil 
		wipe(UnitTracker.Data)
	end,		
	GetCooldown							= function(self, unit, spellName)		
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched)
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].expire then 
					if UnitTracker.Data[GUID][spellName].expire >= TMW.time then 
						return UnitTracker.Data[GUID][spellName].expire - TMW.time, UnitTracker.Data[GUID][spellName].start
					else 
						return 0, UnitTracker.Data[GUID][spellName].start
					end 
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].expire then 
				if UnitTracker.Data[GUID][spellName].expire >= TMW.time then 
					return UnitTracker.Data[GUID][spellName].expire - TMW.time, UnitTracker.Data[GUID][spellName].start
				else 
					return 0, UnitTracker.Data[GUID][spellName].start
				end 
			end 	
		end
		return 0, 0
	end,
	GetMaxDuration						= function(self, unit, spellName)
		-- @return number (max cooldown of the spell on a unit)
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].expire then 
					return UnitTracker.Data[GUID][spellName].expire - UnitTracker.Data[GUID][spellName].start
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].expire then 
				return UnitTracker.Data[GUID][spellName].expire - UnitTracker.Data[GUID][spellName].start
			end 
		end
		return 0		
	end,
	GetUnitID 							= function(self, unit, spellName)
		-- @return unitID (who last casted spell) otherwise nil  
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].expire and UnitTracker.Data[GUID][spellName].expire - TMW.time >= 0 then 
					return unitID
				end
			end 
		end 
	end,
	--[[ Mage Shrimmer/Blink Tracker (only enemy) ]]
	GetBlinkOrShrimmer					= function(self, unit)
		-- @return number, number, number 
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown     			
		local charges, cooldown, summary_cooldown = 1, 0, 0  
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] then 
					if UnitTracker.Data[GUID].Shrimmer then 
						charges = 2
						for i = #UnitTracker.Data[GUID].Shrimmer, 1, -1 do
							cooldown = UnitTracker.Data[GUID].Shrimmer[i] - TMW.time
							if cooldown > 0 then
								charges = charges - 1
								summary_cooldown = summary_cooldown + cooldown												
							end            
						end 
						break 
					elseif UnitTracker.Data[GUID].Blink then 
						cooldown = UnitTracker.Data[GUID].Blink - TMW.time
						if cooldown <= 0 then 
							cooldown = 0 
						else 
							charges = 0
							summary_cooldown = cooldown
						end 
						break 
					end 
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] then 
				if UnitTracker.Data[GUID].Shrimmer then 
					charges = 2
					for i = #UnitTracker.Data[GUID].Shrimmer, 1, -1 do
						cooldown = UnitTracker.Data[GUID].Shrimmer[i] - TMW.time
						if cooldown > 0 then
							charges = charges - 1
							summary_cooldown = summary_cooldown + cooldown												
						end            
					end 					
				elseif UnitTracker.Data[GUID].Blink then 
					cooldown = UnitTracker.Data[GUID].Blink - TMW.time
					if cooldown <= 0 then 
						cooldown = 0 
					else 
						charges = 0
						summary_cooldown = cooldown
					end 					 
				end 
			end 		
		end
		return charges, cooldown, summary_cooldown	
	end, 
	--[[ Is In Flying Spells Tracker ]]
	IsSpellInFly						= function(self, unit, spellName)
		-- @return boolean 
		if type(spellName) == "number" then 
			spellName = A.GetSpellInfo and A.GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] and UnitTracker.Data[GUID][spellName].isFlying then 
					return true
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellName] then 
				return UnitTracker.Data[GUID][spellName].isFlying
			end 
		end
		return false 
	end,
}
 
-- Tracks Freezing Trap 
A.UnitCooldown:Register(ACTION_CONST_SPELLID_FREEZING_TRAP, 15, nil, nil, {
	["SPELL_CAST_SUCCESS"] = true,		
})

-------------------------------------------------------------------------------
-- API: LossOfControl
-------------------------------------------------------------------------------
A.LossOfControl									= {
	Get											= function(self,  locType, name)
		-- @return number (remain duration in seconds of LossOfControl)	
		if LossOfControl.Data[locType] then 
			if name then 
				if LossOfControl.Data[locType][name] then 
					return math_max(LossOfControl.Data[locType][name] - TMW.time, 0)
				end 
			else 
				return math_max(LossOfControl.Data[locType].Result - TMW.time, 0)   
			end 
		end 
		
		return 0	
	end, 
	IsMissed									= function(self, MustBeMissed)
		-- @return boolean 
		local result = true
		if type(MustBeMissed) == "table" then 
			for i = 1, #MustBeMissed do 
				if self:Get(MustBeMissed[i]) > 0 then 
					result = false  
					break 
				end
			end
		else
			result = self:Get(MustBeMissed) == 0
		end 
		return result 
	end,
	IsValid										= function(self, MustBeApplied, MustBeMissed, Exception)
		-- @return boolean (if result is fully okay), boolean (if result is not okay but we can pass it to use another things as remove control)
		local isApplied = false 
		local result = isApplied
		
		for i = 1, #MustBeApplied do 
			if self:Get(MustBeApplied[i]) > 0 then 
				isApplied = true 
				result = isApplied
				break 
			end 
		end 
		
		-- Exception 
		if Exception and not isApplied then 
			-- Dwarf in DeBuffs
			if A.PlayerRace == "Dwarf" then 
				isApplied = A.Unit("player"):HasDeBuffs("Poison") > 0 -- or A.Unit("player"):HasDeBuffs("Disease") > 0 or or A.Unit("player"):HasDeBuffs("Bleeding") > 0 -- these 2 is not added in Unit.lua 
			end
			-- Gnome in current speed 
			if A.PlayerRace == "Gnome" then 
				local cSpeed = A.Unit("player"):GetCurrentSpeed()
				isApplied = cSpeed > 0 and cSpeed < 65
			end 
		end 
		
		if isApplied and MustBeMissed then 
			for i = 1, #MustBeMissed do 
				if self:Get(MustBeMissed[i]) > 0 then 
					result = false 
					break 
				end
			end
		end 
		
		return result, isApplied
	end,
	GetExtra 									= {
		["Dwarf"] 								= {
			Applied 							= {"SLEEP"}, -- Can be sleepd by  Wyvern Sting 
			Missed 								= {"POLYMORPH", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "STUN", "FEAR", "HORROR", "CHARM", "SHACKLE_UNDEAD", "TURN_UNDEAD"},
		},
		["Scourge"] 							= {
			Applied 							= {"FEAR", "HORROR", "SLEEP", "CHARM"}, -- FIX ME: "HORROR" is it works (?)
			Missed 								= {"INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "STUN", "SHACKLE_UNDEAD", "ROOT"}, 
		},
		["Gnome"]	 							= {
			Applied 							= {"ROOT", "SNARE", "DAZE"}, -- Need summary for: "DAZE",  
			Missed 								= {"INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "STUN", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "TURN_UNDEAD"},
		},		
	},	
}

