


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["data"] = {
	
	var = {
		
		["currentMap"] = false,
		["charPosition"] = false,
		["charOrientation"] = false,
		["charHealth"] = false,
		["charMaxHealth"] = false,
		["charWalkSpeed"] = false,
		["charJumpPower"] = false,
		["charJumpHeight"] = false,
		["charSit"] = false
	},
	
	save = true
}

module["currentSave"] = {
	
	var = false
}

module["quickref"] = {
	
	desc = "An array of all saved games for quick reference.",
	
	var = {}
}

module["cheats"] = {
	
	desc = "Toggle game cheats on current save.",
	
	var = false,
	
	cheat = false,
	save = true
}

module["saves"] = {
	
	desc = "Prints a list of all saved games.",
	
	var = function()
		
		local list = module.quickref.var
		for i = 1, #list do
			
			output("["..i.."] "..list[i]) -- Print save and array position
		end
		
		if #list == 0 then output("No saved games.") end
	end,
	
	cheat = false
}

module["save"] = {
	
	desc = "Save a new game or overwrite an existing save.",
	
	params = "save:string?", var = function(userCalled, save)
		
		-- Save
		_G.Remotes.sv:InvokeServer("save_game", userCalled, save or module.currentSave.var)
	end,
	
	cheat = false,
	connect = true
}

module["load"] = {
	
	desc = "Load a specified save.",
	
	params = "save:string?", var = function(userCalled, save)
		
		-- Validate save
		if not validSave(save) then if userCalled then output("Unknown save.", "error") end return end
		
		-- Load
		_G.Remotes.sv:InvokeServer("load_game", userCalled, save or module.currentSave.var)
	end,

	cheat = false
}

module["info"] = {
	
	desc = "Prints the save's information and data.",
	
	params = "save:string?", var = function(userCalled, save)
		
		-- Validate save
		if not validSave(save) then if userCalled then output("Unknown save.", "error") end return end
		
		-- List info
		output("Save information:", Color3.new(1, 1, 1))
		local info = _G.Remotes.game_info:InvokeServer(save or module.currentSave.var)
		for n, v in pairs(info) do
			
			output(n.." = \""..tostring(v).."\"")
		end
		
		-- List data
		output("Save data:", Color3.new(1, 1, 1))
		local data = _G.Remotes.game_data:InvokeServer(save or module.currentSave.var)
		for n, v in pairs(data) do
			
			output(n.." = \""..v.."\"")
		end
	end,
	
	cheat = false
}

module["rename"] = {
	
	desc = "Rename a specified save.",
	
	params = "save:string?,newName:string", var = function(userCalled, save, name)
		
		-- Validate save
		if not validSave(save) then if userCalled then output("Unknown save.", "error") end return end
		
		-- Provide new name
		if name == nil then if userCalled then output("Missing new name.", "error") end return end
		
		-- Must not be the same
		if name == save then if userCalled then output("This save is already named \""..save.."\"", "error") end return end
		
		-- Name must be available
		if table.find(module.quickref.var, name) then
			if userCalled then output("There is already a save with this name.", "error") end
		return end
		
		-- Rename
		_G.Remotes.sv:InvokeServer("rename_game", userCalled, save or module.currentSave.var, name)
	end,
	
	cheat = false
}

module["delete"] = {
	
	desc = "Delete a specified save.",
	
	params = "save:string?", var = function(userCalled, save)
		
		-- Validate save
		if not validSave(save) then if userCalled then output("Unknown save.", "error") end return end
		
		-- Must not be current save
		if save == module.currentSave.var or save == nil then
			if userCalled then output("Cannot delete current save.", "error") end
		return end
		
		-- Delete
		_G.Remotes.sv:InvokeServer("delete_game", userCalled, save or module.currentSave.var)
	end,
	
	cheat = false
}

module["clear"] = {
	
	desc = "Delete all saved games (locked saves are ignored).",
	
	var = function(userCalled)
		
		-- Check if there are any saves
		if #module.quickref.var == 0 then if userCalled then output("No saved games.") end return end
		
		-- Clear
		_G.Remotes.sv:InvokeServer("clear_games", userCalled)
	end,
	
	cheat = false
}

module["lock"] = {
	
	desc = "Lock or unlock a save. Restricts a save from being renamed, overwritten, or deleted.",
	
	params = "save:string?,boolean", var = function(userCalled, save, bool)
		
		-- Validate save
		if not validSave(save) then if userCalled then output("Unknown save.", "error") end return end
		
		-- Must have bool
		if bool == nil then if userCalled then output("Missing boolean.", "error") end return end
		
		-- Lock
		_G.Remotes.sv:InvokeServer("lock_game", userCalled, save or module.currentSave.var, bool)
	end,
	
	cheat = false
}

module["save_map_data"] = {
	
	desc = "Saves the current map's data to 'sv.maps'.",
	
	var = function(saving)
		
		-- Don't run if it's loading the first map of a session
		local currentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder")
		if not currentMap then return end
		
		-- Don't run if the map doesn't allow data saving
		if not _G.Controllers.Maps[currentMap.Name].data.saveData then return end
		
		-- Create table in 'sv.maps'
		module.maps[currentMap.Name] = { var = {}, save = true }
		
		-- Save map configuration to table
		local tblLen = 0
		for n, v in pairs(_G.Controllers.Maps[currentMap.Name].data) do
			
			if n == "saveData" or n == "loadCharacter" then continue end -- Skip main configs
			module.maps[currentMap.Name].var[n] = tostring(v) -- sv.maps.c1a0.alarm01_active = "true"
			tblLen += 1
		end
		
		-- Save map asset's information to table
		local assignedID = 1
		for _, Asset in pairs(currentMap.Assets:GetChildren()) do
			
			-- Asset limit is 999
			if assignedID >= 1000 then break end
			
			-- Save asset data
			local name = Asset.Name.."/"..string.format("%.3u", assignedID).."/"
			module.maps[currentMap.Name].var[name.."Position"] = tostring(Asset.PrimaryPart.Position)
			module.maps[currentMap.Name].var[name.."Orientation"] = tostring(Asset.PrimaryPart.Orientation)
			assignedID += 1 tblLen += 1 -- malik_the_golden_crab/001/Position
		end
		
		-- Delete table if no data was saved
		if tblLen == 0 then module.maps[currentMap.Name] = nil end
		
		return
	end
}

module["load_map_data"] = {
	
	desc = "Loads in saved map data from 'sv.maps'.",
	
	var = function()
		
		local currentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder")
		
		-- Don't run if there is no data
		if not module.maps[currentMap.Name] then return end
		local data = module.maps[currentMap.Name].var
		
		-- Loop through map data
		local LoadedAssets = {}
		for n, v in pairs(data) do
			
			local split = n:split("/")
			if #split == 3 then -- If it's an asset {"pyrm", "001", "Position"}
				
				local name, id, property = split[1], split[2], split[3]
				
				-- Load in asset first
				if not LoadedAssets[id] then -- If asset hasn't loaded in yet
					
					local Model = _G.Assets[name]:Clone()
					local pos = _G.dir.con.datatype.type_Vector3.var(nil, data[name.."/"..id.."/Position"])
					local ort = _G.dir.con.datatype.type_Vector3.var(nil, data[name.."/"..id.."/Orientation"])
					Model:SetPrimaryPartCFrame(CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(math.rad(ort.X), math.rad(ort.Y), math.rad(ort.Z)))
					task.wait() -- Delay because I can't trust rendering speed
					
					Model.Parent = currentMap.Assets
					LoadedAssets[id] = Model -- So they don't multiply every reload
				end
				
				-- Skip if the property is an autosaved property
				if property == "Position" or property == "Orientation" then continue end
				
				-- Now load the 'Data' folder thing if it has one
				local Value = LoadedAssets[id].Data[property]
				local processed = _G.dir.con.datatype["type_"..typeof(Value.Value)].var(nil, v)
				if processed ~= nil then
					
					Value.Value = processed
				else
					
					output("Attempt to load unknown map data \""..n.."\"", "error")
				end
			elseif _G.Controllers.Maps[currentMap.Name].data[n] then -- It's a map configuration
				
				local dataTable = _G.Controllers.Maps[currentMap.Name].data
				local processed = _G.dir.con.datatype["type_"..typeof(dataTable[n])].var(nil, v, true) -- 'true' for type_string
				if processed ~= nil then
					
					dataTable[n] = processed
				else
					
					output("Attempt to load unknown map data \""..n.."\"", "error")
				end
			else -- Unknown data
				
				output("Attempt to load unknown map data \""..n.."\"", "error")
			end
		end
		
		return
	end
}

module["default_data"] = {
	
	desc = "Creates a 'default' attribute for every cvar with the 'save' or 'setting' attribute.",
	
	var = function()
		
		local function recurse(path)
			
			for n, v in pairs(path) do -- Search the module
				
				-- Skip if it's not a cvar/module
				if type(v) ~= "table" then continue end
				
				-- Search
				if v.var ~= nil then -- If cvar
					
					-- Create 'default' attribute
					if type(v.var) ~= "function" and (v.setting or v.save) then -- Non-function and is a setting/save
						
						local function copy()
							
							if type(v.var) == "table" then -- Fixes a table problem that I forgot about (it's been 8 months)
								
								-- Deep copy
								local copy = {} for i, var in pairs(v.var) do copy[i] = var end return copy
							end return v.var
						end
						
						v.default = copy()
					end
				elseif v.require_dir then -- If module
					
					recurse(v)
				end
			end
		end recurse(_G.dir)
		
		return
	end
}

module["clear_data"] = {
	
	desc = "Sets all cvars back to default.",
	
	var = function()
		
		local function recurse(path)
			
			for n, v in pairs(path) do -- Search the module
				
				-- Skip if it's not a cvar/module
				if type(v) ~= "table" then continue end
				
				-- Search
				if v.var ~= nil then -- If cvar
					
					-- Set back to original value, and delete loaded-in tables
					if v.default ~= nil and not v.setting then
						
						local function default()
							
							if type(v.var) == "table" then -- Fixes a table problem that I forgot about (it's been 8 months)
								
								-- Deep copy
								local copy = {} for i, var in pairs(v.default) do copy[i] = var end return copy
							end return v.default
						end
						
						v.var = default()
					elseif type(v.var) == "table" and v.save then -- If cvar is a loaded-in table (missing 'default' attribute)
						
						path[n] = nil -- 'v = nil' won't work for some reason
					end
				elseif v.require_dir then -- If module
					
					recurse(v)
				end
			end
		end recurse(_G.dir)
		
		return
	end
}

module["get_data"] = {
	
	desc = "Creates a table of all current data in the game, which is then sent to the server.",
	
	var = function(attrib)
		
		-- Get player data
		if attrib == "save" then -- If getting current data for a save
			
			local RootPart = _G.Player.Character.HumanoidRootPart
			local Humanoid = _G.Player.Character.Humanoid
			module.data.var.charPosition = RootPart.Position
			module.data.var.charOrientation = RootPart.Orientation
			module.data.var.charHealth = Humanoid.Health
			module.data.var.charMaxHealth = Humanoid.MaxHealth
			module.data.var.charWalkSpeed = Humanoid.WalkSpeed
			module.data.var.charJumpPower = Humanoid.UseJumpPower and Humanoid.JumpPower or false
			module.data.var.charJumpHeight = not Humanoid.UseJumpPower and Humanoid.JumpHeight or false
			module.data.var.charSit = Humanoid.Sit
			module.data.var.currentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder").Name
			module.save_map_data.var() -- Get map data
		end
		
		-- Get data
		local data = {}
		local function recurse(path, pathName)
			
			for n, v in pairs(path) do
				
				-- Prevent getting non cvars
				if type(v) ~= "table" then continue end
				
				-- Get
				if v.require_dir then -- If is a module
					
					recurse(v, (pathName and pathName.."." or "")..n)
				elseif v[attrib] then -- If cvar has the 'setting' or 'save' attribute
					
					if type(v.var) == "table" then -- If cvar is a table
						
						for varName, tblValue in pairs(v.var) do
							
							data[(pathName and pathName.."." or "")..n.."."..varName] = tostring(tblValue)
						end
					else -- Not table
						
						data[(pathName and pathName.."." or "")..n] = tostring(v.var)
					end
				end
			end
		end recurse(_G.dir)
		
		return data
	end
}

module["load_data"] = {
	
	desc = "Loads in saved data to the game.",
	
	var = function(data)
		
		local function recurse(pos, path, i, v)
			
			local npos = pos[path[i]]
			
			-- Search
			if npos and npos.require_dir then -- Next pos is a module
				
				recurse(npos, path, i + 1, v)
			elseif npos and npos.var and type(npos.var) == "table" -- If cvar is a table
				or path[i + 1] ~= nil and path[i + 2] == nil then -- Or cvar is a loaded-in table
				
				-- Create table
				if npos == nil then -- If it's a loaded-in table
					
					pos[path[i]] = { var = {}, save = true }
					npos = pos[path[i]]
				end
				
				-- Insert value to table
				local var = npos.var[path[#path]]
				if var ~= nil then -- Value already exists in table
					
					npos.var[path[#path]] = _G.dir.con.datatype["type_"..typeof(var)].var(var, v)
				else -- Value was loaded-in
					
					npos.var[path[#path]] = _G.dir.con.datatype["type_string"].var(var, v, true) -- Loaded-in will remain as string
				end
			elseif npos then -- Cvar is not a module nor table
				
				npos.var = _G.dir.con.datatype["type_"..typeof(npos.var)].var(npos.var, v, true)
			else -- Unknown next pos
				
				output("Attempt to load unknown cvar \""..table.concat(path, ".").."\"", "error")
			end
		end
		
		-- Iterate through all data
		for n, v in pairs(data) do
			
			-- We could just make it where we call recurse() right off the bat without having to
			-- check path[1], but when I did that, it causes some weird ass error. It's so weird
			-- that even I couldn't pinpoint why the hell it was doing that. (10/19/23)
			
			local path = n:split(".")
			if _G.dir[path[1]] ~= nil then -- Saves us from a weird ass error
				
				recurse(_G.dir[path[1]], path, 2, v)
			else
				
				output("Attempt to load unknown cvar \""..n.."\"", "error")
			end
		end
		
		return
	end
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function validSave(name)
	
	if name ~= nil and table.find(module.quickref.var, name) or name == nil and module.currentSave.var then
		
		return true
	end
end

function output(message: string, category: (Color3 | string)?)
	
	_G.dir.con.print.var(message, category)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
