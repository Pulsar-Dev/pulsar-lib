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

	return self.Levels.DEFAULT
end

--- Build the logging method for a given level.
-- @tparam Logger logger Logger to build the method for.
-- @string component The component name to build for.
-- @number level Required logging level.
function logging:Build(logger, component, level)
	local levelValue = isnumber(level) and level or self.Levels[level:upper()]

	local args = {}
	table.insert(args, fp{self.Brand, self, true})
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

	local function prt(calledLogger, ...)
		if (select(1, ...)) == true then
			logging.print(select(2, ...))
			return calledLogger
		end

		if calledLogger:GetEffectiveLevel() > levelValue then
			return calledLogger
		end

		logging.print(...)
		return calledLogger
	end

	return fp({prt, logger, unpack(args)})
end

local logger = {}
logger.__index = logger

function logger:New(name)
	local log = setmetatable({
		name = name,
		level = name == "" and logging.Levels.DEFAULT or nil
	}, self)

	log.Trace1 = logging:Build(log, name, "TRACE1")
	log.Trace2 = logging:Build(log, name, "TRACE2")
	log.Trace3 = logging:Build(log, name, "TRACE3")
	log.Debug = logging:Build(log, name, "DEBUG")
	log.Info = logging:Build(log, name, "INFO")
	log.Warning = logging:Build(log, name, "WARNING")
	log.Error = logging:Build(log, name, "ERROR")
	log.Critical = logging:Build(log, name, "CRITICAL")
	log.Fatal = logging:Build(log, name, "FATAL")

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

--- Fetch the root logging instance.
-- @treturn Logger
function logging:Root()
	return self:GetLogger("")
end

--- Wrap given statements in highlight colours.
-- @param ...
-- @treturn table
function logging:Highlight(...)
	local hl = {self.Colours.Highlight, ...}
	table.insert(hl, self.Colours.Text)
	return hl
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

function logging:Level(component)
	if not component then
		component = ""
	end

	local path = string.Explode(".", component)
	for i = #path, 0, -1 do
		local check = table.concat(path, ".", 1, i)
		if self.CurrentLevels[check] then
			return self.CurrentLevels[check]
		end
	end

	return self.Levels.DEFAULT
end

--- Build the message functions for a given level.
-- Adds the function to logging.<LEVEL>, ie logging.Warning
-- @tparam string level Message level.
function logging:Build(component, level)
	local levelValue = isnumber(level) and level or self.Levels[level:upper()]

	local args, fileArgs = {}, {"["}
	table.insert(args, PulsarLib.Functional.partial(self.Brand, self, true))
	table.insert(args, self.Colours.Text)
	table.insert(args, "[")

	local logTypes = {
		["SERVER"] = {
			Colour = self.Colours.Server,
			Text = "SERVER"
		},
		["CLIENT"] = {
			Colour = self.Colours.Client,
			Text = "CLIENT"
		},
	}

	local logType = SERVER and "SERVER" or "CLIENT"
	table.insert(args, logTypes[logType].Colour)
	table.insert(args, logTypes[logType].Text)
	table.insert(args, self.Colours.Text)
	table.insert(args, "][")

	table.insert(fileArgs, os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(fileArgs, "][")

	if component ~= "" then
		table.insert(args, component)
		table.insert(fileArgs, component)
		table.insert(args, "][")
		table.insert(fileArgs, "][")
	end

	table.insert(fileArgs, level:upper())
	table.insert(fileArgs, "] ")

	if self.Colours[levelValue] then
		table.insert(args, self.Colours[levelValue])
		table.insert(args, level:upper())
		table.insert(args, self.Colours.Text)
		table.insert(args, "] ")
	else
		table.insert(args, level .. "] ")
	end

	local function prt(...)
		if (select(1, ...)) == true then
			self.print(select(2, ...))
		end

		if self:Level(component:lower()) > levelValue then
			return
		end

		self.print(...)
	end
	local function filePrt(...)
		if not self.LogToFile then
			return
		end

		if (select(1, ...)) == true then
			self.filePrint(select(2, ...))
		end

		if self:Level(component:lower()) > levelValue then
			return
		end

		self.filePrint(...)
	end

	local write = PulsarLib.Functional.partial(
		prt,
		unpack(args)
	)
	local forceWrite = PulsarLib.Functional.partial(
		prt,
		true,
		unpack(args)
	)
	local writeToFile = PulsarLib.Functional.partial(
		filePrt,
		unpack(fileArgs)
	)
	local forceWriteToFile = PulsarLib.Functional.partial(
		filePrt,
		true,
		unpack(fileArgs)
	)

	return function(...)
		write(...)
		writeToFile(...)
	end, function(...)
		forceWrite(...)
		forceWriteToFile(...)
	end
end

function logging:Get(logger)
	local key = logger:lower()

	if not self.stored[key] then
		self.stored[key] = {}
		for _, level in ipairs({"Fatal", "Error", "Warning", "Info", "Debug"}) do
			local msg, forceMsg = self:Build(logger, level)
			self.stored[key][level] = msg
			self.stored[key]["Force" .. level] = forceMsg
		end
	end

	return self.stored[key]
end

function logging.Fatal(...)
	logging:Get("").Fatal(...)
end
function logging.ForceFatal(...)
	logging:Get("").ForceFatal(...)
end

function logging.Error(...)
	logging:Get("").Error(...)
end
function logging.ForceError(...)
	logging:Get("").ForceError(...)
end

function logging.Warning(...)
	logging:Get("").Warning(...)
end
function logging.ForceWarning(...)
	logging:Get("").ForceWarning(...)
end

function logging.Info(...)
	logging:Get("").Info(...)
end
function logging.ForceInfo(...)
	logging:Get("").ForceInfo(...)
end

function logging.Debug(...)
	logging:Get("").Debug(...)
end
function logging.ForceDebug(...)
	logging:Get("").ForceDebug(...)
end

concommand.Add("pulsarlib_log_report", function()
	local l = logging
	local c = l.Colours
	local t = c.Text

	MsgC(unpack(flatten(l:Brand(), " Logging Configuration Report\n")))
	MsgC(t, "Logging is configurable, to be as chatty or quiet as required.\n")
	MsgC(t, "For this, we have various logging levels, representing how dire a log represents.\n")
	MsgC(t, "The various pulsarlib_log ConVars are used to control which of these output.\n")
	MsgC(t, "Any logs at the given level or above will be shown.\n")
	MsgC(t, "Any logs below will be hidden.\n\n")
	MsgC(t, "todo: make it show all the configured loggers")

	MsgC("\n", t, "Below here, we'll print one of each log, in decending order of severity.\n\n")
	l.Fatal("Example Fatal Log")
	l.Error("Example Error Log")
	l.Warning("Example Warning Log")
	l.Info("Example Informational Log")
	l.Debug("Example Debug Log")
end, nil, "Report on which logging levels will be reported by PulsarLib.")

logging:CreateConVar(nil, "")
logging:CreateConVar("loader", "loader")
logging:CreateConVar("database", "database")
logging:CreateConVar("deprecations", "deprecations")