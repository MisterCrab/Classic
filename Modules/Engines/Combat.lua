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
--local InstanceInfo							= A.InstanceInfo
--local TeamCache								= A.TeamCache
--local Azerite 								= LibStub("AzeriteTraits")
--local Pet										= LibStub("PetLibrary")
--local LibRangeCheck  							= LibStub("LibRangeCheck-2.0")
--local SpellRange								= LibStub("SpellRange-1.0")
local DRData 									= LibStub("DRData-1.1")

local _G, type, pairs, table, wipe, bitband  	= 
	  _G, type, pairs, table, wipe, bit.band

local UnitGUID, UnitGetTotalAbsorbs			 	= 
	  UnitGUID, UnitGetTotalAbsorbs
	  
local InCombatLockdown, CombatLogGetCurrentEventInfo = 
	  InCombatLockdown, CombatLogGetCurrentEventInfo
	  
local cLossOfControl 							= _G.C_LossOfControl
local GetEventInfo 								= cLossOfControl.GetEventInfo
local GetNumEvents 								= cLossOfControl.GetNumEvents	  

-------------------------------------------------------------------------------
-- Locals: CombatTracker
-------------------------------------------------------------------------------
local CombatTracker 							= {
	Data			 						= setmetatable({}, { __mode == "kv" }),
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

--[[ This Logs the damage for every unit ]]
CombatTracker.logDamage 						= function(...) 
	local Data = CombatTracker.Data	
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags,_, spellID, spellName, school, Amount = CombatLogGetCurrentEventInfo()	
	-- Update last hit time
	-- Taken 
	Data[DestGUID].DMG.lastHit_taken = TMW.time
	-- Done 
	Data[SourceGUID].DMG.lastHit_done = TMW.time
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
	elseif school == 1  then
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
		if spellID then 
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
	-- Totals    
	-- Taken 
	Data[DestGUID].HPS.heal_taken = Data[DestGUID].HPS.heal_taken + Amount
	Data[DestGUID].HPS.heal_hits_taken = Data[DestGUID].HPS.heal_hits_taken + 1
	-- Done   
	Data[SourceGUID].HPS.heal_done = Data[SourceGUID].HPS.heal_done + Amount
	Data[SourceGUID].HPS.heal_hits_done = Data[SourceGUID].HPS.heal_hits_done + 1   
	-- Spells (Only Taken)
	if isPlayer(destFlags) then 
		if spellID then 
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
		if spellID then 
			Data[DestGUID].absorb_spells[spellID] 	= (Data[DestGUID].absorb_spells[spellID] or 0) + Amount 
		end 
		if spellName then 
			Data[DestGUID].absorb_spells[spellName] = (Data[DestGUID].absorb_spells[spellName] or 0) + Amount      
		end 
	end    
end

CombatTracker.remove_logAbsorb 					= function(...) 
	local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()
	if auraType == "BUFF" then
		CombatTracker.Data[DestGUID].absorb_spells[spellID] 	= nil  
		CombatTracker.Data[DestGUID].absorb_spells[spellName] 	= nil               
	end
end

--[[ This Logs the last cast and amount for every unit ]]
CombatTracker.logLastCast 						= function(...) 
	local Data = CombatTracker.Data
	local _,_,_, SourceGUID, _, sourceFlags,_, DestGUID, _,_,_, spellID, spellName = CombatLogGetCurrentEventInfo()
	if isPlayer(sourceFlags) then 
		-- LastCast time
		Data[SourceGUID].spell_lastcast_time[spellID] 	= TMW.time 
		Data[SourceGUID].spell_lastcast_time[spellName] = TMW.time 
		-- Counter 
		Data[SourceGUID].spell_counter[spellID] 	= (Data[SourceGUID].spell_counter[spellID] or 0) + 1
		Data[SourceGUID].spell_counter[spellName] 	= (Data[SourceGUID].spell_counter[spellName] or 0) + 1
	end 
end 

--[[ This Logs the reset on death for every unit ]]
CombatTracker.logDied							= function(...)
	local _,_,_,_,_,_,_, DestGUID = CombatLogGetCurrentEventInfo()
	CombatTracker.Data[DestGUID] = nil
end	

--[[ This Logs the DR (Diminishing) ]]
CombatTracker.logDR								= function(EVENT, DestGUID, destFlags, spellID)
	if isEnemy(destFlags) then 
		local drCat = DRData:GetSpellCategory(spellID)
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
	["SPELL_PERIODIC_DAMAGE"] 				= CombatTracker.logDamage,
	["SPELL_BUILDING_DAMAGE"] 				= CombatTracker.logDamage,
	["RANGE_DAMAGE"] 						= CombatTracker.logDamage,
	["SWING_DAMAGE"] 						= CombatTracker.logSwing,
	["SPELL_HEAL"] 							= CombatTracker.logHealing,
	["SPELL_PERIODIC_HEAL"] 				= CombatTracker.logHealing,
	["SPELL_AURA_APPLIED"] 					= CombatTracker.logAbsorb,   
	["SPELL_AURA_REFRESH"] 					= CombatTracker.logAbsorb,  
	["SPELL_AURA_REMOVED"] 					= CombatTracker.remove_logAbsorb,  
	["SPELL_CAST_SUCCESS"] 					= CombatTracker.logLastCast,
	["UNIT_DIED"] 							= CombatTracker.logDied,
	["UNIT_DESTROYED"]						= CombatTracker.logDied,
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
	InfoByUnitID 						= {
		-- Defaults
		["player"] 						= {},
	},
	isShrimmer 							= {
		[212653] = true,
	},
	isBlink								= {
		[1953] = true, 
	},
	-- OnEvent 
	UNIT_SPELLCAST_SUCCEEDED			= function(self, unitID, spellID)
		if self.InfoByUnitID[unitID] and self.InfoByUnitID[unitID][spellID] and (not self.InfoByUnitID[unitID][spellID].inPvP or A.IsInPvP) and (not self.InfoByUnitID[unitID][spellID].isFriendly or not A.Unit(unitID):IsEnemy()) then
			local GUID = UnitGUID(unitID)
			
			if GUID then 			
				if not self.Data[GUID] then 
					self.Data[GUID] = {}
				end 
				
				if not self.Data[GUID][spellID] then 
					self.Data[GUID][spellID] = {}
				end 
				
				self.Data[GUID][spellID].start = TMW.time 
				self.Data[GUID][spellID].expire = TMW.time + self.InfoByUnitID[unitID][spellID].Timer 
				self.Data[GUID][spellID].isFlying = true 
				self.Data[GUID][spellID].blackListCLEU = self.InfoByUnitID[unitID][spellID].blackListCLEU
				if self.InfoByUnitID[unitID][spellID].useName then 
					self.Data[GUID][A.GetSpellInfo(spellID)] = self.Data[GUID][spellID]		
				end 
			end 
		end
	end,
	UNIT_SPELLCAST_SUCCEEDED_PLAYER		= function(self, unitID, spellID)
		if unitID == "player" and (not self.InfoByUnitID[unitID][spellID] or not self.InfoByUnitID[unitID][spellID].isFlying) then 
			local GUID = UnitGUID(unitID)
			
			if GUID then 			
				if not self.Data[GUID] then 
					self.Data[GUID] = {}
				end 

				if not self.Data[GUID][spellID] then 
					self.Data[GUID][spellID] = {}
				end 				
				
				self.Data[GUID][spellID].start = TMW.time 
				self.Data[GUID][spellID].isFlying = true 
			end 
		end 
	end, 
	SPELL_CAST_SUCCESS					= function(self, SourceGUID, sourceFlags, spellID)
		if A.IsInPvP and isEnemy(sourceFlags) and isPlayer(sourceFlags) then 
			-- Shrimmer
			if self.isShrimmer[spellID] then 
				local ShrimmerCD = 0
				if not self.Data[SourceGUID] then 
					self.Data[SourceGUID] = {}
				end 	
				
				if not self.Data[SourceGUID].Shrimmer then 
					self.Data[SourceGUID].Shrimmer = {}
				end 		
				
				table.insert(self.Data[SourceGUID].Shrimmer, TMW.time + 20)
				
				-- Since it has only 2 charges by default need remove old ones 
				if #self.Data[SourceGUID].Shrimmer > 2 then 
					table.remove(self.Data[SourceGUID].Shrimmer, 1)
				end 							 
			-- Blink
			elseif self.isBlink[spellID] then 
				if not self.Data[SourceGUID] then 
					self.Data[SourceGUID] = {}
				end 
				
				self.Data[SourceGUID].Blink = TMW.time + 15				
			end 	
		end 
	end, 
	UNIT_DIED							= function(self, DestGUID)
		self.Data[DestGUID] = nil 
	end,
	RESET_IS_FLYING						= function(self, EVENT, SourceGUID, spellID, spellName)
		-- Makes exception for events with _CREATE _FAILED _START since they are point less to be triggered		
		if self.Data[SourceGUID] then 
			if self.Data[SourceGUID][spellID] and self.Data[SourceGUID][spellID].isFlying and (not self.Data[SourceGUID][spellID].blackListCLEU or not self.Data[SourceGUID][spellID].blackListCLEU[EVENT]) and EVENT:match("SPELL") and not EVENT:match("_START") and not EVENT:match("_FAILED") and not EVENT:match("_CREATE") then 
				self.Data[SourceGUID][spellID].isFlying = false 
			end 
			
			if not self.Data[SourceGUID][spellID] and self.Data[SourceGUID][spellName] and self.Data[SourceGUID][spellName].isFlying and (not self.Data[SourceGUID][spellName].blackListCLEU or not self.Data[SourceGUID][spellName].blackListCLEU[EVENT]) and EVENT:match("SPELL") and not EVENT:match("_START") and not EVENT:match("_FAILED") and not EVENT:match("_CREATE") then  
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
	["DISTRACT"]								= 0,
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
	--["TURN_UNDEAD"]							= 0, -- "Feared Undead" currently not usable in BFA PvP 
	--["LOSECONTROL_TYPE_SCHOOLLOCK"] 			= 0, -- HAS SPECIAL HANDLING (per spell school) as "SCHOOL_INTERRUPT"
	["ROOT"]									= 0, -- "Rooted"
	["CONFUSE"]									= 0, -- "Confused" 
	["STUN"]									= 0, -- "Stunned"
	["SILENCE"]									= 0, -- "Silenced"
	["FEAR"]									= 0, -- "Feared"	
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
		CombatTracker.OnEventDR[EVENT](EVENT, DestGUID, destFlags, spellID)
	end 
		
	-- PvP players tracker (Shrimmer / Blink)
	if EVENT == "SPELL_CAST_SUCCESS" then  
		UnitTracker:SPELL_CAST_SUCCESS(SourceGUID, sourceFlags, spellID)
	end 

	-- Reset isFlying
	if EVENT == "UNIT_DIED" or EVENT == "UNIT_DESTROYED" then 
		UnitTracker:UNIT_DIED(DestGUID)
	else 
		UnitTracker:RESET_IS_FLYING(EVENT, SourceGUID, spellID, spellName)
	end 
end 

local UNIT_SPELLCAST_SUCCEEDED					= function(...)
	local unitID, _, spellID = ...
	if unitID then  
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(unitID, spellID)
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED_PLAYER(unitID, spellID)
	end 
end

A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED", 		COMBAT_LOG_EVENT_UNFILTERED	) 
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_SPELLCAST_SUCCEEDED", 			UNIT_SPELLCAST_SUCCEEDED	)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(UnitTracker.Data)
		wipe(CombatTracker.Data)
	end 
end)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	local LastTimeCasted = A.CombatTracker:GetSpellLastCast("player", A.LastPlayerCastID) 
	if (LastTimeCasted == 0 or LastTimeCasted > 0.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(UnitTracker.Data)   	
		wipe(CombatTracker.Data)		
	end 
end)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_UPDATE", 			LossOfControl.OnEvent		)
A.Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_ADDED", 				LossOfControl.OnEvent		)

-------------------------------------------------------------------------------
-- API: CombatTracker
-------------------------------------------------------------------------------
A.CombatTracker									= {
	--[[ Returns the total ammount of time a unit is in-combat for ]]
	CombatTime									= function(self, unitID)
		-- @return number, GUID 
		local GUID = UnitGUID(unitID or "player")
		if CombatTracker.Data[GUID] and InCombatLockdown() then     
			return TMW.time - CombatTracker.Data[GUID].combat_time               
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
		return (Data[GUID] and Data[GUID].spell_value[spell] and Data[GUID].spell_value[spell].Amount) or 0
	end,	
	--[[ This is tracks CLEU spells only if they was applied/missed/reflected e.g. received in any form by end unit to feedback that info ]]
	--[[ Instead of this function for spells which have flying but wasn't received by end unit, since spell still in the fly, you need use A.UnitCooldown ]]		
	GetSpellLastCast 							= function(self, unitID, spell)
		-- @return number, number 
		-- time in seconds since last cast, timestamp of start 
		local GUID 								= UnitGUID(unitID) 
		local Data 								= CombatTracker.Data
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
		if Data[GUID] then
			counter = Data[GUID].spell_counter[spell] or 0
		end 
		return counter
	end,
	--[[ Get Absorb Taken ]]
	GetAbsorb									= function(self, unitID, spellID)
		if not spellID then 
			return UnitGetTotalAbsorbs(unitID)
		else 
			local GUID	 							= UnitGUID(unitID)
			local Data 								= CombatTracker.Data
			if GUID and Data[GUID] and Data[GUID].absorb_spells[spellID] then 		
				return Data[GUID].absorb_spells[spellID]
			end 
		end 		
		return 0
	end,
	--[[ Get DR: Diminishing (only enemy) ]]
	GetDR 										= function(self, unitID, drCat)
		-- @return Tick (number: 100% -> 0%), Remain (number: 0 -> 18), Application (number: 0 -> 5), ApplicationMax (number: 0 -> 5)
		--[[ drCat accepts:
			"root"           
			"stun"      -- PvE unlocked     
			"disorient"      
			"disarm" 	-- added in 1.1		   
			"silence"        
			"taunt"     -- PvE unlocked      
			"incapacitate"   
			"knockback" 
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
		local ttd 								= A.Unit(UNIT):Health() - ( A.Unit(UNIT):HealthMax() * (X / 100) )
		local DMG, Hits 						= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = ttd / DMG
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
	TimeToDie									= function(self, unitID)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.Unit(UNIT):HealthMax()
		local DMG, Hits 						= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = A.Unit(UNIT):Health() / DMG
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
	TimeToDieMagicX								= function(self, unitID, X)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.Unit(UNIT):Health() - ( A.Unit(UNIT):HealthMax() * (X / 100) )
		local _, Hits, _, DMG 					= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = ttd / DMG
		end    
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500 
	end,
	TimeToDieMagic								= function(self, unitID)
		local UNIT 								= unitID and unitID or "target"		
		local ttd 								= A.Unit(UNIT):HealthMax()
		local _, Hits, _, DMG 					= self:GetDMG(UNIT)
		
		if DMG >= 1 and Hits > 1 then
			ttd = A.Unit(UNIT):Health() / DMG
		end  
		
		-- Trainer dummy totems exception 
		if A.Zone == "none" and A.Unit(UNIT):IsDummy() then
			ttd = 500
		end
		
		return ttd or 500
	end,
}

-------------------------------------------------------------------------------
-- API: UnitCooldown
-------------------------------------------------------------------------------
A.UnitCooldown 									= {
	Register							= function(self, unit, spellID, timer, isFriendlyArg, inPvPArg, CLEUbl, useName)	
		-- unit accepts "arena", "raid", "party", their number 		
		-- isFriendlyArg, inPvPArg are optional		
		-- CLEUbl is a table = { ['Event_CLEU'] = true, } which to skip and don't reset by them in fly
		if UnitTracker.isBlink[spellID] or UnitTracker.isShrimmer[spellID] then 
			A.Print("[Error] Can't register Blink or Shrimmer because they are already registered. Please use function Action.UnitCooldown:GetBlinkOrShrimmer(unitID)")
			return 
		end 		
		
		if unit == "player" then 
			A.Print("[Error] Can't register self as " .. unit .. " because it's already registred")
			return 
		end 
		
		if unit:match("target") or unit:match("focus") or unit:match("nameplate") then 
			A.Print("[Error] Can't register invalid unitID as " .. unit)
			return 
		end 
		
		local inPvP 	 = inPvPArg 
		local isFriendly = isFriendlyArg
		if unit:match("arena") then 
			inPvP = true 
		elseif unit:match("party") or unit:match("raid") then 
			isFriendly = true 
		end 	
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				if not UnitTracker.InfoByUnitID[unitID] then 
					UnitTracker.InfoByUnitID[unitID] = {}
				end 
				UnitTracker.InfoByUnitID[unitID][spellID] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl, useName = useName }
			end 
		else 
			if not UnitTracker.InfoByUnitID[unit] then 
				UnitTracker.InfoByUnitID[unit] = {}
			end 
			UnitTracker.InfoByUnitID[unit][spellID] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl, useName = useName } 
		end 	
	end,
	UnRegister							= function(self, unit, spellID)
		if unit == "player" then 
			A.Print("[Error] Can't unregister self as " .. unit .. " because it will break functional")
			return 
		end 
		
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				if not spellID then 
					UnitTracker.InfoByUnitID[unitID] = nil
				else 
					if UnitTracker.InfoByUnitID[unitID] then 
						UnitTracker.InfoByUnitID[unitID][spellID] = nil
					end 
				end 
			end 
		else 
			if not spellID then 
				UnitTracker.InfoByUnitID[unit] = nil 
			else 
				UnitTracker.InfoByUnitID[unit][spellID] = nil
			end 
		end 
		wipe(UnitTracker.Data)
	end,		
	GetCooldown							= function(self, unit, spellID)		
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched)
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].expire then 
					if UnitTracker.Data[GUID][spellID].expire >= TMW.time then 
						return UnitTracker.Data[GUID][spellID].expire - TMW.time, UnitTracker.Data[GUID][spellID].start
					else 
						return 0, UnitTracker.Data[GUID][spellID].start
					end 
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].expire then 
				if UnitTracker.Data[GUID][spellID].expire >= TMW.time then 
					return UnitTracker.Data[GUID][spellID].expire - TMW.time, UnitTracker.Data[GUID][spellID].start
				else 
					return 0, UnitTracker.Data[GUID][spellID].start
				end 
			end 	
		end
		return 0, 0
	end,
	GetMaxDuration						= function(self, unit, spellID)
		-- @return number (max cooldown of the spell on a unit)
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].expire then 
					return UnitTracker.Data[GUID][spellID].expire - UnitTracker.Data[GUID][spellID].start
				end 				
			end 
		else 
			local GUID = UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].expire then 
				return UnitTracker.Data[GUID][spellID].expire - UnitTracker.Data[GUID][spellID].start
			end 
		end
		return 0		
	end,
	GetUnitID 							= function(self, unit, spellID)
		-- @return unitID (who last casted spell) otherwise nil  
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].expire and UnitTracker.Data[GUID][spellID].expire - TMW.time >= 0 then 
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
			local GUID = UnitTracker.CacheGUID[unit] or UnitGUID(unit)
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
	IsSpellInFly						= function(self, unit, spellID)
		-- @return boolean 
		if unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = UnitGUID(unitID)
				if not GUID then 
					break 
				elseif UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] and UnitTracker.Data[GUID][spellID].isFlying then 
					return true
				end 				
			end 
		else 
			local GUID = UnitTracker.CacheGUID[unit] or UnitGUID(unit)
			if GUID and UnitTracker.Data[GUID] and UnitTracker.Data[GUID][spellID] then 
				return UnitTracker.Data[GUID][spellID].isFlying
			end 
		end
		return false 
	end,
}
 
-- Tracks Freezing Trap 
A.UnitCooldown:Register("arena", ACTION_CONST_SPELLID_FREEZING_TRAP, 30, nil, nil, {
	["SPELL_CAST_SUCCESS"] = true,		
}, true)
-- Tracks Counter Shot (hunter's range kick, it's fly able spell and can be avoided by stopcasting)
A.UnitCooldown:Register("arena", ACTION_CONST_SPELLID_COUNTER_SHOT, 24)
-- Tracks Storm Bolt 
A.UnitCooldown:Register("arena", ACTION_CONST_SPELLID_STORM_BOLT, 25, nil, nil, {
	["SPELL_CAST_SUCCESS"] = true,		
}, true)

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
				isApplied = A.Unit("player"):HasDeBuffs("Poison") > 0 or A.Unit("player"):HasDeBuffs("Curse") > 0 or A.Unit("player"):HasDeBuffs("Magic") > 0
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
		["GladiatorMedallion"] 					= {
			Applied = {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "ROOT", "SNARE", "STUN"},	
			isValid = function()
				return A.IsInPvP and 
				(
					A.GladiatorMedallion:IsReadyP("player", true) or 
					(
						A.HonorMedallion:IsExists() and 
						A.HonorMedallion:IsReadyP("player", true)
					)
				)		
			end,
		},
		["Human"] 								= { 
			Applied								= {"STUN"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "ROOT"},
		},
		["Dwarf"] = {
			Applied 							= {"POLYMORPH", "SLEEP", "SHACKLE_UNDEAD"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "STUN", "FEAR", "HORROR", "CHARM", "ROOT"},
		},
		["Scourge"] 							= {
			Applied 							= {"FEAR", "HORROR", "SLEEP", "CHARM"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "STUN", "SHACKLE_UNDEAD", "ROOT"},
		},
		["Gnome"]	 							= {
			Applied 							= {"ROOT", "SNARE"}, 
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "STUN", "SHACKLE_UNDEAD", "FEAR", "HORROR"},
		},		
	},	
}

