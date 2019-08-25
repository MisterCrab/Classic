local TMW 						= TMW
local A 						= Action

--local strlowerCache  			= TMW.strlowerCache

local _G, pairs, tostringall, tostring, tonumber, type, next, select, unpack, setmetatable, table, wipe = 
	  _G, pairs, tostringall, tostring, tonumber, type, next, select, unpack, setmetatable, table, wipe
	  
local concat 					= table.concat	  
local maxn						= table.maxn
	  
local Timer						= _G.C_Timer 
local GetMouseFocus				= _G.GetMouseFocus
local IsAddOnLoaded 			= _G.IsAddOnLoaded

local onEvent 					= _G.onEvent
local CreateFrame 				= _G.CreateFrame
local UnitGUID 					= _G.UnitGUID

-------------------------------------------------------------------------------
-- Listener
-------------------------------------------------------------------------------
local listeners 				= {}
local frame 					= CreateFrame("Frame", "ACTION_EVENT_LISTENER")
frame:SetScript("OnEvent", function(_, event, ...)
	if listeners[event] then 
		for k in pairs(listeners[event]) do		
			if k == "ACTION_EVENT_BASE" then 
				listeners[event][k](event, ...)
			else 
				listeners[event][k](...)
			end
		end
	end 
end)

A.Listener	 					= {
	Add 						= function(self, name, event, callback)
		if not listeners[event] then
			frame:RegisterEvent(event)
			listeners[event] = {}
		end
		if not listeners[event][name] then 
			listeners[event][name] = callback
		end 
	end,
	Remove						= function(self, name, event)
		if listeners[event] then
			listeners[event][name] = nil
		end
	end, 
	Trigger						= function(self, event, ...)
		onEvent(nil, event, ...)
	end,
}

-------------------------------------------------------------------------------
-- Cache 
-------------------------------------------------------------------------------
local OriginalGetSpellTexture	= TMW.GetSpellTexture
TMW.GetSpellTexture 			= setmetatable({}, {
	__mode = "kv",
	__index = function(t, i)
		local o = OriginalGetSpellTexture(i) 
		t[i] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local toStr = setmetatable({}, {
	-- toStr is basically a tostring cache for maximum efficiency
	__mode = "kv",
	__index = function(t, i)
		local o = tostring(i) 
		t[i or o] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local toNum = setmetatable({}, {
	-- toNum is basically a tonumber cache for maximum efficiency
	__mode = "kv",
	__index = function(t, i)
		local o = tonumber(i) 
		t[i or o] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local function strBuilder(s, j)
	-- Full builder (required memory, for deeph tables)
	-- String Concatenation
	local n = maxn(s)
	if n == 0 or (j and n <= j) then 
		return 0
	else 
		local t = {}
		for i = (j or 1), n do
			local type = type(s[i])
			if type == "string" or type == "number" then 
				t[#t + 1] = s[i]
			elseif type == "nil" then 
				t[#t + 1] = type
			elseif type == "table" then
				t[#t + 1] = strBuilder(s[i])
			else -- boolean, userdata	
				t[#t + 1] = toStr[s[i]]
			end 
		end 
		local text = concat(t)
		wipe(t)
		return text
	end 
end 

local bt = {}
local function strAltBuilder(s, j)
	local n = maxn(s)
	if n == 0 or (j and n <= j) then 
		return 0
	else 
		wipe(bt)
		
		for i = (j or 1), n do
			local type = type(s[i])
			if type == "string" or type == "number" or type == "table" then 
				bt[#bt + 1] = s[i]
			elseif type == "nil" then 
				bt[#bt + 1] = type
			else -- boolean, userdata	
				bt[#bt + 1] = toStr[s[i]]
			end 
		end 

		return concat(bt)
	end 
end 

local et = {}
local function strElemBuilder(replaceFirst, ...)
	-- @return string by vararg (...) as (arg, arg, arg, arg, arg)
	-- @usage replaceFirst must be nil if no need to repalce first index by custom 
	-- Elements as arguments (doesn't unpacking deeph table, instead it use identifier)
	-- String Concatenation
	local n = select("#", ...)
	if n == 0 then 
		return 
	end 
	
	wipe(et)
	
	for i = 1, n do 
		if i == 1 and replaceFirst then 
			et[#et + 1] = replaceFirst
		else 
			local type = type(select(i, ...))
			if type == "string" or type == "number" then
				et[#et + 1] = select(i, ...)
			elseif type == "nil" then 
				et[#et + 1] = type
			elseif type == "table" then 
				et[#et + 1] = strAltBuilder(select(i, ...), nil)
			else -- boolean, userdata	
				et[#et + 1] = toStr[select(i, ...)]
			end 
		end 
	end 

	return concat(et) 
end 

A.toStr 			= toStr
A.toNum 			= toNum
A.strBuilder		= strBuilder
A.strElemBuilder 	= strElemBuilder


local Cache = { 
	bufer = {},
	newVal = function(this, interval, keyArg, func, ...)
		if keyArg then 
			if not this.bufer[func][keyArg] then 
				this.bufer[func][keyArg] = {}
			end 		
			this.bufer[func][keyArg].t = TMW.time + (interval or ACTION_CONST_CACHE_DEFAULT_TIMER) + 0.001  -- Add small delay to make sure what it's not previous corroute              
			this.bufer[func][keyArg].v = { func(...) }
			return unpack(this.bufer[func][keyArg].v)
		else 
			this.bufer[func].t = TMW.time + (interval or ACTION_CONST_CACHE_DEFAULT_TIMER) + 0.001
			this.bufer[func].v = { func(...) }
			return unpack(this.bufer[func].v)
		end 		
	end,	
	-- Static without arguments or with non-change able arguments during cycle in func
	WrapStatic = function(this, func, interval)
		if ACTION_CONST_CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = setmetatable({}, { __mode == "kv" })
		end 	
		return function(...)  		
			if TMW.time > (this.bufer[func].t or 0) then			
				return this:newVal(interval, nil, func)
			else
				return unpack(this.bufer[func].v)
			end      
		end
	end,	
	-- Dynamic with unlimited arguments in func 
	WrapDynamic = function(this, func, interval)
		if ACTION_CONST_CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = setmetatable({}, { __mode == "kv" })
		end 	
		return function(...) 
			-- The reason of all this view look is memory hungry eating, this way use less memory 	
			local keyArg = strElemBuilder(nil, ...)	
			if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then			
				return this:newVal(interval, keyArg, func, ...)
			else
				return unpack(this.bufer[func][keyArg].v)
			end      
		end
	end,
}

function A.MakeFunctionCachedStatic(func, interval)
	return Cache:WrapStatic(func, interval)
end 

function A.MakeFunctionCachedDynamic(func, interval)
	return Cache:WrapDynamic(func, interval)
end 

-------------------------------------------------------------------------------
-- Timers 
-------------------------------------------------------------------------------
-- @usage /run Action.TimerSet("Print", 4, function() Action.Print("Hello") end)
function A.TimerSet(name, timer, callback)
	-- Sets timer if it's not running
	if not A.Data.T[name] then 
		A.Data.T[name] = { 
			obj = Timer.NewTimer(timer, function() 
				if callback and type(callback) == "function" then 
					callback()
				end 
				A.TimerDestroy(name)
			end), 
			start = TMW.time,
		}
	end 
end 

function A.TimerSetRefreshAble(name, timer, callback)
	-- Sets timer, if it's running then reset and set again
	A.TimerDestroy(name)
	A.Data.T[name] = { 
		obj = Timer.NewTimer(timer, function() 
			if callback and type(callback) == "function" then 
				callback()
			end 
			A.TimerDestroy(name)
		end), 
		start = TMW.time,
	}
end 

function A.TimerGetTime(name)
	-- @return number 	
	return A.Data.T[name] and TMW.time - A.Data.T[name].start or 0
end 

function A.TimerDestroy(name)
	-- Cancels timer
	if A.Data.T[name] then 
		A.Data.T[name].obj:Cancel()
		A.Data.T[name] = nil 
	end 
end

-------------------------------------------------------------------------------
-- Bit Library
-------------------------------------------------------------------------------
A.Bit				  			= {}
local bitband					= bit.band

function A.Bit.isEnemy(Flags)
	return bitband(Flags, ACTION_CONST_CL_REACTION_HOSTILE) == ACTION_CONST_CL_REACTION_HOSTILE or bitband(Flags, ACTION_CONST_CL_REACTION_NEUTRAL) == ACTION_CONST_CL_REACTION_NEUTRAL
end 

function A.Bit.isPlayer(Flags)
	return bitband(Flags, ACTION_CONST_CL_TYPE_PLAYER) == ACTION_CONST_CL_TYPE_PLAYER or bitband(Flags, ACTION_CONST_CL_CONTROL_PLAYER) == ACTION_CONST_CL_CONTROL_PLAYER
end

-------------------------------------------------------------------------------
-- Utils
-------------------------------------------------------------------------------
local Utils 					= {}
-- Compare two values
local CompareThisTable = {
	[">"] 	= function(A, B) return A > B end,
	["<"] 	= function(A, B) return A < B end,
	[">="] 	= function(A, B) return A >= B end,
	["<="] 	= function(A, B) return A <= B end,
	["=="] 	= function(A, B) return A == B end,
	["min"] = function(A, B) return A < B end,
	["max"] = function(A, B) return A > B end,
}

function Utils.CompareThis(Operator, A, B)
	return CompareThisTable[Operator](A, B)
end

function Utils.CastTargetIf(Object, Range, TargetIfMode, TargetIfCondition, Condition)
	local TargetCondition = (not Condition or (Condition and Condition(Target)))
	if not A.GetToggle(2, "AoE") then
		return TargetCondition
	else 
		local BestUnit, BestConditionValue = nil, nil
		local nameplates = A.MultiUnits:GetActiveUnitPlates()
		if nameplates then 
			for CycleUnit in pairs(nameplates) do 
				if (not Range or A.Unit(CycleUnit):GetRange() <= Range) and ((Condition and Condition(CycleUnit)) or not Condition) and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then 
					BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit)
				end 
			end 
			if BestUnit and UnitGUID(BestUnit) == UnitGUID("target") or (TargetCondition and (BestConditionValue == TargetIfCondition(Target))) then 
				return true 
			end 
		end 
	end 
end

A.Utils 						= Utils

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
function A.MouseHasFrame()
    local focus = A.Unit("mouseover"):IsExists() and GetMouseFocus()
    if focus then
        local frame = not focus:IsForbidden() and focus:GetName()
        return not frame or (frame and frame ~= "WorldFrame")
    end
    return false
end
A.MouseHasFrame = A.MakeFunctionCachedStatic(A.MouseHasFrame)

function round(num, numDecimalPlaces)
    return toNum[string.format("%." .. (numDecimalPlaces or 0) .. "f", num)]
end

function tableexist(self)  
    return (type(self) == "table" and next(self)) or false
end

-------------------------------------------------------------------------------
-- Errors
-------------------------------------------------------------------------------
A.Listener:Add("ACTION_EVENT_TOOLS", "PLAYER_LOGIN", function()
	local listDisable, toDisable = { "ButtonFacade", "Masque", "Masque_ElvUIesque", "GSE", "Gnome Sequencer Enhanced", "Gnome Sequencer", "AddOnSkins" }
	for i = 1, #listDisable do    
		if IsAddOnLoaded(listDisable[i]) then
			toDisable = (toDisable or "\n") .. v .. "\n"
		end
	end

	if toDisable then 
		message("Disable next addons:" .. toDisable)
	end

	A.Listener:Remove("ACTION_EVENT_TOOLS", "PLAYER_LOGIN")
end)