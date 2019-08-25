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
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize, isRated)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------

local TMW 				= TMW
local A   				= Action

A.InstanceInfo			= {}
A.TeamCache				= { 
	Friendly 			= {
		Size			= 1,
		HEALER			= {},
		TANK			= {},
		DAMAGER			= {},
		DAMAGER_MELEE	= {},
		DAMAGER_RANGE	= {},
	},
	Enemy 				= {
		Size 			= 0,
		HEALER			= {},
		TANK			= {},
		DAMAGER			= {},
		DAMAGER_MELEE	= {},
		DAMAGER_RANGE	= {},
	},
}

local _G, pairs, type, wipe = 
	  _G, pairs, type, wipe

local huge 				= math.huge 
local PvP 				= _G.C_PvP

local IsInRaid, IsInGroup, IsInInstance, IsActiveBattlefieldArena, RequestBattlefieldScoreData = 
	  IsInRaid, IsInGroup, IsInInstance, IsActiveBattlefieldArena, RequestBattlefieldScoreData

local UnitIsUnit, UnitInBattleground = 
	  UnitIsUnit, UnitInBattleground

local GetInstanceInfo, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers =
	  GetInstanceInfo, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers

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
    self.Zone == "arena" or 
    self.Zone == "pvp" or 
    UnitInBattleground("player") or 
    IsActiveBattlefieldArena() or
    PvP.IsWarModeDesired() or
    ( A.Unit("target"):IsPlayer() and A.Unit("target"):IsEnemy() )
end

function A.UI_INFO_MESSAGE_IS_WARMODE(...)
	-- @return boolean
	local ID, MSG = ...		
    return (type(MSG) == "string" and (MSG == ACTION_CONST_ERR_PVP_WARMODE_TOGGLE_OFF or MSG == ACTION_CONST_ERR_PVP_WARMODE_TOGGLE_ON)) or false
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
			A.InstanceInfo.isRated		= PvP.IsRatedMap()
			A.TimeStampZone 			= TMW.time
		end 
	end 
	
	-- Update Mode, Duel
    if not A.IsLockedMode then
		if event == "UI_INFO_MESSAGE" and A.UI_INFO_MESSAGE_IS_WARMODE(...) then     
			A.IsInPvP = PvP.IsWarModeDesired()
			A.IsInWarMode = A.IsInPvP or nil
			TMW:Fire("TMW_ACTION_MODE_CHANGED") 
			TMW:Fire("TMW_ACTION_DEPRECATED")			
			return 
		end            
		
		if event == "DUEL_REQUESTED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = true, true, TMW.time
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			return
		elseif event == "DUEL_FINISHED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = A:CheckInPvP(), nil, nil
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			TMW:Fire("TMW_ACTION_DEPRECATED")
			return
		end            
		
		if not A.IsInDuel and (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_LOGIN") then                                
			A.IsInPvP = A:CheckInPvP()  
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
		end  
	end
	
	-- Update Units 
	if event == "UPDATE_INSTANCE_INFO" or event == "GROUP_ROSTER_UPDATE" or event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then 
		-- Wipe Friendly 
		for _, v in pairs(A.TeamCache.Friendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy
		for _, v in pairs(A.TeamCache.Enemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
		
		-- Enemy  		
		if A.Zone == "arena" then 
			A.TeamCache.Enemy.Size = GetNumArenaOpponents() -- GetNumArenaOpponentSpecs()    
			A.TeamCache.Enemy.Type = "arena"
		elseif A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			A.TeamCache.Enemy.Size = GetNumBattlefieldScores()         
			A.TeamCache.Enemy.Type = "arena"
		else
			A.TeamCache.Enemy.Size = 0 
			A.TeamCache.Enemy.Type = nil 
		end
		
		if A.TeamCache.Enemy.Size > 0 then                
			for i = 1, A.TeamCache.Enemy.Size do 
				local arena = "arena" .. i
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
	
	TMW:Fire("TMW_ACTION_DEPRECATED")
end 

A.Listener:Add("ACTION_EVENT_BASE", "DUEL_FINISHED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "DUEL_REQUESTED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_INDOORS", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_NEW_AREA", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "UI_INFO_MESSAGE", 					OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "UPDATE_INSTANCE_INFO", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "GROUP_ROSTER_UPDATE", 				OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "ARENA_OPPONENT_UPDATE", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_WORLD", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_BATTLEGROUND", 	OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_TARGET_CHANGED", 			OnEvent)
A.Listener:Add("ACTION_EVENT_BASE", "PLAYER_LOGIN", 					OnEvent)
