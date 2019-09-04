-------------------------------------------------------------------------------
--[[ 
Global nil-able variables:
A.Zone				(@string)
A.IsInInstance		(@boolean)
A.TimeStampZone 	(@number)
A.TimeStampDuel 	(@number)
A.IsInPvP 			(@boolean)
A.IsInDuel			(@boolean)
A.IsInWarMode		(@boolean)

Global tables:
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------

local TMW 				= TMW
local A   				= Action
local ThreatLib			= LibStub:GetLibrary("ThreatClassic-1.0")

A.InstanceInfo			= {}
A.TeamCache				= { 
	threatData			= {},
	Friendly 			= {
		Size			= 1,
		GUIDs			= {},
		HEALER			= {},
		TANK			= {},
		DAMAGER			= {},
		DAMAGER_MELEE	= {},
		DAMAGER_RANGE	= {},
	},
	Enemy 				= {
		Size 			= 0,
		GUIDs 			= {},
		HEALER			= {},
		TANK			= {},
		DAMAGER			= {},
		DAMAGER_MELEE	= {},
		DAMAGER_RANGE	= {},
	},
}

local _G, table, pairs, type, wipe = 
	  _G, table, pairs, type, wipe

local huge 				= math.huge 

local IsInRaid, IsInGroup, IsInInstance, RequestBattlefieldScoreData = 
	  IsInRaid, IsInGroup, IsInInstance, RequestBattlefieldScoreData

local UnitIsUnit, UnitInBattleground, UnitExists, UnitIsFriend, UnitGUID = 
	  UnitIsUnit, UnitInBattleground, UnitExists, UnitIsFriend, UnitGUID

local GetInstanceInfo, GetNumBattlefieldScores, GetNumGroupMembers =  
	  GetInstanceInfo, GetNumBattlefieldScores, GetNumGroupMembers    

-------------------------------------------------------------------------------
-- Threat Library 
-------------------------------------------------------------------------------
local loaded 						= false 
local oldTime 						= 0
local UnitThreatSituation			= function(unit, mob) return ThreatLib:UnitThreatSituation(unit, mob) end 
local UnitDetailedThreatSituation	= function(unit, mob) return ThreatLib:UnitDetailedThreatSituation(unit, mob) end 

local function UpdateThreatData(unit)
	if not UnitExists(unit) then 
		return 
	end 
	-- check target of target if currently targeting a friend
	local target = UnitIsFriend("player", "target") and "targettarget" or "target"
	local isTanking, status, scaledPercent, rawThreatPercent, threatValue, GUID = UnitDetailedThreatSituation(unit, target) -- Lib modified to return by last argument unitGUID !
	if threatValue and threatValue < 0 then
		threatValue = threatValue + 410065408
	end
	
	-- In case if new lib version overwrite this version 
	if not GUID then 
		GUID = UnitGUID(unit)
	end 
	
	A.TeamCache.threatData[GUID] = {
		unit			= unit,
		isTanking		= isTanking,
		status			= status,
		scaledPercent	= scaledPercent or 0,
		threatValue		= threatValue or 0,
	}
end

local function CheckStatus(event)
	if not loaded then 
		return
	end
	
	local target = UnitIsFriend("player", "target") and "targettarget" or "target"

	if UnitExists(target) then 
		if TMW.time - oldTime > 0.25 then
			-- wipe
			wipe(A.TeamCache.threatData)
			-- group
			if A.TeamCache.Friendly.Size > 0 then
				local unit = A.TeamCache.Friendly.Type
				for i = 1, A.TeamCache.Friendly.Size do
					UpdateThreatData(unit .. i)
					UpdateThreatData(unit .. "pet" .. i)
				end
				-- party excludes player/pet
				if not A.TeamCache.Friendly.Type ~= "raid" then
					UpdateThreatData("player")
					UpdateThreatData("pet")
				end
			-- solo
			else
				UpdateThreatData("player")
				UpdateThreatData("pet")
			end
			oldTime = TMW.time
		end
	end
end

local function OnLoginThreatLib()
	A.Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_ENTERING_WORLD", 	CheckStatus)
	A.Listener:Add("ACTION_EVENT_THREAT_LIB", "GROUP_ROSTER_UPDATE", 	CheckStatus)
	A.Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_TARGET_CHANGED", 	CheckStatus)
	A.Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_REGEN_DISABLED", 	CheckStatus)
	A.Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_REGEN_ENABLED", 	CheckStatus)
	ThreatLib:RegisterCallback("Activate", 		CheckStatus)
	ThreatLib:RegisterCallback("Deactivate", 	CheckStatus)
	ThreatLib:RegisterCallback("ThreatUpdated", CheckStatus)
	ThreatLib:RequestActiveOnSolo(true)  	  	
	loaded = true 
	A.Listener:Remove("ACTION_EVENT_THREAT_LIB", "PLAYER_LOGIN")
end 

A.Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_LOGIN", 				OnLoginThreatLib)

-------------------------------------------------------------------------------
-- Instance, Zone, Mode, Duel, TeamCache
-------------------------------------------------------------------------------	  
function A:GetTimeSinceJoinInstance()
	-- @return number
	return (self.TimeStampZone and TMW.time - self.TimeStampZone) or huge
end 

function A:GetTimeDuel()
	-- @return number
	return (self.IsInDuel and TMW.time - self.TimeStampDuel - ACTION_CONST_CACHE_DEFAULT_OFFSET_DUEL) or 0
end 
 
function A:CheckInPvP()
	-- @return boolean
    return 
    self.Zone == "pvp" or 
    UnitInBattleground("player") or 
    ( A.Unit("target"):IsPlayer() and A.Unit("target"):IsEnemy() )
end

local LastEvent
local function OnEvent(event, ...)    
    -- Don't call it several times
    if TMW.time == LastEvent then 
        return 
    end 
    LastEvent = TMW.time
	
	-- Update IsInInstance, Zone
    A.IsInInstance, A.Zone = IsInInstance()
	if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LOGIN" then 
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		if name then 
			A.InstanceInfo.Name 		= name 
			A.InstanceInfo.Type 		= instanceType
			A.InstanceInfo.difficultyID = difficultyID
			A.InstanceInfo.ID 			= instanceID
			A.InstanceInfo.GroupSize	= instanceGroupSize
			A.TimeStampZone 			= TMW.time
		end 
	end 
	
	-- Update Mode, Duel
    if not A.IsLockedMode then          		
		if event == "DUEL_REQUESTED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = true, true, TMW.time
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			return
		elseif event == "DUEL_FINISHED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = A:CheckInPvP(), nil, nil
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			return
		end            
		
		if not A.IsInDuel and (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_LOGIN") then                                
			A.IsInPvP = A:CheckInPvP()  
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
		end  
	end
	
	-- Update Units 
	if event == "UPDATE_INSTANCE_INFO" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then 
		-- Wipe Friendly 
		for _, v in pairs(A.TeamCache.Friendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy TODO: Classic	
		for _, v in pairs(A.TeamCache.Enemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
				
		-- Enemy
		if A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			A.TeamCache.Enemy.Size = GetNumBattlefieldScores()         
			A.TeamCache.Enemy.Type = "arena"
		else
			A.TeamCache.Enemy.Size = 0 
			A.TeamCache.Enemy.Type = nil 
		end
		
		-- TODO: Classic 
		if A.TeamCache.Enemy.Size > 0 then                
			for i = 1, A.TeamCache.Enemy.Size do 
				local arena = "arena" .. i
				local guid 	= UnitGUID(arena)
				if guid then 
					A.TeamCache.Enemy.GUIDs[guid] = arena 
					if A.Unit(arena):IsHealer() then 
						A.TeamCache.Enemy.HEALER[arena] = arena
					elseif A.Unit(arena):IsTank() then 
						A.TeamCache.Enemy.TANK[arena] = arena
					else
						A.TeamCache.Enemy.DAMAGER[arena] = arena
						if A.Unit(arena):IsMelee() then 
							A.TeamCache.Enemy.DAMAGER_MELEE[arena] = arena
						else 
							A.TeamCache.Enemy.DAMAGER_RANGE[arena] = arena
						end                        
					end
				end 
			end   
		end          
		
		-- Friendly
		A.TeamCache.Friendly.Size = GetNumGroupMembers()
		if IsInRaid() then
			A.TeamCache.Friendly.Type = "raid"
		elseif IsInGroup() then
			A.TeamCache.Friendly.Type = "party"    
		else 
			A.TeamCache.Friendly.Type = nil 
		end    
		
		if A.TeamCache.Friendly.Size > 1 and A.TeamCache.Friendly.Type then 
			for i = 1, A.TeamCache.Friendly.Size do 
				local member = A.TeamCache.Friendly.Type .. i    
				local guid 	= UnitGUID(member)
				if guid then 
					A.TeamCache.Friendly.GUIDs[guid] = member 
					if not UnitIsUnit(member, "player") then 
						if A.Unit(member):IsHealer() then 
							A.TeamCache.Friendly.HEALER[member] = member
						elseif A.Unit(member):IsTank() then  
							A.TeamCache.Friendly.TANK[member] = member
						else 
							A.TeamCache.Friendly.DAMAGER[member] = member
							if A.Unit(member):IsMelee() then 
								A.TeamCache.Friendly.DAMAGER_MELEE[member] = member
							else 
								A.TeamCache.Friendly.DAMAGER_RANGE[member] = member
							end 
						end
					end
				end 
			end 
		end		
	end 
	
	if event == "PLAYER_ENTERING_WORLD" or "PLAYER_ENTERING_BATTLEGROUND" then 
		TMW:Fire("TMW_ACTION_ENTERING") 		-- callback is used in Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
	end 
	
	if event ~= "PLAYER_TARGET_CHANGED" and event ~= "DUEL_FINISHED" and event ~= "DUEL_REQUESTED" then 
		TMW:Fire("TMW_ACTION_GROUP_UPDATE") 	-- callback is used in Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
	end 
end 

A.Listener:Add("ACTION_EVENT_BASE", "DUEL_FINISHED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "DUEL_REQUESTED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_INDOORS", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_NEW_AREA", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "UPDATE_INSTANCE_INFO", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "GROUP_ROSTER_UPDATE", 				OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_WORLD", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_BATTLEGROUND", 	OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_TARGET_CHANGED", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_LOGIN", 					OnEvent)
