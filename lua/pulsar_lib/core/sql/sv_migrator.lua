--- @class MIGRATOR
--- @field public E Color
--- @field public W Color
--- @field public M Color
--- @field public R Color
--- @field public name string
local MIGRATOR = {}
MIGRATOR.E = Color(255, 0, 0)
MIGRATOR.W = Color(255, 255, 0)
MIGRATOR.M = Color(150, 150, 150)
MIGRATOR.R = Color(255, 255, 255)
MIGRATOR.__index = MIGRATOR

local date = os.date
local format = string.format
local function bracket(str)
	return format("[%s]", str)
end

--- Prints an error message to the console.
--- @param ... any The error message to print.
function MIGRATOR:Error(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.E, "[ERROR]", " ", self.R, ...)
	MsgC("\n", self.R)
end

--- Prints an warning message to the console.
--- @param ... any The warning message to print.
function MIGRATOR:Warning(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.W, "[WARNING]", " ", self.R, ...)
	MsgC("\n", self.R)
end

--- Prints an message to the console.
--- @param ... any The message to print.
function MIGRATOR:Message(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.M, "[INFO]", " ", self.R, ...)
	MsgC("\n", self.R)
end

--- Not implemented.
function MIGRATOR:Up()
	return self:Error("MIGRATOR:Up() has not been implemented in a child class.")
end

--- Not implemented.
function MIGRATOR:Down()
	return self:Error("MIGRATOR:Up() has not been implemented in a child class.")
end

--- Creates a new Migrator
--- @param name string|table The name of the migrator.
--- @param sort number The sort order of the migrator.
--- @param up function The function to run when migrating up.
--- @param down function The function to run when migrating down.
--- @return MIGRATOR
function MIGRATOR:New(name, sort, up, down)
	if istable(name) then
		if name.up then
			up = name.up
		end

		if name.down then
			down = name.down
		end

		if name.name then
			name = name.name
		end
	end

	local dt = {}
	if name then
		dt.name = name
	end
	if isnumber(sort) then
		dt.sort = sort
	end
	if isfunction(up) then
		dt.Up = up
	end
	if isfunction(down) then
		dt.Down = down
	end

	return setmetatable(dt, MIGRATOR)
end

return MIGRATOR