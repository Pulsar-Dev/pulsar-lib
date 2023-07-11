PulsarLib = PulsarLib or {}
PulsarLib.Addons = PulsarLib.Addons or setmetatable({
	stored = {}
}, {__index = PulsarLib})

local loaders = {}
local loadLogger

loaders.Include = function(self, path, state, full)
	self = self.PulsarLibAddon
	if not full then
		path = self.Folder .. "/" .. path
		if not path:EndsWith(".lua") then
			path = path .. ".lua"
		end
	end

	local prefix = state or path:match("/?(%w%w)[%w_]*.lua$") or "sh"
	if not loadLogger and self.Logging then
		loadLogger = self.Logging:Get("Loader")
	end
	if loadLogger then
		loadLogger.Debug("Prefix: ", prefix, ". Path: '", path, "'")
	end

	if prefix ~= "sv" then
		AddCSLuaFile(path)
		if CLIENT or prefix == "sh" then
			return include(path)
		end
	elseif SERVER then
		return include(path)
	end
end

loaders.IncludeDir = function(self, path, state)
	path = self.PulsarLibAddon.Folder .. "/" .. path
	if not path:EndsWith("/") then
		path = path .. "/"
	end

	if loadLogger then
		loadLogger.Debug("Including Directory: '", path, "'")
	end

	local files = file.Find(path .. "*", "LUA")
	for _, name in ipairs(files) do
		self:Include(path .. name, state, true)
	end
end

loaders.IncludeDirRecursive = function(self, path, state, full)
	if not full then
		path = self.PulsarLibAddon.Folder .. "/" .. path
	end
	if not path:EndsWith("/") then
		path = path .. "/"
	end

	if loadLogger then
		loadLogger.Debug("Recursive Include of: '", path, "'")
	end

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
	self.dependencies = deps
	return self
end

function AddonHandler:Load()
	if not self.GlobalVar then
		PulsarLib.Logging.Error("Addon " .. self.name .. " has no global var")
		return
	end

	loadLogger = nil

	self.GlobalVar.PulsarLibAddon = self

	self.GlobalVar.Logging = table.Copy(PulsarLib.Logging)
	self.GlobalVar.Logging.stored = {}
	self.GlobalVar.Logging = setmetatable(self.GlobalVar.Logging, {__index = self.GlobalVar})
	loadLogger = self.GlobalVar.Logging:Get("Loader")

	if self.Phrases then
		self.GlobalVar.Logging.stored = {}
		self.GlobalVar.Logging.Phrases = self.Phrases
		self.GlobalVar.Logging:Get("")
	end

	self.GlobalVar.Language = table.Copy(PulsarLib.Language)
	self.GlobalVar.Language.filePath = self.Folder .. "/language/*.lua"
	self.GlobalVar.Language.stored = {}
	self.GlobalVar.Language.plurals = {}
	self.GlobalVar.Language:Load()

	self.GlobalVar.Include = loaders.Include
	self.GlobalVar.IncludeDir = loaders.IncludeDir
	self.GlobalVar.IncludeDirRecursive = loaders.IncludeDirRecursive

	if self.Folder then
		self.GlobalVar:Include(self.Folder .. "/sh_init.lua", "sh", true)
	end

	if self.OnLoad then
		self:OnLoad()
	end

	PulsarLib.Logging.Info("Addon " .. self.name .. " loaded")
end

addons.Create = AddonHandler.Create