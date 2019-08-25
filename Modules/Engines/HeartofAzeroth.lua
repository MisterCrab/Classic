local TMW 							= TMW
local A 							= Action

--local strlowerCache  				= TMW.strlowerCache
--local isEnemy						= A.Bit.isEnemy
--local isPlayer					= A.Bit.isPlayer
--local toStr 						= A.toStr
--local toNum 						= A.toNum
--local InstanceInfo				= A.InstanceInfo
--local TeamCache					= A.TeamCache
local Azerite 						= LibStub("AzeriteTraits")
--local Pet							= LibStub("PetLibrary")
--local LibRangeCheck  				= LibStub("LibRangeCheck-2.0")
--local SpellRange					= LibStub("SpellRange-1.0")
--local DRData 						= LibStub("DRData-1.1")

local _G, pairs 					=
	  _G, pairs

local GetSpecializationRoleByID 	= GetSpecializationRoleByID
local AzeriteEssence 				= _G.C_AzeriteEssence
local AzeriteEssences 				= {
	ALL = {
		ConcentratedFlame 			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.ConcentratedFlame 		}, -- filler (40y, low priority) HPS / DPS 
		WorldveinResonance			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.WorldveinResonance 		}, -- filler (small stat burst, cd1min, high priority)
		RippleinSpace				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.RippleinSpace 			}, -- movement / -10% deffensive (x3 rank)
		MemoryofLucidDreams			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.MemoryofLucidDreams 	}, -- burst (100% power regeneration)
	},
	TANK = {
		AzerothsUndyingGift			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AzerothsUndyingGift 	}, -- -20% 4sec cd1min / -40% 2sec and then -20% 2sec cd45sec
		AnimaofDeath				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AnimaofDeath 			}, -- aoe self heal cd2.5-2min
		AegisoftheDeep				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AegisoftheDeep 			}, -- physical attack protection cd2-1.5min
		EmpoweredNullBarrier		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.EmpoweredNullBarrier 	}, -- magic attack protection cd3-2.3min
		SuppressingPulse			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.SuppressingPulse 		}, -- aoe -70% slow and -25% attack speed cd60-45sec
	},
	HEALER = {
		Refreshment					= { Type = "HeartOfAzeroth", ID = Azerite.CONST.Refreshment 			}, -- filler cd15sec
		Standstill					= { Type = "HeartOfAzeroth", ID = Azerite.CONST.Standstill 				}, -- burst (big absorb incoming dmg and hps) cd3min
		LifeBindersInvocation		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.LifeBindersInvocation 	}, -- burst aoe (big heal) cd3min
		OverchargeMana				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.OverchargeMana 			}, -- filler (my hps < incoming unit dps) cd30sec
		VitalityConduit				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.VitalityConduit 		}, -- aoe cd60-45sec 
	},	
	DAMAGER = {
		FocusedAzeriteBeam			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.FocusedAzeriteBeam 		}, -- aoe 
		GuardianofAzeroth			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.GuardianofAzeroth 		}, -- burst 
		BloodoftheEnemy				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.BloodoftheEnemy 		}, -- aoe 
		PurifyingBlast				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.PurifyingBlast 			}, -- filler (aoe, high priority)
		TheUnboundForce				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.TheUnboundForce 		}, -- filler (high priority)
	},
}

-------------------------------------
-- API
--------------------------------------
function A:CreateEssencesFor(specID) 
	-- If game patch lower than 8.2 it will create empty objects which will be hidden in UI 
	for k, v in pairs(AzeriteEssences.ALL) do 
		self[specID][k] = self.Create(AzeriteEssence and v or nil)
	end 

	for k, v in pairs(AzeriteEssences[GetSpecializationRoleByID(specID)]) do 
		self[specID][k] = self.Create(AzeriteEssence and v or nil)
	end 	 
end 

function A:IsEssenceUseable()
	-- @return boolean (if Major essence has active spell and it's selected on character)
	return Azerite:EssenceIsMajorUseable(self.ID) 
end 

function A:AutoHeartOfAzeroth(unitID, skipShouldStop, skipAuto)
	-- @return boolean 
	-- Note: This is lazy template for all Heart Of Azerote Essences 
	-- Arguments: skipAuto if true then will skip AUTO template conditions and will check only validance (imun, own CC such as silence, range and etc)	
	if self.SubType == "HeartOfAzeroth" and Azerite:EssenceIsMajorUseable() and A.GetToggle(1, "HeartOfAzeroth") then 
		local Major 			= Azerite:EssenceGetMajor()
		local MajorSpellName 	= Azerite:EssenceGetMajorBySpellNameOnENG(Major.spellName)
		
		if MajorSpellName and Major and Major.spellName == self:Info() then 
			self.ID 			= Major.spellID
			
			--[[ Essences Used by All Roles ]]
			if MajorSpellName == "Concentrated Flame" then 				
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it checking range 
					A.LossOfControl:IsMissed("SILENCE") and 
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "FIRE") == 0 
				then 
					local isEnemy = A.Unit(unitID):IsEnemy()
					
					if 	(
							IsEnemy or 
							Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)
						) and 
						(
							(
								not isEnemy and 
								self:AbsentImun(unitID) 
							) or 
							(
								isEnemy and 
								self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"})
							)
						)
					then
						return true 
					end 
				end 
			end 
			
			if MajorSpellName == "Worldvein Resonance" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or 
						((not A.Unit("player"):IsMelee() and A.Unit(unitID):GetRange() <= 40) or A.Unit(unitID):GetRange() <= 12)
					) and 
					(	
						not A.Unit(unitID):IsEnemy() or						
						self:AbsentImun(unitID, {"TotalImun", "DamagePhysImun", "DamageMagicImun"})
					)
				then 
					return true 					
				end 					
			end 
			
			if MajorSpellName == "Ripple in Space" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if self:IsReady(unitID, true, nil, skipShouldStop) then
					if skipAuto then 
						return true 
					else
						local isMelee 	= A.Unit("player"):IsMelee()
						local range 	= A.Unit(unitID):GetRange()
						-- -10% damage reducement over 10 sec
						local isMaxRank = self:GetAzeriteRank() >= 3
						
						if 	(isMelee and range >= 10) or 
							(not isMelee and range >= 10 and range <= 25 and A.Unit("player"):GetCurrentSpeed() > 0) or 
							(isMaxRank and (A.Unit("player"):IsTanking(unitID, 10) or (A.IsInPvP and A.Unit("player"):UseDeff()))) or 
							(A.IsInPvP and A.Unit(unitID):IsPlayer() and A.Unit(unitID):IsEnemy() and A.Unit(unitID):HasBuffs("DamagePhysImun") > 0 and self:AbsentImun(unitID, "TotalImun"))							 
						then  
							return true 
						end 
					end 
				end 
			end 
			
			if MajorSpellName == "Memory of Lucid Dreams" then
				if not unitID then 
					unitID = "target"
				end 
				
				if	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or 
						-- Note: Retribution, Protection, Elemental, Warlock, Mage, Balance, Shadow an exception for power check 
						A.Unit("player"):HasSpec({66, 70, 263, 265, 266, 267, 62, 63, 64, 102, 258}) or
						A.Unit("player"):PowerPercent() <= 50
					) 
				then 
					local isEnemy = A.Unit(unitID):IsEnemy()
					
					if	(
							not isEnemy and 
							self:AbsentImun(unitID)
						) or 
						(
							isEnemy and 
							self:AbsentImun(unitID, "TotalImun")
						)					
					then
						return true 
					end 
				end 
			end 
			
			--[[ Tank ]]
			if MajorSpellName == "Azeroth's Undying Gift" then				
				unitID = "player"				
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or
						(
							(
								-- HP lose per sec >= 15
								A.Unit(unitID):GetDMG() * 100 / A.Unit(unitID):HealthMax() >= 15 or 
								A.Unit(unitID):TimeToDieX(20) <= 6 or 
								A.Unit(unitID):HealthPercent() < 70 or 
								(
									A.IsInPvP and 
									(
										A.Unit(unitID):UseDeff() or 
										(
											A.Unit(unitID):HasFlags() and 
											A.Unit(unitID):GetRealTimeDMG() > 0 and 
											A.Unit(unitID):IsFocused(nil, true) 
										)
									)
								) 
							) and 
							A.Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					) 
				then
					return true
				end 
			end 
			
			if MajorSpellName == "Anima of Death" then
				unitID = "player"				
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 					
					A.LossOfControl:IsMissed("SILENCE") and 
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID) and 
					(
						skipAuto or 
						A.Unit(unitID):HealthPercent() < 70
					) and 
					(
						not A.IsInPvP or
						not A.EnemyTeam("HEALER"):IsBreakAble(8)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Aegis of the Deep" then 
				unitID = "player"				
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 					
					(
						skipAuto or 
						(
							(
								-- HP lose per sec taken from physical attacks >= 25
								A.Unit(unitID):GetDMG(3) * 100 / A.Unit(unitID):HealthMax() >= 25 or 
								A.Unit(unitID):TimeToDieX(25) <= 4 or 
								A.Unit(unitID):HealthPercent() < 30 or 
								(
									A.IsInPvP and 
									(
										A.Unit(unitID):UseDeff() or 
										(
											A.Unit(unitID):HasFlags() and 
											A.Unit(unitID):GetRealTimeDMG() > 0 and 
											A.Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							A.Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					)
				then 
					return true 
				end 						
			end 
			
			if MajorSpellName == "Empowered Null Barrier" then 
				unitID = "player"				
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 					
					(
						skipAuto or 
						(
							(
								-- If can fully absorb 
								A.Unit(unitID):GetDMG(4) * 10 >= self:GetSpellDescription()[1] or 
								-- If can die to 25% from magic attacks in less than 6 sec
								A.Unit(unitID):TimeToDieMagicX(25) < 6 or 
								-- HP lose per sec >= 30 from magic attacks
								A.Unit(unitID):GetDMG(4) * 100 / A.Unit(unitID):HealthMax() >= 30 or 
								-- HP < 40 and real time incoming damage from mage attacks more than 10%
								(
									A.Unit(unitID):HealthPercent() < 40 and 
									A.Unit(unitID):GetRealTimeDMG(4) > A.Unit(unitID):HealthMax() * 0.1
								) or 
								(
									A.IsInPvP and
									-- Stable real time incoming damage from mage attacks more than 20%
									A.Unit(unitID):GetRealTimeDMG(4) > A.Unit(unitID):HealthMax() * 0.2 and 							
									(
										A.Unit(unitID):UseDeff() or 
										(
											A.Unit(unitID):HasFlags() and 									
											A.Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							A.Unit(unitID):HasBuffs("DeffBuffsMagic", true) == 0						
						)
					)
				then
					return true 
				end 
			end 
			
			if MajorSpellName == "Suppressing Pulse" then 
				if not unitID or unitID == "player" then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.LossOfControl:IsMissed("SILENCE") and 
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					(
						(
							skipAuto and 
							A.MultiUnits:GetByRange(15, 1) >= 1						
						) or 
						(
							not skipAuto and 
							A.Unit("player"):IsTanking(unitID, 8) and 
							A.Unit("player"):GetRealTimeDMG(3) > 0 and 
							(
								(
									A.IsInPvP and 
									( 
										(
											A.Unit(unitID):IsPlayer() and 
											A.Unit(unitID):IsEnemy() and 
											A.Unit(unitID):GetCurrentSpeed() >= 100 and 
											self:AbsentImun(unitID, {"TotalImun", "Freedom"}, true)
										) or 
										-- If someone enemy player bursting in 15 range with > 3 duration
										A.EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", 15) > 3 
									)
								) or 
								A.MultiUnits:GetByRange(15, 3) >= 3
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			--[[ Healer ]]
			if MajorSpellName == "Refreshment" then
				if not unitID then 
					unitID = "target"
				end 
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):InRange() and  -- It has 100 yards range but I think it's not truth and 40 yards is enough 
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)					
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Standstill" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):IsPlayer() and 
					A.Unit(unitID):InRange() and
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					not A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, "TotalImun") and 
					(
						skipAuto or 
						(A.Unit(unitID):TimeToDie() <= 6 or A.Unit(unitID):GetDMG() * 4 >= self:GetSpellDescription()[1])
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Life-Binder's Invocation" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):IsPlayer() and 
					A.Unit(unitID):InRange() and 
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "HOLY") == 0 and
					A.Unit("player"):GetCurrentSpeed() == 0 and 
					not A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 					
					(
						skipAuto or 
						(
							A.HealingEngine.GetHealthFrequency(3) > 30 and 
							A.Unit(unitID):TimeToDie() > 8 
						)
					)
				then 
					return true 
				end 
			end  
			
			if MajorSpellName == "Overcharge Mana" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):InRange() and 
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A.Unit(unitID):IsEnemy() and
					self:AbsentImun(unitID) and 
					(
						skipAuto or 
						(
							A.Unit("player"):HasBuffs("BurstHaste") > 0 or 
							(
								A.Unit(unitID):TimeToDie() > 8 and 
								A.Unit("player"):PowerPercent() >= 20 and 
								A.Unit(unitID):GetDMG() * 1.2 > A.Unit("player"):GetHPS()
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Vitality Conduit" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):InRange() and 				
					A.LossOfControl:IsMissed("SILENCE") and 
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)
				then 
					return true 
				end 
			end 
			
			--[[ Damager ]]
			if MajorSpellName == "Focused Azerite Beam" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	A.Unit("player"):CombatTime() > 2 and
					(
						self:GetAzeriteRank() >= 3 or 
						A.Unit("player"):IsStayingTime() >= 1
					) and 
					self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.LossOfControl:IsMissed("SILENCE") and 
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					A.Unit(unitID):IsEnemy() and
					A.Unit(unitID):GetRange() <= 10 and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					(
						not A.IsInPvP or 
						not A.EnemyTeam("HEALER"):IsBreakAble(10)
					) and 
					not A.Unit(unitID):IsTotem() 
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Guardian of Azeroth" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not A.Unit(unitID):IsTotem() and 
					(
						(
							A.Unit("player"):IsMelee() and 
							A.Unit(unitID):GetRange() <= 10 and 
							A.LossOfControl:IsMissed("DISARM")
						) or 
						(
							not A.Unit("player"):IsMelee() and 
							A.Unit(unitID):GetRange() <= 40 and 
							A.LossOfControl:IsMissed({"SILENCE", "DISARM"})
						)
					)  
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Blood of the Enemy" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and 
					A.Unit(unitID):IsEnemy() and 
					A.Unit(unitID):GetRange() <= 12 and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not A.Unit(unitID):IsTotem() and 
					(
						not A.Unit("player"):IsMelee() or 
						A.LossOfControl:IsMissed("DISARM")
					) and 
					(
						not A.IsInPvP or 
						not A.EnemyTeam():IsBreakAble(12)
					) and 
					(
						skipAuto or 
						A.IsInPvP or
						A.MultiUnits:GetByRange(12, 2) >= 2
					)
				then 
					return true  
				end 
			end 
			
			if MajorSpellName == "Purifying Blast" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not A.Unit(unitID):IsTotem()
				then 
					local isMelee = A.Unit("player"):IsMelee()
					local n = A.Zone == "arena" and 2 or 4
					
					if	(
							isMelee and 
							(
								not A.IsInPvP or 
								not A.EnemyTeam("HEALER"):IsBreakAble(8)
							) and 
							(
								skipAuto or 
								A.MultiUnits:GetByRange(8, n) >= n
							)
						) or 
						(
							not isMelee and 
							(
								not A.IsInPvP or 
								not A.EnemyTeam("HEALER"):IsBreakAble(40)
							) and 
							(
								skipAuto or 
								A.MultiUnits:GetByRangeInCombat(40, n + 1) >= n + 1
							)
						)
					then 
						return true 
					end 
				end 
			end 
			
			if MajorSpellName == "The Unbound Force" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it's checking range 
					A.Unit(unitID):IsEnemy() and 
					A.LossOfControl:IsMissed("SILENCE") and
					A.LossOfControl:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not A.Unit(unitID):IsTotem()
				then 
					return true 
				end 
			end 
			
		end 		
	end 
	
	return false 
end 

function A:AutoHeartOfAzerothP(unitID, skipShouldStop)
	-- @return boolean 
	-- Note: No AUTO template 
	return self:AutoHeartOfAzeroth(unitID, skipShouldStop, true)
end 