-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
--[[
If you plan to build profile without use lua then you can skip this guide
]]

-------------------------------------------------------------------------------
-- №1: Create snippet 
-------------------------------------------------------------------------------
-- Write in chat /tmw > LUA Snippets > Profile (left side) > "+" > Write name of class in title of the snippet

-------------------------------------------------------------------------------
-- №2: Set profile defaults 
-------------------------------------------------------------------------------
-- Map
local TMW = TMW 
local CNDT = TMW.CNDT 
local Env = CNDT.Env
local Action = Action

-- Create actions (spells, items, potions, auras, azerites, talents and etc)
-- Structure:
Action[Action.PlayerClass] = {	-- Action.PlayerClass is character class, msut be in upper case on english same as it does return /run select(2, UnitClass("player"))
	Key = Action.Create({ 		-- Key is name of the action which will be used in APL (Action Priority List)
	--[[@usage: attributes (table)
		Required: 
			Type (@string)	- Spell|SpellSingleColor|Item|ItemSingleColor|Potion|Trinket|TrinketBySlot|ItemBySlot|SwapEquip (TrinketBySlot, ItemBySlot is only in CORE!)
			ID (@number) 	- spellID | itemID | textureID (textureID only for Type "SwapEquip")
			Color (@string) - only if type is Spell|SpellSingleColor|Item|ItemSingleColor|SwapEquip, this will set color which stored in A.Data.C[Color] or here can be own hex 
	 	Optional: 
			Desc (@string) uses in UI near Icon tab (usually to describe relative action like Penance can be for heal and for dps and it's different actions but with same name)
			BlockForbidden (@boolean) uses to preset for action fixed block valid 
			QueueForbidden (@boolean) uses to preset for action fixed queue valid 
			Texture (@number) valid only if Type is Spell|Item|Potion|Trinket|SwapEquip
			FixedTexture (@number or @file) valid only if Type is Spell|Item|Potion|Trinket|SwapEquip
			MetaSlot (@number) allows set fixed meta slot use for action whenever it will be tried to set in queue 
			Hidden (@boolean) allows to hide from UI this action 
			isStance (@number) will check in :GetCooldown cooldown timer by GetShapeshiftFormCooldown function instead of default, only if Type is Spell|SpellSingleColor
			isTalent (@boolean) will check in :IsCastable method condition through :IsSpellLearned(), only if Type is Spell|SpellSingleColor
			isRank (@number) will use specified rank for spell (additional frame for color below TargetColor), only if Type is Spell|SpellSingleColor			
			isCP (@boolean) is used only for combo points with type Spell|SpellSingleColor to use as condition in Queue core, it's required to be noted manually due specific way of how it work
			useMaxRank (@boolean or @table) will overwrite current ID by highest available rank and apply isRank number, example of table use {1, 2, 4, 6, 7}, only if Type is Spell|SpellSingleColor 
			useMinRank (@boolean or @table) will overwrite current ID by lowest available rank and apply isRank number, example of table use {1, 2, 4, 6, 7}, only if Type is Spell|SpellSingleColor
			Equip1, Equip2 (@function) between which equipments do swap, used in :IsExists method, only if Type is SwapEquip
			
		So the conception of Classic is to use own texture for any ranks and additional frame which will determine rank whenever it need, we assume what by default no need to determine rank if we use useMaxRank
		Otherwise it will interract with additional frame  
	]]
	}),
}

-- For racials use following values as Key from racial key:
local RacialKeys = {
	NightElf = "Shadowmeld",
	Human = "Perception",
	Gnome = "EscapeArtist",
	Dwarf = "Stoneform",
	Scourge = "WilloftheForsaken",
	Troll = "Berserking",
	Tauren = "WarStomp",
	Orc = "BloodFury",
}

-- This code making shorter access to both tables Action[Action.PlayerClass] and Action
-- However if you prefer long access it still can be used like Action[Action.PlayerClass].Guard:IsReady(), it doesn't make any conflict if you will skip shorter access
-- So with shorter access you can just do A.Guard:IsReady() instead of Action[Action.PlayerClass].Guard:IsReady()
local A = setmetatable(Action[Action.PlayerClass], { __index = Action })

-- Example:
Action["WARRIOR"] = {
	POWS 									= Action.Create({ Type = "Spell", ID = 17}),
	PetKick 								= Action.Create({ Type = "Spell", ID = 47482, Color = "RED", Desc = "RED" }),  
	POWS_Rank2 								= Action.Create({ Type = "SpellSingleColor", ID = 17, Color = "BLUE", Desc = "Rank2" }), 
	TrinketTest 							= Action.Create({ Type = "Trinket", ID = 122530, QueueForbidden = true }),
	TrinketTest2 							= Action.Create({ Type = "Trinket", ID = 159611, QueueForbidden = true }),	
	PotionTest 								= Action.Create({ Type = "Potion", ID = 142117, QueueForbidden = true }),
	-- Mix will use action with ID 2983 as itself Rogue's Sprint but it will display Power Word: Shield with applied over color "LIGHT BLUE" and UI will displays Note with "Test", also Queue system will not run Queue with this action
	Sprint 									= Action.Create({ Type = "SpellSingleColor", ID = 2983, QueueForbidden = true, Desc = "Test", Color = "LIGHT BLUE", Texture = 17}),
	Guard								  	= Action.Create({ Type = "Spell", ID = 115295 	}),	
	HealingElixir						  	= Action.Create({ Type = "Spell", ID = 122281 	}),
	NimbleBrew 								= Action.Create({ Type = "Item", ID = 137648, Color = "RED" }),
	PotionofReconstitution				 	= Action.Create({ Type = "Potion", ID = 168502 	}), 	
	CoastalManaPotion						= Action.Create({ Type = "Potion", ID = 152495 	}),	
	-- Hidden 
	TigerTailSweep							= Action.Create({ Type = "Spell", ID = 264348, Hidden = true }), -- 4/1 Talent +2y increased range of LegSweep	
	RisingMist								= Action.Create({ Type = "Spell", ID = 274909, Hidden = true }), -- 7/3 Talent "Fistweaving Rotation by damage healing"
	SpiritoftheCrane						= Action.Create({ Type = "Spell", ID = 210802, Hidden = true }), -- 3/2 Talent "Mana regen by BlackoutKick"
	Innervate								= Action.Create({ Type = "Spell", ID = 29166, Hidden = true }), -- Aura Buff
	TeachingsoftheMonastery					= Action.Create({ Type = "Spell", ID = 202090, Hidden = true }), -- Aura Buff
	-- Racial
	ArcaneTorrent                         	= Action.Create({ Type = "Spell", ID = 50613 	}),
	BloodFury                             	= Action.Create({ Type = "Spell", ID = 20572  	}),
	Fireblood 							  	= Action.Create({ Type = "Spell", ID = 265221 	}),
	AncestralCall						  	= Action.Create({ Type = "Spell", ID = 274738 	}),
	Berserking                            	= Action.Create({ Type = "Spell", ID = 26297	}),
	ArcanePulse							  	= Action.Create({ Type = "Spell", ID = 260364	}),
	QuakingPalm							  	= Action.Create({ Type = "Spell", ID = 107079 	}),
	Haymaker							  	= Action.Create({ Type = "Spell", ID = 287712 	}), 
	WarStomp							  	= Action.Create({ Type = "Spell", ID = 20549 	}),
	BullRush							  	= Action.Create({ Type = "Spell", ID = 255654 	}),	
	GiftofNaaru 						  	= Action.Create({ Type = "Spell", ID = 59544	}),
	Shadowmeld							  	= Action.Create({ Type = "Spell", ID = 58984	}), 
	Stoneform						  		= Action.Create({ Type = "Spell", ID = 20594	}), 
	WilloftheForsaken				  		= Action.Create({ Type = "Spell", ID = 7744		}), 
	EscapeArtist						  	= Action.Create({ Type = "Spell", ID = 20589	}), 
	EveryManforHimself				  		= Action.Create({ Type = "Spell", ID = 59752	}), 
}

local A = setmetatable(Action["WARRIOR"], { __index = Action })

-------------------------------------------------------------------------------
-- №3: Create rotations
-------------------------------------------------------------------------------
--[[
If you didn't read 1. Introduction.lua, please, read it before you will read below
]]

-- Structure (described on shorter access):
A['@number'] = function(icon)		-- @number is from 1 to 8, where for example 1 is equal for "Meta Icon" #1 in "Shown Main" 
	-- icon is refference for that "Meta Icon" e.g. for that frame 
	
	-- your code:
	-- Key is what you used in Action[Action.PlayerClass] table 
	if A.Key:IsReady('@string', '@boolean') and "next rotation conditions which you want to use" then 																			                                           	
        return A.Key:Show(icon)    -- :Show(icon) method will make 'icon' frame display texture taken from 'Key'    		
    end 	
	
	--[[ mostly often useable methods (more info about methods in Action.lua):
	:IsReady(unit, skiprange)					-- checks block by Queue and SetBlocker, range for unit (if skiprange isn't true), action available (cooldown, useable by power as reactive e.g. example Execute) 
	:IsReadyP(unit, skiprange, skiplua)			-- does same but it skip block check 
	:AutoRacial(unit, isReadyCheck)				-- is already preconfigured template with logic conditions. isReadyCheck if true then will use method :IsReady 
	:AutoRacialP(unit, isReadyCheck)			-- same but without logic conditions, means will check only available (range, imun, school lock, cooldown and etc)
	]]
end

-- If you don't have any rotation or any time to make each meta frame rotation you can skip them and create just [3] for Single Rotation
-- Even if rest meta functions will be omitted 'The Action' core still will do shared general things for them (more info in Action.lua at the end)

-- Example:
local function IsSchoolFree()
	return A.LossOfControlIsMissed("SILENCE") and A.LossOfControl:Get("SCHOOL_INTERRUPT", "NATURE") == 0
end 

local function SelfDefensives()
	if CombatTime("player") == 0 then 
		return 
	end 
	
	local HealingElixir = A.GetToggle(2, "HealingElixir")
	if 	HealingElixir >= 0 and A.HealingElixir:IsReady("player") and Env.TalentLearn(A.HealingElixir.ID) and IsSchoolFree() and
		(
			( 	-- Auto 
				HealingElixir >= 85 and 
				(
					Env.UNITHP("player") <= 50 or
					(						
						Env.UNITHP("player") < 70 and 
						Env.ChargesFrac(A.HealingElixir.ID) > 1.1
					)
				)
			) or 
			(	-- Custom
				HealingElixir < 85 and 
				Env.UNITHP("player") <= HealingElixir
			)
		) 
	then 
		return A.HealingElixir
	end 
end 

-- [3] is Single Rotation
A[3] = function(icon)
	local Deffensive = SelfDefensives()
	if Deffensive then 
		return Deffensive:Show(icon)
	end 
	
	local ShouldStop = A.ShouldStop()
	local unit 
	
	local function DamageRotation(unit)
		if A.ArcaneTorrent:AutoRacial(unit, true) then 
			return A.ArcaneTorrent:Show(icon)
		end 	
		
		-- blackout_strike
		if not ShouldStop and A.BlackoutStrike:IsReady(unit) and A.BlackoutStrike:AbsentImun(unit, {"DamagePhysImun", "TotalImun"}) and A.LossOfControlIsMissed("DISARM") then 
			return A.BlackoutStrike:Show(icon)
		end 
	end 
	
	local function HealingRotation(unit)
		if A.ArcaneTorrent:AutoRacial(unit, true) then 
			return A.ArcaneTorrent:Show(icon)
		end 	
		
		if not ShouldStop and A.Vivify:IsReady(unit) and A.Vivify:AbsentImun(unit) and IsSchoolFree() and Env.UNITCurrentSpeed("player") == 0 and Env.PredictHeal("Vivify", A.Vivify.ID, unit) then 
			return A.Vivify:Show(icon)
		end 
	end 
	
	-- Mouseover 
	-- if you use IsUnitEnemy or IsUnitFriendly with "mouseover" or "targettarget" htne make sure what you created checkbox for ProfileUI with same DB name in LOWER CASE! Otherwise it will bring you an a error 
	if A.IsUnitEnemy("mouseover") then 
		unit = "mouseover"
		
		if DamageRotation(unit) then 
			return true 
		end 
	end 
	
	if A.IsUnitFriendly("mouseover") then 
		unit = "mouseover"	
		
		if HealingRotation(unit) then 
			return true 
		end 			
	end 
	
	-- Target 	
	if A.IsUnitEnemy("target") then 
		unit = "target"
		
		if DamageRotation(unit) then 
			return true 
		end 
	end 
	
	if A.IsUnitFriendly("target") then -- IsUnitEnemy("targettarget") is valid only inside here because macros supposed use damage rotation if @target is friendly and his @targettarget is enemy
		unit = "target"
		
		if HealingRotation(unit) then 
			return true 
		end 
	end 	
end  

--[[
You're not limited to use snippets, their fixed names and any lua codes inside them (limit if they are more than 6k+ lines :D) 
So you can even use HeroLib API actually (if it's available for Classic), that will be described in another documentation guide
]]

-------------------------------------------------------------------------------
-- №4: Apply rotations on TellMeWhen
-------------------------------------------------------------------------------
--[[
If you use "[GGL] Basic" then you can skip it because it has already preconfigured it 

For "Shown Main":
1. You have to create in /tmw new profile group with 8 icons with type "Condition Icon"
2. Right click on "Condition Icon" make checked "Hide Always"
3. At the bottom you will see "Conditions" tab, go there and click "+" to add condition "LUA"
4. Write next code: 
Action.Rotation(thisobj)
5. Click and drag itself "Condition Icon" frame to "Shown Main" group and select from opened menu "Add to meta"
6. Make sure if you moving "Condition Icon" #1 you additing it to "Meta Icon" #1 also in "Shown Main" 
7. Do same for each "Condition Icon"

For "Shown Cast Bars":
1. You have to create in /tmw new profile group with 3-9 icons with type "Casting" 
2. Right click on "Casting" make checked "Hide Always"
3. At the bottom you will see "Conditions" tab, go there and click "+" to add condition "LUA"
4. Write shared code which can be stored in ProfileUI snippet 
5. Don't forget which colors as casting bar icons use (look any [GGL] profile for colors), and also make sure what profile has "Flat" texture (you can check it in /tmw > 'General' > 'Main settings' (or 'Main options')
]]