-------------------------------------------------------------------------------
-- TellMeWhen Utils
-------------------------------------------------------------------------------
local TMW 					= TMW
local CNDT 					= TMW.CNDT
local Env 					= CNDT.Env
local strlowerCache  		= TMW.strlowerCache

local A   					= Action
local toStr 				= A.toStr
local toNum 				= A.toNum

local _G, assert, select, type, next, ipairs, wipe, hooksecurefunc, message, huge	= 
	  _G, assert, select, type, next, ipairs, wipe, hooksecurefunc, message, math.huge
	  
local CreateFrame, GetCVar, SetCVar =
	  CreateFrame, GetCVar, SetCVar

local GetPhysicalScreenSize = GetPhysicalScreenSize
	  
local GetSpellTexture, GetSpellInfo, CombatLogGetCurrentEventInfo =	
  TMW.GetSpellTexture, GetSpellInfo, CombatLogGetCurrentEventInfo	  

local UnitName, UnitGUID, UnitIsUnit =
	  UnitName, UnitGUID, UnitIsUnit
	  
local RANKCOLOR 			= A.Data.RANKCOLOR	
-- IconType: TheAction - UnitCasting  
local LibClassicCasterino 	= LibStub("LibClassicCasterino")

-------------------------------------------------------------------------------
-- Env.LastPlayerCast
-------------------------------------------------------------------------------
-- Note: This code is modified for Action Core 
do
    local module = CNDT:GetModule("LASTCAST", true)
    if not module then
        module = CNDT:NewModule("LASTCAST", "AceEvent-3.0")
        
        local pGUID = UnitGUID("player")
        assert(pGUID, "pGUID was null when func string was generated!")
        
        module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",
            function()
                local _, e, _, sourceGuid, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
                if e == "SPELL_CAST_SUCCESS" and sourceGuid == pGUID then
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					A.LastPlayerCastID		= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)    
        
        module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",
            function(_, unit, _, spellID)
                if unit == "player" then
					local spellName			= A.GetSpellInfo and A.GetSpellInfo(spellID) or GetSpellInfo(spellID)
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					A.LastPlayerCastID		= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)  
    end
end

-------------------------------------------------------------------------------
-- DogTags
-------------------------------------------------------------------------------
local DogTag = LibStub("LibDogTag-3.0", true)
TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", 		DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_BURST_CHANGED",		DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_CHANGED", 			DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_RANK_DISPLAY_CHANGED", DogTag.FireEvent, DogTag)
-- Taste's 
TMW:RegisterCallback("TMW_ACTION_CD_MODE_CHANGED", 		DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_MODE_CHANGED", 	DogTag.FireEvent, DogTag)

local function removeLastChar(text)
	return text:sub(1, -2)
end

if DogTag then
	-- Changes displayed mode on rotation frame
    DogTag:AddTag("TMW", "ActionMode", {
        code = function()
            return A.IsInPvP and "PvP" or "PvE"
        end,
        ret = "string",
        doc = "Displays Rotation Mode",
		example = '[ActionMode] => "PvE"',
        events = "TMW_ACTION_MODE_CHANGED",
        category = "Action",
    })
	-- Changes displayed burst on rotation frame 
	DogTag:AddTag("TMW", "ActionBurst", {
        code = function()
			if A.IsInitialized then 
				local Toggle = A.GetToggle(1, "Burst") or ""
				Toggle = Toggle and Toggle:upper()
				return Toggle == "EVERYTHING" and ("|c" .. A.Data.C["GREEN"] .. "EVERY|r") or Toggle == "OFF" and ("|c" .. removeLastChar(A.Data.C["RED"]) .. Toggle .. "|r") or ("|c" .. A.Data.C["GREEN"] .. Toggle .. "|r")
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation Burst",
		example = '[ActionBurst] => "Auto, Off, Everything"',
        events = "TMW_ACTION_BURST_CHANGED",
        category = "Action",
    })
	-- Changes displayed aoe on rotation frame 
	DogTag:AddTag("TMW", "ActionAoE", {
        code = function()
			if A.IsInitialized then 
				return A.GetToggle(2, "AoE") and ("|c" .. A.Data.C["GREEN"] .. "AoE|r") or "|c" .. removeLastChar(A.Data.C["RED"]) .. "AoE|r"
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation AoE",
		example = '[ActionAoE] => "AoE (green or red)"',
        events = "TMW_ACTION_AOE_CHANGED",
        category = "Action",
    })
	-- Changes displayed rank of spell on rotation frame 
	DogTag:AddTag("TMW", "ActionRank", {
        code = function()
			return A.IsInitialized and RankSingle.isColored or "" 
        end,
        ret = "string",
        doc = "Displays Rotation SpellRank in use on the frame",
		example = '[ActionRank] => "1"',
        events = "TMW_ACTION_RANK_DISPLAY_CHANGED",
        category = "Action",
    })
	
	-- Taste's 
    DogTag:AddTag("TMW", "ActionModeCD", {
        code = function()            
			if A.IsInitialized and A.GetToggle(1, "Burst") ~= "Off" then
			    return "|cff00ff00CD|r"
			else 
				return "|cFFFF0000CD|r"
			end
        end,
        ret = "string",
        doc = "Displays CDs Mode",
		example = '[ActionModeCD] => "CDs ON"',
        events = "TMW_ACTION_CD_MODE_CHANGED",
        category = "ActionCDs",
    })
	DogTag:AddTag("TMW", "ActionModeAoE", {
        code = function()            
			if A.IsInitialized and A.GetToggle(1, "AoE") then
			    return "|cff00ff00AoE|r"
			else 
				return "|cFFFF0000AoE|r"
			end
        end,
        ret = "string",
        doc = "Displays AoE Mode",
		example = '[ActionModeAoE] => "AoE ON"',
        events = "TMW_ACTION_AOE_MODE_CHANGED",
        category = "ActionAoE",
    })	
	
	-- The biggest problem of TellMeWhen what he using :setup on frames which use DogTag and it's bring an error
	TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", function()
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
		TMW:Fire("TMW_ACTION_BURST_CHANGED")
		TMW:Fire("TMW_ACTION_AOE_CHANGED")
		TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
		-- Taste's 
		TMW:Fire("TMW_ACTION_CD_MODE_CHANGED")		
		TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED")
	end)
end

-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------
-- Note: icon can be "TMW:icon:1S2PCb9iygE4" (as GUID) or "TellMeWhen_Group1_Icon1" (as ID)
function Env.IsIconShown(icon)
	-- @return boolean, if icon physically shown	
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.attributes.realAlpha == 1) or false
end 

function Env.IsIconDisplay(icon)
	-- @return textureID or 0 
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled and FRAME:IsVisible() and FRAME.attributes.texture) or 0    
end

function Env.IsIconEnabled(icon)
	-- @return boolean
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled) or false
end

-------------------------------------------------------------------------------
-- IconType: TheAction - UnitCasting
-------------------------------------------------------------------------------
local L = TMW.L

local Type = TMW.Classes.IconType:New("TheAction - UnitCasting")
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = "[The Action] " .. L["ICONMENU_CAST"]
Type.desc = "The Action addon handles this icon type for own API to provide functional for check any unit\nThis is more accurate than anything else, you should use that instead of another options"
Type.menuIcon = "Interface\\Icons\\Temp"
Type.AllowNoName = true
Type.usePocketWatch = 1
Type.unitType = "unitid"
Type.hasNoGCD = true
Type.canControlGroup = true

local STATE_PRESENT = TMW.CONST.STATE.DEFAULT_SHOW
local STATE_ABSENT = TMW.CONST.STATE.DEFAULT_HIDE
local STATE_ABSENTEACH = 10

-- AUTOMATICALLY GENERATED: UsesAttributes
Type:UsesAttributes("state")
Type:UsesAttributes("spell")
Type:UsesAttributes("reverse")
Type:UsesAttributes("start, duration")
Type:UsesAttributes("unit, GUID")
Type:UsesAttributes("texture")
-- END AUTOMATICALLY GENERATED: UsesAttributes

Type:SetModuleAllowance("IconModule_PowerBar_Overlay", true)

Type:RegisterIconDefaults{
	-- The unit(s) to check for casts
	Unit					= "player", 

	-- True if the icon should only check interruptible casts.
	Interruptible			= false,

	-- True if the icon should display blanks instead of the pocketwatch texture.
	NoPocketwatch			= false,
}


Type:RegisterConfigPanel_XMLTemplate(100, "TellMeWhen_ChooseName", {
	title = L["ICONMENU_CHOOSENAME3"] .. " " .. L["ICONMENU_CHOOSENAME_ORBLANK"],
	SUGType = "cast",
})

Type:RegisterConfigPanel_XMLTemplate(105, "TellMeWhen_Unit", {
	implementsConditions = true,
})

Type:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[STATE_PRESENT]     = { order = 1, text = "|cFF00FF00" .. L["ICONMENU_PRESENT"], },
	[STATE_ABSENTEACH]  = { order = 2, text = "|cFFFF0000" .. L["ICONMENU_ABSENTEACH"], tooltipText = L["ICONMENU_ABSENTEACH_DESC"]:format(L["ICONMENU_ABSENTONALL"]) },
	[STATE_ABSENT]      = { order = 3, text = "|cFFFF0000" .. L["ICONMENU_ABSENTONALL"],  },
})

Type:RegisterConfigPanel_ConstructorFunc(150, "TellMeWhen_CastSettings", function(self)
	self:SetTitle(Type.name)
	self:BuildSimpleCheckSettingFrame({
		function(check)
			check:SetTexts(L["ICONMENU_ONLYINTERRUPTIBLE"], L["ICONMENU_ONLYINTERRUPTIBLE_DESC"])
			check:SetSetting("Interruptible")
		end,
		function(check)
			check:SetTexts(L["ICONMENU_NOPOCKETWATCH"], L["ICONMENU_NOPOCKETWATCH_DESC"])
			check:SetSetting("NoPocketwatch")
		end,
	})
end)

-- The unit spellcast events that the icon will register.
-- We keep them in a table because there's a fuckload of them.
local callbacks = {
	UNIT_SPELLCAST_CHANNEL_STOP = true, 
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	UNIT_SPELLCAST_CHANNEL_START = true, 
	UNIT_SPELLCAST_INTERRUPTED = true,
	UNIT_SPELLCAST_FAILED = true, 
	UNIT_SPELLCAST_STOP = true, 
	UNIT_SPELLCAST_DELAYED = true, 
	UNIT_SPELLCAST_START = true,
}

local events = {
	UNIT_SPELLCAST_CHANNEL_STOP = true,
	UNIT_SPELLCAST_INTERRUPTED = true,
	UNIT_SPELLCAST_FAILED = true, 
	UNIT_SPELLCAST_DELAYED = true, 
	UNIT_SPELLCAST_STOP = true, 
}

local function Cast_OnEvent(icon, event, arg1)
	if callbacks[event] and icon.UnitSet.UnitsLookup[arg1] then
		-- A UNIT_SPELLCAST_ event
		-- If the icon is checking the unit, schedule an update for the icon.
		icon.NextUpdateTime = 0
	elseif event == "TMW_UNITSET_UPDATED" and arg1 == icon.UnitSet then
		-- A unit was just added or removed from icon.Units, so schedule an update.
		icon.NextUpdateTime = 0
	end
end

local function Cast_OnUpdate(icon, time)
	-- Upvalue things that will be referenced a lot in our loops.
	local NameFirst, NameStringHash, Units, Interruptible =
	icon.Spells.First, icon.Spells.StringHash, icon.Units, icon.Interruptible

	for u = 1, #Units do
		local unit = Units[u]
		local GUID = UnitGUID(unit)

		if GUID then
			-- This need to set fixed for "player" for LibClassicCasterino
			if UnitIsUnit("player", unit) then 
				unit = "player"
			end 
			
			local name, _, iconTexture, start, endTime, _, _, notInterruptible = LibClassicCasterino:UnitCastingInfo(unit)
			-- Reverse is used to reverse the timer sweep masking behavior. Regular casts should have it be false.
			local reverse = false

			-- There is no regular spellcast. Check for a channel.
			if not name then
				name, _, iconTexture, start, endTime, _, notInterruptible = LibClassicCasterino:UnitChannelInfo(unit)
				-- Channeled casts should reverse the timer sweep behavior.
				reverse = true
			end
			
			if name then 
				local KickImun = A.GetAuraList("KickImun")
				if next(KickImun) then 
					notInterruptible = A.Unit(unit):HasBuffs("KickImun") ~= 0 
				else
					notInterruptible = false 
				end 
			end 

			if name and not (notInterruptible and Interruptible) and (NameFirst == "" or NameStringHash[strlowerCache[name]]) then				
				-- Times reported by the cast APIs are in milliseconds for some reason.
				start, endTime = start/1000, endTime/1000
				local duration = endTime - start
				icon.LastTextures[GUID] = iconTexture

				if not icon:YieldInfo(true, name, unit, GUID, iconTexture, start, duration, reverse) then
					-- If icon:YieldInfo() returns false, it means we don't need to keep harvesting data.
					return
				end
			elseif icon.States[STATE_ABSENTEACH].Alpha > 0 then
				if not icon:YieldInfo(true, nil, unit, GUID, icon.LastTextures[GUID], 0, 0, false) then
					-- If icon:YieldInfo() returns false, it means we don't need to keep harvesting data.
					return
				end
			end
		end
	end

	-- Signal the group controller that we are at the end of our data harvesting.
	icon:YieldInfo(false)
end

function Type:HandleYieldedInfo(icon, iconToSet, spell, unit, GUID, texture, start, duration, reverse)
	if spell then
		-- There was a spellcast or channel present on one of the icon's units.
		iconToSet:SetInfo(
			"state; texture; start, duration; reverse; spell; unit, GUID",
			STATE_PRESENT,
			texture,
			start, duration,
			reverse,
			spell,
			unit, GUID
		)
	elseif unit then
		-- There were no casts detected on this unit.
		iconToSet:SetInfo(
			"state; texture; start, duration; spell; unit, GUID",
			STATE_ABSENTEACH,
			texture or (icon.NoPocketwatch and "" or "Interface\\Icons\\INV_Misc_PocketWatch_01"),
			0, 0,
			icon.Spells.First,
			unit or icon.Units[1], GUID or nil
		)
	else
		-- There were no casts detected at all.
		unit = icon.Units[1]
		GUID = unit and UnitGUID(unit)
		iconToSet:SetInfo(
			"state; texture; start, duration; spell; unit, GUID",
			STATE_ABSENT,
			GUID and icon.LastTextures[GUID] or (icon.NoPocketwatch and "" or "Interface\\Icons\\INV_Misc_PocketWatch_01"),
			0, 0,
			icon.Spells.First,
			unit, GUID
		)
	end
end

function Type:Setup(icon)
	icon.Spells = TMW:GetSpells(icon.Name, false)
	
	icon.Units, icon.UnitSet = TMW:GetUnits(icon, icon.Unit, icon:GetSettings().UnitConditions)

	icon.LastTextures = icon.LastTextures or {}

	local texture, known = Type:GetConfigIconTexture(icon)
	if not known and icon.NoPocketwatch then
		texture = ""
	end
	icon:SetInfo("texture", texture)

	-- Setup events and update functions.
	if icon.UnitSet.allUnitsChangeOnEvent then
		icon:SetUpdateMethod("manual")
	
		-- Register the UNIT_SPELLCAST_ callbacks
		for callback in pairs(callbacks) do
			LibClassicCasterino.RegisterCallback(icon, callback, Cast_OnEvent, icon)
		end
		
		-- Register the UNIT_SPELLCAST_ self events (to fix issue with /stopcasting)
		-- Enemies still can exploit it but timer will remain until their next cast, usually everyone fake casting without this dirt through stopcast
		for event in pairs(events) do			
			icon:RegisterEvent(event)
		end		
		
		TMW:RegisterCallback("TMW_UNITSET_UPDATED", Cast_OnEvent, icon)
		icon:SetScript("OnEvent", Cast_OnEvent)
	end

	icon:SetUpdateFunction(Cast_OnUpdate)
	icon:Update()
end

function Type:GuessIconTexture(ics)
	if ics.Name and ics.Name ~= "" then
		local name = TMW:GetSpells(ics.Name).First
		if name then
			return TMW.GetSpellTexture(name)
		end
	end
	return "Interface\\Icons\\Temp"
end

Type:Register(151)

-------------------------------------------------------------------------------
-- IconType: TheAction - LossOfControl
-------------------------------------------------------------------------------
local INCONTROL 	= 1 -- Inside control 
local CONTROLLOST 	= 2 -- Out of control  

local TypeLOC = TMW.Classes.IconType:New("TheAction - LossOfControl")
TypeLOC.name = "[The Action] " .. L["LOSECONTROL_ICONTYPE"]	
TypeLOC.desc = L["LOSECONTROL_ICONTYPE_DESC"]
TypeLOC.menuIcon = "Interface\\Icons\\Spell_Shadow_Possession"
TypeLOC.AllowNoName = true
TypeLOC.usePocketWatch = 1
TypeLOC.hasNoGCD = true
TypeLOC.canControlGroup = true

TypeLOC:UsesAttributes("state")
TypeLOC:UsesAttributes("start, duration")
TypeLOC:UsesAttributes("texture")

TypeLOC:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[INCONTROL] 	= { text = "|cFF00FF00" .. L["LOSECONTROL_INCONTROL"],   },
	[CONTROLLOST] 	= { text = "|cFFFF0000" .. L["LOSECONTROL_CONTROLLOST"], },
})

local function LossOfControlOnUpdate(icon, time)
	local attributes = icon.attributes
	local start = attributes.start
	local duration = attributes.duration
	
	if duration >= huge then 
		duration = select(2, A.LossOfControl:GetFrameData())
	end 

	if time - start > duration then	
		icon:SetInfo(
			"state; start, duration",
			INCONTROL,
			0, 0
		)		
	else
		icon:SetInfo(
			"state; start, duration",
			CONTROLLOST,
			start, duration
		)	
	end
end

local function LossOfControlOnEvent(icon)	
	local textureID, duration = A.LossOfControl:GetFrameData()		
	if duration ~= 0 and textureID ~= 0 then 
		icon:SetInfo(
			"texture; state; start, duration",
			textureID,
			CONTROLLOST,
			TMW.time, duration
		)
	else 
		icon:SetInfo(
			"texture; state; start, duration",
			icon.FirstTexture,
			INCONTROL,
			0, 0
		)
	end 
	icon.NextUpdateTime = 0
end 

function TypeLOC:Setup(icon)	
	icon.FirstTexture = GetSpellTexture(ACTION_CONST_PICKPOCKET)
	icon:SetInfo("texture", icon.FirstTexture)
	
	TMW:RegisterCallback("TMW_ACTION_LOSS_OF_CONTROL_UPDATE", LossOfControlOnEvent, icon)
	
	icon:SetUpdateMethod("manual")	
	icon:SetUpdateFunction(LossOfControlOnUpdate)
	icon:Update()
end

TypeLOC:Register(103)

-------------------------------------------------------------------------------
-- Scales
-------------------------------------------------------------------------------
local BlackBackground 	= CreateFrame("Frame", nil, UIParent)
BlackBackground:SetBackdrop(nil)
BlackBackground:SetFrameStrata("HIGH")
BlackBackground:SetSize(736, 30)
BlackBackground:SetPoint("TOPLEFT", 0, 12) 
BlackBackground:SetShown(false)
BlackBackground.IsEnable = true
BlackBackground.texture = BlackBackground:CreateTexture(nil, "TOOLTIP")
BlackBackground.texture:SetAllPoints(true)
BlackBackground.texture:SetColorTexture(0, 0, 0, 1)

local function CreateRankFrame(name, anchor, x, y)
	local frame 		= CreateFrame("Frame", name, UIParent)
	frame:SetBackdrop(nil)
	frame:SetFrameStrata("TOOLTIP")
	frame:SetToplevel(true)
	frame:SetSize(1, 1)
	frame:SetScale(1)
	frame:SetPoint(anchor, x, y)
	frame.texture = frame:CreateTexture(nil, "TOOLTIP")
	frame.texture:SetAllPoints(true)
	frame.texture:SetColorTexture(0, 0, 0, 1.0)
	return frame
end 

local RankSingle 		 = CreateRankFrame("RankSingle", "TOPLEFT", 442, -1)
local RankAoE	 		 = CreateRankFrame("RankAoE", "TOPLEFT", 442, -2)

local isShownOnce
local function UpdateFrames()
    if not TellMeWhen_Group1 or not strfind(strlowerCache(TellMeWhen_Group1.Name), "shown main") then 
        if BlackBackground:IsShown() then
            BlackBackground:Hide()
        end     
		
        if TargetColor and TargetColor:IsShown() then
            TargetColor:Hide()
        end  
		
		if RankSingle:IsShown() then
            RankSingle:Hide()
        end				
		
		if RankAoE:IsShown() then
            RankAoE:Hide()
        end		
		
        return 
    end
	
	local myheight = select(2, GetPhysicalScreenSize())
    local myscale1 = 0.42666670680046 * (1080 / myheight)
    local myscale2 = 0.17777778208256 * (1080 / myheight)    
    local group1, group2 = TellMeWhen_Group1:GetEffectiveScale()
    if TellMeWhen_Group2 and TellMeWhen_Group2.Enabled then
        group2 = TellMeWhen_Group2:GetEffectiveScale()   
    end    
	
	-- "Shown Main"
    if group1 ~= nil and group1 ~= myscale1 then
        TellMeWhen_Group1:SetParent(nil)
        TellMeWhen_Group1:SetScale(myscale1) 
        TellMeWhen_Group1:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group1:SetToplevel(true) 
        if BlackBackground.IsEnable then 
            if not BlackBackground:IsShown() then
                BlackBackground:Show()
            end
            BlackBackground:SetScale(myscale1 / (BlackBackground:GetParent() and BlackBackground:GetParent():GetEffectiveScale() or 1))      
        end 
    end
	
	-- "Shown Cast Bars"
    if group2 ~= nil and group2 ~= myscale2 then        
        TellMeWhen_Group2:SetParent(nil)        
        TellMeWhen_Group2:SetScale(myscale2) 
        TellMeWhen_Group2:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group2:SetToplevel(true)
    end   
	
	-- HealingEngine
    if TargetColor then
        if not TargetColor:IsShown() then
            TargetColor:Show()
        end
        TargetColor:SetScale((0.71111112833023 * (1080 / myheight)) / (TargetColor:GetParent() and TargetColor:GetParent():GetEffectiveScale() or 1))
    end           

	-- Rank Spells 
	if RankSingle then 
		if not RankSingle:IsShown() then
            RankSingle:Show()
        end
        RankSingle:SetScale((0.71111112833023 * (1080 / myheight)) / (RankSingle:GetParent() and RankSingle:GetParent():GetEffectiveScale() or 1))	
	end 
	
	if RankAoE then 
		if not RankAoE:IsShown() then
            RankAoE:Show()
        end
        RankAoE:SetScale((0.71111112833023 * (1080 / myheight)) / (RankAoE:GetParent() and RankAoE:GetParent():GetEffectiveScale() or 1))	
	end 	
end

local isCheckedOnce -- Don't display any messages at first time loading (make warnings only with interaction)
local function UpdateCVAR()
    if GetCVar("Contrast") ~= "50" then 
		SetCVar("Contrast", 50)
		if isCheckedOnce then 
			A.Print("Contrast should be 50")		
		end
	end
	
    if GetCVar("Brightness") ~= "50" then 
		SetCVar("Brightness", 50) 
		if isCheckedOnce then 
			A.Print("Brightness should be 50")			
		end 
	end
	
    if GetCVar("Gamma") ~= "1.000000" then 
		SetCVar("Gamma", "1.000000") 
		if isCheckedOnce then 
			A.Print("Gamma should be 1")	
		end 
	end
	
    if GetCVar("colorblindsimulator") ~= "0" then 
		SetCVar("colorblindsimulator", 0) 
	end 
	
	--[[
    if GetCVar("RenderScale") ~= "1" then 
		SetCVar("RenderScale", 1) 
	end
	
	
    if GetCVar("MSAAQuality") ~= "0" then 
		SetCVar("MSAAQuality", 0) 
	end
	
    -- Could effect bugs if > 0 but FXAA should work, some people saying MSAA working too 
	local AAM = toNum[GetCVar("ffxAntiAliasingMode")]
    if AAM > 2 and AAM ~= 6 then 		
		SetCVar("ffxAntiAliasingMode", 0) 
		A.Print("You can't set higher AntiAliasing mode than FXAA or not equal to MSAA 8x")
	end
	]]
	
    if GetCVar("doNotFlashLowHealthWarning") ~="1" then 
		SetCVar("doNotFlashLowHealthWarning", 1) 
	end
	
	local nameplateMaxDistance = GetCVar("nameplateMaxDistance")
    if nameplateMaxDistance and toNum[nameplateMaxDistance] ~= ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE then 
		SetCVar("nameplateMaxDistance", ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE) 
		if isCheckedOnce then 
			A.Print("nameplateMaxDistance " .. nameplateMaxDistance .. " => " .. ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE)	
		end 
	end	
	
	if A.GetToggle(1, "cameraDistanceMaxZoomFactor") then 
		local cameraDistanceMaxZoomFactor = GetCVar("cameraDistanceMaxZoomFactor")
		if cameraDistanceMaxZoomFactor ~= "4" then 
			SetCVar("cameraDistanceMaxZoomFactor", 4) 
			if isCheckedOnce then 
				A.Print("cameraDistanceMaxZoomFactor " .. cameraDistanceMaxZoomFactor .. " => " .. 4)	
			end 
		end		
	end 
	
    -- WM removal
    if GetCVar("screenshotQuality") ~= "10" then 
		SetCVar("screenshotQuality", 10)  
	end
	
    if GetCVar("nameplateShowEnemies") ~= "1" then
        SetCVar("nameplateShowEnemies", 1) 
		if isCheckedOnce then 
			A.Print("Enemy nameplates should be enabled")
		end 
    end		
	
	if GetCVar("autoSelfCast") ~= "1" then 
		SetCVar("autoSelfCast", 1)
	end 
	
	isCheckedOnce = true
end

local function ConsoleUpdate()
	UpdateCVAR()
    UpdateFrames()      
end 

local function TrueScaleInit()
    TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(_, frame)
            local str_group = toStr[frame]
            if strfind(str_group, "TellMeWhen_Group2") then                
                UpdateFrames()  
            end
    end)
    ConsoleUpdate()
    TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TMW_TEMP_SAFESETUP_COMPLETE")
end
TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TMW_TEMP_SAFESETUP_COMPLETE")    

A.Listener:Add("ACTION_EVENT_UTILS", "DISPLAY_SIZE_CHANGED", 	ConsoleUpdate	)
A.Listener:Add("ACTION_EVENT_UTILS", "UI_SCALE_CHANGED", 		ConsoleUpdate	)
--A.Listener:Add("ACTION_EVENT_UTILS", "PLAYER_ENTERING_WORLD", ConsoleUpdate	)
--A.Listener:Add("ACTION_EVENT_UTILS", "CVAR_UPDATE",			UpdateCVAR		)
VideoOptionsFrame:HookScript("OnHide", 							ConsoleUpdate	)
InterfaceOptionsFrame:HookScript("OnHide", 						UpdateCVAR		)

function A.BlackBackgroundSet(bool)
    BlackBackground.IsEnable = bool 
    BlackBackground:SetShown(bool)
end

-------------------------------------------------------------------------------
-- Frames 
-------------------------------------------------------------------------------
-- TellMeWhen Documentation - Sets attributes of an icon.
-- 
-- The attributes passed to this function will be processed by a [[api/icon-data-processor/api-documentation/|IconDataProcessor]] (and possibly one or more [[api/icon-data-processor-hook/api-documentation/|IconDataProcessorHook]]) and interested [[api/icon-module/api-documentation/|IconModule]]s will be notified of any changes to the attributes.
-- @name Icon:SetInfo
-- @paramsig signature, ...
-- @param signature [string] A semicolon-delimited string of attribute strings as passed to the constructor of a [[api/icon-data-processor/api-documentation/|IconDataProcessor]].
-- @param ... [...] Any number of params that will match up one-for-one with the signature passed in.
-- @usage icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
--  
--  -- From IconTypes/IconType_wpnenchant:
--  icon:SetInfo("state; start, duration; spell",
--    STATE_ABSENT,
--    0, 0,
--    nil
--  )
-- 
--  -- From IconTypes/IconType_reactive:
--  icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
--    STATE_USABLE,
--    GetSpellTexture(iName),
--    start, duration,
--    charges, maxCharges, chargeStart, chargeDur
--    stack, stack,
--    iName			
local function TMWAPI(icon, ...)
    local attributesString, param = ...
    
	-- Sets texture 
    if attributesString == "state" then 
        -- Color if not colored (Alpha will show it)
        if type(param) == "table" and param["Color"] then 
            if icon.attributes.calculatedState.Color ~= param["Color"] then 
                icon:SetInfo(attributesString, {Color = param["Color"], Alpha = param["Alpha"], Texture = param["Texture"]})
            end
            return 
        end 
        
        -- Hide if not hidden
        if type(param) == "number" and (param == 0 or param == ACTION_CONST_TMW_DEFAULT_STATE_HIDE) then
            if icon.attributes.realAlpha ~= 0 then 
                icon:SetInfo(attributesString, param)
            end 
            return 
        end 
    end 
    
    if attributesString == "texture" and type(param) == "number" then         
        if (icon.attributes.calculatedState.Color ~= "ffffffff" or icon.attributes.realAlpha == 0) then 
            -- Show + Texture if hidden
            icon:SetInfo("state; " .. attributesString, ACTION_CONST_TMW_DEFAULT_STATE_SHOW, param)
        elseif icon.attributes.texture ~= param then 
            -- Texture if not applied        
            icon:SetInfo(attributesString, param)
        end 
        return         
    end 
    
    icon:SetInfo(...)
end
  
function A.Hide(icon)
	-- @usage A.Hide(icon)
	local meta = icon.ID		
	if meta == 3 and RankSingle.isColored then 
		RankSingle.texture:SetColorTexture(0, 0, 0, 1.0)
		RankSingle.isColored = nil 
		TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
	end 
	
	if meta == 4 and RankAoE.isColored then 
		RankAoE.texture:SetColorTexture(0, 0, 0, 1.0)
		RankAoE.isColored = nil 
	end 
	
	if icon.attributes.state ~= ACTION_CONST_TMW_DEFAULT_STATE_HIDE then 
		icon:SetInfo("state; texture", ACTION_CONST_TMW_DEFAULT_STATE_HIDE, "")
	end 	
end 

function A:Show(icon, texture) 
	-- @usage self:Show(icon) for own texture with color filter or self:Show(icon, textureID)	
	-- Sets ranks 
	local meta = icon.ID
	if meta == 3 then 
		if not self.useMaxRank and self.isRank then 
			if self.isRank ~= RankSingle.isColored then 
				RankSingle.texture:SetColorTexture(RANKCOLOR[self.isRank]())
				RankSingle.isColored = self.isRank 
				TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
			end 
		elseif RankSingle.isColored then 
			RankSingle.texture:SetColorTexture(0, 0, 0, 1.0)
			RankSingle.isColored = nil 
			TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
		end 
	end 
	
	if meta == 4 then 
		if not self.useMaxRank and self.isRank then 
			if self.isRank ~= RankAoE.isColored then 
				RankAoE.texture:SetColorTexture(RANKCOLOR[self.isRank]())
				RankAoE.isColored = self.isRank 
			end 
		elseif RankAoE.isColored then 
			RankAoE.texture:SetColorTexture(0, 0, 0, 1.0)
			RankAoE.isColored = nil 
		end 	
	end 
	
	if texture then 
		TMWAPI(icon, "texture", texture)
	else 
		TMWAPI(icon, self:Texture())
	end 		
	
	return true 
end 

function A.FrameHasSpell(frame, spellID)
	-- @return boolean 
	-- @usage A.FrameHasSpell(icon, {123, 168, 18}) or A.FrameHasSpell(icon, 1022)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and type(frame.attributes.texture) == "number" then 
		local texture = frame.attributes.texture
		if type(spellID) == "table" then 
			for i = 1, #spellID do 
				if texture == GetSpellTexture(spellID[i]) then 
					return true 
				end 
			end 
		else 
			return texture == GetSpellTexture(spellID) 
		end 	
	end 
	return false 
end 

function A.FrameHasObject(frame, ...)
	-- @return boolean 
	-- @usage A.FrameHasObject(frame, A.Spell1, A.Item1)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and frame.attributes.texture and frame.attributes.texture ~= "" then 
		local texture = frame.attributes.texture
		for i = 1, select("#", ...) do 
			local obj = select(i, ...)
			local _, objTexture = obj:Texture()
			if objTexture and objTexture == texture then 
				return true 
			end 
		end 
	end 
end 