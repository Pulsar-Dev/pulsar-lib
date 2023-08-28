PulsarLib = PulsarLib or {}

if file.Exists("pulsarlib/dev", "DATA") then
	PulsarLib.DevelopmentMode = true
end

local loadLogger
function PulsarLib:Include(path, state, full)
	if not full then
		path = "pulsar_lib/" .. path
		if not path:EndsWith(".lua") then
			path = path .. ".lua"
		end
	end

	local prefix = state or path:match("/?(%w%w)[%w_]*.lua$") or "sh"
	if not loadLogger and self.Logging then
		loadLogger = self.Logging:Get("Loader")
	end
	if loadLogger then
		loadLogger:Debug("Prefix: ", loadLogger:Highlight(prefix), ". Path: '", loadLogger:Highlight(path), "'")
	end

	if prefix == "sh" or prefix == "cl" then
		AddCSLuaFile(path)
		if CLIENT or prefix == "sh" then
			return include(path)
		end
	elseif SERVER and prefix == "sv" then
		return include(path)
	end
end

function PulsarLib:IncludeDir(path, state)
	path = "pulsar_lib/" .. path
	if not path:EndsWith("/") then
		path = path .. "/"
	end

	if loadLogger then
		loadLogger:Debug("Including Directory: '", loadLogger:Highlight(path), "'")
	end

	local files = file.Find(path .. "*", "LUA")
	for _, name in ipairs(files) do
		self:Include(path .. name, state, true)
	end
end

function PulsarLib:IncludeDirRecursive(path, state, full)
	if not full then
		path = "pulsar_lib/" .. path
	end
	if not path:EndsWith("/") then
		path = path .. "/"
	end

	if loadLogger then
		loadLogger:Debug("Recursive Include of: '", loadLogger:Highlight(path), "'")
	end

	local files, folders = file.Find(path .. "*", "LUA")
	for _, name in ipairs(files) do
		self:Include(path .. name, state, true)
	end
	for _, name in ipairs(folders) do
		self:IncludeDirRecursive(path .. name, state, true)
	end
end

PulsarLib:Include("sh_init") 