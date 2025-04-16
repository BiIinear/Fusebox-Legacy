


--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- VARIABLES

local module = {}

local Console = _G.Player.PlayerGui:WaitForChild("Console")
local CmdLine = Console.MainFrame:WaitForChild("CommandLine")
local Autofill = Console.MainFrame:WaitForChild("Autofill")
local Description = Console.MainFrame:WaitForChild("Description")

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- COMMAND VARIABLES

module["enabled"] = {
	
	desc = "Enables the autofill feature.",
	
	var = true,
	
	cheat = false,
	setting = true
}

module["show_all"] = {
	
	desc = "Shows all hidden command variables.",
	
	var = false,
	
	cheat = false,
	setting = true
}

module["highlight_color"] = {
	
	desc = "Prediction highlighting color.",
	
	var = Color3.fromRGB(45, 65, 125),
	
	cheat = false,
	setting = true
}

module["search"] = {
	
	link = 1,
	preds = {},
	
	desc = "Search the module/table before creating predictions.",
	
	var = function()
		
		-- Delete old predictions
		if CmdLine:IsFocused() then module.pred_clear.var() end
		
		-- Do not run if 'con.autofill.enabled' is false
		if not module.enabled.var then return end
		
		-- Get link from chained command
		local link = CmdLine.Text:gsub("\\\"", "__"):gsub("%b\"\"", function(match) return match:gsub(".", "_") end)
		module.search.link = #link:sub(1, CmdLine.CursorPosition - 1):split(";")
		local path = link:split(";")[module.search.link]:gsub("^%s+", ""):split(" ")[1]:split(".")
		local typing = path[#path] table.remove(path, #path)
		
		-- Start searching
		local pos = _G.dir.con.query.var(nil, path, 1)
		if pos ~= nil then -- If position was found
			
			for name, val in pairs(type(pos.var) == "table" and pos.var or pos) do -- 'pos.var' is table cvars, 'pos' is modules
				
				if type(val) == "table" and val.var ~= nil -- If value is a cvar
					or type(val) == "table" and val.require_dir -- Or module
					or type(pos.var) == "table" then -- Or table value
					
					if string.find(name, typing, 1, true) then -- If #path matches name of value
						
						if module.show_all.var or type(pos.var) == "table" or val.cheat ~= nil or val.require_dir then
							
							local value if type(pos.var) == "table" then value = val else value = nil end -- Fixes a bug (val == false)
							module.pred_create.var(name, type(val) == "table" and val or pos, value)
						end
					end
				end
			end
		end
		
		-- Enable scrolling if there's many predictions
		local t_autofill = Console.MainFrame.Autofill:GetChildren()
		if #t_autofill >= 12 then -- If predictions clip out of autofill frame
			
			Autofill.ScrollingEnabled = true
		else -- If all predictions fit in autofill frame
			
			Autofill.ScrollingEnabled = false
			Autofill.CanvasPosition = Vector2.new(0, 0)
		end
	end
}

module["pred_create"] = {
	
	desc = "Creates a new prediction.",
	
	var = function(name, cvar, val)
		
		local dtype = typeof(cvar.var)
		local function getAmount(cvar) -- Get amount in table cvar or module
			
			local amount = 0
			for _, v in pairs(cvar.var or cvar) do
				
				if type(v) == "table" and v.var ~= nil or type(v) == "table" and v.require_dir then -- v is module or cvar
					
					amount += 1
				elseif type(cvar.var) == "table" then -- cvar is table cvar
					
					amount += 1
				end
			end
			
			return amount
		end
		
		-- Create parameters
		local params
		if cvar.params ~= nil and dtype ~= "table" then -- If cvar has predefined parameters
			
			-- It seems like a better idea to just display the params string instead of doing all of this.
			-- I'd rather do this because I might change some formatting around and I don't want any old
			-- formats lying around in newer versions of Fusebox. (7/23/23)
			
			params = "["..cvar.params:gsub("%s*", ""):gsub(":", ": "):gsub(",", "] [").."]"
		elseif dtype ~= "table" then -- If cvar.var is not a table, could be a basic cvar or module
			
			params = cvar.require_dir and "["..getAmount(cvar).."]" -- module
				or dtype == "EnumItem" and "["..module.enumTostring(cvar.var).."]" -- EnumItem cvar
				or dtype ~= "function" and "["..dtype.."]" or "" -- Any other datatype
		elseif dtype == "table" and val == nil then -- If cvar.var is a table
			
			params = "["..getAmount(cvar).."]"
		else -- cvar.var is a table. Create parameters for table values
			
			params = typeof(val) == "EnumItem" and "["..module.enumTostring(val).."]" -- EnumItem table value
				or typeof(val) ~= "function" and "["..typeof(val).."]" or "" -- Any other datatype
		end
		
		-- Create icon and name
		local text = " "
		if cvar.cheat then text = _G.dir.sv.cheats.var and "🔓 " or "🔒 " end -- cheat = true
		if cvar.setting and dtype ~= "function" then text = "⚙️ " end -- setting = true
		
		if dtype == "table" and val ~= nil then -- table value
			
			text = " 📄"..text..name
		elseif dtype == "table" then -- table cvar
			
			text = " 📔"..text..name
		elseif cvar.require_dir then -- module
			
			text = " 📁 "..name
		else -- basic cvar
			
			text = " 📄"..text..name
		end
		
		-- Create prediction
		local transp = _G.dir.con.backg_transp.var
		local Object = Autofill.Prefab:Clone()
		module.search.preds[tostring(name)] = {Object, cvar, val} -- Add to predictions table
		if isHidden(cvar, val) then Object.TextTransparency = transp * 2 Object.Params.TextTransparency = transp * 2 end
		Object.Text = text
		Object.Params.Text = params.." "
		Object.Name = name
		Object.Visible = true
		Object.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		Object.BackgroundTransparency = transp
		Object.Parent = Autofill
		
		-- Extend Autofill frame if text overlaps
		local len = (text..params):len() + 1
		if len > 47 then
			
			local set = 300 + ((len - 47) * 6.3)
			if Autofill.Size.X.Offset < set then Autofill.Size = UDim2.new(0, set, 0, 250) end
		end
	end
}

module["pred_hover"] = {
	
	debounce = false,
	
	desc = "Highlights the prediction and shows the description and variable.",
	
	var = function(Object)
		
		-- Prevents a bug (function firing twice)
		if not module.pred_hover.debounce then -- If debounce is false then run function
			
			module.pred_hover.debounce = true
			task.wait()
			module.pred_hover.debounce = false
		else return end
		
		local pred = module.search.preds[Object.Name]
		local cvar = pred[2]
		
		local function createLine()
			
			local Line = Description.Prefab:Clone()
			Line.Name = Object.Name
			Line.Text.Text = cvar.desc or ""
			local lines = 1 for line in Line.Text.Text:gmatch("\n") do lines += .93 end -- Extend desc frame
			Line.Size = UDim2.new(1, -Autofill.Size.X.Offset, 0, Autofill.Prefab.Size.Y.Offset * lines)
			Line.Position = UDim2.new(0, Autofill.AbsolutePosition.X + Autofill.Size.X.Offset, 0, Object.AbsolutePosition.Y)
			Line.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			Line.BackgroundTransparency = _G.dir.con.backg_transp.var
			Line.Parent = Description
			Line.Visible = true
			
			return Line
		end
		
		-- Show cvar's description
		local Line if type(cvar.desc) == "string" then Line = createLine() end
		
		-- Show variable
		if cvar.var ~= nil and type(cvar.var) ~= "table" and type(cvar.var) ~= "function" -- If cvar is not a table nor function
			or pred[3] ~= nil and type(pred[3]) ~= "function" and type(pred[3]) ~= "table" then -- Don't show function values
			
			if not Line then Line = createLine() end
			local var if pred[3] ~= nil then var = pred[3] else var = cvar.var end -- Because of the two conditions above
			local adjustspace = Line.Text.Text:split("\n")[1]:gsub(".", " ").." "-- Show var next to desc
			Line.Value.Text = adjustspace.._G.dir.con.datatype["type_"..typeof(var)].str(var)
			Line.Value.Visible = true
		end
		
		-- Highlight prediction
		if not isHidden(cvar, pred[3]) then -- If cvar is not hidden
			
			Object.BackgroundColor3 = module.highlight_color.var
		end
	end
}

module["pred_leave"] = {
	
	desc = "Removes the highlight color and hides its description.",
	
	var = function(Object)
		
		-- Delete description
		if Description:FindFirstChild(Object.Name) and Description[Object.Name].Visible then
			
			Description[Object.Name]:Destroy()
		end
		
		-- Remove highlight
		Object.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	end
}

module["pred_click"] = {
	
	debounce = false,
	
	desc = "Autofills the command with the name of the chosen prediction.",
	
	var = function(Object)
		
		-- Prevents a bug (function firing twice)
		if not module.pred_click.debounce then -- If debounce is false then run function
			
			module.pred_click.debounce = true
			task.wait()
			module.pred_click.debounce = false
		else return end
		
		local pred = module.search.preds[Object.Name]
		
		-- Prevent autofilling with a hidden cvar
		if isHidden(pred[2], pred[3]) then return end
		
		-- Deconstruct command
		local escKey = _G.dir.con.generateKey()
		local quotes, quoteKey = {}, _G.dir.con.generateKey()
		local text = CmdLine.Text:gsub("\\\"", escKey):gsub("%b\"\"", function(match) table.insert(quotes, match) return quoteKey end)
		for i = 1, #quotes do quotes[i] = quotes[i]:gsub(escKey, "\\\"") end
		text = text:gsub(escKey, "\\\""):split(";")
		local cmd, space = text[module.search.link], ""
		cmd = cmd:gsub("^%s+", function(match) space = match return "" end)
		local args = cmd:split(" ") local path = args[1]:split(".") table.remove(args, 1) args = table.concat(args, " ")
		
		-- Autofill
		if pred[2].require_dir or type(pred[2].var) == "table" and pred[3] == nil then -- module or table
			
			path[#path] = Object.Name.."."
		else -- Basic cvar
			
			path[#path] = Object.Name.." "
		end
		
		-- Reconstruct command
		path = table.concat(path, ".")
		text[module.search.link] = space..path..args
		local cursorpos = space:len() + path:len() + 1
		for i = 1, #text do
			
			text[i] = text[i]:gsub(quoteKey, function() local quote = quotes[1] table.remove(quotes, 1) return quote end)
			if i < module.search.link then cursorpos = cursorpos + text[i]:len() + 1 end
		end text = table.concat(text, ";")
		
		-- Finish autofill
		CmdLine.Text = text
		CmdLine:CaptureFocus()
		CmdLine.CursorPosition = cursorpos
	end
}

module["pred_clear"] = {
	
	desc = "Clears all autofill predictions.",
	
	var = function()
		
		-- Delete predictions
		for i, pred in pairs(module.search.preds) do
			
			pred[1]:Destroy() -- Delete object
			module.search.preds[i] = nil -- Delete from table
		end
		
		-- Delete descriptions
		for _, desc in pairs(Description:GetChildren()) do
			
			if desc.Visible then desc:Destroy() end
		end
		
		-- Reset Autofill frame
		Autofill.Size = UDim2.new(0, 300, 0, 250)
	end
}

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- FUNCTIONS

module.enumTostring = function(var) -- Used by 'con.submit' too
	
	return tostring(var):gsub("%.%w+$", "")
end

function output(message: string, category: (Color3 | string)?)
	
	_G.dir.con.print.var(message, category)
end

function isHidden(cvar, val) -- Check if a cvar or value is hidden (not for use)
	
	if not cvar.require_dir and cvar.cheat == nil or type(val) == "function" then
		
		return true
	end
end

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

-- RETURN

return module
