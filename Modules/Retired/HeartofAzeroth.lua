-------------------------------------------------------------------------------
--
-- DON'T USE THIS API, IT'S OLD AND WILL BE REMOVED, THIS IS LEAVED HERE TO 
-- PROVIDE SUPPORT FOR OLD PROFILES
--
-------------------------------------------------------------------------------
local TMW 							= TMW
local CNDT 							= TMW.CNDT
local Env 							= CNDT.Env

local A 							= Action
local Unit 							= A.Unit
local MultiUnits					= A.MultiUnits
local EnemyTeam						= A.EnemyTeam
local LoC							= A.LossOfControl
local HealingEngine					= A.HealingEngine
local Azerite 						= LibStub("AzeriteTraits")	  

function A.HeartOfAzerothShow(icon)
	return A:Show(icon, ACTION_CONST_HEARTOFAZEROTH)
end 

function A.LazyHeartOfAzeroth(icon, unit) 
	if Azerite:EssenceIsMajorUseable() then 
		local Major 			= Azerite:EssenceGetMajor()
		local spellName 		= Major.spellName 
		local spellID 			= Major.spellID 		
		local MajorSpellName 	= Azerite:EssenceGetMajorBySpellNameOnENG(spellName)
		
		if MajorSpellName and Env.SpellCD(spellID) <= A.GetPing() and Unit("player"):CombatTime() > 0 then 
			local ShouldStop 	= A.ShouldStop()
			local unitID 		= unit and unit or "target"
			
			--[[ Essences Used by All Roles ]]
			if MajorSpellName == "Concentrated Flame" then 
				-- GCD 1 sec 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Env.SpellInRange(unitID, spellID) and (Unit(unitID):IsEnemy() or Azerite:EssencePredictHealing(MajorSpellName, spellID, unitID)) then 
					-- PvP condition 
					if not A.IsInPvP or not Unit(unitID):IsPlayer() or (not Unit(unitID):IsEnemy() and Unit(unitID):DeBuffCyclone() == 0) or (Unit(unitID):IsEnemy() and Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Worldvein Resonance" then 				
				-- GCD 1.5 sec 
				local isMelee = Unit("player"):IsMelee()
				local range = Unit(unitID):GetRange()
				if not ShouldStop and ((isMelee and range <= 8) or (not isMelee and range <= 40)) then  
					-- PvP condition 
					if not A.IsInPvP or not Unit(unitID):IsEnemy() or not Unit(unitID):IsPlayer() or (Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamagePhysImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Ripple in Space" then 
				-- GCD 1.5 sec 				
				local isMelee = Unit("player"):IsMelee()
				local range = Unit(unitID):GetRange()
				-- -10% damage reducement over 10 sec
				local isMaxRank = Azerite:GetRank(spellID) >= 3 
				if not ShouldStop and (
					(isMelee and range >= 10) or 
					(not isMelee and range >= 10 and range <= 25 and Unit("player"):GetCurrentSpeed() > 0) or 
					(isMaxRank and (Unit("player"):IsTanking(unitID, 10) or (A.IsInPvP and Unit("player"):UseDeff()))) or 
					(A.IsInPvP and Unit(unitID):IsPlayer() and Unit(unitID):IsEnemy() and Unit(unitID):HasBuffs("DamagePhysImun") > 0 and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):WithOutKarmed())
				) then  
					return A.HeartOfAzerothShow(icon)
				end
			end 
			
			if MajorSpellName == "Memory of Lucid Dreams" then
				-- GCD 1.5 sec
				-- Note: Retribution, Protection, Elemental, Warlock, Mage, Balance, Shadow an exception for power check 
				if not ShouldStop and (Unit("player"):HasSpec({66, 70, 263, 265, 266, 267, 62, 63, 64, 102, 258}) or Unit("player"):PowerPercent() <= 50) and (A.Zone == "none" or Unit(unitID):IsBoss() or Unit(unitID):IsPlayer()) then 				
					-- PvP condition
					if not A.IsInPvP or not Unit(unitID):IsPlayer() or (not Unit(unitID):IsEnemy() and Unit(unitID):DeBuffCyclone() == 0) or (Unit(unitID):IsEnemy() and Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			--[[ Tank ]]
			if MajorSpellName == "Azeroth's Undying Gift" then
				-- GCD 0 sec
				if 	(
						-- HP lose per sec >= 15
						Unit("player"):GetDMG() * 100 / Unit("player"):HealthMax() >= 15 or 
						Unit("player"):TimeToDieX(20) <= 6 or 
						Unit("player"):HealthPercent() < 70 or 
						(
							A.IsInPvP and 
							(
								Unit("player"):UseDeff() or 
								(
									Unit("player"):HasFlags() and 
									Unit("player"):GetRealTimeDMG() > 0 and 
									Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Unit("player"):HasBuffs("DeffBuffs", true) == 0
				then
					return A.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Anima of Death" then 
				-- GCD 1.5 sec 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Unit("player"):HealthPercent() < 70 and Azerite:EssencePredictHealing(MajorSpellName, spellID, "player") then
					-- PvP condition
					if not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(8) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "Aegis of the Deep" then 
				-- GCD 1.5 sec
				if 	not ShouldStop and 
					(
						-- HP lose per sec taken from physical attacks >= 25
						Unit("player"):GetDMG(3) * 100 / Unit("player"):HealthMax() >= 25 or 
						Unit("player"):TimeToDieX(25) <= 4 or 
						Unit("player"):HealthPercent() < 30 or 
						(
							A.IsInPvP and 
							(
								Unit("player"):UseDeff() or 
								(
									Unit("player"):HasFlags() and 
									Unit("player"):GetRealTimeDMG() > 0 and 
									Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Unit("player"):HasBuffs("DeffBuffs", true) == 0
				then
					return A.HeartOfAzerothShow(icon)
				end 			
			end 
			
			if MajorSpellName == "Empowered Null Barrier" then 
				-- GCD 1.5 sec
				if 	not ShouldStop and 
					(
						-- If can fully absorb 
						Unit("player"):GetDMG(4) * 10 >= A.GetSpellDescription(spellID)[1] or 
						-- If can die to 25% from magic attacks in less than 6 sec
						Unit("player"):TimeToDieMagicX(25) < 6 or 
						-- HP lose per sec >= 30 from magic attacks
						Unit("player"):GetDMG(4) * 100 / Unit("player"):HealthMax() >= 30 or 
						-- HP < 40 and real time incoming damage from mage attacks more than 10%
						(
							Unit("player"):HealthPercent() < 40 and 
							Unit("player"):GetRealTimeDMG(4) > Unit("player"):HealthMax() * 0.1
						) or 
						(
							A.IsInPvP and
							-- Stable real time incoming damage from mage attacks more than 20%
							Unit("player"):GetRealTimeDMG(4) > Unit("player"):HealthMax() * 0.2 and 							
							(
								Unit("player"):UseDeff() or 
								(
									Unit("player"):HasFlags() and 									
									Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Unit("player"):HasBuffs("DeffBuffsMagic", true) == 0
				then
					return A.HeartOfAzerothShow(icon)
				end
			end 
			
			if MajorSpellName == "Suppressing Pulse" then 
				-- GCD 1.5 sec
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and not ShouldStop and Unit("player"):CombatTime() > 3 and Unit("player"):IsTanking(unitID, 8) and Unit("player"):GetRealTimeDMG(3) > 0 then 
					if MultiUnits:GetByRange(15, 3) >= 3 or 
					(
						A.IsInPvP and 
						( 
							(
								Unit(unitID):IsPlayer() and 
								Unit(unitID):IsEnemy() and 
								Unit(unitID):GetCurrentSpeed() >= 100 and 
								Unit(unitID):HasBuffs("TotalImun") == 0 and 
								Unit(unitID):HasBuffs("Freedom") == 0
							) or 
							-- If someone enemy player bursting in 15 range with > 3 duration
							EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", 15) > 3 
						)
					) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			--[[ Healer ]]
			if MajorSpellName == "Refreshment" then 
				-- GCD 1.5 sec 
				-- It has 100 yards range but I think it's not truth and 40 yards by UnitInRange enough 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Unit(unitID):IsEnemy() and (not Unit(unitID):IsPlayer() or Unit(unitID):DeBuffCyclone() == 0) and Unit(unitID):InRange() and Azerite:EssencePredictHealing(MajorSpellName, nil, unitID) then 
					return A.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Standstill" then 
				-- GCD 1.5 sec 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and not ShouldStop and not Unit(unitID):IsEnemy() and Unit(unitID):IsPlayer() and Unit(unitID):DeBuffCyclone() == 0 and Unit(unitID):InRange() and (Unit(unitID):TimeToDie() <= 6 or Unit(unitID):GetDMG() * 4 >= A.GetSpellDescription(spellID)[1]) and Unit(unitID):HasBuffs("TotalImun") == 0 then 
					return A.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Life-Binder's Invocation" then 
				-- GCD 1.5 sec (this is long cast)
				-- If during latest 3 sec group AHP went down to -30%
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "HOLY") == 0 and not ShouldStop and not Unit(unitID):IsEnemy() and HealingEngine.GetHealthFrequency(3) > 30 and Unit("player"):GetCurrentSpeed() == 0 and (Unit("player"):TimeToDie() > 9 or not A.IsInPvP or (not Unit("player"):IsFocused() and Unit("player"):HealthPercent() > 20)) then 
					return A.HeartOfAzerothShow(icon)
				end 
			end  
			
			if MajorSpellName == "Overcharge Mana" then 
				-- GCD 1.5 sec 
				-- If unit TTD <= 16 and TTD > 6 and our mana above 35% or while heroism
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Unit(unitID):IsEnemy() and (not Unit(unitID):IsPlayer() or Unit(unitID):DeBuffCyclone() == 0) and Unit(unitID):InRange() and ((Unit(unitID):TimeToDie() <= 16 and Unit(unitID):TimeToDie() > 6 and Unit("player"):Power() >= Unit("player"):PowerMax() * 0.35) or Unit("player"):HasBuffs("BurstHaste") > 0) then 
					return A.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Vitality Conduit" then 
				-- GCD 1.5 sec 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Unit(unitID):IsEnemy() and (not Unit(unitID):IsPlayer() or Unit(unitID):DeBuffCyclone() == 0) and Unit(unitID):InRange() and Azerite:EssencePredictHealing(MajorSpellName, spellID, unitID) then 
					return A.HeartOfAzerothShow(icon)
				end 
			end 
			
			--[[ Damager ]]
			if MajorSpellName == "Focused Azerite Beam" then 
				-- GCD 1.5 sec (channeled)
				if (Azerite:GetRank(spellID) >= 3 or Unit("player"):IsStayingTime() >= 1) and LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Unit(unitID):IsEnemy() and Unit(unitID):GetRange() <= 10 and Unit("player"):CombatTime() > 3 then 
					local isMelee = Unit("player"):IsMelee()
					if ( not A.IsInPvP or (Unit(unitID):IsPlayer() and not EnemyTeam("HEALER"):IsBreakAble(10) and Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0) ) then 
						return A.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "Guardian of Azeroth" then 
				-- GCD 1.5 sec (range minion with fire attack)
				if not ShouldStop and Unit(unitID):IsEnemy() then 
					local isMelee = Unit("player"):IsMelee()
					if 	((not isMelee and Unit(unitID):GetRange() <= 40 and LoC:IsMissed({"SILENCE", "DISARM"})) or (isMelee and Unit(unitID):GetRange() <= 10 and LoC:IsMissed("DISARM"))) and 
						(Unit(unitID):IsBoss() or Unit("player"):HasBuffs("DamageBuffs") > 8 or Unit("player"):HasBuffs("BurstHaste") > 2 or (A.IsInPvP and Unit(unitID):IsPlayer() and Unit(unitID):UseBurst())) and 
						(not A.IsInPvP or (Unit(unitID):IsPlayer() and Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0)) 					
					then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Blood of the Enemy" then 
				-- GCD 1.5 sec 
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and not ShouldStop and Unit(unitID):IsEnemy() and Unit(unitID):GetRange() <= 12 then 
					local isMelee = Unit("player"):IsMelee()
					if 	(not isMelee or (isMelee and LoC:IsMissed("DISARM"))) and 
						(Unit("player"):HasBuffs("DamageBuffs") > 0 or Unit("player"):HasBuffs("BurstHaste") > 0 or (A.IsInPvP and Unit(unitID):IsPlayer() and Unit(unitID):UseBurst())) and 
						((not A.IsInPvP and AoE(4, 12)) or (Unit(unitID):IsPlayer() and not EnemyTeam():IsBreakAble(12) and Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0)) 					
					then 
						return A.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Purifying Blast" then 
				-- GCD 1.5 sec 
				if not ShouldStop and Unit(unitID):IsEnemy() then
					local isMelee = Unit("player"):IsMelee()
					local n = A.Zone == "arena" and 2 or 4
					if (
							(isMelee and AoE(n, 8) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(8))) or 
							(not isMelee and CombatUnits(n + 1, 40) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40)))  
					   ) 
					then 
						return A.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "The Unbound Force" then 
				-- GCD 1.5 sec (filler)
				if LoC:IsMissed("SILENCE") and LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Unit(unitID):IsEnemy() and Env.SpellInRange(unitID, spellID) then
					if not A.IsInPvP or (not Unit(unitID):IsTotem() and (not Unit(unitID):IsPlayer() or (Unit(unitID):WithOutKarmed() and Unit(unitID):HasBuffs("TotalImun") == 0 and Unit(unitID):HasBuffs("DamageMagicImun") == 0))) then 
						return A.HeartOfAzerothShow(icon)
					end
				end 
			end 
			
		end 		
	end 
	
	return false 
end 
	  