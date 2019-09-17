local TMW 					= TMW 

local A   					= Action	
local UnitCooldown			= A.UnitCooldown
local Unit					= A.Unit 
local Player				= A.Player 
local Pet					= LibStub("PetLibrary")
local LoC 					= A.LossOfControl
local MultiUnits			= A.MultiUnits

local _G, select 			= _G, select

local UnitIsUnit  			= UnitIsUnit

local SpellIsTargeting		= SpellIsTargeting
local IsMouseButtonDown		= IsMouseButtonDown
--local IsPlayerAttacking	= IsPlayerAttacking
local HasWandEquipped		= HasWandEquipped
local UnitPowerType			= UnitPowerType

local ClassPortaits = {
	["WARRIOR"] 			= ACTION_CONST_PORTRAIT_WARRIOR,
	["PALADIN"] 			= ACTION_CONST_PORTRAIT_PALADIN,
	["HUNTER"] 				= ACTION_CONST_PORTRAIT_HUNTER,
	["ROGUE"] 				= ACTION_CONST_PORTRAIT_ROGUE,
	["PRIEST"] 				= ACTION_CONST_PORTRAIT_PRIEST,
	["SHAMAN"]	 			= ACTION_CONST_PORTRAIT_SHAMAN, -- Custom because it making conflict with Bloodlust
	["MAGE"] 				= ACTION_CONST_PORTRAIT_MAGE,
	["WARLOCK"] 			= ACTION_CONST_PORTRAIT_WARLOCK,
	["DRUID"] 				= ACTION_CONST_PORTRAIT_DRUID,
}

local GetKeyByRace = {
	-- I use this to check if we have created for spec needed spell 
	NightElf 				= "Shadowmeld",
	Human 					= "Perception",
	Gnome 					= "EscapeArtist",
	Dwarf 					= "Stoneform",
	Scourge 				= "WilloftheForsaken",
	Troll 					= "Berserking",
	Tauren 					= "WarStomp",
	Orc 					= "BloodFury",
}

-------------------------------------------------------------------------------
-- Conditions
-------------------------------------------------------------------------------
local FoodAndDrink = {	
	587, 	-- Conjure Food 
	18233,	-- Food
	22734, 	-- Drink
	29029,	-- Fizzy Energy Drink
	18140,	-- Blessed Sunfruit Juice
	23698,	-- Alterac Spring Water
	23692,	-- Alterac Manna Biscuit
	24410,	-- Arathi Basin Iron Ration
	24411,	-- Arathi Basin Enriched Ration 
	25990, 	-- Graccu's Mince Meat Fruitcake	
	18124,  -- Blessed Sunfruit
	24384,	-- Essence Mango
	26263,	-- Dim Sum (doesn't triggers Food and Drink)
	26030,	-- Windblossom Berries (doesn't triggers Food and Drink)
	25691, 	-- Brain Food (unknown what does it exactly trigger)
}
function A.PauseChecks()  	
	-- Chat, BindPad, TellMeWhen
	if ACTIVE_CHAT_EDIT_BOX or (BindPadFrame and BindPadFrame:IsVisible()) or not TMW.Locked then 
		return ACTION_CONST_PAUSECHECKS_DISABLED
	end 
	
	if (A.GetToggle(1, "CheckDeadOrGhost") and Unit("player"):IsDead()) or (A.GetToggle(1, "CheckDeadOrGhostTarget") and (Unit("target"):IsDead() or Unit("mouseover"):IsDead()) and (not A.IsInPvP or Unit("target"):Class() ~= "HUNTER")) then 						-- exception in PvP Hunter 
		return ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST
	end 	
	
	if A.GetToggle(1, "CheckMount") and Player:IsMounted() then 																																													-- exception Divine Steed and combat mounted auras
		return ACTION_CONST_PAUSECHECKS_IS_MOUNTED
	end 

	if A.GetToggle(1, "CheckCombat") and Unit("player"):CombatTime() == 0 and Unit("target"):CombatTime() == 0 and not Player:IsStealthed() and A.BossMods_Pulling() == 0 then 																		-- exception Stealthed and DBM pulling event 
		return ACTION_CONST_PAUSECHECKS_WAITING
	end 	
	
	if A.GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() then
		return ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if A.GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return ACTION_CONST_PAUSECHECKS_LOOTFRAME
	end	
	
	if A.GetToggle(1, "CheckEatingOrDrinking") and Unit("player"):CombatTime() == 0 and Player:IsStaying() and Unit("player"):HasBuffs(FoodAndDrink, true) > 0 then
		return ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
A.PauseChecks = A.MakeFunctionCachedStatic(A.PauseChecks)

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.Trinket1 					= A.Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET1,	 			QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "Upper" })
A.Trinket2 					= A.Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET2, 			QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "Lower" })
A.Shoot						= A.Create({ Type = "Spell", 			ID = 5019, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "Wand" })
A.AutoShot					= A.Create({ Type = "Spell", 			ID = 75, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "Hunter's shoot" })
A.HSGreater1				= A.Create({ Type = "Item", 			ID = 5510, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSGreater2				= A.Create({ Type = "Item", 			ID = 19010, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSGreater3				= A.Create({ Type = "Item", 			ID = 19011, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HS1						= A.Create({ Type = "Item", 			ID = 5509, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HS2						= A.Create({ Type = "Item", 			ID = 19008, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HS3						= A.Create({ Type = "Item", 			ID = 19009, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSLesser1					= A.Create({ Type = "Item", 			ID = 5511, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSLesser2					= A.Create({ Type = "Item", 			ID = 19006, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSLesser3					= A.Create({ Type = "Item", 			ID = 19007, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMajor1					= A.Create({ Type = "Item", 			ID = 9421, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMajor2					= A.Create({ Type = "Item", 			ID = 19012, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMajor3					= A.Create({ Type = "Item", 			ID = 19013, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMinor1					= A.Create({ Type = "Item", 			ID = 5512, 										QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMinor2					= A.Create({ Type = "Item", 			ID = 19004, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.HSMinor3					= A.Create({ Type = "Item", 			ID = 19005, 									QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[6] HealthStone" })
A.DarkRune					= A.Create({ Type = "Item", 			ID = 20520, Texture = 134417,					QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[3,4,6] Runes" })
A.DemonicRune				= A.Create({ Type = "Item", 			ID = 12662, Texture = 134417,					QueueForbidden = true, BlockForbidden = true, Hidden = true, Desc = "[3,4,6] Runes" })

local TempHealthStones 		= { A.HSGreater3, A.HSGreater2, A.HSGreater1, A.HS3, A.HS2, A.HS1, A.HSLesser3, A.HSLesser2, A.HSLesser1, A.HSMajor3, A.HSMajor2, A.HSMajor1, A.HSMinor3, A.HSMinor2, A.HSMinor1 }
local function GetHealthStone()
	-- @return object or nil 
	for i = 1, #TempHealthStones do 
		local object = TempHealthStones[i]
		if object:GetCount() > 0 and object:GetCooldown() == 0 then 
			return object
		end 
	end 
end 

local function IsShoot(unit)
	return 	A.GetToggle(1, "AutoShoot") and not Player:IsShooting() and  
			(
				(A.PlayerClass == "HUNTER" and A.AutoShot:IsReadyP(unit)) or 
				(A.PlayerClass ~= "HUNTER" and HasWandEquipped() and A.Shoot:IsInRange(unit) and (not A.GetToggle(1, "AutoAttack") or not Player:IsAttacking() or Unit(unit):GetRange() > 6))
			)
end 

function A.CanUseManaRune(icon)
	-- @return boolean or nil 
	if select(2, UnitPowerType("player")) == "MANA" and not A.ShouldStop() then 
		local Runes = A.GetToggle(2, "Runes") 
		if Runes > 0 and Unit("player"):Health() > 1100 then 
			local Rune = (A.DarkRune:GetCount() > 0 and A.DarkRune:GetCooldown() == 0 and A.DarkRune) or (A.DemonicRune:GetCount() > 0 and A.DemonicRune:GetCooldown() == 0 and A.DemonicRune) or nil 
			if Rune then 			
				if Runes >= 100 then -- AUTO 
					if Unit("player"):TimeToDie() <= 9 and Unit("player"):PowerPercent() <= 20 then 
						return Rune:Show(icon)	
					end 
				elseif Unit("player"):PowerPercent() <= Rune then 
					return Rune:Show(icon)								 
				end 
			end 
		end 
	end 
end 

function A.Rotation(icon)
	if not A.IsInitialized or not A[A.PlayerClass] then 
		return A.Hide(icon)		
	end 	
	
	local meta = icon.ID
	
	-- [1] CC / [2] Kick 
	if meta <= 2 then 
		if A[A.PlayerClass][meta] and A[A.PlayerClass][meta](icon) then 
			return true
		end 
		return A.Hide(icon)
	end 
	
	-- [5] Trinket 
	if meta == 5 then 
		-- Use racial available trinkets if we don't have additional RACIAL_LOC
		-- Note: Additional RACIAL_LOC is the main reason why I avoid here :AutoRacial (see below 'if isApplied then ')
		if A.GetToggle(1, "Racial") then 
			local RacialAction 	= A[A.PlayerClass][GetKeyByRace[A.PlayerRace]]			
			local RACIAL_LOC 	= LoC.GetExtra[A.PlayerRace]							-- Loss Of Control 
			if RACIAL_LOC and RacialAction and RacialAction:IsReady("player", true) and RacialAction:IsExists() then 
				local result, isApplied = LoC:IsValid(RACIAL_LOC.Applied, RACIAL_LOC.Missed, A.PlayerRace == "Dwarf" or A.PlayerRace == "Gnome")
				if result then 
					return RacialAction:Show(icon)
				end 
			end 		
		end	
		
		-- Use specialization spell trinkets
		if A[A.PlayerClass][meta] and A[A.PlayerClass][meta](icon) then  
			return true 			
		end 		
		
		-- Use racial if nothing is not available 
		if isApplied then 
			return RacialAction:Show(icon)
		end 
			
		return A.Hide(icon)		 
	end 
	
	local PauseChecks = A.PauseChecks()
	if PauseChecks then
		if meta == 3 then 
			return A:Show(icon, PauseChecks)
		end  
		return A.Hide(icon)		
	end 		
	
	-- [6] Passive: @player, @raid1, @arena1 
	if meta == 6 then 
		-- Shadowmeld
		if A[A.PlayerClass].Shadowmeld and A[A.PlayerClass].Shadowmeld:AutoRacial("player") then 
			return A[A.PlayerClass].Shadowmeld:Show(icon)
		end 
		
		-- Cursor 
		if A.GameTooltipClick and not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then 			
			if A.GameTooltipClick == "LEFT" then 
				return A:Show(icon, ACTION_CONST_LEFT)			 
			elseif A.GameTooltipClick == "RIGHT" then 
				return A:Show(icon, ACTION_CONST_RIGHT)
			end 
		end 
		
		-- ReTarget 
		if A.Zone == "pvp" and A:GetTimeSinceJoinInstance() >= 30 and A.LastTarget and not A.LastTargetIsExists then  
			return A:Show(icon, A.LastTargetTexture)
		end 
		
		if not Player:IsStealthed() then 
			-- Healthstone 
			local Healthstone = A.GetToggle(1, "HealthStone") 
			if Healthstone >= 0 then 
				local HealthStoneObject = GetHealthStone()
				if HealthStoneObject then 			
					if Healthstone >= 100 then -- AUTO 
						if Unit("player"):TimeToDie() <= 9 and Unit("player"):HealthPercent() <= 40 then 
							return HealthStoneObject:Show(icon)	
						end 
					elseif Unit("player"):HealthPercent() <= Healthstone then 
						return HealthStoneObject:Show(icon)								 
					end 
				end 
			end 		
		end 
		
		-- AutoTarget 
		if A.GetToggle(1, "AutoTarget") and Unit("player"):CombatTime() > 0 -- and not A.IamHealer
			-- No existed or switch in PvE if we accidentally selected out of combat unit  
			and (not Unit("target"):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and Unit("target"):CombatTime() == 0)) 
			-- If there PvE in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE, 1) >= 1) or A.Zone == "pvp")
		then 
			return A:Show(icon, ACTION_CONST_AUTOTARGET)			 
		end 
	end 
	
	-- Queue System
	if A.IsQueueReady(meta) then                                              
		return A.Data.Q[1]:Show(icon)				 
    end 
	
	-- Save unit for AutoAttack, AutoShoot
	local unit, useShoot
	if A.IsUnitEnemy("mouseover") then 
		unit = "mouseover"
	elseif A.IsUnitEnemy("target") then 
		unit = "target"
	elseif A.IsUnitEnemy("targettarget") then 
		unit = "targettarget"
	end 	
	
	-- [3] Single / [4] AoE: AutoAttack
	if unit and (meta == 3 or meta == 4) and not Player:IsStealthed() and Unit("player"):IsCastingRemains() == 0 then 
		useShoot = IsShoot(unit)
		if not useShoot and unit ~= "targettarget" and A.GetToggle(1, "AutoAttack") and (not Player:IsAttacking() or (Pet:IsActive() and not UnitIsUnit("pettarget", unit))) then 
			-- Cancel shoot because it doesn't reseting by /startattack and it will be stucked to shooting
			--if A.PlayerClass ~= "HUNTER" and Player:IsShooting() and HasWandEquipped() then 
				--return A:Show(icon, ACTION_CONST_AUTOSHOOT)
			--end 
			
			-- Use AutoAttack only if not a hunter or it's is out of range by AutoShot 
			if A.PlayerClass ~= "HUNTER" or not A.GetToggle(1, "AutoShoot") or not Player:IsShooting() or not A.AutoShot:IsInRange(unit) then 
				return A:Show(icon, ACTION_CONST_AUTOATTACK)
			end 
		end 
	end 
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-2, @raid1-3, @arena1-3
	if A[A.PlayerClass][meta] and A[A.PlayerClass][meta](icon) then 
		return true 
	end 
	
	-- [3] Single / [4] AoE: AutoShoot
	if useShoot and (meta == 3 or meta == 4) then 
		return A:Show(icon, ACTION_CONST_AUTOSHOOT)
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not A.GetToggle(1, "DisableClassPortraits") then 
		return A:Show(icon, ClassPortaits[A.PlayerClass])
	end 
	
	A.Hide(icon)			
end 