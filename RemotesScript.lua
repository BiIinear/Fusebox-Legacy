


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

_G.Player = game:GetService("Players"):GetPlayers()[1] or game:GetService("Players").PlayerAdded:Wait()

local ServStorage = game:GetService("ServerStorage")
local RepStorage = game:GetService("ReplicatedStorage")

_G.Remotes = RepStorage:WaitForChild("Remotes")
_G.Events = RepStorage:WaitForChild("Events")
_G.Maps = ServStorage:WaitForChild("Maps")
_G.Assets = RepStorage:WaitForChild("Assets")

_G.cooldown = false -- Cooldown when using remotes

Functions = require(script:WaitForChild("Functions"))

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- SETTING UP

Functions.loadStores()

function output(message: string, category: (Color3 | string)?)
	
	_G.Events.ServerOutput:FireClient(_G.Player, message, category)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- EVENTS

_G.Remotes.sv.OnServerInvoke = function(_, func, userCalled, arg1, arg2)
	
	-- Don't fire if cooldown is on
	if _G.cooldown then if userCalled then output("In cooldown, please wait.", "error") end return end
	_G.cooldown = true
	
	Functions[func](userCalled, arg1, arg2)
	
	-- Disable cooldown
	_G.cooldown = false
end

_G.Remotes.change_map.OnServerInvoke = function(_, userCalled, name)
	
	local CurrentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder")
	
	if name == nil then -- Print current map
		
		if userCalled then output("Current map is \""..CurrentMap.Name.."\"") end
	else -- Load specified map
		
		local Map = name == "*" and _G.Maps[CurrentMap.Name] or _G.Maps:FindFirstChild(name)
		if Map then -- If map exists
			
			-- Don't fire if cooldown is on
			if _G.cooldown then if userCalled then output("In cooldown, please wait.", "error") end return end
			_G.cooldown = true
			
			-- Start load sequence
			_G.Events.LoadingSequence:FireClient(_G.Player, true, Map.Name) -- state, toMap
			
			-- Change map
			Functions.change_map(Map)
			if userCalled then output(name == "*" and "Map reloaded." or "Map changed to "..name) end
			
			-- Finish load sequence
			_G.Events.LoadingSequence:FireClient(_G.Player, false, Map.Name) -- state false
			
			-- Disable cooldown
			_G.cooldown = false
		elseif userCalled then -- Map does not exist
			
			output("This map does not exist.", "error")
		end
	end
end

_G.Remotes.list_maps.OnServerInvoke = function()
	
	return Functions.list_maps()
end

_G.Remotes.list_settings.OnServerInvoke = function()
	
	return Functions.list_settings()
end
_G.Remotes.game_info.OnServerInvoke = function(_, name)
	
	return Functions.game_info(name)
end

_G.Remotes.game_data.OnServerInvoke = function(_, name)
	
	return Functions.game_data(name)
end
