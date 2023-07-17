--- Logging Library.
-- @author Joshua Piper
-- @module PulsarLib.Logging
-- @alias logging

PulsarLib = PulsarLib or {}
PulsarLib.Logging = PulsarLib.Logging or setmetatable({
	stored = {}
}, {__index = PulsarLib})
local logging = PulsarLib.Logging

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

logging.CurrentLevels = {}

function logging.Parse(level)
	if tonumber(level) ~= nil then
		level = tonumber(level)
	end

	if isnumber(level) then
		return math.Clamp(level, logging.Levels._MIN, logging.Levels._MAX)
	end

	if level == "INHERIT" then
		return nil
	end

	if logging.Levels[level] then
		return logging.Levels[level]
	end

	return logging.Levels.DEFAULT
end

function logging:EnumDescription()
	local desc = "int[%0d <= X <= %0d]|string<%s>"
	local levels = {}

	for name, level in SortedPairsByValue(self.Levels, true) do
		if name:StartWith("_") then
			continue
		end

		table.insert(levels, name)
	end

	return string.format(desc, self.Levels._MIN, self.Levels._MAX, table.concat(levels, ", "))
end

local log_to_file_cvar = CreateConVar(
	"pulsarlib_log_tofile",
	0,
	FCVAR_ARCHIVE + FCVAR_ARCHIVE_XBOX + FCVAR_UNLOGGED,
	"Set if PulsarLib should log to file. <0|1>",
	0,
	1
)
logging.LogToFile = log_to_file_cvar:GetBool()
cvars.RemoveChangeCallback(log_to_file_cvar:GetName(), "PulsarLib.Logging")
cvars.AddChangeCallback(log_to_file_cvar:GetName(), function()
	logging.LogToFile = log_to_file_cvar:GetBool()
end, "PulsarLib.Logging")

function logging:CreateConVar(name, sets)
	if not istable(sets) then
		sets = {sets}
	end

	if name == nil then
		name = "pulsarlib_log_level"
	else
		name = "pulsarlib_log_level_" .. name
	end

	local level_cvar = CreateConVar(
		name,
		name == nil and self.Levels.DEFAULT or "INHERIT",
		FCVAR_ARCHIVE + FCVAR_ARCHIVE_XBOX + FCVAR_UNLOGGED,
		string.format("Set a component logging level for PulsarLib (%s)", self:EnumDescription()),
		self.Levels._MIN,
		self.Levels._MAX
	)

	local value = self.Parse(level_cvar:GetString())
	for _, set in ipairs(sets) do
		self.CurrentLevels[set] = value
	end

	cvars.RemoveChangeCallback(level_cvar:GetName(), "PulsarLib.Logging")
	cvars.AddChangeCallback(level_cvar:GetName(), function(x, _, val)
		value = self.Parse(val)
		for _, set in ipairs(sets) do
			self.CurrentLevels[set] = value
		end
	end, "PulsarLib.Logging")
end

local function flatten(...)
	local out = {}
	local n = select('#', ...)
	for i = 1, n do
		local v = (select(i, ...))
		if istable(v) and not IsColor(v) then
			table.Add(out, flatten(unpack(v)))
		elseif isfunction(v) then
			table.Add(out, flatten(v()))
		else
			table.insert(out, v)
		end
	end

	return out
end

function logging.filePrint(...)
	local handle = file.Open("PulsarLib-" .. os.date("%Y-%m-%d") .. ".log.txt", "a", "DATA")
	local entries = flatten(...)

	for _, val in ipairs(entries) do
		if isstring(val) then
			handle:Write(val)
		end
	end
	handle:Write("\n")
	handle:Flush()
	handle:Close()
end

function logging.print(...)
	MsgC(unpack(flatten(...)))
	print()
end

logging.Phrases = {
	Brand = {logging.Colours.Brand, "PulsarLib"},
	BrandPride = {
		Color(228, 3, 3), "P",
		Color(255, 140, 0), "u",
		Color(255, 237, 0), "l",
		Color(0, 128, 38), "s",
		Color(36, 64, 142), "a",
		Color(115, 41, 130), "r",
		Color(228, 3, 3), "L",
		Color(255, 140, 0), "i",
		Color(255, 237, 0), "b",
	}
}

--- Create a table with the brand name.
-- @bool wrapped Should the Brand be wrapped in [].
-- @string event It's a secret tool that'll help us later.
-- @rtab
function logging:Brand(wrapped, event)
	if not event then
		event = ""

		if os.date("%m") == "06" then
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