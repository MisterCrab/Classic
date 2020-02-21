local TMW 								= TMW

local A 								= Action
local Listener							= A.Listener
local MakeFunctionCachedDynamic			= A.MakeFunctionCachedDynamic
local MakeFunctionCachedStatic			= A.MakeFunctionCachedStatic
local TeamCacheFriendly					= A.TeamCache.Friendly
local TeamCacheFriendlyUNITs			= TeamCacheFriendly.UNITs
local TeamCacheFriendlyGUIDs			= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs	= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs		= TeamCacheFriendly.IndexToPETs
local GetToggle							= A.GetToggle
local AuraIsValid						= A.AuraIsValid
local GetLOS							= GetLOS -- it's correct

local player 							= "player"

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_IsUnitFriendly, A_IsUnitEnemy
local A_DetermineUsableObject

Listener:Add("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit 							= A.Unit 
		A_IsUnitFriendly 				= A.IsUnitFriendly
		A_IsUnitEnemy					= A.IsUnitEnemy
		
		-- Classic only 
		A_DetermineUsableObject 		= A.DetermineUsableObject	
		-- 
		
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

local _G, type, pairs, table, math		= 
	  _G, type, pairs, table, math 
	  
--local tinsert 						= table.insert	-- Short inline expressions can be faster than function calls. t[#t+1] = 0 is faster than table.insert(t, 0)
local tremove							= table.remove 
local tsort								= table.sort 
local huge 								= math.huge
local wipe 								= _G.wipe

local  CreateFrame,    UIParent			= 
	_G.CreateFrame, _G.UIParent
	  
local UnitGUID, UnitIsUnit 				= 
	  UnitGUID, UnitIsUnit

local Frame 							= CreateFrame("Frame", "TargetColor", UIParent)
Frame:SetBackdrop(nil)
Frame:SetFrameStrata("TOOLTIP")
Frame:SetToplevel(true)
Frame:SetSize(1, 1)
Frame:SetScale(1)
Frame:SetPoint("TOPLEFT", 442, 0)
Frame.texture = Frame:CreateTexture(nil, "TOOLTIP")
Frame.texture:SetAllPoints(true)
Frame.texture:SetColorTexture(0, 0, 0, 1.0)
local Frametexture 						= Frame.texture
local None, healingTarget, healingTargetGUID, healingTargetDelay = "None", "None", "None", 0

local function sort_incDMG(x, y)
	return x.incDMG > y.incDMG
end

local function sort_HP(x, y) 
	return x.HP < y.HP 
end

local function sort_AHP(x, y) 
	return x.AHP > y.AHP 
end

-- [[ Classic Priest Locals ]]
local PR 

-- [[ Classic Paladin Locals ]]
local BlessingofProtectionUnits, BlessingofSacrificeUnits, BlessingofFreedomUnits, DispelUnits

-- [[ Data ]]
local HealingEngine 					= {
	IsRunning							= false,
	QueueOrder							= {},
	Members  							= {		
		ALL 							= {},
		TANK 							= {},
		DAMAGER 						= {},
		HEALER 							= {},
		RAID 							= {},
		MOSTLYINCDMG 					= {},
		-- [[ Classic relative only ]]
		TANKANDPARTY 					= {},
		PARTY 							= {},
		-- 
		Wipe 							= function(self)
			for k in pairs(self) do 
				if k ~= "Wipe" then 
					wipe(self[k])	
				end 
			end 		
		end,
	},
	Frequency 							= {
		Actual 							= {},
		Temp 							= {},
		Wipe 							= function(self)
			for k in pairs(self) do 
				if k ~= "Wipe" then 
					wipe(self[k])	
				end 
			end 		
		end,
	},
	CustomPerform						= {},
}

local HealingEngineQueueOrder			= HealingEngine.QueueOrder
local HealingEngineMembers 				= HealingEngine.Members
local HealingEngineMembersALL			= HealingEngineMembers.ALL
local HealingEngineMembersTANK			= HealingEngineMembers.TANK
local HealingEngineMembersDAMAGER		= HealingEngineMembers.DAMAGER
local HealingEngineMembersHEALER		= HealingEngineMembers.HEALER
local HealingEngineMembersRAID			= HealingEngineMembers.RAID
local HealingEngineMembersTANKANDPARTY	= HealingEngineMembers.TANKANDPARTY
local HealingEngineMembersPARTY			= HealingEngineMembers.PARTY
local HealingEngineMembersMOSTLYINCDMG	= HealingEngineMembers.MOSTLYINCDMG
local HealingEngineFrequency 			= HealingEngine.Frequency
local HealingEngineFrequencyActual		= HealingEngineFrequency.Actual
local HealingEngineFrequencyTemp		= HealingEngineFrequency.Temp
local HealingEngineCustomPerform 		= HealingEngine.CustomPerform

local function CalculateHP(unitID)	
    local incomingheals 				= A_Unit(unitID):GetIncomingHeals()
	local cHealth, mHealth 				= A_Unit(unitID):Health(), A_Unit(unitID):HealthMax()
	
	if mHealth <= 0 then 
		mHealth = 0 
	end 
	
    local PercentWithIncoming 			= 100 * (cHealth + incomingheals) / mHealth
    local ActualWithIncoming 			= mHealth - (cHealth + incomingheals)
	
    return PercentWithIncoming, ActualWithIncoming, cHealth, mHealth
end

local function CanHeal(unitID, unitGUID)
    return 
		A_Unit(unitID):InRange()
		and A_Unit(unitID):IsConnected()
		--and A_Unit(unitID):CanCooperate(player)
		and not A_Unit(unitID):IsCharmed()			
		and not A_Unit(unitID):InLOS(unitGUID) 
		and not A_Unit(unitID):IsDead()
		and (A.IsInPvP or not A_Unit(unitID):IsEnemy())
end

local function PerformByProfileHP(member, memberhp, membermhp, DMG)
	-- Enable specific instructions by profile 
	if not A.IsBasicProfile then 
		if A.IsGGLprofile then 
			if A.PlayerClass == "PRIEST" then 
				if not PR then 
					PR = A.PRIEST
				end 
				
				if PR then 
					if GetToggle(2, "PreParePOWS") and PR.PowerWordShield:IsReady(member, nil, nil, true, nil) and A_Unit(member):HasDeBuffs(PR.WeakenedSoul.ID) == 0 and A_Unit(member):HasBuffs(PR.PowerWordShield.ID) == 0 then 
						memberhp = 50
					elseif GetToggle(2, "PrePareRenew") and A_Unit(member):HasBuffs(PR.Renew.ID, true) == 0 then 
						local Renew = A_DetermineUsableObject(member, nil, nil, true, nil, PR.Renew, PR.Renew9, PR.Renew8, PR.Renew7, PR.Renew6, PR.Renew5, PR.Renew4, PR.Renew3, PR.Renew2, PR.Renew1)
						if Renew then 
							memberhp = 50					
						end 							
					end 
					
					-- Dispels
					if (not A.IsInPvP or not UnitIsUnit(player, member)) and (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) then 
						if ((AuraIsValid(member, "UseDispel", "Magic") or AuraIsValid(member, "UsePurge", "PurgeFriendly")) and PR.DispelMagic:IsReady(member, nil, nil, true))
						or (A_Unit(member):HasBuffs(PR.AbolishDisease.ID) == 0 and AuraIsValid(member, "UseDispel", "Disease") and (PR.AbolishDisease:IsReady(member, nil, nil, true) or PR.CureDisease:IsReady(member, nil, nil, true)))
						then 
							HealingEngineQueueOrder.Dispel = true 
							if A_Unit(member):IsHealer() then 									
								if UnitIsUnit(player, member) then 
									memberhp = memberhp - 25
								else 
									memberhp = memberhp - 60	
								end 
							else 
								memberhp = memberhp - 40	
							end  
						end 							
					end 
				end 
			end

			if A.PlayerClass == "PALADIN" and A.PALADIN then 
				-- [#1] Blessing of Protection
				if not BlessingofProtectionUnits then 
					BlessingofProtectionUnits = GetToggle(2, "BlessingofProtectionUnits")
				end 
				if not HealingEngineQueueOrder.BlessingofProtection and BlessingofProtectionUnits[5] and BlessingofProtectionUnits[4] and A.IsAbleBoP(member, true) then 
					HealingEngineQueueOrder.BlessingofProtection = true
					memberhp = memberhp - 60
				end 
					
				-- [#2] Cleanse / Purify
				if not DispelUnits then 
					DispelUnits = GetToggle(2, "DispelUnits")
				end 
				if not HealingEngineQueueOrder.BlessingofProtection and (not A.IsInPvP or not UnitIsUnit(player, member)) and (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and DispelUnits[5] and DispelUnits[4] and A.IsAbleDispel(member, true) then
					HealingEngineQueueOrder.Dispel = true 
					if A_Unit(member):IsHealer() then 									
						if UnitIsUnit(player, member) then 
							memberhp = memberhp - 25
						else 
							memberhp = memberhp - 60	
						end 
					else 
						memberhp = memberhp - 40	
					end  
				end 
				
				-- [#3] Blessing of Sacrifice
				if not BlessingofSacrificeUnits then 
					BlessingofSacrificeUnits = GetToggle(2, "BlessingofSacrificeUnits")
				end 
				if not HealingEngineQueueOrder.BlessingofProtection and not HealingEngineQueueOrder.BlessingofSacrifice and not HealingEngineQueueOrder.Dispel and BlessingofSacrificeUnits[5] and BlessingofSacrificeUnits[4] and A.IsAbleBoS(member, true) then 
					HealingEngineQueueOrder.BlessingofSacrifice = true 
					memberhp = 25
				end 	
				
				-- [#4] Blessing of Freedom		
				if not BlessingofFreedomUnits then 
					BlessingofFreedomUnits = GetToggle(2, "BlessingofFreedomUnits")
				end 
				if not HealingEngineQueueOrder.BlessingofProtection and not HealingEngineQueueOrder.BlessingofSacrifice and not HealingEngineQueueOrder.BlessingofFreedom and not HealingEngineQueueOrder.Dispel and BlessingofFreedomUnits[5] and BlessingofFreedomUnits[4] and A.IsAbleBoF(member, true) then 
					HealingEngineQueueOrder.BlessingofFreedom = true 
					memberhp = 50
				end 	

				-- [#5] Blessing Buff 
				if not HealingEngineQueueOrder.BlessingofProtection and not HealingEngineQueueOrder.BlessingofSacrifice and not HealingEngineQueueOrder.BlessingofFreedom and not HealingEngineQueueOrder.Dispel and not HealingEngineQueueOrder.BlessingBuff and ((A.IsInPvP and GetToggle(2, "BlessingBuffHealingEnginePvP")) or (not A.IsInPvP and GetToggle(2, "BlessingBuffHealingEnginePvE"))) and A.IsAbleBlessingBuff(member, true) then 
					HealingEngineQueueOrder.BlessingBuff = true 
					memberhp = memberhp - 10
				end 			 
			end 
		elseif A.IsInitialized and HealingEngineCustomPerform[A.CurrentProfile] then 
			memberhp = HealingEngineCustomPerform[A.CurrentProfile](member, memberhp, membermhp, DMG)
		end 
	end 
	
	return memberhp
end 

local function OnUpdate(MODE, useActualHP)   
	local group 				= TeamCacheFriendly.Type
    local ActualHP 				= useActualHP or false
	wipe(HealingEngineQueueOrder)
	HealingEngineMembers:Wipe()
	
    if group ~= "raid" then 
		local pHP, aHP, _, mHP 	= CalculateHP(player)
		local DMG 				= A_Unit(player):GetRealTimeDMG() 
		pHP				 		= PerformByProfileHP(player, pHP, mHP, DMG)
        HealingEngineMembersALL[#HealingEngineMembersALL + 1]									=	{ Unit = player, GUID = TeamCacheFriendlyUNITs.player or UnitGUID(player), HP = pHP, AHP = aHP, isPlayer = true, incDMG = DMG } 
    end 
            
	if not group then 
		return 
	end 
	
    for i = 1, TeamCacheFriendly.MaxSize do
        local member 							= TeamCacheFriendlyIndexToPLAYERs[i]
        local memberGUID 						= member and TeamCacheFriendlyUNITs[member]

		if memberGUID then 
			local memberhp, memberahp, _, membermhp = CalculateHP(member)
			-- Note: We can't use CanHeal here because it will take not all units results may be wrong
			HealingEngineFrequencyTemp.MAXHP 	= (HealingEngineFrequencyTemp.MAXHP or 0) + membermhp 
			HealingEngineFrequencyTemp.AHP 		= (HealingEngineFrequencyTemp.AHP   or 0) + memberahp
			
			-- Party/Raid
			if membermhp > 0 and CanHeal(member, memberGUID) then
				local DMG = A_Unit(member):GetRealTimeDMG() 
				local Actual_DMG = DMG
				
				-- Stop decrease predict HP if offset for DMG more than 15% of member's HP
				local DMG_offset = membermhp * 0.15
				if DMG > DMG_offset then 
					DMG = DMG_offset
				end
				
				-- Checking if Member has threat
				local threat = A_Unit(member):IsTanking()
				if threat then
					memberhp = memberhp - 5
				end            
				
				memberhp = PerformByProfileHP(member, memberhp, membermhp, DMG)
				
				-- Misc: Sort by Roles 			
				if A_Unit(member):IsTank() then
					memberhp = memberhp - 2
					
					if MODE == "TANK" then 
						HealingEngineMembersTANK[#HealingEngineMembersTANK + 1] 				= 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }						
					elseif MODE == "TANKANDPARTY" then 					
						HealingEngineMembersTANKANDPARTY[#HealingEngineMembersTANKANDPARTY + 1] =	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG } 
					elseif MODE == "PARTY" and A_Unit(member):InParty() then 					
						HealingEngineMembersPARTY[#HealingEngineMembersPARTY + 1] 				= 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }		
					end 
				elseif A_Unit(member):IsHealer() then                
					if UnitIsUnit(player, member) and memberhp < 95 then 
						if A.IsInPvP and A.Zone == "pvp" and A_Unit(player):IsFocused(0) then 
							memberhp = memberhp - 20
						else 
							memberhp = memberhp - 2
						end 
					else 
						memberhp = memberhp + 2
					end
					
					if MODE == "HEALER" then 
						HealingEngineMembersHEALER[#HealingEngineMembersHEALER + 1] 			=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG } 
					elseif MODE == "RAID" then 	
						HealingEngineMembersRAID[#HealingEngineMembersRAID + 1] 				= 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG } 
					elseif MODE == "TANKANDPARTY" and A_Unit(member):InParty() then 					
						HealingEngineMembersTANKANDPARTY[#HealingEngineMembersTANKANDPARTY + 1]	=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif MODE == "PARTY" and A_Unit(member):InParty() then 					
						HealingEngineMembersPARTY[#HealingEngineMembersPARTY + 1]				= 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					end 				 
				else 
					memberhp = memberhp - 1
					
					if MODE == "DAMAGER" then 
						HealingEngineMembersDAMAGER[#HealingEngineMembersDAMAGER + 1] 			=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif MODE == "RAID" then  
						HealingEngineMembersRAID[#HealingEngineMembersRAID + 1]					=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif MODE == "TANKANDPARTY" and A_Unit(member):InParty() then 					
						HealingEngineMembersTANKANDPARTY[#HealingEngineMembersTANKANDPARTY + 1]	= 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif MODE == "PARTY" and A_Unit(member):InParty() then 					
						HealingEngineMembersPARTY[#HealingEngineMembersPARTY + 1]				=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					end			 
				end

				HealingEngineMembersALL[#HealingEngineMembersALL + 1]							=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
			end        
			
			-- Pets 
			if GetToggle(1, "HE_Pets") then
				local memberpet 										= TeamCacheFriendlyIndexToPETs[i]
				local memberpetGUID 									= memberpet and TeamCacheFriendlyUNITs[memberpet]
				
				if memberpetGUID then 
					local memberpethp, memberpetahp, _, memberpetmhp 	= CalculateHP(memberpet) 
					
					-- Note: We can't use CanHeal here because it will take not all units results could be wrong
					HealingEngineFrequencyTemp.MAXHP 					= (HealingEngineFrequencyTemp.MAXHP or 0) + memberpetmhp 
					HealingEngineFrequencyTemp.AHP 	 					= (HealingEngineFrequencyTemp.AHP   or 0) + memberpetahp			
					
					if memberpetmhp > 0 and CanHeal(memberpet, memberpetGUID) then 
						if A_Unit(player):CombatTime() > 0 then                
							memberpethp  = memberpethp * 1.35
							memberpetahp = memberpetahp * 1.35
						else                
							memberpethp  = memberpethp * 1.15
							memberpetahp = memberpetahp * 1.15
						end
						
						HealingEngineMembersALL[#HealingEngineMembersALL + 1] 					=	{ Unit = memberpet, GUID = memberpetGUID, HP = memberpethp, AHP = memberpetahp, isPlayer = false, incDMG = A_Unit(memberpet):GetRealTimeDMG() } 
					end 
				end 
			end
		end 
    end
    
    -- Frequency (Summary)
    if HealingEngineFrequencyTemp.MAXHP and HealingEngineFrequencyTemp.MAXHP > 0 then 
		HealingEngineFrequencyActual[#HealingEngineFrequencyActual + 1] = { 	                
                -- Max Group HP
                MAXHP	= HealingEngineFrequencyTemp.MAXHP, 
                -- Current Group Actual HP
                AHP 	= HealingEngineFrequencyTemp.AHP,
				-- Current Time on this record 
				TIME 	= TMW.time, 
        }
		
		-- Clear temp by old record
        wipe(HealingEngineFrequencyTemp)
		
		-- Clear actual from older records
        for i = #HealingEngineFrequencyActual, 1, -1 do             
            -- Remove data longer than 5 seconds 
            if TMW.time - HealingEngineFrequencyActual[i].TIME > 10 then 
                tremove(HealingEngineFrequencyActual, i)                
            end 
        end 
    end 
    
	-- Sort for next target / incDMG (Summary)
    if #HealingEngineMembersALL > 1 then 
        -- Sort by most damage receive
		for i = 1, #HealingEngineMembersALL do 
			HealingEngineMembersMOSTLYINCDMG[#HealingEngineMembersMOSTLYINCDMG + 1]				=	{ Unit = HealingEngineMembersALL[i].Unit, GUID = HealingEngineMembersALL[i].GUID, incDMG = HealingEngineMembersALL[i].incDMG }
		end 
        tsort(HealingEngineMembersMOSTLYINCDMG, sort_incDMG)
        
        -- Sort by Percent or Actual
        if not ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].HP then 
					tsort(v, sort_HP)
				end 
			end 		
        elseif ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].AHP then 
					tsort(v, sort_AHP)
				end 
			end 		
        end
    end 
end

local function SetHealingTarget(MODE)
	if #HealingEngineMembers[MODE] > 0 and HealingEngineMembers[MODE][1].HP < 99 then 
		healingTarget 		= HealingEngineMembers[MODE][1].Unit
		healingTargetGUID 	= HealingEngineMembers[MODE][1].GUID
		return 
	end 	 

    healingTarget 	  		= None
    healingTargetGUID 		= None
end

local function SetColorTarget(isForced)
    --Default 
    Frametexture:SetColorTexture(0, 0, 0, 1.0)   
	
	if not isForced then 
		--If we have no one to heal
		if healingTarget == nil or healingTarget == None or healingTargetGUID == nil or healingTargetGUID == None then
			return
		end	
		
		--If we have a mouseover friendly unit
		if A.IsInitialized and A_IsUnitFriendly("mouseover") then       
			return
		end
		
		--If we have a current target equiled to suggested or he is a boss
		if A_Unit("target"):IsExists() and (healingTargetGUID == UnitGUID("target") or A_Unit("target"):IsBoss()) then
			return
		end     
		
		--If we decided to perform damage
		if A.IsInitialized and (A_IsUnitEnemy("mouseover") or A_IsUnitEnemy("target")) then 
			return 
		end 
    end 
	
    --Party
    if healingTarget == "party1" then
        Frametexture:SetColorTexture(0.345098, 0.239216, 0.741176, 1.0)
        return
    end
    if healingTarget == "party2" then
        Frametexture:SetColorTexture(0.407843, 0.501961, 0.086275, 1.0)
        return
    end
    if healingTarget == "party3" then
        Frametexture:SetColorTexture(0.160784, 0.470588, 0.164706, 1.0)
        return
    end
    if healingTarget == "party4" then
        Frametexture:SetColorTexture(0.725490, 0.572549, 0.647059, 1.0)
        return
    end   
    
    --PartyPET
    if healingTarget == "partypet1" then
        Frametexture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
        return
    end
    if healingTarget == "partypet2" then
        Frametexture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
        return
    end
    if healingTarget == "partypet3" then
        Frametexture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
        return
    end
    if healingTarget == "partypet4" then
        Frametexture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
        return
    end        
    
    --Raid
    if healingTarget == "raid1" then
        Frametexture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
        return
    end
    if healingTarget == "raid2" then
        Frametexture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
        return
    end
    if healingTarget == "raid3" then
        Frametexture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
        return
    end
    if healingTarget == "raid4" then
        Frametexture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
        return
    end
    if healingTarget == "raid5" then
        Frametexture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
        return
    end
    if healingTarget == "raid6" then
        Frametexture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid7" then
        Frametexture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
        return
    end
    if healingTarget == "raid8" then
        Frametexture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid9" then
        Frametexture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid10" then
        Frametexture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
        return
    end
    if healingTarget == "raid11" then
        Frametexture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
        return
    end
    if healingTarget == "raid12" then
        Frametexture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid13" then
        Frametexture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
        return
    end
    if healingTarget == "raid14" then
        Frametexture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid15" then
        Frametexture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
        return
    end
    if healingTarget == "raid16" then
        Frametexture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
        return
    end
    if healingTarget == "raid17" then
        Frametexture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
        return
    end
    if healingTarget == "raid18" then
        Frametexture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
        return
    end
    if healingTarget == "raid19" then
        Frametexture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
        return
    end
    if healingTarget == "raid20" then
        Frametexture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
        return
    end
    if healingTarget == "raid21" then
        Frametexture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
        return
    end
    if healingTarget == "raid22" then
        Frametexture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
        return
    end
    if healingTarget == "raid23" then
        Frametexture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
        return
    end
    if healingTarget == "raid24" then
        Frametexture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
        return
    end
    if healingTarget == "raid25" then
        Frametexture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
        return
    end
    if healingTarget == "raid26" then
        Frametexture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
        return
    end
    if healingTarget == "raid27" then
        Frametexture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
        return
    end
    if healingTarget == "raid28" then
        Frametexture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
        return
    end
    if healingTarget == "raid29" then
        Frametexture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
        return
    end
    if healingTarget == "raid30" then
        Frametexture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
        return
    end
    if healingTarget == "raid31" then
        Frametexture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
        return
    end
    if healingTarget == "raid32" then
        Frametexture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
        return
    end
    if healingTarget == "raid33" then
        Frametexture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
        return
    end
    if healingTarget == "raid34" then
        Frametexture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
        return
    end    
    if healingTarget == "raid35" then
        Frametexture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
        return
    end
    if healingTarget == "raid36" then
        Frametexture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
        return
    end
    if healingTarget == "raid37" then
        Frametexture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
        return
    end
    if healingTarget == "raid38" then
        Frametexture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
        return
    end
    if healingTarget == "raid39" then
        Frametexture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid40" then
        Frametexture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
        return
    end
    if healingTarget == "raidpet1" then
        Frametexture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet2" then
        Frametexture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
        return
    end
    if healingTarget == "raidpet3" then
        Frametexture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
        return
    end
    if healingTarget == "raidpet4" then
        Frametexture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet5" then
        Frametexture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
        return
    end
    if healingTarget == "raidpet6" then
        Frametexture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet7" then
        Frametexture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
        return
    end
    if healingTarget == "raidpet8" then
        Frametexture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
        return
    end
    if healingTarget == "raidpet9" then
        Frametexture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
        return
    end
    if healingTarget == "raidpet10" then
        Frametexture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
        return
    end
    if healingTarget == "raidpet11" then
        Frametexture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
        return
    end
    if healingTarget == "raidpet12" then
        Frametexture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
        return
    end
    if healingTarget == "raidpet13" then
        Frametexture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
        return
    end
    if healingTarget == "raidpet14" then
        Frametexture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
        return
    end
    if healingTarget == "raidpet15" then
        Frametexture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
        return
    end
    if healingTarget == "raidpet16" then
        Frametexture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
        return
    end
    if healingTarget == "raidpet17" then
        Frametexture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
        return
    end
    if healingTarget == "raidpet18" then
        Frametexture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
        return
    end
    if healingTarget == "raidpet19" then
        Frametexture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
        return
    end
    if healingTarget == "raidpet20" then
        Frametexture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
        return
    end
    if healingTarget == "raidpet21" then
        Frametexture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
        return
    end
    if healingTarget == "raidpet22" then
        Frametexture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
        return
    end
    if healingTarget == "raidpet23" then
        Frametexture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
        return
    end
    if healingTarget == "raidpet24" then
        Frametexture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
        return
    end
    if healingTarget == "raidpet25" then
        Frametexture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
        return
    end
    if healingTarget == "raidpet26" then
        Frametexture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet27" then
        Frametexture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
        return
    end
    if healingTarget == "raidpet28" then
        Frametexture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet29" then
        Frametexture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
        return
    end
    if healingTarget == "raidpet30" then
        Frametexture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
        return
    end
    if healingTarget == "raidpet31" then
        Frametexture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
        return
    end
    if healingTarget == "raidpet32" then
        Frametexture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
        return
    end
    if healingTarget == "raidpet33" then
        Frametexture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
        return
    end
    if healingTarget == "raidpet34" then
        Frametexture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet35" then
        Frametexture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
        return
    end
    if healingTarget == "raidpet36" then
        Frametexture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
        return
    end
    if healingTarget == "raidpet37" then
        Frametexture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
        return
    end
    if healingTarget == "raidpet38" then
        Frametexture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
        return
    end
    if healingTarget == "raidpet39" then
        Frametexture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
        return
    end
    if healingTarget == "raidpet40" then
        Frametexture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
        return
    end
    
    --Stuff
    if healingTarget == player then
        Frametexture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
        return
    end
    if healingTarget == "focus" then
        Frametexture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
        return
    end
    --[[
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
        return
    end   
    if healingTarget == PLACEHOLDER then --was party5
        Frametexture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
        return
    end     
    if healingTarget == PLACEHOLDER then --was party5pet
        Frametexture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
        return
    end
    ]]
end

local function UpdateLOS()
	if A.IsInitialized and A_Unit("target"):IsExists() and not A_IsUnitFriendly("mouseover") then
		GetLOS("target")
	end 
end

local function WipeFrequencyActual()
	wipe(HealingEngineFrequencyActual)
end 

local function HealingEngineInit()
	if A.IamHealer or GetToggle(1, "HE_AnyRole") then 
		if not HealingEngine.IsRunning then 
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED", 	UpdateLOS			)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED", 		WipeFrequencyActual	)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED", 	WipeFrequencyActual	)
			Frame:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = (self.elapsed or 0) + elapsed   
				local INTV = TMW.UPD_INTV and TMW.UPD_INTV > 0.3 and TMW.UPD_INTV or 0.3
				if self.elapsed > INTV then 
					local ROLE = GetToggle(1, "HE_Toggle") or "ALL"
					
					OnUpdate(ROLE) 
					
					if TMW.time > healingTargetDelay then 
						SetHealingTarget(ROLE) 
						SetColorTarget()   
					end 
					
					UpdateLOS() 
					
					self.elapsed = 0
				end			
			end)
			HealingEngine.IsRunning = true 
		end 
	elseif HealingEngine.IsRunning then
		Frame:SetScript("OnUpdate", nil)
		Frametexture:SetColorTexture(0, 0, 0, 1.0)  
		HealingEngineMembers:Wipe()
		HealingEngineFrequency:Wipe()
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED")
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED")
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED")	
		HealingEngine.IsRunning = false 
	end 
end 

TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 				HealingEngineInit) 
TMW:RegisterCallback("TMW_ACTION_HEALINGENGINE_ANY_ROLE", 						HealingEngineInit) 
TMW:RegisterCallback("TMW_ACTION_ENTERING", 									HealingEngineInit) 

--- ============================= API ==============================
--- API valid only for healer specializations or if [1] Role has set fixed to HEALER
--- Members are depend on GetToggle(1, "HE_Pets") variable 

--- Globals
A.HealingEngine = { Data = HealingEngine }

--- Data Controller 
function A.HealingEngine.SortMembers(useActualHP)
	-- Manual re-sort table 
	if #HealingEngineMembersALL > 1 then
		for i = 1, #HealingEngineMembersALL do 
			HealingEngineMembersMOSTLYINCDMG[#HealingEngineMembersMOSTLYINCDMG + 1]				=	{ Unit = HealingEngineMembersALL[i].Unit, GUID = HealingEngineMembersALL[i].GUID, incDMG = HealingEngineMembersALL[i].incDMG }
		end 
        tsort(HealingEngineMembersMOSTLYINCDMG, sort_incDMG)  
		
		if not ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].HP then 
					tsort(v, sort_HP)
				end 
			end 		
        elseif ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].AHP then 
					tsort(v, sort_AHP)
				end 
			end 		
        end
	end 
end 

function A.HealingEngine.SetPerformByProfileHP(func)
	-- Note: Only for non GGL profiles and Action initializated
	-- Argument 'func' must be function which will return number (health percent), this function accepts same arguments what will has PerformByProfileHP and fires for each member through enumeration-loop, at the end of loop all members will be sorted by default (refference to A.HealingEngine.SortMembers)
	-- [1] member is @string refference for unitID 
	-- [2] memberhp is @number refference for health percent of member 
	-- [3] membermhp is @number refference for max health non-percent of member 
	-- [4] DMG is @number refference for Unit(member):GetRealTimeDMG() indicates for real time incoming damage, it has limit 15% of the max health per second and can't be higher
	-- Usage: 
	--[[
		local A 						= Action 
		local Unit 						= A.Unit
		local HealingEngine				= A.HealingEngine
		local HealingEngineQueueOrder 	= HealingEngine.Data.QueueOrder -- this is very useful @table which resets every full enumeration-loop (see example of use below)
		HealingEngine.SetPerformByProfileHP(
			function(member, memberhp, membermhp, DMG)
				if A.PlayerSpec == "PRIEST" then 
					if not HealingEngineQueueOrder.usePWS and Unit(member):HasBuffs(18, true) == 0 and Unit(member):HasDeBuffs("WeakenedSoul DeBuff") == 0 then 
						HealingEngineQueueOrder.usePWS = true -- that will skips check :HasBuffs(18, true) for other members and save performance because you can use shield only on one unit per GCD but loop refrehes every ~0.3 sec
						memberhp = memberhp - 20
						if memberhp < 40 then 
							memberhp = 40 
						end 
					end 
				end 
				
				return memberhp
			end 
		end)
	]]
	HealingEngineCustomPerform[A.CurrentProfile] = func 
end 

--- SetTarget Controller 
function A.HealingEngine.SetTargetMostlyIncDMG(delay)
	if #HealingEngineMembersMOSTLYINCDMG > 0 then 
		healingTargetDelay 		= TMW.time + (delay or 2)
		if UnitGUID("target") ~= healingTargetGUID then 
			healingTargetGUID 	= HealingEngineMembersMOSTLYINCDMG[1].GUID
			healingTarget		= HealingEngineMembersMOSTLYINCDMG[1].Unit
			SetColorTarget(true)
		end 
	end 
end 

function A.HealingEngine.SetTarget(unitID, delay)
	-- Sets in HealingEngine specified unitID with delay which will prevent reset target during next few seconds 
	local GUID = TeamCacheFriendlyUNITs[unitID] or UnitGUID(unitID)
	if GUID then 
		healingTargetDelay 		= TMW.time + (delay or 2)
		if GUID ~= healingTargetGUID and #HealingEngineMembersALL > 0 then 
			healingTargetGUID 	= GUID
			healingTarget		= TeamCacheFriendlyGUIDs[GUID] or unitID
			SetColorTarget(true)
		end 
	end 
end 

--- Group Controller 
function A.HealingEngine.GetMembersAll()
	-- @return table 
	return HealingEngineMembersALL 
end 

function A.HealingEngine.GetMembersByMode(MODE)
	-- @return table 
	local mode = MODE or GetToggle(1, "HE_Toggle") or "ALL"
	return HealingEngineMembers[mode] 
end 

function A.HealingEngine.GetBuffsCount(ID, duration, source, byID)
	-- @return number 	
	-- Only players 
    local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if HealingEngineMembersALL[i].isPlayer and A_Unit(HealingEngineMembersALL[i].Unit):HasBuffs(ID, source, byID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetDeBuffsCount(ID, duration, source, byID)
	-- @return number 	
	-- Only players 
    local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if HealingEngineMembersALL[i].isPlayer and A_Unit(HealingEngineMembersALL[i].Unit):HasDeBuffs(ID, source, byID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetHealth()
	-- @return number 
	-- Return actual group health 
	if #HealingEngineFrequencyActual > 0 then 
		return HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP
	end 
	return huge
end 

function A.HealingEngine.GetHealthAVG() 
	-- @return number 
	-- Return current percent (%) of the group health
	if #HealingEngineFrequencyActual > 0 then 
		return HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
	end 
	return 100  
end 

function A.HealingEngine.GetHealthFrequency(timer)
	-- @return number 
	-- Return percent (%) of the group HP changed during lasts 'timer'. Positive (+) is HP lost, Negative (-) is HP gain, 0 - nothing is not changed 
    local total, counter = 0, 0

    if #HealingEngineFrequencyActual > 1 then 
        for i = 1, #HealingEngineFrequencyActual - 1 do 
            -- Getting history during that time rate
            if TMW.time - HealingEngineFrequencyActual[i].TIME <= timer then 
                counter = counter + 1
                total 	= total + HealingEngineFrequencyActual[i].AHP
            end 
        end        
    end 
	
	if total > 0 then           
		total = (HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP) - (total / counter * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP)
	end  	
	
    return total 
end 
A.HealingEngine.GetHealthFrequency = MakeFunctionCachedDynamic(A.HealingEngine.GetHealthFrequency)

function A.HealingEngine.GetIncomingDMG()
	-- @return number, number 
	-- Return REALTIME actual: total - group HP lose per second, avg - average unit HP lose per second
	local total, avg = 0, 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            total = total + HealingEngineMembersALL[i].incDMG
        end
		
		avg = total / #HealingEngineMembersALL
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingDMG = MakeFunctionCachedStatic(A.HealingEngine.GetIncomingDMG)

function A.HealingEngine.GetIncomingHPS()
	-- @return number , number
	-- Return PERSISTENT actual: total - group HP gain per second, avg - average unit HP gain per second 
	local total, avg = 0, 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            total = total + A_Unit(HealingEngineMembersALL[i].Unit):GetHEAL()
        end
		
		avg = total / #HealingEngineMembersALL
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingHPS = MakeFunctionCachedStatic(A.HealingEngine.GetIncomingHPS)

function A.HealingEngine.GetIncomingDMGAVG()
	-- @return number  
	-- Return REALTIME average percent group HP lose per second 
    if #HealingEngineFrequencyActual > 0 then 
		return A.HealingEngine.GetIncomingDMG() * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
    end 
    return 0 
end

function A.HealingEngine.GetIncomingHPSAVG()
	-- @return number  
	-- Return REALTIME average percent group HP gain per second 
    if #HealingEngineFrequencyActual > 0 then 
		return A.HealingEngine.GetIncomingHPS() * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
    end 
    return 0 
end 

function A.HealingEngine.GetTimeToFullDie()
	-- @return number 
	-- Returns AVG time to die all group members 
	local total = 0
	
    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
			total = total + A_Unit(HealingEngineMembersALL[i].Unit):TimeToDie()
        end
		return total / #HealingEngineMembersALL
	else 
		return huge 
    end 
end 

function A.HealingEngine.GetTimeToDieUnits(timer)
	-- @return number 
	local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if A_Unit(HealingEngineMembersALL[i].Unit):TimeToDie() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToDieMagicUnits(timer)
	-- @return number 
	local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if A_Unit(HealingEngineMembersALL[i].Unit):TimeToDieMagic() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToFullHealth()
	-- @return number
	if #HealingEngineFrequencyActual > 0 then 
		local HPS = A.HealingEngine.GetIncomingHPS()
		if HPS > 0 then
			return (HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP - HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP) / HPS
		end 
	end 
	return 0 
end 

function A.HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit)
	-- @return number 
	-- This is easy template to known how many people minimum required be to heal by AoE with different group size or if some units out of range or in cyclone and etc..
	-- More easy to figure - which minimum units require if available group members <= 1 / <= 3 / <= 5 or > 5
	local members = #HealingEngineMembersALL
	return 	( members <= 1 and 1 ) or 
			( members <= 3 and members ) or 
			( members <= 5 and members - (fullPartyMinus or 0) ) or 
			(
				members > 5 and 
				(
					(
						raidLimit ~= nil and
						(
							(
								members >= raidLimit and 
								raidLimit
							) or 
							(
								members < raidLimit and 
								members
							)
						)
					) or 
					(
						raidLimit == nil and 
						members
					)
				)
			)
end 

function A.HealingEngine.GetBelowHealthPercentercentUnits(pHP, range)
	-- @return number 
	-- Return how much members below percent of health with range (range can be nil)
	local total = 0 

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if (not range or A_Unit(HealingEngineMembersALL[i].Unit):CanInterract(range)) and HealingEngineMembersALL[i].HP <= pHP then
                total = total + 1
            end
        end
    end 
	return total 
end 

function A.HealingEngine.HealingByRange(range, object, inParty, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified range with spell
	local total = 0

	if #HealingEngineMembersALL > 0 then 		
		for i = 1, #HealingEngineMembersALL do 
			if 	(not isMelee or A_Unit(HealingEngineMembersALL[i].Unit):IsMelee()) and 
				(not inParty or A_Unit(HealingEngineMembersALL[i].Unit):InParty()) and 
				A_Unit(HealingEngineMembersALL[i].Unit):CanInterract(range) and
				object:PredictHeal(HealingEngineMembersALL[i].Unit, nil, HealingEngineMembersALL[i].GUID)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

function A.HealingEngine.HealingBySpell(object, inParty, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified spell 
	local total = 0

	if #HealingEngineMembersALL > 0 then 		
		for i = 1, #HealingEngineMembersALL do 
			if 	(not isMelee or A_Unit(HealingEngineMembersALL[i].Unit):IsMelee()) and 
				(not inParty or A_Unit(HealingEngineMembersALL[i].Unit):InParty()) and 
				object:IsInRange(HealingEngineMembersALL[i].Unit) and 
				object:PredictHeal(HealingEngineMembersALL[i].Unit, nil, HealingEngineMembersALL[i].GUID)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

--- Unit Controller 
function A.HealingEngine.IsMostlyIncDMG(unitID)
	-- @return boolean, number (realtime incoming damage)	
	if #HealingEngineMembersMOSTLYINCDMG > 0 then 
		return UnitIsUnit(unitID, HealingEngineMembersMOSTLYINCDMG[1].Unit), HealingEngineMembersMOSTLYINCDMG[1].incDMG
	end 
	return false, 0
end 

function A.HealingEngine.GetTarget()
	return healingTarget, healingTargetGUID
end 