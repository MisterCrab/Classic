-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
--[[
If you plan to build profile without use lua then you can skip this guide
]]

-------------------------------------------------------------------------------
-- №1: Create snippet 
-------------------------------------------------------------------------------
--[[
Write in chat /tmw > LUA Snippets > Profile (left side) > "+" > Write name "ProfileUI" in title of the snippet
]]

-------------------------------------------------------------------------------
-- №2: Set profile defaults 
-------------------------------------------------------------------------------
-- Constances (wrriten in Constans.lua)

-- Map
local TMW = TMW 
local CNDT = TMW.CNDT 
local Env = CNDT.Env
local A = Action

-- This indicates to use 'The Action's all components and make it initializated for current profile 
A.Data.ProfileEnabled[TMW.db:GetCurrentProfile()] = true 

-------------------------------------------------------------------------------
-- №3: Create UI on 'The Action' for current profile 
-------------------------------------------------------------------------------
--[[ 
A.Data.ProfileUI is a table where you have to set UI elements with DB (DataBase) variables and their default presets. This table can be omitted however then [2] and [7] will display 'Profile has no configuration for this tab.' in /action
]]
-- Structure:
A.Data.ProfileUI = {	
	DateTime = "v0 (00.00.0000)", 	-- 'v' is version (Day, Month, Year)
	[tab.name] = {					-- supports [2] (spec tab), [7] (MSG tab) in /action
		[PLAYERSPEC] = {			-- is Constanse (look above, [ACTION_CONST_MONK_BREWMASTER], [ACTION_CONST_MONK_MISTWEAVER], [ACTION_CONST_MONK_WINDWALKER])
			-- Configure if [tab.name] is [2] (spec tab)			
			LayoutOptions = {},		-- (optional) is table which can be used to configure layout position
			{						-- {} brackets on this level will create one row 
				RowOptions = {},	-- (optional) is table which can be used to configure this (current) row position on your layout 
				{					-- {} brackets on this level will create one element 
					key = value,	-- is itself element config 
				},
			},
			-- Configure if [tab.name] is [7] (MSG tab)	
			["phrase"] = {			-- ["phrase"] - This is key which is string phase which will match a message written in /party chat. MUST BE IN LOWER CASE!
				key = value,		-- is itself ["phrase"] config 
			},
		},
	},
}

-- (optional) LayoutOptions and RowOptions Structure:
A.Data.ProfileUI = {	
	[2] = {
		[PLAYERSPEC] = {
			LayoutOptions = {
				columns = '@number', 	-- count of columns per row 
				gutter = '@number', 	-- indent between columns ( from 0 to columns )
				padding = { 			-- indent on [2] itself frame 
					top = '@number', 
					right = '@number', 
					left = '@number',
				},
			},
			{ -- row 
				RowOptions = {
					margin = { 			-- indent on current row for elements 
						top = '@number', 
						right = '@number', 
						left = '@number', 
						bottom = '@number',
					},
				}, 
			},
		},
	},
}

-- Element Structure:
A.Data.ProfileUI = {	
	[2] = {
		[PLAYERSPEC] = {
			{
				{
					E = "Label",
					L = {			
						-- Fixed LANGUAGE is short game language, like ["enUS"] , more info https://wowwiki.fandom.com/wiki/API_GetLocale . ["enUS"] key must be existed ALWAYS!! because if user hasn't localization it will use ["enUS"] key 
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced LANGUAGE, ANY is valid for any game language (usefully with GetSpellInfo)
						ANY = '@string',
					},
					S = '@string', 			-- font (text) size					
				},
				{
					E = "Header",
					L = {			
						-- Fixed
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced
						ANY = '@string',
					},
					S = '@string', 			-- font (text) size					
				},
				{
					E = "Button",
					L = {			
						-- Fixed 
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced
						ANY = '@string',
					},
					OnClick = function(self, button, down) 	-- 'self' is own frame button, 'button' is left or right mouse click event, 'down' state of that 
						-- your code here 
					end, 
					-- Optional:
					TT = {									-- tooltip		
						-- Fixed 
						[LANGUAGE] = '@string', 
						-- OR Forced
						ANY = '@string',
					},
					M = '@any' or nil, 						-- non-nill will display tooltip if it's empty about "Right Click to create macro"
					isDisabled = true or nil,
				},
				{
					E = "Checkbox",
					L = {			
						-- Fixed 
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced
						ANY = '@string',
					},
					DB = value,				-- name of key for SavedVariables in DataBase
					DBV = value,			-- default value if key wasn't existed before, it's also used for 'Reset Settings', supports @boolean @string @number
					-- Optional:
					TT = {					-- tooltip		
						-- Fixed 
						[LANGUAGE] = '@string', 
						-- OR Forced
						ANY = '@string',
					},
					M = { 					-- macros, if table exists (even without keys) it will unlock macro creation by right click on this element 
						-- Optional:
						Custom = "/run Action.ToggleTest()", -- using custom macro text to create by right click, all below is not valid if Custom key noted
						-- Otherwise it will structure like 
						-- /run Action.SetToggle({[tab.name], Action.Data.ProfileUI[tab.name][spec].DB, Action.Data.ProfileUI[tab.name][spec].L[CL] .. ": "}, Action.Data.ProfileUI[tab.name][spec].M.Value or nil)
						-- It does call func CraftMacro(L[CL], macro above, 1) -- 1 means perCharacter tab in MacroUI, if nil then will be used allCharacters tab in MacroUI
						Value = value or nil, 
						-- Very Very Optional, no idea why it will be need however.. 
						TabN = '@number' or nil,								
						Print = '@string' or nil,								
					},
					isDisabled = true or nil,
				},
				{
					E = "Dropdown",
					L = {			
						-- Fixed 
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced
						ANY = '@string',
					},
					DB = value,				-- name of key for SavedVariables in DataBase
					DBV = value,			-- default value from OT key if key wasn't existed before, it's also used for 'Reset Settings', supports @string
					-- Optional:
					TT = {					-- tooltip		
						-- Fixed 
						[LANGUAGE] = '@string', 
						-- OR Forced
						ANY = '@string',
					},
					M = {},					-- macros (same as on Checkbox)
					isDisabled = true or nil,					
					H = '@number',			-- height of element (default 20)
					OT = {					-- option table of menu
						{ text = '@string', value = 1 },	-- value must be @number if you use key MULT as true, otherwise it supports @string @number @boolean
						{ text = '@string', value = 2 },	
					},
					MULT = true or nil,		-- makes dropdown as multiselector
					isNotEqualVal = value, 	-- only if MULT is false or omitted, custom value of Dropdown which shouldn't be recorded into Cache, otherwise it's ~= "Off", ~= "OFF" and ~= 0
					SetPlaceholder = { 		-- only if MULT is true, default displayed value if nothing is not selected from menu 
						-- Only Fixed
						[LANGUAGE1] = '@string', 
					}, 
				},
				{
					E = "Slider",
					L = {			
						-- Fixed 
						[LANGUAGE1] = '@string', 
						[LANGUAGE2] = '@string',
						-- OR Forced
						ANY = '@string',
					},
					DB = value,				-- name of key for SavedVariables in DataBase
					DBV = '@number',		-- default value from OT key if key wasn't existed before, it's also used for 'Reset Settings', supports @number
					-- Optional:
					TT = {					-- tooltip		
						-- Fixed 
						[LANGUAGE] = '@string', 
						-- OR Forced
						ANY = '@string',
					},
					M = {},					-- macros (same as on Checkbox)				
					H = '@number',			-- height of element   (default 20)
					MIN = '@number',		-- min value on slider (default -1)
					MAX = '@number',		-- max value on slider (default 100)
					Precision = '@number', 	-- accuracy of slider move (default 2)
					-- One of the next keys:
					-- If one of them is noted then will makes Slider display OFF / AUTO text if it will reach as value to MIN / MAX 
					ONOFF = true,			-- makes to display OFF if value == MIN and AUTO if value == MAX 
					ONLYON = true,			-- makes to display only AUTO if value == MAX 
					ONLYOFF = true,			-- makes to display only OFF if value == MIN 
					-- Otherwise it will display just number
				},
			},
		},
	},
}

-- MSG Structure:
A.Data.ProfileUI = {	
	[7] = {
		[PLAYERSPEC] = {
			["phrase"] = {					-- ["phrase"] - This is key which is string phase which will match a message written in /party chat. MUST BE IN LOWER CASE!
				Enabled = true,
				Key = '@string',			-- is a key from A[PLAYERSPEC] table in your rotation lua snippet, you also can see this key in /action > [3] 'Actions' tab 
				-- Optional:
				LUA = '@string',			-- LUA code which should return true to react on message (has an embedded environment Action[Action.PlayerSpec]. so any what has after Action. or Action[Action.PlayerSpec]. no need to use, it's let's say easier will be attributed)	
				LUAVER = '@number',			-- This key helps to reset for current MSG default assigned LUA if version of LUA code is different than current user has
				Source = '@string',			-- who said "phrase", if same server then probably no need to add server name after name of speaker
			},
		},
	},
}	

-- Example:
A.Data.ProfileUI = {	
	DateTime = "v1.2a (01.01.2850)",
	[2] = {
		[ACTION_CONST_MONK_BREWMASTER] = { 						
			{
				{	
					E = "Header",
					L = { 
						enUS = "HEADER", 
						ruRU = "ЗАГОЛОВОК", 
					}, 
					S = 14,
				},
			},					
			{							
				{
					E = "Checkbox", 
					DB = "Feint",
					DBV = true,
					L = { 
						enUS = "Use Feint", 
						ruRU = "Использовать Фейнт", 
					}, 
					TT = { 
						enUS = "Enable to use", 
						ruRU = "Включает для использования", 
					}, 
					M = {},
				},
				{
					E = "Checkbox", 
					DB = "Shiv",
					DBV = false,
					L = { 
						enUS = "Enable Shiv", 
						ruRU = "Разблокировать шивку", 
					}, 
					TT = { 
						enUS = "Enable to use", 
						ruRU = "Включает для использования", 
					}, 
					M = {},
				},
			},
			{
				{
					E = "Dropdown", 														
					H = 20,
					OT = {
						{ text = "Leap", value = 1 },
						{ text = "Blink", value = 2 },
						{ text = "Portal", value = 3 }
					},
					MULT = true,
					--isNotEqualVal = *any*, -- only if MULT is false or omited 
					DB = "DropdownMult",
					DBV = {
						[1] = true,
						[2] = true,
						[3] = true,
					}, 
					SetPlaceholder = { 
						enUS = "-- DropdownMult --", 
						ruRU = "-- Выпадающий список --", 
					}, 
					L = { 
						enUS = "DropdownMult Config", 
						ruRU = "ВыпадающийСписок Конфиг", 
					}, 
					TT = { 
						enUS = "ToolTip Mult", 
						ruRU = "ТулТипа мульта", 
					}, 
					M = {},									
				},
				{
					E = "Checkbox", 
					DB = "CKnoMacro",
					DBV = true,
					L = { 
						enUS = "CKnoMacro", 
						ruRU = "ЧекБокс без макро", 
					}, 
					TT = { 
						enUS = "English ToolTip", 
						ruRU = "Русский тултип", 
					}, 
				},
			},
			{
				{
					E = "Checkbox", 
					DB = "ShortCK",
					DBV = true,
					L = { 
						enUS = "Short checkBox", 
						ruRU = "Короткий бокс", 
					}, 
				},
				{
					E = "Dropdown", 														
					H = 20,
					OT = {
						{ text = "Simcraft", value = "Simcraft" },
						{ text = "Custom", value = "Custom" },
						{ text = "Off", value = "Off" }
					},
					MULT = false,
					--isNotEqualVal = *any*, -- only if MULT is false or omited 
					DB = "DropdownSingle",
					DBV = "Simcraft",
					L = { 
						enUS = "Dropdown SINGLE", 
						ruRU = "Выпадающий ОДИНОЧ.", 
					}, 
					TT = { 
						enUS = "ToolTip SINGLE", 
						ruRU = "ТулТипа ОДИНОЧ.", 
					}, 
					M = {
						Custom = [[/run Toggle()]],
					},
				},
			},
			{
				{	
					E = "Label",
					L = { 
						enUS = "Label", 
						ruRU = "Метка", 
					}, 
				},							
				{
					E = "Slider", 													
					H = 20,
					MIN = -1, 
					MAX = 100,							
					DB = "Slidertoggle",
					DBV = 40,
					L = { 
						enUS = "Slider Example", 
						ruRU = "Ползунок Пример", 
					}, 
					TT = { 
						enUS = "Slider ToolTip", 
						ruRU = "Ползунок ТулТип", 
					}, 
					M = {
					},
				},
			},
			{
				{
					E = "LayoutSpace",
				},	
				{
					E = "Slider", 													
					H = 20,
					MIN = -1, 
					MAX = 100,							
					DB = "Sliderwithspace",
					DBV = 10,
					L = { 
						enUS = "Slider Example2", 
						ruRU = "Ползунок Пример2", 
					}, 
					TT = { 
						enUS = "Slider ToolTip222", 
						ruRU = "Ползунок ТулТип222", 
					}, 
					M = {
					},
				},							
			},
			{
				{
					E = "Checkbox", 
					DB = "ASDASD",
					DBV = true,
					L = { 
						enUS = "asdasd", 
						ruRU = "asdfsdfg", 
					},
				},
			},
		},
	},
	[7] = {
		[ACTION_CONST_MONK_BREWMASTER] = { 
			["shield"] = { Enabled = true, Key = "POWS", LUAVER = 1, LUA = [[
				-- thisunit is a special thing which will be replaced by string of unitID. Example: some one said phrase "shield party1" then thisunit will be replaced by "party1" and for this MSG will be used meta [7] which is Party1 Rotation which is A[7]()
				-- Confused? huh yeah but that's how it works, to make it easier you can simply set "target" right into this code as example if you want only "target", then SpellInRange("target", Action[PlayerSpec].POWS.ID) 
				-- More info in Action.lua 
				-- You have to keep in mind what once written in DataBase this code can't be changed if you made changes in ProfileUI, you have to use 'Reset Settings' and other people too if you failed here with code, so take attention on it. That's probably one lack of 'The Action' 
				return 	SpellInRange(thisunit, Action[PlayerSpec].POWS.ID) and -- we don't use TMW.CNDT.Env.SpellInRange because of embedded environment, same for PlayerSpec, but Action hasn't so we use it												
						Action[PlayerSpec].POWS:AbsentImun(thisunit) and 
						Action.LossOfControlIsMissed("SILENCE") and 
						LossOfControlGet("SCHOOL_INTERRUPT", "HOLY") == 0
			]] },
		},
	},
}

-- Misc: About ProfileDB (example)
-- A.Data.ProfileUI will create this A.Data.ProfileDB, you can set A.Data.ProfileDB like this instead point DB and DBV actually, but if both up then A.Data.ProfileUI will overwrite A.Data.ProfileDB
-- So don't take attention on it unless you need it for some purposes like visual comfort
A.Data.ProfileDB = {
	[2] = {
		[ACTION_CONST_MONK_BREWMASTER] = { 		
			Feint = true, 
			Shiv = false, 
			CKnoMacro = true,
			ShortCK = true,
			DropdownMult = {
				[1] = true,
				[2] = true,
				[3] = true,
			},
			DropdownSingle = "Simcraft",
			Slidertoggle = 40,
			Sliderwithspace = 10,
			Personalskhf = "unkas",
		},
	},
}

-------------------------------------------------------------------------------
-- №4: Use remain space for shared code between all specializations in profile 
-------------------------------------------------------------------------------
-- I prefer use here configuration for "Shown Cast Bars" because it's shared 
-- Example:
function A.Main_CastBars(unit, list)
	-- Is [1] -> [3] meta icons in "Shown CastBars", green (Heals) / red (PvP)
	if not A.IsInitialized or A.IamHealer or not A.IsInPvP then 
		return false 
	end 
	
	if A[A.PlayerSpec] and A[A.PlayerSpec].SpearHandStrike and A[A.PlayerSpec].SpearHandStrike:IsReadyP(unit, nil, true) and A[A.PlayerSpec].SpearHandStrike:AbsentImun(unit, {"KickImun", "TotalImun", "DamagePhysImun"}, true) and A.InterruptIsValid(unit, list) then 
		return true 		
	end 
end 

function A.Second_CastBars(unit)
	-- Is [1] -> [3] meta icons in "Shown CastBars", yellow
	if not A.IsInitialized or not A.IsInPvP then 
		return false 
	end 
	
	local Toggle = A.GetToggle(2, "ParalysisPvP")	
	if Toggle and Toggle ~= "OFF" and A[A.PlayerSpec] and A[A.PlayerSpec].Paralysis and A[A.PlayerSpec].Paralysis:IsReadyP(unit, nil, true) and A[A.PlayerSpec].Paralysis:AbsentImun(unit, {"CCTotalImun", "TotalImun", "DamagePhysImun"}, true) and A.Unit(unit):IsControlAble("incapacitate", 0) then 
		if Toggle == "BOTH" then 
			return select(2, A.InterruptIsValid(unit, "Heal", true)) or select(2, A.InterruptIsValid(unit, "PvP", true)) 
		else
			return select(2, A.InterruptIsValid(unit, Toggle, true)) 		
		end 
	end 
end 
-- Now add these functions in "Shown Cast Bars" group in /tmw by right click on each icon > Conditions > "+" > LUA > YOUR FUNCTION
-- return Action.Second_CastBars(thisobj.Unit) --or return Action.Second_CastBars("arena1")