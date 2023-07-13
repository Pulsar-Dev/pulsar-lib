PulsarLib = PulsarLib or {}
PulsarLib.Addons = PulsarLib.Addons or setmetatable({
	stored = {}
}, {__index = PulsarLib})

PulsarLib.Addons.WaitingForDeps = PulsarLib.Addons.WaitingForDeps or {}

local loaders = {}

loaders.Include = function(self, path, state, full)
	self = self.PulsarLibAddon
	if not full then
		path = self.Folder .. "/" .. path
		if not path:EndsWith(".lua") then
			path = path .. ".lua"
		end
	end

	local prefix = state or path:match("/?(%w%w)[%w_]*.lua$") or "sh"

	if self.GlobalVar.Logging:Get("Loader") then
		self.GlobalVar.Logging:Get("Loader").Debug("Prefix: ", prefix, ". Path: '", path, "'")
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

	if self.Logging:Get("Loader") then
		self.Logging:Get("Loader").Debug("Including Directory: '", path, "'")
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

	if self.Logging:Get("Loader") then
		self.Logging:Get("Loader").Debug("Recursive Include of: '", path, "'")
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
	self.Dependencies = deps
	return self
end

function AddonHandler:Load()
	if not self.GlobalVar then
		PulsarLib.Logging.Error("Addon " .. self.name .. " has no global var")
		return
	end

	self.GlobalVar.PulsarLibAddon = self

	self.GlobalVar.Logging = table.Copy(PulsarLib.Logging)
	self.GlobalVar.Logging.stored = {}
	self.GlobalVar.Logging = setmetatable(self.GlobalVar.Logging, {__index = self.GlobalVar})
	self.GlobalVar.Logging:Get("Loader")

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

	local loadable = false
	if not istable(self.Dependencies) or (table.Count(self.Dependencies) == 0) then
		loadable = true
	else
		loadable = true

		for k, v in pairs(self.Dependencies) do
			if not PulsarLib.ModuleTable[k].Loaded then
				PulsarLib.Logging.Debug("Addon " .. self.name .. " waiting for " .. k .. " to load")
				loadable = false
				PulsarLib.Addons.WaitingForDeps[self.name] = self
				break
			end
		end
	end

	PulsarLib.Logging.Info("Addon " .. self.name .. " was created and is ready to load.")

	if self.Folder and loadable then
		self.GlobalVar:Include(self.Folder .. "/sh_init.lua", "sh", true)
		if self.OnLoad then
			self:OnLoad()
		end
	end
end

addons.Create = AddonHandler.Create