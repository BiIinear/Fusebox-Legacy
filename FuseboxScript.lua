
-- All global variables (_G) are defined here
-- The directory is defined here
-- All 'startup' cvars are called here

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local RepStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

_G.Player = game:GetService("Players").LocalPlayer
_G.Events = RepStorage:WaitForChild("Events")
_G.Remotes = RepStorage:WaitForChild("Remotes")
_G.Assets = RepStorage:WaitForChild("Assets")
_G.dir = {}

_G.Controllers = {["Assets"] = {}, ["Maps"] = {}}

local startup = {}
local extraUtil = {}
local fbdir

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- SETTING UP

-- Set interface
game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
workspace.CurrentCamera.CameraSubject = workspace
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

-- Check dir and get extra utils
local dir = RepStorage:WaitForChild("dir")
for _, Obj in pairs(dir:GetChildren()) do
	
	if Obj:IsA("ModuleScript") then -- Dev module
		
		if table.find({"con", "sv"}, Obj.Name) then -- Should not be named this
			
			error("Modules should not be named \"con\" or \"sv\".")
		elseif string.match(Obj.Name, "^util") then -- Extra utils
			
			local devUtil = require(Obj) -- Require to get content
			for cvar, cont in pairs(devUtil) do
				
				extraUtil[cvar] = cont -- Add to table so it can be added to util
			end
			
			Obj:Destroy()-- Delete extra util module
		end
	elseif Obj:IsA("Folder") and Obj.Name == "fbdir" and fbdir == nil then -- fbdir folder
		
		fbdir = Obj -- Makes sure there isn't another 'fbdir'
	else -- Invalid object
		
		error("Invalid object in dir: "..Obj.Name)
	end
end

-- Move main modules to dir
for _, Obj in pairs(fbdir:GetChildren()) do Obj.Parent = dir end fbdir:Destroy()

-- Create directory
for _, Module in pairs(dir:GetChildren()) do
	
	-- Add module to directory
	_G.dir[Module.Name] = require(Module)
	
	-- Get startup cvars
	for _, cvar in pairs(_G.dir[Module.Name]) do
		if type(cvar) == "table" and type(cvar.var) == "function" and cvar.startup then table.insert(startup, cvar) end
	end
	
	-- Function for requiring directories
	local require_dir = {} require_dir[1] = function(module, pos) -- Had to make it a table so I could clone functions
		
		local children = module:GetChildren()
		for _, child in pairs(children) do
			
			-- Add child module to directory
			pos[child.Name] = require(child)
			
			-- Get startup cvars
			for _, cvar in pairs(pos[child.Name]) do
				if type(cvar) == "table" and type(cvar.var) == "function" and cvar.startup then table.insert(startup, cvar) end
			end
			
			-- Repeat process
			pos[child.Name].require_dir = require_dir
			pos[child.Name].require_dir[1](child, pos[child.Name])
		end
		
		-- Erase contents but keep the variable. "require_dir" lets the system know that it's a module
		pos.require_dir = true
	end
	
	-- Define and call the function "require_dir" to begin
	_G.dir[Module.Name].require_dir = require_dir
	_G.dir[Module.Name].require_dir[1](Module, _G.dir[Module.Name])
end

-- Add extra utils
for cvar, cont in pairs(extraUtil) do
	
	if _G.dir.util[cvar] ~= nil then error("Cannot add util."..cvar.."; already existing utility.")
	else _G.dir.util[cvar] = cont end
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- EVENTS

_G.Events.FrameworkLoaded.OnClientEvent:Connect(function()
	
	for _, cvar in pairs(startup) do cvar.var() end -- Startup modules
	_G.dir.con.submit.var(_G.dir.util.ros.var) -- Startup cmd
	--_G.Player.PlayerGui:FindFirstChild("ReplicatedFirstGui"):Destroy()
end)

_G.Remotes.cl.OnClientInvoke = function(x, arg1, arg2, arg3)
	
	if x == 0 then -- Calling sv '_data' cvars
		
		return _G.dir.sv[arg1.."_data"].var(arg2, arg3)
	elseif x == 1 then -- Updating 'sv.quickref'
		
		_G.dir.sv.quickref.var = arg1
	elseif x == 2 then -- Updating 'sv.currentSave'
		
		_G.dir.sv.currentSave.var = arg1
	end
end

_G.Player:GetPropertyChangedSignal("Character"):Connect(function() -- Character removed/loaded
	
	if _G.Player.Character == nil then -- Remove character
		
		workspace.CurrentCamera.FieldOfView = 70
		workspace.CurrentCamera.CameraSubject = workspace
		workspace.CurrentCamera.CFrame = CFrame.new(0, 0, 0)
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
	else -- Load character
		
		workspace.CurrentCamera.FieldOfView = 70
		workspace.CurrentCamera.CameraSubject = _G.Player.Character:WaitForChild("Humanoid")
		workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
	end
end)

_G.Events.LoadingSequence.OnClientEvent:Connect(function(state, toMap, toSave)
	
	if state then -- Changing maps/saves
		
		-- Don't run if it's loading the first map of a session
		local currentMap = workspace.CurrentMap:FindFirstChildOfClass("Folder")
		if not currentMap then return end
		
		-- Cleanup map
		_G.Controllers.Maps[currentMap.Name].cleanup()
	else -- Finished loading
		
		-- Get map controller
		if not _G.Controllers.Maps[toMap] then
			
			_G.Controllers.Maps[toMap] = require(RepStorage.MapControllers[toMap])
		end
		
		-- Startup map
		_G.Controllers.Maps[toMap].startup()
	end
end)
