local TMW 							= TMW
local CNDT 							= TMW.CNDT
local Env 							= CNDT.Env
local strlowerCache  				= TMW.strlowerCache

local A   							= Action	
--local isEnemy						= A.Bit.isEnemy
--local isPlayer					= A.Bit.isPlayer
local toStr 						= A.toStr
local toNum 						= A.toNum
--local strBuilder					= A.strBuilder
local strElemBuilder				= A.strElemBuilder
--local InstanceInfo				= A.InstanceInfo
local Player 						= A.Player
local TeamCache						= A.TeamCache
local UnitCooldown					= A.UnitCooldown
local CombatTracker					= A.CombatTracker
local MultiUnits					= A.MultiUnits
--local Pet							= LibStub("PetLibrary")
local ThreatLib  					= LibStub("ThreatClassic-1.0")
local LibRangeCheck  				= LibStub("LibRangeCheck-2.0")
local LibClassicCasterino 			= LibStub("LibClassicCasterino")
-- To activate it
LibClassicCasterino.callbacks.OnUsed() 

local _G, setmetatable, table, unpack, select, next, type, pairs, wipe, tostringall, 	  huge, math_floor =
	  _G, setmetatable, table, unpack, select, next, type, pairs, wipe, tostringall, math.huge, math.floor
	  
local CombatLogGetCurrentEventInfo	= _G.CombatLogGetCurrentEventInfo	  
local GetUnitSpeed					= _G.GetUnitSpeed
local GetSpellInfo					= _G.GetSpellInfo
local GetPartyAssignment 			= _G.GetPartyAssignment	  
local UnitIsUnit, UnitInRaid, UnitInAnyGroup, UnitInParty, UnitInRange, UnitLevel, UnitRace, UnitClass, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible =
	  UnitIsUnit, UnitInRaid, UnitInAnyGroup, UnitInParty, UnitInRange, UnitLevel, UnitRace, UnitClass, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible
local UnitAura 						= TMW.UnitAura	  
	  
--local UnitThreatSituation			= function(unit, mob) return ThreatLib:UnitThreatSituation(unit, mob) end 
local UnitDetailedThreatSituation	= function(unit, mob) return ThreatLib:UnitDetailedThreatSituation(unit, mob) end 
	  
-------------------------------------------------------------------------------
-- Cache
-------------------------------------------------------------------------------
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
			this.bufer[func][keyArg] = {}
		end 
		this.bufer[func][keyArg].t = TMW.time + (inv or ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT) + 0.001  -- Add small delay to make sure what it's not previous corroute  
		this.bufer[func][keyArg].v = { func(...) } 

		return unpack(this.bufer[func][keyArg].v)
	end,
	Wrap = function(this, func, name)
		if ACTION_CONST_CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = setmetatable({}, { __mode = "k" })
		end
		
   		return function(...)   
			-- The reason of all this view look is memory hungry eating, this way use less memory 
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
    Curse = 8277, 			-- Voodoo Hex   			(Shaman) 				-- I AM NOT SURE
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
	Fleeing		= {
		5782, 				-- Fear						(Warlock)
		5484, 				-- Howl of Terror   		(Warlock)
		5246, 				-- Intimidating Shout		(Warrior)
		8122, 				-- Psychic Scream			(Priest)
	},
	Shackled = 9484, 		-- Shackle Undead 			(Priest)	
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
    DamageMagicImun = 710, 	-- Banish 					(Warlock)
    CCTotalImun = {},     
    CCMagicImun = 8178,		-- Grounding Totem Effect	(Shaman)
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
        {20066, 20}, 		-- Repentance 				(Paladin)
        {19386, 35, 8},		-- Wyvern Sting (8 - 35)	(Hunter)
    },
    Premonition = {
        {118, 30}, 			-- Polymorph 				(Mage)
		{851, 20},			-- Polymorph: Sheep 		(Mage)
		{28270, 30},		-- Polymorph: Cow	 		(Mage)
        {20066, 20}, 		-- Repentance 				(Paladin)
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
		return 	A.GetToggle(2, unitID) and A.MouseHasFrame() and not A.Unit(unitID):IsEnemy() 
	else
		return 	(
					not A.GetToggle(2, "mouseover") or 
					not A.Unit("mouseover"):IsExists() or 
					A.Unit("mouseover"):IsEnemy()
				) and 
				not A.Unit(unitID):IsEnemy() and
				A.Unit(unitID):IsExists()
	end 
end 
A.IsUnitFriendly = A.MakeFunctionCachedDynamic(A.IsUnitFriendly)

function A.IsUnitEnemy(unitID)
	-- @return boolean
	if unitID == "mouseover" then 
		return  A.GetToggle(2, unitID) and A.Unit(unitID):IsEnemy() 
	elseif unitID == "targettarget" then
		return 	A.GetToggle(2, unitID) and 
				( not A.GetToggle(2, "mouseover") or (not A.MouseHasFrame() and not A.Unit("mouseover"):IsEnemy()) ) and 
				-- Exception to don't pull by mistake mob
				A.Unit(unitID):CombatTime() > 0 and
				not A.Unit("target"):IsEnemy() and
				A.Unit(unitID):IsEnemy() and 
				-- LOS checking 
				not A.UnitInLOS(unitID)						
	else
		return 	( not A.GetToggle(2, "mouseover") or not A.MouseHasFrame() ) and A.Unit(unitID):IsEnemy() 
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
		["trivial"] 	= true,
		["minus"] 		= true,
		["normal"] 		= true,
		["rare"] 		= true,
		["rareelite"] 	= false,
		["elite"] 		= false,
		["worldboss"] 	= false,
		[""] 			= true,
	},
	IsExceptionID 				= {
		-- Warlock 
		[31117] 		= true, 	-- Unstable Affliction (silence after dispel)
		-- Druid 
		[163505] 		= true, 	-- Rake (stun from stealth)
		--[231052] 		= true, 	-- Rake (dot) spell -- seems old id which is not valid in BFA 
		[155722] 		= true, 	-- Rake (dot)
		[203123] 		= true, 	-- Maim (stun)
		-- Death Knight 
		[204085] 		= true, 	-- Deathchill (Frost - PvP Roots)
		[207171] 		= true, 	-- Winter is Coming (Frost - Remorseless Winter Stun)
		-- Rogue  
		[703] 			= true, 	-- Garroute - Dot 
		[1330] 			= true, 	-- Garroute - Silence
	},
}

function Info.UnitIsNameplate(unitID) 
	local nameplates = MultiUnits:GetActiveUnitPlates()
	if nameplates then 
		for nameplateUnit in pairs(nameplates) do 
			if UnitIsUnit(unitID, nameplateUnit) then 
				return true 
			end 
		end 
	end 
end 

A.Unit = PseudoClass({
	-- if it's by "UnitGUID" then it will use cache for different unitID with same unitGUID (which is not really best way to waste performance)
	-- use "UnitGUID" only on high required resource functions
	-- Pass - no cache at all 
	-- Wrap - is a cache 
	Race 									= Cache:Pass(function(self)  
		-- @return string 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return A.PlayerRace
		end 
		
		return select(2, UnitRace(unitID)) or "none"
	end, "UnitID"),
	Class 									= Cache:Pass(function(self)  
		-- @return string 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return A.PlayerClass 
		end 
		
		return select(2, UnitClass(unitID)) or "none"
	end, "UnitID"),
	Role 									= Cache:Pass(function(self, hasRole)  
		-- @return boolean or string (depended on hasRole argument) 
		local unitID 						= self.UnitID
		local role							= "" -- TODO: Classic 
		return (hasRole and hasRole == role) or (not hasRole and role)
	end, "UnitID"),
	Classification							= Cache:Pass(function(self)  
		-- @return string or empty string  
		local unitID 						= self.UnitID
		return UnitClassification(unitID) or ""
	end, "UnitID"),
	InfoGUID 								= Cache:Wrap(function(self, unitGUID)   -- +
		-- @return type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid or nil
		local unitID 						= self.UnitID
		local GUID 							= unitGUID or UnitGUID(unitID)
		if GUID then 
			local massiv = { strsplit("-", GUID) }
			for i = 2, #massiv do 
				massiv[i] = toNum[massiv[i]]
			end 
			return unpack(massiv)
		end 
		return massiv
	end, "UnitID"),
	InLOS 									= Cache:Pass(function(self, unitGUID)   
		-- @return boolean 
		local unitID 						= self.UnitID
		return A.UnitInLOS(unitID, unitGUID)
	end, "UnitID"),
	InGroup 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitInAnyGroup(unitID)
	end, "UnitID"),
	InParty									= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitInParty(unitID)
	end, "UnitID"),
	InRaid									= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitInRaid(unitID)
	end, "UnitID"),
	InRange 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitIsUnit(unitID, "player") or UnitInRange(unitID)
	end, "UnitID"),
	InCC 									= Cache:Pass(function(self, index)
		-- @return number (time in seconds of remain crownd control)
		local unitID 						= self.UnitID
		local value 						= A.Unit(unitID):DeBuffCyclone()
		if value == 0 then 			
			for i = (index or 1), #Info.AllCC do 
				value = A.Unit(unitID):HasDeBuffs(Info.AllCC[i])
				if value ~= 0 then 
					break
				end 
			end 
		end	    
		return value 
	end, "UnitID"),	
	IsEnemy									= Cache:Wrap(function(self, isPlayer)  
		-- @return boolean
		local unitID 						= self.UnitID
		return (unitID and (UnitCanAttack("player", unitID) or UnitIsEnemy("player", unitID)) and (not isPlayer or UnitIsPlayer(unitID))) or false
	end, "UnitID"),
	IsHealer 								= Cache:Wrap(function(self, skipUnitIsUnit, class)  
		-- @return boolean 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return A.Unit("player"):HasSpec(Info.SpecIs.HEALER) 
		end 
		
		if Info.ClassCanBeHealer[class or A.Unit(unitID):Class()] then 		
											-- bypass it in PvP 
			local taken_dmg 				= (A.Unit(unitID):IsEnemy() and A.Unit(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID)
			local done_dmg					= CombatTracker:GetDPS(unitID)
			local done_hps					= CombatTracker:GetHPS(unitID)
			return done_hps > taken_dmg and done_hps > done_dmg  
		end 
	end, "UnitGUID"),
	IsTank 									= Cache:Wrap(function(self, skipUnitIsUnit, class)    
		-- @return boolean 
		local unitID 						= self.UnitID
		if not skipUnitIsUnit and UnitIsUnit(unitID, "player") then 
			return A.Unit("player"):HasSpec(Info.SpecIs.TANK) 
		end 
		
		local unitID_class 					= class or A.Unit(unitID):Class()
		if Info.ClassCanBeTank[unitID_class] then 
			if unitID:match("raid%d+") and GetPartyAssignment("maintank", unitID) then 
				return true 
			end 
			
			if CombatTracker:CombatTime(unitID) == 0 then 
				if unitID_class == "PALADIN" then 
					local _, offhand = UnitAttackSpeed(unitID)
					-- Buff: Righteous Fury 
					return offhand == nil and A.Unit(unitID):HasBuffs(25781) > 0 and A.GetUnitItem(unitID, ACTION_CONST_INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) -- byPassDistance
				elseif unitID_class == "DRUID" then 
					return UnitPowerType(unitID) == 1
				elseif unitID_class == "WARRIOR" then 
					local _, offhand = UnitAttackSpeed(unitID)
					-- Buff: Defensive Stance
					return offhand == nil and A.Unit(unitID):HasBuffs(71) > 0 and A.GetUnitItem(unitID, ACTION_CONST_INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) -- don't byPassDistance
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
		local unitID 						= self.UnitID
		if not skipUnitIsUnit and UnitIsUnit(unitID, "player") then 
			return A.Unit("player"):HasSpec(Info.SpecIs.DAMAGER) 
		end 

		if unitID:match("raid%d+") and GetPartyAssignment("mainassist", unitID) then 
			return true 
		end 
		
											-- bypass it in PvP 
		local taken_dmg 					= (A.Unit(unitID):IsEnemy() and A.Unit(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID) 
		local done_dmg						= CombatTracker:GetDPS(unitID)
		local done_hps						= CombatTracker:GetHPS(unitID)
		return done_dmg > taken_dmg and done_dmg > done_hps 
	end, "UnitGUID"),	
	IsMelee 								= Cache:Wrap(function(self) 
		-- @return boolean 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return A.Unit("player"):HasSpec(Info.SpecIs.MELEE) 
		end 
		
		local class = A.Unit(unitID):Class()
		if Info.ClassCanBeMelee[class] then 
			if A.Unit(unitID):IsTank(true, class) then 
				return true 
			end 
			
			if A.Unit(unitID):IsDamager(true) then 
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
	IsMovingOut								= Cache:Pass(function(self, snap_timer) -- +
		-- @return boolean 
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return true 
		end 
		
		local unitSpeed 					= A.Unit(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then 
			if unitSpeed == A.Unit("player"):GetCurrentSpeed() then 
				return true 
			end 
			
			local GUID 						= UnitGUID(unitID) 
			local _, min_range				= A.Unit(unitID):GetRange()
			if not Info.CacheMoveOut[GUID] then 
				Info.CacheMoveOut[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false 
			end 
			
			if TMW.time - Info.CacheMoveOut[GUID].TimeStamp <= (snap_timer or 0.2) then 
				return Info.CacheMoveOut[GUID].Result
			end 
			
			Info.CacheMoveOut[GUID].TimeStamp = TMW.time 
			
			if min_range == Info.CacheMoveOut[GUID].Range then 
				return Info.CacheMoveOut[GUID].Result
			end 
			
			if min_range > Info.CacheMoveOut[GUID].Range then 
				Info.CacheMoveOut[GUID].Snapshot = Info.CacheMoveOut[GUID].Snapshot + 1 
			else 
				Info.CacheMoveOut[GUID].Snapshot = Info.CacheMoveOut[GUID].Snapshot - 1
			end		

			Info.CacheMoveOut[GUID].Range = min_range
			
			if Info.CacheMoveOut[GUID].Snapshot >= 3 then 
				Info.CacheMoveOut[GUID].Snapshot = 2
				Info.CacheMoveOut[GUID].Result = true 
				return true 
			else
				if Info.CacheMoveOut[GUID].Snapshot < 0 then 
					Info.CacheMoveOut[GUID].Snapshot = 0 
				end 
				Info.CacheMoveOut[GUID].Result = false
				return false 
			end 
		end 		
	end, "UnitGUID"),
	IsMovingIn								= Cache:Pass(function(self, snap_timer) -- +
		-- @return boolean 		
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving 
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then 
			return true 
		end 
		
		local unitSpeed 					= A.Unit(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then 
			if unitSpeed == A.Unit("player"):GetCurrentSpeed() then 
				return true 
			end 
			
			local GUID 						= UnitGUID(unitID) 
			local _, min_range				= A.Unit(unitID):GetRange()
			if not Info.CacheMoveIn[GUID] then 
				Info.CacheMoveIn[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false 
			end 
			
			if TMW.time - Info.CacheMoveIn[GUID].TimeStamp <= (snap_timer or 0.2) then 
				return Info.CacheMoveIn[GUID].Result
			end 
			
			Info.CacheMoveIn[GUID].TimeStamp = TMW.time 
			
			if min_range == Info.CacheMoveIn[GUID].Range then 
				return Info.CacheMoveIn[GUID].Result
			end 
			
			if min_range < Info.CacheMoveIn[GUID].Range then 
				Info.CacheMoveIn[GUID].Snapshot = Info.CacheMoveIn[GUID].Snapshot + 1 
			else 
				Info.CacheMoveIn[GUID].Snapshot = Info.CacheMoveIn[GUID].Snapshot - 1
			end		

			Info.CacheMoveIn[GUID].Range = min_range
			
			if Info.CacheMoveIn[GUID].Snapshot >= 3 then 
				Info.CacheMoveIn[GUID].Snapshot = 2
				Info.CacheMoveIn[GUID].Result = true 
				return true 
			else
				if Info.CacheMoveIn[GUID].Snapshot < 0 then 
					Info.CacheMoveIn[GUID].Snapshot = 0 
				end 			
				Info.CacheMoveIn[GUID].Result = false
				return false 
			end 
		end 		
	end, "UnitGUID"),
	IsMoving								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return Player:IsMoving()
		else 
			return A.Unit(unitID):GetCurrentSpeed() ~= 0
		end 
	end, "UnitID"),
	IsMovingTime							= Cache:Pass(function(self)	-- +
		-- @return number 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return Player:IsMovingTime()
		else 
			local GUID						= UnitGUID(unitID) 
			local isMoving  				= A.Unit(unitID):IsMoving()
			if isMoving then
				if not Info.CacheMoving[GUID] or Info.CacheMoving[GUID] == 0 then 
					Info.CacheMoving[GUID] = TMW.time 
				end                        
			else 
				Info.CacheMoving[GUID] = 0
			end 
			return (Info.CacheMoving[GUID] == 0 and -1) or TMW.time - Info.CacheMoving[GUID]
		end 
	end, "UnitGUID"),
	IsStaying								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return Player:IsStaying()
		else 
			return A.Unit(unitID):GetCurrentSpeed() == 0
		end 		
	end, "UnitID"),
	IsStayingTime							= Cache:Pass(function(self) -- +
		-- @return number 
		local unitID 						= self.UnitID
		if unitID == "player" then 
			return Player:IsStayingTime()
		else 
			local GUID						= UnitGUID(unitID) 
			local isMoving  				= A.Unit(unitID):IsMoving()
			if not isMoving then
				if not Info.CacheStaying[GUID] or Info.CacheStaying[GUID] == 0 then 
					Info.CacheStaying[GUID] = TMW.time 
				end                        
			else 
				Info.CacheStaying[GUID] = 0
			end 
			return (Info.CacheStaying[GUID] == 0 and -1) or TMW.time - Info.CacheStaying[GUID]
		end
	end, "UnitGUID"),
	IsCasting 								= Cache:Wrap(function(self) -- +
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
				notInterruptable = A.Unit(unitID):HasBuffs("KickImun") ~= 0 
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
		local unitID 						= self.UnitID
		return select(2, A.Unit(unitID):CastTime(argSpellID))
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
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(unitID):IsCasting()

		local TotalCastTime, CurrentCastTimeSeconds, CurrentCastTimeLeftPercent = 0, 0, 0
		if unitID == "player" then 
			TotalCastTime = (select(4, GetSpellInfo(argSpellID or spellID)) or 0) / 1000
			CurrentCastTimeSeconds = TotalCastTime
		end 
		
		if castName and (not argSpellID or A.GetSpellInfo(argSpellID) == castName) then 
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
		local castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable = A.Unit(unitID):CastTime()
		
		if castLeft > 0 and (not range or A.Unit(unitID):GetRange() <= range) then
			local query = (type(spells) == "table" and spells) or AuraList.CastBarsCC  
			for i = 1, #query do 				
				if castID == query[i] or castName == A.GetSpellInfo(query[i]) then 
					break
				end 
			end         
		end   
		
		return castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable
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
		local unitID 						= self.UnitID 
		if not A.IsInPvP then 
			return not A.Unit(unitID):IsBoss() and Info.ControlAbleClassification[A.Unit(unitID):Classification()] and (not drCat or A.Unit(unitID):GetDR(drCat) > (drDiminishing or 25))
		else 
			return not drCat or A.Unit(unitID):GetDR(drCat) > (drDiminishing or 25)
		end 
	end, "UnitID"),
	IsUndead								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID 
		local unitType 						= UnitCreatureType(unitID) or ""
		return Info.IsUndead[unitType]	       	
	end, "UnitID"),
	IsTotem 								= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID 
		local unitType 						= UnitCreatureType(unitID) or ""
		return Info.IsTotem[unitType]	       	
	end, "UnitID"),
	IsDummy									= Cache:Pass(function(self)	
		-- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= A.Unit(unitID):InfoGUID()
		return npc_id and Info.IsDummy[npc_id]
	end, "UnitID"),
	IsDummyPvP								= Cache:Pass(function(self)	
		-- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= A.Unit(unitID):InfoGUID()
		return npc_id and Info.IsDummyPvP[npc_id]
	end, "UnitID"),
	IsBoss 									= Cache:Pass(function(self)       
	    -- @return boolean 
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= A.Unit(unitID):InfoGUID()
		if npc_id and not Info.IsNotBoss[npc_id] then 
			if Info.IsBoss[npc_id] or A.Unit(unitID):GetLevel() == -1 then 
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
		local unitID 						= self.UnitID
		if unitID then 
			local GUID 						= UnitGUID(unitID)					
			if GUID and TeamCache.threatData[GUID] then 
				if otherunitID and not UnitIsUnit(otherunitID, TeamCache.threatData[GUID].unit) then 
					-- By specified otherunitID
					-- Note: I prefer avoid use this as much as it possible since less performance 
					local _, status, scaledPercent, _, threatValue = UnitDetailedThreatSituation(unitID, otherunitID) -- Lib modified to return by last argument unitGUID!
					if threatValue and threatValue < 0 then
						threatValue = threatValue + 410065408
					end					
					return status or 0, scaledPercent or 0, threatValue or 0
				else 
					-- By own unit's target 
					return TeamCache.threatData[GUID].status, TeamCache.threatData[GUID].scaledPercent, TeamCache.threatData[GUID].threatValue       
				end 
			end 
		end 
		return 0, 0, 0
	end, "UnitID"),
	IsTanking 								= Cache:Pass(function(self, otherunitID, range)  
		-- @return boolean 
		local unitID 						= self.UnitID	
		local ThreatSituation 				= A.Unit(unitID):ThreatSituation(otherunitID) -- cacheed defaultly own target but if need to check something additional here is otherunitID
		return ((A.IsInPvP and UnitIsUnit(unitID, (otherunitID or "target") .. "target")) or (not A.IsInPvP and ThreatSituation >= 3)) or A.Unit(unitID):IsTankingAoE(range)	       
	end, "UnitID"),
	IsTankingAoE 							= Cache:Pass(function(self, range) 
		-- @return boolean 
		local unitID 						= self.UnitID
		local activeUnitPlates 				= MultiUnits:GetActiveUnitPlates()
		if activeUnitPlates then
			for unit in pairs(activeUnitPlates) do
				local ThreatSituation 		= A.Unit(unitID):ThreatSituation() -- cacheed defaultly own target 
				if ((A.IsInPvP and UnitIsUnit(unitID, unit .. "target")) or (not A.IsInPvP and ThreatSituation >= 3)) and (not range or A.Unit(unitID):CanInterract(range)) then 
					return true  
				end
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
		return select(2, A.Unit(unitID):GetCurrentSpeed())
	end, "UnitGUID"),
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
	GetCooldown								= Cache:Pass(function(self, spellID)
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched) 
		local unitID 						= self.UnitID
		return UnitCooldown:GetCooldown(unitID, spellID)
	end, "UnitID"),
	GetMaxDuration							= Cache:Pass(function(self, spellID)
		-- @return number (max cooldown of the spell on a unit) 
		local unitID 						= self.UnitID
		return UnitCooldown:GetMaxDuration(unitID, spellID)
	end, "UnitID"),
	GetUnitID								= Cache:Pass(function(self, spellID)
		-- @return unitID (who last casted spell) otherwise nil  
		local unitID 						= self.UnitID
		return UnitCooldown:GetUnitID(unitID, spellID)
	end, "UnitID"),
	GetBlinkOrShrimmer						= Cache:Pass(function(self)
		-- @return number, number, number 
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown 
		local unitID 						= self.UnitID
		return UnitCooldown:GetBlinkOrShrimmer(unitID)
	end, "UnitID"),
	IsSpellInFly							= Cache:Pass(function(self, spellID)
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitCooldown:IsSpellInFly(unitID, spellID)
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
			return select(index, CombatTracker:GetDMG(unitID))
		else
			return CombatTracker:GetDMG(unitID)
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
	GetIncomingHeals						= Cache:Pass(function(self)
		-- @return number 
		--[[ TODO: Classic (Idea is:
		0. Create in Combat.lua local 2 special tables to log incoming heals for each GUID and Caster with destGUID + descript
		1. Register callbacks from LibClassCasterino
		2. Then on each caster check their target, if found then get GUID of that 
		3. Get spellName of cast and compare it with own table of all healing spells 
		4. Get through Actions.lua description for highest possible heal by highest spell rank
		5. Add this descript as incoming value to dest GUID / Add to Caster table destGUID and descript 
		6. If cast stopped or interrupted by caster then get his GUID and decrease from destGUID descript from total incoming value 
		7. Clear Caster table 
		8. If our level lower than max possible per expansion level then return 0 to prevent issues with different ranks 
		Also make it working only on max level because CLEU provide only spellName which can't be reversed to receive spellID by which could be possible get exactly rank, it's limtied so we will assume what all spells will be highest rank 
		Again, this is TODO and will be added later with time, just leaved this manual for own needs here ]]
		local unitID 						= self.UnitID
		return 0
	end, "UnitID"),
	GetRange 								= Cache:Wrap(function(self) -- +
		-- @return number (max), number (min)
		local unitID 						= self.UnitID
		local min_range, max_range 			= LibRangeCheck:GetRange(unitID)
		if not max_range then 
			return 0, 0 
		end 
		
		-- Limit range to 20 if unitID is nameplated and max range over normal behaivor 
		if max_range > ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE and A.Unit(unitID):IsEnemy() and Info.UnitIsNameplate(unitID) then 
			return ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE, min_range
		end 			
		
	    return max_range, min_range 
	end, "UnitGUID"),
	CanInterract							= Cache:Pass(function(self, range) 
		-- @return boolean  
		local unitID 						= self.UnitID
		local min_range 					= A.Unit(unitID):GetRange()
		
		-- Holy Paladin Talent Range buff +50%
		if A.Unit("player"):HasSpec(65) and A.Unit("player"):HasBuffs(214202, true) > 0 then 
			range = range * 1.5 
		end
		-- Moonkin and Restor +5 yards
		if A.Unit("player"):HasSpec({102, 105}) and A.IsSpellLearned(197488) then 
			range = range + 5 
		end  
		-- Feral and Guardian +3 yards
		if A.Unit("player"):HasSpec({103, 104}) and A.IsSpellLearned(197488) then 
			range = range + 3 
		end
		
		return min_range and min_range > 0 and range and min_range <= range		
	end, "UnitID"),
	CanInterrupt							= Cache:Pass(function(self, kickAble, auras, minX, maxX)
		-- @return boolean 
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(unitID):IsCasting()
		if castName and (not kickAble or not notInterruptable) then 
			if auras then 
				if type(auras) == "table" then 
					for i = 1, #auras do 
						if A.Unit(unitID):HasBuffs(auras[i]) > 0 then 
							return false 
						end 
					end 
				elseif A.Unit(unitID):HasBuffs(auras) > 0 then 
					return false 
				end 
			end 
			
			local GUID 						= UnitGUID(unitID)
			if not Info.CacheInterrupt[GUID] or Info.CacheInterrupt[GUID].LastCast ~= castName then 
				Info.CacheInterrupt[GUID] = { LastCast = castName, Timer = math.random(minX or 34, maxX or 68) }
			end 
			
			local castPercent = ((TMW.time * 1000) - castStartTime) * 100 / (castEndTime - castStartTime)
			return castPercent >= Info.CacheInterrupt[GUID].Timer 
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
	    return A.Unit(unitID):HasBuffs(AuraList.Flags) > 0 
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
	    return A.Unit(unitID):HealthMax() - A.Unit(unitID):Health()
	end, "UnitID"),
	HealthDeficitPercent					= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return 100 - A.Unit(unitID):HealthPercent()
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
	    return A.Unit(unitID):PowerMax() - A.Unit(unitID):Power()
	end, "UnitID"),
	PowerDeficitPercent						= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):PowerDeficit() * 100 / A.Unit(unitID):PowerMax()
	end, "UnitID"),
	PowerPercent							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):Power() * 100 / A.Unit(unitID):PowerMax()
	end, "UnitID"),
	AuraTooltipNumber						= Cache:Wrap(function(self, spellID, filter) -- + -->
		-- @return number 
		local unitID 						= self.UnitID
		local name							= strlowerCache[A.GetSpellInfo(spellID)]
	    return Env.AuraTooltipNumber(unitID, name, filter) or 0
	end, "UnitGUID"),
	DeBuffCyclone 							= Cache:Wrap(function(self)
		-- @return number 
		return 0 -- Right now no such effects 
		--local unitID 						= self.UnitID
		--local banishName					= strlowerCache[A.GetSpellInfo(710)] -- Banish 
		--return Env.AuraDur(unitID, banishName, "HARMFUL")
	end, "UnitGUID"),	
	GetDeBuffInfo							= Cache:Pass(function(self, auraTable, caster)
		-- @return number, number, number, number 
		-- rank, remain duration, total duration, stacks 
		-- auraTable is { [spellID] = rank, [18] = 1 }
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		
		for i = 1, huge do			
			local Name, _, count, _, duration, expirationTime, _,_,_, id = UnitAura(unitID, i, filter)
			
			if Name then					
				if auraTable[id] then 
					return auraTable[id], expirationTime == 0 and huge or expirationTime - TMW.time, duration, count
				end 
			else
				break 
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	GetDeBuffInfoByName						= Cache:Pass(function(self, auraName, caster)
		-- @return number, number, number, number 
		-- spellID, remain duration, total duration, stacks 
		-- auraName must be exactly @string 
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		
		for i = 1, huge do			
			local Name, _, count, _, duration, expirationTime, _,_,_, id = UnitAura(unitID, i, filter)
			
			if Name then					
				if Name == auraName then 
					return id, expirationTime == 0 and huge or expirationTime - TMW.time, duration, count
				end 
			else
				break 
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	IsDeBuffsLimited						= Cache:Pass(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID	
		local auras 						= 0 
		
		for i = 1, ACTION_CONST_AURAS_MAX_LIMIT do			
			local Name = UnitAura(unitID, i, "HARMFUL")
			
			if Name then					
				auras = auras + 1
			else
				break 
			end 
		end 
		
		return auras >= ACTION_CONST_AURAS_MAX_LIMIT
	end, "UnitID"), 
	HasDeBuffs 								= Cache:Pass(function(self, spell, caster, byID)
		-- @return number, number 
		-- current remain, total applied duration
		-- Sorting method
		local unitID 						= self.UnitID
        local value, duration 				= 0, 0
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		
        if not A.IsInitialized and A.Unit(unitID):DeBuffCyclone() > 0 then 
            value, duration = -1, -1
        else
            value, duration = A.Unit(unitID):SortDeBuffs(spell, caster, byID) 
        end    
		
        return value, duration   
    end, "UnitID"),
	SortDeBuffs								= Cache:Pass(function(self, spell, caster, byID)
		-- @return sorted number, number 
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		local dur, duration
		
		if type(spell) == "table" then
			local SortTable = {} 
			
			for i = 1, #spell do            
				dur, duration = Env.AuraDur(unitID, (not byID and not Info.IsExceptionID[spell[i]] and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter)                       
				if dur > 0 then
					table.insert(SortTable, {dur, duration})
					
					if #SortTable > 1 then
						if SortTable[1][1] >= SortTable[2][1] then 
							table.remove(SortTable, #SortTable)
						else
							table.remove(SortTable, 1)
						end 
					end 
				end
			end  

			if #SortTable > 0 then
				dur, duration = SortTable[1][1], SortTable[1][2]
			end 
		else
			dur, duration = Env.AuraDur(unitID, (not byID and not Info.IsExceptionID[spell] and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter)
		end   
		
		return dur, duration   
    end, "UnitGUID"),
	HasDeBuffsStacks						= Cache:Pass(function(self, spell, caster, byID)
		-- @return number
		local unitID 						= self.UnitID
		local filter
		if caster then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HARMFUL"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		
		if not A.IsInitialized and A.Unit(unitID):DeBuffCyclone() > 0 then 
			return 0
		elseif type(spell) == "table" then		
			for i = 1, #spell do 
				local stacks = Env.AuraStacks(unitID, (not byID and not Info.IsExceptionID[spell[i]] and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter)
				if stacks > 0 then 
					return stacks
				end 
			end 
		else 
			return Env.AuraStacks(unitID, (not byID and not Info.IsExceptionID[spell] and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter)
		end 
    end, "UnitGUID"),
	-- Pandemic Threshold
	PT										= Cache:Pass(function(self, spell, debuff, byID)    
		-- @return boolean 
		local unitID 						= self.UnitID
		local filter
		if debuff then 
			filter = "HARMFUL PLAYER"
		else 
			filter = "HELPFUL PLAYER"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		
		if type(spell) == "table" then	
			for i = 1, #spell do
				if Env.AuraPercent(unitID, (not byID and not Info.IsExceptionID[spell[i]] and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter) <= 0.3 then 
					return true 
				end 
			end 	
		else 
			return Env.AuraPercent(unitID, (not byID and not Info.IsExceptionID[spell] and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter) <= 0.3 
		end 
    end, "UnitGUID"),
	GetBuffInfo								= Cache:Pass(function(self, auraTable, caster)
		-- @return number, number, number, number 
		-- rank, remain duration, total duration, stacks 
		-- auraTable is { [spellID] = rank, [18] = 1 }
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		
		for i = 1, huge do			
			local Name, _, count, _, duration, expirationTime, _,_,_, id = UnitAura(unitID, i, filter)
			
			if Name then					
				if auraTable[id] then 
					return auraTable[id], expirationTime == 0 and huge or expirationTime - TMW.time, duration, count
				end 
			else
				break 
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	GetBuffInfoByName						= Cache:Pass(function(self, auraName, caster)
		-- @return number, number, number, number 
		-- spellID, remain duration, total duration, stacks 
		-- auraName must be exactly @string 
		local unitID 						= self.UnitID		
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		
		for i = 1, huge do			
			local Name, _, count, _, duration, expirationTime, _,_,_, id = UnitAura(unitID, i, filter)
			
			if Name then					
				if Name == auraName then 
					return id, expirationTime == 0 and huge or expirationTime - TMW.time, duration, count
				end 
			else
				break 
			end 
		end 
		
		return 0, 0, 0, 0
	end, "UnitID"),
	HasBuffs 								= Cache:Pass(function(self, spell, caster, byID)
		-- @return number, number 
		-- current remain, total applied duration	
		-- Normal method 
		local unitID 						= self.UnitID
		local value, duration 				= 0, 0	
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		
		if not A.IsInitialized and A.Unit(unitID):DeBuffCyclone() > 0 then 
			value, duration = -1, -1
		else
			if type(spell) == "table" then         
				for i = 1, #spell do            
					value, duration = Env.AuraDur(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter)                       
					if value > 0 then
						break
					end
				end
			else
				value, duration = Env.AuraDur(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter)
			end   
		end		
		
	    return value, duration		
	end, "UnitGUID"),
	SortBuffs 								= Cache:Pass(function(self, spell, caster, byID)
		-- @return number, number 
		-- current remain, total applied duration	
		local unitID 						= self.UnitID
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell
		local dur, duration	
    	
		if type(spell) == "table" then
			local SortTable = {} 
			
			for i = 1, #spell do            
				dur, duration = Env.AuraDur(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter)                       
				if dur > 0 then
					table.insert(SortTable, {dur, duration})
				end
				
				if #SortTable > 1 then
					if SortTable[1][1] >= SortTable[2][1] then 
						table.remove(SortTable, #SortTable)
					else
						table.remove(SortTable, 1)
					end 
				end 
			end    
			
			if #SortTable > 0 then
				dur, duration = SortTable[1][1], SortTable[1][2]
			end 
		else
			dur, duration = Env.AuraDur(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter)
		end   
    
		return dur, duration 		
	end, "UnitGUID"),
	HasBuffsStacks 							= Cache:Pass(function(self, spell, caster, byID)
		-- @return number 
	    local unitID 						= self.UnitID
		local filter
		if caster then 
			filter = "HELPFUL PLAYER"
		else 
			filter = "HELPFUL"
		end 
		local spell 						= type(spell) == "string" and AuraList[spell] or spell

		if not A.IsInitialized and A.Unit(unitID):DeBuffCyclone() > 0 then 
			return 0
		elseif type(spell) == "table" then         
			for i = 1, #spell do 
				local stacks = Env.AuraStacks(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell[i])]) or spell[i], filter)
				if stacks > 0 then
					return stacks
				end
			end
		else 
			return Env.AuraStacks(unitID, (not byID and strlowerCache[A.GetSpellInfo(spell)]) or spell, filter)
		end 		         
	end, "UnitGUID"),
	IsFocused 								= Cache:Wrap(function(self, burst, deffensive, range, isMelee)
		-- @return boolean
		-- ATTENTION: Instead of retail version this function accepts in arguments now numbers only! Retail has boolean for some of them
		local unitID 						= self.UnitID
		
		if burst ~= nil and type(burst) == "boolean" then 
			burst = 4
		end 

		if A.Unit(unitID):IsEnemy() then
			if TeamCache.Friendly.Type then 
				for i = 1, TeamCache.Friendly.Size do 
					local member = TeamCache.Friendly.Type .. i 
					if  UnitIsUnit(member .. "target", unitID) 
					and not UnitIsUnit(member, "player")
					and ((not isMelee and A.Unit(member):IsDamager()) or (isMelee and A.Unit(member):IsMelee()))
					and (not burst 		or 	A.Unit(member):HasBuffs("DamageBuffs") >= burst) 
					and (not deffensive or 	A.Unit(unitID):HasBuffs("DeffBuffs") <= deffensive)
					and (not range 		or 	A.Unit(member):GetRange() <= range) 					
					then 
						return true 
					end 
				end 
			end 
		else
			if TeamCache.Enemy.Type then 
				for i = 1, TeamCache.Enemy.Size do 
					local arena = TeamCache.Enemy.Type .. i 
					if  UnitIsUnit(arena .. "target", unitID) 
					and ((not isMelee and A.Unit(arena):IsDamager()) or (isMelee and A.Unit(arena):IsMelee()))
					and (not burst 		or	A.Unit(arena):HasBuffs("DamageBuffs") >= burst) 
					and (not deffensive or 	A.Unit(unitID):HasBuffs("DeffBuffs") <= deffensive)
					and (not range 		or	A.Unit(arena):GetRange() <= range)
					then 
						return true 
					end 
				end 
			end 
		end 
	end, "UnitGUID"),
	IsExecuted 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID

		return A.Unit(unitID):TimeToDieX(20) <= A.GetGCD() + A.GetCurrentGCD()
	end, "UnitGUID"),
	UseBurst 								= Cache:Wrap(function(self, pBurst)
		-- @return boolean
		local unitID 						= self.UnitID

		if A.Unit(unitID):IsEnemy() then
			return A.Unit(unitID):IsPlayer() and 
			(
				A.Zone == "none" or 
				A.Unit(unitID):TimeToDieX(25) <= A.GetGCD() * 4 or
				(
					A.Unit(unitID):IsHealer() and 
					(
						(
							A.Unit(unitID):CombatTime() > 5 and 
							A.Unit(unitID):TimeToDie() <= 10 and 
							A.Unit(unitID):HasBuffs("DeffBuffs") == 0                      
						) or
						A.Unit(unitID):HasDeBuffs("Silenced") >= A.GetGCD() * 2 or 
						A.Unit(unitID):HasDeBuffs("Stuned") >= A.GetGCD() * 2                         
					)
				) or 
				A.Unit(unitID):IsFocused(true) or 
				A.EnemyTeam("HEALER"):GetCC() >= A.GetGCD() * 3 or
				(
					pBurst and 
					A.Unit("player"):HasBuffs("DamageBuffs") >= A.GetGCD() * 3
				)
			)       
		elseif A.IamHealer then 
			-- For HealingEngine as Healer
			return A.Unit(unitID):IsPlayer() and 
			(
				A.Unit(unitID):IsExecuted() or
				(
					A.Unit(unitID):HasFlags() and                                         
					A.Unit(unitID):CombatTime() > 0 and 
					A.Unit(unitID):GetRealTimeDMG() > 0 and 
					A.Unit(unitID):TimeToDie() <= 14 and 
					(
						A.Unit(unitID):TimeToDie() <= 8 or 
						A.Unit(unitID):HasBuffs("DeffBuffs") < 1                         
					)
				) or 
				(
					A.Unit(unitID):IsFocused(true) and 
					(
						A.Unit(unitID):TimeToDie() <= 10 or 
						A.Unit(unitID):HealthPercent() <= 70
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
			A.Unit(unitID):IsFocused(4) or 
			(
				A.Unit(unitID):TimeToDie() < 8 and 
				A.Unit(unitID):IsFocused() 
			) or 
			A.Unit(unitID):IsExecuted()
		) 			
	end, "UnitGUID"),	
})	

function A.Unit:New(UnitID, Refresh)
	self.UnitID 	= UnitID
	self.Refresh 	= Refresh
end

local function CheckUnitByRole(ROLE, unitID)
	return  not ROLE 													or 
			(ROLE == "HEALER" 			and A.Unit(unitID):IsHealer()) 	or 
			(ROLE == "TANK"   			and A.Unit(unitID):IsTank()) 	or 
			(ROLE == "DAMAGER" 			and A.Unit(unitID):IsDamager()) or 
			(ROLE == "DAMAGER_MELEE"	and A.Unit(unitID):IsMelee())	or 
			(ROLE == "DAMAGER_RANGE"	and A.Unit(unitID):IsDamager() and not A.Unit(unitID):IsMelee())
end 

-------------------------------------------------------------------------------
-- API: FriendlyTeam 
-------------------------------------------------------------------------------

A.FriendlyTeam = PseudoClass({
	GetUnitID 								= Cache:Wrap(function(self, range)
		-- @return string or nil 
		local ROLE 							= self.ROLE
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do 
				local member = TeamCache.Friendly.Type .. i 
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then 
					return member
				end 
			end 
		end  
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		
		if TeamCache.Friendly.Size <= 1 then 
			if spells then 
				local g = A.Unit("player"):HasDeBuffs(spells) 
				if g ~= 0 then 
					return g, "player"
				else 
					return value, member 
				end 
			else 
				local d = A.Unit("player"):InCC()
				if d ~= 0 then 
					return d, "player"
				else 
					return value, member
				end 
			end 
		end 		
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) then 
					if spells then 
						value = A.Unit(member):HasDeBuffs(spells) 
						if value ~= 0 then 
							return value, member 
						end 					
					else
						value = A.Unit(member):InCC()
						if value ~= 0 then 
							return value, member 
						end 
					end 	
				end 
			end		
		end 

		return 0, "none"
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, Buffs, range, iSource)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		if TeamCache.Friendly.Size <= 1 then 
			local d = A.Unit("player"):HasBuffs(spells, iSource)
			if d ~= 0 then 
				return d, "player"
			else 
				return value, member
			end 
		end 	

		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then 
					value = A.Unit(member):HasBuffs(Buffs, iSource) 
					if value ~= 0 then 
						return value, member
					end   
				end 
			end		
		end 		
		
		return 0, "none"
	end, "ROLE"),
	GetDeBuffs		 						= Cache:Wrap(function(self, DeBuffs, range)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		
		if TeamCache.Friendly.Size <= 1 then 
			local d = A.Unit("player"):HasDeBuffs(DeBuffs)
			if d ~= 0 then 
				return d, "player"
			else 
				return value, member
			end 
		end 		

		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then
					value = A.Unit(member):HasDeBuffs(DeBuffs)  
					if value ~= 0 then 
						return value, member
					end   
				end 
			end		
		end 				
		
		return value, "none"
	end, "ROLE"),
	GetTTD 									= Cache:Wrap(function(self, count, seconds, range)
		-- @return boolean, counter, unitID 
		local ROLE 							= self.ROLE
		local value, counter, member 		= false, 0, "none"
		
		if TeamCache.Friendly.Size <= 1 then 
			if A.Unit("player"):TimeToDie() <= seconds then
				return true, 1, "player"
			else 
				return value, counter, member
			end 
		end 		
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) and A.Unit(member):TimeToDie() <= seconds then
					counter = counter + 1        
					if counter >= count then 
						value = true
						break
					end
				end 
			end		
		end 					
		
		return value, counter, member
	end, "ROLE"),
	AverageTTD 								= Cache:Wrap(function(self)
		-- @return number, number 
		local ROLE 							= self.ROLE
		local value, members 				= 0, 0
		if TeamCache.Friendly.Size <= 1 then 
			return A.Unit("player"):TimeToDie(), 1
		end 
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() then
					value = value + A.Unit(member):TimeToDie()
					members = members + 1
				end 
			end		
		end 			
		
		if members > 0 then 
			value = value / members
		end 
		
		return value, members
	end, "ROLE"),	
	MissedBuffs 							= Cache:Wrap(function(self, spells, iSource)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= false, "none"
		if TeamCache.Friendly.Size <= 1 then 
			local d = A.Unit("player"):HasBuffs(spells, iSource) 
			if d == 0 then 
				return true, "player"
			else 
				return value, member
			end 
		end 
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and A.Unit(member):InRange() and not A.Unit(member):IsDead() and A.Unit(member):HasBuffs(spells, iSource) == 0 then
					return true, member 
				end 
			end		
		end 					
		
		return value, "none" 
	end, "ROLE"),
	PlayersInCombat 						= Cache:Wrap(function(self, range, combatTime)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= false, "none"
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole(ROLE, member) and ((not range and A.Unit(member):InRange()) or (range and A.Unit(member):GetRange() <= range)) and A.Unit(member):CombatTime() > 0 and (not combatTime or A.Unit(member):CombatTime() <= combatTime) then
					return true, member 
				end 
			end		
		end 			
		
		return value, "none" 
	end, "ROLE"),
	HealerIsFocused 						= Cache:Wrap(function(self, burst, deffensive, range, isMelee)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= false, "none"
		
		if TeamCache.Friendly.Type then 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if CheckUnitByRole("HEALER", member) and A.Unit(member):InRange() and A.Unit(member):IsFocused(burst, deffensive, range, isMelee) then
					return true, member 
				end 
			end		
		end 				
		
		return value, "none" 
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
	GetUnitID 								= Cache:Wrap(function(self, range)
		-- @return string or nil 
		local ROLE 							= self.ROLE

		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				local arena = TeamCache.Enemy.Type .. i 
				if CheckUnitByRole(ROLE, arena) and not A.Unit(arena):IsDead() and (not range or A.Unit(arena):GetRange() <= range) then 
					return arena
				end 
			end 
		end  
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i 
				if CheckUnitByRole(ROLE, arena) then 
					if spells then 
						value = A.Unit(arena):HasDeBuffs(spells) 
						if value ~= 0 then 
							return value,  arena
						end 
					elseif ROLE ~= "HEALER" or not UnitIsUnit(arena, "target") then 
						value = A.Unit(arena):InCC()
						if value ~= 0 then 
							return value,  arena 
						end 
					end 
				end 
			end 
		end  		
		
		return value, "none" 
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, Buffs, range, iSource)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i 
				if CheckUnitByRole(ROLE, arena) and (not range or A.Unit(arena):GetRange() <= range) then 
					value = A.Unit(arena):HasBuffs(Buffs, iSource)    
					if value ~= 0 then 
						return value, arena
					end 
				end 
			end 
		end  
		
		return value, "none" 
	end, "ROLE"),
	GetDeBuffs 								= Cache:Wrap(function(self, DeBuffs, range)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i 
				if CheckUnitByRole(ROLE, arena) and (not range or A.Unit(arena):GetRange() <= range) then 
					value = A.Unit(arena):HasDeBuffs(DeBuffs)  
					if value ~= 0 then 
						return value, arena
					end 
				end 
			end 
		end  		
		
		return value, "none" 
	end, "ROLE"),
	IsBreakAble 							= Cache:Wrap(function(self, range)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= false, "none"
				
		if ROLE then 		
			if TeamCache.Enemy.Type then 
				for i = 1, TeamCache.Enemy.Size do 
					arena = TeamCache.Enemy.Type .. i 
					if CheckUnitByRole(ROLE, arena) and not UnitIsUnit(arena, "target") and (not range or A.Unit(arena):GetRange() <= range) and A.Unit(arena):HasDeBuffs("BreakAble") ~= 0 then 
						return true, arena						 
					end 
				end 
			end  				
		else
			local activeUnitPlates 			= MultiUnits:GetActiveUnitPlates()
			if activeUnitPlates then 
				for arena in pairs(activeUnitPlates) do               
					if A.Unit(arena):IsPlayer() and not UnitIsUnit("target", arena) and (not range or A.Unit(arena):GetRange() <= range) and A.Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
						return true, arena	
					end            
				end  
			end 
		end 
		
		return value, "none" 
	end, "ROLE"),
	PlayersInRange 							= Cache:Wrap(function(self, stop, range)
		-- @return boolean, number, unitID 
		local ROLE 							= self.ROLE
		local value, count, arena 			= false, 0, "none"
		
		if ROLE then 
			if TeamCache.Enemy.Type then
				for i = 1, TeamCache.Enemy.Size do 
					arena = TeamCache.Enemy.Type .. i 
					if CheckUnitByRole(ROLE, arena) and (not range or A.Unit(arena):GetRange() <= range) then 
						count = count + 1 	
						if not stop then 
							value = true 
						elseif count >= stop then 
							value = true 
							break 				 						
						end 
					end 
				end 		
			end 
		else
			local activeUnitPlates 			= MultiUnits:GetActiveUnitPlates()
			if activeUnitPlates then 
				for arena in pairs(activeUnitPlates) do                 
					if A.Unit(arena):IsPlayer() and (not range or A.Unit(arena):GetRange() <= range) then
						count = count + 1 	
						if not stop then 
							value = true 
						elseif count >= stop then 
							value = true 
							break 
						end 
					end         
				end  
			end 
		end 
		
		return value, count, arena 
	end, "ROLE"),
	-- Without ROLE argument
	HasInvisibleUnits 						= Cache:Pass(function(self)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
		if TeamCache.Enemy.Type then
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i
				local class = A.Unit(arena):Class()
				if not A.Unit(arena):IsDead() and (class == "ROGUE" or class == "DRUID") then 
					return true, arena 
				end 
			end 
		end 
		 
		return value, "none"
	end, "ROLE"), 
	IsTauntPetAble 							= Cache:Wrap(function(self, object, range)
		-- @return boolean, unitID
		-- object is always Action table key 
		local value, pet = false, "none"
		if TeamCache.Enemy.Type and TeamCache.Enemy.Size > 0 then 
			for i = 1, 10 do 
				pet = TeamCache.Enemy.Type .. "pet" .. i
				if A.Unit(pet):IsExists() and ((not range and object:IsInRange(pet)) or (range and A.Unit(pet):CanInterract(range))) then 
					return true, pet  
				end              
			end  
		end
		
		return value, pet 
	end, "ROLE"),
	IsCastingBreakAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i
				local _, castRemain, _, _, castName = A.Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= (offset or 0.5) then 
					for i = 1, #AuraList.Premonition do 
						if A.GetSpellInfo(AuraList.Premonition[i][1]) == castName and A.Unit(arena):GetRange() <= AuraList.Premonition[i][2] then 
							return true, arena
						end
					end
				end
			end
		end 
 
		return value, arena
	end, "ROLE"),
	IsReshiftAble 							= Cache:Wrap(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i
				local _, castRemain, _, _, castName = A.Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= A.GetCurrentGCD() + A.GetGCD() + (offset or 0.05) then 
					for i = 1, #AuraList.Reshift do 
						if A.GetSpellInfo(AuraList.Reshift[i][1]) == castName and A.Unit(arena):GetRange() <= AuraList.Reshift[i][2] and not A.Unit("player"):IsFocused(nil, nil, 10, true) then 
							return true, arena
						end
					end
				end
			end
		end 
		
		return value, arena 
	end, "ROLE"), 
	IsPremonitionAble 						= Cache:Wrap(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
		if TeamCache.Enemy.Type then 
			for i = 1, TeamCache.Enemy.Size do 
				arena = TeamCache.Enemy.Type .. i
				local _, castRemain, _, _, castName = A.Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= A.GetGCD() + (offset + 0.05) then 
					for i = 1, #AuraList.Premonition do 
						if A.GetSpellInfo(AuraList.Premonition[i][1]) == castName and A.Unit(arena):GetRange() <= AuraList.Premonition[i][2] then 
							return true, arena
						end
					end
				end
			end
		end 
			
		return value, arena
	end, "ROLE"),
})

function A.EnemyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.05          
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
A.Listener:Add("ACTION_EVENT_UNIT", "COMBAT_LOG_EVENT_UNFILTERED", 			function(...)
	local _, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo() 
	if EVENT == "UNIT_DIED" or EVENT == "UNIT_DESTROYED" then 
		Info.CacheMoveIn[DestGUID] 		= nil 
		Info.CacheMoveOut[DestGUID] 	= nil 
		Info.CacheMoving[DestGUID]		= nil 
		Info.CacheStaying[DestGUID]		= nil 
		Info.CacheInterrupt[DestGUID]	= nil 
	end 
end)

A.Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(Info.CacheMoveIn)
		wipe(Info.CacheMoveOut)
		wipe(Info.CacheMoving)
		wipe(Info.CacheStaying)
		wipe(Info.CacheInterrupt)
	end 
end)

A.Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	if CombatTracker:GetSpellLastCast("player", A.LastPlayerCastID)  > 0.5 and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(Info.CacheMoveIn)
		wipe(Info.CacheMoveOut)
		wipe(Info.CacheMoving)
		wipe(Info.CacheStaying)	
		wipe(Info.CacheInterrupt)
	end 
end)