--- Logging Library.
-- @author Joshua Piper
-- @module PulsarLib.Logging
-- @alias logging

PulsarLib = PulsarLib or {}
PulsarLib.Logging = PulsarLib.Logging or setmetatable({
	stored = {}
}, {__index = PulsarLib})
local logging = PulsarLib.Logging

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
-- @param ... Stringable instances to print.
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
-- @tparam string|number level
-- @treturn ?number
function logging:Parse(level)
	if level == "INHERIT" or level == -1 then
		return nil
	end

	if tonumber(level) ~= nil then
		level = tonumber(level)
	end

	if isnumber(level) then
		return math.Clamp(level, self.Levels._MIN, self.Levels._MAX)
	end

	if self.Levels[level] then
		return self.Levels[level]
	end

	-- If we cannot parse the log level, return back to inheriting.
	-- Internally, the root logger will return the default level, so no worries there.
	return nil
end

--- Build the logging method for a given level.
-- @tparam Logger logger Logger to build the method for.
-- @string component The component name to build for.
-- @number level Required logging level.
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

local logger = {}
logger.__index = logger

function logger:New(name)
	local log = setmetatable({
		name = name,
		level = name == "" and logging.Levels.DEFAULT or nil
	}, self)

	log.Trace1 = logging:Build(name, "TRACE1")
	log.Trace2 = logging:Build(name, "TRACE2")
	log.Trace3 = logging:Build(name, "TRACE3")
	log.Debug = logging:Build(name, "DEBUG")
	log.Info = logging:Build(name, "INFO")
	log.Warning = logging:Build(name, "WARNING")
	log.Error = logging:Build(name, "ERROR")
	log.Critical = logging:Build(name, "CRITICAL")
	log.Fatal = logging:Build(name, "FATAL")

	return log
end

function logger:SetLevel(level)
	self.level = logging:Parse(level)
	return self
end

function logger:GetLevel()
	return self.level
end

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

function logger:GetParent()
	local key = self:GetParentName()
	if not key then
		return nil
	end

	return logging:GetLogger(key)
end

function logger:GetChildName(key)
	if self.name == "" then
		return key
	end

	local path = string.Explode(".", self.name)
	table.insert(path, key)
	return table.concat(path, ".")
end

function logger:GetChild(key)
	return logging:GetLogger(self:GetChildName(key))
end

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

function logger:Highlight(...)
	return logging:Highlight(...)
end

--- Get or create a cached logging instance.
-- @string name Name of the logger to fetch.
-- @treturn Logger
function logging:GetLogger(name)
	local key = name:lower()
	if not self.stored[key] then
		self.stored[key] = logger:New(name)
	end

	return self.stored[key]
end

--- Get or create a cached logging instance.
-- @function logging:Get(name)
-- @string name Name of the logger to fetch.
-- @treturn Logger
logging.Get = logging.GetLogger

--- Fetch the root logging instance.
-- @treturn Logger
function logging:Root()
	return self:GetLogger("")
end

--- Wrap given statements in highlight colours.
-- @param ...
-- @treturn table
function logging:Highlight(...)
	local hl = {self.Colours.Highlights, ...}
	table.insert(hl, self.Colours.Text)
	return hl
end

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
-- @bool wrapped Should the Brand be wrapped in [].
-- @string event It's a secret tool that'll help us later.
-- @rtab
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
-- @function logger:Fatal(...)
-- @param ... Stringable arguments.
function logging:Fatal(...)
	self:Root():Fatal(...)
end

--- Emit a log with a Critical log level.
-- @function logger:Critical(...)
-- @param ... Stringable arguments.
function logging:Critical(...)
	self:Root():Critical(...)
end

--- Emit a log with a Error log level.
-- @function logger:Error(...)
-- @param ... Stringable arguments.
function logging:Error(...)
	self:Root():Error(...)
end

--- Emit a log with a Warning log level.
-- @function logger:Warning(...)
-- @param ... Stringable arguments.
function logging:Warning(...)
	self:Root():Warning(...)
end

--- Emit a log with a Info log level.
-- @function logger:Info(...)
-- @param ... Stringable arguments.

function logging:Info(...)
	self:Root():Info(...)
end

--- Emit a log with a Debug log level.
-- @function logger:Debug(...)
-- @param ... Stringable arguments.
function logging:Debug(...)
	self:Root():Debug(...)
end

--- Emit a log with a level 1 trace log level.
-- @function logger:Trace1(...)
-- @param ... Stringable arguments.
function logging:Trace1(...)
	self:Root():Trace1(...)
end

--- Emit a log with a level 2 trace log level.
-- @function logger:Trace2(...)
-- @param ... Stringable arguments.
function logging:Trace2(...)
	self:Root():Trace2(...)
end

--- Emit a log with a level 3 trace log level.
-- @function logger:Trace3(...)
-- @param ... Stringable arguments.
function logging:Trace3(...)
	self:Root():Trace3(...)
end

-- Preload the root logger.
logging:GetLogger("")
