


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

local Mouse = _G.Player:GetMouse()
local ctors = {}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["getctors"] = {
	
	var = function()
		
		for n in pairs(module) do
			
			if n:match("^ctor_") then
				
				table.insert(ctors, tostring(n:gsub("ctor_", "")))
			end
		end
	end,
	
	startup = true
}

module["process"] = {
	
	var = function(params, args, var)
		
		local order = {"EnumItem", "boolean", "number", "string"}
		
		-- Main function
		local function process(i, types)
			
			-- Missing argument
			if args[i] == nil then return var end
			
			-- nil argument (function cvars only)
			if module["type_nil"].var(args[i]) == nil then return nil end
			
			-- Command variable
			local cvar, val = _G.dir.con.query.var(nil, args[i]:gsub("^%!", ""):split("."), 1, true)
			local value if val then value = cvar.var[val] elseif cvar then value = cvar.var end -- cuz value could be false
			if value ~= nil and type(value) ~= "table" and type(value) ~= "function" then
				
				local trueArg = (args[i]:match("^%!") or "")..module["type_"..typeof(value)].str(value)
				if table.find(order, typeof(value)) then
					
					args[i] = trueArg
				else return module["type_"..typeof(value)].var(var, trueArg) end
			end
			
			-- Constructor argument
			local function autoCtor()
				
				local found
				for i = 1, #types do
					
					if table.find(ctors, types[i]) then
						
						if found == nil then found = types[i] else return "" end
					end
				end
				
				return found or ""
			end
			
			local ctor, ctorargs = module.processCtor(args[i])
			if ctor then
				
				ctor[3] = ctor[1] ~= "" and module["ctor_"..ctor[1]] or ctor[1] == "" and module["ctor_"..autoCtor()] or nil
				ctor[2] = ctor[3] and ctor[3].var[ctor[2]] or nil
				if ctor[2] then -- If ctor was valid
					
					return module["type_"..(ctor[1] ~= "" and ctor[1] or autoCtor())].var(var, ctor[2](unpack(ctorargs)))
				end
			end
			
			-- Data types
			for t = 1, #order do
				
				local blah = module["type_"..order[t]].var(var, args[i], types)
				if blah ~= var then return blah end
			end
			
			-- Unrecognized type (process as string)
			return module["type_string"].var(var, args[i], true)
		end
		
		-- Process params
		params = params and params:gsub(" ", ""):gsub("%(", ""):gsub("%)", ""):gsub("%w+:", ""):gsub("?", "|nil"):split(",") or {}
		
		-- Process args
		local processed = {}
		for i = 1, #params do
			
			-- Justify parameters
			local types = params[i]:split("|")
			if types["any"] then types = {"any"} end -- 'any' means any datatype can be used (function cvars only)
			
			-- Process args
			processed[i] = process(i, types)
			local dtype = typeof(processed[i]) dtype = dtype == "EnumItem" and _G.dir.con.autofill.enumTostring(processed[i]) or dtype
			
			-- Type checking
			if table.find(types, dtype) or table.find(types, "any") then else
				
				processed[i] = table.find(types, "string") and dtype ~= "nil" and tostring(processed[i]) or var
			end
		end
		
		return processed
	end
}

module["type_nil"] = {
	
	var = function(arg)
		
		if arg == "nil" or arg == "_" then
			
			return nil
		end
		
		return true
	end
}

module["type_boolean"] = {
	
	var = function(var, arg)
		
		local sign = false
		if arg:match("^%!") then sign = true arg = arg:sub(2, #arg) end
		
		if arg == "true" or arg == "t" then
			
			return not sign and true or false
		elseif arg == "false" or arg == "f" then
			
			return sign and true or false
		end
		
		return var
	end,
	
	str = function(var) return tostring(var) end
}

module["type_number"] = {
	
	var = function(var, arg)
		
		local num = tonumber(arg)
		if num then -- If argument is convertible to a number
			
			return num
		end
		
		return var
	end,
	
	str = function(var) return tostring(var) end
}

module["type_string"] = {
	
	var = function(var, arg, override) -- override to skip the quotations
		
		if type(override) == "boolean" or arg:match("^\".+\"$") then -- If argument is quotated
			
			arg = type(override) ~= "boolean" and arg:gsub("\\\"", "\""):sub(2, -2) or arg -- Move quotations one spot higher
			if arg ~= nil and arg ~= "" and not arg:match("^%s$") then -- If arg has text
				
				local nlKey = _G.dir.con.generateKey()
				return arg:gsub("\\\\n", nlKey):gsub("\\n", "\n"):gsub(nlKey, "\\n")
			end
		end
		
		return var
	end,
	
	str = function(var) return var:gsub("\n", "\\n") end
}

module["type_Color3"] = {
	
	var = function(var, arg)
		
		local r, g, b = arg:match("^(%S+), *(%S+), *(%S+)$")
		if tonumber(r) and tonumber(g) and tonumber(b) then
			
			return Color3.new(r, g, b)
		end
		
		return var
	end,
	
	str = function(var) return tostring(var) end
}

module["ctor_Color3"] = {
	
	var = {
		
		["new"] = function(r, g, b)
			
			if tonumber(r) and tonumber(g) and tonumber(b) then
				
				return tostring(Color3.new(r, g, b))
			end
			
			return ""
		end,
		["fromRGB"] = function(r, g, b)
			
			if tonumber(r) and tonumber(g) and tonumber(b) then
				
				return tostring(Color3.fromRGB(r, g, b))
			end
			
			return ""
		end,
		["fromHSV"] = function(h, s, v)
			
			if tonumber(h) and tonumber(s) and tonumber(v) then
				
				return tostring(Color3.fromHSV(h, s, v))
			end
			
			return ""
		end,
		["fromHex"] = function(hex)
			
			if hex then
				
				local r, g, b = hex:match("^\"?#?(%x?%x)(%x?%x)(%x?%x)\"?$")
				if r and g and b and table.find({3, 6}, string.len(r..g..b)) then
					
					return tostring(Color3.fromHex(r..g..b))
				end
			end
			
			return ""
		end,
		["random"] = function()
			
			local function random() return math.random(0, 255) end
			
			return tostring(Color3.fromRGB(random(), random(), random()))
		end
	}
}

module["type_Vector3"] = {
	
	var = function(var, arg)
		
		local x, y, z = arg:match("^(%S+), *(%S+), *(%S+)$")
		if tonumber(x) and tonumber(y) and tonumber(z) then
			
			return Vector3.new(x, y, z)
		end
		
		return var
	end,
	
	str = function(var) return tostring(var) end
}

module["ctor_Vector3"] = {
	
	var = {
		
		["new"] = function(x, y, z)
			
			if tonumber(x) and tonumber(y) and tonumber(z) then
				
				return tostring(Vector3.new(x, y, z))
			end
			
			return ""
		end,
		["player"] = function()
			
			if _G.Player.Character and _G.Player.Character:FindFirstChild("HumanoidRootPart") then
				
				return tostring(_G.Player.Character.HumanoidRootPart.Position)
			end
			
			return ""
		end,
		["target"] = function()
			
			local Hit = Mouse.Hit
			if Hit then
				
				return tostring(Hit.Position)
			end
			
			return ""
		end
	}
}

module["type_EnumItem"] = {
	
	var = function(var, arg, types) -- 'types' is used to make EnumItem arguments easier to write
		
		local function autoEnum()
			
			-- If is being loaded in
			if type(types) ~= "table" then return arg:split(".")[2] end
			
			-- Called by con.submit
			if (#types == 1 or #types == 2 and table.find(types, "nil")) and types[1]:match("^Enum") then
				
				return types[1]:split(".")[2]
			end
		end
		
		local function findEnum(path)
			
			for _, enum in pairs(Enum:GetEnums()) do
				
				if tostring(enum) == path[2] then -- tostring(enum) == "KeyCode"
					
					for _, item in pairs(Enum[path[2]]:GetEnumItems()) do
						
						if tostring(item) == table.concat(path, ".") then -- args[i] == "Enum.KeyCode.F"
							
							return item
						end
					end break -- So it doesn't continue iterating
				end
			end
		end
		
		local item
		local path, auto = arg:split("."), autoEnum()
		if #path == 1 and auto then -- #{"F"} == 1
			
			table.insert(path, 1, "Enum")
			table.insert(path, 2, auto)
			item = findEnum(path)
		elseif #path == 3 and path[1] == "Enum" then -- #{"Enum", "KeyCode", "F"} == 3
			
			item = findEnum(path)
		end
		
		return item or var
	end,
	
	str = function(var) return tostring(var):split(".")[3] end
}

module["type_any"] = {
	
	var = function()
		
		
	end
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function output(message: string, category: (Color3 | string)?)
	
	_G.dir.con.print.var(message, category)
end

module.processCtor = function(arg)
	
	local ctor = arg:match("^(.+)%(.-%)$") if ctor then ctor = ctor:split(".") end
	if ctor and #ctor == 1 then table.insert(ctor, 1, "") elseif ctor and #ctor > 2 then ctor = nil end
	
	local args
	if ctor then args = arg:match("%( *(.+)%)$") or {}
		if typeof(args) == "string" then args = args:gsub(" ", ""):split(",") end
	end
	
	return ctor, args -- {"Color3", "random"}, {"0", "255", "0", "0", "0", "255"}
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
