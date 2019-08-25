-------------------------------------------------------------------------------------------
-- PetLibrary is special written lib for The Action but can be used for any others
-- addons if will be replaced "A." and "TMW." API by regular provided from game 
-- The goal of this lib to provide range check functional which is not available by default 
-- TODO: Also pet template spell managment (Warlock, Hunter) 
-------------------------------------------------------------------------------------------
local TMW 								= TMW 
local A 								= Action 
local Lib 								= LibStub:NewLibrary("PetLibrary", 3)

--local strlowerCache  					= TMW.strlowerCache
--local isEnemy							= A.Bit.isEnemy
--local isPlayer						= A.Bit.isPlayer
--local toStr 							= A.toStr
--local toNum 							= A.toNum

local type, pairs						=
	  type, pairs
	  
local IsSpellKnown, IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable =
	  IsSpellKnown, IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable	  

local Pet 								= {
	Data								= {},
	LastEvent 							= 0,
	UpdateSlots							= function(self)
		local display_error    
		
		if self.Data[A.PlayerSpec] then 
			for k, v in pairs(self.Data[A.PlayerSpec]) do            
				if v == 0 then 
					for i = 1, 120 do 
						actionType, id, subType = GetActionInfo(i)
						if id and subType == "pet" and k == (type(k) == "number" and id or A.GetSpellInfo(id)) then 
							self.Data[A.PlayerSpec][k] = i 
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
		if display_error and TMW.time - self.LastEvent > 0.1 then 
			A.Print("The following Pet spells are missed on your action bar:")
			-- A.Print("Note: Don't use PetActionBar, you need place following Pet spells on default (Player) action bar")
			for k, v in pairs(self.Data[A.PlayerSpec]) do
				if v == 0 and type(k) == "string" then
					A.Print(A.GetSpellLink(k) .. " is not found on Player action bar!")
				end                
			end 
		end 
		self.LastEvent = TMW.time 	
	end,
	RemoveFromData						= function(self, specID, petSpells)
		if not petSpells then 
			self.Data[specID] = nil 
		elseif self.Data[specID] then 
			for i = 1, #petSpells do 
				self.Data[specID][petSpells[i]] = nil
				if type(petSpells[i]) == "number" then 
					self.Data[specID][A.GetSpellInfo(petSpells[i])] = nil 
				end 
			end 
		end 
	end, 
	AddToData							= function(self, specID, petSpells)
		if not self.Data[specID] then 
			self.Data[specID] = {}
		end 
		
		if type(petSpells) == "table" then 
			for i = 1, #petSpells do 
				-- Creates empty action slot firstly 
				self.Data[specID][petSpells[i]] = 0
				if type(petSpells[i]) == "number" then 
					self.Data[specID][A.GetSpellInfo(petSpells[i])] = 0 
				end 
			end 
		else
			-- Creates empty action slot firstly 
			self.Data[specID][petSpells] = 0
			if type(petSpells) == "number" then 
				self.Data[specID][A.GetSpellInfo(petSpells)] = 0 
			end 
		end 
		
		A.Listener:Add("ACTION_EVENT_PET_LIBRARY", "PLAYER_ENTERING_WORLD", 		self.OnEvent)
		A.Listener:Add("ACTION_EVENT_PET_LIBRARY", "UPDATE_INSTANCE_INFO", 			self.OnEvent)
		A.Listener:Add("ACTION_EVENT_PET_LIBRARY", "PLAYER_SPECIALIZATION_CHANGED", self.OnEvent)
		self:UpdateSlots()
	end,
}

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
Pet.UNIT_PET							= function(...)
    if Pet.Data[A.PlayerSpec] and ... == "player" and Lib:IsActive() and TMW.time ~= Pet.LastEvent then     
        for k, v in pairs(Pet.Data[A.PlayerSpec]) do
            if v == 0 then 
                Pet:UpdateSlots()
                break
            end
        end                 
    end 
end 

Pet.ACTIONBAR_SLOT_CHANGED				= function(...)    
    if Pet.Data[A.PlayerSpec] and Lib:IsActive() and TMW.time ~= Pet.LastEvent then
		local UseUpdate
		
        for k, v in pairs(Pet.Data[A.PlayerSpec]) do
            if v == 0 or v == ... then 
                Pet.Data[A.PlayerSpec][k] = 0
                UseUpdate = true 
            end
        end        
		
        if UseUpdate then 
            Pet:UpdateSlots()
        end
    end
end 

Pet.OnEvent 							= function(...)
	if Pet.Data[A.PlayerSpec] then 
		A.Listener:Add("ACTION_EVENT_PET_LIBRARY", "UNIT_PET", 						Pet.UNIT_PET)
		A.Listener:Add("ACTION_EVENT_PET_LIBRARY", "ACTIONBAR_SLOT_CHANGED", 		Pet.ACTIONBAR_SLOT_CHANGED)
		-- ACTIONBAR_PAGE_CHANGED
		Pet:UpdateSlots()
	else 
		A.Listener:Remove("ACTION_EVENT_PET_LIBRARY", "UNIT_PET")
		A.Listener:Remove("ACTION_EVENT_PET_LIBRARY", "ACTIONBAR_SLOT_CHANGED")
		-- ACTIONBAR_PAGE_CHANGED
	end 	
end

-------------------------------------------------------------------------------
-- API 
-------------------------------------------------------------------------------
function Lib:Add(specID, petSpells)
	-- Adds to track specified spells for noted specID 
	Pet:AddToData(specID, petSpells)
end 

function Lib:Remove(specID, petSpells)
	-- Removes from tracking specified spells or full spec with all spells 
	Pet:RemoveFromData(specID, petSpells)
end 

function Lib:IsInRange(spell, unitID)
	-- @return boolean
	if Pet.Data[A.PlayerSpec] then 
		local ActionBar = Pet.Data[A.PlayerSpec][spell] or (type(spell) == "number" and Pet.Data[A.PlayerSpec][A.GetSpellInfo(spell)])
		return ActionBar and ActionBar > 0 and IsActionInRange(ActionBar, unitID or "target")
	--else 
		--A.Print("[Error] PetLibrary - " .. A.GetSpellLink(spell) .. " is not registered")
	end 
end 

function Lib:IsSpellKnown(spell)
	-- @return boolean 
	return Pet.Data[A.PlayerSpec] and Pet.Data[A.PlayerSpec][spell] or IsSpellKnown(spell, true)
end 

function Lib:GetMultiUnitsBySpell(petSpell, units)
	-- @return number (of total units in range by petSpell, if 'units' is ommited then will take summary units)
	-- Note: petSpell can be table {123, 124} which will be queried 
    local UnitPlates = A.MultiUnits:GetActiveUnitPlates()
    local total = 0 
    if UnitPlates then 
        for reference, unit in pairs(UnitPlates) do
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

function Lib:IsActive(petID)
	-- TODO: petID for Hunters and Warlocks 
	return PetHasActionBar() or GetPetActionsUsable()
end 