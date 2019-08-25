local TMW 									= TMW
local GetSpellTexture						= TMW.GetSpellTexture

local A 									= Action
local GetSpellInfo							= A.GetSpellInfo
local print 								= A.Print

local GetSpellSubtext, GetSpellBaseCooldown	= 
	  GetSpellSubtext. GetSpellBaseCooldown

-- Classic version
function ClassicTriggerGCD()
	TMW.db.global.TriggerGCD = nil
	local temp = {}
	for i = 1, 900000 do 
		local spellName, _, spellTexture, _, _, _, spellID = GetSpellInfo(i)
		if spellName and spellID == i and GetSpellTexture(spellID) then 
			local isPlayerSpell = GetSpellSubtext(spellID)
			if isPlayerSpell and isPlayerSpell ~= "" then 
				local base, baseGCD = GetSpellBaseCooldown(spellID)
				if base and baseGCD then 
					temp[spellID] = baseGCD
				end 
			end 
		end 
	end 
	
	TMW.db.global.TriggerGCD = temp
	print("TriggerGCD updated!")
end 