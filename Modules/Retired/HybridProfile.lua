-------------------------------------------------------------------------------
--
-- DON'T USE THIS API, IT'S OLD AND WILL BE REMOVED, THIS IS LEAVED HERE TO 
-- PROVIDE SUPPORT FOR OLD PROFILES
--
-------------------------------------------------------------------------------
-- TODO: Remove ALL this for old profile which until June 2019
ptgroup = 3
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs = pairs

function SystemToggles()   
    if TellMeWhen_GlobalGroup8 and TellMeWhen_GlobalGroup8:IsEnabled() then
        LOSCheck = TellMeWhen_GlobalGroup8_Icon1 and TellMeWhen_GlobalGroup8_Icon1.Enabled
        MSG_Toggle = TellMeWhen_GlobalGroup8_Icon3 and TellMeWhen_GlobalGroup8_Icon3.Enabled
        Target_Toggle = TellMeWhen_GlobalGroup8_Icon5 and TellMeWhen_GlobalGroup8_Icon5.Enabled
    end    
end

local ProfileToggle = {    
    ["[GGL] Mage"] = function()    
        purge_toggle = TellMeWhen_Group3_Icon1.Enabled
        dispel_toggle = TellMeWhen_Group3_Icon3.Enabled
        kick_toggle = TellMeWhen_Group3_Icon5.Enabled
        petattack_focus = TellMeWhen_Group3_Icon7.Enabled
        burst_toggle = TellMeWhen_Group3_Icon9.Enabled
        deff_toggle = TellMeWhen_Group3_Icon11.Enabled
        DragonRoar_toggle = TellMeWhen_Group3_Icon13.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon15.Enabled
		MouseOver_Toggle = TellMeWhen_Group3_Icon17.Enabled
    end,        
    ["[GGL] Druid"] = function()
        MouseOver_Toggle = TellMeWhen_Group3_Icon1.Enabled
        dispel_toggle = TellMeWhen_Group3_Icon3.Enabled
        kick_toggle = TellMeWhen_Group3_Icon5.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon7.Enabled
        burst_toggle = TellMeWhen_Group3_Icon9.Enabled
        deff_toggle = TellMeWhen_Group3_Icon11.Enabled
        Soothe_toggle = TellMeWhen_Group3_Icon13.Enabled
        Thorns_toggle = TellMeWhen_Group3_Icon15.Enabled 
        HE_Pets = TellMeWhen_Group3_Icon17.Enabled 
        if TellMeWhen_Group3_Icon19.Enabled then
            HE_Toggle = nil
        elseif TellMeWhen_Group3_Icon20.Enabled then
            HE_Toggle = "RAID"
        elseif TellMeWhen_Group3_Icon21.Enabled then
            HE_Toggle = "TANK"
        elseif TellMeWhen_Group3_Icon22.Enabled then
            HE_Toggle = "HEALER"
        elseif TellMeWhen_Group3_Icon23.Enabled then
            HE_Toggle = "DAMAGER"
        end
    end,    
    ["[GGL] Paladin"] = function()
        MouseOver_Toggle = TellMeWhen_Group3_Icon1.Enabled
        dispel_toggle = TellMeWhen_Group3_Icon3.Enabled
        kick_toggle = TellMeWhen_Group3_Icon5.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon7.Enabled
        burst_toggle = TellMeWhen_Group3_Icon9.Enabled
        deff_toggle = TellMeWhen_Group3_Icon11.Enabled
        HoS_toggle = TellMeWhen_Group3_Icon13.Enabled
        HoF_toggle = TellMeWhen_Group3_Icon15.Enabled 
        BoP_toggle = TellMeWhen_Group3_Icon17.Enabled 
        HE_Pets = TellMeWhen_Group3_Icon23.Enabled 
        -- FlashOfLight
        if TellMeWhen_Group3_Icon19.Enabled then
            FL_toggle = "ALL"
        elseif TellMeWhen_Group3_Icon20.Enabled then
            FL_toggle = "SELF"
        elseif TellMeWhen_Group3_Icon21.Enabled then
            FL_toggle = "PARTY"
        elseif TellMeWhen_Group3_Icon22.Enabled then
            FL_toggle = "OFF"
        end
        -- HealingEngine
        if TellMeWhen_Group3_Icon25.Enabled then
            HE_Toggle = nil
        elseif TellMeWhen_Group3_Icon26.Enabled then
            HE_Toggle = "RAID"
        elseif TellMeWhen_Group3_Icon27.Enabled then
            HE_Toggle = "TANK"
        elseif TellMeWhen_Group3_Icon28.Enabled then
            HE_Toggle = "HEALER"
        elseif TellMeWhen_Group3_Icon29.Enabled then
            HE_Toggle = "DAMAGER"
        end
        -- Beacon of Faith
        if TellMeWhen_Group3_Icon31.Enabled then
            BoF_Toggle = "SELF"
        elseif TellMeWhen_Group3_Icon32.Enabled then
            BoF_Toggle = "TANK"
        elseif TellMeWhen_Group3_Icon33.Enabled then
            BoF_Toggle = "MARKED"
        else
            BoF_Toggle = "OFF"            
        end
        -- Beacon of Light
        if TellMeWhen_Group3_Icon37.Enabled then
            BoL_Toggle = "SELF"
        elseif TellMeWhen_Group3_Icon38.Enabled then
            BoL_Toggle = "TANK"
        elseif TellMeWhen_Group3_Icon39.Enabled then
            BoL_Toggle = "MOSTINCDMG"
        elseif TellMeWhen_Group3_Icon40.Enabled then
            BoL_Toggle = "MARKED"
        else
            BoL_Toggle = "OFF"            
        end
        BlindingLight_Toggle = TellMeWhen_Group3_Icon43.Enabled
    end,
    ["[GGL] Demon Hunter"] = function()
        MouseOver_Toggle = TellMeWhen_Group3_Icon1.Enabled
        dispel_toggle = TellMeWhen_Group3_Icon3.Enabled
        kick_toggle = TellMeWhen_Group3_Icon5.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon7.Enabled
        burst_toggle = TellMeWhen_Group3_Icon9.Enabled
        deff_toggle = TellMeWhen_Group3_Icon11.Enabled
        FelRush_Toggle = TellMeWhen_Group3_Icon13.Enabled
        VR_Toggle = TellMeWhen_Group3_Icon15.Enabled 
        Purje_toggle = TellMeWhen_Group3_Icon17.Enabled
        -- Eye of Leotheras
        if TellMeWhen_Group3_Icon19.Enabled then
            EoL_Toggle = "ON CD"
        elseif TellMeWhen_Group3_Icon20.Enabled then
            EoL_Toggle = "ON ENEMY BURST"
        elseif TellMeWhen_Group3_Icon21.Enabled then
            EoL_Toggle = "ON TEAM DEFF"
        elseif TellMeWhen_Group3_Icon22.Enabled then
            EoL_Toggle = "MARKED"
        else
            EoL_Toggle = "OFF"            
        end
        -- Rain From Above 
        if TellMeWhen_Group3_Icon25.Enabled then
            Rain_Toggle = "ON CD"
        elseif TellMeWhen_Group3_Icon26.Enabled then
            Rain_Toggle = "ON ENEMY BURST"
        elseif TellMeWhen_Group3_Icon27.Enabled then
            Rain_Toggle = "ON TEAM DEFF"
        else
            Rain_Toggle = "OFF"            
        end
        -- Use Darkness and Imprison to DeffT
        DeffTeam_Toggle = TellMeWhen_Group3_Icon29.Enabled
        -- Chaos Nova, Fel Eruption, Imprison
        UseCC_Toggle = TellMeWhen_Group3_Icon31.Enabled
        -- Facing
        Facing_Toggle = TellMeWhen_Group3_Icon33.Enabled
        -- Mana Rift
        if TellMeWhen_Group3_Icon35.Enabled then
            ManaRift_Toggle = "HEALER"
        else
            ManaRift_Toggle = "EVERYONE"
        end
    end,    
    ["[GGL] Death Knight"] = function()
        MouseOver_Toggle = TellMeWhen_Group3_Icon1.Enabled
        burst_toggle = TellMeWhen_Group3_Icon3.Enabled
        kick_toggle = TellMeWhen_Group3_Icon5.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon7.Enabled
        DS_Toggle = TellMeWhen_Group3_Icon9.Enabled
        Deff_Toggle = TellMeWhen_Group3_Icon11.Enabled
        DG_Toggle = TellMeWhen_Group3_Icon13.Enabled
        SM_Toggle = TellMeWhen_Group3_Icon15.Enabled 
        AMS_toggle = TellMeWhen_Group3_Icon17.Enabled
        -- Simulacrum Cast Bars
        if TellMeWhen_Group3_Icon19.Enabled then
            Simulacrum_Toggle = "EVERYTHING"
        elseif TellMeWhen_Group3_Icon20.Enabled then
            Simulacrum_Toggle = "CHAIN CC"
        elseif TellMeWhen_Group3_Icon21.Enabled then
            Simulacrum_Toggle = "DEFF AGRESS"
        elseif TellMeWhen_Group3_Icon22.Enabled then
            Simulacrum_Toggle = "MARKED"
        else
            Simulacrum_Toggle = "OFF" 
        end
        -- DeathGrip Cast Bars
        if TellMeWhen_Group3_Icon25.Enabled then
            DeathGrip_Toggle = "EVERYTHING"
        elseif TellMeWhen_Group3_Icon26.Enabled then
            DeathGrip_Toggle = "DEFF"
        elseif TellMeWhen_Group3_Icon27.Enabled then
            DeathGrip_Toggle = "BURST"
        else
            DeathGrip_Toggle = "OFF" 
        end
        -- Use Anti-magic zone
        DeffTeam_Toggle = TellMeWhen_Group3_Icon29.Enabled
        -- Asphyxiate 
        UseCC_Toggle = TellMeWhen_Group3_Icon31.Enabled
        -- Pet
        PetStun_Toggle = TellMeWhen_Group3_Icon33.Enabled
        PetDeff_Toggle = TellMeWhen_Group3_Icon35.Enabled
        if TellMeWhen_Group3_Icon37.Enabled then
            PetAttack_Toggle = "TARGET"
        elseif TellMeWhen_Group3_Icon38.Enabled then
            PetAttack_Toggle = "FOCUS"
        else
            PetAttack_Toggle = "OFF"
        end     
        -- Chains of Ice
        Slow_Toggle = TellMeWhen_Group3_Icon40.Enabled
        Slow_Toggle_Focus = TellMeWhen_Group3_Icon42.Enabled        
        -- MassGrip
        MassGrip_Toggle = TellMeWhen_Group3_Icon44.Enabled
        -- Army of Dead
        Army_Toggle = TellMeWhen_Group3_Icon46.Enabled
        -- PvP 
        PvPCD_Toggle = TellMeWhen_Group3_Icon48.Enabled
    end,         
    ["[GGL] Priest"] = function()
        MouseOver_Toggle = TellMeWhen_Group3_Icon1.Enabled
        TargetTarget_Toggle = TellMeWhen_Group3_Icon3.Enabled
        AoE_Toggle = TellMeWhen_Group3_Icon5.Enabled
        Burst_Toggle = TellMeWhen_Group3_Icon7.Enabled
        SelfDeff_Toggle = TellMeWhen_Group3_Icon9.Enabled
        TeamDeff_Toggle = TellMeWhen_Group3_Icon11.Enabled
        Levitate_Toggle = TellMeWhen_Group3_Icon13.Enabled
        LeapofFaith_Toggle = TellMeWhen_Group3_Icon15.Enabled 
        SpellKick_Toggle = TellMeWhen_Group3_Icon17.Enabled
        Purje_Toggle = TellMeWhen_Group3_Icon19.Enabled
        Dispel_Toggle = TellMeWhen_Group3_Icon21.Enabled
        MassDispel_Toggle = TellMeWhen_Group3_Icon23.Enabled
        SPDispel_Toggle = TellMeWhen_Group3_Icon25.Enabled
        Kick_Toggle = TellMeWhen_Group3_Icon27.Enabled
        AngelicFeather_Toggle = TellMeWhen_Group3_Icon29.Enabled
        Opener_Toggle = TellMeWhen_Group3_Icon34.Enabled
        VampiricEmbrace_Toggle = TellMeWhen_Group3_Icon36.Enabled
        -- Penance 
        if TellMeWhen_Group3_Icon31.Enabled then 
            Penance_Toggle = "BOTH"
        elseif TellMeWhen_Group3_Icon32.Enabled then 
            Penance_Toggle = "HEAL"
        else
            Penance_Toggle = "DMG"
        end 
        -- HealingEngine
        -- HE-Absorb
        HE_Absorb = TellMeWhen_Group3_Icon39.Enabled 
        -- HE-Pets 
        HE_Pets = TellMeWhen_Group3_Icon41.Enabled 
        -- HE-Toggle 
        if TellMeWhen_Group3_Icon43.Enabled then
            HE_Toggle = nil
        elseif TellMeWhen_Group3_Icon44.Enabled then
            HE_Toggle = "RAID"
        elseif TellMeWhen_Group3_Icon45.Enabled then
            HE_Toggle = "TANK"
        elseif TellMeWhen_Group3_Icon46.Enabled then
            HE_Toggle = "HEALER"
        elseif TellMeWhen_Group3_Icon47.Enabled then
            HE_Toggle = "DAMAGER"
        end
        -- Arena1-3 Kick Toggle
        if TellMeWhen_Group3_Icon49.Enabled then
            ArenaKick_Toggle = "EVERYTHING"
        elseif TellMeWhen_Group3_Icon50.Enabled then
            ArenaKick_Toggle = "CHAIN CC"
        elseif TellMeWhen_Group3_Icon51.Enabled then
            ArenaKick_Toggle = "AGRESSIVE"
        elseif TellMeWhen_Group3_Icon52.Enabled then
            ArenaKick_Toggle = "DEFENSIVE"
        else
            ArenaKick_Toggle = "OFF"
        end
        -- Arena1-3 CC Toggle
        if TellMeWhen_Group3_Icon54.Enabled then
            ArenaCC_Toggle = "EVERYTHING"
        elseif TellMeWhen_Group3_Icon55.Enabled then
            ArenaCC_Toggle = "AGRESSIVE"
        elseif TellMeWhen_Group3_Icon56.Enabled then
            ArenaCC_Toggle = "DEFENSIVE"
        else
            ArenaCC_Toggle = "OFF"
        end
        -- Use CC
        CC_Toggle = TellMeWhen_Group3_Icon58.Enabled
        -- Single Rotation Arena Check BreakAble CC
        BreakAbleCheckCC_Toggle = TellMeWhen_Group3_Icon60.Enabled
        AtonementRenew_Toggle = TellMeWhen_Group3_Icon62.Enabled
    end,
}
function LocalToggles()
    local current = TMW.db:GetCurrentProfile()
    local profile = strmatch(current, "Chesder")     
    Env.BasicRotation = current == "[GGL] Basic" or profile == "Chesder"
    Env.IsGGLprofile = strmatch(current, "GGL") == "GGL" 
    if ProfileToggle[current] and TellMeWhen_Group3 then
        ProfileToggle[current]()
    end
end

local function UpdateChesderGroups()   
    local current = TMW.db:GetCurrentProfile()
    local profile = strmatch(current, "Chesder")     
    Env.BasicRotation = current == "[GGL] Basic" or profile == "Chesder"
    Env.IsGGLprofile = strmatch(current, "GGL") == "GGL" 
    
    if profile ~= "Chesder" then         
        -- Chesder Groups
        if TellMeWhen_GlobalGroup1 and TellMeWhen_GlobalGroup1.Enabled then
            for i = 1, 5 do
                DEFAULT_CHAT_FRAME.editBox:SetText("/tmw disable global " .. i)
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end   
        end 
        -- PvP / PvE Toggle
        if TellMeWhen_GlobalGroup8 then
            if not TellMeWhen_GlobalGroup8.Enabled then
                DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 8")
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end
            if TellMeWhen_GlobalGroup8_Icon7 and not TellMeWhen_GlobalGroup8_Icon7.Enabled then
                DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 8 7")
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end
        end
        -- Healer's Taunt Pet Group
        if TellMeWhen_GlobalGroup10 and not TellMeWhen_GlobalGroup10.Enabled then
            DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 10")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        end        
    elseif TellMeWhen_GlobalGroup1 and not TellMeWhen_GlobalGroup1.Enabled then   
        -- Chesder Groups
        if TellMeWhen_GlobalGroup1 and not TellMeWhen_GlobalGroup1.Enabled then
            for i = 1, 5 do
                DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global " .. i)
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end 
        end        
        -- PvP / PvE Toggle
        if TellMeWhen_GlobalGroup8 then
            if not TellMeWhen_GlobalGroup8.Enabled then
                DEFAULT_CHAT_FRAME.editBox:SetText("/tmw enable global 8")
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end
            DEFAULT_CHAT_FRAME.editBox:SetText("/tmw disable global 8 7")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        end
        if TellMeWhen_GlobalGroup10 and TellMeWhen_GlobalGroup10.Enabled then
            -- Healer's Taunt Pet Group
            DEFAULT_CHAT_FRAME.editBox:SetText("/tmw disable global 10")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        end        
    end
    
    -- Clear history of slash commands
    DEFAULT_CHAT_FRAME.editBox:SetHistoryLines(1)
    DEFAULT_CHAT_FRAME.editBox:AddHistoryLine("")
end

local function HybridProfileLaunch()
    if TellMeWhen_GlobalGroup8 then
        SystemToggles()
        LocalToggles() 
    end    
end 

local function UpdateAll()
	UpdateChesderGroups()
	HybridProfileLaunch()
	TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", UpdateAll, "TMW_SAFESETUP_COMPLETE_ACTION_DEPRECATED")
end 

TMW:RegisterCallback("TMW_ON_PROFILE", function(event, profileEvent, arg2, arg3)
        if 
        profileEvent == "OnProfileChanged" or
        profileEvent == "OnProfileCopied" or 
        profileEvent == "OnProfileReset" or 
        profileEvent == "OnNewProfile" 
        then
            UpdateAll()
        end        
end)

TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", UpdateAll, "TMW_SAFESETUP_COMPLETE_ACTION_DEPRECATED")	

Listener:Add("ACTION_EVENT_DEPRECATED_HYBRIDPROFILE", "UPDATE_INSTANCE_INFO",  HybridProfileLaunch)
Listener:Add("ACTION_EVENT_DEPRECATED_HYBRIDPROFILE", "PLAYER_ENTERING_WORLD", HybridProfileLaunch)

-- Used for debug 
function RunLocalToggles(profile)
    if ProfileToggle[current] and TellMeWhen_Group3 and TellMeWhen_Group3:IsEnabled() then
        ProfileToggle[current]()
    end 
end 