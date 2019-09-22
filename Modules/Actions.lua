local TMW 					= TMW
local CNDT 					= TMW.CNDT
local Env 					= CNDT.Env
local strlowerCache  		= TMW.strlowerCache

local A   					= Action	
local toStr 				= A.toStr
local toNum 				= A.toNum
local UnitCooldown			= A.UnitCooldown
local CombatTracker			= A.CombatTracker
local Unit					= A.Unit 
local Player				= A.Player 
local LoC 					= A.LossOfControl
local MultiUnits			= A.MultiUnits
local EnemyTeam				= A.EnemyTeam
local FriendlyTeam			= A.FriendlyTeam
local TriggerGCD			= A.Enum.TriggerGCD

local huge 					= math.huge  	  
local Pet					= LibStub("PetLibrary")
--local LibRangeCheck  		= LibStub("LibRangeCheck-2.0")
local SpellRange			= LibStub("SpellRange-1.0")
local IsSpellInRange 		= SpellRange.IsSpellInRange	  
local SpellHasRange			= SpellRange.SpellHasRange
local isSpellRangeException = {
	-- Shadowmeld
	[58984]		= true,
	-- LightsJudgment
	[255647]	= true,
	-- EveryManforHimself
	[59752]		= true, 
	-- EscapeArtist
	[20589]		= true,
	-- Stoneform
	[20594] 	= true, 
	-- Fireblood
	[265221]	= true,
	-- Regeneratin
	[291944]	= true,
	-- WilloftheForsaken
	[7744]		= true,
	-- Berserking
	[26297]		= true,
	-- WarStomp
	[20549]		= true, 
	-- BloodFury
	[33697]		= true,
	[20572]		= true,
	[33702]		= true,	
}
local ItemHasRange 			= ItemHasRange
local isItemRangeException 	= {
	[19950] = true,
	[18820] = true,
}
local isItemUseException	= {}
local itemCategory 			= {
    [02] = "DPS", 	-- TODO: Classic 
	[01] = "DEFF", 	-- TODO: Classic 
	[19950] = "BOTH",
	[18820] = "BOTH",
}

local GetNetStats 			= GetNetStats	

local _G, type, next, pairs, select, unpack, table, setmetatable = 	
	  _G, type, next, pairs, select, unpack, table, setmetatable
	  
local maxn					= table.maxn	  

-- Spell 
local Spell					= _G.Spell

local IsPlayerSpell, IsUsableSpell, IsHelpfulSpell, IsHarmfulSpell, IsAttackSpell, IsCurrentSpell =
	  IsPlayerSpell, IsUsableSpell, IsHelpfulSpell, IsHarmfulSpell, IsAttackSpell, IsCurrentSpell

local 	  GetSpellTexture, GetSpellLink, GetSpellInfo, GetSpellDescription, GetSpellCount,	GetSpellPowerCost, 	   CooldownDuration, GetSpellCharges, GetHaste = 
	  TMW.GetSpellTexture, GetSpellLink, GetSpellInfo, GetSpellDescription, GetSpellCount, 	GetSpellPowerCost, Env.CooldownDuration, GetSpellCharges, GetHaste

-- Item 	  
local IsUsableItem, IsHelpfulItem, IsHarmfulItem 	=
	  IsUsableItem, IsHelpfulItem, IsHarmfulItem
  
local GetItemInfo, GetItemIcon, GetItemInfoInstant 	= 
	  GetItemInfo, GetItemIcon, GetItemInfoInstant	  

-- Talent	  
local TalentMap 					= A.TalentMap 

-- Rank 
local GetSpellBookItemName			= GetSpellBookItemName
local FindSpellBookSlotBySpellID 	= FindSpellBookSlotBySpellID

-- Unit 	  
local UnitIsUnit 					= UnitIsUnit  	  	 

-- Player 
--[[
local GCD_OneSecond 		= {
	[103] = true, 			-- Feral
	[259] = true, 			-- Assassination
	[260] = true, 			-- Outlaw
	[261] = true, 			-- Subtlety
}
]]

-------------------------------------------------------------------------------
-- Global Cooldown
-------------------------------------------------------------------------------
function A.GetCurrentGCD()
	-- @return number 
	-- Current left in second time of in use (spining) GCD, 0 if GCD is not active
	return CooldownDuration("gcd") -- TMW.GCDSpell
end 
A.GetCurrentGCD = A.MakeFunctionCachedStatic(A.GetCurrentGCD)

function A.GetGCD()
	-- @return number 
	-- Summary time of GCD 
	if TMW.GCD > 0 then
		-- Depended by last used spell 
		return TMW.GCD
	else 
		--if GCD_OneSecond[A.PlayerSpec] then 
			--return 1
		--else 
			-- Depended on current haste
			return 1.5 / (1 + Player:HastePct() / 100) 
		--end 
	end    
end 

function A.IsActiveGCD()
	-- @return boolean 
	return TMW.GCD ~= 0
end 

function A:IsRequiredGCD()
	-- @return boolean, number 
	-- true / false if required, number in seconds how much GCD will be used by action
	if self.Type == "Spell" and TriggerGCD[self.ID] and TriggerGCD[self.ID] > 0 then 
		return true, TriggerGCD[self.ID]
	end 
	
	return false, 0
end 

-------------------------------------------------------------------------------
-- Global Stop Conditions
-------------------------------------------------------------------------------
function A.GetPing()
	-- @return number
	return select(4, GetNetStats()) / 1000 * 2
end 

function A:ShouldStopByGCD()
	-- @return boolean 
	-- By Global Cooldown
	return not Player:IsShooting() and self:IsRequiredGCD() and A.GetGCD() - A.GetPing() > 0.3 and A.GetCurrentGCD() >= A.GetPing() + 0.65
end 

function A.ShouldStop()
	-- @return boolean 
	-- By Casting
	local castName, castStartTime, castEndTime, _, spellID, isChannel = Unit("player"):IsCasting()
	return isChannel or (castName and castEndTime / 1000 - TMW.time > A.GetPing())
end 
A.ShouldStop = A.MakeFunctionCachedStatic(A.ShouldStop)

-------------------------------------------------------------------------------
-- Spell
-------------------------------------------------------------------------------
local spellpowercache = setmetatable({}, { __index = function(t, v)
	local pwr = GetSpellPowerCost(A.GetSpellInfo(v))
	if pwr and pwr[1] then
		t[v] = { pwr[1].cost, pwr[1].type }
		return t[v]
	end     
	return { 0, -1 }
end })

function A:GetSpellPowerCostCache()
	-- THIS IS STATIC CACHED, ONCE CALLED IT WILL NOT REFRESH REALTIME POWER COST
	-- @usage A:GetSpellPowerCostCache() or A.GetSpellPowerCostCache(spellID)
	-- @return cost (@number), type (@number)
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
    return unpack(spellpowercache[ID]) 
end

function A.GetSpellPowerCost(self)
	-- RealTime with cycle cache
	-- @usage A:GetSpellPowerCost() or A.GetSpellPowerCost(123)
	-- @return cost (@number), type (@number)
	local name 
	if type(self) == "table" then 
		name = self:Info()
	else 
		name = A.GetSpellInfo(self)
	end 
	print(self)
	
	local pwr = GetSpellPowerCost(name)
	if pwr and pwr[1] then
		return pwr[1].cost, pwr[1].type
	end   	
	return 0, -1
end 
A.GetSpellPowerCost = A.MakeFunctionCachedDynamic(A.GetSpellPowerCost)

function A.GetSpellDescription(self)
	-- @usage A:GetSpellDescription() or A.GetSpellDescription(18)
	-- @return table 
    local text = GetSpellDescription(type(self) == "table" and self.ID or self) 
    if text then 
		local numbers 		= {}
		local deleted_space = text:gsub("%s+", "")
		deleted_space 		= deleted_space:gsub("%d+%%", "")

		for value in deleted_space:gmatch("%d+") do
			table.insert(numbers, toNum[value])
		end
		
		if #numbers > 1 then
			table.sort(numbers, function (x, y)
					return x > y
			end)
		end 
		
		return numbers
	end
	
	return { 0, 0, 0, 0, 0, 0, 0, 0 } 
end
A.GetSpellDescription = A.MakeFunctionCachedDynamic(A.GetSpellDescription)

function A:GetSpellCastTime()
	-- @return number 
	return (select(4, self:Info()) or 0) / 1000 
end 

function A:GetSpellCharges()
	-- @return number
	local charges = GetSpellCharges(self:Info())
	if not charges then 
		charges = 0
	end 
	
	return charges
end

function A:GetSpellChargesMax()
	-- @return number
	local _, max_charges = GetSpellCharges(self:Info())
	if not max_charges then 
		max_charges = 0
	end 
	
	return max_charges	
end

function A:GetSpellChargesFrac()
	-- @return number	
	local charges, maxCharges, start, duration = GetSpellCharges(self:Info())
	if charges == maxCharges then 
		return maxCharges
	end
	
	return charges + ((TMW.time - start) / duration)  
end

function A:GetSpellChargesFullRechargeTime()
	-- @return number
	local _, _, _, duration = GetSpellCharges(self:Info())
	return duration and self:GetSpellChargesMax() - self:GetSpellChargesFrac() * duration or 0
end 

function A:GetSpellTimeSinceLastCast()
	-- @return number (seconds after last time casted - during fight)
	return CombatTracker:GetSpellLastCast("player", self:Info())
end 

function A:GetSpellCounter()
	-- @return number (total count casted of the spell - during fight)
	return CombatTracker:GetSpellCounter("player", self:Info())
end 

function A:GetSpellAmount(unitID, X)
	-- @return number (taken summary amount of the spell - during fight)
	-- X during which lasts seconds 
	if X then 
		return CombatTracker:GetSpellAmountX(unitID or "player", self:Info())
	else 
		return CombatTracker:GetSpellAmount(unitID or "player", self:Info())
	end 
end 

function A:GetSpellAbsorb(unitID)
	-- @return number (taken current absort amount of the spell - during fight)
	return CombatTracker:GetAbsorb(unitID or "player", self:Info())
end 

function A:IsSpellLastGCD()
	return self:Info() == A.LastPlayerCastName
end 

function A:IsSpellInFlight()
	-- @return boolean
	return UnitCooldown:IsSpellInFly("player", self:Info())
end 

function A:IsSpellInRange(unitID)
	-- @usage A:IsSpellInRange() or A.IsSpellInRange(spellID, unitID)
	-- @return boolean
	local ID, Name
	if type(self) == "table" then 
		ID = self.ID 
		Name = self:Info()
	else 
		ID = self 
		Name = A.GetSpellInfo(ID)
	end		
	return IsSpellInRange(Name, unitID) == 1 or (Pet:IsActive() and Pet:IsInRange(ID, unitID))  
end 

function A:IsSpellInCasting()
	-- @return boolean 
	return Unit("player"):IsCasting() == self:Info()
end 

function A:IsSpellLearned()
	-- @usage A:IsSpellLearned() or A.IsSpellLearned(spellID)
	-- @return boolean 
	local ID, Name
	if type(self) == "table" then 
		ID = self.ID 
		Name = self:Info()
	else 
		ID = self 
		Name = A.GetSpellInfo(ID)
	end	
	return TalentMap[Name] and TalentMap[Name] > 0 or false 
end

function A:IsSpellCurrent()
	return IsCurrentSpell(self.ID)
end 

function A:CanSafetyCastHeal(unitID, offset)
	-- @return boolean 
	local castTime = self:GetSpellCastTime()
	return castTime and (castTime == 0 or castTime > Unit(unitID):TimeToDie() + A.GetCurrentGCD() + (offset or A.GetGCD())) or false 
end 

-------------------------------------------------------------------------------
-- Talent 
-------------------------------------------------------------------------------
function A:GetTalentRank()
	-- @usage A:GetTalentRank() or A.GetTalentRank(spellID)
	-- @return number 
	local ID, Name
	if type(self) == "table" then 
		ID = self.ID 
		Name = self:Info()
	else 
		ID = self 
		Name = A.GetSpellInfo(ID)
	end	
	return TalentMap[Name] or 0 
end 

-------------------------------------------------------------------------------
-- Spell Rank 
-------------------------------------------------------------------------------
local DataSpellRanks = {}
local DataIsSpellUnknown = {}
function A.UpdateSpellBook()
	wipe(DataSpellRanks)
	wipe(DataIsSpellUnknown)
	-- Search by player book 
	for i = 1, huge do 
		local spellName, spellRank, spellID = GetSpellBookItemName(i, BOOKTYPE_SPELL)
		if spellName then 
			if spellRank and spellRank ~= "" and spellID then 
				spellRank = spellRank:match("%d+")
				if spellRank then 
					spellRank = toNum[spellRank]
					
					if not DataSpellRanks[spellName] then 
						DataSpellRanks[spellName] = {}
					end 
					
					DataSpellRanks[spellName][spellRank] = spellID
				end 
			end 
		else 
			break 
		end 
	end 
	
	-- Search by pet book
	for i = 1, huge do 
		local spellName, spellRank, spellID = GetSpellBookItemName(i, BOOKTYPE_PET)
		if spellName then 
			if spellRank and spellRank ~= "" and spellID then 
				spellRank = spellRank:match("%d+")
				if spellRank then 
					spellRank = toNum[spellRank]
					
					if not DataSpellRanks[spellName] then 
						DataSpellRanks[spellName] = {}
					end 
					
					DataSpellRanks[spellName][spellRank] = spellID
				end 
			end 
		else 
			break 
		end 
	end 	

	-- Overwrite ID of spells with update isRank and block unavailable ranks 
	if A[A.PlayerClass] then 				
		for k, v in pairs(A[A.PlayerClass]) do 
			if type(v) == "table" and v.Type == "Spell" then 
				local spellName = v:Info()
				-- Overwrite ID and isRank 
				if DataSpellRanks[spellName] then 
					-- By max 
					if type(v.useMaxRank) == "boolean" then 					
						local maxRank = maxn(DataSpellRanks[spellName])
						v.ID = DataSpellRanks[spellName][maxRank]
						v.isRank = maxRank 		
					elseif type(v.useMaxRank) == "table" then 
						for i = #v.useMaxRank, 1, -1 do 
							if DataSpellRanks[spellName][v.useMaxRank[i]] then 
								v.isRank = v.useMaxRank[i]
								v.ID = DataSpellRanks[spellName][v.isRank]		
								break 
							end 							 
						end 					
					end 
					
					-- By min 
					if type(v.useMinRank) == "boolean" then 					
						local minRank = DataSpellRanks[spellName][1] ~= nil and 1 or next(DataSpellRanks[spellName])
						v.ID = DataSpellRanks[spellName][minRank]
						v.isRank = minRank 		
					elseif type(v.useMinRank) == "table" then 
						for i = 1, #v.useMinRank do 
							if DataSpellRanks[spellName][v.useMinRank[i]] then 
								v.isRank = v.useMinRank[i]
								v.ID = DataSpellRanks[spellName][v.isRank]		
								break 
							end 								
						end 
					end 
				end 
				
				-- Block spell (unlearned)				
				-- Search by player book
				local slot = FindSpellBookSlotBySpellID(v.ID, false)  
				
				-- Search by pet book 
				if not slot then 
					slot = FindSpellBookSlotBySpellID(v.ID, true)
				end
				
				-- Add to block 
				if not slot then 
					DataIsSpellUnknown[v.ID] = true 
					-- Prevent nil errors with ranks if not found at all 
					if not v.isRank then 
						v.isRank = 0
					end 
				end 								 								
			end 
		end 
	end 

	TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")	  -- for [3] tab refresh 
	--TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED") -- no need here since :Show method will be triggered 
end 

A.Listener:Add("ACTION_EVENT_SPELL_RANKS", "PLAYER_LEVEL_UP", 			A.UpdateSpellBook)
A.Listener:Add("ACTION_EVENT_SPELL_RANKS", "PLAYER_LEVEL_CHANGED", 		A.UpdateSpellBook)
A.Listener:Add("ACTION_EVENT_SPELL_RANKS", "LEARNED_SPELL_IN_TAB", 		A.UpdateSpellBook)
A.Listener:Add("ACTION_EVENT_SPELL_RANKS", "CONFIRM_TALENT_WIPE", 		A.UpdateSpellBook)
A.Listener:Add("ACTION_EVENT_SPELL_RANKS", "CHARACTER_POINTS_CHANGED", 	A.UpdateSpellBook)

function A:IsBlockedBySpellBook()
	-- @return boolean 
	return DataIsSpellUnknown[self.ID]
end 

function A:GetSpellRank()
	-- @return number 
	return self.isRank or 1
end 

function A:GetSpellMaxRank()
	-- @return number 
	if self.isRank then 
		local spellName = self:Info()
		if DataSpellRanks[spellName] then 
			return maxn(DataSpellRanks[spellName])
		end 
	end 
	return 1
end 

function A.DetermineHealObject(unitID, skipRange, skipLua, skipShouldStop, skipUsable, ...)
	-- @return object or nil 
	-- Note: :PredictHeal(unitID) must be only ! Use self.ID or self:Info() inside to determine by that which spell is it 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable) and object:PredictHeal(unitID) then 
			return object
		end 
	end 
end 

function A.DetermineUsableObject(unitID, skipRange, skipLua, skipShouldStop, skipUsable, ...)
	-- @return object or nil 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable) then 
			return object
		end 
	end 
end 

-------------------------------------------------------------------------------
-- Racial (template)
-------------------------------------------------------------------------------	 
local Racial = {
	GetRaceBySpellName 										= {
		-- Perception 
		[Spell:CreateFromSpellID(20600):GetSpellName()] 	= "Human",
		-- Shadowmeld
		[Spell:CreateFromSpellID(20580):GetSpellName()] 	= "NightElf",
		-- EscapeArtist
		[Spell:CreateFromSpellID(20589):GetSpellName()] 	= "Gnome",
		-- Stoneform
		[Spell:CreateFromSpellID(20594):GetSpellName()] 	= "Dwarf",
		-- WilloftheForsaken
		[Spell:CreateFromSpellID(7744):GetSpellName()] 		= "Scourge", 				-- (this is confirmed) Undead 
		-- Berserking
		[Spell:CreateFromSpellID(20554):GetSpellName()] 	= "Troll",
		-- WarStomp
		[Spell:CreateFromSpellID(20549):GetSpellName()] 	= "Tauren",
		-- BloodFury
		[Spell:CreateFromSpellID(20572):GetSpellName()] 	= "Orc",
	},
	Temp													= {
		TotalAndMagic 										= {"TotalImun", "DamageMagicImun"},
		TotalAndPhysAndCC									= {"TotalImun", "DamagePhysImun", "CCTotalImun"},
		TotalAndPhysAndCCAndStun							= {"TotalImun", "DamagePhysImun", "CCTotalImun", "StunImun"},
	},
	-- Functions	
	CanUse 													= function(this, self, unitID)
		-- @return boolean 
		A.PlayerRace = this.GetRaceBySpellName[self:Info()]
		
		-- Iterrupts 
		if A.PlayerRace == "Tauren" then 
			return 	(
						(
							unitID and 	
							Unit(unitID):IsEnemy() and 
							Unit(unitID):GetRange() <= 8 and 					
							Unit(unitID):IsControlAble("stun") and 
							self:AbsentImun(unitID, this.Temp.TotalAndPhysAndCCAndStun)
						) or 
						(
							(
								not unitID or 
								not Unit(unitID):IsEnemy() 
							) and 
							MultiUnits:GetByRange(8, 1) >= 1
						)
					)	
		end 

		-- [NO LOGIC - ALWAYS TRUE] 
		return true 		 			
	end,
	CanAuto													= function(this, self, unitID)
		-- Loss Of Control 
		local LOC = LoC.GetExtra[A.PlayerRace]
		if LOC and LoC:IsValid(LOC.Applied, LOC.Missed) then 
			return true 
		end 	
		
		-- TODO: Classic - Perception (PvP)
		
		-- Iterrupts 
		if A.PlayerRace == "Tauren" then 
			return  (
						unitID and 					
						Unit(unitID):IsCastingRemains() > A.GetCurrentGCD() + 0.7
					) or 
					(
						(
							not unitID or 
							not Unit(unitID):IsEnemy() 
						) and 
						MultiUnits:GetCasting(8, 1) >= 1
					)			  
		end 		

		-- Control Avoid 
		if A.PlayerRace == "NightElf" then 
			if A.Zone == "pvp" then 
				-- Check Freezing Trap 
				if 	UnitCooldown:GetCooldown("arena", ACTION_CONST_SPELLID_FREEZING_TRAP) > UnitCooldown:GetMaxDuration("arena", ACTION_CONST_SPELLID_FREEZING_TRAP) - 2 and 
					UnitCooldown:IsSpellInFly("arena", ACTION_CONST_SPELLID_FREEZING_TRAP) and 
					Unit("player"):GetDR("incapacitate") > 0 
				then 
					local Caster = UnitCooldown:GetUnitID("arena", ACTION_CONST_SPELLID_FREEZING_TRAP)
					if Caster and not Player:IsStealthed() and Unit(Caster):GetRange() <= 40 and (Unit("player"):GetDMG() == 0 or not Unit("player"):IsFocused()) then 
						return true 
					end 
				end 
			end 
		end 			
		
		-- Bursting 
		if ( A.PlayerRace == "Troll" or A.PlayerRace == "Orc" ) then 
			return A.BurstIsON(unitID)
		end 	
		
		-- [NO LOGIC - ALWAYS FALSE] 
		return false 		
	end, 
}

function A:IsRacialReady(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	-- For [3-4, 6-8]
	return self:RacialIsON() and self:IsReady(unitID, isSpellRangeException[self.ID] or skipRange, skipLua, skipShouldStop) and Racial:CanUse(self, unitID) 
end 

function A:IsRacialReadyP(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	-- For [1-2, 5]
	return self:RacialIsON() and self:IsReadyP(unitID, isSpellRangeException[self.ID] or skipRange, skipLua, skipShouldStop) and Racial:CanUse(self, unitID) 
end 

function A:AutoRacial(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	return self:IsRacialReady(unitID, skipRange, skipLua, skipShouldStop) and Racial:CanAuto(self, unitID)
end 

-------------------------------------------------------------------------------
-- Item (provided by TMW)
-------------------------------------------------------------------------------	  
function A:GetItemCooldown()
	-- @return number
	local start, duration, enable = self.Item:GetCooldown()
	return enable ~= 0 and (duration == 0 and 0 or duration - (TMW.time - start)) or huge
end 

function A:GetItemCategory()
	-- @return string 
	-- Note: Only for Type "TrinketBySlot"
	return itemCategory[self.ID]
end 

-- Next works by TMW components
-- A:IsInRange(unitID) (in Shared)
-- A:GetCount() (in Shared)
-- A:GetEquipped() 
-- A:GetCooldown() (in Shared)
-- A:GetCooldownDuration() 
-- A:GetCooldownDurationNoGCD() 
-- A:GetID() 
-- A:GetName() 
-- A:HasUseEffect() 

-------------------------------------------------------------------------------
-- Shared
-------------------------------------------------------------------------------	  
function A:IsExists()   
	-- @return boolean
	if self.Type == "Spell" then 
		-- DON'T USE HERE A.GetSpellInfo COZ IT'S CACHE WHICH WILL WORK WRONG DUE RACE CHANGES
		local spellID = select(7, GetSpellInfo(self:Info())) -- Small trick, it will be nil in case of if it's not a player's spell 
		return spellID and (IsPlayerSpell(spellID) or (Pet:IsActive() and Pet:IsSpellKnown(spellID)))
	end 
	
	return self:GetEquipped() or self:GetCount() > 0	
end

function A:IsUsable(extraCD, skipUsable)
	-- @return boolean 
	-- skipUsable can be number to check specified power 
	
	if self.Type == "Spell" then 
		-- Works for pet spells 01/04/2019
		return (skipUsable or (type(skipUsable) == "number" and Unit("player"):Power() >= skipUsable) or IsUsableSpell(self:Info())) and self:GetCooldown() <= A.GetPing() + ACTION_CONST_CACHE_DEFAULT_TIMER + (self:IsRequiredGCD() and A.GetCurrentGCD() or 0) + (extraCD or 0)
	end 
	
	return not isItemUseException[self.ID] and (skipUsable or (type(skipUsable) == "number" and Unit("player"):Power() >= skipUsable) or IsUsableItem(self:Info())) and self:GetItemCooldown() <= A.GetPing() + ACTION_CONST_CACHE_DEFAULT_TIMER + (self:IsRequiredGCD() and A.GetCurrentGCD() or 0) + (extraCD or 0)
end

function A:IsHarmful()
	-- @return boolean 
	if self.Type == "Spell" then 
		return IsHarmfulSpell(self:Info()) or IsAttackSpell(self:Info())
	end 
	
	return IsHarmfulItem(self:Info())
end 

function A:IsHelpful()
	-- @return boolean 
	if self.Type == "Spell" then 
		return IsHelpfulSpell(self:Info())
	end 
	
	return IsHelpfulItem(self:Info())
end 

function A:IsInRange(unitID)
	-- @return boolean
	local unitID = unitID or "target"
	
	if UnitIsUnit("player", unitID) then 
		return true 
	end 
	
	if self.Type == "Spell" then 
		return self:IsSpellInRange(unitID)
	end 
	
	return self.Item:IsInRange(unitID)
end 

function A:HasRange()
	-- @return boolean 
	if self.Type == "Spell" then 
		return not isSpellRangeException[self.ID] and SpellHasRange(self:Info())
	end 
	
	return not isItemRangeException[self:GetID()] and ItemHasRange(self:Info())
end 

function A:GetCooldown()
	-- @return number
	if self.Type == "Spell" then 
		return CooldownDuration(self:Info())
	end 
	
	return self:GetItemCooldown()
end 

function A:GetCount()
	-- @return number
	if self.Type == "Spell" then 
		return GetSpellCount(self.ID) or 0
	end 
	
	return self.Item:GetCount() or 0
end 

function A:AbsentImun(unitID, imunBuffs)
	-- @return boolean 
	-- Note: Checks for friendly / enemy Imun auras and compares it with remain duration 
	if not unitID or not A.IsInPvP or UnitIsUnit(unitID, "player") or not UnitIsPlayer(unitID) then 
		return true 
	else 
		-- Super trick for Queue System, it will save in cache imunBuffs on first entire call by APL and Queue will be allowed to handle cache to compare Imun 
		if type(self) == "table" and not self.AbsentImunQueueCache and imunBuffs then 
			self.AbsentImunQueueCache = imunBuffs
		end 	
		
		local MinDur = type(self) ~= "table" and 0 or self.Type ~= "Spell" and 0 or self:GetSpellCastTime()
		if MinDur > 0 then 
			MinDur = MinDur + (self:IsRequiredGCD() and self.GetCurrentGCD() or 0)
		end
		
		if Unit(unitID):DeBuffCyclone() > MinDur then 
			return false 
		end 
		
		if imunBuffs then 
			if type(imunBuffs) == "table" then 
				for i = 1, #imunBuffs do 
					if Unit(unitID):HasBuffs(imunBuffs[i]) > MinDur then 
						return false 
					end 
				end 
			elseif Unit(unitID):HasBuffs(imunBuffs) > MinDur then
				return false 
			end 
		end 

		return true
	end 
end 

function A:IsCastable(unitID, skipRange, skipShouldStop, isMsg, skipUsable)
	-- @return boolean
	-- Checks toggle, cooldown and range 
	
	if isMsg or ((skipShouldStop or not A.ShouldStop()) and not self:ShouldStopByGCD()) then 
		if 	self.Type == "Spell" and 
			not self:IsBlockedBySpellBook() and 
			( not self.isTalent or self:IsSpellLearned() ) and 
			self:IsUsable(nil, skipUsable) and 
			( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) )
		then 
			return true 				
		end 
		
		if 	self.Type == "Trinket" and 
			-- This also checks equipment (in idea because slot return ID which we compare)
			self.ID ~= nil and 
			( A.Trinket1.ID == self.ID and A.GetToggle(1, "Trinkets")[1] or A.Trinket2.ID == self.ID and A.GetToggle(1, "Trinkets")[2] ) and 
			self:IsUsable(nil, skipUsable) and 
			( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) )
		then
			return true 
		end 
		
		if 	self.Type == "Potion" and 
			A.GetToggle(1, "Potion") and 
			A.BurstIsON(unitID or A.IamHealer and "targettarget" or "target") and 
			self:GetCount() > 0 and 
			self:GetItemCooldown() == 0 
		then
			return true 
		end 
		
		if  self.Type == "Item" and 
			self:GetCount() > 0 and 
			self:GetItemCooldown() == 0 and 
			( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) )
		then
			return true 
		end 
	end 
	
	return false 
end

function A:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable)
	-- @return boolean
	-- For [3-4, 6-8]
    return 	not self:IsBlocked() and 
			not self:IsBlockedByQueue() and 
			self:IsCastable(unitID, skipRange, skipShouldStop, nil, skipUsable) and 
			( skipLua or self:RunLua(unitID) )
end 

function A:IsReadyP(unitID, skipRange, skipLua, skipShouldStop, skipUsable)
	-- @return boolean
	-- For [1-2, 5]
    return 	self:IsCastable(unitID, skipRange, skipShouldStop, nil, skipUsable) and (skipLua or self:RunLua(unitID))
end 

function A:IsReadyM(unitID, skipRange, skipUsable)
	-- @return boolean
	-- For MSG System 
	if unitID == "" then 
		unitID = nil 
	end 
    return 	self:IsCastable(unitID, skipRange, nil, true, skipUsable) and self:RunLua(unitID)
end 

function A:IsReadyToUse(unitID, skipShouldStop, skipUsable)
	-- @return boolean 
	return 	not self:IsBlocked() and 
			not self:IsBlockedByQueue() and 
			self:IsCastable(nil, true, skipShouldStop, nil, skipUsable)
end 

function A:IsReadyOnPower(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	-- Note: Created to bypass stances and equip 
	return self:IsReady(unitID, skipRange, skipLua, skipShouldStop, self.PowerCost)
end 

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
-- Spell  
local spellinfocache = setmetatable({}, { __index = function(t, v)
    local a = { GetSpellInfo(v) }
    if a[1] then
        t[v] = a
    end
    return a
end })

function A:GetSpellInfo()
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
	return unpack(spellinfocache[ID])
end

function A:GetSpellLink()
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
    return GetSpellLink(ID) 
end 

function A:GetSpellIcon()
	return select(3, self:GetSpellInfo())
end

function A:GetSpellTexture(custom)
    return "texture", GetSpellTexture(custom or self.ID)
end 

--- Spell Colored Texturre
function A:GetColoredSpellTexture(custom)
    return "state; texture", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = ""}, GetSpellTexture(custom or self.ID)
end 

-- SingleColor
function A:GetColorTexture()
    return "state", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = "ERROR"}
end 

-- Item
local iteminfocache = setmetatable({}, { __index = function(t, v)	
    local a = { GetItemInfo(v) }
    if a[1] then
        t[v] = a
    end
    return a
end })

function A:GetItemInfo()
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
	return unpack(iteminfocache[ID])
end

function A:GetItemLink()
    return select(2, self:GetItemInfo()) 
end 

function A:GetItemIcon()
	return select(10, self:GetItemInfo())
end

function A:GetItemTexture(custom)
	local texture
	if self.Type == "Trinket" then 
		if A.Trinket1.ID == self.ID then 
			texture = ACTION_CONST_TRINKET1
		else 
			texture = ACTION_CONST_TRINKET2
		end
	elseif self.Type == "Potion" then 
		texture = ACTION_CONST_POTION
	else 
		texture = (custom and select(10, self.GetItemInfo(custom))) or self:GetItemIcon()
	end
	
    return "texture", texture
end 

-- Item Colored Texture
function A:GetColoredItemTexture(custom)
    return "state; texture", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = ""}, (custom and GetItemIcon(custom)) or self:GetItemIcon()
end 

-------------------------------------------------------------------------------
-- UI: Create
-------------------------------------------------------------------------------
function A.Create(attributes)
	--[[@usage: attributes (table)
		Required: 
			Type (@string)	- Spell|SpellSingleColor|Item|ItemSingleColor|Potion|Trinket|TrinketBySlot|ItemBySlot (TrinketBySlot, ItemBySlot is only in CORE!)
			ID (@number) 	- spellID | itemID
			Color (@string) - only if type is Spell|SpellSingleColor|Item|ItemSingleColor, this will set color which stored in A.Data.C[Color] or here can be own hex 
	 	Optional: 
			Desc (@string) uses in UI near Icon tab (usually to describe relative action like Penance can be for heal and for dps and it's different actions but with same name)
			BlockForbidden (@boolean) uses to preset for action fixed block valid 
			QueueForbidden (@boolean) uses to preset for action fixed queue valid 
			Texture (@number) valid only if Type is Spell|Item|Potion|Trinket
			FixedTexture (@number or @file) valid only if Type is Spell|Item|Potion|Trinket
			MetaSlot (@number) allows set fixed meta slot use for action whenever it will be tried to set in queue 
			Hidden (@boolean) allows to hide from UI this action 
			isTalent (@boolean) will check in :IsCastable method condition through :IsSpellLearned(), only if Type is Spell|SpellSingleColor
			isRank (@number) will use specified rank for spell (additional frame for color below TargetColor)			
			useMaxRank (@boolean or @table) will overwrite current ID by highest available rank and apply isRank number, example of table use {1, 2, 4, 6, 7} 
			useMinRank (@boolean or @table) will overwrite current ID by lowest available rank and apply isRank number, example of table use {1, 2, 4, 6, 7} 	
			
		So the conception of Classic is to use own texture for any ranks and additional frame which will determine rank whenever it need, we assume what by default no need to determine rank if we use useMaxRank
		Otherwise it will interract with additional frame  
	]]
	if not attributes then 
		local attributes = {}
	end 	
	local s = {
		ID = attributes.ID,
		SubType = attributes.Type,
		Desc = attributes.Desc or "",
		BlockForbidden = attributes.BlockForbidden,
		QueueForbidden = attributes.QueueForbidden, 
		MetaSlot = attributes.MetaSlot,
		Hidden = attributes.Hidden,
	}
	if attributes.Type == "Spell" then 
		s = setmetatable(s, {__index = A})	
		s.Type = "Spell"		
		-- Methods (metakey:Link())			
		s.Info = A.GetSpellInfo
		s.Link = A.GetSpellLink		
		s.Icon = A.GetSpellIcon
		if attributes.Color then 
			s.Color = attributes.Color
			if attributes.Texture then 
				s.Texture = function()
					return A.GetColoredSpellTexture(s, attributes.Texture)
				end 
			elseif attributes.FixedTexture then 
				s.Texture = function()
					return "texture", attributes.FixedTexture
				end 				
			else 
				s.Texture = A.GetColoredSpellTexture
			end 		
		else 
			if attributes.Texture then 
				s.Texture = function()
					return A.GetSpellTexture(s, attributes.Texture)
				end 
			elseif attributes.FixedTexture then 
				s.Texture = function()
					return "texture", attributes.FixedTexture
				end 
			else 
				s.Texture = A.GetSpellTexture	
			end						
		end 
		-- Power 
		s.PowerCost, s.PowerType = s:GetSpellPowerCostCache()
		-- Talent 
		s.isTalent = attributes.isTalent
		-- Rank 
		s.isRank = attributes.isRank
		if type(attributes.useMaxRank) == "table" then 
			table.sort(attributes.useMaxRank)
		end 
		s.useMaxRank = attributes.useMaxRank		 
		if type(attributes.useMinRank) == "table" then 
			table.sort(attributes.useMinRank)
		end 
		s.useMinRank = attributes.useMinRank
	elseif attributes.Type == "SpellSingleColor" then 
		s = setmetatable(s, {__index = A})	
		s.Type = "Spell"
		s.Color = attributes.Color
		-- Methods (metakey:Link())	
		s.Info = A.GetSpellInfo
		s.Link = A.GetSpellLink		
		s.Icon = A.GetSpellIcon
		-- This using static and fixed only color so no need texture
		s.Texture = A.GetColorTexture			
		-- Power 
		s.PowerCost, s.PowerType = s:GetSpellPowerCostCache()	
		-- Talent 
		s.isTalent = attributes.isTalent
		-- Rank 
		s.isRank = attributes.isRank
		if type(attributes.useMaxRank) == "table" then 
			table.sort(attributes.useMaxRank)
		end 
		s.useMaxRank = attributes.useMaxRank		 
		if type(attributes.useMinRank) == "table" then 
			table.sort(attributes.useMinRank)
		end 
		s.useMinRank = attributes.useMinRank		 
	elseif attributes.Type == "Trinket" or attributes.Type == "Potion" or attributes.Type == "Item" then 
		s = setmetatable(s, {
				__index = function(self, key)
					if A[key] then
						return A[key]
					else
						return self.Item[key]
					end
				end
		})
		s.Type = attributes.Type
		-- Methods (metakey:Link())	
		s.Info = A.GetItemInfo
		s.Link = A.GetItemLink		
		s.Icon = A.GetItemIcon
		if attributes.Color then 
			s.Color = attributes.Color
			if attributes.Texture then 
				s.Texture = function()
					return A.GetColoredItemTexture(s, attributes.Texture)
				end 
			elseif attributes.FixedTexture then 
				s.Texture = function()
					return "texture", attributes.FixedTexture
				end 				
			else 
				s.Texture = A.GetColoredItemTexture
			end 		
		else 		
			if attributes.Texture then 
				s.Texture = function()
					return A.GetItemTexture(s, attributes.Texture)
				end 
			elseif attributes.FixedTexture then 
				s.Texture = function()
					return "texture", attributes.FixedTexture
				end 				
			else 
				s.Texture = A.GetItemTexture
			end 
		end	
		-- Misc
		s.Item = TMW.Classes.ItemByID:New(attributes.ID)
		GetItemInfoInstant(attributes.ID) -- must be here as request limited data from server 	
	elseif attributes.Type == "TrinketBySlot" or attributes.Type == "ItemBySlot" then 
		s = setmetatable(s, {
				__index = function(self, key)
					if key == "ID" then 
						return self.Item:GetID()
					end 
					
					if A[key] then
						return A[key]
					else
						return self.Item[key]
					end
				end
		})
		s.Type = (attributes.Type == "TrinketBySlot" and "Trinket") or "Item"
		-- Methods (metakey:Link())	
		s.Info = A.GetItemInfo
		s.Link = A.GetItemLink		
		s.Icon = A.GetItemIcon
		if attributes.Color then 
			s.Color = attributes.Color
			if attributes.Texture then 
				s.Texture = function()
					return A.GetColoredItemTexture(s, attributes.Texture)
				end 				
			else 
				s.Texture = A.GetColoredItemTexture
			end 		
		else 		
			if attributes.Texture then 
				s.Texture = function()
					return A.GetItemTexture(s, attributes.Texture)
				end 				
			else 
				s.Texture = A.GetItemTexture
			end 
		end	
		-- Misc
		s.Item = TMW.Classes.ItemBySlot:New(attributes.ID)			
		local isEquiped = s.Item:GetID()
		if isEquiped then 
			GetItemInfoInstant(isEquiped) -- must be here as request limited data from server
		end 
		s.ID = nil
	elseif attributes.Type == "ItemSingleColor" then
		s = setmetatable(s, {
				__index = function(self, key)
					if A[key] then
						return A[key]
					else
						return self.Item[key]
					end
				end
		})
		s.Type = "Item" 
		s.Color = attributes.Color
		-- Methods (metakey:Link())	
		s.Info = A.GetItemInfo
		s.Link = A.GetItemLink		
		s.Icon = A.GetItemIcon
		-- This using static and fixed only color so no need texture
		s.Texture = A.GetColorTexture		
		-- Misc 
		s.Item = TMW.Classes.ItemByID:New(attributes.ID)
		GetItemInfoInstant(attributes.ID) -- must be here as request limited data from server	
	else 
		s = setmetatable(s, {__index = A})	
		s.Hidden = true 
	end 
	return s
end 