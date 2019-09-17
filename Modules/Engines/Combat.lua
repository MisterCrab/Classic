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
local DRData 									= LibStub("DRList-1.1")

local huge 										= math.huge 
local abs 										= math.abs 

local _G, type, pairs, table, wipe, bitband  	= 
	  _G, type, pairs, table, wipe, bit.band

local UnitGUID, UnitHealth, UnitHealthMax, UnitAffectingCombat	= 
	  UnitGUID, UnitHealth, UnitHealthMax, UnitAffectingCombat
	  
	  
local InCombatLockdown, CombatLogGetCurrentEventInfo = 
	  InCombatLockdown, CombatLogGetCurrentEventInfo
	  
local cLossOfControl 							= _G.C_LossOfControl
local GetEventInfo 								= cLossOfControl.GetEventInfo
local GetNumEvents 								= cLossOfControl.GetNumEvents	  

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
	local GUID 		= UnitGUID(unitID)
	if not GUID or UnitIsUnit(unitID, "player") or UnitIsUnit(unitID, "pet") then 
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
	RealUnitHealth.DamageTaken[DestGUID] = (RealUnitHealth.DamageTaken[DestGUID] or 0) + Amount	
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
	RealUnitHealth.DamageTaken[DestGUID] = (RealUnitHealth.DamageTaken[DestGUID] or 0) + Amount	
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
	local compare = (RealUnitHealth.DamageTaken[DestGUID] or 0) - Amount
	if compare <= 0 then 
		RealUnitHealth.DamageTaken[DestGUID] = 0
	else 
		RealUnitHealth.DamageTaken[DestGUID] = compare
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
	LastEvent 									= 0,
	["SCHOOL_INTERRUPT"]						= {
		["PHYSICAL"] = {
			bit = 0x1,
			result = 0,
		},
		["HOLY"] = {
			bit = 0x2,
			result = 0,
		},
		["FIRE"] = {
			bit = 0x4,
			result = 0,
		},
		["NATURE"] = {
			bit = 0x8,
			result = 0,
		},
		["FROST"] = {
			bit = 0x10,
			result = 0,		
		},
		["SHADOW"] = {
			bit = 0x20,
			result = 0,			
		},
		["ARCANE"] = {
			bit = 0x40,
			result = 0,			
		},
	},	 
	["BANISH"] 									= 0,
	["CHARM"] 									= 0,
	["CYCLONE"]									= 0,
	["DAZE"]									= 0,
	["DISARM"]									= 0,
	["DISORIENT"]								= 0,
	--["DISTRACT"]								= 0, -- no need 
	["FREEZE"]									= 0,
	["HORROR"]									= 0,
	["INCAPACITATE"]							= 0,
	["INTERRUPT"]								= 0,
	--["INVULNERABILITY"]						= 0,
	--["MAGICAL_IMMUNITY"]						= 0,
	["PACIFY"]									= 0,
	["PACIFYSILENCE"]							= 0, -- "Disabled"
	["POLYMORPH"]								= 0,
	["POSSESS"]									= 0,
	["SAP"]										= 0,
	["SHACKLE_UNDEAD"]							= 0,
	["SLEEP"]									= 0,
	["SNARE"]									= 0, -- "Snared" slow usually example Concussive Shot
	["TURN_UNDEAD"]								= 0, -- "Feared Undead" currently usable in Classic PvP (info: Undead race) 
	--["LOSECONTROL_TYPE_SCHOOLLOCK"] 			= 0, -- HAS SPECIAL HANDLING (per spell school) as "SCHOOL_INTERRUPT"
	["ROOT"]									= 0, -- "Rooted"
	["CONFUSE"]									= 0, -- "Confused" 
	["STUN"]									= 0, -- "Stunned"
	--["STUN_MECHANIC"]							= 0, -- I don't know what is it 
	["SILENCE"]									= 0, -- "Silenced"
	["FEAR"]									= 0, -- "Feared"	
	--["FEAR_MECHANIC"]							= 0, -- I don't know what is it 
	--["TAUNT"]									= 0, -- Not sure if it's required 
}

LossOfControl.OnEvent							= function(...)
    if TMW.time == LossOfControl.LastEvent then
        return
    end
    LossOfControl.LastEvent = TMW.time
    
	local isValidType = false
    for eventIndex = 1, GetNumEvents() do 
        local locType, spellID, text, _, start, timeRemaining, duration, lockoutSchool = GetEventInfo(eventIndex)  			
		
		if LossOfControl[locType] then 
			if locType == "SCHOOL_INTERRUPT" then
				-- Check that the user has requested the schools that are locked out.
				if lockoutSchool and lockoutSchool ~= 0 then 
					for name, val in pairs(LossOfControl[locType]) do
						if bitband(lockoutSchool, val.bit) ~= 0 then 						                 						
							isValidType = true
							LossOfControl[locType][name].result = (start or 0) + (duration or 0)											
						end 
					end 
				end 
			else 
				for name in pairs(LossOfControl) do 
					if _G["LOSS_OF_CONTROL_DISPLAY_" .. name] == text then 
						-- Check that the user has requested the category that is active on the player.
						isValidType = true
						LossOfControl[locType] = (start or 0) + (duration or 0)
						break 
					end 
				end 
			end
		end 
    end 
    
    -- Reset running durations.
    if not isValidType then 
        for name, val in pairs(LossOfControl) do 
            if name ~= "LastEvent" and type(val) == "number" and LossOfControl[name] > 0 then
                LossOfControl[name] = 0
            end            
        end
    end
end

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local COMBAT_LOG_EVENT_UNFILTERED 				= function(...)	
	local _, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, _, auraType = CombatLogGetCurrentEventInfo()
	
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
		UnitTracker:RESET_IS_FLYING(EVENT, SourceGUID, spellName)
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
	local LastTimeCasted = A.CombatTracker:GetSpellLastCast("player", A.LastPlayerCastName) 
	if (LastTimeCasted == 0 or LastTimeCasted > 1.5) and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(UnitTracker.Data)   		
		wipe(CombatTracker.Data) 
	else 
		local GUID = UnitGUID("player")
		if CombatTracker.Data[GUID] then 
			CombatTracker.Data[GUID].combat_time = TMW.time 
		end 
	end 
end)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_UPDATE", 			LossOfControl.OnEvent			)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_ADDED", 				LossOfControl.OnEvent			)

-------------------------------------------------------------------------------
-- API: CombatTracker
-------------------------------------------------------------------------------
A.CombatTracker									= {
	--[[ Returns the real unit max health ]]
	-- Same functional as on retail (only during recorded logs!)
	UnitHealthMax								= function(self, unitID)
		-- @return number (0 in case if unit dead or if it's not recorded by logs)		
		-- Exception for self because we can self real hp by this func 
		if UnitIsUnit("player", unitID) or UnitIsUnit("pet", unitID) then 
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
		if UnitIsUnit("player", unitID) or UnitIsUnit("pet", unitID) then  
			return UnitHealth(unitID)
		end 
		
		local GUID = UnitGUID(unitID)		
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
		elseif RealUnitHealth.DamageTaken[GUID] and RealUnitHealth.DamageTaken[GUID] > 0 then 
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
		return 0, 0 
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
				return 100
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
				return 100
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
		local result = 0		
		if name then 
			result = LossOfControl[locType][name] and LossOfControl[locType][name].result or 0
		else 
			result = LossOfControl[locType] or 0        
		end 
		
		return (TMW.time >= result and 0) or result - TMW.time 		
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
				isApplied = cSpeed > 0 and cSpeed < 100
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
		["Dwarf"] = {
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

