function FindG(s)
	for k, v in pairs(_G) do 
		if type(s) == "string" and type(v) == "string" and v:lower():match(s:lower()) then 
			print(k .. " constain: " .. v)
		end 
		
		if type(s) == "number" and type(v) == "number" and s == v then 
			print(k .. " constain: " .. v)
		end 
	end 
end 