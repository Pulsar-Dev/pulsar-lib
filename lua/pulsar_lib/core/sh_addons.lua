PulsarLib = PulsarLib or {}
PulsarLib.Addons = PulsarLib.Addons or setmetatable({
	stored = {}
}, {
	__index = PulsarLib
})

PulsarLib.Addons.WaitingForDeps = PulsarLib.Addons.WaitingForDeps or {}
PulsarLib.Addons.WaitingForLoad = PulsarLib.Addons.WaitingForLoad or {}
PulsarLib.Addons.Registered = PulsarLib.Addons.Registered or {}
local loaders = {}
loaders.Include = function(self, path, state, full)
	self = self.PulsarLibAddon
	if not full then
		path = self.Folder .. "/" .. path
		if not path:EndsWith(".lua") then path = path .. ".lua" end
	end

	local prefix = state or path:match("/?(%w%w)[%w_]*.lua$") or "sh"
	local logger = self.GlobalVar.Logging:Get("Loader")
	if logger then logger:Debug("Prefix: ", logger:Highlight(prefix), ". Path: '", logger:Highlight(path), "'") end
	if prefix ~= "sv" then
		AddCSLuaFile(path)
		if CLIENT or prefix == "sh" then return include(path) end
	elseif SERVER then
		return include(path)
	end
end

loaders.IncludeDir = function(self, path, state)
	path = self.PulsarLibAddon.Folder .. "/" .. path
	if not path:EndsWith("/") then path = path .. "/" end
	local logger = self.GlobalVar and self.GlobalVar.Logging:Get("Loader")
	if logger then logger:Debug("Including Directory: '", logger:Highlight(path), "'") end
	local files = file.Find(path .. "*", "LUA")
	for _, name in ipairs(files) do
		self:Include(path .. name, state, true)
	end
end

loaders.IncludeDirRecursive = function(self, path, state, full)
	if not full then path = self.PulsarLibAddon.Folder .. "/" .. path end
	if not path:EndsWith("/") then path = path .. "/" end
	local logger = self.GlobalVar and self.GlobalVar.Logging:Get("Loader")
	if logger then logger:Debug("Recursive Include of: '", logger:Highlight(path), "'") end
	local files, folders = file.Find(path .. "*", "LUA")
	for _, name in ipairs(files) do
		self:Include(path .. name, state, true)
	end

	for _, name in ipairs(folders) do
		self:IncludeDirRecursive(path .. name, state, true)
	end
end

local addons = PulsarLib.Addons
local AddonHandler = {}
function AddonHandler.Create(name)
	local addon = setmetatable({}, {
		__index = AddonHandler
	})

	addon.name = name
	return addon
end

function AddonHandler:SetFolder(dir)
	self.Folder = dir
	return self
end

function AddonHandler:SetGlobalVar(var)
	self.GlobalVar = var
	return self
end

function AddonHandler:SetPhrases(phrases)
	self.Phrases = phrases
	return self
end

function AddonHandler:SetOnLoad(func)
	self.OnLoad = func
	return self
end

function AddonHandler:SetDependencies(deps)
	self.Dependencies = deps
	return self
end

function AddonHandler:SetRequiredVars(requiredVars)
	self.RequiredVars = requiredVars
	return self
end

function AddonHandler:Load()
	if not self.GlobalVar then
		PulsarLib.Logging:Error("Addon " .. self.name .. " has no global var")
		return
	end

	self.GlobalVar.PulsarLibAddon = self
	self.GlobalVar.name = self.name
	self.GlobalVar.Logging = table.Copy(PulsarLib.Logging)
	self.GlobalVar.Functional = PulsarLib.Functional
	self.GlobalVar.Logging.stored = {}
	self.GlobalVar.Logging = setmetatable(self.GlobalVar.Logging, {
		__index = self.GlobalVar
	})

	if self.Phrases then
		self.GlobalVar.Logging.stored = {}
		self.GlobalVar.Logging.Phrases = self.Phrases
		self.GlobalVar.Logging:GetLogger("")
		self.GlobalVar.Logging:Get("Loader")
	end

	self.GlobalVar.Language = table.Copy(PulsarLib.Language)
	self.GlobalVar.Language.filePath = self.Folder .. "/language/*.lua"
	self.GlobalVar.Language.stored = {}
	self.GlobalVar.Language.plurals = {}
	self.GlobalVar.Language:Load()
	self.GlobalVar.Include = loaders.Include
	self.GlobalVar.IncludeDir = loaders.IncludeDir
	self.GlobalVar.IncludeDirRecursive = loaders.IncludeDirRecursive

	if SERVER then
		self.GlobalVar.Migrations = table.Copy(PulsarLib.SQL.Migrations)
		self.GlobalVar.Migrations.Ran = {}
		self.GlobalVar.Migrations.Stored = {}
		self.GlobalVar.Migrations.Logging = self.GlobalVar.Logging:Get("Migrations")
		self.GlobalVar.Migrations.addon = self.name
		self.GlobalVar.Migrations.filePath = self.Folder .. "/migrations"

		concommand.Add(self.name:lower() .. "_debug_runmigrations", function(ply)
			if IsValid(ply) and not ply:IsSuperAdmin() then
				return
			end

			self.GlobalVar.Migrations.parent = self.GlobalVar
			self.GlobalVar.Migrations:RunAll()
		end)
	end

	local logger_command_name = self.name:lower():gsub("[%s]", "")
	concommand.Add(logger_command_name .. "_logging_setserverlevel", function(ply, _, args)
		if CLIENT then return end
		local function output(...)
			self.GlobalVar.Logging:Root():Info(true, ...)
		end

		if IsValid(ply) then
			if not ply:IsSuperAdmin() then return ply:ChatPrint("You are not authorized to set the server logging level!") end
			-- Overwrite our local print function.
			-- To pass all our output to the calling client.
			function output(...)
				local out = self.GlobalVar.Logging.flatten({...})
				for i = 1, #out do
					if out[i] and IsColor(out[i]) then table.remove(out, i) end
				end

				ply:PrintMessage(HUD_PRINTCONSOLE, table.concat(out, ""))
			end
		end

		local cnt = #args
		if cnt == 0 or cnt > 2 then
			output(string.format("USAGE: %s [<logger>] <level>", logger_command_name .. "_logging_setserverlevel"))
			output("logger: Optional name of the logger, as seen in your console.")
			output("        If not set, defaults to root logger.")
			output("level: Either a Level Enum Name, or a integer value of either -1, or between 0 and 100.")
			output("       Levels: ", self.GlobalVar.Logging:AsLevel("FATAL"), ", ", self.GlobalVar.Logging:AsLevel("CRITICAL"), ", ", self.GlobalVar.Logging:AsLevel("ERROR"), ", ", self.GlobalVar.Logging:AsLevel("WARNING"), ", ", self.GlobalVar.Logging:AsLevel("INFO"), ", ", self.GlobalVar.Logging:AsLevel("DEBUG"), ", ", self.GlobalVar.Logging:AsLevel("TRACE1"), ", ", self.GlobalVar.Logging:AsLevel("TRACE2"), ", ", self.GlobalVar.Logging:AsLevel("TRACE3"))
			output("       Special Values: DEFAULT, NONE, ANY, INHERIT")
			output()
			output("Setting a logger's level will disallow displaying any logs below that level.")
			output("Any child loggers not explicitly set will also inherit this level.")
			output("Ie. Setting a logger to NONE will disallow all messages.")
			output("Ie. Setting a logger to ERROR will allow ERROR, CRITICAL and FATAL messages.")
			return
		end

		if cnt == 1 then return self.GlobalVar.Logging:Root():SetLevel(args[1]):Info(true, "Logging level set to '", args[1], "'") end
		if cnt == 2 then return self.GlobalVar.Logging:GetLogger(args[1]):SetLevel(args[2]):Info(true, "Logging level set to '", args[2], "' for logger '", args[1], "'") end
	end)

	if CLIENT then
		concommand.Add(logger_command_name .. "_logging_setclientlevel", function(_, _, args)
			local cnt = #args
			if cnt == 0 or cnt > 2 then
				self.GlobalVar.Logging:Root():Info(true, string.format("USAGE: %s [<logger>] <level>", logger_command_name .. "_self.GlobalVar.Logging_setclientlevel"))
				self.GlobalVar.Logging:Root():Info(true, "logger: Optional name of the logger, as seen in your console.")
				self.GlobalVar.Logging:Root():Info(true, "        If not set, defaults to root logger.")
				self.GlobalVar.Logging:Root():Info(true, "level: Either a Level Enum Name, or a integer value of either -1, or between 0 and 100.")
				self.GlobalVar.Logging:Root():Info(true, "       Levels: ", PulsarLib.Logging:AsLevel("FATAL"), ", ", PulsarLib.Logging:AsLevel("CRITICAL"), ", ", PulsarLib.Logging:AsLevel("ERROR"), ", ", PulsarLib.Logging:AsLevel("WARNING"), ", ", PulsarLib.Logging:AsLevel("INFO"), ", ", PulsarLib.Logging:AsLevel("DEBUG"), ", ", PulsarLib.Logging:AsLevel("TRACE1"), ", ", PulsarLib.Logging:AsLevel("TRACE2"), ", ", PulsarLib.Logging:AsLevel("TRACE3"))
				self.GlobalVar.Logging:Root():Info(true, "       Special Values: DEFAULT, NONE, ANY, INHERIT")
				self.GlobalVar.Logging:Root():Info(true)
				self.GlobalVar.Logging:Root():Info(true, "Setting a logger's level will disallow displaying any logs below that level.")
				self.GlobalVar.Logging:Root():Info(true, "Any child loggers not explicitly set will also inherit this level.")
				self.GlobalVar.Logging:Root():Info(true, "Ie. Setting a logger to NONE will disallow all messages.")
				self.GlobalVar.Logging:Root():Info(true, "Ie. Setting a logger to ERROR will allow ERROR, CRITICAL and FATAL messages.")
				return
			end

			if cnt == 1 then return self.GlobalVar.Logging:Root():SetLevel(args[1]):Info(true, "Logging level set to '", args[1], "'") end
			if cnt == 2 then return self.GlobalVar.Logging:GetLogger(args[1]):SetLevel(args[2]):Info(true, "Logging level set to '", args[2], "' for logger '", args[1], "'") end
		end)
	end

	local loadable = false
	local loadedDependencies = {}
	local errorMsg = ""
	local function loadAddon()
		if not loadable then
			PulsarLib.Logging:Error("Addon '" .. self.name .. "' has errored during load: " .. errorMsg)
			return
		end

		PulsarLib.Logging:Info("Addon " .. self.name .. " was created and is now loading.")
		PulsarLib.Addons.stored[self.name] = self
		if self.Folder then
			self.GlobalVar:Include(self.Folder .. "/sh_init.lua", "sh", true)
			PulsarLib.Logging:Info("Addon " .. self.name .. " has loaded.")
			if SERVER then
				self.GlobalVar.Migrations.parent = self.GlobalVar
				self.GlobalVar.Migrations:RunAll()
			end

			if self.OnLoad then self:OnLoad() end
		end
	end

	if not istable(self.Dependencies) or (table.Count(self.Dependencies) == 0) then
		loadable = true
	else
		local totalDependencies = table.Count(self.Dependencies)
		local loadedCount = 0
		for dependency, version in pairs(self.Dependencies) do
			if not dependency then
				PulsarLib.Logging:Error("Addon " .. self.name .. " has a dependency with no name")
				return
			end

			if not version then
				PulsarLib.Logging:Error("Addon " .. self.name .. " has a dependency with no version")
				return
			end

			loadedDependencies[dependency] = false
			PulsarLib.Logging:Debug("Addon " .. self.name .. " is waiting for " .. dependency .. " to load")

			PulsarLib.Modules.LoadModule(dependency, version)

			hook.Add("PulsarLib.Module.Loaded", "PulsarLib.Addons." .. self.name .. ".Dependency." .. dependency, function(moduleName)
				if moduleName ~= dependency then return end
				loadedDependencies[dependency] = true
				loadedCount = loadedCount + 1
				if loadedCount == totalDependencies then
					loadable = true
					PulsarLib.Logging:Debug("Addon " .. self.name .. " has loaded " .. loadedCount .. "/" .. totalDependencies .. " dependencies.")
					hook.Remove("PulsarLib.Module.Loaded", "PulsarLib.Addons." .. self.name .. ".Dependency." .. dependency)
					loadAddon()
				end
			end)

			hook.Add("PulsarLib.Module.FailedLoad", "PulsarLib.Addons." .. self.name .. ".Dependency." .. dependency, function(moduleName, err)
				if moduleName ~= dependency then return end
				errorMsg = err
				PulsarLib.Logging:Error("Addon " .. self.name .. " has errored during load: " .. error)
				hook.Remove("PulsarLib.Module.FailedLoad", "PulsarLib.Addons." .. self.name .. ".Dependency." .. dependency)
			end)
		end
	end

	if loadable then loadAddon() end
	table.insert(PulsarLib.Addons.Registered, self.name)
end

addons.Create = AddonHandler.Create