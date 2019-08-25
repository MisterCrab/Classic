local TMW 							= TMW 
local A	 							= Action
local DBM 							= DBM

local strlowerCache  				= TMW.strlowerCache
--local toStr 						= A.toStr
local toNum 						= A.toNum

local pairs, type, hooksecurefunc 	= 
	  pairs, type, hooksecurefunc

local UnitName 						= UnitName

-------------------------------------------------------------------------------
-- Locals 
-------------------------------------------------------------------------------
local DBM_GetTimeRemaining, DBM_GetTimeRemaining, DBM_IsBossEngaged
if DBM then 
	local Timers, TimersBySpellID = {}, {}
	
	DBM:RegisterCallback("DBM_TimerStart", function(_, id, text, timerRaw, icon, timerType, spellid, colorId)
		-- Older versions of DBM return this value as a string:
		local duration
		if type(timerRaw) == "string" then
			duration = toNum[timerRaw:match("%d+")]
		else
			duration = timerRaw
		end
		
		Timers[id] = {text = strlowerCache[text], start = TMW.time, duration = duration}   
		if spellid then 
			TimersBySpellID[spellid] = Timers[id]
		end 
	end)
	DBM:RegisterCallback("DBM_TimerStop", function(_, id) Timers[id] = nil end)


	function DBM_GetTimeRemaining(text)        
		for id, t in pairs(Timers) do            
			if t.text:match(text) then
				local expirationTime = t.start + t.duration
				local remaining = (expirationTime) - TMW.time
				if remaining < 0 then 
					remaining = 0 
				end
				
				return remaining, expirationTime
			end
		end
		
		return 0, 0
	end

	function DBM_GetTimeRemainingBySpellID(spellID)
		if TimersBySpellID[spellID] then 
			local expirationTime = TimersBySpellID[spellID].start + TimersBySpellID[spellID].duration
			local remaining = (expirationTime) - TMW.time
			if remaining < 0 then 
				remaining = 0
			end
			
			return remaining, expirationTime
		end 
		
		return 0, 0
	end 

	local EngagedBosses = {}
	hooksecurefunc(DBM, "StartCombat", function(DBM, mod, delay, event)
		if event ~= "TIMER_RECOVERY" then
			EngagedBosses[mod] = true            
		end
	end)
	hooksecurefunc(DBM, "EndCombat", function(DBM, mod)
		EngagedBosses[mod] = nil            
	end)
	
	
	function DBM_IsBossEngaged(bossName)
		for mod in pairs(EngagedBosses) do			
			if strlowerCache[mod.localization.general.name]:match(bossName) or strlowerCache[mod.id]:match(bossName) then
				return mod.inCombat and true or false
			end
		end
		
		return false
	end	
else
	local function Null() return 0, 0 end 
	DBM_GetTimeRemaining, DBM_GetTimeRemainingBySpellID = Null, Null
	function DBM_IsBossEngaged()
		return false 
	end 
end

-------------------------------------------------------------------------------
-- API: DBM 
-------------------------------------------------------------------------------
-- Note: /dbm pull <5>
-- Note: /dbm timer <10> <Name>
function A.DBM_PullTimer()
	-- @return number: remaining, expirationTime
    local name = DBM and strlowerCache[DBM_CORE_TIMER_PULL] or nil   
    return DBM_GetTimeRemaining(name)
end 

function A.DBM_GetTimer(name)    
	-- @arg name can be number (spellID) or string (localizated name of the timer)
	-- @return number: remaining, expirationTime
    if not A.IsInitialized or not A.GetToggle(1, "DBM") then
        return 0, 0
    end
    
    if type(name) == "string" then 
		local timername = strlowerCache[name]
		return DBM_GetTimeRemaining(timername)
	else
		return DBM_GetTimeRemainingBySpellID(name)
	end 
end 

function A.DBM_IsEngage()
	-- @return number: remaining, expirationTime
    if not A.IsInitialized or not A.GetToggle(1, "DBM") then
        return 0, 0
    end
    -- Not tested  
    local BossName = UnitName("boss1")
    local name = BossName and format("%q", strlowerCache[BossName:gsub("%%", "%%%%")])
    return name and DBM_IsBossEngaged(name) or false
end 

-------------------------------------------------------------------------------
-- API: Shared 
-------------------------------------------------------------------------------
function A.BossMods_Pulling()
	return A.GetToggle(1, "DBM") and A.DBM_PullTimer() or 0
end 