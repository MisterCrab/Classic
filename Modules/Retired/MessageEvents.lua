-------------------------------------------------------------------------------
--
-- DON'T USE THIS API, IT'S OLD AND WILL BE REMOVED, THIS IS LEAVED HERE TO 
-- PROVIDE SUPPORT FOR OLD PROFILES
--
-------------------------------------------------------------------------------
--- TODO: Delete this after all profile upgrade for Action
local TMW 							= TMW
local CNDT 							= TMW.CNDT
local Env 							= CNDT.Env
local A 							= Action

local pairs, _G 					= 
	  pairs, _G 
	  
local oMSG, starttime = {}, 0
local frame = CreateFrame("Frame", nil) 
frame:SetScript("OnUpdate", function() 
        if TMW.time >= starttime + A.GetGCD() * 2 then
            wipe(oMSG)            
            frame:Hide()              
        end        
end)
local EventTextList = {
    WARRIOR = {
        Icon6 = {"Disarm1", "Kick1", "RallyingCry", "DieBySword", "WarBanner"},
        Icon7 = {"Disarm2", "Kick2"},
        Icon8 = {"Disarm3", "Kick3"},
    }, 
    PALADIN = {
        Icon6 = {"Kick1", "GuardianOfAncientKing", "ArdentDefender", "EyeForAnEye", "ShieldOfVengeance"},
        Icon7 = {"Kick2", "HoS", "BoP", "Freedom", "Dispel"},
        Icon8 = {"Kick3", "HoS", "BoP", "Freedom", "Dispel"},
    },    
    HUNTER = {
        Icon6 = {"Freedom", "Deff", "Root1", "Kick1", "AspectOfTurtle", "Exhilaration"},
        Icon7 = {"Freedom", "Deff", "Root2", "Kick2"},
        Icon8 = {"Freedom", "Deff", "Root3", "Kick3"},
    }, 
    ROGUE = {
        Icon6 = {"Dismantle1", "Blind1", "Kick1"},
        Icon7 = {"Dismantle2", "Blind2", "Kick2"},
        Icon8 = {"Dismantle3", "Blind3", "Kick3"},
    }, 
    PRIEST = {
        Icon6 = {"CC1", "Kick1"},
        Icon7 = {"CC2", "Kick2", "Dispel"},
        Icon8 = {"CC3", "Kick3", "Dispel"},
    }, 
    SHAMAN = {
        Icon6 = {"Kick1", "AstralShift", "GroundingTotem"},
        Icon7 = {"Kick2", "Dispel"},
        Icon8 = {"Kick3", "Dispel"},
    }, 
    MAGE = {
        Icon6 = {"Kick1", "IceBlock"},
        Icon7 = {"Kick2", "Dispel"},
        Icon8 = {"Kick3", "Dispel"},
    },    
    WARLOCK = {
        Icon6 = {"Dispel", "Kick1", "UnendingResolve"},
        Icon7 = {"Dispel", "Kick2"},
        Icon8 = {"Dispel", "Kick3"},
    }, 
    MONK = {
        Icon6 = {"Freedom", "Kick1", "Disarm1"},
        Icon7 = {"Freedom", "Kick2", "Disarm2", "Dispel"},
        Icon8 = {"Freedom", "Kick3", "Disarm3", "Dispel"},
    }, 
    DRUID = {
        Icon6 = {"Kick1", "Thorns", "Renewal", "Barkskin", "SurvivalInstincts"},
        Icon7 = {"Kick2", "Thorns", "Dispel"},
        Icon8 = {"Kick3", "Thorns", "Dispel"},
    }, 
    DEMONHUNTER = {
        Icon6 = {"Kick1", "ReverseMagic", "Netherwalk", "Darkness", "Blur", "SigilOfChains"},
        Icon7 = {"Kick2"},
        Icon8 = {"Kick3"},
    }, 
    DEATHKNIGHT = {
        Icon6 = {"Kick1", "AMS", "DeathPact", "Zone-AntiMagic", "Icebound"},
        Icon7 = {"Kick2"},
        Icon8 = {"Kick3"},
    }, 
}

local function UpdateChat(...)
    if not MSG_Toggle or A.IsInitialized then 
        return 
    end
    
    local msg, _, _, name = ...
    for ICON, v in pairs(EventTextList[A.PlayerClass]) do        
        for i = 1, #v do            
            if strmatch(msg, v[i]) == v[i] then  
                local cu = strmatch(v[i], "raid%d+")
                
                if not cu then                            
                    oMSG[ICON] = v[i]                           
                elseif 
					(ICON == "Icon6" and UnitIsUnit("player", cu)) or
					(ICON == "Icon7" and UnitIsUnit("party1", cu)) or
					(ICON == "Icon8" and UnitIsUnit("party2", cu))
                then                            
                    oMSG[ICON] = select(1, gsub(v[i], "%s"..cu, "", 1))
                else
                    return
                end    
                starttime = TMW.time
                frame:Show()
            end
        end
    end  
end 

A.Listener:Add("ACTION_EVENT_DEPRECATED_MSG", "CHAT_MSG_PARTY", 		UpdateChat)
A.Listener:Add("ACTION_EVENT_DEPRECATED_MSG", "CHAT_MSG_PARTY_LEADER", 	UpdateChat)
A.Listener:Add("ACTION_EVENT_DEPRECATED_MSG", "CHAT_MSG_RAID", 			UpdateChat)
A.Listener:Add("ACTION_EVENT_DEPRECATED_MSG", "CHAT_MSG_RAID_LEADER", 	UpdateChat)


function MacroSpells(ICON, MSG)    
    return (MSG_Toggle and ICON and oMSG[ICON] == MSG) or false        
end

