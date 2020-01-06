-------------------------------------------------------------------------------
--[[ 
Global nil-able variables:
A.Zone				(@string)		"none", "pvp", "arena", "party", "raid", "scenario"
A.ZoneID			(@number) 		wow.gamepedia.com/UiMapID/Classic
A.IsInInstance		(@boolean)
A.TimeStampZone 	(@number)
A.TimeStampDuel 	(@number)
A.IsInPvP 			(@boolean)
A.IsInDuel			(@boolean)

Global tables:
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------

local TMW 									= TMW
local A   									= Action
local ThreatLib								= LibStub:GetLibrary("LibThreatClassic2") -- Classic only
local Listener								= A.Listener	

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit 

Listener:Add("ACTION_EVENT_BASE", "ADDON_LOADED", function(event, addonName) -- "ACTION_EVENT_BASE" fires with arg1 event!
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit = A.Unit 
		Listener:Remove("ACTION_EVENT_BASE", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------

local InstanceInfo							= {}
local TeamCache								= { 
	threatData								= {},
	Friendly 								= {
		Size								= 1,
		MaxSize								= 1,
		UNITs								= {},
		GUIDs								= {},
		IndexToPLAYERs						= {},
		IndexToPETs							= {},
		-- [[ Classic only ]]
		hasShaman							= false,
	},
	Enemy 									= {
		Size 								= 0,
		MaxSize								= 0,
		UNITs								= {},
		GUIDs 								= {},
		IndexToPLAYERs						= {},
		IndexToPETs							= {},
		-- [[ Classic only ]]
		hasShaman 							= false,
	},
}

local TeamCacheFriendly 					= TeamCache.Friendly
local TeamCacheFriendlyUNITs				= TeamCacheFriendly.UNITs -- unitID to unitGUID
local TeamCacheFriendlyGUIDs				= TeamCacheFriendly.GUIDs -- unitGUID to unitID
local TeamCacheFriendlyIndexToPLAYERs		= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs			= TeamCacheFriendly.IndexToPETs
local TeamCacheEnemy 						= TeamCache.Enemy
local TeamCacheEnemyUNITs					= TeamCacheEnemy.UNITs -- unitID to unitGUID
local TeamCacheEnemyGUIDs					= TeamCacheEnemy.GUIDs -- unitGUID to unitID
local TeamCacheEnemyIndexToPLAYERs			= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local TeamCachethreatData					= TeamCache.threatData

local _G, pairs, type, math 				= 
	  _G, pairs, type, math

local huge 									= math.huge
local wipe									= _G.wipe 
local C_Map									= _G.C_Map 

local IsInRaid, IsInGroup, IsInInstance, RequestBattlefieldScoreData = 
	  IsInRaid, IsInGroup, IsInInstance, RequestBattlefieldScoreData

local UnitInBattleground, UnitExists, UnitIsFriend, UnitGUID = 
	  UnitInBattleground, UnitExists, UnitIsFriend, UnitGUID

local GetInstanceInfo, GetNumBattlefieldScores, GetNumGroupMembers =  
	  GetInstanceInfo, GetNumBattlefieldScores, GetNumGroupMembers    
	
local GetBestMapForUnit 					= C_Map.GetBestMapForUnit	

local playerTarget							= "" -- Classic ThreatData
local player 								= "player"
local pet									= "pet"
local target 								= "target"
local targettarget							= "targettarget"
	  
-------------------------------------------------------------------------------
-- Instance, Zone, Mode, Duel, TeamCache
-------------------------------------------------------------------------------	  
A.TeamCache 	= TeamCache
A.InstanceInfo 	= InstanceInfo

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
    UnitInBattleground(player) or 
    ( A_Unit(target):IsPlayer() and (A_Unit(target):IsEnemy() or (A_Unit(targettarget):IsPlayer() and A_Unit(targettarget):IsEnemy())) )
end

local LastEvent, counter
local function OnEvent(event, ...)    
	if event == "PLAYER_TARGET_CHANGED" then 
		playerTarget = UnitExists(target) and (UnitIsFriend(player, target) and targettarget or target) or ""
	end 
	
    -- Don't call it several times
    if TMW.time == LastEvent and TeamCacheFriendlyUNITs.player then 
        return 
    end 
    LastEvent = TMW.time
	
	-- Update IsInInstance, Zone
    A.IsInInstance, A.Zone = IsInInstance()
	if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LOGIN" then 
		A.ZoneID = GetBestMapForUnit(player) or 0
		
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		if name then 
			InstanceInfo.Name 			= name 
			InstanceInfo.Type 			= instanceType
			InstanceInfo.difficultyID 	= difficultyID
			InstanceInfo.ID 			= instanceID
			InstanceInfo.GroupSize		= instanceGroupSize
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
			local oldMode = A.IsInPvP
			A.IsInPvP = A:CheckInPvP()  
			if oldMode ~= A.IsInPvP then 
				TMW:Fire("TMW_ACTION_MODE_CHANGED")
			end 
		end  
	end
	
	-- Update Units 
	if event == "UPDATE_INSTANCE_INFO" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then 
		-- Wipe Friendly 
		TeamCacheFriendly.hasShaman = false 
		for _, v in pairs(TeamCacheFriendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy
		TeamCacheEnemy.hasShaman = false 
		for _, v in pairs(TeamCacheEnemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
				
		-- Enemy
		if A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			TeamCacheEnemy.Size = GetNumBattlefieldScores()    			
			TeamCacheEnemy.Type = "arena"	
			TeamCacheEnemy.MaxSize = 40
		else
			TeamCacheEnemy.Size = 0		
			TeamCacheEnemy.Type = nil 
			TeamCacheEnemy.MaxSize = 0
		end
				
		if TeamCacheEnemy.Size > 0 and TeamCacheEnemy.Type then    
			counter = 0
			for i = 1, huge do 
				local arena = TeamCacheEnemy.Type .. i
				local guid 	= UnitGUID(arena)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheEnemyUNITs[arena] 			= guid
					TeamCacheEnemyGUIDs[guid] 			= arena					
					TeamCacheEnemyIndexToPLAYERs[i] 	= arena					
					if not TeamCacheEnemy.hasShaman and A_Unit(arena):Class() == "SHAMAN" then 
						TeamCacheEnemy.hasShaman = true 
					end 
					
					local arenapet 						= TeamCacheEnemy.Type .. pet .. i
					local arenapetguid 					= UnitGUID(arenapet)
					if arenapetguid then 
						TeamCacheEnemyUNITs[arenapet] 		= arenapetguid
						TeamCacheEnemyGUIDs[arenapetguid] 	= arenapet					
						TeamCacheEnemyIndexToPETs[i] 		= arenapet	
					end 
				end 
				
				if counter >= TeamCacheEnemy.Size or i >= TeamCacheEnemy.MaxSize then 
					if counter >= TeamCacheEnemy.Size then 
						TeamCacheEnemy.MaxSize = counter
					end 
					break 
				end 
			end   
		end          
		
		-- Friendly
		TeamCacheFriendly.Size = GetNumGroupMembers()
		if IsInRaid() then
			TeamCacheFriendly.Type = "raid"
			TeamCacheFriendly.MaxSize = 40
		elseif IsInGroup() then
			TeamCacheFriendly.Type = "party"   
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size - 1
		else 
			TeamCacheFriendly.Type = nil 
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size
		end    
		
		local pGUID = UnitGUID(player)
		TeamCacheFriendlyUNITs[player] 	= pGUID
		TeamCacheFriendlyGUIDs[pGUID] 	= player 		
		
		if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then 
			counter = 0
			for i = 1, huge do 
				local member = TeamCacheFriendly.Type .. i
				local guid 	 = UnitGUID(member)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheFriendlyUNITs[member] 		= guid
					TeamCacheFriendlyGUIDs[guid] 		= member
					TeamCacheFriendlyIndexToPLAYERs[i] 	= member		 					
					if not TeamCacheFriendly.hasShaman and A_Unit(member):Class() == "SHAMAN" and A_Unit(member):InParty() then -- Shaman's totems in Classic works only on party group
						TeamCacheFriendly.hasShaman = true 
					end 
					
					local memberpet 					= TeamCacheFriendly.Type .. pet .. i
					local memberpetguid 				= UnitGUID(memberpet)
					if memberpetguid then 
						TeamCacheFriendlyUNITs[memberpet] 		= memberpetguid
						TeamCacheFriendlyGUIDs[memberpetguid] 	= memberpet					
						TeamCacheFriendlyIndexToPETs[i] 		= memberpet	
					end 
				end 

				if counter >= TeamCacheFriendly.Size or i >= TeamCacheFriendly.MaxSize then 
					if counter >= TeamCacheFriendly.Size then 
						TeamCacheFriendly.MaxSize = counter
					end 
					break 
				end 	
			end 
		end		
	end 
	
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "UPDATE_INSTANCE_INFO" then 
		TMW:Fire("TMW_ACTION_ENTERING", event) 			-- callback is used in PetLibrary.lua, HealingEngine.lua, Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
	end 
	
	if event ~= "PLAYER_TARGET_CHANGED" and event ~= "DUEL_FINISHED" and event ~= "DUEL_REQUESTED" then 
		TMW:Fire("TMW_ACTION_GROUP_UPDATE", event) 		-- callback is used in Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
	end 
	
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then 
		TMW:Fire("TMW_ACTION_THREATLIB_UPDATE") 		-- callback is used in Base.lua to refresh and prepare unitGUID for deprecated official API on UnitThreatSituation and UnitDetailedThreatSituation
	end 
end 

Listener:Add("ACTION_EVENT_BASE", "DUEL_FINISHED", 					OnEvent)
Listener:Add("ACTION_EVENT_BASE", "DUEL_REQUESTED", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED", 					OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_INDOORS", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_NEW_AREA", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "UPDATE_INSTANCE_INFO", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "GROUP_ROSTER_UPDATE", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_WORLD", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_BATTLEGROUND", 	OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_TARGET_CHANGED", 			OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_LOGIN", 					OnEvent)

-------------------------------------------------------------------------------
-- Threat Library 
-------------------------------------------------------------------------------
--local UnitThreatSituation			= function(unit, mob) return ThreatLib:UnitThreatSituation(unit, mob) end 
local UnitDetailedThreatSituation	= function(unit, mob) return ThreatLib:UnitDetailedThreatSituation(unit, mob) end 

local function UpdateThreatData(unit)
	local isTanking, status, scaledPercent, rawThreatPercent, threatValue, GUID = UnitDetailedThreatSituation(unit, playerTarget) -- Lib modified to return by last argument unitGUID!
	if threatValue and threatValue < 0 then
		threatValue = threatValue + 410065408
	end
	
	-- In case if new lib version overwrite this version 
	-- DONT TOUCH THIS!	
	if not GUID then 
		GUID = TeamCacheFriendlyUNITs[unit] or UnitGUID(unit)
	end 	
	
	TeamCachethreatData[GUID] = {
		unit			= unit,
		isTanking		= isTanking,
		status			= status or 0,
		scaledPercent	= scaledPercent or 0,
		threatValue		= threatValue or 0,
	}
end

local function CheckStatus()
	if UnitExists(playerTarget) then 
		-- wipe
		wipe(TeamCachethreatData)
		-- group
		if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then
			local unit = TeamCacheFriendly.Type
			for i = 1, TeamCacheFriendly.MaxSize do
				if TeamCacheFriendlyIndexToPLAYERs[i] then 
					UpdateThreatData(TeamCacheFriendlyIndexToPLAYERs[i])
					
					if TeamCacheFriendlyIndexToPETs[i] then 
						UpdateThreatData(TeamCacheFriendlyIndexToPETs[i])
					end 
				end 
			end
			-- party excludes player/pet
			if TeamCacheFriendly.Type ~= "raid" then
				UpdateThreatData(player)
				if UnitExists(pet) then 
					UpdateThreatData(pet)
				end 
			end
		-- solo
		else			
			UpdateThreatData(player)
			if UnitExists(pet) then 
				UpdateThreatData(pet)
			end 
		end
	end
end

local function OnLoginThreatLib()
	Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_REGEN_DISABLED", 		CheckStatus)
	Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_REGEN_ENABLED", 		CheckStatus)
	TMW:RegisterCallback("TMW_ACTION_THREATLIB_UPDATE",						CheckStatus)
	ThreatLib:RegisterCallback("Activate", 									CheckStatus)
	ThreatLib:RegisterCallback("Deactivate", 								CheckStatus)
	ThreatLib:RegisterCallback("ThreatUpdated", 							CheckStatus)
	ThreatLib:RequestActiveOnSolo(true)  	  	
	Listener:Remove("ACTION_EVENT_THREAT_LIB", "PLAYER_LOGIN")
end 

Listener:Add("ACTION_EVENT_THREAT_LIB", "PLAYER_LOGIN", 					OnLoginThreatLib)