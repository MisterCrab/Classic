-- https://github.com/herotc/hero-lib/blob/HeroLib/Events/PMultiplier.lua
local TMW 							= TMW
local A 							= Action 
local Player 						= A.Player
local Unit							= A.Unit 

local error, table, pairs, type 	= 
	  error, table, pairs, type

local UnitGUID,   GetSpellInfo 		= 
	  UnitGUID, A.GetSpellInfo
	
local CombatLogGetCurrentEventInfo 	= CombatLogGetCurrentEventInfo	
	
local ListenedSpells 				= {}
local ListenedAuras 				= {}
local ListenedLastCast 				= {}	

-------------------------------------------------------------------------------
-- Locals 
-------------------------------------------------------------------------------	
-- PMultiplier Calculator
local function ComputePMultiplier(ListenedSpell)
    local PMultiplier = 1
    for j = 1, #ListenedSpell.Buffs do
        local Buff = ListenedSpell.Buffs[j]
        local Spell = Buff[1]
        local Modifier = Buff[2]
        -- Check if we did registered a Buff to check + a modifier (as a number or through a function).
        if Modifier then
            if Unit("player"):HasBuffs(Spell, true) > 0 or (ListenedLastCast[SpellID] and TMW.time - ListenedLastCast[SpellID] < 0.1)  then
                local ModifierType = type(Modifier)
                if ModifierType == "number" then
                    PMultiplier = PMultiplier * Modifier
                elseif ModifierType == "function" then
                    PMultiplier = PMultiplier * Modifier()
                end
            end
        else
            -- If there is only one element, then check if it's an AIO function and call it.
            if type(Spell) == "function" then
                PMultiplier = PMultiplier * Spell()
            end
        end
    end
    return PMultiplier
end

local function PMultiplierLaunch(...)
	-- Feral 
	if Unit("player"):HasSpec(103) then 
		A.Listener:Add("ACTION_EVENT_PMULTIPLIER", "COMBAT_LOG_EVENT_UNFILTERED", function(...)
			local _, EVENT, _, SourceGUID, _,_,_, DestGUID, _, _, _, SpellID  = CombatLogGetCurrentEventInfo()
			
			-- PMultiplier OnCast Listener
			if EVENT == "SPELL_CAST_SUCCESS" then 
				local ListenedSpell = ListenedSpells[SpellID]
				if ListenedSpell then
					local PMultiplier = ComputePMultiplier(ListenedSpell)
					ListenedSpell.PMultiplier[DestGUID] = { PMultiplier = PMultiplier, Time = TMW.time, Applied = false }					
				end    
			-- PMultiplier OnApply/OnRefresh Listener
			elseif EVENT == "SPELL_AURA_APPLIED" or EVENT == "SPELL_AURA_REFRESH" then 
				local ListenedAura = ListenedAuras[SpellID]
				if ListenedAura then
					local ListenedSpell = ListenedSpells[ListenedAura]
					if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
						ListenedSpell.PMultiplier[DestGUID].Applied = true
					end
				end    
			elseif EVENT == "SPELL_AURA_REMOVED" then 
				local ListenedAura = ListenedAuras[SpellID]				
				if ListenedAura then					
					local ListenedSpell = ListenedSpells[ListenedAura]
					if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
						ListenedLastCast[SpellID] = TMW.time
						ListenedSpell.PMultiplier[DestGUID].Applied = false
					end
				end    
			-- PMultiplier OnRemove & OnUnitDeath Listener    
			elseif EVENT == "UNIT_DIED" or EVENT == "UNIT_DESTROYED" then         
				for SpellID, Spell in pairs(ListenedSpells) do
					if Spell.PMultiplier[DestGUID] then
						Spell.PMultiplier[DestGUID] = nil
					end
				end            
			end 		
		end)
	else 
		A.Listener:Remove("ACTION_EVENT_PMULTIPLIER", "COMBAT_LOG_EVENT_UNFILTERED")
	end
end

local function RegisterPMultiplier(...)
    local Args = { ... }
    local SelfSpellID = Args[1]
    -- Get the SpellID to check on AURA_APPLIED/AURA_REFRESH, should be specified as first arg or it'll take the current spell object.
    local SpellAura = SelfSpellID
    if type(Args[2]) == "number" then
        SpellAura = Args[2]
        table.remove(Args, 2)
    end
    table.remove(Args, 1)
    
    ListenedAuras[SpellAura] = SelfSpellID
    ListenedSpells[SelfSpellID] = { Buffs = Args, PMultiplier = {} }
    --[[
    for k,v in pairs(Args) do
        if type(v) == "table" then
            for _, v1 in pairs(v) do
                if type(v1) == "function" then
                    print(k .. " and " .. v1())
                else
                    print(k .. " and " .. v1)
                end
            end
        elseif type(v) == "function" then
            print(k .. " and " .. v())
        else
            print(k .. " and " .. v)           
        end
    end
    print(Args[1])
]]
end

local function SpellRegisterError(Spell)
    local SpellName = GetSpellInfo(Spell)
    if SpellName then
        return "You forgot to register the spell: " .. SpellName .. " in PMultiplier handler."
    else
        return "You forgot to register the spell object."
    end
end

-------------------------------------------------------------------------------
-- Register  
-------------------------------------------------------------------------------	
if A.PlayerClass == "DRUID" then 
	A.Listener:Add("ACTION_EVENT_PMULTIPLIER", "PLAYER_SPECIALIZATION_CHANGED", PMultiplierLaunch)
	PMultiplierLaunch()
	RegisterPMultiplier( -- Rake dot and action
		1822,    -- Rake action
		155722,  -- Rake dot
		{function ()
				return Player:IsStealthed() and 2 or 1
		end},
		-- BloodtalonsBuff, SavageRoar, TigersFury
		{145152, 1.2}, {52610, 1.15}, {5217, 1.15}
	)
	RegisterPMultiplier(
		1079, -- Rip action
		-- BloodtalonsBuff, SavageRoar, TigersFury
		{145152, 1.2}, {52610, 1.15}, {5217, 1.15}
	)
end 

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------	
-- dot.foo.pmultiplier
function A.PMultiplier(unitID, SpellID)
    if ListenedSpells[SpellID].PMultiplier then
        local UnitDot = ListenedSpells[SpellID].PMultiplier[UnitGUID(unitID)]
        return UnitDot and UnitDot.Applied and UnitDot.PMultiplier or 0
    else
        error(SpellRegisterError(SpellID))
    end
end

-- action.foo.persistent_multiplier
-- Player:PMultiplier
function A.Persistent_PMultiplier(SpellID)
    local ListenedSpell = ListenedSpells[SpellID]
    if ListenedSpell then
        return ComputePMultiplier(ListenedSpell)
    else
        error(SpellRegisterError(SpellID))
    end
end

--[[
RegisterPMultiplier( -- Rake dot and action
    1822,
    155722, 
    {function ()
            return Player:IsStealthed() and 2 or 1
    end},
    {145152, 1.2}, {52610, 1.15}, {5217, 1.15}
)
RegisterPMultiplier(
    1079, -- Rip action
    -- BloodtalonsBuff, SavageRoar, TigersFury
    {145152, 1.2}, {52610, 1.15}, {5217, 1.15}
)
-- Usage
A.Persistent_PMultiplier(1822)
A.PMultiplier("target", 1822)
]]

