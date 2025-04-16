


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local ServStorage = game:GetService("ServerStorage")
local RepStorage = game:GetService("ReplicatedStorage")

local Framework = script:WaitForChild("Framework")

_G.Controllers = {["Assets"] = {}, ["Maps"] = {}}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- Move folders to their respective spots. Create events and remotes.

local dir = script.Parent:WaitForChild("dir")
dir.Parent = RepStorage

function createObj(ClassName, Name, Parent)
	
	local Obj = Instance.new(ClassName)
	Obj.Name = Name
	Obj.Parent = Parent
	
	return Obj
end

local Maps = script.Parent:WaitForChild("Maps")
Maps.Parent = ServStorage
createObj("Folder", "MapControllers", RepStorage)
for _, mapObj in pairs(Maps:GetChildren()) do
	
	_G.Controllers.Maps[mapObj.Name] = require(mapObj.Controller) -- Require controller
	mapObj.Controller.Name = mapObj.Name
	mapObj[mapObj.Name].Parent = RepStorage.MapControllers
end

local Assets = script.Parent:WaitForChild("Assets")
Assets.Parent = RepStorage
createObj("Folder", "AssetFunctions", RepStorage)
for _, assetObj in pairs(Assets:GetChildren()) do
	
	if assetObj:FindFirstChild("Controller") then
		
		_G.Controllers.Assets[assetObj.Name] = require(assetObj.Controller) -- Require controller
		assetObj.Controller.Name = assetObj.Name
		assetObj[assetObj.Name].Parent = RepStorage.AssetFunctions
	end
end

local Events = createObj("Folder", "Events", RepStorage)
createObj("RemoteEvent", "FrameworkLoaded", Events)
createObj("BindableEvent", "ConsoleOpened", Events)
createObj("BindableEvent", "ConsoleClosed", Events)
createObj("RemoteEvent", "LoadingSequence", Events) -- return [state: boolean] [toMap: string] [toSave: string?]
createObj("RemoteEvent", "ServerOutput", Events) -- return [message: string] [category: (Color3|string)?]

local Remotes = createObj("Folder", "Remotes", RepStorage)
createObj("RemoteFunction", "cl", Remotes) -- SERVER TO CLIENT
createObj("RemoteFunction", "sv", Remotes) -- CLIENT TO SERVER
createObj("RemoteFunction", "list_maps", Remotes) -- return {string, ...}
createObj("RemoteFunction", "change_map", Remotes) -- usage [map: string]
createObj("RemoteFunction", "list_settings", Remotes) -- return {string, ...}
createObj("RemoteFunction", "list_assets", Remotes) -- return {string, ...}
createObj("RemoteFunction", "get_asset", Remotes) -- return Instance:Model
createObj("RemoteFunction", "game_info", Remotes)
createObj("RemoteFunction", "game_data", Remotes)

createObj("Folder", "CurrentMap", workspace)

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- Move fbdir to dir. Move scripts to respective spots and activate.

Framework:WaitForChild("fbdir").Parent = dir

game:GetService("Players").PlayerAdded:Connect(function(player)
	
	Framework:WaitForChild("Console").Parent = player.PlayerGui
end)

local RemotesScript = Framework:WaitForChild("RemotesScript")
RemotesScript.Parent = game:GetService("ServerScriptService")
RemotesScript.Enabled = true

local FuseboxScript = Framework:WaitForChild("FuseboxScript")
FuseboxScript.Enabled = true
FuseboxScript.Parent = game:GetService("StarterPlayer").StarterPlayerScripts

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUSEBOX LOADED
