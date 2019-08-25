local TMW 							= TMW
local CNDT 							= TMW.CNDT
local Env 							= CNDT.Env

--local strlowerCache  				= TMW.strlowerCache
local A 							= Action
--local isEnemy						= A.Bit.isEnemy
--local isPlayer					= A.Bit.isPlayer
--local toStr 						= A.toStr
--local toNum 						= A.toNum
local InstanceInfo					= A.InstanceInfo
local TeamCache						= A.TeamCache
local Azerite 						= LibStub("AzeriteTraits")
--local Pet							= LibStub("PetLibrary")
--local LibRangeCheck  				= LibStub("LibRangeCheck-2.0")
--local SpellRange					= LibStub("SpellRange-1.0")
--local DRData 						= LibStub("DRData-1.1")

-- Toggle valid: "TANK", "DAMAGER", "HEALER", "RAID", nil (means "ALL")
_G.HE_Toggle 						= nil 
_G.HE_Pets   						= true

local type, pairs, table, wipe, huge = 
	  type, pairs, table, wipe, math.huge
	  
local UnitGUID, UnitIsUnit = 
	  UnitGUID, UnitIsUnit

A.HealingEngine 					= {}
Frame 				= CreateFrame("Frame", "TargetColor", UIParent)
Frame:SetBackdrop(nil)
Frame:SetFrameStrata("TOOLTIP")
Frame:SetToplevel(true)
Frame:SetSize(1, 1)
Frame:SetScale(1)
Frame:SetPoint("TOPLEFT", 442, 0)
Frame.texture = Frame:CreateTexture(nil, "TOOLTIP")
Frame.texture:SetAllPoints(true)
Frame.texture:SetColorTexture(0, 0, 0, 1.0)

A.HealingEngine.Members = {
	ALL = {},
	TANK = {},
	DAMAGER = {},
	HEALER = {},
	RAID = {},
	MOSTLYINCDMG = {},
}

A.HealingEngine.Frequency = {
	Actual = {},
	Temp = {},
}

function A.HealingEngine.Members:Wipe()
	for k, v in pairs(self) do 
		if type(v) == "table" then 
			wipe(self[k])	
		end 
	end 
end 

function A.HealingEngine.Frequency:Wipe()
	for k, v in pairs(self) do 
		if type(v) == "table" then 
			wipe(self[k])	
		end 
	end 
end 
	  
local Aura = {
	SmokeBomb = 76577,
} 	  

local function CalculateHP(unitID)	
    local incomingheals = A.Unit(unitID):GetIncomingHeals()
	local cHealth, mHealth = A.Unit(unitID):Health(), A.Unit(unitID):HealthMax()
	
    local PercentWithIncoming = 100 * (cHealth + incomingheals) / mHealth
    local ActualWithIncoming = mHealth - (cHealth + incomingheals)
	
    return PercentWithIncoming, ActualWithIncoming, cHealth, mHealth
end

local function CanHeal(unitID, unitGUID)
    return 
		A.Unit(unitID):InRange()
		and A.Unit(unitID):IsConnected()
		--and A.Unit(unitID):CanCooperate("player")
		and not A.Unit(unitID):IsCharmed()			
		and not A.Unit(unitID):InLOS(unitGUID) 
		and not A.Unit(unitID):IsDead()
		and 
		(
			(
				not A.IsInPvP and 
				not A.Unit(unitID):IsEnemy()
			) or 
			(
				A.IsInPvP and 
				A.Unit(unitID):DeBuffCyclone() == 0 and 
				( 
					A.Unit(unitID):HasDeBuffs(Aura.SmokeBomb) == 0 or 
					A.Unit("player"):HasDeBuffs(Aura.SmokeBomb) > 0
				)  
			)
		) 
		-- 8.2 Underwater Monstrosity - Darkest Depths (DeBuff)
		-- 2164 is The Eternal Palace  
		and ( InstanceInfo.ID ~= 2164 or A.Unit(unitID):HasDeBuffs(292127) == 0 )
end

local healingTarget, healingTargetGUID = "None", "None"
local function HealingEngine(MODE, useActualHP)   
	local mode = MODE or "ALL"
    local ActualHP = useActualHP or false
	A.HealingEngine.Members:Wipe()
	
    if TeamCache.Friendly.Type ~= "raid" then 
		local pHP, aHP, _, mHP = CalculateHP("player")
        table.insert(A.HealingEngine.Members.ALL, { Unit = "player", GUID = UnitGUID("player"), HP = pHP, AHP = aHP, isPlayer = true, incDMG = A.Unit("player"):GetRealTimeDMG() })
    end 
    
    local isQueuedDispel = false 
    local group = TeamCache.Friendly.Type
	if not group then 
		return 
	end 
	
    for i = 1, TeamCache.Friendly.Size do
        local member 							= group .. i        
        local memberhp, memberahp, _, membermhp = CalculateHP(member)
        local memberGUID 						= UnitGUID(member)

        -- Note: We can't use CanHeal here because it will take not all units results could be wrong
		A.HealingEngine.Frequency.Temp.MAXHP = (A.HealingEngine.Frequency.Temp.MAXHP or 0) + membermhp 
        A.HealingEngine.Frequency.Temp.AHP 	 = (A.HealingEngine.Frequency.Temp.AHP   or 0) + memberahp
        
        -- Party/Raid
        if CanHeal(member, memberGUID) then
            local DMG = A.Unit(member):GetRealTimeDMG() 
            local Actual_DMG = DMG
            
            -- Stop decrease predict HP if offset for DMG more than 15% of member's HP
            local DMG_offset = membermhp * 0.15
            if DMG > DMG_offset then 
                DMG = DMG_offset
            end
            
            -- Checking if Member has threat
			local threat = A.Unit(member):ThreatSituation()
            if threat >= 3 then
                memberhp = memberhp - threat
            end            
            
			-- Enable specific instructions by profile 
			if A.IsGGLprofile then 
				-- Holy Paladin 
				if A.Unit("player"):HasSpec(ACTION_CONST_PALADIN_HOLY) then                 
					if (not isQueuedDispel or A.Unit(member):IsHealer()) and Env.SpellUsable(4987) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						-- if we will have lower unit than 50% then don't dispel it
						memberhp = 50
						if A.Unit(member):IsHealer() then 
							memberhp = 25
						end
					elseif Azerite:GetRank(287268) > 0 and Env.SpellCD(20473) <= A.GetCurrentGCD() and A.Unit(member, 0.5):HasBuffs(287280, true) <= A.GetGCD() then 
						-- Glimmer of Light 
						-- Generally, prioritize players that might die in the next few seconds > non-Beaconed tank (without Glimmer buff) > Beaconed tank (without Glimmer buff) > players without the Glimmer buff
						if Env.PredictHeal("HolyShock", member) then 
							if A.Unit(member):IsTank() then 
								if A.Unit(member):HasBuffs({156910, 53563}, true) == 0 then 
									memberhp = 35
								else 
									memberhp = 45
								end 
							else 
								memberhp = memberhp - 35
							end 
						else
							memberhp = memberhp - 10
						end 
					elseif memberhp < 100 then      
						-- Beacon HPS SYSTEM + hot current ticking and total duration
						local BestowFaith1, BestowFaith2 = A.Unit(member):HasBuffs(223306, true)
						if BestowFaith1 > 0 then 
							memberhp = memberhp + ( 100 * A.GetSpellDescription(223306)[1] / membermhp )
						end 
						-- Checking if Member has Beacons on them            
						if A.Unit(member):HasBuffs({53563, 156910}, true) > 0 then
							memberhp = memberhp + ( 100 * (A.Unit("player"):GetHPS() * 0.4) / membermhp ) - ( 100 * DMG / membermhp )
						end  
					end 
				end 
				
				-- Restor Druid 
				if A.Unit("player"):HasSpec(ACTION_CONST_DRUID_RESTORATION) then 					
					if (not isQueuedDispel or A.Unit(member):IsHealer()) and Env.SpellUsable(88423) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if A.Unit(member):IsHealer() then 
							memberhp = 25
						end						
					elseif memberhp < 100 then   
						-- HOT SYSTEM: current ticking and total duration
						local Rejuvenation1, Rejuvenation2 	= A.Unit(member):HasBuffs(774, true)
						local Regrowth1, Regrowth2 			= A.Unit(member):HasBuffs(8936, true)
						local WildGrowth1, WildGrowth2		= A.Unit(member):HasBuffs(48438, true)
						local Lifebloom1, Lifebloom2 		= A.Unit(member):HasBuffs(33763, true)                
						local Germination1, Germination2 	= A.Unit(member):HasBuffs(155777, true) -- Rejuvenation Talent 
						local summup, summdmg = 0, {}
						if Rejuvenation1 > 0 then 
							summup = summup + (A.GetSpellDescription(774)[1] / Rejuvenation2 * Rejuvenation1)
							table.insert(summdmg, Rejuvenation1)
						else
							-- If current target is Tank then to prevent staying on that target we will cycle rest units 
							if healingTarget and healingTarget ~= "None" and A.Unit(healingTarget):IsTank() then 
								memberhp = memberhp - 15
							else 
								summup = summup - (A.GetSpellDescription(774)[1] * 3)
							end 
						end
						
						if Regrowth1 > 0 then 
							summup = summup + (A.GetSpellDescription(8936)[2] / Regrowth2 * Regrowth1)
							table.insert(summdmg, Regrowth1)
						end
						
						if WildGrowth1 > 0 then 
							summup = summup + (A.GetSpellDescription(48438)[1] / WildGrowth2 * WildGrowth1)
							table.insert(summdmg, WildGrowth1)                    
						end
						
						if Lifebloom1 > 0 then 
							summup = summup + (A.GetSpellDescription(33763)[1] / Lifebloom2 * Lifebloom1) 
							table.insert(summdmg, Lifebloom1)    
						end
						
						if Germination1 > 0 then -- same with Rejuvenation
							summup = summup + (A.GetSpellDescription(774)[1] / Germination2 * Germination1)
							table.insert(summdmg, Germination1)    
						end
						
						-- Get longer hot duration and predict incoming damage by that 
						table.sort(summdmg, function (x, y)
								return x > y
						end)
						
						-- Now we convert it to persistent (from value to % as HP)
						if summup > 0 then 
							-- current HP % with pre casting heal + predict hot heal - predict incoming dmg 
							memberhpHotSystem = memberhp + ( 100 * summup / membermhp ) - ( 100 * (DMG * summdmg[1]) / membermhp )
							if memberhpHotSystem < 100 then
								memberhp = memberhpHotSystem
							end
						end                    
					end
				end
				
				-- Discipline Priest
				if A.Unit("player"):HasSpec(ACTION_CONST_PRIEST_DISCIPLINE) then                 
					if (not isQueuedDispel or A.Unit(member):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if A.Unit(member):IsHealer() then 
							memberhp = 25
						end 
					elseif AtonementRenew_Toggle and A.Unit(member):HasBuffs(81749, true) <= A.GetCurrentGCD() then 				
						-- Toggle "Group Atonement/Renew﻿"
						memberhp = 50
					elseif memberhp < 100 then                    
						-- Atonement priority 
						if A.Unit(member):HasBuffs(81749, true) > 0 and Env.oPR and Env.oPR["AtonementHPS"] then 
							memberhp = memberhp + ( 100 * Env.oPR["AtonementHPS"] / membermhp )
						end 
						
						-- Absorb system 
						-- Pre pare 
						if A.Unit("player"):CombatTime() <= 5 and 
						(
							A.Unit("player"):CombatTime() > 0 or 
							(
								-- Pre shield before battle will start
								( A.Zone == "arena" or A.Zone == "pvp" ) and
								A:GetTimeSinceJoinInstance() < 120                             
							)
						) and A.Unit(member):GetAbsorb(17) == 0 then 
							memberhp = memberhp - 10
						end                     
						
						-- Toggle or PrePare combat or while Rapture always
						if HE_Absorb or A.Unit("player"):CombatTime() <= 5 or A.Unit("player"):HasBuffs(47536, true) > A.GetCurrentGCD() then 
							memberhp = memberhp + ( 100 * A.Unit(member):GetAbsorb(17) / membermhp )
						end 
					end 
				end 
				
				-- Holy Priest
				if A.Unit("player"):HasSpec(ACTION_CONST_PRIEST_HOLY) then                 
					if (not isQueuedDispel or A.Unit(member):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if A.Unit(member):IsHealer() then 
							memberhp = 25
						end  
					elseif AtonementRenew_Toggle and A.Unit(member):HasBuffs(139, true) <= A.GetCurrentGCD() then 				
						-- Toggle "Group Atonement/Renew﻿"
						memberhp = 50
					elseif memberhp < 100 then 
						if Env.UnitIsTrailOfLight(member) then 
							-- Single Rotation 
							local ST = Env.IsIconDisplay("TMW:icon:1RhherQmOw_V") or 0
							if ST == 2061 then 
								memberhp = memberhp + ( 100 * (A.GetSpellDescription(2061)[1] * 0.35) / membermhp )
							elseif ST == 2060 then 
								memberhp = memberhp + ( 100 * (A.GetSpellDescription(2060)[1] * 0.35) / membermhp )
							end 
						end 
					end 
				end 
			   
				-- Mistweaver Monk 
				if A.IsInitialized and A.Unit("player"):HasSpec(ACTION_CONST_MONK_MISTWEAVER) then 
					if (not isQueuedDispel or A.Unit(member):IsHealer()) and not UnitIsUnit("player", member) and A.AuraIsValid(member, "UseDispel", "Dispel") then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- If we will have lower unit than 50% then don't dispel it
						if A.Unit(member):IsHealer() then 
							memberhp = 25
						end 
					elseif memberhp < 100 and A.GetToggle(2, "HealingEngineAutoHot") and A[ACTION_CONST_MONK_MISTWEAVER].RenewingMist:IsReady() then 
						-- Keep Renewing Mist hots as much as it possible on cooldown
						local RenewingMist = A.Unit(member):HasBuffs(A[ACTION_CONST_MONK_MISTWEAVER].RenewingMist.ID, true)
						if RenewingMist == 0 and A[ACTION_CONST_MONK_MISTWEAVER].RenewingMist:PredictHeal("RenewingMist", member) then 
							memberhp = memberhp - 40
							if memberhp < 55 then 
								memberhp = 55 
							end 
						end 
					end 
				end 
			end 
			
            -- Misc: Sort by Roles 			
            if A.Unit(member):IsTank() then
                memberhp = memberhp - 2
				
				if mode == "TANK" then 
					table.insert(A.HealingEngine.Members.TANK, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })      
				end 
            elseif A.Unit(member):IsHealer() then                
                if UnitIsUnit("player", member) and memberhp < 95 then 
					if A.IsInPvP and A.Unit("player"):IsFocused(nil, true) then 
						memberhp = memberhp - 20
					else 
						memberhp = memberhp - 2
					end 
                else 
                    memberhp = memberhp + 2
                end
				
				if mode == "HEALER" then 
					table.insert(A.HealingEngine.Members.HEALER, 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				elseif mode == "RAID" then 	
					table.insert(A.HealingEngine.Members.RAID, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				end 				 
			else 
				memberhp = memberhp - 1
				
				if mode == "DAMAGER" then 
					table.insert(A.HealingEngine.Members.DAMAGER, 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				elseif mode == "RAID" then  
					table.insert(A.HealingEngine.Members.RAID, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				end			 
            end

            table.insert(A.HealingEngine.Members.ALL, 				{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
        end        
        
        -- Pets 
        if _G.HE_Pets then
            local memberpet 									= group .. "pet" .. i
			local memberpetGUID 								= UnitGUID(memberpet)
			local memberpethp, memberpetahp, _, memberpetmhp 	= CalculateHP(memberpet) 
			
			-- Note: We can't use CanHeal here because it will take not all units results could be wrong
			A.HealingEngine.Frequency.Temp.MAXHP = (A.HealingEngine.Frequency.Temp.MAXHP or 0) + memberpetmhp 
			A.HealingEngine.Frequency.Temp.AHP 	 = (A.HealingEngine.Frequency.Temp.AHP   or 0) + memberpetahp			
			
			if CanHeal(memberpet, memberpetGUID) then 
				if A.Unit("player"):CombatTime() > 0 then                
					memberpethp  = memberpethp * 1.35
					memberpetahp = memberpetahp * 1.35
				else                
					memberpethp  = memberpethp * 1.15
					memberpetahp = memberpetahp * 1.15
				end
				
				table.insert(A.HealingEngine.Members.ALL, 			{ Unit = memberpet, GUID = memberpetGUID, HP = memberpethp, AHP = memberpetahp, isPlayer = false, incDMG = A.Unit(memberpet):GetRealTimeDMG() }) 
			end 
        end
    end
    
    -- Frequency (Summary)
    if A.HealingEngine.Frequency.Temp.MAXHP and A.HealingEngine.Frequency.Temp.MAXHP > 0 then 
        table.insert(A.HealingEngine.Frequency.Actual, { 	                
                -- Max Group HP
                MAXHP	= A.HealingEngine.Frequency.Temp.MAXHP, 
                -- Current Group Actual HP
                AHP 	= A.HealingEngine.Frequency.Temp.AHP,
				-- Current Time on this record 
				TIME 	= TMW.time, 
        })
		
		-- Clear temp by old record
        wipe(A.HealingEngine.Frequency.Temp)
		
		-- Clear actual from older records
        for i = #A.HealingEngine.Frequency.Actual, 1, -1 do             
            -- Remove data longer than 5 seconds 
            if TMW.time - A.HealingEngine.Frequency.Actual[i].TIME > 10 then 
                table.remove(A.HealingEngine.Frequency.Actual, i)                
            end 
        end 
    end 
    
	-- Sort for next target / incDMG (Summary)
    if #A.HealingEngine.Members.ALL > 1 then 
        -- Sort by most damage receive
		for i = 1, #A.HealingEngine.Members.ALL do 
			local t = A.HealingEngine.Members.ALL[i]
			table.insert(A.HealingEngine.Members.MOSTLYINCDMG, 		{ Unit = t.Unit, GUID = t.GUID, incDMG = t.incDMG })
		end 
        table.sort(A.HealingEngine.Members.MOSTLYINCDMG, function(x, y)
                return x.incDMG > y.incDMG
        end)  
        
        -- Sort by Percent or Actual
        if not ActualHP then
			for k, v in pairs(A.HealingEngine.Members) do 
				if type(v) == "table" and #v > 1 and v[1].HP then 
					table.sort(v, function(x, y) return x.HP < y.HP end)
				end 
			end 		
        elseif ActualHP then
			for k, v in pairs(A.HealingEngine.Members) do 
				if type(v) == "table" and #v > 1 and v[1].AHP then 
					table.sort(v, function(x, y) return x.AHP > y.AHP end)
				end 
			end 		
        end
    end 
end

local function setHealingTarget(MODE, HP)
    local mode = MODE or "ALL"
    local hp = HP or 99
	
	if #A.HealingEngine.Members[mode] > 0 and A.HealingEngine.Members[mode][1].HP < hp then 
		healingTarget 		= A.HealingEngine.Members[mode][1].Unit
		healingTargetGUID 	= A.HealingEngine.Members[mode][1].GUID
		return 
	end 	 

    healingTarget 	  = "None"
    healingTargetGUID = "None"
end

local function setColorTarget(isForced)
    --Default 
    Frame.texture:SetColorTexture(0, 0, 0, 1.0)   
	
	if not isForced then 
		--If we have no one to heal
		if healingTarget == nil or healingTarget == "None" or healingTargetGUID == nil or healingTargetGUID == "None" then
			return
		end	
		
		--If we have a mouseover friendly unit
		if (A.IsInitialized and A.IsUnitFriendly("mouseover")) or (not A.IsInitialized and MouseOver_Toggle and A.MouseHasFrame()) then       
			return
		end
		
		--If we have a current target equiled to suggested or he is a boss
		if A.Unit("target"):IsExists() and (healingTargetGUID == UnitGUID("target") or A.Unit("target"):IsBoss()) then
			return
		end     
		
		--If we have enemy as primary unit 
		--TODO: Remove for old profiles until June 2019
		if not A.IsInitialized and ((MouseOver_Toggle and A.Unit("mouseover"):IsEnemy()) or A.Unit("target"):IsEnemy()) then 
			-- Old profiles 
			return 
		end 
		
		if A.IsInitialized and (A.IsUnitEnemy("mouseover") or A.IsUnitEnemy("target")) then 
			-- New profiles 
			return 
		end 
		
		--Mistweaver Monk
		if A.IsInitialized and A.IsGGLprofile and A.Unit("player"):HasSpec(ACTION_CONST_MONK_MISTWEAVER) and A.GetToggle(2, "HealingEnginePreventSuggest") then 
			local unit = "target"
			if A.IsUnitFriendly("mouseover") then 
				unit = "mouseover"
			end 
			if A.Unit(unit):HasBuffs(A[ACTION_CONST_MONK_MISTWEAVER].SoothingMist.ID, true) > 3 and A.Unit(unit):HealthPercent() <= A.GetToggle(2, "SoothingMistHP") then 
				return 
			end 
		end 
    end 
	
    --Party
    if healingTarget == "party1" then
        Frame.texture:SetColorTexture(0.345098, 0.239216, 0.741176, 1.0)
        return
    end
    if healingTarget == "party2" then
        Frame.texture:SetColorTexture(0.407843, 0.501961, 0.086275, 1.0)
        return
    end
    if healingTarget == "party3" then
        Frame.texture:SetColorTexture(0.160784, 0.470588, 0.164706, 1.0)
        return
    end
    if healingTarget == "party4" then
        Frame.texture:SetColorTexture(0.725490, 0.572549, 0.647059, 1.0)
        return
    end   
    
    --PartyPET
    if healingTarget == "partypet1" then
        Frame.texture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
        return
    end
    if healingTarget == "partypet2" then
        Frame.texture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
        return
    end
    if healingTarget == "partypet3" then
        Frame.texture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
        return
    end
    if healingTarget == "partypet4" then
        Frame.texture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
        return
    end        
    
    --Raid
    if healingTarget == "raid1" then
        Frame.texture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
        return
    end
    if healingTarget == "raid2" then
        Frame.texture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
        return
    end
    if healingTarget == "raid3" then
        Frame.texture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
        return
    end
    if healingTarget == "raid4" then
        Frame.texture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
        return
    end
    if healingTarget == "raid5" then
        Frame.texture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
        return
    end
    if healingTarget == "raid6" then
        Frame.texture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid7" then
        Frame.texture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
        return
    end
    if healingTarget == "raid8" then
        Frame.texture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid9" then
        Frame.texture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid10" then
        Frame.texture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
        return
    end
    if healingTarget == "raid11" then
        Frame.texture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
        return
    end
    if healingTarget == "raid12" then
        Frame.texture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid13" then
        Frame.texture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
        return
    end
    if healingTarget == "raid14" then
        Frame.texture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid15" then
        Frame.texture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
        return
    end
    if healingTarget == "raid16" then
        Frame.texture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
        return
    end
    if healingTarget == "raid17" then
        Frame.texture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
        return
    end
    if healingTarget == "raid18" then
        Frame.texture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
        return
    end
    if healingTarget == "raid19" then
        Frame.texture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
        return
    end
    if healingTarget == "raid20" then
        Frame.texture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
        return
    end
    if healingTarget == "raid21" then
        Frame.texture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
        return
    end
    if healingTarget == "raid22" then
        Frame.texture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
        return
    end
    if healingTarget == "raid23" then
        Frame.texture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
        return
    end
    if healingTarget == "raid24" then
        Frame.texture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
        return
    end
    if healingTarget == "raid25" then
        Frame.texture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
        return
    end
    if healingTarget == "raid26" then
        Frame.texture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
        return
    end
    if healingTarget == "raid27" then
        Frame.texture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
        return
    end
    if healingTarget == "raid28" then
        Frame.texture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
        return
    end
    if healingTarget == "raid29" then
        Frame.texture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
        return
    end
    if healingTarget == "raid30" then
        Frame.texture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
        return
    end
    if healingTarget == "raid31" then
        Frame.texture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
        return
    end
    if healingTarget == "raid32" then
        Frame.texture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
        return
    end
    if healingTarget == "raid33" then
        Frame.texture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
        return
    end
    if healingTarget == "raid34" then
        Frame.texture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
        return
    end    
    if healingTarget == "raid35" then
        Frame.texture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
        return
    end
    if healingTarget == "raid36" then
        Frame.texture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
        return
    end
    if healingTarget == "raid37" then
        Frame.texture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
        return
    end
    if healingTarget == "raid38" then
        Frame.texture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
        return
    end
    if healingTarget == "raid39" then
        Frame.texture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid40" then
        Frame.texture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
        return
    end
    if healingTarget == "raidpet1" then
        Frame.texture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet2" then
        Frame.texture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
        return
    end
    if healingTarget == "raidpet3" then
        Frame.texture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
        return
    end
    if healingTarget == "raidpet4" then
        Frame.texture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet5" then
        Frame.texture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
        return
    end
    if healingTarget == "raidpet6" then
        Frame.texture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet7" then
        Frame.texture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
        return
    end
    if healingTarget == "raidpet8" then
        Frame.texture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
        return
    end
    if healingTarget == "raidpet9" then
        Frame.texture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
        return
    end
    if healingTarget == "raidpet10" then
        Frame.texture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
        return
    end
    if healingTarget == "raidpet11" then
        Frame.texture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
        return
    end
    if healingTarget == "raidpet12" then
        Frame.texture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
        return
    end
    if healingTarget == "raidpet13" then
        Frame.texture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
        return
    end
    if healingTarget == "raidpet14" then
        Frame.texture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
        return
    end
    if healingTarget == "raidpet15" then
        Frame.texture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
        return
    end
    if healingTarget == "raidpet16" then
        Frame.texture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
        return
    end
    if healingTarget == "raidpet17" then
        Frame.texture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
        return
    end
    if healingTarget == "raidpet18" then
        Frame.texture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
        return
    end
    if healingTarget == "raidpet19" then
        Frame.texture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
        return
    end
    if healingTarget == "raidpet20" then
        Frame.texture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
        return
    end
    if healingTarget == "raidpet21" then
        Frame.texture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
        return
    end
    if healingTarget == "raidpet22" then
        Frame.texture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
        return
    end
    if healingTarget == "raidpet23" then
        Frame.texture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
        return
    end
    if healingTarget == "raidpet24" then
        Frame.texture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
        return
    end
    if healingTarget == "raidpet25" then
        Frame.texture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
        return
    end
    if healingTarget == "raidpet26" then
        Frame.texture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet27" then
        Frame.texture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
        return
    end
    if healingTarget == "raidpet28" then
        Frame.texture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet29" then
        Frame.texture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
        return
    end
    if healingTarget == "raidpet30" then
        Frame.texture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
        return
    end
    if healingTarget == "raidpet31" then
        Frame.texture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
        return
    end
    if healingTarget == "raidpet32" then
        Frame.texture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
        return
    end
    if healingTarget == "raidpet33" then
        Frame.texture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
        return
    end
    if healingTarget == "raidpet34" then
        Frame.texture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet35" then
        Frame.texture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
        return
    end
    if healingTarget == "raidpet36" then
        Frame.texture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
        return
    end
    if healingTarget == "raidpet37" then
        Frame.texture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
        return
    end
    if healingTarget == "raidpet38" then
        Frame.texture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
        return
    end
    if healingTarget == "raidpet39" then
        Frame.texture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
        return
    end
    if healingTarget == "raidpet40" then
        Frame.texture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
        return
    end
    
    --Stuff
    if healingTarget == "player" then
        Frame.texture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
        return
    end
    if healingTarget == "focus" then
        Frame.texture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
        return
    end
    --[[
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frame.texture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
        return
    end   
    if healingTarget == PLACEHOLDER then --was party5
        Frame.texture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
        return
    end     
    if healingTarget == PLACEHOLDER then --was party5pet
        Frame.texture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
        return
    end
    ]]
end

local function UpdateLOS()
	if A.Unit("target"):IsExists() then
		if A.IsInitialized then
			-- New profiles 
			if not A.IsUnitFriendly("mouseover") then 
				GetLOS("target")
			end 		
		elseif A.IsGGLprofile and (not MouseOver_Toggle or A.Unit("mouseover"):IsEnemy() or not A.MouseHasFrame()) then 
			-- TODO: Remove on old profiles until June 2019
			-- Old profiles 
			GetLOS("target")
		end 
	end 
end

local function HealingEngineInit()
	if A.IamHealer then 
		A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED", 	UpdateLOS)
		A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED", 	function() wipe(A.HealingEngine.Frequency.Actual) end)
		A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED", 	function() wipe(A.HealingEngine.Frequency.Actual) end)
		Frame:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed   
			local INTV = TMW.UPD_INTV > 0.3 and TMW.UPD_INTV or 0.3
			if A.IamHealer and self.elapsed > INTV then 
				HealingEngine(_G.HE_Toggle) 
				setHealingTarget(_G.HE_Toggle) 
				setColorTarget()   
				UpdateLOS() 
				self.elapsed = 0
			end			
		end)
	elseif #A.HealingEngine.Members.ALL > 0 then
		A.HealingEngine.Members:Wipe()
		A.HealingEngine.Frequency:Wipe()
		A.Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED")
		A.Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED")
		A.Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED")
		Frame:SetScript("OnUpdate", nil)
	end 
end 
A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_ENTERING_WORLD", 			HealingEngineInit)
A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "UPDATE_INSTANCE_INFO", 			HealingEngineInit)
A.Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_SPECIALIZATION_CHANGED", 	HealingEngineInit)

--- ============================= API ==============================
--- API valid only for healer specializations  
--- Members are depend on _G.HE_Pets variable 

--- SetTarget Controller 
function A.HealingEngine.SetTargetMostlyIncDMG()
	local GUID = UnitGUID("target")
	if GUID and GUID ~= healingTargetGUID and #A.HealingEngine.Members.MOSTLYINCDMG > 0 then 
		healingTargetGUID 	= A.HealingEngine.Members.MOSTLYINCDMG[1].GUID
		healingTarget		= A.HealingEngine.Members.MOSTLYINCDMG[1].Unit
		setColorTarget(true)
	end 
end 

function A.HealingEngine.SetTarget(unitID)
	local GUID = UnitGUID(unitID)
	if GUID and GUID ~= healingTargetGUID and #A.HealingEngine.Members.ALL > 0 then 
		healingTargetGUID 	= GUID
		healingTarget		= unitID
		setColorTarget(true)
	end 
end 

--- Group Controller 
function A.HealingEngine.GetMembersAll()
	-- @return table 
	return A.HealingEngine.Members.ALL 
end 

function A.HealingEngine.GetMembersByMode()
	-- @return table 
	local mode = _G.HE_Toggle or "ALL"
	return A.HealingEngine.Members[mode] 
end 

function A.HealingEngine.GetBuffsCount(ID, duration, source)
	-- @return number 	
	-- Only players 
    local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if m[i].isPlayer and A.Unit(m[i].Unit):HasBuffs(ID, source) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetDeBuffsCount(ID, duration)
	-- @return number 	
	-- Only players 
    local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if m[i].isPlayer and A.Unit(m[i].Unit):HasDeBuffs(ID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetHealth()
	-- @return number 
	-- Return actual group health 
	local f = A.HealingEngine.Frequency.Actual 
	if #f > 0 then 
		return f[#f].AHP
	end 
	return huge
end 

function A.HealingEngine.GetHealthAVG() 
	-- @return number 
	-- Return current percent (%) of the group health
	local f = A.HealingEngine.Frequency.Actual
	if #f > 0 then 
		return f[#f].AHP * 100 / f[#f].MAXHP
	end 
	return 100  
end 

function A.HealingEngine.GetHealthFrequency(timer)
	-- @return number 
	-- Return percent (%) of the group HP changed during lasts 'timer'. Positive (+) is HP lost, Negative (-) is HP gain, 0 - nothing is not changed 
    local total, counter = 0, 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 1 then 
        for i = 1, #f - 1 do 
            -- Getting history during that time rate
            if TMW.time - f[i].TIME <= timer then 
                counter = counter + 1
                total 	= total + f[i].AHP
            end 
        end        
    end 
	
	if total > 0 then           
		total = (f[#f].AHP * 100 / f[#f].MAXHP) - (total / counter * 100 / f[#f].MAXHP)
	end  	
	
    return total 
end 
A.HealingEngine.GetHealthFrequency = A.MakeFunctionCachedDynamic(A.HealingEngine.GetHealthFrequency)

function A.HealingEngine.GetIncomingDMG()
	-- @return number, number 
	-- Return REALTIME actual: total - group HP lose per second, avg - average unit HP lose per second
	local total, avg = 0, 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            total = total + m[i].incDMG
        end
		
		avg = total / #m
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingDMG = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingDMG)

function A.HealingEngine.GetIncomingHPS()
	-- @return number , number
	-- Return PERSISTENT actual: total - group HP gain per second, avg - average unit HP gain per second 
	local total, avg = 0, 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            total = total + A.Unit(m[i].Unit):GetHEAL()
        end
		
		avg = total / #m
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingHPS = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingHPS)

function A.HealingEngine.GetIncomingDMGAVG()
	-- @return number  
	-- Return REALTIME average percent group HP lose per second 
	local avg = 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 0 then 
		avg = A.HealingEngine.GetIncomingDMG() * 100 / f[#f].MAXHP
    end 
    return avg 
end

function A.HealingEngine.GetIncomingHPSAVG()
	-- @return number  
	-- Return REALTIME average percent group HP gain per second 
	local avg = 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 0 then 
		avg = A.HealingEngine.GetIncomingHPS() * 100 / f[#f].MAXHP
    end 
    return avg 
end 

function A.HealingEngine.GetTimeToDieUnits(timer)
	-- @return number 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if A.Unit(m[i].Unit):TimeToDie() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToDieMagicUnits(timer)
	-- @return number 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if A.Unit(m[i].Unit):TimeToDieMagic() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToFullHealth()
	-- @return number
	local f = A.HealingEngine.Frequency.Actual
	if #f > 0 then 
		local HPS = A.HealingEngine.GetIncomingHPS()
		if HPS > 0 then
			return (f[#f].MAXHP - f[#f].AHP) / HPS
		end 
	end 
	return 0 
end 

function A.HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit)
	-- @return number 
	-- This is easy template to known how many people minimum required be to heal by AoE with different group size or if some units out of range or in cyclone and etc..
	-- More easy to figure - which minimum units require if available group members <= 1 / <= 3 / <= 5 or > 5
	local m = A.HealingEngine.GetMembersAll()
	local members = #m
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
	local total = 0 
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if (not range or A.Unit(m[i].Unit):CanInterract(range)) and m[i].HP <= pHP then
                total = total + 1
            end
        end
    end 
	return total 
end 

function A.HealingEngine.HealingByRange(range, predictName, spell, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified range with spell
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
	if #m > 0 then 		
		for i = 1, #m do 
			if 	(not isMelee or A.Unit(m[i].Unit):IsMelee()) and 
				A.Unit(m[i].Unit):CanInterract(range) and
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, m[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and spell:PredictHeal(predictName, m[i].Unit))
				)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

function A.HealingEngine.HealingBySpell(predictName, spell, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified spell 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
	if #m > 0 then 		
		for i = 1, #m do 
			if 	(not isMelee or A.Unit(m[i].Unit):IsMelee()) and 
				(
					(not A.IsInitialized and Env.SpellInRange(m[i].Unit, spell)) or
					(A.IsInitialized and spell:IsInRange(m[i].Unit))
				) and 
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, m[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and spell:PredictHeal(predictName, m[i].Unit))
				)
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
	if #A.HealingEngine.Members.MOSTLYINCDMG > 0 then 
		return UnitIsUnit(unitID, A.HealingEngine.Members.MOSTLYINCDMG[1].Unit), A.HealingEngine.Members.MOSTLYINCDMG[1].incDMG
	end 
	return false, 0
end 

function A.HealingEngine.GetTarget()
	return healingTarget, healingTargetGUID
end 