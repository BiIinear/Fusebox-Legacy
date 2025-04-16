


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Console = _G.Player.PlayerGui:WaitForChild("Console")
local CmdLine = Console.MainFrame:WaitForChild("CommandLine")
local Output = Console.MainFrame:WaitForChild("Output")

local Mouse = _G.Player:GetMouse()

local listeners = {}
local firstToggle = false

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["enabled"] = {
	
	desc = "Enables the Fusebox console.",
	
	var = true
}

module["toggle_key"] = {
	
	desc = "The keybind to toggle the Fusebox console.",
	
	var = Enum.KeyCode.Backquote,
	
	cheat = false,
	setting = true
}

module["auto_focus"] = {
	
	desc = "Automatically focus on the command line after opening the console or submitting a command.",
	
	var = true,
	
	cheat = false,
	setting = true
}

module["backg_transp"] = {
	
	desc = "Background transparency of the console.",
	
	var = .35,
	
	cheat = false,
	setting = true
}

module["text_colors"] = {
	
	desc = "Output text colors.",
	
	var = {

		["command_color"] = Color3.fromRGB(255, 255, 255),
		["info_color"] = Color3.fromRGB(165, 165, 165),
		["error_color"] = Color3.fromRGB(255, 100, 100)
	},
	
	cheat = false,
	setting = true
}

module["startup"] = {
	
	desc = "Creates RbxScriptSignals for the console.",
	
	var = function()
		
		-- Console function
		UIS.InputBegan:Connect(function(input, gameEvent)
			
			-- Functionality
			local key = input.KeyCode.Name
			if Console.MainFrame.Visible and gameEvent then
				
				if key == "Return" then
					
					module.submit.var()
				elseif key == "Up" then
					
					module.scroll_history.var(true)
				elseif key == "Down" then
					
					module.scroll_history.var()
				end
			end
			
			-- Keybinds
			if input.KeyCode == module.toggle_key.var and not gameEvent then -- If toggling the console
				
				module.toggle.var()
			elseif _G.dir.util.binds.var[key] and not gameEvent then -- If input has a bound command
				
				module.submit.var(_G.dir.util.binds.var[key])
			end
		end)
		
		-- Output from the server-side
		_G.Events.ServerOutput.OnClientEvent:Connect(function(message, category)
			
			_G.dir.con.print.var(message, category)
		end)
	end,
	
	startup = true
}

module["toggle"] = {
	
	desc = "Toggles the Fusebox console.",
	
	params = "boolean?", var = function(userCalled, bool)
		
		-- Don't run if console isn't enabled
		if not module.enabled.var then return end
		
		-- Define 'bool' if it's nil
		if bool == nil then bool = not Console.MainFrame.Visible end
		
		-- Toggle console
		Console.MainFrame.Visible = bool
		
		-- Auto focus and events
		if Console.MainFrame.Visible then -- Console opened
			
			RunService.RenderStepped:Wait()
			if module.auto_focus.var then CmdLine:CaptureFocus() end -- Auto focus
			_G.Events.ConsoleOpened:Fire() -- ConsoleOpen event
			
			local function autofillEvents() -- When predictions are interacted with
				
				local Autofill = Console.MainFrame.Autofill:GetChildren()
				for _, Object in pairs(Autofill) do
					
					if not Object:IsA("UIListLayout") then -- Prevents a dumb error
						
						Object.MouseEnter:Connect(function() -- Mouse hover
							
							module.autofill.pred_hover.var(Object)
						end)
						
						Object.MouseLeave:Connect(function() -- Mouse leave
							
							module.autofill.pred_leave.var(Object)
						end)
						
						Object.MouseButton1Click:Connect(function() -- Mouse left click
							
							module.autofill.pred_click.var(Object)
						end)
					end
				end
			end
			
			-- First toggle
			if not firstToggle then firstToggle = true _G.dir.con.autofill.search.var() autofillEvents() end
			
			-- Connect signals
			listeners = {
				
				Mouse.Button1Down:Connect(function() -- Resizing the console
					
					module.resize.var(true)
				end),
				UIS.InputEnded:Connect(function(input) -- Resizing the console
					
					-- Immediately updates background transparency
					Console.MainFrame.BackgroundTransparency = module.backg_transp.var
					CmdLine.BackgroundTransparency = module.backg_transp.var
					
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						
						module.resize.var()
					end
				end),
				CmdLine:GetPropertyChangedSignal("CursorPosition"):Connect(function() -- Autofill feature
					
					task.wait() -- Prevents delay in updating predictions
					if CmdLine:IsFocused() then
						
						module.autofill.search.var()
					end
					
					autofillEvents()
				end)
			}
		elseif not Console.MainFrame.Visible then -- Console closed
			
			RunService.RenderStepped:Wait()
			CmdLine:ReleaseFocus()
			_G.Events.ConsoleClosed:Fire() -- ConsoleClose event
			
			-- Disconnect signals
			module.resize.dragging = false
			for _, v in pairs(listeners) do v:Disconnect() end listeners = {}
		end
	end,
	
	cheat = false
}

module["submit"] = {
	
	desc = "Submits the text written in the command line.",
	
	var = function(text)
		
		-- text == nil means the player submitted a command
		if text == nil then
			
			-- Don't submit if the command line is empty
			if string.match(CmdLine.Text, "^%s*$") then return end
			
			text = CmdLine.Text
			CmdLine.Text = "" -- Clear CmdLine
			module.scroll_history.pos = 0 -- Refresh scrolling history
			if module.auto_focus.var then RunService.RenderStepped:Wait() CmdLine:CaptureFocus() end -- Auto focus
			output("> "..text, "command") -- Echo command
			table.insert(module.history.var, text) -- Add to history
			module.autofill.pred_clear.var() -- Clear predictions
		end
		
		-- Get path, cvar, and chain
		local path, args, chain = module.parse.var(text)
		local cvar, val = module.query.var(nil, path, 1, true)
		
		-- Check cvar
		if cvar ~= nil then -- If cvar exists
			
			local dtype = type(cvar.var)
			if dtype == "table" then -- Table cvar
				
				if not module.sanity_check.var(cvar) then return end -- Sanity check
				
				if cvar.var[val] ~= nil then -- If table value exists
					
					if type(cvar.var[val]) ~= "function" then -- Don't run if the table value is a function
						
						local oldvar = cvar.var[val]
						dtype = typeof(oldvar) == "EnumItem" and module.autofill.enumTostring(oldvar) or typeof(oldvar)
						cvar.var[val] = unpack(module.datatype.process.var(dtype, args, oldvar))
						module.prompt.var(cvar.var[val], oldvar, path[#path])
					else -- Table value is a function
						
						output("Restricted command variable.", "error")
					end
				else -- Table value does not exist
					
					output("Unknown command variable.", "error")
				end
			elseif dtype == "function" then -- Function cvar
				
				if not module.sanity_check.var(cvar) then return end -- Sanity check
				
				local t = module.datatype.process.var(cvar.params, args) -- Can't use unpack() because it's so bad
				cvar.var(true, t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12], t[13], t[14], t[15], t[16])
			else -- Basic cvar
				
				if not module.sanity_check.var(cvar) then return end -- Sanity check
				
				local oldvar = cvar.var
				dtype = typeof(oldvar) == "EnumItem" and module.autofill.enumTostring(oldvar) or typeof(oldvar)
				cvar.var = unpack(module.datatype.process.var(dtype, args, oldvar))
				module.prompt.var(cvar.var, oldvar, path[#path])
			end
		else -- Cvar does not exist
			
			output("Unknown command variable.", "error")
		end
		
		-- Submit chained commands (if there are any)
		if chain ~= nil then module.submit.var(chain) end
	end
}

module["parse"] = {
	
	desc = "Processes the given command and returns the path, arguments, and chained commands.",
	
	var = function(text)
		
		-- echo "i am \"gay\"" Color3.fromHex("#0077FF")
		-- bind Enum.KeyCode.T "blink; echo \"blinked!\" Color3.fromRGB(0, 100, rand(0, 255))"; close
		-- echo "blinked!" Color3.fromRGB(0, 100, rand(0, 255))
		
		-- Don't run if text is empty
		if type(text) ~= "string" or text:match("^%s*$") then return {} end
		
		local escKey = module.generateKey()
		local quoteKey = module.generateKey()
		local paramKey = module.generateKey()
		local quotes, params = {}, {}
		
		text = text:gsub("^%s+", ""):gsub("\\\"", escKey)
		text = text:gsub("%b\"\"", function(match) table.insert(quotes, match) return quoteKey end)
		for i = 1, #quotes do quotes[i] = quotes[i]:gsub(escKey, "\\\"") end text = text:gsub(escKey, "\\\"")
		local chain = text:split(";") local path = chain[1]:split(" ")[1]:split(".")
		
		local args = chain[1] table.remove(chain, 1) chain = table.concat(chain, ";")
		args = args:gsub("^%S* *", ""):gsub(" +", " ")
		args = args:gsub("%S*%(.-%)+", function(match) table.insert(params, match) return paramKey end)
		args = args:split(" ") if args[1] == "" then args = {} elseif args[#args] == "" then table.remove(args, #args) end
		for i = 1, #args do args[i] = args[i]:gsub(paramKey, function() local v = params[1] table.remove(params, 1) return v end) end
		for i = 1, #args do args[i] = args[i]:gsub(quoteKey, function() local v = quotes[1] table.remove(quotes, 1) return v end) end
		
		if not chain:match("^%s*$") then
			chain = chain:gsub(quoteKey, function() local v = quotes[1] table.remove(quotes, 1) return v end)
		else chain = nil end
		
		return path, args, chain
	end
}

module["query"] = {
	
	desc = "Checks if the given path is valid, then returns the cvar/module.",
	
	var = function(pos, path, i, getCvar)
		
		if getCvar then -- Get cvar
			
			pos = pos or _G.dir
			if pos[path[i]] or _G.dir.util[path[i == 1 and 1]] then -- Check next position in path
				
				local cvar = pos[path[i]] or _G.dir.util[path[1]]
				if type(cvar) ~= "table" then return end -- Prevent getting non-cvars
				if cvar.require_dir then -- If current position is a module
					
					return module.query.var(cvar, path, i + 1, getCvar) -- Recurse
				elseif type(cvar.var) ~= "table" and path[i + 1] == nil -- Basic cvar
					or type(cvar.var) == "table" and path[i + 2] == nil then -- Table cvar
					
					return cvar, path[i + 1] -- Found cvar
				end
			else return end -- Did not find cvar
		else -- Get module or table cvar (modified version)
			
			pos = pos or _G.dir
			if pos[path[i]] then -- Check next position in path
				
				local npos = pos[path[i]]
				if type(npos) ~= "table" then return end -- Prevent getting non-cvars
				if npos.require_dir or type(npos.var) == "table" then -- If current position is a module or table cvar
					
					if path[i + 1] == nil then return npos -- Return position
					else return module.query.var(npos, path, i + 1, getCvar) end -- Recurse; not finished
				else return end -- Did not find next position
			elseif pos == _G.dir and path[i] == nil then return _G.dir end -- Return dir if at beginning
		end
	end
}

module["sanity_check"] = {
	
	desc = "Sanity check when submitting a command.",
	
	var = function(cvar)
		
		if cvar.cheat ~= nil then -- If cvar can be used
			
			if cvar.connect == nil or cvar.connect and _G.Player.Character ~= nil then
				
				if cvar.setting == nil and cvar.cheat then -- If cvar is a cheat
					
					if _G.dir.sv.cheats.var then -- If cheats are on
						
						return true
					else -- Cheats are off
						
						output("Cheats are disabled.", "error")
					end
				elseif cvar.setting or not cvar.cheat then -- Cvar is not a cheat command; no further security needed
					
					return true
				end
			elseif cvar.connect and _G.Player.Character == nil then -- Character is not loaded
				
				output("Character not loaded.", "error")
			end
		else -- Cvar is a hidden cvar
			
			output("Restricted command variable.", "error")
		end
	end
}

module["print"] = {
	
	desc = "Prints a new line of text in the output.",
	
	var = function(message, category, bar) -- If 'category' is nil, it defaults to "info"
		
		-- category can be a Color3 or string
		category = category or "info"
		local name = type(category) == "string" and category or "color"
		
		-- Create new line
		local Line = Output.Prefab:Clone()
		Line.Name = name.."_"..tick()
		Line.RichText = false
		Line.Text = " "..message:gsub("\n", "\n ") -- Space at the beginning for 'optin' messages
		Line.LineHeight = 1.7
		local lines = 1 for line in Line.Text:gmatch("\n") do lines += 1.15 end
		Line.Size = UDim2.new(1, 0, 0, Output.Prefab.Size.Y.Offset * lines)
		Line.TextColor3 = typeof(category) == "Color3" and category or module.text_colors.var[category.."_color"]
		Line.Parent = Output
		
		-- Bar ('optin' util cvar only)
		if bar then
			
			Line.Bar.Visible = true
			Line.Bar.BackgroundColor3 = bar
		end
		
		-- Scroll output
		Output.CanvasPosition += Vector2.new(0, Output.Prefab.Size.Y.Offset * lines)
	end
}

module["prompt"] = {
	
	desc = "Prompt a message after editing a command variable.",
	
	var = function(var, oldvar, name)
		
		if var == oldvar then -- If there was an error
			
			output("Invalid argument.", "error")
		else -- Edited successfully
			
			output(name.." set to "..module.datatype["type_"..typeof(var)].str(var))
		end
	end
}

module["resize"] = {
	
	dragging = false,
	
	desc = "Resizes the console when dragging on the edge.",
	
	var = function(dragging)
		
		if dragging then -- If left mouse button is held down
			
			local frames = _G.Player.PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y) -- Get gui that mouse is hovering over
			for _, frame in pairs(frames) do
				
				if frame:IsA("Frame") and frame.Name == "ResizeDrag" then -- If gui is the resize frame
					
					module.resize.dragging = true
					while module.resize.dragging do
						
						Console.MainFrame.Size = UDim2.new(1, 0, 0, math.max(20, Mouse.Y - 26))
						task.wait()
					end
				end
			end
		else -- Left mouse button is released
			
			module.resize.dragging = false
		end
	end
}

module["history"] = {
	
	desc = "Full list of all previously submitted commands.",
	
	var = {}
}

module["scroll_history"] = {
	
	savedCmd = "", -- Saved written command when scrolling through history
	pos = 0, -- Position in scrolling history
	
	desc = "Scroll through command history when pressing the up/down arrow key.",
	
	var = function(up)
		
		local scroll = module.scroll_history
		local history = module.history.var
		if up then -- If scrolled up
			
			if scroll.pos == 0 then -- If beginning scrolling history
				
				scroll.pos = #history
				scroll.savedCmd = CmdLine.Text
			elseif scroll.pos ~= 1 then -- If scrolling to older history
				
				scroll.pos -= 1
			end
			
			CmdLine.Text = history[scroll.pos] or CmdLine.Text -- Set command line text to history position
		else -- If scrolled down
			
			if scroll.pos ~= #history and scroll.pos ~= 0 then -- If scrolling to later history
				
				scroll.pos += 1
				CmdLine.Text = history[scroll.pos] -- Set command line text to history position
			else -- If reached latest command
				
				scroll.pos = 0
				CmdLine.Text = scroll.savedCmd -- Set command line text to saved written command
			end
		end
		
		CmdLine.CursorPosition = string.len(CmdLine.Text) + 1 -- Set cursor position in command line
	end
}

module["clear"] = {
	
	desc = "Clears the console output.",
	
	var = function()
		
		local output = Output:GetChildren()
		for i = 1, #output do -- All lines in the output
			
			if not table.find({"Layout", "Prefab"}, output[i].Name) then -- Objects that need to stay
				
				output[i]:Destroy()
			end
		end
	end,
	
	cheat = false
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

function output(message: string, category: (Color3 | string)?)
	
	module.print.var(message, category)
end

module.generateKey = function()
	
	return tostring(math.random(100000000, 999999999)) -- Large numbers to ensure randomness
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
