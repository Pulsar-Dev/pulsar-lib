--- Logging Library. By Joshua Piper

PulsarLib = PulsarLib or {}
PulsarLib.Logging = PulsarLib.Logging or setmetatable({
	stored = {}
}, {__index = PulsarLib})

--- @class Logging
--- @field stored table A table of all stored loggers.
local logging = PulsarLib.Logging

--- Takes an arbitrary number of arguments and flattens them into a single table
--- @param ... any Arguments to flatten.
--- @return table
local function flatten(...)
	local out = {}
	local n = select('#', ...)
	for i = 1, n do
		local v = (select(i, ...))
		if istable(v) and not IsColor(v) then
			table.Add(out, flatten(unpack(v)))
		elseif isfunction(v) then
			table.Add(out, flatten(v()))
		elseif type(v) == "Player" then
			table.insert(out, team.GetColor(v:Team()))
			table.insert(out, v:Name())
			table.insert(out, " (")
			table.insert(out, v:SteamID())
			table.insert(out, ")")
			table.insert(out, logging.Colours.Text)
		else
			table.insert(out, v)
		end
	end

	return out
end
logging.flatten = flatten

--- Print a message out to console
--- @param ... any Stringable instances to print.
function logging.print(...)
	MsgC(unpack(flatten(...)))
	print()
end

logging.Levels = {
	NONE = 100,
	FATAL = 90,
	CRITICAL = 80,
	ERROR = 70,
	WARNING = 60,
	INFO = 50,
	DEBUG = 40,
	TRACE1 = 30,
	TRACE2 = 20,
	TRACE3 = 10,
	ANY = 0,
	INHERIT = -1
}
logging.Levels.DEFAULT = logging.Levels.WARNING

if PulsarLib.DevelopmentMode then
	logging.Levels.DEFAULT = logging.Levels.ANY
end

logging.Levels._MAX = logging.Levels.NONE
logging.Levels._MIN = logging.Levels.ANY

logging.Colours = {
	[logging.Levels.NONE] = Color(20, 20, 20),
	[logging.Levels.FATAL] = Color(255, 0, 0),
	[logging.Levels.CRITICAL] = Color(255, 30, 30),
	[logging.Levels.ERROR] = Color(255, 60, 60),
	[logging.Levels.WARNING] = Color(255, 200, 0),
	[logging.Levels.INFO] = Color(20, 140, 255),
	[logging.Levels.DEBUG] = Color(160, 160, 160),
	[logging.Levels.TRACE1] = Color(160, 160, 160),
	[logging.Levels.TRACE2] = Color(160, 160, 160),
	[logging.Levels.TRACE3] = Color(160, 160, 160),

	Brand = Color(2, 153, 204),
	Client = Color(222, 169, 9),
	Server = Color(3, 169, 224),

	Text = Color(200, 200, 200),
	Highlights = Color(206, 192, 0),
	Disabled = Color(20, 20, 20),
}

--- Parse a logging name to a level.
--- @param level string|number
--- @return number|string|nil
function logging:Parse(level)
	if level == "INHERIT" or level == -1 then
		return nil
	end


	local numLevel = tonumber(level)
	if numLevel ~= nil then
		level = numLevel
	end


    if isnumber(level) then
        local numLevel = tonumber(level)
        if numLevel ~= nil then
            return math.Clamp(numLevel, self.Levels._MIN, self.Levels._MAX)
        end
    end

    if self.Levels[level] then
        return self.Levels[level]
    end

	-- If we cannot parse the log level, return back to inheriting.
	-- Internally, the root logger will return the default level, so no worries there.
	return nil
end

--- Build the logging method for a given level.
--- @param component string The component name to build for.
--- @param level number|string Required logging level.
--- @return function
function logging:Build(component, level)
	local levelValue = isnumber(level) and level or self.Levels[level:upper()]

	local args = {}
	table.insert(args, self.Functional.partial(self.Brand, self, true))
	table.insert(args, self.Colours.Text)
	table.insert(args, "[")

	if SERVER then
		table.insert(args, self.Colours.Server)
		table.insert(args, "SERVER")
		table.insert(args, self.Colours.Text)
		table.insert(args, "][")
	end
	if CLIENT then
		table.insert(args, self.Colours.Client)
		table.insert(args, "CLIENT")
		table.insert(args, self.Colours.Text)
		table.insert(args, "][")
	end

	if component and component ~= "" then
		table.insert(args, component)
		table.insert(args, "][")
	end

	if self.Colours[levelValue] then
		table.insert(args, self.Colours[levelValue])
		table.insert(args, level:upper())
		table.insert(args, self.Colours.Text)
		table.insert(args, "] ")
	else
		table.insert(args, level .. "] ")
	end

	local prt = self.Functional.partial(logging.print, args)
	return function(logger, ...)
		if (select(1, ...)) == true then
			prt(select(2, ...))
			return logger
		end

		if logger:GetEffectiveLevel() > levelValue then
			return logger
		end

		prt(...)
		return logger
	end
end

--- @class Logger
--- @field name string
--- @field level number|string
--- @field Trace1 function
--- @field Trace2 function
--- @field Trace3 function
--- @field Debug function
--- @field Info function
--- @field Warning function
--- @field Error function
--- @field Critical function
--- @field Fatal function
local logger = {}
logger.__index = logger

--- Create a new logger instance.
--- @param name string
--- @param loggingMeta Logging
function logger:New(name, loggingMeta)
	local log = setmetatable({
		name = name,
		level = name == "" and loggingMeta.Levels.DEFAULT or nil
	}, self)

	log.Trace1 = loggingMeta:Build(name, "TRACE1")
	log.Trace2 = loggingMeta:Build(name, "TRACE2")
	log.Trace3 = loggingMeta:Build(name, "TRACE3")
	log.Debug = loggingMeta:Build(name, "DEBUG")
	log.Info = loggingMeta:Build(name, "INFO")
	log.Warning = loggingMeta:Build(name, "WARNING")
	log.Error = loggingMeta:Build(name, "ERROR")
	log.Critical = loggingMeta:Build(name, "CRITICAL")
	log.Fatal = loggingMeta:Build(name, "FATAL")

	return log
end

--- Sets the level of the logger.
--- @param level string|number
--- @return Logger
function logger:SetLevel(level)
	self.level = logging:Parse(level) or logging.Levels.INHERIT
	return self
end

--- Fetch the level of the logger.
--- @return number|string
function logger:GetLevel()
	return self.level
end

--- Fetch the loggers parents name.
--- @return string|nil
function logger:GetParentName()
	local path = string.Explode(".", self.name)
	local len = #path
	if len == 0 then
		return nil
	end
	if len == 1 then
		return ""
	end

	return table.concat(path, ".", 1, len - 1)
end

--- Fetch the logger parent.
--- @return Logger|nil
function logger:GetParent()
	local key = self:GetParentName()
	if not key then
		return nil
	end

	return logging:GetLogger(key)
end

--- Fetch the name of a child logger.
--- @param key string
--- @return string
function logger:GetChildName(key)
	if self.name == "" then
		return key
	end

	local path = string.Explode(".", self.name)
	table.insert(path, key)
	return table.concat(path, ".")
end

--- Fetch a child logger.
--- @param key string
--- @return Logger
function logger:GetChild(key)
	return logging:GetLogger(self:GetChildName(key))
end

--- Fetch the effective level of the logger.
--- @return number|string
function logger:GetEffectiveLevel()
	if self.level then
		return self.level
	end

	local parent = self:GetParent()
	if parent then
		return parent:GetEffectiveLevel()
	end

	return logging.Levels.DEFAULT
end

--- Highlights a given set of arguments.
--- @param ... any
function logger:Highlight(...)
	return logging:Highlight(...)
end

--- Get or create a cached logging instance.
--- @param name string Name of the logger to fetch.
--- @return Logger
function logging:GetLogger(name)
	local key = name:lower()
	if not self.stored[key] then
		self.stored[key] = logger:New(name, self)
	end

	return self.stored[key]
end

logging.Get = logging.GetLogger

--- Fetch the root logging instance.
--- @return Logger
function logging:Root()
	return self:GetLogger("")
end

--- Wrap given statements in highlight colours.
--- @param ... any
--- @return table
function logging:Highlight(...)
	local hl = {self.Colours.Highlights, ...}
	table.insert(hl, self.Colours.Text)
	return hl
end

--- Sets a set of arguments to a given level.
--- @param level string
--- @param ... any
--- @return table
function logging:AsLevel(level, ...)
	local parsed = self:Parse(level:upper())
	if parsed == nil then
		return {...}
	end

	local color = self.Colours[parsed] or self.Colours.Text
	if select('#', ...) == 0 then
		return {color, level, self.Colours.Text}
	end

	local out = {color, ...}
	table.insert(out, self.Colours.Text)
	return out
end

logging.Phrases = {
	Brand = {logging.Colours.Brand, "PulsarLib"},
	BrandPride = {
		Color(228, 3, 3), "Pu",
		Color(255, 140, 0), "ls",
		Color(255, 237, 0), "ar",
		Color(0, 128, 38), "L",
		Color(36, 64, 142), "i",
		Color(115, 41, 130), "b",
	},
	BrandTrans = {
		Color(91, 206, 250), "Pu",
		Color(245, 169, 184), "ls",
		Color(255, 255, 255), "a",
		Color(245, 169, 184), "rL",
		Color(91, 206, 250), "ib",
	}
}

--- Create a table with the brand name.
--- @param wrapped boolean Should the Brand be wrapped in [].
--- @param event string It's a secret tool that'll help us later.
--- @return table
function logging:Brand(wrapped, event)
	if not event then
		event = ""

		local dt = os.date("%d-%m")
		if dt == "31-03" then
			event = "Trans"
		elseif os.date("%m") == "06" then
			event = "Pride"
		end
	end

	local brand = self.Phrases["Brand" .. event] or self.Phrases.Brand
	if wrapped then
		return {self.Colours.Text, "[", brand, self.Colours.Text, "]"}
	end

	return {brand, self.Colours.Text}
end

--- Emit a log with a Fatal log level.
--- @param ... any Stringable arguments.
function logging:Fatal(...)
	self:Root():Fatal(...)
end

--- Emit a log with a Critical log level.
--- @param ... any Stringable arguments.
function logging:Critical(...)
	self:Root():Critical(...)
end

--- Emit a log with a Error log level.
--- @param ... any Stringable arguments.
function logging:Error(...)
	self:Root():Error(...)
end

--- Emit a log with a Warning log level.
--- @param ... any Stringable arguments.
function logging:Warning(...)
	self:Root():Warning(...)
end

--- Emit a log with a Info log level.
--- @param ... any Stringable arguments.
function logging:Info(...)
	self:Root():Info(...)
end

--- Emit a log with a Debug log level.
--- @param ... any Stringable arguments.
function logging:Debug(...)
	self:Root():Debug(...)
end

--- Emit a log with a level 1 trace log level.
--- @param ... any Stringable arguments.
function logging:Trace1(...)
	self:Root():Trace1(...)
end

--- Emit a log with a level 2 trace log level.
--- @param ... any Stringable arguments.
function logging:Trace2(...)
	self:Root():Trace2(...)
end

--- Emit a log with a level 3 trace log level.
--- @param ... any Stringable arguments.
function logging:Trace3(...)
	self:Root():Trace3(...)
end

-- Preload the root logger.
logging:GetLogger("")

local function autoComplete(cmd)
	local tbl = {}
	for k, v in pairs(logging.Levels) do
		if k ~= "DEFAULT" then
			table.insert(tbl, cmd .. " " .. k:lower())
		end
	end

	return tbl
end

concommand.Add("pulsarlib_logging_setserverlevel", function(ply, _, args)
	if not SERVER then
		return
	end

	local function output(...)
		logging:Root():Info(true, ...)
	end
	if IsValid(ply) then
		if not ply:IsSuperAdmin() then
			return ply:ChatPrint("You are not authorised to set the server logging level!")
		end

		-- Overwrite our local print function.
		-- To pass all our output to the calling client.
		function output(...)
			local out = flatten({...})
			for i = 1, #out do
				if out[i] and IsColor(out[i]) then
					table.remove(out, i)
				end
			end

			ply:PrintMessage(HUD_PRINTCONSOLE, table.concat(out, ""))
		end
	end

	local cnt = #args
	if cnt == 0 or cnt > 2 then
		output("USAGE: pulsarlib_logging_setserverlevel [<logger>] <level>")
		output("logger: Optional name of the logger, as seen in your console.")
		output("        If not set, defaults to root logger.")
		output("level: Either a Level Enum Name, or a integer value of either -1, or between 0 and 100.")
		output("       Levels: ", logging:AsLevel("FATAL"), ", ", logging:AsLevel("CRITICAL"), ", ", logging:AsLevel("ERROR"), ", ", logging:AsLevel("WARNING"), ", ", logging:AsLevel("INFO"), ", ", logging:AsLevel("DEBUG"), ", ", logging:AsLevel("TRACE1"), ", ", logging:AsLevel("TRACE2"), ", ", logging:AsLevel("TRACE3"))
		output("       Special Values: DEFAULT, NONE, ANY, INHERIT")
		output()
		output("Setting a logger's level will disallow displaying any logs below that level.")
		output("Any child loggers not explicitly set will also inherit this level.")
		output("Ie. Setting a logger to NONE will disallow all messages.")
		output("Ie. Setting a logger to ERROR will allow ERROR, CRITICAL and FATAL messages.")
		return
	end

	if cnt == 1 then
		return logging:Root():SetLevel(args[1]):Info(true, "Logging level set to '", args[1], "'")
	end

	if cnt == 2 then
		return logging:GetLogger(args[1]):SetLevel(args[2]):Info(true, "Logging level set to '", args[2], "' for logger '", args[1], "'")
	end
end, autoComplete)
if CLIENT then
	concommand.Add("pulsarlib_logging_setclientlevel", function(_, _, args)
		local cnt = #args
		if cnt == 0 or cnt > 2 then
			logging:Root():Info(true, "USAGE: pulsarlib_logging_setclientlevel [<logger>] <level>")
			logging:Root():Info(true, "logger: Optional name of the logger, as seen in your console.")
			logging:Root():Info(true, "        If not set, defaults to root logger.")
			logging:Root():Info(true, "level: Either a Level Enum Name, or a integer value of either -1, or between 0 and 100.")
			logging:Root():Info(true, "       Levels: ", logging:AsLevel("FATAL"), ", ", logging:AsLevel("CRITICAL"), ", ", logging:AsLevel("ERROR"), ", ", logging:AsLevel("WARNING"), ", ", logging:AsLevel("INFO"), ", ", logging:AsLevel("DEBUG"), ", ", logging:AsLevel("TRACE1"), ", ", logging:AsLevel("TRACE2"), ", ", logging:AsLevel("TRACE3"))
			logging:Root():Info(true, "       Special Values: DEFAULT, NONE, ANY, INHERIT")
			logging:Root():Info(true)
			logging:Root():Info(true, "Setting a logger's level will disallow displaying any logs below that level.")
			logging:Root():Info(true, "Any child loggers not explicitly set will also inherit this level.")
			logging:Root():Info(true, "Ie. Setting a logger to NONE will disallow all messages.")
			logging:Root():Info(true, "Ie. Setting a logger to ERROR will allow ERROR, CRITICAL and FATAL messages.")
			return
		end

		if cnt == 1 then
			return logging:Root():SetLevel(args[1]):Info(true, "Logging level set to '", args[1], "'")
		end

		if cnt == 2 then
			return logging:GetLogger(args[1]):SetLevel(args[2]):Info(true, "Logging level set to '", args[2], "' for logger '", args[1], "'")
		end
	end)
end

if PulsarLib.DevelopmentMode then
	logging:Root():SetLevel("ANY")
end