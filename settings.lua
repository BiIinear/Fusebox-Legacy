


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["save"] = {
	
	desc = "Save all settings and controls to DataStore.",
	
	var = function(userCalled)
		
		_G.Remotes.sv:InvokeServer("save_settings", userCalled)
	end,
	
	cheat = false
}

module["load"] = {
	
	desc = "Load in saved settings from DataStore.",
	
	var = function(userCalled)
		
		local function getn(tbl)
			
			local amount = 0 for _ in pairs(tbl) do amount += 1 end return amount
		end
		
		local list = _G.Remotes.list_settings:InvokeServer()
		if getn(list) > 0 then
			
			_G.dir.sv.load_data.var(list)
			if userCalled then output("Settings reloaded.") end
		else
			
			if userCalled then output("No saved settings to load.") end
		end
	end,
	
	cheat = false
}

module["clear"] = {
	
	desc = "Delete all saved settings from DataStore.",
	
	var = function(userCalled)
		
		_G.Remotes.sv:InvokeServer("clear_settings", userCalled)
	end,
	
	cheat = false
}

module["reset"] = {
	
	desc = "Set a specified setting back to default.",
	
	params = "cvar:string", var = function(userCalled, arg)
		
		-- Don't run if 'cvar' is missing
		if arg == nil and userCalled then output("Missing command variable.", "error") end
		
		-- Get cvar
		local path = arg:split(".")
		local cvar, val = _G.dir.con.query.var(nil, path, 1, true)
		if cvar and cvar.setting then -- Setting cvar
			
			-- Reset
			if type(cvar.var) == "table" then -- Table cvar
				
				if val == nil then -- Reset table
					
					local copy = {} for i, var in pairs(cvar.default) do copy[i] = var end cvar.var = copy
				elseif cvar.var[val] ~= nil then -- Reset value
					
					cvar.var[val] = cvar.default[path[#path]]
				end
			else -- Basic cvar
				
				cvar.var = cvar.default
			end
			
			if userCalled then output(path[#path].." defaulted.") end
		elseif cvar and not cvar.setting and userCalled then -- Non-setting cvar
			
			output("This command variable is not a setting.", "error")
		elseif userCalled then -- Invalid cvar
			
			output("Unknown command variable.", "error")
		end
	end,
	
	cheat = false
}

module["reset_all"] = {
	
	desc = "Set all settings back to default.",
	
	var = function(userCalled)
		
		-- This cvar is identical to 'sv.default_data'
		local function recurse(path)
			
			for n, v in pairs(path) do -- Search the module
				
				-- Skip if it's not a cvar/module
				if type(v) ~= "table" then continue end
				
				-- Search
				if v.var ~= nil then -- If cvar
					
					if type(v.var) ~= "function" and v.setting then -- Has the 'setting' attribute
						
						local function default()
							
							if type(v.var) == "table" then -- Fixes a table problem that I forgot about (it's been 8 months)
								
								-- Deep copy
								local copy = {} for i, var in pairs(v.default) do copy[i] = var end return copy
							end return v.default
						end
						
						v.var = default()
					end
				elseif v.require_dir then -- If module
					
					recurse(v)
				end
			end
		end recurse(_G.dir)
		
		if userCalled then output("All settings defaulted.") end
		
		return
	end,
	
	cheat = false
}

module["list"] = {
	
	desc = "Prints a list of all saved settings.",
	
	var = function()
		
		local list = _G.Remotes.list_settings:InvokeServer()
		for n, v in pairs(list) do
			
			output(n.." = \""..v.."\"")
		end
	end,
	
	cheat = false
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function output(message: string, category: (Color3 | string)?)
	
	_G.dir.con.print.var(message, category)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
