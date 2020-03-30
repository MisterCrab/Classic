-------------------------------------------------------------------------------------
-- Original lib has missed some spells
-- This file extend spell list and API methods
-------------------------------------------------------------------------------------

local Lib 												= LibStub("DRList-1.0")
local L													= Lib.L
local diminishedDurations_classic						= Lib.diminishedDurations.classic
local categoryNames_classic								= Lib.categoryNames.classic
local spellList											= Lib.spellList

local _G 												= _G
local GetSpellInfo										= _G.GetSpellInfo

-------------------------------------------------------------------------------
-- API extend  
-------------------------------------------------------------------------------	  
categoryNames_classic.disarm 							= L.DISARMS

--- Get next successive diminished duration
-- @tparam number diminished How many times the DR has been applied so far
-- @tparam[opt="default"] string category Unlocalized category name
-- @usage local reduction = DRList:GetNextDR(1) -- returns 0.50, half duration on debuff
-- @treturn number DR percentage in decimals. Returns 0 if max DR is reached or arguments are invalid.
function Lib:GetNextDR(diminished, category)
    local durations = diminishedDurations_classic[category or "default"]
    if not durations and categoryNames_classic[category] then
        -- Redirect to default when "stun", "root" etc is passed
        durations = diminishedDurations_classic["default"]		
    end

	for i = 1, #durations do
		if diminished > durations[i] then
			return durations[i], i, #durations
		end
	end
	return 0, #durations, #durations -- means full DR applied by max of max applications 
end

-- Get ApplicationMax
function Lib:GetApplicationMax(category)
	local durations = diminishedDurations_classic[category or "default"] or diminishedDurations_classic.default
	return durations and #durations or 0
end 

-------------------------------------------------------------------------------
-- List extend  
-------------------------------------------------------------------------------	  
-- Disarms
spellList[GetSpellInfo(676)]     	= { category = "disarm", spellID = 676 }     		-- Disarm
spellList[GetSpellInfo(14251)]   	= { category = "disarm", spellID = 14251 }     		-- Riposte
spellList[GetSpellInfo(23365)]   	= { category = "disarm", spellID = 23365 }     		-- Dropped Weapon

-- Incapacitates
spellList[GetSpellInfo(2094)]		= { category = "incapacitate", spellID = 2094 } 	-- Blind 
spellList[GetSpellInfo(9484)]		= { category = "incapacitate", spellID = 9484 } 	-- Shackle Undead 
spellList[GetSpellInfo(710)]		= { category = "incapacitate", spellID = 710 } 		-- Banish

-- Turn Undead 
spellList[GetSpellInfo(2878)]    	= { category = "fear", spellID = 2878 }          	-- Turn Undead

-- Stuns 
spellList[GetSpellInfo(19482)]  	= { category = "stun", spellID = 19482 }   			-- War Stomp (Doomguard pet)