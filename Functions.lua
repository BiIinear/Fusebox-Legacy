


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

local DataStore = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")

local gameSettingsStore = DataStore:GetDataStore("gameSettings")
local gameSettings = {}
local gameSavesStore = DataStore:GetDataStore("gameSaves")
local gameSaves = {}

local first_gameSettings = true
local first_gameSaves = true

local currentSave = false

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- OTHER

module["list_settings"] = function()
	
	return gameSettings
end

module["list_maps"] = function()
	
	local Maps = _G.Maps:GetChildren()
	
	local list = {} -- Only need the names
	for i = 1, #Maps do
		
		list[i] = Maps[i].Name
	end
	
	return list
end

module["game_info"] = function(name)
	
	return gameSaves[name].info
end

module["game_data"] = function(name)
	
	return gameSaves[name].data
end

module["change_map"] = function(Map, toSave)
	
	-- If the game is just changing maps instead of loading a save, then gather the
	-- current map's data before continuing. However, if it's loading a save, don't
	-- save the map data at all.
	if not toSave then _G.Remotes.cl:InvokeClient(_G.Player, 0, "save_map") end
	
	-- First off, set gravity and global wind to 0. This enables a 'paused physics'
	-- pseudostate so that all unanchored objects that are loading into place can
	-- STAY in place, instead of falling through the map or messing with other
	-- unanchored objects. Keep it like this until the map has fully finished loading.
	workspace.Gravity = 0
	workspace.GlobalWind = Vector3.new()
	
	-- Manage character
	local RootPart = _G.Player.Character and _G.Player.Character:FindFirstChild("HumanoidRootPart")
	if _G.Controllers.Maps[Map.Name].data.loadCharacter then -- Allowed to load character
		
		-- Load character if it isn't already loaded
		if not RootPart then loadChar() end
		RootPart = _G.Player.Character:FindFirstChild("HumanoidRootPart")
		RootPart.Anchored = true
		
		if toSave then -- Called by 'load_game'. Load in character and data
			
			-- Move to location
			local x, y, z = toSave["sv.data.charPosition"]:match("^(%S+), *(%S+), *(%S+)$") local pos = Vector3.new(x, y, z)
			x, y, z = toSave["sv.data.charOrientation"]:match("^(%S+), *(%S+), *(%S+)$") local orient = Vector3.new(x, y, z)
			RootPart.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(orient.X), math.rad(orient.Y), math.rad(orient.Z))
			
			-- Load other data
			local Humanoid = _G.Player.Character:FindFirstChild("Humanoid")
			Humanoid.MaxHealth = tonumber(toSave["sv.data.charMaxHealth"])
			Humanoid.Health = tonumber(toSave["sv.data.charHealth"])
			Humanoid.WalkSpeed = tonumber(toSave["sv.data.charWalkSpeed"])
			Humanoid.UseJumpPower = toSave["sv.data.charJumpPower"] ~= "false" and true or false
			if Humanoid.UseJumpPower then Humanoid.JumpPower = tonumber(toSave["sv.data.charJumpPower"])
			else Humanoid.JumpHeight = tonumber(toSave["sv.data.charJumpHeight"]) end
			Humanoid.Sit = tonumber(toSave["sv.data.charSit"])
		else -- Just changing maps. Move to spawn location (if there is one)
			
			local SpawnLocation = Map.Map:FindFirstChildOfClass("SpawnLocation")
			if SpawnLocation then RootPart.CFrame = SpawnLocation.CFrame end
		end
	else -- Remove character
		
		removeChar()
	end
	
	--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜
	
	-- Remove current map
	local CurrentMap = workspace.CurrentMap
	CurrentMap:ClearAllChildren()
	workspace.Terrain:Clear()
	
	-- Load map lighting
	local MapLighting = Map:FindFirstChild("Lighting")
	Lighting.Ambient = MapLighting.Ambient.Value -- You can't loop through properties which is super inconvenient
	Lighting.Brightness = MapLighting.Brightness.Value
	Lighting.ColorShift_Bottom = MapLighting.ColorShift_Bottom.Value
	Lighting.ColorShift_Top = MapLighting.ColorShift_Top.Value
	Lighting.EnvironmentDiffuseScale = MapLighting.EnvironmentDiffuseScale.Value
	Lighting.EnvironmentSpecularScale = MapLighting.EnvironmentSpecularScale.Value
	Lighting.GlobalShadows = MapLighting.GlobalShadows.Value
	Lighting.OutdoorAmbient = MapLighting.OutdoorAmbient.Value
	Lighting.ShadowSoftness = MapLighting.ShadowSoftness.Value
	Lighting.ClockTime = MapLighting.ClockTime.Value
	Lighting.GeographicLatitude = MapLighting.GeographicLatitude.Value
	Lighting.ExposureCompensation = MapLighting.ExposureCompensation.Value
	if Lighting:FindFirstChild("Bloom") then Lighting.Bloom:Destroy() end
	MapLighting.Bloom:Clone().Parent = Lighting
	if Lighting:FindFirstChild("Blur") then Lighting.Blur:Destroy() end
	MapLighting.Blur:Clone().Parent = Lighting
	if Lighting:FindFirstChild("ColorCorrection") then Lighting.ColorCorrection:Destroy() end
	MapLighting.ColorCorrection:Clone().Parent = Lighting
	if Lighting:FindFirstChild("SunRays") then Lighting.SunRays:Destroy() end
	MapLighting.SunRays:Clone().Parent = Lighting
	if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere:Destroy() end
	MapLighting.Atmosphere:Clone().Parent = Lighting
	if Lighting:FindFirstChild("Sky") then Lighting.Sky:Destroy() end
	MapLighting.Sky:Clone().Parent = Lighting
	if workspace.Terrain:FindFirstChild("Clouds") then workspace.Terrain.Clouds:Destroy() end
	MapLighting.Clouds:Clone().Parent = workspace.Terrain
	
	--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜
	
	local function createFolder(name, parent)
		
		local Folder = Instance.new("Folder")
		Folder.Name = name
		Folder.Parent = parent
		
		parent:WaitForChild(name) -- Delay sorta, makes sure the folder is there
	end

	local function loadObjects(objects, parent)
		
		for _, obj in pairs(objects:GetChildren()) do
			
			obj:Clone().Parent = parent
			task.wait() -- Delay so unanchored objects don't fall through the ground
		end
	end
	
	-- Create map folder
	createFolder(Map.Name, CurrentMap)
	local MapFolder = CurrentMap:WaitForChild(Map.Name)
	
	-- Load map
	createFolder("Map", MapFolder)
	local MapSpawn = Map.Map:FindFirstChildOfClass("SpawnLocation")
	if MapSpawn then MapSpawn:Clone().Parent = MapFolder.Map end
	loadObjects(Map.Map, MapFolder.Map)
	
	-- Load terrain
	for _, part in pairs(Map.Map.Terrain:GetChildren()) do
		
		if part.ClassName == "Part" then
			
			if part.Shape == Enum.PartType.Block then
				
				workspace.Terrain:FillBlock(part.CFrame, part.Size, part.Material)
			elseif part.Shape == Enum.PartType.Wedge or part.Shape == Enum.PartType.CornerWedge then
				
				workspace.Terrain:FillWedge(part.CFrame, part.Size, part.Material)
			elseif part.Shape == Enum.PartType.Ball then
				
				workspace.Terrain:FillBall(part.CFrame, part.Size, part.Material)
			elseif part.Shape == Enum.PartType.Cylinder then
				
				workspace.Terrain:FillCylinder(part.CFrame, part.Size, part.Material)
			end
		elseif part.ClassName == "WedgePart" then
			
			workspace.Terrain:FillWedge(part.CFrame, part.Size, part.Material)
		end
	end
	
	-- Load assets and debris
	createFolder("Assets", MapFolder)
	loadObjects(Map.Assets, MapFolder.Assets)
	createFolder("Debris", MapFolder)
	loadObjects(Map.Debris, MapFolder.Debris)
	
	--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜
	
	-- Apply map data
	_G.Remotes.cl:InvokeClient(_G.Player, 0, "load_map")
	
	-- Delay
	task.wait(1)
	
	-- Finally, set gravity and global wind. Objects leave the 'paused physics'
	-- pseudostate after the map has fully finished loading.
	workspace.Gravity = MapLighting.Gravity.Value
	workspace.GlobalWind = MapLighting.GlobalWind.Value
	if RootPart then RootPart.Anchored = false end
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- SV

module["save_settings"] = function(userCalled)
	
	-- Update 'gameSettings'
	gameSettings = _G.Remotes.cl:InvokeClient(_G.Player, 0, "get", "setting")
	
	-- Save 'gameSettings' to DataStore
	local success, response local count = 0
	while not success do -- Retry if pcall fails
		
		-- Message
		if count < 7 and count >= 1 then -- Error message each time pcall fails
			
			output("Failed to save game settings to DataStore. Retrying... ("..count..")   ---   "..response, "error")
			task.wait(5) -- Request delay
		elseif count ~= 0 then
			
			output("Failed to save game settings to Datastore'. Try again, or report this error.   ---   "..response, "error")
			break
		end
		
		-- Call
		success, response = pcall(function()
			
			if first_gameSettings then -- If player's first time (SetAsync)
				
				return gameSettingsStore:SetAsync(_G.Player.UserId, gameSettings)
			else -- Has played before (UpdateAsync)
				
				return gameSettingsStore:UpdateAsync(_G.Player.UserId, function() return gameSettings end)
			end
		end) count += 1
	end
	
	-- Output message
	if userCalled or count >= 2 then output("Settings successfully saved.") end
	
	-- Delay
	task.wait(1)
end

module["clear_settings"] = function(userCalled)
	
	if not first_gameSettings then -- Not deleted yet
		
		-- Call
		local success, response = pcall(function()
			
			return gameSettingsStore:RemoveAsync(_G.Player.UserId)
		end)
		
		-- Message
		if success then
			
			gameSettings = {}
			first_gameSettings = true
			if userCalled then output("Settings successfully cleared.") end
		else
			
			output("Failed to clear game settings. Try again later.   ---   "..response, "error")
		end
	elseif userCalled then -- No settings
		
		output("No settings to clear.")
	end
	
	-- Delay
	task.wait(1)
end

module["lock_game"] = function(userCalled, name, bool)
	
	-- Validate lock
	local locked = gameSaves[name].info.locked
	if locked == bool then
		if userCalled then output("This save is already "..(locked and "locked." or "unlocked."), "error") end
	return end
	
	-- Lock/unlock save
	gameSaves[name].info.locked = bool
	
	-- Save to DataStore
	locked = gameSaves[name].info.locked
	if module.saveGames() and userCalled then output("Save successfully "..(locked and "locked." or "unlocked.")) end
end

module["rename_game"] = function(userCalled, name, newName)
	
	-- Don't run if locked
	if gameSaves[name].info.locked then if userCalled then output("This save is locked.", "error") end return end
	
	-- Rename save
	local copy = gameSaves[name] -- Create copy
	gameSaves[name] = nil -- Delete original
	gameSaves[newName] = copy -- Create save with new name and copied properties (rename save)
	gameSaves[newName].info.name = newName -- Update 'name' in info
	
	-- Update client
	_G.Remotes.cl:InvokeClient(_G.Player, 1, list()) -- Update quick reference
	if currentSave == name then -- If current save was renamed
		
		_G.Remotes.cl:InvokeClient(_G.Player, 2, newName) -- Update 'sv.currentSave'
		currentSave = newName
	end
	
	-- Save to DataStore
	if module.saveGames() and userCalled then output("Save renamed to \""..newName.."\"") end
end

module["delete_game"] = function(userCalled, name)
	
	-- Don't run if locked
	if gameSaves[name].info.locked then if userCalled then output("This save is locked.", "error") end return end
	
	-- Delete save
	gameSaves[name] = nil
	
	-- Update quick reference
	_G.Remotes.cl:InvokeClient(_G.Player, 1, list())
	
	-- Save to DataStore
	if module.saveGames() and userCalled then output("Save successfully deleted.") end
end

module["clear_games"] = function(userCalled)
	
	-- Clear all unlocked saves
	local count = 0
	for n, v in pairs(gameSaves) do
		
		-- Skip current save
		if n == currentSave then continue end
		
		-- Delete unlocked saves
		if not v.info.locked then gameSaves[n] = nil count += 1 end
	end
	
	-- Don't run if no saves were deleted
	if count == 0 then if userCalled then output("0 saves deleted.") end return end
	
	-- Update quick reference
	_G.Remotes.cl:InvokeClient(_G.Player, 1, list())
	
	-- Save to DataStore
	if module.saveGames() and userCalled then output(count.." save"..(count ~= 1 and "s" or "").." deleted.") end
end

module["load_game"] = function(userCalled, name)
	
	local data = gameSaves[name].data
	local Map = _G.Maps:FindFirstChild(data["sv.data.currentMap"])
	
	-- LoadingSequence
	_G.Events.LoadingSequence:FireClient(_G.Player, true, Map.Name, name)
	
	-- Clear data
	_G.Remotes.cl:InvokeClient(_G.Player, 0, "clear")
	
	-- Load data
	_G.Remotes.cl:InvokeClient(_G.Player, 0, "load", data)
	
	-- Update current save
	_G.Remotes.cl:InvokeClient(_G.Player, 2, name) -- Update 'sv.currentSave'
	currentSave = name
	
	-- Load map
	removeChar()
	module.change_map(Map, data)
	
	-- LoadingSequence
	_G.Events.LoadingSequence:FireClient(_G.Player, false, Map.Name, name)
	output("\""..currentSave.."\" loaded.")
end

module["save_game"] = function(userCalled, name)
	
	if name and gameSaves[name] ~= nil then -- Overwriting a save
		
		-- Don't run if locked
		if gameSaves[name].info.locked then if userCalled then output("This save is locked.", "error") end return end
		
		-- Update save
		gameSaves[name].data = _G.Remotes.cl:InvokeClient(_G.Player, 0, "get", "save")
		gameSaves[name].info.overwrites += 1
		gameSaves[name].info.last_saved = os.time()
		gameSaves[name].info.original = name == currentSave and gameSaves[name].info.original or false
		
		-- Save to DataStore
		if module.saveGames() then -- If saved to DataStore
			
			if userCalled then output("Game successfully saved."..(name ~= currentSave and " \""..name.."\" overwritten." or "")) end
			_G.Remotes.cl:InvokeClient(_G.Player, 2, name) -- Update 'sv.currentSave'
			currentSave = name
		end
	else -- Making a new save
		
		-- Create save
		name = name or "save"..os.date("%Y%m%d_%X", os.time()):gsub(":", "") -- save20231023_055846
		gameSaves[name] = {
			
			["info"] = {
				
				["name"] = name,
				["locked"] = false,
				["original"] = not currentSave and true or false,
				["overwrites"] = 0,
				["created"] = os.time(),
				["last_saved"] = os.time(),
				["elapsed_time"] = 0, -- needs work
				["cheated"] = false -- needs work
			},
			
			["data"] = _G.Remotes.cl:InvokeClient(_G.Player, 0, "get", "save")
		}
		
		-- Save to DataStore
		if module.saveGames() then -- If saved to DataStore
			
			if userCalled then output("New game successfully saved: "..name) end
			_G.Remotes.cl:InvokeClient(_G.Player, 2, name) -- Update 'sv.currentSave'
			currentSave = name
		end
	end
end

module["saveGames"] = function()
	
	local success, response local count = 0
	while not success do -- Retry if pcall fails
		
		-- Message
		if count < 7 and count >= 1 then -- Error message each time pcall fails
			
			output("Failed to save games to DataStore. Retrying... ("..count..")   ---   "..response, "error")
			task.wait(5) -- Request delay
		elseif count ~= 0 then
			
			output("Failed to save games to Datastore'. Try again, or report this error.   ---   "..response, "error")
			break
		end
		
		-- Call
		success, response = pcall(function()
			
			if first_gameSaves then -- If player's first time (SetAsync)
				
				return gameSavesStore:SetAsync(_G.Player.UserId, gameSaves)
			else -- Has played before (UpdateAsync)
				
				return gameSavesStore:UpdateAsync(_G.Player.UserId, function() return gameSaves end)
			end
		end) count += 1
	end
	
	-- Success or fail
	if success then
		
		_G.Remotes.cl:InvokeClient(_G.Player, 1, list()) -- Update quick reference
		return true
	end
end

module["loadStores"] = function()
	
	-- Get 'gameSettings' store
	local success, response local count = 0
	while not success do -- Retry if pcall fails
		
		if count >= 1 then -- Error message each time pcall fails
			
			output("Failed to get game settings from DataStore. Retrying... ("..count..")   ---   "..response, "error")
			task.wait(5) -- Request delay
		end
		
		success, response = pcall(function() gameSettings = gameSettingsStore:GetAsync(_G.Player.UserId) end)
		count += 1
	end
	
	-- Get 'gameSaves' store
	success, response, count = nil, nil, 0
	while not success do -- Retry if pcall fails
		
		if count >= 1 then -- Error message each time pcall fails
			
			output("Failed to get saved games from DataStore. Retrying... ("..count..")   ---   "..response, "error")
			task.wait(5) -- Request delay
		end
		
		success, response = pcall(function() gameSaves = gameSavesStore:GetAsync(_G.Player.UserId) end)
		count += 1
	end if gameSaves then first_gameSaves = false else gameSaves = {} end
	
	-- Update quick reference
	_G.Remotes.cl:InvokeClient(_G.Player, 1, list())
	
	-- Set defaults
	_G.Remotes.cl:InvokeClient(_G.Player, 0, "default")
	
	-- Load in game settings
	if gameSettings then
		
		first_gameSettings = false
		_G.Remotes.cl:InvokeClient(_G.Player, 0, "load", gameSettings)
	else gameSettings = {} end
	
	-- Fix part replication bug
	loadChar() removeChar()
	
	-- Client startup
	_G.Events.FrameworkLoaded:FireClient(_G.Player)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function removeChar()
	
	if _G.Player.Character then
		
		_G.Player.Character = nil
	end
end

function loadChar()
	
	removeChar()
	_G.Player:LoadCharacter()
	_G.Player.CharacterAppearanceLoaded:Wait()
end

function list()
	
	local list = {} for n in pairs(gameSaves) do table.insert(list, n) end
	
	return list
end

function output(message: string, category: (Color3 | string)?)
	
	_G.Events.ServerOutput:FireClient(_G.Player, message, category)
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
