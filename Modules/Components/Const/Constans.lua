local dir														= [[Interface\AddOns\TheAction Classic\Media\]]
-- TellMeWhen
ACTION_CONST_TMW_DEFAULT_STATE_HIDE 							= TMW.CONST.STATE.DEFAULT_HIDE
ACTION_CONST_TMW_DEFAULT_STATE_SHOW 							= TMW.CONST.STATE.DEFAULT_SHOW

-- Action 
ACTION_CONST_CACHE_DISABLE				 						= false 		-- On own risk, it will disable memorize cache but will reduce a lot of memory drive, it's trade-in toggle between CPU and Memory 	(required reload after change)
ACTION_CONST_CACHE_MEM_DRIVE									= false			-- On own risk, it will unlock remain cache for low CPU demand functions "aka memory killer" 										(doesn't work if ACTION_CONST_CACHE_DISABLE is 'true')
ACTION_CONST_CACHE_DEFAULT_TIMER 								= 0.01			-- "Tools.lua" offset on cache control 
ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT							= 0.005			-- "Unit.lua" offset on cache control 
ACTION_CONST_CACHE_DEFAULT_TIMER_MULTIUNIT_CLEU					= 0.004
ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE				= 40			-- Live: 60, Classic: 20 but exponense seems can be 40
ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE_VALIDANCE		= "4e1"
ACTION_CONST_CACHE_DEFAULT_OFFSET_DUEL							= 2.9			-- Delay until duel starts after event trigger

-- Textures
ACTION_CONST_PAUSECHECKS_DISABLED 								= dir .. [[LEVELUPICON-LFD]]
ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST 							= dir .. [[Achievement_BG_Xkills_AVgraveyard]]
ACTION_CONST_PAUSECHECKS_IS_MOUNTED 							= dir .. [[Garrison_Building_Stables]]
ACTION_CONST_PAUSECHECKS_WAITING 								= 134376
ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING 					= dir .. [[Achievement_BG_grab_cap_flagunderXseconds]]
ACTION_CONST_PAUSECHECKS_LOOTFRAME 								= dir .. [[Garrison_Building_TradingPost]]
ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK 						= 134062

ACTION_CONST_TRINKET1 											= dir .. [[Garrison_BlueWeapon]]
ACTION_CONST_TRINKET2 											= dir .. [[Garrison_GreenWeapon]]
ACTION_CONST_POTION 											= dir .. [[Trade_Alchemy_DPotion_A28]]

ACTION_CONST_LEFT 												= dir .. [[Spell_Shaman_SpiritLink]]
ACTION_CONST_RIGHT 												= dir .. [[INV_BannerPVP_03]] 
ACTION_CONST_STOPCAST 											= dir .. [[Spell_Magic_PolymorphRabbit]]
ACTION_CONST_AUTOTARGET 										= dir .. [[INV_Gizmo_GoblingTonkController]]

ACTION_CONST_AUTOSHOOT											= dir .. [[ABILITY_SHOOTWAND]] -- 132317 -- spellID: 5019
ACTION_CONST_AUTOATTACK											= dir .. [[INV_Sword_04]] -- spellID: 7038

ACTION_CONST_HUMAN 												= dir .. [[Spell_Shadow_Charm]]

-- Class portraits
ACTION_CONST_PORTRAIT_WARRIOR									= dir .. [[ClassIcon_Warrior]]
ACTION_CONST_PORTRAIT_PALADIN									= dir .. [[ClassIcon_Paladin]]
ACTION_CONST_PORTRAIT_HUNTER									= dir .. [[ClassIcon_Hunter]]
ACTION_CONST_PORTRAIT_ROGUE										= dir .. [[ClassIcon_Rogue]]
ACTION_CONST_PORTRAIT_PRIEST									= dir .. [[ClassIcon_Priest]]
ACTION_CONST_PORTRAIT_SHAMAN									= dir .. [[TRADE_ARCHAEOLOGY_ANCIENTORCSHAMANHEADDRESS]] 		-- Custom because it making conflict with Bloodlust
ACTION_CONST_PORTRAIT_MAGE										= dir .. [[ClassIcon_Mage]]
ACTION_CONST_PORTRAIT_WARLOCK									= dir .. [[ClassIcon_Warlock]]
ACTION_CONST_PORTRAIT_DRUID										= dir .. [[ClassIcon_Druid]]

-- SpellID
ACTION_CONST_SPELLID_FREEZING_TRAP								= 1499

ACTION_CONST_PICKPOCKET											= 5967

-- Global
ACTION_CONST_MAX_BOSS_FRAMES 									= MAX_BOSS_FRAMES
ACTION_CONST_UNKNOWN											= UNKNOWN
ACTION_CONST_CAMERA_MAX_FACTOR									= BINDING_NAME_VEHICLECAMERAZOOMOUT

-- CombatLog
ACTION_CONST_CL_TYPE_PLAYER 	 								= COMBATLOG_OBJECT_TYPE_PLAYER
ACTION_CONST_CL_CONTROL_PLAYER   								= COMBATLOG_OBJECT_CONTROL_PLAYER
ACTION_CONST_CL_REACTION_HOSTILE 								= COMBATLOG_OBJECT_REACTION_HOSTILE
ACTION_CONST_CL_REACTION_NEUTRAL 								= COMBATLOG_OBJECT_REACTION_NEUTRAL

-- UI INFO MESSAGES
ACTION_CONST_SPELL_FAILED_LINE_OF_SIGHT 						= SPELL_FAILED_LINE_OF_SIGHT

-- Arena
ACTION_CONST_PVP_TARGET_ARENA1									= dir .. [[Spell_Warlock_DemonicPortal_Green]]
ACTION_CONST_PVP_TARGET_ARENA2									= dir .. [[Spell_Nature_MoonGlow]]
ACTION_CONST_PVP_TARGET_ARENA3 									= dir .. [[PALADIN_HOLY]]

-- Specialization ID
ACTION_CONST_WARRIOR_ARMS 										= 71			
ACTION_CONST_WARRIOR_FURY 										= 72			
ACTION_CONST_WARRIOR_PROTECTION 								= 73			

ACTION_CONST_PALADIN_HOLY 										= 65			
ACTION_CONST_PALADIN_PROTECTION 								= 66			
ACTION_CONST_PALADIN_RETRIBUTION 								= 70			

ACTION_CONST_HUNTER_BEASTMASTERY 								= 253			
ACTION_CONST_HUNTER_MARKSMANSHIP 								= 254			
ACTION_CONST_HUNTER_SURVIVAL 									= 255			

ACTION_CONST_ROGUE_ASSASSINATION 								= 259			
ACTION_CONST_ROGUE_OUTLAW 										= 260			
ACTION_CONST_ROGUE_SUBTLETY 									= 261			

ACTION_CONST_PRIEST_DISCIPLINE 									= 256			
ACTION_CONST_PRIEST_HOLY 										= 257			
ACTION_CONST_PRIEST_SHADOW 										= 258			

ACTION_CONST_SHAMAN_ELEMENTAL 									= 262			
ACTION_CONST_SHAMAN_ENCHANCEMENT 								= 263
ACTION_CONST_SHAMAN_RESTORATION									= 264		

ACTION_CONST_MAGE_ARCANE 										= 62
ACTION_CONST_MAGE_FIRE 											= 63
ACTION_CONST_MAGE_FROST 										= 64			

ACTION_CONST_WARLOCK_AFFLICTION									= 265			
ACTION_CONST_WARLOCK_DEMONOLOGY 								= 266			
ACTION_CONST_WARLOCK_DESTRUCTION 								= 267			

ACTION_CONST_DRUID_BALANCE										= 102
ACTION_CONST_DRUID_FERAL	 									= 103
ACTION_CONST_DRUID_RESTORATION 									= 105

-- Inventory slots
ACTION_COST_INVSLOT_AMMO										= INVSLOT_AMMO 		-- 0
-- ACTION_CONST_INVSLOT_HEAD       								= INVSLOT_HEAD 		-- 1
ACTION_CONST_INVSLOT_NECK       								= INVSLOT_NECK 		-- 2
-- ACTION_CONST_INVSLOT_SHOULDAC   								= INVSLOT_SHOULDER 	-- 3
-- ACTION_CONST_INVSLOT_BODY       								= INVSLOT_BODY 		-- 4
-- ACTION_CONST_INVSLOT_CHEST      								= INVSLOT_CHEST 	-- 5
-- ACTION_CONST_INVSLOT_WAIST      								= INVSLOT_WAIST 	-- 6
-- ACTION_CONST_INVSLOT_LEGS       								= INVSLOT_LEGS 		-- 7
-- ACTION_CONST_INVSLOT_FEET       								= INVSLOT_FEET 		-- 8
-- ACTION_CONST_INVSLOT_WRIST      								= INVSLOT_WRIST 	-- 9
-- ACTION_CONST_INVSLOT_HAND       								= INVSLOT_HAND 		-- 10
-- ACTION_CONST_INVSLOT_FINGAC1    								= INVSLOT_FINGER1 	-- 11
-- ACTION_CONST_INVSLOT_FINGAC2    								= INVSLOT_FINGER2 	-- 12
ACTION_CONST_INVSLOT_TRINKET1   								= INVSLOT_TRINKET1 	-- 13
ACTION_CONST_INVSLOT_TRINKET2   								= INVSLOT_TRINKET2 	-- 14
-- ACTION_CONST_INVSLOT_BACK       								= INVSLOT_BACK		-- 15
ACTION_CONST_INVSLOT_MAINHAND   								= INVSLOT_MAINHAND  -- 16
ACTION_CONST_INVSLOT_OFFHAND    								= INVSLOT_OFFHAND	-- 17
ACTION_CONST_INVSLOT_RANGED     								= INVSLOT_RANGED	-- 18
-- ACTION_CONST_INVSLOT_TABARD     								= INVSLOT_TABARD	-- 19