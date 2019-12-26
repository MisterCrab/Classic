local TMW 									= TMW
local CNDT 									= TMW.CNDT
local Env 									= CNDT.Env
local strlowerCache  						= TMW.strlowerCache

local A   									= Action	
local Listener								= A.Listener
local insertMulti							= A.TableInsertMulti
local toNum 								= A.toNum
local strElemBuilder						= A.strElemBuilder
local Player 								= A.Player
local UnitCooldown							= A.UnitCooldown
local CombatTracker							= A.CombatTracker
local MultiUnits							= A.MultiUnits
local GetToggle								= A.GetToggle
local MouseHasFrame							= A.MouseHasFrame
local UnitInLOS								= A.UnitInLOS
local ThreatLib  							= LibStub("ThreatClassic-1.0")
local HealComm 								= LibStub("LibHealComm-4.0", true) -- Note: Leave it with true in case if will need to disable lib, seems lib causing unexpected lua errors in PvP 
local LibRangeCheck  						= LibStub("LibRangeCheck-2.0")
local LibBossIDs							= LibStub("LibBossIDs-1.0").BossIDs
local LibClassicCasterino 					= LibStub("LibClassicCasterino")
-- To activate it
LibClassicCasterino.callbacks.OnUsed() 

local TeamCache								= A.TeamCache
local TeamCachethreatData					= TeamCache.threatData
local TeamCacheFriendly 					= TeamCache.Friendly
--local TeamCacheFriendlyUNITs				= TeamCacheFriendly.UNITs
--local TeamCacheFriendlyGUIDs				= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs		= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs			= TeamCacheFriendly.IndexToPETs
local TeamCacheEnemy 						= TeamCache.Enemy
--local TeamCacheEnemyUNITs					= TeamCacheEnemy.UNITs
--local TeamCacheEnemyGUIDs					= TeamCacheEnemy.GUIDs
local TeamCacheEnemyIndexToPLAYERs			= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local ActiveUnitPlates						= MultiUnits:GetActiveUnitPlates()
local ActiveUnitPlatesAny					= MultiUnits:GetActiveUnitPlatesAny()

local _G, setmetatable, unpack, select, next, type, pairs, ipairs, math, error  =
	  _G, setmetatable, unpack, select, next, type, pairs, ipairs, math, error 
	  
local ALL_HEALS								= HealComm and HealComm.ALL_HEALS	  
local ACTION_CONST_INVSLOT_OFFHAND			= _G.ACTION_CONST_INVSLOT_OFFHAND
local ACTION_CONST_AURAS_MAX_LIMIT			= _G.ACTION_CONST_AURAS_MAX_LIMIT
local ACTION_CONST_MAX_BOSS_FRAMES			= _G.ACTION_CONST_MAX_BOSS_FRAMES
local ACTION_CONST_CACHE_DISABLE			= _G.ACTION_CONST_CACHE_DISABLE
local ACTION_CONST_CACHE_MEM_DRIVE			= _G.ACTION_CONST_CACHE_MEM_DRIVE
local ACTION_CONST_CACHE_DISABLE			= _G.ACTION_CONST_CACHE_DISABLE
local ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT = _G.ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT
local ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE	= _G.ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE
	
local huge 									= math.huge	  
local math_floor							= math.floor	
local math_random							= math.random
local wipe 									= _G.wipe 
local strsplit								= _G.strsplit
local debugstack							= _G.debugstack
	  
local CombatLogGetCurrentEventInfo			= _G.CombatLogGetCurrentEventInfo	  
local GetUnitSpeed							= _G.GetUnitSpeed
local GetSpellInfo							= _G.GetSpellInfo
local GetPartyAssignment 					= _G.GetPartyAssignment	  
local UnitIsUnit, UnitPlayerOrPetInRaid, UnitInAnyGroup, UnitPlayerOrPetInParty, UnitInRange, UnitLevel, UnitRace, UnitClass, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible, UnitDebuff =
	  UnitIsUnit, UnitPlayerOrPetInRaid, UnitInAnyGroup, UnitPlayerOrPetInParty, UnitInRange, UnitLevel, UnitRace, UnitClass, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible, UnitDebuff
local UnitAura 								= TMW.UnitAura	  
	  
--local UnitThreatSituation					= function(unit, mob) return ThreatLib:UnitThreatSituation(unit, mob) end 
local UnitDetailedThreatSituation			= function(unit, mob) return ThreatLib:UnitDetailedThreatSituation(unit, mob) end 
-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_GetSpellInfo, A_GetGCD, A_GetCurrentGCD, A_EnemyTeam, A_GetUnitItem

Listener:Add("ACTION_EVENT_UNIT", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit						= A.Unit		
		A_GetSpellInfo				= A.GetSpellInfo	
		A_GetGCD					= A.GetGCD
		A_GetCurrentGCD				= A.GetCurrentGCD
		A_EnemyTeam					= A.EnemyTeam	
		A_GetUnitItem				= A.GetUnitItem
		
		Listener:Remove("ACTION_EVENT_UNIT", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------	

-------------------------------------------------------------------------------
-- Cache
-------------------------------------------------------------------------------
local str_none = "none"
local str_empty = ""

local function PseudoClass(methods)
    local Class = setmetatable(methods, {
		__call = function(self, ...)
			self:New(...)
			return self				 
		end,
    })
    return Class
end

local Cache = {
	bufer = {},	
	newEl = function(this, inv, keyArg, func, ...)
		if not this.bufer[func][keyArg] then 
			this.bufer[func][keyArg] = { v = {} }
		else 
			wipe(this.bufer[func][keyArg].v)
		end 
		this.bufer[func][keyArg].t = TMW.time + (inv or ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT) + 0.001  -- Add small delay to make sure what it's not previous corroute  
		insertMulti(this.bufer[func][keyArg].v, func(...))
		return unpack(this.bufer[func][keyArg].v)
	end,
	Wrap = function(this, func, name)
		if ACTION_CONST_CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = {} 
		end
		
   		return function(...)   
			-- The reason of all this view look is memory hungry eating, this way use around 0 memory now
			local self = ...		
			local keyArg = strElemBuilder(name == "UnitGUID" and UnitGUID(self.UnitID) or self.UnitID or self.ROLE or name, ...)		

	        if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then
	            return this:newEl(self.Refresh, keyArg, func, ...)
	        else
	            return unpack(this.bufer[func][keyArg].v)
	        end
        end        
    end,
	Pass = function(this, func, name) 
		if ACTION_CONST_CACHE_MEM_DRIVE and not ACTION_CONST_CACHE_DISABLE then 
			return this:Wrap(func, name)
		end 

		return func
	end,
}

local AuraList = {
    -- CC SCHOOL TYPE 
    Magic = {         
		853, 				-- Hammer of Justice 		(Paladin)
		20066, 				-- Repentance				(Paladin)
		17390,				-- Faerie Fire (Feral)		(Druid)		
		2637, 				-- Hibernate 				(Druid)
		1499, 				-- Freezing Trap			(Hunter)
		118, 				-- Polymorph				(Mage)
		851,				-- Polymorph: Sheep 		(Mage)
		28270,				-- Polymorph: Cow			(Mage)
		605, 				-- Mind Control 			(Priest)                 
        8122, 				-- Psychic Scream			(Priest)
		9484, 				-- Shackle Undead 			(Priest)  				
		15487, 				-- Silence 					(Priest)
        5782, 				-- Fear						(Warlock)        
        6358, 				-- Seduction 				(Warlock)
        5484, 				-- Howl of Terror        	(Warlock)        
		710, 				-- Banish 					(Warlock)
		-- Roots 
        22519, 				-- Ice Nova 				(Mage)
        122, 				-- Frost Nova 				(Mage)		
        339, 				-- Entangling Roots 		(Druid)		
    },
    MagicRooted = {
        22519, 				-- Ice Nova 				(Mage)
        122, 				-- Frost Nova 				(Mage)		
        339, 				-- Entangling Roots 		(Druid)
    }, 
    Curse = {
		8277, 				-- Voodoo Hex   			(Shaman) 				-- I AM NOT SURE
	},
    --Disease = {},
    Poison = {
        24133, 				-- Wyvern Sting 			(Hunter)
        3034, 				-- Viper Sting 				(Hunter)
        3043,		 		-- Scorpid Sting 			(Hunter)
		7992, 				-- Slowing Poison 			(Rogue)
		3408, 				-- Crippling Poison 		(Rogue)
    },
    Physical = {
		7922, 				-- Charge Stun				(Warrior)
		676, 				-- Disarm 					(Warrior)
		5246, 				-- Intimidating Shout		(Warrior)
		12809,				-- Concussion Blow			(Warrior)
		20253,				-- Intercept Stun 			(Warrior)
		5211,				-- Bash						(Druid)
		9005,				-- Pounce					(Druid)
		12355,				-- Impact					(Mage, physical effect)
		19503, 				-- Scatter Shot 			(Hunter)
		19577,				-- Intimidation 			(Hunter)  				-- Berserker Rage can remove it!
		19410,				-- Improved Concussive Shot	(Hunter)
		408, 				-- Kidney Shot 				(Rogue)	
		1833, 				-- Cheap Shot 				(Rogue)        
		1776, 				-- Gouge					(Rogue)		
		6770, 				-- Sap 						(Rogue)
		2094, 				-- Blind					(Rogue)		        
		20549, 				-- War Stomp 				(Tauren)	
		20685,				-- Storm Bolt 				(Unknown)				-- FIX ME: Is it useable?
		5530,				-- Mace Stun				(Unknown)
		16922,				-- Starfire Stun			(Unknown)
   },
    -- CC CONTROL TYPE
    Incapacitated = { 
        1499, 				-- Freezing Trap			(Hunter) 
        20066, 				-- Repentance				(Paladin)
		6770, 				-- Sap 						(Rogue)
        1776, 				-- Gouge					(Rogue)
		710, 				-- Banish        			(Warlock)
		22570,				-- Mangle					(Druid)
    },
	Fleeing	= {
		5782, 				-- Fear						(Warlock)
		5484, 				-- Howl of Terror   		(Warlock)
		5246, 				-- Intimidating Shout		(Warrior)
		8122, 				-- Psychic Scream			(Priest)
	},
	Shackled = {
		9484, 				-- Shackle Undead 			(Priest)	
	},
	Polymorphed	= {
		118, 				-- Polymorph				(Mage)
		851,				-- Polymorph: Sheep 		(Mage)
		28270,				-- Polymorph: Cow			(Mage)
		28272,				-- Polymorph: Pig			(Mage)
		28271,				-- Polymorph: Turtle		(Mage)
	},
    Disoriented = {			
		19503, 				-- Scatter Shot 			(Hunter)		 
        2094, 				-- Blind					(Rogue)
    },    
    Fear = {
		5782, 				-- Fear						(Warlock)
		5484, 				-- Howl of Terror   		(Warlock)
		5246, 				-- Intimidating Shout		(Warrior)
		6789,				-- Death Coil				(Warlock)
		8122, 				-- Psychic Scream			(Priest)
    },
    Charmed = {
        605, 				-- Mind Control 			(Priest)                 
        --9484, 				-- Shackle Undead 			(Priest)
    },
    Sleep = {
		2637, 				-- Hibernate 				(Druid)	
		19386, 				-- Wyvern Sting 			(Hunter)
	},
    Stuned = {
		7922, 				-- Charge Stun				(Warrior)
		12809,				-- Concussion Blow			(Warrior)
		20253,				-- Intercept Stun 			(Warrior)
		5530,				-- Mace Stun Effect			(Warrior)
		12798,				-- Revenge Stun				(Warrior)
		5211,				-- Bash						(Druid)
		9005,				-- Pounce					(Druid)
		12355,				-- Impact					(Mage, physical effect)
		22703,				-- Inferno Effect			(Warlock)
		18093,				-- Pyroclasm				(Warlock)
		19577,				-- Intimidation 			(Hunter)  				-- Berserker Rage can remove it!
		19410,				-- Improved Concussive Shot	(Hunter)
		853, 				-- Hammer of Justice 		(Paladin)
		1833, 				-- Cheap Shot 				(Rogue)
        408, 				-- Kidney Shot 				(Rogue)	
		20549, 				-- War Stomp 				(Tauren)
		20685,				-- Storm Bolt 				(Unknown)				-- FIX ME: Is it useable?			
		16922,				-- Starfire Stun			(Unknown)
		56,					-- Stun 					(Weapon proc)
		4067,				-- Big Bronze Bomb
		4066,				-- Small Bronze Bomb
		4065,				-- Large Copper Bomb
		4064,				-- Rough Copper Bomb
		13808,				-- M73 Frag Grenade
		19769,				-- Thorium Grenade
	},
    PhysStuned = {
		7922, 				-- Charge Stun				(Warrior)
		12809,				-- Concussion Blow			(Warrior)
		20253,				-- Intercept Stun 			(Warrior)
		5530,				-- Mace Stun Effect			(Warrior)
		12798,				-- Revenge Stun				(Warrior)
		5211,				-- Bash						(Druid)
		9005,				-- Pounce					(Druid)		
		12355,				-- Impact					(Mage, physical effect)
		22703,				-- Inferno Effect			(Warlock)
		18093,				-- Pyroclasm				(Warlock)
		19577,				-- Intimidation 			(Hunter)  				-- Berserker Rage can remove it!
		19410,				-- Improved Concussive Shot	(Hunter)
		1833, 				-- Cheap Shot 				(Rogue)
        408, 				-- Kidney Shot 				(Rogue)		
		20549, 				-- War Stomp 				(Tauren)	
		20685,				-- Storm Bolt	 			(Unknown)				-- FIX ME: Is it useable?		
		16922,				-- Starfire Stun			(Unknown)		
		56,					-- Stun 					(Weapon proc)	
		4067,				-- Big Bronze Bomb
		4066,				-- Small Bronze Bomb
		4065,				-- Large Copper Bomb
		4064,				-- Rough Copper Bomb
	},
    Silenced = {
		15487, 				-- Silence 					(Priest) 
		18469,				-- Counterspell - Silenced	(Mage)
		18425,				-- Kick - Silenced			(Rogue)
		24259,				-- Spell Lock (Felhunter) 	(Warlock)
		19821,				-- Arcane Bomb
		18278,				-- Silence (Silent Fang sword)
	},
    Disarmed = {
		676, 				-- Disarm 					(Warrior)
		14251,				-- Riposte					(Rogue)
		23365,				-- Dropped Weapon			(Unknown)
	},
    Rooted = {
		23694,				-- Improved Hamstring		(Warrior)
        22519, 				-- Ice Nova 				(Mage)
        122, 				-- Frost Nova 				(Mage)	
		12494,				-- Frostbite				(Mage)	
        339, 				-- Entangling Roots 		(Druid)
		19675,				-- Feral Charge Effect		(Druid)
		19229,				-- Improved Wing Clip 		(Hunter)
		19185,				-- Entrapment				(Hunter)
		25999,				-- Boar Charge				(Hunter's pet)		
    },  
    Slowed = {		
        1715, 				-- Hamstring				(Warrior)
		12323, 				-- Piercing Howl			(Warrior)
        3408, 				-- Crippling Poison			(Rogue)        
        7992, 				-- Slowing Poison			(Rogue)
		2974, 				-- Wing Clip				(Hunter)
		5116, 				-- Concussive Shot			(Hunter)
        13496, 				-- Dazed (aka "confuse")	(Druid, Hunter)        
        17311, 				-- Mind Flay				(Priest)                               
        2484, 				-- Earthbind				(Shaman)
        8056, 				-- Frost Shock				(Shaman)
		8034, 				-- Frostbrand Attack		(Shaman)
		116, 				-- Frostbolt     			(Mage)
		120, 				-- Cone of Cold				(Mage)
        6136, 				-- Chilled 					(Mage)		
		16094, 				-- Frost Breath 			(Mage)        
		11113, 				-- Blast Wave				(Mage)
		3604, 				-- Tendon Rip				(Unknown)
    },
    MagicSlowed = {        
        2484, 				-- Earthbind				(Shaman)
        8056, 				-- Frost Shock				(Shaman)
		8034, 				-- Frostbrand Attack		(Shaman)				-- FIX ME: I AM NOT SURE 		
        6136, 				-- Chilled 					(Mage)	 				-- FIX ME: I AM NOT SURE 
		16094, 				-- Frost Breath 			(Mage)					-- FIX ME: I AM NOT SURE 
        120, 				-- Cone of Cold 			(Mage)
		116, 				-- Frostbolt     			(Mage)
    },
    BreakAble = {
		5246, 				-- Intimidating Shout		(Warrior)
        20066, 				-- Repentance				(Paladin)		
		2637, 				-- Hibernate				(Druid)
		118, 				-- Polymorph				(Mage)
		851,				-- Polymorph: Sheep 		(Mage)
		28270,				-- Polymorph: Cow			(Mage)
		28272,				-- Polymorph: Pig			(Mage)
		28271,				-- Polymorph: Turtle		(Mage)
		1499, 				-- Freezing Trap			(Hunter)
		19386, 				-- Wyvern Sting   			(Hunter)	
		19503, 				-- Scatter Shot        		(Hunter)
        6770, 				-- Sap 						(Rogue)
		2094, 				-- Blind					(Rogue) 
		1776, 				-- Gouge					(Rogue)
        5782, 				-- Fear						(Warlock)        
        6358, 				-- Seduction (pet)			(Warlock)                
        5484, 				-- Howl of Terror			(Warlock)
        8122, 				-- Psychic Scream			(Priest)      
		9484, 				-- Shackle Undead 			(Priest)			
        -- Rooted CC
        339, 				-- Entangling Roots			(Druid)
        122, 				-- Frost Nova				(Mage)
    },
    -- Imun Specific Buffs 
    FearImun = {
		18499, 				-- Berserker Rage 			(Warrior)
		12328,				-- Death Wish				(Warrior)
		1719,				-- Recklessness				(Warrior)
        8143, 				-- Tremor Totem 			(Shaman)
		6346,				-- Fear Ward				(Priest)
    },
    StunImun = {
        6615, 				-- Free Action 				(Free Action Potion)
		24364,				-- Living Free Action		(Potion)
        1953, 				-- Blink (micro buff)		(Mage)
    },        
    Freedom = {
		6615, 				-- Free Action 				(Free Action Potion)
		1044, 				-- Blessing of Freedom		(Paladin)
		24364,				-- Living Free Action		(Potion)
	},
    TotalImun = {
		710, 				-- Banish 					(Warlock)
		498, 				-- Divine Protection		(Paladin)
        642, 				-- Divine Shield			(Paladin)		
        11958, 				-- Ice Block				(Mage)
        19263, 				-- Deterrence    			(Hunter)
        20711, 				-- Spirit of Redemption		(Priest)
		17624,				-- Petrification			(Flask of Petrification)
    },
    DamagePhysImun = {		
		1022, 				-- Blessing of Protection	(Paladin)
		3169,				-- Invulnerability			(Limited Invulnerability Potion)
		--16621,			-- Self Invulnerability (Invulnerable Mail weapon) -- FIX ME: seems only for swing attacks
	},
    DamageMagicImun = {}, 
    CCTotalImun = {},     
    CCMagicImun = {
		8178,				-- Grounding Totem Effect	(Shaman)
	},
    Reflect = { 
        8178, 				-- Grounding Totem Effect	(Shaman)
        23131, 				-- Frost Reflector			(Item)
        23132, 				-- Shadow Reflector			(Item)
        23097, 				-- Fire Reflector			(Item)
    }, 
    KickImun = {},
    -- Purje 
    ImportantPurje = {
        1022, 				-- Blessing of Protection	(Paladin)
        20216, 				-- Divine Favor 			(Paladin)		
        11129, 				-- Combustion 				(Mage)
        12042, 				-- Arcane Power 			(Mage)
        10060, 				-- Power Infusion			(Priest)
		29166,				-- Innervate				(Druid)
		2645, 				-- Ghost Wolf 				(Shaman)
    },
    SecondPurje = {
        1044, 				-- Blessing of Freedom      (Paladin)  
        -- We need purje druid only in bear form 
		467,				-- Thorns					(Druid)
        774, 				-- Rejuvenation				(Druid)
        8936, 				-- Regrowth 				(Druid)
        1126, 				-- Mark of the Wild			(Druid)
    },
    -- Speed 
    Speed = {
        2983, 				-- Sprint 					(Rogue)
        2379, 				-- Speed 					(Swiftness Potion)
        2645, 				-- Ghost Wolf 				(Shaman)
		1850, 				-- Dash 					(Druid)
		5118, 				-- Aspect of the Cheetah	(Hunter)       
    },
    -- Deff 
    DeffBuffsMagic = {
		8178, 				-- Grounding Totem Effect	(Shaman)
		--498, 					-- Divine Protection		(Paladin)
        --642, 					-- Divine Shield			(Paladin)
        --11958, 				-- Ice Block				(Mage)
        --19263, 				-- Deterrence    			(Hunter)
        --20711, 				-- Spirit of Redemption		(Priest)		
    }, 
    DeffBuffs = {        
		871,				-- ShieldWall				(Warrior)
		20230,				-- Retaliation				(Warrior)
		5277, 				-- Evasion					(Rogue)
		1022, 				-- Blessing of Protection	(Paladin)
		22812,				-- Barkskin					(Druid)
		3169,				-- Invulnerability			(Limited Invulnerability Potion)
		--498, 					-- Divine Protection		(Paladin)
        --642, 					-- Divine Shield			(Paladin)
        --11958, 				-- Ice Block				(Mage)
        --19263, 				-- Deterrence    			(Hunter)
        --20711, 				-- Spirit of Redemption		(Priest)		
    },  
	SmallDeffBuffs = {
		20594,				-- Stoneform				(Dwarf)
		6940, 				-- Blessing of Sacrifice	(Paladin)
	},
    -- Damage buffs / debuffs
    Rage = {
        18499, 				-- Berserker Rage (Warrior)
        12880, 				-- Enrage (Warrior)
    }, 
    DamageBuffs = {        
		12328,				-- Death Wish 				(Warrior)		
		1719,				-- Recklessness				(Warrior)
		13877,				-- Blade Flurry				(Rogue)
		13750,				-- Adrenaline Rush			(Rogue)
		19574,				-- Bestial Wrath			(Hunter)
		11129, 				-- Combustion 				(Mage)
		12042, 				-- Arcane Power 			(Mage)
		26297,				-- Berserking				(Troll)
		20572,				-- Blood Fury				(Orc)
    },
    DamageBuffs_Melee = {        
		12328,				-- Death Wish 				(Warrior)	
		1719,				-- Recklessness				(Warrior)
        13750,				-- Adrenaline Rush			(Rogue)
		13877,				-- Blade Flurry				(Rogue)		
    },
    BurstHaste = {
        19372, 				-- Ancient Hysteria 		(Unknown)
        24185, 				-- Bloodlust 				(Unknown)
    },
    -- SOME SPECIAL
    --DamageDeBuffs = {}, 
    Flags = {
        301091, 			-- Alliance flag
        301089,  			-- Horde flag 
		23333,				-- Warsong Flag
        23335,  			-- Silverwing Flag
    }, 
    -- Cast Bars
    Reshift = {
        {118, 30}, 			-- Polymorph 				(Mage)
        {19386, 35, 8},		-- Wyvern Sting (8 - 35)	(Hunter)
    },
    Premonition = {
        {118, 30}, 			-- Polymorph 				(Mage)
		{851, 20},			-- Polymorph: Sheep 		(Mage)
		{28270, 30},		-- Polymorph: Cow	 		(Mage)
		{28272, 30},		-- Polymorph: Pig	 		(Mage)
		{28271, 30},		-- Polymorph: Turtle 		(Mage)
        {24133, 35, 8},		-- Wyvern Sting (8 - 35)	(Hunter)
		{5782, 20}, 		-- Fear 					(Warlock)        
    },
    CastBarsCC = {
        118, 				-- Polymorph 				(Mage)
		851,				-- Polymorph: Sheep 		(Mage)
		28270,				-- Polymorph: Cow			(Mage)
        20066, 				-- Repentance 				(Paladin)
        24133, 				-- Wyvern Sting 			(Hunter)
        5782, 				-- Fear 					(Warlock) 
		5484, 				-- Howl of Terror   		(Warlock)
        605, 				-- Mind Control 			(Priest)                 
        9484, 				-- Shackle Undead 			(Priest) 
    },
    AllPvPKickCasts = {    
        118, 				-- Polymorph 				(Mage)
		851,				-- Polymorph: Sheep 		(Mage)
		28270,				-- Polymorph: Cow			(Mage)
		635,				-- Holy Light				(Paladin)
		19750,				-- Flash of Light			(Paladin)
        20066, 				-- Repentance 				(Paladin)		
		5782, 				-- Fear 					(Warlock) 
        19386, 				-- Wyvern Sting 			(Hunter)       
        982, 				-- Revive Pet 				(Hunter)
		605, 				-- Mind Control 			(Priest)  
		9484, 				-- Shackle Undead 			(Priest) 
        4526, 				-- Mass Dispel 				(Priest)	
		596, 				-- Prayer of Healing		(Priest)
		2060,				-- Greater Heal				(Priest)
		2061,				-- Flash Heal				(Priest)
		740, 				-- Tranquility				(Druid)
        20484, 				-- Rebirth					(Druid)
		25297,				-- Healing Touch			(Druid)
		8936, 				-- Regrowth 				(Druid)
		331,				-- Healing Wave				(Shaman)
		1064,				-- Chain Heal				(Shaman)
    },    
}

local AssociativeTables = setmetatable({ NullTable = {} }, { -- Only for Auras!
	--__mode = "kv",
	__index = function(t, v)
	-- @return table 
	-- Returns converted array like table to associative like with key-val as spellName and spellID with true val
	-- For situations when Action is not initialized and when 'v' is table always return self 'v' to keep working old profiles which use array like table
	-- Note: GetSpellInfo instead of A_GetSpellInfo because we will use it one time either if GC collected dead links, pointless for performance A_GetSpellInfo anyway
	if not v then
		if A.IsInitialized then 
			local error_snippet = debugstack():match("%p%l+%s\"?%u%u%u%s%u%l.*")
			if error_snippet then 
				error("Unit.lua script tried to put in AssociativeTables 'nil' as index and it caused null table return. The script successfully found the first occurrence of the error stack in the TMW snippet: " .. error_snippet, 0)
			else 
				error("Unit.lua script tried to put in AssociativeTables 'nil' as index and it caused null table return. Failed to find TMW snippet stack error. Below must be shown level of stack 1.", 1)
			end 
		end 
		return t.NullTable
	end 
	
	local v_type = type(v)
	if v_type == "table" then  
		if #v > 0 then 
			t[v] = {}
		
			local index, val = next(v)
			while index ~= nil do 
				if type(val) == "string" then 
					if AuraList[val] then
						-- Put associatived spellName (@string) and spellID (@number)
						for spellNameOrID, spellBoolean in pairs(t[val]) do 
							t[v][spellNameOrID] = spellBoolean 
						end 
					else -- Here is expected name of the spell always  
						-- Put associatived spellName (@string)
						t[v][val] = true 
					end 
				else -- Here is expected id of the spell always 
					-- Put associatived spellName (@string)
					local spellName = GetSpellInfo(val) 
					if spellName then
						t[v][spellName] = true 
					end 
					
					-- Put associatived spellID (@number)
					t[v][val] = true 
				end 
				
				index, val = next(v, index)
			end 
		else 
			t[v] = v
		end 			
	elseif AuraList[v] then
		t[v] = {}
		
		local spellName
		for _, spellID in ipairs(AuraList[v]) do 
			spellName = GetSpellInfo(spellID) 
			if spellName then 
				t[v][spellName] = true 
			end 
			t[v][spellID] = true
		end 		
	else
		-- Otherwise create new table and put spellName with spellID (if possible) for single entrance to keep return @table 
		t[v] = {}
				
		--local spellName = GetSpellInfo(v_type == "string" and not v:find("%D") and toNum[v] or v) -- TMW lua code passing through 'thisobj.Name' @string type 
		-- Since Classic hasn't 'thisobj.Name' ways in profiles at all we will avoid use string functions 
		local spellName = GetSpellInfo(v)
		if spellName then 
			t[v][spellName] = true 
		end 		 
		
		t[v][v] = true   
	end 
	
	--print("Created associatived table:")
	--print(tostring(v), "  Output:", tostring(t[v]), " Key:", next(t[v]))
	
	return t[v] 
end })

-- Classic has always associative spellinput
--local IsMustBeByID = {}
--local function IsAuraEqual(spellName, spellID, spellInput, byID)
--	-- @return boolean 
--	if byID then 
--		if #spellInput > 0 then 				-- ArrayTables
--			for i = 1, #spellInput do 
--				if AuraList[spellInput[i]] then 
--					for _, auraListID in ipairs(AuraList[spellInput[i]]) do 
--						if spellID == auraListID then 
--							return true 
--						end 
--					end 
--				elseif spellID == spellInput[i] then 
--					return true 
--				end 
--			end
--		else 									-- AssociativeTables
--			return spellInput[spellID]
--		end 
--	else 
--		if #spellInput > 0 then 				-- ArrayTables
--			for i = 1, #spellInput do 
--				if AuraList[spellInput[i]] then 
--					for _, auraListID in ipairs(AuraList[spellInput[i]]) do 
--						if spellName == A_GetSpellInfo(auraListID) then 
--							return true 
--						end 
--					end 
--				elseif IsMustBeByID[spellInput[i]] then -- Retail only 
--					if spellID == spellInput[i] then 
--						return true 
--					end 
--				elseif spellName == A_GetSpellInfo(spellInput[i]) then 
--					return true 
--				end 
--			end 
--		else 									-- AssociativeTables
--			return spellInput[spellName]
--		end 
--	end 
--end

-------------------------------------------------------------------------------
-- API: Core (Action Rotation Conditions)
-------------------------------------------------------------------------------
function A.GetAuraList(key)
	-- @return table 
    return AuraList[key]
end 

function A.IsUnitFriendly(unitID)
	-- @return boolean
	if unitID == "mouseover" then 
		return 	GetToggle(2, unitID) and MouseHasFrame() and not A_Unit(unitID):IsEnemy() 
	else
		return 	(
					not GetToggle(2, "mouseover") or 
					not A_Unit("mouseover"):IsExists() or 
					A_Unit("mouseover"):IsEnemy()
				) and 
				not A_Unit(unitID):IsEnemy() and
				A_Unit(unitID):IsExists()
	end 
end 
A.IsUnitFriendly = A.MakeFunctionCachedDynamic(A.IsUnitFriendly)

function A.IsUnitEnemy(unitID)
	-- @return boolean
	if unitID == "mouseover" then 
		return  GetToggle(2, unitID) and A_Unit(unitID):IsEnemy() 
	elseif unitID == "targettarget" then
		return 	GetToggle(2, unitID) and 
				( not GetToggle(2, "mouseover") or (not MouseHasFrame() and not A_Unit("mouseover"):IsEnemy()) ) and 
				-- Exception to don't pull by mistake mob
				A_Unit(unitID):CombatTime() > 0 and
				not A_Unit("target"):IsEnemy() and
				A_Unit(unitID):IsEnemy() and 
				-- LOS checking 
				not UnitInLOS(unitID)						
	else
		return 	( not GetToggle(2, "mouseover") or not MouseHasFrame() ) and A_Unit(unitID):IsEnemy() 
	end
end 
A.IsUnitEnemy = A.MakeFunctionCachedDynamic(A.IsUnitEnemy)

-------------------------------------------------------------------------------
-- API: Unit 
-------------------------------------------------------------------------------
local Info = {
	CacheMoveIn					= setmetatable({}, { __mode = "kv" }),
	CacheMoveOut				= setmetatable({}, { __mode = "kv" }),
	CacheMoving 				= setmetatable({}, { __mode = "kv" }),
	CacheStaying				= setmetatable({}, { __mode = "kv" }),
	CacheInterrupt 				= setmetatable({}, { __mode = "kv" }),
	SpecIs 						= {
        ["MELEE"] 				= {103, 255, 70, 259, 260, 261, 263, 71, 72, 66, 73},
        ["RANGE"] 				= {102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
        ["HEALER"] 				= {105, 65, 256, 257, 264},
        ["TANK"] 				= {103, 66, 73},
        ["DAMAGER"] 			= {255, 70, 259, 260, 261, 263, 71, 72, 102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
    },
	ClassCanBeHealer			= {
		["PALADIN"] 			= true,
		["PRIEST"]				= true,
		["SHAMAN"] 				= true,
		["DRUID"] 				= true,	
	},
	ClassCanBeTank				= {
        ["WARRIOR"] 			= true,
        ["PALADIN"] 			= true,
        ["DRUID"] 				= true,	
	},
	ClassCanBeMelee				= {
        ["WARRIOR"] 			= true,
        ["PALADIN"] 			= true,
        ["ROGUE"] 				= true,
        ["SHAMAN"] 				= true,
        ["DRUID"] 				= true,		
	},
	AllCC 						= {"Silenced", "Stuned", "Sleep", "Fear", "Disoriented", "Incapacitated"},
	IsUndead					= {
		["Undead"]				= true, 
        ["Untoter"]				= true, 
        ["No-muerto"]			= true, 
        ["No-muerto"]			= true, 
        ["Mort-vivant"]			= true, 
        ["Non Morto"]			= true, 
        ["Renegado"]			= true, 
        ["Нежить"]				= true,  
		["언데드"]					= true,
		["亡灵"]				= true,
		["不死族"]				= true,
		[""]					= false,		
	},
	IsTotem 					= {
		["Totem"]				= true,
		["Tótem"]				= true,
		["Totém"]				= true,
		["Тотем"]				= true,
		["토템"]					= true,
		["图腾"]				= true,
		["圖騰"]				= true,
		[""]					= false,
	},
	IsDummy 					= {
		-- City (SW, Orgri, ...)
		[5652] 			= true, 
		[4952] 			= true,
		[4957] 			= true,
		[5723] 			= true,
		[1921] 			= true,
		[12426] 		= true, 
		[12385] 		= true,
		[11875] 		= true,
		[16211] 		= true, 
		[2674] 			= true, 
		[2673] 			= true,
		[5202]	 		= true, 
		[14831] 		= true, -- Unkillable Test Dummy 63 Warrior
	},
	IsBoss 						= {
		[14831] 		= true, -- Unkillable Test Dummy 63 Warrior
	},
	IsNotBoss 					= {
	},
	ControlAbleClassification 	= {
		["trivial"] 			= true,
		["minus"] 				= true,
		["normal"] 				= true,
		["rare"] 				= true,
		["rareelite"] 			= false,
		["elite"] 				= false,
		["worldboss"] 			= false,
		[""] 					= true,
	},
}

local InfoCacheMoveIn						= Info.CacheMoveIn
local InfoCacheMoveOut						= Info.CacheMoveOut
local InfoCacheMoving						= Info.CacheMoving
local InfoCacheStaying						= Info.CacheStaying
local InfoCacheInterrupt					= Info.CacheInterrupt

local InfoSpecIs 							= Info.SpecIs
local InfoClassCanBeHealer 					= Info.ClassCanBeHealer
local InfoClassCanBeTank 					= Info.ClassCanBeTank
local InfoClassCanBeMelee 					= Info.ClassCanBeMelee
local InfoAllCC 							= Info.AllCC

local InfoIsUndead							= Info.IsUndead
local InfoIsTotem							= Info.IsTotem
local InfoIsDummy							= Info.IsDummy

local InfoIsBoss 							= Info.IsBoss
local InfoIsNotBoss 						= Info.IsNotBoss
local InfoControlAbleClassification			= Info.ControlAbleClassification

A.Unit = PseudoClass({
	-- If it's by "UnitGUID" then it will use cache for different unitID with same unitGUID (which is not really best way to waste performance)
	-- Use "UnitGUID" only on high required resource functions
	-- Pass - no cache at all 
	-- Wrap - is a cache 
	Race 									= Cache:Pass(function(self)  
		-- @return string 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return A.PlayerRace
		end 
		
		return select(2, UnitRace(unitID)) or str_none
	end, "UnitID"),
	Class 									= Cache:Pass(function(self)  
		-- @return string 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return A.PlayerClass 
		end 
		
		return select(2, UnitClass(unitID)) or str_none
	end, "UnitID"),
	Role 									= Cache:Pass(function(self, hasRole)  
		-- @return boolean or string (depended on hasRole argument, TANK, HEALER, DAMAGER, NONE) 
		-- Nill-able: hasRole
		local unitID 						= self.UnitID

		if hasRole then 
			if hasRole == "HEALER" then 
				return self(unitID):IsHealer()
			elseif hasRole == "TANK" then 
				return self(unitID):IsTank()
			elseif hasRole == "DAMAGER" then 
				return self(unitID):IsDamager()
			else 
				return false
			end 
		else 
			if self(unitID):IsHealer() then 
				return "HEALER"
			elseif self(unitID):IsTank() then 
				return "TANK"
			elseif self(unitID):IsDamager() then 
				return "DAMAGER"
			else 
				return "NONE"
			end 
		end 				
	end, "UnitID"),
	Classification							= Cache:Pass(function(self)  
		-- @return string or empty string  
		local unitID 						= self.UnitID
		return UnitClassification(unitID) or str_empty
	end, "UnitID"),
	InfoGUID 								= Cache:Wrap(function(self, unitGUID)
		-- @return 
		-- For players: Player-[server ID]-[player UID] (Example: "Player-970-0002FD64")
		-- For creatures, pets, objects, and vehicles: [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[spawn UID] (Example: "Creature-0-970-0-11-31146-000136DF91")
		-- Unit Type Names: "Player", "Creature", "Pet", "GameObject", "Vehicle", and "Vignette" they are always in English		
		-- [1] utype
		-- [2] zero 		or server_id 
		-- [3] server_id 	or player_uid
		-- [4] instance_id	or nil 
		-- [5] zone_uid		or nil 
		-- [6] npc_id		or nil 
		-- [7] spawn_uid 	or nil 
		-- or nil
		-- Nill-able: unitGUID
		local unitID 						= self.UnitID
		local GUID 							= unitGUID or UnitGUID(unitID)
		if GUID then 
			local utype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", GUID)
			if utype then 
				return utype, toNum[zero], toNum[server_id], instance_id and toNum[instance_id], zone_uid and toNum[zone_uid], npc_id and toNum[npc_id], spawn_uid and toNum[spawn_uid]
			end 
		end 
	end, "UnitID"),
	InLOS 									= Cache:Pass(function(self, unitGUID)   
		-- @return boolean 
		-- Nill-able: unitGUID
		local unitID 						= self.UnitID
		return UnitInLOS(unitID, unitGUID)
	end, "UnitID"),
	InGroup 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitInAnyGroup(unitID)
	end, "UnitID"),
	InParty									= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitPlayerOrPetInParty(unitID)
	end, "UnitID"),
	InRaid									= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitPlayerOrPetInRaid(unitID)
	end, "UnitID"),
	InRange 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitIsUnit(unitID, "player") or UnitInRange(unitID)
	end, "UnitID"),
	InCC 									= Cache:Pass(function(self, index)
		-- @return number (time in seconds of remain crownd control)
		-- Nill-able: index
		local unitID 						= self.UnitID
		local value 
		for i = (index or 1), #InfoAllCC do 
			value = self(unitID):HasDeBuffs(InfoAllCC[i])
			if value ~= 0 then 
				return value
			end 
		end   
		return 0 
	end, "UnitID"),	
	IsEnemy									= Cache:Wrap(function(self, isPlayer)  
		-- @return boolean
		-- Nill-able: isPlayer
		local unitID 						= self.UnitID
		return unitID and (UnitCanAttack("player", unitID) or UnitIsEnemy("player", unitID)) and (not isPlayer or UnitIsPlayer(unitID))
	end, "UnitID"),
	IsHealer 								= Cache:Wrap(function(self, skipUnitIsUnit, class)  
		-- @return boolean
		-- Nill-able: skipUnitIsUnit, class
		local unitID 						= self.UnitID
		if not skipUnitIsUnit and UnitIsUnit(unitID, "player") then 
			return self("player"):HasSpec(InfoSpecIs.HEALER) 
		end 
		
		if InfoClassCanBeHealer[class or self(unitID):Class()] then 		
											-- bypass it in PvP 
			local taken_dmg 				= (self(unitID):IsEnemy() and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID)
			local done_dmg					= CombatTracker:GetDPS(unitID)
			local done_hps					= CombatTracker:GetHPS(unitID)
			return done_hps > taken_dmg and done_hps > done_dmg  
		end 
	end, "UnitGUID"),
	IsTank 									= Cache:Wrap(function(self, skipUnitIsUnit, class)    
		-- @return boolean 
		-- Nill-able: skipUnitIsUnit, class
		local unitID 						= self.UnitID
		if not skipUnitIsUnit and UnitIsUnit(unitID, "player") then 
			return self("player"):HasSpec(InfoSpecIs.TANK) 
		end 
		
		local unitID_class 					= class or self(unitID):Class()
		if InfoClassCanBeTank[unitID_class] then 
			if unitID:match("raid%d+") and GetPartyAssignment("maintank", unitID) then 
				return true 
			end 
			
			if CombatTracker:CombatTime(unitID) == 0 then 
				if unitID_class == "PALADIN" then 
					local _, offhand = UnitAttackSpeed(unitID)
					-- Buff: Righteous Fury 
					return offhand == nil and self(unitID):HasBuffs(25781) > 0 and A_GetUnitItem(unitID, ACTION_CONST_INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) -- byPassDistance
				elseif unitID_class == "DRUID" then 
					return UnitPowerType(unitID) == 1
				elseif unitID_class == "WARRIOR" then 
					local _, offhand = UnitAttackSpeed(unitID)
					-- Buff: Defensive Stance
					return offhand == nil and self(unitID):HasBuffs(71) > 0 and A_GetUnitItem(unitID, ACTION_CONST_INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) -- don't byPassDistance
				end 
			end 
			
			local taken_dmg 				= CombatTracker:GetDMG(unitID)
			local done_dmg					= CombatTracker:GetDPS(unitID)
			local done_hps					= CombatTracker:GetHPS(unitID)
			return taken_dmg > done_dmg and taken_dmg > done_hps
		end 
	end, "UnitGUID"),	
	IsDamager								= Cache:Wrap(function(self, skipUnitIsUnit)    
		-- @return boolean 
		-- Nill-able: skipUnitIsUnit
		local unitID 						= self.UnitID
		if not skipUnitIsUnit and UnitIsUnit(unitID, "player") then 
			return self("player"):HasSpec(InfoSpecIs.DAMAGER) 
		end 

		if unitID:match("raid%d+") and GetPartyAssignment("mainassist", unitID) then 
			return true 
		end 
											-- bypass it in PvP 
		local taken_dmg 					= (self(unitID):IsEnemy() and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID) 
		local done_dmg						= CombatTracker:GetDPS(unitID)
		local done_hps						= CombatTracker:GetHPS(unitID)
		return done_dmg > taken_dmg and done_dmg > done_hps 
	end, "UnitGUID"),	
	IsMelee 								= Cache:Wrap(function(self) 
		-- @return boolean 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return self("player"):HasSpec(InfoSpecIs.MELEE) 
		end 
		
		local class = self(unitID):Class()
		if InfoClassCanBeMelee[class] then 
			if self(unitID):IsTank(true, class) then 
				return true 
			end 
			
			if self(unitID):IsDamager(true) then 
				if unitClass == "SHAMAN" then 
					local _, offhand = UnitAttackSpeed(unitID)
					return offhand ~= nil                    
				elseif unitClass == "DRUID" then 
					local _, power = UnitPowerType(unitID)
					return power == "ENERGY" or power == "FURY"
				else 
					return true 
				end 
			else 
				if class == "DRUID" then 
					local _, power = UnitPowerType(unitID)
					return power == "ENERGY" or power == "FURY"					
				end 
			end 
		end 
	end, "UnitGUID"),
	IsDead 									= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsDeadOrGhost(unitID) and not UnitIsFeignDeath(unitID)
	end, "UnitID"),	
	IsPlayer								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsPlayer(unitID)
	end, "UnitID"),
	IsPet									= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitPlayerControlled(unitID)
	end, "UnitID"),
	IsVisible								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsVisible(unitID)
	end, "UnitID"),
	IsExists 								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitExists(unitID)
	end, "UnitID"),
	IsNameplate								= Cache:Pass(function(self)  
		-- @return boolean, nameplateUnitID or nil 
		-- Note: Only enemy plates
		local unitID 						= self.UnitID
		for nameplateUnit in pairs(ActiveUnitPlates) do 
			if UnitIsUnit(unitID, nameplateUnit) then 
				return true, nameplateUnit
			end 
		end 
	end, "UnitID"),
	IsNameplateAny							= Cache:Pass(function(self)  
		-- @return boolean, nameplateUnitID or nil 
		-- Note: Any plates
		local unitID 						= self.UnitID
		for nameplateUnit in pairs(ActiveUnitPlatesAny) do 
			if UnitIsUnit(unitID, nameplateUnit) then 
				return true, nameplateUnit
			end 
		end 
	end, "UnitID"),
	IsConnected								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsConnected(unitID)
	end, "UnitID"),
	IsCharmed								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsCharmed(unitID)
	end, "UnitID"),
	IsMovingOut								= Cache:Pass(function(self, snap_timer)
		-- @return boolean 
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return true 
		end 
		
		local unitSpeed 					= self(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then 
			if unitSpeed == self("player"):GetCurrentSpeed() then 
				return true 
			end 
			
			local GUID 						= UnitGUID(unitID) 
			local _, min_range				= self(unitID):GetRange()
			if not InfoCacheMoveOut[GUID] then 
				InfoCacheMoveOut[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false 
			end 
			
			if TMW.time - InfoCacheMoveOut[GUID].TimeStamp <= (snap_timer or 0.2) then 
				return InfoCacheMoveOut[GUID].Result
			end 
			
			InfoCacheMoveOut[GUID].TimeStamp = TMW.time 
			
			if min_range == InfoCacheMoveOut[GUID].Range then 
				return InfoCacheMoveOut[GUID].Result
			end 
			
			if min_range > InfoCacheMoveOut[GUID].Range then 
				InfoCacheMoveOut[GUID].Snapshot = InfoCacheMoveOut[GUID].Snapshot + 1 
			else 
				InfoCacheMoveOut[GUID].Snapshot = InfoCacheMoveOut[GUID].Snapshot - 1
			end		

			InfoCacheMoveOut[GUID].Range = min_range
			
			if InfoCacheMoveOut[GUID].Snapshot >= 3 then 
				InfoCacheMoveOut[GUID].Snapshot = 2
				InfoCacheMoveOut[GUID].Result = true 
				return true 
			else
				if InfoCacheMoveOut[GUID].Snapshot < 0 then 
					InfoCacheMoveOut[GUID].Snapshot = 0 
				end 
				InfoCacheMoveOut[GUID].Result = false
				return false 
			end 
		end 		
	end, "UnitGUID"),
	IsMovingIn								= Cache:Pass(function(self, snap_timer)
		-- @return boolean 		
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return true 
		end 
		
		local unitSpeed 					= self(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then 
			if unitSpeed == self("player"):GetCurrentSpeed() then 
				return true 
			end 
			
			local GUID 						= UnitGUID(unitID) 
			local _, min_range				= self(unitID):GetRange()
			if not InfoCacheMoveIn[GUID] then 
				InfoCacheMoveIn[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false 
			end 
			
			if TMW.time - InfoCacheMoveIn[GUID].TimeStamp <= (snap_timer or 0.2) then 
				return InfoCacheMoveIn[GUID].Result
			end 
			
			InfoCacheMoveIn[GUID].TimeStamp = TMW.time 
			
			if min_range == InfoCacheMoveIn[GUID].Range then 
				return InfoCacheMoveIn[GUID].Result
			end 
			
			if min_range < InfoCacheMoveIn[GUID].Range then 
				InfoCacheMoveIn[GUID].Snapshot = InfoCacheMoveIn[GUID].Snapshot + 1 
			else 
				InfoCacheMoveIn[GUID].Snapshot = InfoCacheMoveIn[GUID].Snapshot - 1
			end		

			InfoCacheMoveIn[GUID].Range = min_range
			
			if InfoCacheMoveIn[GUID].Snapshot >= 3 then 
				InfoCacheMoveIn[GUID].Snapshot = 2
				InfoCacheMoveIn[GUID].Result = true 
				return true 
			else
				if InfoCacheMoveIn[GUID].Snapshot < 0 then 
					InfoCacheMoveIn[GUID].Snapshot = 0 
				end 			
				InfoCacheMoveIn[GUID].Result = false
				return false 
			end 
		end 		
	end, "UnitGUID"),
	IsMoving								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return Player:IsMoving()
		else 
			return self(unitID):GetCurrentSpeed() ~= 0
		end 
	end, "UnitID"),
	IsMovingTime							= Cache:Pass(function(self)	
		-- @return number 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return Player:IsMovingTime()
		else 
			local GUID						= UnitGUID(unitID) 
			local isMoving  				= self(unitID):IsMoving()
			if isMoving then
				if not InfoCacheMoving[GUID] or InfoCacheMoving[GUID] == 0 then 
					InfoCacheMoving[GUID] = TMW.time 
				end                        
			else 
				InfoCacheMoving[GUID] = 0
			end 
			return (InfoCacheMoving[GUID] == 0 and -1) or TMW.time - InfoCacheMoving[GUID]
		end 
	end, "UnitGUID"),
	IsStaying								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return Player:IsStaying()
		else 
			return self(unitID):GetCurrentSpeed() == 0
		end 		
	end, "UnitID"),
	IsStayingTime							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return Player:IsStayingTime()
		else 
			local GUID						= UnitGUID(unitID) 
			local isMoving  				= self(unitID):IsMoving()
			if not isMoving then
				if not InfoCacheStaying[GUID] or InfoCacheStaying[GUID] == 0 then 
					InfoCacheStaying[GUID] = TMW.time 
				end                        
			else 
				InfoCacheStaying[GUID] = 0
			end 
			return (InfoCacheStaying[GUID] == 0 and -1) or TMW.time - InfoCacheStaying[GUID]
		end
	end, "UnitGUID"),
	IsCasting 								= Cache:Wrap(function(self)
		-- @return:
		-- [1] castName (@string or @nil)
		-- [2] castStartedTime (@number or @nil)
		-- [3] castEndTime (@number or @nil)
		-- [4] notInterruptable (@boolean, false is able to be interrupted)
		-- [5] spellID (@number or @nil)
		-- [6] isChannel (@boolean)
		local unitID 						= self.UnitID
		local isChannel
		local castName, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = LibClassicCasterino:UnitCastingInfo(unitID)
		if not castName then 
			castName, _, _, castStartTime, castEndTime, _, notInterruptable, spellID = LibClassicCasterino:UnitChannelInfo(unitID)			
			if castName then 
				isChannel = true
			end 
		end  
		
		-- Check interrupt able 
		if castName then 
			if next(AuraList.KickImun) then 
				notInterruptable = self(unitID):HasBuffs("KickImun") ~= 0 
			else
				notInterruptable = false 
			end 
		end 
		
		return castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel
	end, "UnitGUID"),
	IsCastingRemains						= Cache:Pass(function(self, argSpellID)
		-- @return:
		-- [1] Currect Casting Left Time (seconds) (@number)
		-- [2] Current Casting Left Time (percent) (@number)
		-- [3] spellID (@number)
		-- [4] spellName (@string)
		-- [5] notInterruptable (@boolean, false is able to be interrupted)
		-- [6] isChannel (@boolean)
		-- Nill-able: argSpellID
		local unitID 						= self.UnitID
		return select(2, self(unitID):CastTime(argSpellID))
	end, "UnitGUID"),
	CastTime								= Cache:Pass(function(self, argSpellID)
		-- @return:
		-- [1] Total Casting Time (@number)
		-- [2] Currect Casting Left (X -> 0) Time (seconds) (@number)
		-- [3] Current Casting Done (0 -> 100) Time (percent) (@number)
		-- [4] spellID (@number)
		-- [5] spellName (@string)
		-- [6] notInterruptable (@boolean, false is able to be interrupted)
		-- [7] isChannel (@boolean)
		-- Nill-able: argSpellID
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = self(unitID):IsCasting()

		local TotalCastTime, CurrentCastTimeSeconds, CurrentCastTimeLeftPercent = 0, 0, 0
		if unitID == "player" then 
			TotalCastTime = (select(4, GetSpellInfo(argSpellID or spellID)) or 0) / 1000
			CurrentCastTimeSeconds = TotalCastTime
		end 
		
		if castName and (not argSpellID or A_GetSpellInfo(argSpellID) == castName) then 
			TotalCastTime = (castEndTime - castStartTime) / 1000
			CurrentCastTimeSeconds = (TMW.time * 1000 - castStartTime) / 1000
			CurrentCastTimeLeftPercent = CurrentCastTimeSeconds * 100 / TotalCastTime
		end 		
		
		return TotalCastTime, TotalCastTime - CurrentCastTimeSeconds, CurrentCastTimeLeftPercent, spellID, castName, notInterruptable, isChannel
	end, "UnitGUID"),
	MultiCast 								= Cache:Pass(function(self, spells, range)
		-- @return 
		-- [1] Total CastTime
		-- [2] Current CastingTime Left
		-- [3] Current CastingTime Percent (from 0% as start til 100% as finish)
		-- [4] SpellID 
		-- [5] SpellName
		-- [6] notInterruptable (@boolean, false is able to be interrupted)
		-- Note: spells accepts only table or nil to get list from "CastBarsCC"
		local unitID 						= self.UnitID				    
		local castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable = self(unitID):CastTime()
		
		if castLeft > 0 and (not range or self(unitID):GetRange() <= range) then
			local query = (type(spells) == "table" and spells) or AuraList.CastBarsCC  
			for i = 1, #query do 				
				if castID == query[i] or castName == A_GetSpellInfo(query[i]) then 
					return castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable
				end 
			end         
		end   
		
		return 0, 0, 0
	end, "UnitGUID"),
	IsControlAble 							= Cache:Pass(function(self, drCat, drDiminishing)
		-- @return boolean 
		-- drDiminishing is Tick (number: 100 -> 50 -> 25 -> 0) where 0 is fully imun, 100% no imun - can be fully duration CC'ed 
		-- "taunt" has unique Tick (number: 100 -> 65 -> 42 -> 27 -> 0)
		--[[ drCat accepts:
			"incapacitate"
			"silence"
			"stun"							-- PvE unlocked  
			"root"
			"disarm"						-- Added in original DRList	
			"random_stun"
			"random_root"					-- May be removed in the future!
			"fear"
			"mind_control"
			"frost_shock"
			"kidney_shot"	
		]]
		-- Nill-able: drDiminishing
		local unitID 						= self.UnitID 
		if not A.IsInPvP then 
			return not self(unitID):IsBoss() and InfoControlAbleClassification[self(unitID):Classification()] and (not drCat or self(unitID):GetDR(drCat) > (drDiminishing or 25))
		else 
			return not drCat or self(unitID):GetDR(drCat) > (drDiminishing or 25)
		end 
	end, "UnitID"),
	IsUndead								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID 
		local unitType 						= UnitCreatureType(unitID) or str_empty
		return InfoIsUndead[unitType]	       	
	end, "UnitID"),
	IsTotem 								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID 
		local unitType 						= UnitCreatureType(unitID) or str_empty
		return InfoIsTotem[unitType]	       	
	end, "UnitID"),
	IsDummy									= Cache:Pass(function(self)	
		-- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		return npc_id and InfoIsDummy[npc_id]
	end, "UnitID"),
	IsDummyPvP								= Cache:Pass(function(self)	
		-- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		return npc_id and InfoIsDummyPvP[npc_id]
	end, "UnitID"),
	IsBoss 									= Cache:Pass(function(self)       
	    -- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		if npc_id and not InfoIsNotBoss[npc_id] then 
			if InfoIsBoss[npc_id] or LibBossIDs[npc_id] or self(unitID):GetLevel() == -1 then 
				return true 
			else 
				for i = 1, ACTION_CONST_MAX_BOSS_FRAMES do 
					if UnitIsUnit(unitID, "boss" .. i) then 
						return true 
					end 
				end 			
			end 
		end 
	end, "UnitID"),
	ThreatSituation							= Cache:Pass(function(self, otherunitID)  
		-- @return number, number, number 
		-- Returns: status (0 -> 3), percent of threat, value or threat 
		-- Nill-able: otherunit
		local unitID 						= self.UnitID
		if unitID then 
			local GUID 						= UnitGUID(unitID)					
			if GUID and TeamCachethreatData[GUID] then 
				if otherunitID and not UnitIsUnit(otherunitID, TeamCachethreatData[GUID].unit) then 
					-- By specified otherunitID
					-- Note: I prefer avoid use this as much as it possible since less performance 
					local _, status, scaledPercent, _, threatValue = UnitDetailedThreatSituation(unitID, otherunitID) -- Lib modified to return by last argument unitGUID!
					if threatValue and threatValue < 0 then
						threatValue = threatValue + 410065408
					end					
					return status or 0, scaledPercent or 0, threatValue or 0
				else 
					-- By own unit's target 
					return TeamCachethreatData[GUID].status, TeamCachethreatData[GUID].scaledPercent, TeamCachethreatData[GUID].threatValue       
				end 
			end 
		end 
		return 0, 0, 0
	end, "UnitID"),
	IsTanking 								= Cache:Pass(function(self, otherunitID, range)  
		-- @return boolean 
		-- Nill-able: otherunit, range
		local unitID 						= self.UnitID	
		local ThreatSituation 				= self(unitID):ThreatSituation(otherunitID) -- cacheed defaultly own target but if need to check something additional here is otherunitID
		return (A.IsInPvP and UnitIsUnit(unitID, (otherunitID or "target") .. "target")) or (not A.IsInPvP and ThreatSituation >= 3) or self(unitID):IsTankingAoE(range)	       
	end, "UnitID"),
	IsTankingAoE 							= Cache:Pass(function(self, range) 
		-- @return boolean 
		-- Nill-able: range
		local unitID 						= self.UnitID
		for unit in pairs(ActiveUnitPlates) do
			local ThreatSituation 		= self(unitID):ThreatSituation() -- cacheed defaultly own target 
			if ((A.IsInPvP and UnitIsUnit(unitID, unit .. "target")) or (not A.IsInPvP and ThreatSituation >= 3)) and (not range or self(unitID):CanInterract(range)) then 
				return true  
			end
		end       
	end, "UnitID"),
	GetLevel 								= Cache:Pass(function(self) 
		-- @return number 
		local unitID 						= self.UnitID
		return UnitLevel(unitID) or 0  
	end, "UnitID"),
	GetCurrentSpeed 						= Cache:Wrap(function(self) 
		-- @return number (current), number (max)
		local unitID 						= self.UnitID
		local current_speed, max_speed 		= GetUnitSpeed(unitID)
		return math_floor(current_speed / 7 * 100), math_floor(max_speed / 7 * 100)
	end, "UnitGUID"),
	GetMaxSpeed								= Cache:Pass(function(self) 
		-- @return number 
		local unitID 						= self.UnitID
		return select(2, self(unitID):GetCurrentSpeed())
	end, "UnitGUID"),
	-- Combat: Diminishing
	GetDR 									= Cache:Pass(function(self, drCat) 
		-- @return: DR_Tick (@number), DR_Remain (@number), DR_Application (@number), DR_ApplicationMax (@number)
		-- drDiminishing is Tick (number: 100 -> 50 -> 25 -> 0) where 0 is fully imun, 100% no imun - can be fully duration CC'ed 
		-- "taunt" has unique Tick (number: 100 -> 65 -> 42 -> 27 -> 0)
		--[[ drCat accepts:
			"incapacitate"
			"silence"
			"stun"							-- PvE unlocked  
			"root"
			"disarm"						-- Added in original DRList	
			"random_stun"
			"random_root"					-- May be removed in the future!
			"fear"
			"mind_control"
			"frost_shock"
			"kidney_shot"	
		]]		
		local unitID 						= self.UnitID
		return CombatTracker:GetDR(unitID, drCat)
	end, "UnitID"),
	-- Combat: UnitCooldown
	GetCooldown								= Cache:Pass(function(self, spellName)
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched) 
		local unitID 						= self.UnitID
		return UnitCooldown:GetCooldown(unitID, spellName)
	end, "UnitID"),
	GetMaxDuration							= Cache:Pass(function(self, spellName)
		-- @return number (max cooldown of the spell on a unit) 
		local unitID 						= self.UnitID
		return UnitCooldown:GetMaxDuration(unitID, spellName)
	end, "UnitID"),
	GetUnitID								= Cache:Pass(function(self, spellName)
		-- @return unitID (who last casted spell) otherwise nil  
		local unitID 						= self.UnitID
		return UnitCooldown:GetUnitID(unitID, spellName)
	end, "UnitID"),
	GetBlinkOrShrimmer						= Cache:Pass(function(self)
		-- @return number, number, number 
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown 
		local unitID 						= self.UnitID
		return UnitCooldown:GetBlinkOrShrimmer(unitID)
	end, "UnitID"),
	IsSpellInFly							= Cache:Pass(function(self, spellName)
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitCooldown:IsSpellInFly(unitID, spellName)
	end, "UnitID"),
	-- Combat: CombatTracker 
	CombatTime 								= Cache:Pass(function(self)
		-- @return number, unitGUID
		local unitID 						= self.UnitID
		return CombatTracker:CombatTime(unitID)
	end, "UnitID"),
	GetLastTimeDMGX 						= Cache:Pass(function(self, x)
		-- @return number: taken amount 
		local unitID 						= self.UnitID
		return CombatTracker:GetLastTimeDMGX(unitID, x)
	end, "UnitID"),
	GetRealTimeDMG							= Cache:Pass(function(self, index)
		-- @return number: taken total, hits, phys, magic, swing 
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetRealTimeDMG(unitID))
		else
			return CombatTracker:GetRealTimeDMG(unitID)
		end 
	end, "UnitID"),
	GetRealTimeDPS 							= Cache:Pass(function(self, index)
		-- @return number: done total, hits, phys, magic, swing
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetRealTimeDPS(unitID))
		else
			return CombatTracker:GetRealTimeDPS(unitID)
		end 
	end, "UnitID"),
	GetDMG 									= Cache:Pass(function(self, index)
		-- @return number: taken total, hits, phys, magic 
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetDMG(unitID))
		else
			return CombatTracker:GetDMG(unitID)
		end 
	end, "UnitID"),
	GetDPS 									= Cache:Pass(function(self, index)
		-- @return number: done total, hits, phys, magic
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetDPS(unitID))
		else
			return CombatTracker:GetDPS(unitID)
		end 
	end, "UnitID"),
	GetHEAL 								= Cache:Pass(function(self, index)
		-- @return number: taken total, hits
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetHEAL(unitID))
		else
			return CombatTracker:GetHEAL(unitID)
		end 
	end, "UnitID"),
	GetHPS 									= Cache:Pass(function(self, index)
		-- @return number: done total, hits
		local unitID 						= self.UnitID
		if index then 
			return select(index, CombatTracker:GetHPS(unitID))
		else
			return CombatTracker:GetHPS(unitID)
		end 
	end, "UnitID"),
	GetSpellAmountX 						= Cache:Pass(function(self, spell, x)
		-- @return number: taken total with 'x' lasts seconds by 'spell'
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellAmountX(unitID, spell, x)
	end, "UnitID"),
	GetSpellAmount 							= Cache:Pass(function(self, spell)
		-- @return number: taken total during all time by 'spell'
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellAmount(unitID, spell)
	end, "UnitID"),
	GetSpellLastCast 						= Cache:Pass(function(self, spell)
		-- @return number, number 
		-- time in seconds since last cast, timestamp of start 
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellLastCast(unitID, spell)
	end, "UnitID"),
	GetSpellCounter 						= Cache:Pass(function(self, spell)
		-- @return number (counter of total used 'spell' during all fight)
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellCounter(unitID, spell)
	end, "UnitID"),
	GetAbsorb 								= Cache:Pass(function(self, spell)
		-- @return number: taken absorb total (or by specified 'spell')
		local unitID 						= self.UnitID
		return CombatTracker:GetAbsorb(unitID, spell)
	end, "UnitID"),
	TimeToDieX 								= Cache:Pass(function(self, x)
		-- @return number 
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieX(unitID, x)
	end, "UnitID"),
	TimeToDie 								= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDie(unitID)
	end, "UnitID"),
	TimeToDieMagicX 						= Cache:Pass(function(self, x)
		-- @return number 
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieMagicX(unitID, x)
	end, "UnitID"),
	TimeToDieMagic							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieMagic(unitID)
	end, "UnitID"),
	-- Combat: End
	GetIncomingResurrection					= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitHasIncomingResurrection(unitID)
	end, "UnitID"),
	GetIncomingHeals						= Cache:Wrap(function(self, castTime, unitGUID)
		-- @return number 
		-- Nill-able: unitGUID
		if not HealComm or not castTime or castTime <= 0 then 
			return 0
		end 
		
		local unitID 						= self.UnitID
		local GUID 							= unitGUID or UnitGUID(unitID)
		
		if not GUID then 
			return 0 
		end 
		
		return (HealComm:GetOthersHealAmount(GUID, ALL_HEALS, TMW.time + castTime) or 0) * HealComm:GetHealModifier(GUID) -- Better by others since if we will include our heals it will funky use accidentally downrank
	end, "UnitGUID"),
	GetIncomingHealsIncSelf					= Cache:Wrap(function(self, castTime, unitGUID)
		-- @return number 
		-- Nill-able: unitGUID
		if not HealComm or not castTime or castTime <= 0 then 
			return 0
		end 
		
		local unitID 						= self.UnitID
		local GUID 							= unitGUID or UnitGUID(unitID)
		
		if not GUID then 
			return 0 
		end 
		
		return (HealComm:GetHealAmount(GUID, ALL_HEALS, TMW.time + castTime) or 0) * HealComm:GetHealModifier(GUID) -- Includes self incoming on a unitID 
	end, "UnitGUID"),
	GetRange 								= Cache:Wrap(function(self)
		-- @return number (max), number (min)
		local unitID 						= self.UnitID
		local min_range, max_range 			= LibRangeCheck:GetRange(unitID)
		if not max_range then 
			return 0, 0 
		end 
		
		-- Limit range to 20 if unitID is nameplated and max range over normal behaivor 
		if max_range > ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE and self(unitID):IsEnemy() and self(unitID):IsNameplate() then 
			return ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE, min_range
		end 			
		
	    return max_range, min_range 
	end, "UnitGUID"),
	CanInterract							= Cache:Pass(function(self, range, orBooleanInRange) 
		-- @return boolean  
		local unitID 						= self.UnitID
		local min_range 					= self(unitID):GetRange()
		
		return min_range > 0 and (min_range <= range or orBooleanInRange)	
	end, "UnitID"),
	CanInterrupt							= Cache:Pass(function(self, kickAble, auras, minX, maxX)
		-- @return boolean 
		-- Nill-able: kickAble, auras, minX, maxX
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = self(unitID):IsCasting()
		if castName and (not kickAble or not notInterruptable) then 
			if auras and self(unitID):HasBuffs(auras) > 0 then 
				return false 
			end 
			
			local GUID 						= UnitGUID(unitID)
			if not InfoCacheInterrupt[GUID] then 
				InfoCacheInterrupt[GUID] = {}
			end 
			
			if InfoCacheInterrupt[GUID].LastCast ~= castName then 
				InfoCacheInterrupt[GUID].LastCast 	= castName
				InfoCacheInterrupt[GUID].Timer 		= math_random(minX or 7, maxX or 13)				 
			end 
			
			local castPercent = ((TMW.time * 1000) - castStartTime) * 100 / (castEndTime - castStartTime)
			return castPercent >= InfoCacheInterrupt[GUID].Timer 
		end 	
	end, "UnitID"),
	CanCooperate							= Cache:Pass(function(self, otherunit)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitCanCooperate(unitID, otherunit)
	end, "UnitID"),	
	HasSpec									= Cache:Pass(function(self, specID)	
		-- @return boolean 
		-- Only PLAYER!
		local unitID 						= "player"
		if not UnitIsUnit(unitID, "player") then 
			error("Can't use Action.Unit(" .. (unitID or "unitID") .. "):HasSpec(" .. (specID or "") .. ") since field 'unitID' must be equal to 'player'")
			return 
		end 
		
		if type(specID) == "table" then        
			for i = 1, #specID do
				if specID[i] == A.PlayerSpec then 
					return true 
				end 
			end       
		else 
			return specID == A.PlayerSpec      
		end
	end, "UnitID"),
	HasFlags 								= Cache:Wrap(function(self) 
		-- @return boolean 
		local unitID 						= self.UnitID
	    return self(unitID):HasBuffs(AuraList.Flags) > 0 
	end, "UnitID"),
	Health									= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return CombatTracker:UnitHealth(unitID)
	end, "UnitID"),
	HealthMax								= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return CombatTracker:UnitHealthMax(unitID)
	end, "UnitID"),
	HealthDeficit							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return self(unitID):HealthMax() - self(unitID):Health()
	end, "UnitID"),
	HealthDeficitPercent					= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return 100 - self(unitID):HealthPercent()
	end, "UnitID"),
	HealthPercent							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
		if UnitInAnyGroup(unitID) or UnitIsUnit("player", unitID) or UnitIsUnit("pet", unitID) then 
			return UnitHealth(unitID) * 100 / UnitHealthMax(unitID)
		end 
	    return UnitHealth(unitID)
	end, "UnitID"),
	Power									= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return UnitPower(unitID)
	end, "UnitID"),
	PowerType								= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return select(2, UnitPowerType(unitID))
	end, "UnitID"),
	PowerMax								= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return UnitPowerMax(unitID)
	end, "UnitID"),
	PowerDeficit							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return self(unitID):PowerMax() - self(unitID):Power()
	end, "UnitID"),
	PowerDeficitPercent						= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return self(unitID):PowerDeficit() * 100 / self(unitID):PowerMax()
	end, "UnitID"),
	PowerPercent							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return self(unitID):Power() * 100 / self(unitID):PowerMax()
	end, "UnitID"),
	AuraTooltipNumber						= Cache:Wrap(function(self, spellID, filter)
		-- @return number 
		-- Nill-able: filter
		local unitID 						= self.UnitID
		local name							= strlowerCache[A_GetSpellInfo(spellID)]
	    return Env.AuraTooltipNumber(unitID, name, filter) or 0
	end, "UnitGUID"),
	DeBuffCyclone 							= Cache:Pass(function(self)
		-- @return number 
		return 0 -- Right now no such effects, change Pass to Wrap if will be any in future!
	end, "UnitGUID"),	
	GetDeBuffInfo							= Cache:Pass(function(self, auraTable, caster)
		-- @return number, number, number, number 
		-- [1] rank
		-- [2] remain duration
		-- [3] total duration
		-- [4] stacks 
		-- auraTable is { [spellID or spellName] = rank, [18] = 1 }
		-- Nill-able: caster
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		
		local _, spellName, spellID, spellCount, spellDuration, spellExpirationTime	
		for i = 1, huge do			
			spellName, _, spellCount, _, spellDuration, spellExpirationTime, _,_,_, spellID = UnitAura(unitID, i, filter)
			
			if not spellName then 
				break
			elseif auraTable[spellID] then 
				return auraTable[spellID], spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			elseif auraTable[spellName] then 
				return auraTable[spellName], spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	GetDeBuffInfoByName						= Cache:Pass(function(self, auraName, caster)
		-- @return number, number, number, number 
		-- [1] spellID
		-- [2] remain duration
		-- [3] total duration
		-- [4] stacks 
		-- auraName must be exactly @string 
		-- Nill-able: caster
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		
		local _, spellName, spellID, spellCount, spellDuration, spellExpirationTime	
		for i = 1, huge do			
			spellName, _, spellCount, _, spellDuration, spellExpirationTime, _,_,_, spellID = UnitAura(unitID, i, filter)
			
			if not spellName then 
				break
			elseif spellName == auraName then 
				return spellID, spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	IsDeBuffsLimited						= Cache:Pass(function(self)
		-- @return boolean, number 
		local unitID 						= self.UnitID	
		local auras 						= 0 
		
		local Name
		for i = 1, ACTION_CONST_AURAS_MAX_LIMIT do			
			Name = UnitDebuff(unitID, i)
			
			if Name then					
				auras = auras + 1
			else
				break 
			end 
		end 
		
		return auras >= ACTION_CONST_AURAS_MAX_LIMIT, auras
	end, "UnitID"), 
	--[[HasDeBuffs 								= Cache:Pass(function(self, spell, caster, byID)
		-- @return number, number 
		-- current remain, total applied duration
		-- Sorting method
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
        return self(unitID):SortDeBuffs(spell, caster, byID or IsMustBeByID[spell]) 
    end, "UnitID"),]]
	SortDeBuffs								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number 
		-- Returns sorted by highest and limited by 1-3 firstly found: current remain, total applied duration	
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		local remain_dur, total_dur 		= 0, 0
		
		local c = 0
		local _, spellName, spellID, spellDuration, spellExpirationTime		
		for i = 1, huge do 
			spellName, _, _, _, spellDuration, spellExpirationTime, _, _, _, spellID = UnitAura(unitID, i, filter)
			
			if not spellName then 
				break 			
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				local current_dur = spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time
				if current_dur > remain_dur then 
					c = c + 1
					remain_dur = current_dur
					total_dur = spellDuration				
				
					if remain_dur == huge or c >= (type(spell) == "table" and 3 or 1) then 
						break 
					end 
				end			
			end 
		end 
		
		return remain_dur, total_dur    
    end, "UnitGUID"),
	HasDeBuffsStacks						= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		
		local _, spellName, spellID, spellCount		
		for i = 1, huge do 
			spellName, _, spellCount, _, _, _, _, _, _, spellID = UnitAura(unitID, i, filter)
			if not spellName then 
				break 			
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				return spellCount == 0 and 1 or spellCount			
			end 
		end 
		
		return 0
    end, "UnitGUID"),
	-- Pandemic Threshold
	PT										= Cache:Wrap(function(self, spell, debuff, byID)    
		-- @return boolean 
		-- Note: If duration remains <= 30% only for auras applied by @player
		-- Nill-able: debuff, byID
		local unitID 						= self.UnitID
		local filter
		if debuff then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HELPFUL PLAYER"
		end 
		
		local duration = 0
		local _, spellName, spellID, spellDuration, spellExpirationTime		
		for i = 1, huge do 
			spellName, _, _, _, spellDuration, spellExpirationTime, _, _, _, spellID = UnitAura(unitID, i, filter)
			if not spellName then 
				break 			
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				duration = spellExpirationTime == 0 and 1 or ((spellExpirationTime - TMW.time) / spellDuration)
				if duration <= 0.3 then 
					return true 
				end 
			end 
		end 
		
		return duration <= 0.3
    end, "UnitGUID"),
	GetBuffInfo								= Cache:Pass(function(self, auraTable, caster)
		-- @return number, number, number, number 
		-- [1] rank
		-- [2] remain duration
		-- [3] total duration
		-- [4] stacks 
		-- auraTable is { [spellID or spellName] = rank, [18] = 1 }
		-- Nill-able: caster
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		
		local _, spellName, spellID, spellCount, spellDuration, spellExpirationTime	
		for i = 1, huge do			
			spellName, _, spellCount, _, spellDuration, spellExpirationTime, _,_,_, spellID = UnitAura(unitID, i, filter)
			
			if not spellName then 
				break 
			elseif auraTable[spellID] then 
				return auraTable[spellID], spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			elseif auraTable[spellName] then 
				return auraTable[spellName], spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	GetBuffInfoByName						= Cache:Pass(function(self, auraName, caster)
		-- @return number, number, number, number 
		-- spellID, remain duration, total duration, stacks 
		-- auraName must be exactly @string 
		-- Nill-able: caster
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		
		local _, spellName, spellID, spellCount, spellDuration, spellExpirationTime	
		for i = 1, huge do			
			spellName, _, spellCount, _, spellDuration, spellExpirationTime, _,_,_, spellID = UnitAura(unitID, i, filter)
			
			if not spellName then 
				break
			elseif spellName == auraName then 
				return spellID, spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration, spellCount
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	HasBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number 
		-- current remain, total applied duration	
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID	
		local filter -- default "HELPFUL"
		if caster then 
			filter = "HELPFUL PLAYER"
		end 
		
		local _, spellName, spellID, spellDuration, spellExpirationTime		
		for i = 1, huge do 
			spellName, _, _, _, spellDuration, spellExpirationTime, _, _, _, spellID = UnitAura(unitID, i, filter)
			if not spellName then 
				break  
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				return spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time, spellDuration
			end 
		end 
		
		return 0, 0
	end, "UnitGUID"),
	SortBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number 
		-- Returns sorted by highest: current remain, total applied duration	
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID	
		local filter -- default "HELPFUL"
		if caster then 
			filter = "HELPFUL PLAYER"
		end 
		local remain_dur, total_dur 		= 0, 0
		
		local _, spellName, spellID, spellDuration, spellExpirationTime		
		for i = 1, huge do 
			spellName, _, _, _, spellDuration, spellExpirationTime, _, _, _, spellID = UnitAura(unitID, i, filter)
			if not spellName then 
				break 			
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				local current_dur = spellExpirationTime == 0 and huge or spellExpirationTime - TMW.time
				if current_dur > remain_dur then 
					remain_dur, total_dur = current_dur, spellDuration
					if remain_dur == huge then 
						break 
					end 
				end				
			end 
		end 
		
		return remain_dur, total_dur		
	end, "UnitGUID"),
	HasBuffsStacks 							= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number 
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID	
		local filter -- default "HELPFUL"
		if caster then 
			filter = "HELPFUL PLAYER"
		end 
		
		local _, spellName, spellID, spellCount		
		for i = 1, huge do 
			spellName, _, spellCount, _, _, _, _, _, _, spellID = UnitAura(unitID, i, filter)
			if not spellName then 
				break 			
			elseif AssociativeTables[spell][byID and spellID or spellName] then 
				return spellCount == 0 and 1 or spellCount			
			end 
		end 
		
		return 0
	end, "UnitGUID"),
	IsFocused 								= Cache:Wrap(function(self, burst, deffensive, range, isMelee)
		-- @return boolean
		-- ATTENTION:
		-- 'burst' must be number 			or nil 
		-- 'deffensive' must be number 		or nil 	-- will check deffensive buffs on unitID (not focuser e.g. not member\arena)
		-- 'range' must be number 			or nil 
		-- 'isMelee' must be true 			or nil 
		-- Nill-able: burst, deffensive, range, isMelee
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			if TeamCacheFriendly.Type then 
				for i = 1, TeamCacheFriendly.MaxSize do 
					local member = TeamCacheFriendlyIndexToPLAYERs[i]
					if  member
					and not UnitIsUnit(member, "player")
					and UnitIsUnit(member .. "target", unitID) 					
					and ((not isMelee and self(member):IsDamager()) or (isMelee and self(member):IsMelee()))
					and (not burst 		or 	self(member):HasBuffs("DamageBuffs") >= burst) 
					and (not deffensive or 	self(unitID):HasBuffs("DeffBuffs") <= deffensive)
					and (not range 		or 	self(member):GetRange() <= range) 					
					then 
						return true 
					end 
				end 
			end 
		else
			if TeamCacheEnemy.Type then 
				for i = 1, TeamCacheEnemy.MaxSize do 
					local arena = TeamCacheEnemyIndexToPLAYERs[i]
					if arena
					and UnitIsUnit(arena .. "target", unitID) 
					and ((not isMelee and self(arena):IsDamager()) or (isMelee and self(arena):IsMelee()))
					and (not burst 		or	self(arena):HasBuffs("DamageBuffs") >= burst) 
					and (not deffensive or 	self(unitID):HasBuffs("DeffBuffs") <= deffensive)
					and (not range 		or	self(arena):GetRange() <= range)
					then 
						return true 
					end 
				end 
			end 
		end 
	end, "UnitGUID"),
	IsExecuted 								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID

		return self(unitID):TimeToDieX(20) <= A_GetGCD() + A_GetCurrentGCD()
	end, "UnitID"),
	UseBurst 								= Cache:Wrap(function(self, pBurst)
		-- @return boolean
		-- Nill-able: pBurst
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			return self(unitID):IsPlayer() and 
			(
				A.Zone == str_none or 
				self(unitID):TimeToDieX(25) <= A_GetGCD() * 4 or
				(
					self(unitID):IsHealer() and 
					(
						(
							self(unitID):CombatTime() > 5 and 
							self(unitID):TimeToDie() <= 10 and 
							self(unitID):HasBuffs("DeffBuffs") == 0                      
						) or
						self(unitID):HasDeBuffs("Silenced") >= A_GetGCD() * 2 or 
						self(unitID):HasDeBuffs("Stuned") >= A_GetGCD() * 2                         
					)
				) or 
				self(unitID):IsFocused(true) or 
				A_EnemyTeam("HEALER"):GetCC() >= A_GetGCD() * 3 or
				(
					pBurst and 
					self("player"):HasBuffs("DamageBuffs") >= A_GetGCD() * 3
				)
			)       
		elseif A.IamHealer then 
			-- For HealingEngine as Healer
			return self(unitID):IsPlayer() and 
			(
				self(unitID):IsExecuted() or
				(
					A.IsInPvP and 
					(
						(
							self(unitID):HasFlags() and                                         
							self(unitID):CombatTime() > 0 and 
							self(unitID):GetRealTimeDMG() > 0 and 
							self(unitID):TimeToDie() <= 14 and 
							(
								self(unitID):TimeToDie() <= 8 or 
								self(unitID):HasBuffs("DeffBuffs") < 1                         
							)
						) or 
						(
							self(unitID):IsFocused(true) and 
							(
								self(unitID):TimeToDie() <= 10 or 
								self(unitID):HealthPercent() <= 70
							)
						) 
					)
				)
			)                   
		end 
	end, "UnitGUID"),
	UseDeff 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return 
		(
			self(unitID):IsExecuted() or 
			self(unitID):IsFocused(4) or 
			(
				self(unitID):TimeToDie() < 8 and 
				self(unitID):IsFocused() 
			) 
		) 			
	end, "UnitGUID"),	
})	
A.Unit.HasDeBuffs = A.Unit.SortDeBuffs

function A.Unit:New(UnitID, Refresh)
	self.UnitID 	= UnitID
	self.Refresh 	= Refresh
end

local function CheckUnitByRole(ROLE, unitID)
	return  not ROLE 													or 
			(ROLE == "HEALER" 			and A_Unit(unitID):IsHealer()) 	or 
			(ROLE == "TANK"   			and A_Unit(unitID):IsTank()) 	or 
			(ROLE == "DAMAGER" 			and A_Unit(unitID):IsDamager()) or 
			(ROLE == "DAMAGER_MELEE"	and A_Unit(unitID):IsMelee())	or 
			(ROLE == "DAMAGER_RANGE"	and A_Unit(unitID):IsDamager() and not A_Unit(unitID):IsMelee())
end 

-------------------------------------------------------------------------------
-- API: FriendlyTeam 
-------------------------------------------------------------------------------
A.FriendlyTeam = PseudoClass({
	-- Note: Return field 'unitID' will return "none" if is not found
	-- Note: Classic has included "player" in any way 
	GetUnitID 								= Cache:Wrap(function(self, range)
		-- @return string 
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Type then 
			for i = 1, TeamCacheFriendly.MaxSize do 
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then 
					return member
				end 
			end 
		end  
		
		return str_none 
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID 
		-- Nill-able: spells
		local ROLE 							= self.ROLE
		local duration, member
		
		if TeamCacheFriendly.Size <= 1 then 
			member = "player"
			if CheckUnitByRole(ROLE, member) then 
				if spells then 
					duration = A_Unit(member):HasDeBuffs(spells) 
					if duration ~= 0 then 
						return duration, member					
					end 
				else 
					duration = A_Unit(member):InCC()
					if duration ~= 0 then 
						return duration, member					
					end 
				end 
			end 
			
			return 0, str_none
		end 		
		
		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) then 
				if spells then 
					duration = A_Unit(member):HasDeBuffs(spells) 
				else
					duration = A_Unit(member):InCC()
				end 
				
				if duration ~= 0 then 
					return duration, member 
				end 
			end 
		end
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") then
			duration = A_Unit("player"):HasDeBuffs(spells) 
			if duration ~= 0 then 
				return duration, "player" 
			end
		end 

		return 0, str_none
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, spells, range, source)
		-- @return number, unitID 
		-- Nill-able: range, source
		local ROLE 							= self.ROLE
		local duration, member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") then 
				duration = A_Unit("player"):HasBuffs(spells, source)
				if duration ~= 0 then 
					return duration, "player"
				end  
			end 
			return 0, str_none			 
		end 	

		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]				
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
				duration = A_Unit(member):HasBuffs(spells, source)                     				 
				if duration ~= 0 then 
					return duration, member 
				end      
			end 
		end  
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") then
			duration = A_Unit("player"):HasBuffs(spells) 
			if duration ~= 0 then 
				return duration, "player" 
			end
		end 		
		
		return 0, str_none
	end, "ROLE"),
	GetDeBuffs		 						= Cache:Wrap(function(self, spells, range)
		-- @return number, unitID 
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local duration, member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") then 
				duration = A_Unit("player"):HasDeBuffs(spells)
				if duration ~= 0 then 
					return duration, "player"
				end 
			end 
			return 0, str_none			 
		end 		

		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
				duration = A_Unit(member):HasDeBuffs(spells)                     				 
				if duration ~= 0 then 
					return duration, member
				end      
			end 
		end  
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") then
			duration = A_Unit("player"):HasDeBuffs(spells) 
			if duration ~= 0 then 
				return duration, "player" 
			end
		end 			
		
		return 0, str_none
	end, "ROLE"),
	GetTTD 									= Cache:Wrap(function(self, count, seconds, range)
		-- @return boolean, counter, unitID 
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") and A_Unit("player"):TimeToDie() <= seconds then
				return 1 >= count, 1, "player"
			end  
			
			return false, 0, str_none
		end 		
		
		local counter = 0
		local lastmember
		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):TimeToDie() <= seconds then
				counter = counter + 1     
				if counter >= count then 
					return true, counter, member
				end
				lastmember = member
			end                        
		end  
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") and A_Unit("player"):TimeToDie() <= seconds then
			counter = counter + 1 
			if counter >= count then 
				return true, counter, "player"
			end
			lastmember = "player"
		end 			
		
		return false, counter, lastmember or str_none
	end, "ROLE"),
	AverageTTD 								= Cache:Wrap(function(self, range)
		-- @return number, number 
		-- Returns average time to die of valid players in group, count of valid players in group
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") then 
				return A_Unit("player"):TimeToDie(), 1
			end 
			return 0, 0
		end 
		
		local value, members				= 0, 0
		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
				value = value + A_Unit(member):TimeToDie()
				members = members + 1
			end                        
		end  
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") then
			value = value + A_Unit("player"):TimeToDie()
			members = members + 1
		end 	
		
		if members > 0 then 
			value = value / members
		end 
		
		return value, members
	end, "ROLE"),	
	MissedBuffs 							= Cache:Wrap(function(self, spells, source)
		-- @return boolean, unitID 
		-- Nill-able: source
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") then 
				if A_Unit("player"):HasBuffs(spells, source) == 0 then 
					return true, "player"
				end 
			end 
			return false, str_none 			 
		end 
		
		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and not A_Unit(member):IsDead() and A_Unit(member):HasBuffs(spells, source) == 0 then
				return true, member 
			end 
		end		
		
		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") and A_Unit("player"):HasBuffs(spells, source) == 0 then
			return true, "player"
		end 		
		
		return false, str_none 
	end, "ROLE"),
	PlayersInCombat 						= Cache:Wrap(function(self, range, combatTime)
		-- @return boolean, unitID 
		-- Nill-able: range, combatTime
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Size <= 1 then 
			if CheckUnitByRole(ROLE, "player") then 
				if A_Unit("player"):CombatTime() > 0 and (not combatTime or A_Unit("player"):CombatTime() <= combatTime) then 
					return true, "player"
				end 
			end 
			return false, str_none 			 
		end 
		
		for i = 1, TeamCacheFriendly.MaxSize do
			member = TeamCacheFriendlyIndexToPLAYERs[i]
			if member and CheckUnitByRole(ROLE, member) and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):CombatTime() > 0 and (not combatTime or A_Unit(member):CombatTime() <= combatTime) then
				return true, member
			end 
		end 

		if TeamCacheFriendly.Type ~= "raid" and CheckUnitByRole(ROLE, "player") and A_Unit("player"):CombatTime() > 0 and (not combatTime or A_Unit("player"):CombatTime() <= combatTime) then
			return true, "player"
		end 			
		
		return false, str_none
	end, "ROLE"),
	HealerIsFocused 						= Cache:Wrap(function(self, burst, deffensive, range, isMelee)
		-- @return boolean, unitID 
		-- Nill-able: burst, deffensive, range, isMelee
		-- Note: No 'ROLE' here 
		local ROLE 							= self.ROLE
		local member
		
		if TeamCacheFriendly.Type then 
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and CheckUnitByRole("HEALER", member) and A_Unit(member):InRange() and A_Unit(member):IsFocused(burst, deffensive, range, isMelee) then
					return true, member 
				end 
			end		
		end 				
		
		return false, str_none
	end, "ROLE"),
})

function A.FriendlyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.05
end

-------------------------------------------------------------------------------
-- API: EnemyTeam 
-------------------------------------------------------------------------------
A.EnemyTeam = PseudoClass({
	-- Note: Return field 'unitID' will return "none" if is not found
	GetUnitID 								= Cache:Wrap(function(self, range)
		-- @return string  
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local arena

		if TeamCacheEnemy.Type then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) and not A_Unit(arena):IsDead() and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then 
					return arena
				end 
			end 
		end  
		
		return str_none 
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID 
		-- Note: If 'ROLE' is "HEALER" then it will except healers if they are in @target
		-- Nill-able: spells
		local ROLE 							= self.ROLE
		local duration, arena
		
		if TeamCacheEnemy.Type then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) then 
					if ROLE ~= "HEALER" or not UnitIsUnit(arena, "target") then 
						if spells then 
							duration = A_Unit(arena):HasDeBuffs(spells) 
							if duration ~= 0 then 
								return duration, arena
							end 
						else
							duration = A_Unit(arena):InCC()
							if duration ~= 0 then 
								return duration, arena 
							end 
						end 
					end 
				end 
			end 
		end  		
		
		return 0, str_none
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, spells, range, source)
		-- @return number, unitID 
		-- Nill-able: range, source
		local ROLE 							= self.ROLE
		local duration, arena 
		
		if TeamCacheEnemy.Type then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then 
					duration = A_Unit(arena):HasBuffs(spells, source)    
					if duration ~= 0 then 
						return duration, arena
					end 
				end 
			end 
		end  
		
		return 0, str_none
	end, "ROLE"),
	GetDeBuffs 								= Cache:Wrap(function(self, spells, range)
		-- @return number, unitID 
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local duration, arena 
		
		if TeamCacheEnemy.Type then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then 
					duration = A_Unit(arena):HasDeBuffs(spells)  
					if duration ~= 0 then 
						return duration, arena
					end 
				end 
			end 
		end  		
		
		return 0, str_none 
	end, "ROLE"),
	IsBreakAble 							= Cache:Wrap(function(self, range)
		-- @return boolean, unitID 
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local arena 
				
		if TeamCacheEnemy.Type then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) and not UnitIsUnit(arena, "target") and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) and A_Unit(arena):HasDeBuffs("BreakAble") ~= 0 then 
					return true, arena						 
				end 
			end 			  				
		else
			for arena in pairs(ActiveUnitPlates) do               
				if A_Unit(arena):IsPlayer() and CheckUnitByRole(ROLE, arena) and not UnitIsUnit("target", arena) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) and A_Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
					return true, arena	
				end            
			end  			 
		end 
		
		return false, str_none
	end, "ROLE"),
	PlayersInRange 							= Cache:Wrap(function(self, stop, range)
		-- @return boolean, number, unitID 
		-- Nill-able: stop, range
		local ROLE 							= self.ROLE
		local count 						= 0 
		local arena
		
		if TeamCacheEnemy.Type then
			for i = 1, TeamCacheEnemy.Size do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and CheckUnitByRole(ROLE, arena) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then 
					count = count + 1 	
					if not stop or count >= stop then 
						return true, count, arena 				 						
					end 
				end 
			end 					 
		else
			for arena in pairs(ActiveUnitPlates) do                 
				if A_Unit(arena):IsPlayer() and CheckUnitByRole(ROLE, arena) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then
					count = count + 1 	
					if not stop or count >= stop then 
						return true, count, arena 				 						
					end 
				end         
			end   
		end 
		
		return false, count, arena or str_none 
	end, "ROLE"),
	-- [[ Without ROLE argument ]] 
	HasInvisibleUnits 						= Cache:Pass(function(self, checkVisible)
		-- @return boolean, unitID, unitClass
		-- Nill-able: checkVisible
		local arena, class
		
		for i = 1, TeamCacheEnemy.MaxSize do 
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena and not A_Unit(arena):IsDead() then
				class = A_Unit(arena):Class()
				if (class == "ROGUE" or class == "DRUID") and (not checkVisible or not A_Unit(arena):IsVisible()) then 
					return true, arena, class 
				end
			end 
		end 		 
		 
		return false, str_none, str_none
	end, "ROLE"), 
	IsTauntPetAble 							= Cache:Pass(function(self, object, range)
		-- @return boolean, unitID
		-- Nill-able: range
		if TeamCacheEnemy.Size > 0 then 
			local pet
			for i = 1, (TeamCacheEnemy.MaxSize >= 10 and 10 or TeamCacheEnemy.MaxSize) do -- Retail 3, Classic 10
				pet = TeamCacheEnemyIndexToPETs[i]
				if pet then 
					if not object or object:IsInRange(pet) then 
						return true, pet 
					end 
				end              
			end  
		end
		
		return false, str_none
	end, "ROLE"),
	IsCastingBreakAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena 
		
		for i = 1, TeamCacheEnemy.MaxSize do 
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena then 
				local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= (offset or 0.5) then
					for _, spell in ipairs(AuraList.Premonition) do 
						if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= spell[2] then 
							return true, arena
						end 
					end 
				end
			end 
		end
 
		return false, str_none
	end, "ROLE"),
	IsReshiftAble 							= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena 
		
		if not A_Unit("player"):IsFocused("MELEE") then 
			for i = 1, TeamCacheEnemy.MaxSize do 
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena then 
					local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
					if castRemain > 0 and castRemain <= A_GetCurrentGCD() + A_GetGCD() + (offset or 0.05) then 
						for _, spell in ipairs(AuraList.Reshift) do 
							if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= spell[2] then 
								return true, arena
							end
						end 
					end
				end 
			end
		end
		
		return false, str_none
	end, "ROLE"), 
	IsPremonitionAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena 
		
		for i = 1, TeamCacheEnemy.MaxSize do 
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena then 
				local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= A_GetGCD() + (offset + 0.05) then 
					for _, spell in ipairs(AuraList.Premonition) do 
						if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= spell[2] then 
							return true, arena
						end
					end 
				end
			end 
		end
			
		return false, str_none
	end, "ROLE"),
})

function A.EnemyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.05          
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local IsEventIsDied = {
	["UNIT_DIED"] 						= true,
	["UNIT_DESTROYED"]					= true,
	["UNIT_DISSIPATES"]					= true,
	["PARTY_KILL"] 						= true,
	["SPELL_INSTAKILL"] 				= true,
}
Listener:Add("ACTION_EVENT_UNIT", "COMBAT_LOG_EVENT_UNFILTERED", 			function(...)
	local _, EVENT, _, _, _, _, _, DestGUID = CombatLogGetCurrentEventInfo() 
	if IsEventIsDied[EVENT] then 
		InfoCacheMoveIn[DestGUID] 		= nil 
		InfoCacheMoveOut[DestGUID] 		= nil 
		InfoCacheMoving[DestGUID]		= nil 
		InfoCacheStaying[DestGUID]		= nil 
		InfoCacheInterrupt[DestGUID]	= nil 
	end 
end)

Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)
		wipe(InfoCacheInterrupt)
	end 
end)

Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	if CombatTracker:GetSpellLastCast("player", A.LastPlayerCastName) > 1.5 and A.Zone ~= "pvp" and not A.IsInDuel and not Player:IsStealthed() and Player:CastTimeSinceStart() > 5 then 
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)	
		wipe(InfoCacheInterrupt)
	end 
end)

TMW:RegisterCallback("TMW_ACTION_ENTERING",								function(event, subevent)
	if subevent ~= "UPDATE_INSTANCE_INFO" then 
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)	
		wipe(InfoCacheInterrupt)
	end 
end)