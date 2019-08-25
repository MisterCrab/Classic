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
--local Azerite 					= LibStub("AzeriteTraits")
--local Pet							= LibStub("PetLibrary")
local LibRangeCheck  				= LibStub("LibRangeCheck-2.0")

local _G, setmetatable, table, unpack, select, next, type, pairs, wipe, tostringall =
	  _G, setmetatable, table, unpack, select, next, type, pairs, wipe, tostringall
	  
local CombatLogGetCurrentEventInfo	= _G.CombatLogGetCurrentEventInfo	  
local GetUnitSpeed					= _G.GetUnitSpeed
local UnitIsUnit, UnitInRaid, UnitInParty, UnitInRange, UnitInVehicle, UnitIsQuestBoss, UnitEffectiveLevel, UnitLevel, UnitThreatSituation, UnitRace, UnitClass, UnitGroupRolesAssigned, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCastingInfo, UnitChannelInfo, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGUID =
	  UnitIsUnit, UnitInRaid, UnitInParty, UnitInRange, UnitInVehicle, UnitIsQuestBoss, UnitEffectiveLevel, UnitLevel, UnitThreatSituation, UnitRace, UnitClass, UnitGroupRolesAssigned, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCastingInfo, UnitChannelInfo, UnitCreatureType, UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGUID

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
			this.bufer[func] = setmetatable({}, { __mode == "kv" })
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
        118, -- Polymorph
        605, -- Mind Control                
        9484, -- Shackle Undead
        2637, -- Hibernate
        20066, -- Repentance          
        5782, -- Fear
        3355, -- Freezing Trap
        209790, -- Freezing Arrow (hunter pvp)        
        6358, -- Seduction
        82691, -- Ring of Frost                          
        198909, -- Song of Chi-ji (mistweaver monk talent)
        5484, -- Howl of Terror
        6789, -- Mortal Coil
        87204, -- Sin and Punishment
        8122, -- Psychic Scream
        31661, -- Dragon's Breath
        105421, -- Bliding light (paladin talent)
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        15487, -- Silence        
        31935, -- Avenger's Shield
        199683, -- Last Word
        47476, -- Strangulate
        31117, -- Unstable Affliction
        853, -- Hammer of Justice
        64044, -- Psychic Horror
        30283, -- Shadowfury
        117526, -- Binding Shot
        118905, -- Static Charge
        179057, -- Chaos Nova
        205630, -- Illidan's Grasp (demon hunter)
        226943, -- Mind Bomb
        209749, -- Faerie Swarm (Moonkin Disarm) 
        204399, -- Earthfury (enhancement shaman pvp talent)
        217832, -- Imprison
        286349, -- Gladiator's Maledict		
		22703, -- Summon Infernal
		200166, -- Metamorphosis
		208618, -- Illidan's Grasp (secondary effect)
		211881, -- Fel Eruption
		200200, -- Holy word: Chastise (stunned)
		--200196, -- Holy word: Chastise (incapacitated)
    },
    MagicRooted = {
        233395, -- Frozen Center (DK PvP Frost)    
        339, -- Entangling Roots
        122, -- Frost Nova
        102359, -- Mass Entanglement
        96294, -- Chains of Ice
        183218, -- Retri's -70%
    }, 
    Curse = {
        51514, -- Hex   
        -- Warlock BFA
        12889, -- Curse of Tongues
        17227, -- Curse of Weakness
        199954, -- Curse of Fragility
    },
    Disease = {
        196782, -- Outbreak (5 sec infecting dot)
        191587, -- Outbreak (21+ sec dot)
        58180, -- Infected Wounds (Feral slow)
        -- [Blood Plague] 
        -- [Frost Fever]
    },
    Poison = {
        19386, -- Wyvern Sting
        202933, -- Spider Sting   
        202797, -- Viper Sting
        202900, -- Scorpid Sting
    },
    Physical = {
        115078, -- Paralysis
        6770, -- Sap
        107079, -- Quaking Palm
        207685, -- Sigil of Misery (Havoc Demon hunter)
        5246, -- Intimidating Shout
        99, -- Incapacitating Roar
        1776, -- Gouge
        2094, -- Blind
        186387, -- Bursting Shot (hunter marks ability)
        213691, -- Scatter Shot (hunter pvp talent)
        --25, -- Stun
        1833, -- Cheap Shot
        408, -- Kidney Shot
        5211, -- Mighty Bash
        24394, -- Intimidation
        89766, -- Axe Toss
        108194, -- Asphyxiate (DK)        
        118345, -- Pulverize
        119381, -- Leg Sweep        
        163505, -- Rake
        199804, -- Between the Eyes
        203123, -- Maim
        236025, -- Enraged Maim
        204399, -- Earthfury (enhancement shaman pvp talent)           
        47481, -- Gnaw (DK pet)
        212332, -- Smash (DK transformation pet)
        -- 207167, -- Blinding Sleet (is it physical ? )
        207777, -- Dismantle
        236077, -- Disarm        
        233759, -- Grapple Weapon
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
		-- Warrior 
		132168, -- Shockwave
        132169, -- Storm Bolt
		--237744, -- Warbringer       
		-- Tauren
		--20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    -- CC CONTROL TYPE
    CrowdControl = {
        -- Deprecated
		118, -- Hibernate
    },
    Incapacitated = {
		-- Druid
        99, -- Incapacitating Roar
		203126, -- Maim (Feral PvP talent)
		-- Hunter 
		213691, -- Scatter Shot 
        3355, -- Freezing Trap
        209790, -- Freezing Arrow
		19386, -- Wyvern Sting
		-- Mage 
        118, -- Polymorph  
		82691, -- Ring of Frost	
		-- Monk 
        115078, -- Paralysis
		-- Paladin 
        20066, -- Repentance
		-- Priest 
        200196, -- Holy Word: Chastise (Holy)
		--605, -- Dominate Mind (Mind Control) this is buff type 
		9484, -- Shackle Undead
		-- Rogue 
        6770, -- Sap
		1776, -- Gouge		
		-- Shaman		
        51514, -- Hex (also 211004, 210873, 211015, 211010)   
		-- Warlock 
		710, -- Banish
		6789, -- Mortal Coil        
        -- Pandaren
        107079, -- Quaking Palm
		-- Demon Hunter 
		217832, -- Imprison
		--221527, -- Improve Imprison
    },
    Disoriented = {
		-- Death Knight
		207167, -- Blinding Sleet (Frost) 
		-- Demon Hunter
		207685, -- Sigil of Misery (Havoc)
		115268, -- Mesmerize
		-- Druid 
		--33786, -- Cyclone 
		--209753, -- Cyclone (Balance)		
		-- Hunter
		--224729, -- Bursting Shot		
		186387, -- Bursting Shot (MM)
		-- Mage 
		31661, -- Dragon's Breath (Fire)
		-- Monk 
		202274, -- Incendiary brew (BW)
		198909, -- Song of Chi-ji (MW)
        -- Paladin 
        105421, -- Bliding light (Holy)
		-- Priest
		8122, -- Psychic Scream
		226943, -- Mind Bomb
		-- Rogue 
        2094, -- Blind		
		-- Warlock
		5782, -- Fear 
		--118699, -- Fear 
		--130616, -- Fear 
		5484, -- Howl of Terror 
		115268, -- Mesmerize (Shivarra)
		6358, -- Seduction (Succubus)
		-- Warrior
		5246, -- Intimidating Shout
    },    
    Fear = {
        5782, -- Fear
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        8122, -- Psychic Scream
        87204, -- Sin and Punishment
        207685, -- Sigil of Misery (Havoc Demon hunter)
    },
    Charmed = {
		-- Deprecated
        605, -- Mind Control                  
        9484, -- Shackle Undead
    },
    Sleep = {
        2637, -- Hibernate
    },
    Stuned = {
		-- Death Knight 
        47481, -- Gnaw (pet)
        212332, -- Smash (transformation pet)
        108194, -- Asphyxiate
		207171, -- Winter is Coming (Remorseless winter stun)
		-- Demon Hunter 
		179057, -- Chaos Nova
		200166, -- Metamorphosis
		205630, -- Illidan's Grasp (primary effect)
		208618, -- Illidan's Grasp (secondary effect)
		211881, -- Fel Eruption
		-- Druid 
		203123, -- Maim
        5211, -- Mighty Bash 
		163505, -- Rake
		--2637, -- Hibernate --FIXME: Not sure if Human race can avert it as stunned effect but it has stun DR 
		--236025, -- Enraged Maim --FIXME: same 
		-- Hunter 
        117526, -- Binding Shot
        19577, -- Intimidation (pet)
		-- Monk 		
        119381, -- Leg Sweep
		-- Paladin 
		853, -- Hammer of Justice
		-- Priest 
		200200, -- Holy word: Chastise
		64044, -- Psychic Horror
		-- Rogue 
		1833, -- Cheap Shot 
        408, -- Kidney Shot 
        199804, -- Between the Eyes
		-- Shaman
		118345, -- Pulverize (Primal Earth Elemental)
		118905, -- Static Charge (Capacitor Totem)
		-- Warlock 
        30283, -- Shadowfury
        89766, -- Axe Toss (pet)
		22703, -- Summon Infernal
		-- Warrior 
        132168, -- Shockwave 
        132169, -- Storm Bolt
		237744, -- Warbringer       
		-- Tauren
		20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    PhysStuned = {
		-- Death Knight 
		47481, -- Gnaw (pet)
        212332, -- Smash (transformation pet)
        108194, -- Asphyxiate
		-- Druid 
        203123, -- Maim
        5211, -- Mighty Bash 
		163505, -- Rake
		-- Hunter 
		117526, -- Binding Shot
        19577, -- Intimidation (pet)
		-- Monk
        119381, -- Leg Sweep
        -- Rogue 
        1833, -- Cheap Shot 
        408, -- Kidney Shot 
        199804, -- Between the Eyes 
		-- Shaman
		118345, -- Pulverize (Primal Earth Elemental)
        -- Warlock 
		89766, -- Axe Toss (pet)
        -- Druid 
		203123, -- Maim
        5211, -- Mighty Bash 
		163505, -- Rake
		--236025, -- Enraged Maim --FIXME: it's desorient but DR trigger it as stun 
		-- Warrior 
        132168, -- Shockwave 
        132169, -- Storm Bolt
		237744, -- Warbringer       
		-- Tauren
		20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    Silenced = {
		-- Death Knight 
		47476, -- Strangulate (Unholy/Blood)
		-- Demon Hunter 
        204490, -- Sigil of Silence (Havoc)
		-- Druid 
        78675, -- Solar Beam (Balance)
		-- Hunter 
        202933, -- Spider Sting
		-- Paladin 
        31935, -- Avenger's Shield	(Prot)	
		-- Priest 
        15487, -- Silence (Shadow)    
		199683, -- Last Word (Holy)
		-- Rogue 		
        1330, -- Garrote - Silence				
        -- Warlock         
        31117, -- Unstable Affliction		
    },
    Disarmed = {
		-- Rogue 
        207777, -- Dismantle
		-- Warrior 
        236077, -- Disarm  
		-- Monk 		
        233759, -- Grapple Weapon
		-- Druid 
        209749, -- Faerie Swarm
    }, 
    Rooted = {
        339, -- Entangling Roots Dispel able 
        235963, -- Entangling Roots NO Dispel able
        122, -- Frost Nova
        33395, -- Freeze (frost mage water elemental)
        45334, -- Immobilized (wild charge, bear form)
        53148, -- Charge        
        64695, -- Earthgrab
        91807, -- Shambling Rush (DK pet)
        102359, -- Mass Entanglement
        105771, -- Charge
        116706, -- Disable
        157997, -- Ice Nova (frost mage talent)    
        190927, -- harpoon (survival hunter)
        199042, -- Thunderstruck (Warrior PVP)
        -- 200108, -- Ranger's Net (Hunter talent) (REMOVED)
        201158, -- Super Sticky Tar (Expert Trapper, Hunter talent, Tar Trap effect)
        204085, -- Deathchill (DK PVP)
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
        228600, -- glacial spike (frost mage talent) 
        233395, -- Frozen Center (DK PvP Frost)  
        183218, -- Retri's -70%
    },  
    Slowed = {
        116, -- Frostbolt
        120, -- Cone of Cold
        2120, -- Flamestrike
        6343, -- Thunder Clap
        1715, -- Hamstring
        3409, -- Crippling Poison
        3600, -- Earthbind
        5116, -- Concussive Shot
        12544, -- Frost Armor
        7992, -- Slowing Poison
        26679, -- Deadly Throw
        35346, -- Warp Time
        44614, -- Flurry
        45524, -- Chains of Ice
        50259, -- Dazed (Wild Charge, druid talent, cat form)
        50433, -- Ankle Crack
        51490, -- Thunderstorm
        61391, -- Typhoon
        12323, -- Piercing Howl
        13810, -- Ice Trap
        15407, -- Mind Flay
        31589, -- Slow
        58180, -- Infected Wounds
        102793, -- Ursol's Vortex
        116095, -- Disable
        121253, -- Keg Smash
        123586, -- Flying Serpent Kick
        135299, -- Tar Trap
        147732, -- Frostbrand Attack
        157981, -- Blast Wave
        160065, -- Tendon Rip
        160067, -- Web Spray
        169733, -- Brutal Bash
        183218, -- Hand of Hindrance
        185763, -- Pistol Shot
        190780, -- Frost Breath (dk frost artifact ability)
        191397, -- Bestial Cunning
        194279, -- Caltrops
        194858, -- Dragonsfire Grenade
        195645, -- Wing Clip
        196840, -- Frost Shock
        198813, -- Vengeful Retreat
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205021, -- Ray of Frost (frost mage talent)
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206755, -- Ranger's Net
        206760, -- Night Terrors
        206930, -- Heart Strike
        208278, -- Debilitating Infestation (DK unholy talent)
        209786, -- Goremaw's Bite
        211793, -- Remorseless Winter
        211831, -- Abomination's Might
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        222775, -- Strike from the Shadows
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
        248744, -- Shiv
        198145, -- System Shock
    },
    MagicSlowed = {
        116, -- Frostbolt
        120, -- Cone of Cold       
        3600, -- Earthbind
        12544, -- Frost Armor
        44614, -- Flurry
        61391, -- Typhoon
        123586, -- Flying Serpent Kick
        147732, -- Frostbrand Attack
        183218, -- Hand of Hindrance
        190780, -- Frost Breath (dk frost artifact ability)
        196840, -- Frost Shock
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206760, -- Night Terrors
        209786, -- Goremaw's Bite
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
    },
    BreakAble = {
        118, -- Polymorph
        6770, -- Sap 
        20066, -- Repentance
        51514, -- Hex
        2637, -- Hibernate
        5782, -- Fear
        3355, -- Freezing Trap
        209790, -- Freezing Arrow
        6358, -- Seduction
        2094, -- Blind
        19386, -- Wyvern Sting
        82691, -- Ring of Frost
        115078, -- Paralysis        
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        --6789, -- Mortal Coil
        8122, -- Psychic Scream
        99, -- Incapacitating Roar
        1776, -- Gouge
        31661, -- Dragon's Breath
        105421, -- Blinding Light
        186387, -- Bursting Shot
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        207167, -- Blinding Sleet
        213691, -- Scatter Shot        
        217832, -- Imprison
        236025, -- Enraged Maim
        207685, -- Sigil of Misery (Havoc Demon hunter)
        226943, -- Mind Bomb
        -- Rooted CC
        339, -- Entagle Roots
        212638, -- tracker's net (hunter PvP )
        102359, -- Mass Entanglement
        122, -- Frost Nova
        233395, -- Frozen Center (DK PvP Frost)
        107079, -- Quaking Palm
    },
    -- Imun Specific Buffs 
    FearImun = {
        212704, -- The Beast Within (Hunter BM PvP)
        287081, -- Lichborne
        8143, -- Tremor Totem 
    },
    StunImun = {
        48792, -- Icebound Fortitude
        6615, -- Free Action (Human)
        1953, -- Blink (micro buff)
        287081, -- Lichborne
    },        
    Freedom = {
        1044, -- Blessing of Freedom
        48265, -- Death's Advance
        287081, -- Lichborne
        212552, -- Wraith Walk
        227847, -- Bladestorm
        53271, -- Master's Call    
        116841, -- Tiger's Lust
        216113, -- Way of the Crane (Monk TT PvP)
    },
    TotalImun = {
        642, -- Divine Shield
        45438, -- Ice Block
        186265, -- Aspect of Turtle     
        215769, -- Spirit of Redemption
    },
    DamagePhysImun = {
        1022, -- Blessing of Protection
        188499, -- Blade Dance 
        196555, -- Netherwalk
    },    
    DamageMagicImun = {    -- When we can't totally damage    
        31224, -- Cloak of Shadows
        -- 710, -- Banish (can skip not often usable)
        204018, -- Blessing of Spellwarding    
        196555, -- Netherwalk
    }, 
    CCTotalImun = {
        213610, -- Holy Ward
        227847, -- Bladestorm    
    },     
    CCMagicImun = {
        31224, -- Cloak of Shadows
        204018, -- Blessing of Spellwarding    
        48707, -- Anti-Magic Shell    
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    }, 
    Reflect = {            -- Only to cancel reflect effect  
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    }, 
    KickImun = { -- Imun Silence too
        209584, -- Zen Focus Tea (Monk TT PvP)
        221703, -- Casting Circle (Warlock PvP)
        196762, -- Inner Focus
        289657, -- Holy Word: Concentration (Holy Priest PvP)
    },
    -- Purje 
    ImportantPurje = {
        1022, -- Blessing of Protection
        79206, -- Spiritwalker's Grace
        190319, -- Combustion 
        10060, -- Power Infusion
        12042, -- Arcane Power 
        12472, -- Icy Veins
        213610, -- Holy Ward
        198111, -- Temporal Shield
        210294, -- Divine Favor 
        212295, -- Nether Ward
        271466, -- Luminous Barrier
    },
    SecondPurje = {
        1044, -- Blessing of Freedom        
        -- We need purje druid only in bear form 
        33763, -- Lifebloom
        774, -- Rejuvenation
        155777, -- Rejuvenation (Germination)
        48438, -- Wild Growth    
        8936, -- Regrow 
        289318, -- Mark of the Wild
    },
    PvEPurje = {
        197797, 210662, 211632, 209033, 198745, 194615, 282098,
    },
    -- Speed 
    Speed = {
        2983, -- Sprint
        2379, -- Speed
        2645, -- Ghost Wolf
        7840, -- Swim Speed
        36554, -- Shadowstep
        54861, -- Nitro Boosts
        58875, -- Spirit Walk
        65081, -- Body and Soul
        68992, -- Darkflight
        85499, -- Speed of Light
        87023, -- Cauterize
        61684, -- Dash
        77761, -- Stampeding Roar
        108843, -- Blazing Speed
        111400, -- Burning Rush
        116841, -- Tiger's Lust
        118922, -- Posthaste
        119085, -- Chi Torpedo
        121557, -- Angelic Feather
        137452, -- Displacer Beast
        137573, -- Burst of Speed
        192082, -- Wind Rush (shaman wind rush totem talent)
        196674, -- Planewalker (warlock artifact trait)
        197023, -- Cut to the chase (rogue pvp talent)
        199407, -- Light on your feet (mistweaver monk artifact trait)
        201233, -- whirling kicks (windwalaker monk pvp talent)
        201447, -- Ride the wind (windwalaker monk pvp talent)
        209754, -- Boarding Party (rogue pvp talent)
        210980, -- Focus in the light (holy priest artifact trait)
        213177, -- swift as a coursing river (brewmaster artifact trait)
        214121, -- Body and Mind (priest talent)
        215572, -- Frothing Berserker (warrior talent)
        231390, -- Trailblazer (hunter talent)
        186257, -- Aspect of the Cheetah
        204475, -- Windburst (marks hunter artifact ability)        
    },
    -- Deff 
    DeffBuffsMagic = {
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender 
        871, -- Shield Wall
        118038, -- Die by the Sword 
        104773, -- Unending Resolve        
        108271, -- Astral Shift
        6940, -- Blessing of Sacrifice
        31224, -- Cloak of Shadows
        48707, -- Anti-Magic Shell    
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        122278, -- Dampen Harm 
        61336, -- Survival Instincts
        45182, -- Cheating Death
        204018, -- Blessing of Spellwarding
        196555, -- Netherwalk
        206803, -- Rain from Above
    }, 
    DeffBuffs = {        
        76577, -- Smoke Bomb
        53480, -- Road of Sacriface
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender        
        871, -- Shield Wall
        118038, -- Die by the Sword        
        104773, -- Unending Resolve
        6940, -- Blessing of Sacrifice
        108271, -- Astral Shift
        5277, -- Evasion
        102342, -- Ironbark
        -- 1022, -- Blessing of Protection
        74001, -- Combat Readiness
        -- 31224, -- Cloak of Shadows
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        -- 48792, -- Icebound Fortitude
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        -- 498, -- Divine Protection
        -- 157913, -- Evanesce
        115203, -- Fortifying Brew
        22812, -- Barkskin
        122278, -- Dampen Harm        
        61336, -- Survival Instincts
        45182, -- Cheating Death
        198589, -- Blur    
        196555, -- Netherwalk
        243435, -- Fortifying Brew
        206803, -- Rain from Above
    },    
    -- Damage buffs / debuffs
    Rage = {
        18499, -- Berserker Rage
        184361, -- Enrage
    }, 
    DamageBuffs = {        
        51690, -- Killing Spree
        -- 79140, -- Vendetta (debuff)
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        19574, -- Bestial Wrath
        -- 193530, -- Aspect of the Wild (small burst)
        266779, -- Coordinated Assault
        193526, -- Trueshot
        -- 5217, -- Tiger's Fury (small burst)
        106951, -- Berserk 
        102560, -- Incarnation: Chosen of Elune
        102543, -- Incarnation: King of the Jungle
        190319, -- Combustion 
        12042, -- Arcane Power                
        12472, -- Icy Veins
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy 
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar        
        114050, -- Ascendance
        113858, -- Dark Soul: Instability
        267217, -- Nether Portal
        113860, -- Dark Soul: Misery
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    DamageBuffs_Melee = {        
        51690, -- Killing Spree
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        266779, -- Coordinated Assault
        106951, -- Berserk 
        102543, -- Incarnation: King of the Jungle
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy 
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar        
        114050, -- Ascendance
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    BurstHaste = {
        90355, -- Ancient Hysteria
        146555, -- Drums of Rage
        178207, -- Drums of Fury
        230935, -- Drums of the Mountain
        2825, -- Bloodlust
        80353, -- Time Warp
        160452, -- Netherwinds
        32182, -- Heroism
    },
    -- SOME SPECIAL
    DamageDeBuffs = {
        79140, -- Vendetta (debuff)
        115080, -- Touhc of Death (debuff)
        122470, -- KARMA
    }, 
    Flags = {
        156621, -- Alliance flag
        23333,  -- Horde flag 
        34976,  -- Netherstorm Flag
        121164, -- Orb of Power
    }, 
    -- Cast Bars
    Reshift = {
        {118, 45}, -- Polymorph (45 coz of blink available)
        {20066, 30}, -- Repentance 
        {51514, 30}, -- Hex 
        {19386, 40}, -- Wyvern Sting
    },
    Premonition = {
        {113724, 30}, -- Ring of Frost 
        {118, 45}, -- Polymorph (45 coz of blink available while cast)
        {20066, 30}, -- Repentance 
        {51514, 30}, -- Hex 
        {19386, 40}, -- Wyvern Sting
        {5782, 30}, -- Fear 
    },
    CastBarsCC = {
        113724, -- Ring of Frost
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control   
    },
    AllPvPKickCasts = {    
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control 
        982, -- Revive Pet 
        32375, -- Mass Dispel 
        203286, -- Greatest Pyroblast
        116858, -- Chaos Bolt 
        20484, -- Rebirth
        203155, -- Sniper Shot 
        47540, -- Penance
        596, -- Prayer of Healing
        2060, -- Heal
        2061, -- Flash Heal
        32546, -- Binding Heal                        (priest, holy)
        33076, -- Prayer of Mending
        64843, -- Divine Hymn
        120517, -- Halo                                (priest, holy/disc)
        186263, -- Shadow Mend
        194509, -- Power Word: Radiance
        265202, -- Holy Word: Salvation                (priest, holy)
        289666, -- Greater Heal                        (priest, holy)
        740, -- Tranquility
        8936, -- Regrowth
        48438, -- Wild Growth
        289022, -- Nourish                             (druid, restoration)
        1064, -- Chain Heal
        8004, -- Healing Surge
        73920, -- Healing Rain
        77472, -- Healing Wave
        197995, -- Wellspring                          (shaman, restoration)
        207778, -- Downpour                            (shaman, restoration)
        19750, -- Flash of Light
        82326, -- Holy Light
        116670, -- Vivify
        124682, -- Enveloping Mist
        191837, -- Essence Font
        209525, -- Soothing Mist
        227344, -- Surging Mist                        (monk, mistweaver)
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
	CacheMoveIn					= setmetatable({}, { __mode == "kv" }),
	CacheMoveOut				= setmetatable({}, { __mode == "kv" }),
	CacheMoving 				= setmetatable({}, { __mode == "kv" }),
	CacheStaying				= setmetatable({}, { __mode == "kv" }),
	CacheInterrupt 				= setmetatable({}, { __mode == "kv" }),
	SpecIs 						= {
        ["MELEE"] 				= {251, 252, 577, 103, 255, 269, 70, 259, 260, 261, 263, 71, 72, 250, 581, 104, 268, 66, 73},
        ["RANGE"] 				= {102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
        ["HEALER"] 				= {105, 270, 65, 256, 257, 264},
        ["TANK"] 				= {250, 581, 104, 268, 66, 73},
        ["DAMAGER"] 			= {251, 252, 577, 103, 255, 269, 70, 259, 260, 261, 263, 71, 72, 102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
    },
	ClassIsMelee = {
        ["WARRIOR"] 			= true,
        ["PALADIN"] 			= true,
        ["HUNTER"] 				= false,
        ["ROGUE"] 				= true,
        ["PRIEST"] 				= false,
        ["DEATHKNIGHT"] 		= true,
        ["SHAMAN"] 				= false,
        ["MAGE"] 				= false,
        ["WARLOCK"] 			= false,
        ["MONK"] 				= true,
        ["DRUID"] 				= false,
        ["DEMONHUNTER"] 		= true,
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
		[31146] = true, -- Raider's Training Dummy
		[31144] = true, -- Training Dummy
		[32666] = true, -- Training Dummy
		[32667] = true, -- Training Dummy
		[46647] = true, -- Training Dummy
		-- MoP Shrine of Two Moons
		[67127] = true, -- Training Dummy
		-- WoD Alliance Garrison
		[87317] = true, -- Mage Tower Damage Training Dummy
		[87318] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
		[87320] = true, -- Mage Tower Damage Raider's Training Dummy
		[88314] = true, -- Tanking Dungeoneer's Training Dummy
		[88316] = true, -- Healing Training Dummy ----> FRIENDLY
		-- WoD Horde Garrison
		[87760] = true, -- Mage Tower Damage Training Dummy
		[87761] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
		[87762] = true, -- Mage Tower Damage Raider's Training Dummy
		[88288] = true, -- Tanking Dungeoneer's Training Dummy
		[88289] = true, -- Healing Training Dummy ----> FRIENDLY
		-- Legion Rogue Class Order Hall
		[92164] = true, -- Training Dummy
		[92165] = true, -- Dungeoneer's Training Dummy
		[92166] = true, -- Raider's Training Dummy
		-- Legion Priest Class Order Hall
		[107555] = true, -- Bound void Wraith
		[107556] = true, -- Bound void Walker
		-- Legion Druid Class Order Hall
		[113964] = true, -- Raider's Training Dummy
		[113966] = true, -- Dungeoneer's Training Dummy
		-- Legion Warlock Class Order Hall
		[102052] = true, -- Rebellious imp
		[102048] = true, -- Rebellious Felguard
		[102045] = true, -- Rebellious WrathGuard
		[101956] = true, -- Rebellious Fel Lord
		-- Legion Mage Class Order Hall
		[103397] = true, -- Greater Bullwark Construct
		[103404] = true, -- Bullwark Construct
		[103402] = true, -- Lesser Bullwark Construct
		-- BfA Dazar'Alor
		[144081] = true, -- Training Dummy
		[144082] = true, -- Training Dummy
		[144085] = true, -- Training Dummy
		[144086] = true, -- Raider's Training Dummy		
		-- Misc/Unknown
		[79987]  = true, -- Location Unknown
		[92169]  = true, -- Tanking (Eastern Plaguelands)
		[96442]  = true, -- Damage (Location Unknown)
		[109595] = true, -- Location Unknown
		[113963] = true, -- Damage (Location Unknown)
		[131985] = true, -- Damage (Zuldazar)
		[131990] = true, -- Tanking (Zuldazar)
		[132976] = true, -- Morale Booster (Zuldazar)
		-- Level 1 
		[17578]  = true, -- Lvl 1 (The Shattered Halls)
		[60197]  = true, -- Lvl 1 (Scarlet Monastery)
		[64446]  = true, -- Lvl 1 (Scarlet Monastery)
		[144077] = true, -- Lvl 1 (Dazar'alor) - Morale Booster
		-- Level 3
		[44171]  = true, -- Lvl 3 (New Tinkertown, Dun Morogh)
		[44389]  = true, -- Lvl 3 (Coldridge Valley)
		[44848]  = true, -- Lvl 3 (Camp Narache, Mulgore)
		[44548]  = true, -- Lvl 3 (Elwynn Forest)
		[44614]  = true, -- Lvl 3 (Teldrassil, Shadowglen)
		[44703]  = true, -- Lvl 3 (Ammen Vale)
		[44794]  = true, -- Lvl 3 (Dethknell, Tirisfal Glades)
		[44820]  = true, -- Lvl 3 (Valley of Trials, Durotar)
		[44937]  = true, -- Lvl 3 (Eversong Woods, Sunstrider Isle)
		[48304]  = true, -- Lvl 3 (Kezan)
		-- Level 55
		[32541]  = true, -- Lvl 55 (Plaguelands: The Scarlet Enclave)
		[32545]  = true, -- Lvl 55 (Eastern Plaguelands)
		-- Level 65
		[32542]  = true, -- Lvl 65 (Eastern Plaguelands)
		-- Level 75
		[32543]  = true, -- Lvl 75 (Eastern Plaguelands)
		-- Level 80
		[32546]  = true, -- Lvl 80 (Eastern Plaguelands)
		-- Level 95
		[79414]  = true, -- Lvl 95 (Broken Shore, Talador)
		-- Level 100
		[87321]  = true, -- Lvl 100 (Stormshield) - Healing
		[88835]  = true, -- Lvl 100 (Warspear) - Healing
		[88906]  = true, -- Lvl 100 (Nagrand)
		[88967]  = true, -- Lvl 100 (Lunarfall, Frostwall)
		[89078]  = true, -- Lvl 100 (Frostwall, Lunarfall)
		-- Levl 100 - 110
		[92167]  = true, -- Lvl 100 - 110 (The Maelstrom, Eastern Plaguelands, The Wandering Isle)
		[92168]  = true, -- Lvl 100 - 110 (The Wandering Isles, Easter Plaguelands)
		[100440] = true, -- Lvl 100 - 110 (The Wandering Isles)
		[100441] = true, -- Lvl 100 - 110 (The Wandering Isles)
		[107483] = true, -- Lvl 100 - 110 (Skyhold)
		[107557] = true, -- Lvl 100 - 110 (Netherlight Temple) - Healing
		[108420] = true, -- Lvl 100 - 110 (Stormwind City, Durotar)
		[111824] = true, -- Lvl 100 - 110 (Azsuna)
		[113674] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss) - Dungeoneer
		[113676] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss)
		[113687] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss) - Swarm
		[113858] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113859] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113862] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113863] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113871] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113967] = true, -- Lvl 100 - 110 (The Dreamgrove) - Healing
		[114832] = true, -- Lvl 100 - 110 (Stormwind City)
		[114840] = true, -- Lvl 100 - 110 (Orgrimmar)
		-- Level 102
		[87322]  = true, -- Lvl 102 (Stormshield) - Tank
		[88836]  = true, -- Lvl 102 (Warspear) - Tank
		[93828]  = true, -- Lvl 102 (Hellfire Citadel)
		[97668]  = true, -- Lvl 102 (Highmountain)
		[98581]  = true, -- Lvl 102 (Highmountain)
		-- Level 110 - 120
		[126781] = true, -- Lvl 110 - 120 (Boralus) - Damage
		[131989] = true, -- Lvl 110 - 120 (Boralus) - Damage
		[131994] = true, -- Lvl 110 - 120 (Boralus) - Healing
		[153285] = true, -- Lvl 110 - 120 (Ogrimmar) - Damage
		[153292] = true, -- Lvl 110 - 120 (Stormwind) - Damage
		-- Level 111 - 120
		[131997] = true, -- Lvl 111 - 120 (Boralus, Zuldazar) - PVP Damage
		[131998] = true, -- Lvl 111 - 120 (Boralus, Zuldazar) - PVP Healing
		-- Level 112 - 120
		[144074] = true, -- Lvl 112 - 120 (Dazar'alor) - PVP Healing
		-- Level 112 - 122
		[131992] = true, -- Lvl 112 - 122 (Boralus) - Tanking
		-- Level 113 - 120 
		[132036] = true, -- Lvl 113 - 120 (Boralus) - Healing
		-- Level 113 - 122
		[144078] = true, -- Lvl 113 - 122 (Dazar'alor) - Tanking
		-- Level 114 - 120
		[144075] = true, -- Lvl 114 - 120 (Dazar'alor) - Healing
		-- Level ??
		[24792]  = true, -- Lvl ?? Boss (Location Unknown)
		[30527]  = true, -- Lvl ?? Boss (Location Unknown)
		[87329]  = true, -- Lvl ?? (Stormshield) - Tank
		[88837]  = true, -- Lvl ?? (Warspear) - Tank
		[107202] = true, -- Lvl ?? (Broken Shore) - Raider
		[107484] = true, -- Lvl ?? (Skyhold)
		[113636] = true, -- Lvl ?? (Mardum, the Shattered Abyss) - Raider
		[113860] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[113864] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[70245]  = true, -- Lvl ?? (Throne of Thunder)
		[131983] = true, -- Lvl ?? (Boralus) - Damage	
	},
	IsDummyPvP 					= {
		-- City (SW, Orgri, ...)
		[114840] = true, -- Raider's Training Dummy
		[114832] = true,
		[131997] = true,
	},
	IsBoss 						= {
		-- City (SW, Orgri, ...)
		[31146] = true, -- Raider's Training Dummy
		-- WoD Alliance Garrison
		[87320] = true, -- Mage Tower Damage Raider's Training Dummy
		[88314] = true, -- Tanking Dungeoneer's Training Dummy
		[88316] = true, -- Healing Training Dummy ----> FRIENDLY
		-- WoD Horde Garrison
		[87762] = true, -- Mage Tower Damage Raider's Training Dummy
		[88288] = true, -- Tanking Dungeoneer's Training Dummy
		[88289] = true, -- Healing Training Dummy ----> FRIENDLY
		-- Legion Druid Class Order Hall
		[113964] = true, -- Raider's Training Dummy
		-- Legion Rogue Class Order Hall
		[92166] = true, -- Raider's Training Dummy
		-- BfA Dazar'Alor
		[144086] = true, -- Raider's Training Dummy	
		-- Level ??
		[24792]  = true, -- Lvl ?? Boss (Location Unknown)
		[30527]  = true, -- Lvl ?? Boss (Location Unknown)
		[87329]  = true, -- Lvl ?? (Stormshield) - Tank
		[88837]  = true, -- Lvl ?? (Warspear) - Tank
		[107202] = true, -- Lvl ?? (Broken Shore) - Raider
		[107484] = true, -- Lvl ?? (Skyhold)
		[113636] = true, -- Lvl ?? (Mardum, the Shattered Abyss) - Raider
		[113860] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[113864] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[70245]  = true, -- Lvl ?? (Throne of Thunder)
		[131983] = true, -- Lvl ?? (Boralus) - Damage
	},
	IsNotBoss 					= {
		-- BfA 
		-- Shadow of Zul
		[138489] = true,
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
		[236025] 		= true, 	-- Enraged Maim (incapacitate)
		[339] 			= true, 	-- Entangling Roots (dispel able)
		[235963] 		= true, 	-- Entangling Roots (NO dispel able)
		-- Death Knight 
		[204085] 		= true, 	-- Deathchill (Frost - PvP Roots)
		[207171] 		= true, 	-- Winter is Coming (Frost - Remorseless Winter Stun)
		-- Rogue  
		[703] 			= true, 	-- Garroute - Dot 
		[1330] 			= true, 	-- Garroute - Silence
		-- Paladin 
		--[216411] 		= true, 	-- BUFFS: Holy Shock 	(Divine Purpose)
		--[216413] 		= true, 	-- BUFFS: Light of Down (Divine Purpose)
		-- Priest 
		[200200] 		= true, 	-- Holy word: Chastise (Holy stun)
		[200196] 		= true, 	-- Holy Word: Chastise (Holy incapacitate)
		-- Demon Hunter 
		[217832]		= true, 	-- Imprison	
		[200166]		= true, 	-- Metamorphosis
	},
}

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
		local role							= UnitGroupRolesAssigned(unitID)
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
		return UnitInParty(unitID) or UnitInRaid(unitID)
	end, "UnitID"),
	InRange 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitIsUnit(unitID, "player") or UnitInRange(unitID)
	end, "UnitID"),
	InVehicle								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
		return UnitInVehicle(unitID)
	end, "UnitID"),	
	InCC 									= Cache:Pass(function(self)
		-- @return number (time in seconds of remain crownd control)
		local unitID 						= self.UnitID
		local value 						= A.Unit(unitID):DeBuffCyclone()
		if value == 0 then 			
			for i = 1, #Info.AllCC do 
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
	IsHealer 								= Cache:Pass(function(self)  
		-- @return boolean 
		local unitID 						= self.UnitID
	    if A.Unit(unitID):IsEnemy() then
			return TeamCache.Enemy.HEALER[unitID] or A.Unit(unitID):HasSpec(Info.SpecIs["HEALER"])  
		else 
			return TeamCache.Friendly.HEALER[unitID] or A.Unit(unitID):Role() == "HEALER"
		end 
	end, "UnitID"),
	IsTank 									= Cache:Pass(function(self)    
		-- @return boolean 
		local unitID 						= self.UnitID
	    if A.Unit(unitID):IsEnemy() then
			return TeamCache.Enemy.TANK[unitID] or A.Unit(unitID):HasSpec(Info.SpecIs["TANK"])  
		else 
			return TeamCache.Friendly.TANK[unitID] or A.Unit(unitID):Role() == "TANK"
		end 
	end, "UnitID"),	
	IsMelee 								= Cache:Pass(function(self) 
		-- @return boolean 
		local unitID 						= self.UnitID
	    if A.Unit(unitID):IsEnemy() then
			return TeamCache.Enemy.DAMAGER_MELEE[unitID] or A.Unit(unitID):HasSpec(Info.SpecIs["MELEE"])  
		elseif UnitIsUnit(unitID, "player") then 
			return A.Unit("player"):HasSpec(Info.SpecIs["MELEE"])
		elseif A.Unit(unitID):Role() == "DAMAGER" or A.Unit(unitID):Role() == "TANK" then 
			if TeamCache.Friendly.DAMAGER_MELEE[unitID] then 
				return true 
			end 
			
			local unitClass = A.Unit(unitID):Class()
			if unitClass == "HUNTER" then 
				return 
				(
					A.Unit(unitID):GetSpellCounter(186270) > 0 or -- Raptor Strike
					A.Unit(unitID):GetSpellCounter(259387) > 0 or -- Mongoose Bite
					A.Unit(unitID):GetSpellCounter(190925) > 0 or -- Harpoon
					A.Unit(unitID):GetSpellCounter(259495) > 0    -- Firebomb
				)
			elseif unitClass == "SHAMAN" then 
				local _, offhand = UnitAttackSpeed(unitID)
				return offhand ~= nil                    
			elseif unitClass == "DRUID" then 
				local _, power = UnitPowerType(unitID)
				return power == "ENERGY" or power == "FURY"
			else 
				return Info.ClassIsMelee[unitClass]
			end 
		end 
	end, "UnitID"),
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
				if Info.CacheMoveOut[GUID].Snapshot < 0 then 
					Info.CacheMoveOut[GUID].Snapshot = 0 
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
		local castName, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = UnitCastingInfo(unitID)
		if not castName then 
			castName, _, _, castStartTime, castEndTime, _, notInterruptable, spellID = UnitChannelInfo(unitID)
			if castName then 
				isChannel = true
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
		-- [2] Currect Casting Left Time (seconds) (@number)
		-- [3] Current Casting Left Time (percent) (@number)
		-- [4] spellID (@number)
		-- [5] spellName (@string)
		-- [6] notInterruptable (@boolean, false is able to be interrupted)
		-- [7] isChannel (@boolean)
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = A.Unit(unitID):IsCasting()

		local TotalCastTime, CurrentCastTimeSeconds, CurrentCastTimeLeftPercent = 0, 0, 0
		if unitID == "player" then 
			TotalCastTime = (select(4, A.GetSpellInfo(argSpellID or spellID)) or 0) / 1000
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
		-- drDiminishing is Tick (number: 100 -> 50 -> 25 -> 0) where 0 is fully imun, 100% no imun - can be fully duration CC'ed 
		-- "taunt" has unique Tick (number: 100 -> 65 -> 42 -> 27 -> 0)
		--[[ Taken from Combat Tracker
			drCat accepts:
				"root"           
				"stun"   	-- PvE unlocked       
				"disorient"      
				"disarm" 	-- added in 1.1	DRData	   
				"silence"        
				"taunt"     -- PvE unlocked   
				"incapacitate"   
				"knockback" 
		]]	
		local unitID 						= self.UnitID 
		if not A.IsInPvP then 
			return not A.Unit(unitID):IsBoss() and Info.ControlAbleClassification[A.Unit(unitID):Classification()] and A.Unit(unitID):GetDR(drCat) > (drDiminishing or 25)
		else 
			return A.Unit(unitID):GetDR(drCat) > (drDiminishing or 25)
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
			if Info.IsBoss[npc_id] or A.Unit(unitID):GetLevel() == -1 or UnitIsQuestBoss(unitID) or UnitEffectiveLevel(unitID) == -1 then 
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
	ThreatSituation							= Cache:Pass(function(self, otherunit)  
		-- @return number  
		local unitID 						= self.UnitID
		return UnitThreatSituation(unitID, otherunit or "target") or 0	       
	end, "UnitID"),
	IsTanking 								= Cache:Pass(function(self, otherunit, range)  
		-- @return boolean 
		local unitID 						= self.UnitID
		local ThreatThreshold 				= 3			
		local ThreatSituation 				= A.Unit(unitID):ThreatSituation(otherunit or "target")
		return ((A.IsInPvP and UnitIsUnit(unitID, (otherunit or "target") .. "target")) or (not A.IsInPvP and ThreatSituation >= ThreatThreshold)) or A.Unit(unitID):IsTankingAoE(range)	       
	end, "UnitID"),
	IsTankingAoE 							= Cache:Pass(function(self, range) 
		-- @return boolean 
		local unitID 						= self.UnitID
		local ThreatThreshold 				= 3
		local activeUnitPlates 				= MultiUnits:GetActiveUnitPlates()
		if activeUnitPlates then
			for unit in pairs(activeUnitPlates) do
				local ThreatSituation 		= A.Unit(unitID):ThreatSituation(unit)
				if ((A.IsInPvP and UnitIsUnit(unitID, unit .. "target")) or (not A.IsInPvP and ThreatSituation >= ThreatThreshold)) and (not range or A.Unit(unitID):CanInteract(range)) then 
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
		return math.floor(current_speed / 7 * 100), math.floor(max_speed / 7 * 100)
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
		--[[ Taken from Combat Tracker
			drCat accepts:
				"root"           
				"stun"   	-- PvE unlocked       
				"disorient"      
				"disarm" 	-- added in 1.1	DRData	   
				"silence"        
				"taunt"     -- PvE unlocked   
				"incapacitate"   
				"knockback" 
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
	GetIncomingHeals						= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
		return UnitGetIncomingHeals(unitID) or 0
	end, "UnitID"),
	GetRange 								= Cache:Wrap(function(self) -- +
		-- @return number (max), number (min)
		local unitID 						= self.UnitID
		local min_range, max_range 			= LibRangeCheck:GetRange(unitID)
		if not max_range then 
			return 0, 0 
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
				-- Soothing Mist
				if castName ~= A.GetSpellInfo(209525) then
					Info.CacheInterrupt[GUID] = { LastCast = castName, Timer = math.random(minX or 34, maxX or 68) }
				else 
					Info.CacheInterrupt[GUID] = { LastCast = castName, Timer = math.random(minX or 7, maxX or 13) }
				end 
			end 
			
			local castPercent = (TMW.time - castStartTime) * 100 / (castEndTime - castStartTime)
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
		local unitID 						= self.UnitID
		local name, server 					= UnitName(unitID)
		if name then
			name = name .. (server and "-" .. server or "")
		else 
			return false 
		end       
		
		if type(specID) == "table" then        
			for i = 1, #specID do
				if unitID == "player" then
					if specID[i] == A.PlayerSpec then 
						return true 
					end 
				else
					if Env.ModifiedUnitSpecs[name] and specID[i] == Env.ModifiedUnitSpecs[name] then 
						return true 
					end 
				end
			end       
		else
			if unitID == "player" then
				return specID == A.PlayerSpec 
			else 
				return Env.ModifiedUnitSpecs[name] and specID == Env.ModifiedUnitSpecs[name] 
			end       
		end
	end, "UnitID"),
	HasFlags 								= Cache:Wrap(function(self) -- +
		-- @return boolean 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):HasBuffs({156621, 156618, 34976}) > 0 or A.Unit(unitID):HasDeBuffs(121177) > 0 
	end, "UnitID"),
	Health									= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return UnitHealth(unitID)
	end, "UnitID"),
	HealthMax								= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return UnitHealthMax(unitID)
	end, "UnitID"),
	HealthDeficit							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):HealthMax() - A.Unit(unitID):Health()
	end, "UnitID"),
	HealthDeficitPercent					= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):HealthDeficit() * 100 / A.Unit(unitID):HealthMax()
	end, "UnitID"),
	HealthPercent							= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return A.Unit(unitID):Health() * 100 / A.Unit(unitID):HealthMax()
	end, "UnitID"),
	Power									= Cache:Pass(function(self)
		-- @return number 
		local unitID 						= self.UnitID
	    return UnitPower(unitID)
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
		local unitID 						= self.UnitID
		local cycloneName					= strlowerCache[A.GetSpellInfo(33786)]
		return Env.AuraDur(unitID, cycloneName, "HARMFUL")
	end, "UnitGUID"),
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
	SortDeBuffs								= Cache:Wrap(function(self, spell, caster, byID)
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
	HasDeBuffsStacks						= Cache:Wrap(function(self, spell, caster, byID)
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
	PT										= Cache:Wrap(function(self, spell, debuff, byID)    
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
	HasBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
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
	SortBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
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
	HasBuffsStacks 							= Cache:Wrap(function(self, spell, caster, byID)
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
	WithOutKarmed 							= Cache:Wrap(function(self)
		-- @return boolean 
		local unitID 						= self.UnitID
		local value 						= true 		
		if A.Unit(unitID):IsEnemy() then
			if TeamCache.Friendly.Size > 0 and A.Unit(unitID):HasBuffs(122470) > 0 then 
				value = false
				for i = 1, TeamCache.Friendly.Size do
					local member = TeamCache.Friendly.Type .. i
					-- Forbearance
					if A.Unit(member):HasDeBuffs(25771) >= 20 then 
						value = true 
						break 
					end                     
				end        
			end
		else
			if TeamCache.Enemy.Size > 0 and A.Unit(unitID):HasBuffs(122470) > 0 then 
				value = false
				for i = 1, TeamCache.Enemy.Size do
					local arena = TeamCache.Enemy.Type .. i
					-- Forbearance
					if A.Unit(arena):HasDeBuffs(25771) >= 20 then 
						value = true 
						break 
					end                     
				end        
			end
		end  
		return value
	end, "UnitID"),
	IsFocused 								= Cache:Wrap(function(self, specs, burst, deffensive, range)
		-- @return boolean
		local unitID 						= self.UnitID
		local value 						= false 	
		
		if A.Unit(unitID):IsEnemy() then
			if next(TeamCache.Friendly.DAMAGER) then     
				for member in pairs(TeamCache.Friendly.DAMAGER) do 
					if UnitIsUnit(member .. "target", unitID) 
					and (not specs or 		(specs == "MELEE" and A.Unit(member):IsMelee()))
					and (not burst or 		A.Unit(member):HasBuffs("DamageBuffs") > 2) 
					and (not deffensive or 	A.Unit(unitID):HasBuffs("DeffBuffs") < 2)
					and (not range or 		A.Unit(member):GetRange() <= range) then 
						value = true 
						break 
					end
				end 
			end
		else
			if next(TeamCache.Enemy.DAMAGER) then 
				-- TYPES AND ROLES
				specs = Info.SpecIs[specs] or specs or false
				for arena in pairs(TeamCache.Enemy.DAMAGER) do
					if UnitIsUnit(arena .. "target", unitID) 
					and (not specs or 		A.Unit(arena):HasSpec(specs))
					and (not burst or 		A.Unit(arena):HasBuffs("DamageBuffs") > 2) 
					and (not deffensive or 	A.Unit(unitID):HasBuffs("DeffBuffs") < 2)
					and (not range or 		A.Unit(arena):GetRange() <= range) then 
						value = true 
						break
					end
				end 
			end
		end 
		return value 
	end, "UnitGUID"),
	IsExecuted 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		local value 						= false 
		
		if A.Unit(unitID):IsEnemy() then
			value = A.Unit(unitID):TimeToDieX(20) <= A.GetGCD() + A.GetCurrentGCD()
		else
			if next(TeamCache.Enemy.DAMAGER_MELEE) and A.Unit(unitID):TimeToDieX(20) <= A.GetGCD() + A.GetCurrentGCD() then
				for arena in pairs(TeamCache.Enemy.DAMAGER_MELEE) do 
					if A.Unit(arena):HasSpec({71, 72}) and UnitIsUnit(arena .. "target", unitID) and A.Unit(arena):Power() >= 20 and (unitID ~= "player" or A.Unit(arena):GetRange() < 7) then 
						value = true 
						break
					end
				end
			end
		end 
		return value
	end, "UnitGUID"),
	UseBurst 								= Cache:Wrap(function(self, pBurst)
		-- @return boolean
		local unitID 						= self.UnitID
		local value 						= false 
		
		if A.Unit(unitID):IsEnemy() then
			value = A.Unit(unitID):IsPlayer() and 
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
				A.Unit(unitID):IsFocused(nil, true) or 
				A.EnemyTeam("HEALER"):GetCC() >= A.GetGCD() * 3 or
				(
					pBurst and 
					A.Unit("player"):HasBuffs("DamageBuffs") >= A.GetGCD() * 3
				)
			)       
		elseif A.IamHealer then 
			-- For HealingEngine as Healer
			value = A.Unit(unitID):IsPlayer() and 
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
					A.Unit(unitID):IsFocused(nil, true) and 
					(
						A.Unit(unitID):TimeToDie() <= 10 or 
						A.Unit(unitID):HealthPercent() <= 70
					)
				) 
			)                   
		end 
		return value 
	end, "UnitGUID"),
	UseDeff 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return 
		(
			A.Unit(unitID):IsFocused(nil, true) or 
			(
				A.Unit(unitID):TimeToDie() < 8 and 
				A.Unit(unitID):IsFocused() 
			) or 
			A.Unit(unitID):HasDeBuffs("DamageDeBuffs") > 5 or 
			A.Unit(unitID):IsExecuted()
		) 			
	end, "UnitGUID"),	
})	

function A.Unit:New(UnitID, Refresh)
	self.UnitID 	= UnitID
	self.Refresh 	= Refresh
end

-------------------------------------------------------------------------------
-- API: FriendlyTeam 
-------------------------------------------------------------------------------
A.FriendlyTeam = PseudoClass({
	GetUnitID 								= Cache:Pass(function(self, range)
		-- @return string 
		local ROLE 							= self.ROLE
		local value	 						= "none" 
		
		for member in pairs(TeamCache.Friendly[ROLE]) do
			if not A.Unit(member):IsDead() and A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then 
				value = member 
				break 
			end 
		end 
		
		return value 
	end, "ROLE"),
	GetCC 									= Cache:Pass(function(self, spells)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if spells then 
					value = A.Unit(member):HasDeBuffs(spells) 
				else
					value = A.Unit(member):InCC()
					if value ~= 0 then 
						break 
					end 
				end 				
			end     
		else
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if spells then 
					value = A.Unit(member):HasDeBuffs(spells) 
				else
					value = A.Unit(member):InCC()
					if value ~= 0 then 
						break 
					end 
				end 	
			end
		end 		

		return value, member
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, Buffs, range, iSource)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		if TeamCache.Friendly.Size == 0 then 
			return A.Unit("player"):HasBuffs(spells, iSource) == 0, "player"
		end 		
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then
					value = A.Unit(member):HasBuffs(Buffs, iSource)       
					if value ~= 0 then 
						break
					end
				end 
			end 
		else
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then
					value = A.Unit(member):HasBuffs(Buffs, iSource)                     				 
					if value ~= 0 then 
						break
					end      
				end 
			end  
		end  	
		
		return value, member
	end, "ROLE"),
	GetDeBuffs		 						= Cache:Wrap(function(self, DeBuffs, range)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= 0, "none"
		
		if TeamCache.Friendly.Size == 0 then 
			local d = A.Unit("player"):HasDeBuffs(DeBuffs)
			if d ~= 0 then 
				return d, "player"
			else 
				return value, member
			end 
		end 		
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then
					value = A.Unit(member):HasDeBuffs(DeBuffs)       
					if value ~= 0 then 
						break
					end
				end 
			end 
		else
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) then
					value = A.Unit(member):HasDeBuffs(DeBuffs)                     				 
					if value ~= 0 then 
						break
					end      
				end 
			end  
		end  		
		
		return value, member
	end, "ROLE"),
	GetTTD 									= Cache:Pass(function(self, count, seconds, range)
		-- @return boolean, counter, unitID 
		local ROLE 							= self.ROLE
		local value, counter, member 		= false, 0, "none"
		
		if TeamCache.Friendly.Size == 0 then 
			if A.Unit("player"):TimeToDie() <= seconds then
				return true, 1, "player"
			else 
				return value, counter, member
			end 
		end 		
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) and A.Unit(member):TimeToDie() <= seconds then
					counter = counter + 1        
					if counter >= count then 
						value = true
						break
					end
				end 
			end 
		else
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):InRange() and (not range or A.Unit(member):GetRange() <= range) and A.Unit(member):TimeToDie() <= seconds  then
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
		if TeamCache.Friendly.Size == 0 then 
			return A.Unit("player"):TimeToDie(), 1
		end 
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if A.Unit(member):InRange() then 
					value = value + A.Unit(member):TimeToDie()
					members = members + 1
				end 
			end 
		else 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):InRange() then
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
		if TeamCache.Friendly.Size == 0 then 
			local d = A.Unit("player"):HasBuffs(spells, iSource) 
			if d == 0 then 
				return d, "player"
			else 
				return value, member
			end 
		end 
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly[ROLE]) do
				if A.Unit(member):InRange() and not A.Unit(member):IsDead() and A.Unit(member):HasBuffs(spells, iSource) == 0 then
					return true, member 
				end 
			end 
		else 
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):InRange() and not A.Unit(member):IsDead() and A.Unit(member):HasBuffs(spells, iSource) == 0 then
					return true, member 
				end                        
			end  
		end 		
		
		return value, member 
	end, "ROLE"),
	HealerIsFocused 						= Cache:Wrap(function(self, burst, deffensive, range)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= false, "none"
		
		for member in pairs(TeamCache.Friendly.HEALER) do
			if A.Unit(member):InRange() and A.Unit(member):IsFocused(nil, burst, deffensive, range) then
				return true, member
			end 
		end 
		
		return value, member 
	end, "ROLE"),
	ArcaneTorrentMindControl 				= Cache:Pass(function(self)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, member 				= false, "none"
		
		if ROLE then 
			for member in pairs(TeamCache.Friendly.HEALER) do
				if A.Unit(member):HasBuffs(605) > 0 and A.Unit(member):GetRange() <= 8 then
					return true, member 
				end 
			end 
		else
			for i = 1, TeamCache.Friendly.Size do
				member = TeamCache.Friendly.Type .. i
				if A.Unit(member):HasBuffs(605) > 0 and A.Unit(member):GetRange() <= 8 then
					return true, member 
				end                        
			end  
		end 
		
		return value, member 
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
	GetUnitID 								= Cache:Pass(function(self, range, specs)
		-- @return string 
		local ROLE 							= self.ROLE
		local value 						= "none" 

		for arena in pairs(TeamCache.Enemy[ROLE]) do
			if not A.Unit(arena):IsDead() and (not specs or A.Unit(arena):HasSpec(specs)) and (not range or A.Unit(arena):GetRange() <= range) then 
				value = arena 
				break 
			end 
		end 

		return value 
	end, "ROLE"),
	GetCC 									= Cache:Pass(function(self, spells)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if ROLE then 
			for arena in pairs(TeamCache.Enemy[ROLE]) do
				if spells then 
					value = A.Unit(arena):HasDeBuffs(spells) 
				elseif ROLE ~= "HEALER" or not UnitIsUnit(arena, "target") then 
					value = A.Unit(arena):InCC()
					if value ~= 0 then 
						break 
					end 
				end 				
			end     
		else
			for i = 1, TeamCache.Enemy.Size do
				arena = TeamCache.Enemy.Type .. i
				if spells then 
					value = A.Unit(arena):HasDeBuffs(spells) 
				elseif ROLE ~= "HEALER" or not UnitIsUnit(arena, "target") then 
					value = A.Unit(arena):InCC()
					if value ~= 0 then 
						break 
					end 
				end 	
			end
		end 
		
		return value, arena 
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, Buffs, range, iSource)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if ROLE then 
			for arena in pairs(TeamCache.Enemy[ROLE]) do
				if not range or A.Unit(arena):GetRange() <= range then
					value = A.Unit(arena):HasBuffs(Buffs, iSource)       
					if value ~= 0 then 
						break
					end
				end 
			end 
		else
			for i = 1, TeamCache.Enemy.Size do
				arena = TeamCache.Enemy.Type .. i
				if not range or A.Unit(arena):GetRange() <= range then
					value = A.Unit(arena):HasBuffs(Buffs, iSource)                     				 
					if value ~= 0 then 
						break
					end      
				end 
			end  
		end  
		
		return value, arena 
	end, "ROLE"),
	GetDeBuffs 								= Cache:Wrap(function(self, DeBuffs, range)
		-- @return number, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= 0, "none"
		
		if ROLE then 
			for arena in pairs(TeamCache.Enemy[ROLE]) do
				if not range or A.Unit(arena):GetRange() <= range then
					value = A.Unit(arena):HasDeBuffs(DeBuffs)                     				 
					if value ~= 0 then 
						break
					end
				end
			end 
		else
			for i = 1, TeamCache.Enemy.Size do
				arena = TeamCache.Enemy.Type .. i
				if not range or A.Unit(arena):GetRange() <= range then
					value = A.Unit(arena):HasDeBuffs(DeBuffs)                     				 
					if value ~= 0 then 
						break
					end         
				end 
			end  
		end   
		
		return value, arena 
	end, "ROLE"),
	IsBreakAble 							= Cache:Wrap(function(self, range)
		-- @return boolean, unitID 
		local ROLE 							= self.ROLE
		local value, arena 					= false, "none"
		
		if ROLE then 
			for arena in pairs(TeamCache.Enemy[ROLE]) do
				if not UnitIsUnit(arena, "target") and (not range or A.Unit(arena):GetRange() <= range) and A.Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
					value = true 
					break
				end 
			end 
		else
			local activeUnitPlates 			= MultiUnits:GetActiveUnitPlates()
			if activeUnitPlates then 
				for arena in pairs(activeUnitPlates) do               
					if A.Unit(arena):IsPlayer() and not UnitIsUnit("target", arena) and (not range or A.Unit(arena):GetRange() <= range) and A.Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
						value = true 
						break
					end            
				end  
			end 
		end 
		
		return value, arena 
	end, "ROLE"),
	PlayersInRange 							= Cache:Wrap(function(self, stop, range)
		-- @return boolean, number, unitID 
		local ROLE 							= self.ROLE
		local value, count, arena 			= false, 0, "none"
		
		if ROLE then 
			for arena in pairs(TeamCache.Enemy[ROLE]) do
				if not range or A.Unit(arena):GetRange() <= range then
					count = count + 1 	
					if not stop then 
						value = true 
					elseif count >= stop then 
						value = true 
						break 				 						
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
		
		for i = 1, TeamCache.Enemy.Size do 
			arena = TeamCache.Enemy.Type .. i
			local class = A.Unit(arena):Class()
			if not A.Unit(arena):IsDead() and (class == "MAGE" or class == "ROGUE" or class == "DRUID") then 
				value = true  
				break 
			end 
		end 
		 
		return value, arena
	end, "ROLE"), 
	IsTauntPetAble 							= Cache:Wrap(function(self, spellID)
		-- @return boolean, unitID
		local value, pet = false, "none"
		if TeamCache.Enemy.Size > 0 then 
			for i = 1, 3 do 
				pet = TeamCache.Enemy.Type .. "pet" .. i
				if A.Unit(pet):IsExists() and (not spellID or (type(spellID) == "table" and spellID:IsInRange(pet)) or (type(spellID) ~= "table" and A.IsSpellInRange(spellID, pet))) then 
					value = true 
					break 
				end              
			end  
		end
		
		return value, pet 
	end, "ROLE"),
	IsCastingBreakAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
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
 
		return value, arena
	end, "ROLE"),
	IsReshiftAble 							= Cache:Wrap(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
		for i = 1, TeamCache.Enemy.Size do 
			arena = TeamCache.Enemy.Type .. i
			local _, castRemain, _, _, castName = A.Unit(arena):CastTime()
			if castRemain > 0 and castRemain <= A.GetCurrentGCD() + A.GetGCD() + (offset or 0.05) then 
				for i = 1, #AuraList.Reshift do 
					if A.GetSpellInfo(AuraList.Reshift[i][1]) == castName and A.Unit(arena):GetRange() <= AuraList.Reshift[i][2] and not A.Unit("player"):IsFocused("MELEE") then 
						return true, arena
					end
				end
			end
		end
		
		return value, arena 
	end, "ROLE"), 
	IsPremonitionAble 						= Cache:Wrap(function(self, offset)
		-- @return boolean, unitID
		local value, arena 					= false, "none"
		
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
	local LastTimeCasted = CombatTracker:GetSpellLastCast("player", A.LastPlayerCastID) 
	if (LastTimeCasted == 0 or LastTimeCasted > 0.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then 
		wipe(Info.CacheMoveIn)
		wipe(Info.CacheMoveOut)
		wipe(Info.CacheMoving)
		wipe(Info.CacheStaying)	
		wipe(Info.CacheInterrupt)
	end 
end)