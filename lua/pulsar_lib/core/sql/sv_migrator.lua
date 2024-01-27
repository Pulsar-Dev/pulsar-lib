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

function MIGRATOR:Error(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.E, "[ERROR]", " ", self.R, ...)
	MsgC("\n", self.R)
end

function MIGRATOR:Warning(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.W, "[WARNING]", " ", self.R, ...)
	MsgC("\n", self.R)
end

function MIGRATOR:Message(...)
	MsgC(self.R, bracket(date("%Y-%m-%dT%X")), bracket(self.name or "Anonymous Migrator"), self.M, "[INFO]", " ", self.R, ...)
	MsgC("\n", self.R)
end

function MIGRATOR:Up()
	return self:Error("MIGRATOR:Up() has not been implemented in a child class.")
end

function MIGRATOR:Down()
	return self:Error("MIGRATOR:Up() has not been implemented in a child class.")
end

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