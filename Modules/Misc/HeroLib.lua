HeroRotation					= HeroRotation or {}
local Cache 					= HeroCache
local HL 						= HeroLib
local HR 						= HeroRotation 

if not HL then 
	return 
end 

local Cache, Utils 				= HeroCache, HL.Utils
local Unit 						= HL.Unit
local Player 					= Unit.Player
local Target 					= Unit.Target
local Spell 					= HL.Spell
local Item 						= HL.Item
-- Lua
local mathmin 					= math.min
local stringlower	 			= string.lower
local strsplit 					= strsplit

local TMW 						= TMW 
local GetSpellTexture			= TMW.GetSpellTexture
local A 						= Action
local MultiUnits				= A.MultiUnits
local UnitGUID					= UnitGUID
local pairs, loadstring, select =		
	  pairs, loadstring, select
 
-------------------------------------------------------------------------------
-- Core 
-------------------------------------------------------------------------------	  
function A:HeroCreate() 
	-- @return table, table or nil 
	-- Convert from Action to Hero Spells and Items
	if HL then 
		local S, I = {}, {}
		for k, v in pairs(self) do 
			if v.Type:match("Spell") or v.SubType == "HeartOfAzeroth" then 
				S[k] = Spell(v.ID)
				-- Push identificator for 'The Action'
				S[k].KEY = k
			end 
			
			if v.Type:match("Item") or v.Type == "Potion" or v.Type == "Trinket" then 
				I[k] = Item(v.ID)
				-- Push identificator for 'The Action'
				I[k].KEY = k
			end 
		end 
		return S, I
	end 	 
end 

local IsHooked = {}
function A.HeroSetHook(objects, metas)
	-- @usage
	--[[
		A.HeroSetHook({
			S.Brew,
			S.Guard,
			I.SomeTrinket,
		}, 
		{
			[3] = "TellMeWhen_Group4_Icon3",
			[4] = "TellMeWhen_Group4_Icon4",
		})
	]]
	-- Sets hook on call HR.Cast and HR.CastSuggested functions with relative frame for texture show 
	for i = 1, #objects do 
		IsHooked[objects[i].KEY] = metas
	end 
end 

function A.HeroSetHookAllTable(tabl, metas)
	-- @usage 
	--[[
		A.HeroSetHookAllTable(S, {
			[3] = "TellMeWhen_Group4_Icon3",
			[4] = "TellMeWhen_Group4_Icon4",
		})
		A.HeroSetHookAllTable(I, {
			[3] = "TellMeWhen_Group4_Icon3",
			[4] = "TellMeWhen_Group4_Icon4",
		})
	]]
	-- Does same as A.HeroSetHook but it takes all from direct table
	for _, v in pairs(tabl) do 
		IsHooked[v.KEY] = metas
	end 
end 

-------------------------------------------------------------------------------
-- Remap 
-------------------------------------------------------------------------------	  
local Dummy = function() return true end 
local Null	= function() end 
local ObjKey = function(Object)
	if A.IsInitialized and Object and Object.KEY and IsHooked[Object.KEY] then 
		for meta, frame in pairs(IsHooked[Object.KEY]) do
			if A[A.PlayerSpec] and A[A.PlayerSpec][meta] and A[A.PlayerSpec][Object.KEY] then 
				A[A.PlayerSpec][Object.KEY]:Show(loadstring("return " .. frame)())
				-- /run local a = assert(loadstring("return TellMeWhen_Group4_Icon4"))(); print(a)
				-- /dump loadstring("return TellMeWhen_Group4_Icon4")()
			end 
		end 
	end 
	
	return true 
end 

local CachedCast = HR.Cast or Dummy
function HR.Cast(Object, OffGCD, DisplayStyle)
	if CachedCast(Object, OffGCD, DisplayStyle) then 
		ObjKey(Object)
		return true 
	end 
end 

local CachedCastQueue = HR.CastQueue or Dummy 
function HR.CastQueue(...)
	CachedCastQueue(...)
	if A.IsInitialized then 
		local args = { ... }
		for i = 1, #args do 
			if args[i].KEY and IsHooked[args[i].KEY] then 			
				if A[A.PlayerSpec] and A[A.PlayerSpec][args[i].KEY] and not A[A.PlayerSpec][args[i].KEY]:IsQueued() then 
					A[A.PlayerSpec][args[i].KEY]:SetQueue({ Silence = true, Priority = 1 })
				end 
			end 
		end 
	end 
	return "Should Return"
end

local CachedCastCycle = HR.CastCycle or Dummy
function HR.CastCycle(Object, Range, Condition)
	if CachedCastCycle(Object, Range, Condition) then 
		if Condition(Target) then
			return HR.Cast(Object)
		end
		if HR.AoEON() then
			local BestUnit = nil
			local TargetGUID = UnitGUID("target")
			for _, CycleUnit in pairs(MultiUnits:GetActiveUnitPlates() or {}) do
				if (not range or A.Unit(CycleUnit):GetRange() <= range) and UnitGUID(CycleUnit) ~= TargetGUID and Condition(CycleUnit) then
					HR.CastLeftNameplate(CycleUnit, Object)
					return true 
				end
			end
		end				
	end 
end 

local CachedCastTargetIf = HR.CastTargetIf or Dummy
function HR.CastTargetIf(Object, Range, TargetIfMode, TargetIfCondition, Condition)
	local TargetCondition = (not Condition or (Condition and Condition(Target)))
	if not HR.AoEON() and TargetCondition then
		return HR.Cast(Object)
	end	
	if HR.AoEON() then
		local BestUnit, BestConditionValue = nil, nil
		for _, CycleUnit in pairs(MultiUnits:GetActiveUnitPlates() or {}) do
			if (not range or A.Unit(CycleUnit):GetRange() <= range) and ((Condition and Condition(CycleUnit)) or not Condition) and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then
				BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit)
			end
		end
		if BestUnit then
			if (BestUnit:GUID() == Target:GUID()) or (TargetCondition and (BestConditionValue == TargetIfCondition(Target))) then
				return HR.Cast(Object)
			else
				HR.CastLeftNameplate(BestUnit, Object)
				return ObjKey(Object)
			end
		end
	end
end

HR.Print 				= HR.Print or A.Print 
HR.SetAPL 				= HR.SetAPL or Dummy
HR.CastLeft 			= HR.CastLeft or Null 
HR.CastLeftCommon 		= HR.CastLeftCommon or Null 
HR.CastLeftNameplate	= HR.CastLeftNameplate or Dummy 
HR.CastAnnotated		= HR.CastAnnotated or Null 
HR.Locked				= HR.Locked or Null 
HR.ON					= HR.ON or Null
HR.CmdHandler			= HR.CmdHandler or Null
 
HR.GetTexture 			= HR.GetTexture or function(Object) 
	return GetSpellTexture(Object.SpellID)
end 

local CachedCastSuggested = HR.CastSuggested or Dummy
function HR.CastSuggested(Object)
	if CachedCastSuggested(Object) then 
		ObjKey(Object)
		return true 
	end 
end 

-- Get if the CDs are enabled.
function HR.CDsON(unit)
	if A.IsInitialized then 
		local unit = unit or "target"
		return A.BurstIsON(unit)
	end 
	
	return HeroRotationCharDB and HeroRotationCharDB.Toggles[1]
end

-- Get if the AoE is enabled.
function HR.AoEON()
	if A.IsInitialized then 
		return A.GetToggle(2, "AoE")
	end 
	
	return HeroRotationCharDB and HeroRotationCharDB.Toggles[2]
end

if HL then 
	local Spell = HL.Spell
	local Item = HL.Item
	
	-- Connect it with 'The Action' by SetBlocker, SetQueue and custom LUA (+ toggles for Potion, Trinkets, HeartOfAzeroth)
	local function ActionAPI(Object)
		return not A.IsInitialized or (A[A.PlayerSpec] and A[A.PlayerSpec][Object.KEY] and A[A.PlayerSpec][Object.KEY]:IsReady())
	end 
	
	-- Spells 
	local CachedSpellIsCastable = Spell.IsCastable
	function Spell:IsCastable(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsCastable(self, Range, AoESpell, ThisUnit)
	end

	local CachedSpellIsCastableP = Spell.IsCastableP
	function Spell:IsCastableP(Range, AoESpell, ThisUnit, BypassRecovery, Offset)
		return ActionAPI(self) and CachedSpellIsCastableP(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
	end
	
	local CachedSpellIsReady = Spell.IsReady
	function Spell:IsReady(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReady(self, Range, AoESpell, ThisUnit)
	end
	
	local CachedSpellIsReadyP = Spell.IsReadyP
	function Spell:IsReadyP(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReadyP(self, Range, AoESpell, ThisUnit)
	end
	
	-- Items 
	local CachedItemIsReady = Item.IsReady
	function Item:IsReady()
		return ActionAPI(self) and CachedItemIsReady(self)
	end
end 

local Commons = {}
if not HR.Commons then 
	HR.Commons = {}	
	HR.Commons.Everyone = Commons
	
	-- Put EnemiesCount to 1 if we have AoEON or are targetting an AoE insensible unit
	local AoEInsensibleUnit = {
		--- Legion
		----- Dungeons (7.0 Patch) -----
		--- Mythic+ Affixes
		-- Fel Explosives (7.2 Patch)
		[120651] = true,
	}
	function Commons.AoEToggleEnemiesUpdate ()
		if not HR.AoEON() or AoEInsensibleUnit[Target:NPCID()] then
			for Key, Value in pairs(Cache.EnemiesCount) do
				Cache.EnemiesCount[Key] = math.min(1, Cache.EnemiesCount[Key]);
			end
		end
	end	
else 
	Commons = HR.Commons.Everyone
end 

local CachedTargetIsValid 	= Commons.TargetIsValid or Dummy 
function Commons.TargetIsValid()
	return CachedTargetIsValid() and (not A.IsInitialized or A.UnitIsEnemy("target"))
end 

Commons.UnitIsCycleValid 	= Commons.UnitIsCycleValid or Dummy
Commons.CanDoTUnit		 	= Commons.CanDoTUnit or Dummy 

local CachedInterrupt 	 	= Commons.Interrupt
function Commons.Interrupt(Range, Spell, Setting, StunSpells) 
	-- Note: HeroRotations need little bit tweak with it by adding this func with "if Commons.Interrupt(args) then return end" 
	if not A.IsInitialized then 
		return CachedInterrupt(Range, Spell, Setting, StunSpells) 
	else 	
		local Kick, CC = A.InterruptIsValid("target", "TargetMouseover")  
		if ((not StunSpells and Kick) or (StunSpells and CC)) and (not Range or A.Unit("target"):GetRange() <= Range) and (not Spell or (Spell.KEY and IsHooked[Spell.KEY] and A[A.PlayerSpec][Spell.KEY] and A[A.PlayerSpec][Spell.KEY]:IsReady("target"))) and A.Unit("target"):CanInterrupt(true, {"KickImun", "TotalImun"}) then 
			return HR.Cast(Spell)
		end 
	end
end 