


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["help"] = {
	
	desc = "The simplest, most self-explanatory command.",
	
	params = "dataType:string?", var = function(userCalled, dtype)
		
		
	end,
	
	cheat = false
}

module["fusebox"] = {
	
	var = function()
		
		output([[Fusebox Framework v1.0
Build: 12/19/2023 19:37:00
----------------------------
Change log:]])
	end,
	
	cheat = false
}

module["clear"] = {
	
	desc = "Clears the Fusebox console output.",
	
	var = function(userCalled)
		
		_G.dir.con.clear.var()
	end,
	
	cheat = false
}

module["close"] = {
	
	desc = "Close the Fusebox console.",
	
	var = function(userCalled)
		
		_G.dir.con.toggle.var(false)
	end,
	
	cheat = false
}

module["hist"] = {
	
	desc = "Prints a list of all previously submitted commands.",
	
	var = function()
		
		local history = _G.dir.con.history.var
		for i = 1, #history do
			
			output("["..i.."] "..history[i])
		end
	end,
	
	cheat = false
}

module["echo"] = {
	
	desc = "Echo text in the Fusebox console output.",
	
	params = "string,Color3?", var = function(userCalled, text, color)
		
		if text ~= nil then output(text, color) end
	end,
	
	cheat = false
}

module["loop"] = {
	
	desc = "Repeat a command a sepecified amount of times.",
	
	params = "number,cmd:string", var = function(userCalled, amount, command)
		
		if amount ~= nil and command ~= nil then
			
			for i = 1, amount do
				
				_G.dir.con.submit.var(command)
			end
		else -- Tuple was not provided
			
			output("Provide a number and a command (string).", "error")
		end
	end,
	
	cheat = false
}

module["wait"] = {
	
	desc = "Delay the next command by a specific amount of time. For example, wait 3; echo \"hello\"",
	
	params = "number", var = function(userCalled, num)
		
		task.wait(num)
	end,
	
	cheat = false
}

module["map"] = {
	
	desc = [[Switch to a specified map.
Use "maps" to get a list of all available maps. Use "map *" to reload current map.]],
	
	params = "map:string?", var = function(userCalled, map)
		
		-- Change map
		_G.Remotes.change_map:InvokeServer(userCalled, map)
	end,
	
	cheat = true
}

module["maps"] = {
	
	desc = "Prints a list of all available maps.",
	
	var = function(userCalled)
		
		local maps = _G.Remotes.list_maps:InvokeServer(userCalled)
		for i = 1, #maps do
			
			output("["..i.."] "..maps[i]) -- Print map name and array position
		end
	end,
	
	cheat = false
}

module["bind"] = {
	
	desc = "Bind a command to a key.",
	
	params = "Enum.KeyCode,cmd:string", var = function(userCalled, key, text)
		
		-- Validate key
		local key = string.split(tostring(key), ".") key = key[3] or nil
		if not key then output("Missing or invalid key.", "error") return end
		
		-- Validate string
		if not text then output("Missing command.", "error") return end
		
		-- Bind command to KeyCode
		module.binds.var[key] = text
		output("Command bound to "..key..".")
	end,
	
	cheat = false
}

module["binds"] = {
	
	desc = "Commands bound to keys.",
	
	var = {},
	
	cheat = false,
	setting = true
}

module["unbind"] = {
	
	desc = "Unbind a command from a key.",
	
	params = "Enum.KeyCode", var = function(userCalled, key)
		
		key = string.split(tostring(key), ".")[3]
		if module.binds.var[key] then -- If player wants to clear a specific bind
			
			-- Clear bind
			module.binds.var[key] = nil
			output("Command unbound.")
		else -- Argument is not a used bind
			
			output("This key does not have a bound command.", "error")
		end
	end,
	
	cheat = false
}

module["logs"] = {
	
	desc = "Recieve game logs in the Fusebox console output.",
	
	params = "toggle:boolean?", var = function(userCalled, bool)
		
		-- Autocorrect 'bool' if it wasn't provided
		if bool == nil then bool = module.logs.listener == nil end
		
		-- Game logs
		if bool and module.logs.listener == nil then -- If wanting to opt in
			
			module.logs.listener = game:GetService("LogService").MessageOut:Connect(function(text, msgType)
				
				-- info, error, output, warning
				msgType = tostring(msgType):lower():gsub("enum.messagetype.message", "")
				local category = msgType == "info" and Color3.fromRGB(100, 200, 255)
					or msgType == "output" and Color3.new(1, 1, 1)
					or msgType == "warning" and Color3.fromRGB(255, 200, 65)
					or msgType
					
				_G.dir.con.print.var(text, category, Color3.fromRGB(0, 170, 255))
			end)
			
			output("Now listening for game logs.")
		elseif not bool and module.logs.listener ~= nil then -- Bool == false and if opted in
			
			module.logs.listener:Disconnect()
			module.logs.listener = nil
			output("Stopped listening.")
		end
	end,
	
	cheat = false
}

module["ros"] = {
	
	desc = "Run on startup.",
	
	var = "sv.cheats true; map \"pre_a0.06\"; echo \"Hi! Welcome to my game\" Color3.new(1, 1, 1); con.toggle true",
	
	cheat = false,
	setting = true
}

module["cvar"] = {
	
	desc = "Create a command variable.",
	
	params = "name:string,any", var = function(userCalled, name, any)
		
		if name and (module.cvars.list[name] or module[name] == nil) then -- Overwrite/create custom cvar
			
			-- Justify name
			name = name:gsub("%.", "_"):gsub(";", "_"):gsub("%s", "_"):gsub("\"", "_")
			
			-- Var cannot be nil
			if any == nil then output("Cvar cannot be nil.", "error") return end
			
			-- Define
			if module[name] == nil then output("Made new cvar \""..name.."\"\nData type: "..typeof(any)) end
			module[name] = {var = any, cheat = false}
			module.cvars.list[name] = true
		elseif name and module[name] ~= nil then -- Utility cvar
			
			output("This is a utility cvar.", "error")
		else -- Missing name
			
			output("Missing name.", "error")
		end
	end,
	
	cheat = false
}

module["cvars"] = {
	
	list = {},
	
	desc = "Prints a list of all user-created command variables.",
	
	var = function()
		
		for i in pairs(module.cvars.list) do
			
			output(i)
		end
	end,
	
	cheat = false
}

module["rmcvar"] = {
	
	desc = "Remove a user-created command variable.",
	
	params = "name:string", var = function(userCalled, name)
		
		if name and module.cvars.list[name] then -- Valid cvar
			
			-- Remove
			module[name] = nil
			module.cvars.list[name] = nil
			output("Cvar removed.")
		elseif name and not module.cvars.list[name] then -- Invalid cvar
			
			output("This cvar could not be found.", "error")
		else -- Missing name
			
			output("Missing name.", "error")
		end
	end,
	
	cheat = false
}

module["uptime"] = {
	
	desc = "Prints the game's uptime (workspace.DistributedGameTime).",
	
	var = function()
		
		local uptime = math.floor(workspace.DistributedGameTime)
		output(uptime.." seconds ("..(math.floor(uptime / 60)).." minutes)")
	end,
	
	cheat = false
}

module["box"] = {
	
	desc = "Draw a wireframe box with an optional color and specified position.",
	
	params = "pos:Vector3?,Color3?", var = function(userCalled, pos, color)
		
		local Part = Instance.new("Part")
		Part.Size = Vector3.new(3, 3, 3)
		Part.Position = pos or workspace.CurrentCamera.CFrame.Position
		Part.Transparency = 1
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanTouch = false
		Part.CanQuery = false
		local SelectionBox = Instance.new("SelectionBox")
		SelectionBox.Color3 = color or Color3.new(1, 1, 1)
		SelectionBox.LineThickness = .001
		SelectionBox.Adornee = Part
		SelectionBox.Parent = Part
		
		Part.Parent = workspace
	end,
	
	cheat = true
}

module["ray"] = {
	
	desc = "Draw a raycast from the camera to the specified position.",
	
	params = "Vector3,Color3?", var = function(userCalled, pos, color)
		
		-- Validate Vector3
		if not pos then output("Missing Vector3.", "error") return end
		
		-- Get points and numbers
		local rayOrigin = workspace.CurrentCamera.CFrame.Position
		local dist = (rayOrigin - pos).Magnitude
		
		-- Visualize raycast
		local Part = Instance.new("Part")
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanTouch = false
		Part.CanQuery = false
		Part.Size = Vector3.new(.01, .01, dist)
		Part.CFrame = CFrame.lookAt(rayOrigin, pos) * CFrame.new(0, 0, -dist / 2)
		Part.Material = Enum.Material.Neon
		Part.Color = color or Color3.new(1, 1, 1)
		
		Part.Parent = workspace
	end,
	
	cheat = true
}

module["sound"] = {
	
	desc = "Play a given sound at a specific position or in the background.",
	
	params = "soundid:number,Vector3?", var = function(userCalled, id, pos)
		
		-- Validate id
		if not id then output("Missing sound ID.", "error") return end
		
		-- Make sound
		local Sound = Instance.new("Sound")
		Sound.SoundId = "rbxassetid://"..id
		Sound.PlayOnRemove = true
		
		if pos then -- Play at position
			
			-- Make part (so sound can play at that position)
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.CanCollide = false
			Part.CanTouch = false
			Part.CanQuery = false
			Part.Position = pos
			
			Sound.Parent = Part
			Part.Parent = workspace
			Part:Destroy()
		else -- Play in background
			
			Sound.Parent = workspace
			Sound:Destroy()
		end
	end,
	
	cheat = true
}

module["assets"] = {
	
	desc = "Prints a list of all game assets.",
	
	var = function()
		
		for i, v in pairs(_G.Assets:GetChildren()) do -- Only need the names
			
			output("["..i.."] "..v.Name)
		end
	end,
	
	cheat = false
}

module["spawn"] = {
	
	desc = "Spawns the given asset to the mouse target or specified position.",
	
	params = "asset:string,Vector3?", var = function(userCalled, asset, pos)
		
		-- Validate asset
		if not asset then output("Missing asset.", "error") return end
		
		-- Asset is in list
		if not _G.Assets[asset] then output("Invalid asset.", "error") return end
		
		-- Autocorrect pos
		if not pos then pos = _G.Player:GetMouse().Hit.Position end
		
		-- Spawn asset to pos
		local Model = _G.Assets[asset]:Clone()
		local camPos = workspace.CurrentCamera.CFrame.Position
		Model:SetPrimaryPartCFrame(CFrame.lookAt(pos, Vector3.new(camPos.X, pos.Y, camPos.Z)) + Vector3.new(0, Model.PrimaryPart.Size.Y / 2, 0))
		Model.Parent = workspace.CurrentMap:FindFirstChildOfClass("Folder").Assets
	end,
	
	cheat = true
}

module["despawn"] = {
	
	desc = "Destroys the mouse-targeted asset.",
	
	var = function()
		
		local CurrentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder")
		
		local function findParent(p)
			
			if p.Parent.Parent == CurrentMap.Assets then
				
				return p.Parent
			elseif p.Parent == workspace then -- Went too far
				
				return
			else
				
				findParent(p.Parent)
			end
		end
		
		local Target = _G.Player:GetMouse().Target
		if Target then
			
			local Asset = findParent(Target)
			if Asset then Asset:Destroy() end
		end
	end,
	
	cheat = true
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function output(message: string, category: (Color3 | string)?)
	
	_G.dir.con.print.var(message, category)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
