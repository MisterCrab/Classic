local TMW 						= TMW
--local strlowerCache  			= TMW.strlowerCache

local A   						= Action	
--local isEnemy					= A.Bit.isEnemy
--local isPlayer				= A.Bit.isPlayer
--local toStr 					= A.toStr
--local toNum 					= A.toNum
local InstanceInfo				= A.InstanceInfo
--local TeamCache				= A.TeamCache
--local Azerite 				= LibStub("AzeriteTraits")
--local Pet						= LibStub("PetLibrary")
--local LibRangeCheck  			= LibStub("LibRangeCheck-2.0")
--local SpellRange				= LibStub("SpellRange-1.0")

local _G, error, type, pairs, table, next =
	  _G, error, type, pairs, table, next 

local Enum 						= _G.Enum 
local PowerType 				= Enum.PowerType
local ManaPowerType 			= PowerType.Mana
local RagePowerType 			= PowerType.Rage
local FocusPowerType 			= PowerType.Focus
local EnergyPowerType 			= PowerType.Energy
local ComboPointsPowerType		= PowerType.ComboPoints
local RunicPowerPowerType 		= PowerType.RunicPower
local SoulShardsPowerType 		= PowerType.SoulShards
local LunarPowerPowerType 		= PowerType.LunarPower
local HolyPowerPowerType 		= PowerType.HolyPower
local MaelstromPowerType 		= PowerType.Maelstrom
local ChiPowerType 				= PowerType.Chi
local InsanityPowerType 		= PowerType.Insanity
local ArcaneChargesPowerType 	= PowerType.ArcaneCharges
local FuryPowerType 			= PowerType.Fury
local PainPowerType				= PowerType.Pain
local WarlockPowerBar_UnitPower = _G.WarlockPowerBar_UnitPower

local UnitPower, UnitPowerMax, UnitStagger =
	  UnitPower, UnitPowerMax, UnitStagger

local GetPowerRegen, GetRuneCooldown, GetShapeshiftForm, GetCritChance, GetHaste, GetMasteryEffect, GetVersatilityBonus, GetCombatRatingBonus =
	  GetPowerRegen, GetRuneCooldown, GetShapeshiftForm, GetCritChance, GetHaste, GetMasteryEffect, GetVersatilityBonus, GetCombatRatingBonus
	  
local IsEquippedItem, IsStealthed, IsMounted, IsFalling = 	  
	  IsEquippedItem, IsStealthed, IsMounted, IsFalling 

-------------------------------------------------------------------------------
-- Locals 
-------------------------------------------------------------------------------
local Data = {
	Stance = 0,
	TimeStampMoving = 0,
	TimeStampStaying = TMW.time, 
	TimeStampFalling = 0,
	AuraStealthed = {
		["ROGUE"] = {
			11327, 					-- Vanish 
			115193, 				-- Vanish w/ Subterfuge Talent
			115192,					-- Subterfuge Buff
			185422,					-- Stealth from Shadow Dance
		},
		["DRUID"] = {
			--102543, 				-- Incarnation: King of the Jungle
			5215,					-- Prowl 			
		},
		Shadowmeld = 58984,
		MassInvisible = {
			32612, 
			110959, 
			198158,  
		},
	},
	AuraOnCombatMounted = {
		["PALADIN"] = {
			220509,					-- Divine Steed 
			221883, 
			221885,
			221886,
			221887,
			254471,
			254472,
			254473,
			254474,
			220504,					-- Silver Hand Charger
			220507,
		},
		["DRUID"] = {
			783,		 			-- Travel form 
			165962,					-- Druid Flight Form
		},
		["DEMONHUNTER"] = 131347,	-- Demon Hunter Glide
	},
	-- Items 
	CheckItems 	= {},	
	CountItems 	= {},		
} 

function Data.OnItemsUpdate()
	for tier_name, items in pairs(Data.CheckItems) do 
		local count = 0
		for i = 1, #items do 
			if IsEquippedItem(items[i]) then 
				count = count + 1
			end 
		end 
		Data.CountItems[tier_name] = count
	end 
end

function Data.UpdateStance()
	Data.Stance = GetShapeshiftForm()
end 

A.Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_STARTED_MOVING", function()
	if Data.TimeStampMoving ~= TMW.time then 
		Data.TimeStampMoving = TMW.time 
		Data.TimeStampStaying = 0
	end 
end)

A.Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_STOPPED_MOVING", function()
	if Data.TimeStampStaying ~= TMW.time then 
		Data.TimeStampMoving = 0
		Data.TimeStampStaying = TMW.time 
	end 
end)

A.Listener:Add("ACTION_EVENT_PLAYER", "UPDATE_SHAPESHIFT_FORMS", 	Data.UpdateStance)
A.Listener:Add("ACTION_EVENT_PLAYER", "UPDATE_SHAPESHIFT_FORM", 	Data.UpdateStance)
A.Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_ENTERING_WORLD", 		Data.UpdateStance)
A.Listener:Add("ACTION_EVENT_PLAYER", "PLAYER_LOGIN", 				Data.UpdateStance)

local function RecoveryOffset()
	return A.GetPing() + A.GetCurrentGCD()
end 

-------------------------------------------------------------------------------
-- API 
-------------------------------------------------------------------------------
A.Player = {
	UnitID = "player",
}

function A.Player:IsStance(x)
	-- @return boolean 
	return Data.Stance == x
end 

function A.Player:GetStance()
	-- @return number 
	--[[Number - one of following:
		All
		0 = humanoid form
		Druid
		1 = Bear Form
		2 = Cat Form
		3 = Travel Form / Aquatic Form / Flight Form (all 3 location-dependent versions of Travel Form count as Form 3)
		4 = The first known of: Moonkin Form, Treant Form, Stag Form (in order)
		5 = The second known of: Moonkin Form, Treant Form, Stag Form (in order)
		6 = The third known of: Moonkin Form, Treant Form, Stag Form (in order)
		Note: The last 3 are ordered. For example, if you know Stag Form only, it is form 4. If you know both Treant and Stag, Treant is 4 and Stag is 5. If you know all 3, Moonkin is 4, Treant 5, and Stag 6.
		Priest
		1 = Shadowform
		Rogue
		1 = Stealth
		2 = Vanish / Shadow Dance (for Subtlety rogues, both Vanish and Shadow Dance return as Form 1)
		Shaman
		1 = Ghost Wolf
	]]	
	return Data.Stance
end 

function A.Player:IsFalling()
	-- @return boolean (more accurate IsFalling function, which excludes jumps), number 
    if IsFalling() then         
        if Data.TimeStampFalling == 0 then 
            Data.TimeStampFalling = TMW.time 
        elseif TMW.time - Data.TimeStampFalling > 1.7 then 
            return true, TMW.time - Data.TimeStampFalling
        end         
    elseif Data.TimeStampFalling > 0 then  
        Data.TimeStampFalling = 0
    end 
    return false, 0
end

function A.Player:GetFalling()
	-- @return number 
	return select(2, self:IsFalling())
end 

function A.Player:IsMoving()
	-- @return boolean 
	return Data.TimeStampMoving ~= 0
end 

function A.Player:IsMovingTime()
	-- @return number (seconds) 
	return Data.TimeStampMoving == 0 and 0 or TMW.time - Data.TimeStampMoving
end 

function A.Player:IsStaying()
	-- @return boolean 
	return Data.TimeStampStaying ~= 0 
end 

function A.Player:IsStayingTime()
	-- @return number (seconds) 
	return Data.TimeStampStaying == 0 and 0 or TMW.time - Data.TimeStampStaying
end 

function A.Player:IsMounted()
	-- @return boolean
	return IsMounted() and (not Data.AuraOnCombatMounted[A.PlayerClass] or A.Unit(self.UnitID):HasBuffs(Data.AuraOnCombatMounted[A.PlayerClass], true, true) == 0)
end 

function A.Player:IsStealthed()
	-- @return boolean 
	return IsStealthed() or (A.PlayerRace == "NightElf" and A.Unit(self.UnitID):HasBuffs(Data.AuraStealthed.Shadowmeld, true, true) > 0) or (Data.AuraStealthed[A.PlayerClass] and A.Unit(self.UnitID):HasBuffs(Data.AuraStealthed[A.PlayerClass], true, true) > 0) or A.Unit(self.UnitID):HasBuffs(Data.AuraStealthed.MassInvisible) > 0
end 

function A.Player:IsCasting()
	-- @return castName or nil 
	local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(self.UnitID):IsCasting()
	return not isChannel and castName or nil 
end 

function A.Player:IsChanneling()
	-- @return castName or nil 
	local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(self.UnitID):IsCasting()
	return isChannel and castName or nil 
end 

function A.Player:CastRemains(spellID)
	-- @return number 
	return A.Unit(self.UnitID):IsCastingRemains(spellID)
end 

function A.Player:CastCost()
	-- @return number 
	local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(self.UnitID):IsCasting()
	return castName and A.GetSpellPowerCost(spellID) or 0
end 

-- crit_chance
function A.Player:CritChancePct()
	return GetCritChance()
end

-- haste
function A.Player:HastePct()
	return GetHaste()
end

function A.Player:SpellHaste()
	return 1 / (1 + (self:HastePct() / 100))
end

-- mastery
function A.Player:MasteryPct()
	return GetMasteryEffect()
end

-- versatility
function A.Player:VersatilityDmgPct()
	return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
end

-- execute_time
function A.Player:Execute_Time(spellID) 
    -- @return boolean (GCD > CastTime or GCD)
    local gcd 		= A.GetGCD()
	local cast_time = A.Unit(self.UnitID):CastTime(spellID)     
    if cast_time > gcd then
        return cast_time 
    else
        return gcd
    end	
end 

function A.Player:GCDRemains()
	-- @return number 
	return A.GetCurrentGCD()
end 

-- Equipment
function A.Player:RemoveTier(tier)
	-- @usage A.Player:RemoveTier("Tier21")
	Data.CheckItems[tier] = nil 
	Data.CountItems[tier] = nil
	if not next(Data.CheckItems) then 
		Data.IierIsInitialized = nil 
		A.Listener:Remove("ACTION_EVENT_EQUIPMENT", "PLAYER_ENTERING_WORLD")
		A.Listener:Remove("ACTION_EVENT_EQUIPMENT", "PLAYER_EQUIPMENT_CHANGED")		
	end 
end

function A.Player:AddTier(tier, items)
	-- @usage A.Player:AddTier("Tier21", { itemID, itemID, itemID, itemID, itemID, itemID })
	Data.CheckItems[tier] = items 
	Data.CountItems[tier] = 0
	if not Data.IierIsInitialized then 
		Data.IierIsInitialized = true 
		A.Listener:Add("ACTION_EVENT_EQUIPMENT", "PLAYER_ENTERING_WORLD", 		Data.OnItemsUpdate)
		A.Listener:Add("ACTION_EVENT_EQUIPMENT", "PLAYER_EQUIPMENT_CHANGED",	Data.OnItemsUpdate)	
		Data.OnItemsUpdate()
	end 
end

function A.Player:GetTier(tier)
	-- @return number (how much parts of tier gear is equipped)
	return Data.CountItems[tier] or 0
end 

function A.Player:HasTier(tier, count)
	-- @return boolean 
	-- Set Bonuses are disabled in Challenge Mode (Diff = 8) and in Proving Grounds (Map = 1148)
	return self:GetTier(tier) >= count and InstanceInfo.difficultyID ~= 8 and InstanceInfo.ID ~= 1148 
end 

--------------------------
--- 0 | Mana Functions ---
--------------------------
-- mana.max
function A.Player:ManaMax()
	return UnitPowerMax(self.UnitID, ManaPowerType)
end

-- Mana
function A.Player:Mana()
	return UnitPower(self.UnitID, ManaPowerType)
end

-- Mana.pct
function A.Player:ManaPercentage()
	return (self:Mana() / self:ManaMax()) * 100
end

-- Mana.deficit
function A.Player:ManaDeficit()
	return self:ManaMax() - self:Mana()
end

-- "Mana.deficit.pct"
function A.Player:ManaDeficitPercentage()
	return (self:ManaDeficit() / self:ManaMax()) * 100
end

-- mana.regen
function A.Player:ManaRegen()
	return GetPowerRegen(self.UnitID)
end

-- Mana regen in a cast
function A.Player:ManaCastRegen(CastTime)
	if self:ManaRegen() == 0 then return -1 end
	return self:ManaRegen() * CastTime
end

-- "remaining_cast_regen"
function A.Player:ManaRemainingCastRegen(Offset)
	if self:ManaRegen() == 0 then return -1 end
	-- If we are casting, we check what we will regen until the end of the cast
	if self:IsCasting() then
		return self:ManaRegen() * (self:CastRemains() + (Offset or 0))
	-- Else we'll use the remaining GCD as "CastTime"
	else
		return self:ManaRegen() * (A.GetCurrentGCD() + (Offset or 0))
	end
end

-- mana.time_to_max
function A.Player:ManaTimeToMax()
	if self:ManaRegen() == 0 then return -1 end
	return self:ManaDeficit() / self:ManaRegen()
end

-- Mana Predicted with current cast
function A.Player:ManaP()
	local FutureMana = self:Mana() - self:CastCost()
	-- Add the mana tha we will regen during the remaining of the cast
	if self:Mana() ~= self:ManaMax() then FutureMana = FutureMana + self:ManaRemainingCastRegen() end
	-- Cap the max
	if FutureMana > self:ManaMax() then FutureMana = self:ManaMax() end
	return FutureMana
end

-- Mana.pct Predicted with current cast
function A.Player:ManaPercentageP()
	return (self:ManaP() / self:ManaMax()) * 100
end

-- Mana.deficit Predicted with current cast
function A.Player:ManaDeficitP()
	return self:ManaMax() - self:ManaP()
end

-- "Mana.deficit.pct" Predicted with current cast
function A.Player:ManaDeficitPercentageP()
	return (self:ManaDeficitP() / self:ManaMax()) * 100
end

--------------------------
--- 1 | Rage Functions ---
--------------------------
-- rage.max
function A.Player:RageMax()
	return UnitPowerMax(self.UnitID, RagePowerType)
end

-- rage
function A.Player:Rage()
	return UnitPower(self.UnitID, RagePowerType)
end

-- rage.pct
function A.Player:RagePercentage()
	return (self:Rage() / self:RageMax()) * 100
end

-- rage.deficit
function A.Player:RageDeficit()
	return self:RageMax() - self:Rage()
end

-- "rage.deficit.pct"
function A.Player:RageDeficitPercentage()
	return (self:RageDeficit() / self:RageMax()) * 100
end

---------------------------
--- 2 | Focus Functions ---
---------------------------
-- focus.max
function A.Player:FocusMax()
	return UnitPowerMax(self.UnitID, FocusPowerType)
end

-- focus
function A.Player:Focus()
	return UnitPower(self.UnitID, FocusPowerType)
end

-- focus.regen
function A.Player:FocusRegen()
	return GetPowerRegen(self.UnitID)
end

-- focus.pct
function A.Player:FocusPercentage()
	return (self:Focus() / self:FocusMax()) * 100
end

-- focus.deficit
function A.Player:FocusDeficit()
	return self:FocusMax() - self:Focus()
end

-- "focus.deficit.pct"
function A.Player:FocusDeficitPercentage()
	return (self:FocusDeficit() / self:FocusMax()) * 100
end

-- "focus.regen.pct"
function A.Player:FocusRegenPercentage()
	return (self:FocusRegen() / self:FocusMax()) * 100
end

-- focus.time_to_max
function A.Player:FocusTimeToMax()
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusDeficit() / self:FocusRegen()
end

-- "focus.time_to_x"
function A.Player:FocusTimeToX(Amount)
	if self:FocusRegen() == 0 then return -1 end
	return Amount > self:Focus() and (Amount - self:Focus()) / self:FocusRegen() or 0
end

-- "focus.time_to_x.pct"
function A.Player:FocusTimeToXPercentage(Amount)
	if self:FocusRegen() == 0 then return -1 end
	return Amount > self:FocusPercentage() and (Amount - self:FocusPercentage()) / self:FocusRegenPercentage() or 0
end

-- cast_regen
function A.Player:FocusCastRegen(CastTime)
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusRegen() * CastTime
end

-- "remaining_cast_regen"
function A.Player:FocusRemainingCastRegen(Offset)
	if self:FocusRegen() == 0 then return -1 end
	-- If we are casting, we check what we will regen until the end of the cast
	if self:IsCasting() then
		return self:FocusRegen() * (self:CastRemains() + (Offset or 0))
	-- Else we'll use the remaining GCD as "CastTime"
	else
		return self:FocusRegen() * (self:GCDRemains() + (Offset or 0))
	end
end

-- Get the Focus we will loose when our cast will end, if we cast.
function A.Player:FocusLossOnCastEnd()
	local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(self.UnitID):IsCasting()
	return castName and A.GetSpellPowerCost(spellID) or 0
end

-- Predict the expected Focus at the end of the Cast/GCD.
function A.Player:FocusPredicted(Offset)
	if self:FocusRegen() == 0 then return -1 end
	return math.min(self:FocusMax(), self:Focus() + self:FocusRemainingCastRegen(Offset) - self:FocusLossOnCastEnd())
end

-- Predict the expected Focus Deficit at the end of the Cast/GCD.
function A.Player:FocusDeficitPredicted(Offset)
	if self:FocusRegen() == 0 then return -1 end
	return self:FocusMax() - self:FocusPredicted(Offset)
end

-- Predict time to max Focus at the end of Cast/GCD
function A.Player:FocusTimeToMaxPredicted()
	if self:FocusRegen() == 0 then return -1 end
	local FocusDeficitPredicted = self:FocusDeficitPredicted()
	if FocusDeficitPredicted <= 0 then
		return 0
	end
	return FocusDeficitPredicted / self:FocusRegen()
end

----------------------------
--- 3 | Energy Functions ---
----------------------------
-- energy.max
function A.Player:EnergyMax()
	return UnitPowerMax(self.UnitID, EnergyPowerType)
end

-- energy
function A.Player:Energy()
	return UnitPower(self.UnitID, EnergyPowerType)
end

-- energy.regen
function A.Player:EnergyRegen()
	return GetPowerRegen(self.UnitID)
end

-- energy.pct
function A.Player:EnergyPercentage()
	return (self:Energy() / self:EnergyMax()) * 100
end

-- energy.deficit
function A.Player:EnergyDeficit()
	return self:EnergyMax() - self:Energy()
end

-- "energy.deficit.pct"
function A.Player:EnergyDeficitPercentage()
	return (self:EnergyDeficit() / self:EnergyMax()) * 100
end

-- "energy.regen.pct"
function A.Player:EnergyRegenPercentage()
	return (self:EnergyRegen() / self:EnergyMax()) * 100
end

-- energy.time_to_max
function A.Player:EnergyTimeToMax()
	if self:EnergyRegen() == 0 then return -1 end
	return self:EnergyDeficit() / self:EnergyRegen()
end

-- "energy.time_to_x"
function A.Player:EnergyTimeToX(Amount, Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return Amount > self:Energy() and (Amount - self:Energy()) / (self:EnergyRegen() * (1 - (Offset or 0))) or 0
end

-- "energy.time_to_x.pct"
function A.Player:EnergyTimeToXPercentage(Amount)
	if self:EnergyRegen() == 0 then return -1 end
	return Amount > self:EnergyPercentage() and (Amount - self:EnergyPercentage()) / self:EnergyRegenPercentage() or 0
end

-- "energy.cast_regen"
function A.Player:EnergyRemainingCastRegen(Offset)
    if self:EnergyRegen() == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() or self:IsChanneling() then
		return self:EnergyRegen() * (self:CastRemains() + (Offset or 0))
    -- Else we'll use the remaining GCD as "CastTime"
    else
		return self:EnergyRegen() * (self:GCDRemains() + (Offset or 0))
    end
end

-- Predict the expected Energy at the end of the Cast/GCD.
function A.Player:EnergyPredicted(Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return math.min(self:EnergyMax(), self:Energy() + self:EnergyRemainingCastRegen(Offset))
end

-- Predict the expected Energy Deficit at the end of the Cast/GCD.
function A.Player:EnergyDeficitPredicted(Offset)
	if self:EnergyRegen() == 0 then return -1 end
	return math.max(0, self:EnergyDeficit() - self:EnergyRemainingCastRegen(Offset))
end

-- Predict time to max energy at the end of Cast/GCD
function A.Player:EnergyTimeToMaxPredicted()
	if self:EnergyRegen() == 0 then return -1 end
	local EnergyDeficitPredicted = self:EnergyDeficitPredicted()
	if EnergyDeficitPredicted <= 0 then
		return 0
	end
	return EnergyDeficitPredicted / self:EnergyRegen()
end

----------------------------------
--- 4 | Combo Points Functions ---
----------------------------------
-- combo_points.max
function A.Player:ComboPointsMax()
	return UnitPowerMax(self.UnitID, ComboPointsPowerType)
end

-- combo_points
function A.Player:ComboPoints()
	return UnitPower(self.UnitID, ComboPointsPowerType) or 0
end

-- combo_points.deficit
function A.Player:ComboPointsDeficit()
	return self:ComboPointsMax() - self:ComboPoints()
end

---------------------------------
--- 5 | Runic Power Functions ---
---------------------------------
-- runicpower.max
function A.Player:RunicPowerMax()
	return UnitPowerMax(self.UnitID, RunicPowerPowerType)
end

-- runicpower
function A.Player:RunicPower()
	return UnitPower(self.UnitID, RunicPowerPowerType)
end

-- runicpower.pct
function A.Player:RunicPowerPercentage()
	return (self:RunicPower() / self:RunicPowerMax()) * 100
end

-- runicpower.deficit
function A.Player:RunicPowerDeficit()
	return self:RunicPowerMax() - self:RunicPower()
end

-- "runicpower.deficit.pct"
function A.Player:RunicPowerDeficitPercentage()
	return (self:RunicPowerDeficit() / self:RunicPowerMax()) * 100
end

---------------------------
--- 6 | Runes Functions ---
---------------------------
-- Computes any rune cooldown.
local function ComputeRuneCooldown(Slot, BypassRecovery)
	-- Get rune cooldown infos
	local CDTime, CDValue = GetRuneCooldown(Slot)
	-- Return 0 if the rune isn't in CD.
	if CDTime == 0 then return 0 end
	-- Compute the CD.
	local CD = CDTime + CDValue - TMW.time - (BypassRecovery and 0 or RecoveryOffset())
	-- Return the Rune CD
	return CD > 0 and CD or 0
end

-- rune
function A.Player:Rune()
	local Count = 0
	for i = 1, 6 do
		if ComputeRuneCooldown(i) == 0 then
			Count = Count + 1
		end
	end
	return Count
end

-- rune.time_to_x
function A.Player:RuneTimeToX(Value)
	if type(Value) ~= "number" then error("Value must be a number.") end
	if Value < 1 or Value > 6 then error("Value must be a number between 1 and 6.") end
	local Runes = {}
	for i = 1, 6 do
		Runes[i] = ComputeRuneCooldown(i)
	end
	table.sort(Runes, function(a, b) return a < b end)
	local Count = 1
	for _, CD in pairs(Runes) do
		if Count == Value then
			return CD
		end
		Count = Count + 1
	end
end

------------------------
--- 7 | Soul Shards  ---
------------------------
-- soul_shard.max
function A.Player:SoulShardsMax()
	return UnitPowerMax(self.UnitID, SoulShardsPowerType)
end

-- soul_shard
function A.Player:SoulShards()
	return WarlockPowerBar_UnitPower(self.UnitID)
end

-- soul shards predicted, customize in spec overrides
function A.Player:SoulShardsP()
	return WarlockPowerBar_UnitPower(self.UnitID)
end

-- soul_shard.deficit
function A.Player:SoulShardsDeficit()
	return self:SoulShardsMax() - self:SoulShards()
end

------------------------
--- 8 | Astral Power ---
------------------------
-- astral_power.max
function A.Player:AstralPowerMax()
	return UnitPowerMax(self.UnitID, LunarPowerPowerType)
end

-- astral_power
function A.Player:AstralPower(OverrideFutureAstralPower)
	return OverrideFutureAstralPower or UnitPower(self.UnitID, LunarPowerPowerType)
end

-- astral_power.pct
function A.Player:AstralPowerPercentage(OverrideFutureAstralPower)
	return (self:AstralPower(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
end

-- astral_power.deficit
function A.Player:AstralPowerDeficit(OverrideFutureAstralPower)
	local AstralPower = self:AstralPower(OverrideFutureAstralPower)
	return self:AstralPowerMax() - AstralPower
end

-- "astral_power.deficit.pct"
function A.Player:AstralPowerDeficitPercentage(OverrideFutureAstralPower)
	return (self:AstralPowerDeficit(OverrideFutureAstralPower) / self:AstralPowerMax()) * 100
end

--------------------------------
--- 9 | Holy Power Functions ---
--------------------------------
-- holy_power.max
function A.Player:HolyPowerMax()
	return UnitPowerMax(self.UnitID, HolyPowerPowerType)
end

-- holy_power
function A.Player:HolyPower()
	return UnitPower(self.UnitID, HolyPowerPowerType)
end

-- holy_power.pct
function A.Player:HolyPowerPercentage()
	return (self:HolyPower() / self:HolyPowerMax()) * 100
end

-- holy_power.deficit
function A.Player:HolyPowerDeficit()
	return self:HolyPowerMax() - self:HolyPower()
end

-- "holy_power.deficit.pct"
function A.Player:HolyPowerDeficitPercentage()
	return (self:HolyPowerDeficit() / self:HolyPowerMax()) * 100
end

------------------------------
-- 11 | Maelstrom Functions --
------------------------------
-- maelstrom.max
function A.Player:MaelstromMax()
	return UnitPowerMax(self.UnitID, MaelstromPowerType)
end

-- maelstrom
function A.Player:Maelstrom()
	return UnitPower(self.UnitID, MaelstromPowerType)
end

-- maelstrom.pct
function A.Player:MaelstromPercentage()
	return (self:Maelstrom() / self:MaelstromMax()) * 100
end

-- maelstrom.deficit
function A.Player:MaelstromDeficit()
	return self:MaelstromMax() - self:Maelstrom()
end

-- "maelstrom.deficit.pct"
function A.Player:MaelstromDeficitPercentage()
	return (self:MaelstromDeficit() / self:MaelstromMax()) * 100
end

--------------------------------------
--- 12 | Chi Functions (& Stagger) ---
--------------------------------------
-- chi.max
function A.Player:ChiMax()
	return UnitPowerMax(self.UnitID, ChiPowerType)
end

-- chi
function A.Player:Chi()
	return UnitPower(self.UnitID, ChiPowerType)
end

-- chi.pct
function A.Player:ChiPercentage()
	return (self:Chi() / self:ChiMax()) * 100
end

-- chi.deficit
function A.Player:ChiDeficit()
	return self:ChiMax() - self:Chi()
end

-- "chi.deficit.pct"
function A.Player:ChiDeficitPercentage()
	return (self:ChiDeficit() / self:ChiMax()) * 100
end

-- "stagger.max"
function A.Player:StaggerMax()
	return A.Unit(self.UnitID):HealthMax()
end

-- stagger_amount
function A.Player:Stagger()
	return UnitStagger(self.UnitID)
end

-- stagger_percent
function A.Player:StaggerPercentage()
	return (self:Stagger() / self:StaggerMax()) * 100
end

------------------------------
-- 13 | Insanity Functions ---
------------------------------
-- insanity.max
function A.Player:InsanityMax()
	return UnitPowerMax(self.UnitID, InsanityPowerType)
end

-- insanity
function A.Player:Insanity()
	return UnitPower(self.UnitID, InsanityPowerType)
end

-- insanity.pct
function A.Player:InsanityPercentage()
	return (self:Insanity() / self:InsanityMax()) * 100
end

-- insanity.deficit
function A.Player:InsanityDeficit()
	return self:InsanityMax() - self:Insanity()
end

-- "insanity.deficit.pct"
function A.Player:InsanityDeficitPercentage()
	return (self:InsanityDeficit() / self:InsanityMax()) * 100
end

-- Insanity Drain
function A.Player:Insanityrain()
	local void_form_stack = A.Unit(self.UnitID):HasBuffsStacks(194249, true)
	return (void_form_stack == 0 and 0) or (6 + 0.68 * void_form_stack)
end

-----------------------------------
-- 16 | Arcane Charges Functions --
-----------------------------------
-- arcanecharges.max
function A.Player:ArcaneChargesMax()
	return UnitPowerMax(self.UnitID, ArcaneChargesPowerType)
end

-- arcanecharges
function A.Player:ArcaneCharges()
	return UnitPower(self.UnitID, ArcaneChargesPowerType)
end

-- arcanecharges.pct
function A.Player:ArcaneChargesPercentage()
	return (self:ArcaneCharges() / self:ArcaneChargesMax()) * 100
end

-- arcanecharges.deficit
function A.Player:ArcaneChargesDeficit()
	return self:ArcaneChargesMax() - self:ArcaneCharges()
end

-- "arcanecharges.deficit.pct"
function A.Player:ArcaneChargesDeficitPercentage()
	return (self:ArcaneChargesDeficit() / self:ArcaneChargesMax()) * 100
end

---------------------------
--- 17 | Fury Functions ---
---------------------------
-- fury.max
function A.Player:FuryMax()
	return UnitPowerMax(self.UnitID, FuryPowerType)
end

-- fury
function A.Player:Fury()
	return UnitPower(self.UnitID, FuryPowerType)
end

-- fury.pct
function A.Player:FuryPercentage()
	return (self:Fury() / self:FuryMax()) * 100
end

-- fury.deficit
function A.Player:FuryDeficit()
	return self:FuryMax() - self:Fury()
end

-- "fury.deficit.pct"
function A.Player:FuryDeficitPercentage()
	return (self:FuryDeficit() / self:FuryMax()) * 100
end

---------------------------
--- 18 | Pain Functions ---
---------------------------
-- pain.max
function A.Player:PainMax()
	return UnitPowerMax(self.UnitID, PainPowerType)
end

-- pain
function A.Player:Pain()
	return UnitPower(self.UnitID, PainPowerType)
end

-- pain.pct
function A.Player:PainPercentage()
	return (self:Pain() / self:PainMax()) * 100
end

-- pain.deficit
function A.Player:PainDeficit()
	return self:PainMax() - self:Pain()
end

-- "pain.deficit.pct"
function A.Player:PainDeficitPercentage()
	return (self:PainDeficit() / self:PainMax()) * 100
end

------------------------------
--- Predicted Resource Map ---
------------------------------
A.Player.PredictedResourceMap = {
	-- Mana
	[0] = function() return A.Player:ManaP() end,
	-- Rage
	[1] = function() return A.Player:Rage() end,
	-- Focus
	[2] = function() return A.Player:FocusPredicted() end,
	-- Energy
	[3] = function() return A.Player:EnergyPredicted() end,
	-- ComboPoints
	[4] = function() return A.Player:ComboPoints() end,
	-- Runes
	[5] = function() return A.Player:Runes() end,
	-- Runic Power
	[6] = function() return A.Player:RunicPower() end,
	-- Soul Shards
	[7] = function() return A.Player:SoulShardsP() end,
	-- Astral Power
	[8] = function() return A.Player:AstralPower() end,
	-- Holy Power
	[9] = function() return A.Player:HolyPower() end,
	-- Maelstrom
	[11] = function() return A.Player:Maelstrom() end,
	-- Chi
	[12] = function() return A.Player:Chi() end,
	-- Insanity
	[13] = function() return A.Player:Insanity() end,
	-- Arcane Charges
	[16] = function() return A.Player:ArcaneCharges() end,
	-- Fury
	[17] = function() return A.Player:Fury() end,
	-- Pain
	[18] = function() return A.Player:Pain() end,
}