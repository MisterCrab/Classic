-------------------------------------------------------------------------------------------
-- PetLibrary is special written lib for The Action but can be used for any others
-- addons if will be replaced "A." and "TMW." API by regular provided from game 
-- The goal of this lib to provide pet functional which is not available by default 
-------------------------------------------------------------------------------------------
--[[ DOCUMENTATION:
This library seprated by 2 mainly parts, we will call them as: "API - Spells" and "API - Tracker"
API - Spell is used to create for player spec specified spells with action bar mapping mainly to reuse it for range checks 
API - Tracker is used to create and harvest some data on summoned / dead specified pets, here is possible to add own template. This method fires two callbacks for ADD and REMOVE 
Tracker has monitoring and maintance for counter, GUIDs but if you need to add or remove manually then you have to interract with it 

local Pet = LibStub("PetLibrary")
-- API - Spell
-- Example of create:
Pet:Add(252, {
	-- number accepted
	47482, -- Jump
	47481, -- Gnaw
	-- strings also accepted!
	"Gnaw",
	GetSpellInfo(47481),
})
-- Example of use:
/dump LibStub("PetLibrary"):IsInRange(47482, "target") 
/dump LibStub("PetLibrary"):GetMultiUnitsBySpell(47481)


-- API - Tracker 
-- Example of create:
Pet:InitializeTrackerFor("WARLOCK", { -- this template table is the same with what has this library already built-in, just for example
	[98035] = {
		name = "Dreadstalker",
		duration = 12.25,
	},
	[55659] = {
		name = "Wild Imp",
		duration = 20,
	},
	[143622] = {
		name = "Wild Imp",
		duration = 20,
	},
	[17252] = {
		name = "Felguard",
		duration = 28,
	},
	[135002] = {
		name = "Demonic Tyrant",
		duration = 15,
	},
})
-- Example of use:
/dump LibStub("PetLibrary"):GetRemainDuration(135002)
/dump LibStub("PetLibrary"):IsActive(135002)
/dump LibStub("PetLibrary"):GetMainPet()
-- Callbacks 
local PetTrackerData = Pet:GetTrackerData() -- this is table with [petID] = @table 
TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_REMOVED", function(callbackEvent, PetID, PetGUID)
	print("Removed " .. PetID .. ", GUID: " .. PetGUID)
end)
TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_ADDED", function(callbackEvent, PetID, PetGUID, PetData)
	-- PetData is a @table with next keys: name, duration, count, GUIDs 
	print("Added " .. PetID .. ", his name is " .. PetData.name .. ", GUID: " .. PetGUID)
	-- If we want to modify data we can 
	PetTrackerData.myVar = "custom data"
	print(PetTrackerData.myVar)
end)
]]

local TMW 								= TMW 
local A 								= Action
local Listener							= A.Listener
local Print								= A.Print
local Lib 								= LibStub:NewLibrary("PetLibrary", 4)

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_GetSpellInfo, ActiveNameplates
local TeamCache, TeamCacheFriendly, TeamCacheFriendlyUNITs

Listener:Add("ACTION_EVENT_PET_LIBRARY", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit							= A.Unit
		A_GetSpellInfo					= A.GetSpellInfo
		ActiveNameplates				= A.MultiUnits:GetActiveUnitPlates()
		
		TeamCache						= A.TeamCache
		TeamCacheFriendly				= TeamCache.Friendly
		TeamCacheFriendlyUNITs			= TeamCacheFriendly.UNITs
		
		Listener:Remove("ACTION_EVENT_PET_LIBRARY", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

local _G, type, next, pairs, setmetatable, print, string, tonumber, math =
	  _G, type, next, pairs, setmetatable, print, string, tonumber, math
	  
local wipe 								= _G.wipe	  
local strfind 							= string.find
local huge								= math.huge
local math_max							= math.max 

local  CreateFrame,    UIParent			= 
	_G.CreateFrame, _G.UIParent	  
	  
local IsSpellKnown, IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable, GetSpellInfo =
	  IsSpellKnown, IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable, GetSpellInfo	
	  
local CombatLogGetCurrentEventInfo		= CombatLogGetCurrentEventInfo	 
local UnitGUID							= UnitGUID 
local UnitName							= UnitName	  

local Frame = CreateFrame("Frame", nil, UIParent)

local function GetGUID(unitID)
	return (unitID and TeamCacheFriendlyUNITs[unitID]) or UnitGUID(unitID)
end 
	  
local function ConvertGUIDtoNPCID(GUID)
	if A_Unit then 
		local _, _, _, _, _, npc_id = A_Unit():InfoGUID(GUID) -- A_Unit() because no unitID 
		return npc_id
	else
		local _, _, _, _, _, _, _, NPCID = strfind(GUID, "(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)")
		return NPCID and tonumber(NPCID)
	end 
end 	  

local function GetInfoSpell(spellID)
	return (A_GetSpellInfo and A_GetSpellInfo(spellID)) or GetSpellInfo(spellID)
end 

local function ChatPrint(...)
	if Print then 
		Print(...)
	else 
		print(...)
	end 
end  	  

local Pet 								= {
	-- Spells 
	Data								= {},
	NameErrors							= setmetatable({}, { __mode = "kv" }),
	UpdateSlots							= function(self)
		local display_error    
		
		if self.Data[A.PlayerClass] then 
			for k, v in pairs(self.Data[A.PlayerClass]) do            
				if v == 0 then 
					for i = 1, 120 do 
						actionType, id, subType = GetActionInfo(i)
						if id and subType == "pet" and k == (type(k) == "number" and id or GetInfoSpell(id)) then 
							self.Data[A.PlayerClass][k] = i 
							break 
						end 
						
						if i == 120 then 
							display_error = true
						end 
					end
				end
			end       
		end 
		
		-- Display errors 
		if display_error and TMW.time - (self.LastEvent or 0) > 0.1 then 
			wipe(self.NameErrors)			
			ChatPrint("The following Pet spells are missed on your action bar:")
			
			-- ChatPrint("Note: Don't use PetActionBar, you need place following Pet spells on default (Player) action bar")
			for k, v in pairs(self.Data[A.PlayerClass]) do          
				if v == 0 then 
					local Name, KeyName 
					if type(k) ~= "string" then
						KeyName = GetInfoSpell(k)
						Name = KeyName or k
					else 
						KeyName = k
						Name = k
					end 
					
					if Name and not self.NameErrors[KeyName] then
						self.NameErrors[KeyName] = true 
						ChatPrint(Name .. " is not found on Player action bar!")
					end 
				end  				
			end 
		end 
		
		self.LastEvent = TMW.time 	
	end,
	RemoveFromData						= function(self, class, petSpells)
		if not petSpells then 
			self.Data[class] = nil 
			self.OnEvent()
		elseif self.Data[class] then 
			for i = 1, #petSpells do 
				self.Data[class][petSpells[i]] = nil
				if type(petSpells[i]) == "number" then 
					self.Data[class][GetInfoSpell(petSpells[i])] = nil 
				end 
			end 
		end 
	end, 
	AddToData							= function(self, class, petSpells)
		if not self.Data[class] then 
			self.Data[class] = {}
		end 
		
		if type(petSpells) == "table" then 
			for i = 1, #petSpells do 
				-- Creates empty action slot firstly 
				self.Data[class][petSpells[i]] = 0
				if type(petSpells[i]) == "number" then 
					self.Data[class][GetInfoSpell(petSpells[i])] = 0 
				end 
			end 
		else
			-- Creates empty action slot firstly 
			self.Data[class][petSpells] = 0
			if type(petSpells) == "number" then 
				self.Data[class][GetInfoSpell(petSpells)] = 0 
			end 
		end 

		if not self.CallbackIsInitialized then 
			--TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 		self.OnEvent) 
			TMW:RegisterCallback("TMW_ACTION_ENTERING", 							self.OnEvent) 
			TMW:RegisterCallback("TMW_ACTION_RANK_SPELLS_UPGRADED", 				function() Pet:UpdateSlots() end) 
			self.CallbackIsInitialized = true 
		end 
	end,
	-- Tracker
	MainGUID							= "",
	CanUseTemplate						= {
		["HUNTER"] 		= {},
		["WARLOCK"] 	= {},
	},
	TrackerData 						= {}, 
	TrackerGUID							= {}, 
	AddToTrackerData					= function(self, class, customTemplate)
		if not self.CanUseTemplate[class] then 
			self.CanUseTemplate[class] = {}
		end 				
		
		if type(customTemplate) == "table" then 
			wipe(self.CanUseTemplate[class])
			for k, v in pairs(customTemplate) do 
				self.CanUseTemplate[class][k] = v
			end 
		end 			
		
		if not self.TrackerCallbackIsInitialized then 
			--TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 		self.OnEventTracker)
			TMW:RegisterCallback("TMW_ACTION_ENTERING", 							self.OnEventTracker)
			self.TrackerCallbackIsInitialized = true
		end 			
		
		self.CanUseTemplate[class].enabled = true 
	end, 
	RemoveFromTrackerData				= function(self, class)
		if self.CanUseTemplate[class] then 
			Frame:SetScript("OnUpdate", nil)
			Frame.IsRunning = nil 	
			for k, v in pairs(self.TrackerData) do 
				-- Fires every removed GUID
				for guid in pairs(v.GUIDs) do 
					TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", k, guid)
				end 					
			end 
			wipe(self.TrackerData)
			wipe(self.TrackerGUID)
			self.CanUseTemplate[class].enabled = nil 		
			self.OnEventTracker()			
		end 
	end,
	OnEventCLEU							= {
		["UNIT_DIED"] 		= "Remove",
		["UNIT_DESTROYED"] 	= "Remove",
		["UNIT_DISSIPATES"] = "Remove",
		["PARTY_KILL"] 		= "Remove",
		["SPELL_INSTAKILL"] = "Remove",		
		["SPELL_SUMMON"] 	= "Add",
	},
}

local PetData							= Pet.Data
local PetTrackerData					= Pet.TrackerData
local PetTrackerGUID					= Pet.TrackerGUID
local PetCanUseTemplate					= Pet.CanUseTemplate
local PetOnEventCLEU					= Pet.OnEventCLEU

-------------------------------------------------------------------------------
-- Locals - Spells 
-------------------------------------------------------------------------------
Pet.UNIT_PET							= function(...)
    if TMW.time ~= Pet.LastEvent and PetData[A.PlayerClass] and (... == "player" or ... == "pet") and Lib:IsActive(nil, nil, true) then     
        for _, v in pairs(PetData[A.PlayerClass]) do
            if v == 0 then 
                Pet:UpdateSlots()
                break
            end
        end                 
    end 
end 

Pet.ACTIONBAR_SLOT_CHANGED				= function(...)    
    if TMW.time ~= Pet.LastEvent and PetData[A.PlayerClass] and Lib:IsActive(nil, nil, true) then
		local UseUpdate
		
        for k, v in pairs(PetData[A.PlayerClass]) do
            if v == 0 or v == ... then 
                PetData[A.PlayerClass][k] = 0
                UseUpdate = true 
            end
        end        
		
        if UseUpdate then 
            Pet:UpdateSlots()
        end
    end
end 

Pet.OnEvent 							= function()
	if PetData[A.PlayerClass] then 
		Listener:Add("ACTION_EVENT_PET_LIBRARY", "UNIT_PET", 						Pet.UNIT_PET)
		Listener:Add("ACTION_EVENT_PET_LIBRARY", "ACTIONBAR_SLOT_CHANGED", 			Pet.ACTIONBAR_SLOT_CHANGED)
		-- ACTIONBAR_PAGE_CHANGED
		--Pet:UpdateSlots()
	else 
		Listener:Remove("ACTION_EVENT_PET_LIBRARY", "UNIT_PET")
		Listener:Remove("ACTION_EVENT_PET_LIBRARY", "ACTIONBAR_SLOT_CHANGED")
		-- ACTIONBAR_PAGE_CHANGED
	end 	
end

-------------------------------------------------------------------------------
-- Locals - Tracker 
-------------------------------------------------------------------------------
local function OnUpdateTracker(self, elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
	if self.TimeSinceLastUpdate > 1 then 	
		local PetID, pData = next(PetTrackerData)	
		
		if not PetID or (pData.isMain and not next(PetTrackerData, PetID)) then 
			self:SetScript("OnUpdate", nil)
			self.IsRunning = nil 
			return 
		end 			
			
		local wasRemoved	
		while PetID ~= nil do
			if not pData.isMain then
				for PetGUID, DataGUID in pairs(pData.GUIDs) do 
					if (DataGUID.expiration == huge and TMW.time - DataGUID.updated > 4) or DataGUID.expiration - TMW.time <= 0 then 
						PetTrackerGUID[PetGUID] 		= nil
						if pData.count > 1 then 
							-- Erase keys from tables
							pData.count 				= pData.count - 1
							pData.GUIDs[PetGUID] 		= nil 
							-- Erase table from memory 
							DataGUID					= nil 							
						else 
							-- Erase keys from tables
							PetTrackerData[PetID] 		= nil
							-- Erase table from memory 
							pData						= nil 
							-- To pass break loop and repeat while by 'next'
							wasRemoved 					= true 
						end 
						
						-- Fire callback 
						TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", PetID, PetGUID)

						if wasRemoved then 
							wasRemoved = nil 
							break 
						end 
					end 
				end 	 
			end 
			
			PetID, pData = next(PetTrackerData, PetID)
		end 

		self.TimeSinceLastUpdate = 0
	end 
end 

local function ClearMainPet()
	for k, v in pairs(PetTrackerData) do 
		if v.isMain then 		
			-- Erase static 
			Pet.MainGUID 				= nil 
			local petGUID 				= v.isMain
			-- Erase keys from tables  
			PetTrackerGUID[petGUID] 	= nil
			PetTrackerData[k] 			= nil 
			-- Erase table from memory 
			v 							= nil 
			TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", k, petGUID)
			break 
		end 
	end 
end 

local function AddPetToTracker(PetID, PetGUID, PetName)
	local foundMainPet 					
	if PetGUID == UnitGUID("pet") then 
		foundMainPet = true 
		ClearMainPet()
	end 
	
	if not PetTrackerData[PetID] then 
		PetTrackerData[PetID] = { count = 0, GUIDs = {} }
	end 
	
	PetTrackerData[PetID].name 				= (PetCanUseTemplate[A.PlayerClass][PetID] and PetCanUseTemplate[A.PlayerClass][PetID].name) 	 or PetName or (foundMainPet and UnitName("pet"))
	PetTrackerData[PetID].duration 			= (PetCanUseTemplate[A.PlayerClass][PetID] and PetCanUseTemplate[A.PlayerClass][PetID].duration) or huge
	PetTrackerData[PetID].count				= (foundMainPet and 1) or PetTrackerData[PetID].count + 1
	PetTrackerData[PetID].GUIDs[PetGUID]	= { 
		updated			= TMW.time, 
		start 			= TMW.time, 
		expiration		= TMW.time + PetTrackerData[PetID].duration,
	}

	if foundMainPet then 
		PetTrackerData[PetID].isMain 		= PetGUID -- Primary @pet has always unique ID and can't have copies, here is will be noted GUID to re-use it for reset
		Pet.MainGUID 						= PetGUID 
	end 
	
	PetTrackerGUID[PetGUID]					= PetID
	if not Frame.IsRunning and not PetTrackerData[PetID].isMain then 
		Frame:SetScript("OnUpdate", OnUpdateTracker)
		Frame.IsRunning = true 
	end 
	
	TMW:Fire("TMW_ACTION_PET_LIBRARY_ADDED", PetID, PetGUID, PetTrackerData[PetID])
end 

Pet.COMBAT_LOG_EVENT_UNFILTERED			= function(...)
	if PetCanUseTemplate[A.PlayerClass] and PetCanUseTemplate[A.PlayerClass].enabled then 
		local _, Event, _, SourceGUID, _, _, _, DestGUID, DestName = CombatLogGetCurrentEventInfo()		
		if SourceGUID and SourceGUID ~= Pet.MainGUID and PetTrackerGUID[SourceGUID] and PetTrackerData[PetTrackerGUID[SourceGUID]] then 
			PetTrackerData[PetTrackerGUID[SourceGUID]].GUIDs[SourceGUID].updated = TMW.time 
		end 
		
		if DestGUID and DestGUID ~= Pet.MainGUID then 
			if PetTrackerGUID[DestGUID] and PetTrackerData[PetTrackerGUID[DestGUID]] then 
				PetTrackerData[PetTrackerGUID[DestGUID]].GUIDs[DestGUID].updated = TMW.time 
			end 
		
			local SubEvent = PetOnEventCLEU[Event]
			if SubEvent == "Remove" and PetTrackerGUID[DestGUID] then  
				local PetID 					= PetTrackerGUID[DestGUID]
				PetTrackerGUID[DestGUID] 		= nil 
				
				if not PetTrackerData[PetID].isMain and PetTrackerData[PetID].count > 1 then 
					PetTrackerData[PetID].count = PetTrackerData[PetID].count - 1
					PetTrackerData[PetID].GUIDs[DestGUID] = nil 
				else  
					PetTrackerData[PetID] = nil 
				end 

				TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", PetID, DestGUID)					 
			elseif SubEvent == "Add" and SourceGUID == GetGUID("player") then 
				local PetID = ConvertGUIDtoNPCID(DestGUID)
				
				if PetID then 		
					AddPetToTracker(PetID, DestGUID, DestName)
				end 
			end 
		end		
	end 
end 

Pet.UNIT_PET_TRACKER					= function(...)
	if PetCanUseTemplate[A.PlayerClass] and PetCanUseTemplate[A.PlayerClass].enabled then 
		local unitID = ...
		if unitID == "player" or unitID == "pet" then 
			if Lib:IsActive(nil, nil, true) then 
				local PetGUID = UnitGUID("pet")
				if PetGUID and PetGUID ~= Pet.MainGUID then 
					local PetID = ConvertGUIDtoNPCID(PetGUID)
					if PetID then 
						AddPetToTracker(PetID, PetGUID)
					end 
				end 
			else
				ClearMainPet()
			end 
		end 
	end 
end 

--local callback_c = 0
Pet.OnEventTracker						= function(event)
	--[[ ByPass Action API (no need for Classic)
	if event == "TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED" and callback_c < 3 then 
		callback_c = callback_c + 1
		return 
	end ]]

	-- Reset old pets 
	Frame:SetScript("OnUpdate", nil)
	Frame.IsRunning = nil 	
	wipe(PetTrackerGUID)
	for k, v in pairs(PetTrackerData) do 		
		-- Erase keys from tables  
		PetTrackerData[k] 			= nil 
		-- Fires every removed GUID
		for guid in pairs(v.GUIDs) do 
			TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", k, guid)
		end 					
		-- Erase table from memory 
		v 							= nil 			
	end 
		
	if PetCanUseTemplate[A.PlayerClass] and PetCanUseTemplate[A.PlayerClass].enabled then 
		Listener:Add(	"ACTION_EVENT_PET_LIBRARY_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED", 	Pet.COMBAT_LOG_EVENT_UNFILTERED)
		Listener:Add(	"ACTION_EVENT_PET_LIBRARY_TRACKER", "UNIT_PET", 					Pet.UNIT_PET_TRACKER)
		if Lib:IsActive(nil, nil, true) then 
			local PetGUID = UnitGUID("pet")
			if PetGUID then 
				local PetID = ConvertGUIDtoNPCID(PetGUID)
				if PetID then 
					AddPetToTracker(PetID, PetGUID)
				end 
			end 
		end 
	else 
		Listener:Remove("ACTION_EVENT_PET_LIBRARY_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED")
		Listener:Remove("ACTION_EVENT_PET_LIBRARY_TRACKER", "UNIT_PET")
	end 
end 

-------------------------------------------------------------------------------
-- Locals - Shared 
-------------------------------------------------------------------------------
Pet.UNIT_FLAGS							= function(...)
	if ... == "pet" then 
		Pet.IsMainDead = not UnitIsDeadOrGhost(...)
		if Pet.IsMainDead and next(PetTrackerData) then 
			ClearMainPet()
		end 
	end 
end 
Listener:Add("ACTION_EVENT_PET_LIBRARY", "UNIT_FLAGS", 								Pet.UNIT_FLAGS)

-------------------------------------------------------------------------------
-- API - Spells 
-------------------------------------------------------------------------------
-- Note: Library accepts spellName and spellID, if specified spellName then only string will be performed otherwise both spellID and spellName 
-- Note: petSpell can be table {123, 124} or {123, "spellName", spellID} 

function Lib:Add(class, petSpells)
	-- Adds to track specified spells for noted player class 
	Pet:AddToData(class, petSpells)
end 

function Lib:Remove(class, petSpells)
	-- Removes from tracking specified spells or full spec with all spells 
	Pet:RemoveFromData(class, petSpells)
end 

function Lib:GetSlotHolder(spell)
	-- @return number (slot, 0 if not found)
	return PetData[A.PlayerClass] and PetData[A.PlayerClass][spell]
end 

function Lib:GetData()
	-- @return table or nil 
	return PetData[A.PlayerClass]
end 

function Lib:IsInRange(spell, unitID)
	-- @return boolean
	if PetData[A.PlayerClass] then 
		local ActionBar = PetData[A.PlayerClass][spell] or (type(spell) == "number" and PetData[A.PlayerClass][GetInfoSpell(spell)])
		return ActionBar and ActionBar > 0 and IsActionInRange(ActionBar, unitID or "target")
	--else 
		--ChatPrint("[Error] PetLibrary - " .. GetInfoSpell(spell) .. " is not registered")
	end 
end 

function Lib:IsSpellKnown(spell)
	-- @return boolean 
	return IsSpellKnown(spell, true) or (type(spell) == "number" and IsSpellKnown(GetInfoSpell(spell), true)) -- PetData[A.PlayerClass] and PetData[A.PlayerClass][spell] or 
end 

function Lib:GetMultiUnitsBySpell(petSpell, units)
	-- @return number (of total units in range by petSpell, if 'units' is ommited then will take summary units)
    local total = 0 
    if ActiveNameplates then 
        for unit in pairs(ActiveNameplates) do
            if type(petSpell) == "table" then
                for i = 1, #petSpell do
                    if self:IsInRange(petSpell[i], unit) then
                        total = total + 1  
                        break
                    end
                end
            elseif self:IsInRange(petSpell, unit) then 
                total = total + 1                                            
            end  
            
            if units and total >= units then
                break                        
            end     
        end
    end 
	
    return total 	
end 

-------------------------------------------------------------------------------
-- API - Shared 
-------------------------------------------------------------------------------
function Lib:IsActive(petID, petName, skipIsDead)
	-- @return boolean 
	if skipIsDead or not Pet.IsMainDead then 
		if petID or petName then 
			return self:GetCount(petID, petName) > 0
		else 
			return PetHasActionBar() or GetPetActionsUsable()
		end 
	end 
end 

-------------------------------------------------------------------------------
-- API - Tracker 
-------------------------------------------------------------------------------
function Lib:InitializeTrackerFor(class, customTemplate)
	-- Initializes tracker for petIDs and their info 
	-- Note: Once added customTemplate (@table) can't be restored back to default template
	-- customTemplate accepts main key with subkeys [petID (@number)] = { "name" = @string, "duration" = @number }
	if not PetCanUseTemplate[class] and not customTemplate then 
		ChatPrint(class .. " can't initialize pet tracker because it's not listed as available class")
		return 
	end 
	Pet:AddToTrackerData(class, customTemplate)
end 

function Lib:UninitializeTrackerFor(class)
	-- Uninitializes tracker for petIDs and their info 
	Pet:RemoveFromTrackerData(class)
end 

function Lib:GetTrackerData()
	-- @return table 
	return PetTrackerData
end 

function Lib:GetMainPet()
	-- @return table or nil 
	-- Note: table is not static and not re-useable! 
	for _, v in pairs(PetTrackerData) do
		if v.isMain then 
			return v
		end 
	end 
end 

function Lib:GetRemainDuration(petID, petName, operator)
	-- @return number 
	-- Note: Only if template has "duration" key otherwise it's huge 
	local total = 0
	
	if petName then 
		for _, v in pairs(PetTrackerData) do
			if v.name == petName then 
				for _, data in pairs(v.GUIDs) do 					
					local duration = math_max(data.expiration - TMW.time, 0)
					if operator == "<" then 
						if duration > 0 and (total == 0 or duration < total) then 
							total = duration
						end 						
					else 
						if duration > total then 
							total = duration
						end
					end 
				end 
				
				break 
			end 
		end 
		
		if total > 0 then 
			return total 
		end 
	end 
	
	if petID and PetTrackerData[petID] then 
		for _, data in pairs(PetTrackerData[petID].GUIDs) do 
			local duration = math_max(data.expiration - TMW.time, 0)
			if operator == "<" then 
				if duration > 0 and (total == 0 or duration < total) then 
					total = duration
				end 						
			else 
				if duration > total then 
					total = duration
				end
			end 
		end 
	end 
	
	return total 
end 

function Lib:GetCount(petID, petName)
	-- @return number 
	-- Note: Number of active pets
	if petName then 
		for _, v in pairs(PetTrackerData) do
			if v.name == petName and v.count > 0 then 
				return v.count
			end 			 
		end
	end 
	
	if petID then 
		return (PetTrackerData[petID] and PetTrackerData[petID].count) or 0 
	end 
	
	return 0
end