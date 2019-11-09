--- 
local DateTime 						= "09.11.2019"
---
local TMW 							= TMW
local strlowerCache  				= TMW.strlowerCache
local huge	 						= math.huge
local math_abs						= math.abs
local math_floor					= math.floor
local math_log10					= math.log10
local math_max						= math.max

local StdUi 						= LibStub("StdUi")
local LibDBIcon	 					= LibStub("LibDBIcon-1.0")
local LSM 							= LibStub("LibSharedMedia-3.0")
	  LSM:Register(LSM.MediaType.STATUSBAR, "Flat", [[Interface\Addons\TheAction Classic\Media\Flat]])

local pcall, ipairs, pairs, type, assert, error, setfenv, tostringall, tostring, tonumber, getmetatable, setmetatable, loadstring, select, _G, coroutine, table, hooksecurefunc, wipe,     safecall,    debugprofilestop = 
	  pcall, ipairs, pairs, type, assert, error, setfenv, tostringall, tostring, tonumber, getmetatable, setmetatable, loadstring, select, _G, coroutine, table, hooksecurefunc, wipe, TMW.safecall, _G.debugprofilestop_SAFE

local GetRealmName, GetExpansionLevel, GetSpecialization, GetFramerate, GetMouseFocus, GetLocale, GetCVar, SetCVar, GetBindingFromClick, GetItemSpell = 
	  GetRealmName, GetExpansionLevel, GetSpecialization, GetFramerate, GetMouseFocus, GetLocale, GetCVar, SetCVar, GetBindingFromClick, GetItemSpell
	  
local UnitName, UnitClass, UnitRace, UnitExists, UnitIsUnit, 	 UnitAura, UnitPower, UnitIsOwnerOrControllerOfUnit = 
	  UnitName, UnitClass, UnitRace, UnitExists, UnitIsUnit, TMW.UnitAura, UnitPower, UnitIsOwnerOrControllerOfUnit	  
	  
-- AutoShoot 
local HasWandEquipped 				= HasWandEquipped	  
	  
-- LetMeCast 	  
local DoEmote, Dismount, CancelShapeshiftForm =
	  DoEmote, Dismount, CancelShapeshiftForm
	    
-- AuraDuration 
local SetPortraitToTexture, CooldownFrame_Set, TargetFrame_ShouldShowDebuffs, TargetFrame_UpdateAuras, TargetFrame_UpdateAuraPositions, TargetFrame_UpdateBuffAnchor, TargetFrame_UpdateDebuffAnchor, Target_Spellbar_AdjustPosition,    DebuffTypeColor =
	  SetPortraitToTexture, CooldownFrame_Set, TargetFrame_ShouldShowDebuffs, TargetFrame_UpdateAuras, TargetFrame_UpdateAuraPositions, TargetFrame_UpdateBuffAnchor, TargetFrame_UpdateDebuffAnchor, Target_Spellbar_AdjustPosition, _G.DebuffTypeColor
	  
-- UnitHealthTool
local TextStatusBar_UpdateTextStringWithValues =
	  TextStatusBar_UpdateTextStringWithValues	 	 
		
local GameLocale 							= GetLocale()	
-- Mexico is used esES
if GameLocale == "esMX" then 
	GameLocale = "esES"
end 
local UIParent								= UIParent
local C_UI									= _G.C_UI
local Spell									= _G.Spell 	  								-- ObjectAPI/Spell.lua  
local CreateFrame 							= _G.CreateFrame	
local PlaySound								= _G.PlaySound	  
local InCombatLockdown						= _G.InCombatLockdown

Action 										= LibStub("AceAddon-3.0"):NewAddon("Action", "AceEvent-3.0")  
Action.PlayerRace 							= select(2, UnitRace("player"))
Action.PlayerClassName, Action.PlayerClass  = UnitClass("player")

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------
-- Note: L (@table localized with current language of interface), CL (@string current selected language of interface), GameLocale (@string game language default), Localization (@table clear with all locales)
local CL, L = "enUS"
local Localization = {
	[GameLocale] = {},
	enUS = {			
		NOSUPPORT = "this profile is not supported ActionUI yet",	
		DEBUG = "|cffff0000[Debug] Error Identification: |r",			
		ISNOTFOUND = "is not found!",			
		CREATED = "created",
		YES = "Yes",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selected",
		RESET = "Reset",
		RESETED = "Reseted",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro already existed!|r",
		MACROLIMIT = "|cffff0000Can't create macro, you reached limit. You need to delete at least one macro!|r",	
		GLOBALAPI = "API Global: ",
		RESIZE = "Resize",
		RESIZE_TOOLTIP = "Click-and-drag to resize",
		SLASH = {
			LIST = "List of slash commands:",
			OPENCONFIGMENU = "shows config menu",
			HELP = "shows help info",
			QUEUEHOWTO = "macro (toggle) for sequence system (Queue), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			QUEUEEXAMPLE = "example of Queue usage",
			BLOCKHOWTO = "macro (toggle) for disable|enable any actions (Blocker), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			BLOCKEXAMPLE = "example of Blocker usage",
			RIGHTCLICKGUIDANCE = "Most elements are left and right click-able. Right click will create macro toggle so you can consider the above suggestion",				
			INTERFACEGUIDANCE = "UI explains:",
			INTERFACEGUIDANCEGLOBAL = "[Global] relative for ALL your account, ALL characters, ALL specializations",	
			TOTOGGLEBURST = "to toggle Burst Mode",
			TOTOGGLEMODE = "to toggle PvP / PvE",
			TOTOGGLEAOE = "to toggle AoE",
		},
		TAB = {
			RESETBUTTON = "Reset settings",
			RESETQUESTION = "Are you sure?",
			SAVEACTIONS = "Save Actions settings",
			SAVEINTERRUPT = "Save Interrupt Lists",
			SAVEDISPEL = "Save Auras Lists",
			SAVEMOUSE = "Save Cursor Lists",
			SAVEMSG = "Save MSG Lists",
			LUAWINDOW = "LUA Configure",
			LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need to use Action. for anything that have it\n\nIf you want to remove already default code you will need to write 'return true' without quotes instead of remove them all",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Close LUA Configuration before add",
			FIXLUABEFOREADD = "You need to fix errors in LUA Configuration before to add",
			RIGHTCLICKCREATEMACRO = "RightClick: Create macro",
			NOTHING = "Profile has no configuration for this tab",
			HOW = "Apply:",
			HOWTOOLTIP = "Global: All account, all characters and all specializations",
			GLOBAL = "Global",
			ALLSPECS = "To all specializations of the character",
			THISSPEC = "To the current specialization of the character",			
			KEY = "Key:",
			CONFIGPANEL = "'Add' Configuration",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "Primary",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Forcing a profile to switch to another mode\n(especially useful when the War Mode is ON)\n\nRightClick: Create macro", 
				PVEPVPRESETTOOLTIP = "Reset manual toggle to auto select",
				CHANGELANGUAGE = "Switch language",
				CHARACTERSECTION = "Character Section",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "If the target is empty, but you are in combat, it will return the nearest enemy\nThe switcher works in the same way if the target has immunity in PvP\n\nRightClick: Create macro",					
				POTION = "Potion",
				RACIAL = "Racial spell",
				STOPCAST = "Stop casting",
				SYSTEMSECTION = "System Section",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ATTENTION: This option causes delay of 0.3s + current spinning gcd\nif unit being checked it is located in a lose (for example, behind a box at arena)\nYou must also enable the same setting in Advanced Settings\nThis option blacklists unit which in a lose and\nstops providing actions to it for N seconds\n\nRightClick: Create macro",
				HEALINGENGINEPETS = "HealingEngine pets",
				HEALINGENGINEPETSTOOLTIP = "Include in target select player's pets and calculate for heal them\n\nRightClick: Create macro",
				HEALINGENGINEANYROLE = "HealingEngine any role",
				HEALINGENGINEANYROLETOOLTIP = "Enable to use member targeting on any your role",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Will stop harmful damage on enemies\nIf they have CC such as Polymorph\nIt doesn't cancel auto attack!\n\nRightClick: Create macro",
				ALL = "All",
				RAID = "Raid",
				TANK = "Only Tanks",
				DAMAGER = "Only Damage Dealers",
				HEALER = "Only Healers",
				TANKANDPARTY = "Tanks and Party",
				PARTY = "Party",
				HEALINGENGINETOOLTIP = "This option relative for unit selection on healers\nAll: Everyone member\nRaid: Everyone member without tanks\n\nRightClick: Create macro\nIf you would like set fix toggle state use argument in (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "DBM Timers",
				DBMTOOLTIP = "Tracking pull timers and some specific events such as trash incoming.\nThis feature is not availble for all the profiles!\n\nRightClick: Create macro",
				FPS = "FPS Optimization",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Increases frames per second by increasing the dynamic dependency\nframes of the refresh cycle (call) of the rotation cycle\n\nYou can also manually set the interval following a simple rule:\nThe larger slider then more FPS, but worse rotation update\nToo high value can cause unpredictable behavior!\n\nRightClick: Create macro",					
				PVPSECTION = "PvP Section",
				RETARGET = "Return previous saved @target\n(arena1-3 units only)\nIt recommended against hunters with 'Feign Death' and any unforeseen target drops\n\nRightClick: Create macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Burst Mode",
				BURSTTOOLTIP = "Everything - On cooldown\nAuto - Boss or Players\nOff - Disabled\n\nRightClick: Create macro\nIf you would like set fix toggle state use argument in (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Healing Potion",
				HEALTHSTONETOOLTIP = "Set percent health (HP)\nHealing Potion depends on your tab of the class settings for Potion\nand if these potions shown in Actions tab\nHealthstone has shared cooldown with Healing Potion\n\nRightClick: Create macro",
				AUTOATTACK = "Auto Attack",
				AUTOSHOOT = "Auto Shoot",				
				PAUSECHECKS = "Rotation doesn't work if:",
				DEADOFGHOSTPLAYER = "You're dead",
				DEADOFGHOSTTARGET = "Target is dead",
				DEADOFGHOSTTARGETTOOLTIP = "Exception enemy hunter if he selected as primary target",
				MOUNT = "IsMounted",
				COMBAT = "Out of combat", 
				COMBATTOOLTIP = "If You and Your target out of combat. Invisible is exception\n(while stealthed this condition will skip)",
				SPELLISTARGETING = "SpellIsTargeting",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heroic Leap, Freezing Trap",
				LOOTFRAME = "LootFrame",
				EATORDRINK = "Is Eating or Drinking",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Hide display rotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Hides the group, which is usually at the\ncenter bottom of the screen",
				DISABLEBLACKBACKGROUND = "Hide black background", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Hides the black background in the upper left corner\nATTENTION: This can cause unpredictable behavior!",
				DISABLEPRINT = "Hide print",
				DISABLEPRINTTOOLTIP = "Hides chat notifications from everything\nATTENTION: This will also hide [Debug] Error Identification!",
				DISABLEMINIMAP = "Hide icon on minimap",
				DISABLEMINIMAPTOOLTIP = "Hides minimap icon of this UI",
				DISABLEPORTRAITS = "Hide class portrait",
				DISABLEROTATIONMODES = "Hide rotation modes",
				DISABLESOUNDS = "Disable sounds",
				CAMERAMAXFACTOR = "Camera max factor", 
				ROLETOOLTIP = "Depending on this mode, rotation will work\nAUTO - Defines your role depending on the majority of nested talents in the right tree",
				TOOLS = "Tools:",
				LETMECASTTOOLTIP = "Auto-dismount and Auto-stand\nIf a spellcast or interaction fails due to being mounted, you will dismount. If it fails due to you sitting down, you will stand up\nLet me cast!",
				TARGETCASTBAR = "Target CastBar",
				TARGETCASTBARTOOLTIP = "Shows a true cast bar under the target frame",
				TARGETREALHEALTH = "Target RealHealth",
				TARGETREALHEALTHTOOLTIP = "Shows a real health value on the target frame",
				TARGETPERCENTHEALTH = "Target PercentHealth",
				TARGETPERCENTHEALTHTOOLTIP = "Shows a percent health value on the target frame",
				AURADURATION = "Aura Duration",
				AURADURATIONTOOLTIP = "Shows duration value on default unit frames",
				AURACCPORTRAIT = "Aura CC Portrait",
				AURACCPORTRAITTOOLTIP = "Shows portrait of crowd control on the target frame",
				LOSSOFCONTROLPLAYERFRAME = "Loss Of Control: Player Frame",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Displays the duration of loss of control at the player portrait position",
				LOSSOFCONTROLROTATIONFRAME = "Loss Of Control: Rotation Frame",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Displays the duration of loss of control at the rotation portrait position (at the center)",
				LOSSOFCONTROLTYPES = "Loss Of Control: Display Triggers",				
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Queue",
				ENABLED = "Enabled",
				NAME = "Name",
				DESC = "Note",
				ICON = "Icon",
				SETBLOCKER = "Set\nBlocker",
				SETBLOCKERTOOLTIP = "This will block selected action in rotation\nIt will never use it\n\nRightClick: Create macro",
				SETQUEUE = "Set\nQueue",
				SETQUEUETOOLTIP = "This will queue action in rotation\nIt will use it as soon as it possible\n\nRightClick: Create macro\nYou can pass additional conditions in created macro for queue\nSuch as combo points (CP is key), example: { Priority = 1, CP = 5 }\nYou can find acceptable keys with description in the function 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blocked: |r",
				UNBLOCKED = "|cff00ff00Unblocked: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Queued Total: ",
				KEYTOOLTIP = "Use this key in MSG tab",
				ISFORBIDDENFORBLOCK = "is forbidden for blocker!",
				ISFORBIDDENFORQUEUE = "is forbidden for queue!",
				ISQUEUEDALREADY = "is already existing in queue!",
				QUEUED = "|cff00ff00Queued: |r",
				QUEUEREMOVED = "|cffff0000Removed from queue: |r",
				QUEUEPRIORITY = " has priority #",
				QUEUEBLOCKED = "|cffff0000can't be queued because SetBlocker blocked it!|r",
				SELECTIONERROR = "|cffff0000You didn't selected row!|r",
				AUTOHIDDEN = "AutoHide unavailable actions",
				AUTOHIDDENTOOLTIP = "Makes Scroll Table smaller and clear by visual hide\nFor example character class has few racials but can use one, this option will hide others racials\nJust for comfort view",
				LUAAPPLIED = "LUA code was applied to ",
				LUAREMOVED = "LUA was removed from ",
			},
			[4] = {
				HEADBUTTON = "Interrupts",	
				HEADTITLE = "Profile Interrupts",					
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				CONFIGPANEL = "'Add Interrupt' Configuration",
				INTERRUPTFRONTSTRINGTITLE = "Select list:",
				INTERRUPTTOOLTIP = "[Main] for units @target/@mouseover/@targettarget\n[Heal] for units @arena1-3 (healing)\n[PvP] for units @arena1-3 (crowdcontrol)\n\nYou can set different timings for [Heal] and [PvP] (not in this UI)",
				INPUTBOXTITLE = "Write spell:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): clear text and remove focus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Search by name or ID",
				TARGETMOUSEOVERLIST = "[Main] List",
				TARGETMOUSEOVERLISTTOOLTIP = "Unchecked: will interrupt ANY cast randomly\nChecked: will interrupt only specified custom list for @target/@mouseover/@targettarget\nNote: in PvP will fixed interrupt that list if enabled, otherwise only healers if they will die in less than 3-4 sec!\n\n@mouseover/@targettarget are optional and depend on toggles in spec tab\n\nRightClick: Create macro",
				KICKTARGETMOUSEOVER = "[Main] Interrupts\nEnabled",					
				KICKTARGETMOUSEOVERTOOLTIP = "Unchecked: @target/@mouseover unit interrupts don't work\nChecked: @target/@mouseover unit interrupts will work\n\nRightClick: Create macro",					
				KICKHEALONLYHEALER = "[Heal] Only healers",					
				KICKHEALONLYHEALERTOOLTIP = "Unchecked: list will valid for any enemy unit specialization\n(e.g. Ench, Elem, SP, Retri)\nChecked: list will valid only for enemy healers\n\nRightClick: Create macro",
				KICKHEAL = "[Heal] List",
				KICKHEALPRINT = "[Heal] List of Interrupts",
				KICKHEALTOOLTIP = "Unchecked: @arena1-3 [Heal] custom list don't work\nChecked: @arena1-3 [Heal] custom list will work\n\nRightClick: Create macro",
				KICKPVP = "[PvP] List",
				KICKPVPPRINT = "[PvP] List of Interrupts",
				KICKPVPTOOLTIP = "Unchecked: @arena1-3 [PvP] custom list don't work\nChecked: @arena1-3 [PvP] custom list will work\n\nRightClick: Create macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Checked: will interrupt only accordingly to logic established in profile lua configuration. Example:\n1) Chain control on your healer\n2) Someone friendly (or you) has Burst buffs >4 sec\n3) Someone will die in less than 8 sec\n4) Your (or @target) HP going to execute phase\nUnchecked: will interrupt this list always without any kind of logic\n\nNote: Cause high CPU demand\nRightClick: Create macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Add Interrupt",					
				ADDERROR = "|cffff0000You didn't specify anything in 'Write spell' or spell is not found!|r",
				ADDTOOLTIP = "Add spell from 'Write spell'\neditbox to current selected list",
				REMOVE = "Remove Interrupt",
				REMOVETOOLTIP = "Remove selected spell in scroll table row from the current list",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "Checkbox Configuration",
				USEDISPEL = "Use Dispel",
				USEPURGE = "Use Purge",
				USEEXPELENRAGE = "Expel Enrage",
				USEEXPELFRENZY = "Expel Frenzy",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Category:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel diseases",
				CURSE = "Dispel curses",
				MAGIC = "Dispel magic",
				MAGICMOVEMENT = "Dispel magic slow/roots",
				PURGEFRIENDLY = "Purge friendly",
				PURGEHIGH = "Purge enemy (high priority)",
				PURGELOW = "Purge enemy (low priority)",
				ENRAGE = "Expel Enrage",
				ROLE = "Role",
				ID = "ID",
				NAME = "Name",
				DURATION = "Duration\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icon",					
				ROLETOOLTIP = "Your role to use it",
				DURATIONTOOLTIP = "React on aura if the duration of the aura is longer (>) of the specified seconds\nIMPORTANT: Auras without duration such as 'Divine favor'\n(Light Paladin) must be 0. This means that the aura is present!",
				STACKSTOOLTIP = "React on aura if it has more or equal (>=) specified stacks",													
				CANSTEALORPURGE = "Only if can\nsteal or purge",					
				ONLYBEAR = "Only if unit\nin 'Bear form'",									
				CONFIGPANEL = "'Add Aura' Configuration",
				ANY = "Any",
				HEALER = "Healer",
				DAMAGER = "Tank|Damager",
				ADD = "Add Aura",					
				REMOVE = "Remove Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Mouse Interaction",
				USETITLE = "Buttons Config:",
				USELEFT = "Use Left click",
				USELEFTTOOLTIP = "This using macro /target mouseover which is not itself click!\n\nRightClick: Create macro",
				USERIGHT = "Use Right click",
				LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nIf you use LUA in Category 'GameToolTip' then thisunit is not valid\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need use Action. for anything that have it\n\nIf you want to remove already default code you will need write 'return true' without quotes instead of remove all",							
				BUTTON = "Click",
				NAME = "Name",
				LEFT = "Left click",
				RIGHT = "Right click",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "If enabled then will check @mouseover on type 'Totem' for given name\nAlso prevent click in situation if your @target already has there any totem",				
				INPUTTITLE = "Enter the name of the object (localized!)", 
				INPUT = "This entry is case non sensitive",
				ADD = "Add",
				REMOVE = "Remove",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "spirit link totem",
				HEALINGTIDETOTEM = "healing tide totem",
				CAPACITORTOTEM = "capacitor totem",					
				SKYFURYTOTEM = "skyfury totem",					
				ANCESTRALPROTECTIONTOTEM = "ancestral protection totem",					
				COUNTERSTRIKETOTEM = "counterstrike totem",
				-- Optional totems
				TREMORTOTEM = "tremor totem",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "wind rush totem",
				EARTHBINDTOTEM = "earthbind totem",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "horde battle standard",
				ALLIANCEBATTLESTANDARD = "alliance battle standard",
				-- GameToolTips
				ALLIANCEFLAG = "alliance flag",
				HORDEFLAG = "horde flag",
			},
			[7] = {
				HEADTITLE = "Message System",
				USETITLE = "",
				MSG = "MSG System",
				MSGTOOLTIP = "Checked: working\nUnchecked: not working\n\nRightClick: Create macro",
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Preventing by repeated message deletion from queue system\nE.g. possible spam macro without being removed\n\nRightClick: Create macro",
				MACRO = "Macro for your group:",
				MACROTOOLTIP = "This is what should be sent to the group chat to trigger the assigned action on the specified key\nTo address the action to a specific unit, add them to the macro or leave it as it is for the appointment in Single/AoE rotation\nSupported: raid1-40, party1-2, player, arena1-3\nONLY ONE UNIT FOR ONE MESSAGE!\n\nYour companions can use macros as well, but be careful, they must be loyal to this!\nDON'T LET THE MACRO TO UNIMINANCES AND PEOPLE NOT IN THE THEME!",
				KEY = "Key",
				KEYERROR = "You did not specify a key!",
				KEYERRORNOEXIST = "key does not exist!",
				KEYTOOLTIP = "You must specify a key to bind the action\nYou can extract the key in the 'Actions' tab",
				MATCHERROR = "this given name already matches, use another!",				
				SOURCE = "The name of the person who said",					
				WHOSAID = "Who said",
				SOURCETOOLTIP = "This is optional. You can leave it blank (recommended)\nIf you want to configure it, the name must be exactly the same as in the chat group",
				NAME = "Contains a message",
				ICON = "Icon",
				INPUT = "Enter a phrase for the system message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "You have not entered a phrase!",
				INPUTTOOLTIP = "The phrase will be triggered on any match in the group chat (/party)\nIt's not case sensitive\nContains patterns, this means that a phrase written by someone with the combination of the words raid, party, arena, party or player\nadaptates the action to the desired meta slot\nYou don’t need to set the listed patterns here, they are used as an addition to the macro\nIf the pattern is not found, then slots for Single and AoE rotations will be used",				
			},
		},
	},
	ruRU = {
		NOSUPPORT = "данный профиль еще не поддерживает ActionUI",
		DEBUG = "|cffff0000[Debug] Идентификатор ошибки: |r",			
		ISNOTFOUND = "не найдено!",				
		CREATED = "создан",
		YES = "Да",
		NO = "Нет",	
		TOGGLEIT = "Переключить",
		SELECTED = "Выбрано",
		RESET = "Сброс",
		RESETED = "Сброшено",
		MACRO = "Макрос",
		MACROEXISTED = "|cffff0000Макрос уже существует!|r",
		MACROLIMIT = "|cffff0000Не удается создать макрос, вы достигли лимита. Удалите хотя бы один макрос!|r",
		GLOBALAPI = "API Глобальное: ",	
		RESIZE = "Изменить размер",
		RESIZE_TOOLTIP = "Чтобы изменить размер, нажмите и тащите ",	
		SLASH = {
			LIST = "Список слеш команд:",
			OPENCONFIGMENU = "открыть конфиг меню",
			HELP = "помощь и информация",
			QUEUEHOWTO = "макрос (переключатель) для системы очередности (Очередь), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			QUEUEEXAMPLE = "пример использования Очереди",
			BLOCKHOWTO = "макрос (переключатель) для отключения|включения любых действий (Блокировка), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			BLOCKEXAMPLE = "пример использования Блокировки",
			RIGHTCLICKGUIDANCE = "Большинство элементов кликабельны левой и правой кнопкой мышки. Правая кнопка мышки создаст макрос, так что вы можете не брать во внимание выше изложенную подсказку",						
			INTERFACEGUIDANCE = "UI пояснения:",
			INTERFACEGUIDANCEGLOBAL = "[Глобально] относится к ВСЕМУ вашему аккаунту, к ВСЕМ персонажам, к ВСЕМ специализациям",	
			TOTOGGLEBURST = "чтобы переключить Режим Бурстов",
			TOTOGGLEMODE = "чтобы переключить PvP / PvE",
			TOTOGGLEAOE = "чтобы переключить AoE",
		},
		TAB = {
			RESETBUTTON = "Сбросить настройки",
			RESETQUESTION = "Вы точно уверены?",
			SAVEACTIONS = "Сохранить настройки Действий",
			SAVEINTERRUPT = "Сохранить Списки Прерываний",
			SAVEDISPEL = "Сохранить Списки Аур",
			SAVEMOUSE = "Сохранить Списки Курсора",
			SAVEMSG = "Сохранить Списки MSG",
			LUAWINDOW = "LUA Конфигурация",
			LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true' без кавычек,\nвместо простого удаления",	
			BRACKETMATCH = "Закрывать Скобки",
			CLOSELUABEFOREADD = "Закройте LUA Конфигурацию прежде чем добавлять",
			FIXLUABEFOREADD = "Исправьте ошибки в LUA Конфигурации прежде чем добавлять",
			RIGHTCLICKCREATEMACRO = "Правая кнопка мышки: Создать макрос",
			NOTHING = "Профиль не имеет конфигурации для этой вкладки",
			HOW = "Применить:",
			HOWTOOLTIP = "Глобально: Весь аккаунт, все персонажи и все спеки",
			GLOBAL = "Глобально",
			ALLSPECS = "Ко всем специализациям персонажа",
			THISSPEC = "К текущей специализации персонажа",			
			KEY = "Ключ:",	
			CONFIGPANEL = "'Добавить' Конфигурация",
			[1] = {
				HEADBUTTON = "Общее",
				HEADTITLE = "Основное",					
				PVEPVPTOGGLE = "PvE / PvP Ручной Переключатель",
				PVEPVPTOGGLETOOLTIP = "Принудительно переключить профиль в другой режим\n(особенно полезно при включенном Режиме Войны)\n\nПравая кнопка мышки: Создать макрос", 
				PVEPVPRESETTOOLTIP = "Сброс ручного переключателя в автоматический выбор",
				CHANGELANGUAGE = "Смена языка",
				CHARACTERSECTION = "Секция Персонажа",
				AUTOTARGET = "Авто Цель",
				AUTOTARGETTOOLTIP = "Если цель пуста, но вы в бою, то вернет ближайшего противника в цель\nАналогично работает свитчер если в PvP цель имеет иммунитет\n\nПравая кнопка мышки: Создать макрос",					
				POTION = "Зелье",
				RACIAL = "Расовая способность",
				STOPCAST = "Стоп кастить",
				SYSTEMSECTION = "Секция Систем",
				LOSSYSTEM = "LOS Система",
				LOSSYSTEMTOOLTIP = "ВНИМАНИЕ: Эта опция вызывает задержку 0.3сек + тек. крутящийся гкд\nесли проверяемый юнит находится в лосе (например за столбом на арене)\nВы также должны включить такую же настройку в Advanced Settings\nДанная опция заносит в черный список проверяемого юнита\nи перестает на N секунд предоставлять к нему действия если юнит в лосе\n\nПравая кнопка мышки: Создать макрос",
				HEALINGENGINEPETS = "HealingEngine питомцы",
				HEALINGENGINEPETSTOOLTIP = "Включить в выбор цели питомцев игроков и калькулировать исцеление на них\n\nПравая кнопка мышки: Создать макрос",
				HEALINGENGINEANYROLE = "HealingEngine любая роль",
				HEALINGENGINEANYROLETOOLTIP = "Позволяет использовать выбор цели на любую вашу роль",
				ALL = "Все",
				RAID = "Рейд",
				TANK = "Только Танки",
				DAMAGER = "Только Дамагеры",
				HEALER = "Только Хилеры",			
				TANKANDPARTY = "Танки и Группа",
				PARTY = "Группа",	
				HEALINGENGINETOOLTIP = "Эта опция отвечает за выбор участников группы или рейда если вы играете хилером\nВсе: Каждый участник\nРейд: Каждый участник исключая танков\n\nПравая кнопка мышки: Создать макрос\nЕсли вы предпочитаете фиксированное состояние, то используйте аргумент (АРГУМЕНТ): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "DBM Таймеры",
				DBMTOOLTIP = "Отслеживает пулл таймер и некоторые спец. события такие как 'след.треш'.\nЭта опция доступна не для всех профилей!\n\nПравая кнопка мышки: Создать макрос",
				FPS = "FPS Оптимизация",
				FPSSEC = " (сек)",
				FPSTOOLTIP = "AUTO: Повышение кадров в секунду за счет увеличения в динамической зависимости\nкадров интервала обновления (вызова) цикла ротации\n\nВы также можете вручную задать интервал следуя простому правилу:\nЧем больше ползунок, тем больше кадров, но хуже обновление ротации\nСлишком высокое значение может вызвать непредсказуемое поведение!\n\nПравая кнопка мышки: Создать макрос",					
				PVPSECTION = "Секция PvP",
				RETARGET = "Возвращать предыдущий сохраненный @target (arena1-3 юниты только)\nРекомендуется против Охотников с 'Притвориться мертвым'\nи(или) при любых непредвиденных сбросов цели\n\nПравая кнопка мышки: Создать макрос",
				TRINKETS = "Аксессуары",
				TRINKET = "Аксессуар",
				BURST = "Режим Бурстов",
				BURSTTOOLTIP = "Everything - По доступности способности\nAuto - Босс или Игрок\nOff - Выключено\n\nПравая кнопка мышки: Создать макрос\nЕсли вы предпочитаете фиксированное состояние, то\nиспользуйте аргумент (АРГУМЕНТ): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Камень здоровья | Зелье исцеления",
				HEALTHSTONETOOLTIP = "Выставить процент своего здоровья при котором использовать\nЗелье исцеления зависит от вашей вкладки настроек класса для Зелья\nи от того, отображаются ли эти зелья во вкладке Действия\nКамень здоровья имеет общее время восстановления с Зельем исцеления\n\nПравая кнопка мышки: Создать макрос",
				STOPATBREAKABLE = "Стоп урон на ломающемся контроле",
				STOPATBREAKABLETOOLTIP = "Остановит вредоносный урон по врагам\nЕсли у них есть CC, например, Превращение\nЭто не отменяет автоатаку!\n\nПравая кнопка мышки: Создать макрос",
				AUTOATTACK = "Авто Атака",
				AUTOSHOOT = "Авто Выстрел",	
				PAUSECHECKS = "Ротация не работает если:",
				DEADOFGHOSTPLAYER = "Вы мертвы",
				DEADOFGHOSTTARGET = "Цель мертва",
				DEADOFGHOSTTARGETTOOLTIP = "Исключение вражеский Охотник если выбран в качестве цели",
				MOUNT = "Вы на\nтранспорте",
				COMBAT = "Не в бою", 
				COMBATTOOLTIP = "Если Вы и Ваша цель не в бою. Исключение незаметность\n(будучи в скрытости это условие не работает)",
				SPELLISTARGETING = "Курсор ожидает клик",
				SPELLISTARGETINGTOOLTIP = "Например: Снежная Буря, Героический прыжок, Замораживающая ловушка",
				LOOTFRAME = "Открыто окно добычи\n(лута)",		
				EATORDRINK = "Вы Пьете или Едите",
				MISC = "Разное:",
				DISABLEROTATIONDISPLAY = "Скрыть отображение\nротации",
				DISABLEROTATIONDISPLAYTOOLTIP = "Скрывает группу, которая обычно в\nцентральной нижней части экрана",
				DISABLEBLACKBACKGROUND = "Скрыть черный фон", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Скрывает черный фон в левом верхнем углу\nВНИМАНИЕ: Это может вызвать непредсказуемое поведение!",
				DISABLEPRINT = "Скрыть печать",
				DISABLEPRINTTOOLTIP = "Скрывает уведомления этого UI в чате\nВНИМАНИЕ: Это также скрывает [Debug] Идентификатор ошибки!",
				DISABLEMINIMAP = "Скрыть значок на миникарте",
				DISABLEMINIMAPTOOLTIP = "Скрывает значок этого UI",
				DISABLEPORTRAITS = "Скрыть классовый портрет",
				DISABLEROTATIONMODES = "Скрыть режимы ротации",
				DISABLESOUNDS = "Отключить звуки",
				CAMERAMAXFACTOR = "Макс. отдаление камеры", 
				ROLETOOLTIP = "В зависимости от этого режима будет работать ротация\nAUTO - Определяет вашу роль в зависимости от большинства вложенных талантов в нужное дерево",
				TOOLS = "Утилиты:",
				LETMECASTTOOLTIP = "Авто-спешивание и Авто-встать\nЕсли произнесение или взаимодействие невозможно из-за транспорта, то вы будете спешены\nЕсли это невозможно пока вы сидите, то вы встанете\nLet me cast - Позволь мне произнести!",
				TARGETCASTBAR = "Бар произнесения цели",
				TARGETCASTBARTOOLTIP = "Отображает правдивый ползунок произнесения заклинания под фреймом цели",
				TARGETREALHEALTH = "Реальное здоровье цели",
				TARGETREALHEALTHTOOLTIP = "Показывает цифровое значение здоровья на фрейме цели",
				TARGETPERCENTHEALTH = "Процентное здоровье цели",
				TARGETPERCENTHEALTHTOOLTIP = "Показывает процентное здоровье на фрейме цели",
				AURADURATION = "Продолжительность аур",
				AURADURATIONTOOLTIP = "Показывает продолжительность значений аур на по умолчанию фреймах целей",
				AURACCPORTRAIT = "Портрет СС ауры",
				AURACCPORTRAITTOOLTIP = "Показывает портрет ауры цепочки контроля на фрейме цели",
				LOSSOFCONTROLPLAYERFRAME = "Потеря контроля: Рамка игрока",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Отображает продолжительность потери контроля на портрете игрока",
				LOSSOFCONTROLROTATIONFRAME = "Потеря контроля: Рамка ротации",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Отображает продолжительность потери контроля на портрете ротации (по центру)",
				LOSSOFCONTROLTYPES = "Потеря контроля: Отображение Триггеров",	
			},			
			[3] = {
				HEADBUTTON = "Действия",
				HEADTITLE = "Блокировка | Очередь",
				ENABLED = "Включено",
				NAME = "Название",
				DESC = "Заметка",
				ICON = "Значок",
				SETBLOCKER = "Установить\nБлокировку",
				SETBLOCKERTOOLTIP = "Это заблокирует выбранное действие в ротации\nЭто никогда не будет использовано\n\nПравая кнопка мыши: Создать макрос", 
				SETQUEUE = "Установить\nОчередь",
				SETQUEUETOOLTIP = "Это поставит действие в очередь ротации\nЭто использует действие по первой доступности\n\nПравая кнопка мыши: Создать макрос\nВы можете добавить дополнительные условия в созданном макросе для очереди\nТакие как длина серии приемов (CP является ключом), например: {Priority = 1, CP = 5}\nВы можете найти доступные ключи с описанием в функции 'Action:SetQueue' (Action.lua)", 
				BLOCKED = "|cffff0000Заблокировано: |r",
				UNBLOCKED = "|cff00ff00Разблокировано: |r",
				KEY = "[Ключ: ",
				KEYTOTAL = "[Суммарно Очереди: ",
				KEYTOOLTIP = "Используйте этот ключ во вкладке MSG",
				ISFORBIDDENFORBLOCK = "запрещен для установки в блокировку!",
				ISFORBIDDENFORQUEUE = "запрещен для установки в очередь!",
				ISQUEUEDALREADY = "уже в состоит в очереди!",
				QUEUED = "|cff00ff00Установлен в очередь: |r",
				QUEUEREMOVED = "|cffff0000Удален из очереди: |r",
				QUEUEPRIORITY = " имеет приоритет #",
				QUEUEBLOCKED = "|cffff0000не может быть поставлен в очередь поскольку установлена блокировка!|r",
				SELECTIONERROR = "|cffff0000Вы не выбрали строку!|r",
				AUTOHIDDEN = "АвтоСкрытие недоступных действий",
				AUTOHIDDENTOOLTIP = "Делает прокручивающейся список меньше и чистее за счет визуального скрытия\nНапример, класс персонажа имеет несколько расовых способностей, но может использовать лишь одну, эта опция скроет остальные\nПросто для удобства просмотра",
				LUAAPPLIED = "LUA код был добавлен к ",
				LUAREMOVED = "LUA код был удален из ",
			},
			[4] = {
				HEADBUTTON = "Прерывания",	
				HEADTITLE = "Прерывания Профиля",					
				ID = "ID",
				NAME = "Название",
				ICON = "Значок",
				CONFIGPANEL = "'Добавить Прерывание' Конфигурация",
				INTERRUPTFRONTSTRINGTITLE = "Выберите список:",	
				INTERRUPTTOOLTIP = "[Main] для @target/@mouseover/@targettarget\n[Heal] для @arena1-3 (исцеляющие)\n[PvP] для @arena1-3 (контроль)\n\nВы можете выставить тайминги для [Heal] и [PvP] (не в этом UI)",
				INPUTBOXTITLE = "Введите способность:",
				INPUTBOXTOOLTIP = "ESCAPE (ESC): стереть текст и убрать фокус ввода",
				SEARCH = "Поиск по имени или ID",
				INTEGERERROR = "Целочисленное переполнение при попытке ввода > 7 чисел", 
				TARGETMOUSEOVERLIST = "[Main] Список",
				TARGETMOUSEOVERLISTTOOLTIP = "НЕ включено: будет прерывать ЛЮБОЙ каст случайно\nВключено: будет прерывать только из этого списка для @target/@mouseover/@targettarget\nПримечание: в PvP принудительно будет прерывать этот список если включено, или только хилеров за 3-4 сек до смерти!\n\n@mouseover/@targettarget являются опциональными и зависят от переключателей во вкладке специализации\n\nПравая кнопка мыши: Создать макрос",					
				KICKTARGETMOUSEOVER = "[Main] Прерывания\nвключены",					
				KICKTARGETMOUSEOVERTOOLTIP = "НЕ включено: @target/@mouseover/@targetarget юнит прерывания не работают\nВключено: @target/@mouseover/@targettarget юнит прерывания будут работать\n\nПравая кнопка мыши: Создать макрос",					
				KICKHEALONLYHEALER = "[Heal] Только\nлекарей",				
				KICKHEALONLYHEALERTOOLTIP = "НЕ включено: список будет валидным для любых специализаций вражеского юнита\nНапример: Энх, Элем, Ретрик, ШП\nВключено: список будет валидным только для вражеских хилеров\n\nПравая кнопка мыши: Создать макрос",
				KICKHEAL = "[Heal] Список",
				KICKHEALPRINT = "[Heal] Список Прерываний",
				KICKHEALTOOLTIP = "НЕ включено: @arena1-3 [Heal] список не работает\nВключено: @arena1-3 [Heal] список будет работать\n\nПравая кнопка мыши: Создать макрос",						
				KICKPVP = "[PvP] Список",
				KICKPVPPRINT = "[PvP] Список Прерываний",
				KICKPVPTOOLTIP = "НЕ включено: @arena1-3 [PvP] список не работает\nВключено: @arena1-3 [PvP] список будет работать\n\nПравая кнопка мыши: Создать макрос",	
				KICKPVPONLYSMART = "[PvP] УМНЫЙ",					
				KICKPVPONLYSMARTTOOLTIP = "Включено: будет прерывать только по логике заложенной в профиле на lua конфигурации. Например:\n1) Цепочку контроля по своему лекарю\n2) Кто-либо из союзников в бурстах >4 сек\n3) Кто-либо из союзников может умереть меньше чем за 8 сек\n4) Вы (или @target) здоровье близко к смертельной фазе\nНЕ включено: будет прерывать этот список всегда без какой либо логики\n\nЗаметка: Вызывает высокое потребление CPU\nПравая кнопка мыши: Создать макрос",					
				USEKICK = "Киком",
				USECC = "СС",
				USERACIAL = "Расовой",
				ADD = "Добавить Прерывание",
				ADDERROR = "|cffff0000Вы ничего не указали в 'Введите способность'\nили способность не найдена!|r",				
				ADDTOOLTIP = "Добавить способность из поля ввода 'Введите способность' в текущий выбранный список",					
				REMOVE = "Удалить Прерывание",
				REMOVETOOLTIP = "Удалить выбранную способность в прокручивающейся таблице из текущего списка",					
			},
			[5] = { 
				HEADBUTTON = "Ауры",					
				USETITLE = "Конфигурация чекбоксов",
				USEDISPEL = "Использовать Диспел",
				USEPURGE = "Использовать Пурж",
				USEEXPELENRAGE = "Снимать Исступления",
				USEEXPELFRENZY = "Снимать Бешенство",
				HEADTITLE = "[Глобально] Диспел | Пурж | Исступление",	
				MODE = "Режим:",
				CATEGORY = "Категория:",
				POISON = "Диспел ядов",
				DISEASE = "Диспел болезней",
				CURSE = "Диспел проклятий",
				MAGIC = "Диспел магического",
				MAGICMOVEMENT = "Диспел магич. замедлений/рут",
				PURGEFRIENDLY = "Пурж союзников",
				PURGEHIGH = "Пурж врагов (высокий приоритет)",
				PURGELOW = "Пурж врагов (низкий приоритет)",
				ENRAGE = "Снятие исступлений",
				ROLE = "Роль",
				ID = "ID",
				NAME = "Название",
				DURATION = "Длитель-\nность >",
				STACKS = "Стаки\n >=",
				ICON = "Значок",
				ROLETOOLTIP = "Ваша роль для использования этого",
				DURATIONTOOLTIP = "Реагировать если продолжительность ауры больше (>) указанных секунд\nВНИМАНИЕ: Ауры без продолжительности такие как 'Божественное одобрение'\n(Свет Паладин) должны быть 0. Это значит аура присутствует!",
				STACKSTOOLTIP = "Реагировать если кол-во ауры (стаки) больше (>=) указанных",								
				CANSTEALORPURGE = "Только если можно\nукрасть или спуржить",					
				ONLYBEAR = "Только если юнит\nв 'Облике медведя'",									
				CONFIGPANEL = "'Добавить Ауру' Конфигурация",
				ANY = "Любая",
				HEALER = "Лекарь",
				DAMAGER = "Танк|Урон",
				ADD = "Добавить Ауру",					
				REMOVE = "Удалить Ауру",				
			},				
			[6] = {
				HEADBUTTON = "Курсор",
				HEADTITLE = "Взаимодействие Мышки",		
				USETITLE = "Конфигурация кнопок:",
				USELEFT = "Использовать Левый щелчок",
				USELEFTTOOLTIP = "Используется макрос /target mouseover это не является самим щелчком!\n\nПравая кнопка мыши: Создать макрос",
				USERIGHT = "Использовать Правый щелчок",
				LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nЕсли вы используете LUA в категории 'GameToolTip' тогда thisunit не имеет никакого значения\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true'без кавычек,\nвместо простого удаления",														
				BUTTON = "Щелчок",
				NAME = "Название",
				LEFT = "Левый щелчок",
				RIGHT = "Правый щелчок",
				ISTOTEM = "Является тотемом",
				ISTOTEMTOOLTIP = "Если включено, то будет проверять @mouseover на тип 'Тотем' для данного имени\nТакже предотвращает клик в случае если в @target уже есть какой-либо тотем",
				INPUTTITLE = "Введите название объекта (на русском!)", 
				INPUT = "Этот ввод является не чувствительным к регистру",
				ADD = "Добавить",
				REMOVE = "Удалить",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "тотем духовной связи",
				HEALINGTIDETOTEM = "тотем целительного прилива",
				CAPACITORTOTEM = "тотем конденсации",					
				SKYFURYTOTEM = "тотем небесной ярости",					
				ANCESTRALPROTECTIONTOTEM = "тотем защиты предков",					
				COUNTERSTRIKETOTEM = "тотем контрудара",
				-- Optional totems
				TREMORTOTEM = "тотем трепета",
				GROUNDINGTOTEM = "тотем заземления",
				WINDRUSHTOTEM = "тотем ветряного порыва",
				EARTHBINDTOTEM = "тотем оков земли",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "боевой штандарт орды",
				ALLIANCEBATTLESTANDARD = "боевой штандарт альянса",
				-- GameToolTips
				ALLIANCEFLAG = "флаг альянса",
				HORDEFLAG = "флаг орды",
			},
			[7] = {
				HEADTITLE = "Система Сообщений",
				USETITLE = "[Каждый спек]",
				MSG = "MSG Система",				
				MSGTOOLTIP = "Включено: работает\nНЕ включено: не работает\n\nПравая кнопка мыши: Создать макрос",
				DISABLERETOGGLE = "Блокировать снятие очереди",
				DISABLERETOGGLETOOLTIP = "Предотвращает повторным сообщением удаление из системы очереди\nИными словами позволяет спамить макрос без риска быть снятым\n\nПравая кнопка мыши: Создать макрос",
				MACRO = "Макрос для вашей группы:",
				MACROTOOLTIP = "Это то, что должно посылаться в чат группы для срабатывания назначенного действия по заданному ключу\nЧтобы адресовать действие к конкретному юниту допишите их в макрос или оставьте как есть для назначения в Single/AoE ротацию\nПоддерживаются: raid1-40, party1-2, player, arena1-3\nТОЛЬКО ОДИН ЮНИТ ЗА ОДНО СООБЩЕНИЕ!\n\nВаши напарники могут использовать макрос также, но осторожно, они должны быть лояльны к этому!\nНЕ ДАВАЙТЕ МАКРОС НЕЗНАКОМЦАМ И ЛЮДЯМ НЕ В ТЕМЕ!",
				KEY = "Ключ",
				KEYERROR = "Вы не указали ключ!",
				KEYERRORNOEXIST = "ключ не существует!",
				KEYTOOLTIP = "Вы должны указать ключ, чтобы привязать действие\nВы можете извлечь ключ во вкладке 'Действия'",
				MATCHERROR = "данное имя уже совпадает, используйте другое!",
				SOURCE = "Имя сказавшего",	
				WHOSAID = "Кто сказал",
				SOURCETOOLTIP = "Это опционально. Вы можете оставить это пустым (рекомендуется)\nВ случае если вы хотите настроить это, то имя должно быть точно таким же как в группе чата",
				NAME = "Содержит в сообщении",
				ICON = "Значок",
				INPUT = "Введите фразу для системы сообщений",
				INPUTTITLE = "Фраза",
				INPUTERROR = "Вы не ввели фразу!",
				INPUTTOOLTIP = "Фраза будет срабатывать на любое совпадение в чате группы (/party)\nЯвляется не чувствительным к регистру\nСодержит патерны, это означает, что сказанная кем-то фраза с комбинацией слов raid, party, arena, party или player\nпереназначит действие на нужный мета слот\nВам не нужно задавать перечисленные патерны здесь, они используются как приписка к макросу\nЕсли патерн не найден, то будут использоваться слоты для Single и AoE ротаций",
			},
		},
	},
	deDE = {			
		NOSUPPORT = "das Profil wird bisher nicht unterstützt",	
		DEBUG = "|cffff0000[Debug] Identifikationsfehler: |r",			
		ISNOTFOUND = "nicht gefunden!",			
		CREATED = "erstellt",
		YES = "Ja",
		NO = "Nein",
		TOGGLEIT = "Wechsel",
		SELECTED = "Ausgewählt",
		RESET = "Zurücksetzen",
		RESETED = "Zurückgesetzt",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro bereits vorhanden!|r",
		MACROLIMIT = "|cffff0000Makrolimit erreicht, lösche vorher eins!|r",	
		GLOBALAPI = "API Global: ",
		RESIZE = "Größe ändern",
		RESIZE_TOOLTIP = "Click-und-bewege um die Größe zu ändern",
		SLASH = {
			LIST = "Liste der Slash-Befehle:",
			OPENCONFIGMENU = "Menü Öffnen",
			HELP = "Zeigt dir die Hilfe an",
			QUEUEHOWTO = "Makro (Toggle) für Sequenzsystem (Queue), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			QUEUEEXAMPLE = "Beispiel für das Sequenzsystem",
			BLOCKHOWTO = "Makro (Umschalten) zum Deaktivieren | Aktivieren beliebiger Aktionen (Blocker), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			BLOCKEXAMPLE = "Beispiel zum Deaktivierungssystem",
			RIGHTCLICKGUIDANCE = "Die meisten Elemente können mit der linken und rechten Maustaste angeklickt werden. Durch Klicken mit der rechten Maustaste wird ein Makrowechsel erstellt, sodass Sie sich nicht um das obige Hilfehandbuch kümmern müssen",				
			INTERFACEGUIDANCE = "UI erklrüngen7:",
			INTERFACEGUIDANCEGLOBAL = "[Global] Spezifiziert für alle auf deinem Account, Alle Charaktere, Alle Skillungen",
			TOTOGGLEBURST = "um den Burst-Modus umzuschalten",
			TOTOGGLEMODE = "PvP / PvE umschalten",
			TOTOGGLEAOE = "um AoE umzuschalten",			
		},
		TAB = {
			RESETBUTTON = "Einstellungen zurücksetzten",
			RESETQUESTION = "Bist du dir SICHER?",
			SAVEACTIONS = "Einstellungen Speichern",
			SAVEINTERRUPT = "Speicher Unterbrechungsliste",
			SAVEDISPEL = "Speicher Auraliste",
			SAVEMOUSE = "Speicher Cursorliste",
			SAVEMSG = "Speicher Nachrichtrenliste",
			LUAWINDOW = "LUA Einstellung",
			LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nCode muss einen booleschen Rückgabewert (true) haben, um Bedingungen zu verarbeiten\nDieser Code hat setfenv, was bedeutet, dass Sie Action. nicht benötigen. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Vor dem Adden LUA Konfiguration schließen!",
			FIXLUABEFOREADD = "LUA Fehler beheben bevor du es hinzufügst",
			RIGHTCLICKCREATEMACRO = "Rechtsklick: Erstelle macro",
			NOTHING = "Keine Konfiguration für das Profil",
			HOW = "Bestätigen:",
			HOWTOOLTIP = "Global: Alle Accounrs, alle Charaktere und alle Skillungen",
			GLOBAL = "Global",
			ALLSPECS = "Für alle Skillungen auf diesen Charakter",
			THISSPEC = "Für die jetzige Skillung auf dem Charakter",			
			KEY = "Schlüssel:",
			CONFIGPANEL = "Konfiguration Hinzufügen",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "Primär",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Erzwingen, dass ein Profil in einen anderen Modus wechselt\n(besonders nützlich, wenn der Kriegsmodus aktiviert ist)\n\nRechtsklick: Makro erstellen", 
				PVEPVPRESETTOOLTIP = "Manuelle Umschaltung auf automatische Auswahl zurücksetzen",
				CHANGELANGUAGE = "Sprache wechseln",
				CHARACTERSECTION = "Character Fenster",
				AUTOTARGET = "Automatisches Ziel",
				AUTOTARGETTOOLTIP = "Wenn kein Ziel vorhanden, Sie sich jedoch in einem Kampf befinden, wird der nächste Feind ausgewählt.\nDer Umschalter funktioniert auf die gleiche Weise, wenn das Ziel Immunität gegen PvP hat.\n\nRechtsklick: Makro erstellen",					
				POTION = "Potion",
				RACIAL = "Rassenfähigkeit",
				STOPCAST = "Hör auf zu gießen",
				SYSTEMSECTION = "Systemmenu",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ACHTUNG: Diese Option führt zu einer Verzögerung von 0,3 s + der aktuellen Spinning-GCD.\nwenn überprüft wird, ob sich die Einheit in Sichtweite befindet (z. B. hinter einer Box in der Arena).\nDiese Option muss auch in den erweiterten Einstellungen aktiviert werden a lose und\nunterbricht die Bereitstellung von Aktionen für N Sekunden\n\nRechtsklick: Makro erstellen",
				HEALINGENGINEPETS = "Heileinstellung für Begleiter",
				HEALINGENGINEPETSTOOLTIP = "Füge die Begleiter des ausgewählten Spielers zum Ziel hinzu und berechne sie, um sie zu heilen.\n\nRechtsklick: Makro erstellen",
				HEALINGENGINEANYROLE = "HealingEngine irgendeine Rolle",
				HEALINGENGINEANYROLETOOLTIP = "Aktivieren Sie diese Option, um das Mitglieder-Targeting für jede Ihrer Rollen zu verwenden",
				STOPATBREAKABLE = "Stoppt den Schaden bei Zerbrechlichkeit",
				STOPATBREAKABLETOOLTIP = "Verhindert schädlichen Schaden bei Feinden\nWenn sie CC wie Polymorph haben\nDer automatische Angriff wird nicht abgebrochen!\n\nRechtsklick: Makro erstellen",
				ALL = "Alle",
				RAID = "Raid",
				TANK = "Nur Tanks",
				DAMAGER = "Nur Damagers",
				HEALER = "Nur Healers",
				TANKANDPARTY = "Tanks und Party",
				PARTY = "Party",
				HEALINGENGINETOOLTIP = "Diese Option bezieht sich auf die Einheitenauswahl bei Heilern.\nAlle: Alle Mitglieder\nGezahlt: Alle Mitglieder ohne Tanks\n\nRechtsklick: Makro erstellen\nWenn Sie das Argument für die Verwendung des Status zum Festlegen des Umschaltens in (ARG) festlegen möchten: 'ALL', 'RAID'. , 'TANK', 'HEILER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "DBM Timers",
				DBMTOOLTIP = "Verfolgen von Pull-Timern und bestimmten Ereignissen, z. B. eingehendem Thrash.\nDiese Funktion ist nicht für alle Profile verfügbar!\n\nKlicken mit der rechten Maustaste: Makro erstellen",
				FPS = "FPS Optimierungen",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Erhöht die Frames pro Sekunde durch Erhöhen der dynamischen Abhängigkeit.\nFrames des Aktualisierungszyklus (Aufruf) des Rotationszyklus\n\nSie können das Intervall auch nach einer einfachen Regel manuell einstellen:\nDer größere Schieberegler als mehr FPS, aber schlechtere Rotation Update\nZu hoher Wert kann zu unvorhersehbarem Verhalten führen!\n\nRechtsklick: Makro erstellen",					
				PVPSECTION = "PvP Einstellungen",
				RETARGET = "Vorheriges gespeichertes @Ziel zurückgeben\n(nur Arena1-3-Einheiten)\nEs wird gegen Jäger mit 'Totstellen' und unvorhergesehenen Zielabwürfen empfohlen\n\nRechtsklick: Makro erstellen",
				TRINKETS = "Schmuckstücke",
				TRINKET = "Schmuck",
				BURST = "Burst Modus",
				BURSTTOOLTIP = "Alles - Auf Abklingzeit\nAuto - Boss oder Spieler\nAus - Deaktiviert\nRechtsklick: Makro erstellen\nWenn Sie einen festen Umschaltstatus festlegen möchten, verwenden Sie das Argument in (ARG): 'Alles', 'Auto', 'Aus'",					
				HEALTHSTONE = "Gesundheitsstein | Heiltrank",
				HEALTHSTONETOOLTIP = "Wann der GeSu benutzt werden soll!\nDer Heiltrank hängt von der Registerkarte der Klasseneinstellungen für Trank\nab und davon, ob diese Tränke auf der Registerkarte Aktionen angezeigt werden\nGesundheitsstein hat die Abklingzeit mit Heiltrank geteilt\n\nRechtsklick: Makro erstellen",
				AUTOATTACK = "Automatischer Angriff",
				AUTOSHOOT = "Automatisches Schießen",	
				PAUSECHECKS = "Rota funktioniert nicht wenn:",
				DEADOFGHOSTPLAYER = "Wenn du Tot bist",
				DEADOFGHOSTTARGET = "Das Ziel Tot ist",
				DEADOFGHOSTTARGETTOOLTIP = "Ausnahme feindlicher Jäger, wenn er als Hauptziel ausgewählt ist",
				MOUNT = "Aufgemounted",
				COMBAT = "Nicht im Kampf", 
				COMBATTOOLTIP = "Wenn Sie und Ihr Ziel außerhalb des Kampfes sind. Unsichtbar ist eine Ausnahme.\n(Wenn diese Bedingung getarnt ist, wird sie übersprungen.)",
				SPELLISTARGETING = "Fähigkeit dich im Ziel hat",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heldenhafter Sprung, Eiskältefalle",
				LOOTFRAME = "Beutefenster",
				EATORDRINK = "Isst oder trinkt",
				MISC = "Verschiedenes:",		
				DISABLEROTATIONDISPLAY = "Verstecke Rotationsanzeige",
				DISABLEROTATIONDISPLAYTOOLTIP = "Blendet die Gruppe aus, die sich normalerweise im unteren Bereich des Bildschirms befindet",
				DISABLEBLACKBACKGROUND = "Verstecke den schwarzen Hintergrund", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Verbirgt den schwarzen Hintergrund in der oberen linken Ecke.\nACHTUNG: Dies kann zu unvorhersehbarem Verhalten führen!",
				DISABLEPRINT = "Verstecke Text",
				DISABLEPRINTTOOLTIP = "Verbirgt Chat-Benachrichtigungen vor allem\nACHTUNG: Dadurch wird auch die [Debug] -Fehleridentifikation ausgeblendet!",
				DISABLEMINIMAP = "Verstecke Minimap Symbol",
				DISABLEMINIMAPTOOLTIP = "Blendet das Minikartensymbol dieser Benutzeroberfläche aus",
				DISABLEPORTRAITS = "Klassenporträt ausblenden",
				DISABLEROTATIONMODES = "Drehmodi ausblenden",
				DISABLESOUNDS = "Sounds deaktivieren",
				CAMERAMAXFACTOR = "Kameramaximalfaktor", 
				ROLETOOLTIP = "Abhängig von diesem Modus funktioniert die Drehung\nAUTO - Definiert Ihre Rolle in Abhängigkeit von der Mehrheit der verschachtelten Talente im rechten Baum",
				TOOLS = "Werkzeuge: ",				
				LETMECASTTOOLTIP = "Auto-Dismount und Auto-Stand\nWenn ein Zauber oder eine Interaktion aufgrund eines Reitens fehlschlägt, werden Sie aussteigen. Wenn es fehlschlägt, weil Sie sitzen, werden Sie aufstehen\nLet Me Cast - Lass mich werfen!",
				TARGETCASTBAR = "Ziel-Cast-Leiste",
				TARGETCASTBARTOOLTIP = "Zeigt eine echte Zauberleiste unter dem Zielrahmen an",
				TARGETREALHEALTH = "Echte Gesundheit anvisieren",
				TARGETREALHEALTHTOOLTIP = "Zeigt einen realen Gesundheitswert auf dem Zielframe an",
				TARGETPERCENTHEALTH = "Zielprozent Gesundheit",
				TARGETPERCENTHEALTHTOOLTIP = "Zeigt einen prozentualen Integritätswert im Ziel-Frame an",
				AURADURATION = "Aura-Dauer",
				AURADURATIONTOOLTIP = "Zeigt die Dauer der Standardeinheiten an",
				AURACCPORTRAIT = "Aura CC Portrait",
				AURACCPORTRAITTOOLTIP = "Zeigt ein Porträt der Mengensteuerung auf dem Zielrahmen",
				LOSSOFCONTROLPLAYERFRAME = "Kontrollverlust: Spieler-Frame",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Zeigt die Dauer des Kontrollverlusts an der Position des Spielerporträts an",
				LOSSOFCONTROLROTATIONFRAME = "Kontrollverlust: Drehrahmen",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Zeigt die Dauer des Kontrollverlusts an der Position des Rotationsporträts (in der Mitte) an",
				LOSSOFCONTROLTYPES = "Kontrollverlust: Trigger anzeigen",	
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Warteschleife",
				ENABLED = "Aktiviert",
				NAME = "Name",
				DESC = "Notiz",
				ICON = "Icon",
				SETBLOCKER = "Set\n Blocker",
				SETBLOCKERTOOLTIP = "Dadurch wird die ausgewählte Aktion in der Rotation blockiert.\nSie wird niemals verwendet.\n\nRechtsklick: Makro erstellen",
				SETQUEUE = "Set\n Warteschleife",
				SETQUEUETOOLTIP = "Der nächste Spell wird in die Warteschleife gessetzt\nEr wird benutzt sobald es möglich ist\n\n Rechtsklick: Makro erstellen\nSie können im erstellten Makro zusätzliche Bedingungen für die Warteschlange übergeben\nWie Kombinationspunkte (CP ist Schlüssel), Beispiel: {Priority = 1, CP = 5}\nDie Beschreibung der akzeptablen Schlüssel finden Sie in der Funktion 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blockiert: |r",
				UNBLOCKED = "|cff00ff00Freigestellt: |r",
				KEY = "[Schlüssel: ",
				KEYTOTAL = "[Warteschlangensumme: ",
				KEYTOOLTIP = "Benutze den Schlüssel im MSG Fenster", 
				ISFORBIDDENFORBLOCK = "Verboten für die Blocker!",
				ISFORBIDDENFORQUEUE = "Verboten für die Warteschleife!",
				ISQUEUEDALREADY = "Schon in der Warteschleife drin!",
				QUEUED = "|cff00ff00Eingereiht: |r",
				QUEUEREMOVED = "|cffff0000Entfernt aus der Warteschleife: |r",
				QUEUEPRIORITY = " hat Priorität #",
				QUEUEBLOCKED = "|cffff0000Kann nicht eingereiht werden das der Spell geblockt ist!|r",
				SELECTIONERROR = "|cffff0000Du hast nichts ausgewählt!|r",
				AUTOHIDDEN = "Nicht verfügbare Aktionen automatisch ausblenden",
				AUTOHIDDENTOOLTIP = "Verkleinern Sie die Bildlauftabelle und löschen Sie sie durch visuelles Ausblenden\nZum Beispiel hat die Charakterklasse nur wenige Rassen, kann aber eine verwenden. Diese Option versteckt andere Rassen\nNur zur Komfortsicht",
				LUAAPPLIED = "LUA-Code wurde angewendet auf ",
				LUAREMOVED = "LUA-Code wurde gelöscht von ",
			},
			[4] = {
				HEADBUTTON = "Unterbrechungen",	
				HEADTITLE = "Profile Unterbrechungen",				
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				CONFIGPANEL = "'Unterbrechungen hinzufügen' Menu",
				INTERRUPTFRONTSTRINGTITLE = "Liste auswählen:",
				INTERRUPTTOOLTIP = "[Main] für Einheiten @target/@mouseover/@targettarget\n [Heilung] für Einheiten @arena1-3 (Heilung)\n [PvP] für Einheiten @arena1-3 (crowdcontrol)\n\n Du kannst verschiedene Zeiten für [Heilung] und [PvP] (nicht in dem UI)",
				INPUTBOXTITLE = "Spell eintragen:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): Lösch den Text und entferne den Fokus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Suche nach Name oder SpellID",
				TARGETMOUSEOVERLIST = "[Main] List",
				TARGETMOUSEOVERLISTTOOLTIP = "Deaktiviert: unterbricht JEGLICHE Zauber nach dem Zufallsprinzip.\nÜberprüft: unterbricht nur die angegebene benutzerdefinierte Liste für @ target / @ mouseover / @ targettarget.\nHinweis: Im PvP wird die Unterbrechung dieser Liste behoben, wenn sie aktiviert ist. 4 Sek.!\n\n@ mouseover / @ targettarget sind optional und hängen von den Optionen auf der Registerkarte spec ab.\n\nRechtsklick: Create macro",
				KICKTARGETMOUSEOVER = "[Main] Unterbrechungen\n Aktiviert",				
				KICKTARGETMOUSEOVERTOOLTIP = "Deaktiviert: @target/@mouseover Einheit Unterbrechen funktioniert nicht\nAktiviert: @target/@mouseover Einheiten Unterbrechen funktioniert \n\n Rechtsklick: Create macro",					
				KICKHEALONLYHEALER = "[Heilung] Nur Heiler",					
				KICKHEALONLYHEALERTOOLTIP = "Deaktiviert: Die Liste gilt für alle Spezialisierungen feindlicher Einheiten\n(e.g. Ench, Elem, SP, Retri)\n Aktiviert: Liste gilt nur für feindliche Heiler\n\n Rechtsklick: Create macro",
				KICKHEAL = "[Heilung] Liste",
				KICKHEALPRINT = "[Heilung] Liste der Unterbrechungen",
				KICKHEALTOOLTIP = "Deaktiviert: @arena1-3 [Heilung] Benutzerlist funktioniert nicht\nChecked: @arena1-3 [Heilung] Benutzerliste funktioniert\n\nRechtsklick: Create macro",
				KICKPVP = "[PvP] Liste",
				KICKPVPPRINT = "[PvP] Liste der Unterbrechungen",
				KICKPVPTOOLTIP = "Deaktiviert: @arena1-3 [PvP] Benutzerlist funktioniert nicht\nChecked: @arena1-3 [PvP] Benutzerliste funktioniert \n\n Rechtsklick: Create macro",	
				KICKPVPONLYSMART = "[PvP] Einfach",
				KICKPVPONLYSMARTTOOLTIP = "Aktiviert: wird nur durch logische Aktionen in der profil lua konfiguration unterbrochen. Beispiel:\n1) CC Kette auf deinen Heiler \n2) Dein partner (oder du) hat seinen Burst Aktiv >4 sec\n3) Wenn jemand in weniger als 8 Sekunden stirbt\n4) Dein (oder @target) HP kommt in die execute Phase\n Deaktiviert: Wird alles mögliche ohne Logik unterbrechen von deiner Liste\n\nNote: Hohe CPU Auslastung\nRightClick: Create macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Rassisch",
				ADD = "Unterbrechung hinzufügen",					
				ADDERROR = "|cffff0000Du hast in 'Zauberspell' nichts angegeben, oder der Zauber wurde nicht gefunden!|r",
				ADDTOOLTIP = "Füge Fähigkeit von 'Zauberspell'\n Zu deiner Liste",
				REMOVE = "Entferne Unterbrechung",
				REMOVETOOLTIP = "Entfernt markierten Spell von deiner Liste",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "Checkbox Configuration",
				USEDISPEL = "Benutze Dispel",
				USEPURGE = "Benutze Purge",
				USEEXPELENRAGE = "Entferne Enrage",
				USEEXPELFRENZY = "Entferne Frenzy",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Kategorie:",
				POISON = "Dispel Gifte",
				DISEASE = "Dispel Krankheiten",
				CURSE = "Dispel Flüche",
				MAGIC = "Dispel Magische Effekte",
				MAGICMOVEMENT = "Dispel Magische verlangsamungen/festhalten",
				PURGEFRIENDLY = "Purge Partner",
				PURGEHIGH = "Purge Gegner (Hohe Priorität)",
				PURGELOW = "Purge Gegner (Geringe Priorität)",
				ENRAGE = "Entferne Enrage",	
				ROLE = "Rolle",
				ID = "ID",
				NAME = "Name",
				DURATION = "Dauer\n >",
				STACKS = "Stapel\n >=",
				ICON = "Symbol",					
				ROLETOOLTIP = "Deine Rolle, es zu benutzen",
				DURATIONTOOLTIP = "Reagiere auf Aura, wenn die Dauer der Aura länger (>) als die angegebenen Sekunden ist.\nWICHTIG: Auren ohne Dauer wie 'Göttliche Gunst'\n(Lichtpaladin) müssen 0 sein. Dies bedeutet, dass die Aura vorhanden ist!",
				STACKSTOOLTIP = "Reagiere auf Aura, wenn es mehr oder gleiche (>=) spezifizierte Stapel hat",													
				CANSTEALORPURGE = "Nur wenn ich\n Klauen oder Entfernen kann",					
				ONLYBEAR = "Nur wenn der Gegner\nin 'Bär Form'ist",									
				CONFIGPANEL = "'Aura hinzufügen' Menü",
				ANY = "Jeder",
				HEALER = "Heiler",
				DAMAGER = "Tank|Damager",
				ADD = "Aura hinzufügen",					
				REMOVE = "Aura entfernen",					
			},				
			[6] = {
				HEADBUTTON = "Zeiger",
				HEADTITLE = "Maus Interaktion",
				USETITLE = "Tasten Menü:",
				USELEFT = "Benutze Links Klick",
				USELEFTTOOLTIP = "Dies erfolgt mit einem Makro / Ziel-Mouseover, bei dem es sich nicht um einen Klick handelt!\n\nRechtsklick: Makro erstellen",
				USERIGHT = "Benutze Rechts Klick",
				LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nWenn Sie in der Kategorie 'GameToolTip' LUA verwenden, ist diese Einheit ungültig.\nCode muss eine boolesche Rückgabe (trifft zu) für die Verarbeitung von Bedingungen haben Verwenden Sie Action. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",							
				BUTTON = "Klick",
				NAME = "Name",
				LEFT = "Linkklick",
				RIGHT = "Rechtsklick",
				ISTOTEM = "im Totem",
				ISTOTEMTOOLTIP = "Wenn diese Option aktiviert ist, wird @mouseover auf 'Totem' für die Art des Totems überprüft.\nVermeiden Sie auch, dass Sie in eine Situation klicken, in der Ihr @target bereits ein Totem enthält",				
				INPUTTITLE = "Geben Sie den Namen des Objekts ein (localized!)", 
				INPUT = "Dieser Eintrag unterscheidet nicht zwischen Groß- und Kleinschreibung",
				ADD = "Hinzufügen",
				REMOVE = "Entfernen",
				-- GlobalFactory default name preset in lower case!				
				SPIRITLINKTOTEM = "totem der geistverbindung",
				HEALINGTIDETOTEM = "totem der heilungsflut",
				CAPACITORTOTEM = "totem der energiespeicherung",					
				SKYFURYTOTEM = "totem des himmelszorns",					
				ANCESTRALPROTECTIONTOTEM = "totem des schutzes der ahnen",					
				COUNTERSTRIKETOTEM = "totem des gegenschlags",
				-- Optional totems
				TREMORTOTEM = "totem des erdstoßes",
				GROUNDINGTOTEM = "totem der erdung",
				WINDRUSHTOTEM = "totem des windsturms",
				EARTHBINDTOTEM = "totem der erdbindung",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "schlachtstandarte der horde",
				ALLIANCEBATTLESTANDARD = "schlachtstandarte der allianz",
				-- GameToolTips
				ALLIANCEFLAG = "siegesflagge der allianz",
				HORDEFLAG = "siegesflagge der horde",                                 
			},
			[7] = {
				HEADTITLE = "Nachrichten System",
				USETITLE = "",
				MSG = "MSG System",
				MSGTOOLTIP = "Aktiviert: Funktioniert \nDeaktiviert: Funktioniert nicht\n\nRightClick: Create macro",
				DISABLERETOGGLE = "Warteschlange entfernen",
				DISABLERETOGGLETOOLTIP = "Verhindert durch wiederholtes Löschen von Nachrichten aus dem Warteschlangensystem\nE.g. Mögliches Spam-Makro, ohne entfernt zu werden\n\nRechtsklick: Makro erstellen",
				MACRO = "Macro für deine Gruppe:",
				MACROTOOLTIP = "Dies sollte an den Gruppenchat gesendet werden, um die zugewiesene Aktion auf der angegebenen Taste auszulösen.\nUm die Aktion an eine bestimmte Einheit zu richten, fügen Sie sie dem Makro hinzu oder lassen Sie sie unverändert, wie sie für den Termin in der Einzel- / AoE-Rotation vorgesehen ist.\nUnterstützt : raid1-40, party1-2, player, arena1-3\nNUR EINE EINHEIT FÜR EINE NACHRICHT!\n\nIhre Gefährten können auch Makros verwenden, aber seien Sie vorsichtig, sie müssen dem treu bleiben!\nLASSEN SIE DAS NICHT MAKRO ZU UNIMINANZEN UND MENSCHEN NICHT IM THEMA!",
				KEY = "Taste",
				KEYERROR = "Du hast keine Taste ausgewählt!",
				KEYERRORNOEXIST = "Taste existiert nicht!",
				KEYTOOLTIP = "Sie müssen eine Taste zum auswählen der Aktion angeben.\nSie können die Taste auf der Registerkarte 'Aktionen' finden",
				MATCHERROR = "Der name ist bereits vorhanden, bitte nimm einen anderen!",				
				SOURCE = "Der Name der Person, die das gesagt hat",					
				WHOSAID = "Wer es sagt",
				SOURCETOOLTIP = "Dies ist optional. Du kannst dieses Feld leer lassen (empfohlen).\nWenn du es konfigurieren möchtest, muss der Name exakt mit dem in der Chatgruppe übereinstimmen",
				NAME = "Enthält eine Nachricht",
				ICON = "Symbol",
				INPUT = "Gib einen Text für das Nachrichtensystem ein",
				INPUTTITLE = "Text",
				INPUTERROR = "Du hast keinen Text angegeben!",
				INPUTTOOLTIP = "Der Text wird ausgelöst sobald einer aus deiner Gruppe im Gruppenchat schreibt (/party)\nEr ist nicht Groß geschrieben\n Enthält Muster, das heisst der Text, die von jemandem mit der Kombination der Wörter Schlachtzug, Party, Arena, Party oder Spieler gesprochen wird, passt die Aktion an den gewünschten Meta-Slot an.\nDie hier aufgeführten Muster müssen nicht festgelegt werden Wird das Muster nicht gefunden, werden Slots für Single- und AoE-Rotationen verwendet",				
			},
		},
	},
	frFR = {			
		NOSUPPORT = "ce profil n'est pas encore supporté par ActionUI",	
		DEBUG = "|cffff0000[Debug] Identification d'erreur : |r",			
		ISNOTFOUND = "n'est pas trouvé!",			
		CREATED = "créé",
		YES = "Oui",
		NO = "Non",
		TOGGLEIT = "Basculer ON/OFF",
		SELECTED = "Selectionné",
		RESET = "Réinitialiser",
		RESETED = "Remis à zéro",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La macro existe déjà !|r",
		MACROLIMIT = "|cffff0000Impossible de créer la macro, vous avez atteint la limite. Vous devez supprimer au moins une macro!|r",	
		GLOBALAPI = "API Globale: ",
		RESIZE = "Redimensionner",
		RESIZE_TOOLTIP = "Cliquer et faire glisser pour redimensionner",
		SLASH = {
			LIST = "Liste des commandes slash:",
			OPENCONFIGMENU = "Voir le menu de configuration",
			HELP = "Voir le menu d'aide",
			QUEUEHOWTO = "macro (toggle) pour la séquence système (Queue), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			QUEUEEXAMPLE = "exemple d'utilisation de Queue(file d'attende)",
			BLOCKHOWTO = "macro (toggle) pour désactiver|activer n'importe quelles actions (Blocker-Blocage), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			BLOCKEXAMPLE = "exemple d'usage Blocker (Blocage)",
			RIGHTCLICKGUIDANCE = "Vous pouvez faire un clic droit ou gauche sur la plupart des éléments. Un clicque droit va créer la macro toggle donc ne vous souciez pas de laide au dessus",				
			INTERFACEGUIDANCE = "Explications de l'UI:",
			INTERFACEGUIDANCEGLOBAL = "[Global] concernant TOUT vos compte, TOUT vos personnage et TOUTES vos spécialisations",
			TOTOGGLEBURST = "pour basculer en mode rafale",
			TOTOGGLEMODE = "pour basculer PvP / PvE",
			TOTOGGLEAOE = "pour basculer en zone d'effet (AoE)",			
		},
		TAB = {
			RESETBUTTON = "Réinitiliser les paramètres",
			RESETQUESTION = "Êtes-vous sûr?",
			SAVEACTIONS = "Sauvegarder les paramètres d'Actions",
			SAVEINTERRUPT = "Sauvegarder la liste d'interruption",
			SAVEDISPEL = "Sauvergarder la liste d'auras",
			SAVEMOUSE = "Sauvergarder la liste de Curseur",
			SAVEMSG = "Sauvergarder La liste MSG",
			LUAWINDOW = "Configuration LUA",
			LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
			BRACKETMATCH = "Repérage des paires de\nparenthèse", 
			CLOSELUABEFOREADD = "Fermer la configuration LUA avant de l'ajouter",
			FIXLUABEFOREADD = "Vous devez corriger les erreurs dans la configuration LUA avant de l'ajouter",
			RIGHTCLICKCREATEMACRO = "Clique droit : Créer la macro",
			NOTHING = "Le profile n'a pas de configuration pour cette onglet",
			HOW = "Appliquer:",
			HOWTOOLTIP = "Globale: Tous les comptes, tous les personnages et toutes les spécialisations",
			GLOBAL = "Globale",
			ALLSPECS = "Pour toutes les spécialisations de votre personnage",
			THISSPEC = "Pour la spécialisation actuelle de votre personnage",			
			KEY = "Touche:",
			CONFIGPANEL = "'Ajouter' Configuration",
			[1] = {
				HEADBUTTON = "Générale",	
				HEADTITLE = "Primary",
				PVEPVPTOGGLE = "PvE / PvP basculement manuelle",
				PVEPVPTOGGLETOOLTIP = "Focer un profile a basculer dans l'autre mode (PVE/PVP)\n(Utile avec le mode de guerre activé)\n\nClique Droit : Créer la macro", 
				PVEPVPRESETTOOLTIP = "Réinitialiser le basculemant en automatique",
				CHANGELANGUAGE = "Changer la langue",
				CHARACTERSECTION = "Section du personnage",
				AUTOTARGET = "Ciblage Automatique",
				AUTOTARGETTOOLTIP = "Si vous n'avez pas de cible, mais que vous êtes en combat, il va choisir la cible la plus proche\n Le basculement fonctionne de la même manière si la cible est immunisé en PVP\n\nClique droit : Créer la macro",					
				POTION = "Potion",
				RACIAL = "Sort raciaux",
				STOPCAST = "Arrêtez le casting",
				SYSTEMSECTION = "Section système",
				LOSSYSTEM = "Système LOS",
				LOSSYSTEMTOOLTIP = "ATTENTION: Cette option cause un delai de 0.3s + votre gcd en cours\nSi la cible verifié n'est pas dans la ligne de vue (par exemple, derrière une boite en arène) \nVous devez aussi activer ce paramètre dans les paramètres avancés\nCette option blacklistes l'unité qui n'est pas à vue et\narrête d'effectuer des actions sur elle pendant N secondes\n\nClique droit : Créer la macro",
				HEALINGENGINEPETS = "HealingEngine familiers",
				HEALINGENGINEPETSTOOLTIP = "Inclut les familier des joueurs et calcule les soins pour eux\n\nClique droit : Créer la macro",
				HEALINGENGINEANYROLE = "HealingEngine n'importe quel rôle",
				HEALINGENGINEANYROLETOOLTIP = "Activer l'utilisation du ciblage des membres sur n'importe quel rôle",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Arrêtera les dégâts sur les ennemis\nSi ils ont un CC tel que Polymorph\nIl n'annule pas l'attaque automatique!\n\nClique droit : Créer la macro",
				ALL = "Tout",
				RAID = "Raid",
				TANK = "Tanks seulement",
				DAMAGER = "DPS seulement",
				HEALER = "Heal seulement",
				TANKANDPARTY = "Tanks et Groupe",
				PARTY = "Groupe",
				HEALINGENGINETOOLTIP = "Cette option concerne les cible pour les heals\nTout: Tout les membres\nRaid: Tous les membres sauf les tanks\n\nClique droit : Créer la macro\nSi vous voulez régler comment bascule le ciblage des cible utiliser l'argumment (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "Timeur DBM",
				DBMTOOLTIP = "Suit les timeur de pull and certain événement spécifique comme l'arrivé de trash.\nCette fonction n'est pas disponible pour tout les profiles!\n\nClique droit : Créer la macro",
				FPS = "FPS Optimisation",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO:  Augmente les images par seconde en augmentant la dépendance dynamique\nimage du cycle de rafraichisement (call) du cycle de rotation\n\nVous pouvez régler manuellement l'intervalle en suivant cette règle simple:\nPlus le slider est grand plus vous avez de FPS, mais pire sera la mise à jour de la rotation\nUne valeur trop élevée peut entraîner un comportement imprévisible!\n\nClique droit : Créer la macro",
				PVPSECTION = "Section PvP",
				RETARGET = "Remet le @target sauvé précédemment\n(Uniquement pour les cibles arena1-3)\nCela est recommander contre les chasseurs avec 'Feindre la mort' et les perte de cible imprévu\n\nClique droit : Créer la macro",
				TRINKETS = "Bijoux",
				TRINKET = "Bijou",
				BURST = "Mode Burst",
				BURSTTOOLTIP = "Tout - On cooldown\nAuto - Boss or Joueur\nOff - Désactiver\n\nClique droit : Créer la macro\nSi vous voulez régler comment bascule les cooldowns utiliser l'argumment (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Pierre de soin | Potion de guérison",
				HEALTHSTONETOOLTIP = "Choisisez le pourcentage de vie (HP)\nPotion de guérison dépend des paramètres de votre classe dans Potion\net de leur affichage dans l’onglet Actions\nHealthstone a partagé son temps de recharge avec Potion de guérison\n\nClique droit : Créer la macro",
				PAUSECHECKS = "La rotation ne fonction pas, si:",
				AUTOATTACK = "Attaque automatique",
				AUTOSHOOT = "Tir automatique",	
				DEADOFGHOSTPLAYER = "Vous êtes mort!",
				DEADOFGHOSTTARGET = "Votre cible est morte",
				DEADOFGHOSTTARGETTOOLTIP = "Exception des chasseurs ennemi si il est en cible principale",
				MOUNT = "EnMonture",
				COMBAT = "Hors de combat", 
				COMBATTOOLTIP = "Si vous et votre cible êtes hors de combat. L'invicibilité cause une exception\n(Quand vous êtes camouflé, cette condition est ignoré)",
				SPELLISTARGETING = "Ciblage d'un sort",
				SPELLISTARGETINGTOOLTIP = "Exemple: Blizzard, Bond héroïque, Piège givrant",
				LOOTFRAME = "Fenêtre du butin",
				EATORDRINK = "Est-ce que manger ou boire",
				MISC = "Autre:",		
				DISABLEROTATIONDISPLAY = "Cacher l'affichage de la\nrotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Cacher le groupe, qui se trouve par défaut\n en bas au centre de l'écran",
				DISABLEBLACKBACKGROUND = "Cacher le fond noir", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Cacher le fond noir dans le coin en haut à gauche\nATTENTION: Cela peut entraîner un comportement imprévisible de la rotation!",
				DISABLEPRINT = "Cacher les messages chat",
				DISABLEPRINTTOOLTIP = "Cacher toutes les notification du chat\nATTENTION: Cela cache aussi les message de [Debug] Identification d'erreur!",
				DISABLEMINIMAP = "Cacher l'icone de la minimap",
				DISABLEMINIMAPTOOLTIP = "Cacher l'icone de la minmap de cette interface",
				DISABLEPORTRAITS = "Masquer le portrait de classe",
				DISABLEROTATIONMODES = "Masquer les modes de rotation",
				DISABLESOUNDS = "Désactiver les sons",
				CAMERAMAXFACTOR = "Facteur max caméra", 
				ROLETOOLTIP = "En fonction de ce mode, la rotation fonctionnera\nAUTO - Définit votre rôle en fonction de la majorité des talents imbriqués dans le bon arbre",
				TOOLS = "Outils: ",
				LETMECASTTOOLTIP = "Démontage automatique et stand automatique\nSi un orthographe ou une interaction échoue en raison de son montage, vous serez démonté. Si vous ne vous assoyez pas, vous vous lèverez.\nLet Me Cast - Laissez-moi jeter!",
				TARGETCASTBAR = "Cible CastBar",
				TARGETCASTBARTOOLTIP = "Affiche une vraie barre de distribution sous le cadre cible",
				TARGETREALHEALTH = "Cible la santé réelle",
				TARGETREALHEALTHTOOLTIP = "Affiche une valeur de santé réelle sur le cadre cible",
				TARGETPERCENTHEALTH = "Cible Pourcentage De La Santé",
				TARGETPERCENTHEALTHTOOLTIP = "Affiche un pourcentage d'intégrité sur le cadre cible",
				AURADURATION = "Durée de l'aura",
				AURADURATIONTOOLTIP = "Affiche la valeur de la durée sur les cadres d'unités par défaut",
				AURACCPORTRAIT = "Portrait Aura CC",
				AURACCPORTRAITTOOLTIP = "Affiche le portrait du contrôle de la foule sur l'image cible",
				LOSSOFCONTROLPLAYERFRAME = "Perte de contrôle: cadre du joueur",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Affiche la durée de la perte de contrôle à la position de portrait du joueur",
				LOSSOFCONTROLROTATIONFRAME = "Perte de contrôle: cadre de rotation",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Affiche la durée de la perte de contrôle à la position portrait en rotation (au centre)",
				LOSSOFCONTROLTYPES = "Perte de contrôle: déclencheurs d'affichage",		
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocage | File d'attente",
				ENABLED = "Activer",
				NAME = "Nom",
				DESC = "Note",
				ICON = "Icone",
				SETBLOCKER = "Activer\nBloquer",
				SETBLOCKERTOOLTIP = "Cela bloque l'action sélectionné dans la rotation\nElle ne sera jamais utiliser\n\nClique droit : Créer la macro",
				SETQUEUE = "Activer\nQueue(file d'attente)",
				SETQUEUETOOLTIP = "Cela met l'action en queue dans la rotation\nElle sera utilisé le plus tôt possible\n\nClique droit : Créer la macro\nVous pouvez passer des conditions supplémentaires dans la macro créée pour la file d'attente\nComme des points de liste déroulante (la clé CP est la clé), exemple: {Priority = 1, CP = 5}\nVous pouvez trouver des clés acceptables avec une description dans la fonction 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqué: |r",
				UNBLOCKED = "|cff00ff00Débloqué: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Total de la file d'attente: ",
				KEYTOOLTIP = "Utiliser ce mot clef dans l'onglet MSG",
				ISFORBIDDENFORBLOCK = "est indertit pour la file bloquer!",
				ISFORBIDDENFORQUEUE = "est indertit pour la file d'attente!",
				ISQUEUEDALREADY = "est déjà dans la file d'attente!",
				QUEUED = "|cff00ff00Mise en attente: |r",
				QUEUEREMOVED = "|cffff0000Retirer de la file d'attente: |r",
				QUEUEPRIORITY = " est prioritaire #",
				QUEUEBLOCKED = "|cffff0000ne peut être mise en attente car le blocage est activé!|r",
				SELECTIONERROR = "|cffff0000Vous n'avez pas sélectionné de ligne!|r",
				AUTOHIDDEN = "Masquer automatiquement les actions non disponibles",
				AUTOHIDDENTOOLTIP = "Rendre la table de défilement plus petite et claire en masquant visuellement\nPar exemple, la classe de personnage a peu de caractères raciaux, mais peut en utiliser un. Cette option masquera les autres caractères raciaux\nJuste pour le confort vue",
				LUAAPPLIED = "Le code LUA a été appliqué à",
				LUAREMOVED = "Le code LUA a été retiré de",
			},
			[4] = {
				HEADBUTTON = "Interruptions",	
				HEADTITLE = "Profile pour les Interruptions",					
				ID = "ID",
				NAME = "Nom du sort",
				ICON = "Icone",
				CONFIGPANEL = "Configuration 'Ajouter une interuption'",
				INTERRUPTFRONTSTRINGTITLE = "Sélectionner une liste:",
				INTERRUPTTOOLTIP = "[Principal] pour les cibles en @target/@mouseover/@targettarget\n[Heal] pour les cibles @arena1-3 (healing)\n[PvP] pour les cibles @arena1-3 (Contrôle de foule)\n\nVous pouvez mettre différents timeur pour [Heal] et [PvP] (pas dans cette interface)",
				INPUTBOXTITLE = "Ajouter un sort:",					
				INPUTBOXTOOLTIP = "ECHAP (ESC): supprimer texte and focus",
				INTEGERERROR = "Plus de 7 chiffres ont été rentré", 
				SEARCH = "Recherche par nom ou ID",
				TARGETMOUSEOVERLIST = "[Principale] Liste",
				TARGETMOUSEOVERLISTTOOLTIP = "Décoché: cela va interrompre N'IMPORTE quel sort\nCoché: Cela va interrompre uniquement les sort de cette liste sur @target/@mouseover/@targettarget\nNote: en PvP seul les sort de la liste PvP sera interrompu, par ailleurs si votre cible est un heal seul les sort de le liste [Heal] seront interrompu si la cible meurent dans les 3-4 sec!\n\n@mouseover/@targettarget sont optionel et dépend de l'option choisi dans l'onglet spécialisation\n\nClique droit : Créer la macro",
				KICKTARGETMOUSEOVER = "[Principale] Interruptions",					
				KICKTARGETMOUSEOVERTOOLTIP = "Décoché: Les interuptions sur les cibles @target/@mouseover ne fonctionnent pas\nCoché: Les interruptiond sur les cibles @target/@mouseover fonctionnent\n\nClique droit : Créer la macro",					
				KICKHEALONLYHEALER = "[Heal] Heal seulement",					
				KICKHEALONLYHEALERTOOLTIP = "Décoché: La liste sera valide pour ni'mporte quel spécialisation ennemis\n(e.g. Amélio, Elem, SP, Ret)\nCoché: La liste ne fonctionnera que sur les heals ennemis\n\nClique droit : Créer la macro",
				KICKHEAL = "[Heal] Liste",
				KICKHEALPRINT = "[Heal] Liste des Interruptions",
				KICKHEALTOOLTIP = "Décoché: @arena1-3 [Heal] la liste ne fontionne pas\nCoché: @arena1-3 [Heal] La liste fonctionne\n\nClique droit : Créer la macro",
				KICKPVP = "[PvP] Liste",
				KICKPVPPRINT = "[PvP] Liste des Interruptions",
				KICKPVPTOOLTIP = "Décoché: @arena1-3 [PvP] la liste ne fontionne pas\nCoché: @arena1-3 [PvP] La liste fonctionne\n\nClique droit : Créer la macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Coché: interrompera seulement en suivant la logic établi dans le profile LUA. Exemple:\n1) Enchaînement de contrôle sur votre heal\n2) Quelqu'un d'amical (ou vous) avait des buffs de Burst >4 sec\n3) Quelqu'un va mourir en moins de 8 sec\n4) Vous (ou @target) HP rentre en phase d'execution \nDécoché: va interrompre les sorts de la liste sans aucune sorte de logique\n\nNote: Cause une demande élevée sur le CPU\nClique droit : Créer la macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Ajouter une Interruption",					
				ADDERROR = "|cffff0000Vous n'avez rien préciser dans 'Ajouter un sort' ou le sort n'est pas trouvé!|r",
				ADDTOOLTIP = "Ajouter un sort depuis 'Ajouter un sort'\nDe la boite de texte à votre liste actuelle",
				REMOVE = "Retirer Interruption",
				REMOVETOOLTIP = "Retire le sort sélectionné de votre liste actuelle",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "Configuration Checkbox",
				USEDISPEL = "Utiliser Dispel",
				USEPURGE = "Utiliser Purge",
				USEEXPELENRAGE = "Supprimer Enrage",
				USEEXPELFRENZY = "Supprimer Frenzy",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Catégorie:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel maladie",
				CURSE = "Dispel malédiction",
				MAGIC = "Dispel magique",
				MAGICMOVEMENT = "Dispel magique ralentissement/roots",
				PURGEFRIENDLY = "Purge amical",
				PURGEHIGH = "Purge ennemie (priorité haute)",
				PURGELOW = "Purge ennemie (priorité basse)",
				ENRAGE = "Supprimer Enrage",	
				ROLE = "Role",
				ID = "ID",
				NAME = "Nom",
				DURATION = "Durée\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icône",					
				ROLETOOLTIP = "Rôle pour l'utiliser",
				DURATIONTOOLTIP = "Réagit à l'aura si la durée de l'aura est plus grande (>) que le temps spécifié en secondes\nIMPORTANT: les auras sans durée comme 'Faveur divine'\n(Paladin Sacrée) doivent être à 0. Cela signifie que l'aura est présente!",
				STACKSTOOLTIP = "Réagit à l'aura si le nombre de stack est plus grand ou égale (>=) au nombre de stacks spécifié",													
				CANSTEALORPURGE = "Seulement si vous pouvez\nvolé ou purge",					
				ONLYBEAR = "Seulement si la cible\nest en 'Forme d'ours'",									
				CONFIGPANEL = " Configuration 'Ajouter une Aura'",
				ANY = "N'importe lequel",
				HEALER = "Heal",
				DAMAGER = "Tank|Dps",
				ADD = "Ajouter Aura",					
				REMOVE = "Retirer Aura",					
			},				
			[6] = {
				HEADBUTTON = "Curseur",
				HEADTITLE = "Interaction Souris",
				USETITLE = "Cougiration des Bouttons:",
				USELEFT = "Utiliser Clique Gauche",
				USELEFTTOOLTIP = "Cette macro utilise le survol de la souris pas bessoin de clique!\n\nClique droit : Créer la macro",
				USERIGHT = "Utiliser Clique Droit",
				LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nSi vous utiliser le code LUA dans la catégorie 'GameToolTip' alors 'thisunit' n'est pas valide\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
				BUTTON = "Cliquer",
				NAME = "Nom",
				LEFT = "Clique Gauche",
				RIGHT = "Clique Droit",
				ISTOTEM = "EstunTotem",
				ISTOTEMTOOLTIP = "Si activer cela va donner le nom si votre souris survol un totem\nAussi empêche de clic dans le cas où votre cible a déjà un totem",				
				INPUTTITLE = "Entrée le nom d'un objet (localisé!)", 
				INPUT = "Ce texte est case insensitive",
				ADD = "Ajouter",
				REMOVE = "Retirer",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem de lien d'esprit",
				HEALINGTIDETOTEM = "totem de marée de soins",
				CAPACITORTOTEM = "totem condensateur",					
				SKYFURYTOTEM = "totem fureur-du-ciel",					
				ANCESTRALPROTECTIONTOTEM = "totem de protection ancestrale",					
				COUNTERSTRIKETOTEM = "totem de réplique",
				-- Optional totems
				TREMORTOTEM = "totem de séisme",
				GROUNDINGTOTEM = "totem de glèbe",
				WINDRUSHTOTEM = "totem de bouffée de vent",
				EARTHBINDTOTEM = "totem de lien terrestre",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "etendard de bataille de la horde",
				ALLIANCEBATTLESTANDARD = "etendard de bataille de l'alliance",
				-- GameToolTips
				ALLIANCEFLAG = "drapeau de l’alliance",
				HORDEFLAG = "drapeau de la horde",
			},
			[7] = {
				HEADTITLE = "Système de Message",
				USETITLE = "",
				MSG = "Système MSG ",
				MSGTOOLTIP = "Coché: fonctionne\nDécoché: ne fonctionne pas\n\nClique droit : Créer la macro",
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Préviens la répétition de retrait de message de la file d'attente\nE.g. Possible de spam la macro sans que le message soit retirer\n\nClique droit : Créer la macro",
				MACRO = "Macro pour votre groupe:",
				MACROTOOLTIP = "C’est ce qui doit être envoyé au groupe de discussion pour déclencher l’action assignée sur le mot clé spécifié\nPour adresser l'action à une unité spécifique, ajoutez-les à la macro ou laissez-la telle quelle pour l'affecter à la rotation Single/AoE.\nPris en charge: raid1-40, party1-2, player, arena1-3\nUNE SEULE UNITÉ POUR UN MESSAGE!\n\nVos compagnons peuvent aussi utiliser des macros, mais attention, ils doivent être fidèles à cela!\nNE PAS LAISSER LA MACRO AUX GENS N'UTILISANT PAS CE GENRE DE PROGRAMME (RISQUE DE REPORT)!",
				KEY = "Mot clef",
				KEYERROR = "Vous n'avez pas spécifié de mot clef!",
				KEYERRORNOEXIST = "Le mot clef n'existe pas!",
				KEYTOOLTIP = "Vous devez spécifier un mot clef pour lier à une action\nVous pouvez extraire un mot clef depuis l'onglet 'Actions'",
				MATCHERROR = "le nom existe déjà, utiliser un autre!",				
				SOURCE = "Le nom de la personne à qui le dire",					
				WHOSAID = "À qui le dire",
				SOURCETOOLTIP = "Ceci est optionel. Vous pouvez le liasser vide (recommandé)\nVous pouvez le configurer, le nom doit être le même quecelui du groupe de discussion",
				NAME = "Contiens un message",
				ICON = "Icône",
				INPUT = "Entrée une phrase pour le systéme de message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "Vous n'avez pas rentré de phrase!",
				INPUTTOOLTIP = "La phrase sera déclenchée sur toute correspondance dans le chat de groupe (/party)\nCe n’est pas sensible à la casse\nContient des patterns, ce qui signifie que si la phrase est dite par des personne dans le chat raid, arène, groupe ou  par un joueur\ncela adapte l'action en fonction du groupe qui l'a dis\nVous n'avez pas besoin de préciser les pattern, ils sont utilisés comme un ajout à la macro\nSi le pattern n'est pas trouvé, les macros pour la rotation Single et AoE seront utilisé",				
			},
		},
	},
	itIT = {			
		NOSUPPORT = "questo profilo non supporta ancora ActionUI",	
		DEBUG = "|cffff0000[Debug] Identificativo di Errore: |r",			
		ISNOTFOUND = "non trovato!",			
		CREATED = "creato",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selezionato",
		RESET = "Riavvia",
		RESETED = "Riavviato",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La Macro esiste gia!|r",
		MACROLIMIT = "|cffff0000Non posso creare la macro, hai raggiunto il limite. Devi cancellare almeno una macro!|r",	
		GLOBALAPI = "API Globale: ",
		RESIZE = "Ridimensiona",
		RESIZE_TOOLTIP = "Seleziona e tracina per ridimensionare",
		SLASH = {
			LIST = "Lista comandi:",
			OPENCONFIGMENU = "mostra il menu di configurazione",
			HELP = "mostra info di aiuto",
			QUEUEHOWTO = "macro (toggle) per il sistema di coda (Coda), la TABLENAME é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			QUEUEEXAMPLE = "esempio per uso della Coda",
			BLOCKHOWTO = "macro (toggle) per disabilitare|abilitare le azioni (Blocco), é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			BLOCKEXAMPLE = "esempio per uso del Blocker",
			RIGHTCLICKGUIDANCE = "La maggior parte degli elementi sono pulsanti cliccabili sinistro e destro del mouse. Il pulsante destro del mouse creerà una macro, in modo che tu non possa tener conto del suggerimento di cui sopra",				
			INTERFACEGUIDANCE = "spiegazioni UI:",
			INTERFACEGUIDANCEGLOBAL = "[Spec Globale] si applica GLOBALMENTE al tuo account TUTTI i personaggi TUTTE le specializzazioni.",			
			TOTOGGLEBURST = "per attivare / disattivare la modalità Burst",
			TOTOGGLEMODE = "per attivare / disattivare PvP / PvE",
			TOTOGGLEAOE = "per attivare / disattivare AoE",
		},
		TAB = {
			RESETBUTTON = "Riavvia settaggi",
			RESETQUESTION = "Sei sicuro?",
			SAVEACTIONS = "Salva settaggi Actions",
			SAVEINTERRUPT = "Salva liste Interruzioni",
			SAVEDISPEL = "Salva liste Auree",
			SAVEMOUSE = "Salva liste cursori",
			SAVEMSG = "Salva liste MSG",
			LUAWINDOW = "Configura LUA",
			LUATOOLTIP = "Per fare riferimento all unità da controllare, usa il nome senza virgolette \nIl codice deve avere un valore(true) per funzionare \nIl codice ha setfenv, significa che non devi usare Action. \n\nSe vuoi rimpiazzare il codice predefinito, devi rimpiazzare con un 'return true' senza virgolette, \n invece di cancellarlo",
			BRACKETMATCH = "Verifica parentesi",
			CLOSELUABEFOREADD = "Chiudi la configurazione LUA prima di aggiungere",
			FIXLUABEFOREADD = "Devi correggere gli errori nella configurazione LUA prima di aggiungere",
			RIGHTCLICKCREATEMACRO = "Pulsanmte destro: Crea macro",
			NOTHING = "Il profilo non ha una configuration per questo tab",
			HOW = "Applica:",
			HOWTOOLTIP = "Global: Tutto account, tutti i personaggi e tutte le specializzazioni",
			GLOBAL = "Globale",
			ALLSPECS = "A tutte le specializzazioni di un personaggio",
			THISSPEC = "Alla specializzazione corrente del personaggio",			
			KEY = "Chiave:",
			CONFIGPANEL = "'Aggiungi' Configurazione",
			[1] = {
				HEADBUTTON = "Generale",	
				HEADTITLE = "Primaria",
				PVEPVPTOGGLE = "PvE / PvP interruttore manuale",
				PVEPVPTOGGLETOOLTIP = "Forza il cambio di un profilo\n(utile quando Modalitá guerra é attiva)\n\nTastodestro: Crea macro", 
				PVEPVPRESETTOOLTIP = "Resetta interruttore manuale - auto",
				CHANGELANGUAGE = "Cambia Lingua",
				CHARACTERSECTION = "Seleziona personaggio",
				AUTOTARGET = "Bersaglio automatico",
				AUTOTARGETTOOLTIP = "Se il bersaglio non é selezionato e sei in combattimento, ritorna il nemico piú vicino\nInterruttore funziona nella stesso modo se il bersaglio selezionato é immune|non in PvP\n\nTastodestro: Crea macro",					
				POTION = "Pozione",
				RACIAL = "Abilitá Raziale",
				STOPCAST = "Smetti di lanciare",
				SYSTEMSECTION = "Area systema",
				LOSSYSTEM = "Sistema di linea di vista [LOS]",
				LOSSYSTEMTOOLTIP = "ATTENZIONE: Questa opzione causa un ritardo di 0.3s + piu tempo del sistema di recupero globale [srg]\nse il bersaglio é in los (per esempio dietro una cassa in arena)\nDevi anche abilitare lo stesso settaggio in Settaggi Avanzati\nQuesta opzione mette in blacklists bersagli fuori los e\nferma le azioni verso il bersaglio per N secondio\n\nTastodestro: Crea macro",
				HEALINGENGINEPETS = "Logica di cure per pet",
				HEALINGENGINEPETSTOOLTIP = "include nella selezione dei bersagli  i pets dei giocatori e considera la loro cura \n\nTastodestro: Crea macro",
				HEALINGENGINEANYROLE = "HealingEngine qualsiasi ruolo",
				HEALINGENGINEANYROLETOOLTIP = "Abilita l'utilizzo del targeting per membro su qualsiasi tuo ruolo",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Fermerà i danni dannosi ai nemici\nSe hanno CC come Polymorph\nNon annulla l'attacco automatico!\n\nTastodestro: Crea macro",
				ALL = "Tutti",
				RAID = "Raid",
				TANK = "Solo Tank",
				DAMAGER = "Solo Danno",
				HEALER = "Solo Curatori",
				TANKANDPARTY = "Tanks e Gruppo",
				PARTY = "Gruppo",
				HEALINGENGINETOOLTIP = "Opzione per la selezione bersagli per i curatori\nTutti: Tutti i membri\nRaid: Tutti i membri ma non i tank\n\nTastodestro: Crea macro\nSe desideri utilizzare specifici attributi per il bersaglio usa in (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "Timers DBM",
				DBMTOOLTIP = "Tiene traccia dei timer di avvio combattimento e alcuni eventi specific tipo patrol in arrivo.\nQuesta funzionalitá é disponibile per tutti i profili!\n\nTastodestro: Crea macro",
				FPS = "Ottimizzazione FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Aumenta i frames per second incrementando la dipendenza dinamica\ndei frames del ciclo di refresh (call) della rotazione\n\nPuoi settare manualmente l'intervallo seguendo questa semplice regola:\nPiú é altop lo slider piú é l'FPS, ma peggiore sará l'update della rotazione\nValori troppo alti possono portare a risultati imprevedibili!\n\nTastodestro: Crea macro",					
				PVPSECTION = "Sezione PvP",
				RETARGET = "Identifica il bersaglio precedente @target\n(solo arena unitá 1-3)\nraccomandato contro cacciatori con capacitá 'Morte Fasulla' e altre abilitá che deselezionano il bersaglio\n\nTastodestro: Crea macro",
				TRINKETS = "Ninnolo",
				TRINKET = "Ninnoli",
				BURST = "Modalitá raffica",
				BURSTTOOLTIP = "Utilizza Tutto - appena esce dal coll down\nAuto - Boss o Giocatore\nOff - Disabilitata\n\nTastodestro: Crea macro\nSe desidere utilizzare specifici attributi utilizza in (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Pozione curativa",
				HEALTHSTONETOOLTIP = "Seta la percentuale di vita (HP)\nPozione curativa dipende dalle impostazioni della scheda classe per Pozione\ne se queste pozioni sono mostrate nella scheda Azioni\nHealthstone ha condiviso il tempo di recupero con Pozione curativa\n\nTastodestro: Crea macro",
				AUTOATTACK = "Attacco automatico",
				AUTOSHOOT = "Scatto automatico",	
				PAUSECHECKS = "Rotation doesn't work if:",
				DEADOFGHOSTPLAYER = "Sei Morto",
				DEADOFGHOSTTARGET = "Il bersaglio é morto",
				DEADOFGHOSTTARGETTOOLTIP = "Eccezione il cacciatore bersaglio se é selezionato come bersaglio primario",
				MOUNT = "ACavallo",
				COMBAT = "Non in combattimento", 
				COMBATTOOLTIP = "Se tu e il tuo bersaglio siete non in combattimento. l' invisibile non viene considerato\n(quando invisibile questa condizione viene non valutata|saltata)",
				SPELLISTARGETING = "IncantesimoHaBersaglio",
				SPELLISTARGETINGTOOLTIP = "Esembio: Tormento, Balzo eroico, Trappola congelante",
				LOOTFRAME = "Bottino",
				EATORDRINK = "Sta mangiando o bevendo",
				MISC = "Varie:",		
				DISABLEROTATIONDISPLAY = "Nascondi|Mostra la rotazione",
				DISABLEROTATIONDISPLAYTOOLTIP = "Nasconde il gruppo, che generalmente siu trova al\ncentro in basso dello schermo",
				DISABLEBLACKBACKGROUND = "Nascondi lo sfondo nero", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Nasconde lo sfondo nero nell'angolo in alto a sinistra dello schermo\nATTENZIONE: puo causare comportamenti anomali della applicazione!",
				DISABLEPRINT = "Nascondi|Stampa",
				DISABLEPRINTTOOLTIP = "Nasconde notifice di chat per tutto\nATTENZIONE: Questa opzione nasconde anche le notifiche [Debug] Identificazione errori!",
				DISABLEMINIMAP = "Nasconde icona nella minimap",
				DISABLEMINIMAPTOOLTIP = "Nasconde l'icona di questa UI dalla minimappa",
				DISABLEPORTRAITS = "Nascondi ritratto di classe",
				DISABLEROTATIONMODES = "Nascondi le modalità di rotazione",
				DISABLESOUNDS = "Disabilita i suoni",
				CAMERAMAXFACTOR = "Fattore massimo della fotocamera", 
				ROLETOOLTIP = "A seconda di questa modalità, la rotazione funzionerà\nAUTO - Definisce il tuo ruolo in base alla maggior parte dei talenti nidificati nell'albero giusto",
				TOOLS = "Utensili: ",
				LETMECASTTOOLTIP = "Auto-smontaggio e Auto-stand\nSe un incantesimo o un'interazione falliscono a causa del montaggio, si smonterà. Se fallisce a causa del fatto che ti siedi, ti alzi\nLet Me Cast - Lasciami lanciare!",
				TARGETCASTBAR = "Target CastBar",
				TARGETCASTBARTOOLTIP = "Mostra una barra del cast reale sotto il riquadro di destinazione",
				TARGETREALHEALTH = "Target RealHealth",
				TARGETREALHEALTHTOOLTIP = "Mostra un valore di salute reale sul frame di destinazione",
				TARGETPERCENTHEALTH = "Target PercentHealth",
				TARGETPERCENTHEALTHTOOLTIP = "Mostra un valore di integrità percentuale nel riquadro di destinazione",	
				AURADURATION = "Durata dell'aura",
				AURADURATIONTOOLTIP = "Mostra il valore della durata sui frame delle unità predefiniti",
				AURACCPORTRAIT = "Ritratto di Aura CC",
				AURACCPORTRAITTOOLTIP = "Mostra il ritratto del controllo della folla sul riquadro di destinazione",	
				LOSSOFCONTROLPLAYERFRAME = "Perdita di controllo: Player Frame",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Visualizza la durata della perdita di controllo nella posizione verticale del giocatore",
				LOSSOFCONTROLROTATIONFRAME = "Perdita di controllo: telaio di rotazione",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Visualizza la durata della perdita di controllo nella posizione verticale di rotazione (al centro)",
				LOSSOFCONTROLTYPES = "Perdita di controllo: visualizzazione dei trigger",					
			},
			[3] = {
				HEADBUTTON = "Azioni",
				HEADTITLE = "Blocco | Coda",
				ENABLED = "Abilitato",
				NAME = "Nome",
				DESC = "Nota",
				ICON = "Icona",
				SETBLOCKER = "Setta\nBlocco",
				SETBLOCKERTOOLTIP = "Blocca l'azione selezionata da esser eseguta nella rotazione\nNon verrá usata in nessuna condizione\n\nTastodestro: Crea macro",
				SETQUEUE = "Set\nCoda",
				SETQUEUETOOLTIP = "Accoda l'azione selezionata alla rotazione\nUtilizza l'azione appena é possibile\n\nTastodestro: Crea macro\nPuoi passare ulteriori condizioni nella macro creata per la coda\nCome punti combo (CP è la chiave), esempio: {Priority = 1, CP = 5}\nPuoi trovare chiavi accettabili con descrizione nella funzione 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloccato: |r",
				UNBLOCKED = "|cff00ff00Sbloccato: |r",
				KEY = "[Chiave: ",
				KEYTOTAL = "[Totale coda: ",
				KEYTOOLTIP = "Usa questa chiave nel tab MSG",
				ISFORBIDDENFORBLOCK = "non può esser messo in blocco!",
				ISFORBIDDENFORQUEUE = "non può esser messo in coda!",
				ISQUEUEDALREADY = "esiste giá nella coda!",
				QUEUED = "|cff00ff00Nella Coda: |r",
				QUEUEREMOVED = "|cffff0000Rimosso dalla Coda: |r",
				QUEUEPRIORITY = " ha prioritá #",
				QUEUEBLOCKED = "|cffff0000non può essere in Coda perché é giá bloccato!|r",
				SELECTIONERROR = "|cffff0000Non hai selezionato una riga!|r",
				AUTOHIDDEN = "Nascondi automaticamente le azioni non disponibili",
				AUTOHIDDENTOOLTIP = "Rende la Tabella di Scorrimento più piccola e chiara per nascondere l'immagine\nAd esempio, la classe personaggio ha poche razze ma può usarne una, questa opzione nasconderà altre razze\nSolo per una visione confortevole",
				LUAAPPLIED = "LUA code é applicato a ",
				LUAREMOVED = "LUA code é rimosso da ",
			},
			[4] = {
				HEADBUTTON = "Interruzioni",	
				HEADTITLE = "Profile per le interruzioni",					
				ID = "ID",
				NAME = "Nome",
				ICON = "Icona",
				CONFIGPANEL = "'Aggiungi Interruzione' Configurazione",
				INTERRUPTFRONTSTRINGTITLE = "Seleziona lista:",
				INTERRUPTTOOLTIP = "[Principale] per bersagli @target/@mouseover/@targettarget\n[Cura] per bersagli @arena1-3 (curatore)\n[PvP] per bersagli @arena1-3 (Controllo bersagli)\n\nPuoi settare differenti timer per [Cura] and [PvP] (non un questa UI)",
				INPUTBOXTITLE = "Srivi Incantesimo :",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): cancella incantesimo e rimuove il focus",
				INTEGERERROR = "Errore Integer overflow > tentativo di memorizzare piú di 7 numeri", 
				SEARCH = "Cerca per nome o ID ",
				TARGETMOUSEOVERLIST = "[Principale] Lista",
				TARGETMOUSEOVERLISTTOOLTIP = "Non selezionato: interroperá QUALSIASI incantesimo a caso\nSelezionato: interromperá solo scecifiche liste se @target/@mouseover/@targettarget\nNota: in PvP interromperá gli spell della lista se selezionato, altrimeti solo healers se moriranno in meno di 3-4 sec!\n\n@mouseover/@targettarget sono opzionali e dipendono dalle selezioni fatte nella sezione spec\n\nTastodestro: Crea macro",
				KICKTARGETMOUSEOVER = "[Principale] Interruzioni\nAbilitato",					
				KICKTARGETMOUSEOVERTOOLTIP = "Non selezionato: @target/@mouseover le interruzioni non funzionano\nSelezionato: @target/@mouseover le interruzioni funzionano\n\nTastodestro: Crea macro",					
				KICKHEALONLYHEALER = "[Cura] Solo curatori",					
				KICKHEALONLYHEALERTOOLTIP = "Non selezionato: la lista sará valida per ogni specializzazione del bersaglio\n(e.g. Ench, Elem, SP, Retri)\nSelezionato: la lista sará valida solo per i bersagli curatori\n\nTastodestro: Crea macro",
				KICKHEAL = "[Cura] Lista",
				KICKHEALPRINT = "[Cura] Lista delle interruzioni",
				KICKHEALTOOLTIP = "Non selezionato: @arena1-3 [Cura] lista custom non attiva\nSelezionato: @arena1-3 [Cura] lista custom attiva\n\nTastodestro: Crea macro",
				KICKPVP = "[PvP] Lista",
				KICKPVPPRINT = "[PvP] Lista delle interruzioni",
				KICKPVPTOOLTIP = "Non selezionato: @arena1-3 [PvP] lista custom non attiva\nSelezionato: @arena1-3 [PvP] lista custom attiva\n\nTastodestro: Crea macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Selezionato: interompe seguendo la logica definita nella configurazione del profilo. Esempio:\n1) Controllo a catena sul curatore\n2) Bersaglio amico (o tu) ha il raffica di buff con tempo residuo >4 sec\n3) Qualcuno muore in meno di 8 sec\n4) I punti vita tuoi (o @target) vengono considerati\nnon selezionato: interrompe sempre gli incantesimi nella lista senza ulteriori logiche\n\nNota: può causare un alto uso della CPU\nTastodestro: Crea macro",
				USEKICK = "Calcio",
				USECC = "CC",
				USERACIAL = "Razziale",
				ADDERROR = "|cffff0000Non hai specificato niente in 'Scrivi Incantesimo' o l'incantesimo non é stato trovato!|r",
				ADD = "Aggiungi Interruzione",					
				ADDTOOLTIP = "Aggiungi incantesimo indicato in 'Scrivi Incantesimo'\nalla lista selezionata",
				REMOVE = "Rimuovi Interruzione",
				REMOVETOOLTIP = "Rimuovi l'incantesimo alla riga selezionata della lista",
			},
			[5] = { 	
				HEADBUTTON = "Auree",					
				USETITLE = "Configurazione",
				USEDISPEL = "Usa Dissoluzione",
				USEPURGE = "Usa Epurazione",
				USEEXPELENRAGE = "Usa Enrage",
				USEEXPELFRENZY = "Usa Frenzy",
				HEADTITLE = "[Globale] Dissoluzione | Epurazione | Enrage",
				MODE = "Modo:",
				CATEGORY = "Categoria:",
				POISON = "Dissolvi Veleni",
				DISEASE = "Dissolvi Malattie",
				CURSE = "Dissolvi Maledizioni",
				MAGIC = "Dissolvi Magia",
				MAGICMOVEMENT = "Dissolvi magia rallentamento/radici",
				PURGEFRIENDLY = "Epura amico",
				PURGEHIGH = "Epura nemico (alta prioritá)",
				PURGELOW = "Epura nemico  (bassa prioritá)",
				ENRAGE = "Expel Enrage",	
				ROLE = "Ruolo",
				ID = "ID",
				NAME = "Nome",
				DURATION = "Durata\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icona",					
				ROLETOOLTIP = "Il tuo ruolo per usarla",
				DURATIONTOOLTIP = "Reazione all'aura se la durata é maggiore di (>) secondi specificati\nIMPORTANTE: Auree senza una durata come 'Favore Divino'\n(Paladino della luce) devono essere a 0. Questo indica che l'aura é presente!",
				STACKSTOOLTIP = "Reazione all'aura se la durata é maggiore o eguale a (>=) degli stack specificati",														
				CANSTEALORPURGE = "Solo se può\nrubare o epurare",					
				ONLYBEAR = "Solo se bersaglio\nin 'Forma D'Orso'",									
				CONFIGPANEL = "'Aggiungi Aura' Configurazione",
				ANY = "Qualsiasi",
				HEALER = "Curatore",
				DAMAGER = "Tank|Danno",
				ADD = "Aggiungi Aura",					
				REMOVE = "Rimuovi Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursore",
				HEADTITLE = "Interazione con mouse",
				USETITLE = "Configurazione pulsanti:",
				USELEFT = "Utilizza click sinistro",
				USELEFTTOOLTIP = "Utilizza macro /target mouseover che non é un click!\n\nTastodestro: Crea macro",
				USERIGHT = "Utilizza click destro",
				LUATOOLTIP = "Per fare riferimento all'unitá da controllare, utilizza 'thisunit' senza virgolette\nSe usi LUA nella categoria 'GameToolTip' questa unitaá non é allora valida\nIl codice deve avere un ritorno logico (vero) perche sia attivato\nQuesto codice ha setfenv questo significa che non hai bisogno di usare Action.\n\nSe vuoi rimuovere il codice predefinito, devi scrivere 'return true' senza virgolette\ninvece di una semplice eliminazione",							
				BUTTON = "Click",
				NAME = "Nome",
				LEFT = "Click sinistro",
				RIGHT = "Click Destro",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "Se abilitato, controlla @mouseover per il tipo 'Totem' con il nome specificato\nPreviene anche il cast nel caso il totem @target sia giá presente",				
				INPUTTITLE = "inserisci il nome dell'oggetto (nella lingua di gioco!)", 
				INPUT = "Questo inserimento non é influenzato da maiuscole|minuscole",
				ADD = "Aggiungi",
				REMOVE = "Rimuovi",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "spirit link totem",
				HEALINGTIDETOTEM = "healing tide totem",
				CAPACITORTOTEM = "capacitor totem",					
				SKYFURYTOTEM = "skyfury totem",					
				ANCESTRALPROTECTIONTOTEM = "ancestral protection totem",					
				COUNTERSTRIKETOTEM = "counterstrike totem",
				-- Optional totems
				TREMORTOTEM = "tremor totem",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "wind rush totem",
				EARTHBINDTOTEM = "earthbind totem",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "horde battle standard",
				ALLIANCEBATTLESTANDARD = "alliance battle standard",
				-- GameToolTips
				ALLIANCEFLAG = "alliance flag",
				HORDEFLAG = "horde flag",
			},
			[7] = {
				HEADTITLE = "Messaggio di sistema",
				USETITLE = "[Spec Corrente]",
				MSG = "MSG Sistema",
				MSGTOOLTIP = "Selezionato: attivo\nNon selezionato: non attivo\n\nTastodestro: Crea macro",
				DISABLERETOGGLE = "Blocca Coda Rimuovi",
				DISABLERETOGGLETOOLTIP = "Previeni l'eliminazione di un incantesimo dalla coda con un messaggio ripetuto\nEsempio, consente di inviare una macro spam senza rischiare eliminazioni non volute\n\nTastodestro: Crea macro",
				MACRO = "Macro per il tuo gruppo:",
				MACROTOOLTIP = "Questo è ciò che dovrebbe alla chat di gruppo per attivare l'azione assegnata ad una chiave specifica\nPer indirizzare un'azione a una unitá specifica, aggiungerlo alla macro o lasciala così com'è per l'utilizzo in rotazione singola/AoE\nSupportati: raid1-40, party1-2, giocatore, arena1-3\nSOLO UN'UNITÀ PER MESSAGGIO!\n\nI tuoi compagni possono usare anche loro macro, ma fai attenzione, devono essere macro allineate!",
				KEY = "Chiave",
				KEYERROR = "Non hai specificato una chiave!",
				KEYERRORNOEXIST = "la chiave non esite!",
				KEYTOOLTIP = "Devi specificare una chiave per vincolare l'azione\nPuoi verificare|leggere lachiave nel Tab 'Azioni'",
				MATCHERROR = "il nome che stai usando esiste giá, usane un altro!",				
				SOURCE = "Il nomme della persona che ha detto",
				WHOSAID = "Che ha detto",
				SOURCETOOLTIP = "Opzionale. Puoi lasciarlo vuoto (raccomndato)\nSe vuoi configurarlo, il nome deve essere esattamente lo stesso indicato nella chat del gruppo",
				NAME = "Contiene un messaggio",
				ICON = "Icona",
				INPUT = "Inserire una frase da usare come messaggio di sistema",
				INPUTTITLE = "Frase",
				INPUTERROR = "Non hai inserito una frase!",
				INPUTTOOLTIP = "La frase verrà attivata in corrispondenza ai riscontri nella chat di gruppo(/party)\nNon é sensibile alle maiuscole\nIdentifica pattern, ciò significa che una frase scritta in chat con la combinazione delle parole raid, party, arena, party o giocatore\nattiva l'azione nel meta slot desiderato\nNon hai bisogno di impostare i pattern elencati, sono usati on top alla macro\nIf non trova nessun pattern, allora verra usato lo slot per rotazione Singola e ad area",				
			},
		},
	},
	esES = {			
		NOSUPPORT = "No soportamos este perfil ActionUI todavía",	
		DEBUG = "|cffff0000[Debug] Error identificado: |r",			
		ISNOTFOUND = "no encontrado!",			
		CREATED = "creado",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Cambiar",
		SELECTED = "Seleccionado",
		RESET = "Reiniciar",
		RESETED = "Reiniciado",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro ya existe!|r",
		MACROLIMIT = "|cffff0000No se puede crear la macro, límite alcanzado. Debes borrar al menos una macro!|r",	
		GLOBALAPI = "API Global: ",
		RESIZE = "Redimensionar",
		RESIZE_TOOLTIP = "Click-y-arrastrar para redimensionar",
		SLASH = {
			LIST = "Lista de comandos:",
			OPENCONFIGMENU = "Mostrar menú de configuración",
			HELP = "Mostrar ayuda",
			QUEUEHOWTO = "macro (toggle) para sistema de secuencia (Cola), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			QUEUEEXAMPLE = "ejemplo de uso de Cola",
			BLOCKHOWTO = "macro (toggle) para deshabilitar|habilitar cualquier acción (Blocker), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			BLOCKEXAMPLE = "ejemplo de uso de Blocker",
			RIGHTCLICKGUIDANCE = "La mayoría de elementos son usables con el botón izquierdo y derecho del ratón. El botón derecho del ratón creará un macro toggle por lo que puedes considerar la sugerencia anterior",				
			INTERFACEGUIDANCE = "Explicación de la UI:",
			INTERFACEGUIDANCEGLOBAL = "[Global] relativa a toda tu cuenta, TODOS los personajes, TODAS las especializaciones",		
			TOTOGGLEBURST = "para alternar el modo de ráfaga",
			TOTOGGLEMODE = "para alternar PvP / PvE",
			TOTOGGLEAOE = "para alternar AoE",
		},
		TAB = {
			RESETBUTTON = "Reiniciar ajustes",
			RESETQUESTION = "¿Estás seguro?",
			SAVEACTIONS = "Guardar ajustes de Acciones",
			SAVEINTERRUPT = "Guardar Lista de Interrupciones",
			SAVEDISPEL = "Guardar Lista de Auras",
			SAVEMOUSE = "Guardar Lista de Cursor",
			SAVEMSG = "Guardar Lista de Mensajes",
			LUAWINDOW = "Configurar LUA",
			LUATOOLTIP = "Para referirse a la unidad de comprobación, usa 'thisunit' sin comillas\nEl código debe tener retorno boolean (true) para procesar las condiciones\nEste código tiene setfenv que significa lo que no necesitas usar Action. para cualquier cosa que tenga it\n\nSi quieres borrar un codigo default necesitas escribir 'return true' sin comillas en vez de removerlo todo",
			BRACKETMATCH = "Correspondencia de corchetes",
			CLOSELUABEFOREADD = "Cerrar las configuración de LUA antes de añadir",
			FIXLUABEFOREADD = "Debes arreglas los errores en la Configuración de LUA antes de añadir",
			RIGHTCLICKCREATEMACRO = "ClickDerecho: Crear macro",
			NOTHING = "El Perfil no tiene configuración para este apartado",
			HOW = "Aplicar:",
			HOWTOOLTIP = "Global: Todas las cuentas, personajes y especializaciones",
			GLOBAL = "Global",
			ALLSPECS = "Para todas las especializaciones del personaje",
			THISSPEC = "Para la especialización actual del personaje",			
			KEY = "Tecla:",
			CONFIGPANEL = "'Añadir' Configuración",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "Primaria",
				PVEPVPTOGGLE = "PvE / PvP Mostrar Manual",
				PVEPVPTOGGLETOOLTIP = "Forzar un perfil a cambiar a otro modo\n(especialmente útil cuando el War Mode está ON)\n\nClickDerecho: Crear macro", 
				PVEPVPRESETTOOLTIP = "Reiniciar mostrar manual a selección automática",
				CHANGELANGUAGE = "Cambiar idioma",
				CHARACTERSECTION = "Sección de Personaje",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "Si el target está vacío, pero estás en combate, devolverá el que esté más cerca\nEl cambiador funciona de la misma manera si el target tiene inmunidad en PvP\n\nClickDerecho: Crear macro",					
				POTION = "Poción",
				RACIAL = "Habilidad Racial",
				STOPCAST = "Deja de lanzar",
				SYSTEMSECTION = "Sección del sistema",
				LOSSYSTEM = "Sistema LOS",
				LOSSYSTEMTOOLTIP = "ATENCIÓN: Esta opción causa un delay de 0.3s + un giro actual de gcd\nsi la unidad está siendo comprobada esta se localizará como pérdida (por ejemplo, detrás de una caja en la arena)\nDebes también habilitar las mismas opciones en Opciones Avanzadas\nEsta opción pone en una lista negra la unidad con perdida y\n deja de producir acciones a esta durante N segundos\n\nClickDerecho: Crear macro",
				HEALINGENGINEPETS = "Motor de Curación para Pets",
				HEALINGENGINEPETSTOOLTIP = "Incluída en el target de las pets del jugador y calcula para curarles\n\nClickDerecho: Crear macro",
				HEALINGENGINEANYROLE = "HealingEngine cualquier papel",
				HEALINGENGINEANYROLETOOLTIP = "Habilite el uso de la orientación a miembros en cualquier rol",
				STOPATBREAKABLE = "Detener el daño en el descanso",
				STOPATBREAKABLETOOLTIP = "Detendrá el daño dañino en los enemigos\nSi tienen CC como Polymorph\nNo cancela el ataque automático!\n\nClickDerecho: Crear macro",
				ALL = "Todo",
				RAID = "Raid",
				TANK = "Solo Tanques",
				DAMAGER = "Solo Damage Dealers",
				HEALER = "Solo Healers",
				TANKANDPARTY = "Tanks y Grupo",
				PARTY = "Grupo",
				HEALINGENGINETOOLTIP = "Esta opción relativa a selección de unidad en curación\nTodo: todos los miembros\nRaid: Todos los miembros sin tanques\n\nClickDerecho: Crear macro\nSi quieres establecer el estado de conmutación fija usa el argumento en (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER', 'TANKANDPARTY', 'PARTY'",
				DBM = "Tiempos DBM",
				DBMTOOLTIP = "Rastrea tiempos de pull y algunos eventos específicos como la basura que pueda venir.\nEsta característica no está disponible para todos los perfiles!\n\nClickDerecho: Crear macro",
				FPS = "Optimización de FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Incrementa los frames por segundo aumentando la dependencia dinámica\nframes del ciclo de recarga (llamada) del ciclo de rotación\n\nTambién puedes establecer manualmente el intervalo siguiendo una regla simple:\nCuanto mayor sea el desplazamiento, mayor las FPS, pero peor actualización de rotación\nUn valor demasiado alto puede causar un comportamiento impredecible!\n\nClickDerecho: Crear macro",					
				PVPSECTION = "Sección PvP",
				RETARGET = "Devuelve el guardado anterior @target\n(arena1-3 unidades solamente)\nEs recomendable contra cazadores con 'Feign Death' and cualquier objetivo imprevisto cae\n\nClickDerecho: Crear macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Modo Bursteo",
				BURSTTOOLTIP = "Todo - En cooldown\nAuto - Boss o Jugadores\nOff - Deshabilitado\n\nClickDerechohabilitado\n\nClickDerecho: Crear macro\nSi quieres establecer el estado de conmutación fija usa el argumento en (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Poción curativa",
				HEALTHSTONETOOLTIP = "Establecer porcentaje de vida (HP)\nPoción curativa depende de la configuración de la pestaña de tu clase para Poción\ny si estas pociones se muestran en la pestaña Acciones\nPiedra de salud ha compartido tiempo de reutilización con Poción de sanación\n\nClickDerecho: Crear macro",
				AUTOATTACK = "Auto ataque",
				AUTOSHOOT = "Disparo automático",	
				PAUSECHECKS = "La rotación no funciona si:",
				DEADOFGHOSTPLAYER = "Estás muerto",
				DEADOFGHOSTTARGET = "El Target está muerto",
				DEADOFGHOSTTARGETTOOLTIP = "Excepción a enemigo hunter if seleccionó como objetivo principal",
				MOUNT = "En montura",
				COMBAT = "Fuera de comabte", 
				COMBATTOOLTIP = "Si tu y tu target estáis fuera de combate. Invisible es una excepción\n(mientras te mantengas en sigilo esta condición se omitirá)",
				SPELLISTARGETING = "Hechizo está apuntando",
				SPELLISTARGETINGTOOLTIP = "Ejemplo: Blizzard, Salto heroico, Trampa de congelación",
				LOOTFRAME = "Frame de botín",
				EATORDRINK = "Está comiendo o bebiendo",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Esconder mostrar rotación",
				DISABLEROTATIONDISPLAYTOOLTIP = "Esconder el grupo, que está ubicado normalmente en la\nparte inferior central de la pantalla",
				DISABLEBLACKBACKGROUND = "Esconder fondo negro", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Esconder el fondo negro en la esquina izquierda\nATENCIÓN: Esto puede causar comportamientos impredecibles!",
				DISABLEPRINT = "Esconder impresión",
				DISABLEPRINTTOOLTIP = "Esconder notificaciones de chat de todo\nATENCIÓN: Esto también esconderá [Debug] Error Identificado!",
				DISABLEMINIMAP = "Esconder icono en el minimapa",
				DISABLEMINIMAPTOOLTIP = "Esconder icono de esta UI en el minimapa",
				DISABLEPORTRAITS = "Ocultar retrato de clase",
				DISABLEROTATIONMODES = "Ocultar modos de rotación",
				DISABLESOUNDS = "Desactivar sonidos",
				CAMERAMAXFACTOR = "Factor máximo de cámara", 
				ROLETOOLTIP = "Dependiendo de este modo, la rotación funcionará\nAUTO - Define tu rol dependiendo de la mayoría de los talentos anidados en el árbol correcto",
				TOOLS = "Herramientas: ",
				LETMECASTTOOLTIP = "Desmontaje automático y soporte automático\nSi un hechizo o interacción falla debido a que está montado, desmontarás. Si falla debido a que te sientas, te levantarás\nLet Me Cast - Déjame echar!",
				TARGETCASTBAR = "Target CastBar",
				TARGETCASTBARTOOLTIP = "Muestra una barra de lanzamiento real debajo del marco de destino",
				TARGETREALHEALTH = "Target RealHealth",
				TARGETREALHEALTHTOOLTIP = "Muestra un valor de salud real en el marco objetivo.",
				TARGETPERCENTHEALTH = "Porcentaje de salud objetivo",
				TARGETPERCENTHEALTHTOOLTIP = "Muestra un valor de salud porcentual en el marco objetivo",
				AURADURATION = "Duración del aura",
				AURADURATIONTOOLTIP = "Muestra el valor de duración en fotogramas de unidad predeterminados",
				AURACCPORTRAIT = "Aura CC Portrait",
				AURACCPORTRAITTOOLTIP = "Muestra el retrato del control de multitudes en el marco objetivo.",	
				LOSSOFCONTROLPLAYERFRAME = "Pérdida de control: marco del jugador",
				LOSSOFCONTROLPLAYERFRAMETOOLTIP = "Muestra la duración de la pérdida de control en la posición vertical del jugador",
				LOSSOFCONTROLROTATIONFRAME = "Pérdida de control: marco de rotación",
				LOSSOFCONTROLROTATIONFRAMETOOLTIP = "Muestra la duración de la pérdida de control en la posición vertical de rotación (en el centro)",
				LOSSOFCONTROLTYPES = "Pérdida de control: disparadores de pantalla",	
			},
			[3] = {
				HEADBUTTON = "Acciones",
				HEADTITLE = "Bloquear | Cola",
				ENABLED = "Activado",
				NAME = "Nombre",
				DESC = "Nota",
				ICON = "Icono",
				SETBLOCKER = "Establecer\nBloquear",
				SETBLOCKERTOOLTIP = "Esto bloqueará la acción seleccionada en la rotación\nNunca la usará\n\nClickDerecho: Crear macro",
				SETQUEUE = "Establecer\nCola",
				SETQUEUETOOLTIP = "Pondrá la acción en la cola de rotación\nLo usará lo antes posible\n\nClickDerecho: Crear macro\nPuede pasar condiciones adicionales en la macro creada para la cola\nTales como puntos combinados (CP es clave), ejemplo: {Priority = 1, CP = 5}\nPuede encontrar claves aceptables con descripción en la función 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqueado: |r",
				UNBLOCKED = "|cff00ff00Desbloqueado: |r",
				KEY = "[Tecla: ",
				KEYTOTAL = "[Cola Total: ",
				KEYTOOLTIP = "Usa esta tecla en la pestaña MSG",
				ISFORBIDDENFORBLOCK = "está prohibido ponerlo en bloquear!",
				ISFORBIDDENFORQUEUE = "está prohibido ponerlo en cola!",
				ISQUEUEDALREADY = "ya existe en la cola!",
				QUEUED = "|cff00ff00Cola: |r",
				QUEUEREMOVED = "|cffff0000Borrado de la cola: |r",
				QUEUEPRIORITY = " tiene prioridad #",
				QUEUEBLOCKED = "|cffff0000no puede añadirse a la cola porque SetBlocker lo ha bloqueado!|r",
				SELECTIONERROR = "|cffff0000No has seleccionado una fila!|r",
				AUTOHIDDEN = "AutoOcultar acciones no disponibles",
				AUTOHIDDENTOOLTIP = "Hace que la tabla de desplazamiento sea más pequeña y clara ocultándola visualmente\nPor ejemplo, el tipo de personaje tiene pocos racials pero puede usar uno, esta opción hará que se escondan los demás raciales\nPara que sea más cómodo visualmente",				
				LUAAPPLIED = "El código LUA ha sido aplicado a ",
				LUAREMOVED = "El código LUA ha sido removido de ",
			},
			[4] = {
				HEADBUTTON = "Interrupciones",	
				HEADTITLE = "Perfil de Interrupciones",					
				ID = "ID",
				NAME = "Nombre",
				ICON = "Icono",
				CONFIGPANEL = "'Añadir Interrupción' Configuración",
				INTERRUPTFRONTSTRINGTITLE = "Seleccionar lista:",
				INTERRUPTTOOLTIP = "[Main] para unidades @target/@mouseover/@targettarget\n[Heal] para unidades @arena1-3 (healing)\n[PvP] para unidades @arena1-3 (controlmultitud)\n\nPuedes establecer diferentes tiempos para [Heal] y [PvP] (no en esta UI)",
				INPUTBOXTITLE = "Escribir habilidad:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): limpiar texto y borrar focus",
				INTEGERERROR = "Desbordamiento de enteros intentando almacenar > 7 números", 
				SEARCH = "Buscar por nombre o ID",
				TARGETMOUSEOVERLIST = "[Main] Lista",
				TARGETMOUSEOVERLISTTOOLTIP = "Desmarcado: interrumpirá CUALQUIER cast de forma aleatoria\nMarcado: interrumpirá solamente la lista específica de @target/@mouseover/@targettarget\nNota: en PvP se solucionará la interrupción de esa lista si está habilitado, de otra manera solo healers si mueren en menos de 3-4 segundos!\n\n@mouseover/@targettarget son opcionales y dependen de si están activados en la seccion spec\n\nClickDerecho: Crear macro",
				KICKTARGETMOUSEOVER = "[Main] Interrupciones\nHabilitado",					
				KICKTARGETMOUSEOVERTOOLTIP = "Desmarcado: @target/@mouseover interrupciones de la unidad no funcionan\nMarcado: @target/@mouseover interrupciones de la unidad funcionan\n\nClickDerecho: Crear macro",					
				KICKHEALONLYHEALER = "[Heal] Solo healers",					
				KICKHEALONLYHEALERTOOLTIP = "Desmarcado: lista válida para cualquier especialización de la unidad enemiga\n(e.g. Ench, Elem, SP, Retri)\nMarcado: lista solo válida para enemigos healers\n\nClickDerecho: Crear macro",
				KICKHEAL = "[Heal] Lista",
				KICKHEALPRINT = "[Heal] Lista of Interrupciones",
				KICKHEALTOOLTIP = "Desmarcado: @arena1-3 [Heal] lista personalizada no funcionará\nChecked: @arena1-3 [Heal] lista personalizada funcionará\n\nClickDerecho: Crear macro",
				KICKPVP = "[PvP] Lista",
				KICKPVPPRINT = "[PvP] Lista de Interrupciones",
				KICKPVPTOOLTIP = "Desmarcado: @arena1-3 [PvP] lista personalizada no funcionará\nChecked: @arena1-3 [PvP] lista personalizada funcionará\n\nClickDerecho: Crear macro",	
				KICKPVPONLYSMART = "[PvP] INTELIGENTE",
				KICKPVPONLYSMARTTOOLTIP = "Marcado: interrumpirá solamente acorden a la lógica establecida en la configuración del perfil lua. Ejemplo:\n1) Chain control en tu healer\n2) Alguien amigo (o tu) teneis buffs de Burst > 4 segundos\n3) Alguien morirá en menos de 8 segundos\n4) Tu (o @target) HP va a ejecutar la fase\nDesmarcado: interrumpirá esta lista siempre sin ningún tipo de lógica\n\nNota: Causa una demanda alta de la CPU\nClickDerecho: Crear macro",
				USEKICK = "Patada",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Añadir Interrupción",					
				ADDERROR = "|cffff0000No has especificado nada en 'Escribir Habilidad' o la habilidad no ha sido encontrada!|r",
				ADDTOOLTIP = "Añade habilidad del 'Escribir Habilidad'\n edita el cuadro a la lista seleccionada actual",
				REMOVE = "Borrar Interrupción",
				REMOVETOOLTIP = "Borra la habilidad seleccionada de la fila de la lista actual",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "Configuración de Caja",
				USEDISPEL = "Usar Dispel",
				USEPURGE = "Usar Purga",
				USEEXPELENRAGE = "Expel Enrague",
				USEEXPELFRENZY = "Expel Frenzy",
				HEADTITLE = "[Global] Dispel | Purga | Enrague",
				MODE = "Modo:",
				CATEGORY = "Categoría:",
				POISON = "Dispelea venenos",
				DISEASE = "Dispelea enfermedades",
				CURSE = "Dispelea maldiciones",
				MAGIC = "Dispelea magias",
				MAGICMOVEMENT = "Dispelea relentizaciones/raíces",
				PURGEFRIENDLY = "Purgar amigo",
				PURGEHIGH = "Purgar enemigo (prioridad alta)",
				PURGELOW = "Purgar enemigo (prioridad baja)",
				ENRAGE = "Expel Enrague",	
				ROLE = "Rol",
				ID = "ID",
				NAME = "Nombre",
				DURATION = "Duración\n >",
				STACKS = "Marcas\n >=",
				ICON = "Icono",					
				ROLETOOLTIP = "Tu rol para usar",
				DURATIONTOOLTIP = "Reacciona al aura si la duración de esta es mayor (>) de los segundos especificados\nIMPORTANTE: Auras sin duración como 'favor divido'\n(sanazión de Paladin) debe ser 0. Esto significa que el aura está presente!",
				STACKSTOOLTIP = "Reacciona al aura si tiene más o igual (>=) marcas especificadas",									
				CANSTEALORPURGE = "Solo si puedes\nrobar o purgar",					
				ONLYBEAR = "Solo si la unidad está\nen 'Forma de oso'",									
				CONFIGPANEL = "'Añadir Aura' Configuración",
				ANY = "Cualquiera",
				HEALER = "Healer",
				DAMAGER = "Tanque|Dañador",
				ADD = "Añadir Aura",					
				REMOVE = "Borrar Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Interacción del ratón",
				USETITLE = "Configuración de botones:",
				USELEFT = "Usar click izquierdo",
				USELEFTTOOLTIP = "Estás usando macro /target mouseover lo que no significa click!\n\nClickDerecho: Crear macro",
				USERIGHT = "Usar click derecho",
				LUATOOLTIP = "Para referirse a la unidad seleccionada, usa 'thisunit' sin comillas\nSi usas LUA en Categoría 'GameToolTip' entonces thisunit no es válido\nEl código debe tener boolean return (true) para procesar las condiciones\nEste código tiene setfenv que significa que no necesitas usar Action. para ninguna que lo tenga\n\nSi quieres borrar el codigo por defecto necesitarás escribir 'return true' sin comillas en vez de borrarlo todo",							
				BUTTON = "Click",
				NAME = "Nombre",
				LEFT = "Click izquierdo",
				RIGHT = "Click Derecho",
				ISTOTEM = "Es Totem",
				ISTOTEMTOOLTIP = "Si está activado comprobará @mouseover en tipo 'Totem' para el nombre dado\nTambién prevendrá click en situaciones si tu @target ya tiene algún totem",				
				INPUTTITLE = "Escribe el nombre del objeto (localizado!)", 
				INPUT = "Esta entrada no puede escribirse en mayúsculas",
				ADD = "Añadir",
				REMOVE = "Borrar",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "tótem enlace de espíritu",
				HEALINGTIDETOTEM = "tótem de marea de sanación",
				CAPACITORTOTEM = "tótem capacitador",					
				SKYFURYTOTEM = "tótem furia del cielo",					
				ANCESTRALPROTECTIONTOTEM = "tótem de protección ancestral",					
				COUNTERSTRIKETOTEM = "tótem de golpe de contraataque",
				-- Optional totems
				TREMORTOTEM = "tótem de tremor",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "tótem de carga de viento",
				EARTHBINDTOTEM = "tótem nexo terrestre",
				-- Flags by UnitName 
				HORDEBATTLESTANDARD = "estandarte de batalla de la horda",
				ALLIANCEBATTLESTANDARD = "estandarte de batalla de la alianza",
				-- GameToolTips
				ALLIANCEFLAG = "bandera de la alianza",
				HORDEFLAG = "bandera de la horda",
			},
			[7] = {
				HEADTITLE = "Mensaje del Sistema",
				USETITLE = "",
				MSG = "Sistema de MSG",
				MSGTOOLTIP = "Marcado: funcionando\nDesmarcado: sin funcionar\n\nClickDerecho: Crear macro",
				DISABLERETOGGLE = "Bloquear borrar cola",
				DISABLERETOGGLETOOLTIP = "Prevenir la repetición de mensajes borrados de la cola del sistema\nE.j. Posible spam de macro sin ser removida\n\nClickDerecho: Crear macro",
				MACRO = "Macro para tu grupo:",
				MACROTOOLTIP = "Esto es lo que debe ser enviado al chat de grupo para desencadenar la acción asignada en la tecla específica\nPara direccionar la acción específica de la unidad, añádelos al macro o déjalo tal como está en la rotación Single/AoE\nSoportado: raid1-40, party1-2, player, arena1-3\nSOLO UNA UNIDAD POR MENSAJE!\n\nTus compañeros pueden usar macros también, pero ten cuidado, deben ser leales a esto!\n NO DES ESTA MACRO A LA GENTE QUE NO LE PUEDA GUSTAR QUE USES BOT!",
				KEY = "Tecla",
				KEYERROR = "No has especificado una tecla!",
				KEYERRORNOEXIST = "La tecla no existe!",
				KEYTOOLTIP = "Debes especificar una tecla para bindear la acción\nPuedes extraer la tecla en el apartado 'Acciones'",
				MATCHERROR = "Este nombre ya coincide, usa otro!",				
				SOURCE = "El nombre de la personaje que dijo",					
				WHOSAID = "Quien dijo",
				SOURCETOOLTIP = "Esto es opcional. Puede dejarlo en blanco (recomendado)\nSi quieres configurarlo, el nombre debe ser exactamente el mismo al del chat de grupo",
				NAME = "Contiene un mensaje",
				ICON = "Icono",
				INPUT = "Escribe una frase para el sistema de mensajes",
				INPUTTITLE = "Frase",
				INPUTERROR = "No has escrito una frase!",
				INPUTTOOLTIP = "La frase aparecerá en cualquier coincidencia del chat de grupo (/party)\nNo se distingue entre mayúsculas y minúsculas\nContiene patrones, significa que la frase escrita por alguien con la combinación de palabras de raid, party, arena, party o player\nse adapta la acción a la meta slot deseada\nNo necesitas establecer los patrones listados aquí, se utilizan como un añadido a la macro\nSi el patrón no es encontrado, los espacios para las rotaciones Single y AoE serán usadas",				
			},
		},
	},
}
setmetatable(Localization[GameLocale], { __index = Localization[CL] })

function Action.GetLocalization()
	-- @return table localized with current language of interface 
	CL = TMW and TMW.db and TMW.db.global.ActionDB and TMW.db.global.ActionDB.InterfaceLanguage ~= "Auto" and Localization[TMW.db.global.ActionDB.InterfaceLanguage] and TMW.db.global.ActionDB.InterfaceLanguage or next(Localization[GameLocale]) and GameLocale or "enUS"
	L = Localization[CL]
	-- This need to prevent any errors caused by missed keys 
	setmetatable(L, { __index = Localization["enUS"] })
	return L
end 

-------------------------------------------------------------------------------
-- DB: Database
-------------------------------------------------------------------------------
Action.Enum = {}
Action.Data = {	
	ProfileUI = {},
	ProfileDB = {},
	ProfileEnabled = {
		["[GGL] Test"] 		= false,
	},
	DefaultProfile = {
		["WARRIOR"] 		= "[GGL] Warrior",
		["PALADIN"] 		= "[GGL] Paladin",
		["HUNTER"] 			= "[GGL] Hunter",
		["ROGUE"] 			= "[GGL] Rogue",
		["PRIEST"] 			= "[GGL] Priest",
		["SHAMAN"] 			= "[GGL] Shaman",
		["MAGE"] 			= "[GGL] Mage",
		["WARLOCK"] 		= "[GGL] Warlock",
		["DRUID"] 			= "[GGL] Druid",
		["BASIC"]			= "[GGL] Basic",
	},
	-- UI template config  
	theme = {
		off 				= "|cffff0000OFF|r",
		on 					= "|cff00ff00ON|r",
		dd = {
			width 			= 125,
			height 			= 25,
		},
	},
	-- Color
    C = {
		-- Standart 
        ["GREEN"] 			= "ff00ff00",
        ["RED"] 			= "ffff0000d",
        ["BLUE"] 			= "ff0900ffd",        
        ["YELLOW"]	 		= "ffffff00d",
        ["PINK"] 			= "ffff00ffd",
        ["LIGHT BLUE"] 		= "ff00ffffd",
		-- Nicely
		["LIGHTRED"]        = "ffff6060d",
		["TORQUISEBLUE"]	= "ff00C78Cd",
		["SPRINGGREEN"]	  	= "ff00FF7Fd",
		["GREENYELLOW"]   	= "ffADFF2Fd",
		["PURPLE"]		    = "ffDA70D6d",
		["GOLD"]            = "ffffcc00d",
		["GOLD2"]			= "ffFFC125d",
		["GREY"]            = "ff888888d",
		["WHITE"]           = "ffffffffd",
		["SUBWHITE"]        = "ffbbbbbbd",
		["MAGENTA"]         = "ffff00ffd",
		["ORANGEY"]		    = "ffFF4500d",
		["CHOCOLATE"]		= "ffCD661Dd",
		["CYAN"]            = "ff00ffffd",
		["IVORY"]			= "ff8B8B83d",
		["LIGHTYELLOW"]	    = "ffFFFFE0d",
		["SEXGREEN"]		= "ff71C671d",
		["SEXTEAL"]		    = "ff388E8Ed",
		["SEXPINK"]		    = "ffC67171d",
		["SEXBLUE"]		    = "ff00E5EEd",
		["SEXHOTPINK"]	    = "ffFF6EB4d",		
    },
	RANKCOLOR = {
		-- Simular to Healing Engine Raid1 and next 
		[1] = function() return 0.192157, 0.878431, 0.015686, 1.0 end,
		[2] = function() return 0.780392, 0.788235, 0.745098, 1.0 end,
		[3] = function() return 0.498039, 0.184314, 0.521569, 1.0 end,
		[4] = function() return 0.627451, 0.905882, 0.882353, 1.0 end,
		[5] = function() return 0.145098, 0.658824, 0.121569, 1.0 end,
		[6] = function() return 0.639216, 0.490196, 0.921569, 1.0 end,
		[7] = function() return 0.172549, 0.368627, 0.427451, 1.0 end,
		[8] = function() return 0.949020, 0.333333, 0.980392, 1.0 end,
		[9] = function() return 0.109804, 0.388235, 0.980392, 1.0 end,
		[10] = function() return 0.615686, 0.694118, 0.435294, 1.0 end,
		[11] = function() return 0.066667, 0.243137, 0.572549, 1.0 end,
		[12] = function() return 0.113725, 0.129412, 1.000000, 1.0 end,
		[13] = function() return 0.592157, 0.023529, 0.235294, 1.0 end,
		[14] = function() return 0.545098, 0.439216, 1.000000, 1.0 end,
		[15] = function() return 0.890196, 0.800000, 0.854902, 1.0 end,
		[16] = function() return 0.513725, 0.854902, 0.639216, 1.0 end,
		[17] = function() return 0.078431, 0.541176, 0.815686, 1.0 end,
		[18] = function() return 0.109804, 0.184314, 0.666667, 1.0 end,
		[19] = function() return 0.650980, 0.572549, 0.098039, 1.0 end,
		[20] = function() return 0.541176, 0.466667, 0.027451, 1.0 end,
	},
    -- Queue List
    Q = {},
	-- Timers
	T = {},
	-- Toggle Cache 
	TG = {},
	-- Auras 
	Auras = {},
}

-- Templates
-- Important: Default LUA overwrite problem was fixed by additional LUAVER key, however [3] "QLUA" and "LUA" was leaved and only 'Reset Settings' can clear it 
-- TMW.db.profile.ActionDB DefaultBase
local Factory = {
	-- Special keys: 
	-- ISINTERRUPT will swap ID to locale Name as key and create formated table 
	-- ISCURSOR will swap key localized Name from Localization table and create formated table 
	[1] = {
		CheckDeadOrGhost = true, 
		CheckDeadOrGhostTarget = true,
		CheckMount = false, 
		CheckCombat = false, 
		CheckSpellIsTargeting = true, 
		CheckLootFrame = true, 	
		CheckEatingOrDrinking = true,
		DisableRotationDisplay = false,
		DisableBlackBackground = false,
		DisablePrint = false,
		DisableMinimap = false,
		DisableClassPortraits = false,
		DisableRotationModes = false,
		DisableSounds = true,
		cameraDistanceMaxZoomFactor = true,
		LetMeCast = true,
		TargetCastBar = true,
		TargetRealHealth = true,
		TargetPercentHealth = true,		
		AuraDuration = true,
		AuraCCPortrait = true,
		LossOfControlPlayerFrame = true,
		LossOfControlRotationFrame = true,
		LossOfControlTypes = {
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[7] = true,
			[8] = true,
			[9] = true,
			[10] = true,
			[11] = true,
			[12] = true,
			[13] = true,
			[14] = true,
			[15] = true,
			[16] = true,
			[17] = true,
			[18] = true,
			[19] = true,
			[20] = true,
			[21] = true,
			[22] = true,
			[23] = true,
			[24] = true,
			[25] = true,
			[26] = true,
			[27] = true,
			[28] = true,
			[29] = true,
			[30] = true,
			[31] = true,
		},
		AutoTarget = true, 
		Potion = true, 
		Racial = true,	
		StopCast = true,
		AutoShoot = true,
		AutoAttack = true, 
		DBM = true,
		LOSCheck = false, 
		HE_Toggle = "ALL",
		HE_Pets = true,		
		HE_AnyRole = false,
		StopAtBreakAble = false,
		FPS = -0.01, 			
		Trinkets = {
			[1] = true, 
			[2] = true, 
		},
		Burst = "Auto",
		Role = "AUTO",
		HealthStone = 20,  
		ReTarget = true, 			
	}, 
	[3] = {			
		AutoHidden = true,	
		disabledActions = {},
		luaActions = {},
		QluaActions = {},
	},
	[4] = {
		BlackList = {
			[GameLocale] = {
				ISINTERRUPT = true,
				[22651] = "Sacrifice",
			},	
		},
		PvETargetMouseover = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		PvPTargetMouseover = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		Heal = {
			[GameLocale] = {	
				ISINTERRUPT = true,
				-- Priest
				[2050] = "Lesser Heal",
				[2060] = "Greater Heal",
				[6064] = "Heal",
				[596] = "Prayer of Healing",
				-- Druid
				[740] = "Tranquility",
				[8936] = "Regrowth",
				[25297] = "Healing Touch",
				-- Shaman
				[1064] = "Chain Heal",
				[331] = "Healing Wave",
				[8004] = "Lesser Healing Wave",
				-- Paladin
				[19750] = "Flash of Light",
				[635] = "Holy Light",
			},			
		},
		PvP = {
			[GameLocale] = {
				ISINTERRUPT = true,
				-- Shaman 
				[2645] = "Ghost Wolf",
				-- Mage 
				[118] = "Pollymorph",
				[28270] = "Polymorph: Cow",
				-- Priest 
				[605] = "Mind Control",
				[9484] = "Shackle Undead",
				[8129] = "Mana Burn",
				-- Hunter 
				[982] = "Revive pet",
				[1513] = "Scare Beast",
				-- Warlock 				
				[20757] = "Create Soulstone (Major)",
				[693] = "Create Soulstone (Minor)",
				[11730] = "Create Healthstone (Major)",
				[11729] = "Create Healthstone (Greater)",
				[5699] = "Create Healthstone",
				[1122] = "Inferno",
				[5782] = "Fear",
				[5484] = "Howl of Terror",
				[20755] = "Create Soulstone",	
				[710] = "Banish",
				-- Druid 
				[20484] = "Rebirth",
				[339] = "Entangling Roots",
				[2637] = "Hibernate",
				-- Rogue 
				[8681] = "Instant Poison",
				[3420] = "Crippling Poison",
				[13220] = "Wound Poison",
				[5763] = "Mind-numbing Poison",
				[2823] = "Deadly Poison",
				-- Paladin 
				[2878] = "Turn Undead",		
				-- Hunter 
				[19386] = "Wyvern Sting",
			},	
		},	
		TargetMouseoverList = false,
		KickHealOnlyHealers = false, 
		KickPvPOnlySmart = false,
		KickTargetMouseover = true, 
		KickHeal = true, 
		KickPvP = true, 		
	},
	[5] = {
		UseDispel = true,			
		UsePurge = true,
		UseExpelEnrage = true,
		UseExpelFrenzy = true,
		-- DispelPurgeEnrageRemap func will push needed keys here 
	},
	[6] = {
		UseLeft = true,
		UseRight = true,
		PvE = {
			UnitName = {
				[GameLocale] = {
					ISCURSOR = true,
				},
			},
			GameToolTip = {
				[GameLocale] = {
					ISCURSOR = true,
				},
			},
		},
		PvP = {
			UnitName = {
				[GameLocale] = {
					ISCURSOR = true,
					[Localization[GameLocale]["TAB"][6]["SPIRITLINKTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["HEALINGTIDETOTEM"]] 				= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["CAPACITORTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["SKYFURYTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["ANCESTRALPROTECTIONTOTEM"]] 		= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["COUNTERSTRIKETOTEM"]] 				= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["TREMORTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["GROUNDINGTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["WINDRUSHTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["EARTHBINDTOTEM"]] 					= { isTotem = true, Button = "LEFT" },
					[Localization[GameLocale]["TAB"][6]["HORDEBATTLESTANDARD"]]				= { Button = "LEFT" },					
					[Localization[GameLocale]["TAB"][6]["ALLIANCEBATTLESTANDARD"]]			= { Button = "LEFT" },
				}, 
			},
			GameToolTip = {
				[GameLocale] = {
					ISCURSOR = true,
					[Localization[GameLocale]["TAB"][6]["ALLIANCEFLAG"]] 					= { Button = "RIGHT" },
					[Localization[GameLocale]["TAB"][6]["HORDEFLAG"]] 						= { Button = "RIGHT" },
				},
			},
		},
	},
	[7] = {
		MSG_Toggle = true,
		DisableReToggle = false,
		msgList = {},
	},
}

-- TMW.db.global.ActionDB DefaultBase
local GlobalFactory = {	
	InterfaceLanguage = "Auto",	
	minimap = {},
	[5] = {		
		PvE = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
				-- Seduction
				--[270920] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				--return PlayerClass ~= "MAGE" ]] },
				-- Dominate Mind
				[15859] = {},		-- FIX ME: Is a buff?
				-- Cause Insanity
				[12888] = {},		-- FIX ME: Is a buff?
			},
			PurgeHigh = {		
				-- Molten Core: Deaden Magic
				[19714] = {},
			},
			PurgeLow = {
			},
			Poison = {    
				-- Onyxia: Brood Affliction: Green
				[23169] = {},
				-- Aspect of Venoxis
				[24688] = { dur = 1.5 },
				-- Atal'ai Poison
				[18949] = { dur = 1.5 },
				-- Baneful Poison
				[15475] = {},
				-- Barbed Sting
				[14534] = {},
				-- Bloodpetal Poison
				[14110] = {},
				-- Bottle of Poison
				[22335] = {},
				-- Brood Affliction: Green
				[23169] = {},
				-- Copy of Poison Bolt Volley
				[29169] = { enabled = false }, 
				-- Corrosive Poison 
				[13526] = {},
				-- Corrosive Venom Spit
				[20629] = { dur = 1.5 },
				-- Creeper Venom
				[14532] = {},
				-- Deadly Leech Poison
				[3388] = {},
				-- Deadly Poison
				[13582] = {},
				-- Enervate
				[22661] = {},
				-- Entropic Sting
				[23260] = {},
				-- Festering Bites
				[16460] = {},
				-- Larva Goo
				[21069] = {},
				-- Lethal Toxin
				[8256] = {},
				-- Maggot Goo
				[17197] = {},
				-- Abomination Spit
				[25262] = {},
				-- Minor Scorpion Venom Effect
				[5105] = {},
				-- Poisonous Spit
				[4286] = {},
				-- Slow Poison
				[3332] = {},
				-- Slime Bolt
				[28311] = {},
				-- Seeping Willow
				[17196] = {},
				-- Paralyzing Poison
				[3609] = { LUA = [[ return not UnitIsUnit(thisunit, "player") ]] },
			},
			Disease = {
				-- Rabies
				[3150] = {},
				-- Fevered Fatigue
				[8139] = {},
				-- Silithid Pox
				[8137] = {},
				-- Wandering Plague
				[3439] = {},
				-- Spirit Decay
				[8016] = {},
				-- Tetanus
				[8014] = {},
				-- Contagion of Rot
				[7102] = {},
				-- Volatile Infection
				[3584] = {},
				-- Mirkfallon Fungus
				[8138] = {},
				-- Infected Wound
				[3427] = {},
				-- Noxious Catalyst
				[5413] = {},
				-- Corrupted Agility
				[6817] = {},
				-- Irradiated
				[9775] = {},
				-- Infected Spine
				[12245] = {},
				-- Corrupted Stamina
				[6819] = {},
				-- Decayed Strength
				[6951] = {},
				-- Decayed Agility
				[7901] = {},
				-- Infected Bite
				[16128] = {},
				-- Plague Cloud
				[3256] = {},
				-- Plague Mind
				[3429] = {},
				-- Magenta Cap Sickness
				[10136] = {},
				-- Gift of Arthas
				[11374] = {},
				-- Festering Rash
				[15848] = {},
				-- Dark Plague
				[18270] = {},
				-- Fevered Plague
				[8600] = {},
				-- Rabid Maw
				[4316] = {},
				-- Brood Affliction: Red
				[23155] = {},
				-- Blight
				[9796] = {},
				-- Slime Dysentery
				[16461] = {},
				-- Creeping Mold
				[18289] = {},
				-- Weakening Disease
				[18633] = {},
				-- Putrid Breath
				[21062] = {},
				-- Dredge Sickness
				[14535] = {},
				-- Putrid Bite
				[30113] = {},
				-- Putrid Enzyme
				[14539] = {},			
				-- Black Rot
				[16448] = {},
				-- Cadaver Worms
				[16143] = {},
				-- Ghoul Plague
				[16458] = {},
				-- Putrid Stench
				[12946] = { LUA = [[ return not UnitIsUnit(thisunit, "player") ]] },
			}, 
			Curse = {	
				-- Molten Core: Lucifron's Curse
				[19703] = {},
				-- Molten Core: Gehennas' Curse 
				-- Note: Tank should be prioritized 
				[19716] = {},
				-- Shazzrah's Curse
				-- Note: Tank should be prioritized 
				[19713] = {},
				-- Shadowfang Keep: Veil of Shadow
				[7068] = { dur = 1.5 },
				-- Curse of Thorns
				[6909] = {},
				-- Wracking Pains
				[13619] = {},
				-- Curse of Stalvan
				[13524] = {},
				-- Curse of Blood
				[16098] = {},
				-- Curse of the Plague Rat
				[17738] = {},
				-- Discombobulate
				[4060] = {},
				-- Hex of Jammal'an
				[12480] = {},
				-- Shrink
				[24054] = {},
				-- Curse of the Firebrand
				[16071] = {},
				-- Enfeeble
				[11963] = {},
				-- Piercing Shadow
				[16429] = {},
				-- Rage of Thule
				[3387] = {},
				-- Mark of Kazzak
				[21056] = {},
				-- Curse of the Dreadmaul
				[11960] = {},
				-- Banshee Curse
				[17105] = {},
				-- Corrupted Fear
				[21330] = {},
				-- Curse of Impotence
				[22371] = {},
				-- Delusions of Jin'do
				[24306] = {},
				-- Haunting Phantoms				-- FIX ME: Does it need here ? (Naxxramas)
				[16336] = {},
				-- Tainted Mind
				[16567] = {},
				-- Ancient Hysteria
				[19372] = {},
				-- Breath of Sargeras
				[28342] = {},
				-- Curse of the Elemental Lord
				[26977] = {},
				-- Curse of Mending
				[15730] = {},
				-- Curse of the Darkmaster
				[18702] = {},
				-- Arugal's Curse
				[7621] = {},
			},
			Magic = {	
				-- Molten Core: Ignite Mana
				[19659] = {},
				-- Molten Core: Impending Doom
				[19702] = { dur = 1.5 },
				-- Molten Core: Panic
				[19408] = {},			
				-- Molten Core: Magma Splash
				[13880] = { dur = 1.5 },
				-- Molten Core: Ancient Despair
				[19369] = { dur = 1.5 },
				-- Molten Core: Soul Burn
				[19393] = { dur = 1.5 },
				-- Onyxia: Greater Polymorph
				[22274] = {},
				-- Onyxia: Wild Polymorph
				[23603] = {},
				-- Firelords: Soul Burn
				[19393] = {},
				-- Ancient Despair
				[19369] = {},
				-- Dominate Mind
				[20740] = {},
				-- Immolate
				[12742] = { dur = 2 },
				-- Shadow Word: Pain 				-- FIX ME: Does it needs in PvE (?)
				[23952] = { dur = 2 },
				-- Misc: Reckless Charge
				[13327] = { dur = 1 },
				-- Misc: Hex 
				[17172] = {},
				-- Polymorph Backfire (Azshara)
				[28406] = {},	
				-- Polymorph: Chicken
				[228] = {},
				-- Chains of Ice
				[113] = { dur = 12 },
				-- Grasping Vines
				[8142] = { dur = 4 },
				-- Naralex's Nightmare
				[7967] = {},
				-- Thundercrack
				[8150] = { dur = 1 },
				-- Screams of the Past
				[7074] = { dur = 1 },
				-- Smoke Bomb
				[7964] = { dur = 1 },
				-- Ice Blast
				[11264] = { dur = 6 },
				-- Pacify
				[10730] = {},
				-- Sonic Burst
				[8281] = { dur = 0.5 },
				-- Enveloping Winds
				[6728] = { dur = 1 },
				-- Petrify
				[11020] = { dur = 1 },
				-- Freeze Solid
				[11836] = { dur = 1 },
				-- Deep Slumber
				[12890] = { LUA = [[ return not UnitIsUnit(thisunit, "player") ]] },
				-- Crystallize
				[16104] = { dur = 1, LUA = [[ return not UnitIsUnit(thisunit, "player") ]] },
				-- Enchanting Lullaby
				[16798] = { dur = 1 },
				-- Burning Winds
				[17293] = { dur = 1 },
				-- Banshee Shriek
				[16838] = { dur = 1 },
			}, 
			Enrage = {
			},
			Frenzy = {
				-- Frenzy 
				[19451] = { dur = 1.5 },
			},
		},
		PvP = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
				-- Seduction
				--[270920] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				--return PlayerClass ~= "MAGE" ]] },
			},
			PurgeHigh = {
				-- Paladin: Blessing of Protection
				[1022] = { dur = 1 },
				-- Paladin: Divine Favor 
				[20216] = { dur = 0 },
				-- Priest: Power Infusion
				[10060] = { dur = 4 },
				-- Mage: Combustion
				[11129] = { dur = 4 },
				-- Mage: Arcane Power
				[12042] = { dur = 4 },
				-- Priest (Human): Feedback
				[13896] = { dur = 1.5 },
				-- Druid | Shaman: Nature's Swiftness
				[16188] = { dur = 1.5 },
				-- Shaman: Elemental Mastery
				[16166] = { dur = 1.5 },
			},
			PurgeLow = {
				-- Paladin: Blessing of Freedom  
				[1044] = { dur = 1.5 },
				-- Druid: Rejuvenation
				[774] = { dur = 0, onlyBear = true },
				-- Druid: Regrow
				[8936] = { dur = 0, onlyBear = true },
				-- Druid: Mark of the Wild
				[1126] = { dur = 0, onlyBear = true },
			},
			Poison = {
				-- Hunter: Wyvern Sting
				[19386] = { dur = 0 },
				-- Hunter: Serpent Sting
				[1978] = { dur = 3 },
				-- Hunter: Viper Sting
				[3034] = { dur = 2 },
				-- Hunter: Scorpid Sting
				[3043] = { dur = 1.5 },
				-- Rogue: Slow Poison
				[3332] = {},
			},
			Disease = {
			},
			Curse = {
				-- Voodoo Hex   			(Shaman) 				-- I AM NOT SURE
				[8277] = {}, 			
				-- Hex of Weakness			(Priest - Troll)
				[9035] = {},
				-- Warlock: Curse of Tongues
				[1714] = { dur = 3 },
				-- Warlock: Curse of Weakness
				[702] = { dur = 3 },
				-- Warlock: Curse of Doom
				[603] = {},
				-- Warlock: Curse of Shadow
				[17862] = {},
				-- Warlock: Curse of the Elements
				[1490] = {},
				-- Corrupted Fear (set bonus)
				[21330] = {},
			},
			Magic = {			
				-- Paladin: Repentance
				[20066] = { dur = 1.5 },
				-- Paladin: Hammer of Justice
				[853] = { dur = 0 },
				-- Hunter: Freezing Trap
				[1499] = { dur = 1 },
				-- Hunter: Entrapment
				[19185] = { dur = 1.5 },
				-- Hunter: Hunter's Mark
				[14325] = {},
				-- Hunter: Trap 
				[8312] = { dur = 1 },
				-- Rogue: Kick - Silenced
				[18425] = { dur = 1 },
				-- Priest: Mind Control 
				[605] = { dur = 0 },
				-- Priest: Psychic Scream
				[8122] = { dur = 1.5 },
				-- Priest: Shackle Undead 
				[9484] = { dur = 1 },
				-- Priest: Silence
				[15487] = { dur = 1 },
				-- Priest: Blackout
				[15269] = { dur = 1 },
				-- Mage: Polymorph 
				[118] = { dur = 1.5 },
				-- Mage: Polymorph: Sheep 
				[851] = { dur = 1.5 },
				-- Mage: Polymorph: Cow 
				[28270] = { dur = 1.5 },
				-- Mage: Polymorph: Turtle 
				[28271] = { dur = 1.5 },
				-- Mage: Polymorph: Pig 
				[28272] = { dur = 1.5 },
				-- Mage: Frost Nova  
				[122] = { dur = 1 },
				-- Warlock: Banish 
				[710] = {},				
				-- Warlock: Fear 
				[5782] = { dur = 1.5 },
				-- Warlock: Seduction
				[6358] = { dur = 1.5 },	
				-- Warlock: Howl of Terror
				[5484] = { dur = 1.5 },
				-- Warlock: Death Coil
				[6789] = { dur = 1 },
				-- Warlock: Spell Lock (Felhunter)
				[24259] = { dur = 1 },
				-- Druid: Hibernate 
				[2637] = { dur = 1.5 },
				-- Druid: Faerie Fire (Feral)
				[17390] = { dur = 0 },					
				-- Mage: Ice Nova 
				[22519] = { dur = 1 },
				-- Druid: Entangling Roots
				[339] = { dur = 1 },					
				-- Trinket: Tidal Charm
				[835] = { dur = 1 },
				-- Iron Grenade
				[4068] = {},
				-- Sleep (Green Whelp Armor chest)
				[9159] = {},
				-- Arcane Bomb
				[19821] = {},
				-- Silence (Silent Fang sword)
				[18278] = {},
				-- Highlord's Justice (Alliance Stormwind Boss - Highlord Bolvar Fordragon)
				[20683] = {},
				-- Crusader's Hammer (Horde Stratholme - Boss Grand Crusader Dathrohan)
				[17286] = {},
				-- Veil of Shadow (Horde Orgrimmar - Boss Vol'jin)
				[17820] = {},
				-- Glimpse of Madness (Dark Edge of Insanity axe)
				[26108] = { dur = 1 },
			},
			Enrage = {
				-- Berserker Rage
				[18499] = { dur = 1 },
				-- Enrage
				[12880] = { dur = 1 },
			},
			Frenzy = {
			},
		},
	},
}

-- Table controlers 	
local function tMerge(default, new, special, nonexistremove)
	-- Forced push all keys new > default 
	-- if special true will replace/format special keys 
	local result = {}
	
	for k, v in pairs(default) do 
		if type(v) == "table" then 
			if special and v.ISINTERRUPT then 
				result[k] = {}
				for ID in pairs(v) do
					if type(ID) == "number" then 												
						result[k][Spell:CreateFromSpellID(ID):GetSpellName()] = { Enabled = true, ID = ID, useKick = true, useCC = true, useRacial = true }
					end 
				end
			elseif special and v.ISCURSOR then 
				result[k] = {}
				for KeyLocale, Val in pairs(v) do 					
					if type(Val) == "table" then 				
						result[k][KeyLocale] = { Enabled = true, Button = Val.Button, isTotem = Val.isTotem } 
					end 
				end 
			elseif new[k] ~= nil then 
				result[k] = tMerge(v, new[k], special, nonexistremove)
			else
				result[k] = tMerge(v, v, special, nonexistremove)
			end 
		elseif new[k] ~= nil then 
			result[k] = new[k]
		elseif not nonexistremove then  	
			result[k] = v				
		end 
	end 
	
	if new ~= default then 
		for k, v in pairs(new) do 
			if type(v) == "table" then 
				result[k] = tMerge(type(result[k]) == "table" and result[k] or v, v, special, nonexistremove)
			else 
				result[k] = v
			end 
		end 
	end
	
	return result
end

local function tCompare(default, new, upkey, skip)
	local result = {}
	
	if (new == nil or next(new) == nil) and default ~= nil then 
		result = tMerge(result, default)		
	else 		
		if default ~= nil then 
			for k, v in pairs(default) do
				if not skip and new[k] ~= nil then 
					if type(v) == "table" then 
						result[k] = tCompare(v, new[k], k)
					elseif type(v) == type(new[k]) then 
						-- Overwrite default LUA specified in profile (default) even if user made custom (new), doesn't work for [3] "QLUA" and "LUA" 
						if k == "LUA" and default.LUAVER ~= nil and default.LUAVER ~= new.LUAVER then 							
							result[k] = v
							Action.Print(L["DEBUG"] .. (upkey or "") .. " (LUA) " .. " " .. L["RESETED"]:lower())
						elseif k == "LUAVER" then 
							result[k] = v  
						else 
							result[k] = new[k]
						end 
					elseif new[k] ~= nil then 
						result[k] = v
					end 
				else
					result[k] = v 
				end			
			end 
		end 
		
		for k, v in pairs(new) do 
			if type(v) == "table" then 	
				result[k] = tCompare(result[k], v, k, true)		
			elseif result[k] == nil then 
				result[k] = v
			--else 
				-- Debugs keys which has been updated by default 
				--Action.Print(L["DEBUG"] .. "tCompare key: " .. k .. "  upkey: " .. (upkey or ""))				
			end	
		end 
	end 				
	
	return result 
end

-- TMW.db.global.ActionDB[5] -> TMW.db.profile.ActionDB[5]
local isDispelCategory = {
	["Poison"] = true,
	["Disease"] = true,
	["Curse"] = true,
	["Magic"] = true,
}
local function DispelPurgeEnrageRemap()
	-- Note: This function should be called every time when [5] "Auras" in UI has been changed or shown
	-- Creates localization on keys and put them into profile db relative spec 
	wipe(Action.Data.Auras)
	for Mode, Mode_v in pairs(TMW.db.global.ActionDB[5]) do 
		if not Action.Data.Auras[Mode] then 
			Action.Data.Auras[Mode] = {}
		end 
		for Category, Category_v in pairs(Mode_v) do 			
			if not Action.Data.Auras[Mode][Category] then 
				Action.Data.Auras[Mode][Category] = {} 
			end 
			for SpellID, v in pairs(Category_v) do 
				local Name = Spell:CreateFromSpellID(SpellID):GetSpellName()	
				Action.Data.Auras[Mode][Category][Name] = { 
					ID = SpellID, 
					Name = Name, 
					Enabled = true,
					Role = v.role or "ANY",
					Dur = v.dur or 0,
					Stack = v.stack or 0,
					canStealOrPurge = v.canStealOrPurge,
					onlyBear = v.onlyBear,
					LUA = v.LUA,
				} 
				if v.enabled ~= nil then 
					Action.Data.Auras[Mode][Category][Name].Enabled = v.enabled 
				end 
			end 			 
		end 
	end 
	-- Creates relative to each specs which can dispel or purje anyhow
	local UnitAuras = {
		["WARRIOR"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				PurgeFriendly = Action.Data.Auras.PvE.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvE.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvE.PurgeLow,				
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				PurgeFriendly = Action.Data.Auras.PvP.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvP.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvP.PurgeLow,
			},
		},
		["DRUID"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Poison = Action.Data.Auras.PvE.Poison,
				Curse = Action.Data.Auras.PvE.Curse,
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Poison = Action.Data.Auras.PvP.Poison,
				Curse = Action.Data.Auras.PvP.Curse,
			},
		},
		["MAGE"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Curse = Action.Data.Auras.PvE.Curse,
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Curse = Action.Data.Auras.PvP.Curse,
			},
		},
		["PALADIN"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Poison = Action.Data.Auras.PvE.Poison,
				Magic = Action.Data.Auras.PvE.Magic,
				Disease = Action.Data.Auras.PvE.Disease,
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Poison = Action.Data.Auras.PvP.Poison,
				Magic = Action.Data.Auras.PvP.Magic,
				Disease = Action.Data.Auras.PvP.Disease,
			},
		},
		["PRIEST"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Magic = Action.Data.Auras.PvE.Magic,
				Disease = Action.Data.Auras.PvE.Disease,
				PurgeFriendly = Action.Data.Auras.PvE.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvE.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvE.PurgeLow,				
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Magic = Action.Data.Auras.PvP.Magic,
				Disease = Action.Data.Auras.PvP.Disease,
				PurgeFriendly = Action.Data.Auras.PvP.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvP.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvP.PurgeLow,
			},
		}, 
		["SHAMAN"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Poison = Action.Data.Auras.PvE.Poison,
				Disease = Action.Data.Auras.PvE.Disease,
				PurgeFriendly = Action.Data.Auras.PvE.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvE.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvE.PurgeLow,				
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Poison = Action.Data.Auras.PvP.Poison,
				Disease = Action.Data.Auras.PvP.Disease,
				PurgeFriendly = Action.Data.Auras.PvP.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvP.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvP.PurgeLow,
			},
		},
		["WARLOCK"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				PurgeFriendly = Action.Data.Auras.PvE.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvE.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvE.PurgeLow,				
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				PurgeFriendly = Action.Data.Auras.PvP.PurgeFriendly,
				PurgeHigh = Action.Data.Auras.PvP.PurgeHigh,
				PurgeLow = Action.Data.Auras.PvP.PurgeLow,
			},
		},
		["HUNTER"] = {
			PvE = {
				BlackList = Action.Data.Auras.PvE.BlackList,
				Frenzy = Action.Data.Auras.PvE.Frenzy,		
			},
			PvP = {
				BlackList = Action.Data.Auras.PvP.BlackList,
				Frenzy = Action.Data.Auras.PvP.Frenzy,
			},
		},
	}

	if UnitAuras[Action.PlayerClass] then 
		Action.Data.Auras.DisableCheckboxes = { UseDispel = true, UsePurge = true, UseExpelEnrage = true, UseExpelFrenzy = true }
		for Mode, Mode_v in pairs(UnitAuras[Action.PlayerClass]) do 
			for Category, Category_v in pairs(Mode_v) do 
				if not TMW.db.profile.ActionDB[5][Mode] then 
					TMW.db.profile.ActionDB[5][Mode] = {}
				end 
				if not TMW.db.profile.ActionDB[5][Mode][Category] then 
					TMW.db.profile.ActionDB[5][Mode][Category] = {}
				end 

				-- Always to reset
				TMW.db.profile.ActionDB[5][Mode][Category][GameLocale] = {}
			
				if isDispelCategory[Category] then 
					Action.Data.Auras.DisableCheckboxes.UseDispel = false 
				elseif Category:match("Purge") then 
					Action.Data.Auras.DisableCheckboxes.UsePurge = false 
				elseif Category:match("Enrage") then 
					Action.Data.Auras.DisableCheckboxes.UseExpelEnrage = false 
				elseif Category:match("Frenzy") then 	
					Action.Data.Auras.DisableCheckboxes.UseExpelFrenzy = false 
				end	
				
				if #Category_v > 0 then 
					for i = 1, #Category_v do 
						for k, v in pairs(Category_v[i]) do 
							TMW.db.profile.ActionDB[5][Mode][Category][GameLocale][k] = v
						end 
					end 
				else
					for k, v in pairs(Category_v) do 
						TMW.db.profile.ActionDB[5][Mode][Category][GameLocale][k] = v
					end 
				end 
			end 	
		end
		 
		for Checkbox, v in pairs(Action.Data.Auras.DisableCheckboxes) do 
			if v then 
				TMW.db.profile.ActionDB[5][Checkbox] = not v
			end 
		end 
	else  
		Action.Data.Auras.DisableCheckboxes = nil	
		TMW.db.profile.ActionDB[5].UseDispel = false 
		TMW.db.profile.ActionDB[5].UsePurge = false 
		TMW.db.profile.ActionDB[5].UseExpelEnrage = false
		TMW.db.profile.ActionDB[5].UseExpelFrenzy = false
	end 		
end

-------------------------------------------------------------------------------
-- UI: Containers
-------------------------------------------------------------------------------
local tabFrame, strElemBuilder
local function ConvertSpellNameToID(spellName)
	local Name, _, _, _, _, _, ID = GetSpellInfo(spellName)
	if not Name then 
		for i = 1, 350000 do 
			Name, _, _, _, _, _, ID = GetSpellInfo(i) 
			if Name ~= nil and Name ~= "" and Name == spellName then 
				return ID
			end 
		end 
	end 
	return ID 
end 
ConvertSpellNameToID = TMW:MakeSingleArgFunctionCached(ConvertSpellNameToID)
local function GetTableKeyIdentify(action)
	-- Using to link key in DB
	if not action.TableKeyIdentify then 
		action.TableKeyIdentify = strElemBuilder(nil, action.SubType, action.ID, action.isRank, action.Desc, action.Color)
	end 
	return action.TableKeyIdentify
end
local function ShowTooltip(parent, show, ID, Type)
	if show then
		if ID == nil or Type == "SwapEquip" then 
			GameTooltip:Hide()
			return 
		end
		GameTooltip:SetOwner(parent)
		if Type == "Trinket" or Type == "Potion" or Type == "Item" then 
			GameTooltip:SetItemByID(ID) 
		else
			GameTooltip:SetSpellByID(ID)
		end 
	else
		GameTooltip:Hide()
	end
end
local function LayoutSpace(parent)
	-- Util for EasyLayout to create "space" in row since it support only elements
	return StdUi:FontString(parent, '')
end 
local function GetWidthByColumn(parent, col, offset)
	-- Util for EasyLayout to provide correctly width for dropdown menu since lib has bug to properly resize it 
	local left = parent.layout.padding.left
	local right = parent.layout.padding.right
	local width = parent:GetWidth() - parent.layout.padding.left - parent.layout.padding.right
	local gutter = parent.layout.gutter
	local columns = parent.layout.columns
	return (width / (columns / col)) - 2 * gutter + (offset or 0)
end 
local function GetAnchor(tab, spec)
	-- Uses for EasyLayout (only resizer / comfort remap)
	if tab.name == 1 or tab.name == 2 then 
		return tab.childs[spec].scrollChild
	else 
		return tab.childs[spec]
	end  
end 
local function GetKids(tab, spec)
	-- Uses for EasyLayout (resizer / toggles)
	if tab.name == 1 or tab.name == 2 then 
		return tab.childs[spec].scrollChild:GetChildrenWidgets()
	else 
		return tab.childs[spec]:GetChildrenWidgets()
	end  
end 
local function CreateResizer(parent)
	if not TMW or parent.resizer then return end 
	-- Pre Loading options in case if first time it failed 
	if TMW.Classes.Resizer_Generic == nil then 
		TMW:LoadOptions()
	end 
	local frame = {}
	frame.resizer = TMW.Classes.Resizer_Generic:New(parent)
	frame.resizer:Show()
	frame.resizer.y_min = parent:GetHeight()
	frame.resizer.x_min = parent:GetWidth()
	TMW:TT(frame.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
	return frame
end 
local function CraftMacro(Name, Macro, perCharacter, QUESTIONMARK, leaveNewLine)
	if MacroFrame then 
		MacroFrame.CloseButton:Click()
	end
	local numglobal, numperchar = GetNumMacros()	
	local NumMacros = perCharacter and numperchar or numglobal
	if (perCharacter and NumMacros >= MAX_CHARACTER_MACROS) or (not perCharacter and NumMacros >= MAX_ACCOUNT_MACROS) then 
		Action.Print(L["MACROLIMIT"])
		GameMenuButtonMacros:Click()
		return 
	end 
	Name = string.gsub(Name, "\n", " ")
	for i = 1, MAX_CHARACTER_MACROS + MAX_ACCOUNT_MACROS do 
		if GetMacroInfo(i) == Name then 
			Action.Print(Name .. " - " .. L["MACROEXISTED"])
			GameMenuButtonMacros:Click()
			return 
		end 
	end 
	CreateMacro(Name, QUESTIONMARK and "INV_MISC_QUESTIONMARK" or GetMacroIcons()[1], not leaveNewLine and string.gsub(Macro, "\n", " ") or Macro, perCharacter and 1 or nil)			
	Action.Print(L["MACRO"] .. " " .. Name .. " " .. L["CREATED"] .. "!")
	GameMenuButtonMacros:Click()
end
Action.CraftMacro = CraftMacro
local function GetActionTableByKey(key)
	-- @return table or nil 
	-- Note: Returns table object which can be used to pass methods by specified key 
	if Action[Action.PlayerClass] and Action[Action.PlayerClass][key] then 
		return Action[Action.PlayerClass][key]
	elseif Action[key] and type(Action[key]) == "table" and Action[key].Type and Action[key].ID and Action[key].Desc then 
		return Action[key]
	end 
end 
local function SetProperlyScale()
	if GetCVar("useUiScale") ~= "1" then
		Action.MainUI:SetScale(0.8)
	else 
		Action.MainUI:SetScale(1)
	end 	
end 

-------------------------------------------------------------------------------
-- UI: LUA - Container
-------------------------------------------------------------------------------
local Functions = {}
local function GetCompiledFunction(luaCode, thisunit)
	local func, key, err
	luaCode = luaCode:gsub("thisunit", '"' .. (thisunit or "") .. '"') 
	if Functions[luaCode] then
		key, err = tostring(Functions[luaCode]):gsub("function: ", "LF_")
		return Functions[luaCode], key, err
	end	

	func, err = loadstring(luaCode)
	
	if func then
		setfenv(func, setmetatable(Action, { __index = _G }))
		key = tostring(func):gsub("function: ", "LF_")
		Functions[luaCode] = func
	end	
	return func, key, err
end
local function RunLua(luaCode, thisunit)
	if not luaCode or luaCode == "" then 
		return true 
	end 
	
	local func, key, err = GetCompiledFunction(luaCode, thisunit)
	return func and func()
end
local function CreateLuaEditor(parent, title, w, h, editTT)
	-- @return frame which is simular between WeakAura and TellMeWhen (if IndentationLib loaded, otherwise without effects like colors and tabulations)
	local LuaWindow = StdUi:Window(parent, title, w, h)
	LuaWindow:SetShown(false)
	LuaWindow:SetFrameStrata("DIALOG")
	LuaWindow:SetMovable(false)
	LuaWindow:EnableMouse(false)
	StdUi:GlueAfter(LuaWindow, Action.MainUI, 0, 0)	
	
	LuaWindow.UseBracketMatch = StdUi:Checkbox(LuaWindow, L["TAB"]["BRACKETMATCH"])
	StdUi:GlueTop(LuaWindow.UseBracketMatch, LuaWindow, 15, -15, "LEFT")
	
	LuaWindow.LineNumber = StdUi:FontString(LuaWindow, "")
	LuaWindow.LineNumber:SetFontSize(14)
	StdUi:GlueTop(LuaWindow.LineNumber, LuaWindow, 0, -30)
	
	LuaWindow.EditBox = StdUi:MultiLineBox(LuaWindow, 100, 5, "")
	LuaWindow.EditBox:SetText("")
	LuaWindow.EditBox.panel:SetBackdropColor(0, 0, 0, 1)
	StdUi:GlueAcross(LuaWindow.EditBox.panel, LuaWindow, 5, -50, -5, 5)
	
	if editTT then 
		StdUi:FrameTooltip(LuaWindow.EditBox, editTT, nil, "TOPLEFT", "TOPLEFT")
	end 	
	
	-- The indention lib overrides GetText, but for the line number
	-- display we ned the original, so save it here
	LuaWindow.EditBox.GetOriginalText = LuaWindow.EditBox.GetText
	-- ForAllIndentsAndPurposes
	if IndentationLib then
		-- Monkai   
		local theme = {		
			["Table"] = "|c00ffffff",
			["Arithmetic"] = "|c00f92672",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c00f92672",
			["Special"] = "|c0066d9ef",
			["Keyword"] =  "|c00f92672",
			["Comment"] = "|c0075715e",
			["Number"] = "|c00ae81ff",
			["String"] = "|c00e6db74"
		}
  
		local color_scheme = { [0] = "|r" }
		color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
		color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
		color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

		color_scheme["..."] = theme["Table"]
		color_scheme["{"] = theme["Table"]
		color_scheme["}"] = theme["Table"]
		color_scheme["["] = theme["Table"]
		color_scheme["]"] = theme["Table"]

		color_scheme["+"] = theme["Arithmetic"]
		color_scheme["-"] = theme["Arithmetic"]
		color_scheme["/"] = theme["Arithmetic"]
		color_scheme["*"] = theme["Arithmetic"]
		color_scheme[".."] = theme["Arithmetic"]

		color_scheme["=="] = theme["Relational"]
		color_scheme["<"] = theme["Relational"]
		color_scheme["<="] = theme["Relational"]
		color_scheme[">"] = theme["Relational"]
		color_scheme[">="] = theme["Relational"]
		color_scheme["~="] = theme["Relational"]

		color_scheme["and"] = theme["Logical"]
		color_scheme["or"] = theme["Logical"]
		color_scheme["not"] = theme["Logical"]
		
		IndentationLib.enable(LuaWindow.EditBox, color_scheme, 4)		
	end 
	
	-- Bracket Matching
	LuaWindow.EditBox:SetScript("OnChar", function(self, char)		
		if not IsControlKeyDown() and LuaWindow.UseBracketMatch:GetChecked() then 
			if char == "(" then
				LuaWindow.EditBox:Insert(")")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "{" then
				LuaWindow.EditBox:Insert("}")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "[" then
				LuaWindow.EditBox:Insert("]")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			end	
		end 
	end)
		
	-- Update Line Number 
	LuaWindow.EditBox:SetScript("OnCursorChanged", function()
		local cursorPosition = LuaWindow.EditBox:GetCursorPosition()
		local next = -1
		local line = 0
		while (next and cursorPosition >= next) do
			next = LuaWindow.EditBox.GetOriginalText(LuaWindow.EditBox):find("[\n]", next + 1)
			line = line + 1
		end
		LuaWindow.LineNumber:SetText(line)
	end)	
	
	-- Close handlers 		
	LuaWindow.closeBtn:SetScript("OnClick", function(self) 
		LuaWindow.LineNumber:SetText(nil)
		local Code = LuaWindow.EditBox:GetText()
		local CodeClear = Code:gsub("[\r\n\t%s]", "")		
		if CodeClear ~= nil and CodeClear:len() > 0 then 
			-- Check user mistakes with quotes on thisunit 
			if Code:find("'thisunit'") or Code:find('"thisunit"') then 				
				LuaWindow.EditBox.LuaErrors = true	
				error("thisunit must be without quotes!")
				return
			end 
		
			-- Check syntax on errors
			local func, key, err = GetCompiledFunction(Code)
			if not func then 				
				LuaWindow.EditBox.LuaErrors = true	
				error(err)
				return
			end 
			
			-- Check game API on errors
			local success, errorMessage = pcall(func)
			if not success then  					
				LuaWindow.EditBox.LuaErrors = true		
				error(errorMessage)
				return
			end 		
			
			LuaWindow.EditBox.LuaErrors = nil 
		else 
			LuaWindow.EditBox.LuaErrors = nil
			LuaWindow.EditBox:SetText("")
		end 
		self:GetParent():Hide()
	end)
	
	LuaWindow:SetScript("OnHide", function(self)
		self.closeBtn:Click() 
	end)
	
	LuaWindow.EditBox:SetScript("OnEscapePressed", function() 
		LuaWindow.closeBtn:Click() 
	end)
	
	return LuaWindow
end 

-- [3] LUA API 
function Action:GetLUA()
	return TMW.db.profile.ActionDB[3].luaActions[GetTableKeyIdentify(self)] 
end

function Action:SetLUA(luaCode)
	TMW.db.profile.ActionDB[3].luaActions[GetTableKeyIdentify(self)] = luaCode
end 

function Action:RunLua(thisunit)
	return RunLua(self:GetLUA(), thisunit)
end

-- [3] QLUA API 
function Action:GetQLUA()
	return TMW.db.profile.ActionDB[3].QluaActions[GetTableKeyIdentify(self)] 
end

function Action:SetQLUA(luaCode)
	TMW.db.profile.ActionDB[3].QluaActions[GetTableKeyIdentify(self)] = luaCode
end 

function Action:RunQLua(thisunit)
	return RunLua(self:GetQLUA(), thisunit)
end

-------------------------------------------------------------------------------
-- UI: API
-------------------------------------------------------------------------------
-- [1] Mode 
function Action.ToggleMode()
	Action.IsLockedMode = true
	Action.IsInPvP = not Action.IsInPvP	
	Action.Print(L["SELECTED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
	TMW:Fire("TMW_ACTION_MODE_CHANGED")
end 

-- [1] Role 
function Action.ToggleRole(fixed, between)
	local Current = Action.GetToggle(1, "Role")
	
	local set
	if between and fixed ~= between then 	
		if Current == fixed then 
			set = between
		else 
			set = fixed
		end 
	end 
	
	if Current ~= "AUTO" then 		
		Action.Data.TG.Role = Current
		Current = "AUTO"
	elseif Action.Data.TG.Role == nil then  
		Current = "DAMAGER"
		Action.Data.TG.Role = Current
	else
		Current = Action.Data.TG.Role
	end 			
	
	Action.SetToggle({1, "Role", L["TAB"][5]["ROLE"] .. ": "}, set or fixed or Current)	
	Action:PLAYER_SPECIALIZATION_CHANGED()	
	TMW:Fire("TMW_ACTION_ROLE_CHANGED")
end 

-- [1] Burst 
function Action.ToggleBurst(fixed, between)
	local Current = Action.GetToggle(1, "Burst")
	
	local set
	if between and fixed ~= between then 	
		if Current == fixed then 
			set = between
		else 
			set = fixed
		end 
	end 
	
	if Current ~= "Off" then 		
		Action.Data.TG.Burst = Current
		Current = "Off"
	elseif Action.Data.TG.Burst == nil then  
		Current = "Everything"
		Action.Data.TG.Burst = Current
	else
		Current = Action.Data.TG.Burst
	end 			
	
	Action.SetToggle({1, "Burst", L["TAB"][1]["BURST"] .. ": "}, set or fixed or Current)	
end 

function Action.BurstIsON(unitID)	
	-- @return boolean
	-- Note: This function is cached
	local Current = Action.GetToggle(1, "Burst")
	
	if Current == "Auto" then  
		local unit = unitID or "target"
		return Action.Unit(unitID):IsPlayer() or Action.Unit(unitID):IsBoss()
	elseif Current == "Everything" then 
		return true 
	end 		
	
	return false 			
end 

-- [1] Racial 
function Action.RacialIsON(self)
	-- @usage Action.RacialIsON() or Action:RacialIsON()
	-- @return boolea
	return Action.GetToggle(1, "Racial") and (not self or self:IsExists())
end 

-- [1] HealingEngine 
function Action.ToggleHE(fixed)
	local Current = Action.GetToggle(1, "HE_Toggle")
	if Current == "ALL" then 		
		Current = "RAID"
	elseif Current == "RAID" then  
		Current = "TANK"
	elseif Current == "TANK" then 
		Current = "DAMAGER"
	elseif Current == "DAMAGER" then 
		Current = "HEALER"
	elseif Current == "HEALER" then 
		Current = "TANKANDPARTY"
	elseif Current == "TANKANDPARTY" then 
		Current = "PARTY"
	else 
		Current = "ALL"
	end 		
	Action.SetToggle({1, "HE_Toggle", "HealingEngine: "}, fixed or Current)	
end 

-- [1] ReTarget
local Re = {
	Units = { "arena1", "arena2", "arena3" },
	-- Textures 
	target = {
		["arena1"] = ACTION_CONST_PVP_TARGET_ARENA1,
		["arena2"] = ACTION_CONST_PVP_TARGET_ARENA2,
		["arena3"] = ACTION_CONST_PVP_TARGET_ARENA3,
	},
	-- OnEvent 
	PLAYER_TARGET_CHANGED = function(self)
		if Action.Zone == "pvp" then 			
			if UnitExists("target") then 
				Action.LastTargetIsExists = true 
				for i = 1, #self.Units do
					if UnitIsUnit("target", self.Units[i]) then 
						Action.LastTargetUnitID = self.Units[i]
						Action.LastTargetTexture = self.target[Action.LastTargetUnitID]
					end 
				end 
			else
				Action.LastTargetIsExists = false 
			end 
		end 		
	end,	
	Wipe			= function(self)
		Action.LastTargetIsExists	= nil
		Action.LastTargetUnitID 	= nil 
		Action.LastTargetTexture 	= nil 	
	end,
	Reset 			= function(self)		
		Action.Listener:Remove("ACTION_EVENT_RE", 		"PLAYER_TARGET_CHANGED")
		self:Wipe()
	end,
	Initialize		= function(self)
		if Action.GetToggle(1, "ReTarget") then 
			Action.Listener:Add("ACTION_EVENT_RE", 		"PLAYER_TARGET_CHANGED", function() self:PLAYER_TARGET_CHANGED() end)
			self:PLAYER_TARGET_CHANGED()
		else 
			Action.Listener:Remove("ACTION_EVENT_RE", 	"PLAYER_TARGET_CHANGED")
			Action.LastTargetIsExists	= nil
			Action.LastTargetUnitID 	= nil 
			Action.LastTargetTexture 	= nil 			
		end 
	end,
}

-- [1] LOS System (Line of Sight)
local LineOfSight = {
	Cache 			= setmetatable({}, { __mode = "kv" }),
	Timer			= 5,	
	-- Functions
	UnitInLOS 		= function(self, unitID, unitGUID)		
		if not Action.GetToggle(1, "LOSCheck") then 
			return false 
		end 
		local GUID = unitGUID or UnitGUID(unitID)
		return GUID and self.Cache[GUID] and TMW.time < self.Cache[GUID]
	end,
	Wipe 			= function(self)
		-- Physical reset 
		self.PhysicalUnitID 	= nil
		self.PhysicalUnitGUID	= nil	
		self.PhysicalUnitWait 	= nil
	end,
	Reset 			= function(self)		
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"UI_ERROR_MESSAGE")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"COMBAT_LOG_EVENT_UNFILTERED")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_ENABLED")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_DISABLED")
		self:Wipe()
	end,
	-- OnEvent
	UI_ERROR_MESSAGE = function(self, ...)
		if Action.IsInitialized and select(2, ...) == ACTION_CONST_SPELL_FAILED_LINE_OF_SIGHT then 
			if self.PhysicalUnitID and TMW.time >= self.PhysicalUnitWait then 
				local SkipTimer = self.Timer
				-- Fix for HealingEngine
				if Action.IamHealer and self.PhysicalUnitID == "target" and self.PhysicalUnitGUID == UnitGUID(self.PhysicalUnitID) then 
					if Action.Zone == "arena" then 
						SkipTimer = 3 
					else 
						SkipTimer = 9
					end 
				end 

				if self.PhysicalUnitGUID then 
					self.Cache[self.PhysicalUnitGUID] = TMW.time + SkipTimer
				else 
					self.Cache[UnitGUID(self.PhysicalUnitID)] = TMW.time + SkipTimer
				end 
				
				self:Wipe()
				return
			end 

			if Action.IamHealer and Action.IsUnitEnemy("targettarget") then
				self.Cache[UnitGUID("targettarget")] = TMW.time + self.Timer
			end 
		end 	
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
		if Action.IsInitialized then 
			local _, event, _, SourceGUID, _,_,_, DestGUID = CombatLogGetCurrentEventInfo()	
			if event == "SPELL_CAST_SUCCESS" and self.Cache[DestGUID] and SourceGUID and SourceGUID == UnitGUID("player") then 
				self.Cache[DestGUID] = nil 
				if self.PhysicalUnitID and DestGUID == (self.PhysicalUnitGUID or UnitGUID(self.PhysicalUnitID)) then 
					self:Wipe()
				end 
			end 	
		end 
	end,
	Initialize		= function(self)
		if Action.GetToggle(1, "LOSCheck") then 	
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "UI_ERROR_MESSAGE", 				function(...) self:UI_ERROR_MESSAGE(...) 			end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "COMBAT_LOG_EVENT_UNFILTERED", 	function(...) self:COMBAT_LOG_EVENT_UNFILTERED(...) end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_ENABLED", 			function() 	  wipe(self.Cache)						end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_DISABLED", 		function() 	  wipe(self.Cache)						end)
		else 
			wipe(self.Cache)
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "UI_ERROR_MESSAGE")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "COMBAT_LOG_EVENT_UNFILTERED")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_ENABLED")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_DISABLED")			
		end 
	end,
}

function Action.SetTimerLOS(timer)
	-- Sets timer for non @target units to skip during 'timer' (seconds) after message receive
	LineOfSight.Timer = timer 
end 

function Action.UnitInLOS(unitID, unitGUID)
	-- @return boolean
	return LineOfSight:UnitInLOS(unitID, unitGUID)
end 

function GetLOS(unitID) 
	-- External physical button use 
	if Action.IsInitialized and Action.GetToggle(1, "LOSCheck") then
		if not Action.IsActiveGCD() and (not LineOfSight.PhysicalUnitID or TMW.time > LineOfSight.PhysicalUnitWait) and (unitID ~= "target" or not LineOfSight.PhysicalUnitWait or TMW.time > LineOfSight.PhysicalUnitWait + 1) and not Action.UnitInLOS(unitID) then 
			LineOfSight.PhysicalUnitID = unitID
			if unitID == "target" then 
				LineOfSight.PhysicalUnitGUID = UnitGUID(unitID)
			end 
			-- 0.3 seconds is how much time need wait before start trigger message because if make it earlier it can trigger message from another unit  
			LineOfSight.PhysicalUnitWait = TMW.time + 0.3 
		end 
	end 
end 

-- [1] LetMeCast 
local LETMECAST = {
	SitElapsed = 0,
	MSG 				= {
		[SPELL_FAILED_NOT_STANDING] 				= "STAND", 
		[ERR_CANTATTACK_NOTSTANDING]				= "STAND",
		[ERR_LOOT_NOTSTANDING]						= "STAND",
		[ERR_TAXINOTSTANDING]						= "STAND",
		[SPELL_FAILED_BAD_TARGETS]					= "SIT",
		[SPELL_FAILED_NOT_MOUNTED] 					= "DISMOUNT",
		[ERR_NOT_WHILE_MOUNTED]						= "DISMOUNT",
		[ERR_MOUNT_ALREADYMOUNTED]					= "DISMOUNT",
		[ERR_TAXIPLAYERALREADYMOUNTED]				= "DISMOUNT",
		[ERR_ATTACK_MOUNTED]						= "DISMOUNT",
		[ERR_NO_ITEMS_WHILE_SHAPESHIFTED] 			= "DISMOUNT",
		[ERR_TAXIPLAYERSHAPESHIFTED]				= "DISMOUNT",
		[ERR_MOUNT_SHAPESHIFTED]					= "DISMOUNT",
		[ERR_NOT_WHILE_SHAPESHIFTED]				= "DISMOUNT",
		[ERR_CANT_INTERACT_SHAPESHIFTED]			= "DISMOUNT",
		[SPELL_NOT_SHAPESHIFTED_NOSPACE]			= "DISMOUNT",
		[SPELL_NOT_SHAPESHIFTED]					= "DISMOUNT",
		[SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED]	= "DISMOUNT",
		[SPELL_FAILED_NOT_SHAPESHIFT]				= "DISMOUNT",
	},
	ClassBuffs = {
		SHAMAN = 2645,
	},
	-- OnEvent 
	UI_ERROR_MESSAGE	= function(self, ...)
		local _, msg = ...
		if self.MSG[msg] == "STAND" then 
			DoEmote("STAND")
		elseif self.MSG[msg] == "SIT" then 
			-- Sometimes game bugging and not allow to use damage spells, the fix is simply to make /sit and /stand which is supposed to do 
			if TMW.time > self.SitElapsed then 
				DoEmote("SIT")
				self.SitElapsed = TMW.time + 5
			end 
		elseif self.MSG[msg] == "DISMOUNT" then 
			if Action.PlayerClass == "DRUID" and Action.Player:GetStance() ~= 0 then 
				CancelShapeshiftForm()
			end 
			
			if self.ClassBuffs[Action.PlayerClass] then 
				local buffName = Action.GetSpellInfo(self.ClassBuffs[Action.PlayerClass])
				Action.Player:CancelBuff(buffName)
			end 
			
			Dismount()			
		end 
	end,
	TAXIMAP_OPENED		= function()
		Dismount()
	end,
	Reset 				= function(self)
		Action.Listener:Remove("ACTION_EVENT_LET_ME_CAST", "UI_ERROR_MESSAGE")
		Action.Listener:Remove("ACTION_EVENT_LET_ME_CAST", "TAXIMAP_OPENED")		
	end,
	Initialize			= function(self)
		if Action.GetToggle(1, "LetMeCast") then 
			Action.Listener:Add("ACTION_EVENT_LET_ME_CAST", "UI_ERROR_MESSAGE", function(...) self:UI_ERROR_MESSAGE(...) end)
			Action.Listener:Add("ACTION_EVENT_LET_ME_CAST", "TAXIMAP_OPENED", 	self.TAXIMAP_OPENED)
		else 
			Action.Listener:Remove("ACTION_EVENT_LET_ME_CAST", "UI_ERROR_MESSAGE")
			Action.Listener:Remove("ACTION_EVENT_LET_ME_CAST", "TAXIMAP_OPENED")			
		end 
	end,
}

-- [1] AuraDuration
local AuraDuration = {
	CONST = {
		AURA_ROW_WIDTH 		= 122,
		TOT_AURA_ROW_WIDTH 	= 101,
		NUM_TOT_AURA_ROWS 	= 2,
		LARGE_AURA_SIZE 	= 40,
		SMALL_AURA_SIZE 	= 18,	
		DEFAULT_AURA_SIZE	= 23,
	},
	defaults 				= {
		portraitIcon 		= true,
		verbosePortraitIcon = true,
	},
	largeBuffList			= {},
	largeDebuffList 		= {},
	LibAuraTypes			= LibStub("LibAuraTypes"),
	LibSpellLocks			= LibStub("LibSpellLocks"),
	TurnOnAuras				= function(self)
		TargetFrame_Update(_G["TargetFrame"])
		self:TargetFrameHook()	
	end,
	TurnOffAuras			= function(self)
		-- turn off visual immediately
		if not self.IsEnabled then 	
			local frame, frameName, frameCooldown
			for i = 1, MAX_TARGET_BUFFS do		
				frameName 	= "TargetFrameBuff" .. i
				frame 		= _G[frameName]	
				if frame then 
					frameCooldown = _G[frameName .. "Cooldown"]
					if frameCooldown then 
						CooldownFrame_Set(frameCooldown, 0)
						frame:SetSize(self.CONST.DEFAULT_AURA_SIZE, self.CONST.DEFAULT_AURA_SIZE)
					end 
				end 
			end 
			
			for i = 1, MAX_TARGET_DEBUFFS do		
				frameName 	= "TargetFrameDebuff" .. i
				frame 		= _G[frameName]	
				if frame then 
					frameCooldown = _G[frameName .. "Cooldown"]
					if frameCooldown then 
						CooldownFrame_Set(frameCooldown, 0)
						frame:SetSize(self.CONST.DEFAULT_AURA_SIZE, self.CONST.DEFAULT_AURA_SIZE)
					end 
				end 
			end 			
		end 	
	end,
	TurnOnPortrait			= function(self)
		self.defaults.portraitIcon = true 
	end,
	TurnOffPortrait 		= function(self)
		self.defaults.portraitIcon = false 
		--[[ PORTRAIT AURA ]]
		local auraCD 			= _G["TargetFrame"].CADPortraitFrame
		local originalPortrait 	= auraCD.originalPortrait	
		auraCD:Hide()
		originalPortrait:Show()			
	end,
	Reset					= function(self)
		if not self.IsInitialized then
			return 
		end 
		-- turn off portrait 
		self:TurnOffPortrait()
		
		-- turn off visual immediately
		self:TurnOffAuras()		
	end,
	UpdatePortraitIcon 		= function(self, unit, maxPrio, maxPrioIndex, maxPrioFilter)
		local auraCD 			= _G["TargetFrame"].CADPortraitFrame
		local originalPortrait 	= auraCD.originalPortrait

		local isLocked 			= self.LibSpellLocks:GetSpellLockInfo(unit)
		
		local CUTOFF_AURA_TYPE 	= self.defaults.verbosePortraitIcon and "SPEED_BOOST" or "SILENCE"
		local PRIO_SILENCE 		= self.LibAuraTypes.GetDebuffTypePriority(CUTOFF_AURA_TYPE)
		if isLocked and PRIO_SILENCE > maxPrio then
			maxPrio 			= PRIO_SILENCE
			maxPrioIndex 		= -1
		end

		if maxPrioFilter and maxPrio >= PRIO_SILENCE then
			local name, icon, _, _, duration, expirationTime, caster, _,_, spellId
			if maxPrioIndex == -1 then
				spellId, name, icon, duration, expirationTime = self.LibSpellLocks:GetSpellLockInfo(unit)
			else
				if maxPrioIndex then 
					name, icon, _, _, duration, expirationTime, caster, _,_, spellId = UnitAura(unit, maxPrioIndex, maxPrioFilter)
				else 
					for i = 1, huge do 
						name, icon, _, _, duration, expirationTime, caster, _,_, spellId = UnitAura(unit, i, maxPrioFilter)
						if not name then 
							break 
						end 
					end 
				end 
			end
			SetPortraitToTexture(auraCD.texture, icon)
			originalPortrait:Hide()
			auraCD:SetCooldown(expirationTime - duration, duration)
			auraCD:Show()
		else
			auraCD:Hide()
			originalPortrait:Show()
		end
	end,
	TargetFrameHook 		= function(self)	
		local frame, frameName							-- Don't touch, need for default 
		local frameIcon, frameCount, frameCooldown		-- Don't touch, need for default 
		local numBuffs 			= 0 					-- Don't touch, need for default 
		
		local selfName 			= _G["TargetFrame"]:GetName()
		local unit 				= _G["TargetFrame"].unit
		
		local playerIsTarget 	= UnitIsUnit(PlayerFrame.unit, unit)
		--[[ PORTRAIT AURA ]]
		local maxPrio = 0
		local maxPrioFilter
		local maxPrioIndex = 1

		local maxBuffs 			= math.min(_G["TargetFrame"].maxBuffs or MAX_TARGET_BUFFS, MAX_TARGET_BUFFS)
		for i = 1, maxBuffs do
			local buffName, icon, count, _, duration, expirationTime, caster, canStealOrPurge, _, spellId = UnitAura(unit, i, "HELPFUL")
			if buffName then
				frameName 	= "TargetFrameBuff" .. i
				frame 		= _G[frameName]			
				
				if not frame then
					if not icon then
						break
					else
						frame 		= CreateFrame("Button", frameName, _G["TargetFrame"], "TargetBuffFrameTemplate")
						frame.unit 	= unit
					end
				end	
					
				if icon then		
					frame:SetID(i)
					
					--[[ No reason to do it twice
					-- set the icon
					frameIcon = _G[frameName .. "Icon"]
					frameIcon:SetTexture(icon)
						
					-- set the count
					frameCount = _G[frameName .. "Count"]
					if count > 1 then
						frameCount:SetText(count)
						frameCount:Show()
					else
						frameCount:Hide()
					end
					]]								

					-- Handle cooldowns
					frameCooldown = _G[frameName .. "Cooldown"]
					CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true)

					--[[ PORTRAIT AURA ]]
					if self.defaults.portraitIcon then
						local rootSpellID, spellType, prio = self.LibAuraTypes.GetDebuffInfo(spellId)
						if prio and prio > maxPrio then
							maxPrio 		= prio
							maxPrioIndex 	= i
							maxPrioFilter 	= "HELPFUL"
						end
					end

					-- Show stealable frame if the target is not the current player and the buff is stealable.
					_G[frameName .. "Stealable"]:SetShown(not playerIsTarget and canStealOrPurge)

					-- set the buff to be big if the buff is cast by the player or his pet.
					if caster and (UnitIsUnit(caster, PlayerFrame.unit) or UnitIsOwnerOrControllerOfUnit(PetFrame.unit, PlayerFrame.unit)) then 
						numBuffs = numBuffs + 1
						self.largeBuffList[numBuffs] = true
						frame:SetSize(self.CONST.LARGE_AURA_SIZE, self.CONST.LARGE_AURA_SIZE)
					else 
						frame:SetSize(self.CONST.SMALL_AURA_SIZE, self.CONST.SMALL_AURA_SIZE)
					end 

					--frame:ClearAllPoints()
					--frame:Show()
				--else
					--frame:Hide()
				end
			else
				break
			end
		end
		
		local color, frameBorder			-- Custom highlight debuff borders 
		local numDebuffs 					= 0
		local maxDebuffs 					= math.min(_G["TargetFrame"].maxDebuffs or MAX_TARGET_DEBUFFS, MAX_TARGET_DEBUFFS)
		for i = 1, maxDebuffs do 
			local debuffName, icon, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, _, casterIsPlayer, nameplateShowAll = UnitAura(unit, i, "HARMFUL")
			if debuffName then 
				if TargetFrame_ShouldShowDebuffs(unit, caster, nameplateShowAll, casterIsPlayer) then
					frameName 	= "TargetFrameDebuff" .. i
					frame 		= _G[frameName]
					
					if not frame then
						if not icon then
							break
						else
							frame 		= CreateFrame("Button", frameName, _G["TargetFrame"], "TargetDebuffFrameTemplate")
							frame.unit 	= unit
						end
					end		

					if icon then 
						frame:SetID(i)
						
						--[[ No reason to do it twice
						-- set the icon
						frameIcon = _G[frameName .. "Icon"]
						frameIcon:SetTexture(icon)
						
						-- set the count
						frameCount = _G[frameName .. "Count"]
						if (count > 1 and self.showAuraCount) then
							frameCount:SetText(count)
							frameCount:Show()
						else
							frameCount:Hide()
						end		
						]]
						
						-- Handle cooldowns
						frameCooldown = _G[frameName .. "Cooldown"]
						CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true)		

						--[[ PORTRAIT AURA ]]
						if self.defaults.portraitIcon then
							local rootSpellID, spellType, prio = self.LibAuraTypes.GetDebuffInfo(spellId)
							if prio and prio > maxPrio then
								maxPrio 		= prio
								maxPrioIndex 	= i
								maxPrioFilter 	= "HARMFUL"
							end
						end

						-- set debuff type color
						if debuffType then
							color = DebuffTypeColor[debuffType]
						else
							color = DebuffTypeColor["none"]
						end
						frameBorder = _G[frameName .. "Border"]
						frameBorder:SetVertexColor(color.r, color.g, color.b)

						-- set the debuff to be big if the debuff is cast by the player or his pet.
						if caster and (UnitIsUnit(caster, PlayerFrame.unit) or UnitIsOwnerOrControllerOfUnit(PetFrame.unit, PlayerFrame.unit)) then 
							numDebuffs = numDebuffs + 1
							self.largeDebuffList[numDebuffs] = true
							frame:SetSize(self.CONST.LARGE_AURA_SIZE, self.CONST.LARGE_AURA_SIZE)
						else 
							frame:SetSize(self.CONST.SMALL_AURA_SIZE, self.CONST.SMALL_AURA_SIZE)
						end 

						--frame:ClearAllPoints()
						--frame:Show()						
					--else 
						--frame:Hide()
					end 
				end 
			else 
				break 
			end 
		end 

		_G["TargetFrame"].auraRows = 0

		local mirrorAurasVertically = false
		if _G["TargetFrame"].buffsOnTop then
			mirrorAurasVertically = true
		end
		local haveTargetofTarget
		if _G["TargetFrame"].totFrame then
			haveTargetofTarget = _G["TargetFrame"].totFrame:IsShown()
		end
		_G["TargetFrame"].spellbarAnchor = nil
		local maxRowWidth
		-- update buff positions
		maxRowWidth = (haveTargetofTarget and self.CONST.TOT_AURA_ROW_WIDTH) or self.CONST.AURA_ROW_WIDTH
		TargetFrame_UpdateAuraPositions(_G["TargetFrame"], selfName .. "Buff", numBuffs, numDebuffs, self.largeBuffList, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3, mirrorAurasVertically)
		-- update debuff positions
		maxRowWidth = (haveTargetofTarget and _G["TargetFrame"].auraRows < self.CONST.NUM_TOT_AURA_ROWS and self.CONST.TOT_AURA_ROW_WIDTH) or self.CONST.AURA_ROW_WIDTH
		TargetFrame_UpdateAuraPositions(_G["TargetFrame"], selfName .. "Debuff", numDebuffs, numBuffs, self.largeDebuffList, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 3, mirrorAurasVertically)
		-- update the spell bar position
		if _G["TargetFrame"].spellbar then
			Target_Spellbar_AdjustPosition(_G["TargetFrame"].spellbar)
		end

		--[[ PORTRAIT AURA ]]
		if self.defaults.portraitIcon then
			self:UpdatePortraitIcon(unit, maxPrio, maxPrioIndex, maxPrioFilter)
		end		
	end,
	Initialize				= function(self, isLaunch)
		self.IsEnabled 		= Action.GetToggle(1, "AuraDuration")
		
		if self.IsInitialized then 
			if not isLaunch then 
				-- turn off visual immediately
				if not self.IsEnabled then 
					self:Reset()
				-- turn on visual immediately
				else 
					self:TurnOnAuras()	
				end 	
			end 
			
			return 		
		end 
		self.IsInitialized 	= true 
		
		if GetCVar("noBuffDebuffFilterOnTarget") ~= "1" then 
			SetCVar("noBuffDebuffFilterOnTarget", "1")
			Action.Print("noBuffDebuffFilterOnTarget 0 => 1")
		end 
		
		self.LibSpellLocks.RegisterCallback(Action, "UPDATE_INTERRUPT", function(event, guid)
			if Action.IsInitialized and self.IsEnabled and UnitGUID("target") == guid then
				TargetFrame_UpdateAuras(TargetFrame)
			end
		end)

		local originalPortrait = _G["TargetFramePortrait"]

		local auraCD = CreateFrame("Cooldown", "AuraDurationsPortraitAura", TargetFrame, "CooldownFrameTemplate")
		auraCD:SetFrameStrata("BACKGROUND")
		auraCD:SetDrawEdge(false)
		auraCD:SetReverse(true)
		auraCD:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
		auraCD:SetAllPoints(originalPortrait)
		_G["TargetFrame"].CADPortraitFrame = auraCD
		auraCD.originalPortrait = originalPortrait

		local auraIconTexture = auraCD:CreateTexture(nil, "BORDER", nil, 2)
		auraIconTexture:SetAllPoints(originalPortrait)
		auraCD.texture = auraIconTexture
		auraCD:Hide()
		
		-- load portrait saved options
		if not Action.GetToggle(1, "AuraCCPortrait") then 
			self.defaults.portraitIcon = false 
		end 

		hooksecurefunc("TargetFrame_UpdateAuras", function() 
			if Action.IsInitialized and self.IsEnabled then 
				self:TargetFrameHook()
			end 
		end)

		hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, unit, index, filter)
			if Action.IsInitialized and self.IsEnabled then 
				local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HELPFUL")
				local enabled = expirationTime and expirationTime ~= 0
				if enabled then
					CooldownFrame_Set(buffFrame.cooldown, expirationTime - duration, duration, true)
				else
					CooldownFrame_Clear(buffFrame.cooldown)
				end
			end 
		end)

		hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, unit, index, filter)
			if Action.IsInitialized and self.IsEnabled then 
				local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, filter)
				local enabled = expirationTime and expirationTime ~= 0
				if enabled then
					CooldownFrame_Set(debuffFrame.cooldown, expirationTime - duration, duration, true)
				else
					CooldownFrame_Clear(debuffFrame.cooldown)
				end
			end 
		end)
						
		-- turn on visual immediately
		self:TurnOnAuras()	
	end,
}

-- [1] RealHealth and PercentHealth
local NumberGroupingScale = {
	enUS = 3,
	koKR = 4,
	zhCN = 4,
	zhTW = 4,
}
local UnitHealthTool = {
	AddOn_Localization_NumberGroupingScale = NumberGroupingScale[GameLocale] or NumberGroupingScale["enUS"],
	AbbreviateNumber		= function(self, val)
		-- Calculate exponent of 10 and clamp to zero
		local exp = math_max(0, math_floor(math_log10(math_abs(val))))
		-- Less than 1k, return as-is
		if exp < self.AddOn_Localization_NumberGroupingScale then 
			return Action.toStr and Action.toStr[math_floor(val)] or tostring(math_floor(val))
		end

		-- Exponent factor of 1k
		local factor 	= math_floor(exp / self.AddOn_Localization_NumberGroupingScale)
		-- Dynamic precision based on how many digits we have (Returns numbers like 100k, 10.0k, and 1.00k)
		local precision = math_max(0, (self.AddOn_Localization_NumberGroupingScale - 1) - exp % self.AddOn_Localization_NumberGroupingScale)

		-- Fallback to scientific notation if we run out of units
		return ((val < 0 and "-" or "") .. "%0." .. precision .. "f%s"):format(val / (10 ^ self.AddOn_Localization_NumberGroupingScale) ^ factor, NumberCaps[factor] or "e" .. (factor * self.AddOn_Localization_NumberGroupingScale))
	end,
	SetupStatusBarText		= function(self)
		local parent = _G["TargetFrame"]
		-- create font strings since default frame hasn't it 
		if not parent.fontFrame then 
			parent.fontFrame = CreateFrame("Frame", nil, parent)
			parent.fontFrame:SetFrameStrata("TOOLTIP")
		end 
		if not parent.RealHealth then 
			parent.RealHealth 		= parent.fontFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
		end 		
		if not parent.PercentHealth then 
			parent.PercentHealth 	= parent.fontFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
		end 
		
		-- set values 
		local realValue = round(Action.Unit("target"):Health(), 0)
		if realValue ~= 0 then 
			parent.RealHealth:SetText(self.AbbreviateNumber(realValue))
		else 
			parent.RealHealth:SetText("")
		end 		
		
		local percentValue = round(Action.Unit("target"):HealthPercent(), 0)
		if percentValue ~= 0 then 
			parent.PercentHealth:SetText(percentValue .. "%")
		else 
			parent.PercentHealth:SetText("")
		end 
		
		-- determine default anchors and visible status 
		local real, percent = Action.GetToggle(1, "TargetRealHealth"), Action.GetToggle(1, "TargetPercentHealth")
		
		parent.RealHealth:ClearAllPoints()
		parent.PercentHealth:ClearAllPoints()
		
		if real and percent then 
			parent.RealHealth:SetPoint("RIGHT", _G["TargetFrameHealthBar"], "RIGHT", -3, 0)	
			parent.PercentHealth:SetPoint("LEFT", _G["TargetFrameHealthBar"], "LEFT", 0, 0)		
			parent.RealHealth:Show()
			parent.PercentHealth:Show()
			return 
		end 
		
		if real then 
			parent.RealHealth:SetPoint("TOP", _G["TargetFrameHealthBar"])	
			parent.RealHealth:Show()
			parent.PercentHealth:Hide()
			return 
		end 
		
		if percent then 
			parent.PercentHealth:SetPoint("TOP", _G["TargetFrameHealthBar"])	
			parent.PercentHealth:Show()
			parent.RealHealth:Hide()
			return 
		end 
		
		parent.RealHealth:Hide()
		parent.PercentHealth:Hide()
	end,
	Reset 					= function(self)
		if not self.IsInitialized then 
			return 
		end 
		
		local parent = _G["TargetFrame"]
		parent.RealHealth:Hide()
		parent.PercentHealth:Hide()
	end,
	Initialize				= function(self)
		if self.IsInitialized then 
			self:SetupStatusBarText()
			return 
		end 
		self.IsInitialized = true 
		
		self:SetupStatusBarText()
		
		local EVENTS = {
			UNIT_HEALTH = true,
			PLAYER_ENTERING_WORLD = true,
			PLAYER_TARGET_CHANGED = true,
		}		
		
		local frame = _G["TargetFrame"]
		frame:HookScript("OnEvent", function(this, event, ...)
			if Action.IsInitialized then 
				if EVENTS[event] then 
					if this.RealHealth:IsShown() then 
						local realValue = round(Action.Unit("target"):Health(), 0)
						if realValue ~= 0 then 
							this.RealHealth:SetText(realValue)			
						else 
							this.RealHealth:SetText("")
						end 						
					end 
					
					if this.PercentHealth:IsShown() then 
						local percentValue = round(Action.Unit("target"):HealthPercent(), 0)
						if percentValue ~= 0 then 
							this.PercentHealth:SetText(percentValue .. "%")
						else 
							this.PercentHealth:SetText("")
						end 
					end 
				end 
			end 	
		end)			
	end,
}

-- [2] AoE toggle through Ctrl+Left Click on main picture 
local tempAoE = {2, "AoE"}
function Action.ToggleAoE()
	Action.SetToggle(tempAoE)
end 

-- [3] SetBlocker 
function Action:IsBlocked()
	-- @return boolean 
	return TMW.db.profile.ActionDB[3].disabledActions[GetTableKeyIdentify(self)] == true
end

function Action:SetBlocker()
	-- Sets block on action
	-- Note: /run Action[Action.PlayerClass].WordofGlory:SetBlocker()
	if self.BlockForbidden and not self:IsBlocked() then 
		Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORBLOCK"])
        return 		
	end 
	
	local Notification 
	local Identify = GetTableKeyIdentify(self)
	if self:IsBlocked() then 
		TMW.db.profile.ActionDB[3].disabledActions[Identify] = nil 
		Notification = L["TAB"][3]["UNBLOCKED"] .. self:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]"		
	else 
		TMW.db.profile.ActionDB[3].disabledActions[Identify] = true
		Notification = L["TAB"][3]["BLOCKED"] .. self:Link() .. " " ..  L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]"
	end 
    Action.Print(Notification)
	
	if Action.MainUI then 
		local spec = Action.PlayerClass .. CL	
		local ScrollTable = tabFrame.tabs[3].childs[spec].ScrollTable
		for i = 1, #ScrollTable.data do 
			if Identify == GetTableKeyIdentify(ScrollTable.data[i]) then 
				if self:IsBlocked() then 
					ScrollTable.data[i].Enabled = "False"
				else 
					ScrollTable.data[i].Enabled = "True"
				end								 			
			end 
		end		
		ScrollTable:ClearSelection() 
	end 
end

function Action.MacroBlocker(key)
	-- Sets block on action with avoid lua errors for non exist key
	local object = GetActionTableByKey(key)
	if not object then 
		Action.Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetBlocker()
end

-- [3] SetQueue (Queue System)
local Queue = {
	Temp 						= {
		SilenceON				= { Silence = true },
		SilenceOFF				= { Silence = false },
	},
	Reset 						= function(self)
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "LEARNED_SPELL_IN_TAB")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "CHARACTER_POINTS_CHANGED")		
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "CONFIRM_TALENT_WIPE")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED")	
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED")	
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD")	
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "ITEM_UNLOCKED")
		TMW:UnregisterCallback("TMW_ACTION_MODE_CHANGED", function() self:OnEventToReset() end,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET")
	end, 
	IsThisMeta 					= function(self, meta)
		return (not Action.Data.Q[1].MetaSlot and (meta == 3 or meta == 4)) or Action.Data.Q[1].MetaSlot == meta
	end, 
	IsInterruptAbleChannel 		= {},
	-- Events
	UNIT_SPELLCAST_SUCCEEDED 	= function(self, ...)
		local source, _, spellID = ...
		if (source == "player" or source == "pet") and Action.Data.Q[1] and Action.Data.Q[1].Type == "Spell" and ((Action.Data.Q[1].isRank and Action.Data.Q[1].isRank ~= 0 and Action.Data.Q[1].ID == spellID) or ((not Action.Data.Q[1].isRank or Action.Data.Q[1].isRank == 0) and Action.Data.Q[1]:Info() == Action.GetSpellInfo(spellID))) then 			
			getmetatable(Action.Data.Q[1]).__index:SetQueue(self.Temp.SilenceON)
		end 	
	end,
	BAG_UPDATE_COOLDOWN			= function(self)
		if Action.Data.Q[1] and Action.Data.Q[1].Type ~= "Spell" and Action.Data.Q[1].Type ~= "SwapEquip" then 
			local start, duration, enable = Action.Data.Q[1].Item:GetCooldown()
			if duration and math_abs(TMW.time - start) <= 2 then 
				getmetatable(Action.Data.Q[1]).__index:SetQueue(self.Temp.SilenceON)
				return 
			end 
			-- For things like a potion that was used in combat and the cooldown hasn't yet started counting down
			if enable == 0 and Action.Data.Q[1].Type ~= "Trinket" then 
				getmetatable(Action.Data.Q[1]).__index:SetQueue(self.Temp.SilenceON)
			end 
		end 	
	end, 
	ITEM_UNLOCKED				= function(self)
		if Action.Data.Q[1] and Action.Data.Q[1].Type == "SwapEquip" then 
			getmetatable(Action.Data.Q[1]).__index:SetQueue(self.Temp.SilenceON)
		end 
	end, 
	OnEventToResetNoCombat 	= function(self, isSilenced)
		-- ByPass wrong reset events by equip swap during combat
		if Action.Unit("player"):CombatTime() == 0 then 
			self:OnEventToReset(isSilenced)
		end 
	end, 
	OnEventToReset 				= function(self, isSilenced)
		if #Action.Data.Q > 0 then 
			for i = #Action.Data.Q, 1, -1 do 
				if Action.Data.Q[i] and Action.Data.Q[i].Queued then 
					getmetatable(Action.Data.Q[i]).__index:SetQueue((isSilenced and self.Temp.SilenceON) or self.Temp.SilenceOFF)
				end 
			end 		
		end 
		wipe(Action.Data.Q) 
		self:Reset()
	end, 
}

function Action:QueueValidCheck()
	-- @return boolean
	-- Note: This thing does mostly tasks but still causing some issues with certain spells which should be blacklisted or avoided through another way (ideally) 
	-- Example of issue: Monk can set Queue for Resuscitate while has @target an enemy and it will true because it will set to variable "player" which is also true and correct!
	-- Why "player"? Coz while @target an enemy you can set queue of supportive spells for "self" and if they will be used on enemy then they will be applied on "player" 	
	local isCastingName, _, _, _, castID, isChannel = Action.Unit("player"):IsCasting()
	if (not isCastingName or isCastingName ~= self:Info()) and (not isChannel or Queue.IsInterruptAbleChannel[castID]) then
		if self.Type == "SwapEquip" or self.isStance then 
			return true 
		elseif not self:HasRange() then 
			return self:AbsentImun(self.UnitID, self.AbsentImunQueueCache)	-- Well at least will do something, better than nothing 
		else 
			local isHarm 	= self:IsHarmful()
			local unitID 	= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and ((isHarm and "target") or (not Action.IamHealer and "player"))) or "target"
			self.UnitID		= unitID
			-- IsHelpful for Item under testing phase
			-- unitID 		= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and (((isHarm or self:IsHelpful()) and "target") or (not Action.IamHealer and "player"))) or "target"
			
			if isHarm then 
				return Action.Unit(unitID):IsEnemy() and self:IsInRange(unitID) and self:AbsentImun(unitID, self.AbsentImunQueueCache)
			else 
				return UnitIsUnit(unitID, "player") or (self:IsInRange(unitID) and self:AbsentImun(unitID))
			end 
		end 
	end 
	return false 
end 

function Action.CancelAllQueue()
	Queue:OnEventToReset(true)
end 

function Action.CancelAllQueueForMeta(meta)
	local index 			= #Action.Data.Q 
	if index > 0 then 
		for i = index, 1, -1 do 
			if (not Action.Data.Q[i].MetaSlot and (meta == 3 or meta == 4)) or Action.Data.Q[i].MetaSlot == meta then 
				getmetatable(Action.Data.Q[i]).__index:SetQueue(Queue.Temp.SilenceON)
			end 
		end 
	end 
end 

function Action.IsQueueRunning()
	-- @return boolean 
	return #Action.Data.Q > 0
end 

function Action.IsQueueRunningAuto()
	-- @return boolean 	
	local index = #Action.Data.Q
	return index > 0 and (Action.Data.Q[index].Auto or Action.Data.Q[1].Auto)
end 

function Action.IsQueueReady(meta)
	-- @return boolean
	local index = #Action.Data.Q
    if index > 0 and Queue:IsThisMeta(meta) then 		
		local self = Action.Data.Q[1]
		if self.Auto and self.Start and TMW.time - self.Start > (Action.Data.QueueAutoResetTimer or 10) then 
			Queue:OnEventToReset()
			return false 
		end 		
        if self.Type == "Spell" or self.Type == "Trinket" or self.Type == "Potion" or self.Type == "Item" then -- Note: Equip, Count, Existance of action already checked in Action:SetQueue 
			if self.UnitID == "player" or self:QueueValidCheck() then 
				return self:IsUsable(self.ExtraCD) and (not self.PowerCustom or UnitPower("player", self.PowerType) >= (self.PowerCost or 0)) and (self.Auto or self:RunQLua(self.UnitID)) and (not self.isCP or Action.Player:ComboPoints("target") >= (self.CP or 1))  
			end
		elseif self.Type == "SwapEquip" then 
			return not Action.Player:IsSwapLocked() and (self.Auto or self:RunQLua(self.UnitID)) and (not self.isCP or Action.Player:ComboPoints("target") >= (self.CP or 1))  
        else 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"])          
			getmetatable(self).__index:SetQueue()
        end 
    end 
    return false 
end 

function Action:IsBlockedByQueue()
	-- @return boolean 
	return 	not self.QueueForbidden and 
			#Action.Data.Q > 0 and 
			self.Type == Action.Data.Q[1].Type and 
			( not Action.Data.Q[1].PowerType or self.PowerType == Action.Data.Q[1].PowerType ) and 
			( not Action.Data.Q[1].PowerCost or UnitPower("player", self.PowerType) < Action.Data.Q[1].PowerCost ) and 
			( not Action.Data.Q[1].isCP or (self.isCP == Action.Data.Q[1].isCP and Action.Player:ComboPoints("target") < (Action.Data.Q[1].CP or Action.Player:ComboPointsMax())) )
end

function Action:IsQueued()
	-- @return boolean 
    return self.Queued
end 

function Action:SetQueue(args) 
	-- Sets queue on action 
	-- Note: /run Action[Action.PlayerClass].WordofGlory:SetQueue()
	-- QueueAuto: Action:SetQueue({ Silence = true, Priority = 1 }) just sometimes simcraft use it in some place
	--[[@usage: args (table)
	 	Optional: 
			PowerType (number) custom offset 														(passing conditions to func IsQueueReady)
			PowerCost (number) custom offset 														(passing conditions to func IsQueueReady)
			ExtraCD (number) custom offset															(passing conditions to func IsQueueReady)
			Silence (boolean) if true don't display print 
			UnitID (string) specified for spells usually to check their for range on certain unit 	(passing conditions to func QueueValidCheck)
			Value (boolean) sets custom fixed statement for queue
			Priority (number) put in specified priority 
			MetaSlot (number) usage for MSG system to set queue on fixed position 
			Auto (boolean) usage to skip RunQLua
			CP (number) usage to queue action on specified combo points 							(passing conditions to func IsQueueReady)		
	]]
	-- Check validance 
	if not self.Queued and (not self:IsExists() or self:IsBlockedBySpellBook()) then  
		Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"]) 
		return 
	end 
	
	local printKey 	= self.Desc .. (self.Color or "") 
		  printKey	= (printKey ~= "" and (" " .. L["TAB"][3]["KEY"] .. printKey .. "]")) or ""
	
	local args = args or {}	
	local Identify = GetTableKeyIdentify(self)
	if self.QueueForbidden or (self.isStance and Action.Player:IsStance(self.isStance)) or ((self.Type == "Trinket" or self.Type == "Item") and not GetItemSpell(self.ID)) then 
		if not args.Silence then 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. printKey)
		end 
        return 	 
	-- Let for user allow run blocked actions whenever he wants, anyway why not 
	--elseif self:IsBlocked() and not self.Queued then 
		--if not args.Silence then 
			--Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"] .. printKey)
		--end 
        --return 
	end
	
	if args.Value ~= nil and self.Queued == args.Value then 
		if not args.Silence then 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISQUEUEDALREADY"] .. printKey)
		end 
		return 
	end 
	
	if args.Value ~= nil then 
		self.Queued = args.Value 
	else 
		self.Queued = not self.Queued
	end 
	
	local priority = (args.Priority and (args.Auto or not Action.IsQueueRunningAuto()) and (args.Priority > #Action.Data.Q + 1 and #Action.Data.Q + 1 or args.Priority)) or #Action.Data.Q + 1
    if not args.Silence then		
		if self.Queued then 
			Action.Print(L["TAB"][3]["QUEUED"] .. self:Link() .. L["TAB"][3]["QUEUEPRIORITY"] .. priority .. ". " .. L["TAB"][3]["KEYTOTAL"] .. #Action.Data.Q + 1 .. "]")
		else
			Action.Print(L["TAB"][3]["QUEUEREMOVED"] .. self:Link() .. printKey)
		end 
    end 
    
	if not self.Queued then 
		for i = #Action.Data.Q, 1, -1 do 
			if GetTableKeyIdentify(Action.Data.Q[i]) == Identify then 
				table.remove(Action.Data.Q, i)
				if #Action.Data.Q == 0 then 
					Queue:Reset()
					return 
				end 				
			end 
		end 
		return
	end 
    
	-- Do nothing if it does in spam with always true as insert to queue list 	
	if args.Value and #Action.Data.Q > 0 then 
		for i = #Action.Data.Q, 1, -1 do
			if GetTableKeyIdentify(Action.Data.Q[i]) == Identify then 
				return
			end 
		end 
	end
    table.insert(Action.Data.Q, priority, setmetatable({ UnitID = args.UnitID, MetaSlot = args.MetaSlot, Auto = args.Auto, Start = TMW.time, CP = args.CP }, { __index = self }))

	if args.PowerType then 
		-- Note: we set it as true to use in function Action.IsQueueReady()
		Action.Data.Q[priority].PowerType = args.PowerType   	
		Action.Data.Q[priority].PowerCustom = true
	end	
	if args.PowerCost then 
		Action.Data.Q[priority].PowerCost = args.PowerCost
		Action.Data.Q[priority].PowerCustom = true
	end 		 	
	if args.ExtraCD then
		Action.Data.Q[priority].ExtraCD = args.ExtraCD 
	end 	
		
    Action.Listener:Add("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED", 		function(...) Queue:UNIT_SPELLCAST_SUCCEEDED(...) 	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN", 			function() 	  Queue:BAG_UPDATE_COOLDOWN() 		  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "ITEM_UNLOCKED",					function() 	  Queue:ITEM_UNLOCKED() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "LEARNED_SPELL_IN_TAB", 			function() 	  Queue:OnEventToReset() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "CHARACTER_POINTS_CHANGED", 		function() 	  Queue:OnEventToResetNoCombat() 	  	end)	
    Action.Listener:Add("ACTION_EVENT_QUEUE", "CONFIRM_TALENT_WIPE", 			function() 	  Queue:OnEventToResetNoCombat() 	  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED", 			function() 	  Queue:OnEventToReset() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED", 		function() 	  Queue:OnEventToResetNoCombat() 	 	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD", 			function() 	  Queue:OnEventToReset() 			  	end)	
	TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", 							function() 	  Queue:OnEventToReset() 				end,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET")
end

function Action.MacroQueue(key, args)
	-- Sets queue on action with avoid lua errors for non exist key
	local object = GetActionTableByKey(key)
	if not object then 
		Action.Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetQueue(args)
end

-- [4] Interrupts
function Action.InterruptIsON(list)
	-- @return boolean 	
	-- Note: list 	("TargetMouseover", "PvP", "Heal")
	return TMW.db.profile.ActionDB[4]["Kick" .. list]
end 

function Action.InterruptIsBlackListed(unitID, spellName)
	-- @return boolean (Kick, CC, Racial)
	local blackListed = TMW.db.profile.ActionDB[4].BlackList[GameLocale][spellName]
	if blackListed and blackListed.Enabled then 
		local luaCode = blackListed.LUA or nil
		if RunLua(luaCode, unitID) then 
			return blackListed.useKick, blackListed.useCC, blackListed.useRacial
		end 
	end 
	return false, false, false 
end 

function Action.InterruptEnabled(list, spellName)
	-- @return boolean 
	-- Note: list ("PvETargetMouseover", "PvPTargetMouseover", "PvP", "Heal")
	return TMW.db.profile.ActionDB[4][list][GameLocale][spellName] and TMW.db.profile.ActionDB[4][list][GameLocale][spellName].Enabled
end 

local function SmartInterrupt()
	-- Note: This function is cached 
	local HealerInCC = not Action.IamHealer and Action.FriendlyTeam("HEALER"):GetCC() or 0
	return (HealerInCC > 0 and HealerInCC < Action.GetGCD() + Action.GetCurrentGCD()) or Action.FriendlyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4 or Action.FriendlyTeam():GetTTD(1, 8) or Action.Unit("target"):IsExecuted() or Action.Unit("player"):IsExecuted() or Action.EnemyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4
end 
local ConcatenationStr = {
	[true] = "PvPTargetMouseover",
	[false] = "PvETargetMouseover",
}

function Action.InterruptIsValid(unitID, list, ignoreToggle)
	-- @return boolean (Kick, CC, Racial)
	-- Note: list 	("TargetMouseover", "PvP", "Heal")
	-- list as "PvETargetMouseover" and "PvPTargetMouseover" must be always "TargetMouseover"
	
	-- ATTENTION
	-- This thing doesn't check random interval and as well distance with imun to kick
	
	if ignoreToggle or Action.InterruptIsON(list) then 	
		local spellName = Action.Unit(unitID):IsCasting()
		if spellName then 
			local bl_useKick, bl_useCC, bl_useRacial = Action.InterruptIsBlackListed(unitID, spellName)
			if list == "TargetMouseover" then 
				list = ConcatenationStr[Action.IsInPvP]
			end 	

			local Interrupt = TMW.db.profile.ActionDB[4][list][GameLocale][spellName]
			local luaCode = Interrupt and Interrupt.LUA or nil
			
			if list:match("TargetMouseover") then
				if (not Action.GetToggle(4, "TargetMouseoverList") and (not Action.IsInPvP or (Action.Unit(unitID):IsHealer() and TimeToDie(unitID) < 6))) or (Action.InterruptEnabled(list, spellName) and RunLua(luaCode, unitID)) then 
					if Interrupt then 
						return bl_useKick or Interrupt.useKick, bl_useCC or Interrupt.useCC, bl_useRacial or Interrupt.useRacial
					else
						return bl_useKick or true, bl_useCC or true, bl_useRacial or true 
					end 
				end 
			elseif list == "Heal" then 
				if Action.InterruptEnabled(list, spellName) and (not Action.GetToggle(4, "KickHealOnlyHealers") or Action.Unit(unitID):IsHealer()) and RunLua(luaCode, unitID) then 
					if Interrupt then 
						return bl_useKick or Interrupt.useKick, bl_useCC or Interrupt.useCC, bl_useRacial or Interrupt.useRacial
					else
						return bl_useKick or true, bl_useCC or true, bl_useRacial or true
					end 
				end 
			elseif list == "PvP" then 
				if Action.InterruptEnabled(list, spellName) and (not Action.GetToggle(4, "KickPvPOnlySmart") or SmartInterrupt()) and RunLua(luaCode, unitID) then 
					if Interrupt then 
						return bl_useKick or Interrupt.useKick, bl_useCC or Interrupt.useCC, bl_useRacial or Interrupt.useRacial
					else
						return bl_useKick or true, bl_useCC or true, bl_useRacial or true 
					end 
				end 
			end
		end 
	end 
	return false, false, false
end 

-- [5] Auras
-- Note: Toggles  ("UseDispel", "UsePurge", "UseExpelEnrage", "UseExpelFrenzy")  
--		 Category ("Poison", "Disease", "Curse", "Magic", "PurgeFriendly", "PurgeHigh", "PurgeLow", "Enrage", "Frenzy", "BlackList")				
function Action.AuraIsON(Toggle)
	-- @return boolean 
	return type(Toggle) == "boolean" or TMW.db.profile.ActionDB[5][Toggle]
end 

function Action.AuraGetCategory(Category)
	-- @return table or nil (if not found category in certain Mode), string or (Filter)
	--[[ table basic structure:
		[Name] = { ID, Name, Enabled, Role, Dur, Stack, canStealOrPurge, onlyBear, LUA }
		-- Look DispelPurgeEnrageRemap about table create 
	]]
	local Mode = Action.IsInPvP and "PvP" or "PvE"
	local Filter = "HARMFUL"
	if Category:match("Purge") or Category:match("Enrage") or Category:match("Frenzy") then 
		Filter = "HELPFUL"
	elseif Category:match("BlackList") then 
		Filter = Filter .. " HELPFUL"
	end 
	
	if TMW.db.profile.ActionDB[5][Mode] and TMW.db.profile.ActionDB[5][Mode][Category] then 
		return TMW.db.profile.ActionDB[5][Mode][Category][GameLocale], Filter
	end 
	
	if Action.Data.Auras[Mode] then 
		return Action.Data.Auras[Mode][Category], Filter
	end 
	
	return nil, Filter
end

function Action.AuraIsBlackListed(unitID)
	-- @return boolean 
	local Aura, Filter = Action.AuraGetCategory("BlackList")
	if Aura and next(Aura) then 
		for i = 1, huge do 
			local Name, _, count, _, duration, expirationTime, _, canStealOrPurge, _, id = UnitAura(unitID, i, Filter)
			if Name then
				if Aura[Name] and Aura[Name].Enabled and (Aura[Name].Role == "ANY" or (Aura[Name].Role == "HEALER" and Action.IamHealer) or (Aura[Name].Role == "DAMAGER" and not Action.IamHealer)) then 
					local Dur = expirationTime == 0 and huge or expirationTime - TMW.time
					if Dur > Aura[Name].Dur and (Aura[Name].Stack == 0 or count >= Aura[Name].Stack) and (not Aura[Name].canStealOrPurge or canStealOrPurge == true) and (not Aura[Name].onlyBear or Action.Unit(unitID):HasBuffs(5487) > 0) and RunLua(Aura[Name].LUA, unitID) then
						return true
					end 
				end 
			else
				break 
			end 
		end 
	end 
	return false 
end 

function Action.AuraIsValid(unitID, Toggle, Category)
	-- @return boolean 
	if Category ~= "BlackList" and Action.AuraIsON(Toggle) then 
		local Aura, Filter = Action.AuraGetCategory(Category)
		if Aura and not Action.AuraIsBlackListed(unitID) then 
			for i = 1, huge do			
				local Name, _, count, _, duration, expirationTime, _, canStealOrPurge, _, id = UnitAura(unitID, i, Filter)
				if Name then					
					if Aura[Name] and Aura[Name].Enabled and (Aura[Name].Role == "ANY" or (Aura[Name].Role == "HEALER" and Action.IamHealer) or (Aura[Name].Role == "DAMAGER" and not Action.IamHealer)) then 					
						local Dur = expirationTime == 0 and huge or expirationTime - TMW.time
						if Dur > Aura[Name].Dur and (Aura[Name].Stack == 0 or count >= Aura[Name].Stack) and (not Aura[Name].canStealOrPurge or canStealOrPurge == true) and (not Aura[Name].onlyBear or Action.Unit(unitID):HasBuffs(5487) > 0) and RunLua(Aura[Name].LUA, unitID) then
							return true
						end 
					end 
				else
					break 
				end 
			end 
		end
	end 
	return false 
end

-- [6] Cursor 
function Action.CursorInit()
	if not Action.IsGameTooltipInitializated then
		local function OnEvent(self)
			if Action.IsInitialized and Action[Action.PlayerClass] then 
				local UseLeft = Action.GetToggle(6, "UseLeft")
				local UseRight = Action.GetToggle(6, "UseRight")
				if UseLeft or UseRight then 
					local M = Action.IsInPvP and "PvP" or "PvE"
					local ObjectName = UnitName("mouseover")
					if ObjectName then 		
						-- UnitName 
						ObjectName = ObjectName:lower()
						local UnitNameKey = TMW.db.profile.ActionDB[6][M]["UnitName"][GameLocale][ObjectName]
						if UnitNameKey and UnitNameKey.Enabled and ((UnitNameKey.Button == "LEFT" and UseLeft) or (UnitNameKey.Button == "RIGHT" and UseRight)) and (not UnitNameKey.isTotem or Action.Unit("mouseover"):IsTotem() and not Action.Unit("target"):IsTotem()) and RunLua(UnitNameKey.LUA, "mouseover") then 
							Action.GameTooltipClick = UnitNameKey.Button
							return
						end 
					elseif self:IsShown() and self:GetEffectiveAlpha() >= 1 then 			
						-- GameTooltip 
						local focus = GetMouseFocus() 
						if focus and not focus:IsForbidden() and focus:GetName() == "WorldFrame" then
							local GameTooltipTable = TMW.db.profile.ActionDB[6][M]["GameToolTip"][GameLocale]
							if next(GameTooltipTable) then 						
								local Regions = { self:GetRegions() }
								for i = 1, #Regions do 					
									local region = Regions[i]							
									if region and region:GetObjectType() == "FontString" then 
										local text = region:GetText() 								
										if text then 
											text = text:lower()
											local GameTooltipKey = GameTooltipTable[text]
											if GameTooltipKey and GameTooltipKey.Enabled and ((GameTooltipKey.Button == "LEFT" and UseLeft) or (GameTooltipKey.Button == "RIGHT" and UseRight)) and (not GameTooltipKey.isTotem or Action.Unit("mouseover"):IsTotem() and not Action.Unit("target"):IsTotem()) and RunLua(GameTooltipKey.LUA, "mouseover") then 								
												Action.GameTooltipClick = GameTooltipKey.Button
												return 									
											end 
										end 
									end 
								end 
							end 
						end 
					end
				end 
				Action.GameTooltipClick = nil	
			end 				 			
		end
		
		-- PRE
		GameTooltip:HookScript("OnShow", OnEvent)
		-- POST
		GameTooltip:RegisterEvent("CURSOR_UPDATE")
		GameTooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		GameTooltip:HookScript("OnEvent", function(self, event) 
			if Action.GameTooltipClick and (event == "CURSOR_UPDATE" or (event == "UPDATE_MOUSEOVER_UNIT" and not UnitExists("mouseover"))) and self:IsShown() and self:GetEffectiveAlpha() >= 1 then  			
				Action.GameTooltipClick = nil	
				self:Hide()
			end 
		end)		
		GameTooltip:HookScript("OnTooltipCleared", function(self)
			if self:IsShown() then 
				OnEvent(self)
			else 
				Action.GameTooltipClick = nil 
			end 
		end)		
		
		Action.IsGameTooltipInitializated = true 
	end 
end 

-- [7] MSG System (Message)
--[[
local CompareUnitIDwithUnitName(unitID, unitName)
	local name, server = UnitName(unitID)
	if unitID == "player" then 
		server = GetRealmName():gsub(" ", "")
	end 
	local fullname = name .. "-" .. server 
	return fullname == unitName
end 
]]

local function UpdateChat(...)
	if not Action.IsInitialized then 
		return 
	end 
	
	local msgList = Action.GetToggle(7, "msgList")
	if not msgList or next(msgList) == nil then 
		return 
	end 
	
	local msg, sname  = ... 
	msg = msg:lower()
	for Name in pairs(msgList) do 
		if msgList[Name].Enabled and msg:match(Name) and (not msgList[Name].Source or msgList[Name].Source == sname) and Action[Action.PlayerClass][msgList[Name].Key] and (not Action.GetToggle(7, "DisableReToggle") or not Action[Action.PlayerClass][msgList[Name].Key]:IsQueued()) then  			
			local units = { "raid%d+", "party%d+", "arena%d+", "player", "target" }
			local unit
			
			for j = 1, #units do 
				unit = msg:match(units[j])
				if unit then 
					break
				end 
			end 
				
			--[[
			if not msgList[Name].Source then 
				for j = 1, #units do 
					unit = msg:match(units[j])
					if unit then 
						break
					end 
				end 
			else 
				if CompareUnitIDwithUnitName("player", sname) then 
					unit = "player"
				elseif CompareUnitIDwithUnitName("target", sname) then
					unit = "target"
				else 
					for j = 1, Action.TeamCache.Friendly.Size do 
						local cUnit = Action.TeamCache.Friendly.Type .. j 
						if CompareUnitIDwithUnitName(cUnit, sname) then
							unit = cUnit
							break 
						end 
					end 
					
					if not unit then 
						for j = 1, Action.TeamCache.Enemy.Size do 
							local cUnit = Action.TeamCache.Enemy.Type .. j 
							if CompareUnitIDwithUnitName(cUnit, sname) then
								unit = cUnit
								break 
							end 
						end 					
					end 
				end 
			end
			]]			
			
			if unit then 
				if RunLua(msgList[Name].LUA, unit) then 
					-- Note: Regarding "player" unit here is a lot of profiles which don't support slot 6 and mostly 6 slot is valid for healer which has different @target always 
					-- Since damager / tank always has @target an enemy then "player" will be applied even if spell will be launched in slot 3-4 
					if unit:match("raid") then 
						local raidunits = { { u = "player", meta = Action.IamHealer and 6 or nil }, { u = "party1", meta = 7 }, { u = "party2", meta = 8} }					
						for j = 1, #raidunits do 
							if UnitIsUnit(unit, raidunits[j].u) then 							
								Action.MacroQueue(msgList[Name].Key, { Unit = raidunits[j].u, MetaSlot = raidunits[j].meta })							
								break 
							end 
						end 					
					elseif unit:match("party") then 
						if unit == "party1" then 
							Action.MacroQueue(msgList[Name].Key, { Unit = unit, MetaSlot = 7 })
						elseif unit == "party2" then
							Action.MacroQueue(msgList[Name].Key, { Unit = unit, MetaSlot = 8 })
						end 
					elseif unit:match("arena") then 
						if unit == "arena1" then 
							Action.MacroQueue(msgList[Name].Key, { Unit = unit, MetaSlot = 6 })
						elseif unit == "arena2" then 
							Action.MacroQueue(msgList[Name].Key, { Unit = unit, MetaSlot = 7 })
						elseif unit == "arena3" then 
							Action.MacroQueue(msgList[Name].Key, { Unit = unit, MetaSlot = 8 })
						end 
					elseif unit == "player" then 
						Action.MacroQueue(msgList[Name].Key, { Unit = "player" }) -- , MetaSlot = Action.IamHealer and 6 or nil
					else 
						Action.MacroQueue(msgList[Name].Key, { Unit = unit })
					end 
				end 
			else
				if msgList[Name].LUA ~= nil and msgList[Name].LUA ~= "" then 
					local Key = Action[Action.PlayerClass][msgList[Name].Key]		
					if Key:HasRange() then
						unit = (Key:IsHarmful() or (Key:IsHelpful() and (Key.Type == "Spell" or Action.IamHealer)) and "target") or (Key.Type ~= "Spell" and ((not Action.IamHealer and "player") or "target")) or "player"
					end 
				end 
			
				if RunLua(msgList[Name].LUA, unit or "target") then
					Action.MacroQueue(msgList[Name].Key, { Unit = unit })
				end 
			end	
		end        
    end  
end 

function Action.ToggleMSG(isLaunch)
	if not isLaunch and Action.IsInitialized then 
		Action.SetToggle({7, "MSG_Toggle", L["TAB"][7]["MSG"] .. " : "})
	end
	
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")	
	
	if Action.GetToggle(7, "MSG_Toggle") then 
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY", 			UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER", 	UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID", 			UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER", 	UpdateChat)
	end 	
	
	if Action.MainUI and Action.Data.ProfileUI and Action.Data.ProfileUI[7] and Action.Data.ProfileUI[7][Action.PlayerClass] and next(Action.Data.ProfileUI[7][Action.PlayerClass]) then 
		local spec = Action.PlayerClass .. CL
		local tab = tabFrame.tabs[7]
		if tab and tab.childs[spec] then 
			local anchor = GetAnchor(tab, spec)
			local kids = GetKids(tab, spec)
			for _, child in ipairs(kids) do 				
				if child.Identify and child.Identify.Toggle == "DisableReToggle" then 
					if Action.GetToggle(7, "MSG_Toggle") then 
						child:Enable()
					else 
						child:Disable()
					end 
					break 
				end 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- UI: Toggles
-------------------------------------------------------------------------------
function Action.SetToggle(arg, custom)
	-- @usage: Action.SetToggle({ tab.name (@number), key (@string ActionDB), text (@string optional for Print), silence (@boolean optional for Print) }, custom (@any value to set - optional))
	if not TMW.db.profile.ActionDB then 
		Action.Print(TMW.db:GetCurrentProfile() .. "  " .. L["NOSUPPORT"])
		return
	end 
	
	local bool 
	local n, toggle, text, silence = arg[1], arg[2], arg[3], arg[4]
	if TMW.db.global.ActionDB[toggle] ~= nil then 
		if custom ~= nil then 
			TMW.db.global.ActionDB[toggle] = custom		
		else 
			TMW.db.global.ActionDB[toggle] = not TMW.db.global.ActionDB[toggle]	
		end 
		
		bool = TMW.db.global.ActionDB[toggle] 		
	elseif Factory[n] and Factory[n][toggle] ~= nil then 
		if custom ~= nil then 
			TMW.db.profile.ActionDB[n][toggle] = custom 	
		else 
			TMW.db.profile.ActionDB[n][toggle] = not TMW.db.profile.ActionDB[n][toggle]	
		end 
		
		bool = TMW.db.profile.ActionDB[n][toggle] 
	elseif TMW.db.profile.ActionDB[n] == nil or TMW.db.profile.ActionDB[n][toggle] == nil then
		if not silence then 
			Action.Print(L["DEBUG"] .. (n or "") .. " " .. (toggle or "") .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle")
		end
		return 
	else 
		-- Usually only for Dropdown in multi. Logic is simply:
		-- 1 Create (or refresh) cache of all instances in DB if any is ON (true or with value), then turn all OFF if anything was ON. 
		-- 2 Or if all OFF then:
		-- 2.1 If no cache (means all was OFF) then make ON all (next time it will repeat 1 step to create cache)
		-- 2.2 If cache exist then turn ON from cache 
		-- /run TMW.db.profile.ActionDB[1].Trinkets.Cache = nil
		if type(TMW.db.profile.ActionDB[n][toggle]) == "table" then 
			local anyIsON = false
			for k, v in pairs(TMW.db.profile.ActionDB[n][toggle]) do 
				if TMW.db.profile.ActionDB[n][toggle][k] and k ~= "Cache" and not anyIsON then 
					TMW.db.profile.ActionDB[n][toggle].Cache = {}								
					for k1, v1 in pairs(TMW.db.profile.ActionDB[n][toggle]) do 
						if k1 ~= "Cache" then 
							TMW.db.profile.ActionDB[n][toggle].Cache[k1] = v1
						end
					end										
					anyIsON = true 
					break 
				end 
			end 
			
			if anyIsON then 
				for k, v in pairs(TMW.db.profile.ActionDB[n][toggle]) do
					if TMW.db.profile.ActionDB[n][toggle][k] and k ~= "Cache" then 
						if custom ~= nil then 
							TMW.db.profile.ActionDB[n][toggle][k] = custom
						else 
							TMW.db.profile.ActionDB[n][toggle][k] = not v
						end 
						
						if text then 
							Action.Print(text .. " " .. k .. ": ", TMW.db.profile.ActionDB[n][toggle][k])
						end 
					end 
				end 
			elseif TMW.db.profile.ActionDB[n][toggle].Cache then 			
				for k, v in pairs(TMW.db.profile.ActionDB[n][toggle].Cache) do	
					if k ~= "Cache" then 
						TMW.db.profile.ActionDB[n][toggle][k] = v	
						if text then 
							Action.Print(text .. " " .. k .. ": ", TMW.db.profile.ActionDB[n][toggle][k])
						end
					end
				end 
			else 
				for k, v in pairs(TMW.db.profile.ActionDB[n][toggle]) do
					if k ~= "Cache" then 
						if custom ~= nil then 
							TMW.db.profile.ActionDB[n][toggle][k] = custom
						else 
							TMW.db.profile.ActionDB[n][toggle][k] = not v 
						end 
						
						if text then 
							Action.Print(text .. " " .. k .. ": ", TMW.db.profile.ActionDB[n][toggle][k])
						end		
					end
				end 				
			end 
		else 
			if custom ~= nil then 
				TMW.db.profile.ActionDB[n][toggle] = custom					
			else 
				TMW.db.profile.ActionDB[n][toggle] = not TMW.db.profile.ActionDB[n][toggle]	
			end 			
		end
		bool = TMW.db.profile.ActionDB[n][toggle] 
	end 
		
	if toggle == "ReTarget" then 
		Re:Initialize()
	end 
	
	if toggle == "LOSCheck" then 
		LineOfSight:Initialize()
	end 
	
	if toggle == "HE_AnyRole" then 
		TMW:Fire("TMW_ACTION_HEALINGENGINE_ANY_ROLE")
	end 
	
	if text and type(bool) ~= "table" then 
		local boolprint = bool
		if type(bool) == "number" and bool < 0 then 			
			if toggle ~= "FPS" then 
				boolprint = "|cffff0000OFF|r"
			else 
				boolprint = "|cff00ff00AUTO|r"
			end 
		end 
		if toggle == "HE_Toggle" then 
			boolprint = L["TAB"][1][bool]
		end 
		
		if not silence then
			Action.Print(text, boolprint)
		end 
	end

	-- Fires callback for AoE to display DogTag
	if n == 1 and toggle == "Burst" then 
		TMW:Fire("TMW_ACTION_BURST_CHANGED")
		TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 		 
	elseif n == 2 and strlowerCache[toggle] == "aoe" then 
		TMW:Fire("TMW_ACTION_AOE_CHANGED")
		TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED") -- Taste's callback 
	end 		
	
	if Action.MainUI then 		
		local spec = Action.PlayerClass .. CL
		local tab = tabFrame.tabs[n]
		if tab and tab.childs[spec] then 
			local anchor = GetAnchor(tab, spec)
			local kids = GetKids(tab, spec)
			for _, child in ipairs(kids) do 				
				if child.Identify and child.Identify.Toggle == toggle then 
					-- SetValue not uses here because it will trigger OnValueChanged which we don't need in case of performance optimization
					if child.Identify.Type == "Checkbox" then
						if n == 4 then 
							-- Exception to trigger OnValueChanged callback 
							child:SetChecked(bool)
						else 
							child.isChecked = bool 
							if child.isChecked then
								child.checkedTexture:Show()
							else 
								child.checkedTexture:Hide()
							end							
						end
					elseif child.Identify.Type == "Dropdown" then						
						if child.multi then 
							local SetVal = {}
							for i = 1, #child.optsFrame.scrollChild.items do 													
								child.optsFrame.scrollChild.items[i].isChecked = TMW.db.profile.ActionDB[tab.name][toggle][i]								
								if child.optsFrame.scrollChild.items[i].isChecked then 
									child.optsFrame.scrollChild.items[i].checkedTexture:Show()
									tinsert(SetVal, child.optsFrame.scrollChild.items[i].value)
								else 
									child.optsFrame.scrollChild.items[i].checkedTexture:Hide()										
								end 
							end 							
							child.value = SetVal
							child:SetText(child:FindValueText(SetVal))
						else 
							child.value = bool
							if toggle == "HE_Toggle" then 
								child:SetText(L["TAB"][1][bool])
							else 
								child:SetText(bool)
							end
						end 
					elseif child.Identify.Type == "Slider" then							
						child:SetValue(bool) 
					end 
					return  
				end
			end 	
		end		
	end 		 	
end 	

local function failedReturn(n, toggle)
	if n == 1 then 
		if toggle == "FPS" then
			return TMW.db.global.Interval
		end 	
		
		if toggle == "DisableMinimap" or toggle == "DisableRotationDisplay" or toggle == "DisableClassPortraits" then 
			return true
		end 
		
		if toggle == "cameraDistanceMaxZoomFactor" then 			
			return Action.IsGGLprofile or (TMW.db and TMW.db:GetCurrentProfile():match("GGL") and true)
		end 
		
		if toggle == "Role" then 
			return "AUTO"
		end 
		
		if toggle == "HE_Toggle" then 
			return "ALL"
		end 
		
		if toggle == "HE_Pets" or "HE_AnyRole" then 
			return false 
		end 
	end 
	
	if n == 2 then 
		if toggle == "Runes" then 
			return 
		else  
			Action.Print(TMW.db:GetCurrentProfile() .. " - Toggle: [" .. (n or "") .. "] " .. toggle .. " " .. (L and L["NOSUPPORT"] or ""))
			return 
		end 
	end 
	
	if TMW.db then 
		Action.Print(TMW.db:GetCurrentProfile() .. " - Toggle: [" .. (n or "") .. "] " .. toggle .. " " .. (L and L["NOSUPPORT"] or ""), nil, true)
	end 
	return
end 
function Action.GetToggle(n, toggle)
	-- @usage: Action.GetToggle(tab.name (@number), key (@string ActionDB))
	if not TMW.db or not TMW.db.profile.ActionDB or not TMW.db.global.ActionDB then 		
		return failedReturn(n, toggle)
	end 
	
	local bool 
	if TMW.db.global.ActionDB[toggle] ~= nil then 	
		bool = TMW.db.global.ActionDB[toggle] 		
	elseif TMW.db.profile.ActionDB[n] == nil then 
		return failedReturn(n, toggle)
	else
		bool = TMW.db.profile.ActionDB[n][toggle] 	
	end 
	
	return bool	
end 	

function Action.ToggleMinimap()
	if Action.Minimap then 
		if Action.IsInitialized then 
			Action.SetToggle({1, "DisableMinimap", L["TAB"][1]["DISABLEMINIMAP"] .. " : "})
		end
		if Action.GetToggle(1, "DisableMinimap") then 
			LibDBIcon:Hide("ActionUI")
		else 
			LibDBIcon:Show("ActionUI")
		end 		
	end 
end 

function Action.ToggleMainUI()
	if not Action.MainUI and not Action.IsInitialized then 
		return 
	end 
	local spec = Action.PlayerClass .. CL
	if Action.MainUI then 	
		if Action.MainUI:IsShown() then 
			Action.MainUI:SetShown(not Action.MainUI:IsShown())
			return
		else 
			Action.MainUI:SetShown(not Action.MainUI:IsShown())	
			Action.MainUI.PDateTime:SetText(TMW.db:GetCurrentProfile() .. "\n" .. (Action.Data.ProfileUI.DateTime or ""))			
		end 
	else 
		Action.MainUI = StdUi:Window(UIParent, "The Action", 540, 640)	
		Action.MainUI.titlePanel.label:SetFontSize(20)
		Action.MainUI.default_w = Action.MainUI:GetWidth()
		Action.MainUI.default_h = Action.MainUI:GetHeight()
		Action.MainUI.titlePanel:SetPoint("TOP", 0, -15)
		Action.MainUI:SetFrameStrata("HIGH")
		Action.MainUI:SetPoint("CENTER")
		Action.MainUI:SetShown(true) 
		Action.MainUI:RegisterEvent("UI_SCALE_CHANGED")
		Action.MainUI:RegisterEvent("CRAFT_SHOW")
		Action.MainUI:SetScript("OnEvent", function(self, event, ...)
			if event == "CRAFT_SHOW" then 
				if self:IsShown() then 
					self:Hide()
				end 
			end 
			
			if event == "UI_SCALE_CHANGED" then 
				Action.TimerSetRefreshAble("ACTION_UI_SCALE_SET", 0.001, SetProperlyScale)
			end 
		end)
				
		Action.MainUI:EnableKeyboard(true)
		Action.MainUI:SetPropagateKeyboardInput(true)
		--- Catches the game menu bind just before it fires.
		Action.MainUI:SetScript("OnKeyDown", function (self, Key)				
			if GetBindingFromClick(Key) == "TOGGLEGAMEMENU" and Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
		--- Disallows closing the dialogs once the game menu bind is processed.
		hooksecurefunc("ToggleGameMenu", function()			
			if Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)	
		--- Catches shown (aka clicks) on default "?" GameMenu 
		Action.MainUI.GameMenuFrame = CreateFrame("Frame", nil, _G["GameMenuFrame"])
		Action.MainUI.GameMenuFrame:SetScript("OnShow", function()
			if Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
		
		Action.MainUI.PDateTime = StdUi:FontString(Action.MainUI, TMW.db:GetCurrentProfile() .. "\n" .. (Action.Data.ProfileUI.DateTime or ""))
		Action.MainUI.PDateTime:SetJustifyH("RIGHT")
		Action.MainUI.GDateTime = StdUi:FontString(Action.MainUI, L["GLOBALAPI"] .. DateTime)	
		Action.MainUI.GDateTime:SetJustifyH("RIGHT")
		StdUi:GlueBefore(Action.MainUI.PDateTime, Action.MainUI.closeBtn, -5, 0)
		StdUi:GlueBelow(Action.MainUI.GDateTime, Action.MainUI.PDateTime, 0, 0, "RIGHT")
		
		Action.MainUI.AllReset = StdUi:Button(Action.MainUI, 100, 35, L["TAB"]["RESETBUTTON"])
		StdUi:ButtonAutoWidth(Action.MainUI.AllReset)
		StdUi:GlueTop(Action.MainUI.AllReset, Action.MainUI, 10, -10, "LEFT")
		Action.MainUI.AllReset:SetScript('OnClick', function()
			Action.MainUI.ResetQuestion:SetShown(not Action.MainUI.ResetQuestion:IsShown())
		end)
		
		Action.MainUI.ResetQuestion = StdUi:Window(Action.MainUI, L["TAB"]["RESETQUESTION"], 350, 250)
		Action.MainUI.ResetQuestion:SetPoint("CENTER")
		Action.MainUI.ResetQuestion:SetFrameStrata("TOOLTIP")
		Action.MainUI.ResetQuestion:SetFrameLevel(50)
		Action.MainUI.ResetQuestion:SetBackdropColor(0, 0, 0, 1)
		Action.MainUI.ResetQuestion:SetMovable(false)
		Action.MainUI.ResetQuestion:SetShown(false)
		Action.MainUI.ResetQuestion:SetScript("OnDragStart", nil)
		Action.MainUI.ResetQuestion:SetScript("OnDragStop", nil)
		Action.MainUI.ResetQuestion:SetScript("OnReceiveDrag", nil)
		
		Action.MainUI.CheckboxSaveActions = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEACTIONS"])
		Action.MainUI.CheckboxSaveInterrupt = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEINTERRUPT"])			
		Action.MainUI.CheckboxSaveDispel = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEDISPEL"])
		Action.MainUI.CheckboxSaveMouse	= StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEMOUSE"])	
		Action.MainUI.CheckboxSaveMSG = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEMSG"])
		
		Action.MainUI.Yes = StdUi:Button(Action.MainUI.ResetQuestion, 150, 35, L["YES"])		
		StdUi:GlueBottom(Action.MainUI.Yes, Action.MainUI.ResetQuestion, 20, 20, "LEFT")
		Action.MainUI.Yes:SetScript("OnClick", function()
			local ProfileSave, GlobalSave = {}, {}
			if Action.MainUI.CheckboxSaveActions:GetChecked() then 
				ProfileSave[3] = {}
				for k, v in pairs(TMW.db.profile.ActionDB[3]) do 
					if type(v) == "table" then
						ProfileSave[3][k] = v					
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveInterrupt:GetChecked() then 
				ProfileSave[4] = {}
				for k, v in pairs(TMW.db.profile.ActionDB[4]) do 	
					if type(v) == "table" then 	
						ProfileSave[4][k] = v
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveDispel:GetChecked() then 
				GlobalSave[5] = {}
				for k, v in pairs(TMW.db.global.ActionDB[5]) do					
					GlobalSave[5][k] = v					
				end
			end 
			if Action.MainUI.CheckboxSaveMouse:GetChecked() then 	
				ProfileSave[6] = {}
				for k, v in pairs(TMW.db.profile.ActionDB[6]) do
					if type(v) == "table" then 
						ProfileSave[6][k] = v
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveMSG:GetChecked() then 	
				ProfileSave[7] = {}
				for k, v in pairs(TMW.db.profile.ActionDB[7]) do
					if type(v) == "table" then 	
						ProfileSave[7][k] = v						
					end 
				end
			end 
			wipe(TMW.db.global.ActionDB)
			wipe(TMW.db.profile.ActionDB)
			if next(ProfileSave) or #ProfileSave > 0 then 
				TMW.db.profile.ActionDB = ProfileSave				
			end 
			if next(GlobalSave) or #GlobalSave > 0 then 
				TMW.db.global.ActionDB = GlobalSave
			end
			C_UI.Reload()	
		end)
		
		Action.MainUI.No = StdUi:Button(Action.MainUI.ResetQuestion, 150, 35, L["NO"])
		StdUi:GlueBottom(Action.MainUI.No, Action.MainUI.ResetQuestion, -20, 20, "RIGHT")
		Action.MainUI.No:SetScript("OnClick", function()
			Action.MainUI.ResetQuestion:Hide()
		end)			

		StdUi:GlueBottom(Action.MainUI.CheckboxSaveActions, Action.MainUI.ResetQuestion, 20, 30 + Action.MainUI.Yes:GetHeight(), "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveInterrupt, Action.MainUI.CheckboxSaveActions, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveDispel, Action.MainUI.CheckboxSaveInterrupt, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveMouse, Action.MainUI.CheckboxSaveDispel, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveMSG, Action.MainUI.CheckboxSaveMouse, 0, 10, "LEFT")
		
		tabFrame = StdUi:TabPanel(Action.MainUI, nil, nil, {
			{
				name = 1,
				title = L["TAB"][1]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 2,
				title = Action.PlayerClassName,
				childs = {},
			},
			{
				name = 3,
				title = L["TAB"][3]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 4,
				title = L["TAB"][4]["HEADBUTTON"],	
				childs = {},		
			},
			{
				name = 5,
				title = L["TAB"][5]["HEADBUTTON"],		
				childs = {},
			},
			{
				name = 6,
				title = L["TAB"][6]["HEADBUTTON"],		
				childs = {},
			},			
			{
				name = 7,
				title = "MSG",	
				childs = {},
			},
		})
		StdUi:GlueAcross(tabFrame, Action.MainUI, 10, -50, -10, 10)
		tabFrame.container:SetPoint('TOPLEFT', tabFrame.buttonContainer, 'BOTTOMLEFT', 0, 0)
		tabFrame.container:SetPoint('TOPRIGHT', tabFrame.buttonContainer, 'BOTTOMRIGHT', 0, 0)	
		
		-- Create resizer		
		Action.MainUI.resizer = CreateResizer(Action.MainUI)
		if Action.MainUI.resizer then 			
			function Action.MainUI.UpdateResize() 
				tabFrame:EnumerateTabs(function(tab)
					for spec in pairs(tab.childs) do						
						local specCL = spec:gsub(Action.PlayerClass, "")
						if tab.childs[spec] and specCL == CL then									
							-- Easy Layout (main)
							local anchor = GetAnchor(tab, spec)							
							if anchor.layout then 
								anchor:DoLayout()
							end	
						
							local kids = GetKids(tab, spec)
							for _, child in ipairs(kids) do								
								-- EasyLayout (additional)
								if child.layout then 
									child:DoLayout()
								end 	
								-- Dropdown 
								if child.dropTex then 
									-- EasyLayout will resize button so we can don't care
									-- Resize scroll "panel" (container) 
									child.optsFrame:SetWidth(child:GetWidth())
									-- Resize scroll "lines" (list grid)
									for i = 1, #child.optsFrame.scrollChild.items do 
										child.optsFrame.scrollChild.items[i]:SetWidth(child:GetWidth())									
									end 									
								end 
								-- ScrollTable
								if child.data and child.columns then 
									for i = 1, #child.columns do 										
										if child.columns[i].index == "Name" then
											-- Column by Name resize
											child.columns[i].width = round(child.columns[i].defaultwidth + (Action.MainUI:GetWidth() - Action.MainUI.default_w), 0)
											child:SetColumns(child.columns)	
											-- Row resize
											child.numberOfRows = child.defaultrows.numberOfRows + round((Action.MainUI:GetHeight() - Action.MainUI.default_h) / child.defaultrows.rowHeight, 0)
											child:SetDisplayRows(child.numberOfRows, child.defaultrows.rowHeight)
											break 
										end 
									end
									break
								end 
							end 						
						end 						
					end 
				end)
			end 
			Action.MainUI:HookScript("OnSizeChanged", Action.MainUI.UpdateResize)
			-- I don't know how to fix layout overleap problem caused by resizer after hide, so I did some trick through this:
			-- If you have a better idea let me know 
			Action.MainUI:HookScript("OnHide", function(self) 
				Action.MainUI.RememberTab = tabFrame.selected 
				tabFrame:SelectTab(tabFrame.tabs[1].name)		
				Action.MainUI.UpdateResize()
			end)
			Action.MainUI:HookScript("OnShow", function(self)
				if Action.MainUI.RememberTab then 
					tabFrame:SelectTab(tabFrame.tabs[Action.MainUI.RememberTab].name)
				end 				
				Action.MainUI.UpdateResize()
				TMW:TT(self.resizer.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
			end)
		end 
	end 
	
	if not Action.GetToggle(1, "DisableSounds") then 
		PlaySound(5977)
	end 
	
	SetProperlyScale()
	
	tabFrame:EnumerateTabs(function(tab)
		for k in pairs(tab.childs) do
			if k ~= spec then 
				tab.childs[k]:Hide()
			end 
		end		
		if tab.childs[spec] then 
			tab.childs[spec]:Show()			
			return
		end  
		if tab.name == 1 or tab.name == 2 then 
			tab.childs[spec] = StdUi:ScrollFrame(tab.frame, tab.frame:GetWidth(), tab.frame:GetHeight()) 			
			tab.childs[spec]:SetAllPoints()
			tab.childs[spec]:Show()			
		else 
			tab.childs[spec] = StdUi:Frame(tab.frame) 
			tab.childs[spec]:SetAllPoints()		
			tab.childs[spec]:Show()
		end
		
		local anchor = GetAnchor(tab, spec)
		
		local UI_Title = StdUi:FontString(anchor, tab.title)
		UI_Title:SetFont(UI_Title:GetFont(), 15)
        StdUi:GlueTop(UI_Title, anchor, 0, -10)
		if not StdUi.config.font.color.yellow then 
			local colored = { UI_Title:GetTextColor() }
			StdUi.config.font.color.yellow = { r = colored[1], g = colored[2], b = colored[3], a = colored[4] }
		end 
		
		local UI_Separator = StdUi:FontString(anchor, '')
        StdUi:GlueBelow(UI_Separator, UI_Title, 0, -5)
		
		-- We should leave "OnShow" handlers because user can swap language, otherwise in performance case better remove it 		
		if tab.name == 1 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget
			StdUi:InitWidget(anchor)
			
			StdUi:EasyLayout(anchor, { padding = { top = 40, right = 10 + 20 } }) -- { padding = { top = 40 } })	
			
			local PvEPvPToggle = StdUi:Button(anchor, GetWidthByColumn(anchor, 5.5), Action.Data.theme.dd.height, L["TOGGLEIT"])
			PvEPvPToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			PvEPvPToggle:SetScript('OnClick', function(self, button, down)
				if button == "LeftButton" then 
					Action.ToggleMode()
				elseif button == "RightButton" then 
					CraftMacro("PvEPvPToggle", [[/run Action.ToggleMode()]])	
				end 
			end)
			StdUi:FrameTooltip(PvEPvPToggle, L["TAB"][tab.name]["PVEPVPTOGGLETOOLTIP"], nil, "TOPRIGHT", true)
			PvEPvPToggle.FontStringTitle = StdUi:FontString(PvEPvPToggle, L["TAB"][tab.name]["PVEPVPTOGGLE"])
			StdUi:GlueAbove(PvEPvPToggle.FontStringTitle, PvEPvPToggle)
			
			local PvEPvPresetbutton = StdUi:SquareButton(anchor, PvEPvPToggle:GetHeight(), PvEPvPToggle:GetHeight(), "DELETE")
			PvEPvPresetbutton:SetScript('OnClick', function()
				Action.IsLockedMode = false
				Action.IsInPvP = Action:CheckInPvP()	
				Action.Print(L["RESETED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
				TMW:Fire("TMW_ACTION_MODE_CHANGED")
			end)
			StdUi:FrameTooltip(PvEPvPresetbutton, L["TAB"][tab.name]["PVEPVPRESETTOOLTIP"], nil, "TOPRIGHT", true)					

			local InterfaceLanguages = {
				{ text = "Auto", value = "Auto" },	
			}
			for Language in pairs(Localization) do 
				table.insert(InterfaceLanguages, { text = Language, value = Language })
			end 
			anchor.InterfaceLanguage = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, InterfaceLanguages)         
			anchor.InterfaceLanguage:SetValue(TMW.db.global.ActionDB.InterfaceLanguage)
			anchor.InterfaceLanguage.OnValueChanged = function(self, val)                				
				TMW.db.global.ActionDB.InterfaceLanguage = val				
				Action.GetLocalization()						
				Action.MainUI.AllReset.text = StdUi:ButtonLabel(Action.MainUI.AllReset, L["TAB"]["RESETBUTTON"])
				StdUi:ButtonAutoWidth(Action.MainUI.AllReset)
				Action.MainUI.GDateTime:SetText(L["GLOBALAPI"] .. DateTime)
				Action.MainUI.ResetQuestion.titlePanel.label:SetText(L["TAB"]["RESETQUESTION"])
				Action.MainUI.Yes.text = StdUi:ButtonLabel(Action.MainUI.Yes, L["YES"])
				Action.MainUI.No.text = StdUi:ButtonLabel(Action.MainUI.No, L["NO"])
				Action.MainUI.CheckboxSaveActions:SetText(L["TAB"]["SAVEACTIONS"])
				Action.MainUI.CheckboxSaveInterrupt:SetText(L["TAB"]["SAVEINTERRUPT"])
				Action.MainUI.CheckboxSaveDispel:SetText(L["TAB"]["SAVEDISPEL"])
				Action.MainUI.CheckboxSaveMouse:SetText(L["TAB"]["SAVEMOUSE"])
				Action.MainUI.CheckboxSaveMSG:SetText(L["TAB"]["SAVEMSG"])
				tabFrame.tabs[1].title = L["TAB"][1]["HEADBUTTON"]
				tabFrame.tabs[3].title = L["TAB"][3]["HEADBUTTON"]
				tabFrame.tabs[4].title = L["TAB"][4]["HEADBUTTON"]
				tabFrame.tabs[5].title = L["TAB"][5]["HEADBUTTON"]
				tabFrame.tabs[6].title = L["TAB"][6]["HEADBUTTON"]			
				tabFrame:DrawButtons()							
				spec = Action.PlayerClass .. CL	
				for i = 1, #tabFrame.tabs do
					local tab = tabFrame.tabs[i]
					if tab and tab.childs[spec] then -- don't touch tab.childs[spec]
						if i == 3 then 	
							if tab.childs[spec] and tab.childs[spec].ScrollTable then -- in case if profile is Basic without created actions 
								local ScrollTable = tab.childs[spec].ScrollTable -- don't touch tab.childs[spec]
								for index = 1, #ScrollTable.data do 								
									if ScrollTable.data[index]:IsBlocked() then 
										ScrollTable.data[index].Enabled = "False"
									else 
										ScrollTable.data[index].Enabled = "True"
									end								
								end
								ScrollTable:ClearSelection()			
							end 
						else 
							-- Redraw statement by Identify if that langue frame is already drawed							
							local kids = GetKids(tab, spec)
							for _, child in ipairs(kids) do 				
								if child.Identify and child.Identify.Toggle then 
									-- SetValue not uses here because it will trigger OnValueChanged which we don't need in case of performance optimization
									if child.Identify.Type == "Checkbox" then
										child.isChecked = Action.GetToggle(i, child.Identify.Toggle)
										if child.isChecked then
											child.checkedTexture:Show()
										else 
											child.checkedTexture:Hide()
										end
									elseif child.Identify.Type == "Dropdown" then						
										if child.multi then 
											local SetVal = {}
											for item = 1, #child.optsFrame.scrollChild.items do 													
												child.optsFrame.scrollChild.items[item].isChecked = Action.GetToggle(i, child.Identify.Toggle)[item]								
												if child.optsFrame.scrollChild.items[item].isChecked then 
													child.optsFrame.scrollChild.items[item].checkedTexture:Show()
													tinsert(SetVal, child.optsFrame.scrollChild.items[item].value)
												else 
													child.optsFrame.scrollChild.items[item].checkedTexture:Hide()										
												end 
											end 							
											child.value = SetVal
											child:SetText(child:FindValueText(SetVal))
										else 
											child.value = Action.GetToggle(i, child.Identify.Toggle)
											--child.text:SetText(child.value)
											child.text:SetText(child:FindValueText(child.value))
										end 
									elseif child.Identify.Type == "Slider" then							
										child:SetValue(Action.GetToggle(i, child.Identify.Toggle)) 
									end 								  
								end
							end 	
						end
					end
				end							
				Action.ToggleMainUI()
				Action.ToggleMainUI()	
			end			
			anchor.InterfaceLanguage.Identify = { Type = "Dropdown", Toggle = "InterfaceLanguage" }
			anchor.InterfaceLanguage.FontStringTitle = StdUi:FontString(anchor.InterfaceLanguage, L["TAB"][tab.name]["CHANGELANGUAGE"])
			StdUi:GlueAbove(anchor.InterfaceLanguage.FontStringTitle, anchor.InterfaceLanguage)
			anchor.InterfaceLanguage.text:SetJustifyH("CENTER")															
			
			local AutoTarget = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AUTOTARGET"])	
			AutoTarget:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoTarget)	
			AutoTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoTarget:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].AutoTarget = not TMW.db.profile.ActionDB[tab.name].AutoTarget	
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoTarget)	
					Action.Print(L["TAB"][tab.name]["AUTOTARGET"] .. ": ", TMW.db.profile.ActionDB[tab.name].AutoTarget)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["AUTOTARGET"], [[/run Action.SetToggle({]] .. tab.name .. [[, "AutoTarget", "]] .. L["TAB"][tab.name]["AUTOTARGET"] .. [[: "})]])	
				end 
			end)
			AutoTarget.Identify = { Type = "Checkbox", Toggle = "AutoTarget" }			
			StdUi:FrameTooltip(AutoTarget, L["TAB"][tab.name]["AUTOTARGETTOOLTIP"], nil, "TOPRIGHT", true)		
			AutoTarget.FontStringTitle = StdUi:FontString(AutoTarget, L["TAB"][tab.name]["CHARACTERSECTION"])
			StdUi:GlueAbove(AutoTarget.FontStringTitle, AutoTarget)
			
			local Potion = StdUi:Checkbox(anchor, L["TAB"][tab.name]["POTION"])		
			Potion:SetChecked(TMW.db.profile.ActionDB[tab.name].Potion)
			Potion:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Potion:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].Potion = not TMW.db.profile.ActionDB[tab.name].Potion
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].Potion)	
						Action.Print(L["TAB"][tab.name]["POTION"] .. ": ", TMW.db.profile.ActionDB[tab.name].Potion)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["POTION"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Potion", "]] .. L["TAB"][tab.name]["POTION"] .. [[: "})]])	
					end 
				end 
			end)
			Potion.Identify = { Type = "Checkbox", Toggle = "Potion" }	
			StdUi:FrameTooltip(Potion, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			local function PotionCheckboxUpdate()
				if Action.IsBasicProfile then 
					if not Potion.isDisabled then 
						Potion:Disable()
						Potion:SetChecked(false)
					end 
				elseif Potion.isDisabled then  					
					Potion:SetChecked(TMW.db.profile.ActionDB[tab.name].Potion)
					Potion:Enable()
				end 			
			end 
			Potion:SetScript("OnShow", PotionCheckboxUpdate)
			PotionCheckboxUpdate()

			local Racial = StdUi:Checkbox(anchor, L["TAB"][tab.name]["RACIAL"])			
			Racial:SetChecked(TMW.db.profile.ActionDB[tab.name].Racial)
			Racial:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Racial:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].Racial = not TMW.db.profile.ActionDB[tab.name].Racial
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].Racial)	
					Action.Print(L["TAB"][tab.name]["RACIAL"] .. ": ", TMW.db.profile.ActionDB[tab.name].Racial)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["RACIAL"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Racial", "]] .. L["TAB"][tab.name]["RACIAL"] .. [[: "})]])	
				end 
			end)
			Racial.Identify = { Type = "Checkbox", Toggle = "Racial" }
			StdUi:FrameTooltip(Racial, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	

			local StopCast = StdUi:Checkbox(anchor, L["TAB"][tab.name]["STOPCAST"])			
			StopCast:SetChecked(TMW.db.profile.ActionDB[tab.name].StopCast)
			StopCast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopCast:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].StopCast = not TMW.db.profile.ActionDB[tab.name].StopCast
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].StopCast)	
					Action.Print(L["TAB"][tab.name]["STOPCAST"] .. ": ", TMW.db.profile.ActionDB[tab.name].StopCast)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["STOPCAST"], [[/run Action.SetToggle({]] .. tab.name .. [[, "StopCast", "]] .. L["TAB"][tab.name]["STOPCAST"] .. [[: "})]])	
				end 
			end)
			StopCast.Identify = { Type = "Checkbox", Toggle = "StopCast" }
			StdUi:FrameTooltip(StopCast, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			
			local ReTarget = StdUi:Checkbox(anchor, "ReTarget")			
			ReTarget:SetChecked(TMW.db.profile.ActionDB[tab.name].ReTarget)
			ReTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			ReTarget:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].ReTarget = not TMW.db.profile.ActionDB[tab.name].ReTarget
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].ReTarget)	
					Action.Print("ReTarget" .. ": ", TMW.db.profile.ActionDB[tab.name].ReTarget)	
					Re:Initialize()
				elseif button == "RightButton" then 
					CraftMacro("ReTarget", [[/run Action.SetToggle({]] .. tab.name .. [[, "ReTarget", "]] .. "ReTarget" .. [[: "})]])	
				end 
			end)
			ReTarget.Identify = { Type = "Checkbox", Toggle = "ReTarget" }
			StdUi:FrameTooltip(ReTarget, L["TAB"][tab.name]["RETARGET"], nil, "TOPRIGHT", true)
			ReTarget.FontStringTitle = StdUi:FontString(ReTarget, L["TAB"][tab.name]["PVPSECTION"])
			StdUi:GlueAbove(ReTarget.FontStringTitle, ReTarget)						
			
			local LosSystem = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOSSYSTEM"])
			LosSystem:SetChecked(TMW.db.profile.ActionDB[tab.name].LOSCheck)
			LosSystem:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			LosSystem:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].LOSCheck = not TMW.db.profile.ActionDB[tab.name].LOSCheck
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].LOSCheck)	
					Action.Print(L["TAB"][tab.name]["LOSSYSTEM"] .. ": ", TMW.db.profile.ActionDB[tab.name].LOSCheck)
					LineOfSight:Initialize()	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["LOSSYSTEM"], [[/run Action.SetToggle({]] .. tab.name .. [[, "LOSCheck", "]] .. L["TAB"][tab.name]["LOSSYSTEM"] .. [[: "})]])	
				end 
			end)
			LosSystem.Identify = { Type = "Checkbox", Toggle = "LOSCheck" }				
			StdUi:FrameTooltip(LosSystem, L["TAB"][tab.name]["LOSSYSTEMTOOLTIP"], nil, "TOPLEFT", true)
			LosSystem.FontStringTitle = StdUi:FontString(LosSystem, L["TAB"][tab.name]["SYSTEMSECTION"])
			StdUi:GlueAbove(LosSystem.FontStringTitle, LosSystem)								
			
			local DBMFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DBM"])
			DBMFrame:SetChecked(TMW.db.profile.ActionDB[tab.name].DBM)
			DBMFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DBMFrame:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 	
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].DBM = not TMW.db.profile.ActionDB[tab.name].DBM
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].DBM)					
						Action.Print(L["TAB"][tab.name]["DBM"] .. ": ", TMW.db.profile.ActionDB[tab.name].DBM)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["DBM"], [[/run Action.SetToggle({]] .. tab.name .. [[, "DBM", "]] .. L["TAB"][tab.name]["DBM"] .. [[: "})]])	
					end 
				end
			end)
			DBMFrame.Identify = { Type = "Checkbox", Toggle = "DBM" }
			DBMFrame:SetScript("OnShow", function()
				if not DBM then 
					DBMFrame:Disable()
				else 
					DBMFrame:Enable()
				end 
			end)
			if not DBM then 
				DBMFrame:Disable()
			end 
			StdUi:FrameTooltip(DBMFrame, "Deadly Boss Mods\n" .. L["TAB"][tab.name]["DBMTOOLTIP"], nil, "TOPLEFT", true)
			
			local HE_AnyRole = StdUi:Checkbox(anchor, L["TAB"][tab.name]["HEALINGENGINEANYROLE"])		
			HE_AnyRole:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_AnyRole)
			HE_AnyRole:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HE_AnyRole:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 				
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].HE_AnyRole = not TMW.db.profile.ActionDB[tab.name].HE_AnyRole
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_AnyRole)							
						Action.Print(L["TAB"][tab.name]["HEALINGENGINEANYROLE"] .. ": ", TMW.db.profile.ActionDB[tab.name].HE_AnyRole)	
						TMW:Fire("TMW_ACTION_HEALINGENGINE_ANY_ROLE")
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEALINGENGINEANYROLE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HE_AnyRole", "]] .. L["TAB"][tab.name]["HEALINGENGINEANYROLE"] .. [[: "})]])	
					end 
				end 
			end)
			HE_AnyRole.Identify = { Type = "Checkbox", Toggle = "HE_AnyRole" }
			StdUi:FrameTooltip(HE_AnyRole, L["TAB"][tab.name]["HEALINGENGINEANYROLETOOLTIP"], nil, "TOPLEFT", true)
			local isUnavailableByClass = {
				WARRIOR = true, 
				HUNTER = true,
				ROGUE = true,
				MAGE = true,
				WARLOCK = true,				
			}
			local function HE_AnyRoleCheckboxUpdate()
				if Action.IsBasicProfile or isUnavailableByClass[Action.PlayerClass] then 
					if not HE_AnyRole.isDisabled then 
						HE_AnyRole:Disable()
						TMW.db.profile.ActionDB[tab.name].HE_AnyRole = false
						HE_AnyRole:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_AnyRole)
					end 
				elseif HE_AnyRole.isDisabled then  					
					HE_AnyRole:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_AnyRole)
					HE_AnyRole:Enable()
				end 			
				TMW:Fire("TMW_ACTION_HEALINGENGINE_ANY_ROLE")
			end 
			HE_AnyRole:SetScript("OnShow", HE_AnyRoleCheckboxUpdate)
			HE_AnyRoleCheckboxUpdate()			
			
			local HE_PetsFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["HEALINGENGINEPETS"])		
			HE_PetsFrame:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_Pets)
			HE_PetsFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HE_PetsFrame:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 				
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].HE_Pets = not TMW.db.profile.ActionDB[tab.name].HE_Pets
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].HE_Pets)							
						Action.Print(L["TAB"][tab.name]["HEALINGENGINEPETS"] .. ": ", TMW.db.profile.ActionDB[tab.name].HE_Pets)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEALINGENGINEPETS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HE_Pets", "]] .. L["TAB"][tab.name]["HEALINGENGINEPETS"] .. [[: "})]])	
					end 
				end 
			end)
			HE_PetsFrame.Identify = { Type = "Checkbox", Toggle = "HE_Pets" }			
			local function UpdateHealingEngineCheckbox()
				if not Action.IamHealer and not Action.GetToggle(1, "HE_AnyRole") then 
					HE_PetsFrame:Disable()
				else 
					HE_PetsFrame:Enable()
				end 			
			end 
			HE_PetsFrame:SetScript("OnShow", UpdateHealingEngineCheckbox)
			if not Action.IamHealer and not Action.GetToggle(1, "HE_AnyRole") then
				HE_PetsFrame:Disable()
			end 
			StdUi:FrameTooltip(HE_PetsFrame, L["TAB"][tab.name]["HEALINGENGINEPETSTOOLTIP"], nil, "TOPLEFT", true)
			TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 					UpdateHealingEngineCheckbox) 
			TMW:RegisterCallback("TMW_ACTION_HEALINGENGINE_ANY_ROLE", 							UpdateHealingEngineCheckbox) 
			
			local HE_ToggleFrame = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), 20, {
				{ text = L["TAB"][tab.name]["ALL"], value = "ALL" },
				{ text = L["TAB"][tab.name]["RAID"], value = "RAID" },				
				{ text = L["TAB"][tab.name]["TANK"], value = "TANK" },
				{ text = L["TAB"][tab.name]["DAMAGER"], value = "DAMAGER" },
				{ text = L["TAB"][tab.name]["HEALER"], value = "HEALER" },
				{ text = L["TAB"][tab.name]["TANKANDPARTY"], value = "TANKANDPARTY" },
				{ text = L["TAB"][tab.name]["PARTY"], value = "PARTY" },				
			})		          
			HE_ToggleFrame:SetValue(TMW.db.profile.ActionDB[tab.name].HE_Toggle)
			HE_ToggleFrame.OnValueChanged = function(self, val)                
				TMW.db.profile.ActionDB[tab.name].HE_Toggle = val 
				Action.Print("HealingEngine" .. ": ", L["TAB"][tab.name][TMW.db.profile.ActionDB[tab.name].HE_Toggle])
			end
			local function UpdateHealingEngineDropDown()
				if not Action.IamHealer and not Action.GetToggle(1, "HE_AnyRole") then 
					HE_ToggleFrame:Disable()
				else 
					HE_ToggleFrame:Enable()
				end 			
			end 
			HE_ToggleFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HE_ToggleFrame:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro("HealingEngine", [[/run Action.ToggleHE()]])	
					end
				end 
			end)	
			HE_ToggleFrame:SetScript("OnShow", UpdateHealingEngineDropDown)				
			if not Action.IamHealer and not Action.GetToggle(1, "HE_AnyRole") then
				HE_ToggleFrame:Disable()
			end 
			HE_ToggleFrame.Identify = { Type = "Dropdown", Toggle = "HE_Toggle" }
			StdUi:FrameTooltip(HE_ToggleFrame, L["TAB"][tab.name]["HEALINGENGINETOOLTIP"], nil, "TOPLEFT", true)
			HE_ToggleFrame.FontStringTitle = StdUi:FontString(HE_ToggleFrame, "HealingEngine")
			StdUi:GlueBelow(HE_ToggleFrame.FontStringTitle, HE_ToggleFrame)	
			HE_ToggleFrame.text:SetJustifyH("CENTER")			
			TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 					UpdateHealingEngineDropDown) 
			TMW:RegisterCallback("TMW_ACTION_HEALINGENGINE_ANY_ROLE", 							UpdateHealingEngineDropDown) 
			
			local StopAtBreakAble = StdUi:Checkbox(anchor, L["TAB"][tab.name]["STOPATBREAKABLE"])			
			StopAtBreakAble:SetChecked(TMW.db.profile.ActionDB[tab.name].StopAtBreakAble)
			StopAtBreakAble:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopAtBreakAble:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].StopAtBreakAble = not TMW.db.profile.ActionDB[tab.name].StopAtBreakAble
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].StopAtBreakAble)	
					Action.Print(L["TAB"][tab.name]["STOPATBREAKABLE"] .. ": ", TMW.db.profile.ActionDB[tab.name].StopAtBreakAble)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["STOPATBREAKABLE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "StopAtBreakAble", "]] .. L["TAB"][tab.name]["STOPATBREAKABLE"] .. [[: "})]])	
				end 
			end)
			StopAtBreakAble.Identify = { Type = "Checkbox", Toggle = "StopAtBreakAble" }
			StdUi:FrameTooltip(StopAtBreakAble, L["TAB"]["STOPATBREAKABLETOOLTIP"], nil, "TOPLEFT", true)	
			
			local FPS = StdUi:Slider(anchor, GetWidthByColumn(anchor, 5.8), Action.Data.theme.dd.height, TMW.db.profile.ActionDB[tab.name].FPS, false, -0.01, 1.5)
			FPS:SetPrecision(2)
			FPS:SetScript('OnMouseUp', function(self, button, down)
				if button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["FPS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "FPS", "]] .. L["TAB"][tab.name]["FPS"] .. [[: "}, ]] .. TMW.db.profile.ActionDB[tab.name].FPS .. [[)]])	
				end					
			end)		
			FPS.Identify = { Type = "Slider", Toggle = "FPS" }		
			FPS.OnValueChanged = function(self, value)
				if value < 0 then 
					value = -0.01
				end 
				TMW.db.profile.ActionDB[tab.name].FPS = value
				FPS.FontStringTitle:SetText(L["TAB"][tab.name]["FPS"] .. ": |cff00ff00" .. (value < 0 and "AUTO" or (value .. L["TAB"][tab.name]["FPSSEC"])))
			end
			StdUi:FrameTooltip(FPS, L["TAB"][tab.name]["FPSTOOLTIP"], nil, "TOPRIGHT", true)	
			FPS.FontStringTitle = StdUi:FontString(anchor, L["TAB"][tab.name]["FPS"] .. ": |cff00ff00" .. (TMW.db.profile.ActionDB[tab.name].FPS < 0 and "AUTO" or (TMW.db.profile.ActionDB[tab.name].FPS .. L["TAB"][tab.name]["FPSSEC"])))
			StdUi:GlueAbove(FPS.FontStringTitle, FPS)					
			
			local Trinkets = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, {
				{ text = L["TAB"][tab.name]["TRINKET"] .. " 1", value = 1 },
				{ text = L["TAB"][tab.name]["TRINKET"] .. " 2", value = 2 },
			}, nil, true)
			Trinkets:SetPlaceholder(" -- " .. L["TAB"][tab.name]["TRINKETS"] .. " -- ") 
			for i = 1, #Trinkets.optsFrame.scrollChild.items do 
				Trinkets.optsFrame.scrollChild.items[i]:SetChecked(TMW.db.profile.ActionDB[tab.name].Trinkets[i])
			end 			
			Trinkets.OnValueChanged = function(self, value)			
				for i = 1, #self.optsFrame.scrollChild.items do 					
					if TMW.db.profile.ActionDB[tab.name].Trinkets[i] ~= self.optsFrame.scrollChild.items[i]:GetChecked() then
						TMW.db.profile.ActionDB[tab.name].Trinkets[i] = self.optsFrame.scrollChild.items[i]:GetChecked()
						Action.Print(L["TAB"][tab.name]["TRINKET"] .. " " .. i .. ": ", TMW.db.profile.ActionDB[tab.name].Trinkets[i])
					end 				
				end 				
			end				
			Trinkets:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Trinkets:SetScript('OnClick', function(self, button, down)
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["TRINKETS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Trinkets", "]] .. L["TAB"][tab.name]["TRINKET"] .. [[ "})]])	
					end
			end)		
			Trinkets.Identify = { Type = "Dropdown", Toggle = "Trinkets" }			
			Trinkets.FontStringTitle = StdUi:FontString(Trinkets, L["TAB"][tab.name]["TRINKETS"])
			StdUi:FrameTooltip(Trinkets, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Trinkets.FontStringTitle, Trinkets)
			Trinkets.text:SetJustifyH("CENTER")		

			local function GetProfileRole()
				local temp = {}
				tinsert(temp, { text = "AUTO", value = "AUTO" })
				
				local roles = Action.GetCurrentSpecializationRoles()
				local isUsed = {}
				if roles then 
					for role in pairs(roles) do 
						if not isUsed[role] then 
							tinsert(temp, { text = _G[role], value = role })
							isUsed[role] = true 
						end 
					end 
				end 
				
				return temp 				
			end 
			local Role = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, GetProfileRole())		          
			Role:SetValue(TMW.db.profile.ActionDB[tab.name].Role)
			Role.OnValueChanged = function(self, val)				
				TMW.db.profile.ActionDB[tab.name].Role = val 				
				if val ~= "AUTO" then 
					Action.Data.TG["Role"] = val
				end 
				Action:PLAYER_SPECIALIZATION_CHANGED()	
				TMW:Fire("TMW_ACTION_ROLE_CHANGED")
			end
			Role:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Role:SetScript('OnClick', function(self, button, down)
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][5]["ROLE"], [[/run Action.ToggleRole()]])	
					end
			end)		
			Role.Identify = { Type = "Dropdown", Toggle = "Role" }	
			StdUi:FrameTooltip(Role, L["TAB"][tab.name]["ROLETOOLTIP"], nil, "TOPLEFT", true)
			Role.FontStringTitle = StdUi:FontString(Role, L["TAB"][5]["ROLE"])
			StdUi:GlueAbove(Role.FontStringTitle, Role)	
			Role.text:SetJustifyH("CENTER")				
			TMW:RegisterCallback("TMW_ACTION_ROLE_CHANGED", function() 
				local textRole = TMW.db.profile.ActionDB[tab.name].Role 
				Role.text:SetText(Role:FindValueText(textRole))
			end) 
	
			local Burst = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, {
				{ text = "Everything", value = "Everything" },
				{ text = "Auto", value = "Auto" },				
				{ text = "Off", value = "Off" },
			})		          
			Burst:SetValue(TMW.db.profile.ActionDB[tab.name].Burst)
			Burst.OnValueChanged = function(self, val)                
				TMW.db.profile.ActionDB[tab.name].Burst = val 
				TMW:Fire("TMW_ACTION_BURST_CHANGED")
				TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 
				if val ~= "Off" then 
					Action.Data.TG["Burst"] = val
				end 
				Action.Print(L["TAB"][tab.name]["BURST"] .. ": ", TMW.db.profile.ActionDB[tab.name].Burst)
			end
			Burst:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Burst:SetScript('OnClick', function(self, button, down)
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["BURST"], [[/run Action.ToggleBurst()]])	
					end
			end)		
			Burst.Identify = { Type = "Dropdown", Toggle = "Burst" }	
			StdUi:FrameTooltip(Burst, L["TAB"][tab.name]["BURSTTOOLTIP"], nil, "TOPLEFT", true)
			Burst.FontStringTitle = StdUi:FontString(Burst, L["TAB"][tab.name]["BURST"])
			StdUi:GlueAbove(Burst.FontStringTitle, Burst)	
			Burst.text:SetJustifyH("CENTER")				

			HealthStone = StdUi:Slider(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, TMW.db.profile.ActionDB[tab.name].HealthStone, false, -1, 100)	
			HealthStone:SetScript('OnMouseUp', function(self, button, down)
					if button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEALTHSTONE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HealthStone", "]] .. L["TAB"][tab.name]["HEALTHSTONE"] .. [[: "}, ]] .. TMW.db.profile.ActionDB[tab.name].HealthStone .. [[)]])	
					end					
			end)		
			HealthStone.Identify = { Type = "Slider", Toggle = "HealthStone" }		
			HealthStone.OnValueChanged = function(self, value)
				local value = math_floor(value) 
				TMW.db.profile.ActionDB[tab.name].HealthStone = value
				self.FontStringTitle:SetText(L["TAB"][tab.name]["HEALTHSTONE"] .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value >= 100 and "|cff00ff00AUTO|r" or value))
			end
			StdUi:FrameTooltip(HealthStone, L["TAB"][tab.name]["HEALTHSTONETOOLTIP"], nil, "TOPLEFT", true)	
			HealthStone.FontStringTitle = StdUi:FontString(anchor, L["TAB"][tab.name]["HEALTHSTONE"] .. ": |cff00ff00" .. (TMW.db.profile.ActionDB[tab.name].HealthStone < 0 and "|cffff0000OFF|r" or TMW.db.profile.ActionDB[tab.name].HealthStone >= 100 and "|cff00ff00AUTO|r" or TMW.db.profile.ActionDB[tab.name].HealthStone))
			StdUi:GlueAbove(HealthStone.FontStringTitle, HealthStone)
			
			local AutoAttack = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AUTOATTACK"])			
			AutoAttack:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoAttack)
			AutoAttack:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoAttack:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].AutoAttack = not TMW.db.profile.ActionDB[tab.name].AutoAttack
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoAttack)	
					Action.Print(L["TAB"][tab.name]["AUTOATTACK"] .. ": ", TMW.db.profile.ActionDB[tab.name].AutoAttack)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["AUTOATTACK"], [[/run Action.SetToggle({]] .. tab.name .. [[, "AutoAttack", "]] .. L["TAB"][tab.name]["AUTOATTACK"] .. [[: "})]])	
				end 
			end)
			AutoAttack.Identify = { Type = "Checkbox", Toggle = "AutoAttack" }
			StdUi:FrameTooltip(AutoAttack, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			
			local AutoShoot = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AUTOSHOOT"])			
			AutoShoot:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoShoot)
			AutoShoot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoShoot:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].AutoShoot = not TMW.db.profile.ActionDB[tab.name].AutoShoot
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoShoot)	
						Action.Print(L["TAB"][tab.name]["AUTOSHOOT"] .. ": ", TMW.db.profile.ActionDB[tab.name].AutoShoot)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["AUTOSHOOT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "AutoShoot", "]] .. L["TAB"][tab.name]["AUTOSHOOT"] .. [[: "})]])	
					end 
				end
			end)
			AutoShoot.Identify = { Type = "Checkbox", Toggle = "AutoShoot" }
			StdUi:FrameTooltip(AutoShoot, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			local function AutoShootCheckBoxUpdate()
				if Action.PlayerClass ~= "WARRIOR" and Action.PlayerClass ~= "ROGUE" and Action.PlayerClass ~= "HUNTER" and not HasWandEquipped() then 
					if not AutoShoot.isDisabled then 
						AutoShoot:Disable()
					end 
				elseif AutoShoot.isDisabled then  
					AutoShoot:Enable()
				end 				
			end 
			AutoShoot:SetScript("OnShow", AutoShootCheckBoxUpdate) 
			AutoShoot:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
			AutoShoot:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_EQUIPMENT_CHANGED" then 
					AutoShootCheckBoxUpdate()
				end 
			end)
			AutoShootCheckBoxUpdate()

			local PauseChecksPanel = StdUi:PanelWithTitle(anchor, tab.frame:GetWidth() - 30, 425, L["TAB"][tab.name]["PAUSECHECKS"])
			StdUi:GlueTop(PauseChecksPanel.titlePanel, PauseChecksPanel, 0, -5)
			PauseChecksPanel.titlePanel.label:SetFontSize(14)
			StdUi:EasyLayout(PauseChecksPanel, { padding = { top = PauseChecksPanel.titlePanel.label:GetHeight() + 10 } })			
			
			local CheckDeadOrGhost = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DEADOFGHOSTPLAYER"])	
			CheckDeadOrGhost:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhost)
			function CheckDeadOrGhost:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhost = not TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhost		
				Action.Print(L["TAB"][tab.name]["DEADOFGHOSTPLAYER"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhost)
			end		
			CheckDeadOrGhost.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhost" }
			
			local CheckDeadOrGhostTarget = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DEADOFGHOSTTARGET"])
			CheckDeadOrGhostTarget:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhostTarget)
			function CheckDeadOrGhostTarget:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhostTarget = not TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhostTarget
				Action.Print(L["TAB"][tab.name]["DEADOFGHOSTTARGET"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckDeadOrGhostTarget)
			end	
			CheckDeadOrGhostTarget.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhostTarget" }
			StdUi:FrameTooltip(CheckDeadOrGhostTarget, L["TAB"][tab.name]["DEADOFGHOSTTARGETTOOLTIP"], nil, "BOTTOMLEFT", true)						

			local CheckCombat = StdUi:Checkbox(anchor, L["TAB"][tab.name]["COMBAT"])	
			CheckCombat:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckCombat)
			function CheckCombat:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckCombat = not TMW.db.profile.ActionDB[tab.name].CheckCombat	
				Action.Print(L["TAB"][tab.name]["COMBAT"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckCombat)
			end	
			CheckCombat.Identify = { Type = "Checkbox", Toggle = "CheckCombat" }
			StdUi:FrameTooltip(CheckCombat, L["TAB"][tab.name]["COMBATTOOLTIP"], nil, "BOTTOMRIGHT", true)		

			local CheckMount = StdUi:Checkbox(anchor, L["TAB"][tab.name]["MOUNT"])
			CheckMount:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckMount)
			function CheckMount:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckMount = not TMW.db.profile.ActionDB[tab.name].CheckMount
				Action.Print(L["TAB"][tab.name]["MOUNT"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckMount)
			end	
			CheckMount.Identify = { Type = "Checkbox", Toggle = "CheckMount" }			

			local CheckSpellIsTargeting = StdUi:Checkbox(anchor, L["TAB"][tab.name]["SPELLISTARGETING"])		
			CheckSpellIsTargeting:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckSpellIsTargeting)
			function CheckSpellIsTargeting:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckSpellIsTargeting = not TMW.db.profile.ActionDB[tab.name].CheckSpellIsTargeting
				Action.Print(L["TAB"][tab.name]["SPELLISTARGETING"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckSpellIsTargeting)
			end	
			CheckSpellIsTargeting.Identify = { Type = "Checkbox", Toggle = "CheckSpellIsTargeting" }
			StdUi:FrameTooltip(CheckSpellIsTargeting, L["TAB"][tab.name]["SPELLISTARGETINGTOOLTIP"], nil, "BOTTOMRIGHT", true)	

			local CheckLootFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOOTFRAME"])
			CheckLootFrame:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckLootFrame)
			function CheckLootFrame:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckLootFrame = not TMW.db.profile.ActionDB[tab.name].CheckLootFrame	
				Action.Print(L["TAB"][tab.name]["LOOTFRAME"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckLootFrame)
			end	
			CheckLootFrame.Identify = { Type = "Checkbox", Toggle = "CheckLootFrame" }	

			local CheckEatingOrDrinking = StdUi:Checkbox(anchor, L["TAB"][tab.name]["EATORDRINK"])
			CheckEatingOrDrinking:SetChecked(TMW.db.profile.ActionDB[tab.name].CheckEatingOrDrinking)
			function CheckEatingOrDrinking:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].CheckEatingOrDrinking = not TMW.db.profile.ActionDB[tab.name].CheckEatingOrDrinking	
				Action.Print(L["TAB"][tab.name]["EATORDRINK"] .. ": ", TMW.db.profile.ActionDB[tab.name].CheckEatingOrDrinking)
			end	
			CheckEatingOrDrinking.Identify = { Type = "Checkbox", Toggle = "CheckEatingOrDrinking" }	
			
			local Misc = StdUi:Header(PauseChecksPanel, L["TAB"][tab.name]["MISC"])
			Misc:SetAllPoints()			
			Misc:SetJustifyH('MIDDLE')
			Misc:SetFontSize(14)
			
			local DisableRotationDisplay = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEROTATIONDISPLAY"])
			DisableRotationDisplay:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableRotationDisplay)
			function DisableRotationDisplay:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisableRotationDisplay = not TMW.db.profile.ActionDB[tab.name].DisableRotationDisplay		
				Action.Print(L["TAB"][tab.name]["DISABLEROTATIONDISPLAY"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableRotationDisplay)
			end				
			DisableRotationDisplay.Identify = { Type = "Checkbox", Toggle = "DisableRotationDisplay" }
			StdUi:FrameTooltip(DisableRotationDisplay, L["TAB"][tab.name]["DISABLEROTATIONDISPLAYTOOLTIP"], nil, "BOTTOMRIGHT", true)	
			
			local DisableBlackBackground = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEBLACKBACKGROUND"])
			DisableBlackBackground:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableBlackBackground)
			function DisableBlackBackground:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisableBlackBackground = not TMW.db.profile.ActionDB[tab.name].DisableBlackBackground	
				Action.Print(L["TAB"][tab.name]["DISABLEBLACKBACKGROUND"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableBlackBackground)
				Action.BlackBackgroundSet(not TMW.db.profile.ActionDB[tab.name].DisableBlackBackground)
			end				
			DisableBlackBackground.Identify = { Type = "Checkbox", Toggle = "DisableBlackBackground" }
			StdUi:FrameTooltip(DisableBlackBackground, L["TAB"][tab.name]["DISABLEBLACKBACKGROUNDTOOLTIP"], nil, "BOTTOMLEFT", true)	

			local DisablePrint = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEPRINT"])
			DisablePrint:SetChecked(TMW.db.profile.ActionDB[tab.name].DisablePrint)
			function DisablePrint:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisablePrint = not TMW.db.profile.ActionDB[tab.name].DisablePrint		
				Action.Print(L["TAB"][tab.name]["DISABLEPRINT"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisablePrint, true)
			end				
			DisablePrint.Identify = { Type = "Checkbox", Toggle = "DisablePrint" }
			StdUi:FrameTooltip(DisablePrint, L["TAB"][tab.name]["DISABLEPRINTTOOLTIP"], nil, "BOTTOMRIGHT", true)

			local DisableMinimap = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEMINIMAP"])
			DisableMinimap:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableMinimap)
			function DisableMinimap:OnValueChanged(self, state, value)
				Action.ToggleMinimap()
			end				
			DisableMinimap.Identify = { Type = "Checkbox", Toggle = "DisableMinimap" }
			StdUi:FrameTooltip(DisableMinimap, L["TAB"][tab.name]["DISABLEMINIMAPTOOLTIP"], nil, "BOTTOMLEFT", true)	
						
			local DisableClassPortraits = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEPORTRAITS"])
			DisableClassPortraits:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableClassPortraits)
			function DisableClassPortraits:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisableClassPortraits = not TMW.db.profile.ActionDB[tab.name].DisableClassPortraits		
				Action.Print(L["TAB"][tab.name]["DISABLEPORTRAITS"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableClassPortraits)
			end				
			DisableClassPortraits.Identify = { Type = "Checkbox", Toggle = "DisableClassPortraits" }	

			local DisableRotationModes = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEROTATIONMODES"])
			DisableRotationModes:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableRotationModes)
			function DisableRotationModes:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisableRotationModes = not TMW.db.profile.ActionDB[tab.name].DisableRotationModes		
				Action.Print(L["TAB"][tab.name]["DISABLEROTATIONMODES"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableRotationModes)
			end				
			DisableRotationModes.Identify = { Type = "Checkbox", Toggle = "DisableRotationModes" }	
			
			local DisableSounds = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLESOUNDS"])
			DisableSounds:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableSounds)
			function DisableSounds:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].DisableSounds = not TMW.db.profile.ActionDB[tab.name].DisableSounds		
				Action.Print(L["TAB"][tab.name]["DISABLESOUNDS"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableSounds)
			end				
			DisableSounds.Identify = { Type = "Checkbox", Toggle = "DisableSounds" }
			
			local cameraDistanceMaxZoomFactor = StdUi:Checkbox(anchor, L["TAB"][tab.name]["CAMERAMAXFACTOR"])
			cameraDistanceMaxZoomFactor:SetChecked(TMW.db.profile.ActionDB[tab.name].cameraDistanceMaxZoomFactor)
			function cameraDistanceMaxZoomFactor:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].cameraDistanceMaxZoomFactor = not TMW.db.profile.ActionDB[tab.name].cameraDistanceMaxZoomFactor	
				
				local cameraDistanceMaxZoomFactor = GetCVar("cameraDistanceMaxZoomFactor")
				if TMW.db.profile.ActionDB[tab.name].cameraDistanceMaxZoomFactor then 					
					if cameraDistanceMaxZoomFactor ~= "4" then 
						SetCVar("cameraDistanceMaxZoomFactor", 4) 																	
					end	
				else 
					if cameraDistanceMaxZoomFactor ~= "2" then 
						SetCVar("cameraDistanceMaxZoomFactor", 2) 
					end						
				end 
				
				Action.Print(L["TAB"][tab.name]["CAMERAMAXFACTOR"] .. ": ", TMW.db.profile.ActionDB[tab.name].cameraDistanceMaxZoomFactor)
			end				
			cameraDistanceMaxZoomFactor.Identify = { Type = "Checkbox", Toggle = "cameraDistanceMaxZoomFactor" }		

			local Tools = StdUi:Header(PauseChecksPanel, L["TAB"][tab.name]["TOOLS"])
			Tools:SetAllPoints()			
			Tools:SetJustifyH('MIDDLE')
			Tools:SetFontSize(14)			
			
			local LetMeCast = StdUi:Checkbox(anchor, "LetMeCast")
			LetMeCast:SetChecked(TMW.db.profile.ActionDB[tab.name].LetMeCast)
			function LetMeCast:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].LetMeCast = not TMW.db.profile.ActionDB[tab.name].LetMeCast		
				LETMECAST:Initialize()
				Action.Print("LetMeCast: ", TMW.db.profile.ActionDB[tab.name].LetMeCast)
			end				
			LetMeCast.Identify = { Type = "Checkbox", Toggle = "LetMeCast" }	
			StdUi:FrameTooltip(LetMeCast, L["TAB"][tab.name]["LETMECASTTOOLTIP"], nil, "TOPRIGHT", true)
			
			local TargetCastBar = StdUi:Checkbox(anchor, L["TAB"][tab.name]["TARGETCASTBAR"])
			TargetCastBar:SetChecked(TMW.db.profile.ActionDB[tab.name].TargetCastBar)
			function TargetCastBar:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].TargetCastBar = not TMW.db.profile.ActionDB[tab.name].TargetCastBar						
				Action.Print(L["TAB"][tab.name]["TARGETCASTBAR"] .. ": ", TMW.db.profile.ActionDB[tab.name].TargetCastBar)
			end				
			TargetCastBar.Identify = { Type = "Checkbox", Toggle = "TargetCastBar" }	
			StdUi:FrameTooltip(TargetCastBar, L["TAB"][tab.name]["TARGETCASTBARTOOLTIP"], nil, "TOPLEFT", true)			
			
			local TargetRealHealth = StdUi:Checkbox(anchor, L["TAB"][tab.name]["TARGETREALHEALTH"])
			TargetRealHealth:SetChecked(TMW.db.profile.ActionDB[tab.name].TargetRealHealth)
			function TargetRealHealth:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].TargetRealHealth = not TMW.db.profile.ActionDB[tab.name].TargetRealHealth		
				UnitHealthTool:SetupStatusBarText()
				Action.Print(L["TAB"][tab.name]["TARGETREALHEALTH"] .. ": ", TMW.db.profile.ActionDB[tab.name].TargetRealHealth)
			end				
			TargetRealHealth.Identify = { Type = "Checkbox", Toggle = "TargetRealHealth" }	
			StdUi:FrameTooltip(TargetRealHealth, L["TAB"][tab.name]["TARGETREALHEALTHTOOLTIP"], nil, "TOPLEFT", true)	
			
			local TargetPercentHealth = StdUi:Checkbox(anchor, L["TAB"][tab.name]["TARGETPERCENTHEALTH"])
			TargetPercentHealth:SetChecked(TMW.db.profile.ActionDB[tab.name].TargetPercentHealth)
			function TargetPercentHealth:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].TargetPercentHealth = not TMW.db.profile.ActionDB[tab.name].TargetPercentHealth	
				UnitHealthTool:SetupStatusBarText()
				Action.Print(L["TAB"][tab.name]["TARGETPERCENTHEALTH"] .. ": ", TMW.db.profile.ActionDB[tab.name].TargetPercentHealth)
			end				
			TargetPercentHealth.Identify = { Type = "Checkbox", Toggle = "TargetPercentHealth" }	
			StdUi:FrameTooltip(TargetPercentHealth, L["TAB"][tab.name]["TARGETPERCENTHEALTHTOOLTIP"], nil, "TOPRIGHT", true)	
					
			local AuraCCPortrait = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AURACCPORTRAIT"])
			AuraCCPortrait:SetChecked(TMW.db.profile.ActionDB[tab.name].AuraCCPortrait)
			AuraCCPortrait:RegisterForClicks("LeftButtonUp")
			AuraCCPortrait:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					TMW.db.profile.ActionDB[tab.name].AuraCCPortrait = not TMW.db.profile.ActionDB[tab.name].AuraCCPortrait		
					if TMW.db.profile.ActionDB[tab.name].AuraCCPortrait then 
						AuraDuration:TurnOnPortrait()
					else 
						AuraDuration:TurnOffPortrait()
					end 
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].AuraCCPortrait)
					Action.Print(L["TAB"][tab.name]["AURACCPORTRAIT"] .. ": ", TMW.db.profile.ActionDB[tab.name].AuraCCPortrait)
				end 
			end)				
			AuraCCPortrait.Identify = { Type = "Checkbox", Toggle = "AuraCCPortrait" }	
			StdUi:FrameTooltip(AuraCCPortrait, L["TAB"][tab.name]["AURACCPORTRAITTOOLTIP"], nil, "TOPRIGHT", true)
			if not Action.GetToggle(1, "AuraDuration") then 
				AuraCCPortrait:Disable()
			end 
			
			local AuraDurationCheckbox = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AURADURATION"])
			AuraDurationCheckbox:SetChecked(TMW.db.profile.ActionDB[tab.name].AuraDuration)
			function AuraDurationCheckbox:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].AuraDuration = not TMW.db.profile.ActionDB[tab.name].AuraDuration	
				AuraDuration:Initialize()
				if TMW.db.profile.ActionDB[tab.name].AuraDuration then 
					AuraCCPortrait:Enable()
				else 
					AuraCCPortrait:Disable()
				end 
				Action.Print(L["TAB"][tab.name]["AURADURATION"] .. ": ", TMW.db.profile.ActionDB[tab.name].AuraDuration)
			end				
			AuraDurationCheckbox.Identify = { Type = "Checkbox", Toggle = "AuraDuration" }	
			StdUi:FrameTooltip(AuraDurationCheckbox, L["TAB"][tab.name]["AURADURATIONTOOLTIP"], nil, "TOPLEFT", true)		

			local LossOfControlPlayerFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOSSOFCONTROLPLAYERFRAME"])
			LossOfControlPlayerFrame:SetChecked(TMW.db.profile.ActionDB[tab.name].LossOfControlPlayerFrame)
			function LossOfControlPlayerFrame:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].LossOfControlPlayerFrame = not TMW.db.profile.ActionDB[tab.name].LossOfControlPlayerFrame	
				Action.LossOfControl:UpdateFrameData()				
				Action.Print(L["TAB"][tab.name]["LOSSOFCONTROLPLAYERFRAME"] .. ": ", TMW.db.profile.ActionDB[tab.name].LossOfControlPlayerFrame)
			end				
			LossOfControlPlayerFrame.Identify = { Type = "Checkbox", Toggle = "LossOfControlPlayerFrame" }	
			StdUi:FrameTooltip(LossOfControlPlayerFrame, L["TAB"][tab.name]["LOSSOFCONTROLPLAYERFRAMETOOLTIP"], nil, "TOPRIGHT", true)	

			local LossOfControlRotationFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOSSOFCONTROLROTATIONFRAME"])
			LossOfControlRotationFrame:SetChecked(TMW.db.profile.ActionDB[tab.name].LossOfControlRotationFrame)
			function LossOfControlRotationFrame:OnValueChanged(self, state, value)
				TMW.db.profile.ActionDB[tab.name].LossOfControlRotationFrame = not TMW.db.profile.ActionDB[tab.name].LossOfControlRotationFrame	
				Action.LossOfControl:UpdateFrameData()				
				Action.Print(L["TAB"][tab.name]["LOSSOFCONTROLROTATIONFRAME"] .. ": ", TMW.db.profile.ActionDB[tab.name].LossOfControlRotationFrame)
			end				
			LossOfControlRotationFrame.Identify = { Type = "Checkbox", Toggle = "LossOfControlRotationFrame" }	
			StdUi:FrameTooltip(LossOfControlRotationFrame, L["TAB"][tab.name]["LOSSOFCONTROLROTATIONFRAMETOOLTIP"], nil, "TOPLEFT", true)		
			
			local LossOfControlTypes = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), Action.Data.theme.dd.height, {
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL0_CAP, value = 1 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL1_CAP, value = 2 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL2_CAP, value = 3 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL3_CAP, value = 4 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL4_CAP, value = 5 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL5_CAP, value = 6 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INTERRUPT"] .. " " .. SPELL_SCHOOL6_CAP, value = 7 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_BANISH"], 			value = 8 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_CHARM"],		 	value = 9 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_CYCLONE"], 		value = 10 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_DAZE"], 			value = 11 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_DISARM"], 			value = 12 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_DISORIENT"], 		value = 13 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_FREEZE"], 			value = 14 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_HORROR"],	 		value = 15 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_INCAPACITATE"], 	value = 16 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_PACIFY"], 			value = 17 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_PACIFYSILENCE"], 	value = 18 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_POLYMORPH"], 		value = 19 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_POSSESS"], 		value = 20 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_SAP"], 			value = 21 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_SHACKLE_UNDEAD"], 	value = 22 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_SLEEP"], 			value = 23 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_SNARE"], 			value = 24 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_TURN_UNDEAD"], 	value = 25 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_ROOT"], 			value = 26 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_CONFUSE"], 		value = 27 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_STUN"], 			value = 28 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_SILENCE"], 		value = 29 },
				{ text = _G["LOSS_OF_CONTROL_DISPLAY_FEAR"], 			value = 30 },
			}, nil, true)
			LossOfControlTypes:SetPlaceholder(" -- " .. L["NO"] .. " -- ") 
			for i = 1, #LossOfControlTypes.optsFrame.scrollChild.items do 
				LossOfControlTypes.optsFrame.scrollChild.items[i]:SetChecked(TMW.db.profile.ActionDB[tab.name].LossOfControlTypes[i])
			end 			
			LossOfControlTypes.OnValueChanged = function(self, value)			
				for i = 1, #self.optsFrame.scrollChild.items do 					
					if TMW.db.profile.ActionDB[tab.name].LossOfControlTypes[i] ~= self.optsFrame.scrollChild.items[i]:GetChecked() then
						TMW.db.profile.ActionDB[tab.name].LossOfControlTypes[i] = self.optsFrame.scrollChild.items[i]:GetChecked()
						Action.Print(L["TAB"][tab.name]["LOSSOFCONTROLTYPES"] .. " " .. self:FindValueText(i) .. ": ", TMW.db.profile.ActionDB[tab.name].LossOfControlTypes[i])
					end 				
				end 	
				Action.LossOfControl:UpdateFrameData()	
			end				
			LossOfControlTypes:RegisterForClicks("LeftButtonUp")
			LossOfControlTypes:SetScript('OnClick', function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				end
			end)		
			LossOfControlTypes.Identify = { Type = "Dropdown", Toggle = "LossOfControlTypes" }			
			LossOfControlTypes.FontStringTitle = StdUi:FontString(LossOfControlTypes, L["TAB"][tab.name]["LOSSOFCONTROLTYPES"])
			StdUi:GlueAbove(LossOfControlTypes.FontStringTitle, LossOfControlTypes)
			LossOfControlTypes.text:SetJustifyH("CENTER")
			
			local GlobalOverlay = anchor:AddRow()					
			GlobalOverlay:AddElement(PvEPvPToggle, { column = 5.5 })			
			GlobalOverlay:AddElement(PvEPvPresetbutton, { column = 0 })			
			GlobalOverlay:AddElement(LayoutSpace(anchor), { column = 0.5})
			GlobalOverlay:AddElement(anchor.InterfaceLanguage, { column = 6 })			
			anchor:AddRow({ margin = { top = 10 } }):AddElements(ReTarget, Trinkets, { column = "even" })			
			anchor:AddRow():AddElements(Role, Burst, { column = "even" })			
			local SpecialRow = anchor:AddRow()
			SpecialRow:AddElement(FPS, { column = 5.8 })
			SpecialRow:AddElement(LayoutSpace(anchor), { column = 0.2 })
			SpecialRow:AddElement(HealthStone, { column = 6 })
			anchor:AddRow({ margin = { top = 10 } }):AddElements(AutoTarget, LosSystem, { column = "even" })
			anchor:AddRow({ margin = { top = -10 } }):AddElements(Potion, DBMFrame, { column = "even" })			
			anchor:AddRow({ margin = { top = -10 } }):AddElements(Racial, HE_PetsFrame, { column = "even" })
			anchor:AddRow({ margin = { top = -10 } }):AddElements(StopCast, HE_AnyRole, { column = "even" })	
			anchor:AddRow({ margin = { top = -10 } }):AddElements(AutoAttack, HE_ToggleFrame, { column = "even" })
			anchor:AddRow({ margin = { top = -10 } }):AddElements(AutoShoot, StopAtBreakAble, { column = "even" })
			anchor:AddRow():AddElement(PauseChecksPanel)		
			PauseChecksPanel:AddRow({ margin = { top = 10 } }):AddElements(CheckSpellIsTargeting, CheckLootFrame, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckEatingOrDrinking, CheckDeadOrGhost, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckMount, CheckDeadOrGhostTarget, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckCombat, LayoutSpace(anchor), { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -15 } }):AddElement(Misc)		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableRotationDisplay, DisableBlackBackground, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisablePrint, DisableMinimap, { column = "even" })			
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableClassPortraits, DisableRotationModes, { column = "even" })		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableSounds, cameraDistanceMaxZoomFactor, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -5 } }):AddElement(Tools)
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(LetMeCast, TargetCastBar, { column = "even" })
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(TargetPercentHealth, TargetRealHealth, { column = "even" })
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(AuraCCPortrait, AuraDurationCheckbox, { column = "even" })
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(LossOfControlPlayerFrame, LossOfControlRotationFrame, { column = "even" })
			PauseChecksPanel:AddRow({ margin = { top = 5 } }):AddElement(LossOfControlTypes)
			PauseChecksPanel:DoLayout()		
			-- Add empty space for scrollframe after all elements 
			--anchor:AddRow():AddElement(LayoutSpace(anchor), { column = 12 })	
			anchor:AddRow():AddElement(LayoutSpace(anchor), { column = 12, margin = { top = 10 } })	
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			
		
			anchor:DoLayout()
		end 
		
		if tab.name == 2 then 	
            UI_Title:SetText(Action.PlayerClassName)			
			tab.title = Action.PlayerClassName
			tabFrame:DrawButtons()	
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget
			StdUi:InitWidget(anchor)
			
			if not Action.Data.ProfileUI or not Action.Data.ProfileUI[tab.name] or not next(Action.Data.ProfileUI[tab.name]) then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 				

			local options = Action.Data.ProfileUI[tab.name].LayoutOptions
			if options then 
				if not options.padding then 
					options.padding = {}
				end 
				
				if not options.padding.top then 
					options.padding.top = 40 
				end 	

				-- Cut out scrollbar 
				if not options.padding.right then 
					options.padding.right = 10 + 20
				elseif options.padding.right < 20 then 
					options.padding.right = options.padding.right + 20
				end 
			end 			
			
			StdUi:EasyLayout(anchor, options or { padding = { top = 40, right = 10 + 20 } })			
			for row = 1, #Action.Data.ProfileUI[tab.name] do 
				local SpecRow = anchor:AddRow(Action.Data.ProfileUI[tab.name][row].RowOptions)	
				for element = 1, #Action.Data.ProfileUI[tab.name][row] do 
					local config = Action.Data.ProfileUI[tab.name][row][element]	
					local CL = (config.L and (TMW.db and TMW.db.global.ActionDB and TMW.db.global.ActionDB.InterfaceLanguage ~= "Auto" and config.L[TMW.db.global.ActionDB.InterfaceLanguage] and TMW.db.global.ActionDB.InterfaceLanguage or config.L[GameLocale] and GameLocale)) or "enUS"
					local CTT = (config.TT and (TMW.db and TMW.db.global.ActionDB and TMW.db.global.ActionDB.InterfaceLanguage ~= "Auto" and config.TT[TMW.db.global.ActionDB.InterfaceLanguage] and TMW.db.global.ActionDB.InterfaceLanguage or config.TT[GameLocale] and GameLocale)) or "enUS"
					local obj					
					if config.E == "Label" then 
						obj = StdUi:Label(anchor, config.L.ANY or config.L[CL], config.S or 14)
					elseif config.E == "Header" then 
						obj = StdUi:Header(anchor, config.L.ANY or config.L[CL])
						obj:SetAllPoints()			
						obj:SetJustifyH("MIDDLE")						
						obj:SetFontSize(config.S or 14)	
					elseif config.E == "Button" then 
						obj = StdUi:Button(anchor, GetWidthByColumn(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][row])), config.H or 20, config.L.ANY or config.L[CL])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)
							if not self.isDisabled then 
								config.OnClick(self, button, down) 
							end 
						end)
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						--obj.FontStringTitle = StdUi:FontString(obj, config.L.ANY or config.L[CL])
						--StdUi:GlueAbove(obj.FontStringTitle, obj)
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Checkbox" then 						
						obj = StdUi:Checkbox(anchor, config.L.ANY or config.L[CL], 35)
						obj:SetChecked(TMW.db.profile.ActionDB[tab.name][config.DB])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)	
							if not self.isDisabled then 	
								if button == "LeftButton" then 
									TMW.db.profile.ActionDB[tab.name][config.DB] = not TMW.db.profile.ActionDB[tab.name][config.DB]
									self:SetChecked(TMW.db.profile.ActionDB[tab.name][config.DB])	
									if strlowerCache[self.Identify.Toggle] == "aoe" then 
										TMW:Fire("TMW_ACTION_AOE_CHANGED")
										TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED") -- Taste's callback 
									end 
									Action.Print((config.L.ANY or config.L[CL]) .. ": ", TMW.db.profile.ActionDB[tab.name][config.DB])	
								elseif button == "RightButton" and config.M then 
									CraftMacro( config.L.ANY or config.L[CL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tab.name) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. (config.M.Value or "nil") .. [[)]]), 1 )	
								end 
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Dropdown" then
						obj = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][row])), config.H or 20, config.OT, nil, config.MULT)
						if config.SetPlaceholder then 
							obj:SetPlaceholder(config.SetPlaceholder.ANY or config.SetPlaceholder[CL])
						end 
						if config.MULT then 
							for i = 1, #obj.optsFrame.scrollChild.items do 
								obj.optsFrame.scrollChild.items[i]:SetChecked(TMW.db.profile.ActionDB[tab.name][config.DB][i])
							end
							obj.OnValueChanged = function(self, value)			
								for i = 1, #self.optsFrame.scrollChild.items do 					
									if TMW.db.profile.ActionDB[tab.name][config.DB][i] ~= self.optsFrame.scrollChild.items[i]:GetChecked() then
										TMW.db.profile.ActionDB[tab.name][config.DB][i] = self.optsFrame.scrollChild.items[i]:GetChecked()
										Action.Print((config.L.ANY or config.L[CL]) .. " " .. i .. ": ", TMW.db.profile.ActionDB[tab.name][config.DB][i])
									end 				
								end 				
							end
						else 
							obj:SetValue(TMW.db.profile.ActionDB[tab.name][config.DB])
							obj.OnValueChanged = function(self, val)                
								TMW.db.profile.ActionDB[tab.name][config.DB] = val 
								if (config.isNotEqualVal and val ~= config.isNotEqualVal) or (config.isNotEqualVal == nil and val ~= "Off" and val ~= "OFF" and val ~= 0) then 
									Action.Data.TG[config.DB] = val
								end 
								Action.Print((config.L.ANY or config.L[CL]) .. ": ", TMW.db.profile.ActionDB[tab.name][config.DB])
							end
						end 
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)
							if not self.isDisabled then 
								if button == "LeftButton" then 
									self:ToggleOptions()
								elseif button == "RightButton" and config.M then 
									CraftMacro( config.L.ANY or config.L[CL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tab.name) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. (config.M.Value or (not config.MULT and obj:GetValue() and ([["]] .. obj:GetValue() .. [["]])) or "nil") .. [[)]]), 1 )								
								end
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						obj.FontStringTitle = StdUi:FontString(obj, config.L.ANY or config.L[CL])
						obj.text:SetJustifyH("CENTER")
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)	
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Slider" then	
						obj = StdUi:Slider(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][row]), config.H or 20, TMW.db.profile.ActionDB[tab.name][config.DB], false, config.MIN or -1, config.MAX or 100)	
						if config.Precision then 
							obj:SetPrecision(config.Precision)
						end
						if config.M then 
							obj:SetScript("OnMouseUp", function(self, button, down)
									if button == "RightButton" then 
										CraftMacro( config.L.ANY or config.L[CL], [[/run Action.SetToggle({]] .. tab.name .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. TMW.db.profile.ActionDB[tab.name][config.DB] .. [[)]], 1 )	
									end					
							end)
						end 
						local function ONOFF(value)
							if config.ONLYON then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value >= config.MAX and "|cff00ff00AUTO|r" or value)
							elseif config.ONLYOFF then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value)
							elseif config.ONOFF then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value >= config.MAX and "|cff00ff00AUTO|r" or value)
							else
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. value .. "|r"
							end 
						end 
						obj.OnValueChanged = function(self, value)
							if not config.Precision then 
								value = math_floor(value) 
							elseif value < 0 then 
								value = config.MIN or -1
							end
							TMW.db.profile.ActionDB[tab.name][config.DB] = value
							self.FontStringTitle:SetText(ONOFF(value))
						end
						obj.Identify = { Type = config.E, Toggle = config.DB }						
						obj.FontStringTitle = StdUi:FontString(obj, ONOFF(TMW.db.profile.ActionDB[tab.name][config.DB]))
						obj.FontStringTitle:SetJustifyH("CENTER")						
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)						
					elseif config.E == "LayoutSpace" then	
						obj = LayoutSpace(anchor)
					end 
					
					local margin = config.ElementOptions and config.ElementOptions.margin or { top = 10 } 					
					SpecRow:AddElement(obj, { column = math_floor(12 / #Action.Data.ProfileUI[tab.name][row]), margin = margin })
				end
			end
			
			-- Add some empty space after all elements 
			if #Action.Data.ProfileUI[tab.name] > 12 then 
				for row = 1, 2 do 
					local SpecRow = anchor:AddRow()		
					local obj = LayoutSpace(anchor)
					SpecRow:AddElement(obj, { column = 12, margin = { top = 10 } })
				end 
			end 
			
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			

			anchor:DoLayout()	
		end 
		
		if tab.name == 3 then 
			if not Action[Action.PlayerClass] then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 50 } })	
			local QLuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height - 3, "QLUA")
			QLuaButton.FontStringLUA = StdUi:FontString(QLuaButton, Action.Data.theme.off)
			local QLuaEditor = CreateLuaEditor(tab.childs[spec], "QUEUE " .. L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height - 3, "LUA")
			LuaButton.FontStringLUA = StdUi:FontString(LuaButton, Action.Data.theme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Key = StdUi:SimpleEditBox(tab.childs[spec], 50, Action.Data.theme.dd.height, "")							
						
			local hasdata = {}			
			local function OnPairs(k, v, ToggleAutoHidden)
				if type(v) == "table" and not v.Hidden and v.Type and v.ID and v.Desc then 
					local Enabled = "True"
					if v:IsBlocked() then 
						Enabled = "False"
					end 
					
					local isShown = true 
					-- AutoHidden unavailable 
					if ToggleAutoHidden and v.ID ~= ACTION_CONST_PICKPOCKET then 								
						if v.Type == "SwapEquip" then 
							if not v:IsExists() then 
								isShown = false 
							end 
						elseif v.Type == "Spell" then 															
							if not v:IsExists() or v:IsBlockedBySpellBook() then 
								isShown = false 
							end 
						else 
							if v.Type == "Trinket" then 
								if not v:GetEquipped() then 
									isShown = false 
								end 
							else 
								if v:GetCount() <= 0 or not v:GetEquipped() then 
									isShown = false 
								end 
							end								
						end 
					end 
					
					if isShown then 
						table.insert(hasdata, setmetatable({ 
							Enabled = Enabled, 				
							Name = v:Info(),
							Icon = v:Icon(),
							TableKeyName = k,
						}, { __index = Action[Action.PlayerClass][k] or Action }))
					end 
				end			
			end 			
			local function ScrollTableActionsData()
				wipe(hasdata)
				local ToggleAutoHidden = Action.GetToggle(tab.name, "AutoHidden")
				if Action[Action.PlayerClass] then 					
					for k, v in pairs(Action[Action.PlayerClass]) do 
						OnPairs(k, v, ToggleAutoHidden)
					end
				end 
				for k, v in pairs(Action) do 
					OnPairs(k, v, ToggleAutoHidden)
				end
				return hasdata
			end
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					local luaCode = rowData:GetLUA() or ""
					LuaEditor.EditBox:SetText(luaCode)
					if luaCode and luaCode ~= "" then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 
					
					local QluaCode = rowData:GetQLUA() or ""
					QLuaEditor.EditBox:SetText(QluaCode)
					if QluaCode and QluaCode ~= "" then 
						QLuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						QLuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 					
					
					Key:SetText(rowData.TableKeyName)
					Key:ClearFocus()
					
					if columnData.index == "Enabled" then
						rowData:SetBlocker()
						tab.childs[spec].ScrollTable:ClearSelection()
					end 
				end 				
			end 
						
			tab.childs[spec].ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
                {
                    name = L["TAB"][tab.name]["ENABLED"],
                    width = 70,
                    align = "LEFT",
                    index = "Enabled",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "True" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "False" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = "ID",
                    width = 70,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 197,
					defaultwidth = 197,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["DESC"],
                    width = 90,
                    align = "LEFT",
                    index = "Desc",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)    							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)   							
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 16, 25)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						tab.childs[spec].ScrollTable.SORTBY = columnIndex
						Key:ClearFocus()	
					end	
				end, 
			}
			tab.childs[spec].ScrollTable:RegisterEvents(nil, headerEvents)
			tab.childs[spec].ScrollTable.SORTBY = 3
			tab.childs[spec].ScrollTable.defaultrows = { numberOfRows = tab.childs[spec].ScrollTable.numberOfRows, rowHeight = tab.childs[spec].ScrollTable.rowHeight }
            tab.childs[spec].ScrollTable:EnableSelection(true)  
			tab.childs[spec].ScrollTable:SetScript("OnShow", function(self)			
				self:SetData(ScrollTableActionsData())	
				self:SortData(self.SORTBY)
				
				local index = self:GetSelection()
				if not index then 
					Key:SetText("")
					Key:ClearFocus() 
				else 
					local data = self:GetRow(index)
					if data then 
						if data.TableKeyName ~= Key:GetText() then 
							Key:SetText(data.TableKeyName)
						end 
					else 
						Key:SetText("")
						Key:ClearFocus() 
					end 
				end 
			end)
			-- Register callback to refresh table by earned ranks 
			TMW:RegisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", function()
				if tab.childs[spec].ScrollTable:IsVisible() and Action.GetToggle(tab.name, "AutoHidden") then 
					tab.childs[spec].ScrollTable:SetData(ScrollTableActionsData())	
					tab.childs[spec].ScrollTable:SortData(tab.childs[spec].ScrollTable.SORTBY)					
				end 
			end)
			-- AutoHidden update ScrollTable events 
			local EVENTS = {
				["UNIT_PET"] 						= true,
				["PLAYER_LEVEL_UP"]					= true,
				["CHARACTER_POINTS_CHANGED"]		= true,
				["CONFIRM_TALENT_WIPE"]				= true,
				["BAG_UPDATE_DELAYED"]				= true,
				["PLAYER_EQUIPMENT_CHANGED"]		= true,
				["LEARNED_SPELL_IN_TAB"]			= true, 
			}
			local function EVENTS_INIT() 
				if Action.GetToggle(tab.name, "AutoHidden") then 
					for k in pairs(EVENTS) do 
						tab.childs[spec].ScrollTable:RegisterEvent(k)
					end 
				else 
					for k in pairs(EVENTS) do 
						tab.childs[spec].ScrollTable:UnregisterEvent(k)
					end 
				end 
			end 	
			EVENTS_INIT() 
			tab.childs[spec].ScrollTable.ts = 0
			tab.childs[spec].ScrollTable:SetScript("OnEvent", function(self, event, ...)
				if self:IsVisible() and TMW.time ~= self.ts and Action.GetToggle(tab.name, "AutoHidden") and EVENTS[event] then 
					self.ts = TMW.time 
					-- Update ScrollTable if pet gone or summoned or swaped
					if event == "UNIT_PET" then 
						if ... == "player" then 						
							self:SetData(ScrollTableActionsData())	
							self:SortData(self.SORTBY)
						end 
					else 		
						self:SetData(ScrollTableActionsData())	
						self:SortData(self.SORTBY)
					end 
					
					local index = self:GetSelection()
					if not index then 
						Key:SetText("")
						Key:ClearFocus() 
					else 
						local data = self:GetRow(index)
						if data then 
							if data.TableKeyName ~= Key:GetText() then 
								Key:SetText(data.TableKeyName)
							end 
						else 
							Key:SetText("")
							Key:ClearFocus() 
						end 
					end 
				end 
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then
				tab.childs[spec].ScrollTable:SetData(ScrollTableActionsData())
				tab.childs[spec].ScrollTable:SortData(tab.childs[spec].ScrollTable.SORTBY)				
				--tab.childs[spec].ScrollTable:SetScript("OnShow", nil)
			end 
					
			Key:SetJustifyH("CENTER")
			Key.FontString = StdUi:FontString(Key, L["TAB"]["KEY"]) 
			Key:SetScript("OnTextChanged", function(self)
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					return
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)						
					if data and data.TableKeyName ~= self:GetText() then 
						self:SetText(data.TableKeyName)
					end 
				end 
            end)
			Key:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)	
			StdUi:GlueAbove(Key.FontString, Key)		
			StdUi:FrameTooltip(Key, L["TAB"][tab.name]["KEYTOOLTIP"], nil, "TOP", true)			
			
			local AutoHidden = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["AUTOHIDDEN"])		
			AutoHidden:SetChecked(TMW.db.profile.ActionDB[tab.name].AutoHidden)
			AutoHidden:RegisterForClicks("LeftButtonUp")
			AutoHidden:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 				
						local fixedspec = Action.PlayerClass .. CL
						Action.SetToggle({tab.name, "AutoHidden", L["TAB"][tab.name]["AUTOHIDDEN"] .. ": "})
						tab.childs[fixedspec].ScrollTable:SetData(ScrollTableActionsData())	
						tab.childs[fixedspec].ScrollTable:SortData(tab.childs[fixedspec].ScrollTable.SORTBY)	
						EVENTS_INIT()
						
						local index = tab.childs[fixedspec].ScrollTable:GetSelection()
						if not index then 
							Key:SetText("")
							Key:ClearFocus() 
						else 
							local data = tab.childs[fixedspec].ScrollTable:GetRow(index)
							if data then 
								if data.TableKeyName ~= Key:GetText() then 
									Key:SetText(data.TableKeyName)
								end 
							else 
								Key:SetText("")
								Key:ClearFocus() 
							end 
						end 						
					end 
				end 
			end)
			AutoHidden.Identify = { Type = "Checkbox", Toggle = "AutoHidden" }
			StdUi:FrameTooltip(AutoHidden, L["TAB"][tab.name]["AUTOHIDDENTOOLTIP"], nil, "TOP", true)		
			
			local SetBlocker = StdUi:Button(tab.childs[spec], tab.childs[spec]:GetWidth() / 2 - 22, 30, L["TAB"][tab.name]["SETBLOCKER"])
			SetBlocker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetBlocker:SetScript("OnClick", function(self, button, down)
				local spec = Action.PlayerClass .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)
					if button == "LeftButton" then 
						data:SetBlocker()						
					elseif button == "RightButton" then 						
						CraftMacro("Block: " .. data.TableKeyName, [[#showtip ]] .. data:Info() .. "\n" .. [[/run Action.MacroBlocker("]] .. data.TableKeyName .. [[")]], 1, true, true)	
					end
				end 
			end)			         
            StdUi:FrameTooltip(SetBlocker, L["TAB"][tab.name]["SETBLOCKERTOOLTIP"], nil, "TOPRIGHT", true)
			
			local SetQueue = StdUi:Button(tab.childs[spec], tab.childs[spec]:GetWidth() / 2 - 22, 30, L["TAB"][tab.name]["SETQUEUE"])
			SetQueue:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetQueue:SetScript("OnClick", function(self, button, down)
				local spec = Action.PlayerClass .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)
					if data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not GetItemSpell(data.ID)) then 
						Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"])
					-- I decided unlocked Queue for blocked actions
					--elseif data:IsBlocked() and not data.Queued then 
						--Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"])
					else
						if button == "LeftButton" then 	
							Action.MacroQueue(data.TableKeyName, { Priority = 1 })							
						elseif button == "RightButton" then 						
							CraftMacro("Queue: " .. data.TableKeyName, [[#showtip ]] .. data:Info() .. "\n" .. [[/run Action.MacroQueue("]] .. data.TableKeyName .. [[", { Priority = 1 })]], 1, true, true)	
						end
					end 
				end 
			end)			         
            StdUi:FrameTooltip(SetQueue, L["TAB"][tab.name]["SETQUEUETOOLTIP"], nil, "TOPLEFT", true)		
			
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(tab.childs[spec].ScrollTable)
			tab.childs[spec]:AddRow({ margin = { left = -15, right = 70 } }):AddElement(Key)
			tab.childs[spec]:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(AutoHidden)
			tab.childs[spec]:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElements(SetBlocker, SetQueue, { column = "even" })
			tab.childs[spec]:DoLayout()
			
			-- Action LUA 
			LuaButton:SetScript("OnClick", function()		
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
					return 
				end 
				
				if not LuaEditor:IsShown() then 
					local spec = Action.PlayerClass .. CL
					local index = tab.childs[spec].ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
					else 				
						LuaEditor:Show()
					end 
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(LuaButton, SetQueue, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, 0, 0)

			LuaEditor:HookScript("OnHide", function(self)
				local spec = Action.PlayerClass .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()
				local data = index and tab.childs[spec].ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = GetTableKeyIdentify(data)
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetLUA() ~= luaCode
					
					data:SetLUA(luaCode)
					if data:GetLUA() then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
						if isChanged then 
							Action.Print(L["TAB"][tab.name]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)	
						if isChanged then 
							Action.Print(L["TAB"][tab.name]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)
			
			-- Queue LUA
			QLuaButton:SetScript("OnClick", function()		
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
					return 
				end 
				
				if not QLuaEditor:IsShown() then 
					local spec = Action.PlayerClass .. CL
					local index = tab.childs[spec].ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
					else 			
						local data = tab.childs[spec].ScrollTable:GetRow(index)
						if not data:GetQLUA() and (data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not GetItemSpell(data.ID))) then 
							Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. " " .. L["TAB"][3]["KEY"] .. data.TableKeyName .. "]")
						else 
							QLuaEditor:Show()
						end 
					end 
				else 
					QLuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(QLuaButton, LuaButton, 0, 0)
			StdUi:GlueLeft(QLuaButton.FontStringLUA, QLuaButton, 0, 0)

			QLuaEditor:HookScript("OnHide", function(self)
				local spec = Action.PlayerClass .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()
				local data = index and tab.childs[spec].ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = GetTableKeyIdentify(data)
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetQLUA() ~= luaCode
					
					data:SetQLUA(luaCode)
					if data:GetQLUA() then 
						QLuaButton.FontStringLUA:SetText(Action.Data.theme.on)
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tab.name]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						QLuaButton.FontStringLUA:SetText(Action.Data.theme.off)	
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tab.name]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)			
			
			hooksecurefunc(tab.childs[spec].ScrollTable, "ClearSelection", function()				
				LuaEditor.EditBox:SetText("")
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
				end 
				
				QLuaEditor.EditBox:SetText("")
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
				end 				
			end)
		end 
		
		if tab.name == 4 then					
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])			

			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 50 } })
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 145, L["TAB"][tab.name]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local KickHealOnlyHealers = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKHEALONLYHEALER"])
			local KickPvPOnlySmart = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKPVPONLYSMART"]) 
			local KickHeal = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKHEAL"])
			local KickPvP = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKPVP"])			
			local KickTargetMouseover = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKTARGETMOUSEOVER"])
			local useKick = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEKICK"])
			local useCC = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USECC"])
			local useRacial = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USERACIAL"])
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["SEARCH"])
			local How = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], value = "GLOBAL" },				
				{ text = L["TAB"]["ALLSPECS"], value = "ALLSPECS" },
			}, "ALLSPECS")
			local TargetMouseoverList = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["TARGETMOUSEOVERLIST"])
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, Action.Data.theme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:FontString(LuaButton, Action.Data.theme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Add = StdUi:Button(tab.childs[spec], InputBox:GetWidth(), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], InputBox:GetWidth(), 25, L["TAB"][tab.name]["REMOVE"])					
			local InterruptUnits = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), Action.Data.theme.dd.height, {
				{ text = "BlackList", value = "BlackList" },
				{ text = "[Main]PvE: @target / @mouseover / @targettarget", value = "PvETargetMouseover" },
				{ text = "[Main]PvP: @target / @mouseover / @targettarget", value = "PvPTargetMouseover" },				
				{ text = "[Heal] @arena1-3", value = "Heal" },				
				{ text = "[PvP] @arena1-3", value = "PvP" },
			}, (Action.IsInPvP and "PvP" or "PvE") .. "TargetMouseover")	
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 
					InputBox:SetNumber(rowData.ID)
					InputBox.val = rowData.ID 
					InputBox:ClearFocus()					
					useKick:SetChecked(		(columnData.index == "useKickIndex" 	and not rowData.useKick) 	or (columnData.index ~= "useKickIndex" 		and rowData.useKick)	)
					useCC:SetChecked(		(columnData.index == "useCCIndex" 		and not rowData.useCC) 		or (columnData.index ~= "useCCIndex" 		and rowData.useCC)		)
					useRacial:SetChecked(	(columnData.index == "useRacialIndex" 	and not rowData.useRacial) 	or (columnData.index ~= "useRacialIndex" 	and rowData.useRacial)	)
					if columnData.index == "useKickIndex" or columnData.index == "useCCIndex" or columnData.index == "useRacialIndex" then 
						Action.Print(Action.GetSpellLink(rowData.ID) .. " " .. columnData.name .. ": ", not rowData[columnData.index:gsub("Index", "")])
						Add:Click()
						tab.childs[spec].RefferenceScrollTable:ClearSelection()
					end 
				end 				
			end 
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
                {
                    name = L["TAB"][tab.name]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 172,
					defaultwidth = 172,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["USEKICK"],
                    width = 65,
                    align = "CENTER",
                    index = "useKickIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["USECC"],
                    width = 65,
                    align = "CENTER",
                    index = "useCCIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["USERACIAL"],
                    width = 65,
                    align = "CENTER",
                    index = "useRacialIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, "Spell")       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 9, 25)			
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						InputBox:ClearFocus()	
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)	
			-- For refference
			tab.childs[spec].RefferenceScrollTable = ScrollTable
			
			local function Reset()
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(Action.Data.theme.off)	
				useKick:SetChecked(false)
				useCC:SetChecked(false)
				useRacial:SetChecked(false)
			end 
			local function ScrollTableInterruptData(InterruptUnits)
				local data = {}
				for k, v in pairs(TMW.db.profile.ActionDB[4][InterruptUnits][GameLocale]) do 
					if v.Enabled then 
						local useKickIndex, useCCIndex, useRacialIndex = v.useKick, v.useCC, v.useRacial
						useKickIndex 	= useKickIndex 		and "ON" or "OFF"
						useCCIndex 		= useCCIndex 		and "ON" or "OFF"
						useRacialIndex 	= useRacialIndex 	and "ON" or "OFF"
						table.insert(data, setmetatable({ 									
								Name 			= k,
								Icon 			= select(3, Action.GetSpellInfo(v.ID)),	
								useKickIndex 	= useKickIndex,
								useCCIndex 		= useCCIndex,
								useRacialIndex 	= useRacialIndex,
							}, {__index = v}))
					end 
				end
				return data
			end
			local function ScrollTableUpdate()
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableInterruptData(InterruptUnits:GetValue()))					
				ScrollTable:SortData(ScrollTable.SORTBY)			
			end 	
			local function CheckboxsUpdate()				
				local val = InterruptUnits:GetValue()			
				
				if val == "BlackList" then 
					-- TargetMouseover
					if not KickTargetMouseover.isDisabled then KickTargetMouseover:Disable() end 
					if not TargetMouseoverList.isDisabled then TargetMouseoverList:Disable() end 
					-- Heal
					if not KickHeal.isDisabled then KickHeal:Disable() end 
					if not KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Disable() end
					-- PvP 
					if not KickPvP.isDisabled then KickPvP:Disable() end 
					if not KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Disable() end 
					-- Disable use checkboxs
					useKick:SetChecked(false)
					useCC:SetChecked(false)
					useRacial:SetChecked(false)
					if not useKick.isDisabled then useKick:Disable() end 
					if not useCC.isDisabled then useCC:Disable() end 
					if not useRacial.isDisabled then useRacial:Disable() end 
				else 
					-- Enable use checkboxs 
					if useKick.isDisabled then useKick:Enable() end 
					if useCC.isDisabled then useCC:Enable() end 
					if useRacial.isDisabled then useRacial:Enable() end 
				end 
				
				if val:match("TargetMouseover") then 
					if KickTargetMouseover.isDisabled then KickTargetMouseover:Enable() end
					if Action.InterruptIsON("TargetMouseover") then 
						if TargetMouseoverList.isDisabled then TargetMouseoverList:Enable() end 
					elseif not TargetMouseoverList.isDisabled then 
						TargetMouseoverList:Disable()
					end 
				else 
					if not KickTargetMouseover.isDisabled then KickTargetMouseover:Disable() end 
					if not TargetMouseoverList.isDisabled then TargetMouseoverList:Disable() end 
				end
				
				if val == "Heal" then 
					if KickHeal.isDisabled then KickHeal:Enable() end 
					if Action.InterruptIsON(val) then
						if KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Enable() end 
					elseif not KickHealOnlyHealers.isDisabled then 
						KickHealOnlyHealers:Disable()						
					end 
				else 
					if not KickHeal.isDisabled then KickHeal:Disable() end 
					if not KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Disable() end
				end 
				
				if val == "PvP" then 
					if KickPvP.isDisabled then KickPvP:Enable() end 
					if Action.InterruptIsON(val) then
						if KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Enable() end
					elseif not KickPvPOnlySmart.isDisabled then  
						KickPvPOnlySmart:Disable()
					end 
				else 
					if not KickPvP.isDisabled then KickPvP:Disable() end 
					if not KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Disable() end 
				end
				
			end 		
			
			InterruptUnits.OnValueChanged = function(self, val)   
				ScrollTableUpdate()	
				CheckboxsUpdate()				
			end	
			StdUi:FrameTooltip(InterruptUnits, L["TAB"][tab.name]["INTERRUPTTOOLTIP"], nil, "TOP", true)		
			InterruptUnits.FontStringTitle = StdUi:FontString(InterruptUnits, L["TAB"][tab.name]["INTERRUPTFRONTSTRINGTITLE"])
			StdUi:GlueAbove(InterruptUnits.FontStringTitle, InterruptUnits)	
			InterruptUnits.text:SetJustifyH("CENTER")			

			Add:SetScript("OnClick", function(self, button, down)	
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local SpellID = InputBox.val
				local Name = Action.GetSpellInfo(SpellID)	
				if not SpellID or Name == nil or Name == "" or SpellID <= 1 then 
					Action.Print(L["TAB"][tab.name]["ADDERROR"]) 
				else 
					local InterruptList = InterruptUnits:GetValue()
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					
					local Kick, CC, Racial = useKick:GetChecked(), useCC:GetChecked(), useRacial:GetChecked()
					
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMW.db.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] and profile.ActionDB[tab.name][InterruptList] and profile.ActionDB[tab.name][InterruptList][GameLocale] then 	
								profile.ActionDB[tab.name][InterruptList][GameLocale][Name] = { Enabled = true, ID = SpellID, Name = Name, LUA = CodeLua, useKick = Kick, useCC = CC, useRacial = Racial }
							end 
						end 					
					else
						TMW.db.profile.ActionDB[tab.name][InterruptList][GameLocale][Name] = { Enabled = true, ID = SpellID, Name = Name, LUA = CodeLua, useKick = Kick, useCC = CC, useRacial = Racial }
					end 					

					ScrollTableUpdate()	
					InputBox:ClearFocus()
					InputBox:SetText("")
					InputBox.val = ""
					-- Clear checkboxs 
					useKick:SetChecked(false)
					useCC:SetChecked(false)
					useRacial:SetChecked(false)
				end 
			end)          
            StdUi:FrameTooltip(Add, L["TAB"][tab.name]["ADDTOOLTIP"], nil, "TOPRIGHT", true)		
		
			Remove:SetScript("OnClick", function(self, button, down)
				Reset()
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local InterruptList = InterruptUnits:GetValue()					
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMW.db.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] and profile.ActionDB[tab.name][InterruptList] and profile.ActionDB[tab.name][InterruptList][GameLocale] then 
								if Factory[tab.name][InterruptList][GameLocale][data.ID] and profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] then 
									profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name].Enabled = false
								else 
									profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] = nil
								end 														
							end 
						end 
					else
						if Factory[tab.name][InterruptList][GameLocale][data.ID] then 
							TMW.db.profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name].Enabled = false
						else 
							TMW.db.profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] = nil
						end 	
					end 
					ScrollTableUpdate()					
				end 
			end)           
            StdUi:FrameTooltip(Remove, L["TAB"][tab.name]["REMOVETOOLTIP"], nil, "TOPLEFT", true)				
								
            InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""
							self:SetNumber(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][tab.name]["INTEGERERROR"]) 
							return 
						end 
						ShowTooltip(self, true, self.val, "Spell") 
					else 
						ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = ConvertSpellNameToID(text)
							ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                ShowTooltip(self, false)
				Add:Click()                
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                ShowTooltip(self, false)
				self.val = ""
				self:SetNumber("")
				self:ClearFocus() 
            end)			
			InputBox:HookScript("OnHide", function(self)
				ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:FontString(InputBox, L["TAB"][tab.name]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][tab.name]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)		

			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:FontString(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)	
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)				
			
			KickPvP:SetChecked(TMW.db.profile.ActionDB[tab.name].KickPvP)
			KickPvP:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickPvP:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].KickPvP = not TMW.db.profile.ActionDB[tab.name].KickPvP	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].KickPvP)	
						Action.Print(L["TAB"][tab.name]["KICKPVPPRINT"] .. ": ", TMW.db.profile.ActionDB[tab.name].KickPvP)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKPVPPRINT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickPvP", "]] .. L["TAB"][tab.name]["KICKPVPPRINT"] .. [[: "})]])	
					end 
				end 
			end)
			KickPvP.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickPvP.Identify = { Type = "Checkbox", Toggle = "KickPvP" }				
			StdUi:FrameTooltip(KickPvP, L["TAB"][tab.name]["KICKPVPTOOLTIP"], nil, "TOPRIGHT", true)	
			
			KickHeal:SetChecked(TMW.db.profile.ActionDB[tab.name].KickHeal)
			KickHeal:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickHeal:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].KickHeal = not TMW.db.profile.ActionDB[tab.name].KickHeal	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].KickHeal)	
						Action.Print(L["TAB"][tab.name]["KICKHEALPRINT"] .. ": ", TMW.db.profile.ActionDB[tab.name].KickHeal)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKHEALPRINT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickHeal", "]] .. L["TAB"][tab.name]["KICKHEALPRINT"] .. [[: "})]])	
					end 
				end
			end)
			KickHeal.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickHeal.Identify = { Type = "Checkbox", Toggle = "KickHeal" }					
			StdUi:FrameTooltip(KickHeal, L["TAB"][tab.name]["KICKHEALTOOLTIP"], nil, "TOP", true)				
			
			TargetMouseoverList:SetChecked(TMW.db.profile.ActionDB[tab.name].TargetMouseoverList)	
			TargetMouseoverList:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			TargetMouseoverList:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].TargetMouseoverList = not TMW.db.profile.ActionDB[tab.name].TargetMouseoverList	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].TargetMouseoverList)	
						Action.Print(L["TAB"][tab.name]["TARGETMOUSEOVERLIST"] .. ": ", TMW.db.profile.ActionDB[tab.name].TargetMouseoverList)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["TARGETMOUSEOVERLIST"], [[/run Action.SetToggle({]] .. tab.name .. [[, "TargetMouseoverList", "]] .. L["TAB"][tab.name]["TARGETMOUSEOVERLIST"] .. [[: "})]])	
					end 
				end
			end)
			TargetMouseoverList.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()				
			end
			TargetMouseoverList.Identify = { Type = "Checkbox", Toggle = "TargetMouseoverList" }			
			StdUi:FrameTooltip(TargetMouseoverList, L["TAB"][tab.name]["TARGETMOUSEOVERLISTTOOLTIP"], nil, "TOPLEFT", true)	
			
			KickPvPOnlySmart:SetChecked(TMW.db.profile.ActionDB[tab.name].KickPvPOnlySmart)
			KickPvPOnlySmart:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickPvPOnlySmart:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].KickPvPOnlySmart = not TMW.db.profile.ActionDB[tab.name].KickPvPOnlySmart	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].KickPvPOnlySmart)	
						Action.Print(L["TAB"][tab.name]["KICKPVPONLYSMART"] .. ": ", TMW.db.profile.ActionDB[tab.name].KickPvPOnlySmart)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKPVPONLYSMART"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickPvPOnlySmart", "]] .. L["TAB"][tab.name]["KICKPVPONLYSMART"] .. [[: "})]])	
					end 
				end 
			end)
			KickPvPOnlySmart.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickPvPOnlySmart.Identify = { Type = "Checkbox", Toggle = "KickPvPOnlySmart" }						
			StdUi:FrameTooltip(KickPvPOnlySmart, L["TAB"][tab.name]["KICKPVPONLYSMARTTOOLTIP"], nil, "TOPRIGHT", true)												

			KickHealOnlyHealers:SetChecked(TMW.db.profile.ActionDB[tab.name].KickHealOnlyHealers)
			KickHealOnlyHealers:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickHealOnlyHealers:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].KickHealOnlyHealers = not TMW.db.profile.ActionDB[tab.name].KickHealOnlyHealers	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].KickHealOnlyHealers)	
						Action.Print(L["TAB"][tab.name]["KICKHEALONLYHEALER"] .. ": ", TMW.db.profile.ActionDB[tab.name].KickHealOnlyHealers)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKHEALONLYHEALER"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickHealOnlyHealers", "]] .. L["TAB"][tab.name]["KICKHEALONLYHEALER"] .. [[: "})]])	
					end
				end 
			end)
			KickHealOnlyHealers.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickHealOnlyHealers.Identify = { Type = "Checkbox", Toggle = "KickHealOnlyHealers" }				
			StdUi:FrameTooltip(KickHealOnlyHealers, L["TAB"][tab.name]["KICKHEALONLYHEALERTOOLTIP"], nil, "TOP", true)		

			KickTargetMouseover:SetChecked(TMW.db.profile.ActionDB[tab.name].KickTargetMouseover)
			KickTargetMouseover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickTargetMouseover:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].KickTargetMouseover = not TMW.db.profile.ActionDB[tab.name].KickTargetMouseover	
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].KickTargetMouseover)	
						Action.Print(L["TAB"][tab.name]["KICKTARGETMOUSEOVER"] .. ": ", TMW.db.profile.ActionDB[tab.name].KickTargetMouseover)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKTARGETMOUSEOVER"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickTargetMouseover", "]] .. L["TAB"][tab.name]["KICKTARGETMOUSEOVER"] .. [[: "})]])	
					end 
				end
			end)
			KickTargetMouseover.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()				
			end
			KickTargetMouseover.Identify = { Type = "Checkbox", Toggle = "KickTargetMouseover" }			
			StdUi:FrameTooltip(KickTargetMouseover, L["TAB"][tab.name]["KICKTARGETMOUSEOVERTOOLTIP"], nil, "TOPLEFT", true)
			          		
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				CheckboxsUpdate()
				Reset()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
				CheckboxsUpdate()
				Reset()
			end 
						
			tab.childs[spec]:AddRow({ margin = { top = -8, left = -15, right = -15 } }):AddElement(InterruptUnits)
			tab.childs[spec]:AddRow({ margin = { top = 15, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -20, left = -10, right = -10 } }):AddElements(KickPvPOnlySmart, KickHealOnlyHealers, KickTargetMouseover, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = -10, left = -10, right = -10 } }):AddElements(KickPvP, KickHeal, TargetMouseoverList, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:AddRow({ margin = { top = -10, left = -10, right = -10 } }):AddElements(useKick, useCC, useRacial, { column = "even" })
			ConfigPanel:DoLayout()		
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()

			ResetConfigPanel:SetScript("OnClick", Reset)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")			
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
				else 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				end 
			end)
		end 
		
		if tab.name == 5 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])							
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 10 } })
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 60, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseDispel = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEDISPEL"], 30)
			local UsePurge = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEPURGE"], 30)	
			local UseExpelEnrage = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEEXPELENRAGE"], 30)
			local UseExpelFrenzy = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEEXPELFRENZY"], 30)
			local Mode = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), Action.Data.theme.dd.height, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), Action.Data.theme.dd.height, {		
				{ text = "BlackList", value = "BlackList" },
				{ text = L["TAB"][tab.name]["POISON"], value = "Poison" },				
				{ text = L["TAB"][tab.name]["DISEASE"], value = "Disease" },
				{ text = L["TAB"][tab.name]["CURSE"], value = "Curse" },				
				{ text = L["TAB"][tab.name]["MAGIC"], value = "Magic" },
				--{ text = L["TAB"][tab.name]["MAGICMOVEMENT"], value = "MagicMovement" },				
				{ text = L["TAB"][tab.name]["PURGEFRIENDLY"], value = "PurgeFriendly" },
				{ text = L["TAB"][tab.name]["PURGEHIGH"], value = "PurgeHigh" },				
				{ text = L["TAB"][tab.name]["PURGELOW"], value = "PurgeLow" },
				{ text = L["TAB"][tab.name]["ENRAGE"], value = "Enrage" },
				{ text = L["TAB"][tab.name]["USEEXPELFRENZY"], value = "Frenzy" },				
			}, "Magic")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 140, L["TAB"][tab.name]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { gutter = 0, padding = { top = 40 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, Action.Data.theme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:FontString(LuaButton, Action.Data.theme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Role = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tab.name]["ANY"], value = "ANY" },				
				{ text = L["TAB"][tab.name]["HEALER"], value = "HEALER" },
				{ text = L["TAB"][tab.name]["DAMAGER"], value = "DAMAGER" },
			}, "ANY")
			local Duration = StdUi:EditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, 0)
			local Stack = StdUi:NumericBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, 0)			
			local canStealOrPurge = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["CANSTEALORPURGE"])	
			local onlyBear = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["ONLYBEAR"])	
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12, 15), 20, L["TAB"][4]["SEARCH"])						
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["REMOVE"])

			local function ClearAllEditBox(clearInput)
				if clearInput then 
					InputBox:SetNumber("")
				end
				InputBox:ClearFocus()
				Duration:ClearFocus()
				Stack:ClearFocus()
			end 
			
			-- [ScrollTable] BEGIN			
			local function ShowCellTooltip(parent, show, data)
				if show == "Hide" then 
					GameTooltip:Hide()
				else 
					GameTooltip:SetOwner(parent)				
					if show == "Role" then
						GameTooltip:SetText(L["TAB"][tab.name]["ROLETOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Dur" then 
						GameTooltip:SetText(L["TAB"][tab.name]["DURATIONTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Stack" then 
						GameTooltip:SetText(L["TAB"][tab.name]["STACKSTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)					
					end 
				end
			end 
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 
					Role:SetValue(rowData.Role)
					Duration:SetNumber(rowData.Dur)
					Stack:SetNumber(rowData.Stack)
					canStealOrPurge:SetChecked(rowData.canStealOrPurge)
					onlyBear:SetChecked(rowData.onlyBear)
					InputBox:SetNumber(rowData.ID)					
					ClearAllEditBox()
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["ROLE"],
                    width = 70,
                    align = "LEFT",
                    index = "RoleLocale",
                    format = "string",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Role")   							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")    							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number", 
					events = {                        
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 167,
					defaultwidth = 167,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["DURATION"],
                    width = 80,
                    align = "LEFT",
                    index = "Dur",
                    format = "number",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Dur")   							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide") 							
                        end,
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["STACKS"],
                    width = 50,
                    align = "LEFT",
                    index = "Stack",
                    format = "number", 
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Stack")      						
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")  							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, "Spell")  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 7, 30)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						ClearAllEditBox()	
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 3
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				DispelPurgeEnrageRemap()
				local CategoryValue = Category:GetValue()
				local ModeValue = Mode:GetValue()
				local data = {}
				for k, v in pairs(Action.Data.Auras[ModeValue][CategoryValue]) do 
					if v.Enabled then 
						v.Icon = select(3, Action.GetSpellInfo(v.ID))
						v.RoleLocale = L["TAB"][tab.name][v.Role]
						table.insert(data, v)
					end 
				end
				return data
			end 
			local function ScrollTableUpdate()
				ClearAllEditBox(true)
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END 
			
			UseDispel:SetChecked(TMW.db.profile.ActionDB[tab.name].UseDispel)
			UseDispel:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseDispel:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].UseDispel = not TMW.db.profile.ActionDB[tab.name].UseDispel
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].UseDispel)	
						Action.Print(L["TAB"][tab.name]["USEDISPEL"] .. ": ", TMW.db.profile.ActionDB[tab.name].UseDispel)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEDISPEL"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseDispel", "]] .. L["TAB"][tab.name]["USEDISPEL"] .. [[: "})]])	
					end
				end 
			end)
			UseDispel.Identify = { Type = "Checkbox", Toggle = "UseDispel" }
			StdUi:FrameTooltip(UseDispel, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			if not Action.Data.Auras.DisableCheckboxes or Action.Data.Auras.DisableCheckboxes.UseDispel then 
				UseDispel:Disable()
			end 
	
			UsePurge:SetChecked(TMW.db.profile.ActionDB[tab.name].UsePurge)
			UsePurge:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UsePurge:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].UsePurge = not TMW.db.profile.ActionDB[tab.name].UsePurge
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].UsePurge)	
						Action.Print(L["TAB"][tab.name]["USEPURGE"] .. ": ", TMW.db.profile.ActionDB[tab.name].UsePurge)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEPURGE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UsePurge", "]] .. L["TAB"][tab.name]["USEPURGE"] .. [[: "})]])	
					end 
				end
			end)
			UsePurge.Identify = { Type = "Checkbox", Toggle = "UsePurge" }
			StdUi:FrameTooltip(UsePurge, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOP", true)	
			if not Action.Data.Auras.DisableCheckboxes or Action.Data.Auras.DisableCheckboxes.UsePurge then 
				UsePurge:Disable()
			end 			

			UseExpelEnrage:SetChecked(TMW.db.profile.ActionDB[tab.name].UseExpelEnrage)
			UseExpelEnrage:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseExpelEnrage:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].UseExpelEnrage = not TMW.db.profile.ActionDB[tab.name].UseExpelEnrage
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].UseExpelEnrage)	
						Action.Print(L["TAB"][tab.name]["USEEXPELENRAGE"] .. ": ", TMW.db.profile.ActionDB[tab.name].UseExpelEnrage)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEEXPELENRAGE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseExpelEnrage", "]] .. L["TAB"][tab.name]["USEEXPELENRAGE"] .. [[: "})]])	
					end 
				end
			end)
			UseExpelEnrage.Identify = { Type = "Checkbox", Toggle = "UseExpelEnrage" }	
			StdUi:FrameTooltip(UseExpelEnrage, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)	
			if not Action.Data.Auras.DisableCheckboxes or Action.Data.Auras.DisableCheckboxes.UseExpelEnrage then 
				UseExpelEnrage:Disable()
			end 
			
			UseExpelFrenzy:SetChecked(TMW.db.profile.ActionDB[tab.name].UseExpelFrenzy)
			UseExpelFrenzy:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseExpelFrenzy:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].UseExpelFrenzy = not TMW.db.profile.ActionDB[tab.name].UseExpelFrenzy
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].UseExpelFrenzy)	
						Action.Print(L["TAB"][tab.name]["USEEXPELFRENZY"] .. ": ", TMW.db.profile.ActionDB[tab.name].UseExpelFrenzy)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEEXPELFRENZY"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseExpelFrenzy", "]] .. L["TAB"][tab.name]["USEEXPELFRENZY"] .. [[: "})]])	
					end 
				end
			end)
			UseExpelFrenzy.Identify = { Type = "Checkbox", Toggle = "UseExpelFrenzy" }	
			StdUi:FrameTooltip(UseExpelFrenzy, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)	
			if not Action.Data.Auras.DisableCheckboxes or Action.Data.Auras.DisableCheckboxes.UseExpelFrenzy then 
				UseExpelFrenzy:Disable()
			end 
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:FontString(Mode, L["TAB"][tab.name]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", ClearAllEditBox)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:FontString(Category, L["TAB"][tab.name]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", ClearAllEditBox)
								
			Role.text:SetJustifyH("CENTER")
			Role.FontStringTitle = StdUi:FontString(Role, L["TAB"][tab.name]["ROLE"])
			Role:HookScript("OnClick", ClearAllEditBox)			
			StdUi:FrameTooltip(Role, L["TAB"][tab.name]["ROLETOOLTIP"], nil, "TOPRIGHT", true)
			StdUi:GlueAbove(Role.FontStringTitle, Role)	
			
			Duration:SetJustifyH("CENTER")
			Duration:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Duration:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Duration:SetScript("OnTextChanged", function(self)
				local val = self:GetText():gsub("[^%d%.]", "")
				self:SetNumber(val)
			end)
			Duration:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()				
				if text == nil or text == "" or not text:find("%d") or text:sub(1, 1) == "." or (text:len() > 1 and text:sub(1, 1) == "0" and not text:find("%.")) then 
					self:SetNumber(0)
				elseif text:sub(-1) == "." then 
					self:SetNumber(text:gsub("%.", ""))
				end 
			end)
			local Font = string.gsub(string.gsub(L["TAB"][tab.name]["DURATION"], "\n", ""), "-", "")
			Duration.FontStringTitle = StdUi:FontString(Duration, Font)			
			StdUi:FrameTooltip(Duration, L["TAB"][tab.name]["DURATIONTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(Duration.FontStringTitle, Duration)	
						
            Stack:SetMaxValue(1000)
            Stack:SetMinValue(0)
			Stack:SetJustifyH("CENTER")
			Stack:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Stack:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Stack:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()	
				if text == nil or text == "" then 
					self:SetNumber(0)
				end 
			end)
			local Font = string.gsub(L["TAB"][tab.name]["STACKS"], "\n", "")
			Stack.FontStringTitle = StdUi:FontString(Stack, Font)			
			StdUi:FrameTooltip(Stack, L["TAB"][tab.name]["STACKSTOOLTIP"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Stack.FontStringTitle, Stack)						
		
			canStealOrPurge:HookScript("OnClick", ClearAllEditBox)						
			onlyBear:HookScript("OnClick", ClearAllEditBox)
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""
							self:SetNumber(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][4]["INTEGERERROR"]) 
							return 
						end 
						ShowTooltip(self, true, self.val, "Spell") 
					else 
						ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = ConvertSpellNameToID(text)
							ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                ShowTooltip(self, false)
				Add:Click()				              
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                ShowTooltip(self, false)
				InputBox:ClearFocus()
            end)
			InputBox:HookScript("OnHide", function(self)
				ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:FontString(InputBox, L["TAB"][4]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local SpellID = InputBox.val
				local Name = Action.GetSpellInfo(SpellID)	
				if not SpellID or Name == nil or Name == "" or SpellID <= 1 then 
					Action.Print(L["TAB"][4]["ADDERROR"]) 
				else
					local M = Mode:GetValue()
					local C = Category:GetValue()
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					-- Prevent overwrite by next time loading if user applied own changes 
					local LUAVER 
					if TMW.db.global.ActionDB[tab.name][M][C][SpellID] then 
						LUAVER = TMW.db.global.ActionDB[tab.name][M][C][SpellID].LUAVER 
					end 
									
					TMW.db.global.ActionDB[tab.name][M][C][SpellID] = { 
						ID = SpellID, 
						Name = Name, 
						enabled = true,
						role = Role:GetValue(),
						dur = round(tonumber(Duration:GetNumber()), 3) or 0,
						stack = Stack:GetNumber() or 0,
						canStealOrPurge = canStealOrPurge:GetChecked(),
						onlyBear = onlyBear:GetChecked(),
						LUA = CodeLua,
						LUAVER = LUAVER,
					}
					ScrollTableUpdate()						
				end 
			end)         
            StdUi:FrameTooltip(Add, L["TAB"][4]["ADDTOOLTIP"], nil, "TOPRIGHT", true)		

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)	
					if GlobalFactory[tab.name][Mode:GetValue()][Category:GetValue()][data.ID] then 
						TMW.db.global.ActionDB[tab.name][Mode:GetValue()][Category:GetValue()][data.ID].enabled = false						
					else 
						TMW.db.global.ActionDB[tab.name][Mode:GetValue()][Category:GetValue()][data.ID] = nil
					end 					
					ScrollTableUpdate()					
				end 
			end)            
            StdUi:FrameTooltip(Remove, L["TAB"][4]["REMOVETOOLTIP"], nil, "TOPLEFT", true)							          
				
			tab.childs[spec]:AddRow({ margin = { top = -4, left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow({ margin = { top = 5 } }):AddElements(UseDispel, UsePurge, UseExpelEnrage, UseExpelFrenzy, { column = "even" })	
			UsePanel:DoLayout()	
			tab.childs[spec]:AddRow({ margin = { top = -10 } }):AddElement(UI_Title)			
			tab.childs[spec]:AddRow({ margin = { top = 0, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			tab.childs[spec]:AddRow({ margin = { top = 18, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)
			ConfigPanel:AddRow():AddElements(Role, Duration, Stack, { column = "even" })						
			ConfigPanel:AddRow({ margin = { top = -10 } }):AddElements(canStealOrPurge, onlyBear, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = 5 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			UI_Title:SetJustifyH("CENTER")
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				Role:SetValue("ANY")
				Duration:SetNumber(0)
				Stack:SetNumber(0)
				canStealOrPurge:SetChecked(false)
				onlyBear:SetChecked(false)
				InputBox.val = ""
				InputBox:SetNumber("")					
				ClearAllEditBox()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
				else 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				end 
			end)
		end 
		
		if tab.name == 6 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, tab.childs[spec], 0, -5)			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 50, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseLeft = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USELEFT"])
			local UseRight = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USERIGHT"])
			local Mode = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), Action.Data.theme.dd.height, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), Action.Data.theme.dd.height, {				
				{ text = "UnitName", value = "UnitName" },				
				{ text = "GameToolTip", value = "GameToolTip" },
			}, "UnitName")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 95, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, Action.Data.theme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:FontString(LuaButton, Action.Data.theme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"][tab.name]["LUATOOLTIP"])
			local Button = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tab.name]["LEFT"], value = "LEFT" },				
				{ text = L["TAB"][tab.name]["RIGHT"], value = "RIGHT" },		
			}, "LEFT")
			local isTotem = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["ISTOTEM"])				
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["INPUT"])		
			local How = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], value = "GLOBAL" },				
				{ text = L["TAB"]["ALLSPECS"], value = "ALLSPECS" },
			}, "ALLSPECS")	
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 
					Button:SetValue(rowData.Button)
					isTotem:SetChecked(rowData.isTotem)
					InputBox:SetNumber(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["BUTTON"],
                    width = 120,
                    align = "LEFT",
                    index = "ButtonLocale",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 357,
					defaultwidth = 357,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
            }, 12, 20)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						InputBox:ClearFocus()
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				isTotem:SetChecked(false)
				local CategoryValue = Category:GetValue()
				local ModeValue = Mode:GetValue()
				local data = {}
				for k, v in pairs(TMW.db.profile.ActionDB[tab.name][ModeValue][CategoryValue][GameLocale]) do 
					if v.Enabled then 
						table.insert(data, setmetatable({ 
								Name = k, 				
								ButtonLocale = L["TAB"][tab.name][v.Button],
							}, {__index = v}))
					end 
				end			
				return data
			end 
			local function ScrollTableUpdate()
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END 
			
			UseLeft:SetChecked(TMW.db.profile.ActionDB[tab.name].UseLeft)
			UseLeft:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseLeft:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].UseLeft = not TMW.db.profile.ActionDB[tab.name].UseLeft
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].UseLeft)	
					Action.Print(L["TAB"][tab.name]["USELEFT"] .. ": ", TMW.db.profile.ActionDB[tab.name].UseLeft)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["USELEFT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseLeft", "]] .. L["TAB"][tab.name]["USELEFT"] .. [[: "})]])	
				end				
			end)
			UseLeft.Identify = { Type = "Checkbox", Toggle = "UseLeft" }
			StdUi:FrameTooltip(UseLeft, L["TAB"][tab.name]["USELEFTTOOLTIP"], nil, "TOPRIGHT", true)
			
			UseRight:SetChecked(TMW.db.profile.ActionDB[tab.name].UseRight)
			UseRight:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseRight:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					TMW.db.profile.ActionDB[tab.name].UseRight = not TMW.db.profile.ActionDB[tab.name].UseRight
					self:SetChecked(TMW.db.profile.ActionDB[tab.name].UseRight)	
					Action.Print(L["TAB"][tab.name]["USERIGHT"] .. ": ", TMW.db.profile.ActionDB[tab.name].UseRight)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["USERIGHT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseRight", "]] .. L["TAB"][tab.name]["USERIGHT"] .. [[: "})]])	
				end				
			end)
			UseRight.Identify = { Type = "Checkbox", Toggle = "UseRight" }
			StdUi:FrameTooltip(UseRight, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:FontString(Mode, L["TAB"][5]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:FontString(Category, L["TAB"][5]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
								
			Button.text:SetJustifyH("CENTER")
			Button:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)			
			
			StdUi:FrameTooltip(isTotem, L["TAB"][tab.name]["ISTOTEMTOOLTIP"], nil, "BOTTOMLEFT", true)	
			isTotem:HookScript("OnClick", function(self)
				if not self.isDisabled then 
					InputBox:ClearFocus()
				end 
			end)	
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function()
				InputBox:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:FontString(InputBox, L["TAB"][tab.name]["INPUTTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:FontString(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)	
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tab.name]["INPUTTITLE"]) 
				else					
					Name = Name:lower()
					local M = Mode:GetValue()
					local C = Category:GetValue()					
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMW.db.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] then 
								-- Prevent overwrite by next time loading if user applied own changes 
								local LUAVER 
								if profile.ActionDB[tab.name][M][C][GameLocale][Name] then 
									LUAVER = profile.ActionDB[tab.name][M][C][GameLocale][Name].LUAVER 
								end 
								
								profile.ActionDB[tab.name][M][C][GameLocale][Name] = { 
									Enabled = true,
									Button = Button:GetValue(),
									isTotem = isTotem:GetChecked(),
									LUA = CodeLua,
									LUAVER = LUAVER,
								}								 
							end 
						end 					
					else 
						-- Prevent overwrite by next time loading if user applied own changes 
						local LUAVER 
						if TMW.db.profile.ActionDB[tab.name][M][C][GameLocale][Name] then 
							LUAVER = TMW.db.profile.ActionDB[tab.name][M][C][GameLocale][Name].LUAVER 
						end 
							
						TMW.db.profile.ActionDB[tab.name][M][C][GameLocale][Name] = { 
							Enabled = true,
							Button = Button:GetValue(),
							isTotem = isTotem:GetChecked(),
							LUA = CodeLua,
							LUAVER = LUAVER,
						}
					end 
					ScrollTableUpdate()						
				end 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					local M = Mode:GetValue()
					local C = Category:GetValue()	
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMW.db.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] then 
								if profile.ActionDB[tab.name][M] and profile.ActionDB[tab.name][M][C] and profile.ActionDB[tab.name][M][C][GameLocale] then 
									if Factory[tab.name][M][C][GameLocale][Name] and profile.ActionDB[tab.name][M][C][GameLocale][Name] then 
										profile.ActionDB[tab.name][M][C][GameLocale][Name].Enabled = false
									else 
										profile.ActionDB[tab.name][M][C][GameLocale][Name] = nil
									end 
								end 								 
							end 
						end 					  
					else 
						if Factory[tab.name][M][C][GameLocale][Name] then 
							TMW.db.profile.ActionDB[tab.name][M][C][GameLocale][Name].Enabled = false
						else 
							TMW.db.profile.ActionDB[tab.name][M][C][GameLocale][Name] = nil
						end 
					end 
					ScrollTableUpdate()					
				end 
			end)            							          
				
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(UseLeft, UseRight, { column = "even" })
			UsePanel:DoLayout()						
			tab.childs[spec]:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			tab.childs[spec]:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -20, left = -15, right = -15 } }):AddElements(Button, isTotem, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				isTotem:SetChecked(false)
				InputBox:SetNumber("")					
				InputBox:ClearFocus()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
				else 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				end 
			end)		
		end 
		
		if tab.name == 7 then 
			if not Action.Data.ProfileUI or not Action.Data.ProfileUI[tab.name] or not Action.Data.ProfileUI[tab.name] or not next(Action.Data.ProfileUI[tab.name]) then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 		
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, tab.childs[spec], 0, -5)			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 50, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local MSG_Toggle = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["MSG"])
			local DisableReToggle = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["DISABLERETOGGLE"])
			local ScrollTable 
			local Macro = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 20, "")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 100, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(13)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, Action.Data.theme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, Action.Data.theme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:FontString(LuaButton, Action.Data.theme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])						
			local Key = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local Source = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["INPUT"])			
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
					else 
						LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
					end 
					Macro:SetText(rowData.Name and "/party " .. rowData.Name or "")
					Macro:ClearFocus()										
					Key:SetText(rowData.Key)
					Key:ClearFocus()
					Source:SetText(rowData.Source or "")
					Source:ClearFocus()
					InputBox:SetText(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 
			ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["KEY"],
                    width = 100,
                    align = "LEFT",
                    index = "Key",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 207,
					defaultwidth = 207,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["WHOSAID"],
                    width = 120,
                    align = "LEFT",
                    index = "Source",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 14, 20)			
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						Macro:ClearFocus()					
						Key:ClearFocus()
						Source:ClearFocus()
						InputBox:ClearFocus()						
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				local data = {}
				for k, v in pairs(TMW.db.profile.ActionDB[tab.name].msgList) do 
					if v.Enabled then 
						if Action[Action.PlayerClass][v.Key] then 
							table.insert(data, setmetatable({
								Enabled = v.Enabled,
								Key = v.Key,
								Source = v.Source or "",
								LUA = v.LUA,
								Name = k, 								
								Icon = Action[Action.PlayerClass][v.Key]:Icon(),
							}, {__index = Action[Action.PlayerClass][v.Key]}))
						else 
							v = nil 
						end 
					end 
				end			
				return data
			end 
			local function ScrollTableUpdate()
				Macro:ClearFocus()				
				Key:ClearFocus()
				Source:ClearFocus()
				InputBox:ClearFocus()				
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END
			
			MSG_Toggle:SetChecked(TMW.db.profile.ActionDB[tab.name].MSG_Toggle)
			MSG_Toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			MSG_Toggle:SetScript("OnClick", function(self, button, down)	
				Macro:ClearFocus()	
				Key:ClearFocus()
				Source:ClearFocus()				
				InputBox:ClearFocus()
				if button == "LeftButton" then 
					Action.ToggleMSG()	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["MSG"], [[/run Action.ToggleMSG()]])	
				end				
			end)
			MSG_Toggle.Identify = { Type = "Checkbox", Toggle = "MSG_Toggle" }
			StdUi:FrameTooltip(MSG_Toggle, L["TAB"][tab.name]["MSGTOOLTIP"], nil, "TOPRIGHT", true)
			
			DisableReToggle:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableReToggle)
			DisableReToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableReToggle:SetScript("OnClick", function(self, button, down)	
				Macro:ClearFocus()	
				Key:ClearFocus()
				Source:ClearFocus()				
				InputBox:ClearFocus()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMW.db.profile.ActionDB[tab.name].DisableReToggle = not TMW.db.profile.ActionDB[tab.name].DisableReToggle
						self:SetChecked(TMW.db.profile.ActionDB[tab.name].DisableReToggle)	
						Action.Print(L["TAB"][tab.name]["DISABLERETOGGLE"] .. ": ", TMW.db.profile.ActionDB[tab.name].DisableReToggle)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["DISABLERETOGGLE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "DisableReToggle", "]] .. L["TAB"][tab.name]["DISABLERETOGGLE"] .. [[: "})]])	
					end		
				end 
			end)
			DisableReToggle.Identify = { Type = "Checkbox", Toggle = "DisableReToggle" }
			StdUi:FrameTooltip(DisableReToggle, L["TAB"][tab.name]["DISABLERETOGGLETOOLTIP"], nil, "TOPLEFT", true)
			DisableReToggle:SetScript("OnShow", function(self) 
				if not MSG_Toggle:GetChecked() then 
					self:Disable()
				end 
			end)
			if not MSG_Toggle:GetChecked() then 
				DisableReToggle:Disable()
			end 
			
			Macro:SetScript("OnTextChanged", function(self)
				local index = ScrollTable:GetSelection()				
				if not index then 
					return
				else 
					local data = ScrollTable:GetRow(index)					
					if data then 
						local thisname = "/party " .. data.Name 
						if thisname ~= self:GetText() then 
							self:SetText(thisname)
						end 
					end 
				end 
            end)
			Macro:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Macro:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)						
			Macro:SetJustifyH("CENTER")
			Macro.FontString = StdUi:FontString(Macro, L["TAB"][tab.name]["MACRO"])
			StdUi:GlueAbove(Macro.FontString, Macro) 
			StdUi:FrameTooltip(Macro, L["TAB"][tab.name]["MACROTOOLTIP"], nil, "TOP", true)			
			
			Key:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Key:SetJustifyH("CENTER")
			Key.FontString = StdUi:FontString(Key, L["TAB"][tab.name]["KEY"])
			StdUi:GlueAbove(Key.FontString, Key)	
			StdUi:FrameTooltip(Key, L["TAB"][tab.name]["KEYTOOLTIP"], nil, "TOPRIGHT", true)	

			Source:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Source:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Source:SetJustifyH("CENTER")
			Source.FontString = StdUi:FontString(Source, L["TAB"][tab.name]["SOURCE"])
			StdUi:GlueAbove(Source.FontString, Source)	
			StdUi:FrameTooltip(Source, L["TAB"][tab.name]["SOURCETOOLTIP"], nil, "TOPLEFT", true)

			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:FontString(InputBox, L["TAB"][tab.name]["INPUTTITLE"])						
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			StdUi:FrameTooltip(InputBox, L["TAB"][tab.name]["INPUTTOOLTIP"], nil, "TOP", true)			
			
			Add:SetScript("OnClick", function(self, button, down)		
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tab.name]["INPUTERROR"]) 
					return 
				end 
				
				local TableKey = Key:GetText()
				if TableKey == nil or TableKey == "" then 
					Action.Print(L["TAB"][tab.name]["KEYERROR"]) 
					return 
				elseif not Action[Action.PlayerClass][TableKey] then 
					Action.Print(TableKey .. " " .. L["TAB"][tab.name]["KEYERRORNOEXIST"]) 
					return 
				end 				
			
				Name = Name:lower()	
				for k, v in pairs(TMW.db.profile.ActionDB[tab.name].msgList) do 
					if v.Enabled and Name:match(k) and Name ~= k then 
						Action.Print(Name .. " " .. L["TAB"][tab.name]["MATCHERROR"]) 
						return 
					end
				end 
				
				local SourceName = Source:GetText()
				if SourceName == "" then 
					SourceName = nil
				end 				
				
				local CodeLua = LuaEditor.EditBox:GetText()
				if CodeLua == "" then 
					CodeLua = nil 
				end 
				
				-- Prevent overwrite by next time loading if user applied own changes 
				local LUAVER 
				if TMW.db.profile.ActionDB[tab.name].msgList[Name] then 
					LUAVER = TMW.db.profile.ActionDB[tab.name].msgList[Name].LUAVER
				end 

				TMW.db.profile.ActionDB[tab.name].msgList[Name] = { 
					Enabled = true,
					Key = TableKey,
					Source = SourceName,
					LUA = CodeLua,
					LUAVER = LUAVER,
				}
 
				ScrollTableUpdate()										 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)		
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					if Action.Data.ProfileDB[tab.name].msgList[Name] then 
						TMW.db.profile.ActionDB[tab.name].msgList[Name].Enabled = false							
					else 
						TMW.db.profile.ActionDB[tab.name].msgList[Name] = nil	
					end 					
					ScrollTableUpdate()					
				end 
			end)            							          
				
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(MSG_Toggle, DisableReToggle, { column = "even" })
			UsePanel:DoLayout()								
			tab.childs[spec]:AddRow({ margin = { top = 10, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(Macro)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElements(Key, Source, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				Macro:SetText("")
				Macro:ClearFocus()	
				Key:SetText("")
				Key:ClearFocus()
				Source:SetText("")
				Source:ClearFocus()
				InputBox:SetText("")
				InputBox:ClearFocus()				
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.on)
				else 
					LuaButton.FontStringLUA:SetText(Action.Data.theme.off)
				end 
			end)							
		end 		
		
		if Action.MainUI.resizer then 
			Action.MainUI.UpdateResize()
		end 
	end)		
end

-------------------------------------------------------------------------------
-- Debug  
-------------------------------------------------------------------------------
function Action.Print(text, bool, ignore)
	if not ignore and TMW.db and TMW.db.profile.ActionDB and TMW.db.profile.ActionDB[1] and TMW.db.profile.ActionDB[1].DisablePrint then 
		return 
	end 
    local hex = "00ccff"
    local prefix = string.format("|cff%s%s|r", hex:upper(), "Action:")	
	local fulltext = text .. (bool ~= nil and tostring(bool) or "")
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, fulltext))
end

function Action.PrintHelpToggle()
	Action.Print("|cff00cc66Shift+LeftClick|r " .. L["SLASH"]["TOTOGGLEBURST"])
	Action.Print("|cff00cc66Ctrl+LeftClick|r " .. L["SLASH"]["TOTOGGLEMODE"])
	Action.Print("|cff00cc66Alt+LeftClick|r " .. L["SLASH"]["TOTOGGLEAOE"])
end 

-------------------------------------------------------------------------------
-- Specializations
-------------------------------------------------------------------------------
local classSpecIds = {
	DRUID 		= {102,103,105},
	HUNTER 		= {253,254,255},
	MAGE 		= {62,63,64},
	PALADIN 	= {65,66,70},
	PRIEST 		= {256,257,258},
	ROGUE 		= {259,260,261},
	SHAMAN 		= {262,263,264},
	WARLOCK 	= {265,266,267},
	WARRIOR 	= {71,72,73},
}
local specs = {
	-- 4th index is localizedName of the specialization 
	[253]	= {"Beast Mastery", 461112, "DAMAGER"},
	[254]	= {"Marksmanship", 236179, "DAMAGER"},
	[255]	= {"Survival", 461113, "DAMAGER"},

	[71]	= {"Arms", 132355, "DAMAGER"},
	[72]	= {"Fury", 132347, "DAMAGER"},
	[73]	= {"Protection", 132341, "TANK"},

	[65]	= {"Holy", 135920, "HEALER"},
	[66]	= {"Protection", 236264, "TANK"},
	[70]	= {"Retribution", 135873, "DAMAGER"},

	[62]	= {"Arcane", 135932, "DAMAGER"},
	[63]	= {"Fire", 135810, "DAMAGER"},
	[64]	= {"Frost", 135846, "DAMAGER"},

	[256]	= {"Discipline", 135940, "HEALER"},
	[257]	= {"Holy", 237542, "HEALER"},
	[258]	= {"Shadow", 136207, "DAMAGER"},

	[265]	= {"Affliction", 136145, "DAMAGER"},
	[266]	= {"Demonology", 136172, "DAMAGER"},
	[267]	= {"Destruction", 136186, "DAMAGER"},

	[102]	= {"Balance", 136096, "DAMAGER"},
	[103]	= {"Feral", 132115, "DAMAGER"},
	[105]	= {"Restoration", 136041, "HEALER"},

	[262]	= {"Elemental", 136048, "DAMAGER"},
	[263]	= {"Enhancement", 237581, "DAMAGER"},
	[264]	= {"Restoration", 136052, "HEALER"},

	[259]	= {"Assassination", 236270, "DAMAGER"},
	[260]	= {"Combat", 236286, "DAMAGER"},
	[261]	= {"Subtlety", 132320, "DAMAGER"},
}

function Action.GetNumSpecializations()
	-- @return number 
	return 3
end

function Action.GetCurrentSpecialization()
	-- @return number 
	-- Note: Index of the current specialization, otherwise 1 (assume it's first spec)
	local specID = Action.GetCurrentSpecializationID() 
	for i = 1, #classSpecIds[Action.PlayerClass] do 
		if specID == classSpecIds[Action.PlayerClass][i] then 
			return i 
		end 
	end 
	
	return 1 
end 

function Action.GetCurrentSpecializationID() 
	-- @return specID 
	-- Note: If it's zero we assume what our spec is some damager 
	local specIDs = classSpecIds[Action.PlayerClass]
	
	local biggest = 0
	local specID
	for i = 1, #specIDs do
		local localizedName, _, points = GetTalentTabInfo(i)
		specs[specIDs[i]][4] = localizedName
		if points > biggest then
			biggest = points
			specID = specIDs[i]
		elseif not specID and specs[specIDs[i]][3] == "DAMAGER" then 
			specID = specIDs[i]
		end
	end

	return specID
end

function Action.GetSpecializationInfo(index)
	-- @return specID, specNameEnglish, nil (was description), specIcon, specRole, specLocalizedName
	return Action.GetSpecializationInfoByID(classSpecIds[Action.PlayerClass][index])
end

function Action.GetSpecializationInfoByID(specID)
	-- @return specID, specNameEnglish, nil (was description), specIcon, specRole, specLocalizedName
	local data = specs[specID]
	return specID, data[1], nil, data[2], data[3], data[4]
end

function Action.GetCurrentSpecializationRole()
	-- @return string 
	local _, _, _, _, role = Action.GetSpecializationInfoByID(Action.GetCurrentSpecializationID())
	return role
end

function Action.GetCurrentSpecializationRoles()
	-- @return table or nil 
	local roles = {}
	for i = 1, Action.GetNumSpecializations() do 
		local _, _, _, _, role = Action.GetSpecializationInfo(i)
		roles[role] = true 
	end 
	return next(roles) and roles or nil 
end 

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
local HealerSpecs = {
	[ACTION_CONST_DRUID_RESTORATION]	= true,  
	[ACTION_CONST_PALADIN_HOLY]  		= true, 
	[ACTION_CONST_PRIEST_DISCIPLINE] 	= true, 
	[ACTION_CONST_PRIEST_HOLY] 			= true, 
	[ACTION_CONST_SHAMAN_RESTORATION] 	= true, 
}
local RangerSpecs = {
	--[ACTION_CONST_PALADIN_HOLY] 		= true,
	[ACTION_CONST_HUNTER_BEASTMASTERY]	= true,
	[ACTION_CONST_HUNTER_MARKSMANSHIP]	= true,
	[ACTION_CONST_HUNTER_SURVIVAL]		= true, 
	--[ACTION_CONST_PRIEST_DISCIPLINE]	= true,
	--[ACTION_CONST_PRIEST_HOLY]		= true,
	[ACTION_CONST_PRIEST_SHADOW]		= true,
	[ACTION_CONST_SHAMAN_ELEMENTAL]		= true,
	--[ACTION_CONST_SHAMAN_RESTORATION]	= true,
	[ACTION_CONST_MAGE_ARCANE]			= true,
	[ACTION_CONST_MAGE_FIRE]			= true,
	[ACTION_CONST_MAGE_FROST]			= true,
	[ACTION_CONST_WARLOCK_AFFLICTION]	= true,
	[ACTION_CONST_WARLOCK_DEMONOLOGY]	= true,	
	[ACTION_CONST_WARLOCK_DESTRUCTION]	= true,	
	[ACTION_CONST_DRUID_BALANCE]		= true,	
	--[ACTION_CONST_DRUID_RESTORATION]	= true,	
}
local tempRoleAssign = {1, "Role", nil, true}
function Action:PLAYER_SPECIALIZATION_CHANGED(event)
	if TMW.time == self.PLAYER_SPECIALIZATION_CHANGED_STAMP then 
		return 
	end 
	self.PLAYER_SPECIALIZATION_CHANGED_STAMP = TMW.time 
	
	local specID, specName, _, specIcon, specRole, specLocalizedName = Action.GetSpecializationInfoByID(Action.GetCurrentSpecializationID())
	Action.Role = Action.GetToggle(1, "Role") == "AUTO" and specRole or Action.GetToggle(1, "Role")
	
	local checkClassRoles 	= Action.GetCurrentSpecializationRoles()
	if checkClassRoles and not checkClassRoles[Action.Role] then 
		if TMW.db and TMW.db.profile and TMW.db.profile.ActionDB then 
			Action.SetToggle(tempRoleAssign, "DAMAGER")
		end 
		Action.Role = "DAMAGER"		
	end 
	
	-- The player can be in damager specID but still remain functional as HEALER role (!) 
	Action.PlayerSpec 		= specID
	Action.PlayerSpecName 	= specLocalizedName
    Action.IamHealer 		= Action.Role == "HEALER" or HealerSpecs[Action.PlayerSpec]
	Action.IamRanger 		= Action.IamHealer or RangerSpecs[Action.PlayerSpec]
	Action.IamMelee  		= not Action.IamRanger	
	
	Action.Print(string.format(LOOT_SPECIALIZATION_DEFAULT, Action.PlayerSpecName))
	Action.Print(L["TAB"][5]["ROLE"] .. ": " .. _G[Action.Role])
	
	-- For PetLibrary 
	-- For MultiUnits to initialize CLEU for ranger 
	-- For HealingEngine to initialize it 
	TMW:Fire("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED")	
end
Action:RegisterEvent("CHARACTER_POINTS_CHANGED", 	"PLAYER_SPECIALIZATION_CHANGED")
Action:RegisterEvent("CONFIRM_TALENT_WIPE", 		"PLAYER_SPECIALIZATION_CHANGED")

local function OnInitialize()	
	-- This function calls only if TMW finished EVERYTHING load
	-- This will initialize ActionDB for current profile by Action.Data.ProfileUI > Action.Data.ProfileDB (which in profile snippet)
	local profile = TMW.db:GetCurrentProfile()

	Action.IsInitialized = nil	
	Action.IsGGLprofile = profile:match("GGL") and true or false  	-- Don't remove it because this is validance for HealingEngine   	
	Action.IsBasicProfile = profile == "[GGL] Basic"
	
	----------------------------------
	-- TMW CORE SNIPPETS FIX
	----------------------------------	
	-- Finally owner of TMW fixed it in 8.6.6
	if TELLMEWHEN_VERSIONNUMBER < 86603 and not Action.IsInitializedSnippetsFix then 
		-- TMW owner has trouble with ICON and GROUP PRE SETUP, he trying :setup() frames before lua snippets would be loaded 
		-- Yeah he has callback ON PROFILE to run it but it's POST handler which triggers AFTER :setup() and it cause errors for nil objects (coz they are in snippets :D which couldn't be loaded before frames)
		local function OnProfileFix()
			if not TMW.Initialized or not TMW.InitializedDatabase then
				return
			end		
			
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMW.db.profile.CodeSnippets) do
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and not TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end						      
		end	
		TMW:RegisterCallback("TMW_GLOBAL_UPDATE", OnProfileFix, "TMW_SNIPPETS_FIX")	
		Action.IsInitializedSnippetsFix = true 
	end 	
	
	----------------------------------
	-- Register Localization
	----------------------------------	
	Action.GetLocalization()
	
	----------------------------------
	-- Profile Manipulation
	----------------------------------	
	-- Load default profile if current profile is generated as default
	local defaultprofile = UnitName("player") .. " - " .. GetRealmName()
	if profile == defaultprofile then 
		local AllProfiles = TMW.db.profiles
		if AllProfiles then 
			if Action.Data.DefaultProfile[Action.PlayerClass] and AllProfiles[Action.Data.DefaultProfile[Action.PlayerClass]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMW.db:SetProfile(Action.Data.DefaultProfile[Action.PlayerClass])
				return
			end		
		
			if AllProfiles[Action.Data.DefaultProfile["BASIC"]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMW.db:SetProfile(Action.Data.DefaultProfile["BASIC"])				
				return 
			end 
		end 
	end 		
		
	-- Check if profile support Action
	if not Action.Data.ProfileEnabled[profile] then 
		if TMW.db.profile.ActionDB then 
			TMW.db.profile.ActionDB = nil
			Action.Print("|cff00cc66" .. profile .. " - profile.ActionDB|r " .. L["RESETED"]:lower())
		end 			
		if Action.Minimap and LibDBIcon then 
			LibDBIcon:Hide("ActionUI")
		end 
		Queue:OnEventToReset()
		wipe(Action.Data.ProfileUI)
		wipe(Action.Data.ProfileDB)	
		if Action[Action.PlayerClass] then
			wipe(Action[Action.PlayerClass])
		end 
		Action:PLAYER_SPECIALIZATION_CHANGED()
		return 
	end 	 
	
	-- Action.Data.ProfileUI > Action.Data.ProfileDB creates template to merge in Factory after
	if next(Action.Data.ProfileUI) or #Action.Data.ProfileUI > 0 then 
		wipe(Action.Data.ProfileDB)
		-- Prevent developer's by mistake sensitive wrong assigns 
		local ReMap = {
			["mouseover"] = "mouseover",
			["targettarget"] = "targettarget", 
			["aoe"] = "AoE",
		}
		for i, i_value in pairs(Action.Data.ProfileUI) do
			if ( i == 2 or i == 7 ) and type(i) == "number" and type(i_value) == "table" then 	-- get tab 
				if not Action.Data.ProfileDB[i] then 
					Action.Data.ProfileDB[i] = {}
				end 
		
				if i == 2 then 																-- tab [2] for toggles 					
					for row = 1, #Action.Data.ProfileUI[i] do 								-- get row for spec in tab 						
						for element = 1, #Action.Data.ProfileUI[i][row] do 			-- get element in row for spec in tab 
							local DB = Action.Data.ProfileUI[i][row][element].DB 
							if ReMap[strlowerCache[DB]] then 
								Action.Data.ProfileUI[i][row][element].DB = ReMap[strlowerCache[DB]]
								DB = ReMap[strlowerCache[DB]]
							end 
							
							local DBV = Action.Data.ProfileUI[i][row][element].DBV
							if DB ~= nil and DBV ~= nil then 								-- if default value for DB inside UI 
								Action.Data.ProfileDB[i][DB] = DBV
							end 
						end						
					end
				elseif i == 7 then 															-- tab [7] for MSG 	
					if not Action.Data.ProfileDB[i].msgList then 
						Action.Data.ProfileDB[i].msgList = {}
					end 	
					
					for Name, Val in pairs(i_value) do 
						Action.Data.ProfileDB[i].msgList[Name] = Val
					end 
				end				 
			end 
		end 
	end 	
		
	-- profile	
	if not TMW.db.profile.ActionDB then 
		Action.Print("|cff00cc66ActionDB.profile|r " .. L["CREATED"])		
	end	
	TMW.db.profile.ActionDB = tCompare(tMerge(Factory, Action.Data.ProfileDB, true), TMW.db.profile.ActionDB) 
		
	-- global
	if not TMW.db.global.ActionDB then 		
		Action.Print("|cff00cc66ActionDB.global|r " .. L["CREATED"])
	end
	TMW.db.global.ActionDB = tCompare(GlobalFactory, TMW.db.global.ActionDB)	
	
	----------------------------------
	-- All remaps and additional sort DB 
	----------------------------------		
	-- Note: These functions must be call whenever relative settings in UI has been changed in their certain places!
	if Action.GetToggle(1, "DisableBlackBackground") then 
		Action.BlackBackgroundSet(not Action.GetToggle(1, "DisableBlackBackground"))
	end 
	DispelPurgeEnrageRemap() -- [5] by global to profile
	
	----------------------------------	
	-- Welcome Notification
	----------------------------------	
    Action.Print(L["SLASH"]["LIST"])
	Action.Print("|cff00cc66/action|r - "  .. L["SLASH"]["OPENCONFIGMENU"])
	Action.Print("|cff00cc66/action help|r - " .. L["SLASH"]["HELP"])		
	TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", OnInitialize, "ACTION_TMW_SAFESETUP_COMPLETE")

	----------------------------------	
	-- Initialization
	----------------------------------	
	-- Disable on Basic non available elements 
	if Action.IsBasicProfile then 
		TMW.db.profile.ActionDB[1].Potion = false 
	end 
	
	-- Initialization ReTarget 
	Re:Initialize()
	
	-- Initialization LOS System
	LineOfSight:Initialize()
	
	-- Initialization Cursor hooks 
	Action.CursorInit()
	
	-- Unregister from old interface MSG events and use new ones 
	Action.ToggleMSG(true)
	
	-- LetMeCast 
	LETMECAST:Initialize()
	
	-- AuraDuration 
	AuraDuration:Initialize(true)
	
	-- UnitHealthTool
	UnitHealthTool:Initialize(true)

	-- Initialization Cached functions 
	if not Action.IsInitializedCachedFunctions then 
		SmartInterrupt 						= Action.MakeFunctionCachedStatic(SmartInterrupt)		
		strElemBuilder						= Action.strElemBuilder
		Action.IsInitializedCachedFunctions = true 
	end 
	
	-- Minimap 
	if not Action.Minimap and LibDBIcon then 
		local ldbObject = {
			type = "launcher",
			icon = ACTION_CONST_AUTOTARGET,
			label = "ActionUI",
			OnClick = function(self, button)
				Action.ToggleMainUI()
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("ActionUI")
			end,
		}
		LibDBIcon:Register("ActionUI", ldbObject, TMW.db.global.ActionDB.minimap)
		LibDBIcon:Refresh("ActionUI", TMW.db.global.ActionDB.minimap)
		Action.Minimap = true 
		Action.ToggleMinimap()
	else
		Action.ToggleMinimap()
	end 
		
	-- Modified update engine of TMW core with additional FPS Optimization	
	if not Action.IsInitializedModifiedTMW and TMW then 
		local LastUpdate = 0
		local updateInProgress, shouldSafeUpdate
		local start 
		-- Assume in combat unless we find out otherwise.
		local inCombatLockdown = 1

		-- Limit in milliseconds for each OnUpdate cycle.
		local CoroutineLimit = 50
		
		TMW:RegisterEvent("UNIT_FLAGS", function(event, unit)
				if unit == "player" then
					inCombatLockdown = InCombatLockdown()
				end
		end)	
		
		local function checkYield()
				if inCombatLockdown and debugprofilestop() - start > CoroutineLimit then
					TMW:Debug("OnUpdate yielded early at %s", TMW.time)

					coroutine.yield()
				end
		end	
		
		-- This is the main update engine of TMW.
		local function OnUpdate()
			while true do
				TMW:UpdateGlobals()

				if updateInProgress then
					-- If the previous update cycle didn't finish (updateInProgress is still true)
					-- then we should enable safecalling icon updates in order to prevent catastrophic failure of the whole addon
					-- if only one icon or icon type is malfunctioning.
					if not shouldSafeUpdate then
						TMW:Debug("Update error detected. Switching to safe update mode!")
						shouldSafeUpdate = true
					end
				end
				updateInProgress = true
				
				TMW:Fire("TMW_ONUPDATE_PRE", TMW.time, TMW.Locked)
				-- FPS Optimization
				local FPS = Action.GetToggle(1, "FPS")
				if not FPS or FPS < 0 then 
					local Framerate = GetFramerate() or 0
					if Framerate > 0 and Framerate < 100 then
						FPS = (100 - Framerate) / 900
						if FPS < 0.04 then 
							FPS = 0.04
						end 
					else
						FPS = 0.03
					end					
				end 				
				TMW.UPD_INTV = FPS + 0.001					
			
				if LastUpdate <= TMW.time - TMW.UPD_INTV then
					LastUpdate = TMW.time
					if TMW.profilingEnabled and TellMeWhen_CpuProfileDialog:IsShown() then 
						TMW:CpuProfileReset()
					end 

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_PRE", TMW.time, TMW.Locked)
					
					if TMW.Locked then
						for i = 1, #TMW.GroupsToUpdate do
							-- GroupsToUpdate only contains groups with conditions
							local group = TMW.GroupsToUpdate[i]
							local ConditionObject = group.ConditionObject
							if ConditionObject and (ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < TMW.time) then
								ConditionObject:Check()

								if inCombatLockdown then checkYield() end
							end
						end
				
						if shouldSafeUpdate then
							for i = 1, #TMW.IconsToUpdate do
								local icon = TMW.IconsToUpdate[i]
								safecall(icon.Update, icon)
								if inCombatLockdown then checkYield() end
							end
						else
							for i = 1, #TMW.IconsToUpdate do
								--local icon = IconsToUpdate[i]
								TMW.IconsToUpdate[i]:Update()

								-- inCombatLockdown check here to avoid a function call.
								if inCombatLockdown then checkYield() end
							end
						end
					end

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_POST", TMW.time, TMW.Locked)
				end

				updateInProgress = nil
				
				if inCombatLockdown then checkYield() end

				TMW:Fire("TMW_ONUPDATE_POST", TMW.time, TMW.Locked)

				coroutine.yield()
			end
		end 

		local Coroutine 
		function TMW:OnUpdate()
			start = debugprofilestop()			
			
			if not Coroutine or coroutine.status(Coroutine) == "dead" then
				if Coroutine then
					TMW:Debug("Rebirthed OnUpdate coroutine at %s", TMW.time)
				end
				
				Coroutine = coroutine.create(OnUpdate)
			end
			
			assert(coroutine.resume(Coroutine))
		end

		local function UnlockExtremelyInterval(forced)
			if Action.IsInitialized or forced then 
				local PREV_INTERVAL = TMW.db.global.Interval 
				TMW.db.global.Interval = 0
				TMW:Update()
				TMW.db.global.Interval = PREV_INTERVAL
			end 
		end
		
		TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", function() UnlockExtremelyInterval(true) end) 
		
		local isIconEditorHooked
		hooksecurefunc(TMW, "LockToggle", function() 
			if not isIconEditorHooked then 
				TellMeWhen_IconEditor:HookScript("OnHide", function() 
					if TMW.Locked then 
						UnlockExtremelyInterval()						
					end 
				end)
				isIconEditorHooked = true
			end
			if TMW.Locked then 
				UnlockExtremelyInterval()
			end 			
		end)			
		
		-- Loading options 
		if TMW.Classes.Resizer_Generic == nil then 
			TMW:LoadOptions()
		end 		
		
		Action.IsInitializedModifiedTMW = true 
	end 
			
	-- Update ranks	and overwrite ID 
	Action.UpdateSpellBook()
	
	-- Make frames work able 
	Action.IsInitialized = true 	
	Action:PLAYER_SPECIALIZATION_CHANGED()
	TMW:Fire("TMW_ACTION_IS_INITIALIZED")
end

function Action:OnInitialize()		
	----------------------------------
	-- Register Slash Commands
	----------------------------------
	local function SlashCommands(input) 
		if not L then return end -- If we trying show UI before DB finished load locales 
		local profile = TMW.db:GetCurrentProfile()
		if not Action.Data.ProfileEnabled[profile] then 
			Action.Print(profile .. "  " .. L["NOSUPPORT"])
			return 
		end 
		if not input or #input > 0 then 
			-- without checks for another options for /action since right now only "help" enough even if user did wrong input 
			Action.Print(L["SLASH"]["LIST"])
			Action.Print("|cff00cc66/action|r - " .. L["SLASH"]["OPENCONFIGMENU"])
			Action.Print('|cff00cc66/run Action.MacroQueue("TABLE_NAME")|r - ' .. L["SLASH"]["QUEUEHOWTO"])
			Action.Print('|cff00cc66/run Action.MacroQueue("WordofGlory")|r - ' .. L["SLASH"]["QUEUEEXAMPLE"])		
			Action.Print('|cff00cc66/run Action.MacroBlocker("TABLE_NAME")|r - ' .. L["SLASH"]["BLOCKHOWTO"])
			Action.Print('|cff00cc66/run Action.MacroBlocker("FelRush")|r - ' .. L["SLASH"]["BLOCKEXAMPLE"])	
			Action.Print(L["SLASH"]["RIGHTCLICKGUIDANCE"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCE"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCEGLOBAL"])			
		else 
			Action.ToggleMainUI()
		end 
	end 	
	SLASH_ACTION1 = "/action"
	SlashCmdList.ACTION = SlashCommands	
	----------------------------------
	-- Register ActionDB defaults
	----------------------------------	
	local function OnSwap(event, profileEvent, arg2, arg3)
		-- Turn off everything 
		if Action.MainUI and Action.MainUI:IsShown() then 
			Action.ToggleMainUI()
		end
		Action.IsInitialized = nil
		-- ReTarget 
		Re:Reset()
		-- LOSInit 
		LineOfSight:Reset()
		-- LetMeCast 
		LETMECAST:Reset()
		-- AuraDuration
		AuraDuration:Reset()
		-- UnitHealthTool
		UnitHealthTool:Reset()
		-- ToggleMSG 
		Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
		Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")
		Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
		Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")	
		-- TMW has wrong condition which prevent run already running snippets and it cause issue to refresh same variables as example, so let's fix this 
		-- Note: Can cause issues if there loops, timers, frames or hooks 	
		if profileEvent == "OnProfileChanged" then
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMW.db.profile.CodeSnippets) do
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end			
		end 		
		OnInitialize()			
	end
	TMW:RegisterCallback("TMW_ON_PROFILE", OnSwap)
	TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", OnInitialize, "ACTION_TMW_SAFESETUP_COMPLETE")	
end