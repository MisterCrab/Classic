-------------------------------------------------------------------------------------
-- I decided to fix issue which owner of Lib don't want to fix, this mostly game bug
-- Issue is named CLEU on event SPELL_CAST_FAILED 
-- This thing works wrong in over 50% cases which is not okay
-- This is additional code which make extension for original Lib 
-- This code checking unit movement to properly fire SPELL_CAST_FAILED event 
-- Cost around zero in performance even on 0 update interval
-------------------------------------------------------------------------------------

local LibClassicCasterino 	= LibStub("LibClassicCasterino")
local f 					= LibClassicCasterino.frame
local callbacks 			= LibClassicCasterino.callbacks
local casters 				= LibClassicCasterino.casters

local TMW 					= TMW 
local A						= Action
local Unit 					= A.Unit 
local MultiUnits			= A.MultiUnits
local TeamCache 			= A.TeamCache
local FriendlyGUIDs			= TeamCache.Friendly.GUIDs
local EnemyGUIDs			= TeamCache.Enemy.GUIDs

local UnitGUID 				= UnitGUID
local GetUnitSpeed			= GetUnitSpeed
local next, pairs, ipairs	= next, pairs, ipairs

local commonUnits 			= {
    -- "player",
    "target",
    "targettarget",
	"mouseover",
    "pet",
}

local function FireToUnits(event, guid, ...)
    for _, unit in ipairs(commonUnits) do
        if UnitGUID(unit) == guid then
            callbacks:Fire(event, unit, ...)
        end
    end

    local fUnit = FriendlyGUIDs[guid]
    if fUnit then
        callbacks:Fire(event, fUnit, ...)
    end
	
    local eUnit = EnemyGUIDs[guid]
    if eUnit then
        callbacks:Fire(event, eUnit, ...)
    end	

	local NameplatesGUID 	= MultiUnits:GetActiveUnitPlatesGUID()
    local nameplateUnit 	= NameplatesGUID[guid]
    if nameplateUnit then
        callbacks:Fire(event, nameplateUnit, ...)
    end
end

local function CastStop(srcGUID, castType, suffix)
    local currentCast = casters[srcGUID]
    if currentCast then
        castType = castType or currentCast[1]

        casters[srcGUID] = nil

        if castType == "CAST" then
            local event = "UNIT_SPELLCAST_"..suffix
            FireToUnits(event, srcGUID)
        else
            FireToUnits("UNIT_SPELLCAST_CHANNEL_STOP", srcGUID)
        end
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
	if not next(casters) then 
		return 
	end 
	
    for i = 1, #commonUnits do
		local GUID = UnitGUID(commonUnits[i])
        if GUID and casters[GUID] and GetUnitSpeed(commonUnits[i]) ~= 0 then
            CastStop(GUID, nil, "FAILED")
			return 
        end
    end
	
	-- If we're outside pvp BG then use nameplates instead of unitID "arena" since it's not exist
	-- If existd then better to use their GUIDs since they are not limited to distance 20yards
	if not next(EnemyGUIDs) then 
		local NameplatesGUID 	= MultiUnits:GetActiveUnitPlatesGUID()
		if nameplateUnit and next(NameplatesGUID) then
			for guid, unit in pairs(NameplatesGUID) do 
				if casters[guid] and GetUnitSpeed(unit) ~= 0 then
					CastStop(guid, nil, "FAILED")
					return
				end 
			end 
		end
	end 

	for guid, unit in pairs(FriendlyGUIDs) do 
		if casters[guid] and GetUnitSpeed(unit) ~= 0 then
            CastStop(guid, nil, "FAILED")
			return 
        end
	end 

	for guid, unit in pairs(EnemyGUIDs) do 
		if casters[guid] and GetUnitSpeed(unit) ~= 0 then
            CastStop(guid, nil, "FAILED")
			return
        end
	end 
end)